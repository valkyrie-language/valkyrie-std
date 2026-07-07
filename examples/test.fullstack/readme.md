# test.fullstack — 全栈金样例

布局目标：`apps/shell` ∥ `apps/atlas` + `packages/domain`（从旧的 `web`/`api`/`shared` 与更早的 `frontend`/`backend` 收紧）。

```
test.fullstack/
├── voa.workspace.v
├── deploy/profiles/          # deploy.profile 示例
│   ├── cdn+serverless.von    # 部分 implemented（静态腿）
│   └── portable.von          # planned
├── apps/
│   ├── shell/                # Asgard / VOA（asgard.config.v，SSG 默认）
│   └── atlas/                # Atlas（atlas.config.von，非 asgard.config）
└── packages/
    └── domain/               # 纯 library（无宿主 config）
```

## 配置边界

| 包 | 配置 | 流水线 |
|:---|:---|:---|
| `apps/shell` | `asgard.config.v` | Asgard/VOA → browser 制品 |
| `apps/atlas` | `atlas.config.von` | Atlas → 服务 / server 岛（planned） |
| `packages/domain` | 仅 `legion.von` | 库；**不要**放 asgard/atlas 宿主配置 |

## 怎么试

```bash
# 在 valkyrie.rs workspace
cargo test -p voa deploy::
cargo build -p voa --bin asgard

# 列出 profiles 目录中的 .von
./target/debug/asgard plan --list ../valkyrie.v/examples/test.fullstack/deploy/profiles

# 校验金样例 deploy profile 并打印制品矩阵（不构建）
./target/debug/asgard plan --profile ../valkyrie.v/examples/test.fullstack/deploy/profiles/cdn+serverless.von

# 仅 shell SSG 构建（需在 apps/shell 目录，且工具链可用时）
asgard build
```

## 状态

| 项 | 状态 |
|:---|:---|
| 目录与配置边界 | **implemented**（本样例） |
| `asgard plan` 校验 / 列表 / 矩阵 | **implemented** |
| Atlas server 岛 HTML 片段 | **planned** |
| `portable` 单宿主打包 | **planned** |
| shell ↔ atlas 真实 HTTP 联调 | 样例壳；联调 **planned** |

详见 [Deploy Profile](../../projects/asgard._/projects/asgard/documentation/pages/zh-hans/architecture/deploy-profiles.md)、[Island 架构](../../documentation/pages/zh-hans/guides/island-architecture.md)。
