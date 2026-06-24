# `std.adaptor.wasi`

Valkyrie `WASI` 平台 `SDK`，统一承接 `WASI Component Model` 下的宿主绑定能力。

## 目标

- 不再区分 `wasip1` / `wasip2`
- 不再考虑已淘汰的 `wasip1`
- 所有新实现都以 `WASI Component Model` 为准

## 当前范围

- `std.io.now`
- `std.io.monotonic`
- `std.adaptor.wasi.lifecycle`：组件实例上下文、资源作用域与能力权限模型

后续会继续补齐：

- `std.io.fs` 相关 provider
- `std.net` 相关 provider
- `std.console` / `std.crypto` 等其他 `wasi` 组件接口能力
- 基于真实 `wasi` bind 的 provider 落地

## 编译命令

```bash
vcc build --target wasi
```

## 说明

- `host_provider` 从源码属性收集
- 底层 `bind` 继续由 `nyar` 收集
- `std.adaptor.wasi` 当前不再发明不存在的底层导入签名，只有仓库中已经真实存在的 `wasi` bind 才会落到 provider
- 字符串稳定 contract 继续优先使用 `utf8`
