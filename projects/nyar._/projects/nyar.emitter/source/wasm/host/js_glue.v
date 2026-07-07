namespace nyar.emitter.wasm.host;

using nyar.emitter.executable;
using nyar.emitter.wasi;

# Host shells — isomorphic to Rust `backends/wasm/host/{js_glue,wasi_cm}`.
# Shared artifact shape for JS glue / WASI CM packaging.
#
# env.utf8_* index contract (Node JS glue / `wasm_js_glue` launcher):
# - Storage may be a JS `string` (UTF-16 code units).
# - `utf8_length` / `utf8_slice` / `utf8_index_of` use Unicode **scalars**
#   (`[...s]`), matching std `Utf8Text` — never `s.length` / `s.substring` alone.
# - `LoadConstString.utf8_source` stays language UTF-8 until `env.const_utf8`
#   interns a host handle; do not treat the handle index as a UTF-16 offset.
# - WASI paths that pass raw UTF-8 bytes stay byte-oriented at the WASI boundary.

structure WasmHostArtifact {
    kind: utf8
    export_name: utf8
    preview: utf8
    note: utf8
    ok: bool
    error: utf8
}

# Node / JS-glue host utf8 method import fields — Rust `NODE_UTF8_HOST_IMPORT_FIELDS`.
micro js_glue_utf8_host_import_fields() -> [utf8] {
    let mut fields: [utf8] = []
    fields = push(fields, "utf8_trim")
    fields = push(fields, "utf8_length")
    fields = push(fields, "utf8_concat")
    fields = push(fields, "utf8_starts_with")
    fields = push(fields, "utf8_ends_with")
    fields = push(fields, "utf8_contains")
    fields = push(fields, "utf8_equals")
    fields = push(fields, "utf8_replace")
    fields = push(fields, "utf8_index_of")
    fields = push(fields, "utf8_slice")
    fields = push(fields, "utf8_to_lower")
    fields = push(fields, "utf8_to_upper")
    return fields
}

# Map language method short-name → env.utf8_* (Rust `utf8_host_import_field_for_method`).
micro js_glue_utf8_host_field_for_method(method: utf8) -> utf8 {
    if method == "trim" {
        return "utf8_trim"
    }
    if method == "length" {
        return "utf8_length"
    }
    if method == "concat" {
        return "utf8_concat"
    }
    if method == "starts_with" {
        return "utf8_starts_with"
    }
    if method == "ends_with" {
        return "utf8_ends_with"
    }
    if method == "contains" {
        return "utf8_contains"
    }
    if method == "equals" {
        return "utf8_equals"
    }
    if method == "replace" {
        return "utf8_replace"
    }
    if method == "index_of" {
        return "utf8_index_of"
    }
    if method == "slice" {
        return "utf8_slice"
    }
    if method == "to_lower" {
        return "utf8_to_lower"
    }
    if method == "to_upper" {
        return "utf8_to_upper"
    }
    return ""
}

structure JsGlueHostPlan {
    export_name: utf8
    import_fields: [utf8]
    include_const_utf8: bool
    utf8_literal_count: u32
    encoding_note: utf8
}

micro build_js_glue_host_plan(module: ExecutableModule) -> JsGlueHostPlan {
    let mut has_string: bool = false
    let mut literal_count: u32 = 0
    let mut fi: usize = 0
    while fi < module.functions.length() {
        let func: ExecutableFunction = module.functions⁅fi⁆
        let mut bi: usize = 0
        while bi < func.blocks.length() {
            let block: ExecutableBlock = func.blocks⁅bi⁆
            let mut ii: usize = 0
            while ii < block.instructions.length() {
                match block.instructions⁅ii⁆.kind {
                    case LoadConstString { utf8_source }: {
                        has_string = true
                        literal_count = literal_count + 1
                    }
                    else: { }
                }
                ii = ii + 1
            }
            bi = bi + 1
        }
        fi = fi + 1
    }
    return JsGlueHostPlan {
        export_name: "main",
        import_fields: js_glue_utf8_host_import_fields(),
        include_const_utf8: has_string,
        utf8_literal_count: literal_count,
        encoding_note: "utf8_* indices = Unicode scalars ([...s]); host string storage is UTF-16; IR strings remain UTF-8 until const_utf8"
    }
}

micro lower_executable_to_js_glue(module: ExecutableModule) -> WasmHostArtifact {
    if module.functions.length() == 0 {
        return WasmHostArtifact {
            kind: "wasm-js-glue",
            export_name: "main",
            preview: "",
            note: "",
            ok: false,
            error: "FAIL: nyar.emitter.wasm.host.js_glue: empty ExecutableModule (need Executable MIR; body_source bypass rejected)"
        }
    }
    let plan: JsGlueHostPlan = build_js_glue_host_plan(module)
    let mut note: utf8 = plan.encoding_note
    note = note + "; imports="
    if plan.include_const_utf8 {
        note = note + "const_utf8+"
    }
    note = note + "utf8_*"
    return WasmHostArtifact {
        kind: "wasm-js-glue",
        export_name: plan.export_name,
        preview: "",
        note: note,
        ok: true,
        error: ""
    }
}
