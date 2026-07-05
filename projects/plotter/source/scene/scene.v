namespace plotter;

structure PlotScene {
    width: f64
    height: f64
    marks: [Mark]
}

micro panel_left(spec: PlotSpec) -> f64 {
    return spec.margin.left
}

micro panel_right(spec: PlotSpec) -> f64 {
    return spec.width - spec.margin.right
}

micro panel_top(spec: PlotSpec) -> f64 {
    return spec.margin.top
}

micro panel_bottom(spec: PlotSpec) -> f64 {
    return spec.height - spec.margin.bottom
}

micro resolve_x_domain(spec: PlotSpec) -> ScaleDomain {
    let x_name: utf8 = spec.aes.x
    if x_name.equals("") {
        return continuous_domain(0.0, 1.0)
    }
    let maybe: Option<Column> = find_column(spec.data, x_name)
    if maybe.is_none() {
        return continuous_domain(0.0, 1.0)
    }
    let column: Column = maybe.unwrap()
    if spec.x_discrete || !column.is_numeric {
        return discrete_domain(unique_labels(column))
    }
    return continuous_domain(column_min(column), column_max(column))
}

micro resolve_y_domain(spec: PlotSpec) -> ScaleDomain {
    let y_name: utf8 = spec.aes.y
    if y_name.equals("") {
        return continuous_domain(0.0, 1.0)
    }
    let maybe: Option<Column> = find_column(spec.data, y_name)
    if maybe.is_none() {
        return continuous_domain(0.0, 1.0)
    }
    let column: Column = maybe.unwrap()
    if spec.y_discrete || !column.is_numeric {
        return discrete_domain(unique_labels(column))
    }
    return continuous_domain(column_min(column), column_max(column))
}

micro build_scene(spec: PlotSpec) -> PlotScene {
    let mut marks: [Mark] = []
    let x_domain: ScaleDomain = resolve_x_domain(spec)
    let y_domain: ScaleDomain = resolve_y_domain(spec)
    let left: f64 = panel_left(spec)
    let right: f64 = panel_right(spec)
    let top: f64 = panel_top(spec)
    let bottom: f64 = panel_bottom(spec)

    if spec.show_grid {
        marks = append_grid(marks, left, right, top, bottom)
    }
    if spec.show_axis {
        marks = append_axes(marks, left, right, top, bottom)
        marks = append_axis_labels(marks, spec, x_domain, y_domain, left, right, top, bottom)
    }
    if !spec.title.equals("") {
        push(marks, mark_text(left, 20.0, spec.title, "#1a1a2e"))
    }
    if !spec.subtitle.equals("") {
        push(marks, mark_text(left, 36.0, spec.subtitle, "#666666"))
    }

    let mut geom_index: usize = 0
    while geom_index < spec.geoms.length() {
        let layer: GeomLayer = spec.geoms[geom_index]
        marks = append_geom_marks(marks, spec, layer, x_domain, y_domain, left, right, top, bottom, geom_index)
        geom_index = geom_index + 1
    }

    return PlotScene {
        width: spec.width,
        height: spec.height,
        marks: marks
    }
}

micro append_grid(marks: [Mark], left: f64, right: f64, top: f64, bottom: f64) -> [Mark] {
    let mut result: [Mark] = marks
    let mut i: i32 = 1
    while i < 5 {
        let t: f64 = (i as f64) / 5.0
        let y: f64 = bottom - t * (bottom - top)
        push(result, mark_line(left, y, right, y, "#e5e7eb", 1.0))
        let x: f64 = left + t * (right - left)
        push(result, mark_line(x, top, x, bottom, "#e5e7eb", 1.0))
        i = i + 1
    }
    return result
}

micro append_axes(marks: [Mark], left: f64, right: f64, top: f64, bottom: f64) -> [Mark] {
    let mut result: [Mark] = marks
    push(result, mark_line(left, bottom, right, bottom, "#333333", 1.5))
    push(result, mark_line(left, top, left, bottom, "#333333", 1.5))
    return result
}

