namespace gnosis.text;

# gnosis.text.atlas: 字形图集纹理管理
# GlyphAtlas 负责分配图集槽位、记录字形 UV，并持有上传到 GPU 的图集纹理句柄。
# 首版采用固定尺寸图集 + 顺序行打包，满足 HUD 与浮字所需字形量。

⍝ 图集槽位，记录单个字形在图集中的归一化 UV 与像素尺寸。
structure AtlasSlot {
    ⍝ 字形标识。
    glyph_id: u32
    ⍝ 左边界 U（归一化）。
    u0: f32
    ⍝ 上边界 V（归一化）。
    v0: f32
    ⍝ 右边界 U（归一化）。
    u1: f32
    ⍝ 下边界 V（归一化）。
    v1: f32
    ⍝ 槽位像素宽度。
    pixel_w: i32
    ⍝ 槽位像素高度。
    pixel_h: i32
}

⍝ 字形图集，管理图集纹理与槽位表。
class GlyphAtlas {
    ⍝ 图集纹理像素宽度。
    _width: i32
    ⍝ 图集纹理像素高度。
    _height: i32
    ⍝ 已上传的图集纹理句柄，None 表示尚未上传。
    _texture: Option<ImageHandle>
    ⍝ 槽位表，按 glyph_id 查找。
    _slots: [AtlasSlot]
    ⍝ 下一个可用槽位的像素 x 坐标（行内光标）。
    _cursor_x: i32
    ⍝ 下一个可用槽位的像素 y 坐标（当前行顶部）。
    _cursor_y: i32
    ⍝ 当前行已使用的最大高度，用于换行时推进 _cursor_y。
    _row_max_h: i32
    ⍝ 单个字形的像素边距（避免采样溢出）。
    _padding: i32
}

imply GlyphAtlas {
    ⍝ 创建指定尺寸与边距的空图集，纹理句柄初始为 None。
    micro new(width: i32, height: i32, padding: i32): Self {
        return GlyphAtlas {
            _width: width,
            _height: height,
            _texture: None,
            _slots: [],
            _cursor_x: 0,
            _cursor_y: 0,
            _row_max_h: 0,
            _padding: padding,
        }
    }

    ⍝ 返回图集纹理宽度（像素）。
    micro width(self): i32 {
        return self._width
    }

    ⍝ 返回图集纹理高度（像素）。
    micro height(self): i32 {
        return self._height
    }

    ⍝ 返回已上传的图集纹理句柄，None 表示尚未上传。
    micro texture(self): Option<ImageHandle> {
        return self._texture
    }

    ⍝ 设置图集纹理句柄（由宿主上传纹理后回填）。
    micro set_texture(mut self, texture: ImageHandle): unit {
        self._texture = Some::<ImageHandle>(texture)
    }

    ⍝ 返回当前已记录的所有槽位（供宿主上传像素数据使用）。
    micro slots(self): [AtlasSlot] {
        return self._slots
    }

    ⍝ 向图集中添加一个字形槽位，返回该槽位。
    ⍝ 若图集空间不足（行内放不下且已到图集底部），返回 None。
    micro add_glyph(mut self, glyph_id: u32, pixel_w: i32, pixel_h: i32): Option<AtlasSlot> {
        let pad: i32 = self._padding
        let need_w: i32 = pixel_w + pad * 2
        let need_h: i32 = pixel_h + pad * 2

        if self._cursor_x + need_w > self._width {
            self._cursor_x = 0
            self._cursor_y = self._cursor_y + self._row_max_h
            self._row_max_h = 0
        }
        if self._cursor_y + need_h > self._height {
            return None
        }

        let px: i32 = self._cursor_x + pad
        let py: i32 = self._cursor_y + pad
        let inv_w: f32 = 1.0 / (self._width as f32)
        let inv_h: f32 = 1.0 / (self._height as f32)
        let slot: AtlasSlot = AtlasSlot {
            glyph_id: glyph_id,
            u0: (px as f32) * inv_w,
            v0: (py as f32) * inv_h,
            u1: ((px + pixel_w) as f32) * inv_w,
            v1: ((py + pixel_h) as f32) * inv_h,
            pixel_w: pixel_w,
            pixel_h: pixel_h,
        }
        push(self._slots, slot)

        self._cursor_x = self._cursor_x + need_w
        if need_h > self._row_max_h {
            self._row_max_h = need_h
        }
        return Some::<AtlasSlot>(slot)
    }

    ⍝ 按 glyph_id 查找槽位，未找到返回 None。
    micro get_glyph(self, glyph_id: u32): Option<AtlasSlot> {
        let slots: [AtlasSlot] = self._slots
        let count: usize = slots.length
        let mut i: usize = 0
        while i < count {
            let slot: AtlasSlot = slots[i]
            if slot.glyph_id == glyph_id {
                return Some::<AtlasSlot>(slot)
            }
            i = i + 1
        }
        return None
    }

    ⍝ 清空所有槽位并重置打包光标，保留纹理句柄与尺寸。
    micro clear(mut self): unit {
        self._slots = []
        self._cursor_x = 0
        self._cursor_y = 0
        self._row_max_h = 0
    }
}
