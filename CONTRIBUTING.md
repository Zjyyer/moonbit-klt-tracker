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

## Provenance

Submit original work or disclose the source and license of any non-original material before it is incorporated. Algorithm citations belong in [docs/references.md](docs/references.md); see [docs/provenance.md](docs/provenance.md) for the project's original-code policy and AI-tool disclosure.
