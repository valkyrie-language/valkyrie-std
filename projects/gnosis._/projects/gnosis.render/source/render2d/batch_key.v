namespace gnosis.render.render2d;

# gnosis.render.render2d.batch_key: 批次键与混合模式 / 分层定义

⍝ 混合模式，决定片元如何与帧缓冲混合。
unite BlendMode {
    ⍝ 不透明渲染，直接覆盖。
    Opaque
    ⍝ Alpha 混合，源色按 alpha 与目标色混合。
    Alpha
    ⍝ 加法混合，源色叠加到目标色上。
    Additive
}

⍝ 渲染分层，控制提交顺序与裁剪行为。
unite Layer {
    ⍝ 世界层，受相机变换影响，最先提交。
    World
    ⍝ UI 层，屏幕空间正交投影，不受相机影响。
    UI
    ⍝ 调试层，线框 / 边界可视化，最后提交。
    Debug
}

⍝ 批次键，用于将 DrawCommand 分组为可合并的批次。
structure BatchKey {
    ⍝ 混合模式。
    blend_mode: BlendMode
    ⍝ 渲染分层。
    layer: Layer
    ⍝ 绑定的纹理句柄，None 表示无纹理（纯色填充）。
    texture: Option<ImageHandle>
}

⍝ 返回分层的提交顺序权重（World=0, UI=1, Debug=2）。
micro layer_order(layer: Layer): u32 {
    match layer {
        case World: 0
        case UI: 1
        case Debug: 2
    }
}

⍝ 返回混合模式的排序权重（Opaque=0, Alpha=1, Additive=2）。
micro blend_order(mode: BlendMode): u32 {
    match mode {
        case Opaque: 0
        case Alpha: 1
        case Additive: 2
    }
}
