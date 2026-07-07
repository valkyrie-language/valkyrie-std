namespace gnosis.ecs;

# gnosis.ecs.event: 事件总线
# 定义事件的写入队列与消费读取协议，支撑系统间松耦合通信。
# 生产者向 EventQueue 推送事件，消费者通过 EventReader 按类型读取。

# ──────────────────────────────────────────────
# Event trait
# ──────────────────────────────────────────────

⍝ 事件类型标识，区分不同事件种类。
structure EventId {
    ⍝ 事件类型的不透明索引。
    id: u32
}

⍝ 事件抽象协议，所有事件需实现以提供类型标识。
trait Event {
    ⍝ 返回该事件类型的稳定标识。
    micro event_id(self): EventId
}

# ──────────────────────────────────────────────
# EventQueue
# ──────────────────────────────────────────────

⍝ 事件写入队列，系统向其推送事件供后续帧消费。
class EventQueue {
    ⍝ 内部存储标记，具体后端由宿主提供。
    _marker: u32
}

imply EventQueue {
    ⍝ 构造一个空的事件队列。
    micro new(): Self {
        return EventQueue {
            _marker: 0,
        }
    }

    ⍝ 向队列追加一个事件。
    [host_contract]
    micro push<T>(mut self, event: T): unit
        where T: Event
    {
        return
    }

    ⍝ 返回当前队列中待消费事件的数量。
    [host_contract]
    micro pending(self): u32 {
        return 0
    }

    ⍝ 清空当前积压的事件。
    [host_contract]
    micro clear(mut self): unit {
        return
    }
}

# ──────────────────────────────────────────────
# EventReader
# ──────────────────────────────────────────────

⍝ 事件读取器，按类型消费队列中的事件。
class EventReader {
    ⍝ 关联的事件队列。
    _queue: EventQueue
}

imply EventReader {
    ⍝ 基于事件队列构造读取器。
    micro new(queue: EventQueue): Self {
        return EventReader {
            _queue: queue,
        }
    }

    ⍝ 取出下一个指定类型的事件，无则返回 None。
    [host_contract]
    micro next<T>(mut self): Option<T>
        where T: Event
    {
        return None
    }

    ⍝ 遍历当前所有待消费事件，按回调逐个派发。
    [host_contract]
    micro for_each<T>(self, f: micro(T) -> unit): unit
        where T: Event
    {
        return
    }
}
