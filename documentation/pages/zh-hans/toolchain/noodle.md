# Noodle

Noodle 是面向 **Node.js / Web** 的统一工具链。产品形态**借鉴** [Vite+](https://viteplus.dev/)（一个入口覆盖包管理 + `fmt` / `lint` / `check`），**不是** Vite+ / npm / pnpm 换皮或逐命令对齐。

与 [Legion](legion.md)、[Panda](panda.md) 并列，共同消费中性的 `nyar-package-manager`。分工与分层见 [架构边界](architecture-boundaries.md)。

## 自研边界（硬约束）

| 能力 | 做法 | 禁止 |
|:---|:---|:---|
| CLI | **clap** | — |
| `fmt` / `lint` / `check` | `nyar-analyzer` 合约 + `nyar-language::javascript` 实现；产品只做路径/选项适配 | `Command::new` 套壳 Biome / Prettier / ESLint / Vite |
| install / add / remove / update | `nyar-package-manager` + 产品层 `package.json` 翻译 + `node_modules` 布局适配 | 套壳 `npm` / `pnpm` / `yarn` / `bun` CLI |
| build / run / test / exec | 读 `package.json` `scripts.*`，经 **ScriptRunner** 跑**用户**脚本 | 把工具链自身做成 npm/pnpm/vite 套壳 |
| 兼容策略 | 读 `package.json`（`noodle.compat` / `packageManager`） | 按 `package-lock.json` / `pnpm-lock.yaml` 等猜工具 |

`nyar-package-manager` 保持产品/生态身份中立：Node / npm / pnpm 概念只留在 noodle。仓库内有 `architecture_guards` 扫描 `src`，防止 `Command::new("npm"|…)` 回潮。

## Install 布局（适配器 ≠ 调用外部 CLI）

PM 仍写入 `vendors/{registry}/{name}@{version}`。Noodle 按 compat **物化** `node_modules`（symlink/junction，失败则 copy）：

| Compat | 布局 |
|:---|:---|
| `npm` / `yarn` / `bun`（默认） | 扁平 `node_modules/{name}` |
| `pnpm` | A-lite pnpm-like：`node_modules/.pnpm/{id}/node_modules/{name}` + 顶层链接 |

这是自研布局适配，**不是**调用 pnpm/npm CLI，也不追求完整 hoisting / peer / store 对齐。

锁文件：`noodle-lock.von` 为真相源；外来 lockfile 忽略（最多提示）。

## 快速开始

```bash
cargo run -p noodle -- create my-app
cd my-app
cargo run -p noodle -- check
cargo run -p noodle -- install
```

## 相关

- 源码说明：`valkyrie.rs/projects/noodle/readme.md`
- [架构边界](architecture-boundaries.md)
- [Panda](panda.md)
- [Legion](legion.md)
