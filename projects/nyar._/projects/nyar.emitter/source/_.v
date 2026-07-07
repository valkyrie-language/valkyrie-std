namespace nyar.emitter;

# Crate root — isomorphic entry for `nyar-emitter`.
# Pipeline: language → analyzer → optimizer → emitter (this crate).
# Backends (symmetric under `source/`):
#   clr/     ExecutableModule → typed MSIL (`std.data.text.msil`) → text/PE
#   jvm/     ExecutableModule → ClassFile (`std.data.binary.class`)
#   wasm/    ExecutableModule → typed opcodes → wasm bytes (`std.data.binary.wasm`) + host/{js_glue,wasi_cm}
#   wasi/    wasip2|wasip3 preview adapters + adapt/component (consumed by wasm wasi_cm)
# Neutral view: `executable.v` (ExecutableModule) — shared by clr/jvm/wasm/wasi.
# Encoding: IR uses language UTF-8; CLR/JVM/JS hosts store UTF-16 — transcode at lane
# boundaries (`string_encoding.v` for MSIL ldstr). `Utf8Text.length`/`slice` = Unicode
# scalars (never flatten to host String.get_Length / JS .length). `Utf16Text` = code units.
# WASI CM paths / WIT ids = UTF-8 **bytes** at the boundary; JS `env.utf8_*` = scalars.
# Language AST package is `std.data.text.valkyrie` (not `std.data.text.v`).
# Format packages: `std.data.binary.class` / `std.data.binary.jar` (never `binary.jvm`).
# VM packages (`nyar.vm.*`) consume artifacts — they must NOT depend on language.
