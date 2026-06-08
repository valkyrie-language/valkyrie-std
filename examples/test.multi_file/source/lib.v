namespace multi_file::lib;

class LibType { value: i32 }

micro helper(t: LibType) -> i32 {
    return t.value + 1
}