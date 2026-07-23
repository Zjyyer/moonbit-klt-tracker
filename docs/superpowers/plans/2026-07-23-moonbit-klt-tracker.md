# moonbit-klt-tracker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a MoonBit-native, deterministic sparse KLT tracking library and CLI for grayscale frame sequences.

**Architecture:** A dependency-directed package graph separates grayscale images and pyramids, feature detection, the KLT solver, validation, track lifecycle, versioned formats, and CLI orchestration. Tests begin with deterministic synthetic frames, making numerical behavior observable before adding sequence and CLI layers.

**Tech Stack:** MoonBit v0.10.4; MoonBit native, Wasm, Wasm-GC, and JS targets; GitHub Actions; Apache-2.0; JSON/CSV text output.

## Global Constraints

- Use MoonBit v0.10.4 and do not depend on FFI, image codecs, video codecs, GPU APIs, or a network connection at runtime.
- Support grayscale buffers only; every public buffer constructor validates `width * height == bytes.length()`.
- Use fixed, deterministic ordering for seeds, track IDs, JSON keys, CSV rows, reports, and fixture outputs.
- Return explicit `Result` errors for invalid inputs; represent per-feature algorithmic failure as a result status, never as a batch abort.
- CI must run `moon fmt --check`, `moon check --target all --deny-warn`, `moon test --target all --deny-warn`, `moon info`, then `git diff --exit-code`.
- Do not use unsupported `moon fmt --deny-warn` or `moon info --deny-warn` flags.
- All commit authors use `Zjyyer <298568415+Zjyyer@users.noreply.github.com>` and every commit corresponds to an inspectable change.

---

## File structure

| Path | Responsibility |
|---|---|
| `moon.mod` | Module metadata, version, repository and license |
| `src/image/` | Frame validation, sampling, gradients and pyramids |
| `src/math/` | Small numeric types, vector operations and 2×2 solve |
| `src/features/` | Seed validation and Shi–Tomasi detection |
| `src/klt/` | Coarse-to-fine Lucas–Kanade motion solve |
| `src/validation/` | Forward–backward, residual, and bounds decisions |
| `src/tracking/` | Track lifecycle, IDs, pruning and redetection schedule |
| `src/formats/` | Versioned trajectory schema, JSON and CSV writing |
| `src/cli/` | Manifest parser, command dispatch, report rendering |
| `tests/fixtures/` | Checked-in deterministic frame and expected-output data |
| `benchmarks/` | Repeatable fixed-input benchmarks |
| `docs/` | User guide, references, provenance, development journal and OSC audit |
| `.github/workflows/` | Cross-platform quality and package-publish workflows |

### Task 1: Bootstrap module and quality baseline

**Files:**
- Create: `moon.mod`, `.gitignore`, `LICENSE`, `README.md`, `README.zh-CN.md`, `.editorconfig`
- Create: `.github/workflows/check.yml`, `.github/workflows/publish.yml`
- Test: `moon check --target all`

**Interfaces:**
- Produces the `zjyyer/moonbit-klt-tracker` module root for every later package.

- [ ] **Step 1: Create a minimal compiling module**

Create a root module named `zjyyer/moonbit-klt-tracker` with Apache-2.0 metadata and a minimal public root package that compiles without depending on the later image package.

- [ ] **Step 2: Add repository hygiene and CI**

Add a root `.gitignore` for `_build/`, `.moon/`, coverage output, and local fixture output. Add Apache-2.0 text, bilingual README stubs that describe actual v1 scope, and the cross-platform workflow from the community template with the global quality commands. Add the manual publish workflow without a credential value.

- [ ] **Step 3: Run quality checks**

Run: `moon fmt --check; moon check --target all`

Expected: both pass with the bootstrap package.

- [ ] **Step 4: Commit**

Run: `git add moon.mod .gitignore .editorconfig LICENSE README.md README.zh-CN.md .github && git commit -m "chore: bootstrap MoonBit tracker module"`

### Task 2: Numeric primitives and checked grayscale frames

**Files:**
- Create: `src/math/vec2.mbt`, `src/math/solve2.mbt`, `src/math/math_test.mbt`, `src/math/moon.pkg.json`
- Create: `src/image/frame.mbt`, `src/image/frame_test.mbt`, `src/image/moon.pkg.json`

