namespace nyar.language.valkyrie;

using std.io;

structure ParsedStructField {
    name: utf8
    type_text: utf8
}

structure ParsedStruct {
    name: utf8
    fields: [ParsedStructField]
}

# CLR unite layout (aligned with Rust CLR): class with `int32 tag` + `object payload`.
structure ParsedUniteVariant {
    name: utf8
    tag: i32
    payload_type: utf8
}

structure ParsedUnite {
    name: utf8
    variants: [ParsedUniteVariant]
}

micro empty_parsed_struct() -> ParsedStruct {
    return ParsedStruct {
        name: "",
        fields: []
    }
}

# `castclass` / `isinst` type token — arrays of classes need `class Foo[]`.
micro msil_cast_type(ty: utf8) -> utf8 {
    let t: utf8 = ty.trim()
    if t.length() == 0 || t == "string" || t == "object" || t == "int32" || t == "bool" || t == "uint8" {
        return t
    }
    if t == "string[]" || t == "object[]" || t == "int32[]" || t == "uint8[]" {
        return t
    }
    if t.ends_with("[]") {
        let elem: utf8 = t.slice(0, t.length() - 2).trim()
        if elem.starts_with("class ") {
            return t
        }
        return msil_class_array_ty(elem)
    }
    return t
}

# Quote IL-reserved / ambiguous simple names so fields, params, and locals assemble.
micro msil_id(name: utf8) -> utf8 {
    let n: utf8 = name.trim()
    if n.length() == 0 {
        return n
    }
    # Space-delimited keyword table — avoid a giant `||` chain (seed stack overflow).
    let keys: utf8 = " error value assembly event sealed class object string bool public private family method field property void int32 default instance static managed cil nested extends implements self package request filter to at as type char module namespace try catch handler enum serializable abstract interface explicit sequential auto ansi beforefieldinit specialname rtspecialname hidebysig newslot virtual final native unmanaged retval marshal initonly literal notserialized "
    if keys.contains(" " + n + " ") {
        let mut qn: utf8 = "\u{27}"
        qn = qn + n
        qn = qn + "\u{27}"
        return qn
    }
    return n
}

micro find_struct_def(structs: [ParsedStruct], name: utf8) -> ParsedStruct {
    let mut i: usize = 0
    while i < structs.length() {
        if structs⁅i⁆.name == name {
            return structs⁅i⁆
        }
        i = i + 1
    }
    return empty_parsed_struct()
}

micro find_struct_field(st: ParsedStruct, field: utf8) -> ParsedStructField {
    let mut i: usize = 0
    while i < st.fields.length() {
        if st.fields⁅i⁆.name == field {
            return st.fields⁅i⁆
        }
        i = i + 1
    }
    return ParsedStructField {
        name: "",
        type_text: ""
    }
}

micro nominal_type_name(type_text: utf8) -> utf8 {
    let t: utf8 = type_text.trim()
    let lt: i32 = t.index_of("<")
    if lt > 0 {
        return t.slice(0, lt).trim()
    }
    return t
}

# `"class " + name` collapses under v1 body→MSIL — build stepwise.
micro msil_class_ty(name: utf8) -> utf8 {
    let mut t: utf8 = "class"
    t = t + " "
    t = t + name
    return t
}

micro msil_class_array_ty(elem: utf8) -> utf8 {
    let mut t: utf8 = msil_class_ty(elem)
    t = t + "[]"
    return t
}

micro apply_type_argument(type_text: utf8) -> utf8 {
    let t: utf8 = type_text.trim()
    let lt: i32 = t.index_of("<")
    if lt < 0 || !t.ends_with(">") {
        return ""
    }
    return t.slice(lt + 1, t.length() - lt - 2).trim()
}

micro find_unite_def(unites: [ParsedUnite], name: utf8) -> ParsedUnite {
    let n: utf8 = nominal_type_name(name)
    let mut i: usize = 0
    while i < unites.length() {
        if unites⁅i⁆.name == n {
            return unites⁅i⁆
        }
        i = i + 1
    }
    return ParsedUnite {
        name: "",
        variants: []
    }
}

