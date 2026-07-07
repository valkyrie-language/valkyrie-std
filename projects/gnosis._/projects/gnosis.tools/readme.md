# gnosis.tools

工具与调试支持包，提供帧级性能采样（frame time / draw calls / particle count / visible objects）、调试绘制开关、批次分组视图与粒子系统视图，全部基于 `gnosis` 与 `gnosis.render` 的公开契约构建，不包含任何项目专属逻辑。

## 设计目标

- 可观测：frame time / update time / render time / draw calls / vertices / triangles / particle count / visible objects 全部可在帧循环中埋点采集
- 可开关：调试绘制（AABB / 圆形线框）通过 `enabled` 开关控制，关闭时为零开销空操作
- 非侵入：ParticleView 通过向临时 DrawList 探测渲染结果来统计粒子数与边界，不修改上游 ParticleSystem 接口
- 无项目耦合：不含 Geometry Wars 或任何具体项目的专属逻辑

## 文件布局

| 文件 | 职责 |
|------|------|
| `source/profiler/frame_stats.v` | FrameStats：begin/end 计时对记录 frame_ms / update_ms / render_ms / step_count，合成 StatsSnapshot |
| `source/profiler/render_stats.v` | RenderStats：累加 draw_calls / vertices / triangles / particle_count / visible_objects |
| `source/debug/draw_bounds.v` | DrawBounds：开关控制的 AABB / 圆形线框，提交到 DrawList 的 Debug 层 |
| `source/debug/batch_view.v` | BatchView：按 BatchKey 分组统计 DrawList 命令（每组 key / 命令数 / 顶点数 / 索引数） |
| `source/debug/particle_view.v` | ParticleView：检视 ParticleSystem 活跃粒子数与发射器数，绘制粒子整体边界 |

## 依赖

- `gnosis`：`StatsSnapshot`（`gnosis/source/debug/stats_overlay_contract.v`）
- `gnosis.render`：`DrawList` / `DrawCommand` / `Batcher` / `Batch` / `BatchKey` / `ParticleSystem` / `Vertex`（`gnosis.render/source/render2d/*`）

## 能力清单

- FrameStats：begin_frame / end_frame / begin_update / end_update / begin_render / end_render / record_step / to_snapshot
- RenderStats：record_draw_call / record_particle / record_visible / reset
- DrawBounds：enabled 开关 + draw_aabb / draw_circle 线框提交
- BatchView：inspect(DrawList) 按键分组 + inspect_batched(Batcher, DrawList) 批次摘要
- ParticleView：inspect(ParticleSystem) 输出活跃粒子数与发射器数 + draw_bounds 绘制整体边界

## 典型用法

1. 帧开始：`frame_stats.begin_frame()` → `render_stats.reset()`
2. 更新阶段：`frame_stats.begin_update()` → ... → `frame_stats.end_update()`
3. 渲染阶段：`frame_stats.begin_render()` → 每次 draw 调用 `render_stats.record_draw_call(...)` → `frame_stats.end_render()`
4. 帧结束：`frame_stats.end_frame()` → `frame_stats.to_snapshot(render_stats.draw_calls(), render_stats.visible_objects(), fps)`
5. 调试绘制：`draw_bounds.set_enabled(true)` → `draw_bounds.draw_aabb(list, min, max, color)`

## 不在范围内

- GPU 时间查询（需宿主提供 query pool）
- 内存分配追踪
- 远程调试协议
- 录制与回放（由各项目自行实现，参见 `game.geometry_wars/tools/replay_inspector`）
