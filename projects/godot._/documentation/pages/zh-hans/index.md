# Godot 游戏生态

`godot._` 负责 Godot 游戏开发生态的 workspace 组织与长期边界。

## 定位

- 面向 Godot 宿主的桥接层
- 管理场景、输入、资源与导出约定
- 为 `legion` 与后续游戏生态包提供 Godot 宿主接入点

## 不在这里做什么

- 不把 Godot 生态写成自研引擎
- 不和 `unity._` 强行共用宿主细节
- 不把引擎层职责塞进宿主桥接层

## 计划中的子包

- `projects/godot`
- `projects/godot.scene`
- `projects/godot.input`
- `projects/godot.asset`
- `projects/godot.tools`

## 关系

- `godot._`：Godot 宿主生态
- `unity._`：Unity 宿主生态
- `gnosis._`：自研游戏引擎主线
