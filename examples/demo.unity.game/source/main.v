namespace demo.unity.game;

# Unity 游戏示例入口

[main]
micro main() {
    std.console.write_line("demo.unity.game boot");

    let cached = unity.engine.sdk.storage.get_text("profile");
    std.console.write_line(cached);

    let language = unity.engine.sdk.application.system_language();
    std.console.write_line("unity language loaded");

    let response = std.net.get("https://example.com/api/profile");
    std.console.write_line(response);
}
