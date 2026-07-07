# atlas.adaptor

Atlas 部署入口桥接 — 平台运行时与 `AtlasHost.process` 之间的薄适配。

## 职责

- `process_request` — `AtlasRequest` → `AtlasHost.process` → `AtlasResponse`
- `process_http` — 原始 HTTP 字节 → 解析 → 处理

不含 VOA 概念，也不含云服务实现（云服务见 `atlas.cloud.*`）。

## 使用

```valkyrie
using atlas.adaptor;
using atlas.adaptor.azure;

let mut host: AtlasHost = build_host()
let req: AtlasRequest = AtlasRequest::new("GET", "/api/health")
let resp: AtlasResponse = process_request(host, req)
```
