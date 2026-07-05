# atlas.adaptor.azure

Azure 平台部署入口 — 将 HTTP 字节或 `AtlasRequest` 委托给 `AtlasHost.process`。

## 职责

- `build_host()` — 应用 composition root，注册路由
- `handle_http` / `handle_request` — Azure Functions / App Service 入口

不含 VOA 前端或 API Routes 配置；API 由 Atlas Controller / Handler 体系提供。