micro find_unite_variant(u: ParsedUnite, variant: utf8) -> ParsedUniteVariant {
    let mut i: usize = 0
    while i < u.variants.length() {
        if u.variants⁅i⁆.name == variant {
            return u.variants⁅i⁆
        }
        i = i + 1
    }
    return ParsedUniteVariant {
        name: "",
        tag: -1,
        payload_type: ""
    }
}

micro clr_type_for_annotation_with_defs(type_text: utf8, structs: [ParsedStruct], unites: [ParsedUnite]) -> utf8 {
    # Isomorphic to Rust `nyar_type_to_msil` + AggregateLayoutPlan membership:
    # language primitives → MSIL ABI; nominals only when present in struct/unite tables.
    # No per-type-name whitelists (VonValue / List→ArrayList / *Result suffix, …).
    let t: utf8 = type_text.trim()
    # T? → nullable class ref (None = null).
    if t.ends_with("?") && t.length() > 1 {
        let inner: utf8 = t.slice(0, t.length() - 1).trim()
        let inner_clr: utf8 = clr_type_for_annotation_with_defs(inner, structs, unites)
        if inner_clr.length() > 0 {
            return inner_clr
        }
    }
    if t == "usize" || t == "i32" || t == "i64" || t == "int32" || t == "bool" {
        return "int32"
    }
    if t == "utf8" || t == "string" || t == "utf16" {
        return "string"
    }
    if t == "[utf8]" || t == "[string]" {
        return "string[]"
    }
    if t == "[u8]" || t == "[byte]" {
        return "uint8[]"
    }
    if t.starts_with("[") && t.ends_with("]") {
        let inner: utf8 = t.slice(1, t.length() - 2).trim()
        if inner == "utf8" || inner == "string" {
            return "string[]"
        }
        if inner == "u8" || inner == "byte" {
            return "uint8[]"
        }
        if inner == "usize" || inner == "i32" || inner == "i64" || inner == "int32" || inner == "bool" {
            return "int32[]"
        }
        if inner == "u16" || inner == "i16" || inner == "i8" || inner == "u32" || inner == "char" {
            return "int32[]"
        }
        if inner == "u64" || inner == "i64" {
            return "int64[]"
        }
        if inner == "f32" {
            return "float32[]"
        }
        if inner == "f64" {
            return "float64[]"
        }
        # Unsubstituted type parameter — CLR ABI erase (Rust Named("T") → Object element).
        if inner == "T" || inner.length() == 1 {
            return "object[]"
        }
        let inner_clr: utf8 = clr_type_for_annotation_with_defs(inner, structs, unites)
        if inner_clr.starts_with("class ") {
            let en: utf8 = inner_clr.slice(6, inner_clr.length() - 6).trim()
            return msil_class_array_ty(en)
        }
        if inner_clr == "string" {
            return "string[]"
        }
        if inner_clr == "int32" {
            return "int32[]"
        }
        if inner_clr == "uint8" {
            return "uint8[]"
        }
        if inner_clr == "object" {
            return "object[]"
        }
        # Unknown element — fail-closed (empty); callers must not invent class names.
        return ""
    }
    # Apply erase: Foo<T> → Foo when Foo is in the fragment type tables.
    let nominal: utf8 = nominal_type_name(t)
    if find_struct_def(structs, nominal).name.length() > 0 {
        return msil_class_ty(nominal)
    }
    if find_unite_def(unites, nominal).name.length() > 0 {
        return msil_class_ty(nominal)
    }
    if find_struct_def(structs, t).name.length() > 0 {
        return msil_class_ty(t)
    }
    if find_unite_def(unites, t).name.length() > 0 {
        return msil_class_ty(t)
    }
    return ""
}

micro clr_type_for_annotation_with_structs(type_text: utf8, structs: [ParsedStruct]) -> utf8 {
    return clr_type_for_annotation_with_defs(type_text, structs, [])
}

micro msil_field_type(type_text: utf8, structs: [ParsedStruct]) -> utf8 {
    return msil_field_type_with_defs(type_text, structs, [])
}

