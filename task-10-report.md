# Task 10 report

## Delivered

- Deterministic property invariant suite in `tests/property/invariants.mbt`.
- Fixed LCG-backed 128 x 96 translation benchmarks for detector and tracker.
- Reproducibility guidance in `docs/performance.md`.

## Verification

- `moon test tests/property --target native --deny-warn`: 1 passed.
- `moon bench bench --target native --release --deny-warn`: 2 passed.
- `moon test --target all --deny-warn`: 53 passed on wasm, wasm-gc, js, and native.

The MoonBit CLI currently emits non-fatal package warnings for the existing CLI main-package test layout and for the benchmark package's `bench` alias. The full command exits successfully with `--deny-warn`; no source changes outside Task 10 were made to address the CLI warning.

## Review follow-up

- Strengthened the invariant to require every zero-motion frame to report all eight original tracks in their original observation order.
- Required every such observation to remain `Active` before checking finite, in-bounds coordinates and near-zero displacement.
- Removed the unused KLT package import from the property-test package.
