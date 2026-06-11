namespace test;

[wasm("env", "console_log")]
micro console_log(msg: utf8): unit

[main]
micro hello() {
    console_log("Hello Direct WASM!")
}