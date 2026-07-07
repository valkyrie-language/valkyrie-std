# AWSL 組件 ABI 與響應式語義最小擴展

狀態：Implemented（Draft RFC 落地）

## 核心語法

| 用途 | 語法 |
|:---|:---|
| 組件輸入 | `[property] let name;` / `[property] let name = default;` |
| 內部狀態 | `let mut name = expr;` |
| 派生值 | `let name = expr;`（自動重算） |
| 快取派生 | `[memoize] let name = expr;` |
| 輸出事件 | `[event] micro event_name(args...) { }`（必須空 body） |
| 觸發事件 | `emit(event_name, args...)` |
| 副作用 | `effect(deps) { ... }` |
| 模板綁定 | `:snake_case` / `@snake_case` |

## 實作位置

- **Parser（最小微改）**：[`valkyrie.rs/projects/std-data/src/text/valkyrie/parser/`](../../../../../../valkyrie.rs/projects/std-data/src/text/valkyrie/parser/) — widget body 支援 `[attr] let` / expression statements
- **ABI 提取**：[`valkyrie.rs/projects/std-data/src/text/awsl/abi/`](../../../../../../valkyrie.rs/projects/std-data/src/text/awsl/abi/)
- **編譯 / 跨檔校驗**：[`valkyrie.rs/projects/asgard/src/awsl/abi_index.rs`](../../../../../../valkyrie.rs/projects/asgard/src/awsl/abi_index.rs)
- **Wire v2**：[`valkyrie.rs/projects/asgard/src/codegen/mobile_ui_binary.rs`](../../../../../../valkyrie.rs/projects/asgard/src/codegen/mobile_ui_binary.rs) — `ASGARDUI` + `0x02` + ABI 段
- **LSP 診斷**：[`valkyrie.rs/projects/nyar-language/src/valkyrie/lsp/handlers/awsl/diagnostics.rs`](../../../../../../valkyrie.rs/projects/nyar-language/src/valkyrie/lsp/handlers/awsl/diagnostics.rs)
- **JetBrains**：`AwslAbiAttributeInspection`、語義高亮 `SYM_ABI_*`

## 範例

見 [`Switch.awsl`](../../../../../../valkyrie.v/projects/asgard._/projects/asgard.ui.core/source/components/Switch.awsl)。

## 遷移

- `emit("name", payload)` → 宣告 `[event] micro name(...) { }` + `emit(name, ...)`
- 隱式 prop `let x = default` → `[property] let x = default`
- camelCase → snake_case
