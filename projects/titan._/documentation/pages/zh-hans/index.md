# Titan 深度学习框架

`titan._` 是深度学习框架主线，后续承接张量、自动微分、神经网络层与训练工具链。

## 定位

- 张量与数值计算核心
- 自动微分与梯度传播
- 神经网络层、优化器与数据管线
- 面向训练与推理的工具链
- GPU compute / device runtime 建立在共享图形栈之上

## 计划中的子包

- `projects/titan`
- `projects/titan.compute`
- `projects/titan.device`
- `projects/titan.autograd`
- `projects/titan.nn`
- `projects/titan.optim`
- `projects/titan.data`
- `projects/titan.tools`

## 与共享 GPU 契约的关系

`Titan` 不再单独发明第二套底层 GPU 设备模型，而是复用 `gnosis.gpu` 提供的：

- `Device`
- `Queue`
- `Buffer`
- `Texture`
- `ComputePipeline`
- `Synchronization`

`Titan` 自己只在其上叠加训练 / 推理所需的 compute scheduler、tensor kernel 编排与 device policy。

相关总文档见：[公共图形栈](../../../../../documentation/pages/zh-hans/developer/graphics-stack.md)

## 当前阶段

规划中，当前优先完成 workspace 组织与文档边界。
