namespace gnosis.text;

# gnosis.text.shaping: 文本 shaping 最小实现
# 首版按等宽步进生成 ShapedGlyph 序列，累积水平前进量，供渲染层消费。
# 码点提取通过 host contract 完成，避免在语言层重复实现 UTF-8 解码。

⍝ 已 shape 的单个字形定位信息。
structure ShapedGlyph {
    ⍝ 字形标识，对应 Font 字形表中的 glyph_id。
    glyph_id: u32
    ⍝ 相对于光标起点的水平像素偏移（通常为 0）。
    x_offset: f32
    ⍝ 相对于基线的垂直像素偏移（正值上移）。
    y_offset: f32
    ⍝ 该字形贡献的水平前进量（像素）。
    x_advance: f32
}

⍝ 一段文本的 shaping 结果，包含字形序列与总前进量。
structure ShapedRun {
    ⍝ 已 shape 的字形序列。
    glyphs: [ShapedGlyph]
    ⍝ 整段文本的总水平前进量（像素）。
    total_advance: f32
}

⍝ 将文本按等宽步进 shaping 为字形序列。
⍝ 首版实现：每个码点映射为 glyph_id，前进量统一取 font.metrics.glyph_advance。
micro shape_text(text: utf8, font: Font): ShapedRun {
    let mut glyphs: [ShapedGlyph] = []
    let mut cursor: f32 = 0.0
    let advance: f32 = font.metrics.glyph_advance
    let codepoints: [u32] = to_codepoints(text)
    let count: usize = codepoints.length
    let mut i: usize = 0
    while i < count {
        let gid: u32 = codepoints[i]
        push(glyphs, ShapedGlyph {
            glyph_id: gid,
            x_offset: 0.0,
            y_offset: 0.0,
            x_advance: advance,
        })
        cursor = cursor + advance
        i = i + 1
    }
    return ShapedRun {
        glyphs: glyphs,
        total_advance: cursor,
    }
}

⍝ 将 utf8 文本解码为 Unicode 码点数组。
⍝ 该函数为 host contract：具体解码由宿主运行时提供，保证多字节字符正确性。
[host_contract]
micro to_codepoints(text: utf8): [u32]
