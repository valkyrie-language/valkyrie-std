namespace gnosis.layout;

# gnosis.layout.hud_layout: HUD 组件布局
# 组合血条 / XP 条 / cooldown widget 的测量与排列，提供 HUD 各组件的最终矩形。
# 内部复用 AnchorLayout 完成锚点定位。

⍝ HUD 组件种类，用于在 HudLayout 中区分不同 widget。
unite HudSlot {
    ⍝ 血条。
    HealthBar
    ⍝ XP 条。
    XpBar
    ⍝ 冷却 widget。
    Cooldown
}

⍝ 单个 HUD 组件的布局结果。
structure HudSlotRect {
    ⍝ 组件种类。
    slot: HudSlot
    ⍝ 组件最终矩形。
    rect: Rect
}

⍝ HUD 布局，按屏幕容器与各组件测量尺寸计算最终位置。
class HudLayout {
    ⍝ 屏幕容器矩形。
    _screen: Rect
    ⍝ 已排列的组件矩形列表。
    _slots: [HudSlotRect]
}

imply HudLayout {
    ⍝ 创建指定屏幕矩形的 HUD 布局。
    micro new(screen: Rect): Self {
        return HudLayout {
            _screen: screen,
            _slots: [],
        }
    }

    ⍝ 返回屏幕容器矩形。
    micro screen(self): Rect {
        return self._screen
    }

    ⍝ 返回已排列的组件矩形列表。
    micro slots(self): [HudSlotRect] {
        return self._slots
    }

    ⍝ 布局血条：左上角，指定尺寸与边距。
    micro layout_health_bar(mut self, size: MeasureResult, margin: f32): Rect {
        let layout: AnchorLayout = AnchorLayout::new(self._screen)
        let r: Rect = layout.place(size, TopLeft, margin)
        push(self._slots, HudSlotRect { slot: HealthBar, rect: r })
        return r
    }

    ⍝ 布局 XP 条：底部居中，指定尺寸与边距。
    micro layout_xp_bar(mut self, size: MeasureResult, margin: f32): Rect {
        let layout: AnchorLayout = AnchorLayout::new(self._screen)
        let r: Rect = layout.place(size, BottomCenter, margin)
        push(self._slots, HudSlotRect { slot: XpBar, rect: r })
        return r
    }

    ⍝ 布局冷却 widget：右下角，指定尺寸与边距。
    micro layout_cooldown(mut self, size: MeasureResult, margin: f32): Rect {
        let layout: AnchorLayout = AnchorLayout::new(self._screen)
        let r: Rect = layout.place(size, BottomRight, margin)
        push(self._slots, HudSlotRect { slot: Cooldown, rect: r })
        return r
    }

    ⍝ 清空已排列的组件矩形列表，保留屏幕矩形。
    micro clear(mut self): unit {
        self._slots = []
    }
}
