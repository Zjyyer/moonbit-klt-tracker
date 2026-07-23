# moonbit-klt-tracker design

## Purpose

`moonbit-klt-tracker` is a MoonBit-native sparse feature tracking engine for ordered grayscale image frames. It turns a seeded or detected feature set into explainable point trajectories using pyramidal Lucas–Kanade (KLT) optical flow. The project is designed as a reusable systems library and a deterministic command-line workflow, not as a general image-processing or video-decoding framework.

## Problem and users

Applications such as lightweight motion analysis, camera calibration pipelines, robotics prototypes, and visual-test tooling need reproducible short-range point tracking but should not need to embed a large computer-vision runtime. Library users need an embeddable API; command-line users and AI agents need a stable way to run a frame sequence, inspect rejection reasons, and export results.

## Scope

The first release provides:

- Grayscale frame buffers with checked dimensions and boundary-safe bilinear sampling.
- Gaussian pyramids, image gradients, and small fixed-size numeric helpers.
- Shi–Tomasi corner detection and an API for caller-supplied seed points.
- Coarse-to-fine iterative Lucas–Kanade tracking with subpixel coordinates.
- Forward–backward consistency validation, residual/conditioning diagnostics, and per-point rejection reasons.
- Track IDs, lifecycle management, configurable loss pruning, and optional periodic redetection.
- Deterministic JSON and CSV trajectory exports plus a stable quality report.
- `detect`, `track`, and `inspect` CLI commands for frame manifests and reproducible fixture runs.
- Unit, integration, golden-output, property-style, benchmark, and target-parity tests.

The first release deliberately excludes video or image codecs, camera capture, deep-learning models, GPU acceleration, an interactive GUI, dense optical flow, and general-purpose CV primitives. Codec adapters remain external dependencies or later extension packages.

## Architecture

```text
frame manifest / caller buffers
          |
          v
  image -> pyramid -> gradients
          |              |
          v              v
features ------------> klt solver
                             |
                             v
                   validation and diagnostics
                             |
                             v
                      track lifecycle
                         |         |
                         v         v
                    library API   JSON/CSV + CLI report
```

### Package boundaries

| Package | Responsibility | Does not own |
|---|---|---|
| `image` | Gray frame validation, sampling, pyramid construction, gradients | File decoding and video I/O |
| `math` | Fixed-size vector/matrix operations and stable 2×2 solve | General numerical computing |
| `features` | Shi–Tomasi detection, non-maximum suppression, seed validation | Tracking state |
| `klt` | Per-level iterative displacement estimate and convergence checks | Track IDs or output serialization |
| `validation` | Forward–backward, residual, conditioning, bounds policy | Frame lifecycle |
| `tracking` | ID allocation, state transitions, pruning, redetection scheduling | KLT internals |
| `formats` | Versioned trajectory schema and JSON/CSV rendering | Filesystem policy |
| `cli` | Manifest parsing, command dispatch, human-readable reports | Library-only algorithms |

Dependencies flow toward lower-level packages only. `tracking` uses narrow interfaces from feature detection and solving, allowing future detector, SIMD, or hardware-accelerated implementations without altering trajectory consumers.

## Public behavior

Each input point produces an explicit result, not only a coordinate. A tracked observation carries source and target coordinates, residual, minimum eigenvalue, iteration count, pyramid level, forward–backward error, and one of `tracked`, `rejected`, `out_of_bounds`, or `lost` states. A batch can therefore finish when individual points fail, retaining diagnostic evidence.

Configuration validates dimensions, odd window sizes, pyramid depth, iteration limits, thresholds, and redetection intervals before processing. Invalid inputs return stable typed errors. Algorithmic non-convergence and quality rejection remain observation outcomes, so one poor feature never aborts an otherwise valid frame pair.

Repeated runs with identical input, manifest order, configuration, and target must create logically equivalent tracks and sorted exports. The JSON schema is versioned; CSV is a convenient flat projection of that same model.

## CLI workflow

`detect` produces a seed file from a grayscale frame manifest. `track` accepts a seed file or detector options, processes a sequence, writes JSON and optional CSV, and emits a summary. `inspect` renders a deterministic report for a prior JSON result, including state counts and threshold failures. All commands are non-interactive and return documented non-zero codes for invalid configuration or input.

## Quality strategy

- **Numerical tests:** sampling, gradient, Gaussian reduction, conditioning, coordinate scaling, and 2×2 solve.
- **Synthetic sequence tests:** integer/subpixel translation, motion at pyramid boundaries, low texture, occlusion, exit from frame, and forward–backward disagreement.
- **Lifecycle tests:** ID stability, pruning, recovery through redetection, empty seed sets, and deterministic ordering.
- **Integration tests:** CLI manifests, JSON/CSV schema, golden reports, invalid input exit codes, and rerun equality.
- **Cross-target checks:** Wasm, Wasm-GC, JavaScript, and native builds and tests where the toolchain supports them.
- **Benchmarks:** fixed synthetic frame sets report tracked-point throughput and allocations; benchmarks are informative rather than pass/fail performance claims.

## CI and repository rules

The project uses MoonBit v0.10.4 (the installed, current toolchain at design time). CI is based on the MoonBit community cross-platform template and also checks the requested PaiGack-style coverage workflow. It runs:

```text
moon fmt --check
moon check --target all --deny-warn
moon test --target all --deny-warn
moon info
git diff --exit-code
```

`moon fmt --deny-warn` and `moon info --deny-warn` are not used because the installed v0.10.4 CLI does not implement those flags; the chosen formatting and generated-interface sequence enforces the intended no-warning/no-diff invariant without an unsupported command.

The repository will use `main` as default branch, Apache-2.0, a bilingual README, an architecture note, an algorithm/reference note, a third-party-attribution record, a development journal, and a transparent OSC self-audit. Commits must be meaningful and authored only as `Zjyyer <298568415+Zjyyer@users.noreply.github.com>`; no synthetic collaborators, altered dates, or fabricated history.

## Ecosystem positioning and sources

MoonCakes lookup on 2026-07-23 found no module tagged or described as KLT, Lucas–Kanade, or optical flow. Nearby projects (`PingGuoMiaoMiao/MoonVision`, `megemini/millow`, and `python123-ops/moon-cv-geometry`) cover basic image processing or geometric foundations. This project must remain narrowly distinguished as a sequence-aware sparse-tracking engine, and must not copy their implementation.

Algorithmic behavior is derived from the Lucas–Kanade method and KLT literature. Public docs will cite sources and state any externally inspired design choices; source code will be authored independently and tested against synthetic expected behavior.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Pure implementation has numerical instability | Small units, explicit conditioning thresholds, deterministic synthetic oracles, and diagnostic outputs |
| Scope becomes a generic CV toolkit | Enforce package boundaries and exclude codecs/dense flow/GPU from v1 |
| Cross-target differences | Avoid target-specific assumptions, test all available targets, record any sanctioned deviations |
| Generated interfaces or formatting drift | CI regenerates `mbti` and fails on diffs |
| Competition audit questions AI use or provenance | Keep an honest development journal, source record, self-audit, and meaningful commit history |

## Success criteria

1. A new user can run a documented command on checked-in synthetic fixtures and obtain deterministic trajectories and a report.
2. A library user can pass grayscale buffers and seeds, track them through a sequence, and inspect per-point quality/loss reasons.
3. Declared key paths and invalid inputs are covered by automated tests across supported targets.
4. The repository is open, reproducible, documented, licensed, warning-free under supported commands, and clearly distinct from adjacent MoonCakes packages.
