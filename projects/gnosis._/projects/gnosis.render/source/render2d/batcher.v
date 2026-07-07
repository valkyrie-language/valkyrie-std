namespace gnosis.render.render2d;

# gnosis.render.render2d.batcher: 按 BatchKey 分组排序

⍝ 批次，描述一段可合并的连续顶点 / 索引区间。
structure Batch {
    ⍝ 批次键。
    key: BatchKey
    ⍝ 顶点缓冲区起始偏移。
    vertex_offset: u32
    ⍝ 顶点数量。
    vertex_count: u32
    ⍝ 索引缓冲区起始偏移。
    index_offset: u32
    ⍝ 索引数量。
    index_count: u32
}

⍝ 批次化器，将 DrawList 的命令按 BatchKey 分组排序后输出 Batch 列表。
class Batcher {}

imply Batcher {
    ⍝ 创建空批次化器。
    micro new(): Self {
        return Batcher {}
    }

    ⍝ 将 DrawList 的命令按 (layer, blend_mode, texture) 排序后分组为 Batch 列表。
    ⍝ 排序保证 Opaque 先于 Alpha 先于 Additive，World 先于 UI 先于 Debug，
    ⍝ 相同键且顶点 / 索引区间相邻的连续命令合并为单个 Batch。
    micro batch(mut self, list: DrawList): [Batch] {
        let commands: [DrawCommand] = list.commands()
        let sorted: [DrawCommand] = self.sort(commands)

        let mut batches: [Batch] = []
        let count: usize = sorted.length

        let mut i: usize = 0
        while i < count {
            let cmd: DrawCommand = sorted[i]
            let key: BatchKey = BatchKey {
                blend_mode: cmd.blend_mode,
                layer: cmd.layer,
                texture: cmd.texture,
            }

            let mut v_off: u32 = cmd.vertex_offset
            let mut v_cnt: u32 = cmd.vertex_count
            let mut i_off: u32 = cmd.index_offset
            let mut i_cnt: u32 = cmd.index_count

            let mut j: usize = i + 1
            while j < count {
                let next_cmd: DrawCommand = sorted[j]
                let next_key: BatchKey = BatchKey {
                    blend_mode: next_cmd.blend_mode,
                    layer: next_cmd.layer,
                    texture: next_cmd.texture,
                }
                if !self.key_eq(next_key, key) {
                    break
                }

                let v_end: u32 = v_off + v_cnt
                if next_cmd.vertex_offset == v_end {
                    v_cnt = v_cnt + next_cmd.vertex_count
                }

                let i_end: u32 = i_off + i_cnt
                if next_cmd.index_offset == i_end {
                    i_cnt = i_cnt + next_cmd.index_count
                }

                j = j + 1
            }

            push(batches, Batch {
                key: key,
                vertex_offset: v_off,
                vertex_count: v_cnt,
                index_offset: i_off,
                index_count: i_cnt,
            })

            i = j
        }

        return batches
    }

    ⍝ 按 (layer, blend_mode) 插入排序。
    micro sort(mut self, commands: [DrawCommand]): [DrawCommand] {
        let mut sorted: [DrawCommand] = []
        let count: usize = commands.length

        let mut i: usize = 0
        while i < count {
            let cmd: DrawCommand = commands[i]
            let mut pos: usize = 0

            let mut j: usize = 0
            while j < sorted.length {
                if self.compare(cmd, sorted[j]) < 0 {
                    pos = j
                    break
                }
                pos = j + 1
                j = j + 1
            }

            insert(sorted, pos + 1, cmd)
            i = i + 1
        }

        return sorted
    }

    ⍝ 比较两个命令的批次顺序，返回 -1 / 0 / 1。
    micro compare(mut self, a: DrawCommand, b: DrawCommand): i32 {
        let la: u32 = layer_order(a.layer)
        let lb: u32 = layer_order(b.layer)
        if la < lb {
            return -1
        }
        if la > lb {
            return 1
        }

        let ba: u32 = blend_order(a.blend_mode)
        let bb: u32 = blend_order(b.blend_mode)
        if ba < bb {
            return -1
        }
        if ba > bb {
            return 1
        }

        return 0
    }

    ⍝ 判断两个 BatchKey 是否相等。
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
