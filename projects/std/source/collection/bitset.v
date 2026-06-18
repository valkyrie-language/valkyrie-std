namespace std.collections;

# std.collections: BitSet - 位图

[clr("System.Collections", "System.Collections.BitArray")]
[jvm("java.util.BitSet")]
class BitSet {
    words: List<u64>
}

imply BitSet {
    micro new(): Self {
        <% match arch %>
            <% case "clr" %>
        return __bit_set_clr_new(0)
            <% case "jvm" %>
        return __bit_set_jvm_new()
            <% else %>
        return Self { words: ArrayList::new(0) }
        <% end match %>
    }

    micro with_capacity(bits: usize): Self {
        <% match arch %>
            <% case "clr" %>
        return __bit_set_clr_new(bits)
            <% case "jvm" %>
        return __bit_set_jvm_new_with_capacity(bits)
            <% else %>
        let words_needed: usize = (bits + 63) / 64
        let mut words: List<u64> = ArrayList::new(0)
        let mut i: usize = 0
        while i < words_needed {
            words.push(0u64)
            i = i + 1
        }
        return Self { words: words }
        <% end match %>
    }

    micro set(mut self, index: usize): unit {
        <% match arch %>
            <% case "clr" %>
        if index >= __bit_set_clr_length(self) {
            __bit_set_clr_set_length(self, index + 1)
        }

        __bit_set_clr_set_value(self, index, true)
            <% case "jvm" %>
        __bit_set_jvm_set(self, index)
            <% else %>
        let word_idx: usize = index / 64
        let bit_idx: usize = index % 64
        self.ensure_capacity(word_idx + 1)
        let word: u64 = self.words.get(word_idx).unwrap()
        self.words.set(word_idx, word | (1u64 << bit_idx))
        <% end match %>
    }

    micro clear_bit(mut self, index: usize): unit {
        <% match arch %>
            <% case "clr" %>
        if index >= __bit_set_clr_length(self) {
            return
        }

        __bit_set_clr_set_value(self, index, false)
            <% case "jvm" %>
        __bit_set_jvm_clear_index(self, index)
            <% else %>
        let word_idx: usize = index / 64
        let bit_idx: usize = index % 64
        if word_idx >= self.words.length() {
            return
        }
        let word: u64 = self.words.get(word_idx).unwrap()
        self.words.set(word_idx, word & ~(1u64 << bit_idx))
        <% end match %>
    }

    micro get(self, index: usize): bool {
        <% match arch %>
            <% case "clr" %>
        if index >= __bit_set_clr_length(self) {
            return false
        }

        return __bit_set_clr_get(self, index)
            <% case "jvm" %>
        return __bit_set_jvm_get(self, index)
            <% else %>
        let word_idx: usize = index / 64
        let bit_idx: usize = index % 64
        if word_idx >= self.words.length() {
            return false
        }
        let word: u64 = self.words.get(word_idx).unwrap()
        return (word & (1u64 << bit_idx)) != 0u64
        <% end match %>
    }

    micro toggle(mut self, index: usize): unit {
        <% match arch %>
            <% case "clr" %>
        let value: bool = self.get(index)
        if !value && index >= __bit_set_clr_length(self) {
            __bit_set_clr_set_length(self, index + 1)
        }

        __bit_set_clr_set_value(self, index, !value)
            <% case "jvm" %>
        __bit_set_jvm_flip(self, index)
            <% else %>
        if self.get(index) {
            self.clear_bit(index)
        } else {
            self.set(index)
        }
        <% end match %>
    }

    micro intersect(mut self, other: BitSet): unit {
        <% match arch %>
            <% case "clr" %>
        let self_length: usize = __bit_set_clr_length(self)
        let other_length: usize = __bit_set_clr_length(other)
        let max_length: usize = if self_length > other_length { self_length } else { other_length }
        if self_length < max_length {
            __bit_set_clr_set_length(self, max_length)
        }

        let mut i: usize = 0
        while i < max_length {
            __bit_set_clr_set_value(self, i, self.get(i) && other.get(i))
            i = i + 1
        }
            <% case "jvm" %>
        __bit_set_jvm_and(self, other)
            <% else %>
        let min_length: usize = if self.words.length() < other.words.length() { self.words.length() } else { other.words.length() }
        let mut i: usize = 0
        while i < min_length {
            let a: u64 = self.words.get(i).unwrap()
            let b: u64 = other.words.get(i).unwrap()
            self.words.set(i, a & b)
            i = i + 1
        }
        while i < self.words.length() {
            self.words.set(i, 0u64)
            i = i + 1
        }
        <% end match %>
    }

    micro union(mut self, other: BitSet): unit {
        <% match arch %>
            <% case "clr" %>
        let self_length: usize = __bit_set_clr_length(self)
        let other_length: usize = __bit_set_clr_length(other)
        let max_length: usize = if self_length > other_length { self_length } else { other_length }
        if self_length < max_length {
            __bit_set_clr_set_length(self, max_length)
        }

        let mut i: usize = 0
        while i < max_length {
            __bit_set_clr_set_value(self, i, self.get(i) || other.get(i))
            i = i + 1
        }
            <% case "jvm" %>
        __bit_set_jvm_or(self, other)
            <% else %>
        self.ensure_capacity(other.words.length())
        let mut i: usize = 0
        while i < other.words.length() {
            let a: u64 = self.words.get(i).unwrap()
            let b: u64 = other.words.get(i).unwrap()
            self.words.set(i, a | b)
            i = i + 1
        }
        <% end match %>
    }

    micro difference(mut self, other: BitSet): unit {
        <% match arch %>
            <% case "clr" %>
        let self_length: usize = __bit_set_clr_length(self)
        let mut i: usize = 0
        while i < self_length {
            __bit_set_clr_set_value(self, i, self.get(i) && !other.get(i))
            i = i + 1
        }
            <% case "jvm" %>
        __bit_set_jvm_and_not(self, other)
            <% else %>
        let min_length: usize = if self.words.length() < other.words.length() { self.words.length() } else { other.words.length() }
        let mut i: usize = 0
        while i < min_length {
            let a: u64 = self.words.get(i).unwrap()
            let b: u64 = other.words.get(i).unwrap()
            self.words.set(i, a & ~b)
            i = i + 1
        }
        <% end match %>
    }

    micro xor(mut self, other: BitSet): unit {
        <% match arch %>
            <% case "clr" %>
        let self_length: usize = __bit_set_clr_length(self)
        let other_length: usize = __bit_set_clr_length(other)
        let max_length: usize = if self_length > other_length { self_length } else { other_length }
        if self_length < max_length {
            __bit_set_clr_set_length(self, max_length)
        }

        let mut i: usize = 0
        while i < max_length {
            __bit_set_clr_set_value(self, i, self.get(i) != other.get(i))
            i = i + 1
        }
            <% case "jvm" %>
        __bit_set_jvm_xor(self, other)
            <% else %>
        self.ensure_capacity(other.words.length())
        let min_length: usize = if self.words.length() < other.words.length() { self.words.length() } else { other.words.length() }
        let mut i: usize = 0
        while i < min_length {
            let a: u64 = self.words.get(i).unwrap()
            let b: u64 = other.words.get(i).unwrap()
            self.words.set(i, a ^ b)
            i = i + 1
        }
        while i < other.words.length() {
            self.words.set(i, other.words.get(i).unwrap())
            i = i + 1
        }
        <% end match %>
    }

    micro is_empty(self): bool {
        <% match arch %>
            <% case "clr" %>
        let length: usize = __bit_set_clr_length(self)
        let mut i: usize = 0
        while i < length {
            if __bit_set_clr_get(self, i) {
                return false
            }

            i = i + 1
        }

        return true
            <% case "jvm" %>
        return __bit_set_jvm_is_empty(self)
            <% else %>
        let mut i: usize = 0
        while i < self.words.length() {
            if self.words.get(i).unwrap() != 0u64 {
                return false
            }
            i = i + 1
        }
        return true
        <% end match %>
    }

    micro clear_all(mut self): unit {
        <% match arch %>
            <% case "clr" %>
        __bit_set_clr_set_all(self, false)
            <% case "jvm" %>
        __bit_set_jvm_clear_all(self)
            <% else %>
        let mut i: usize = 0
        while i < self.words.length() {
            self.words.set(i, 0u64)
            i = i + 1
        }
        <% end match %>
    }

    micro ensure_capacity(mut self, needed: usize): unit {
        <% match arch %>
            <% case "clr" %>
        if __bit_set_clr_length(self) < needed * 64 {
            __bit_set_clr_set_length(self, needed * 64)
        }
            <% case "jvm" %>
            <% else %>
        while self.words.length() < needed {
            self.words.push(0u64)
        }
        <% end match %>
    }
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








