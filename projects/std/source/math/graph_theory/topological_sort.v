namespace std.math.graph_theory;

# Kahn 拓扑排序算法
# 对有向无环图 (DAG) 返回拓扑序排列的节点列表
# 若图中存在循环，返回空列表
micro topological_sort(graph: DirectedGraph) -> [utf8] {
    let mut result: [utf8] = []
    let nodes: [utf8] = directed_graph_nodes(graph)

    if nodes.length() == 0 {
        return result
    }

    # 计算所有节点的初始入度
    let mut in_degree: [usize] = []
    let mut i: usize = 0
    while i < nodes.length() {
        push(in_degree, directed_graph_in_degree(graph, nodes[i]))
        i = i + 1
    }

    # 入度为 0 的节点入队
    let mut queue: [utf8] = []
    i = 0
    while i < nodes.length() {
        if in_degree[i] == 0 {
            push(queue, nodes[i])
        }
        i = i + 1
    }

    # Kahn 算法主循环
    while queue.length() > 0 {
        let current: utf8 = queue[0]
        queue = array_remove_first(queue)
        push(result, current)

        let successors: [utf8] = directed_graph_successors(graph, current)
        loop succ in successors {
            # 找到后继节点在 nodes 中的索引，减少入度
            let mut k: usize = 0
            while k < nodes.length() {
                if nodes[k] == succ {
                    in_degree[k] = in_degree[k] - 1
                    if in_degree[k] == 0 {
                        push(queue, succ)
                    }
                }
                k = k + 1
            }
        }
    }

    # 如果有环，结果长度小于节点数
    if result.length() < nodes.length() {
        return []
    }

    return result
}

# 移除数组第一个元素的辅助函数
micro array_remove_first(arr: [utf8]) -> [utf8] {
    if arr.length() <= 1 {
        return []
    }
    let mut result: [utf8] = []
    let mut i: usize = 1
    while i < arr.length() {
        push(result, arr[i])
        i = i + 1
    }
    return result
}
