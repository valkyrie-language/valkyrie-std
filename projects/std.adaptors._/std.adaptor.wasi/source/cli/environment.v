# WASI command-line environment: argv via wasi:cli/environment.
# Command-world entry is nullary; guests read argv here instead of wasm params.

namespace std.adaptor.wasi.cli;

[wasi("wasi:cli/environment", "get-arguments")]
micro get_arguments(): [utf8]
