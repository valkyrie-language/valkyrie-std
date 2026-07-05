namespace plotter;

# 坐标系。首期仅笛卡尔；facet_wrap 为预留 no-op。

micro coord_cartesian(spec: PlotSpec) -> PlotSpec {
    return spec
}

micro facet_wrap(spec: PlotSpec, by: utf8) -> PlotSpec {
    return PlotSpec {
        data: spec.data,
        aes: spec.aes,
        geoms: spec.geoms,
        title: spec.title,
        subtitle: spec.subtitle,
        x_lab: spec.x_lab,
        y_lab: spec.y_lab,
        width: spec.width,
        height: spec.height,
        theme_id: spec.theme_id,
        x_continuous: spec.x_continuous,
        y_continuous: spec.y_continuous,
        x_discrete: spec.x_discrete,
        y_discrete: spec.y_discrete,
        show_grid: spec.show_grid,
        show_axis: spec.show_axis,
        margin: spec.margin,
        facet_by: by
    }
}
