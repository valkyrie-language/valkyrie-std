namespace plotter;

# plotter — Valkyrie 图形语法（ggplot2 心智，SVG 优先）
#
# 典型用法：
#   let chart = dataframe_from_xy(labels, values)
#       |> plot()
#       |> aes("x", "y")
#       |> geom_col()
#       |> scale_y_continuous()
#       |> labs("Title", "X", "Y")
#       |> theme_minimal()
#       |> render_svg()
