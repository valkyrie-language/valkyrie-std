# nyar.vm.wasm

`nyar.vm.wasm` 是 `nyar` 体系中的 `WASM` 经典运行时家族文档入口。

## 定位

- 面向 `WASM` family 的运行时与宿主约束
- 基于 `nyar` 公共基础设施实现 `WASM` 运行时家族
- 负责区分 `browser`、`node`、`wasi` 等运行模型差异
- 承接 `WASM` 目标的入口、桥接、打包与运行契约

## 关注点

- `WASM` 模块运行时行为
- 宿主导入导出与桥接规则
- 浏览器、`Node`、`WASI` 之间的边界
- 调试资产、胶水代码与运行契约

## 不负责什么

- 不定义语言级语义主线
- 不把浏览器或 `WASI` 细节抬升成所有 target 的公共前提
- 不把 `WASM` 家族重新伪装成统一大 backend

## 与其他项目的关系

- `projects/nyar._/projects/nyar`：提供公共 target 与契约基础设施
- 与 `nyar.vm.clr`、`nyar.vm.jvm` 一起组成基于 `nyar` 基础设施的经典运行时家族
- **依赖方向**：只消费 `nyar.emitter` 产物，**不得**依赖 `nyar.language`；WASM/WASI lane 输入类型全称为 `ExecutableModule`

## 说明

当前目录主要作为 `nyar.vm.wasm` 的项目说明入口，后续可以补充：

- `browser / node / wasi` 子路线
- 导入导出约束
- 胶水与打包策略
- 调试与交付规范