**Interfaces:**
- Produces `Vec2 { x : Double, y : Double }`, `solve_symmetric_2x2(...) -> Result[Vec2, SolveError]`, `GrayFrame::new(width, height, pixels) -> Result[GrayFrame, FrameError]`, `GrayFrame::sample_bilinear(point) -> Option[Double]`.

- [ ] **Step 1: Write failing numeric and frame tests**

Cover vector addition/scaling, a well-conditioned solve, singular and near-singular matrices, invalid buffer length, integer pixel lookup, and out-of-bounds bilinear sampling.

- [ ] **Step 2: Run tests to verify failure**

Run: `moon test src/math src/image`

Expected: compile failures because the exported types and functions do not exist.

- [ ] **Step 3: Implement the smallest deterministic primitives**

Use `Double` coordinates; reject determinant magnitude at or below a documented epsilon; convert `Byte` pixels to `Double`; return `None` rather than clamping samples outside `[0,width-1] × [0,height-1]`.

- [ ] **Step 4: Run target tests**

Run: `moon test src/math src/image --target all --deny-warn`

Expected: all tests pass without warnings.

- [ ] **Step 5: Commit**

Run: `git add src/math src/image && git commit -m "feat: add checked grayscale frame primitives"`

### Task 3: Gradients and Gaussian pyramids

**Files:**
- Create: `src/image/gradient.mbt`, `src/image/pyramid.mbt`, `src/image/pyramid_test.mbt`
- Modify: `src/image/moon.pkg.json`

**Interfaces:**
- Consumes: `GrayFrame`, `Vec2`.
- Produces: `GradientFrame`, `Pyramid::build(frame, levels) -> Result[Pyramid, PyramidError]`, `Pyramid::level(index) -> GrayFrame`, `GradientFrame::at(point) -> Option[Vec2]`.

- [ ] **Step 1: Write failing tests**

Use a 5×5 horizontal ramp to assert central-difference x-gradient, zero y-gradient, valid 2-level dimensions, and an error when requested pyramid depth cannot retain a 3×3 image.

- [ ] **Step 2: Run failure check**

Run: `moon test src/image`

Expected: missing pyramid and gradient exports.

- [ ] **Step 3: Implement blur/downsample and gradients**

Implement a fixed separable `[1,4,6,4,1]/16` Gaussian kernel with reflected-edge sampling; halve each dimension using the blurred even coordinates; calculate central differences with edge reflection.

- [ ] **Step 4: Verify behavior**

Run: `moon test src/image --target all --deny-warn`

Expected: all image tests pass.

- [ ] **Step 5: Commit**

Run: `git add src/image && git commit -m "feat: build gradients and image pyramids"`

### Task 4: Feature seeds and Shi–Tomasi detection

**Files:**
- Create: `src/features/seed.mbt`, `src/features/shi_tomasi.mbt`, `src/features/features_test.mbt`, `src/features/moon.pkg.json`

**Interfaces:**
- Consumes: `GrayFrame`, `GradientFrame`, `Vec2`.
- Produces: `SeedPoint { position : Vec2, score : Double }`, `detect_shi_tomasi(frame, config) -> Result[Array[SeedPoint], FeatureError]`, `validate_seeds(frame, seeds) -> Result[Array[SeedPoint], FeatureError]`.

- [ ] **Step 1: Write failing detector tests**

Create a synthetic corner and a flat frame. Assert that a corner is selected, flat regions yield no candidates, requested count caps output, and seeds outside the usable window produce a validation error.

- [ ] **Step 2: Run failure check**

Run: `moon test src/features`

Expected: missing feature package.

- [ ] **Step 3: Implement structure-tensor scoring and suppression**

Accumulate gradient products in a configured odd window, compute the smaller eigenvalue, discard values below threshold, sort score-descending then y/x ascending, and apply radius non-maximum suppression.

- [ ] **Step 4: Run target tests**

Run: `moon test src/features --target all --deny-warn`

Expected: deterministic ordered seeds on every target.

- [ ] **Step 5: Commit**

Run: `git add src/features && git commit -m "feat: detect and validate track seeds"`

