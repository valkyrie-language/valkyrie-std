namespace demo.wechat.game;

# 微信小游戏示例入口

[main]
micro main() {
    std.console.write_line("demo.wechat.game boot");

    let cached = tencent.wechat.sdk.storage.get_text("session");
    std.console.write_line(cached);

    let login_handle = tencent.wechat.sdk.auth.login();
    std.console.write_line("wechat login requested");

    let response = std.net.get("https://example.com/api/profile");
    std.console.write_line(response);
}
