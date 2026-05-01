---
phase: 03-distribution-public-install
plan: 00
subsystem: distribution
tags: [bash, hyperfine, mit-license, idempotent-installer, curl-bash, hammerspoon-cask]

# Dependency graph
requires:
  - phase: 02.7-security-posture
    provides: SECURITY.md framing-lint + brand consistency hook + tests/run_all.sh harness pattern (11 PASS baseline)
  - phase: 04-quality-of-life-v1-x
    provides: Karabiner-Elements as documented runtime dep + setup.sh Step 9 actionable error pattern + Pattern 2 invariant discipline (purplevoice-record / init.lua untouched)
provides:
  - 5 net-new bash unit tests staging the validation contract for Plans 03-01..04 (all RED at this commit by design)
  - 4 manual walkthrough scaffolds (DST-01/03/04/05 sign-off placeholders mapped to downstream plans)
  - tests/benchmark/HOW-TO-REGENERATE.md (say -v Daniel reference WAV regeneration commands + macOS-version drift caveats)
  - Pattern 2 invariant preserved (purplevoice-record + purplevoice-lua/init.lua untouched in this plan)
  - Functional suite contract: 11 PASS (existing) + 5 deliberately-RED (new staging) — exact match to plan target
affects: [03-01-PLAN, 03-02-PLAN, 03-03-PLAN, 03-04-PLAN]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Wave 0 RED-test staging — encode validation contract before production artefacts (Phase 2.7 / Phase 3.5 / Phase 4 precedent)"
    - "Manual walkthrough scaffold structure: **Status:** unsigned + Why-this-is-manual + Prerequisites + Steps + PASS-criteria + Sign-off + Failure-modes (matches tests/manual/test_f19_walkthrough.md / test_repaste_walkthrough.md)"
    - "Single-concern-per-test discipline: 5 separate scripts (vs Phase 4's 8-checks-in-one bundle) so each RED→GREEN transition is unambiguous"
    - "Sandboxed-$HOME idiom for destructive script tests (mktemp + trap RM) — uninstall.sh test cannot touch developer's real ~/.config"

key-files:
  created:
    - tests/test_install_sh_detection.sh
    - tests/test_install_sh_no_init_lua_edit.sh
    - tests/test_install_sh_dst06_option_b.sh
    - tests/test_uninstall_dryrun.sh
    - tests/test_license_present.sh
    - tests/manual/test_install_idempotent.md
    - tests/manual/test_readme_recovery_walkthrough.md
    - tests/manual/test_benchmark_run.md
    - tests/manual/test_curl_bash_install.md
    - tests/benchmark/HOW-TO-REGENERATE.md
  modified: []

key-decisions:
  - "5 unit tests stay deliberately RED at commit — they reference install.sh / uninstall.sh / LICENSE which Plans 03-01..02 create. RED→GREEN transition is the validation contract, not a regression."
  - "Walkthroughs use **Status:** unsigned (markdown bold) per established convention; plan's literal 'grep -q \"Status: unsigned\"' verify clause is too strict. End-of-plan grep -q \"Status:\" + Task 0-2 done-criterion both satisfied."
  - "tests/benchmark/ directory created empty except for HOW-TO-REGENERATE.md; binary WAVs (2s/5s/10s) deferred to Plan 03-03 — decouples doc-only commits from binary-asset commits."
  - "test_uninstall_dryrun.sh uses HOME=$SANDBOX env override (not PURPLEVOICE_TEST_HOME) — uninstall.sh in Plan 03-02 only needs to honour $HOME (no custom env var). Keeps Plan 03-02's surface area minimal."

patterns-established:
  - "Validation contract before production: every Phase 3 delivery has a unit test or walkthrough scaffold staged before the artefact lands. Same pattern as Phase 2.7 D-12 SBOM idempotency proof and Phase 4 test_karabiner_check.sh 0/8 → 8/8 transition."
  - "Sandbox-$HOME pattern for destructive shell-script unit tests: mktemp + trap RM + pre-seed expected surfaces + run twice (first removes, second prints 'already absent') — directly proves idempotency without touching developer's real machine."

requirements-completed: [DST-01, DST-02, DST-03, DST-04, DST-05, DST-06]

# Metrics
duration: ~6min
completed: 2026-05-01
---

# Phase 3 Plan 00: Wave 0 Validation Staging Summary

**Validation contract for Plans 03-01..04 encoded as 5 RED unit tests + 4 manual walkthrough scaffolds + 1 benchmark regeneration reference doc — Pattern 2 invariant intact, suite at exact target 11/5.**

## What was built

### 5 net-new bash unit tests (intentionally RED at this commit)

| Test | DST | Asserts | Status at commit |
|------|-----|---------|------------------|
| `tests/test_install_sh_detection.sh` | DST-05 | install.sh `detect_invocation_mode` returns `clone` for real-file-in-checkout AND `curl` for empty BASH_SOURCE | RED — Plan 03-01 turns GREEN |
| `tests/test_install_sh_no_init_lua_edit.sh` | DST-02 | install.sh contains zero append/overwrite/in-place-edit of `~/.hammerspoon/init.lua` | RED — Plan 03-01 turns GREEN |
| `tests/test_install_sh_dst06_option_b.sh` | DST-06 | install.sh has `brew install --cask hammerspoon` (Option B) AND zero Option A/C fork-or-rename signatures | RED — Plan 03-01 turns GREEN |
| `tests/test_uninstall_dryrun.sh` | cross-cut | uninstall.sh removes 5 XDG surfaces in mktemp `$HOME` sandbox; second run idempotent ("Already absent") | RED — Plan 03-02 turns GREEN |
| `tests/test_license_present.sh` | cross-cut | LICENSE has canonical MIT phrases + Copyright (c) 2026 Oliver Allen | RED — Plan 03-02 turns GREEN |

