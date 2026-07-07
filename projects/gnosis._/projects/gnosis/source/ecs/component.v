namespace gnosis.ecs;

# gnosis.ecs.component: 组件存储与 trait
# 定义 Entity / Component / ComponentStorage 的最小契约与稠密数组实现。
# 所有组件类型通过 Component trait 暴露稳定的 ComponentId，由 ComponentStorage 按实体索引存取。

# ──────────────────────────────────────────────
# 实体与组件标识
# ──────────────────────────────────────────────

⍝ 实体标识，索引世界中唯一对象的句柄。
structure EntityId {
    ⍝ 实体的不透明索引，从 0 开始递增。
    id: u32
}

⍝ 组件类型标识，区分不同组件种类。
structure ComponentId {
    ⍝ 组件类型的不透明索引。
    id: u32
}

# ──────────────────────────────────────────────
# Component trait
# ──────────────────────────────────────────────

⍝ 组件抽象协议，所有组件类型需实现以提供稳定的类型标识。
trait Component {
    ⍝ 返回该组件类型的稳定标识。
    micro component_id(self): ComponentId
}

# ──────────────────────────────────────────────
# ComponentStorage trait + DenseStorage
# ──────────────────────────────────────────────

⍝ 组件存储抽象协议，定义组件按实体的增删查改接口。
trait ComponentStorage<T> {
    ⍝ 为指定实体插入组件，若已存在则覆盖。
    micro insert(mut self, entity: EntityId, component: T): unit

    ⍝ 查询指定实体是否拥有该类型组件。
    micro has(self, entity: EntityId): bool

    ⍝ 取出指定实体组件的不可变副本。
    micro get(self, entity: EntityId): Option<T>

    ⍝ 移除并返回指定实体的组件。
    micro remove(mut self, entity: EntityId): Option<T>
}

⍝ 稠密数组组件存储，以实体索引为键的紧凑存储。
⍝ 内部维护按实体 id 直接寻址的 Option 槽位，未占用的槽位为 None。
class DenseStorage<T> {
    ⍝ 按实体 id 直接寻址的组件槽位。
    _slots: [Option<T>]
}

imply DenseStorage<T>: ComponentStorage<T> {
    ⍝ 构造一个空的稠密存储。
    micro new(): Self {
        return DenseStorage {
            _slots: [],
        }
    }

    ⍝ 为指定实体插入组件，必要时扩展槽位至能容纳该实体索引。
    ⍝ 实际数组扩展与寻址由宿主提供，保证跨后端一致的语义。
    [host_contract]
    micro insert(mut self, entity: EntityId, component: T): unit {
        return
    }

    ⍝ 查询指定实体是否拥有该类型组件。
    [host_contract]
    micro has(self, entity: EntityId): bool {
        return false
    }

    ⍝ 取出指定实体组件的不可变副本。
    [host_contract]
    micro get(self, entity: EntityId): Option<T> {
        return None
    }

    ⍝ 移除并返回指定实体的组件，槽位置空。
    [host_contract]
    micro remove(mut self, entity: EntityId): Option<T> {
        return None
    }
}
