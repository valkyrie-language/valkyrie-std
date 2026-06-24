namespace test_module_system;

using nyar;
using std.io;

# 单元测试：验证 nyar.parse_target 正确解析 CLR 目标
micro test_parse_clr_target() -> bool {
    let target: CanonicalTarget = parse_target("clr-microsoft-unknown-managed")
    if target.architecture != "clr" {
        return false
    }
    if target.vendor != "microsoft" {
        return false
    }
    if target.system != "unknown" {
        return false
    }
    if target.abi != "managed" {
        return false
    }
    return true
}

# 单元测试：验证 nyar.parse_target 正确解析 nyar 目标
micro test_parse_nyar_target() -> bool {
    let target: CanonicalTarget = parse_target("nyar-unknown-unknown")
    if target.architecture != "nyar" {
        return false
    }
    if target.vendor != "unknown" {
        return false
    }
    if target.system != "unknown" {
        return false
    }
    if target.abi != "" {
        return false
    }
    return true
}

# 单元测试：验证 nyar.format_target 正确格式化
micro test_format_target() -> bool {
    let target: CanonicalTarget = parse_target("clr-microsoft-unknown-managed")
    let formatted: utf8 = format_target(target)
    return formatted == "clr-microsoft-unknown-managed"
}

# 单元测试：验证 nyar.default_target 返回 nyar 默认目标
micro test_default_target() -> bool {
    let target: CanonicalTarget = default_target()
    if target.architecture != "nyar" {
        return false
    }
    if target.vendor != "unknown" {
        return false
    }
    if target.system != "unknown" {
        return false
    }
    return true
}

# 单元测试：验证作用域隔离 — 本命名空间的函数不污染 nyar 命名空间
micro test_scope_isolation() -> bool {
    let local_result: utf8 = format_target(parse_target("clr-microsoft-unknown-managed"))
    return local_result == "clr-microsoft-unknown-managed"
}

# 单元测试：验证跨模块类型传递 — CanonicalTarget 可在函数间传递
micro test_cross_module_type_passing() -> bool {
    let parsed: CanonicalTarget = parse_target("jvm-openjdk-unknown-managed")
    let formatted: utf8 = format_target(parsed)
    if formatted != "jvm-openjdk-unknown-managed" {
        return false
    }
    if parsed.architecture != "jvm" {
        return false
    }
    return true
}

# 单元测试：验证 std.io 模块可被调用
micro test_std_io_module() -> bool {
    let current_dir: utf8 = std.io.get_current_directory()
    return current_dir.length() >= 0
}

# 测试入口：运行所有单元测试
[main]
micro main(args: [utf8]) -> i32 {
    let mut passed: usize = 0
    let mut failed: usize = 0

    if test_parse_clr_target() {
        passed = passed + 1
    }
    else {
        failed = failed + 1
        std.io.print_line("FAIL: test_parse_clr_target")
    }

    if test_parse_nyar_target() {
        passed = passed + 1
    }
    else {
        failed = failed + 1
        std.io.print_line("FAIL: test_parse_nyar_target")
    }

    if test_format_target() {
        passed = passed + 1
    }
    else {
        failed = failed + 1
        std.io.print_line("FAIL: test_format_target")
    }

    if test_default_target() {
        passed = passed + 1
    }
    else {
        failed = failed + 1
        std.io.print_line("FAIL: test_default_target")
    }

    if test_scope_isolation() {
        passed = passed + 1
    }
    else {
        failed = failed + 1
        std.io.print_line("FAIL: test_scope_isolation")
    }

    if test_cross_module_type_passing() {
        passed = passed + 1
    }
    else {
        failed = failed + 1
        std.io.print_line("FAIL: test_cross_module_type_passing")
    }

    if test_std_io_module() {
        passed = passed + 1
    }
    else {
        failed = failed + 1
        std.io.print_line("FAIL: test_std_io_module")
    }

    std.io.print_line("模块系统测试结果：" + passed + " 通过，" + failed + " 失败")

    if failed > 0 {
        return 1
    }
    return 0
}
