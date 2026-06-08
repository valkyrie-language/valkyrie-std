namespace std.effect;

⍝ 效应 trait
⍝ 所有效应类型必须实现此 trait，定义效应完成后的恢复类型
trait Effectful {
    ⍝ 效应完成后的恢复类型
    type Resume;
}