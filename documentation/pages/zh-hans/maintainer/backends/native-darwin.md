# Native Darwin

## 定位

本页描述 `native-darwin` 子路线。它属于 `Native` family 内部的平台细分，负责 Darwin 宿主上的目标文件、可执行文件、动态库与签名相关边界。

## 输入前提

- 已完成 `Native` family lowering
- 目标架构、ABI 与打包方式已经确定
- 入口约定、运行时依赖与发布要求已经外显

## Validate

在进入 `compile` 前，至少要确认：

- 目标格式与 Darwin 平台约束一致
- ABI、入口和平台打包前提明确
- 所需依赖、附属产物与运行说明完整

## Compile

`Compile` 阶段负责：

- 生成 Darwin 平台可接受的目标文件或可执行映像
- 组织平台所需的入口、重定位与装载信息
- 准备打包和交付阶段需要的产物

## 典型交付物

- `.o`
- Darwin 可执行文件
- `.dylib`
- 调试符号、签名说明或打包说明

## 风险边界

- 禁止把 Darwin 平台细节提升为全部 `Native` family 的统一模型
- 禁止把平台签名、打包和运行要求反向污染公共语义层
