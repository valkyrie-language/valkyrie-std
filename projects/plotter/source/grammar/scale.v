namespace plotter;

# 比例尺声明。首期只有 continuous / discrete 开关，训练在 scene 构建时完成。

micro scale_x_continuous(spec: PlotSpec) -> PlotSpec {
    return clone_spec_scales(spec, true, spec.y_continuous, false, spec.y_discrete)
}

micro scale_y_continuous(spec: PlotSpec) -> PlotSpec {
    return clone_spec_scales(spec, spec.x_continuous, true, spec.x_discrete, false)
}

micro scale_x_discrete(spec: PlotSpec) -> PlotSpec {
    return clone_spec_scales(spec, false, spec.y_continuous, true, spec.y_discrete)
}

micro scale_y_discrete(spec: PlotSpec) -> PlotSpec {
    return clone_spec_scales(spec, spec.x_continuous, false, spec.x_discrete, true)
}

structure ScaleDomain {
    min_value: f64
    max_value: f64
    labels: [utf8]
    is_discrete: bool
}

micro continuous_domain(min_value: f64, max_value: f64) -> ScaleDomain {
    let low: f64 = if min_value < 0.0 { min_value } else { 0.0 }
    let high: f64 = if max_value <= low { low + 1.0 } else { max_value }
    return ScaleDomain {
        min_value: low,
        max_value: high,
        labels: [],
        is_discrete: false
    }
}

micro discrete_domain(labels: [utf8]) -> ScaleDomain {
    return ScaleDomain {
        min_value: 0.0,
        max_value: if labels.length() == 0 { 1.0 } else { labels.length() as f64 },
        labels: labels,
        is_discrete: true
    }
}

micro map_continuous(domain: ScaleDomain, value: f64, range_min: f64, range_max: f64) -> f64 {
    let span: f64 = domain.max_value - domain.min_value
    if span <= 0.0 {
        return range_min
    }
    let t: f64 = (value - domain.min_value) / span
    return range_min + t * (range_max - range_min)
}

micro map_discrete_index(domain: ScaleDomain, label: utf8, range_min: f64, range_max: f64) -> f64 {
    let count: f64 = domain.labels.length() as f64
    if count <= 0.0 {
        return (range_min + range_max) * 0.5
    }
    let mut index: usize = 0
    let mut found: usize = 0
    let mut matched: bool = false
    while index < domain.labels.length() {
        if domain.labels[index].equals(label) {
            found = index
            matched = true
        }
        index = index + 1
    }
    if !matched {
        return range_min
    }
    let step: f64 = (range_max - range_min) / count
    return range_min + (found as f64 + 0.5) * step
}

# 报告语义色板（pass/fail/skip 等可覆盖）
micro palette_color(index: usize) -> utf8 {
    let colors: [utf8] = [
        "#3873ad",
        "#22c55e",
        "#ef4444",
        "#f97316",
        "#8b5cf6",
        "#14b8a6",
        "#eab308",
        "#64748b"
    ]
    if colors.length() == 0 {
        return "#3873ad"
    }
    let offset: usize = index % colors.length()
    return colors[offset]
}

micro status_color(status: utf8) -> utf8 {
    if status.equals("pass") || status.equals("通过") || status.equals("covered") {
        return "#22c55e"
    }
    if status.equals("fail") || status.equals("失败") || status.equals("uncovered") {
        return "#ef4444"
    }
    if status.equals("skip") || status.equals("跳过") || status.equals("compile_error") {
        return "#f97316"
    }
    return "#3873ad"
}
