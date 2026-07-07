# Panda

Panda 是面向 **Python** 的统一工具链。产品形态**借鉴** [Vite+](https://viteplus.dev/)（统一入口 + 自带质量命令），不是「Python 版 Vite+」，也不逐命令对齐 uv / poetry / pip。

与 [Legion](legion.md)、[Noodle](noodle.md) 并列，共同消费中性的 `nyar-package-manager`。分工与分层见 [架构边界](architecture-boundaries.md)。

## 自研边界（硬约束）

| 能力 | 做法 | 禁止 |
|:---|:---|:---|
| CLI | **clap** | — |
| `fmt` / `lint` / `check` | `nyar-analyzer` 合约 + `nyar-language::python` 实现；产品只做路径/选项适配 | `Command::new` 套壳 ruff / black / flake8 / mypy |
| install / add / remove / update | `nyar-package-manager` + 产品层读写 `pyproject.toml` / `requirements*.txt` | 套壳 `uv` / `pip` / `poetry` / `conda` CLI |
| build / run / test | **ScriptRunner** + stdlib `unittest`；产品层注入 `PYTHONPATH` | 套壳 hatch / uv / poetry / pytest；把工具链做成 pip 套壳 |
| 兼容策略 | 读 `[tool.panda]` / `[tool.uv]` / `[tool.poetry]` 等清单参数 | 按 lockfile 猜工具 |

生态细节（pip / poetry / conda 清单形状）留在 panda；**不得**渗入 `nyar-package-manager`。仓库内有 `architecture_guards` 扫描 `src`，防止 `Command::new("uv"|…)` 回潮。

## Install 布局与 PYTHONPATH（适配器 ≠ 调用 pip）

PM 安装落在 `vendors/{registry}/{name}@{version}`，**不**在 PM 内物化 `.venv` / `site-packages`。

`panda run` / `test` / `build` 在产品层设置 `PYTHONPATH`：

1. 项目根
2. `src/`（若存在）
3. 各 `vendors/…` 包根
4. 既有 `PYTHONPATH`（追加）

这是布局适配，不是 `pip install -e` / `uv sync` 套壳。`.venv/` 仍由用户自管（脚手架 `.gitignore` 会忽略它）。

锁文件：`panda-lock.von`；home：`PANDA_HOME` / `.panda`。

## 快速开始

```bash
cargo run -p panda -- create my_pkg
cd my_pkg
cargo run -p panda -- check
cargo run -p panda -- install
```

## 相关

- 源码说明：`valkyrie.rs/projects/panda/readme.md`
- [架构边界](architecture-boundaries.md)
- [Noodle](noodle.md)
- [Legion](legion.md)
