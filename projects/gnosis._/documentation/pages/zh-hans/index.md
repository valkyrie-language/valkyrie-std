# Gnosis 元游戏引擎

`gnosis._` 是面向游戏开发的**元游戏引擎 / 基础设施主线**，不是 Unity / Godot 的宿主桥接，也不直接等同于某个具体游戏引擎产品品牌。

## 定位

- 游戏基础设施与运行时边界
- 渲染、场景、资源与物理等子系统的长期承载点
- `GUI / 2D / 3D / compute` 共享图形底座的正式承载点
- 面向 `valkyrie` 生态的自研引擎能力

## 游戏开发三层

当前建议把游戏开发相关能力拆成三层理解：

| 层级 | 说明 |
|:---|:---|
| **游戏引擎产品层** | `Genesis` 与 `Unity / Godot / Unreal` 应按并列产品定位理解；`Cocos` 是否纳入正式并列范围暂未定案 |
| **游戏开发语义层** | 场景、实体、组件、系统、输入、动画、UI、任务、网络、Mod 等开发语义 |
| **游戏基础设施层** | graphics、runtime、asset、scene、physics、toolchain 等共享底座 |

`gnosis._` 当前位于第三层，并为第二层提供稳定基础设施。

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

## 公共图形栈

当前 `gnosis._` 负责托管共享图形底座，供引擎本体、`asgard.bifrost` 与 `titan` 共同消费：

- `gnosis.gpu`：GPU / compute / resource / synchronization
- `gnosis.text`：字体系统、text shaping、glyph atlas、段落布局
- `gnosis.layout`：constraints、intrinsic size、flow / flex / grid / scroll
- `gnosis.render`：2D draw list、3D render graph、frame submission
- `gnosis.scene`：transform tree、camera、light、mesh / sprite / text node
- `gnosis.asset`：mesh、image、material、font、shader module

这里的归属原则是：图形底座归 `gnosis._`，GUI 语义归 `asgard`，深度学习运行时语义归 `titan`。这样可以避免 `layout / fonts / gpu` 被某个上层生态私有化。

相关总文档见：[公共图形栈](../../../../../documentation/pages/zh-hans/developer/graphics-stack.md)

## ECS 语言扩展

ECS 语言扩展当前先按“通用核心 + 引擎专属扩展”来设计：

- **通用核心**：`component`、`system`、`query`、`resource`、`event`、`schedule`
- **引擎专属扩展**：`scene`、`prefab`、`quest`、`dialogue`、`world` 等工作流语义

其中通用核心更适合作为跨引擎游戏开发能力；引擎专属扩展是否最终归属 `Genesis`，还是继续抽象成可供 `Unity / Godot / Cocos` 等产品层消费的共通语义，当前暂不写死。

## 与其他游戏生态的关系

- `gnosis._`：元游戏引擎 / 基础设施层
- `Genesis`：具体游戏引擎产品层（规划语义）
- `unity._`：Unity 宿主桥接
- `godot._`：Godot 宿主桥接

## 当前阶段

规划中，优先先把 workspace 边界与文档契约写清楚。
