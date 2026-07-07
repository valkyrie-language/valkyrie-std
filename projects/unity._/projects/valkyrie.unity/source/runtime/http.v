namespace valkyrie.unity.runtime.http;

# 供 `unity.engine.sdk.net` 使用的同步 HTTP 导出。

[export(unity.runtime)]
micro get_text(url: utf8): utf8 {
    return __unity_http_get_text(url)
}

[clr("UnityEngine.UnityWebRequestModule", "UnityEngine.Networking.UnityWebRequest", "Get")]
private micro __unity_http_get_text(url: utf8): utf8
