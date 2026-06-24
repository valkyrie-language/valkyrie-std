# `demo.unity.game`

Unity 游戏构建流示例。

## 目标

- 由 Unity 侧构建器或导出工具隐式注入 `unity.engine.sdk`
- 使用 `std` 的统一入口
- 编译阶段生成 `MSIL` 中间产物
- 通过 Unity build 插件自动写入 Unity 工程并触发 Unity 编译

## 构建流

1. `vcc` 编译 `Valkyrie` 源码
2. 输出 `MSIL` 到 `build/unity/msil`
3. `unity-project-export` 构建器自动接管
4. 插件写入 `build/unity/project`
5. Unity Editor 或批处理构建继续完成最终游戏产物

## 边界

- 项目通常不需要显式写 `unity.engine.sdk`
- 只有锁版本、测试版本或覆盖默认实现时才显式写出 `sdk` 依赖
- `legion` 只负责通用编译与中间产物输出
- Unity 侧自动导出与最终构建由平台构建器继续完成
