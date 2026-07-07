namespace asgard.plotter;

# asgard.plotter — 绘图 UI 壳
#
# Widgets（source/components/）：
#   - Plot.awsl                裸图容器，props: svg_html, width
#   - PlotCard.awsl            带标题/副标题/页脚的卡片壳
#   - PlotGrid.awsl            多图网格
#   - InteractiveColPlot.awsl  交互柱图（on:click + reactive；仅 asgard auto glue）
#
# 出图语法由依赖包 `plotter` 提供：render_svg(PlotSpec) -> utf8
# Helpers：col_series_items / plot_col_svg / plot_line_svg / plot_histogram_svg
# UI 层负责呈现与交互绑定，不手写业务 JS。
