# WebSocket frame codec tests

using atlas.ws;

[test]
micro `enframe text tiny payload`() {
    let enframer: WebSocketEnframer = WebSocketEnframer::text()
    let framed: [i32] = enframer.enframe_text("hi")
    if framed.length != 4 {
        panic("frame length")
    }
    if framed[0] != 0x81 {
        panic("opcode should be text fin")
    }
    if framed[1] != 2 {
        panic("payload length")
    }
    if framed[2] != 104 {
        panic("h")
    }
    if framed[3] != 105 {
        panic("i")
    }
}

[test]
micro `deframe text round trip`() {
    let enframer: WebSocketEnframer = WebSocketEnframer::text()
    let framed: [i32] = enframer.enframe_text("hello")
    let mut deframer: WebSocketDeframer = WebSocketDeframer::server()
    deframer.feed(framed)
    if deframer.try_get_next_frame() == false {
        panic("expected frame")
    }
    if deframer.current_opcode != opcode_text() {
        panic("opcode text")
    }
    if deframer.current_text().equals("hello") == false {
        panic("payload text")
    }
}

[test]
micro `deframe masked client frame`() {
    let mut data: [i32] = []
    push(data, 0x81)
    push(data, 0x82)
    push(data, 0x01)
    push(data, 0x02)
    push(data, 0x03)
    push(data, 0x04)
    push(data, 105)
    push(data, 107)
    let mut deframer: WebSocketDeframer = WebSocketDeframer::server()
    deframer.feed(data)
    if deframer.try_get_next_frame() == false {
        panic("expected masked frame")
    }
    if deframer.current_text().equals("hi") == false {
        panic("unmask")
    }
}
