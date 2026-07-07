namespace gnosis.scene.physics2d;

# gnosis.scene.physics2d.spatial_hash: 空间哈希
# 固定格子的空间索引，用于 broadphase 候选筛选。
# 首版内部以扁平条目表存储，query 时对全部条目做 AABB 相交筛选；
# cell_size 字段已保留，后续可替换为按格子桶化的真实哈希表。

⍝ 空间哈希条目，关联实体与其包围盒。
structure SpatialHashEntry {
    ⍝ 条目对应的实体标识。
    entity: EntityId
    ⍝ 条目的 AABB。
    aabb: Aabb
}

⍝ 固定格子大小的空间索引。
⍝ 首版以扁平条目表存储，query 遍历全部条目做 AABB 相交筛选。
⍝ cell_size 已保留，后续可升级为按格子桶化的哈希加速。
class SpatialHash {
    ⍝ 格子边长，应为正数。
    _cell_size: f64
    ⍝ 已插入的条目表。
    _entries: [SpatialHashEntry]
}

imply SpatialHash {
    ⍝ 以指定格子大小构造空的空间哈希。
    micro new(cell_size: f64): Self {
        return SpatialHash {
            _cell_size: cell_size,
            _entries: [],
        }
    }

    ⍝ 返回格子边长。
    micro cell_size(self): f64 {
        return self._cell_size
    }

    ⍝ 返回全部条目的只读副本，供 broadphase 遍历使用。
    micro entries(self): [SpatialHashEntry] {
        return self._entries
    }

    ⍝ 插入实体及其 AABB。
    micro insert(mut self, entity: EntityId, aabb: Aabb): unit {
        push(self._entries, SpatialHashEntry {
            entity: entity,
            aabb: aabb,
        })
    }

    ⍝ 查询与指定 AABB 相交的全部实体标识。
    micro query(self, aabb: Aabb): [EntityId] {
        let mut result: [EntityId] = []
        let count: usize = self._entries.length
        let mut i: usize = 0
        while i < count {
            let entry: SpatialHashEntry = self._entries[i]
            if aabb_intersects_aabb(aabb, entry.aabb) {
                push(result, entry.entity)
            }
            i = i + 1
        }
        return result
    }

    ⍝ 移除指定实体的全部条目。
    micro remove(mut self, entity: EntityId): unit {
        let mut kept: [SpatialHashEntry] = []
        let count: usize = self._entries.length
        let mut i: usize = 0
        while i < count {
            let entry: SpatialHashEntry = self._entries[i]
            if entry.entity.id != entity.id {
                push(kept, entry)
            }
            i = i + 1
        }
        self._entries = kept
    }

    ⍝ 清空全部条目。
    micro clear(mut self): unit {
        self._entries = []
    }
}