### Task 5: Single-level iterative Lucas–Kanade solver

**Files:**
- Create: `src/klt/config.mbt`, `src/klt/single_level.mbt`, `src/klt/klt_test.mbt`, `src/klt/moon.pkg.json`

**Interfaces:**
- Consumes: `GrayFrame`, `GradientFrame`, `SeedPoint`, `Vec2`.
- Produces: `KltConfig`, `KltObservation`, `track_single_level(previous, next, gradient, seed, initial, config) -> KltObservation`.

- [ ] **Step 1: Write failing motion tests**

Generate a textured synthetic frame and a one-pixel translated successor. Assert returned displacement is within a documented tolerance, iteration count does not exceed the cap, flat regions report a conditioning rejection, and out-of-bounds windows report `out_of_bounds`.

- [ ] **Step 2: Run failure check**

Run: `moon test src/klt`

Expected: missing solver exports.

- [ ] **Step 3: Implement inverse-compositional-style local iteration**

Accumulate the 2×2 gradient matrix and temporal residual across the window, solve for update, stop on update norm threshold, stop at `max_iterations`, and preserve residual/eigenvalue diagnostics in every outcome.

- [ ] **Step 4: Run target tests**

Run: `moon test src/klt --target all --deny-warn`

Expected: translation and rejection tests pass.

- [ ] **Step 5: Commit**

Run: `git add src/klt && git commit -m "feat: solve single-level KLT motion"`

### Task 6: Coarse-to-fine KLT and forward–backward validation

**Files:**
- Create: `src/klt/pyramidal.mbt`, `src/validation/forward_backward.mbt`, `src/validation/validation_test.mbt`, `src/validation/moon.pkg.json`
- Modify: `src/klt/klt_test.mbt`, `src/klt/moon.pkg.json`

**Interfaces:**
- Consumes: `Pyramid`, `KltConfig`, `KltObservation`.
- Produces: `track_pyramidal(previous, next, seed, config) -> KltObservation`, `validate_forward_backward(previous, next, seed, forward, config) -> KltObservation`.

- [ ] **Step 1: Write failing tests**

Use a six-pixel translation that cannot pass at one level but must pass with three levels. Create an inconsistent backward frame and assert `rejected` with a recorded forward–backward error above the threshold.

- [ ] **Step 2: Run failure check**

Run: `moon test src/klt src/validation`

Expected: tests fail because pyramidal and validation functions are absent.

- [ ] **Step 3: Implement scale propagation and quality gates**

Start at the smallest pyramid level with zero motion, double displacement when moving to the next finer level, run the single-level solver, then run the same tracking direction backward from the forward endpoint and compare to the original seed.

- [ ] **Step 4: Run target tests**

Run: `moon test src/klt src/validation --target all --deny-warn`

Expected: large-motion and inconsistency scenarios pass.

- [ ] **Step 5: Commit**

Run: `git add src/klt src/validation && git commit -m "feat: add pyramidal tracking validation"`

### Task 7: Track lifecycle and frame-sequence engine

**Files:**
- Create: `src/tracking/track.mbt`, `src/tracking/engine.mbt`, `src/tracking/tracking_test.mbt`, `src/tracking/moon.pkg.json`

**Interfaces:**
- Consumes: `GrayFrame`, `SeedPoint`, `KltConfig`, `KltObservation`.
- Produces: `TrackId`, `TrackState`, `Track`, `TrackerConfig`, `Tracker::start(frame, seeds)`, `Tracker::step(frame) -> Result[FrameReport, TrackerError]`, `Tracker::tracks() -> Array[Track]`.

- [ ] **Step 1: Write failing lifecycle tests**

Assert seed IDs start at zero and remain stable; a lost point becomes `lost` exactly once; a frame with one valid and one invalid point still reports the valid result; configured redetection adds only non-overlapping new IDs at the stated interval.

- [ ] **Step 2: Run failure check**

Run: `moon test src/tracking`

Expected: missing tracker types and methods.

- [ ] **Step 3: Implement deterministic engine state**

Keep previous frame and active tracks, process tracks by ascending ID, append observations, transition only through documented states, prune only after configured consecutive losses, and call the detector only on explicit redetection frames.

