namespace valkyrie.unity.runtime;

# Unity Play Mode 入口（由 UPM `Valkyrie.Unity.Runtime.dll` 提供）。

[export(unity.runtime)]
micro run(assembly_file: utf8, entry_method: utf8): unit {
    run_with_type(assembly_file, "", entry_method)
}

[export(unity.runtime)]
micro run_with_type(assembly_file: utf8, entry_type: utf8, entry_method: utf8): unit {
    __unity_debug_log("[Valkyrie] Run " + assembly_file + " :: " + entry_method)
}

[clr("UnityEngine.CoreModule", "UnityEngine.Debug", "Log")]
private micro __unity_debug_log(message: utf8): unit
