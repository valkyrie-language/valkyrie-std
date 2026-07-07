# Island 架构

VOA / Asgard 支持 **Hybrid Island** 架构（灵感来自 Astro）。页面由多种独立岛屿组成；**默认交付是 SSG**，不是 SSR-first / LiveView。

## 岛屿类型

| 类型 | 说明 | 何时产出 | 状态 |
|:---|:---|:---|:---|
| `static` | 构建期静态 HTML，零 JS | **SSG**（编译时） | **implemented** |
| `hydrated` | AWSL 组件，客户端懒水化 | SSG 壳 + 客户端 WASM/glue | **implemented** |
| `server` | 请求时 HTML **片段**（Atlas） | 可选；按路由/岛按需 | 分类 **implemented**（客户端构建跳过）；渲染 **planned** |
| `wasm` | WASM 重计算组件 | 客户端 | 文档级 / 部分场景 |
| `vue` / `react` | 第三方框架岛 | 客户端 | 配置声明；深度集成视实现 |

**锁定语义**：

- `static` = **SSG**（build-time HTML），不是「服务端渲染整页」。
- `server` = **request-time HTML partial**（由 Atlas 吐片段），不是整站 SSR、不是 LiveView。
- 全站默认：**SSG**；SSR 仅作为可选 server 岛能力。

## 架构原理

```
┌─────────────────────────────────────────────┐
│           index.html（SSG 默认）              │
│                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │  static  │  │ hydrated │  │  server  │  │
│  │ 岛屿 A   │  │ 岛屿 B   │  │ 岛屿 C   │  │
│  │ (SSG)    │  │ (AWSL)   │  │ (Atlas,  │  │
│  │          │  │          │  │  planned)│  │
│  └──────────┘  └──────────┘  └──────────┘  │
│                                              │
│  HydrationScheduler 调度客户端水化           │
└─────────────────────────────────────────────┘
```

- `static`：构建期写入 HTML，永不水化。
- `hydrated`：SSG 占位 + 客户端按需水化。
- `server`：构建期可留槽位；**运行时**由 Atlas 返回 HTML 片段（与 Asgard/VOA 客户端流水线并行，见 [Deploy Profile](../../../../projects/asgard._/projects/asgard/documentation/pages/zh-hans/architecture/deploy-profiles.md)）。

## 水化策略

`HydrationScheduler` 按优先级调度岛屿水化：

1. **视口内岛屿** — 优先水化
2. **即将进入视口** — 预水化
3. **远离视口** — 延迟水化
4. **静态岛屿** — 永不水化
5. **Server 岛屿** — 不走客户端水化；由请求路径填充（planned）

## 定义岛屿

AWSL 组件默认可成为 `hydrated` 岛屿：

```awsl
<island:counter>
  <script>
    let count = 0
  </script>
  <button @click=increment>点击: {count}</button>
</island:counter>
```

路径启发式（`IslandKind`，当前实现）：

- `islands/server/**` → `server`（分类 **implemented**；Asgard 客户端构建**跳过**；Atlas 渲染管线 **planned**）
- `pages/*-report.awsl`、`pages/layout.awsl` → `static`（SSG）
- `charts/*` → `hydrated`
- 其余默认 → `hydrated`

Vue/React 岛屿通过在 `asgard.config.v` 的 `define_config(asgard)` 块中声明：

```v
define_config(asgard) {
    islands {
        vue_components = ["components/chart.vue"]
        react_components = ["components/map.jsx"]
    }
}
```

## 与部署的关系

- 默认 profile（如 `cdn+serverless`）：静态/ hydrated → CDN；server 岛 → Atlas/serverless（可选）。
- 详见 [Deploy Profile](../../../../projects/asgard._/projects/asgard/documentation/pages/zh-hans/architecture/deploy-profiles.md)。
