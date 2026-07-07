namespace gnosis.layout;

# gnosis.layout.anchor_layout: 锚点定位
# 定义 9 种锚点与 AnchorLayout，按锚点将 widget 定位到容器内的指定位置。

⍝ 锚点，决定 widget 在容器内的对齐方位。
unite Anchor {
    ⍝ 左上角。
    TopLeft
    ⍝ 顶部居中。
    TopCenter
    ⍝ 右上角。
    TopRight
    ⍝ 左侧居中。
    CenterLeft
    ⍝ 正中。
    Center
    ⍝ 右侧居中。
    CenterRight
    ⍝ 左下角。
    BottomLeft
    ⍝ 底部居中。
    BottomCenter
    ⍝ 右下角。
    BottomRight
}

⍝ 锚点布局，按锚点将 widget 的测量尺寸定位到容器矩形内。
class AnchorLayout {
    ⍝ 容器矩形。
    _container: Rect
    ⍝ 已排列的矩形列表。
    _rects: [Rect]
}

imply AnchorLayout {
    ⍝ 创建指定容器矩形的锚点布局。
    micro new(container: Rect): Self {
        return AnchorLayout {
            _container: container,
            _rects: [],
        }
    }

    ⍝ 返回容器矩形。
    micro container(self): Rect {
        return self._container
    }

    ⍝ 返回已排列的矩形列表。
    micro rects(self): [Rect] {
        return self._rects
    }

    ⍝ 按指定锚点将一个 widget（由其测量尺寸描述）定位到容器内，返回最终矩形。
    micro place(mut self, size: MeasureResult, anchor: Anchor, margin: f32): Rect {
        let c: Rect = self._container
        let w: f32 = size.width
        let h: f32 = size.height
        let x: f32 = anchor_x(anchor, c, w, margin)
        let y: f32 = anchor_y(anchor, c, h, margin)
        let r: Rect = Rect {
            x: x,
            y: y,
            width: w,
            height: h,
        }
        push(self._rects, r)
        return r
    }

    ⍝ 清空已排列的矩形列表，保留容器。
    micro clear(mut self): unit {
        self._rects = []
    }
}

⍝ 计算指定锚点下的 widget 左上角 x 坐标。
micro anchor_x(anchor: Anchor, container: Rect, widget_w: f32, margin: f32): f32 {
    return match anchor {
        case TopLeft: container.x + margin
        case TopCenter: container.x + (container.width - widget_w) * 0.5
        case TopRight: container.x + container.width - widget_w - margin
        case CenterLeft: container.x + margin
        case Center: container.x + (container.width - widget_w) * 0.5
        case CenterRight: container.x + container.width - widget_w - margin
        case BottomLeft: container.x + margin
        case BottomCenter: container.x + (container.width - widget_w) * 0.5
        case BottomRight: container.x + container.width - widget_w - margin
    }
}

⍝ 计算指定锚点下的 widget 左上角 y 坐标。
micro anchor_y(anchor: Anchor, container: Rect, widget_h: f32, margin: f32): f32 {
    return match anchor {
        case TopLeft: container.y + margin
        case TopCenter: container.y + margin
        case TopRight: container.y + margin
        case CenterLeft: container.y + (container.height - widget_h) * 0.5
        case Center: container.y + (container.height - widget_h) * 0.5
        case CenterRight: container.y + (container.height - widget_h) * 0.5
        case BottomLeft: container.y + container.height - widget_h - margin
        case BottomCenter: container.y + container.height - widget_h - margin
        case BottomRight: container.y + container.height - widget_h - margin
    }
}
