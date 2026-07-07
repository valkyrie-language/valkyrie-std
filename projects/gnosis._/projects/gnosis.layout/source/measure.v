namespace gnosis.layout;

# gnosis.layout.measure: 文本与 widget 测量
# 定义布局所需的最小度量：FontMetrics / MeasureResult / measure_text / MeasureWidget trait。
# 本包不依赖 GPU / 渲染层，FontMetrics 为纯像素度量结构。

⍝ 字体度量，供布局层计算文本尺寸使用。
structure FontMetrics {
    ⍝ 等宽字形水平步进（像素）。
    glyph_advance: f32
    ⍝ 单个字形高度（像素）。
    glyph_height: f32
    ⍝ 行高（像素），两行基线之间的距离。
    line_height: f32
}

⍝ 测量结果，记录 widget 或文本的宽高。
structure MeasureResult {
    ⍝ 宽度（像素）。
    width: f32
    ⍝ 高度（像素）。
    height: f32
}

⍝ Widget 自测接口，统一布局层对 widget 尺寸的查询方式。
trait MeasureWidget {
    ⍝ 在给定约束下测量该 widget 的尺寸。
    micro measure(self, constraint: Constraint): MeasureResult
}

⍝ 按等宽度量计算文本的尺寸。
⍝ 单行文本宽度 = 字符数 * glyph_advance，高度 = line_height。
micro measure_text(text: utf8, metrics: FontMetrics): MeasureResult {
    let count: usize = text.length()
    let chars: f32 = (count as f32)
    let width: f32 = chars * metrics.glyph_advance
    return MeasureResult {
        width: width,
        height: metrics.line_height,
    }
}

⍝ 取两个测量结果中较大的尺寸，用于堆叠布局求并集。
micro max_measure(a: MeasureResult, b: MeasureResult): MeasureResult {
    let w: f32 = a.width
    let bw: f32 = b.width
    let h: f32 = a.height
    let bh: f32 = b.height
    let mut out_w: f32 = w
    if bw > w {
        out_w = bw
    }
    let mut out_h: f32 = h
    if bh > h {
        out_h = bh
    }
    return MeasureResult {
        width: out_w,
        height: out_h,
    }
}
