namespace nyar.emitter.wasi;

# Preview2 / Preview3 import adapt layer — isomorphic to Rust
# `wasi_adapt_import_for_preview` / `wasi_versioned_import_module_for`.
#
# p3-first: Preview3 remaps legacy Preview2 names; they are not a long-term guest ABI.
# Paths / WIT module strings are UTF-8 byte-oriented at the WASI boundary (ASCII WIT
# ids: scalar index ≡ byte index). Never flatten through Utf16Text / host String length.

structure WasiImportTarget {
    module: utf8
    field: utf8
}

# Strip `@version` suffix from a WIT import module (UTF-8 / ASCII).
micro wasi_module_bare(module: utf8) -> utf8 {
    let at: i32 = module.index_of("@")
    if at < 0 {
        return module
    }
    return module.slice(0, at)
}

# Attach preview package version to unversioned `wasi:*` import modules.
micro wasi_versioned_import_module_for(module: utf8, preview: WasiPreview) -> utf8 {
    if module.contains("@") || !module.starts_with("wasi:") {
        return module
    }
    let mut out: utf8 = module
    out = out + "@"
    out = out + wasi_package_version(preview)
    return out
}

micro wasi_versioned_import_module(module: utf8) -> utf8 {
    return wasi_versioned_import_module_for(module, Preview2)
}

# First-occurrence ASCII substring replace (avoid host `utf8.replace` arch stubs).
micro wasi_utf8_replacen(hay: utf8, old: utf8, new_value: utf8) -> utf8 {
    let i: i32 = hay.index_of(old)
    if i < 0 {
        return hay
    }
    let old_len: i32 = old.length()
    let mut out: utf8 = hay.slice(0, i)
    out = out + new_value
    let rest_start: i32 = i + old_len
    let rest_len: i32 = hay.length() - rest_start
    if rest_len > 0 {
        out = out + hay.slice(rest_start, rest_len)
    }
    return out
}

# `wasi_snapshot_preview1` is strictly forbidden (fail-closed at CM boundary).
micro wasi_is_forbidden_preview1_module(module: utf8) -> bool {
    let bare: utf8 = wasi_module_bare(module)
    return bare == "wasi_snapshot_preview1"
}

# Adapt `(module, field)` to the selected package train.
# Preview3 remaps:
# - clocks: `resolution` → `get-resolution`; `wall-clock` → `system-clock`
# - console: `wasi:io/streams#blocking-write-and-flush` → `wasi:cli/stdout#write-via-stream`
# Returns None when an import has no honest p3 equivalent.
micro wasi_adapt_import_for_preview(module: utf8, field: utf8, preview: WasiPreview) -> Option<WasiImportTarget> {
    match preview {
        case Preview2: {
            return Some(WasiImportTarget {
                module: module,
                field: field
            })
        }
        case Preview3: {
            let bare: utf8 = wasi_module_bare(module)
            if bare == "wasi:io/streams" && field == "blocking-write-and-flush" {
                return Some(WasiImportTarget {
                    module: "wasi:cli/stdout",
                    field: "write-via-stream"
                })
            }
            if bare.starts_with("wasi:io/") {
                return None
            }
            let mut adapted_module: utf8 = bare
            if bare == "wasi:clocks/wall-clock" || bare.starts_with("wasi:clocks/wall-clock@") {
                adapted_module = wasi_utf8_replacen(bare, "wall-clock", "system-clock")
            }
            let mut adapted_field: utf8 = field
            if field == "resolution" {
                if adapted_module.contains("monotonic-clock") || adapted_module.contains("system-clock") {
                    adapted_field = "get-resolution"
                }
            }
            return Some(WasiImportTarget {
                module: adapted_module,
                field: adapted_field
            })
        }
    }
}

# Adapt then stamp preview version onto `wasi:*` modules (host-import collection path).
micro wasi_adapt_and_version_import(module: utf8, field: utf8, preview: WasiPreview) -> Option<WasiImportTarget> {
    match wasi_adapt_import_for_preview(module, field, preview) {
        case None: {
            return None
        }
        case Some(target): {
            return Some(WasiImportTarget {
                module: wasi_versioned_import_module_for(target.module, preview),
                field: target.field
            })
        }
    }
}
