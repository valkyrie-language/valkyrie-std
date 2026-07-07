# npm 与 JSR 发布策略

Valkyrie 在 JavaScript 生态的 **主要发布平台** 为 [npm](https://www.npmjs.com/) 与 [JSR](https://jsr.io/)。CLR 轨继续以 NuGet 为主；二者服务不同目标，不互相替代。

## 平台分工

| 平台 | 适合发布 | 典型包名 | `legion publish` |
|:---|:---|:---|:---|
| **npm** | CLI 工具、带 bin 的全局命令、通用 JS 库 | `@valkyrie-language/legion` | `--registry npm` |
| **JSR** | 模块化库、TypeScript 友好、标准库切片 | `@valkyrie/std` | `--registry jsr` |
| NuGet | .NET / CLR 工具 | `Valkyrie.Legion` | `type: "nuget"` |

## `legion.von` 配置

### 默认 registry

```von
publishConfig: {
    registry: "npm",
    access: "public",
    tag: "latest"
}
```

未传 `--registry` 时，`legion publish` 使用 `publishConfig.registry`；多目标时按 `publish[]` 数组逐项发布。

### 多目标发布

```von
publish: [
    {
        target: "node",
        type: "npm",
        package_id: "@valkyrie-language/legion",
        version: "0.1.0"
    },
    {
        target: "node",
        type: "jsr",
        package_id: "@valkyrie/legion-tools",
        version: "0.1.0"
    }
]
```

- `target`：构建目标（Node 轨为 `node` → `wasm32-node-unknown-wasm`）。
- `type`：`npm` / `jsr` 触发 registry 打包；`web-app` 等格式走产物发布路径。
- `package_id`：注册表上的包标识（npm scope 或 JSR scope/name）。

### 依赖消费

```von
dependencies: {
    "left.pad": {
        version: "2.0.0",
        source: "registry",
        registry: "npm"
    },
    "std.codec": {
        version: "0.4.0",
        source: "registry",
        registry: "jsr"
    }
}
```

规划器默认 `registry: "npm"`；安装路径为 `vendors/{registry}/{name}@{version}/`。

## 构建产物（Node 轨）

```bash
legion build . --target node -o dist/node
```

期望产物（自举契约）：

- `legion.mjs` — Node 入口胶水
- `legion.wasm` — WASM 模块
- `run-contracts.txt` — 运行契约（比对用）

发布前须通过：

```bash
node scripts/bootstrap-node.mjs
```

## 认证

```bash
legion vendor login npm
legion vendor login jsr
legion whoami
```

令牌写入 `~/.valkyrie/` 凭证存储；JSR 可使用官方 token 或环境变量（见 `legion vendor login jsr --help`）。

## 发布流程

```bash
legion build --target node
legion pack
legion publish --registry npm --dry-run
legion publish --registry npm
legion publish --registry jsr
```

JSR 包使用 flat tarball 布局（无嵌套 `package/` 目录），由 `legion publish` 自动设置。

## 与自举的关系

- **开发 / 验收**：`legion.tools` 的核心依赖（`nyar`、`std`）必须用 **workspace** 成员，不能用 npm/jsr 包顶替（见 [bootstrap-contract](../../../projects/legion._/projects/legion.tools/documentation/pages/zh-hans/bootstrap-contract.md)）。
- **分发 / seed**：公开发布的 npm / JSR 包可作为下游用户的 **seed**（仅 `源码→v1`），但同一轮自举验收中不得用 registry 包伪造 workspace 前置门。

## 相关文档

- [包发布](./publishing.md)
- [编译器自举契约](../../../projects/legion._/projects/legion.tools/documentation/pages/zh-hans/bootstrap-contract.md)
- [Canonical Target — `node` 三元组](../developer/target-triples.md)