- [ ] **Step 4: Run target tests**

Run: `moon test src/tracking --target all --deny-warn`

Expected: state transition tests pass.

- [ ] **Step 5: Commit**

Run: `git add src/tracking && git commit -m "feat: manage feature track lifecycles"`

### Task 8: Versioned result schema and deterministic exports

**Files:**
- Create: `src/formats/model.mbt`, `src/formats/json.mbt`, `src/formats/csv.mbt`, `src/formats/formats_test.mbt`, `src/formats/moon.pkg.json`

**Interfaces:**
- Consumes: `Track`, `FrameReport`.
- Produces: `TrajectoryDocument`, `export_json(document) -> String`, `export_csv(document) -> String`, `schema_version() -> String`.

- [ ] **Step 1: Write failing serialization tests**

Construct a two-track document in reverse insertion order. Assert exported JSON fields use schema `1.0`, track rows sort by ID then frame, CSV uses the documented header, and repeated renderings are byte-identical.

- [ ] **Step 2: Run failure check**

Run: `moon test src/formats`

Expected: package is missing.

- [ ] **Step 3: Implement data model and escaping**

Use an internal explicit document model; serialize finite numbers with fixed deterministic formatting; reject non-finite numeric values before writing; quote CSV values containing comma, quote, or newline.

- [ ] **Step 4: Run target tests**

Run: `moon test src/formats --target all --deny-warn`

Expected: exports are stable on every target.

- [ ] **Step 5: Commit**

Run: `git add src/formats && git commit -m "feat: export versioned trajectories"`

### Task 9: CLI manifest, commands, and golden integration tests

**Files:**
- Create: `src/cli/main.mbt`, `src/cli/manifest.mbt`, `src/cli/report.mbt`, `src/cli/cli_test.mbt`, `src/cli/moon.pkg.json`
- Create: `tests/fixtures/translation/manifest.json`, `tests/fixtures/translation/expected.json`, `tests/fixtures/occlusion/manifest.json`, `tests/fixtures/occlusion/expected.json`

**Interfaces:**
- Consumes: `Tracker`, `TrajectoryDocument`.
- Produces commands `detect`, `track`, and `inspect`; `parse_manifest(text) -> Result[FrameManifest, ManifestError]`; `render_report(document) -> String`.

- [ ] **Step 1: Write failing CLI tests**

Verify a valid manifest parses in listed order, duplicate frame indexes and dimension mismatches fail with stable errors, `track` produces the checked-in translation JSON, and `inspect` reports tracked/lost/rejected counts in deterministic order.

- [ ] **Step 2: Run failure check**

Run: `moon test src/cli`

Expected: missing command and manifest exports.

- [ ] **Step 3: Implement non-interactive command flow**

Dispatch exactly `detect`, `track`, or `inspect`; parse required flags without network access; emit JSON/CSV only to requested paths; emit summary to standard output; return non-zero codes for usage, manifest, configuration, and input errors.

- [ ] **Step 4: Run golden tests**

Run: `moon test src/cli --target native --deny-warn`

Expected: fixture output matches byte-for-byte.

- [ ] **Step 5: Commit**

Run: `git add src/cli tests/fixtures && git commit -m "feat: add reproducible tracking CLI"`

### Task 10: Property tests, benchmarks, and target-parity suite

**Files:**
- Create: `tests/property/invariants.mbt`, `benchmarks/translation_bench.mbt`, `benchmarks/moon.pkg`, `docs/performance.md`

**Interfaces:**
- Consumes: all public tracking APIs.
- Produces deterministic invariant suite and documented benchmark command/output format.

- [ ] **Step 1: Write failing invariants**

For deterministic generated image seeds, assert valid tracked coordinates remain finite and in bounds, track ID never changes, observation frame indexes strictly increase, and a zero-motion sequence has displacement within tolerance.

- [ ] **Step 2: Run failure check**

Run: `moon test tests/property --target native`

Expected: failure until invariant generator and engine hooks are available.

- [ ] **Step 3: Implement fixtures and benchmark**

Use a documented linear-congruential generator with a fixed seed; build a fixed 128×96 textured translation sequence; benchmark detector plus tracker separately; record the toolchain, target, fixture size, and command without claiming a universal performance figure.

