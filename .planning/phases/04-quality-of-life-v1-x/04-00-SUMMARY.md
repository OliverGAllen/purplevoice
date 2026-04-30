---
phase: 04-quality-of-life-v1-x
plan: 00
subsystem: tests-and-requirements-staging
tags: [staging, wave-0, tests, requirements, qol-01, qol-new-01, karabiner, f19, re-paste]
status: complete
completed: 2026-04-30
requirements:
  - QOL-01
  - QOL-NEW-01
dependency-graph:
  requires:
    - tests/run_all.sh (alphabetical test discovery)
    - tests/test_hud_env_off.sh (Wave-0 RED-at-commit precedent)
    - tests/manual/test_clipboard_restore.md (canonical scaffold structure)
    - .planning/REQUIREMENTS.md (current v2 stub for QOL-01)
    - 04-CONTEXT.md decisions D-01..D-10
    - 04-RESEARCH.md §6 (verbatim test_karabiner_check.sh content)
  provides:
    - tests/test_karabiner_check.sh — 8 string-level Phase 4 wiring assertions (RED at Wave 0; turns GREEN as Plans 04-01 + 04-02 land)
    - tests/manual/test_repaste_walkthrough.md — QOL-01 manual sign-off scaffold (3 PASS markers)
    - tests/manual/test_f19_walkthrough.md — QOL-NEW-01 positive-path manual scaffold (5 PASS markers + 200ms tuning anchor)
    - tests/manual/test_setup_karabiner_missing.md — QOL-NEW-01 negative-control manual scaffold (BASELINE-OK + 2 PASS markers)
    - .planning/REQUIREMENTS.md — QOL-01 promoted to v1 with concrete language; QOL-NEW-01 added; v1 coverage 39 → 41; v2 QOL stubs rebranded to `purplevoice` namespace
  affects:
    - Plan 04-01 (lua-core) — must turn checks 6, 7, 8 of test_karabiner_check.sh GREEN; lands cmd+shift+v binding + F19 binding + cmd+shift+e removal in init.lua
    - Plan 04-02 (karabiner-docs) — must turn checks 1-5 of test_karabiner_check.sh GREEN; lands assets/karabiner-fn-to-f19.json + setup.sh Step 9 + README/SECURITY.md updates + REQUIREMENTS.md Pending → Complete flip
tech-stack:
  added: []
  patterns:
    - bash test-script idiom (set -uo pipefail + cd-to-repo-root + FAIL counter + per-check echo)
    - Manual walkthrough scaffold (H1 + Requirement + Prerequisites + Steps + Expected Outcome + Failure modes + Sign-off)
    - jq null-default form (jq -r '.path // empty') for safe field extraction
    - Defensive [ -f "$FILE" ] re-guards on jq calls (prevents jq errors when prior check already failed)
key-files:
  created:
    - tests/test_karabiner_check.sh (98 lines)
    - tests/manual/test_repaste_walkthrough.md (45 lines)
    - tests/manual/test_f19_walkthrough.md (45 lines)
    - tests/manual/test_setup_karabiner_missing.md (50 lines)
  modified:
    - .planning/REQUIREMENTS.md (+19 lines, -12 lines net; QOL-01 promoted, QOL-NEW-01 added, v2 stubs rebranded, coverage stats refreshed, traceability extended)
decisions:
  - "tests/test_karabiner_check.sh is RED at Wave 0 by design — 6 checks fail at commit because assets/karabiner-fn-to-f19.json + setup.sh Step 9 + init.lua F19/cmd+shift+v bindings do not yet exist. This is the contract handoff to Plans 04-01 + 04-02. The plan's acceptance criterion is 'test FILE exists + has 8 checks + run_all.sh discovers it', NOT 'test passes'."
  - "Defensive [ -f \"$KARABINER_JSON\" ] re-guards added on checks 2 and 3 of test_karabiner_check.sh — prevents jq errors when check 1 has already failed but FAIL is reset to 0 between checks. Same pattern as RESEARCH §6 verbatim content; no functional deviation."
  - "Per CONTEXT.md D-04 nil-state behaviour: brief alert (`hs.alert.show(\"PurpleVoice: nothing to re-paste yet\", 1.5)`) chosen over silent no-op. Manual walkthrough test_repaste_walkthrough.md PASS-3 verifies this empirically post-Hammerspoon-reload."
  - "Per CONTEXT.md D-10 deferred-items rebrand: v2 QOL-03/04/05 stubs updated from voice-cc → purplevoice paths/vars even though they remain Deferred. Brand-consistency lint stays GREEN with no legacy strings in active or stub requirements. QOL-02 unchanged (no path/var to rebrand)."
  - "QOL-01 + QOL-NEW-01 left as `[ ]` Pending in v1 subsection — Plan 04-02 closure task flips both to `[x]` Complete via `gsd-tools requirements mark-complete`. Wave 0 stages stubs only; closure is Wave 2's responsibility."
