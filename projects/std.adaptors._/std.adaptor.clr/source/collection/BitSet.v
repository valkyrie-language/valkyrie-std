namespace std.adaptor.clr.collections;

using std.collections;

[host_provider(std::collections::BitSet::new)]
[inline(always)]
private micro bit_set_new(): BitSet {
    return __bit_set_clr_new(0)
}

[host_provider(std::collections::BitSet::with_capacity)]
[inline(always)]
private micro bit_set_with_capacity(bits: usize): BitSet {
    return __bit_set_clr_new(bits)
}

[host_provider(std::collections::BitSet::set)]
[inline(always)]
private micro bit_set_set(bits: BitSet, index: usize): unit {
    if index >= __bit_set_clr_length(bits) {
        __bit_set_clr_set_length(bits, index + 1)
    }

    __bit_set_clr_set_value(bits, index, true)
}

[host_provider(std::collections::BitSet::clear_bit)]
[inline(always)]
private micro bit_set_clear_bit(bits: BitSet, index: usize): unit {
    if index >= __bit_set_clr_length(bits) {
        return
    }

    __bit_set_clr_set_value(bits, index, false)
}

[host_provider(std::collections::BitSet::get)]
[inline(always)]
private micro bit_set_get(bits: BitSet, index: usize): bool {
    return bit_set_clr_get_or_false(bits, index)
}

[host_provider(std::collections::BitSet::toggle)]
[inline(always)]
private micro bit_set_toggle(bits: BitSet, index: usize): unit {
    let value: bool = bit_set_clr_get_or_false(bits, index)
    if !value && index >= __bit_set_clr_length(bits) {
        __bit_set_clr_set_length(bits, index + 1)
    }

    __bit_set_clr_set_value(bits, index, !value)
}

[host_provider(std::collections::BitSet::intersect)]
[inline(always)]
private micro bit_set_intersect(bits: BitSet, other: BitSet): unit {
    let self_length: usize = __bit_set_clr_length(bits)
    let other_length: usize = __bit_set_clr_length(other)
    let maximum_length: usize = if self_length > other_length { self_length } else { other_length }
    if self_length < maximum_length {
        __bit_set_clr_set_length(bits, maximum_length)
    }

    let mut i: usize = 0
    while i < maximum_length {
        __bit_set_clr_set_value(bits, i, bit_set_clr_get_or_false(bits, i) && bit_set_clr_get_or_false(other, i))
        i = i + 1
    }
}

[host_provider(std::collections::BitSet::union)]
[inline(always)]
private micro bit_set_union(bits: BitSet, other: BitSet): unit {
    let self_length: usize = __bit_set_clr_length(bits)
    let other_length: usize = __bit_set_clr_length(other)
    let maximum_length: usize = if self_length > other_length { self_length } else { other_length }
    if self_length < maximum_length {
        __bit_set_clr_set_length(bits, maximum_length)
    }

    let mut i: usize = 0
    while i < maximum_length {
        __bit_set_clr_set_value(bits, i, bit_set_clr_get_or_false(bits, i) || bit_set_clr_get_or_false(other, i))
        i = i + 1
    }
}

[host_provider(std::collections::BitSet::difference)]
[inline(always)]
private micro bit_set_difference(bits: BitSet, other: BitSet): unit {
    let self_length: usize = __bit_set_clr_length(bits)
    let mut i: usize = 0
    while i < self_length {
        __bit_set_clr_set_value(bits, i, bit_set_clr_get_or_false(bits, i) && !bit_set_clr_get_or_false(other, i))
        i = i + 1
    }
}

[host_provider(std::collections::BitSet::xor)]
[inline(always)]
private micro bit_set_xor(bits: BitSet, other: BitSet): unit {
    let self_length: usize = __bit_set_clr_length(bits)
    let other_length: usize = __bit_set_clr_length(other)
    let maximum_length: usize = if self_length > other_length { self_length } else { other_length }
    if self_length < maximum_length {
        __bit_set_clr_set_length(bits, maximum_length)
    }

    let mut i: usize = 0
    while i < maximum_length {
        __bit_set_clr_set_value(bits, i, bit_set_clr_get_or_false(bits, i) != bit_set_clr_get_or_false(other, i))
        i = i + 1
    }
}

[host_provider(std::collections::BitSet::is_empty)]
[inline(always)]
private micro bit_set_is_empty(bits: BitSet): bool {
    let length: usize = __bit_set_clr_length(bits)
    let mut i: usize = 0
    while i < length {
        if __bit_set_clr_get(bits, i) {
            return false
        }

        i = i + 1
    }

    return true
}

[host_provider(std::collections::BitSet::clear_all)]
[inline(always)]
private micro bit_set_clear_all(bits: BitSet): unit {
    __bit_set_clr_set_all(bits, false)
}

[inline(always)]
private micro bit_set_clr_get_or_false(bits: BitSet, index: usize): bool {
    if index >= __bit_set_clr_length(bits) {
        return false
    }

    return __bit_set_clr_get(bits, index)
}

[clr("System.Collections", "System.Collections.BitArray", ".ctor")]
private micro __bit_set_clr_new(length: usize): BitSet { }

[clr("System.Collections", "System.Collections.BitArray", "Get"), pure]
private micro __bit_set_clr_get(bits: BitSet, index: usize): bool { }

[clr("System.Collections", "System.Collections.BitArray", "Set")]
private micro __bit_set_clr_set_value(bits: BitSet, index: usize, value: bool): unit { }

[clr("System.Collections", "System.Collections.BitArray", "get_Length"), pure]
private micro __bit_set_clr_length(bits: BitSet): usize { }

[clr("System.Collections", "System.Collections.BitArray", "set_Length")]
private micro __bit_set_clr_set_length(bits: BitSet, length: usize): unit { }

[clr("System.Collections", "System.Collections.BitArray", "SetAll")]
private micro __bit_set_clr_set_all(bits: BitSet, value: bool): unit { }