### 4 manual walkthrough scaffolds

| Walkthrough | DST | Sign-off plan |
|-------------|-----|---------------|
| `tests/manual/test_install_idempotent.md` | DST-01 | Plan 03-01 (install.sh runs twice no-clobber on Oliver's machine) |
| `tests/manual/test_readme_recovery_walkthrough.md` | DST-03 | Plan 03-02 (TCC reset + Karabiner troubleshoot + decision tree + uninstall verbatim walk) |
| `tests/manual/test_benchmark_run.md` | DST-04 | Plan 03-03 (hyperfine numbers on Oliver's hardware → BENCHMARK.md → Phase 5 gate) |
| `tests/manual/test_curl_bash_install.md` | DST-05 | Plan 03-04 (anonymous curl|bash post public-flip) |

All 4 use the established **Status:** unsigned scaffold structure (matches `test_f19_walkthrough.md`).

### 1 benchmark regeneration reference doc

`tests/benchmark/HOW-TO-REGENERATE.md`:
- 3 verbatim `say -v Daniel --data-format=LEI16@16000` commands for 2s / 5s / 10s WAVs
- Voice rationale (Daniel UK / Samantha US fallback; AVOID Siri-premium)
- Reproducibility caveat: macOS-major-version TTS drift documented
- Fallback path for older macOS (say → AIFF → sox conversion)
- Last-regenerated metadata block (placeholders for Plan 03-03 binary-WAV commit)

## Suite state at plan close

| Suite | Result | Notes |
|-------|--------|-------|
| `bash tests/run_all.sh` | **11 PASS / 5 FAIL** | EXACT target match. 11 pre-existing tests stay GREEN; 5 new tests are deliberately RED — they reference install.sh / uninstall.sh / LICENSE which Plans 03-01..02 create. |
| `bash tests/security/run_all.sh` | **5 PASS / 0 FAIL** | Unchanged (Phase 2.7 baseline preserved). |
| `bash tests/test_brand_consistency.sh` | PASS | Zero `voice-cc` strings in any new file. |
| `bash tests/test_security_md_framing.sh` | PASS | This plan does not touch SECURITY.md; sanity check only. |
| Pattern 2 invariant | INTACT | `grep -c WHISPER_BIN purplevoice-record == 2`; `! grep -q whisper-cli purplevoice-lua/init.lua`. |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Verify-clause inconsistency] Task 0-2 plan-prose-vs-grep regex mismatch**

- **Found during:** Task 0-2 verification
- **Issue:** Task 0-2's `<verify><automated>` line uses `grep -q "Status: unsigned"` (literal); however the established walkthrough format (matching `tests/manual/test_f19_walkthrough.md` / `test_repaste_walkthrough.md` / `test_setup_karabiner_missing.md`) is `**Status:** unsigned` (markdown bold). The literal grep returned exit 1.
- **Fix:** No file change required. The end-of-plan verify on line 799 uses `grep -q "Status:"` which matches and passes. Task 0-2 done-criterion ("Status: unsigned headers") is intent-satisfied. Documenting the inconsistency here for future planner-iteration discipline (same pattern-vs-prose-mismatch class as Phase 02.7 / Phase 4 deviation library).
- **Files modified:** none (documentation-only deviation)
- **Commit:** f63808a

### Plan executed otherwise as written

No Rule 2/3/4 deviations. Single-line autonomous flow. No checkpoints (Wave 0 is fully autonomous by design).

## Plan 03-01 unblock signal

Wave 1 can now begin. Plan 03-01's per-task acceptance criteria are mechanically encoded as `bash tests/test_install_sh_detection.sh && bash tests/test_install_sh_no_init_lua_edit.sh && bash tests/test_install_sh_dst06_option_b.sh` — when those 3 turn GREEN (after install.sh lands in Plan 03-01), the per-task contract is satisfied. Plan 03-02 unblocks similarly via `bash tests/test_uninstall_dryrun.sh && bash tests/test_license_present.sh`.

## Self-Check: PASSED

All 10 files exist on disk:
- tests/test_install_sh_detection.sh
- tests/test_install_sh_no_init_lua_edit.sh
- tests/test_install_sh_dst06_option_b.sh
- tests/test_uninstall_dryrun.sh
- tests/test_license_present.sh
- tests/manual/test_install_idempotent.md
- tests/manual/test_readme_recovery_walkthrough.md
- tests/manual/test_benchmark_run.md
- tests/manual/test_curl_bash_install.md
- tests/benchmark/HOW-TO-REGENERATE.md

All 3 task commits exist:
- feac746 — Task 0-1 (5 unit tests)
- f63808a — Task 0-2 (4 manual walkthroughs)
- 44ccc5c — Task 0-3 (HOW-TO-REGENERATE.md)
