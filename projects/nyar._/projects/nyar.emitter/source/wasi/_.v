namespace nyar.emitter.wasi;

# WASI lane adapters — isomorphic to Rust `nyar-emitter` `backend/wasi` + preview train.
# Files:
#   preview.v    — WasiPreview, package versions, cli/run full export names
#   adapt.v      — Preview2/Preview3 import remaps + version stamping (fail-omit p3 gaps)
#   component.v  — WIT command-world text stub (UTF-8); not `std.data.text.valkyrie`
# Consumed by `wasm/host/wasi_cm` (ExecutableModule entry, fail-closed).