- [ ] **Step 4: Run full suite**

Run: `moon test --target all --deny-warn`

Expected: all unit, integration, and invariant tests pass.

- [ ] **Step 5: Commit**

Run: `git add tests/property bench docs/performance.md && git commit -m "test: add tracking invariants and benchmarks"`

### Task 11: Complete documentation, provenance, and OSC audit

**Files:**
- Modify: `README.md`, `README.zh-CN.md`
- Create: `docs/architecture.md`, `docs/algorithm.md`, `docs/references.md`, `docs/provenance.md`, `docs/development-journal.md`, `docs/osc2026-self-audit.md`, `CHANGELOG.md`, `CONTRIBUTING.md`

**Interfaces:**
- Produces the complete user journey, algorithm limitations, source attribution, AI-tool disclosure, and repeatable self-audit evidence.

- [ ] **Step 1: Write documentation verification checks**

Add a repository script or test that asserts README links resolve to checked-in files, the documented CLI commands match accepted command names, and the audit lists license, default branch, source scale command, history count command, CI workflow, and generated-interface gate.

- [ ] **Step 2: Run failure check**

Run: the documentation verification command.

Expected: it fails until the listed documents and command examples exist.

- [ ] **Step 3: Write the documents from actual implementation evidence**

Document API examples that are executed in CI, limitations such as brightness/affine-motion assumptions, adjacent MoonCakes packages and differentiation, original-code policy, third-party algorithm references, meaningful development stages, and a date-stamped OSC checklist.

- [ ] **Step 4: Verify documentation and quality**

Run: documentation verification; `moon fmt --check; moon check --target all --deny-warn; moon test --target all --deny-warn; moon info; git diff --exit-code`

Expected: every command passes and generated interfaces are committed.

- [ ] **Step 5: Commit**

Run: `git add README.md README.zh-CN.md docs CHANGELOG.md CONTRIBUTING.md && git commit -m "docs: complete user and competition guidance"`

### Task 12: Release readiness and remote publication

**Files:**
- Create: `scripts/osc-audit.ps1`, `scripts/line-count.ps1`
- Modify: `.github/workflows/check.yml`, `README.md`

**Interfaces:**
- Produces a local audit report that checks branch, author identities, license, README, workflow, commit count, source size, `moon fmt --check`, `moon info` diff, and tests.

- [ ] **Step 1: Write failing audit checks**

Make the audit fail if `main` is absent, an author email differs from the configured noreply identity, required docs are absent, fewer than 10 meaningful commits exist, a CI workflow is absent, source line count is not reported, or a quality command fails.

- [ ] **Step 2: Run failure check**

Run: `powershell -ExecutionPolicy Bypass -File scripts/osc-audit.ps1`

Expected: failure before all metadata and history requirements are satisfied.

- [ ] **Step 3: Implement audit and line count scripts**

Limit line counting to tracked `*.mbt` files outside `_build`; print both physical and nonblank noncomment counts; report checks rather than inventing results; preserve all command output required for an auditor.

- [ ] **Step 4: Run final local verification**

Run: `powershell -ExecutionPolicy Bypass -File scripts/osc-audit.ps1`

Expected: PASS, author set contains only the account owner, and every required quality test passes.

- [ ] **Step 5: Commit**

Run: `git add scripts .github/workflows/check.yml README.md && git commit -m "build: add OSC release readiness audit"`

## Self-review

- **Spec coverage:** Tasks 2–8 implement image buffers, pyramids, features, KLT, validation, lifecycle, and exports. Task 9 implements all three CLI commands and fixtures. Task 10 covers quality/performance evidence. Tasks 1, 11, and 12 cover license, CI, provenance, user documentation, audit, history, and publishing checks.
- **Placeholder scan:** This plan contains no deferred implementation markers; every task specifies files, tests, commands, expected state, and commit boundary.
- **Type consistency:** `GrayFrame` and `Vec2` flow upward from image/math; `SeedPoint` feeds KLT; `KltObservation` feeds validation and tracking; `Track` and `FrameReport` feed formats and CLI. No upper package is required by a lower package.
