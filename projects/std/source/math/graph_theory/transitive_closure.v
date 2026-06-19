namespace std.math.graph_theory;

# 计算传递后继闭包
# 返回从 start 节点出发可到达的所有节点（不含自身）
micro transitive_successors(graph: DirectedGraph, start: utf8) -> [utf8] {
    # 使用 BFS 计算可达节点
    let mut visited: [utf8] = []
    push(visited, start)

    let mut queue: [utf8] = []
    push(queue, start)

    while queue.length() > 0 {
        let current: utf8 = queue[0]
        queue = array_remove_first(queue)

        let successors: [utf8] = directed_graph_successors(graph, current)
        loop succ in successors {
            let is_visited: bool = visited
                .into_iterator()
                .any(micro(visited_node: utf8) -> bool {
                    return visited_node == succ
                })

            if !is_visited {
                push(visited, succ)
                push(queue, succ)
            }
        }
    }

    # 移除 start 自身
    return visited
        .into_iterator()
        .filter(micro(node: utf8) -> bool {
            return node != start
        })
        |> std.iterator.collect_array()
}

# 计算传递前驱闭包
# 返回可到达 start 节点的所有节点（不含自身）
micro transitive_predecessors(graph: DirectedGraph, start: utf8) -> [utf8] {
    let mut visited: [utf8] = []
    push(visited, start)

    let mut queue: [utf8] = []
    push(queue, start)

    while queue.length() > 0 {
        let current: utf8 = queue[0]
        queue = array_remove_first(queue)

        let predecessors: [utf8] = directed_graph_predecessors(graph, current)
        loop pred in predecessors {
            let is_visited: bool = visited
                .into_iterator()
                .any(micro(visited_node: utf8) -> bool {
                    return visited_node == pred
                })

            if !is_visited {
                push(visited, pred)
                push(queue, pred)
            }
        }
    }

    # 移除 start 自身
    return visited
        .into_iterator()
        .filter(micro(node: utf8) -> bool {
            return node != start
        })
        |> std.iterator.collect_array()
}
