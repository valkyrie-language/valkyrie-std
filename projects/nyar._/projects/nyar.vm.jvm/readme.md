# nyar.vm.jvm

`nyar.vm.jvm` 是 `nyar` 体系中的 `JVM` 经典运行时家族文档入口。

## 定位

- 面向 `JVM` 宿主环境
- 基于 `nyar` 公共基础设施实现 `JVM` 运行时家族
- 负责 `JVM` 家族特有的入口、类加载边界、运行模型与产物组织

## 关注点

- `JVM` 目标的运行时行为
- 类文件、`jar` 与 launcher 约定
- 调试资产与运行契约
- 与其他经典运行时家族共享的公共基础设施边界

## 不负责什么

- 不定义具体语言的前端类型系统与语义规则
- 不承担公共编译前端职责
- 不把 `JVM` 的宿主细节反向污染到其他 family

## 与其他项目的关系

- `projects/nyar._/projects/nyar`：提供公共 target 与契约基础设施
- 与 `nyar.vm.clr`、`nyar.vm.wasm` 一起组成基于 `nyar` 基础设施的经典运行时家族
- **依赖方向**：只消费 `nyar.emitter` 产物，**不得**依赖 `nyar.language`；JVM lane 输入类型全称为 `ExecutableModule`

## 说明

当前目录主要作为 `nyar.vm.jvm` 的项目说明入口，后续可以补充：

- 入口规则
- 类路径与运行器约定
- 调试与交付规范
- 宿主依赖与兼容性范围
