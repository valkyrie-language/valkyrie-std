namespace nyar.emitter.wasi;

# WIT command-world text stubs — isomorphic to Rust `backend/wasi/component.rs`
# (`build_component_wit_document_for`). Text-level mirror only; binary component
# packaging still lives on the wasm CM host path (`wasm/host/wasi_cm`).
#
# Do not depend on a fictional `std.data.text.v` package — Valkyrie language AST is
# `std.data.text.valkyrie`; WIT models (when wired) are `std.data.text.wit`.

# Sanitize a WIT package segment: keep [0-9a-zA-Z-], else `-`; collapse `--`.
# Callers typically pass already-lowercase artifact stems (Rust lowercases).
micro wasi_sanitize_wit_segment(raw: utf8) -> utf8 {
    let mut sanitized: utf8 = ""
    let mut i: i32 = 0
    let n: i32 = raw.length()
    while i < n {
        let ch: utf8 = raw.slice(i, 1)
        if ch == "_" || ch == "." || ch == "/" || ch == ":" || ch == " " {
            sanitized = sanitized + "-"
        }
        else {
            sanitized = sanitized + ch
        }
        i = i + 1
    }
    while sanitized.contains("--") {
        sanitized = wasi_utf8_replacen(sanitized, "--", "-")
    }
    while sanitized.starts_with("-") {
        let rest: i32 = sanitized.length() - 1
        if rest <= 0 {
            return "generated"
        }
        sanitized = sanitized.slice(1, rest)
    }
    while sanitized.ends_with("-") {
        let rest2: i32 = sanitized.length() - 1
        if rest2 <= 0 {
            return "generated"
        }
        sanitized = sanitized.slice(0, rest2)
    }
    if sanitized.length() == 0 {
        return "generated"
    }
    return sanitized
}

# Minimal command-world WIT (no local/external imports yet) — Preview2/Preview3 version stamp.
micro build_component_wit_document_for(artifact_name: utf8, preview: WasiPreview) -> utf8 {
    let version: utf8 = wasi_package_version(preview)
    let segment: utf8 = wasi_sanitize_wit_segment(artifact_name)
    let mut wit: utf8 = "package nyar:"
    wit = wit + segment
    wit = wit + "@0.1.0;\n\n"
    wit = wit + "world command {\n"
    wit = wit + "  export wasi:cli/run@"
    wit = wit + version
    wit = wit + ";\n"
    wit = wit + "}\n"
    return wit
}

micro build_component_wit_document(artifact_name: utf8) -> utf8 {
    return build_component_wit_document_for(artifact_name, Preview2)
}
