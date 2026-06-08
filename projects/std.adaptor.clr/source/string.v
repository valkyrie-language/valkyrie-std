namespace std.adaptor.clr.string;

# 字符串 API

[clr("System.String", "Format"), pure]
micro string_format(template: utf8, arg0: utf8): utf8

[clr("System.String", "Concat"), pure]
micro string_concat(a: utf8, b: utf8): utf8

[clr("System.String", "Substring"), pure]
micro string_substring(s: utf8, start: i32, len: i32): utf8

[clr("System.String", "IndexOf"), pure]
micro string_index_of(s: utf8, value: utf8): i32

[clr("System.String", "Replace"), pure]
micro string_replace(s: utf8, old_value: utf8, new_value: utf8): utf8

[clr("System.String", "ToUpper"), pure]
micro string_to_upper(s: utf8): utf8

[clr("System.String", "ToLower"), pure]
micro string_to_lower(s: utf8): utf8

[clr("System.String", "Split"), pure]
micro string_split(s: utf8, separator: utf8): i32

[clr("System.String", "Trim"), pure]
micro string_trim(s: utf8): utf8

[clr("System.String", "get_Length"), pure]
micro string_length(s: utf8): i32
