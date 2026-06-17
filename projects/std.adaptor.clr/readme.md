# `std.adaptor.clr`

Valkyrie .NET 骞冲彴 SDK 鈥?鎻愪緵 .NET 杩愯鏃?API 缁戝畾锛岀紪璇戜负 CLR 绋嬪簭闆嗭紙`.dll`/`.exe`锛夈€?
## 馃搵 鐩爣涓夊厓缁?
| 鐩爣涓夊厓缁?                 | 鏋舵瀯    | 渚涘簲鍟? | OS      | ABI  | 璇存槑                     |
|:----------------------------|:--------|:--------|:--------|:-----|:-------------------------|
| `x86_64-pc-windows-msvc`    | x86_64  | pc      | windows | msvc | Windows x64 .NET锛堜富娴侊級 |
| `aarch64-pc-windows-msvc`   | aarch64 | pc      | windows | msvc | Windows ARM64 .NET       |
| `x86_64-unknown-linux-gnu`  | x86_64  | unknown | linux   | gnu  | Linux x64 .NET           |
| `aarch64-unknown-linux-gnu` | aarch64 | unknown | linux   | gnu  | Linux ARM64 .NET         |
| `x86_64-apple-darwin`       | x86_64  | apple   | darwin  | 鈥?   | macOS Intel .NET         |
| `aarch64-apple-darwin`      | aarch64 | apple   | darwin  | 鈥?   | macOS Apple Silicon .NET |

> **涓夊厓缁勬牸寮?*锛歚<arch>-<implementation>-<specification>-<abi>`锛堥伒寰?LLVM/Rust 鏍囧噯锛?> .NET 鏄法骞冲彴杩愯鏃讹紝鍚屼竴 IL 浠ｇ爜鍙湪鎵€鏈夊钩鍙拌繍琛岋紝涓夊厓缁勪富瑕佸奖鍝?P/Invoke 璋冪敤绾﹀畾銆?
### 鏄犲皠鍒?Nyar CompilationTarget

| 涓夊厓缁?                    | Arch | ABI | API | OS      | Environment |
|:---------------------------|:-----|:----|:----|:--------|:------------|
| `x86_64-pc-windows-msvc`   | Clr  | CLR | NET | Windows | Native      |
| `x86_64-unknown-linux-gnu` | Clr  | CLR | NET | Linux   | Native      |
| `aarch64-apple-darwin`     | Clr  | CLR | NET | macOS   | Native      |

### 涓庡叾浠栫洰鏍囩殑鍖哄埆

| 鐗规€?       | `wasm32-unknown-unknown` | `wasm32-wasi-preview1` | CLR                    |
|:------------|:-------------------------|:-----------------------|:-----------------------|
| 馃摝 浜у嚭鏍煎紡 | `.wasm`                  | `.wasm`                | `.dll` / `.exe`        |
| 馃彈锔?杩愯鏃?  | 娴忚鍣?JS                | Wasmtime/Wasmer        | .NET Runtime           |
| 馃搧 鏂囦欢绯荤粺 | 鉂?                      | 鉁?                    | 鉁?`System.IO`         |
| 馃實 缃戠粶     | 鉂岋紙浠?`fetch`锛?        | 鉁?                    | 鉁?`System.Net`        |
| 馃搳 鍙嶅皠     | 鉂?                      | 鉂?                    | 鉁?`System.Reflection` |
| 馃敆 浜掓搷浣?  | JS glue                  | WASI imports           | P/Invoke               |
| 馃У 澶氱嚎绋?  | 鉂岋紙SharedArrayBuffer锛? | 鉁?                    | 鉁?`System.Threading`  |
| 馃摎 鏍囧噯搴?  | Web API                  | WASI                   | BCL锛堝熀纭€绫诲簱锛?       |

## 馃摝 鍖呭唴瀹?
```
std.adaptor.dotnet/
鈹溾攢鈹€ legion.von              # 鍖呮竻鍗?鈹溾攢鈹€ README.md               # 鏈枃浠?鈹斺攢鈹€ source/
    鈹溾攢鈹€ console.v           # 鎺у埗鍙?API锛圕onsole.Write/WriteLine/ReadLine锛?    鈹溾攢鈹€ io.v                # 鏂囦欢绯荤粺 API锛團ile/Directory/Path锛?    鈹溾攢鈹€ net.v               # 缃戠粶 API锛圚ttpClient锛?    鈹溾攢鈹€ math.v              # 鏁板 API锛圫ystem.Math锛?    鈹溾攢鈹€ utf8.v            # 瀛楃涓?API锛圫tring 鎿嶄綔锛?    鈹斺攢鈹€ threading.v         # 绾跨▼ API锛圱ask/Thread锛?```

## 馃敡 缁戝畾姒傝

### `[clr("Namespace.Type", "Method")]` 灞炴€?
.NET 鏂规硶閫氳繃 `[clr]` 灞炴€у０鏄庯紝缂栬瘧鏃舵槧灏勪负 CLR 鏂规硶寮曠敤锛圡emberRef锛夛細

```v
[clr("System.Console", "WriteLine")]
micro console_write_line(value: string): void

[clr("System.IO.File", "ReadAllText")]
micro file_read_all_text(path: string): string

[clr("System.Math", "Abs")]
micro math_abs(value: f64): f64
```

### 鏂囦欢璇存槑

| 鏂囦欢          | 缁戝畾绫诲瀷 | 鍓綔鐢?   | 瑕嗙洊 API       |
|:--------------|:---------|:----------|:---------------|
| `console.v`   | `[clr]`  | 鉁?鏈?    | 鎺у埗鍙拌緭鍏ヨ緭鍑?|
| `io.v`        | `[clr]`  | 鉁?鏈?    | 鏂囦欢/鐩綍鎿嶄綔  |
| `net.v`       | `[clr]`  | 鉁?鏈?    | HTTP 璇锋眰      |
| `math.v`      | `[clr]`  | 鉂?绾嚱鏁?| 鏁板鍑芥暟       |
| `utf8.v`    | `[clr]`  | 鉂?绾嚱鏁?| 瀛楃涓叉搷浣?    |
| `threading.v` | `[clr]`  | 鉁?鏈?    | 寮傛/绾跨▼      |

## 馃幆 浣跨敤鍦烘櫙

- 馃枼锔?Windows 妗岄潰搴旂敤锛圵PF/WinForms 鍚庣閫昏緫锛?- 馃寪 ASP.NET 鏈嶅姟绔?- 馃敡 鍛戒护琛屽伐鍏?- 馃幃 Unity 娓告垙鑴氭湰锛堥€氳繃 CLR 鍚庣锛?
## 鈿欙笍 缂栬瘧鍛戒护

```bash
# 缂栬瘧涓?.NET 绋嬪簭闆?vcc build --target clr

# 杩愯浜у嚭
dotnet module.dll
```

## 馃搶 鐘舵€?
馃毀 鍗犲潙闃舵锛?NET BCL API 缁戝畾寰呭疄鐜板畬鏁磋鐩栥€?鈿狅笍 ClrEncoder 鐨?Blob Heap 鍜?UserString Heap 缂栫爜涓烘渶灏忓疄鐜帮紙杩斿洖 `[0]`
锛夛紝鏆備笉鏀寔瀛楁绛惧悕鍜屽瓧绗︿覆瀛楅潰閲忋€?鈿狅笍 ClrTypeMapper.MapToMethodAttributes 濮嬬粓杩斿洖 `Public | Static`锛屽緟瀹屽杽璁块棶淇グ绗︽槧灏勩€?
