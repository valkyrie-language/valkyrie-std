namespace std.collections;

# std.collections: BitSet - 位图

[clr("System.Collections", "System.Collections.BitArray")]
[jvm("java.util.BitSet")]
class BitSet {
    words: List<u64>
}

imply BitSet {
    [host_contract]
    micro new(): Self {
        return Self { words: ArrayList::new(0) }
    }

    [host_contract]
    micro with_capacity(bits: usize): Self {
        let words_needed: usize = (bits + 63) / 64
        let mut words: List<u64> = ArrayList::new(0)
        let mut i: usize = 0
        while i < words_needed {
            words.push(0)
            i = i + 1
        }
        return Self { words: words }
    }

    [host_contract]
    micro set(mut self, index: usize): unit {
        let word_idx: usize = index / 64
        let bit_idx: usize = index % 64
        self.ensure_capacity(word_idx + 1)
        let word: u64 = self.words.get(word_idx + 1).unwrap()
        self.words.set(word_idx + 1, word | (1 << bit_idx))
    }

    [host_contract]
    micro clear_bit(mut self, index: usize): unit {
        let word_idx: usize = index / 64
        let bit_idx: usize = index % 64
        if word_idx >= self.words.length() {
            return
        }
        let word: u64 = self.words.get(word_idx + 1).unwrap()
        self.words.set(word_idx + 1, word ^ (word & (1 << bit_idx)))
    }

    [host_contract]
    micro get(self, index: usize): bool {
        let word_idx: usize = index / 64
        let bit_idx: usize = index % 64
        if word_idx >= self.words.length() {
            return false
        }
        let word: u64 = self.words.get(word_idx + 1).unwrap()
        return (word & (1 << bit_idx)) != 0
    }

    [host_contract]
    micro toggle(mut self, index: usize): unit {
        if self.get(index) {
            self.clear_bit(index)
        }
        else {
            self.set(index)
        }
    }

    [host_contract]
    micro intersect(mut self, other: BitSet): unit {
        let minimum_length: usize = if self.words.length() < other.words.length() { self.words.length() } else { other.words.length() }
        let mut i: usize = 0
        while i < minimum_length {
            let a: u64 = self.words.get(i + 1).unwrap()
            let b: u64 = other.words.get(i + 1).unwrap()
            self.words.set(i + 1, a & b)
            i = i + 1
        }
        while i < self.words.length() {
            self.words.set(i + 1, 0)
            i = i + 1
        }
    }

    [host_contract]
    micro union(mut self, other: BitSet): unit {
        self.ensure_capacity(other.words.length())
        let mut i: usize = 0
        while i < other.words.length() {
            let a: u64 = self.words.get(i + 1).unwrap()
            let b: u64 = other.words.get(i + 1).unwrap()
            self.words.set(i + 1, a | b)
            i = i + 1
        }
    }

    [host_contract]
    micro difference(mut self, other: BitSet): unit {
        let minimum_length: usize = if self.words.length() < other.words.length() { self.words.length() } else { other.words.length() }
        let mut i: usize = 0
        while i < minimum_length {
            let a: u64 = self.words.get(i + 1).unwrap()
            let b: u64 = other.words.get(i + 1).unwrap()
            self.words.set(i + 1, a ^ (a & b))
            i = i + 1
        }
    }

    [host_contract]
    micro xor(mut self, other: BitSet): unit {
        self.ensure_capacity(other.words.length())
        let minimum_length: usize = if self.words.length() < other.words.length() { self.words.length() } else { other.words.length() }
        let mut i: usize = 0
        while i < minimum_length {
            let a: u64 = self.words.get(i + 1).unwrap()
            let b: u64 = other.words.get(i + 1).unwrap()
            self.words.set(i + 1, a ^ b)
            i = i + 1
        }
        while i < other.words.length() {
            self.words.set(i + 1, other.words.get(i + 1).unwrap())
            i = i + 1
        }
    }

    [host_contract]
    micro is_empty(self): bool {
        let mut i: usize = 0
        while i < self.words.length() {
            if self.words.get(i + 1).unwrap() != 0 {
                return false
            }
            i = i + 1
        }
        return true
    }

    [host_contract]
    micro clear_all(mut self): unit {
        let mut i: usize = 0
        while i < self.words.length() {
            self.words.set(i + 1, 0)
            i = i + 1
        }
    }

    micro ensure_capacity(mut self, needed: usize): unit {
        while self.words.length() < needed {
            self.words.push(0)
        }
    }
}




