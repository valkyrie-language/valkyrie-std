namespace nyar.emitter.wasm.host;

using nyar.emitter.executable;
using nyar.emitter.wasi;

# WASI Component Model packaging shell — isomorphic to Rust
# `lowering/backends/wasm/host/wasi_cm`.
#
# Entry: `ExecutableModule` only (no body_source bypass). Fail-closed on empty MIR,
# and on any `wasi_snapshot_preview1` import (use wasip2 / wasip3).
#
# Exports use **full** WIT names (`wasi:cli/run@{ver}#run`), never a bare `run`.
# Paths / guest strings at this boundary are UTF-8 bytes — do not index via Utf16Text.

# Declared host import `(module, field)` — source `[wasi(...)]` only; never synthesize.
structure WasiCmHostImport {
    module: utf8
    field: utf8
}

micro empty_wasi_cm_host_imports() -> [WasiCmHostImport] {
    return []
}

# Fail-closed if any import module is preview1.
micro wasi_cm_validate_imports(imports: [WasiCmHostImport]) -> utf8 {
    let mut i: usize = 0
    while i < imports.length() {
        let module: utf8 = imports⁅i⁆.module
        if wasi_is_forbidden_preview1_module(module) {
            return "FAIL: nyar.emitter.wasm.host.wasi_cm: wasi_snapshot_preview1 is forbidden; use wasip2 or wasip3"
        }
        i = i + 1
    }
    return ""
}

# Adapt + version declared imports for the selected preview (omit None p3 gaps).
micro wasi_cm_adapt_imports(imports: [WasiCmHostImport], preview: WasiPreview) -> [WasiImportTarget] {
    let mut out: [WasiImportTarget] = []
    let mut i: usize = 0
    while i < imports.length() {
        let raw: WasiCmHostImport = imports⁅i⁆
        match wasi_adapt_and_version_import(raw.module, raw.field, preview) {
            case Some(adapted): {
                out = push(out, adapted)
            }
            case None: {
                # Honest omit — no p3 twin yet (fail-closed later when cabi requires it).
            }
        }
        i = i + 1
    }
    return out
}

# Component command export list (full names) — Rust `component_command_exports`.
micro wasi_cm_command_export_names(preview: WasiPreview) -> [utf8] {
    let mut names: [utf8] = []
    names = push(names, wasi_start_export_name(preview))
    names = push(names, "run")
    names = push(names, "cabi_post_run")
    names = push(names, "memory")
    names = push(names, "cabi_realloc")
    names = push(names, "_initialize")
    names = push(names, wasi_cli_run_export_name_for(preview))
    return names
}

micro lower_executable_to_wasi_cm(module: ExecutableModule, preview: WasiPreview) -> WasmHostArtifact {
    return lower_executable_to_wasi_cm_with_imports(module, preview, empty_wasi_cm_host_imports())
}

micro lower_executable_to_wasi_cm_with_imports(module: ExecutableModule, preview: WasiPreview, imports: [WasiCmHostImport]) -> WasmHostArtifact {
    if module.functions.length() == 0 {
        return WasmHostArtifact {
            kind: "wasi-component",
            export_name: wasi_cli_run_export_name_for(preview),
            preview: wasi_preview_name(preview),
            note: "",
            ok: false,
            error: "FAIL: nyar.emitter.wasm.host.wasi_cm: empty ExecutableModule (need Executable MIR; body_source bypass rejected)"
        }
    }
    let preview1_err: utf8 = wasi_cm_validate_imports(imports)
    if preview1_err.length() > 0 {
        return WasmHostArtifact {
            kind: "wasi-component",
            export_name: wasi_cli_run_export_name_for(preview),
            preview: wasi_preview_name(preview),
            note: "",
            ok: false,
            error: preview1_err
        }
    }
    let adapted: [WasiImportTarget] = wasi_cm_adapt_imports(imports, preview)
    let cli_run: utf8 = wasi_cli_run_export_name_for(preview)
    let wit_stub: utf8 = build_component_wit_document_for(module.name, preview)
    let exports: [utf8] = wasi_cm_command_export_names(preview)
    let mut note: utf8 = "OK-STUB: wasi-cm preview="
    note = note + wasi_preview_name(preview)
    note = note + " start="
    note = note + wasi_start_export_name(preview)
    note = note + " cli_run="
    note = note + cli_run
    note = note + " export_count="
    if exports.length() == 7 {
        note = note + "7"
    }
    else {
        note = note + "n"
    }
    note = note + " imports="
    if adapted.length() == 0 {
        note = note + "0"
    }
    else {
        note = note + "n"
    }
    note = note + " wit="
    note = note + wit_stub.slice(0, 12)
    note = note + "... (core/component bytes not emitted yet; paths=UTF-8 bytes)"
    return WasmHostArtifact {
        kind: "wasi-component",
        export_name: cli_run,
        preview: wasi_preview_name(preview),
        note: note,
        ok: true,
        error: ""
    }
}

# Rust-named entry points (Fragment → ExecutableModule isomorphism).
micro lower_fragment_to_wasi_cm_module(module: ExecutableModule) -> WasmHostArtifact {
    return lower_executable_to_wasi_cm(module, Preview2)
}

micro lower_fragment_to_wasi_cm_module_for(module: ExecutableModule, preview: WasiPreview) -> WasmHostArtifact {
    return lower_executable_to_wasi_cm(module, preview)
}
