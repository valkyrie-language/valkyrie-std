namespace std.data.text.msil;

[tag(MsilTokenKindTag)]
unite MsilTokenKind {
    EndOfFile

    # 指令 -- 纯分派标记，不携带数据
    AssemblyDirective
    ModuleDirective
    ClassDirective
    OverrideDirective
    PermissionDirective
    PermissionSetDirective
    HashDirective
    VerDirective
    LocaleDirective
    PublicKeyDirective
    CustomDirective
    PackDirective
    SizeDirective
    FieldDirective
    MethodDirective
    PropertyDirective
    EventDirective
    MaxStackDirective
    LocalsDirective
    TryDirective
    LineDirective
    LanguageDirective
    EntryPointDirective
    GetDirective
    SetDirective
    AddOnDirective
    RemoveOnDirective
    FireDirective
    PInvokeImplDirective

    # 关键字 -- 纯分派标记，不携带数据
    ExtendsKeyword
    ImplementsKeyword
    CatchKeyword
    FilterKeyword
    FinallyKeyword
    FaultKeyword
    InitKeyword
    DefaultKeyword
    VarArgKeyword
    AtKeyword
    AsKeyword
    CilKeyword
    ManagedKeyword

    # 带数据变体 -- 值嵌入 kind 内部，无需外部 text 字段
    Opcode { value: utf8 }
    Identifier { value: utf8 }
    TypeReference { value: utf8 }
    Number { value: utf8 }
    String { value: utf8 }
    IllLabel { value: utf8 }
    Comment { value: utf8 }
    Punctuation { value: utf8 }
}

structure MsilToken {
    kind: MsilTokenKind
    span: TextSpan
    line: usize
    column: usize
}

micro new_msil_token(kind: MsilTokenKind, start: usize, stop: usize, line: usize, column: usize) -> MsilToken {
    return MsilToken {
        kind: kind,
        span: TextSpan {
            start: start,
            stop: stop
        },
        line: line,
        column: column
    }
}

micro eof_msil_token(position: usize, line: usize, column: usize) -> MsilToken {
    return new_msil_token(EndOfFile, position, position, line, column)
}

⍝ 判断 token 文本是否为 MSIL 修饰符 -- 仅 lexer 分类用
micro is_msil_modifier_text(word: utf8) -> bool {
    return word == "public" || word == "private" || word == "family" || word == "assembly"
        || word == "famandassem" || word == "famorassem" || word == "privatescope"
        || word == "static" || word == "instance" || word == "virtual" || word == "abstract"
        || word == "sealed" || word == "final" || word == "specialname" || word == "rtspecialname"
        || word == "initonly" || word == "literal" || word == "notserialized"
        || word == "value" || word == "enum" || word == "interface"
        || word == "sequential" || word == "auto" || word == "explicit"
        || word == "ansi" || word == "unicode" || word == "autochar"
        || word == "beforefieldinit" || word == "forwardref" || word == "preservesig"
        || word == "internalcall" || word == "synchronized" || word == "noinlining"
        || word == "aggressiveinlining" || word == "optil" || word == "nooptimization"
}
