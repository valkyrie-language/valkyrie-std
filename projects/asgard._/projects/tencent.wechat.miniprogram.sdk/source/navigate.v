namespace tencent.wechat.miniprogram.sdk.nav;

# 微信小程序路由宿主绑定

micro navigate_to(url: utf8) {
    __wx_navigate_to(url)
}

[js_builtin("wx.navigateTo")]
micro __wx_navigate_to(url: utf8): unit
