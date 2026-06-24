# Native Windows

## 定位

本页描述 `native-windows` 子路线。它属于 `Native` family 内部的平台细分，负责 Windows 宿主上的对象文件、可执行文件、动态库与调试资产边界。

## 输入前提

- 已完成 `Native` family lowering
- 目标架构、ABI、链接模式与入口约定已经确定
- 需要的运行时依赖、附属产物与发布方式已经外显

## Validate

在进入 `compile` 前，至少要确认：

- 目标格式与 Windows 平台约束一致
- ABI、入口与装载约束明确
- 所需导入库、运行时依赖与 sidecar 已经声明

## Compile

`Compile` 阶段负责：

- 生成 Windows 平台可接受的目标文件或可执行映像
- 组织平台所需的入口、重定位与装载信息
- 准备打包和交付阶段需要的产物

## 典型交付物

- `.obj`
- `.exe`
- `.dll`
- 调试符号、导入库或运行说明

## 风险边界

- 禁止把 Windows 平台细节抬升成全部 `Native` family 的公共结构
- 禁止把平台打包、调试和装载逻辑塞进单一巨型对象
