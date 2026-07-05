# WebSocket RFC 6455 帧编解码（服务端视角）

namespace atlas.ws;

using std.text;

micro opcode_continuation(): i32 { return 0 }
micro opcode_text(): i32 { return 1 }
micro opcode_binary(): i32 { return 2 }
micro opcode_close(): i32 { return 8 }
micro opcode_ping(): i32 { return 9 }
micro opcode_pong(): i32 { return 10 }

micro close_normal(): i32 { return 1000 }
micro close_going_away(): i32 { return 1001 }
micro close_protocol_error(): i32 { return 1002 }

class WebSocketEnframer {
    is_text: bool
}

class WebSocketDeframer {
    is_server: bool
    buffer: [i32]
    count: i32
    current_opcode: i32
    current_frame: [i32]
    has_frame: bool
}

imply WebSocketEnframer {
    micro text(): Self {
        return Self { is_text: true }
    }

    micro binary(): Self {
        return Self { is_text: false }
    }

    micro enframe(self, payload: [i32]): [i32] {
        let opcode: i32 = frame_fin_opcode(self.is_text)
        return enframe_with_opcode(payload, opcode)
    }

    micro enframe_text(self, message: utf8): [i32] {
        return enframe_with_opcode(utf8_to_bytes(message), frame_fin_opcode(true))
    }

    micro enframe_close(self, status: i32): [i32] {
        let mut payload: [i32] = []
        push(payload, (status >> 8) & 255)
        push(payload, status & 255)
        return enframe_with_opcode(payload, 0x88)
    }

    micro enframe_pong(self, payload: [i32]): [i32] {
        return enframe_with_opcode(payload, 0x8A)
    }
}

imply WebSocketDeframer {
    micro server(): Self {
        return Self {
            is_server: true,
            buffer: [],
            count: 0,
            current_opcode: 0,
            current_frame: [],
            has_frame: false
        }
    }

    micro feed(mut self, data: [i32]): unit {
        let mut i: i32 = 0
        while i < data.length {
            push(self.buffer, data[i])
            i = i + 1
        }
        self.count = self.buffer.length
    }

    micro feed_utf8(mut self, data: utf8): unit {
        self.feed(utf8_to_bytes(data))
    }

    micro try_get_next_frame(mut self): bool {
        if self.count < 2 {
            self.has_frame = false
            return false
        }

        let first_byte: i32 = self.buffer[0]
        let second_byte: i32 = self.buffer[1]
        let opcode: i32 = first_byte & 15
        let is_masked: bool = (second_byte & 128) != 0
        let mut payload_length: i32 = second_byte & 127
        let mut header_size: i32 = 2

        if payload_length == 126 {
            if self.count < 4 {
                self.has_frame = false
                return false
            }
            payload_length = (self.buffer[2] << 8) | self.buffer[3]
            header_size = 4
        } else if payload_length == 127 {
            if self.count < 10 {
                self.has_frame = false
                return false
            }
            payload_length = (self.buffer[6] << 24) | (self.buffer[7] << 16) | (self.buffer[8] << 8) | self.buffer[9]
            header_size = 10
        }

        let mut mask_size: i32 = 0
        if is_masked {
            mask_size = 4
        }
        let total_length: i32 = header_size + mask_size + payload_length
        if self.count < total_length {
            self.has_frame = false
            return false
        }

        let data_offset: i32 = header_size + mask_size
        let mut frame: [i32] = []
        let mut i: i32 = 0
        while i < payload_length {
            let mut b: i32 = self.buffer[data_offset + i]
            if is_masked && self.is_server {
                let mask_byte: i32 = self.buffer[header_size + (i % 4)]
                b = b ^ mask_byte
            }
            push(frame, b)
            i = i + 1
        }

        let remaining: i32 = self.count - total_length
        let mut next_buffer: [i32] = []
        let mut r: i32 = 0
        while r < remaining {
            push(next_buffer, self.buffer[total_length + r])
            r = r + 1
        }

        self.buffer = next_buffer
        self.count = remaining
        self.current_opcode = opcode
        self.current_frame = frame
        self.has_frame = true
        return true
    }

    micro current_text(self): utf8 {
        return bytes_to_utf8(self.current_frame)
    }

    micro reset(mut self): unit {
        self.buffer = []
        self.count = 0
        self.current_opcode = 0
        self.current_frame = []
        self.has_frame = false
    }
}

micro frame_fin_opcode(is_text: bool): i32 {
    if is_text {
        return 0x81
    }
    return 0x82
}

micro enframe_with_opcode(payload: [i32], opcode: i32): [i32] {
    let mut out: [i32] = []
    push(out, opcode)
    let payload_length: i32 = payload.length
    if payload_length <= 125 {
        push(out, payload_length)
    } else if payload_length <= 65535 {
        push(out, 126)
        push(out, (payload_length >> 8) & 255)
        push(out, payload_length & 255)
    } else {
        push(out, 127)
        push(out, 0)
        push(out, 0)
        push(out, 0)
        push(out, 0)
        push(out, (payload_length >> 24) & 255)
        push(out, (payload_length >> 16) & 255)
        push(out, (payload_length >> 8) & 255)
        push(out, payload_length & 255)
    }
    let mut i: i32 = 0
    while i < payload_length {
        push(out, payload[i])
        i = i + 1
    }
    return out
}

micro utf8_to_bytes(text: utf8): [i32] {
    let mut out: [i32] = []
    let n: i32 = text.byte_length()
    let mut i: i32 = 0
    while i < n {
        push(out, i32(text._repr[i]))
        i = i + 1
    }
    return out
}

micro bytes_to_utf8(bytes: [i32]): utf8 {
    let mut out: [u8] = []
    let mut i: i32 = 0
    while i < bytes.length {
        push(out, u8(bytes[i]))
        i = i + 1
    }
    return Utf8Text::from_bytes(out)
}

micro bytes_equal(left: [i32], right: [i32]): bool {
    if left.length != right.length {
        return false
    }
    let mut i: i32 = 0
    while i < left.length {
        if left[i] != right[i] {
            return false
        }
        i = i + 1
    }
    return true
}
