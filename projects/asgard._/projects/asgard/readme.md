# Asgard 框架核心（`asgard`）

**Asgard** 是 Valkyrie 上的 **GUI 应用框架**：widget 语义、AWSL 表面语法、跨宿主交付契约与运行时能力（DOM、路由、存储等）。

本目录 `valkyrie.v/projects/asgard/` 是框架的 **V 侧库**，不是编译器，也不是 CLI。

| 名称 | 是什么 |
|:---|:---|
| **Asgard** | 框架（本包及 `asgard.router` 等子项目） |
| **Asgard Bifrost** | Asgard 的跨平台自绘渲染引擎（`asgard.bifrost`） |
| **Asgard** | **框架 + CLI**（`asgard build` / `asgard dev` / `asgard pack`） |
| **VOA** | **Rust 编译 crate**（`valkyrie.rs/projects/voa/`，配置文件 `asgard.config.v`） |

文档入口：[documentation/pages/zh-hans/index.md](documentation/pages/zh-hans/index.md)

统一 GUI 编译架构：[architecture/gui-compilation.md](documentation/pages/zh-hans/architecture/gui-compilation.md)
