# nyar.vm.clr — dependency direction

```
nyar.language → nyar.analyzer → nyar.optimizer → nyar.emitter (clr lane)
    → ExecutableModule → typed MSIL / PE
    → nyar.vm.clr
```

- VM must **not** depend on `nyar.language` or AST packages; it only consumes artifacts.
- CLR lowering lives in `nyar.emitter/source/clr/` and consumes **`ExecutableModule`** (full type name; do not abbreviate as `Exec` / `ExecModule`).
- Formal isomorphic path only. Do **not** document `clr_body_lowering` / `body_source→MSIL` or type-name special-case emit as the architecture.

Status: documentation shell only (no V sources yet).
