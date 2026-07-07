namespace gnosis.ecs;

# gnosis.ecs.resource: 全局资源
# 定义非组件全局状态的注册与访问协议。
# 资源是单例性质的世界级状态（如时间、配置、随机源），不绑定到具体实体。

# ──────────────────────────────────────────────
# Resource trait
# ──────────────────────────────────────────────

⍝ 资源类型标识，区分不同资源种类。
structure ResourceId {
    ⍝ 资源类型的不透明索引。
    id: u32
}

⍝ 资源抽象协议，所有全局资源需实现以提供类型标识。
trait Resource {
    ⍝ 返回该资源类型的稳定标识。
    micro resource_id(self): ResourceId
}

# ──────────────────────────────────────────────
# ResourceMap
# ──────────────────────────────────────────────

⍝ 资源映射表，按资源类型存取全局单例资源。
⍝ 内部采用类型擦除存储，具体后端由宿主提供。
class ResourceMap {
    ⍝ 内部存储标记，具体后端由宿主提供。
    _marker: u32
}

imply ResourceMap {
    ⍝ 构造一个空的资源映射表。
    micro new(): Self {
        return ResourceMap {
            _marker: 0,
        }
    }

    ⍝ 注册或覆盖一个全局资源实例。
    [host_contract]
    micro register<T>(mut self, resource: T): unit
        where T: Resource
    {
        return
    }

    ⍝ 查询是否包含指定类型的资源。
    [host_contract]
    micro has<T>(self): bool
        where T: Resource
    {
        return false
    }

    ⍝ 取出指定类型资源的不可变副本。
    [host_contract]
    micro get<T>(self): Option<T>
        where T: Resource
    {
        return None
    }

    ⍝ 移除指定类型的资源。
    [host_contract]
    micro remove<T>(mut self): unit
        where T: Resource
    {
        return
    }
}
