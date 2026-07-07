namespace tencent.wechat.sdk.file;

# 微信小游戏文件系统宿主绑定

micro read_text(path: utf8) -> utf8 {
    return __wx_get_file_system_manager_read(path)
}

[js_builtin("wx.getFileSystemManager")]
micro __wx_get_file_system_manager_read(path: utf8): utf8
