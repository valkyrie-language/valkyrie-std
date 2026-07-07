namespace unity.engine.sdk.time;

# Unity 时间 API（游戏循环 tick 由 Editor 插件驱动）

micro delta_time() -> f64 {
    return __unity_delta_time()
}

micro time() -> f64 {
    return __unity_time()
}

[clr("UnityEngine", "UnityEngine.Time", "get_deltaTime")]
micro __unity_delta_time(): f64

[clr("UnityEngine", "UnityEngine.Time", "get_time")]
micro __unity_time(): f64
