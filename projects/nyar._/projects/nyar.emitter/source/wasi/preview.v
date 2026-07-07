namespace nyar.emitter.wasi;

# WASI package-train adapters — isomorphic to Rust `nyar_backend_wasi::WasiPreview`
# (`backend/wasi/component.rs`).
# wasip2 = Preview2 component model train; wasip3 = Preview3 (`-S p3` / wasip3 target).
#
# Encoding: WIT ids and filesystem paths at the WASI boundary are **UTF-8 bytes**.
# Do not apply CLR `String.get_Length` / JS `.length` (UTF-16 code units). Language
# `utf8` scalar APIs are fine for ASCII WIT package ids (byte ≡ scalar).

unite WasiPreview {
    Preview2
    Preview3
}

# WASI Preview2 package version (wasmtime command-world linking).
micro wasi_preview2_version() -> utf8 {
    return "0.2.12"
}

# WASI 0.3 (`wasip3`) package version (wasmtime `-S p3`).
micro wasi_preview3_version() -> utf8 {
    return "0.3.0"
}

micro wasi_preview_name(p: WasiPreview) -> utf8 {
    match p {
        case Preview2: {
            return "wasip2"
        }
        case Preview3: {
            return "wasip3"
        }
    }
}

micro wasi_package_version(p: WasiPreview) -> utf8 {
    match p {
        case Preview2: {
            return wasi_preview2_version()
        }
        case Preview3: {
            return wasi_preview3_version()
        }
    }
}

# Target-string dispatch (`wasip3` / bare `wasi` / `wasip2`).
micro wasi_preview_from_target(target: utf8) -> WasiPreview {
    if target.contains("wasip3") || target.contains("p3") {
        return Preview3
    }
    return Preview2
}

# Host-flavor token (`wasi-component-model` / `…-p3`) — Rust `WasiPreview::from_host_flavor`.
micro wasi_preview_from_host_flavor(host_flavor: utf8) -> WasiPreview {
    if host_flavor.contains("wasip3") || host_flavor.ends_with("-p3") || host_flavor.contains("component-model-p3") {
        return Preview3
    }
    return Preview2
}

# Core wasm `_start` export shared by wasip2/wasip3 CM shells.
micro wasi_start_export_name(p: WasiPreview) -> utf8 {
    return "_start"
}

# Full command-world export: `wasi:cli/run@{version}#run` (never a bare `run`).
micro wasi_cli_run_export_name_for(preview: WasiPreview) -> utf8 {
    let mut name: utf8 = "wasi:cli/run@"
    name = name + wasi_package_version(preview)
    name = name + "#run"
    return name
}

micro wasi_cli_run_export_name() -> utf8 {
    return wasi_cli_run_export_name_for(Preview2)
}
