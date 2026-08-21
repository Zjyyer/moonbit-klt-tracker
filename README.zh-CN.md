# moonbit-klt-tracker

[English](README.md)

`moonbit-klt-tracker` 是一个确定性的 MoonBit 稀疏特征跟踪库和 CLI，面向有序灰度帧。项目组合了经过校验的图像缓冲区、Shi-Tomasi 特征、金字塔 Lucas-Kanade 跟踪、轨迹生命周期、质量验证、报告以及稳定的 JSON/CSV/NDJSON 数据契约。

## 特性

- 确定性的灰度帧、梯度与图像金字塔；
- 有限值安全的数学、插值、滤波、归一化、分块和区域分析；
- Shi-Tomasi 选择、金字塔 KLT、前后向验证和恢复诊断；
- 不可变轨迹、运动模型、质量、分段和事件 API；
- 表格/流/模式契约与分析报告；
- 基于清单和黄金夹具的原生 CLI。

## 快速开始

```sh
moon run src/cli -- detect --manifest tests/fixtures/occlusion/manifest.json
moon run src/cli -- inspect --manifest tests/fixtures/occlusion/manifest.json
moon run src/cli -- track --manifest tests/fixtures/occlusion/manifest.json --json trajectory.json --csv trajectory.csv
```

清单包含 `frames` 数组；每帧尺寸必须一致，`pixels` 必须是字节值。`detect` 输出数量，`inspect` 输出确定性报告，`track` 只写入指定的 JSON/CSV 输出。重复参数、未知参数、缺少清单和无效输出组合都会被拒绝。

## 包结构

| 包 | 职责 |
| --- | --- |
| `math` | 向量、矩阵、统计、几何、区间和序列工具 |
| `image` | 帧、梯度、金字塔、插值、滤波、归一化、分块和区域 |
| `features` | Shi-Tomasi 候选、确定性选择、间距和分数统计 |
| `klt` | 单层与金字塔 Lucas-Kanade 跟踪 |
| `motion` | 平移/仿射/投影模型、鲁棒损失、拟合和残差 |
| `validation` | 前后向检查、阈值、诊断和批量门禁 |
| `tracking` | 生命周期、健康度、恢复候选、时间线、检查点和会话 |
| `trajectory` | 不可变样本、重采样、平滑、指标、窗口和分段 |
| `formats` | JSON/CSV 以及表格、流、列和模式契约 |
| `analytics` | 聚合、排序、仪表板、过滤、报告和 NDJSON 契约 |
| `cli_core` / `cli` | 与目标无关的命令流程和原生可执行程序 |

## 开发与验证

```sh
node --test tools/verify-docs.test.mjs
node tools/verify-docs.mjs
moon fmt --check
moon check --target all --deny-warn
moon test --target wasm-gc --deny-warn
moon bench benchmarks --target wasm-gc --release --deny-warn
moon info
```

参阅 [贡献指南](CONTRIBUTING.md)、[变更记录](CHANGELOG.md)、[架构说明](docs/architecture.md)、[算法说明](docs/algorithm.md)、[性能证据](docs/performance.md)、[参考资料](docs/references.md)和[来源说明](docs/provenance.md)。

## 范围与限制

本项目面向稀疏、短距离点跟踪，不是视频运行时；调用方需要提供已解码的灰度帧。默认跟踪器假设局部亮度恒定并使用固定源梯度；不提供稠密光流、编解码器、采集设备、相机标定、滚动快门建模、GPU 执行或 GUI。

## 许可证

Apache-2.0，详见 [LICENSE](LICENSE)。
