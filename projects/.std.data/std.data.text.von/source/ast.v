namespace std.data.text.von;

unite VonValueKind {
    TextValue
    FlagValue
    NumberValue
    NameValue
    ArrayValue
    ObjectValue
    EmptyValue
}

structure VonValue {
    kind: VonValueKind
    text: utf8
    flag: bool
    number: utf8
    name: utf8
    items: [VonValue]
    fields: [VonField]
}

structure VonField {
    name: utf8
    value: VonValue
}

micro new_von_field(name: utf8, value: VonValue) -> VonField {
    return VonField {
        name: name,
        value: value
    }
}

micro Text(text: utf8) -> VonValue {
    return VonValue {
        kind: TextValue,
        text: text,
        flag: false,
        number: "",
        name: "",
        items: [],
        fields: []
    }
}

micro Flag(flag: bool) -> VonValue {
    return VonValue {
        kind: FlagValue,
        text: "",
        flag: flag,
        number: "",
        name: "",
        items: [],
        fields: []
    }
}

micro Number(number: utf8) -> VonValue {
    return VonValue {
        kind: NumberValue,
        text: "",
        flag: false,
        number: number,
        name: "",
        items: [],
        fields: []
    }
}

micro Name(name: utf8) -> VonValue {
    return VonValue {
        kind: NameValue,
        text: "",
        flag: false,
        number: "",
        name: name,
        items: [],
        fields: []
    }
}

micro Array(items: [VonValue]) -> VonValue {
    return VonValue {
        kind: ArrayValue,
        text: "",
        flag: false,
        number: "",
        name: "",
        items: items,
        fields: []
    }
}

micro Object(fields: [VonField]) -> VonValue {
    return VonValue {
        kind: ObjectValue,
        text: "",
        flag: false,
        number: "",
        name: "",
        items: [],
        fields: fields
    }
}

micro Empty() -> VonValue {
    return VonValue {
        kind: EmptyValue,
        text: "",
        flag: false,
        number: "",
        name: "",
        items: [],
        fields: []
    }
}

micro von_find_field(value: VonValue, field_name: utf8) -> VonValue {
    if value.kind != ObjectValue {
        return Empty()
    }
    loop field in value.fields {
        if field.name == field_name {
            return field.value
        }
    }
    return Empty()
}

micro von_as_text(value: VonValue) -> utf8 {
    if value.kind == TextValue {
        return value.text
    }
    if value.kind == NameValue {
        return value.name
    }
    if value.kind == NumberValue {
        return value.number
    }
    return ""
}

micro von_as_bool(value: VonValue) -> bool {
    if value.kind == FlagValue {
        return value.flag
    }
    return false
}

micro von_as_array(value: VonValue) -> [VonValue] {
    if value.kind == ArrayValue {
        return value.items
    }
    return []
}

micro von_as_object(value: VonValue) -> [VonField] {
    if value.kind == ObjectValue {
        return value.fields
    }
    return []
}

micro von_is_object(value: VonValue) -> bool {
    return value.kind == ObjectValue
}
