# std.collections: primitive Hash implementations

namespace std.collections;

imply utf8: Hash {
    micro hash(self) -> usize {
        return std.collections.hash_utf8(self)
    }
}

imply i32: Hash {
    micro hash(self) -> usize {
        return self as usize
    }
}

imply u32: Hash {
    micro hash(self) -> usize {
        return std.collections.hash_utf8(stringify(self))
    }
}

imply i64: Hash {
    micro hash(self) -> usize {
        return self as usize
    }
}

imply u64: Hash {
    micro hash(self) -> usize {
        return std.collections.hash_utf8(stringify(self))
    }
}

imply f32: Hash {
    micro hash(self) -> usize {
        return (self * 1000000.0) as usize
    }
}

imply f64: Hash {
    micro hash(self) -> usize {
        return (self * 1000000.0) as usize
    }
}

micro hash_utf8(s: utf8) -> usize {
    let mut hash: usize = 0
    let mut i: usize = 0
    while i < s.length {
        hash = hash * 31 + s[i] as usize
        i = i + 1
    }
    return hash
}
