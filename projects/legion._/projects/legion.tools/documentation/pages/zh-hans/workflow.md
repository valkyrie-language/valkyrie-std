# 工作流

## 目标

本文定义 `legion.tools` 视角下的 `Valkyrie` 工程工作流。

重点说明三件事：

- `legion.tools` 如何作为开发者与 `CI` 的统一入口
- `legion.tools` 如何调用 `source/valkyrie` 与 `nyar`
- `legion.tools` 应整合哪些流程，以及绝不能越过哪些边界

本文描述的是长期工作流结构，不等同于“当前所有代码都已经拆完”。

## 调用链

`legion.tools` 自己知道并组织如下调用链：

```text
用户 / CI
    -> legion.tools
    -> app.v / cli.v
    -> commands/build.v | commands/publish.v | commands/pack.v
    -> source/valkyrie
    -> nyar
    -> target family / runtime / packaging
```

在这条链路里：

- `source/valkyrie` 负责前端解析、绑定、类型检查与诊断
- `nyar` 负责 `OA / EGraph / PE` 元优化核心
- `legion.tools` 负责把创建、构建、测试、运行、打包、发布等工作流编排起来

当前实现中，这些命令逻辑仍主要集中在 `source/_.v`；但长期应迁移到 `commands/*.v`。

## 命令层结构

长期建议的命令层结构如下：

- `app.v` 或 `cli.v`：最薄的命令路由层
- `commands/build.v`：`build` 命令编排
- `commands/publish.v`：`publish` 命令编排
- `commands/pack.v`：`pack` 命令编排
- `cli_args.v`：命令行参数解析与共享 CLI 参数 helper
- `paths.v`：路径归一、项目目录与输出目录解析
- `requests.v`：`BuildRequest` 等共享请求结构
- `nyar_driver.v`：`nyar_driver_compile_project` 后端执行入口

## `legion.tools` 负责什么

`legion.tools` 应负责：

- 项目创建与初始化
- workspace、依赖与配置解析
- 调用 `source/valkyrie` 执行前端分析
- 串联构建、测试、运行、打包、发布工作流
- 组织缓存、产物目录与交付记录

它的职责是编排，不是重新实现语义。

更具体地说：

- 顶层入口负责命令分发
- `commands/*` 负责各自子命令编排
- `cli_args.v` 负责参数解析
- `paths.v` 负责路径相关 helper
- `requests.v` 负责共享请求结构
- 构建上下文与编译计划应继续交给更下层模块
- 宿主桥调用应收口在独立桥接层，而不是散落在多个命令文件里

## `legion.tools` 不负责什么

`legion.tools` 不应负责：

- 重新实现一套 `Valkyrie` parser、binder 或 type checker
- 自己维护一套平行的优化主线
- 自己定义 `OA / EGraph / PE` 核心协议
- 把工具层临时状态抬升成语言语义事实

一旦工具层开始复制前端或核心层实现，后续维护成本会急剧上升。

同样不应做的还有：

- 把所有命令继续长期堆在 `_.v`
- 让 `publish` 直接复制一整份 `build` 流程
- 让宿主桥声明混回命令编排层

## 输入与输出

`legion.tools` 的典型输入包括：

- workspace 清单
- 项目配置
- 依赖信息
- 构建、测试、发布等命令参数

`legion.tools` 的典型输出包括：

- 构建计划
- 执行中的工作流状态
- 产物目录与交付记录
- 面向开发者与 `CI` 的诊断汇总

## 设计要求

- 与 `source/valkyrie` 之间保持清晰接口
- 与 `nyar` 之间保持清晰调用边界
- 与 `build_context.v`、`build_planner.v` 之间保持清晰模块边界
- 新工作流优先整合现有实现
- 不新增平行 parser、平行 binder、平行 optimizer
- 不让工具层变成新的语义核心
- 优先把命令逻辑拆入 `commands/*.v`，而不是继续膨胀 `_.v`

## 长期目标

- 为 `Valkyrie` 提供统一、稳定的工程入口
- 保持构建与包管理职责清晰
- 避免工具层反向污染核心库与前端分析层
- 优先整合现有工作流，而不是继续膨胀出一大堆平行实现

## 用户文档（`legion doc`）

`valkyrie.v` 的用户文档是**仓库内的 Markdown 源文件**，由 `legion doc` 编译为静态 HTML 站点。文档描述的是语言、工具链与工程约定；**不是** Rust crate 文档，也**不是** `cargo doc` 产物。

### 两类交付物（不要混写）

| 交付物 | 源 | 命令 | 产出目录 | 用途 |
|:---|:---|:---|:---|:---|
| **用户文档** | `documentation/pages/**/*.md` | `legion doc` | `dist/legion-document/` | 语言/工具链/项目说明，长期托管 |
| **CI 报告** | 测试/基准/覆盖率运行结果 + `legion.report` 皮肤 | `legion test` / `legion bench` / `legion coverage` | `dist/legion-test/` 等 | 单次运行的 HTML 报告，非文档站 |

