⍝ 转发层：`std.types` 命名空间下 `Option` / `Some` / `None` / `option_none`
⍝ 的真实定义位于 `core::types`（见 `core/source/types/Option.v`）。
⍝ 此文件不持有类型所有权，仅通过 `using` 暴露 `core::types` 的符号。
⍝ 未限定名通过编译单元全局后缀匹配解析到 `core::types` 的定义。
namespace std.types;

using core::types::{Option, Some, None, option_none};
