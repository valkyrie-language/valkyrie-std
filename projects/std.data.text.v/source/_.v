namespace std.data.text.v;

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