micro msil_field_type_with_defs(type_text: utf8, structs: [ParsedStruct], unites: [ParsedUnite]) -> utf8 {
    let raw: utf8 = type_text.trim()
    # Function / closure field types → object (ilasm cannot spell `micro(T) -> …`).
    if raw.contains("->") || raw.contains("micro(") || raw.starts_with("micro ") {
        return "object"
    }
    let clr: utf8 = clr_type_for_annotation_with_defs(type_text, structs, unites)
    if clr.length() == 0 {
        return "object"
    }
    if clr.contains("->") || (clr.contains("(") && !clr.ends_with("[]")) {
        return "object"
    }
    if clr.starts_with("class ") {
        let n: utf8 = clr.slice(6, clr.length() - 6).trim()
        if n.contains("(") || n.contains(" ") || n.contains(">") || n.contains("<") || n.contains("-") {
            return "object"
        }
    }
    return clr
}

micro is_clr_keyword_type_name(name: utf8) -> bool {
    if name == "bool" || name == "int32" || name == "int64" || name == "string" || name == "object" || name == "void" {
        return true
    }
    if name == "i8" || name == "i16" || name == "i32" || name == "i64" || name == "i128" || name == "isize" {
        return true
    }
    if name == "u8" || name == "u16" || name == "u32" || name == "u64" || name == "u128" || name == "usize" {
        return true
    }
    if name == "f32" || name == "f64" || name == "f128" || name == "unit" || name == "char" || name == "text" {
        return true
    }
    if name == "utf8" || name == "utf16" || name == "any" || name == "null" || name == "`any`" || name == "`null`" {
        return true
    }
    return false
}

micro struct_is_emitable(st: ParsedStruct) -> bool {
    if st.name.length() == 0 || is_clr_keyword_type_name(st.name) {
        return false
    }
    if st.name.contains("(") || st.name.contains(" ") || st.name.contains("<") || st.name.contains(">") {
        return false
    }
    # Reject operator/trait pseudo-structures scraped from std sources.
    let mut i: usize = 0
    while i < st.fields.length() {
        let fname: utf8 = st.fields⁅i⁆.name
        if fname.contains("(") || fname.contains("`") || fname.starts_with("infix") || fname.starts_with("prefix") {
            return false
        }
        if fname.starts_with("let ") || fname.starts_with("private ") || fname.starts_with("micro ") {
            return false
        }
        # Keep structs with function-typed fields (emit as object); reject only junk names.
        i = i + 1
    }
    return true
}

micro filter_emitable_structs(structs: [ParsedStruct]) -> [ParsedStruct] {
    let mut out: [ParsedStruct] = []
    let mut i: usize = 0
    while i < structs.length() {
        if struct_is_emitable(structs⁅i⁆) {
            out = push(out, structs⁅i⁆)
        }
        i = i + 1
    }
    return out
}

micro emit_struct_classes(structs: [ParsedStruct]) -> utf8 {
    let mut parts: [utf8] = []
    let mut seen: [utf8] = []
    let mut si: usize = 0
    while si < structs.length() {
        let st: ParsedStruct = structs⁅si⁆
        if !struct_is_emitable(st) {
            si = si + 1
            continue
        }
        let sname: utf8 = st.name.trim()
        if sname.length() == 0 || contains_text(seen, sname) {
            si = si + 1
            continue
        }
        seen = push(seen, sname)
        parts = push(parts, ".class public auto ansi beforefieldinit " + sname + " extends [mscorlib]System.Object\n")
        parts = push(parts, "{\n")
        let mut fi: usize = 0
        while fi < st.fields.length() {
            let field: ParsedStructField = st.fields⁅fi⁆
            let ft: utf8 = msil_field_type(field.type_text, structs)
            parts = push(parts, "    .field public " + ft + " " + msil_id(field.name) + "\n")
            fi = fi + 1
        }
        parts = push(parts, "    .method public hidebysig specialname rtspecialname instance void .ctor() cil managed\n")
        parts = push(parts, "    {\n")
        parts = push(parts, "        .maxstack 8\n")
        parts = push(parts, "        ldarg.0\n")
        parts = push(parts, "        call instance void [mscorlib]System.Object::.ctor()\n")
        parts = push(parts, "        ret\n")
        parts = push(parts, "    }\n")
        parts = push(parts, "}\n\n")
        si = si + 1
    }
    return join_msil_parts(parts)
}

