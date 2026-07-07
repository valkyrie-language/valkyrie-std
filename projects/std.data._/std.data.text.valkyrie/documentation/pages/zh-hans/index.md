# std.data.text.valkyrie

Valkyrie 源码文本模型包：AST / CST / 词法 / `TextSpan`（同构自 Rust `std-data::text::valkyrie`）。

## 命名约定（硬约束）

| 概念 | 正式写法 |
|:---|:---|
| 语言名 | **Valkyrie** |
| 源码后缀 | **`.v`** |

二者是**同一门语言**的名称与文件后缀，不是两门语言。

- 包名用全称：`std.data.text.valkyrie`
- **`.v` 只是源文件后缀**，不存在平行包 `std.data.text.v`
- 勿把后缀与语言名读成两套前端

## 职责

- 拥有 Valkyrie 源码的 AST / CST / lexer / span 模型
- 供 `nyar.language` 前端消费；AST **不**长期放在 `nyar.language/source/valkyrie`

## 非职责

- 不做 HIR / MIR / 分析 / 发射
- 不定义宿主绑定或 target family 产物格式
- 其他文本格式（VON / MSIL / WAT / WIT）各自建模，不经本包冒充 Valkyrie
