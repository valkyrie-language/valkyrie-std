namespace gnosis.tools.debug;

using gnosis.render.render2d;

# gnosis.tools.debug.batch_view: 批次分组视图
# 检视 DrawList 的命令，按 BatchKey 分组统计每组的命令数 / 顶点数 / 索引数，
# 也可直接消费 Batcher 输出的 Batch 列表生成摘要。

⍝ 批次分组统计项，描述一个分组键及其聚合数量。
structure BatchGroup {
    ⍝ 批次键（混合模式 / 分层 / 纹理）。
    key: BatchKey
    ⍝ 该分组内的命令数量。
    command_count: u32
    ⍝ 该分组内的顶点总数。
    vertex_count: u32
    ⍝ 该分组内的索引总数。
    index_count: u32
}

⍝ 批次分组视图，将 DrawList 命令按 BatchKey 聚合为统计列表。
class BatchView {}

imply BatchView {
    ⍝ 构造一个空的批次视图。
    micro new(): Self {
        return BatchView {}
    }

    ⍝ 检视 list 的命令，按 BatchKey 分组并返回统计列表。
    ⍝ 分组顺序遵循命令在 list 中的出现顺序，相同键的连续命令合并为一组。
    micro inspect(mut self, list: DrawList): [BatchGroup] {
        let commands: [DrawCommand] = list.commands()
        let count: usize = commands.length
        let mut groups: [BatchGroup] = []

        let mut i: usize = 0
        while i < count {
            let cmd: DrawCommand = commands[i]
            let key: BatchKey = BatchKey {
                blend_mode: cmd.blend_mode,
                layer: cmd.layer,
                texture: cmd.texture,
            }

            let mut cmd_count: u32 = 1
            let mut v_count: u32 = cmd.vertex_count
            let mut i_count: u32 = cmd.index_count

            let mut j: usize = i + 1
            while j < count {
                let next_cmd: DrawCommand = commands[j]
                let next_key: BatchKey = BatchKey {
                    blend_mode: next_cmd.blend_mode,
                    layer: next_cmd.layer,
                    texture: next_cmd.texture,
                }
                if !self.key_eq(key, next_key) {
                    break
                }
                cmd_count = cmd_count + 1
                v_count = v_count + next_cmd.vertex_count
                i_count = i_count + next_cmd.index_count
                j = j + 1
            }

            push(groups, BatchGroup {
                key: key,
                command_count: cmd_count,
                vertex_count: v_count,
                index_count: i_count,
            })

            i = j
        }

        return groups
    }

    ⍝ 使用已有 Batcher 对 list 批次化后生成每个 Batch 的摘要。
    ⍝ command_count 固定为 1（Batch 已合并连续命令，不保留原始命令计数）。
    micro inspect_batched(mut self, batcher: Batcher, list: DrawList): [BatchGroup] {
        let batches: [Batch] = batcher.batch(list)
        let count: usize = batches.length
        let mut groups: [BatchGroup] = []

        let mut i: usize = 0
        while i < count {
            let batch: Batch = batches[i]
            push(groups, BatchGroup {
                key: batch.key,
                command_count: 1,
                vertex_count: batch.vertex_count,
                index_count: batch.index_count,
            })
            i = i + 1
        }

        return groups
    }

    ⍝ 返回分组统计的总命令数。
    micro total_commands(mut self, groups: [BatchGroup]): u32 {
        let mut total: u32 = 0
        let count: usize = groups.length
        let mut i: usize = 0
        while i < count {
            let group: BatchGroup = groups[i]
            total = total + group.command_count
            i = i + 1
        }
        return total
    }

    ⍝ 判断两个 BatchKey 是否相等（分层 / 混合模式 / 纹理句柄）。
    micro key_eq(mut self, a: BatchKey, b: BatchKey): bool {
        if layer_order(a.layer) != layer_order(b.layer) {
            return false
        }
        if blend_order(a.blend_mode) != blend_order(b.blend_mode) {
            return false
        }
        return match a.texture {
            case None:
                match b.texture {
                    case None: true
                    case Some(_): false
                }
            case Some(ta):
                match b.texture {
                    case None: false
                    case Some(tb): ta.id == tb.id
                }
        }
    }
}
