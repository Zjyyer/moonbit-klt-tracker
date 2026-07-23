# moonbit-klt-tracker

[English](README.md)

`moonbit-klt-tracker` 是一个使用 MoonBit 实现的确定性稀疏特征跟踪库，面向有序灰度帧缓冲区。v1 将提供经过尺寸校验的灰度帧、图像金字塔和梯度、Shi–Tomasi 特征检测、金字塔 Lucas–Kanade（KLT）跟踪、质量诊断、轨迹生命周期管理、确定性的 JSON/CSV 导出，以及 `detect`、`track`、`inspect` 命令行工作流。

## 范围

v1 有意不包含图像或视频编解码器、相机采集、GPU 加速、深度学习模型、稠密光流、交互式 GUI 或通用计算机视觉基础库。请由应用程序或外部适配器提供已经解码的灰度字节数据。

## 状态

项目正以增量方式构建；各软件包落地后会补充稳定的公开 API 和可运行示例。

## 许可证

Apache-2.0。详见 [LICENSE](LICENSE)。
