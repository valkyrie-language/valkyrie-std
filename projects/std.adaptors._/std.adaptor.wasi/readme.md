# `std.adaptor.wasi`

Valkyrie `WASI` 平台 `SDK`，统一承接 `WASI Component Model` 下的宿主绑定能力。

## 目标

- 统一采用单一 `wasi` 目标口径（含 `wasip3` 包列车）
- 不再考虑已淘汰的 `WASI Preview 1`
- 所有新实现都以 `WASI Component Model` 为准

## 当前范围

- `std.io.now` / `std.io.monotonic`
- `std.console.write` / `write_line` / `error_line`
- `wasi:cli/environment#get-arguments`
- `std.io` FS contract 的 host_provider 骨架（底层仍待完整 cabi）

后续会继续补齐：

- `std.io.fs` 与 `wasi:filesystem/*` 的精确 Canonical ABI
- `std.net` 相关 provider
- 基于真实 `wasi` bind 的 provider 落地

## 编译命令

```bash
vcc build --target wasi
vcc build --target wasip3
```

## 说明

- `host_provider` 从源码属性收集
- 底层 `bind` 继续由 `nyar` 收集
- 字符串稳定 contract 继续优先使用 `utf8`
