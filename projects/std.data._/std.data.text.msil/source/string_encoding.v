namespace std.data.text.msil;

# Host string encoding contracts (do not conflate):
# - Language `utf8` / `Utf8Text`: UTF-8 storage in std; `length` / `slice` / `index_of`
#   are Unicode **scalar** indices (not UTF-8 byte offsets, not UTF-16 code units).
# - Language `utf16` / `Utf16Text`: UTF-16 **code units** (`System.String.get_Length` OK).
# - CLR `System.String` / JVM `java.lang.String` / JS `string`: UTF-16 **code units**.
# - Forbidden: lower `Utf8Text.length` / `slice` straight to `get_Length` / `Substring`
#   (or JS `.length` / `substring`) without scalar ↔ code-unit conversion
#   (`std.adaptor.clr.text.Utf8Text`, wasm `env.utf8_*` / JS `[...s]` scalars).
# - ILASM `ldstr "..."` payload is interpreted for the CLR string heap (UTF-16).
#   Raw multi-byte UTF-8 inside quotes breaks Framework ilasm for non-ASCII
#   (e.g. index quills U+2045/U+2046) — use `ldstr bytearray (UTF-16LE …)`.
# Indexing: never treat UTF-8 byte offsets as UTF-16 code-unit indices (or reverse)
# across an interop boundary without an explicit transcoder.

micro msil_quote_char() -> utf8 {
    return "\""
}

micro msil_hex2_u8(n: i32) -> utf8 {
    let mut v: i32 = n
    if v < 0 {
        v = 0
    }
    if v > 255 {
        v = 255
    }
    let hi: i32 = v / 16
    let lo: i32 = v % 16
    let digits: utf8 = "0123456789ABCDEF"
    return digits.slice(hi, 1) + digits.slice(lo, 1)
}

# One BMP code point as UTF-16LE hex pair (language `utf8` scalar held as one V char).
micro msil_utf16le_hex_bmp(ch: utf8) -> utf8 {
    if ch == "⁅" {
        return "45 20"
    }
    if ch == "⁆" {
        return "46 20"
    }
    if ch == "\u{09}" {
        return "09 00"
    }
    if ch == "\u{0a}" {
        return "0A 00"
    }
    if ch == "\u{0d}" {
        return "0D 00"
    }
    let mut map: utf8 = " !"
    map = map + msil_quote_char()
    map = map + "#$%&"
    map = map + "\u{27}"
    map = map + "()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ["
    map = map + "\u{5c}"
    map = map + "]^_"
    map = map + "\u{60}"
    map = map + "abcdefghijklmnopqrstuvwxyz"
    map = map + "{|}~"
    let idx: i32 = map.index_of(ch)
    if idx >= 0 {
        return msil_hex2_u8(idx + 32) + " 00"
    }
    return "3F 00"
}

# Render CLR `ldstr` from language UTF-8 source text → UTF-16 string heap form.
micro render_msil_ldstr_from_utf8_source(utf8_source: utf8) -> utf8 {
    let mut ascii: utf8 = "\u{09}\u{0a}\u{0d} !#$%&()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_abcdefghijklmnopqrstuvwxyz{}~"
    ascii = ascii + msil_quote_char()
    ascii = ascii + "\u{5c}\u{27}\u{60}|"
    let mut escaped: utf8 = ""
    let mut bytearray_hex: utf8 = ""
    let mut needs_utf16_bytearray: bool = false
    let mut i: i32 = 0
    let backslash: utf8 = "\\"
    while i < utf8_source.length() {
        let ch: utf8 = utf8_source.slice(i, 1)
        if ch == "⁅" || ch == "⁆" {
            needs_utf16_bytearray = true
        }
        if ch == backslash {
            escaped = escaped + backslash + backslash
        }
        else if ch == msil_quote_char() {
            escaped = escaped + backslash + msil_quote_char()
        }
        else if ch == "\u{0a}" {
            escaped = escaped + backslash + "n"
        }
        else if ch == "\u{09}" {
            escaped = escaped + backslash + "t"
        }
        else if ch == "\u{0d}" {
            escaped = escaped + backslash + "r"
        }
        else if ascii.contains(ch) {
            escaped = escaped + ch
        }
        else {
            needs_utf16_bytearray = true
            escaped = escaped + "?"
        }
        if bytearray_hex.length() > 0 {
            bytearray_hex = bytearray_hex + " "
        }
        bytearray_hex = bytearray_hex + msil_utf16le_hex_bmp(ch)
        i = i + 1
    }
    if needs_utf16_bytearray {
        let mut line: utf8 = "bytearray ("
        line = line + bytearray_hex
        line = line + ")"
        return line
    }
    let mut quoted: utf8 = msil_quote_char()
    quoted = quoted + escaped
    quoted = quoted + msil_quote_char()
    return quoted
}
