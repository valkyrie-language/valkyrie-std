namespace std.text;

structure c_str {
    _address: usize
}

structure c_char {
    _char: u8
}

imply c_str {
    micro null_ptr() -> Self {
        return Self { _address: 0 }
    }

    micro is_null(self) -> bool {
        return self._address == 0
    }

    micro len(self) -> i32 {
        return c_str_len(self)
    }

    micro is_empty(self) -> bool {
        return c_str_len(self) == 0
    }

    micro to_utf8(self) -> utf8 {
        return c_str_to_utf8(self)
    }

    micro to_utf16(self) -> utf16 {
        return c_str_to_utf16(self)
    }
}

structure jvm_str {
    _address: usize
}

imply jvm_str {
    micro null_ptr() -> Self {
        return Self { _address: 0 }
    }

    micro is_null(self) -> bool {
        return self._address == 0
    }
}
