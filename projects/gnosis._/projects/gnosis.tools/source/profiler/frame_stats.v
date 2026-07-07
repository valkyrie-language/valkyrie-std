namespace gnosis.tools.profiler;

using gnosis.debug;

# gnosis.tools.profiler.frame_stats: 帧耗时统计
# 通过 begin/end 计时对在帧循环各阶段埋点，记录每帧总耗时、更新耗时、
# 渲染耗时与固定步长次数，最终合成 gnosis.debug.StatsSnapshot。

# ──────────────────────────────────────────────
# 时间源 host contract
# ──────────────────────────────────────────────

⍝ 返回当前时间（毫秒），用于帧各阶段耗时测量。
⍝ 该函数为 host contract：具体时钟源由宿主运行时提供。
[host_contract]
micro now_ms(): f64

# ──────────────────────────────────────────────
# FrameStats
# ──────────────────────────────────────────────

⍝ 帧耗时统计器，通过 begin/end 计时对记录每帧各阶段耗时与步长次数。
class FrameStats {
    ⍝ 当前帧起始时间戳（毫秒）。
    _frame_start_ms: f64
    ⍝ 当前更新阶段起始时间戳（毫秒）。
    _update_start_ms: f64
    ⍝ 当前渲染阶段起始时间戳（毫秒）。
    _render_start_ms: f64
    ⍝ 上一帧总耗时（毫秒）。
    _frame_ms: f64
    ⍝ 上一帧更新阶段耗时（毫秒）。
    _update_ms: f64
    ⍝ 上一帧渲染阶段耗时（毫秒）。
    _render_ms: f64
    ⍝ 上一帧固定步长执行次数。
    _step_count: u32
    ⍝ 当前帧固定步长执行次数（累加中，end_frame 时提交到 _step_count）。
    _current_steps: u32
}

imply FrameStats {
    ⍝ 构造一个所有计数为零的帧统计器。
    micro new(): Self {
        return FrameStats {
            _frame_start_ms: 0.0,
            _update_start_ms: 0.0,
            _render_start_ms: 0.0,
            _frame_ms: 0.0,
            _update_ms: 0.0,
            _render_ms: 0.0,
            _step_count: 0,
            _current_steps: 0,
        }
    }

    ⍝ 标记帧开始，记录起始时间戳并重置当前帧步长计数。
    micro begin_frame(mut self): unit {
        self._frame_start_ms = now_ms()
        self._current_steps = 0
    }

    ⍝ 标记帧结束，计算本帧总耗时并提交步长计数。
    micro end_frame(mut self): unit {
        let end: f64 = now_ms()
        self._frame_ms = end - self._frame_start_ms
        self._step_count = self._current_steps
    }

    ⍝ 标记更新阶段开始，记录起始时间戳。
    micro begin_update(mut self): unit {
        self._update_start_ms = now_ms()
    }

    ⍝ 标记更新阶段结束，计算更新耗时。
    micro end_update(mut self): unit {
        let end: f64 = now_ms()
        self._update_ms = end - self._update_start_ms
    }

    ⍝ 标记渲染阶段开始，记录起始时间戳。
    micro begin_render(mut self): unit {
        self._render_start_ms = now_ms()
    }

    ⍝ 标记渲染阶段结束，计算渲染耗时。
    micro end_render(mut self): unit {
        let end: f64 = now_ms()
        self._render_ms = end - self._render_start_ms
    }

    ⍝ 记录一次固定步长执行，应在 begin_frame 与 end_frame 之间调用。
    micro record_step(mut self): unit {
        self._current_steps = self._current_steps + 1
    }

    ⍝ 返回上一帧总耗时（毫秒）。
    micro frame_ms(self): f64 {
        return self._frame_ms
    }

    ⍝ 返回上一帧更新阶段耗时（毫秒）。
    micro update_ms(self): f64 {
        return self._update_ms
    }

    ⍝ 返回上一帧渲染阶段耗时（毫秒）。
    micro render_ms(self): f64 {
        return self._render_ms
    }

    ⍝ 返回上一帧固定步长执行次数。
    micro step_count(self): u32 {
        return self._step_count
    }

    ⍝ 合成统计快照。
    ⍝ draw_calls / object_count / fps 由 RenderStats 或上层提供，
    ⍝ 本方法仅填充耗时与步长字段。
    micro to_snapshot(self, draw_calls: u32, object_count: u32, fps: f32): StatsSnapshot {
        return StatsSnapshot {
            frame_ms: self._frame_ms,
            update_ms: self._update_ms,
            render_ms: self._render_ms,
            fixed_steps: self._step_count,
            draw_calls: draw_calls,
            object_count: object_count,
            fps: fps,
        }
    }
}
