namespace std.data.text.valkyrie;

# Isomorphic to Rust `std-data::text::valkyrie::cst`.

unite ValSyntaxKind {
    Root
    Statement
    Trivia
    Error
}

unite ValCstElement {
    Trivia {
        text: utf8
        span: TextSpan
    }
    Statement {
        leading: utf8
        # Index into accompanying AST statement list (full RootStatement attach later).
        statement_index: i32
        trailing: utf8
    }
    Error {
        message: utf8
        text: utf8
        span: TextSpan
    }
}

structure ValCstFile {
    elements: [ValCstElement]
}

micro empty_val_cst_file() -> ValCstFile {
    return ValCstFile {
        elements: []
    }
}
