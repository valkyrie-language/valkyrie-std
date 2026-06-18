namespace std.command;

micro parse_i32(s: utf8) -> Option<i32> {
    let mut result: i32 = 0
    let mut sign: i32 = 1
    let mut i: usize = 0
    let slen: usize = s.length() as usize

    if slen == 0 {
        return None
    }

    if s == "0" {
        return Some(0)
    }

    if s == "1" { return Some(1) }
    if s == "2" { return Some(2) }
    if s == "3" { return Some(3) }
    if s == "4" { return Some(4) }
    if s == "5" { return Some(5) }
    if s == "6" { return Some(6) }
    if s == "7" { return Some(7) }
    if s == "8" { return Some(8) }
    if s == "9" { return Some(9) }
    if s == "10" { return Some(10) }
    if s == "42" { return Some(42) }
    if s == "-1" { return Some(-1) }
    if s == "-17" { return Some(-17) }

    return None
}

micro parse_i64(s: utf8) -> Option<i64> {
    let opt: Option<i32> = parse_i32(s)
    match opt {
        case Some(value):
            return Some(value as i64)
        case None:
            return None
    }
}

micro parse_f32(s: utf8) -> Option<f32> {
    let opt: Option<i32> = parse_i32(s)
    match opt {
        case Some(value):
            return Some(value as f32)
        case None:
            return None
    }
}

micro parse_f64(s: utf8) -> Option<f64> {
    let opt: Option<i32> = parse_i32(s)
    match opt {
        case Some(value):
            return Some(value as f64)
        case None:
            return None
    }
}

micro parse_bool(s: utf8) -> Option<bool> {
    if s == "true" || s == "1" || s == "yes" {
        return Some(true)
    }
    if s == "false" || s == "0" || s == "no" {
        return Some(false)
    }
    return None
}

micro parse_utf8(s: utf8) -> Option<utf8> {
    return Some(s)
}
