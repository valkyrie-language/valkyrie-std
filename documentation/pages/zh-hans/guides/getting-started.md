# VOA 快速开始

## 概述

VOA（Valkyrie of Asgard）是 Valkyrie 生态的全栈开发框架，对标 Next.js 的全栈体验但使用纯 GGScript + AWSL。

## 核心特性

| 特性 | 说明 |
|:---|:---|
| Islands 架构 | 前端使用 AWSL 模板语言，编译到细粒度响应式 |
| SSR / SSG | 服务端渲染引擎 + 编译时静态生成 |
| 文件路由 | `pages/` 目录自动路由 + 动态参数 + 嵌套 Layout |
| WASM + WASI | 全栈编译到 WebAssembly |
| PWA | Service Worker + Manifest + 离线回退 |
| DevServer | 开发服务器 + WebSocket HMR + Error Overlay |
| CLI | `voa` 命令全闭环 |

## 安装

```bash
legion install voa-cli
```

## 创建项目

```bash
voa new my-app --template webapp
```

可选模板：`webapp`、`api`、`dashboard`、`fullstack`

## 项目结构

```
my-app/
├── voa.config.v          # 项目配置
├── source/
│   ├── main.v            # 入口 GGScript 代码
│   └── Hello.awsl        # AWSL 模板组件
├── pages/                # 文件路由目录
│   ├── index.awsl        # 首页 → /
│   ├── about.awsl        # 关于页 → /about
│   └── user/
│       └── [id].awsl     # 动态路由 → /user/:id
├── components/           # 共享组件
├── styles/               # 全局样式
└── public/               # 静态资源
```

## CLI 命令参考

| 命令 | 说明 |
|:---|:---|
| `voa new` | 创建新项目 |
| `voa init` | 初始化项目 |
| `voa dev` | 启动开发服务器 |
| `voa build` | 生产构建 |
| `voa start` | 启动生产服务器 |
| `voa test` | 运行测试 |
| `voa check` | 代码检查 |
| `voa fmt` | 代码格式化 |
| `voa clean` | 清理构建产物 |
| `voa publish` | 发布包 |
| `voa add` | 添加依赖 |
| `voa remove` | 移除依赖 |
| `voa install` | 安装依赖 |
| `voa benchmark` | 运行基准测试 |
| `voa coverage` | 代码覆盖率 |

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

```awsl
<script>
    let count: i32 = 0
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

## 部署

```bash
voa build --ssr --pwa
```

产物输出到 `dist/` 目录：

```
dist/
├── index.html
├── main.wasm
├── main.js
├── voa-runtime.js
├── sw.js              # --pwa
├── manifest.json      # --pwa
└── offline.html       # --pwa
```

```bash
voa start --port 3000
```