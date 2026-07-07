# gnosis.text

文本渲染最小集，提供字体度量 / 字形数据 / 文本 shaping / 字形图集 / 数字短文本生成，
作为 HUD 与浮字显示的文本数据来源。

## 设计目标

- 最小文本数据面：Font / Glyph / ShapedGlyph / GlyphAtlas / NumberText
- 首版按等宽 shaping 处理，稳定支持数字、短标签、波次标题
- 不重复定义 GPU 类型，图集纹理句柄引用 `gnosis.gpu`
- 不含复杂排版（bidi / 换行 / 禁则），不含字体解析细节（由 host contract 提供）

## 文件布局

| 文件 | 职责 |
|------|------|
| `source/font.v` | FontMetrics / Glyph / Font 与 load_font host contract |
| `source/shaping.v` | ShapedGlyph / ShapedRun / shape_text（等宽首版） |
| `source/atlas.v` | GlyphAtlas：字形图集纹理管理与 add_glyph / get_glyph |
| `source/number_text.v` | NumberText：把 i32/f64 格式化为短文本（"1234" / "1.2k"） |

## 能力清单

- Font 持有度量、字形表与图集纹理句柄，支持 find_glyph 二分查找
- shape_text 按等宽步进生成 ShapedGlyph 序列，累积 x_advance
- GlyphAtlas 管理固定尺寸图集纹理，按字形 id 存取 AtlasSlot
- NumberText 支持 i32 整数格式化与 k/m 短缩写格式化

## 上游依赖

- `gnosis.gpu`：ImageHandle 等句柄类型
- `gnosis.render`：draw path（绘制消费方）

## 不在范围内

- 字体文件解析（TTF / OTF）
- 复杂文本 shaping（连字 / bidi / 禁则）
- 多行排版与换行算法
- 距离场 / SDF 字形
