namespace std.effect;

# 日志效应
# raise Log { msg: "..." } 将消息交由 handler 处理
# Resume = Never：handler 不可 resume，一旦 resume 直接报错
structure Log {
    msg: utf8
}

imply Log: Effectful {
    type Resume = Never;
}
