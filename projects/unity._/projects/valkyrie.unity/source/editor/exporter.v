namespace valkyrie.unity.editor;

# Editor 导入 MSIL（由 `legion-unity sync` 落盘后调用）。

[export(unity.editor)]
micro import_msil(project_root: utf8): bool {
    if project_root.len() == 0 {
        return false
    }
    __unity_debug_log("[Valkyrie] import_msil from " + project_root)
    return true
}

[clr("UnityEngine.CoreModule", "UnityEngine.Debug", "Log")]
private micro __unity_debug_log(message: utf8): unit
