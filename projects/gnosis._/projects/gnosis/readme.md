# gnosis

`gnosis` 是 `gnosis._` 工作区下的**通用游戏玩法框架基建**。
它定义 ECS 最小核心、输入动作映射、固定步长模拟与调试统计契约，
供上层具体游戏（如 Geometry Wars 样板）与可复用玩法样板搭建。

## 设计目标

- **最小核心**：只提供支撑典型游戏循环所需的 ECS / 输入 / 模拟契约，不引入具体玩法逻辑。
- **设备无关**：输入层把物理输入（键鼠 / 手柄）抽象为统一 `InputEvent`，再由 `ActionMap` 映射为逻辑动作。
- **解耦模拟与渲染**：`FixedStep` 以累加器模式按固定 dt 推进逻辑，与可变帧率渲染互不干扰。
- **可观测**：`StatsSource` 契约约定性能快照的数据形状，具体覆盖层绘制留给上层渲染包。
- **通用基建**：不含任何具体游戏私货，可被任意 2D / 3D 游戏样板复用。

## 文件布局

| 文件 | 职责 |
|:---|:---|
| `source/ecs/component.v` | 实体 / 组件标识、Component trait、ComponentStorage + DenseStorage |
| `source/ecs/system.v` | System trait、SystemContext、SystemRegistry |
| `source/ecs/query.v` | QueryView / QueryIterator 查询原语 |
| `source/ecs/resource.v` | Resource trait、ResourceMap 全局资源 |
| `source/ecs/event.v` | Event trait、EventQueue / EventReader 事件总线 |
| `source/ecs/schedule.v` | Stage 划分、Schedule 系统调度器 |
| `source/input/input_event.v` | InputEvent / InputState 跨设备输入抽象 |
| `source/input/action_map.v` | ActionMap 物理输入 → 逻辑动作映射 |
| `source/input/gamepad.v` | GamepadId / GamepadState / ButtonAxis 手柄输入 |
| `source/input/keyboard_mouse.v` | KeyCode / MouseButton / KeyboardMouseState 键鼠输入 |
| `source/sim/fixed_step.v` | FixedStep 累加器固定步长循环 |
| `source/debug/stats_overlay_contract.v` | StatsSnapshot / StatsSource 性能统计契约 |

## 能力清单

- ECS：实体 / 组件 / 系统 / 查询 / 资源 / 事件 / 调度 七件套最小契约
- 组件存储：`DenseStorage` 按实体索引的稠密数组存储
- 调度：`PreUpdate` / `Update` / `PostUpdate` 三阶段有序执行
- 输入：跨设备 `InputEvent` → `ActionMap` → `is_pressed` / `just_pressed` / `just_released`
- 手柄：按钮 / 摇杆 / 扳机的 `ButtonAxis` 模拟量与多手柄管理
- 键鼠：常见键码 / 鼠标按键 / 光标位置快照
- 模拟：`FixedStep` 累加器，固定 dt + `max_steps_per_frame` 防追帧雪崩
- 调试：`StatsSnapshot` 帧耗时 / 绘制调用 / 实体数等指标契约

## 典型帧循环

```
# 帧开始
input_state.clear()
# 平台采样物理输入 → input_state.push(event) ...

action_map.update(input_state)            # 刷新逻辑动作状态

fixed_step.accumulate(frame_elapsed)      # 注入墙钟时间
steps = fixed_step.consume()              # 取本帧应执行的固定步数
loop i in 0..steps {
    schedule.run(pre_update_ctx)          # 输入采样 / 状态准备
    schedule.run(update_ctx)              # 主逻辑更新（固定 dt）
    schedule.run(post_update_ctx)         # 提交 / 清理
}

# 渲染（可变帧率）...
snapshot = stats.snapshot()               # 采集本帧统计
```

## 不在范围内

- 具体游戏逻辑 / 玩法系统（由上层游戏包实现）
- 资源加载 / 场景图（由 `gnosis.asset` / `gnosis.scene` 等承担）
- 渲染 / 覆盖层绘制（由上层渲染包实现，本包只提供 stats 数据契约）
- 多线程系统调度（当前为单线程顺序模型）
- 输入设备热插拔的具体平台实现（由宿主 adaptor 提供）
