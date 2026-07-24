# Trajectory Analytics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a deterministic, pure analytics package that provides more than 1,100 lines of useful MoonBit code and tests.

**Architecture:** The package reads existing trajectory documents and produces immutable summaries/events. Small modules isolate validation, statistics, event extraction, ranking, and NDJSON rendering.

**Tech Stack:** MoonBit 0.10.4, existing `formats`, `tracking`, `klt`, and all-target `moon test`.

## Global Constraints

- Use MoonBit package files and pass `moon fmt --check`, `moon check --target all --deny-warn`, `moon test --target all --deny-warn`, and `moon info` with clean diff.
- Preserve one Git author identity and use only meaningful commits.
- Count only tracked `.mbt` lines; do not pad code or comments.

---

### Task 1: Analytics data model and finite statistics

**Files:** Create `src/analytics/moon.pkg`, `model.mbt`, `statistics.mbt`, `analytics_test.mbt`.

- [ ] Write failing tests for empty/one/many finite samples, mean/min/max/variance, and invalid configuration.
- [ ] Run `moon test src/analytics --target all --deny-warn` and observe missing API failure.
- [ ] Implement validated statistic accumulators and immutable summary records.
- [ ] Re-run the package test and commit `feat: add trajectory analytics statistics`.

### Task 2: Track summaries, quality and events

**Files:** Create `src/analytics/summary.mbt`, `events.mbt`; extend `analytics_test.mbt`.

- [ ] Write failing fixtures/tests for displacement, velocity, active/lost transitions, quality counters, deterministic tie ranking, and anomaly limits.
- [ ] Run analytics tests and observe missing summary/event API failure.
- [ ] Implement document traversal, state transitions, ranking, and anomaly classification.
- [ ] Re-run tests and commit `feat: summarize trajectory quality and events`.

### Task 3: NDJSON report and integration evidence

**Files:** Create `src/analytics/ndjson.mbt`, `ndjson_test.mbt`; modify `README.md`, `docs/architecture.md`, `docs/performance.md`.

- [ ] Write failing byte-stability, escaping, ordering, and schema-header NDJSON tests.
- [ ] Run analytics tests and observe missing export failure.
- [ ] Implement deterministic NDJSON rendering and document the package boundary.
- [ ] Run all quality gates, source inventory, and commit `feat: export trajectory analytics reports`.
