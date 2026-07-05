namespace plotter;

# SVG 渲染后端：PlotScene -> utf8，无 DOM 依赖。

micro escape_xml(text: utf8) -> utf8 {
    return text
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace("\"", "&quot;")
}

micro render_svg(spec: PlotSpec) -> utf8 {
    return render_svg_sized(spec, spec.width, spec.height)
}

micro render_svg_sized(spec: PlotSpec, width: f64, height: f64) -> utf8 {
    let sized: PlotSpec = with_size(spec, width, height)
    let scene: PlotScene = build_scene(sized)
    return scene_to_svg(scene)
}

micro scene_to_svg(scene: PlotScene) -> utf8 {
    let mut body: utf8 = ""
    let mut index: usize = 0
    while index < scene.marks.length() {
        body = body + mark_to_svg(scene.marks[index])
        index = index + 1
    }

    return "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\""
        + format("{}", scene.width)
        + "\" height=\""
        + format("{}", scene.height)
        + "\" viewBox=\"0 0 "
        + format("{}", scene.width)
        + " "
        + format("{}", scene.height)
        + "\">"
        + "<rect width=\"100%\" height=\"100%\" fill=\"#ffffff\"/>"
        + body
        + "</svg>"
}

micro mark_to_svg(mark: Mark) -> utf8 {
    if mark.kind == 0 {
        return "<rect x=\""
            + format("{}", mark.x)
            + "\" y=\""
            + format("{}", mark.y)
            + "\" width=\""
            + format("{}", mark.width)
            + "\" height=\""
            + format("{}", mark.height)
            + "\" fill=\""
            + mark.fill
            + "\"/>"
    }
    if mark.kind == 1 {
        return "<line x1=\""
            + format("{}", mark.x)
            + "\" y1=\""
            + format("{}", mark.y)
            + "\" x2=\""
            + format("{}", mark.x2)
            + "\" y2=\""
            + format("{}", mark.y2)
            + "\" stroke=\""
            + mark.stroke
            + "\" stroke-width=\""
            + format("{}", mark.stroke_width)
            + "\"/>"
    }
    if mark.kind == 2 {
        return "<path d=\""
            + mark.path
            + "\" fill=\""
            + mark.fill
            + "\" stroke=\""
            + mark.stroke
            + "\" stroke-width=\""
            + format("{}", mark.stroke_width)
            + "\" fill-opacity=\"0\"/>"
    }
    if mark.kind == 3 {
        return "<circle cx=\""
            + format("{}", mark.x)
            + "\" cy=\""
            + format("{}", mark.y)
            + "\" r=\""
            + format("{}", mark.radius)
            + "\" fill=\""
            + mark.fill
            + "\" stroke=\""
            + mark.stroke
            + "\"/>"
    }
    if mark.kind == 4 {
        return "<text x=\""
            + format("{}", mark.x)
            + "\" y=\""
            + format("{}", mark.y)
            + "\" fill=\""
            + mark.fill
            + "\" font-family=\"system-ui,sans-serif\" font-size=\"12\">"
            + escape_xml(mark.text)
            + "</text>"
    }
    return ""
}
