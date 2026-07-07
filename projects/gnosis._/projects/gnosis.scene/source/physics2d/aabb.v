namespace gnosis.scene.physics2d;

# gnosis.scene.physics2d.aabb: 2D 轴对齐包围盒
# 定义 Aabb 结构与点包含 / AABB-AABB / AABB-圆 相交判定。

⍝ 2D 轴对齐包围盒，由最小角与最大角坐标定义。
structure Aabb {
    ⍝ 最小角坐标 [x_min, y_min]。
    min: [f64; 2]
    ⍝ 最大角坐标 [x_max, y_max]。
    max: [f64; 2]
}

⍝ 由中心坐标与半Extent构造 AABB。
micro aabb_from_center_half_extent(center: [f64; 2], half_extent: [f64; 2]): Aabb {
    return Aabb {
        min: [center[0] - half_extent[0], center[1] - half_extent[1]],
        max: [center[0] + half_extent[0], center[1] + half_extent[1]],
    }
}

⍝ 判断点是否在 AABB 内（含边界）。
micro aabb_contains_point(aabb: Aabb, point: [f64; 2]): bool {
    if point[0] < aabb.min[0] {
        return false
    }
    if point[0] > aabb.max[0] {
        return false
    }
    if point[1] < aabb.min[1] {
        return false
    }
    if point[1] > aabb.max[1] {
        return false
    }
    return true
}

⍝ 判断两 AABB 是否相交。
micro aabb_intersects_aabb(a: Aabb, b: Aabb): bool {
    if a.min[0] > b.max[0] {
        return false
    }
    if a.max[0] < b.min[0] {
        return false
    }
    if a.min[1] > b.max[1] {
        return false
    }
    if a.max[1] < b.min[1] {
        return false
    }
    return true
}

⍝ 判断 AABB 与圆是否相交。
micro aabb_intersects_circle(aabb: Aabb, circle: Circle): bool {
    return circle_intersects_aabb(circle, aabb)
}
