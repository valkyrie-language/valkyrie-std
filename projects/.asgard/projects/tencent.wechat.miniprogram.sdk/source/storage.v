namespace tencent.wechat.miniprogram.sdk.storage;

# 微信小程序本地存储宿主绑定

micro get_text(key: utf8) -> utf8 {
    return __wx_get_storage_sync(key)
}

[js_builtin("wx.getStorageSync")]
micro __wx_get_storage_sync(key: utf8): utf8

[js_builtin("wx.setStorageSync")]
micro __wx_set_storage_sync(key: utf8, value: utf8): unit
