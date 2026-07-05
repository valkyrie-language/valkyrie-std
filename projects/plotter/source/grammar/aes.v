namespace plotter;

# 美学映射：列名绑定到视觉通道。

micro aes(spec: PlotSpec, x: utf8, y: utf8) -> PlotSpec {
    return aes_full(spec, x, y, "", "", "")
}

micro aes_fill(spec: PlotSpec, x: utf8, y: utf8, fill: utf8) -> PlotSpec {
    return aes_full(spec, x, y, fill, "", "")
}

micro aes_full(spec: PlotSpec, x: utf8, y: utf8, fill: utf8, color: utf8, size: utf8) -> PlotSpec {
    let mapping: AesMapping = AesMapping {
        x: x,
        y: y,
        fill: fill,
        color: color,
        size: size
    }
    return clone_spec_with_aes(spec, mapping)
}
