# Asgard UI v1 契约

设备侧由**原生 shim**解码（见 [AOT 原则](aot-principles.md)）；本文描述 wire 二进制格式。

## 段封装（section framing）

宿主制品（dex / Mach-O / wasm）尾段可多次追加 Asgard 段；解码取**最后一段**匹配。

```
magic (8 字节 ASCII) || u32le payload_len || payload
```

| 魔数 | 含义 |
|:---|:---|
| `ASGARDNT` | native AOT 逻辑（Android `.so`、iOS Mach-O 等） |
| `ASGARDUI` | asgard ui wire 包体 |

UI 包体 `payload` 内层再以 `ASGARDUI` 魔数 + 版本字节开头（7 字节魔数 + 1 字节版本 `0x01`）。

## 节点类型

| kind | 名称 | 载荷 |
|:---:|:---|:---|
| 1 | Tag | tag, node_kind, attrs, children |
| 2 | Text | text_parts |
| 3 | If | cond, then_children, else_children |
| 4 | Loop | items_expr, item_var, body |

## If 节点语义

解码器必须保留 `else_children` 为独立子树（见 `asgard.ui` `RenderNode.else_children`），不得展平为兄弟节点。

## 向后兼容

- v1 段可追加在宿主制品末尾多次；解码取**最后一段** Asgard UI wire 匹配。
- 新增节点 kind 仅允许追加偶数编号；旧解码器忽略未知 kind。

## 金样例

`valkyrie.rs/projects/voa/tests/asgard_ui_golden.rs` 对 Counter / If 模板编码快照；四套解码器（Rust encode、V `decode_package`、Kotlin/Swift 生成运行时、JS `mp_ir_runtime`）须与本文一致。

参考实现：[`mobile_ui_binary.rs`](../../../../../../valkyrie.rs/projects/voa/src/codegen/mobile_ui_binary.rs)
