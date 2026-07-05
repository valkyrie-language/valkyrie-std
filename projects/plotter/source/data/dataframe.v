namespace plotter;

# 轻量列式 DataFrame：每列要么是数值要么是离散标签。

structure Column {
    name: utf8
    is_numeric: bool
    numbers: [f64]
    labels: [utf8]
}

structure DataFrame {
    columns: [Column]
    row_count: usize
}

micro empty_dataframe() -> DataFrame {
    return DataFrame {
        columns: [],
        row_count: 0
    }
}

micro dataframe_add_numeric(data: DataFrame, name: utf8, values: [f64]) -> DataFrame {
    let column: Column = Column {
        name: name,
        is_numeric: true,
        numbers: values,
        labels: []
    }
    let mut columns: [Column] = data.columns
    push(columns, column)
    let rows: usize = if data.row_count > values.length() { data.row_count } else { values.length() }
    return DataFrame {
        columns: columns,
        row_count: rows
    }
}

micro dataframe_add_categorical(data: DataFrame, name: utf8, labels: [utf8]) -> DataFrame {
    let column: Column = Column {
        name: name,
        is_numeric: false,
        numbers: [],
        labels: labels
    }
    let mut columns: [Column] = data.columns
    push(columns, column)
    let rows: usize = if data.row_count > labels.length() { data.row_count } else { labels.length() }
    return DataFrame {
        columns: columns,
        row_count: rows
    }
}

micro dataframe_from_xy(x_labels: [utf8], y_values: [f64]) -> DataFrame {
    let data: DataFrame = empty_dataframe()
    let with_x: DataFrame = dataframe_add_categorical(data, "x", x_labels)
    return dataframe_add_numeric(with_x, "y", y_values)
}

micro find_column(data: DataFrame, name: utf8) -> Option<Column> {
    let mut index: usize = 0
    while index < data.columns.length() {
        let column: Column = data.columns[index]
        if column.name.equals(name) {
            return Some(column)
        }
        index = index + 1
    }
    return None
}

micro column_numeric_at(column: Column, row: usize) -> f64 {
    if column.is_numeric {
        if row < column.numbers.length() {
            return column.numbers[row]
        }
        return 0.0
    }
    return row as f64
}

micro column_label_at(column: Column, row: usize) -> utf8 {
    if !column.is_numeric {
        if row < column.labels.length() {
            return column.labels[row]
        }
        return ""
    }
    return format("{}", column.numbers[row])
}

micro column_min(column: Column) -> f64 {
    if !column.is_numeric || column.numbers.length() == 0 {
        return 0.0
    }
    let mut min_value: f64 = column.numbers[0]
    let mut index: usize = 1
    while index < column.numbers.length() {
        let value: f64 = column.numbers[index]
        if value < min_value {
            min_value = value
        }
        index = index + 1
    }
    return min_value
}

micro column_max(column: Column) -> f64 {
    if !column.is_numeric || column.numbers.length() == 0 {
        return 1.0
    }
    let mut max_value: f64 = column.numbers[0]
    let mut index: usize = 1
    while index < column.numbers.length() {
        let value: f64 = column.numbers[index]
        if value > max_value {
            max_value = value
        }
        index = index + 1
    }
    return max_value
}

micro unique_labels(column: Column) -> [utf8] {
    let mut result: [utf8] = []
    if column.is_numeric {
        return result
    }
    let mut index: usize = 0
    while index < column.labels.length() {
        let label: utf8 = column.labels[index]
        if !result.contains(label) {
            push(result, label)
        }
        index = index + 1
    }
    return result
}
