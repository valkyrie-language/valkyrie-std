# unity._

`unity._` 是 Unity 游戏生态的顶层 workspace，占位的是 **Unity 宿主桥接**，不是自研引擎。

## 原则

- Unity 宿主能力留在这里
- 自研引擎能力留给 `gnosis._`
- 工具链能力单独落到 `unity.tools`

## 当前状态

规划中，先补齐 workspace 与文档骨架，再逐步落子包。

## 计划中的子包

- `projects/unity`
- `projects/unity.scene`
- `projects/unity.input`
- `projects/unity.asset`
- `projects/unity.tools`

文档入口：[documentation/pages/zh-hans/index.md](documentation/pages/zh-hans/index.md)
