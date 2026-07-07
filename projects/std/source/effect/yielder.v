namespace std.effect;

# 生成器效应
# 用于实现迭代器/生成器语义
# Yield { value: T } 产生一个值并暂停
# YieldBreak 终止生成
# Resume = ()：每次 yield 后恢复为 unit
unite Yielder<T> {
    Yield { value: T }
    YieldBreak
}

imply Yielder<T>: Effectful {
    type Resume = ();
}