# Build a default instance of `class Name` with nested structs / empty string[].
micro emit_default_struct_new(struct_name: utf8, structs: [ParsedStruct]) -> BodyLowerResult {
    let st: ParsedStruct = find_struct_def(structs, struct_name)
    if st.name.length() == 0 {
        return body_lower_fail("未知结构：" + struct_name)
    }
    let mut parts: [utf8] = []
    parts = push(parts, "        newobj instance void " + struct_name + "::.ctor()\n")
    let mut fi: usize = 0
    while fi < st.fields.length() {
        let field: ParsedStructField = st.fields⁅fi⁆
        let ft: utf8 = field.type_text.trim()
        parts = push(parts, "        dup\n")
        let nested: ParsedStruct = find_struct_def(structs, ft)
        if nested.name.length() > 0 {
            let nested_r: BodyLowerResult = emit_default_struct_new(ft, structs)
            if !nested_r.ok {
                return nested_r
            }
            parts = push(parts, nested_r.instructions)
            parts = push(parts, "        stfld class " + ft + " " + struct_name + "::" + msil_id(field.name) + "\n")
        }
        else if ft == "[utf8]" || ft == "[string]" {
            parts = push(parts, "        ldc.i4.0\n")
            parts = push(parts, "        newarr [mscorlib]System.String\n")
            parts = push(parts, "        stfld string[] " + struct_name + "::" + msil_id(field.name) + "\n")
        }
        else if ft == "utf8" || ft == "string" {
            parts = push(parts, "        ldstr " + dq() + dq() + "\n")
            parts = push(parts, "        stfld string " + struct_name + "::" + msil_id(field.name) + "\n")
        }
        else if ft == "bool" || ft == "i32" || ft == "i64" || ft == "usize" {
            parts = push(parts, "        ldc.i4.0\n")
            parts = push(parts, "        stfld int32 " + struct_name + "::" + msil_id(field.name) + "\n")
        }
        else {
            return body_lower_fail("结构默认值不支持字段类型：" + struct_name + "." + field.name + ": " + ft)
        }
        fi = fi + 1
    }
    return body_lower_ok(join_msil_parts(parts), "")
}

micro parse_structures_from_source(source: utf8) -> [ParsedStruct] {
    let mut structs: [ParsedStruct] = []
    let lines: [utf8] = source.split("\n")
    let line_count: usize = lines.length()
    let mut i: usize = 0
    while i < line_count {
        let line: utf8 = trim_text(lines⁅i⁆)
        let mut is_type_block: bool = false
        let mut rest: utf8 = ""
        if line.starts_with("structure ") {
            is_type_block = true
            rest = line.slice(10, line.length() - 10).trim()
        }
        else if line.starts_with("class ") {
            is_type_block = true
            rest = line.slice(6, line.length() - 6).trim()
        }
        if is_type_block {
            let name_end: i32 = rest.index_of(" ")
            let brace_on: i32 = rest.index_of("{")
            let mut name: utf8 = rest
            if brace_on >= 0 {
                name = rest.slice(0, brace_on).trim()
            }
            else if name_end >= 0 {
                name = rest.slice(0, name_end).trim()
            }
            # Search `<` in the already-trimmed name (not rest) — avoids OOR when brace precedes generics.
            let gen_in_name: i32 = name.index_of("<")
            if gen_in_name >= 0 {
                name = name.slice(0, gen_in_name).trim()
            }
            let mut fields: [ParsedStructField] = []
            let mut depth: i32 = 0
            if line.contains("{") {
                depth = 1
            }
            i = i + 1
            while i < line_count {
                let fl: utf8 = trim_text(lines⁅i⁆)
                if fl.contains("{") {
                    depth = depth + 1
                }
                if fl.contains("}") {
                    depth = depth - 1
                    if depth <= 0 {
                        break
                    }
                }
                let colon: i32 = fl.index_of(":")
                if colon > 0 && !fl.starts_with("//") && !fl.starts_with("structure ") && !fl.starts_with("class ") && !fl.starts_with("micro ") && !fl.starts_with("imply ") {
                    let mut fname: utf8 = fl.slice(0, colon).trim()
                    if fname.starts_with("[get]") {
                        fname = fname.slice(5, fname.length() - 5).trim()
                    }
                    if fname.starts_with("[set]") {
                        fname = fname.slice(5, fname.length() - 5).trim()
                    }
                    # Prefer `len - (colon + 1)` — chained `a - b - c` still mis-associates in int emit.
                    let after_colon: i32 = colon + 1
                    let mut fty: utf8 = fl.slice(after_colon, fl.length() - after_colon).trim()
                    if fty.ends_with(",") {
                        fty = fty.slice(0, fty.length() - 1).trim()
                    }
                    if fname.length() > 0 && fty.length() > 0 && !fname.contains("(") {
                        fields = push(fields, ParsedStructField {
                            name: fname,
                            type_text: fty
                        })
                    }
                }
                i = i + 1
            }
            if name.length() > 0 {
                structs = push(structs, ParsedStruct {
                    name: name,
                    fields: fields
                })
            }
        }
        i = i + 1
    }
    return structs
}

