#!/usr/bin/env node
/**
 * 反汇编 wasm 模块的指定函数,定位类型错误的根因。
 *
 * 用法: node scripts/_disasm_func.mjs <wasm-path> <func-index> [byte-offset]
 */
import fs from 'fs';
import path from 'path';

const args = process.argv.slice(2);
if (args.length < 2) {
    console.error('用法: node _disasm_func.mjs <wasm-path> <func-index> [byte-offset]');
    process.exit(1);
}

const wasmPath = path.resolve(args[0]);
const targetFuncIndex = parseInt(args[1], 10);
const targetOffset = args.length >= 3 ? parseInt(args[2], 10) : -1;

const bytes = fs.readFileSync(wasmPath);

// --- LEB128 readers ---
function readUleb(buf, off) {
    let result = 0, shift = 0, cursor = off;
    for (;;) {
        const b = buf[cursor++];
        result |= (b & 0x7F) << shift;
        if ((b & 0x80) === 0) break;
        shift += 7;
    }
    return { value: result >>> 0, next: cursor };
}
function readSleb32(buf, off) {
    let result = 0, shift = 0, cursor = off;
    for (;;) {
        const b = buf[cursor++];
        result |= (b & 0x7F) << shift;
        shift += 7;
        if ((b & 0x80) === 0) {
            if (shift < 32 && (b & 0x40) !== 0) {
                result |= (-1 << shift);
            }
            break;
        }
    }
    return { value: result | 0, next: cursor };
}

// --- 解析 wasm section ---
let cursor = 8; // skip magic + version
const sections = {};
while (cursor < bytes.length) {
    const sectionId = bytes[cursor++];
    const lenRead = readUleb(bytes, cursor);
    cursor = lenRead.next;
    const payloadStart = cursor;
    const payloadEnd = cursor + lenRead.value;
    sections[sectionId] = { start: payloadStart, end: payloadEnd, bytes: bytes.slice(payloadStart, payloadEnd) };
    cursor = payloadEnd;
}

// --- 解析 type section (id=1) ---
const typeSec = sections[1];
const types = [];
if (typeSec) {
    let off = typeSec.start;
    const countRead = readUleb(bytes, off);
    off = countRead.next;
    const count = countRead.value;
    for (let i = 0; i < count; i++) {
        const form = bytes[off++];
        if (form === 0x60) {
            // functype
            const paramCountRead = readUleb(bytes, off);
            off = paramCountRead.next;
            const params = [];
            for (let j = 0; j < paramCountRead.value; j++) params.push(bytes[off++]);
            const resultCountRead = readUleb(bytes, off);
            off = resultCountRead.next;
            const results = [];
            for (let j = 0; j < resultCountRead.value; j++) results.push(bytes[off++]);
            types.push({ kind: 'func', params, results });
        } else if (form === 0x5F) {
            // structtype
            const fieldCountRead = readUleb(bytes, off);
            off = fieldCountRead.next;
            const fields = [];
            for (let j = 0; j < fieldCountRead.value; j++) {
                const vt = bytes[off++];
                const mut = bytes[off++];
                fields.push({ vt, mut });
            }
            types.push({ kind: 'struct', fields });
        } else if (form === 0x5E) {
            // arraytype
            const vt = bytes[off++];
            const mut = bytes[off++];
            types.push({ kind: 'array', vt, mut });
        } else {
            console.error(`未知 type form: 0x${form.toString(16)} (type #${i}), 停止解析 type section`);
            break;
        }
    }
}

