namespace test_module_system;

using nyar;
using std.io;

# 验证 nyar 模块的类型导入：CanonicalTarget 结构体可被引用
micro parse_clr_target() -> CanonicalTarget {
    return parse_target("clr-microsoft-unknown-managed")
}

# 验证 nyar 模块的函数调用：format_target 可被调用
micro format_clr_target() -> utf8 {
    let target: CanonicalTarget = parse_clr_target()
    return format_target(target)
}

# 验证 nyar 模块的默认值函数：default_target 可被调用
micro default_canonical_target() -> CanonicalTarget {
    return default_target()
}

# 验证作用域隔离：本命名空间的函数不会与 nyar 命名空间冲突
micro test_scope_isolation() -> bool {
    let local_target: CanonicalTarget = parse_clr_target()
    let formatted: utf8 = format_target(local_target)
    return formatted == "clr-microsoft-unknown-managed"
}

# 验证跨模块类型传递：nyar.CanonicalTarget 可作为函数参数和返回值
micro round_trip_target(triple: utf8) -> utf8 {
    let parsed: CanonicalTarget = parse_target(triple)
    return format_target(parsed)
}

# 验证 std 模块的函数调用：std.io.print_line 可被调用
micro print_target_info(triple: utf8) -> unit {
    let formatted: utf8 = round_trip_target(triple)
    std.io.print_line("目标三元组：" + formatted)
}
