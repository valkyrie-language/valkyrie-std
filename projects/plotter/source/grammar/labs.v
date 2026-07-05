namespace plotter;

micro labs(spec: PlotSpec, title: utf8, x: utf8, y: utf8) -> PlotSpec {
    return PlotSpec {
        data: spec.data,
        aes: spec.aes,
        geoms: spec.geoms,
        title: title,
        subtitle: spec.subtitle,
        x_lab: x,
        y_lab: y,
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
        facet_by: spec.facet_by
    }
}

micro labs_title(spec: PlotSpec, title: utf8) -> PlotSpec {
    return labs(spec, title, spec.x_lab, spec.y_lab)
}

micro labs_subtitle(spec: PlotSpec, subtitle: utf8) -> PlotSpec {
    return PlotSpec {
        data: spec.data,
        aes: spec.aes,
        geoms: spec.geoms,
        title: spec.title,
        subtitle: subtitle,
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
        facet_by: spec.facet_by
    }
}
