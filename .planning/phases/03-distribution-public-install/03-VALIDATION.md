---
phase: 03
slug: distribution-public-install
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-01
---

# Phase 03 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash test scripts (no test runner — each `tests/test_*.sh` is standalone, returns 0/1; `tests/security/verify_*.sh` for security tier) |
| **Config file** | None — `tests/run_all.sh` iterates `tests/test_*.sh` alphabetically |
| **Quick run command** | `bash tests/run_all.sh` |
| **Full suite command** | `bash tests/run_all.sh && bash tests/security/run_all.sh` |
| **Estimated runtime** | ~5s quick / ~35s full |
| **Benchmark runner** | `bash tests/benchmark/run.sh` (Wave 3-time activation; not in default suites; needs `brew install hyperfine` first) |

Baseline at Phase 3 start: **11/0 functional + 5/0 security.** Phase 3 target: **13/0 functional + 5/0 security** (some tests may fold into existing brand-consistency check; minimum 13/0 if minimal-add path).

---

## Sampling Rate

- **After every task commit:** `bash tests/run_all.sh` (~5 seconds; all functional tests must be green)
- **After every plan wave:** `bash tests/run_all.sh && bash tests/security/run_all.sh` (full suite)
- **Wave 3 (benchmarks):** `bash tests/benchmark/run.sh` produces hyperfine JSON for 3 reference WAVs; manual sign-off in `tests/manual/test_benchmark_run.md`
- **Wave 4 (public flip):** Live walkthrough of `curl -fsSL ... | bash` from a fresh terminal AFTER the public flip; manual sign-off in `tests/manual/test_curl_bash_install.md`
- **Before `/gsd:verify-work`:** Full suite green + 4 manual walkthroughs signed off (install_idempotent, readme_recovery, benchmark_run, curl_bash_install)
- **Max feedback latency:** ~5 seconds for the unit suite

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 03-00-01 | 00 | 0 | DST-05 | unit (mock $0) | `bash tests/test_install_sh_detection.sh` | ❌ W0 creates | ⬜ pending |
| 03-00-02 | 00 | 0 | DST-02 | unit (negative) | `bash tests/test_install_sh_no_init_lua_edit.sh` (or fold into brand-consistency) | ❌ W0 creates | ⬜ pending |
| 03-00-03 | 00 | 0 | DST-06 | unit (presence) | `bash tests/test_install_sh_dst06_option_b.sh` (or fold into brand-consistency) | ❌ W0 creates | ⬜ pending |
| 03-00-04 | 00 | 0 | cross-cut | unit (sandbox) | `bash tests/test_uninstall_dryrun.sh` | ❌ W0 creates | ⬜ pending |
| 03-00-05 | 00 | 0 | cross-cut | unit (presence) | `bash tests/test_license_present.sh` | ❌ W0 creates | ⬜ pending |
| 03-00-06 | 00 | 0 | DST-01 | manual scaffold | `tests/manual/test_install_idempotent.md` exists | ❌ W0 creates | ⬜ pending |
| 03-00-07 | 00 | 0 | DST-03 | manual scaffold | `tests/manual/test_readme_recovery_walkthrough.md` exists | ❌ W0 creates | ⬜ pending |
| 03-00-08 | 00 | 0 | DST-04 | manual scaffold | `tests/manual/test_benchmark_run.md` exists | ❌ W0 creates | ⬜ pending |
| 03-00-09 | 00 | 0 | DST-05 | manual scaffold | `tests/manual/test_curl_bash_install.md` exists | ❌ W0 creates | ⬜ pending |
| 03-00-10 | 00 | 0 | DST-04 | doc (regen guide) | `tests/benchmark/HOW-TO-REGENERATE.md` exists | ❌ W0 creates | ⬜ pending |
| 03-01-01 | 01 | 1 | DST-13 (sweep) | doc (typo fix) | `! grep -rq 'oliverallen/' setup.sh SECURITY.md` (excluding history) | ✅ W0 | ⬜ pending |
| 03-01-02 | 01 | 1 | DST-01, DST-05 | unit (rename) | `test -f install.sh && ! test -f setup.sh && bash tests/test_install_sh_detection.sh` | ✅ W0 | ⬜ pending |
| 03-01-03 | 01 | 1 | DST-06 | unit (Option B) | `bash tests/test_install_sh_dst06_option_b.sh` | ✅ W0 | ⬜ pending |
| 03-01-04 | 01 | 1 | DST-02 | unit (no init.lua edit) | `bash tests/test_install_sh_no_init_lua_edit.sh` | ✅ W0 | ⬜ pending |
| 03-01-05 | 01 | 1 | DST-01 | manual walkthrough | `tests/manual/test_install_idempotent.md` (live sign-off) | ✅ W0 | ⬜ pending |
| 03-02-01 | 02 | 2 | cross-cut | unit (LICENSE) | `bash tests/test_license_present.sh` | ✅ W0 | ⬜ pending |
| 03-02-02 | 02 | 2 | DST-03 | doc (rewrite) | `grep -q '^## Quickstart' README.md && grep -q '^## Detailed Install' README.md && grep -q 'OliverGAllen/purplevoice' README.md` | ✅ W0 | ⬜ pending |
| 03-02-03 | 02 | 2 | cross-cut | unit (uninstall) | `bash tests/test_uninstall_dryrun.sh` | ✅ W0 | ⬜ pending |
| 03-02-04 | 02 | 2 | DST-03 | manual walkthrough | `tests/manual/test_readme_recovery_walkthrough.md` (live sign-off) | ✅ W0 | ⬜ pending |
| 03-03-01 | 03 | 3 | DST-04 | unit (3 WAVs + script) | `test -f tests/benchmark/2s.wav && test -f tests/benchmark/5s.wav && test -f tests/benchmark/10s.wav && test -x tests/benchmark/run.sh` | ❌ W0/Plan-03 creates | ⬜ pending |
| 03-03-02 | 03 | 3 | DST-04 | manual walkthrough | `tests/manual/test_benchmark_run.md` (live: Oliver runs benchmarks; numbers committed to BENCHMARK.md) | ✅ W0 | ⬜ pending |
| 03-03-03 | 03 | 3 | DST-04 | doc (Phase 5 trigger) | `grep -E 'p50.*2.*p95.*4' BENCHMARK.md` (the trigger threshold rule documented) | (Plan-03 creates) | ⬜ pending |
| 03-04-01 | 04 | 4 | DST-13 (pre-flip) | regression | `bash tests/run_all.sh && bash tests/security/run_all.sh` (all suites GREEN before flip) | ✅ existing | ⬜ pending |
| 03-04-02 | 04 | 4 | DST-05 | flip operation | `gh repo edit --visibility public --accept-visibility-change-consequences` (one-shot) | ✅ gh CLI | ⬜ pending |
| 03-04-03 | 04 | 4 | DST-05 | smoke (post-flip) | `curl -fsSL https://raw.githubusercontent.com/OliverGAllen/purplevoice/main/install.sh | head -5` (anonymous; expect 200 + bash content) | ✅ curl | ⬜ pending |
| 03-04-04 | 04 | 4 | DST-05 | manual walkthrough | `tests/manual/test_curl_bash_install.md` (live: Oliver runs the one-liner from a fresh terminal/machine; signs off) | ✅ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/test_install_sh_detection.sh` — sources install.sh detection function with mocked `$0`; asserts curl-vs-clone branch returns correct mode for both inputs
- [ ] `tests/test_install_sh_no_init_lua_edit.sh` — greps install.sh; asserts zero writes to `~/.hammerspoon/init.lua` (DST-02: print, never auto-append)
- [ ] `tests/test_install_sh_dst06_option_b.sh` — greps install.sh; asserts `brew install --cask hammerspoon` (Option B path); asserts no `.app` rename / fork logic exists
- [ ] `tests/test_uninstall_dryrun.sh` — runs uninstall.sh in a sandboxed `$HOME` (env override `PURPLEVOICE_TEST_HOME`); asserts XDG dirs removed; re-runs and asserts "already removed" path; restores
- [ ] `tests/test_license_present.sh` — greps `LICENSE` for `MIT License` + canonical phrases (`Permission is hereby granted`) + `Oliver Allen` + `2026`
- [ ] `tests/manual/test_install_idempotent.md` — manual walkthrough scaffold for DST-01 (Oliver runs install.sh twice, signs off no-clobber)
- [ ] `tests/manual/test_readme_recovery_walkthrough.md` — manual walkthrough scaffold for DST-03 (Oliver follows README recovery steps verbatim, signs off)
- [ ] `tests/manual/test_benchmark_run.md` — manual walkthrough scaffold for DST-04 (Oliver runs `bash tests/benchmark/run.sh`, commits results to BENCHMARK.md, signs off)
- [ ] `tests/manual/test_curl_bash_install.md` — manual walkthrough scaffold for DST-05 (Oliver runs `curl ... | bash` from a fresh terminal post-public-flip, signs off)
- [ ] `tests/benchmark/HOW-TO-REGENERATE.md` — documents the `say -v Daniel --data-format=LEI16@16000 ...` reference WAV generation commands + macOS-version caveats

*Framework install:* None — bash + grep + jq already available. `brew install hyperfine` is a Wave 3 prep step (not Wave 0).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| install.sh re-runs cleanly with no-clobber on a real machine state | DST-01 | Sandbox can't fully replicate real `~/.hammerspoon/init.lua` + `~/.config/purplevoice/vocab.txt` user-edited state | `tests/manual/test_install_idempotent.md` — Oliver runs `bash install.sh` twice on his actual machine; verifies no config files were rewritten; signs off |
| README recovery procedures actually work end-to-end on macOS | DST-03 | Requires real TCC state, real Karabiner UI, real Hammerspoon reload — impossible to mock | `tests/manual/test_readme_recovery_walkthrough.md` — Oliver follows each recovery step from README verbatim (tccutil reset; Karabiner Event Viewer key-code check; "lost my hotkeys" decision tree); signs off each |
| hyperfine benchmark numbers on Oliver's actual hardware | DST-04 | Numbers are hardware-specific; can't be mocked or pre-computed; must run on the real machine to be meaningful | `tests/manual/test_benchmark_run.md` — Oliver runs `bash tests/benchmark/run.sh`; ingests JSON output via `tests/benchmark/quantiles.sh` (jq-based p95 calc); commits results + Phase-5 trigger eval to BENCHMARK.md; signs off |
| Public `curl|bash` one-liner works from anonymous terminal post-flip | DST-05 | Requires the live public-flipped repo + a fresh terminal that hasn't authenticated to GitHub via Oliver's gh token; only end-to-end real-world test proves DST-05 | `tests/manual/test_curl_bash_install.md` — Oliver opens an incognito browser / fresh terminal / fresh VM; runs the curl one-liner; verifies install.sh executes correctly; signs off. Critical: tested AFTER `gh repo edit --visibility public --accept-visibility-change-consequences` lands |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify (manual walkthroughs paired with automated string-checks per per-task map)
- [ ] Wave 0 covers all MISSING references (5 unit tests + 4 manual scaffolds + 1 HOW-TO-REGENERATE doc)
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s (bash test suite)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
