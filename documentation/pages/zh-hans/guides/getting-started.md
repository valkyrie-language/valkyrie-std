# VOA 快速开始

## 概述

VOA（Valkyrie of Asgard）是 Valkyrie 生态里 **Asgard GUI** 的编译实现（Rust crate `voa`，用户 CLI 为 `asgard`）。前端默认 **SSG**；可选 Atlas **server 岛 HTML 片段**，不是 SSR-first / LiveView。

## 核心特性

| 特性 | 说明 | 状态 |
|:---|:---|:---|
| Islands | AWSL 模板；`static`=SSG，`hydrated`=客户端水化 | **implemented** |
| SSG（默认） | 构建期静态 HTML | **implemented** |
| Server 岛（可选） | Atlas 按请求返回 HTML 片段 | **planned** |
| 文件路由 | `pages/` 约定路由 | **implemented**（约定随模板） |
| 多平台制品 | 同一源码按 `platform` 出制品；deploy profile 选拓扑 | 构建矩阵 **implemented**；编排 **planned** |
| DevServer | `asgard dev` + HMR（browser） | **implemented** |
| CLI | `asgard build` / `dev` / `pack` / `plan` | `plan` = profile 校验+矩阵 |

## 安装

```bash
# 从 valkyrie.rs workspace 构建 CLI
cargo build -p voa --bin asgard
```

## 创建项目

```bash
# 视模板工具是否落地；金样例见 examples/test.fullstack
```

可选方向：`webapp`、`api`、`fullstack`（以仓库 examples 为准）。

## 项目结构（单前端）

```
my-app/
├── asgard.config.v          # Asgard / VOA 客户端配置
├── source/
│   ├── main.v
│   └── Hello.awsl
├── pages/                   # 文件路由（SSG）
│   ├── index.awsl
│   └── about.awsl
├── components/
├── styles/
└── public/
```

全栈金样例布局见 [`examples/test.fullstack`](../../../examples/test.fullstack/readme.md)：`apps/shell`（asgard）∥ `apps/atlas`（atlas）∥ `packages/domain`。

## CLI 命令参考

| 命令 | 说明 | 状态 |
|:---|:---|:---|
| `asgard build` | 按 `asgard.config.v` 生产构建 | **implemented** |
| `asgard dev` | 开发构建 +（browser）HMR | **implemented** |
| `asgard pack` | 组装 apk / ipa / mini-program / mini-game | **implemented** |
| `asgard plan` | 校验 deploy profile / `--list` 列出 / 打印制品矩阵 | **implemented**（不编排构建） |
| `asgard fmt` | 格式化 `.v` / `.awsl` 等 | **implemented** |

## AWSL 组件

### 基本语法

```awsl
<widget name="MyComponent">
    <div class="container">
        <h1>{title}</h1>
        <p>{message}</p>
        <if condition={loading}>
            <span>Loading...</span>
        <else/>
            <span>{data}</span>
        </if>
    </div>
</widget>

<script>
    let title: string = "Hello VOA"
    let message: string = "Welcome to AWSL"
    let loading: bool = false
    let data: string = ""
</script>

<style scoped>
    .container {
        padding: 16px;
        max-width: 800px;
        margin: 0 auto;
    }
</style>
```

### 响应式状态

使用 **`let mut`** 声明响应式变量（Solid 语义，编译进 WASM）。普通 `let` 为非响应式常量。

```awsl
<script>
    let mut count: i32 = 0
</script>

<button on:click={() => count = count + 1}>
    Clicked {count} times
</button>
```

### 列表渲染

```awsl
<loop user in {users}>
    <div class="user-card">{user}</div>
</loop>
```

### 动态路由

```
pages/
├── index.awsl          → /
├── about.awsl          → /about
├── blog/
│   └── [slug].awsl     → /blog/:slug
└── user/
    └── [id]/
        └── index.awsl  → /user/:id
```

## 标准函数

| 模块 | 可用函数 |
|:---|:---|
| `console` | `log` / `warn` / `error` / `debug` / `info` |
| `fetch` | `fetch(url)` / `fetch_with_options(url, options)` |
| `json` | `parse_json(raw)` / `stringify_json(value)` |
| `storage` | `get_local(key)` / `set_local(key, value)` / `remove_local(key)` / `clear_local()` |
| `url` | `parse_url(url)` / `encode_uri_component(value)` |
| `dom` | `query_selector(selector)` / `set_element_text(id, text)` / `add_class(id, class)` / `remove_class(id, class)` |
| `math` | `abs` / `ceil` / `floor` / `round` / `sqrt` / `random` |
| `timer` | `set_timeout(delay_ms)` / `set_interval(interval_ms)` / `clear_timer(id)` / `now_ms()` |
| `crypto` | `uuid()` / `sha256(data)` / `encode_base64(data)` / `decode_base64(encoded)` |
| `performance` | `mark(name)` / `measure(name, start)` / `now_perf()` |
| `types` | `type_of(value)` / `is_string` / `is_number` / `is_bool` / `is_array` / `is_map` / `parse_int` / `parse_float` / `to_string` |

## 构建与部署

默认（SSG，browser 平台）：

```bash
asgard build
```

产物通常在 `dist/`（以 `asgard.config.v` 的 `build.output` 为准），例如：

```
dist/
├── index.html
├── boot.js
├── *.wasm
└── c/*.js             # 组件胶水
```

用 deploy profile 查看将构建的制品矩阵（**不**执行编排）：

```bash
asgard plan --list deploy/profiles
asgard plan --profile deploy/profiles/cdn+serverless.von
```

说明：

- **没有**已实现的 `asgard build --ssr` / `--pwa` 开关；旧文档中的该写法已废弃。
- PWA（`sw.js` / `offline.html`）与整站 SSR：**planned**。
- 可选 server 岛与拓扑见 [Deploy Profile](../../../../projects/asgard._/projects/asgard/documentation/pages/zh-hans/architecture/deploy-profiles.md) 与 [Island 架构](island-architecture.md)。
