namespace std.math.graph_theory;

# std.math.graph_theory: 有向图邻接表数据结构
# 使用边列表表示法，适合依赖解析等小规模图（< 100 节点）

class DirectedGraph {
    _nodes: [utf8]
    _edge_sources: [utf8]
    _edge_targets: [utf8]
}

# 创建空有向图
micro directed_graph_new() -> DirectedGraph {
    return DirectedGraph {
        _nodes: [],
        _edge_sources: [],
        _edge_targets: []
    }
}

# 添加节点，已存在则忽略
micro directed_graph_add_node(mut graph: DirectedGraph, node: utf8) -> unit {
    if !directed_graph_has_node(graph, node) {
        push(graph._nodes, node)
    }
}

# 添加有向边 from → to，自动补充缺失节点
micro directed_graph_add_edge(mut graph: DirectedGraph, from: utf8, to: utf8) -> unit {
    directed_graph_add_node(graph, from)
    directed_graph_add_node(graph, to)
    push(graph._edge_sources, from)
    push(graph._edge_targets, to)
}

# 检查节点是否存在
micro directed_graph_has_node(graph: DirectedGraph, node: utf8) -> bool {
    let mut i: usize = 0
    while i < graph._nodes.length() {
        if graph._nodes[i] == node {
            return true
        }
        i = i + 1
    }
    return false
}

# 检查边是否存在
micro directed_graph_has_edge(graph: DirectedGraph, from: utf8, to: utf8) -> bool {
    let mut i: usize = 0
    while i < graph._edge_sources.length() {
        if graph._edge_sources[i] == from && graph._edge_targets[i] == to {
            return true
        }
        i = i + 1
    }
    return false
}

# 删除节点及其关联的所有边
micro directed_graph_remove_node(mut graph: DirectedGraph, node: utf8) -> unit {
    let mut new_nodes: [utf8] = []
    let mut i: usize = 0
    while i < graph._nodes.length() {
        if graph._nodes[i] != node {
            push(new_nodes, graph._nodes[i])
        }
        i = i + 1
    }
    graph._nodes = new_nodes

    let mut new_sources: [utf8] = []
    let mut new_targets: [utf8] = []
    i = 0
    while i < graph._edge_sources.length() {
        if graph._edge_sources[i] != node && graph._edge_targets[i] != node {
            push(new_sources, graph._edge_sources[i])
            push(new_targets, graph._edge_targets[i])
        }
        i = i + 1
    }
    graph._edge_sources = new_sources
    graph._edge_targets = new_targets
}

# 删除有向边
micro directed_graph_remove_edge(mut graph: DirectedGraph, from: utf8, to: utf8) -> unit {
    let mut new_sources: [utf8] = []
    let mut new_targets: [utf8] = []
    let mut i: usize = 0
    while i < graph._edge_sources.length() {
        if graph._edge_sources[i] != from || graph._edge_targets[i] != to {
            push(new_sources, graph._edge_sources[i])
            push(new_targets, graph._edge_targets[i])
        }
        i = i + 1
    }
    graph._edge_sources = new_sources
    graph._edge_targets = new_targets
}

# 获取节点的后继列表
micro directed_graph_successors(graph: DirectedGraph, node: utf8) -> [utf8] {
    let mut result: [utf8] = []
    let mut i: usize = 0
    while i < graph._edge_sources.length() {
        if graph._edge_sources[i] == node {
            push(result, graph._edge_targets[i])
        }
        i = i + 1
    }
    return result
}

# 获取节点的前驱列表
micro directed_graph_predecessors(graph: DirectedGraph, node: utf8) -> [utf8] {
    let mut result: [utf8] = []
    let mut i: usize = 0
    while i < graph._edge_sources.length() {
        if graph._edge_targets[i] == node {
            push(result, graph._edge_sources[i])
        }
        i = i + 1
    }
    return result
}

# 获取节点数量
micro directed_graph_node_count(graph: DirectedGraph) -> usize {
    return graph._nodes.length()
}

# 获取边数量
micro directed_graph_edge_count(graph: DirectedGraph) -> usize {
    return graph._edge_sources.length()
}

# 获取所有节点列表
micro directed_graph_nodes(graph: DirectedGraph) -> [utf8] {
    return graph._nodes
}

# 获取节点的出度
micro directed_graph_out_degree(graph: DirectedGraph, node: utf8) -> usize {
    let mut count: usize = 0
    let mut i: usize = 0
    while i < graph._edge_sources.length() {
        if graph._edge_sources[i] == node {
            count = count + 1
        }
        i = i + 1
    }
    return count
}

# 获取节点的入度
micro directed_graph_in_degree(graph: DirectedGraph, node: utf8) -> usize {
    let mut count: usize = 0
    let mut i: usize = 0
    while i < graph._edge_sources.length() {
        if graph._edge_targets[i] == node {
            count = count + 1
        }
        i = i + 1
    }
    return count
}
