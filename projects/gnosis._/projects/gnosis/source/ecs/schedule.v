namespace gnosis.ecs;

# gnosis.ecs.schedule: 系统调度器
# 定义按阶段划分的系统调度列表与执行顺序。
# 调度器在每帧按 PreUpdate → Update → PostUpdate 顺序执行已注册系统。

# ──────────────────────────────────────────────
# Stage
# ──────────────────────────────────────────────

⍝ 调度阶段，决定系统在帧内的执行时机。
unite Stage {
    ⍝ 更新前阶段，处理输入采样与状态准备。
    PreUpdate
    ⍝ 主更新阶段，推进模拟与游戏逻辑。
    Update
    ⍝ 更新后阶段，处理提交与清理。
    PostUpdate
}

# ──────────────────────────────────────────────
# ScheduleEntry
# ──────────────────────────────────────────────

⍝ 已注册到某阶段的系统条目。
structure ScheduleEntry {
    ⍝ 条目所属阶段。
    stage: Stage
    ⍝ 被调度的系统标识。
    system: SystemId
}

# ──────────────────────────────────────────────
# Schedule
# ──────────────────────────────────────────────

⍝ 系统调度器，按阶段顺序组织并执行系统列表。
class Schedule {
    ⍝ 按注册顺序排列的调度条目列表。
    _entries: [ScheduleEntry]
}

imply Schedule {
    ⍝ 构造一个空的调度器。
    micro new(): Self {
        return Schedule {
            _entries: [],
        }
    }

    ⍝ 将系统添加到指定阶段末尾。
    [host_contract]
    micro add(mut self, stage: Stage, system: SystemId): unit {
        return
    }

    ⍝ 返回指定阶段的系统标识有序列表。
    [host_contract]
    micro stage_systems(self, stage: Stage): [SystemId] {
        return []
    }

    ⍝ 按阶段顺序返回所有调度条目。
    [host_contract]
    micro entries(self): [ScheduleEntry] {
        return []
    }

    ⍝ 依次执行所有阶段的系统，传入执行上下文。
    [host_contract]
    micro run(mut self, ctx: SystemContext): unit {
        return
    }
}
