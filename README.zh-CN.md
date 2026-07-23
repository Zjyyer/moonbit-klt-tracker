# moonbit-klt-tracker

[English](README.md)

`moonbit-klt-tracker` 是一个 MoonBit 原生、确定性的稀疏特征跟踪库，输入为有序灰度帧缓冲区。它提供经过校验的灰度帧、图像金字塔和梯度、Shi-Tomasi 特征检测、金字塔 Lucas-Kanade（KLT）跟踪、前后向校验、轨迹生命周期管理，以及确定性的 JSON/CSV 导出。

## 快速开始

安装 MoonBit 后，用仓库内的夹具运行原生 CLI：

```sh
moon run src/cli -- detect --manifest tests/fixtures/occlusion/manifest.json
moon run src/cli -- inspect --manifest tests/fixtures/occlusion/manifest.json
moon run src/cli -- track --manifest tests/fixtures/occlusion/manifest.json --json trajectory.json --csv trajectory.csv
```

`detect` 输出检测到的轨迹数量，`inspect` 输出确定性的报告；`track` 至少需要 `--json` 或 `--csv` 之一，并且只写入请求的结果路径。所有命令都需要 `--manifest`。重复或未知的标志，以及向 `detect` 或 `inspect` 传入输出标志，都会产生用法错误。清单是包含 `frames` 数组的 JSON；每帧尺寸必须一致，`pixels` 必须是字节值。完整输入见以上夹具。

CLI 解析、文件边界、黄金输出和夹具工作流由 `src/cli_core/cli_flow_test.mbt` 覆盖；CI 通过 `moon test --target all --deny-warn` 执行这些测试。

## 库概览

公共包采用分层设计：`math` 和 `image` 为 `features` 提供基础；`klt` 与 `validation` 建立在其上；`tracking` 管理生命周期；`formats` 序列化报告；`cli_core` 负责与目标无关的命令流程；原生 `cli` 可执行包负责进程参数与退出状态。API 名称和错误行为见[架构说明](docs/architecture.md)与[算法说明](docs/algorithm.md)。

## 范围与限制

本项目提供稀疏、短距离的点跟踪，而不是视频或图像处理运行时；调用方需要提供已解码的灰度帧。实现采用局部平移模型和固定源图像梯度，并假设每个跟踪窗口内亮度恒定。它会拒绝无纹理、病态、越界或前后向不一致的观测；不建模仿射或投影运动、光照变化、遮挡语义、滚动快门、相机标定、稠密光流、GPU、编解码器、采集设备、深度学习模型或 GUI。

## 开发与验证

```sh
node tools/verify-docs.mjs
moon fmt --check
moon check --target all --deny-warn
moon test --target all --deny-warn
moon info
git diff --exit-code
```

请参阅 [CONTRIBUTING.md](CONTRIBUTING.md)、[变更记录](CHANGELOG.md)、[性能证据](docs/performance.md)、[参考资料](docs/references.md)、[来源说明](docs/provenance.md)和 [OSC 2026 自审](docs/osc2026-self-audit.md)。

## 许可证

Apache-2.0，详见 [LICENSE](LICENSE)。
