namespace asgard.bifrost;

# asgard.bifrost —— Asgard 自绘渲染后端占位入口
#
# 长期职责：
#   - 消费 asgard.ui 视图树与布局结果
#   - 组织统一的自绘渲染命令
#   - 对接 GPU / raster 后端
#   - 承接跨平台像素级一致的 UI 渲染
