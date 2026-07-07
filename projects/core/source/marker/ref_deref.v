namespace marker;

# Class / reference payload identity: MIR inserts `__ref_deref` before FieldGet on `class`.
# Same pattern as `__array_len` — empty body + `[intrinsic]`, backends expand via opcode.
[intrinsic("ref.deref")]
private micro __ref_deref<T>(self: T): T { }