metrics:
  duration: ~12 minutes
  completed: 2026-04-30
  tasks-completed: 5
  files-changed: 5 (4 created + 1 modified)
  commits: 5 (one per task; --no-verify per parallel-execution convention)
---

# Phase 4 Plan 00: Staging Summary

**Stage all Phase 4 verification scaffolds (1 unit test + 3 manual walkthroughs + REQUIREMENTS.md QOL-01/QOL-NEW-01 stubs) in a single Wave 0 commit so Plans 04-01 + 04-02 implement against contracts that already exist on disk.**

## What This Plan Did

Phase 4 scope = QOL-01 (cmd+shift+v re-paste hotkey) + QOL-NEW-01 (F19 alt hotkey via Karabiner fn-remap), per CONTEXT.md D-01 trigger validation. Plan 04-00 lands the validation gates BEFORE any production code changes — mirroring the Phase 02-00 / Phase 03.5-00 Wave-0 precedent. Tests + REQUIREMENTS.md stubs land first; implementation plans turn the tests GREEN.

Five tasks executed autonomously, one per task commit:

| Task | Output | Commit |
|------|--------|--------|
| 0-1 | tests/test_karabiner_check.sh (8 string-level checks; RED at Wave 0) | `fdf2cd8` |
| 0-2 | tests/manual/test_repaste_walkthrough.md (QOL-01; 3 PASS markers) | `738976b` |
| 0-3 | tests/manual/test_f19_walkthrough.md (QOL-NEW-01 positive; 5 PASS markers) | `a28f846` |
| 0-4 | tests/manual/test_setup_karabiner_missing.md (QOL-NEW-01 negative-control; BASELINE-OK + 2 PASS) | `bde15e2` |
| 0-5 | .planning/REQUIREMENTS.md (QOL-01 promoted, QOL-NEW-01 added, v2 stubs rebranded, coverage 39→41) | `8f54448` |

## Intentional RED-at-Wave-0 State

**`tests/test_karabiner_check.sh` fails 6 of 8 checks at commit. This is BY DESIGN.**

The 8 checks assert wiring that lands across Plans 04-01 + 04-02:

| # | Check | Plan that turns it GREEN |
|---|-------|--------------------------|
| 1 | `assets/karabiner-fn-to-f19.json` exists + parses as JSON | Plan 04-02 |
| 2 | JSON has `title` + `rules[]` (length ≥ 1) | Plan 04-02 |
| 3 | `.rules[0].manipulators[0].from.key_code == "fn"` AND `.to_if_held_down[0].key_code == "f19"` | Plan 04-02 |
| 4 | `setup.sh` references `Karabiner-Elements.app` | Plan 04-02 |
| 5 | `setup.sh` references `karabiner-fn-to-f19.json` | Plan 04-02 |
| 6 | `purplevoice-lua/init.lua` binds F19 with empty modifier table | **Plan 04-01** |
| 7 | `purplevoice-lua/init.lua` binds cmd+shift+v for re-paste | **Plan 04-01** |
| 8 | `purplevoice-lua/init.lua` does NOT bind cmd+shift+e (D-05 removal) | **Plan 04-01** |

**Final state after both plans land: 8/8 GREEN.**

The plan's acceptance criterion was "test FILE exists + has 8 checks + run_all.sh discovers it", NOT "test passes". This is the contract handoff to downstream plans.

## Suite State at Plan Close

| Suite | Result | Notes |
|-------|--------|-------|
| `bash tests/run_all.sh` | **10 PASS / 1 FAIL** (exit 1) | New `test_karabiner_check.sh` is the expected RED; all 10 prior tests still GREEN |
| `bash tests/security/run_all.sh` | 5 PASS / 0 FAIL (exit 0) | No security infrastructure touched; suite unchanged |
| `bash tests/test_brand_consistency.sh` | PASS (exit 0) | New files contain no legacy `voice-cc` strings; v2 stub rebrand to `purplevoice` namespace was a brand-hygiene improvement |
| `bash tests/test_security_md_framing.sh` | PASS (exit 0) | SECURITY.md not touched |

## Pattern 2 Invariants (Unchanged)

| Invariant | Status |
|-----------|--------|
| `grep -c WHISPER_BIN purplevoice-record == 2` | OK (single assignment + single use inside `transcribe()`) |
| `! grep -q whisper-cli purplevoice-lua/init.lua` | OK (init.lua stays whisper-cli-free) |

Plan 04-00 did not modify `purplevoice-record` or `purplevoice-lua/init.lua` — invariants intact by construction.

## REQUIREMENTS.md Closure Status

