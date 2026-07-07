namespace nyar;

structure CanonicalTarget {
    architecture: utf8
    vendor: utf8
    system: utf8
    abi: utf8
}

micro parse_target(triple: utf8) -> CanonicalTarget {
    let mut arch: utf8 = ""
    let mut vendor: utf8 = ""
    let mut sys: utf8 = ""
    let mut abi: utf8 = ""

    let mut part: i32 = 0
    let mut i: usize = 0
    let length: usize = triple.length()
    while i < length {
        let ch: utf8 = triple⁅i⁆
        if ch == "-" {
            part = part + 1
        }
        if ch != "-" && part == 0 {
            arch = arch + ch
        }
        if ch != "-" && part == 1 {
            vendor = vendor + ch
        }
        if ch != "-" && part == 2 {
            sys = sys + ch
        }
        if ch != "-" && part == 3 {
            abi = abi + ch
        }
        i = i + 1
    }

    return CanonicalTarget {
        architecture: arch,
        vendor: vendor,
        system: sys,
        abi: abi
    }
}

micro format_target(target: CanonicalTarget) -> utf8 {
    let mut result: utf8 = target.architecture
    result = result + "-"
    result = result + target.vendor
    result = result + "-"
    result = result + target.system
    if target.abi.length() > 0 {
        result = result + "-"
        result = result + target.abi
    }
    return result
}

micro default_target() -> CanonicalTarget {
    return CanonicalTarget {
        architecture: "nyar",
        vendor: "unknown",
        system: "unknown",
        abi: ""
    }
}
