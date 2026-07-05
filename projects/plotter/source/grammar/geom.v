namespace plotter;

# 几何图层。kind: 0=col, 1=bar, 2=point, 3=line, 4=histogram, 5=hline, 6=vline

micro push_geom(spec: PlotSpec, layer: GeomLayer) -> PlotSpec {
    let mut geoms: [GeomLayer] = spec.geoms
    push(geoms, layer)
    return clone_spec_with_geoms(spec, geoms)
}

micro geom_col(spec: PlotSpec) -> PlotSpec {
    return push_geom(spec, GeomLayer { kind: 0, bins: 0, intercept: 0.0 })
}

micro geom_bar(spec: PlotSpec) -> PlotSpec {
    return push_geom(spec, GeomLayer { kind: 1, bins: 0, intercept: 0.0 })
}

micro geom_point(spec: PlotSpec) -> PlotSpec {
    return push_geom(spec, GeomLayer { kind: 2, bins: 0, intercept: 0.0 })
}

micro geom_line(spec: PlotSpec) -> PlotSpec {
    return push_geom(spec, GeomLayer { kind: 3, bins: 0, intercept: 0.0 })
}

micro geom_histogram(spec: PlotSpec, bins: i32) -> PlotSpec {
    let count: i32 = if bins < 1 { 10 } else { bins }
    return push_geom(spec, GeomLayer { kind: 4, bins: count, intercept: 0.0 })
}

micro geom_hline(spec: PlotSpec, intercept: f64) -> PlotSpec {
    return push_geom(spec, GeomLayer { kind: 5, bins: 0, intercept: intercept })
}

micro geom_vline(spec: PlotSpec, intercept: f64) -> PlotSpec {
    return push_geom(spec, GeomLayer { kind: 6, bins: 0, intercept: intercept })
}
