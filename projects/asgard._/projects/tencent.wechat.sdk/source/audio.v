namespace tencent.wechat.sdk.audio;

# 微信小游戏音频宿主绑定

micro play(src: utf8) {
    __wx_create_inner_audio_context(src)
}

[js_builtin("wx.createInnerAudioContext")]
micro __wx_create_inner_audio_context(src: utf8): i32
