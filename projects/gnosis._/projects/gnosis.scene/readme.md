# gnosis.scene

`gnosis.scene` 是 `gnosis._` 工作区下的 **2D 物理最小集**。
它定义圆 / AABB / 空间哈希 / 碰撞查询 / 运动学积分的最小契约，
供上层肉鸽射击首版做 projectile vs enemy / player vs pickup / enemy vs player 碰撞检测。

## 设计目标

- **最小集**：只提供支撑肉鸽射击首版所需的 2D 碰撞原语，不引入完整通用物理世界。
- **纯函数优先**：形状相交判定与 narrowphase 均为无副作用纯函数，便于测试与组合。
- **结构即数据**：Circle / Aabb / Kinematics / CollisionPair 为纯数据结构，操作以自由函数提供。
- **无私货**：不含任何具体游戏专属逻辑，可被任意 2D 射击样板复用。

## 文件布局

| 文件 | 职责 |
|:---|:---|
| `source/physics2d/circle.v` | Circle 结构与圆-点 / 圆-圆 / 圆-AABB 相交判定 |
| `source/physics2d/aabb.v` | Aabb 结构与点包含 / AABB-AABB / AABB-圆 相交判定 |
| `source/physics2d/spatial_hash.v` | SpatialHash 类，固定 cell_size 的空间索引 |
| `source/physics2d/collision_query.v` | CollisionPair 结构与 broadphase / narrowphase 纯函数 |
| `source/physics2d/kinematics.v` | Kinematics 结构与半隐式 Euler 积分 / 指数阻力 |

## 能力清单

- 圆碰撞：contains_point / intersects_circle / intersects_aabb
- AABB 碰撞：contains_point / intersects_aabb / intersects_circle / from_center_half_extent
- 空间索引：insert / query / remove / clear
- 碰撞查询：broadphase 产出候选对、narrowphase 计算法线与穿透深度
- 运动学：integrate 半隐式 Euler 推进位置、simple_drag 指数阻力

## 依赖

- `gnosis` — EntityId
- `std` — max / min / clamp / sqrt

## 不在范围内

- 完整刚体动力学（质量 / 力 / 角速度 / 约束求解）
- 连续碰撞检测（CCD）
- 多体物理岛与约束求解器
- 3D 物理
