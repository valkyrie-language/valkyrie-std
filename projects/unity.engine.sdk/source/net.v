namespace unity.engine.sdk.net;

# Unity 网络能力宿主提供

[host_provider(std::net::get)]
micro get(url: utf8): utf8 {
    return __valkyrie_unity_http_get(url)
}

# 由 `valkyrie.unity` Runtime 分区 DLL 提供 HTTP 导出

[clr("valkyrie.unity.runtime", "valkyrie.unity.runtime.http", "get_text")]
micro __valkyrie_unity_http_get(url: utf8): utf8
