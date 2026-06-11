namespace std.math.graph_theory;

# DFS 深度优先遍历
# 从 start 节点出发进行深度优先搜索，返回访问顺序的节点列表
micro dfs(graph: DirectedGraph, start: utf8) -> [utf8] {
    let mut result: [utf8] = []
    let mut visited: [utf8] = []

    dfs_visit(graph, start, visited, result)

    return result
}

# DFS 辅助递归函数
micro dfs_visit(graph: DirectedGraph, node: utf8, visited: [utf8], result: [utf8]) -> unit {
    # 检查是否已访问
    let mut i: usize = 0
    while i < len(visited) {
        if visited[i] == node {
            return
        }
        i = i + 1
    }

    push(visited, node)
    push(result, node)

    let successors: [utf8] = directed_graph_successors(graph, node)
    i = 0
    while i < len(successors) {
        dfs_visit(graph, successors[i], visited, result)
        i = i + 1
    }
}

# BFS 广度优先遍历
# 从 start 节点出发进行广度优先搜索，返回访问顺序的节点列表
micro bfs(graph: DirectedGraph, start: utf8) -> [utf8] {
    let mut result: [utf8] = []
    let mut visited: [utf8] = []
    let mut queue: [utf8] = []

    push(visited, start)
    push(queue, start)

    while len(queue) > 0 {
        let current: utf8 = queue[0]
        queue = array_remove_first(queue)
        push(result, current)

        let successors: [utf8] = directed_graph_successors(graph, current)
        let mut i: usize = 0
        while i < len(successors) {
            let succ: utf8 = successors[i]

            # 检查是否已访问
            let mut is_visited: bool = false
            let mut j: usize = 0
            while j < len(visited) {
                if visited[j] == succ {
                    is_visited = true
                }
                j = j + 1
            }

            if !is_visited {
                push(visited, succ)
                push(queue, succ)
            }
            i = i + 1
        }
    }

    return result
}