// --- 解析 import section (id=2) 计算 function imports 数量 ---
const importSec = sections[2];
let functionImportCount = 0;
const importNames = [];
if (importSec) {
    let off = importSec.start;
    const countRead = readUleb(bytes, off);
    off = countRead.next;
    for (let i = 0; i < countRead.value; i++) {
        const modLenRead = readUleb(bytes, off);
        off = modLenRead.next;
        const modName = bytes.slice(off, off + modLenRead.value).toString('utf8');
        off += modLenRead.value;
        const fieldLenRead = readUleb(bytes, off);
        off = fieldLenRead.next;
        const fieldName = bytes.slice(off, off + fieldLenRead.value).toString('utf8');
        off += fieldLenRead.value;
        const kind = bytes[off++];
        const typeIdxRead = readUleb(bytes, off);
        off = typeIdxRead.next;
        if (kind === 0) {
            importNames.push(`${modName}.${fieldName} (type ${typeIdxRead.value})`);
            functionImportCount++;
        } else if (kind === 1) {
            // table
        } else if (kind === 2) {
            // memory
        } else if (kind === 3) {
            // global
        }
    }
}

console.log(`函数 imports: ${functionImportCount}`);
console.log(`types: ${types.length}`);

// --- 解析 function section (id=3) 获取每个本地函数的 type index ---
const funcSec = sections[3];
const funcTypeIndices = [];
if (funcSec) {
    let off = funcSec.start;
    const countRead = readUleb(bytes, off);
    off = countRead.next;
    for (let i = 0; i < countRead.value; i++) {
        const idxRead = readUleb(bytes, off);
        off = idxRead.next;
        funcTypeIndices.push(idxRead.value);
    }
}

// --- 解析 code section (id=10) ---
const codeSec = sections[10];
if (!codeSec) {
    console.error('无 code section');
    process.exit(1);
}

const funcBodies = [];
let off = codeSec.start;
const bodyCountRead = readUleb(bytes, off);
off = bodyCountRead.next;
for (let i = 0; i < bodyCountRead.value; i++) {
    const bodySizeRead = readUleb(bytes, off);
    off = bodySizeRead.next;
    const bodyStart = off;
    const bodyEnd = off + bodySizeRead.value;
    // 解析 local decls
    const localDeclCountRead = readUleb(bytes, off);
    off = localDeclCountRead.next;
    const localDecls = [];
    for (let j = 0; j < localDeclCountRead.value; j++) {
        const cntRead = readUleb(bytes, off);
        off = cntRead.next;
        const ty = bytes[off++];
        localDecls.push({ count: cntRead.value, type: ty });
    }
    const codeStart = off;
    funcBodies.push({
        bodyStart,
        bodyEnd,
        localDecls,
        codeStart,
        codeBytes: bytes.slice(codeStart, bodyEnd),
    });
    off = bodyEnd;
}

console.log(`code bodies: ${funcBodies.length}`);

// 定位目标函数
if (targetFuncIndex < functionImportCount) {
    console.log(`\n函数 #${targetFuncIndex} 是 import: ${importNames[targetFuncIndex]}`);
    process.exit(0);
}

const localFuncIdx = targetFuncIndex - functionImportCount;
if (localFuncIdx >= funcBodies.length) {
    console.error(`函数 #${targetFuncIndex} 超出范围 (本地函数数=${funcBodies.length})`);
    process.exit(1);
}

const body = funcBodies[localFuncIdx];
const typeIdx = funcTypeIndices[localFuncIdx];
const fnType = types[typeIdx];

console.log(`\n=== 函数 #${targetFuncIndex} (local #${localFuncIdx}, type #${typeIdx}) ===`);
if (!fnType) {
    console.error(`type #${typeIdx} 不存在 (types 总数=${types.length})`);
    process.exit(1);
}
if (fnType.kind !== 'func') {
    console.error(`type #${typeIdx} 不是 functype (${fnType.kind})`);
    process.exit(1);
}
console.log(`参数类型: ${fnType.params.map(b => '0x' + b.toString(16)).join(', ')}`);
console.log(`返回类型: ${fnType.results.map(b => '0x' + b.toString(16)).join(', ')}`);

