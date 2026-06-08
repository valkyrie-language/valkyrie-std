namespace core::primitive;

⍝ 有符号 32 位
⍝ 原始类型
[primitive("core::primitive::i32")]
structure i32 { }

imply i32 {
    infix `+`(self, rhs: Self): Self {
        __i32_add(self, rhs)
    }

    infix `-`(self, rhs: Self): Self {
        __i32_sub(self, rhs)
    }

    infix `*`(self, rhs: Self): Self {
        __i32_mul(self, rhs)
    }

    infix `/`(self, rhs: Self): Self {
        __i32_div(self, rhs)
    }

    infix `%`(self, rhs: Self): Self {
        __i32_rem(self, rhs)
    }

    infix `^`(self, rhs: Self): Self {
        __i32_pow(self, rhs)
    }

    infix `==`(self, rhs: Self): bool {
        __i32_eq(self, rhs)
    }

    infix `!=`(self, rhs: Self): bool {
        !(self == rhs)
    }

    infix `<`(self, rhs: Self): bool {
        __i32_lt(self, rhs)
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

    prefix `-`(self): Self {
        0 - self
    }

    bit_and(self, rhs: Self): Self {
        __i32_and(self, rhs)
    }

    bit_or(self, rhs: Self): Self {
        __i32_or(self, rhs)
    }

    bit_xor(self, rhs: Self): Self {
        __i32_xor(self, rhs)
    }

    bit_shift_left(self, rhs: Self): Self {
        __i32_shl(self, rhs)
    }

    bit_shift_right(self, rhs: Self): Self {
        __i32_shr(self, rhs)
    }

    bit_not(self): Self {
        self.bit_xor(-1)
    }
}

# region i32 内部指令映射
[intrinsic("i32.add")]
private micro __i32_add(lhs: i32, rhs: i32): i32 { }

[intrinsic("i32.sub")]
private micro __i32_sub(lhs: i32, rhs: i32): i32 { }

[intrinsic("i32.mul")]
private micro __i32_mul(lhs: i32, rhs: i32): i32 { }

[intrinsic("i32.div")]
private micro __i32_div(lhs: i32, rhs: i32): i32 { }

[intrinsic("i32.rem")]
private micro __i32_rem(lhs: i32, rhs: i32): i32 { }

private micro __i32_pow(lhs: i32, rhs: i32): i32 {
    if rhs < 0 {
        return 0
    }

    let mut base: i32 = lhs
    let mut exp: i32 = rhs
    let mut acc: i32 = 1

    while exp > 0 {
        if exp % 2 == 1 {
            acc = acc * base
        }
        base = base * base
        exp = exp / 2
    }

    return acc
}

[intrinsic("i32.eq")]
private micro __i32_eq(lhs: i32, rhs: i32): bool { }

[intrinsic("i32.lt")]
private micro __i32_lt(lhs: i32, rhs: i32): bool { }

[intrinsic("i32.and")]
private micro __i32_and(lhs: i32, rhs: i32): i32 { }

[intrinsic("i32.or")]
private micro __i32_or(lhs: i32, rhs: i32): i32 { }

[intrinsic("i32.xor")]
private micro __i32_xor(lhs: i32, rhs: i32): i32 { }

[intrinsic("i32.shl")]
private micro __i32_shl(lhs: i32, rhs: i32): i32 { }

[intrinsic("i32.shr")]
private micro __i32_shr(lhs: i32, rhs: i32): i32 { }
# end region

