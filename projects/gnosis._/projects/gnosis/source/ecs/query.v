namespace gnosis.ecs;

# gnosis.ecs.query: 查询原语
# 定义按组件组合枚举实体的查询视图与迭代协议。
# 查询联合多个 ComponentStorage，具体枚举由宿主世界提供。

# ──────────────────────────────────────────────
# QueryView
# ──────────────────────────────────────────────

⍝ 查询视图，描述所需组件集合并枚举满足条件的实体。
class QueryView {
    ⍝ 查询涉及的组件类型标识集合。
    _components: [ComponentId]
}

imply QueryView {
    ⍝ 以一组所需组件标识构造查询视图。
    micro new(components: [ComponentId]): Self {
        return QueryView {
            _components: components,
        }
    }

    ⍝ 返回该查询所需的组件标识集合。
    micro components(self): [ComponentId] {
        return self._components
    }

    ⍝ 返回满足查询条件的实体标识列表。
    ⍝ 具体枚举需联合多个 ComponentStorage，由宿主世界提供。
    [host_contract]
    micro entities(self): [EntityId] {
        return []
    }
}

# ──────────────────────────────────────────────
# QueryIterator
# ──────────────────────────────────────────────

⍝ 查询迭代器，按序产出满足查询的实体标识。
structure QueryIterator {
    ⍝ 关联的查询视图。
    _view: QueryView
    ⍝ 当前游标位置。
    _cursor: u32
}

imply QueryIterator {
    ⍝ 基于查询视图构造一个从起点开始的迭代器。
    micro new(view: QueryView): Self {
        return QueryIterator {
            _view: view,
            _cursor: 0,
        }
    }

    ⍝ 查询是否还有剩余实体。
    [host_contract]
    micro has_next(self): bool {
        return false
    }

    ⍝ 取出下一个实体标识，无剩余时返回 None。
    [host_contract]
    micro next(mut self): Option<EntityId> {
        return None
    }
}