micro digit_value(ch: utf8) -> i32 {
    if ch == "0" {
        return 0
    }
    if ch == "1" {
        return 1
    }
    if ch == "2" {
        return 2
    }
    if ch == "3" {
        return 3
    }
    if ch == "4" {
        return 4
    }
    if ch == "5" {
        return 5
    }
    if ch == "6" {
        return 6
    }
    if ch == "7" {
        return 7
    }
    if ch == "8" {
        return 8
    }
    if ch == "9" {
        return 9
    }
    return -1
}

micro parse_tag_attribute(line: utf8) -> i32 {
    let marker: utf8 = "[tag("
    let at: i32 = line.index_of(marker)
    if at < 0 {
        return -1
    }
    let start: i32 = at + marker.length()
    let count: i32 = line.length() - start
    let after: utf8 = line.slice(start, count).trim()
    let close: i32 = after.index_of(")")
    if close <= 0 {
        return -1
    }
    let digits: utf8 = after.slice(0, close).trim()
    let mut n: i32 = 0
    let mut i: i32 = 0
    if digits.length() == 0 {
        return -1
    }
    while i < digits.length() {
        let d: i32 = digit_value(digits.slice(i, 1))
        if d < 0 {
            return -1
        }
        n = n * 10 + d
        i = i + 1
    }
    return n
}

