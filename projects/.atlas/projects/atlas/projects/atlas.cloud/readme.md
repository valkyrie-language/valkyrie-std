# atlas.cloud

Atlas 云服务抽象层，对标 C# `Atlas.Cloud`。

## 职责

- 12 个云服务端口（Blob/SMS/Email/KeyVault/Chat/Embedding/Image/Speech/Translation/Search/Push/CDN）
- 共享 Models + Null 实现
- `AtlasCloudWireState` — 独立于 `AtlasWireContainer` 的云端口注册

## 与 atlas.adaptor 的区别

| 包 | 职责 |
|----|------|
| `atlas.cloud.*` | 直接包装厂商 API（OSS、SMS、邮件等） |
| `atlas.adaptor.*` | 部署入口桥接（平台 HTTP → `AtlasHost.process`） |

## 使用

```valkyrie
let mut cloud: AtlasCloudWireState = AtlasCloudWireState::new()
let bundle: AlibabaCloudBundle = register_alibaba_cloud(cloud, opts)
cloud = bundle.state
let result: BlobResult = bundle.blob.put_object("bucket", "key", "data", "text/plain")
```