// 构造 local 类型表（local 0 开始是参数）
const localTypes = [];
for (const p of fnType.params) localTypes.push({ kind: 'param', type: p });
for (const decl of body.localDecls) {
    for (let i = 0; i < decl.count; i++) {
        localTypes.push({ kind: 'local', type: decl.type });
    }
}
console.log(`locals (${localTypes.length}):`);
for (let i = 0; i < localTypes.length; i++) {
    const lt = localTypes[i];
    const typeName = lt.type === 0x7F ? 'i32' : lt.type === 0x7E ? 'i64' : lt.type === 0x6E ? 'anyref' : lt.type === 0x6F ? 'externref' : '0x' + lt.type.toString(16);
    console.log(`  local[${i}] = ${typeName} (${lt.kind})`);
}

// 简单反汇编
const code = body.codeBytes;
console.log(`\n反汇编 (code 起始偏移 ${body.codeStart}, 长度 ${code.length}):`);

function decodeInstr(buf, off) {
    const startOff = off;
    const op = buf[off++];
    let mnemonic = '';
    let detail = '';

    // 基本单字节指令
    const singleByte = {
        0x00: 'unreachable', 0x01: 'nop', 0x02: 'block', 0x03: 'loop', 0x04: 'if', 0x05: 'else',
        0x0B: 'end', 0x0C: 'br', 0x0D: 'br_if', 0x0E: 'br_table', 0x0F: 'return',
        0x10: 'call', 0x11: 'call_indirect', 0x1A: 'drop', 0x1B: 'select',
        0x20: 'local.get', 0x21: 'local.set', 0x22: 'local.tee', 0x23: 'global.get', 0x24: 'global.set',
        0x28: 'i32.load', 0x29: 'i64.load', 0x2A: 'f32.load', 0x2B: 'f64.load',
        0x36: 'i32.store', 0x37: 'i64.store', 0x38: 'f32.store', 0x39: 'f64.store',
        0x41: 'i32.const', 0x42: 'i64.const', 0x43: 'f32.const', 0x44: 'f64.const',
        0x45: 'i32.eqz', 0x46: 'i32.eq', 0x47: 'i32.ne', 0x48: 'i32.lt_s', 0x49: 'i32.lt_u',
        0x4A: 'i32.gt_s', 0x4B: 'i32.gt_u', 0x4C: 'i32.le_s', 0x4D: 'i32.le_u',
        0x4E: 'i32.ge_s', 0x4F: 'i32.ge_u', 0x6A: 'i32.add', 0x6B: 'i32.sub', 0x6C: 'i32.mul',
        0x6D: 'i32.div_s', 0x71: 'i32.and', 0x72: 'i32.or', 0x73: 'i32.xor',
        0x6F: 'i32.shl', 0x70: 'i32.shr_s', 0x74: 'i32.shr_u',
        0x3F: 'memory.size', 0x40: 'memory.grow',
        0xD0: 'ref.null', 0xD1: 'ref.is_null', 0xD2: 'ref.func',
    };

    if (op === 0xFC) {
        // misc 前缀
        const subRead = readUleb(buf, off);
        off = subRead.next;
        const miscNames = { 0x0A: 'memory.copy', 0x0B: 'memory.fill' };
        mnemonic = miscNames[subRead.value] || `misc#${subRead.value}`;
        return { mnemonic, detail, startOff, endOff: off };
    }

    if (op === 0xFB) {
        // GC 前缀
        const subRead = readUleb(buf, off);
        off = subRead.next;
        const gcNames = {
            0x01: 'struct.new_default', 0x02: 'struct.new',
            0x03: 'struct.get', 0x04: 'struct.get_s', 0x05: 'struct.get_u',
            0x06: 'struct.set',
            0x0E: 'array.new_default', 0x0C: 'array.new_fixed',
            0x10: 'array.get', 0x11: 'array.get_s', 0x12: 'array.get_u',
            0x13: 'array.set', 0x0F: 'array.len',
            0x1C: 'ref.cast', 0x1D: 'ref.cast_nullable',
            0x18: 'ref.test', 0x19: 'ref.test_nullable',
        };
        mnemonic = gcNames[subRead.value] || `gc#${subRead.value}`;
        // struct/array 指令额外读 type index
        if ([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x0E, 0x0C, 0x10, 0x11, 0x12, 0x13].includes(subRead.value)) {
            const tRead = readUleb(buf, off);
            off = tRead.next;
            detail = `type=${tRead.value}`;
            // struct.get/set/array.get/array.set 还需 field/idx
            if ([0x03, 0x04, 0x05, 0x06].includes(subRead.value)) {
                const fRead = readUleb(buf, off);
                off = fRead.next;
                detail += ` field=${fRead.value}`;
            }
        } else if ([0x1C, 0x1D, 0x18, 0x19].includes(subRead.value)) {
            // ref.cast 读 heap type (s33)
            const hRead = readSleb32(buf, off);
            off = hRead.next;
            detail = `heap=${hRead.value}`;
        }
        return { mnemonic, detail, startOff, endOff: off };
    }

    mnemonic = singleByte[op] || `unknown(0x${op.toString(16)})`;

    // 操作数
    if (op === 0x02 || op === 0x03 || op === 0x04) {
        // block/loop/if 读 blocktype
        const bt = buf[off++];
        detail = `blocktype=0x${bt.toString(16)}`;
    } else if (op === 0x0C || op === 0x0D || op === 0x0E || op === 0x10 || op === 0x11 || op === 0x20 || op === 0x21 || op === 0x22 || op === 0x23 || op === 0x24 || op === 0xD2) {
        // 标签/索引
        const idxRead = readUleb(buf, off);
        off = idxRead.next;
        detail = `idx=${idxRead.value}`;
        if (op === 0x20 || op === 0x21 || op === 0x22) {
            const lt = localTypes[idxRead.value];
            if (lt) {
                const tn = lt.type === 0x7F ? 'i32' : lt.type === 0x6E ? 'anyref' : '0x' + lt.type.toString(16);
                detail += ` (${tn})`;
            }
        }
    } else if (op === 0x41) {
        const vRead = readSleb32(buf, off);
        off = vRead.next;
        detail = `${vRead.value}`;
    } else if (op === 0x42) {
        // i64 const 简化
        off += 4; // 不严格解析
        detail = `<i64>`;
    } else if (op === 0x28 || op === 0x29 || op === 0x2A || op === 0x2B || op === 0x36 || op === 0x37 || op === 0x38 || op === 0x39) {
        // memarg
        const aRead = readUleb(buf, off);
        off = aRead.next;
        const oRead = readUleb(buf, off);
        off = oRead.next;
        detail = `align=${aRead.value} offset=${oRead.value}`;
    } else if (op === 0x3F || op === 0x40) {
        // memory.size/grow 有 0x00 后缀
        off++;
    } else if (op === 0xD0) {
        // ref.null 读 heap type
        const ht = buf[off++];
        detail = `heap=0x${ht.toString(16)}`;
    }

    return { mnemonic, detail, startOff, endOff: off };
}

// 反汇编所有指令
let instrOff = 0;
const instrs = [];
while (instrOff < code.length) {
    const startAbs = body.codeStart + instrOff;
    const instr = decodeInstr(code, instrOff);
    instrs.push({ ...instr, absOff: startAbs });
    instrOff = instr.endOff;
    if (instr.mnemonic === 'end' && instrOff === code.length) break;
}

// 打印指令
for (const ins of instrs) {
    const marker = (targetOffset >= 0 && ins.absOff === targetOffset) ? ' <<<TARGET' : '';
    console.log(`  +${ins.absOff.toString().padStart(6)}: ${ins.mnemonic} ${ins.detail}${marker}`);
}

// 如果有目标偏移,打印附近的指令
if (targetOffset >= 0) {
    console.log(`\n=== 目标偏移 ${targetOffset} 附近 ===`);
    const nearby = instrs.filter(i => Math.abs(i.absOff - targetOffset) < 30);
    for (const ins of nearby) {
        const marker = ins.absOff === targetOffset ? ' <<<TARGET' : '';
        console.log(`  +${ins.absOff.toString().padStart(6)}: ${ins.mnemonic} ${ins.detail}${marker}`);
    }
}
