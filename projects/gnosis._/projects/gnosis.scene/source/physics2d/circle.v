namespace gnosis.scene.physics2d;

# gnosis.scene.physics2d.circle: 2D 圆形碰撞体
# 定义 Circle 结构与圆-点 / 圆-圆 / 圆-AABB 相交判定。

⍝ 2D 圆形碰撞体，由圆心坐标与半径定义。
structure Circle {
    ⍝ 圆心坐标 [x, y]。
    center: [f64; 2]
    ⍝ 圆半径，应保持非负。
    radius: f64
}

⍝ 判断点是否落在圆内（含边界）。
micro circle_contains_point(circle: Circle, point: [f64; 2]): bool {
    let dx: f64 = circle.center[0] - point[0]
    let dy: f64 = circle.center[1] - point[1]
    let r: f64 = circle.radius
    return dx * dx + dy * dy <= r * r
}

⍝ 判断两圆是否相交（含相切）。
micro circle_intersects_circle(a: Circle, b: Circle): bool {
    let dx: f64 = a.center[0] - b.center[0]
    let dy: f64 = a.center[1] - b.center[1]
    let r_sum: f64 = a.radius + b.radius
    return dx * dx + dy * dy <= r_sum * r_sum
}

⍝ 判断圆与 AABB 是否相交。
⍝ 取 AABB 上离圆心最近的点，比较其与圆心距离平方与半径平方。
micro circle_intersects_aabb(circle: Circle, aabb: Aabb): bool {
    let nx: f64 = max(aabb.min[0], min(circle.center[0], aabb.max[0]))
    let ny: f64 = max(aabb.min[1], min(circle.center[1], aabb.max[1]))
    let dx: f64 = circle.center[0] - nx
    let dy: f64 = circle.center[1] - ny
    let r: f64 = circle.radius
    return dx * dx + dy * dy <= r * r
}
