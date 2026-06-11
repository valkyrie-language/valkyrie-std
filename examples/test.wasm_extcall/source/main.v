namespace test;

[wasm("env", "console_log")]
micro console_log(msg: utf8): unit

[main]
micro main() {
    console_log("Hello WASM ExtCall!")
}