用户文档与 CI 报告共用 AWSL 静态渲染与 Islands 能力，但**源文件位置、命令入口、读者场景完全不同**。

### 文档源约定

```text
valkyrie.v/
├── documentation/pages/zh-hans/          # 仓库总入口文档
│   ├── index.md
│   ├── language/
│   ├── guides/
│   ├── toolchain/
│   ├── developer/
│   └── maintainer/
└── projects/<pkg>/documentation/pages/ # 各包自有文档（可选）
    └── zh-hans/
        └── index.md
```

规则：

- 正文一律 **Markdown**（`.md`），放在 `documentation/pages/` 下
- 默认语言目录为 `zh-hans/`；根站按 `{language,guides,toolchain,developer,maintainer}/**/*.md` 分区
- 若 `zh-hans/` 下无上述子目录，则直接渲染该目录内全部 `.md`
- 各 `projects/*` 包可自带 `documentation/pages/`，写本包职责与契约；通过相对路径链到根站（见 `asgard`、`plotter` 现有写法）
- `readme.md` 只做入口指针，**不替代** `documentation/pages/` 正文

### 构建与产出

```bash
# 单项目（默认 dist/legion-document/）
legion doc .

# 指定输出目录
legion doc . -o ./dist/legion-document

# workspace：聚合各 member 的 documentation/pages/
legion doc . --workspace
```

```text
dist/legion-document/
  index.html              # 根 hub
  legion-document.css
  doc/
    index.html            # 用户文档目录
    {section}/            # 如 zh-hans/toolchain/legion.html
```

页面壳层与导航由文档 AWSL 布局模板渲染；Markdown 正文注入布局槽位。实现细节在工具链侧，**本文档层只约定源路径与产出形状**。

`api/` 参考文档尚未纳入 `legion doc`，计划在后续阶段与 `documentation/pages/` 对齐。

### 跨包引用

- 根站 `valkyrie.v/documentation/pages/zh-hans/`：语言、通用工具链、开发者/维护者主线
- 项目站 `projects/<pkg>/documentation/pages/zh-hans/`：该包的架构、平台、契约（如 `asgard`、`legion.tools`、`plotter`）
- 短页可只做跳转 hub（`guides/*.md` → `projects/asgard/documentation/...`），避免双份维护

## CI 报告（`legion test` / `bench` / `coverage`）

报告**不是** `documentation/pages/` 的一部分。皮肤与布局在独立包 **`projects/legion._/projects/legion.report`**：

```text
legion.report/
├── source/
│   ├── pages/          # 报告页 AWSL（test / coverage / bench）
│   ├── charts/         # 图表路由薄包装（引用 asgard.plotter）
│   └── assets/         # 报告基础样式
└── legion.von
```

分工：

- **`legion.report`**：页面壳、图表 widget 包装、CSS；不含业务 series 数据
- **`asgard.plotter`**：交互柱图组件（`InteractiveColPlot`）
- **`legion` 命令**：收集测试结果，归一化 series，填充 `__TITLE__` / `__SERIES__` 占位符后渲染

表格与摘要走**静态岛**；交互柱图走 **hydrated 岛**（WASM + 组件胶水），与 Asgard browser 交付物同族。

### 报告交付模式

| 模式 | 产出 | 打开方式 |
|:---|:---|:---|
| 默认 | `dist/legion-test/index.html` + `boot.js` + `manifest.json` + wasm/胶水 | 本地 HTTP（`file://` 下 `fetch`/`import` 受限） |
| `--standalone` | 同上目录下的 `standalone.html`（单文件，内联资源） | 双击 / `file://` 离线查看 |

```bash
legion test .              # dist/legion-test/index.html
legion test . --standalone # 额外生成 standalone.html
```

`--standalone` 仅影响报告打包形态，**不改变** `legion doc` 与用户文档约定。


## CLR 自举（当前）

`build_planner.v` 的后端执行模式已统一为 `nyar_driver`：

- 公共入口：`nyar_driver.v` → `nyar_driver_compile_project`
- 要求：v1/v2 产物在本进程内完成 `FrontendBuildOutput → nyar-driver`，不得委托 seed 或外部 bridge

验收脚本：

- `valkyrie.v/scripts/bootstrap-clr.mjs` — 完整 L2（legion.tools v1→v2）
- `valkyrie.v/scripts/bootstrap-smoke-clr.mjs` — smoke 切片（v1 真编译 `examples/bootstrap-smoke`）

Rust 对等入口：`legion bootstrap --project <legion.tools>`。