# godot._

`godot._` 是 Godot 游戏生态的顶层 workspace，占位的是 **Godot 宿主桥接与交付能力**。

## 原则

- Godot 宿主能力留在这里
- 自研引擎能力留给 `gnosis._`
- 不为了“统一”而把 Unity / Godot 细节揉进同一套宿主层

## 当前状态

规划中，先建立 workspace 与文档骨架。

## 计划中的子包

- `projects/godot`
- `projects/godot.scene`
- `projects/godot.input`
- `projects/godot.asset`
- `projects/godot.tools`

文档入口：[documentation/pages/zh-hans/index.md](documentation/pages/zh-hans/index.md)
