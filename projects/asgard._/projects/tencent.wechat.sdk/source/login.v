namespace tencent.wechat.sdk.auth;

# 微信小游戏登录宿主绑定

micro login() -> i32 {
    return __wx_login()
}

# 直接绑定微信小游戏 `wx.login`

[js_builtin("wx.login")]
micro __wx_login(): i32
