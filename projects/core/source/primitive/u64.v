namespace core::primitive;

⍝ 无符号 64 位整数。
⍝ 适合大范围无符号计数与位级数据表示。
[primitive("core::primitive::u64")]
structure u64 { }

imply u64 {
    infix `+`(self, rhs: Self): Self {
        __u64_add(self, rhs)
    }

    infix `-`(self, rhs: Self): Self {
        __u64_sub(self, rhs)
    }

    infix `*`(self, rhs: Self): Self {
        __u64_mul(self, rhs)
    }

    infix `/`(self, rhs: Self): Self {
        __u64_div(self, rhs)
    }

    infix `%`(self, rhs: Self): Self {
        __u64_rem(self, rhs)
    }

    infix `==`(self, rhs: Self): bool {
        __u64_eq(self, rhs)
    }

    infix `!=`(self, rhs: Self): bool {
        !(self == rhs)
    }

    infix `<`(self, rhs: Self): bool {
        __u64_lt(self, rhs)
    }

    infix `<=`(self, rhs: Self): bool {
        !(rhs < self)
    }

    infix `>`(self, rhs: Self): bool {
        rhs < self
    }

    infix `>=`(self, rhs: Self): bool {
        !(self < rhs)
    }

    bit_and(self, rhs: Self): Self {
        __u64_and(self, rhs)
    }

    bit_or(self, rhs: Self): Self {
        __u64_or(self, rhs)
    }

    bit_xor(self, rhs: Self): Self {
        __u64_xor(self, rhs)
    }

    bit_shift_left(self, rhs: Self): Self {
        __u64_shl(self, rhs)
    }

    bit_shift_right(self, rhs: Self): Self {
        __u64_shr(self, rhs)
    }
}

[intrinsic("u64.add")]
private micro __u64_add(lhs: u64, rhs: u64): u64;

[intrinsic("u64.sub")]
private micro __u64_sub(lhs: u64, rhs: u64): u64 { }

[intrinsic("u64.mul")]
private micro __u64_mul(lhs: u64, rhs: u64): u64 { }

[intrinsic("u64.div")]
private micro __u64_div(lhs: u64, rhs: u64): u64 { }

[intrinsic("u64.rem")]
private micro __u64_rem(lhs: u64, rhs: u64): u64 { }

[intrinsic("u64.eq")]
private micro __u64_eq(lhs: u64, rhs: u64): bool { }

[intrinsic("u64.lt")]
private micro __u64_lt(lhs: u64, rhs: u64): bool { }

[intrinsic("u64.and")]
private micro __u64_and(lhs: u64, rhs: u64): u64 { }

[intrinsic("u64.or")]
private micro __u64_or(lhs: u64, rhs: u64): u64 { }

[intrinsic("u64.xor")]
private micro __u64_xor(lhs: u64, rhs: u64): u64 { }

[intrinsic("u64.shl")]
private micro __u64_shl(lhs: u64, rhs: u64): u64 { }

[intrinsic("u64.shr")]
private micro __u64_shr(lhs: u64, rhs: u64): u64 { }
