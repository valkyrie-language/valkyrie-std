namespace test;

# JVM 外部函数：调用 java.lang.System.nanoTime
[jvm("java/lang/System", "nanoTime")]
micro jvm_nano_time(): i64

# JVM 外部函数：调用 java.lang.Math.abs
[jvm("java/lang/Math", "abs")]
micro jvm_abs(value: i64): i64

# 跨后端外部函数：仅用于让语义分析器推断返回 unit，JVM 编译时跳过
[clr("System.Console", "WriteLine")]
micro clr_print(value: utf8): unit

[main]
micro hello() {
    var time = jvm_nano_time()
    var abs = jvm_abs(time)
    clr_print("Hello JVM Direct!")
}