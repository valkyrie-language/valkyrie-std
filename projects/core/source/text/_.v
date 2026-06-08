namespace core::text;

⍝ 文本区间
⍝ 使用 (起始偏移, 长度) 描述一段连续文本的位置。
⍝ 这是 `RedGreenTree`、`Rope`、`PieceTable` 等高效文本结构常用的定位方式。
structure TextSpan {
    ⍝ 起始字节偏移量
    offset: usize,
    ⍝ 从起始偏移量开始的字节数
    length: usize
}

imply TextSpan {
    ⍝ 将文本范围转换为字节范围
    micro as_range(self) -> Range<usize> {
        return Range(self.offset, self.offset + self.length)
    }
}

⍝ 文本接口
⍝ 所有文本类型（本体、视图、构造器等）均可实现此接口。
trait Text {
    ⍝ 该文本类型的不可变视图类型
    type View: TextView<Text = Self>;
    ⍝ 文本是否为空
    micro is_empty(self) -> bool;
    ⍝ 获取文本的不可变视图
    micro view(self, span: TextSpan) -> Self::View;
    ⍝ 切分一段新的文本，具有独立的所有权和可变性（对本体的要求）
    micro slice(self, span: TextSpan) -> Self;
}

⍝ 文本视图接口
⍝ 视图是对底层文本的只读窗口，自身不可变，不拥有数据。
trait TextView: Text {
    ⍝ 视图对应的底层文本类型
    type Text: Text;
    ⍝ 获得文本视图的文本区间
    micro span(self) -> TextSpan;
    ⍝ 将文本视图重新具体化为底层文本类型
    ⍝ 假定有开销，不消耗视图
    micro to_text(self) -> Self::Text;
}

# `as_*` 一般用于无开销且不消耗原始数据的操作
# `to_*` 一般用于有开销但不消耗原始数据的操作，这里的开销指的是含栈分配以外的操作
# `into_*` 一般用于消耗原始数据的操作，无论是否有开销
