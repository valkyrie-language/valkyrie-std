# gnosis.render

2D 渲染最小 draw path，提供 quad / line / circle / polygon draw list、world / UI / debug 三层提交、batching 与排序、hit flash / additive / bloom 后处理请求接口。

## 设计目标

- 最小 draw path：DrawList → Batcher 分组排序 → WorldPass / HudPass / DebugPass 分层提交 → PostFxRequest 后处理
- 不重复定义 GPU 类型，全部引用 `gnosis.gpu`
- 不含粒子 / 拖尾 / 光照 / 阴影等高级渲染特性

## 文件布局

| 文件 | 职责 |
|------|------|
| `source/render2d/draw_list.v` | 顶点 / 图元类型 / DrawCommand / DrawList（push_quad / push_line / push_circle / push_polygon / clear） |
| `source/render2d/batch_key.v` | BlendMode / Layer / BatchKey |
| `source/render2d/batcher.v` | Batcher：按 BatchKey 分组排序输出 Batch 列表 |
| `source/render2d/camera_2d.v` | Camera2D：position / zoom / rotation、view_matrix、screen_to_world |
| `source/render2d/world_pass.v` | WorldPass：提取 World 层并提交 GPU |
| `source/render2d/hud_pass.v` | HudPass：提取 UI 层并提交 GPU |
| `source/render2d/debug_pass.v` | DebugPass：提取 Debug 层并提交 GPU |
| `source/render2d/postfx_requests.v` | PostFxRequest / PostFxRequestQueue |

## 能力清单

- quad / line / circle / polygon 四种图元的 draw list 录制
- Opaque / Alpha / Additive 三种混合模式
- World / UI / Debug 三层渲染分离
- Batcher 按 (layer, blend_mode, texture) 排序，相同键的连续命令合并为单个 Batch
- Camera2D 提供 view_matrix 与 screen_to_world 逆变换
- PostFxRequest 队列支持 hit flash / additive / bloom 请求

## 典型帧循环

1. `draw_list.clear()`
2. `draw_list.set_state(blend_mode, texture)` → `draw_list.push_quad(...)` / `push_line(...)` / ...
3. `batcher.batch(draw_list)` → 排序后的 Batch 列表
4. `world_pass.submit(cmd, ...)` → `hud_pass.submit(cmd, ...)` → `debug_pass.submit(cmd, ...)`
5. `postfx_queue.drain()` → 取出后处理请求

## 不在范围内

- 粒子系统 / 拖尾
- 光照 / 阴影
- 文字渲染
- 材质系统
- GPU 资源管理（由 `gnosis.gpu` 提供）
