// 临时诊断脚本：dump marker.main_legion 类字节码并定位指定方法的 VerifyError
// 运行后产出 dump 文件供分析
import { spawnSync } from "node:child_process";
import { writeFileSync, readFileSync, existsSync } from "node:fs";
import path from "node:path";

const JAR = String.raw`E:\Goddess of Victory\valkyrie.v\dist\bootstrap-jvm\v1\legion__main_legion.jar`;
const OUT_FULL = String.raw`E:\Goddess of Victory\valkyrie.v\scripts\_diag_full.txt`;
const OUT_METHOD = String.raw`E:\Goddess of Victory\valkyrie.v\scripts\_diag_method.txt`;
const TARGET_METHOD = "legion__legion_parse_workspace_auto_link";
const TARGET_CLASS = "marker.main_legion";

function run(cmd, args) {
  const r = spawnSync(cmd, args, { encoding: "utf8", maxBuffer: 1024 * 1024 * 64 });
  if (r.error) throw r.error;
  return { stdout: r.stdout ?? "", stderr: r.stderr ?? "", status: r.status };
}

console.log("[1/4] javap -c -p -classpath ...", TARGET_CLASS);
const full = run("javap", ["-c", "-p", "-classpath", JAR, TARGET_CLASS]);
writeFileSync(OUT_FULL, full.stdout + "\n----STDERR----\n" + full.stderr);
console.log("  ->", OUT_FULL, "size:", full.stdout.length);

console.log("[2/4] extract target method:", TARGET_METHOD);
const lines = full.stdout.split(/\r?\n/);
let start = -1, end = lines.length;
for (let i = 0; i < lines.length; i++) {
  if (lines[i].includes(TARGET_METHOD) && start === -1) {
    start = i;
  } else if (start !== -1 && /^\s*(public|private|protected|static|final|native|abstract|synchronized)\s+.*\(.*\).*$/.test(lines[i]) && i > start) {
    end = i;
    break;
  }
}
if (start === -1) {
  console.error("METHOD NOT FOUND");
  process.exit(2);
}
const methodLines = lines.slice(start, end);
writeFileSync(OUT_METHOD, methodLines.join("\n") + "\n");
console.log("  ->", OUT_METHOD, "lines:", methodLines.length, "(dump lines", start, "-", end, ")");

console.log("[3/4] also dump with -v (verbose) for stackmap/constant pool info");
const verbose = run("javap", ["-v", "-p", "-classpath", JAR, TARGET_CLASS]);
writeFileSync(String.raw`E:\Goddess of Victory\valkyrie.v\scripts\_diag_verbose.txt`, verbose.stdout + "\n----STDERR----\n" + verbose.stderr);
console.log("  -> verbose size:", verbose.stdout.length);

console.log("[4/4] done");
console.log("method slice:");
console.log(methodLines.join("\n"));
