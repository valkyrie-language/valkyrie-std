# Legion 报告 dist 预览

结构与 `legion test` 产出的 `dist/legion-test/` 一致（本目录为手工示例，便于本地打开）。

```
dist-preview/
├── index.html          # SSG 静态页 + hydrate 挂载点
├── legion-test.css     # base.css + AWSL 作用域样式 + asgard-icol
├── boot.js             # voa 生成：加载 manifest → WASM → 组件 glue → mountIslands
├── manifest.json       # 组件 / WASM / CSS 清单
├── c/
│   └── chart-status.js   # 组件 glue：callExport('awsl_render_chart_status')
├── legion-test.mjs     # WASM instantiate glue（真实构建由编译器产出）
└── legion-test.wasm    # 需 cargo build 后由 legion test 生成（本预览可无）
```

用 HTTP 打开（`file://` 下 fetch manifest 会失败）：

```bash
cd valkyrie.v/projects/legion.report/dist-preview
python -m http.server 8765
```

浏览器访问 http://localhost:8765/
