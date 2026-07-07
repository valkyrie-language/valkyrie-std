namespace std.data.text.msil;

# Render typed MSIL → ILASM text (subset). Full opcode table grows with CLR lane.
# Call/newobj/ldfld operands must carry full type names (no short-name rewrite here).

micro render_digit(d: i64) -> utf8 {
    if d == 0 { return "0" }
    if d == 1 { return "1" }
    if d == 2 { return "2" }
    if d == 3 { return "3" }
    if d == 4 { return "4" }
    if d == 5 { return "5" }
    if d == 6 { return "6" }
    if d == 7 { return "7" }
    if d == 8 { return "8" }
    if d == 9 { return "9" }
    return "0"
}

micro render_i64_text(value: i64) -> utf8 {
    if value == 0 {
        return "0"
    }
    let mut n: i64 = value
    let mut neg: bool = false
    if n < 0 {
        neg = true
        n = 0 - n
    }
    let mut out: utf8 = ""
    while n > 0 {
        let d: i64 = n % 10
        out = render_digit(d) + out
        n = n / 10
    }
    if neg {
        out = "-" + out
    }
    return out
}

micro render_msil_type(ty: MsilType) -> utf8 {
    match ty {
        case Void: {
            return "void"
        }
        case Bool: {
            return "bool"
        }
        case Char: {
            return "char"
        }
        case Int8 { signed }: {
            if signed {
                return "int8"
            }
            return "uint8"
        }
        case Int16 { signed }: {
            if signed {
                return "int16"
            }
            return "uint16"
        }
        case Int32 { signed }: {
            if signed {
                return "int32"
            }
            return "uint32"
        }
        case Int64 { signed }: {
            if signed {
                return "int64"
            }
            return "uint64"
        }
        case Float32: {
            return "float32"
        }
        case Float64: {
            return "float64"
        }
        case String: {
            return "string"
        }
        case Object: {
            return "object"
        }
        case IntPtr { signed }: {
            if signed {
                return "native int"
            }
            return "native unsigned int"
        }
        case SzArrayNamed { element_name }: {
            return element_name + "[]"
        }
        case Named { name }: {
            return name
        }
    }
}

micro render_msil_opcode(op: MsilOpcode) -> utf8 {
    match op {
        case Nop: { return "nop" }
        case Break: { return "break" }
        case Ret: { return "ret" }
        case Pop: { return "pop" }
        case Dup: { return "dup" }
        case Ldnull: { return "ldnull" }
        case Ldarg0: { return "ldarg.0" }
        case Ldarg1: { return "ldarg.1" }
        case Ldarg2: { return "ldarg.2" }
        case Ldarg3: { return "ldarg.3" }
        case Ldarg: { return "ldarg" }
        case Ldloc0: { return "ldloc.0" }
        case Ldloc1: { return "ldloc.1" }
        case Ldloc2: { return "ldloc.2" }
        case Ldloc3: { return "ldloc.3" }
        case Ldloc: { return "ldloc" }
        case Stloc0: { return "stloc.0" }
        case Stloc1: { return "stloc.1" }
        case Stloc2: { return "stloc.2" }
        case Stloc3: { return "stloc.3" }
        case Stloc: { return "stloc" }
        case LdcI4M1: { return "ldc.i4.m1" }
        case LdcI4_0: { return "ldc.i4.0" }
        case LdcI4_1: { return "ldc.i4.1" }
        case LdcI4_2: { return "ldc.i4.2" }
        case LdcI4_3: { return "ldc.i4.3" }
        case LdcI4_4: { return "ldc.i4.4" }
        case LdcI4_5: { return "ldc.i4.5" }
        case LdcI4_6: { return "ldc.i4.6" }
        case LdcI4_7: { return "ldc.i4.7" }
        case LdcI4_8: { return "ldc.i4.8" }
        case LdcI4: { return "ldc.i4" }
        case LdcI8: { return "ldc.i8" }
        case Ldstr: { return "ldstr" }
        case Call: { return "call" }
        case Callvirt: { return "callvirt" }
        case Newobj: { return "newobj" }
        case Initobj: { return "initobj" }
        case Ldfld: { return "ldfld" }
        case Stfld: { return "stfld" }
        case Ldsfld: { return "ldsfld" }
        case Stsfld: { return "stsfld" }
        case Br: { return "br" }
        case Brfalse: { return "brfalse" }
        case Brtrue: { return "brtrue" }
        case Beq: { return "beq" }
        case BneUn: { return "bne.un" }
        case Add: { return "add" }
        case Sub: { return "sub" }
        case Mul: { return "mul" }
        case Div: { return "div" }
        case Rem: { return "rem" }
        case Neg: { return "neg" }
        case Not: { return "not" }
        case And: { return "and" }
        case Or: { return "or" }
        case Xor: { return "xor" }
        case Ceq: { return "ceq" }
        case Clt: { return "clt" }
        case Cgt: { return "cgt" }
        case ConvI4: { return "conv.i4" }
        case ConvI8: { return "conv.i8" }
        case Ldlen: { return "ldlen" }
        case Newarr: { return "newarr" }
        case Box: { return "box" }
        case UnboxAny: { return "unbox.any" }
        case Castclass: { return "castclass" }
        case Isinst: { return "isinst" }
        case LdelemRef: { return "ldelem.ref" }
        case StelemRef: { return "stelem.ref" }
        case LdelemI4: { return "ldelem.i4" }
        case StelemI4: { return "stelem.i4" }
        else: {
            return "nop"
        }
    }
}

