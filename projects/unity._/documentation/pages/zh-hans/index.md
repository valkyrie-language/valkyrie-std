# Unity 游戏生态

`unity._` 负责 Unity 游戏开发生态的 workspace 组织与长期边界。

## 定位

- 面向 Unity 宿主的桥接层
- 统一场景、输入、资源与交付约定
- 为 `legion` / `asgard` / `nyar` 提供 Unity 宿主接入点

## 不在这里做什么

- 不把 Unity 生态写成自研引擎
- 不和 `gnosis._` 混成一个游戏大包
- 不把通用编译器语义塞进 Unity 宿主层

## 计划中的子包

- `projects/unity`
- `projects/unity.scene`
- `projects/unity.input`
- `projects/unity.asset`
- `projects/unity.tools`

## 关系

- `unity._`：Unity 宿主生态
- `godot._`：Godot 宿主生态
- `gnosis._`：自研游戏引擎主线
