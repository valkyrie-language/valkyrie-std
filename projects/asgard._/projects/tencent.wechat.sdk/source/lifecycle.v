namespace tencent.wechat.sdk.lifecycle;

# 微信小游戏生命周期宿主绑定

micro on_show() {
    __wx_on_show()
}

[js_builtin("wx.onShow")]
micro __wx_on_show(): unit

[js_builtin("wx.onHide")]
micro __wx_on_hide(): unit
