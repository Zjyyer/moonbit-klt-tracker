# Trajectory Analytics Design

## Goal

Raise the project above the OSC 2026 4,000-line requirement with useful, tested MoonBit capabilities rather than generated or duplicated code.

## Scope

Add `src/analytics`, a pure package consuming `formats.TrajectoryDocument`. It will model per-track and sequence summaries, finite-safe descriptive statistics, displacement/velocity metrics, quality counters, lifecycle transition events, anomaly flags, deterministic ranking, and a compact NDJSON report. It has no filesystem, image-decoding, GUI, or CLI dependency.

## Interfaces

`analyze(document, config) -> Result[SequenceAnalysis, AnalysisError]` validates finite controls and produces deterministic summaries sorted by track ID. `export_ndjson(analysis)` emits one schema header, sorted track summaries, then sorted events. Analysis never mutates tracker state.

## Quality

Every public behavior receives black-box tests: empty reports, finite validation, order stability, lost/rejected outcomes, transition detection, displacement/velocity arithmetic, anomaly thresholds, ranking ties, and byte-stable NDJSON. CI continues to run format, warning-denied checks/tests, and generated-interface validation.