micro append_axis_labels(marks: [Mark], spec: PlotSpec, x_domain: ScaleDomain, y_domain: ScaleDomain, left: f64, right: f64, top: f64, bottom: f64) -> [Mark] {
    let mut result: [Mark] = marks
    if x_domain.is_discrete {
        let mut index: usize = 0
        while index < x_domain.labels.length() {
            let label: utf8 = x_domain.labels[index]
            let x: f64 = map_discrete_index(x_domain, label, left, right)
            push(result, mark_text(x - 12.0, bottom + 18.0, label, "#555555"))
            index = index + 1
        }
    } else {
        push(result, mark_text(left, bottom + 18.0, format("{}", x_domain.min_value), "#555555"))
        push(result, mark_text(right - 24.0, bottom + 18.0, format("{}", x_domain.max_value), "#555555"))
    }

    push(result, mark_text(4.0, bottom, format("{}", y_domain.min_value), "#555555"))
    push(result, mark_text(4.0, top + 12.0, format("{}", y_domain.max_value), "#555555"))

    if !spec.x_lab.equals("") {
        push(result, mark_text((left + right) * 0.5 - 20.0, bottom + 34.0, spec.x_lab, "#333333"))
    }
    if !spec.y_lab.equals("") {
        push(result, mark_text(8.0, (top + bottom) * 0.5, spec.y_lab, "#333333"))
    }
    return result
}

micro append_geom_marks(
    marks: [Mark],
    spec: PlotSpec,
    layer: GeomLayer,
    x_domain: ScaleDomain,
    y_domain: ScaleDomain,
    left: f64,
    right: f64,
    top: f64,
    bottom: f64,
    geom_index: usize
) -> [Mark] {
    if layer.kind == 5 {
        let y: f64 = map_continuous(y_domain, layer.intercept, bottom, top)
        let mut result: [Mark] = marks
        push(result, mark_line(left, y, right, y, "#ef4444", 1.5))
        return result
    }
    if layer.kind == 6 {
        let x: f64 = map_continuous(x_domain, layer.intercept, left, right)
        let mut result: [Mark] = marks
        push(result, mark_line(x, top, x, bottom, "#ef4444", 1.5))
        return result
    }
    if layer.kind == 4 {
        return append_histogram_marks(marks, spec, layer, y_domain, left, right, top, bottom)
    }
    if layer.kind == 0 || layer.kind == 1 {
        return append_col_marks(marks, spec, x_domain, y_domain, left, right, top, bottom, geom_index)
    }
    if layer.kind == 2 {
        return append_point_marks(marks, spec, x_domain, y_domain, left, right, top, bottom, geom_index)
    }
    if layer.kind == 3 {
        return append_line_marks(marks, spec, x_domain, y_domain, left, right, top, bottom, geom_index)
    }
    return marks
}

micro row_x(spec: PlotSpec, x_domain: ScaleDomain, row: usize, left: f64, right: f64) -> f64 {
    let maybe: Option<Column> = find_column(spec.data, spec.aes.x)
    if maybe.is_none() {
        return left
    }
    let column: Column = maybe.unwrap()
    if x_domain.is_discrete {
        return map_discrete_index(x_domain, column_label_at(column, row), left, right)
    }
    return map_continuous(x_domain, column_numeric_at(column, row), left, right)
}

micro row_y(spec: PlotSpec, y_domain: ScaleDomain, row: usize, top: f64, bottom: f64) -> f64 {
    let maybe: Option<Column> = find_column(spec.data, spec.aes.y)
    if maybe.is_none() {
        return bottom
    }
    let column: Column = maybe.unwrap()
    return map_continuous(y_domain, column_numeric_at(column, row), bottom, top)
}

micro row_fill(spec: PlotSpec, row: usize, fallback_index: usize) -> utf8 {
    if !spec.aes.fill.equals("") {
        let maybe: Option<Column> = find_column(spec.data, spec.aes.fill)
        if maybe.is_some() {
            let column: Column = maybe.unwrap()
            let label: utf8 = column_label_at(column, row)
            let status: utf8 = status_color(label)
            if !status.equals("#3873ad") || label.equals("pass") || label.equals("fail") {
                return status_color(label)
            }
            let categories: [utf8] = unique_labels(column)
            let mut index: usize = 0
            while index < categories.length() {
                if categories[index].equals(label) {
                    return palette_color(index)
                }
                index = index + 1
            }
        }
    }
    return palette_color(fallback_index)
}

micro append_col_marks(
    marks: [Mark],
    spec: PlotSpec,
    x_domain: ScaleDomain,
    y_domain: ScaleDomain,
    left: f64,
    right: f64,
    top: f64,
    bottom: f64,
    geom_index: usize
) -> [Mark] {
    let mut result: [Mark] = marks
    let count: f64 = if x_domain.is_discrete { x_domain.labels.length() as f64 } else { spec.data.row_count as f64 }
    let slot: f64 = if count <= 0.0 { 20.0 } else { (right - left) / count }
    let bar_width: f64 = slot * 0.7
    let mut row: usize = 0
    while row < spec.data.row_count {
        let x_center: f64 = row_x(spec, x_domain, row, left, right)
        let y: f64 = row_y(spec, y_domain, row, top, bottom)
        let height: f64 = bottom - y
        let fill: utf8 = row_fill(spec, row, geom_index + row)
        push(result, mark_rect(x_center - bar_width * 0.5, y, bar_width, height, fill))
        row = row + 1
    }
    return result
}

