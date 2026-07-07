namespace std.data.text.valkyrie;

# Source location span for Valkyrie text (language = Valkyrie, source suffix = `.v`).
# Indices are UTF-8 scalar / language-text offsets — not JVM/CLR UTF-16 code units.

structure TextSpan {
    start: usize
    stop: usize
}

micro new_text_span(start: usize, stop: usize) -> TextSpan {
    return TextSpan {
        start: start,
        stop: stop
    }
}

micro text_span_length(span: TextSpan) -> usize {
    if span.stop < span.start {
        return 0
    }
    return span.stop - span.start
}
