# OSC 2026 self-audit

Audit date: 2026-08-21

| Check | Evidence | Status |
| --- | --- | --- |
| License | License: Apache-2.0; checked-in `LICENSE` | recorded |
| Default branch | Default branch: main; local repository branch `main` is required by `scripts/osc-audit.ps1` | repeatable locally |
| Remote default branch | Remote default branch: deferred until publish; run `scripts/osc-audit.ps1 -CheckRemoteDefault` against `origin` | pending publication |
| Source scale | Source scale command: `scripts/line-count.ps1`; tracked `*.mbt` files only, with tests reported separately | repeatable |
| History | History count command: git rev-list --count HEAD; the audit requires at least 10 revisions and reports that commit contents still need human inspection for meaningful scope | repeatable |
| CI | `.github/workflows/check.yml` runs format/check plus wasm-gc tests on Ubuntu, macOS, and Windows; native tests run on Ubuntu; `.github/workflows/benchmark.yml` records the fixed benchmark | checked in |
| Generated interfaces | Generated-interface gate: git diff --exit-code; CI runs it after `moon info` | checked in |
| Documentation integrity | `node --test tools/verify-docs.test.mjs` and `node tools/verify-docs.mjs` check required files, contained README links, CLI names, and these audit fields | repeatable |
| Formatting and quality | `moon fmt --check`, `moon check --target all --deny-warn`, and target-specific `moon test --target ... --deny-warn` are CI steps; local wasm-gc verification passes | checked in |

Run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/osc-audit.ps1` from the local candidate `main` branch. This is a self-audit, not an external certification: it can verify only local repository evidence unless `-CheckRemoteDefault` is used after a remote is published. Re-run the commands from [CONTRIBUTING.md](../CONTRIBUTING.md) on the candidate revision and record their output with any submission.
