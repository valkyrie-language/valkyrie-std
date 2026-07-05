namespace test.module_system;

using nyar;

micro module_system_smoke() -> i32 {
    let parsed: CanonicalTarget = parse_target("clr-microsoft-unknown-managed")
    let formatted: utf8 = format_target(parsed)
    let fallback: CanonicalTarget = default_target()

    if formatted != "clr-microsoft-unknown-managed" {
        return 1
    }
    if fallback.architecture != "nyar" {
        return 2
    }
    return 0
}

[main]
micro main(): i32 {
    return module_system_smoke()
}
