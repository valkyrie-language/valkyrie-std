# std.data.text.valkyrie

Valkyrie source-text models: AST / CST / lexer / `TextSpan` (isomorphic to Rust `std-data::text::valkyrie`).

## Naming (hard rule)

| Concept | Canonical |
|:---|:---|
| Language name | **Valkyrie** |
| Source suffix | **`.v`** |

These name **one** language. Package = full language name (`std.data.text.valkyrie`); on-disk suffix = `.v`.

There is **no** parallel `std.data.text.v` package — do not reintroduce it.

## Owns

- Valkyrie AST / CST / lexer / span models for `nyar.language` consumption

## Does not own

- HIR / MIR / analyze / emit
- Host bindings or target-family artifact formats
- Other text formats (VON / MSIL / WAT / WIT) — those packages model themselves
