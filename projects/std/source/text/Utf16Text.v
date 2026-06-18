namespace std.text;

type utf16 = Utf16Text

⍝ UTF-16 编码的字符串
[clr("System.Runtime", "System.String")]
[jvm("java.lang.String")]
class Utf16Text {
    _repr: [u16]
}

imply Utf16Text {
    micro length(self) -> isize {
        <% match arch %>
            <% case "clr" %>
            return __utf16_clr_length(self)
            <% case "jvm" %>
            return __utf16_jvm_length(self)
            <% else %>
            return self._repr.length
        <% end match %>
    }

    micro is_empty(self) -> bool {
        if self.length() == 0 {
            return true
        }

        return false
    }

    micro sub_string(self, start: isize, count: isize) -> utf16 {
        <% match arch %>
            <% case "clr" %>
            return __utf16_clr_substring(self, start, count)
            <% case "jvm" %>
            return __utf16_jvm_substring(self, start, start + count)
            <% else %>
            return self
        <% end match %>
    }

    micro concat(self, other: utf16) -> utf16 {
        <% match arch %>
            <% case "clr" %>
            return __utf16_clr_concat(self, other)
            <% case "jvm" %>
            return __utf16_jvm_concat(self, other)
            <% else %>
            return self
        <% end match %>
    }

    micro contains(self, value: utf16) -> bool {
        <% match arch %>
            <% case "clr" %>
            return __utf16_clr_contains(self, value)
            <% case "jvm" %>
            return __utf16_jvm_contains(self, value)
            <% else %>
            return false
        <% end match %>
    }

    micro starts_with(self, prefix: utf16) -> bool {
        <% match arch %>
            <% case "clr" %>
            return __utf16_clr_starts_with(self, prefix)
            <% case "jvm" %>
            return __utf16_jvm_starts_with(self, prefix)
            <% else %>
            return false
        <% end match %>
    }

    micro ends_with(self, suffix: utf16) -> bool {
        <% match arch %>
            <% case "clr" %>
            return __utf16_clr_ends_with(self, suffix)
            <% case "jvm" %>
            return __utf16_jvm_ends_with(self, suffix)
            <% else %>
            return false
        <% end match %>
    }

    micro index_of(self, value: utf16) -> isize {
        <% match arch %>
            <% case "clr" %>
            return __utf16_clr_index_of(self, value)
            <% case "jvm" %>
            return __utf16_jvm_index_of(self, value)
            <% else %>
            return -1
        <% end match %>
    }

    micro trim(self) -> utf16 {
        <% match arch %>
            <% case "clr" %>
            return __utf16_clr_trim(self)
            <% case "jvm" %>
            return __utf16_jvm_trim(self)
            <% else %>
            return self
        <% end match %>
    }

    micro to_lower(self) -> utf16 {
        <% match arch %>
            <% case "clr" %>
            return __utf16_clr_to_lower(self)
            <% case "jvm" %>
            return __utf16_jvm_to_lower(self)
            <% else %>
            return self
        <% end match %>
    }

    micro to_upper(self) -> utf16 {
        <% match arch %>
            <% case "clr" %>
            return __utf16_clr_to_upper(self)
            <% case "jvm" %>
            return __utf16_jvm_to_upper(self)
            <% else %>
            return self
        <% end match %>
    }

    micro replace(self, old_value: utf16, new_value: utf16) -> utf16 {
        <% match arch %>
            <% case "clr" %>
            return __utf16_clr_replace(self, old_value, new_value)
            <% case "jvm" %>
            return __utf16_jvm_replace(self, old_value, new_value)
            <% else %>
            return self
        <% end match %>
    }

    micro equals(self, other: utf16) -> bool {
        <% match arch %>
            <% case "clr" %>
            return __utf16_clr_equals(self, other)
            <% case "jvm" %>
            return __utf16_jvm_equals(self, other)
            <% else %>
            return false
        <% end match %>
    }
}

⍝ 返回当前 UTF-16 文本的长度。
⍝ 在 CLR 下直接映射到 `System.String.Length` getter。
[clr("System.Runtime", "System.String", "get_Length"), pure]
private micro __utf16_clr_length(value: utf16): isize { }

⍝ 截取从 `start` 开始、长度为 `count` 的 UTF-16 子串。
⍝ 在 CLR 下直接映射到 `System.String.Substring(start, count)`。
[clr("System.Runtime", "System.String", "Substring"), pure]
private micro __utf16_clr_substring(value: utf16, start: isize, count: isize): utf16 { }

⍝ 拼接两个 UTF-16 文本。
⍝ 在 CLR 下直接映射到 `System.String.Concat(lhs, rhs)`。
[clr("System.Runtime", "System.String", "Concat"), pure]
private micro __utf16_clr_concat(lhs: utf16, rhs: utf16): utf16 { }

⍝ 判断当前 UTF-16 文本是否包含目标子串。
⍝ 在 CLR 下直接映射到 `System.String.Contains(value)`。
[clr("System.Runtime", "System.String", "Contains"), pure]
private micro __utf16_clr_contains(value: utf16, other: utf16): bool { }

⍝ 判断当前 UTF-16 文本是否以指定前缀开头。
⍝ 在 CLR 下直接映射到 `System.String.StartsWith(prefix)`。
[clr("System.Runtime", "System.String", "StartsWith"), pure]
private micro __utf16_clr_starts_with(value: utf16, prefix: utf16): bool { }

