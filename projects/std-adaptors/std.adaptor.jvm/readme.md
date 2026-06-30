# `std.adaptor.jvm`

Valkyrie JVM 骞冲彴 SDK 鈥?鎻愪緵 Java 杩愯鏃?API 缁戝畾锛岀紪璇戜负 JVM 瀛楄妭鐮侊紙`.class`锛夈€?
## 馃搵 鐩爣涓夊厓缁?
| 鐩爣涓夊厓缁?                | 鏋舵瀯 | 渚涘簲鍟? | OS      | ABI  | 璇存槑                            |
|:---------------------------|:-----|:--------|:--------|:-----|:--------------------------------|
| `jvm-unknown-linux-gnu`    | jvm  | unknown | linux   | gnu  | Linux x64 JVM锛圤penJDK/Oracle锛?|
| `jvm-unknown-darwin`       | jvm  | unknown | darwin  | 鈥?   | macOS JVM                       |
| `jvm-unknown-windows-msvc` | jvm  | unknown | windows | msvc | Windows JVM                     |
| `jvm-unknown-android`      | jvm  | unknown | android | 鈥?   | Android Dalvik/ART              |

> **涓夊厓缁勬牸寮?*锛歚<arch>-<implementation>-<specification>-<abi>`锛堥伒寰?LLVM/Rust 鏍囧噯锛?> JVM 鏄法骞冲彴杩愯鏃讹紝鍚屼竴瀛楄妭鐮佸彲鍦ㄦ墍鏈夊钩鍙拌繍琛岋紝涓夊厓缁勪富瑕佸奖鍝?JNI 璋冪敤绾﹀畾銆?> JVM 鐩爣鐨勪笁鍏冪粍涓?`arch` 鍥哄畾涓?`jvm`锛屽洜涓?JVM 瀛楄妭鐮佷笌鐗╃悊鏋舵瀯鏃犲叧銆?
### 鏄犲皠鍒?Nyar CompilationTarget

| 涓夊厓缁?                    | Arch | ABI | API  | OS      | Environment |
|:---------------------------|:-----|:----|:-----|:--------|:------------|
| `jvm-unknown-linux-gnu`    | Jvm  | JVM | Java | Linux   | Native      |
| `jvm-unknown-darwin`       | Jvm  | JVM | Java | macOS   | Native      |
| `jvm-unknown-windows-msvc` | Jvm  | JVM | Java | Windows | Native      |

### 涓庡叾浠栫洰鏍囩殑鍖哄埆

| 鐗规€?       | CLR             | JVM                       | WASI         |
|:------------|:----------------|:--------------------------|:-------------|
| 馃摝 浜у嚭鏍煎紡 | `.dll` / `.exe` | `.class`                  | `.wasm`      |
| 馃彈锔?杩愯鏃?  | .NET Runtime    | JVM (OpenJDK)             | Wasmtime     |
| 馃搧 鏂囦欢绯荤粺 | 鉁?`System.IO`  | 鉁?`java.io` / `java.nio` | 鉁?WASI fd   |
| 馃實 缃戠粶     | 鉁?`System.Net` | 鉁?`java.net`             | 鉁?WASI sock |
| 馃搳 鍙嶅皠     | 鉁?             | 鉁?                       | 鉂?          |
| 馃敆 浜掓搷浣?  | P/Invoke        | JNI                       | WASI imports |
| 馃У 澶氱嚎绋?  | 鉁?             | 鉁?                       | 鉂?          |
| 馃摎 鏍囧噯搴?  | BCL             | JDK                       | WASI minimal |

## 馃摝 鍖呭唴瀹?
```
std.adaptor.jvm/
鈹溾攢鈹€ legion.von              # 鍖呮竻鍗?鈹溾攢鈹€ README.md               # 鏈枃浠?鈹斺攢鈹€ source/
    鈹溾攢鈹€ console.v           # 鎺у埗鍙?API锛圫ystem.out/in锛?    鈹溾攢鈹€ io.v                # 鏂囦欢绯荤粺 API锛坖ava.io.File锛?    鈹溾攢鈹€ net.v               # 缃戠粶 API锛坖ava.net.URL/HttpURLConnection锛?    鈹溾攢鈹€ math.v              # 鏁板 API锛坖ava.lang.Math锛?    鈹溾攢鈹€ utf8.v            # 瀛楃涓?API锛坖ava.lang.String锛?    鈹斺攢鈹€ thread.v            # 绾跨▼ API锛坖ava.lang.Thread锛?```

