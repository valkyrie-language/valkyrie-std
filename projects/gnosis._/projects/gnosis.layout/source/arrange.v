namespace gnosis.layout;

# gnosis.layout.arrange: 约束与排列
# 定义 Axis / Rect / Constraint / Arranger，按测量结果与约束框排列 widget。
# Arranger 支持横向 / 纵向堆叠，并在约束框内居中对齐。

⍝ 轴向，决定堆叠方向。
unite Axis {
    ⍝ 水平轴，沿 x 方向堆叠。
    Horizontal
    ⍝ 垂直轴，沿 y 方向堆叠。
    Vertical
}

⍝ 矩形，描述一个 widget 的最终位置与尺寸。
structure Rect {
    ⍝ 左上角 x 坐标（像素）。
    x: f32
    ⍝ 左上角 y 坐标（像素）。
    y: f32
    ⍝ 宽度（像素）。
    width: f32
    ⍝ 高度（像素）。
    height: f32
}

⍝ 约束框，描述可用空间与对齐方式。
structure Constraint {
    ⍝ 可用区域。
    bounds: Rect
    ⍝ 堆叠方向。
    axis: Axis
    ⍝ 子项之间的间距（像素）。
    spacing: f32
}

⍝ 排列器，按约束框与测量结果计算各 widget 的最终 Rect。
class Arranger {
    ⍝ 已排列的矩形列表，与输入的测量结果一一对应。
    _rects: [Rect]
}

imply Arranger {
    ⍝ 创建空的排列器。
    micro new(): Self {
        return Arranger {
            _rects: [],
        }
    }

    ⍝ 返回已排列的矩形列表。
    micro rects(self): [Rect] {
        return self._rects
    }

    ⍝ 按约束框沿轴向堆叠一组测量结果，返回排列后的矩形列表。
    ⍝ Horizontal 时沿 x 累加前进量并居中纵向对齐；Vertical 时沿 y 累加并居中横向对齐。
    micro arrange(mut self, measures: [MeasureResult], constraint: Constraint): [Rect] {
        self._rects = []
        let bounds: Rect = constraint.bounds
        let count: usize = measures.length
        if count == 0 {
            return self._rects
        }

        let horizontal: bool = match constraint.axis {
            case Horizontal: true
            case Vertical: false
        }

        let mut total_main: f32 = 0.0
        let mut i: usize = 0
        while i < count {
            let m: MeasureResult = measures[i]
            if horizontal {
                total_main = total_main + m.width
            } else {
                total_main = total_main + m.height
            }
            i = i + 1
        }
        total_main = total_main + ((count - 1) as f32) * constraint.spacing

        if horizontal {
            let main_size: f32 = bounds.width
            let mut cursor: f32 = 0.0
            if total_main < main_size {
                cursor = (main_size - total_main) * 0.5
            }
            let mut j: usize = 0
            while j < count {
                let m: MeasureResult = measures[j]
                let cy: f32 = bounds.y + (bounds.height - m.height) * 0.5
                push(self._rects, Rect {
                    x: bounds.x + cursor,
                    y: cy,
                    width: m.width,
                    height: m.height,
                })
                cursor = cursor + m.width + constraint.spacing
                j = j + 1
            }
        } else {
            let main_size: f32 = bounds.height
            let mut cursor: f32 = 0.0
            if total_main < main_size {
                cursor = (main_size - total_main) * 0.5
            }
            let mut k: usize = 0
            while k < count {
                let m: MeasureResult = measures[k]
                let cx: f32 = bounds.x + (bounds.width - m.width) * 0.5
                push(self._rects, Rect {
                    x: cx,
                    y: bounds.y + cursor,
                    width: m.width,
                    height: m.height,
                })
                cursor = cursor + m.height + constraint.spacing
                k = k + 1
            }
        }
        return self._rects
    }

    ⍝ 清空已排列的矩形列表。
    micro clear(mut self): unit {
        self._rects = []
    }
}
