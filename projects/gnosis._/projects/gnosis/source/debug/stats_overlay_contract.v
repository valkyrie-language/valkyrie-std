namespace gnosis.debug;

# gnosis.debug.stats_overlay_contract: debug stats 覆盖层契约
# 定义性能统计快照与数据源协议，不包含任何渲染实现。
# 具体覆盖层绘制由上层渲染包实现，本契约仅约定数据形状。

# ──────────────────────────────────────────────
# StatsSnapshot
# ──────────────────────────────────────────────

⍝ 性能统计快照，记录单帧关键指标。
structure StatsSnapshot {
    ⍝ 本帧总耗时（毫秒）。
    frame_ms: f64
    ⍝ 本帧逻辑更新耗时（毫秒）。
    update_ms: f64
    ⍝ 本帧渲染提交耗时（毫秒）。
    render_ms: f64
    ⍝ 本帧固定步长执行次数。
    fixed_steps: u32
    ⍝ 本帧提交的绘制调用次数。
    draw_calls: u32
    ⍝ 本帧活跃的实体数量。
    object_count: u32
    ⍝ 当前每秒帧率估计。
    fps: f32
}

# ──────────────────────────────────────────────
# StatsSource
# ──────────────────────────────────────────────

⍝ 统计数据源协议，由希望暴露指标的系统实现。
trait StatsSource {
    ⍝ 采集并返回当前统计快照。
    micro snapshot(self): StatsSnapshot
}

# ──────────────────────────────────────────────
# StatsAggregator
# ──────────────────────────────────────────────

⍝ 统计聚合器，收集多个数据源并合成单一快照。
class StatsAggregator {
    ⍝ 内部存储标记，具体后端由宿主提供。
    _marker: u32
}

imply StatsAggregator {
    ⍝ 构造一个空的聚合器。
    micro new(): Self {
        return StatsAggregator {
            _marker: 0,
        }
    }

    ⍝ 注册一个统计数据源。
    [host_contract]
    micro register<T>(mut self, source: T): unit
        where T: StatsSource
    {
        return
    }

    ⍝ 合成并返回当前聚合快照。
    [host_contract]
    micro snapshot(self): StatsSnapshot {
        return StatsSnapshot {
            frame_ms: 0.0,
            update_ms: 0.0,
            render_ms: 0.0,
            fixed_steps: 0,
            draw_calls: 0,
            object_count: 0,
            fps: 0.0,
        }
    }
}
