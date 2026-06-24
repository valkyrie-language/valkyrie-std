namespace unity.engine.sdk.console;

# Unity 控制台能力填充

[fill("std.console.write_line")]
micro write_line(message: utf8): unit {
    __unity_debug_log(message)
}

# 直接绑定 Unity `Debug.Log`

[clr("UnityEngine", "UnityEngine.Debug", "Log")]
micro __unity_debug_log(message: utf8): unit
