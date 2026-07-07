# Atlas workspace

Atlas 子包位于 `projects/atlas/projects/*`，workspace 清单为本目录下的 `legions.von`。

数据访问立场摘要（Hermes；UpgradePlan；**不是** migrations 回放；与 yyds 无关）：见 [documentation · 数据访问](documentation/pages/zh-hans/data-access/index.md)。包内实现摘要：[`projects/atlas/readme.md`](projects/atlas/readme.md)。

## 成员

- `projects/atlas`
- `projects/atlas.adaptor`
- `projects/atlas.adaptor.azure`
- `projects/atlas.cloud`
- `projects/atlas.cloud.aliyun`
- `projects/atlas.cloud.azure`
- `projects/atlas.cloud.tencent`
- `../atlas.tools`

## 构建

发行版入口（嵌套 `legions`）：

```bash
cd valkyrie.v/projects/atlas._
legion build
```

全量集成构建：

```bash
cd valkyrie.v
legion build
```
