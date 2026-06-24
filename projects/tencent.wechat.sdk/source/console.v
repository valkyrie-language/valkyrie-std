namespace tencent.wechat.sdk.console;

# 微信小游戏控制台能力宿主提供

[host_provider("std.console.write_line")]
micro write_line(message: utf8): unit {
    __console_log(message)
}

# 直接绑定浏览器控制台 `console.log`

[js_builtin("console.log")]
micro __console_log(message: utf8): unit
