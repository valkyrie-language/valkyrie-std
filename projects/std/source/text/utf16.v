namespace std.text;


class Utf16Text {
    _bytes: Vector<u8> 
}

imply Utf16Text: Text {
    micro len(self) -> i32 {
        return utf16_len(self)
    }

    micro is_empty(self) -> bool {
        return utf16_len(self) == 0
    }

    micro to_utf8(self) -> utf8 {
        return utf16_to_utf8(self)
    }

    micro to_utf16(self) -> utf16 {
        return self
    }

    micro to_c_str(self) -> c_str {
        return utf16_to_c_str(self)
    }
}
