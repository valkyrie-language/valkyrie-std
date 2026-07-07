# VOA 插件系统

## 概述

VOA 插件系统允许第三方扩展框架能力，对标 Next.js 插件生态。

## 在管线中的位置

插件不嵌入编译管线内部，而是在管线的关键节点挂载钩子函数。插件系统在编译启动时加载配置（`asgard.config.v`），按优先级排序钩子，在对应事件触发时依次执行。

| 钩子 | 触发阶段 | 说明 |
|:---|:---|:---|
| `before_compile` | ① 之前 | 源码预处理 |
| `after_compile` | ⑦ 之后 | 编译结果后处理 |
| `before_render` / `after_render` | AWSL 渲染前后 | 模板加工 |
| `on_request` | DevServer 运行时 | HTTP 中间件 |
| `before_build` / `after_build` | ⑩ Packaging 前后 | 构建后处理 |

## 插件类型

| 类型 | 说明 | 示例 |
|:---|:---|:---|
| Compiler Plugin | 编译管线钩子 | AWSL 预处理器、自定义优化 |
| DevServer Plugin | DevServer 中间件 | 代理、Mock、日志增强 |
| Renderer Plugin | 渲染扩展 | 自定义 `<Head>` 注入、Script 管理 |
| Route Plugin | 路由中间件 | 认证守卫、重定向、A/B 测试 |
| Build Plugin | 构建后处理 | 压缩、CDN 上传、SourceMap 处理 |

## 插件结构

```valkyrie
struct VoaPlugin
{
    name: utf8,
    version: utf8,
    hooks: [VoaPluginHook],
}

struct VoaPluginHook
{
    event: utf8,
    handler: utf8,
    priority: i32,
}
```

| 字段 | 说明 |
|:---|:---|
| `event` | 钩子事件名 |
| `handler` | 处理函数名 |
| `priority` | 执行优先级，越小越先执行 |

## 内置钩子列表

| 钩子名 | 触发时机 | 参数 |
|:---|:---|:---|
| `before_compile` | 编译开始前 | source_files, target |
| `after_compile` | 编译完成后 | build_result |
| `on_request` | HTTP 请求到达 | request, response |
| `before_render` | AWSL 渲染前 | component, props |
| `after_render` | AWSL 渲染后 | html |
| `on_hmr_update` | HMR 更新广播前 | changed_files |
| `before_build` | 生产构建前 | project_config |
| `after_build` | 生产构建后 | output_files |

## 配置示例（asgard.config.v）

```valkyrie
let plugins: [VoaPlugin] = [
    VoaPlugin {
        name: "voa-plugin-compress",
        version: "0.1.0",
        hooks: [
            VoaPluginHook { event: "after_build", handler: "compress_output", priority: 10 },
        ],
    },
    VoaPlugin {
        name: "voa-plugin-auth-guard",
        version: "0.1.0",
        hooks: [
            VoaPluginHook { event: "on_request", handler: "check_authentication", priority: 1 },
        ],
    },
]
```

## 插件发现机制

1. Legion 包管理系统扫描 `voa-plugin-*` 依赖
2. 读取插件的 `legion.von` 中的 `plugin` 段
3. 按 `priority` 排序执行钩子

## 安全模型

- 插件在沙箱瓦片内运行
- 文件系统访问通过 WASI 接口受限
- 网络请求通过 `[wasm_import]` 声明的白名单