import { execFileSync } from 'node:child_process';

const SPY = 'E:\\Goddess of Victory\\valkyrie.rs\\target\\release\\legion.exe';
const EXE = 'E:\\Goddess of Victory\\valkyrie.v\\dist\\bootstrap-clr\\v1_new\\legion__main_legion.exe';

const methods = [
    'legion__bootstrap_console_write_line',
    'legion__print_root_help',
    'std__console__write_line',
    'std__io__print_line',
    'std__io__error',
];

for (const method of methods) {
    console.log(`\n========== ${method} ==========`);
    try {
        const output = execFileSync(SPY, ['spy', 'clr', '-m', method, EXE], {
            timeout: 30000,
            encoding: 'utf8',
            maxBuffer: 10 * 1024 * 1024,
        });
        const lines = output.split('\n');
        let inIl = false;
        for (const line of lines) {
            if (line.includes('=== 方法体反汇编') || line.includes('Method body disassembly')) {
                inIl = true;
            }
            if (inIl) {
                if (line.startsWith('===') && !line.includes('方法体反汇编') && !line.includes('disassembly') && inIl) {
                    break;
                }
                console.log(line);
            }
        }
    } catch (err) {
        console.error(`Error: ${err.message}`);
    }
}
