namespace gnosis.scene.physics2d;

# gnosis.scene.physics2d.kinematics: 运动学积分
# 定义 Kinematics 结构与半隐式 Euler 积分、指数阻力。

⍝ 运动学状态，持有速度与加速度。
structure Kinematics {
    ⍝ 速度 [vx, vy]。
    velocity: [f64; 2]
    ⍝ 加速度 [ax, ay]。
    acceleration: [f64; 2]
}

⍝ 以半隐式 Euler 推进位置：先更新速度再积分位置。
⍝ 返回推进后的新位置，不修改传入的 kinematics。
micro integrate(position: [f64; 2], kinematics: Kinematics, dt: f64): [f64; 2] {
    let new_vx: f64 = kinematics.velocity[0] + kinematics.acceleration[0] * dt
    let new_vy: f64 = kinematics.velocity[1] + kinematics.acceleration[1] * dt
    let new_px: f64 = position[0] + new_vx * dt
    let new_py: f64 = position[1] + new_vy * dt
    return [new_px, new_py]
}

⍝ 应用指数阻力：v' = v * clamp(1 - drag * dt, 0, 1)。
⍝ drag_coefficient 越大减速越快，dt 为步长。
micro simple_drag(velocity: [f64; 2], drag_coefficient: f64, dt: f64): [f64; 2] {
    let factor: f64 = clamp(1.0 - drag_coefficient * dt, 0.0, 1.0)
    return [velocity[0] * factor, velocity[1] * factor]
}
