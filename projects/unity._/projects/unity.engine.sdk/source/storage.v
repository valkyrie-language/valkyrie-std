namespace unity.engine.sdk.storage;

# Unity 本地存储宿主绑定

micro get_text(key: utf8) -> utf8 {
    return __player_prefs_get_string(key)
}

micro set_text(key: utf8, value: utf8) {
    __player_prefs_set_string(key, value)
}

# 直接绑定 Unity `PlayerPrefs.GetString`

[clr("UnityEngine", "UnityEngine.PlayerPrefs", "GetString")]
micro __player_prefs_get_string(key: utf8): utf8

# 直接绑定 Unity `PlayerPrefs.SetString`

[clr("UnityEngine", "UnityEngine.PlayerPrefs", "SetString")]
micro __player_prefs_set_string(key: utf8, value: utf8): unit
