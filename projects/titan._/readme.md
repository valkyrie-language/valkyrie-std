# titan._

`titan._` 是深度学习框架的顶层 workspace。

## 原则

- 张量、自动微分、神经网络层与训练工具链分包组织
- 不把 AI 文档示例直接冒充成框架实现
- 不让深度学习运行时反向污染编译器主链
- 共享 GPU / device 抽象复用 `gnosis.gpu`，不再定义第二套底层设备模型

## 当前状态

规划中，先把 workspace 与文档骨架建立起来，同时把 compute / device 边界挂到共享图形栈上。

## 计划中的子包

- `projects/titan`
- `projects/titan.compute`
- `projects/titan.device`
- `projects/titan.autograd`
- `projects/titan.nn`
- `projects/titan.optim`
- `projects/titan.data`
- `projects/titan.tools`

## 与公共图形栈的关系

- `titan.device`：面向训练 / 推理运行时的 device capability、memory policy、stream policy
- `titan.compute`：面向 tensor kernel / graph execution 的 compute 编排
- 底层 `buffer / texture / queue / sync / pipeline` 直接复用 `gnosis.gpu`

文档入口：[documentation/pages/zh-hans/index.md](documentation/pages/zh-hans/index.md)
