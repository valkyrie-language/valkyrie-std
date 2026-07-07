# `_prelude` — 标准库转发层

本目录是**纯暴露 / 转发层**，不持有任何类型所有权。

## 约定

- **禁止**在此目录定义 nominal type（`unite` / `imply` / `struct` / `enum` / `class`）。
- **只允许** `namespace` 声明与 `using` 转发语句，以及 `⍝` 行注释。
- 真实类型定义归 `core`（如 `core/source/types/Option.v`、`core/source/types/Result.v`，命名空间 `core::types`）。
- 此目录文件通过 `using core::types::{...}` 暴露 `core` 的符号，供 `std` 编译单元使用。
- 未限定名（如 `option_none`、`Some`）通过编译单元全局后缀匹配解析到 `core::types` 的定义。

## 当前转发表

| 文件 | 转发来源 | 转发符号 |
| --- | --- | --- |
| `Option.v` | `core::types` | `Option`、`Some`、`None`、`option_none` |
| `Result.v` | `core::types` | `Result`、`Fine`、`Fail` |

## 编译机制

- `legion` 的 `collect_v_files` 递归扫描 `source/` 下所有子目录（唯一跳过 `compile_only`），`_prelude` 只是普通子目录，无特殊编译器处理。
- `std` 项目通过 `legion.von` 的 `auto_link.core: true` 将 `core` 的源文件合并进同一编译单元（见 `legion/src/planner.rs` 的 `collect_source_closure`）。
- 合并后的源码由 `load_combined_source`（`legion/src/cmds/build/mod.rs`）拼接为单一字符串交由 `ValkyrieCompiler::compile_source` 编译。

## 维护

新增预加载类型时，先将真实定义写入 `core/source/types/`，再在此目录添加只含 `using` 转发的 `.v` 文件。