micro render_typed_instruction(ins: TypedMsilInstruction) -> utf8 {
    let mut line: utf8 = ""
    if ins.label.length() > 0 {
        line = line + ins.label
        line = line + ":\n"
    }
    line = line + "        "
    line = line + render_msil_opcode(ins.opcode)
    match ins.operand {
        case None: {
        }
        case StringLiteral { utf8_source }: {
            line = line + " "
            line = line + render_msil_ldstr_from_utf8_source(utf8_source)
        }
        case BranchTarget { label }: {
            line = line + " "
            line = line + label
        }
        case Symbol { value }: {
            line = line + " "
            line = line + value
        }
        case TypeName { value }: {
            line = line + " "
            line = line + value
        }
        case Field { owner, name }: {
            line = line + " "
            line = line + owner
            line = line + "::"
            line = line + name
        }
        case Method { value }: {
            line = line + " "
            line = line + render_msil_type(value.signature.return_type)
            line = line + " "
            if value.owner.length() > 0 {
                line = line + value.owner
                line = line + "::"
            }
            line = line + value.name
        }
        case Raw { value }: {
            line = line + " "
            line = line + value
        }
        case Integer { value }: {
            line = line + " "
            line = line + render_i64_text(value)
        }
        case FloatText { value }: {
            line = line + " "
            line = line + value
        }
        case Token { value }: {
            line = line + " "
            line = line + render_i64_text(value as i64)
        }
    }
    return line
}

micro render_typed_locals(locals: [MsilType]) -> utf8 {
    if locals.length() == 0 {
        return ""
    }
    let mut out: utf8 = "    .locals init ("
    let mut i: usize = 0
    while i < locals.length() {
        if i > 0 {
            out = out + ", "
        }
        out = out + "["
        out = out + render_i64_text(i as i64)
        out = out + "] "
        out = out + render_msil_type(locals⁅i⁆)
        i = i + 1
    }
    out = out + ")\n"
    return out
}

micro render_typed_method_body(body: TypedMsilMethodBody) -> utf8 {
    let mut out: utf8 = render_typed_locals(body.locals)
    let mut i: usize = 0
    while i < body.instructions.length() {
        out = out + render_typed_instruction(body.instructions⁅i⁆)
        out = out + "\n"
        i = i + 1
    }
    return out
}
