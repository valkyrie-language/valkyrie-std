namespace gnosis.text;

# gnosis.text.number_text: 数字短文本生成
# NumberText 把 i32 / f64 格式化为 HUD 与浮字所需的短文本，
# 支持纯整数形式与 k / m 短缩写形式，便于快速构建 damage number。

⍝ 数字文本的格式风格。
unite NumberStyle {
    ⍝ 纯整数形式，如 "1234" / "-56"。
    Plain
    ⍝ 短缩写形式，如 "1.2k" / "3.4m"，绝对值小于 1000 时退化为 Plain。
    Short
}

⍝ 数字文本生成器，缓存生成结果供一帧内多次引用。
class NumberText {
    ⍝ 已生成的文本，供调用方读取。
    _text: utf8
    ⍝ 当前使用的格式风格。
    _style: NumberStyle
}

imply NumberText {
    ⍝ 创建空的 NumberText，默认风格为 Plain。
    micro new(): Self {
        return NumberText {
            _text: "",
            _style: Plain,
        }
    }

    ⍝ 返回当前已生成的文本。
    micro text(self): utf8 {
        return self._text
    }

    ⍝ 设置格式风格。
    micro set_style(mut self, style: NumberStyle): unit {
        self._style = style
    }

    ⍝ 将 i32 格式化为文本并写入缓存，返回生成的文本。
    micro format_i32(mut self, value: i32): utf8 {
        let result: utf8 = i32_to_utf8(value)
        self._text = result
        return result
    }

    ⍝ 将 i32 按 Short 风格格式化为短文本并写入缓存，返回生成的文本。
    ⍝ 绝对值小于 1000 时输出纯整数；否则输出一位小数 + k / m 后缀。
    micro format_i32_short(mut self, value: i32): utf8 {
        let result: utf8 = format_short_i32(value)
        self._text = result
        return result
    }

    ⍝ 将 f64 按 Short 风格格式化为短文本并写入缓存，返回生成的文本。
    ⍝ 绝对值小于 1000 时输出整数部分；否则输出一位小数 + k / m 后缀。
    micro format_f64_short(mut self, value: f64): utf8 {
        let result: utf8 = format_short_f64(value)
        self._text = result
        return result
    }
}

⍝ 将 i32 格式化为短文本：小于 1000 输出整数，否则输出 k / m 缩写。
micro format_short_i32(value: i32): utf8 {
    let neg: bool = value < 0
    let mut mag: i32 = value
    if neg {
        mag = -value
    }
    if mag < 1000 {
        return i32_to_utf8(value)
    }
    let body: utf8 = format_magnitude_short(mag)
    if neg {
        return "-".concat(body)
    }
    return body
}

⍝ 将 f64 格式化为短文本：按绝对值大小输出 k / m 缩写。
micro format_short_f64(value: f64): utf8 {
    let neg: bool = value < 0.0
    let mut mag: f64 = value
    if neg {
        mag = -value
    }
    if mag < 1000.0 {
        let truncated: i32 = (mag as i32)
        let body: utf8 = i32_to_utf8(truncated)
        if neg {
            return "-".concat(body)
        }
        return body
    }
    let body: utf8 = format_magnitude_short_f64(mag)
    if neg {
        return "-".concat(body)
    }
    return body
}

⍝ 将不小于 1000 的 i32 量级格式化为 k / m 短文本（带一位小数）。
micro format_magnitude_short(mag: i32): utf8 {
    if mag >= 1000000 {
        let scaled: i32 = mag / 100000
        let int_part: i32 = scaled / 10
        let frac: i32 = scaled % 10
        return i32_to_utf8(int_part).concat(".").concat(i32_to_utf8(frac)).concat("m")
    }
    let scaled: i32 = mag / 100
    let int_part: i32 = scaled / 10
    let frac: i32 = scaled % 10
    return i32_to_utf8(int_part).concat(".").concat(i32_to_utf8(frac)).concat("k")
}

⍝ 将不小于 1000 的 f64 量级格式化为 k / m 短文本（带一位小数）。
micro format_magnitude_short_f64(mag: f64): utf8 {
    if mag >= 1000000.0 {
        let scaled: i32 = ((mag / 100000.0) as i32)
        let int_part: i32 = scaled / 10
        let frac: i32 = scaled % 10
        return i32_to_utf8(int_part).concat(".").concat(i32_to_utf8(frac)).concat("m")
    }
    let scaled: i32 = ((mag / 100.0) as i32)
    let int_part: i32 = scaled / 10
    let frac: i32 = scaled % 10
    return i32_to_utf8(int_part).concat(".").concat(i32_to_utf8(frac)).concat("k")
}