## 馃敡 缁戝畾姒傝

### `[jvm("fully.qualified.Class", "methodName")]` 灞炴€?
Java 鏂规硶閫氳繃 `[jvm]` 灞炴€у０鏄庯紝缂栬瘧鏃舵槧灏勪负 JVM 甯搁噺姹犳柟娉曞紩鐢紙Methodref锛夛細

```v
[jvm("java.lang.System", "out.println")]
micro jvm_println(value: string): void

[jvm("java.lang.Math", "abs")]
micro jvm_math_abs(value: f64): f64

[jvm("java.io.File", "exists")]
micro jvm_file_exists(path: string): bool
```

### 鏂囦欢璇存槑

| 鏂囦欢        | 缁戝畾绫诲瀷 | 鍓綔鐢?   | 瑕嗙洊 API       |
|:------------|:---------|:----------|:---------------|
| `console.v` | `[jvm]`  | 鉁?鏈?    | 鎺у埗鍙拌緭鍏ヨ緭鍑?|
| `io.v`      | `[jvm]`  | 鉁?鏈?    | 鏂囦欢/鐩綍鎿嶄綔  |
| `net.v`     | `[jvm]`  | 鉁?鏈?    | HTTP 璇锋眰      |
| `math.v`    | `[jvm]`  | 鉂?绾嚱鏁?| 鏁板鍑芥暟       |
| `utf8.v`  | `[jvm]`  | 鉂?绾嚱鏁?| 瀛楃涓叉搷浣?    |
| `thread.v`  | `[jvm]`  | 鉁?鏈?    | 绾跨▼鎿嶄綔       |

## 馃幆 浣跨敤鍦烘櫙

- 馃枼锔?鏈嶅姟绔?Java 搴旂敤锛圫pring Boot 鍚庣閫昏緫锛?- 馃摫 Android 娓告垙鑴氭湰
- 馃敡 澶ф暟鎹鐞嗭紙Hadoop/Spark UDF锛?- 馃幃 Minecraft 鎻掍欢锛圔ukkit/Spigot锛?
## 鈿欙笍 缂栬瘧鍛戒护

```bash
# 缂栬瘧涓?JVM 瀛楄妭鐮?vcc build --target jvm

# 杩愯浜у嚭
java Module
```

## 馃搶 鐘舵€?
馃毀 鍗犲潙闃舵锛孞DK API 缁戝畾寰呭疄鐜板畬鏁磋鐩栥€?鈿狅笍 JvmBackend 鐨?`EmitCallFromInstruction` 鍐欏叆 methodref 绱㈠紩涓?0锛堝崰浣嶇锛夛紝璺ㄥ嚱鏁拌皟鐢ㄥ皻鏈疄鐜板父閲忔睜瑙ｆ瀽銆?鈿狅笍 JvmBackend 鐨?`EmitJumpFromInstruction` 鍐欏叆璺宠浆鍋忕Щ涓?0锛堝崰浣嶇锛夛紝鍒嗘敮鍋忕Щ灏氭湭璁＄畻銆?鈿狅笍 Acorn.Jvm.Decode 鐨勫睘鎬цВ鐮佷负 stub锛堝缁堣繑鍥?null锛夛紝鏃犳硶瀹屾暣 round-trip銆?
