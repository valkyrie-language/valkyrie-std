namespace plotter;

# PlotScene 图元：与渲染后端解耦。
# MarkKind: 0=rect, 1=line, 2=path, 3=circle, 4=text, 5=hline, 6=vline

structure Mark {
    kind: i32
    x: f64
    y: f64
    x2: f64
    y2: f64
    width: f64
    height: f64
    radius: f64
    fill: utf8
    stroke: utf8
    stroke_width: f64
    text: utf8
    path: utf8
}

micro mark_rect(x: f64, y: f64, width: f64, height: f64, fill: utf8) -> Mark {
    return Mark {
        kind: 0,
        x: x,
        y: y,
        x2: 0.0,
        y2: 0.0,
        width: width,
        height: height,
        radius: 0.0,
        fill: fill,
        stroke: "none",
        stroke_width: 0.0,
        text: "",
        path: ""
    }
}

micro mark_line(x: f64, y: f64, x2: f64, y2: f64, stroke: utf8, stroke_width: f64) -> Mark {
    return Mark {
        kind: 1,
        x: x,
        y: y,
        x2: x2,
        y2: y2,
        width: 0.0,
        height: 0.0,
        radius: 0.0,
        fill: "none",
        stroke: stroke,
        stroke_width: stroke_width,
        text: "",
        path: ""
    }
}

micro mark_path(path: utf8, stroke: utf8, stroke_width: f64, fill: utf8) -> Mark {
    return Mark {
        kind: 2,
        x: 0.0,
        y: 0.0,
        x2: 0.0,
        y2: 0.0,
        width: 0.0,
        height: 0.0,
        radius: 0.0,
        fill: fill,
        stroke: stroke,
        stroke_width: stroke_width,
        text: "",
        path: path
    }
}

micro mark_circle(x: f64, y: f64, radius: f64, fill: utf8, stroke: utf8) -> Mark {
    return Mark {
        kind: 3,
        x: x,
        y: y,
        x2: 0.0,
        y2: 0.0,
        width: 0.0,
        height: 0.0,
        radius: radius,
        fill: fill,
        stroke: stroke,
        stroke_width: 1.0,
        text: "",
        path: ""
    }
}

micro mark_text(x: f64, y: f64, text: utf8, fill: utf8) -> Mark {
    return Mark {
        kind: 4,
        x: x,
        y: y,
        x2: 0.0,
        y2: 0.0,
        width: 0.0,
        height: 0.0,
        radius: 0.0,
        fill: fill,
        stroke: "none",
        stroke_width: 0.0,
        text: text,
        path: ""
    }
}
