namespace std.math.graph_theory;

# 计算传递后继闭包
# 返回从 start 节点出发可到达的所有节点（不含自身）
# CLR 自举阶段：避免 iterator HOF（any/filter），改用显式 while。
micro transitive_successors(graph: DirectedGraph, start: utf8) -> [utf8] {
    let mut visited: [utf8] = []
    push(visited, start)

    let mut queue: [utf8] = []
    push(queue, start)

    while queue.length() > 0 {
        let current: utf8 = queue⁅0⁆
        queue = array_remove_first(queue)

        let successors: [utf8] = directed_graph_successors(graph, current)
        loop succ in successors {
            let mut is_visited: bool = false
            let mut j: usize = 0
            while j < visited.length() {
                if visited⁅j⁆ == succ {
                    is_visited = true
                }
                j = j + 1
            }

            if !is_visited {
                push(visited, succ)
                push(queue, succ)
            }
        }
    }

    let mut result: [utf8] = []
    let mut i: usize = 0
    while i < visited.length() {
        if visited⁅i⁆ != start {
            push(result, visited⁅i⁆)
        }
        i = i + 1
    }
    return result
}

# 计算传递前驱闭包
# 返回可到达 start 节点的所有节点（不含自身）
micro transitive_predecessors(graph: DirectedGraph, start: utf8) -> [utf8] {
    let mut visited: [utf8] = []
    push(visited, start)

    let mut queue: [utf8] = []
    push(queue, start)

    while queue.length() > 0 {
        let current: utf8 = queue⁅0⁆
        queue = array_remove_first(queue)

        let predecessors: [utf8] = directed_graph_predecessors(graph, current)
        loop pred in predecessors {
            let mut is_visited: bool = false
            let mut j: usize = 0
            while j < visited.length() {
                if visited⁅j⁆ == pred {
                    is_visited = true
                }
                j = j + 1
            }

            if !is_visited {
                push(visited, pred)
                push(queue, pred)
            }
        }
    }

    let mut result: [utf8] = []
    let mut i: usize = 0
    while i < visited.length() {
        if visited⁅i⁆ != start {
            push(result, visited⁅i⁆)
        }
        i = i + 1
    }
    return result
}