**QOL-01 and QOL-NEW-01 are `[ ]` Pending — NOT `[x]` Complete.** Wave 0 stages stubs; closure is Plan 04-02's responsibility (uses `gsd-tools requirements mark-complete QOL-01 QOL-NEW-01` after Plans 04-01 + 04-02 land their production code and the manual walkthroughs are signed off live by Oliver).

Coverage stats:
- v1 requirements: 39 → 41 (added QOL-01 + QOL-NEW-01)
- Mapped to phases: 41 / 41 (100%)
- v2 requirements: 7 → 6 (QOL-01 promoted out)
- Per-phase counts: new Phase 4 row — 2 requirements (QOL-01, QOL-NEW-01) — Pending

## Deviations from Plan

**None.** Plan executed exactly as written. The defensive `[ -f "$KARABINER_JSON" ]` re-guards on checks 2 + 3 of `test_karabiner_check.sh` were called out in the plan's `<reference_data>` block as "a defensive correctness fix, not a deviation" — the plan explicitly authored them as part of the verbatim content. No Rule 1/2/3 auto-fixes; no Rule 4 architectural decisions; no authentication gates.

## Handoff to Plan 04-01

Plan 04-01 (Lua core) implements `purplevoice-lua/init.lua` changes:

1. **Adds** `local lastTranscript = nil` at module scope.
2. **Adds** a `repaste()` function with nil-check pattern: `if lastTranscript then pasteWithRestore(lastTranscript) else hs.alert.show("PurpleVoice: nothing to re-paste yet", 1.5) end` (per CONTEXT.md D-04).
3. **Adds** `hs.hotkey.bind({"cmd", "shift"}, "v", repaste)` near the existing hotkey block.
4. **Replaces** the existing `hs.hotkey.bind({"cmd", "shift"}, "e", onPress, onRelease)` with `hs.hotkey.bind({}, "f19", onPress, onRelease)` (per CONTEXT.md D-05). The cmd+shift+e binding is REMOVED, not supplemented.
5. **Caches** `lastTranscript = transcript` inside `pasteWithRestore()` AFTER the `cmd+v` keystroke fires (per CONTEXT.md D-03; success-path cache point).
6. **Updates** the module-load alert string from "cmd+shift+e" to "F19 to record, ⌘⇧V to re-paste".

After Plan 04-01: `bash tests/test_karabiner_check.sh` checks 6, 7, 8 GREEN (3 of 8). Checks 1-5 still RED (Plan 04-02's responsibility).

## Handoff to Plan 04-02

Plan 04-02 (Karabiner integration + docs closure) implements:

1. **Creates** `assets/karabiner-fn-to-f19.json` with the documented complex-modification rule (fn → F19 with 200ms threshold; D-06).
2. **Adds** `setup.sh` Step 9 — checks for `/Applications/Karabiner-Elements.app`, prints actionable error + exits 1 when absent (D-07); honours `PURPLEVOICE_OFFLINE=1` mode (D-08).
3. **Updates** README.md to document the Karabiner dependency in the install flow.
4. **Updates** SECURITY.md SBOM scope disclaimer to acknowledge Karabiner-Elements alongside Hammerspoon as a Pitfall-2-scoped-out runtime dependency.
5. **Updates** all `tests/manual/test_*.md` references from cmd+shift+e to F19 (mechanical text replacements).
6. **Closes** REQUIREMENTS.md QOL-01 + QOL-NEW-01 from `[ ]` Pending to `[x]` Complete via `gsd-tools requirements mark-complete`.
7. **Updates** ROADMAP.md Phase 4 progress row.

After Plan 04-02: `bash tests/test_karabiner_check.sh` 8/8 GREEN; functional suite 11/0; security suite 5/0; brand consistency GREEN; framing lint GREEN. Phase 4 ready for verifier sign-off.

## Self-Check: PASSED

Files exist (verified):
- FOUND: tests/test_karabiner_check.sh
- FOUND: tests/manual/test_repaste_walkthrough.md
- FOUND: tests/manual/test_f19_walkthrough.md
- FOUND: tests/manual/test_setup_karabiner_missing.md
- FOUND: .planning/REQUIREMENTS.md (modified)

Commits exist (verified via `git log --oneline`):
- FOUND: fdf2cd8 (Task 0-1)
- FOUND: 738976b (Task 0-2)
- FOUND: a28f846 (Task 0-3)
- FOUND: bde15e2 (Task 0-4)
- FOUND: 8f54448 (Task 0-5)

Suite state verified:
- FOUND: 10 PASS + 1 FAIL functional (`test_karabiner_check.sh` RED-at-Wave-0)
- FOUND: 5 PASS + 0 FAIL security
- FOUND: brand consistency GREEN
- FOUND: Pattern 2 invariants intact

All success criteria from PLAN.md `<success_criteria>` block satisfied.
