// WASM glue stub — real build emits compiled glue from nyar wasm backend.
export async function instantiate(wasmUrl, imports) {
  const response = await fetch(wasmUrl);
  if (!response.ok) throw new Error('wasm fetch failed');
  const bytes = await response.arrayBuffer();
  const { instance } = await WebAssembly.instantiate(bytes, imports);
  return instance;
}
