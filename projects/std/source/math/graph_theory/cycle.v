namespace std.math.graph_theory;

# 检测有向图中是否存在循环
# 使用 Kahn 拓扑排序检查：若拓扑排序结果长度 < 节点数，则存在环
micro has_cycle(graph: DirectedGraph) -> bool {
    let sorted: [utf8] = topological_sort(graph)
    let node_count: usize = directed_graph_node_count(graph)
    return sorted.length() < node_count
}

# 查找图中的一条循环路径
# 使用 DFS 染色法（三色标记）：White=0, Gray=1, Black=2
# 返回循环路径，无环返回空列表
# CLR 自举阶段：避免 iterator HOF（map/collect），改用显式 while。
micro find_cycle(graph: DirectedGraph) -> [utf8] {
    let nodes: [utf8] = directed_graph_nodes(graph)
    if nodes.length() == 0 {
        return []
    }

    let mut color: [usize] = []
    let mut parent: [utf8] = []
    let mut init: usize = 0
    while init < nodes.length() {
        push(color, 0)
        push(parent, "")
        init = init + 1
    }

    let mut i: usize = 0

    while i < nodes.length() {
        if color⁅i⁆ == 0 {
            let cycle: [utf8] = find_cycle_dfs(graph, nodes, color, parent, nodes⁅i⁆)
            if cycle.length() > 0 {
                return cycle
            }
        }
        i = i + 1
    }

    return []
}

# DFS 辅助函数，返回发现的循环路径
micro find_cycle_dfs(graph: DirectedGraph, nodes: [utf8], mut color: [usize], mut parent: [utf8], node: utf8) -> [utf8] {
    # 找到节点索引
    let mut idx: usize = 0
    let mut found: bool = false
    let mut i: usize = 0
    while i < nodes.length() {
        if nodes⁅i⁆ == node {
            idx = i
            found = true
        }
        i = i + 1
    }

    if !found {
        return []
    }

    color⁅idx⁆ = 1

    let successors: [utf8] = directed_graph_successors(graph, node)
    loop succ in successors {
        let mut succ_idx: usize = 0
        let mut succ_found: bool = false
        let mut j: usize = 0
        while j < nodes.length() {
            if nodes⁅j⁆ == succ {
                succ_idx = j
                succ_found = true
            }
            j = j + 1
        }

        if succ_found {
            if color⁅succ_idx⁆ == 1 {
                # 发现环，从 succ → node 回溯构建路径
                let mut cycle: [utf8] = []
                push(cycle, succ)
                let mut current: utf8 = node
                while current != succ {
                    push(cycle, current)
                    # 找 current 的父节点
                    let mut p_idx: usize = 0
                    let mut p_found: bool = false
                    let mut k: usize = 0
                    while k < nodes.length() {
                        if nodes⁅k⁆ == current {
                            p_idx = k
                            p_found = true
                        }
                        k = k + 1
                    }
                    if p_found && parent⁅p_idx⁆.length() > 0 {
                        current = parent⁅p_idx⁆
                    }
                    else {
                        current = succ
                    }
                }
                push(cycle, succ)
                return cycle
            }
            if color⁅succ_idx⁆ == 0 {
                parent⁅succ_idx⁆ = node
                let sub_cycle: [utf8] = find_cycle_dfs(graph, nodes, color, parent, succ)
                if sub_cycle.length() > 0 {
                    return sub_cycle
                }
            }
        }
    }

    color⁅idx⁆ = 2
    return []
}
