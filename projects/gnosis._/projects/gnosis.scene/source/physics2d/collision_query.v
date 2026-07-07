namespace gnosis.scene.physics2d;

# gnosis.scene.physics2d.collision_query: 碰撞查询
# 定义 CollisionPair 与 broadphase / narrowphase 纯函数。
# broadphase 从 SpatialHash 产出 AABB 重叠候选对；
# narrowphase 在具体形状上计算碰撞法线与穿透深度。

⍝ 碰撞对，记录两个实体及碰撞流形（法线与穿透深度）。
⍝ hit_normal 从 a 指向 b，penetration 为非负穿透深度。
structure CollisionPair {
    ⍝ 实体 A。
    a: EntityId
    ⍝ 实体 B。
    b: EntityId
    ⍝ 碰撞法线，从 a 指向 b，单位向量。
    hit_normal: [f64; 2]
    ⍝ 穿透深度，非负。
    penetration: f64
}

⍝ 宽相：从空间哈希中产出所有 AABB 重叠的实体对。
⍝ hit_normal 与 penetration 留空，由 narrowphase 填充。
micro broadphase(hash: SpatialHash): [CollisionPair] {
    let entries: [SpatialHashEntry] = hash.entries()
    let count: usize = entries.length
    let mut pairs: [CollisionPair] = []

    let mut i: usize = 0
    while i < count {
        let ei: SpatialHashEntry = entries[i]
        let mut j: usize = i + 1
        while j < count {
            let ej: SpatialHashEntry = entries[j]
            if ei.entity.id != ej.entity.id {
                if aabb_intersects_aabb(ei.aabb, ej.aabb) {
                    push(pairs, CollisionPair {
                        a: ei.entity,
                        b: ej.entity,
                        hit_normal: [0.0, 0.0],
                        penetration: 0.0,
                    })
                }
            }
            j = j + 1
        }
        i = i + 1
    }

    return pairs
}

⍝ 窄相：圆-圆碰撞检测，返回带法线与穿透深度的碰撞对。
micro narrowphase_circle_circle(a: EntityId, circle_a: Circle, b: EntityId, circle_b: Circle): Option<CollisionPair> {
    let dx: f64 = circle_b.center[0] - circle_a.center[0]
    let dy: f64 = circle_b.center[1] - circle_a.center[1]
    let dist_sq: f64 = dx * dx + dy * dy
    let r_sum: f64 = circle_a.radius + circle_b.radius

    if dist_sq > r_sum * r_sum {
        return None
    }

    let dist: f64 = sqrt(dist_sq)

    if dist == 0.0 {
        return Some::<CollisionPair>(CollisionPair {
            a: a,
            b: b,
            hit_normal: [1.0, 0.0],
            penetration: r_sum,
        })
    }

    return Some::<CollisionPair>(CollisionPair {
        a: a,
        b: b,
        hit_normal: [dx / dist, dy / dist],
        penetration: r_sum - dist,
    })
}

⍝ 窄相：AABB-AABB 碰撞检测，按最小穿透轴计算法线。
micro narrowphase_aabb_aabb(a: EntityId, aabb_a: Aabb, b: EntityId, aabb_b: Aabb): Option<CollisionPair> {
    if !aabb_intersects_aabb(aabb_a, aabb_b) {
        return None
    }

    let overlap_x_lo: f64 = aabb_b.max[0] - aabb_a.min[0]
    let overlap_x_hi: f64 = aabb_a.max[0] - aabb_b.min[0]
    let overlap_y_lo: f64 = aabb_b.max[1] - aabb_a.min[1]
    let overlap_y_hi: f64 = aabb_a.max[1] - aabb_b.min[1]

    let mut pen_x: f64 = overlap_x_hi
    let mut dir_x: f64 = 1.0
    if overlap_x_lo < overlap_x_hi {
        pen_x = overlap_x_lo
        dir_x = -1.0
    }

    let mut pen_y: f64 = overlap_y_hi
    let mut dir_y: f64 = 1.0
    if overlap_y_lo < overlap_y_hi {
        pen_y = overlap_y_lo
        dir_y = -1.0
    }

    if pen_x < pen_y {
        return Some::<CollisionPair>(CollisionPair {
            a: a,
            b: b,
            hit_normal: [dir_x, 0.0],
            penetration: pen_x,
        })
    }

    return Some::<CollisionPair>(CollisionPair {
        a: a,
        b: b,
        hit_normal: [0.0, dir_y],
        penetration: pen_y,
    })
}

⍝ 窄相：AABB-圆 碰撞检测，法线从 AABB 指向圆。
micro narrowphase_aabb_circle(a: EntityId, aabb: Aabb, b: EntityId, circle: Circle): Option<CollisionPair> {
    if !circle_intersects_aabb(circle, aabb) {
        return None
    }

    let closest_x: f64 = max(aabb.min[0], min(circle.center[0], aabb.max[0]))
    let closest_y: f64 = max(aabb.min[1], min(circle.center[1], aabb.max[1]))
    let dx: f64 = circle.center[0] - closest_x
    let dy: f64 = circle.center[1] - closest_y
    let dist_sq: f64 = dx * dx + dy * dy
    let r: f64 = circle.radius

    if dist_sq == 0.0 {
        return Some::<CollisionPair>(CollisionPair {
            a: a,
            b: b,
            hit_normal: [0.0, -1.0],
            penetration: r,
        })
    }

    let dist: f64 = sqrt(dist_sq)

    return Some::<CollisionPair>(CollisionPair {
        a: a,
        b: b,
        hit_normal: [dx / dist, dy / dist],
        penetration: r - dist,
    })
}

⍝ 窄相：圆-AABB 碰撞检测，法线从圆指向 AABB。
micro narrowphase_circle_aabb(a: EntityId, circle: Circle, b: EntityId, aabb: Aabb): Option<CollisionPair> {
    if !circle_intersects_aabb(circle, aabb) {
        return None
    }

    let closest_x: f64 = max(aabb.min[0], min(circle.center[0], aabb.max[0]))
    let closest_y: f64 = max(aabb.min[1], min(circle.center[1], aabb.max[1]))
    let dx: f64 = circle.center[0] - closest_x
    let dy: f64 = circle.center[1] - closest_y
    let dist_sq: f64 = dx * dx + dy * dy
    let r: f64 = circle.radius

    if dist_sq == 0.0 {
        return Some::<CollisionPair>(CollisionPair {
            a: a,
            b: b,
            hit_normal: [0.0, 1.0],
            penetration: r,
        })
    }

    let dist: f64 = sqrt(dist_sq)

    return Some::<CollisionPair>(CollisionPair {
        a: a,
        b: b,
        hit_normal: [-dx / dist, -dy / dist],
        penetration: r - dist,
    })
}