⍝ 判断当前 UTF-16 文本是否以指定后缀结尾。
⍝ 在 CLR 下直接映射到 `System.String.EndsWith(suffix)`。
[clr("System.Runtime", "System.String", "EndsWith"), pure]
private micro __utf16_clr_ends_with(value: utf16, suffix: utf16): bool { }

⍝ 返回目标子串在当前 UTF-16 文本中的起始位置。
⍝ 在 CLR 下直接映射到 `System.String.IndexOf(value)`。
[clr("System.Runtime", "System.String", "IndexOf"), pure]
private micro __utf16_clr_index_of(value: utf16, other: utf16): isize { }

⍝ 去除当前 UTF-16 文本首尾空白。
⍝ 在 CLR 下直接映射到 `System.String.Trim()`。
[clr("System.Runtime", "System.String", "Trim"), pure]
private micro __utf16_clr_trim(value: utf16): utf16 { }

⍝ 将当前 UTF-16 文本转换为小写。
⍝ 在 CLR 下直接映射到 `System.String.ToLower()`。
[clr("System.Runtime", "System.String", "ToLower"), pure]
private micro __utf16_clr_to_lower(value: utf16): utf16 { }

⍝ 将当前 UTF-16 文本转换为大写。
⍝ 在 CLR 下直接映射到 `System.String.ToUpper()`。
[clr("System.Runtime", "System.String", "ToUpper"), pure]
private micro __utf16_clr_to_upper(value: utf16): utf16 { }

⍝ 替换当前 UTF-16 文本中的指定子串。
⍝ 在 CLR 下直接映射到 `System.String.Replace(oldValue, newValue)`。
[clr("System.Runtime", "System.String", "Replace"), pure]
private micro __utf16_clr_replace(value: utf16, old_value: utf16, new_value: utf16): utf16 { }

⍝ 判断当前 UTF-16 文本是否与目标文本内容相等。
⍝ 在 CLR 下直接映射到 `System.String.Equals(value)`。
[clr("System.Runtime", "System.String", "Equals"), pure]
private micro __utf16_clr_equals(value: utf16, other: utf16): bool { }

⍝ 返回当前 UTF-16 文本的长度。
⍝ 在 JVM 下直接映射到 `java.lang.String.length()`。
[jvm("java.lang.String", "length"), pure]
private micro __utf16_jvm_length(value: utf16): isize { }

⍝ 截取从 `start` 到 `end` 之间的 UTF-16 子串。
⍝ 在 JVM 下直接映射到 `java.lang.String.substring(start, end)`。
[jvm("java.lang.String", "substring"), pure]
private micro __utf16_jvm_substring(value: utf16, start: isize, end: isize): utf16 { }

⍝ 拼接两个 UTF-16 文本。
⍝ 在 JVM 下直接映射到 `java.lang.String.concat(other)`。
[jvm("java.lang.String", "concat"), pure]
private micro __utf16_jvm_concat(value: utf16, other: utf16): utf16 { }

⍝ 判断当前 UTF-16 文本是否包含目标子串。
⍝ 在 JVM 下直接映射到 `java.lang.String.contains(value)`。
[jvm("java.lang.String", "contains"), pure]
private micro __utf16_jvm_contains(value: utf16, other: utf16): bool { }

⍝ 判断当前 UTF-16 文本是否以指定前缀开头。
⍝ 在 JVM 下直接映射到 `java.lang.String.startsWith(prefix)`。
[jvm("java.lang.String", "startsWith"), pure]
private micro __utf16_jvm_starts_with(value: utf16, prefix: utf16): bool { }

⍝ 判断当前 UTF-16 文本是否以指定后缀结尾。
⍝ 在 JVM 下直接映射到 `java.lang.String.endsWith(suffix)`。
[jvm("java.lang.String", "endsWith"), pure]
private micro __utf16_jvm_ends_with(value: utf16, suffix: utf16): bool { }

⍝ 返回目标子串在当前 UTF-16 文本中的起始位置。
⍝ 在 JVM 下直接映射到 `java.lang.String.indexOf(value)`。
[jvm("java.lang.String", "indexOf"), pure]
private micro __utf16_jvm_index_of(value: utf16, other: utf16): isize { }

⍝ 去除当前 UTF-16 文本首尾空白。
⍝ 在 JVM 下直接映射到 `java.lang.String.trim()`。
[jvm("java.lang.String", "trim"), pure]
private micro __utf16_jvm_trim(value: utf16): utf16 { }

⍝ 将当前 UTF-16 文本转换为小写。
⍝ 在 JVM 下直接映射到 `java.lang.String.toLowerCase()`。
[jvm("java.lang.String", "toLowerCase"), pure]
private micro __utf16_jvm_to_lower(value: utf16): utf16 { }

⍝ 将当前 UTF-16 文本转换为大写。
⍝ 在 JVM 下直接映射到 `java.lang.String.toUpperCase()`。
[jvm("java.lang.String", "toUpperCase"), pure]
private micro __utf16_jvm_to_upper(value: utf16): utf16 { }

⍝ 替换当前 UTF-16 文本中的指定子串。
⍝ 在 JVM 下直接映射到 `java.lang.String.replace(oldValue, newValue)`。
[jvm("java.lang.String", "replace"), pure]
private micro __utf16_jvm_replace(value: utf16, old_value: utf16, new_value: utf16): utf16 { }

⍝ 判断当前 UTF-16 文本是否与目标文本内容相等。
⍝ 在 JVM 下直接映射到 `java.lang.String.equals(value)`。
[jvm("java.lang.String", "equals"), pure]
private micro __utf16_jvm_equals(value: utf16, other: utf16): bool { }
