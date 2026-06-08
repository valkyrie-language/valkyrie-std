# 字符串 API

[jvm("java.lang.String", "format"), pure]
micro jvm_string_format(template: utf8, arg0: utf8): utf8

[jvm("java.lang.String", "concat"), pure]
micro jvm_string_concat(a: utf8, b: utf8): utf8

[jvm("java.lang.String", "substring"), pure]
micro jvm_string_substring(s: utf8, begin: i32, end: i32): utf8

[jvm("java.lang.String", "indexOf"), pure]
micro jvm_string_index_of(s: utf8, value: utf8): i32

[jvm("java.lang.String", "replace"), pure]
micro jvm_string_replace(s: utf8, old_value: utf8, new_value: utf8): utf8

[jvm("java.lang.String", "toUpperCase"), pure]
micro jvm_string_to_upper(s: utf8): utf8

[jvm("java.lang.String", "toLowerCase"), pure]
micro jvm_string_to_lower(s: utf8): utf8

[jvm("java.lang.String", "split"), pure]
micro jvm_string_split(s: utf8, regex: utf8): i32

[jvm("java.lang.String", "trim"), pure]
micro jvm_string_trim(s: utf8): utf8

[jvm("java.lang.String", "length"), pure]
micro jvm_string_length(s: utf8): i32
