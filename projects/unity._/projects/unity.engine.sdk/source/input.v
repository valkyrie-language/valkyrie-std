namespace unity.engine.sdk.input;

# Unity 输入 API（首版键盘）

micro get_key(key_name: utf8) -> bool {
    return __unity_get_key(key_name)
}

[clr("UnityEngine", "UnityEngine.Input", "GetKey")]
micro __unity_get_key(key_name: utf8): bool
