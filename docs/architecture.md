# Architecture

## Package boundaries

| Package | Responsibility | Evidence |
| --- | --- | --- |
| `src/math` | `Vec2` operations and a finite-result symmetric 2x2 solver | `vec2.mbt`, `solve2.mbt` |
| `src/image` | checked `GrayFrame`, bilinear sampling, gradients, and reflected-kernel pyramids | `frame.mbt`, `gradient.mbt`, `pyramid.mbt` |
| `src/features` | `SeedPoint`, validated feature configuration, Shi-Tomasi detection, suppression | `seed.mbt`, `shi_tomasi.mbt` |
| `src/klt` | single-level and coarse-to-fine KLT observations | `single_level.mbt`, `pyramidal.mbt` |
| `src/validation` | forward-backward consistency check | `forward_backward.mbt` |
| `src/tracking` | IDs, active/lost state, pruning, and optional redetection | `track.mbt`, `engine.mbt` |
| `src/formats` | versioned trajectory documents and JSON/CSV serialization | `model.mbt`, `json.mbt`, `csv.mbt` |
| `src/cli` | manifest parsing, request validation, native file I/O, and command dispatch | `manifest.mbt`, `main.mbt` |

Dependencies point downward: callers create `GrayFrame` values, detect or supply seeds, start a `Tracker`, call `step` for each following frame, then serialize `Tracker::tracks()` and frame reports. Only the native CLI boundary reads a manifest or writes requested JSON/CSV paths; `run_cli` accepts manifest text so its core flow remains target-independent.

## Observable API behavior

`GrayFrame::new(width, height, pixels)` rejects invalid dimensions or a pixel count that does not equal `width * height`. `Pyramid::build(frame, levels)` rejects depths that cannot be represented by the source dimensions. `Tracker::start(config, frame, seeds)` validates tracker controls and finite in-frame seeds. `Tracker::step(frame)` returns a report and updates active tracks; failed observations become `Lost`, are counted, and are pruned once their consecutive-loss count reaches the configured bound.

`parse_request` recognizes exactly `detect`, `track`, and `inspect`. All require a manifest; only `track` may accept `--json` and/or `--csv`, and it requires at least one output. The integration tests in `src/cli/cli_test.mbt` execute parsing, in-memory operation, native file I/O, and golden JSON checks. The repository CI runs the package tests on every configured target.
