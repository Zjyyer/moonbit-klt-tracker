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
| `src/analytics` | pure finite-safe trajectory summaries, lifecycle events, and deterministic NDJSON rendering | `model.mbt`, `statistics.mbt`, `summary.mbt`, `events.mbt`, `ndjson.mbt` |
| `src/cli_core` | manifest parsing, request validation, command dispatch, reports, and native file I/O helpers | `command.mbt`, `manifest.mbt`, `report.mbt` |
| `src/cli` | thin native executable boundary: process arguments and exit status | `main.mbt` |

Dependencies point downward: callers create `GrayFrame` values, detect or supply seeds, start a `Tracker`, call `step` for each following frame, then serialize `Tracker::tracks()` and frame reports. `analytics` consumes a `formats.TrajectoryDocument` and has no CLI, filesystem, image-decoding, or tracker-mutation dependency. `cli_core` accepts manifest text for target-independent parsing and command flow, while its native file helpers perform the requested JSON/CSV writes. The `cli` executable only passes process arguments to `cli_core` and exits with its returned status.

## Observable API behavior

`GrayFrame::new(width, height, pixels)` rejects invalid dimensions or a pixel count that does not equal `width * height`. `Pyramid::build(frame, levels)` rejects depths that cannot be represented by the source dimensions. `Tracker::start(config, frame, seeds)` validates tracker controls and finite in-frame seeds. `Tracker::step(frame)` returns a report and updates active tracks; failed observations become `Lost`, are counted, and are pruned once their consecutive-loss count reaches the configured bound.

`parse_request` recognizes exactly `detect`, `track`, and `inspect`. All require a manifest; only `track` may accept `--json` and/or `--csv`, and it requires at least one output. The integration tests in `src/cli_core/cli_flow_test.mbt` execute parsing, in-memory operation, native file I/O, and golden JSON checks. The repository CI runs the package tests on every configured target.

`analyze(document, config)` validates finite configuration and derived displacement before returning summaries. `export_ndjson(analysis)` therefore renders only finite metrics: it writes one `trajectory_analytics` schema-header JSON object, zero or more `track_summary` objects sorted by ID, and then lifecycle-event objects sorted by frame, ID, and activated-before-lost order. Every object ends with `\n`; field order is fixed, and JSON strings use deterministic escaping. This is a pure library boundary rather than a CLI output option.
