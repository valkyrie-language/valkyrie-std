namespace gnosis.ecs;

# gnosis.ecs.system: 系统 trait 与注册
# 定义 System 的执行协议与系统注册表。
# 系统是每帧对世界进行变更的逻辑单元，通过 SystemContext 获取时间步长等执行上下文。

# ──────────────────────────────────────────────
# 系统标识与上下文
# ──────────────────────────────────────────────

⍝ 系统标识，区分不同系统实例。
structure SystemId {
    ⍝ 系统的不透明索引。
    id: u32
}

⍝ 系统执行上下文，携带本次更新的时间步长与观测信息。
structure SystemContext {
    ⍝ 自上次更新以来的逻辑时间步长（秒）。
    delta: f64
    ⍝ 已累计的固定步长模拟次数，供调试与节奏观测。
    step_count: u32
}

# ──────────────────────────────────────────────
# System trait
# ──────────────────────────────────────────────

⍝ 系统抽象协议，每帧由调度器调用 update 推进世界状态。
trait System {
    ⍝ 返回该系统的稳定标识。
    micro id(self): SystemId

    ⍝ 推进系统状态一次。
    micro update(mut self, ctx: SystemContext): unit
}

# ──────────────────────────────────────────────
# SystemRegistry
# ──────────────────────────────────────────────

⍝ 系统注册表，维护已注册系统的有序列表。
class SystemRegistry {
    ⍝ 已注册的系统标识有序列表。
    _systems: [SystemId]
}

imply SystemRegistry {
    ⍝ 构造一个空的注册表。
    micro new(): Self {
        return SystemRegistry {
            _systems: [],
        }
    }

    ⍝ 注册一个系统标识，追加到列表末尾。
    [host_contract]
    micro register(mut self, system: SystemId): unit {
        return
    }

    ⍝ 返回已注册系统数量。
    [host_contract]
    micro count(self): u32 {
        return 0
    }

    ⍝ 按注册顺序返回系统标识列表。
    [host_contract]
    micro systems(self): [SystemId] {
        return []
    }
}