micro parse_unites_from_source(source: utf8) -> [ParsedUnite] {
    let mut unites: [ParsedUnite] = []
    let lines: [utf8] = source.split("\n")
    let line_count: usize = lines.length()
    let mut i: usize = 0
    while i < line_count {
        let line: utf8 = trim_text(lines⁅i⁆)
        if line.starts_with("unite ") {
            let rest: utf8 = line.slice(6, line.length() - 6).trim()
            let brace_on: i32 = rest.index_of("{")
            let gen_on: i32 = rest.index_of("<")
            let mut name: utf8 = rest
            if brace_on >= 0 {
                name = rest.slice(0, brace_on).trim()
            }
            if gen_on >= 0 && (brace_on < 0 || gen_on < brace_on) {
                name = name.slice(0, gen_on).trim()
            }
            let sp: i32 = name.index_of(" ")
            if sp >= 0 {
                name = name.slice(0, sp).trim()
            }
            let mut variants: [ParsedUniteVariant] = []
            let mut depth: i32 = 0
            let mut pending_tag: i32 = -1
            if line.contains("{") {
                depth = 1
            }
            i = i + 1
            while i < line_count {
                let fl: utf8 = trim_text(lines⁅i⁆)
                if fl.starts_with("[tag(") {
                    pending_tag = parse_tag_attribute(fl)
                    i = i + 1
                    continue
                }
                if fl.contains("{") {
                    depth = depth + 1
                }
                if fl.contains("}") {
                    depth = depth - 1
                    if depth <= 0 {
                        break
                    }
                }
                # Variant: `Fine { value: T }` or bare `Empty`.
                let brace: i32 = fl.index_of("{")
                if brace > 0 && !fl.starts_with("//") && !fl.starts_with("[") {
                    let vname: utf8 = fl.slice(0, brace).trim()
                    if vname.length() > 0 && !vname.contains(":") && !vname.contains(" ") {
                        let mut payload_ty: utf8 = ""
                        let inner_start: i32 = brace + 1
                        let inner_close: i32 = fl.index_of("}")
                        if inner_close > inner_start {
                            let inner: utf8 = fl.slice(inner_start, inner_close - inner_start).trim()
                            let colon: i32 = inner.index_of(":")
                            if colon > 0 {
                                payload_ty = inner.slice(colon + 1, inner.length() - colon - 1).trim()
                            }
                        }
                        let mut tag: i32 = pending_tag
                        if tag < 0 {
                            tag = variants.length() as i32
                        }
                        variants = push(variants, ParsedUniteVariant {
                            name: vname,
                            tag: tag,
                            payload_type: payload_ty
                        })
                        pending_tag = -1
                    }
                }
                else if brace < 0 && fl.length() > 0 && !fl.starts_with("//") && !fl.starts_with("[") && !fl.starts_with("}") && !fl.contains(":") && !fl.contains(" ") && !fl.contains("(") {
                    # Bare nullary variant: `Empty`
                    let mut tag: i32 = pending_tag
                    if tag < 0 {
                        tag = variants.length() as i32
                    }
                    variants = push(variants, ParsedUniteVariant {
                        name: fl,
                        tag: tag,
                        payload_type: ""
                    })
                    pending_tag = -1
                }
                i = i + 1
            }
            if name.length() > 0 && variants.length() > 0 {
                unites = push(unites, ParsedUnite {
                    name: name,
                    variants: variants
                })
            }
        }
        i = i + 1
    }
    return unites
}

micro merge_unite_defs(dst: [ParsedUnite], src: [ParsedUnite]) -> [ParsedUnite] {
    let mut out: [ParsedUnite] = dst
    let mut i: usize = 0
    while i < src.length() {
        let n: utf8 = src⁅i⁆.name.trim()
        if n.length() > 0 && find_unite_def(out, n).name.length() == 0 {
            out = push(out, ParsedUnite { name: n, variants: src⁅i⁆.variants })
        }
        i = i + 1
    }
    return out
}

# Emit CLR unite classes: `int32 tag` + `object payload` (Rust CLR ABI).
micro emit_unite_classes(unites: [ParsedUnite]) -> utf8 {
    let mut parts: [utf8] = []
    let mut seen: [utf8] = []
    let mut i: usize = 0
    while i < unites.length() {
        let u: ParsedUnite = unites⁅i⁆
        let uname: utf8 = u.name.trim()
        if uname.length() == 0 || contains_text(seen, uname) {
            i = i + 1
            continue
        }
        seen = push(seen, uname)
        parts = push(parts, ".class public auto ansi beforefieldinit " + uname + " extends [mscorlib]System.Object\n")
        parts = push(parts, "{\n")
        parts = push(parts, "    .field public int32 tag\n")
        parts = push(parts, "    .field public object payload\n")
        parts = push(parts, "    .method public hidebysig specialname rtspecialname instance void .ctor() cil managed\n")
        parts = push(parts, "    {\n")
        parts = push(parts, "        .maxstack 8\n")
        parts = push(parts, "        ldarg.0\n")
        parts = push(parts, "        call instance void [mscorlib]System.Object::.ctor()\n")
        parts = push(parts, "        ret\n")
        parts = push(parts, "    }\n")
        parts = push(parts, "}\n\n")
        i = i + 1
    }
    return join_msil_parts(parts)
}
