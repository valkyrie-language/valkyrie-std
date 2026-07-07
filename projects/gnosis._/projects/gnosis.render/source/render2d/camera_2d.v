namespace gnosis.render.render2d;

# gnosis.render.render2d.camera_2d: 2D 相机与视图矩阵

⍝ 3×2 仿射视图矩阵（行主序）。
⍝ 上 2×2 为旋转 + 缩放，第三行为平移。
structure ViewMatrix {
    ⍝ 第 0 行第 0 列。
    m00: f32
    ⍝ 第 0 行第 1 列。
    m01: f32
    ⍝ 第 1 行第 0 列。
    m10: f32
    ⍝ 第 1 行第 1 列。
    m11: f32
    ⍝ 第 2 行第 0 列（平移 X）。
    m20: f32
    ⍝ 第 2 行第 1 列（平移 Y）。
    m21: f32
}

⍝ 将视图矩阵序列化为字节序列，用于 push_constants 上传。
⍝ 字节布局：6 × f32，共 24 字节，行主序。
[host_contract]
micro view_matrix_to_bytes(matrix: ViewMatrix): [u8]

⍝ 返回单位视图矩阵（无旋转 / 缩放 / 平移），用于 HUD 等屏幕空间 pass。
micro identity_view(): ViewMatrix {
    return ViewMatrix {
        m00: 1.0,
        m01: 0.0,
        m10: 0.0,
        m11: 1.0,
        m20: 0.0,
        m21: 0.0,
    }
}

⍝ 2D 正交相机，通过 position / zoom / rotation 控制世界到视图的变换。
class Camera2D {
    ⍝ 相机中心在世界空间的位置。
    _position: [f32; 2]
    ⍝ 缩放系数，> 1 放大。
    _zoom: f32
    ⍝ 旋转弧度。
    _rotation: f32
}

imply Camera2D {
    ⍝ 创建位于原点、无旋转、缩放为 1 的相机。
    micro new(): Self {
        return Camera2D {
            _position: [0.0, 0.0],
            _zoom: 1.0,
            _rotation: 0.0,
        }
    }

    ⍝ 返回相机位置。
    micro position(self): [f32; 2] {
        return self._position
    }

    ⍝ 返回缩放系数。
    micro zoom(self): f32 {
        return self._zoom
    }

    ⍝ 返回旋转弧度。
    micro rotation(self): f32 {
        return self._rotation
    }

    ⍝ 设置相机位置。
    micro set_position(mut self, position: [f32; 2]): unit {
        self._position = position
    }

    ⍝ 设置缩放系数。
    micro set_zoom(mut self, zoom: f32): unit {
        self._zoom = zoom
    }

    ⍝ 设置旋转弧度。
    micro set_rotation(mut self, rotation: f32): unit {
        self._rotation = rotation
    }

    ⍝ 计算世界到视图的仿射矩阵。
    ⍝ 变换顺序：平移 -position → 旋转 -rotation → 缩放 1/zoom。
    micro view_matrix(self): ViewMatrix {
        let cos_r: f32 = cos(self._rotation)
        let sin_r: f32 = sin(self._rotation)
        let inv_zoom: f32 = 1.0 / self._zoom

        let m00: f32 = cos_r * inv_zoom
        let m01: f32 = sin_r * inv_zoom
        let m10: f32 = -sin_r * inv_zoom
        let m11: f32 = cos_r * inv_zoom
        let m20: f32 = -(m00 * self._position[0] + m01 * self._position[1])
        let m21: f32 = -(m10 * self._position[0] + m11 * self._position[1])

        return ViewMatrix {
            m00: m00,
            m01: m01,
            m10: m10,
            m11: m11,
            m20: m20,
            m21: m21,
        }
    }

    ⍝ 将屏幕坐标转换为世界坐标。
    ⍝ screen_size 为交换链当前范围（像素）。
    micro screen_to_world(self, screen: [f32; 2], screen_size: [f32; 2]): [f32; 2] {
        let ndc_x: f32 = (2.0 * screen[0]) / screen_size[0] - 1.0
        let ndc_y: f32 = 1.0 - (2.0 * screen[1]) / screen_size[1]

        let scaled_x: f32 = ndc_x * self._zoom
        let scaled_y: f32 = ndc_y * self._zoom

        let cos_r: f32 = cos(self._rotation)
        let sin_r: f32 = sin(self._rotation)

        let world_x: f32 = cos_r * scaled_x - sin_r * scaled_y + self._position[0]
        let world_y: f32 = sin_r * scaled_x + cos_r * scaled_y + self._position[1]

        return [world_x, world_y]
    }
}
