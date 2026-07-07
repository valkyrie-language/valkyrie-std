namespace gnosis.text;

# gnosis.text.font: 字体度量、字形数据与字体加载入口
# 定义 FontMetrics / Glyph / Font 三类核心数据，以及通过 host contract 加载字体的入口。
# 字形以归一化 UV 与 advance 描述，供 shaping 与 atlas 共用。

⍝ 字体度量，描述一种字体的纵向排版参数。
structure FontMetrics {
    ⍝ 基线以上的上行高度（像素）。
    ascent: f32
    ⍝ 基线以下的下行深度（像素，正值）。
    descent: f32
    ⍝ 行间距（像素），两行基线之间的额外间距。
    line_gap: f32
    ⍝ 等宽字形的水平步进（像素），首版 shaping 按等宽处理。
    glyph_advance: f32
    ⍝ 单个字形的标称高度（像素），通常等于 ascent + descent。
    glyph_height: f32
}

⍝ 单个字形的几何与图集映射信息。
structure Glyph {
    ⍝ 字形标识，首版以 Unicode 码点作为 id。
    glyph_id: u32
    ⍝ 图集中该字形的左边界 U 坐标（归一化 0..1）。
    u0: f32
    ⍝ 图集中该字形的上边界 V 坐标（归一化 0..1）。
    v0: f32
    ⍝ 图集中该字形的右边界 U 坐标（归一化 0..1）。
    u1: f32
    ⍝ 图集中该字形的下边界 V 坐标（归一化 0..1）。
    v1: f32
    ⍝ 该字形的水平步进（像素），等宽字体等于 metrics.glyph_advance。
    advance: f32
    ⍝ 该字形相对于光标原点的偏移（像素，XY）。
    offset: [f32; 2]
}

⍝ 字体资源，持有度量、字形表与所在图集纹理句柄。
structure Font {
    ⍝ 字体友好名称（如 "hud-default"）。
    name: utf8
    ⍝ 字体度量。
    metrics: FontMetrics
    ⍝ 字形列表，按 glyph_id 排序供二分查找。
    glyphs: [Glyph]
    ⍝ 该字体字形所在图集纹理句柄，None 表示尚未上传到 GPU。
    atlas: Option<ImageHandle>
}

⍝ 字体加载请求描述，传给宿主加载器。
structure FontLoadRequest {
    ⍝ 字体逻辑名称（对应资源清单中的键）。
    name: utf8
    ⍝ 期望的字号（像素），决定光栅化与图集尺寸。
    size: i32
}

⍝ 按字形 id 在已排序的字形表中查找字形，未找到时返回 None。
micro find_glyph(font: Font, glyph_id: u32): Option<Glyph> {
    let glyphs: [Glyph] = font.glyphs
    let count: usize = glyphs.length
    let mut lo: usize = 0
    let mut hi: usize = count
    while lo < hi {
        let mid: usize = lo + (hi - lo) / 2
        let g: Glyph = glyphs[mid]
        if g.glyph_id == glyph_id {
            return Some::<Glyph>(g)
        }
        if g.glyph_id < glyph_id {
            lo = mid + 1
        } else {
            hi = mid
        }
    }
    return None
}

⍝ 计算两行基线之间的行高（ascent + descent + line_gap）。
micro line_height(metrics: FontMetrics): f32 {
    return metrics.ascent + metrics.descent + metrics.line_gap
}

⍝ 通过宿主加载字体资源，返回填充好的 Font 结构。
⍝ 该函数为 host contract：具体的字体解析、光栅化与图集上传由宿主提供。
[host_contract]
micro load_font(request: FontLoadRequest): Font
