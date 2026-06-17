# `std.adaptor.nyar`

Valkyrie NyarVM 骞冲彴 SDK 鈥?鎻愪緵 NyarVM 鎸囦护闆嗙粦瀹氾紝缂栬瘧涓?`.nyar` 瀛楄妭鐮併€?
## 鐩爣涓夊厓缁?
| 鐩爣涓夊厓缁?            | 鏋舵瀯   | 璇存槑              |
|:-----------------------|:-------|:------------------|
| `nyar-unknown-unknown` | nyar32 | NyarVM 閫氱敤杩愯鏃?|

## 鍖呭唴瀹?
```
std.adaptor.nyar/
鈹溾攢鈹€ legion.von          # 鍖呮竻鍗?鈹斺攢鈹€ source/
    鈹溾攢鈹€ arith.v         # 绠楁湳杩愮畻 [vm] 缁戝畾
    鈹溾攢鈹€ builtin.v       # VM 鍐呯疆鍑芥暟 [vm] 缁戝畾
    鈹溾攢鈹€ cmp.v           # 姣旇緝杩愮畻 [vm] 缁戝畾
    鈹溾攢鈹€ control.v       # 鎺у埗娴?[vm] 缁戝畾
    鈹溾攢鈹€ conv.v          # 绫诲瀷杞崲 [vm] 缁戝畾
    鈹溾攢鈹€ memory.v        # 鍐呭瓨鎿嶄綔 [vm] 缁戝畾
    鈹溾攢鈹€ object.v        # 瀵硅薄鎿嶄綔 [vm] 缁戝畾
    鈹斺攢鈹€ utf8.v        # 瀛楃涓叉搷浣?[vm] 缁戝畾
```

## 缁戝畾姒傝

| 鏂囦欢        | 缁戝畾绫诲瀷                      | 璇存槑                                 |
|:------------|:------------------------------|:-------------------------------------|
| `arith.v`   | `[vm("i32_add/...")]`         | i32/i64/f64 绠楁湳涓庝綅杩愮畻 opcode 缁戝畾 |
| `builtin.v` | `[vm("println/...")]`         | NyarVM 鍐呯疆鍑芥暟缁戝畾                  |
| `cmp.v`     | `[vm("i32_eq/...")]`          | i32 姣旇緝 opcode 缁戝畾                 |
| `control.v` | `[vm("nop")]`                 | 鎺у埗娴?opcode 缁戝畾                   |
| `conv.v`    | `[vm("i32_to_...")]`          | 绫诲瀷杞崲 opcode 缁戝畾                 |
| `memory.v`  | `[vm("alloc/...")]`           | 鍐呭瓨绠＄悊 opcode 缁戝畾                 |
| `object.v`  | `[vm("obj_.../closure_...")]` | 瀵硅薄涓庨棴鍖?opcode 缁戝畾               |
| `utf8.v`  | `[vm("str_...")]`             | 瀛楃涓叉搷浣?opcode 缁戝畾               |

## 涓庡叾浠栭€傞厤鍣ㄧ殑鍏崇郴

`std.adaptor.nyar` 鏄?NyarVM 骞冲彴鐨勯€傞厤灞傦紝涓庡叾浠栧钩鍙伴€傞厤鍣ㄥ苟鍒楋細

| 閫傞厤鍣?              | 骞冲彴        | 缁戝畾灞炴€?          |
|:---------------------|:------------|:-------------------|
| `std.adaptor.nyar`   | NyarVM      | `[vm]`             |
| `std.adaptor.wasm`   | WebAssembly | `[js_builtin]`     |
| `std.adaptor.dotnet` | .NET CLR    | `[dotnet_builtin]` |
| `std.adaptor.jvm`    | JVM         | `[jvm_builtin]`    |
| ...                  | ...         | ...                |

`valkyrie-core` 鎻愪緵涓庤繍琛屾椂鏃犲叧鐨勭函 GGScript 瀹炵幇鍜屾娊璞″０鏄庯紝 鍚勫钩鍙伴€傞厤鍣ㄦ彁渚涘搴旇繍琛屾椂鐨勫叿浣撶粦瀹氥€?
## 缂栬瘧鍛戒护

```bash
# 缂栬瘧涓?NyarVM 瀛楄妭鐮?vcc build --target nyar

# 缂栬瘧涓?NyarVM 骞惰繍琛?vcc run --target nyar
```

## 鐘舵€?
鉁?NyarVM 鎸囦护闆嗙粦瀹氬凡瑕嗙洊 8 涓ā鍧楋紝鍖呭惈 50+ opcode 缁戝畾銆?
