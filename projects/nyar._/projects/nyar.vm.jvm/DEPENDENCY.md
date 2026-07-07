# nyar.vm.jvm — dependency direction

This package is a **runtime/host shell** for JVM artifacts.

Correct direction:

```
nyar.language → nyar.analyzer → nyar.optimizer → nyar.emitter (jvm lane)
                                      ↓
                         ExecutableModule → classfile / JAR
                                      ↓
                                 nyar.vm.jvm
```

Rules:
- `nyar.vm.jvm` must **not** depend on `nyar.language` or AST packages.
- It may depend on `nyar` (runtime contracts) and JVM host adapters.
- Codegen lives in `nyar.emitter` (`source/jvm/`), consuming **`ExecutableModule`** (full name; not `Exec` / `ExecModule`).
- Do **not** treat language body bypass or type-name special-case emit as the formal path.

Status: documentation shell only (no V sources yet).
