namespace tencent.wechat.sdk.share;

# 微信小游戏分享宿主绑定

micro share_app_message(title: utf8) {
    __wx_share_app_message(title)
}

[js_builtin("wx.shareAppMessage")]
micro __wx_share_app_message(title: utf8): unit
