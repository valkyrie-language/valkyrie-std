namespace nyar.language.valkyrie;

structure ParsedClrExtern {
    assembly: utf8
    owner_type: utf8
    method_name: utf8
}

structure ParsedFunction {
    name: utf8
    is_main: bool
    is_clr_extern: bool
    return_is_unit: bool
    return_is_i64: bool
    clr_extern: ParsedClrExtern
    body_source: utf8
}

structure ParsedModule {
    namespace_name: utf8
    functions: [ParsedFunction]
}

micro empty_parsed_module() -> ParsedModule {
    return ParsedModule {
        namespace_name: "",
        functions: []
    }
}

micro empty_parsed_function() -> ParsedFunction {
    return ParsedFunction {
        name: "",
        is_main: false,
        is_clr_extern: false,
        return_is_unit: false,
        return_is_i64: false,
        clr_extern: ParsedClrExtern {
            assembly: "",
            owner_type: "",
            method_name: ""
        },
        body_source: ""
    }
}
