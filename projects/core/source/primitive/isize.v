namespace core::primitive;

⍝ 有符号指针宽度整数。
⍝ 适合平台相关有符号偏移与差值表示。
[primitive("core::primitive::isize")]
structure isize { }

imply isize {
    infix `+`(self, rhs: Self): Self {
        __isize_add(self, rhs)
    }

    infix `-`(self, rhs: Self): Self {
        __isize_sub(self, rhs)
    }

    infix `*`(self, rhs: Self): Self {
        __isize_mul(self, rhs)
    }

    infix `/`(self, rhs: Self): Self {
        __isize_div(self, rhs)
    }

    infix `%`(self, rhs: Self): Self {
        __isize_rem(self, rhs)
    }

    infix `==`(self, rhs: Self): bool {
        __isize_eq(self, rhs)
    }

    infix `!=`(self, rhs: Self): bool {
        !(self == rhs)
    }

    infix `<`(self, rhs: Self): bool {
        __isize_lt(self, rhs)
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
        __isize_neg(self)
    }

    bit_and(self, rhs: Self): Self {
        __isize_and(self, rhs)
    }

    bit_or(self, rhs: Self): Self {
        __isize_or(self, rhs)
    }

    bit_xor(self, rhs: Self): Self {
        __isize_xor(self, rhs)
    }

    bit_shift_left(self, rhs: Self): Self {
        __isize_shl(self, rhs)
    }

    bit_shift_right(self, rhs: Self): Self {
        __isize_shr(self, rhs)
    }
}

[intrinsic("isize.add")]
private micro __isize_add(lhs: isize, rhs: isize): isize;

[intrinsic("isize.sub")]
private micro __isize_sub(lhs: isize, rhs: isize): isize { }

[intrinsic("isize.neg")]
private micro __isize_neg(self: isize): isize { }

[intrinsic("isize.mul")]
private micro __isize_mul(lhs: isize, rhs: isize): isize { }

[intrinsic("isize.div")]
private micro __isize_div(lhs: isize, rhs: isize): isize { }

[intrinsic("isize.rem")]
private micro __isize_rem(lhs: isize, rhs: isize): isize { }

[intrinsic("isize.eq")]
private micro __isize_eq(lhs: isize, rhs: isize): bool { }

[intrinsic("isize.lt")]
private micro __isize_lt(lhs: isize, rhs: isize): bool { }

[intrinsic("isize.and")]
private micro __isize_and(lhs: isize, rhs: isize): isize { }

[intrinsic("isize.or")]
private micro __isize_or(lhs: isize, rhs: isize): isize { }

[intrinsic("isize.xor")]
private micro __isize_xor(lhs: isize, rhs: isize): isize { }

[intrinsic("isize.shl")]
private micro __isize_shl(lhs: isize, rhs: isize): isize { }

[intrinsic("isize.shr")]
private micro __isize_shr(lhs: isize, rhs: isize): isize { }
