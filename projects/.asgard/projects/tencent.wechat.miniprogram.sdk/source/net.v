namespace tencent.wechat.miniprogram.sdk.net;

# 微信小程序网络能力宿主提供

[host_provider(std::net::get)]
micro get(url: utf8): utf8 {
    return __wx_request_get(url)
}

[js_builtin("wx.request")]
micro __wx_request_get(url: utf8): utf8
