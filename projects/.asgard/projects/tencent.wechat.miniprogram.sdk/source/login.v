namespace tencent.wechat.miniprogram.sdk.auth;

# 微信小程序登录

micro login() -> i32 {
    return __wx_login()
}

[js_builtin("wx.login")]
micro __wx_login(): i32
