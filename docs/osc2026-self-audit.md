# OSC 2026 self-audit

Audit date: 2026-07-23

| Check | Evidence | Status |
| --- | --- | --- |
| License | License: Apache-2.0; checked-in `LICENSE` | recorded |
| Default branch | Default branch: main; local repository branch `main` | recorded |
| Source scale | Source scale command: moon info | repeatable |
| History | History count command: git rev-list --count HEAD | repeatable |
| CI | CI workflow: .github/workflows/check.yml | checked in |
| Generated interfaces | Generated-interface gate: git diff --exit-code; CI runs it after `moon info` | checked in |
| Documentation integrity | `node tools/verify-docs.mjs` checks required files, README links, CLI names, and these audit fields | repeatable |
| Formatting and quality | `moon fmt --check`, `moon check --target all --deny-warn`, and `moon test --target all --deny-warn` are CI steps | checked in |

This is a self-audit, not an external certification. Re-run the commands from [CONTRIBUTING.md](../CONTRIBUTING.md) on the candidate revision and record their output with any submission.
