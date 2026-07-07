import fs from 'fs';
const file = 'e:\\Goddess of Victory\\valkyrie.rs\\projects\\nyar-emitter\\src\\lowering\\backends\\clr\\suspend.rs';
const content = fs.readFileSync(file, 'utf8');
const lines = content.split(/\r?\n/);
// 检查所有 real_witness_call_target 调用
lines.forEach((line, i) => {
    if (line.includes('real_witness_call_target(') && !line.includes('fn real_witness_call_target')) {
        console.log(`L${i+1}: ${line}`);
    }
});
// 检查 resolve_witness_slot 调用和 slot 绑定
console.log('\n--- slot 绑定 ---');
lines.forEach((line, i) => {
    if (line.includes('let Some(slot)') || line.includes('let Some(cancel_slot)')) {
        console.log(`L${i+1}: ${line.trim()}`);
    }
});
