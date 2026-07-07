namespace nyar.language.valkyrie;

# Legion entry helpers. Template-copy / handcrafted bootstrap PE was removed:
# V 片段路径不能诚实自举 legion.tools（需 seed 级 MIR→PE）。

micro entry_is_legion(entry: utf8) -> bool {
    if entry == "legion" {
        return true
    }
    if entry.ends_with(".legion") {
        return true
    }
    if entry.ends_with("__legion") {
        return true
    }
    return false
}

micro legion_self_host_gap_message() -> utf8 {
    return "fail-closed: legion.tools CLR 自举需要 seed 级 MIR→PE；已拒绝模板复制与空桩 emit（V 片段 lowering 不足以再编译编译器）"
}
