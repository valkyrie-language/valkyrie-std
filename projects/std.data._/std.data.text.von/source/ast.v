namespace std.data.text.von;

[tag(VonValueKind)]
unite VonValue {
    Text { value: utf8 }
    Flag { value: bool }
    Number { value: utf8 }
    Name { value: utf8 }
    Array { items: [VonValue] }
    Object { fields: [VonField] }
    Empty
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

micro von_is_object(value: VonValue) -> bool {
    match value {
        case Object(_):
            return true
        else:
            return false
    }
}

micro von_find_field(value: VonValue, field_name: utf8) -> VonValue {
    match value {
        case Object(fields):
            # Indexed while — `loop field in fields` currently lowers to `while true`
            # without advancing the cursor (CLR livelock when the key is missing).
            let mut index: usize = 0
            while index < fields.length() {
                let field: VonField = fields⁅index⁆
                if field.name == field_name {
                    return field.value
                }
                index = index + 1
            }
            return Empty
        else:
            return Empty
    }
}

micro von_as_text(value: VonValue) -> utf8 {
    match value {
        case Text(text):
            return text
        case Name(text):
            return text
        case Number(text):
            return text
        else:
            return ""
    }
}

micro von_as_bool(value: VonValue) -> bool {
    match value {
        case Flag(flag):
            return flag
        else:
            return false
    }
}

micro von_as_array(value: VonValue) -> [VonValue] {
    match value {
        case Array(items):
            return items
        else:
            return []
    }
}

micro von_as_object(value: VonValue) -> [VonField] {
    match value {
        case Object(fields):
            return fields
        else:
            return []
    }
}
