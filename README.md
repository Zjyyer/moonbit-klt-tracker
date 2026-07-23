# moonbit-klt-tracker

[简体中文](README.zh-CN.md)

`moonbit-klt-tracker` is a MoonBit-native, deterministic sparse feature-tracking library for ordered grayscale frame buffers. It provides checked grayscale frames, image pyramids and gradients, Shi-Tomasi feature detection, pyramidal Lucas-Kanade (KLT) tracking, forward-backward validation, track lifecycle management, and deterministic JSON/CSV exports.

## Quick start

Install MoonBit, then run the checked-in fixture through the native CLI:

```sh
moon run src/cli -- detect --manifest tests/fixtures/occlusion/manifest.json
moon run src/cli -- inspect --manifest tests/fixtures/occlusion/manifest.json
moon run src/cli -- track --manifest tests/fixtures/occlusion/manifest.json --json trajectory.json --csv trajectory.csv
```

`detect` prints the detected-track count. `inspect` prints a deterministic report. `track` requires at least one of `--json` or `--csv` and writes only the requested result paths. All commands require `--manifest`; duplicate flags, unknown flags, and output flags on `detect` or `inspect` are usage errors. The manifest is JSON with a `frames` array whose frames share dimensions and contain byte-valued grayscale `pixels`; see the fixtures above for complete inputs.

The CLI's parsing, file boundary, golden output, and fixture workflows are tested in `src/cli_core/cli_flow_test.mbt`. The CI workflow runs those tests through `moon test --target all --deny-warn`.

## Library overview

The public packages are deliberately layered: `math` and `image` support `features`; `klt` and `validation` operate on those; `tracking` owns lifecycle; `formats` serializes reports; `cli_core` owns target-independent command flow; and the native `cli` executable owns process arguments and exit status. API names and error behavior are described in [architecture notes](docs/architecture.md) and [algorithm notes](docs/algorithm.md).

## Scope and limitations

This is sparse, short-range point tracking, not a video or image-processing runtime. Callers supply decoded grayscale frames. The implementation uses a local translation model with fixed source gradients and assumes brightness constancy within each tracking window. It can reject textureless, ill-conditioned, out-of-bounds, or forward-backward-inconsistent observations; it does not model affine or projective motion, illumination changes, occlusion semantics, rolling shutter, camera calibration, dense flow, GPU execution, codecs, capture devices, deep-learning models, or a GUI.

## Development and verification

```sh
node --test tools/verify-docs.test.mjs
node tools/verify-docs.mjs
moon fmt --check
moon check --target all --deny-warn
moon test --target all --deny-warn
moon info
git diff --exit-code
```

For the OSC candidate-repository checks, switch to the locally checked-out `main` branch and run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/osc-audit.ps1`. It reports the tracked MoonBit source inventory, one recorded author identity, history count, required repository files, and the same quality gates. Remote default-branch verification is intentionally separate and is performed only after publishing with `-CheckRemoteDefault`.

See [CONTRIBUTING.md](CONTRIBUTING.md), the [change log](CHANGELOG.md), [performance evidence](docs/performance.md), [references](docs/references.md), [provenance](docs/provenance.md), and the [OSC 2026 self-audit](docs/osc2026-self-audit.md).

## License

Apache-2.0. See [LICENSE](LICENSE).
