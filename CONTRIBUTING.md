# Contributing

## Before opening a change

Keep changes focused, add or update tests for behavior changes, and keep public MoonBit interfaces generated and checked in. Do not add codecs, capture backends, dense flow, or unrelated vision primitives without an agreed scope change.

Run the complete local gate from the repository root:

```sh
node tools/verify-docs.mjs
moon fmt --check
moon check --target all --deny-warn
moon test --target all --deny-warn
moon info
git diff --exit-code
```

`moon info` updates generated interface metadata when needed. The final diff check is intentional: it ensures generated interfaces are committed rather than left only in a local build directory. The CI workflow at `.github/workflows/check.yml` runs the MoonBit checks across Ubuntu, macOS, and Windows; its final diff gate enforces the same generated-interface rule.

For an OSC submission candidate, first check out local `main`, then run the reproducible repository audit from PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/osc-audit.ps1
```

The audit requires one actual Git author identity, at least 10 committed revisions, Apache-2.0, README, CI, and tracked MoonBit source counts. It runs the gate above unless `-SkipQualityGates` is supplied for development-only diagnostics. `scripts/line-count.ps1` reports its inclusion rule (tracked `*.mbt` only) and exclusions separately. A local `main` ref does not prove a hosting service's default branch: after publishing, run `scripts/osc-audit.ps1 -CheckRemoteDefault` to verify `origin/HEAD` points to `main`.

## Provenance

Submit original work or disclose the source and license of any non-original material before it is incorporated. Algorithm citations belong in [docs/references.md](docs/references.md); see [docs/provenance.md](docs/provenance.md) for the project's original-code policy and AI-tool disclosure.
