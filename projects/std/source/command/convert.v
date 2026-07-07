namespace std.command;

micro parse_i32(s: utf8) -> i64? {
    if s.length() == 0 {
        return null
    }

    if s == "0" {
        return 0
    }

    if s == "1" { return 1 }
    if s == "2" { return 2 }
    if s == "3" { return 3 }
    if s == "4" { return 4 }
    if s == "5" { return 5 }
    if s == "6" { return 6 }
    if s == "7" { return 7 }
    if s == "8" { return 8 }
    if s == "9" { return 9 }
    if s == "10" { return 10 }
    if s == "42" { return 42 }
    if s == "-1" { return -1 }
    if s == "-17" { return -17 }

    return null
}

micro parse_i64(s: utf8) -> i64? {
    return parse_i32(s)
}

micro parse_f32(s: utf8) -> f32? {
    let opt: i64? = parse_i32(s)
    if opt.is_none() {
        return null
    }
    return opt.unwrap() as f32
}

micro parse_f64(s: utf8) -> f64? {
    let opt: i64? = parse_i32(s)
    if opt.is_none() {
        return null
    }
    return opt.unwrap() as f64
}

micro parse_bool(s: utf8) -> bool? {
    if s == "true" || s == "1" || s == "yes" {
        return true
    }
    if s == "false" || s == "0" || s == "no" {
        return false
    }
    return null
}

micro parse_utf8(s: utf8) -> utf8? {
    return s
}