micro append_point_marks(
    marks: [Mark],
    spec: PlotSpec,
    x_domain: ScaleDomain,
    y_domain: ScaleDomain,
    left: f64,
    right: f64,
    top: f64,
    bottom: f64,
    geom_index: usize
) -> [Mark] {
    let mut result: [Mark] = marks
    let mut row: usize = 0
    while row < spec.data.row_count {
        let x: f64 = row_x(spec, x_domain, row, left, right)
        let y: f64 = row_y(spec, y_domain, row, top, bottom)
        let fill: utf8 = row_fill(spec, row, geom_index + row)
        push(result, mark_circle(x, y, 4.0, fill, "#1a1a2e"))
        row = row + 1
    }
    return result
}

micro append_line_marks(
    marks: [Mark],
    spec: PlotSpec,
    x_domain: ScaleDomain,
    y_domain: ScaleDomain,
    left: f64,
    right: f64,
    top: f64,
    bottom: f64,
    geom_index: usize
) -> [Mark] {
    let mut result: [Mark] = marks
    if spec.data.row_count == 0 {
        return result
    }
    let mut path: utf8 = ""
    let mut row: usize = 0
    while row < spec.data.row_count {
        let x: f64 = row_x(spec, x_domain, row, left, right)
        let y: f64 = row_y(spec, y_domain, row, top, bottom)
        if row == 0 {
            path = "M " + format("{}", x) + " " + format("{}", y)
        } else {
            path = path + " L " + format("{}", x) + " " + format("{}", y)
        }
        row = row + 1
    }
    let stroke: utf8 = palette_color(geom_index)
    push(result, mark_path(path, stroke, 2.0, "none"))
    return result
}

micro increment_bin(counts: [f64], index: usize) -> [f64] {
    let mut result: [f64] = []
    let mut i: usize = 0
    while i < counts.length() {
        if i == index {
            push(result, counts[i] + 1.0)
        } else {
            push(result, counts[i])
        }
        i = i + 1
    }
    return result
}

micro append_histogram_marks(
    marks: [Mark],
    spec: PlotSpec,
    layer: GeomLayer,
    y_domain: ScaleDomain,
    left: f64,
    right: f64,
    top: f64,
    bottom: f64
) -> [Mark] {
    let mut result: [Mark] = marks
    let maybe_x: Option<Column> = find_column(spec.data, spec.aes.x)
    let maybe_y: Option<Column> = find_column(spec.data, spec.aes.y)
    if maybe_x.is_none() && maybe_y.is_none() {
        return result
    }

    let column: Column = if maybe_x.is_some() {
        maybe_x.unwrap()
    } else {
        maybe_y.unwrap()
    }
    if !column.is_numeric || column.numbers.length() == 0 {
        return result
    }

    let bins: i32 = if layer.bins < 1 { 10 } else { layer.bins }
    let min_value: f64 = column_min(column)
    let max_value: f64 = column_max(column)
    let span: f64 = max_value - min_value
    let width: f64 = if span <= 0.0 { 1.0 } else { span / (bins as f64) }

    let mut counts: [f64] = []
    let mut b: i32 = 0
    while b < bins {
        push(counts, 0.0)
        b = b + 1
    }

    let mut row: usize = 0
    while row < column.numbers.length() {
        let value: f64 = column.numbers[row]
        let mut index: i32 = 0
        if width > 0.0 {
            index = ((value - min_value) / width) as i32
        }
        if index < 0 {
            index = 0
        }
        if index >= bins {
            index = bins - 1
        }
        counts = increment_bin(counts, index as usize)
        row = row + 1
    }

    let mut max_count: f64 = 1.0
    let mut i: usize = 0
    while i < counts.length() {
        if counts[i] > max_count {
            max_count = counts[i]
        }
        i = i + 1
    }

    let slot: f64 = (right - left) / (bins as f64)
    let mut bin_index: usize = 0
    while bin_index < counts.length() {
        let count: f64 = counts[bin_index]
        let bar_height: f64 = (count / max_count) * (bottom - top)
        let x: f64 = left + (bin_index as f64) * slot
        let y: f64 = bottom - bar_height
        push(result, mark_rect(x + slot * 0.05, y, slot * 0.9, bar_height, palette_color(0)))
        bin_index = bin_index + 1
    }
    return result
}
