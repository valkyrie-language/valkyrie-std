namespace plotter;

# PlotSpec 轻量序列化契约（von/JSON 文本），供 legion 等外部工具接入。

micro geom_kind_name(kind: i32) -> utf8 {
    if kind == 0 { return "col" }
    if kind == 1 { return "bar" }
    if kind == 2 { return "point" }
    if kind == 3 { return "line" }
    if kind == 4 { return "histogram" }
    if kind == 5 { return "hline" }
    if kind == 6 { return "vline" }
    return "unknown"
}

micro plot_spec_to_json(spec: PlotSpec) -> utf8 {
    let mut geoms_json: utf8 = "["
    let mut index: usize = 0
    while index < spec.geoms.length() {
        if index > 0 {
            geoms_json = geoms_json + ","
        }
        let layer: GeomLayer = spec.geoms[index]
        geoms_json = geoms_json
            + "{\"kind\":\""
            + geom_kind_name(layer.kind)
            + "\",\"bins\":"
            + format("{}", layer.bins)
            + ",\"intercept\":"
            + format("{}", layer.intercept)
            + "}"
        index = index + 1
    }
    geoms_json = geoms_json + "]"

    let mut columns_json: utf8 = "["
    index = 0
    while index < spec.data.columns.length() {
        if index > 0 {
            columns_json = columns_json + ","
        }
        let column: Column = spec.data.columns[index]
        columns_json = columns_json
            + "{\"name\":\""
            + column.name
            + "\",\"is_numeric\":"
            + if column.is_numeric { "true" } else { "false" }
            + ",\"length\":"
            + format("{}", if column.is_numeric { column.numbers.length() } else { column.labels.length() })
            + "}"
        index = index + 1
    }
    columns_json = columns_json + "]"

    return "{"
        + "\"width\":" + format("{}", spec.width) + ","
        + "\"height\":" + format("{}", spec.height) + ","
        + "\"title\":\"" + spec.title + "\","
        + "\"subtitle\":\"" + spec.subtitle + "\","
        + "\"x_lab\":\"" + spec.x_lab + "\","
        + "\"y_lab\":\"" + spec.y_lab + "\","
        + "\"theme_id\":" + format("{}", spec.theme_id) + ","
        + "\"aes\":{"
        + "\"x\":\"" + spec.aes.x + "\","
        + "\"y\":\"" + spec.aes.y + "\","
        + "\"fill\":\"" + spec.aes.fill + "\","
        + "\"color\":\"" + spec.aes.color + "\","
        + "\"size\":\"" + spec.aes.size + "\""
        + "},"
        + "\"scales\":{"
        + "\"x_continuous\":" + if spec.x_continuous { "true" } else { "false" } + ","
        + "\"y_continuous\":" + if spec.y_continuous { "true" } else { "false" } + ","
        + "\"x_discrete\":" + if spec.x_discrete { "true" } else { "false" } + ","
        + "\"y_discrete\":" + if spec.y_discrete { "true" } else { "false" }
        + "},"
        + "\"geoms\":" + geoms_json + ","
        + "\"data\":{\"row_count\":" + format("{}", spec.data.row_count) + ",\"columns\":" + columns_json + "}"
        + "}"
}

micro plot_spec_to_von(spec: PlotSpec) -> utf8 {
    # von 形态与 JSON 字段同构，外层用花括号与键值。
    return plot_spec_to_json(spec)
        .replace("\":", ": ")
        .replace(",\"", ", ")
        .replace("{\"", "{ ")
}
