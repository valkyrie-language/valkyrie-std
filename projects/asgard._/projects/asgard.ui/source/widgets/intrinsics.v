# PascalCase 原生 widget intrinsic（Column / Text / Button）

namespace asgard.ui.widgets;

micro tag_column(): utf8 {
    return "Column"
}

micro tag_text(): utf8 {
    return "Text"
}

micro tag_button(): utf8 {
    return "Button"
}

micro is_intrinsic(tag: utf8): bool {
    return tag == tag_column() || tag == tag_text() || tag == tag_button()
}
