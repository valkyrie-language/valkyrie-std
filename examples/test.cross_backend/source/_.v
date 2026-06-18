namespace test;

# CLR 外部函数：调用 System.Console.WriteLine
[clr("System.Console", "System.Console", "WriteLine")]
micro clr_print(value: utf8): unit

# JVM 外部函数：调用 java.lang.System.nanoTime
[jvm("java/lang/System", "nanoTime")]
micro jvm_nano_time(): i64

# JVM 外部函数：调用 java.lang.Math.abs
[jvm("java/lang/Math", "abs")]
micro jvm_abs(value: i64): i64

# WASM 外部函数：调用 env.console_log
[wasm("env", "console_log")]
micro wasm_log(value: utf8): unit

[main]
micro main() {
    clr_print("Hello from CLR!")
    var time = jvm_nano_time()
    var abs = jvm_abs(time)
    wasm_log("Hello from WASM!")
}
