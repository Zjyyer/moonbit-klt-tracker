# moonbit-klt-tracker

[简体中文](README.zh-CN.md)

`moonbit-klt-tracker` is a deterministic MoonBit library and CLI for sparse feature tracking on ordered grayscale frames. It combines checked image buffers, Shi-Tomasi features, pyramidal Lucas-Kanade tracking, trajectory lifecycle management, validation, reporting, and stable JSON/CSV/NDJSON contracts.

## Highlights

- deterministic integer-backed grayscale frames and image pyramids;
- finite-safe math, interpolation, filtering, normalization, tiling, and region analysis;
- Shi-Tomasi selection, pyramidal KLT tracking, forward-backward validation, and recovery diagnostics;
- immutable trajectory, motion-model, quality, segmentation, and event APIs;
- schema-aware table/stream contracts and analytics reports;
- a small native CLI with checked manifests and golden fixtures.

## Quick start

```sh
moon run src/cli -- detect --manifest tests/fixtures/occlusion/manifest.json
moon run src/cli -- inspect --manifest tests/fixtures/occlusion/manifest.json
moon run src/cli -- track --manifest tests/fixtures/occlusion/manifest.json --json trajectory.json --csv trajectory.csv
```

The manifest contains a `frames` array. Frames must share dimensions and contain byte-valued grayscale `pixels`. `detect` prints a count, `inspect` prints a deterministic report, and `track` writes only the requested JSON/CSV outputs. Duplicate flags, unknown flags, missing manifests, and invalid output combinations are rejected.

## Package map

| Package | Responsibility |
| --- | --- |
| `math` | vectors, matrices, statistics, geometry, intervals, and series utilities |
| `image` | frames, gradients, pyramids, interpolation, filters, normalization, tiles, and regions |
| `features` | Shi-Tomasi candidates, deterministic selection, spacing, and score summaries |
| `klt` | single-level and pyramidal Lucas-Kanade tracking |
| `motion` | translation/affine/projective models, robust losses, fitting, and residuals |
| `validation` | forward-backward checks, thresholds, typed diagnostics, and batch gates |
| `tracking` | lifecycle, health, recovery candidates, timelines, checkpoints, and sessions |
| `trajectory` | immutable samples, resampling, smoothing, metrics, windows, and segmentation |
| `formats` | JSON/CSV models plus table, stream, column, and schema contracts |
| `analytics` | aggregation, ranking, dashboards, filters, reports, and NDJSON contracts |
| `cli_core` / `cli` | target-independent commands and the native executable |

## Data and API contracts

The library APIs are pure where practical and return typed errors for invalid dimensions, non-finite values, insufficient samples, and incompatible schemas. `analytics.analyze(document, config)` produces deterministic per-track summaries, quality totals, and lifecycle events. `analytics.export_ndjson(analysis)` emits a newline-terminated stream with one header, summaries ordered by track ID, and events ordered by frame, track ID, and kind.

## Benchmarks

The checked-in benchmark uses a fixed 128 × 96 LCG-generated texture and a one-pixel horizontal translation. It measures detector and tracker paths separately. Captured output and reproduction details are in [docs/performance.md](docs/performance.md); these numbers are fixture- and toolchain-specific, not universal performance claims.

## Development

```sh
node --test tools/verify-docs.test.mjs
node tools/verify-docs.mjs
moon fmt --check
moon check --target all --deny-warn
moon test --target wasm-gc --deny-warn
moon bench benchmarks --target wasm-gc --release --deny-warn
moon info
```

See [CONTRIBUTING.md](CONTRIBUTING.md), [CHANGELOG.md](CHANGELOG.md), [architecture notes](docs/architecture.md), [algorithm notes](docs/algorithm.md), [performance evidence](docs/performance.md), [references](docs/references.md), and [provenance](docs/provenance.md).

## Scope and limitations

This is sparse, short-range point tracking, not a video runtime. Callers provide decoded grayscale frames. The default tracker assumes local brightness constancy and fixed source gradients. It does not provide dense flow, codecs, capture devices, calibration, rolling-shutter modeling, GPU execution, or a GUI.

## License

Apache-2.0. See [LICENSE](LICENSE).
