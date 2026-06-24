# Native Linux

## 定位

本页描述 `native-linux` 子路线。它属于 `Native` family 内部的平台细分，负责 Linux 宿主上的对象文件、可执行文件与链接约束。

## 输入前提

- 已完成 `Native` family lowering
- 目标架构、ABI 与链接模式已经确定
- 入口约定、运行时依赖与打包方式已经外显

## Validate

在进入 `compile` 前，至少要确认：

- 目标对象格式与 Linux 平台约束一致
- ABI、调用约定和入口符号约束明确
- 所需运行时依赖、动态库或 sidecar 已经声明

## Compile

`Compile` 阶段负责：

- 生成 Linux 平台可接受的目标文件或可执行映像
- 组织平台所需的入口、重定位与链接信息
- 准备打包和交付阶段需要的产物

## 典型交付物

- `.o`
- Linux 可执行文件
- `.so`
- 调试符号与链接说明

## 风险边界

- 禁止把 Linux 平台细节抬升成全部 `Native` family 的公共结构
- 禁止把链接策略、启动逻辑和调试信息塞进单一巨型对象
