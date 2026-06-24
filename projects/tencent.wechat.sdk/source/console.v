namespace tencent.wechat.sdk.console;

# 微信小游戏控制台能力填充

[fill("std.console.write_line")]
micro write_line(message: utf8): unit {
    __console_log(message)
}

# 直接绑定浏览器控制台 `console.log`

[js_builtin("console.log")]
micro __console_log(message: utf8): unit
