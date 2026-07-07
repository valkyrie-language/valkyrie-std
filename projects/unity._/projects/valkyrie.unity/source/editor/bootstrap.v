namespace valkyrie.unity.editor.bootstrap;

# 生成 Play Mode 引导脚本路径提示（完整生成由 `legion-unity` 工作流负责）。

[export(unity.editor)]
micro generate_bootstrap(entry_assembly: utf8, entry_method: utf8, entry_type: utf8): bool {
    __unity_debug_log("[Valkyrie] bootstrap for " + entry_assembly + " :: " + entry_method)
    return entry_type.len() >= 0
}

[clr("UnityEngine.CoreModule", "UnityEngine.Debug", "Log")]
private micro __unity_debug_log(message: utf8): unit
