# gnosis._

`gnosis._` 是面向游戏开发的**元游戏引擎 / 基础设施**顶层 workspace。

## 原则

- `gnosis._` 承载游戏基础设施层，而不是直接等同于某个具体引擎产品
- Unity / Godot 宿主桥接分别留在 `unity._`、`godot._`
- 不把宿主适配和引擎核心混成一个 God package
- 公共图形栈由 `gnosis._` 承载，供 `asgard.bifrost` 与 `titan` 复用

## 游戏开发三层

为了避免“元引擎”“具体引擎”“语言扩展”混成一团，`gnosis._` 当前按三层来理解：

| 层级 | 职责 | 当前原则 |
|:---|:---|:---|
| **游戏引擎产品层** | 编辑器、项目系统、资源工作流、发布流程 | `Genesis` 与 `Unity / Godot / Unreal` 应按并列产品理解 |
| **游戏开发语义层** | 场景、实体、组件、系统、输入、动画、UI、任务、网络 | 可由语言扩展与引擎框架共同承载 |
| **游戏基础设施层** | graphics、runtime、asset、scene、physics、toolchain | 由 `gnosis._` 承载 |

这里的关键点是：`gnosis._` 更接近“元游戏引擎层”，而不是“直接对外的唯一具体游戏引擎品牌”。

## 当前状态

规划中，正在先把共享图形底座拆成稳定子包，避免 GUI / game / deep learning 各造一套 GPU / text / layout。

## 计划中的子包

- `projects/gnosis`
- `projects/gnosis.gpu`
- `projects/gnosis.text`
- `projects/gnosis.layout`
- `projects/gnosis.render`
- `projects/gnosis.scene`
- `projects/gnosis.physics`
- `projects/gnosis.asset`
- `projects/gnosis.tools`

## 公共图形栈职责

- `gnosis.gpu`：共享 GPU / compute / device / queue / resource 契约
- `gnosis.text`：字体、fallback、shaping、glyph atlas、段落布局
- `gnosis.layout`：constraints、intrinsic size、flex / grid / scroll 等布局协议
- `gnosis.render`：统一 draw list / render graph / frame submission
- `gnosis.scene`：2D / 3D scene graph、camera、light、visibility
- `gnosis.asset`：mesh / image / material / font / shader module 等图形资源

这里的关键点不是“让游戏引擎吞掉一切”，而是把图形基础设施放在最接近其本体的位置：`asgard` 持有 GUI 语义，`titan` 持有深度学习语义，而 `gnosis` 持有共享图形底座。

## ECS 语言扩展

ECS 语言扩展当前建议拆成两层，而不是直接写成 `Genesis` 私有 DSL：

### 通用核心

更适合作为跨引擎的游戏开发核心语义：

- `component`
- `system`
- `query`
- `resource`
- `event`
- `schedule`

### 引擎专属扩展

由具体引擎产品在其框架层追加：

- `scene`
- `prefab`
- `quest`
- `dialogue`
- `world`

是否最终形成 `Genesis` 专属扩展，还是进一步抽成 `Unity / Godot / Cocos` 也能共用的更高层语义，目前先不写死。

## 生态关系

- `asgard.bifrost` 复用 `gnosis.layout`、`gnosis.text`、`gnosis.render`、`gnosis.gpu`
- `titan` 复用 `gnosis.gpu` 的 compute / memory / sync 契约，不再发明第二套 GPU device model
- `Genesis` 一类具体游戏引擎产品应消费 `gnosis._` 的基础设施，而不是反过来定义其底座边界

文档入口：[documentation/pages/zh-hans/index.md](documentation/pages/zh-hans/index.md)
