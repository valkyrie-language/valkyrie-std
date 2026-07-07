namespace std.data.text.wat;

[tag(WatTokenKindTag)]
unite WatTokenKind {
    EndOfFile

    # 关键字 —— 纯分派标记，不携带数据
    ModuleKeyword
    FuncKeyword
    ImportKeyword
    ExportKeyword
    MemoryKeyword
    TableKeyword
    GlobalKeyword
    DataKeyword
    TypeKeyword
    ParamKeyword
    ResultKeyword
    LocalKeyword
    BlockKeyword
    LoopKeyword
    IfKeyword
    ThenKeyword
    ElseKeyword
    EndKeyword
    StartKeyword
    ElemKeyword
    OffsetKeyword
    ItemKeyword
    MutKeyword

    # 带数据变体 —— 值嵌入 kind 内部，无需外部 text 字段
    Opcode { value: utf8 }
    Identifier { value: utf8 }
    Number { value: utf8 }
    String { value: utf8 }
    Comment { value: utf8 }
    Punctuation { value: utf8 }
}

⍝ 判断文本是否为值类型关键词 -- 仅 lexer 分类用
micro is_wat_value_type(word: utf8) -> bool {
    return word == "i32" || word == "i64" || word == "f32" || word == "f64"
        || word == "funcref" || word == "externref" || word == "v128"
}

structure WatToken {
    kind: WatTokenKind
    span: TextSpan
    line: usize
    column: usize
}

micro new_wat_token(kind: WatTokenKind, start: usize, stop: usize, line: usize, column: usize) -> WatToken {
    return WatToken {
        kind: kind,
        span: TextSpan {
            start: start,
            stop: stop
        },
        line: line,
        column: column
    }
}

micro eof_wat_token(position: usize, line: usize, column: usize) -> WatToken {
    return new_wat_token(EndOfFile, position, position, line, column)
}
