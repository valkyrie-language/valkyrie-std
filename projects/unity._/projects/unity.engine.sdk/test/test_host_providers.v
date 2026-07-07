namespace unity.engine.sdk.test;

# unity-player publish 下 host_provider 选择冒烟（编译期图检查）

micro host_provider_smoke() -> bool {
    unity.engine.sdk.console.write_line("unity.engine.sdk host smoke")
    return true
}
