namespace std.adaptor.jvm.collections;

using std.collections;

[host_provider(std::collections::BitSet::new)]
[inline(always)]
private micro bit_set_new(): BitSet {
    return __bit_set_jvm_new()
}

[host_provider(std::collections::BitSet::with_capacity)]
[inline(always)]
private micro bit_set_with_capacity(bits: usize): BitSet {
    return __bit_set_jvm_new_with_capacity(bits)
}

[host_provider(std::collections::BitSet::set)]
[inline(always)]
private micro bit_set_set(bits: BitSet, index: usize): unit {
    __bit_set_jvm_set(bits, index)
}

[host_provider(std::collections::BitSet::clear_bit)]
[inline(always)]
private micro bit_set_clear_bit(bits: BitSet, index: usize): unit {
    __bit_set_jvm_clear_index(bits, index)
}

[host_provider(std::collections::BitSet::get)]
[inline(always)]
private micro bit_set_get(bits: BitSet, index: usize): bool {
    return __bit_set_jvm_get(bits, index)
}

[host_provider(std::collections::BitSet::toggle)]
[inline(always)]
private micro bit_set_toggle(bits: BitSet, index: usize): unit {
    __bit_set_jvm_flip(bits, index)
}

[host_provider(std::collections::BitSet::intersect)]
[inline(always)]
private micro bit_set_intersect(bits: BitSet, other: BitSet): unit {
    __bit_set_jvm_and(bits, other)
}

[host_provider(std::collections::BitSet::union)]
[inline(always)]
private micro bit_set_union(bits: BitSet, other: BitSet): unit {
    __bit_set_jvm_or(bits, other)
}

[host_provider(std::collections::BitSet::difference)]
[inline(always)]
private micro bit_set_difference(bits: BitSet, other: BitSet): unit {
    __bit_set_jvm_and_not(bits, other)
}

[host_provider(std::collections::BitSet::xor)]
[inline(always)]
private micro bit_set_xor(bits: BitSet, other: BitSet): unit {
    __bit_set_jvm_xor(bits, other)
}

[host_provider(std::collections::BitSet::is_empty)]
[inline(always)]
private micro bit_set_is_empty(bits: BitSet): bool {
    return __bit_set_jvm_is_empty(bits)
}

[host_provider(std::collections::BitSet::clear_all)]
[inline(always)]
private micro bit_set_clear_all(bits: BitSet): unit {
    __bit_set_jvm_clear_all(bits)
}

[jvm("java.util.BitSet", "<init>")]
private micro __bit_set_jvm_new(): BitSet { }

[jvm("java.util.BitSet", "<init>")]
private micro __bit_set_jvm_new_with_capacity(bits: usize): BitSet { }

[jvm("java.util.BitSet", "set")]
private micro __bit_set_jvm_set(bits: BitSet, index: usize): unit { }

[jvm("java.util.BitSet", "clear")]
private micro __bit_set_jvm_clear_index(bits: BitSet, index: usize): unit { }

[jvm("java.util.BitSet", "get"), pure]
private micro __bit_set_jvm_get(bits: BitSet, index: usize): bool { }

[jvm("java.util.BitSet", "flip")]
private micro __bit_set_jvm_flip(bits: BitSet, index: usize): unit { }

[jvm("java.util.BitSet", "and")]
private micro __bit_set_jvm_and(bits: BitSet, other: BitSet): unit { }

[jvm("java.util.BitSet", "or")]
private micro __bit_set_jvm_or(bits: BitSet, other: BitSet): unit { }

[jvm("java.util.BitSet", "xor")]
private micro __bit_set_jvm_xor(bits: BitSet, other: BitSet): unit { }

[jvm("java.util.BitSet", "andNot")]
private micro __bit_set_jvm_and_not(bits: BitSet, other: BitSet): unit { }

[jvm("java.util.BitSet", "isEmpty"), pure]
private micro __bit_set_jvm_is_empty(bits: BitSet): bool { }

[jvm("java.util.BitSet", "clear")]
private micro __bit_set_jvm_clear_all(bits: BitSet): unit { }
