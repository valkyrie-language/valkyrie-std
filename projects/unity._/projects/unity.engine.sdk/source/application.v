namespace unity.engine.sdk.application;

# Unity 应用信息宿主绑定

micro system_language() -> i32 {
    return __unity_system_language()
}

# 直接绑定 Unity `Application.systemLanguage`

[clr("UnityEngine", "UnityEngine.Application", "systemLanguage")]
micro __unity_system_language(): i32
