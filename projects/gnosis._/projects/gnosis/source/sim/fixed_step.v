namespace gnosis.sim;

# gnosis.sim.fixed_step: 固定步长循环
# 基于累加器的固定步长模拟，保证逻辑更新频率与渲染解耦。
# 调用方每帧注入墙钟时间，consume 返回本帧应执行的固定步数。

# ──────────────────────────────────────────────
# FixedStep
# ──────────────────────────────────────────────

⍝ 固定步长模拟器，以恒定 dt 推进逻辑，按需每帧执行多次。
class FixedStep {
    ⍝ 固定逻辑步长（秒）。
    _dt: f64
    ⍝ 时间累加器（秒）。
    _accumulator: f64
    ⍝ 每帧最多执行的步数，防止卡顿后追帧雪崩。
    _max_steps_per_frame: u32
    ⍝ 已累计执行的步数。
    _step_count: u32
}

imply FixedStep {
    ⍝ 按指定步长与每帧步数上限构造模拟器。
    micro new(dt: f64, max_steps_per_frame: u32): Self {
        return FixedStep {
            _dt: dt,
            _accumulator: 0.0,
            _max_steps_per_frame: max_steps_per_frame,
            _step_count: 0,
        }
    }

    ⍝ 返回固定步长（秒）。
    micro dt(self): f64 {
        return self._dt
    }

    ⍝ 返回每帧最多执行的步数上限。
    micro max_steps_per_frame(self): u32 {
        return self._max_steps_per_frame
    }

    ⍝ 返回累计执行的步数。
    micro step_count(self): u32 {
        return self._step_count
    }

    ⍝ 向累加器注入经过的墙钟时间（秒）。
    micro accumulate(mut self, elapsed: f64): unit {
        self._accumulator = self._accumulator + elapsed
    }

    ⍝ 消耗累加器并返回本帧应执行的固定步数。
    ⍝ 不超过 max_steps_per_frame；剩余不足一步的时间保留在累加器中供下帧使用。
    micro consume(mut self): u32 {
        let mut steps: u32 = 0
        while self._accumulator >= self._dt {
            if steps >= self._max_steps_per_frame {
                return steps
            }
            self._accumulator = self._accumulator - self._dt
            self._step_count = self._step_count + 1
            steps = steps + 1
        }
        return steps
    }

    ⍝ 丢弃累加器中不足一步的残余时间，避免长期漂移。
    micro flush(mut self): unit {
        self._accumulator = 0.0
    }
}
