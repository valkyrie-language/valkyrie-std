# nyar.vm.wasm — dependency direction

This package is a **runtime/host shell** for Wasm / WASI artifacts.

Correct direction:

```
nyar.language → nyar.analyzer → nyar.optimizer → nyar.emitter (wasm / wasi lanes)
                                      ↓
              ExecutableModule → .wasm (+ JS glue | wasip2/wasip3 CM)
                                      ↓
                                 nyar.vm.wasm
```

Rules:
- `nyar.vm.wasm` must **not** depend on `nyar.language` or AST packages.
- Emitter owns `ExecutableModule`→wasm-gc and host shells (`source/wasm/`, `source/wasi/`).
- VM runs/loads artifacts; it does not lower language AST.
- Type names use full forms (`ExecutableModule`, …); do not abbreviate as `Exec` / `ExecModule`.

Status: documentation shell only (no V sources yet).
