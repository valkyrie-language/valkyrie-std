namespace tencent.wechat.sdk.net;

# 微信小游戏网络能力宿主提供

[host_provider("std.net.get")]
micro get(url: utf8): utf8 {
    return __wx_request_get(url)
}

# 直接绑定微信小游戏 `wx.request`
# 参数与返回的宿主胶水由编译器自动生成，这里不手写额外桥接层

[js_builtin("wx.request")]
micro __wx_request_get(url: utf8): utf8
