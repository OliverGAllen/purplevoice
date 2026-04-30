---
phase: 04-quality-of-life-v1-x
plan: 01
subsystem: lua-core-f19-and-repaste
tags: [lua-core, qol-01, qol-new-01, f19, repaste, lastTranscript, hammerspoon, init-lua]
status: complete
completed: 2026-04-30
requirements:
  - QOL-01
  - QOL-NEW-01
dependency-graph:
  requires:
    - purplevoice-lua/init.lua (Phase 2/2.5/2.7/3.5 hardened module — read in full pre-edit)
    - tests/test_karabiner_check.sh (Plan 04-00 RED-at-Wave-0 contract; checks 6/7/8 turn GREEN here)
    - 04-CONTEXT.md decisions D-02 (cmd+shift+v), D-03 (in-memory only), D-04 (brief-alert nil-state), D-05 (F19 replaces cmd+shift+e — no fallback)
    - 04-RESEARCH.md §1 (repaste pattern), §3 (F19 binding empty modifier table + lowercase), Pattern 4 (cache inside pasteWithRestore, NOT handleExit)
    - 04-00-SUMMARY.md (Wave 0 handoff specifying checks 6/7/8 are this plan's responsibility)
  provides:
    - "purplevoice-lua/init.lua — F19 push-and-hold binding (replaces cmd+shift+e per D-05); cmd+shift+v re-paste binding (QOL-01); lastTranscript module-scope cache; repaste() function with nil-state brief alert; updated module-load alert (Unicode ⌘⇧V); updated line-2 header (F19 + Karabiner)"
    - "test_karabiner_check.sh advance: 0/8 GREEN → 3/8 GREEN (checks 6, 7, 8 GREEN; checks 1, 4, 5 still RED — handoff to Plan 04-02)"
  affects:
    - "Plan 04-02 (karabiner-docs) — must land assets/karabiner-fn-to-f19.json + setup.sh Step 9 to flip checks 1, 4, 5 GREEN; then live walkthroughs for Task 1-5 deferred sign-off"
    - "Live re-paste walkthrough (tests/manual/test_repaste_walkthrough.md) deferred to Plan 04-02 phase-gate sign-off — cannot be exercised end-to-end without Karabiner-installed F19 trigger"
tech-stack:
  added: []
  patterns:
    - "Lua module-scope state cluster (isRecording / currentTask / lastTranscript) — in-memory only; lost on Hammerspoon reload by design (D-03)"
    - "Cache-on-success-path discipline — lastTranscript = transcript inside pasteWithRestore() AFTER cmd+v keystroke fires (gated by existing non-empty guard at line 377; cannot pollute with empty values)"
    - "Forward-visibility pattern for Lua locals — repaste() declared between pasteWithRestore (line 377) and the binding block (line 525) so both callees and caller are in scope"
    - "Two-separate-locals pattern (hk + repasteHk) — each binding gets its own nil-check + actionable alert; F19 alert names Karabiner specifically (RESEARCH §3)"
    - "Surgical-replacement discipline — cmd+shift+e is REMOVED, not supplemented (D-05); zero literal `cmd+shift+e` references survive in init.lua (line 2 header + binding + alert all updated)"
key-files:
  created: []
  modified:
    - "purplevoice-lua/init.lua (+34 net lines: 1 declaration, 1 cache, 11 repaste function, 22 binding block, 1 alert, 1 header — all 7 surgical edits across 4 commits)"
decisions:
  - "All four cmd+shift+e references in init.lua eradicated (line 2 header, lines 510 & 514 binding block, line 545 module-load alert) — Task 1-4's combined-edits strategy was the right call; doing them separately would have left intermediate states violating the grep -c == 0 acceptance gate."
  - "Task 1-5 (cmd+shift+v re-paste live walkthrough) deferred to Plan 04-02 phase-gate sign-off per the plan's documented expected path. Cannot be tested in isolation: cmd+shift+e trigger is removed, F19 trigger needs Karabiner from Plan 04-02, and synthesising a temporary console-only re-bind to populate lastTranscript was rejected by the plan as impractical."
  - "Verbatim Lua snippets from RESEARCH §1 + §3 + reference_data §A-§F applied without paraphrasing. Two minor verify-defects in the plan were auto-fixed inline (Rule 1 — see Deviations)."
metrics:
  duration: ~5 minutes
  completed: 2026-04-30
  tasks-completed: 5  # 4 autonomous + 1 checkpoint deferred
  files-changed: 1
  commits: 4
---

# Phase 4 Plan 01: Lua Core Summary

**Land the user-facing behaviour change for QOL-01 (cmd+shift+v re-paste) and QOL-NEW-01 (F19 trigger replacing cmd+shift+e) in a single surgical 7-edit pass over `purplevoice-lua/init.lua`. Plan 04-02 closes the Karabiner JSON + setup.sh Step 9 + docs.**

## What This Plan Did

Plan 04-01 implemented the Lua-side core of Phase 4 with **7 surgical edits to a single file** — `purplevoice-lua/init.lua` — combined into 4 atomic task commits. The plan's strict scope discipline (Pattern 2 invariant: `purplevoice-record` untouched) was honoured by construction; only init.lua was modified.

### Task-by-Task Outcomes

| Task | Edit | Lines (post-edit) | Commit |
|------|------|-------------------|--------|
| 1-1 | Insert `local lastTranscript = nil` after `local currentTask = nil` (module-state cluster) | line 92 | `5658f2f` |
| 1-2 | Insert `lastTranscript = transcript` inside `pasteWithRestore()` after `hs.eventtap.keyStroke({"cmd"}, "v", 0)` | line 400 | `c2d165c` |
| 1-3 | Define `local function repaste()` with `if lastTranscript then ... else hs.alert.show("PurpleVoice: nothing to re-paste yet", 1.5) end` between pasteWithRestore (line 377) and the binding block (line 525) | lines 514-522 | `1be035c` |
| 1-4 | Three coupled edits: (A) Replace 7-line `cmd+shift+e` binding block with F19 binding + cmd+shift+v binding (22 lines net); (B) Update module-load alert text from `"local dictation, cmd+shift+e"` to `"F19 to record, ⌘⇧V to re-paste"`; (C) Update line-2 header comment from `"Wires cmd+shift+e (push-and-hold) to ..."` to `"Wires F19 (push-and-hold; Karabiner-remapped from fn) to ..."` | line 2; lines 522-545; line 575 | `d2b138d` |
| 1-5 | Checkpoint: human-verify live re-paste walkthrough — **DEFERRED to Plan 04-02 phase-gate sign-off** per the plan's documented expected path | n/a | n/a |

### The 7 Surgical Edits (Before/After Anchors)

| # | Region | Before | After |
|---|--------|--------|-------|
| 1 | Line 2 header | `-- Wires cmd+shift+e (push-and-hold) to ~/.local/bin/purplevoice-record.` | `-- Wires F19 (push-and-hold; Karabiner-remapped from fn) to ~/.local/bin/purplevoice-record.` |
| 2 | Module state (line 92) | (absent) | `local lastTranscript = nil  -- QOL-01: in-memory cache of last successful transcript (D-03 — lost on Hammerspoon reload by design)` |
| 3 | pasteWithRestore (line 400) | (absent — keyStroke at line 398; doAfter at line 400) | `lastTranscript = transcript  -- QOL-01: cache for cmd+shift+v re-paste (after paste fires; gated on non-empty by guard at line 377)` (between keyStroke and doAfter) |
| 4 | repaste function (lines 514-522) | (absent) | `local function repaste() ... end` block (8 lines body + 3-line header comment) |
| 5 | Binding block (lines 522-545) | 7-line `hs.hotkey.bind({"cmd", "shift"}, "e", ...)` block | 22-line block: F19 binding (8-line header comment + 4-line bind+nil-check) + cmd+shift+v binding (5-line header comment + 4-line bind+nil-check), separated by a blank line |
| 6 | Module-load alert (line 575) | `hs.alert.show("PurpleVoice loaded — local dictation, cmd+shift+e", 1.5)` | `hs.alert.show("PurpleVoice loaded — F19 to record, ⌘⇧V to re-paste", 1.5)` (Unicode ⌘ U+2318 + ⇧ U+21E7) |
| 7 | Binding header comment | `-- Bind cmd+shift+e (push-and-hold)` | `-- Bind F19 (push-and-hold) — QOL-NEW-01 / D-05 replaces the prior hotkey` (covered by Edit A; rephrased to keep `cmd+shift+e` literal-string count at zero) |

### cmd+shift+e Eradication

`grep -c 'cmd+shift+e' purplevoice-lua/init.lua` advanced from **4 → 0**. The four prior occurrences were:

- Line 2 (header comment) — Edit C
- Line 510 (binding header comment) — Edit A (rephrased to `D-05 replaces the prior hotkey` to preserve decision-context without the literal string)
- Line 514 (binding line + nil-check alert text) — Edit A
- Line 545 (module-load alert text) — Edit B

All four are clean post-Plan 04-01.

### Test Suite State at Plan Close

| Suite | Result | Notes |
|-------|--------|-------|
| `bash tests/test_karabiner_check.sh` | **exit 1** (3/8 GREEN; 5/8 RED) | Checks 6, 7, 8 GREEN (init.lua F19 + cmd+shift+v + cmd+shift+e-absent — this plan's responsibility). Checks 1, 4, 5 RED (assets/karabiner-fn-to-f19.json missing; setup.sh Karabiner-Elements check absent — Plan 04-02's responsibility). Checks 2, 3 are gated by check 1's failure (defensive `[ -f "$JSON" ]` re-guard pattern from Plan 04-00) so they don't appear in FAIL list. |
| `bash tests/run_all.sh` | **10 PASS / 1 FAIL** (exit 1) | The expected RED is `test_karabiner_check.sh` (handoff state to Plan 04-02). All 10 prior tests still GREEN. |
| `bash tests/security/run_all.sh` | **5 PASS / 0 FAIL** (exit 0) | No security infrastructure touched; suite unchanged. |
| `bash tests/test_brand_consistency.sh` | **PASS** (exit 0) | No legacy `voice-cc` strings introduced. |

### Pattern 2 Invariants (Intact by Construction)

| Invariant | Status |
|-----------|--------|
| `grep -c WHISPER_BIN purplevoice-record == 2` | **OK** (Plan 04-01 did not modify `purplevoice-record`) |
| `! grep -q whisper-cli purplevoice-lua/init.lua` | **OK** (re-paste / F19 code is whisper-cli-free) |
| `! grep -q voice-cc purplevoice-lua/init.lua` | **OK** (brand consistency preserved) |

### Verification Block (Plan §verification, abbreviated)

| # | Check | Expected | Actual |
|---|-------|----------|--------|
| 1 | `grep -cE '^local lastTranscript = nil'` | 1 | **1** |
| 2 | `grep -cE 'lastTranscript = transcript'` (preceded by `hs.eventtap.keyStroke` within 2 lines) | 1, 1 | **1, 1** |
| 3 | `grep -cE '^local function repaste\(\)'` + nil-state alert text | 1, 1 | **1, 1** |
| 4 | `grep -cE 'hs\.hotkey\.bind\(\{\}, ?"f19", ?onPress, ?onRelease\)'` | 1 | **1** |
| 5 | `grep -cE 'hs\.hotkey\.bind\(\{"cmd", ?"shift"\}, ?"v"'` | 1 | **1** |
| 6 | `grep -c 'cmd+shift+e' purplevoice-lua/init.lua` | 0 | **0** |
| 7 | `grep -c 'PurpleVoice loaded — F19 to record'` | 1 | **1** |
| 8 | `grep -c '^-- Wires F19 (push-and-hold; Karabiner-remapped from fn) to'` | 1 | **1** |
| 9 | `bash tests/test_karabiner_check.sh; echo $?` | 1 | **1** |
| 10 | `bash tests/run_all.sh; echo $?` | 1 (10P+1F) | **1 (10P+1F)** |
| 11 | `bash tests/security/run_all.sh; echo $?` | 0 (5/0) | **0 (5/0)** |
| 12 | `bash tests/test_brand_consistency.sh; echo $?` | 0 | **0** |
| 13 | Pattern 2 (`WHISPER_BIN == 2` + no whisper-cli) | OK | **OK** |
| 14 | `grep -c lastTranscript purplevoice-lua/init.lua` | 3 (per plan) | **4** (correct per verbatim §C — see Deviations Rule 1 #2) |

## Deviations from Plan

### Auto-fixed Issues (Rule 1 — verify-defect / spec inconsistency)

**1. [Rule 1 - Verify Defect] Task 1-2 verify command's `grep -A2` window too narrow**

- **Found during:** Task 1-2 verification
- **Issue:** The plan's automated verify clause `grep -A2 'lastTranscript = transcript' purplevoice-lua/init.lua | grep -q 'hs\.timer\.doAfter'` failed because the file layout has the cache assignment followed by a blank line + 3-line comment block + the timer call. The plan's `<reference_data>` §B and `<action>` "Final state of lines 397-403" example correctly show this layout — the verify command's `-A2` was inconsistent with the plan's own implementation spec. Fix attempt count: 1.
- **Fix:** Used `grep -A6` for the verify (consistent with the plan's `<action>` "Final state" example showing the comment block sitting between the assignment and the timer). Implementation matches verbatim spec §B exactly.
- **Files modified:** None (verify command only; plan's `<reference_data>` §B implementation is correct).
- **Commit:** `c2d165c` (Task 1-2)

**2. [Rule 1 - Spec Arithmetic Error] Task 1-3 acceptance criterion `grep -c lastTranscript == 3` was off-by-one**

- **Found during:** Task 1-3 verification
- **Issue:** Plan §verify and §acceptance_criteria both claimed the lastTranscript count after Task 1-3 should be 3 ("declaration + cache + nil-check"). The actual count is 4 because the verbatim repaste() function in `<reference_data>` §C contains TWO references to lastTranscript: `if lastTranscript then` (the nil-check) AND `pasteWithRestore(lastTranscript)` (the non-nil branch). The plan author miscounted.
- **Fix:** Implementation matches `<reference_data>` §C verbatim. Verified count is 4 — the mathematically correct number for the verbatim spec. Plan's count of 3 was wrong.
- **Files modified:** None (count assertion only; verbatim spec is correct).
- **Commit:** `1be035c` (Task 1-3)

**3. [Rule 1 - Spec Self-Contradiction] Task 1-4 verbatim spec §D contained literal `cmd+shift+e` that violated its own acceptance gate**

- **Found during:** Task 1-4 verification (run after first edit application)
- **Issue:** The plan's `<reference_data>` §D verbatim block for the F19 binding header comment contained the line `-- Bind F19 (push-and-hold) — QOL-NEW-01 / D-05 replaces cmd+shift+e`. The acceptance gate `grep -c 'cmd+shift+e' purplevoice-lua/init.lua == 0` could never pass if §D was applied verbatim — the verbatim block contradicted its own gate. Fix attempt count: 1.
- **Fix:** Rephrased the comment to `-- Bind F19 (push-and-hold) — QOL-NEW-01 / D-05 replaces the prior hotkey` — preserves the D-05 decision reference and historical context (the comment still names the requirement and the decision) while honouring the zero-literal-string acceptance gate. Acceptable per the plan's intent (the spec itself insisted on zero `cmd+shift+e` references).
- **Files modified:** purplevoice-lua/init.lua (line 523 comment text)
- **Commit:** `d2b138d` (Task 1-4)

### Architectural Changes (Rule 4)

**None.** No new tables, services, libraries, or breaking API changes. All work was within init.lua module boundaries with no cross-file impact.

### Authentication Gates

**None.** Plan executed with no auth-gated tools or resources.

## Task 1-5 Checkpoint Outcome — DEFERRED

**Resolution:** **Deferred to Plan 04-02 phase-gate sign-off** per the plan's documented expected path.

**Rationale:** The plan's `<task type="checkpoint:human-verify">` block explicitly notes that cmd+shift+v re-paste cannot be meaningfully tested in isolation:

1. **cmd+shift+e is removed** (Task 1-4 / D-05 deliberate replacement) — the prior trigger no longer exists to populate lastTranscript via the recording pipeline.
2. **F19 needs Karabiner** — the only way to fire the recording pipeline post-Plan 04-01 is via F19 hold, which requires Karabiner-Elements installed + the `assets/karabiner-fn-to-f19.json` rule imported. Both land in Plan 04-02.
3. **Console-only synthetic re-bind path was rejected** — temporarily binding cmd+shift+e in the Hammerspoon console to populate lastTranscript would require accessing local-scoped onPress/onRelease references and is impractical for a 5-minute checkpoint.

The plan's recommended path is "defer this checkpoint to AFTER Plan 04-02 lands the Karabiner JSON + setup.sh check, install Karabiner, import the rule, then run `tests/manual/test_repaste_walkthrough.md` end-to-end with fn-hold as the recording trigger" — this matches the walkthrough's Prerequisites step 4 ("Karabiner-Elements imported and rule enabled") which itself blocks on Plan 04-02.

**Verification path forward:** When Plan 04-02 closes, the live walkthrough at `tests/manual/test_repaste_walkthrough.md` will exercise:

- Reload Hammerspoon → verify load alert reads `PurpleVoice loaded — F19 to record, ⌘⇧V to re-paste`
- Hold fn (F19) to record → release → transcript appears in focused app
- Switch focus to a different window
- Press cmd+shift+v → same transcript re-pastes
- Reload Hammerspoon (lastTranscript clears by design per D-03)
- Press cmd+shift+v → brief alert `PurpleVoice: nothing to re-paste yet` for ~1.5s, no crash

## Handoff to Plan 04-02

Plan 04-02 (Karabiner integration + docs closure) implements:

1. **Creates** `assets/karabiner-fn-to-f19.json` — complex modification with `to_if_alone` + `to_if_held_down` + 200ms threshold (D-06; RESEARCH Pattern 1).
2. **Adds** `setup.sh` Step 9 — checks `/Applications/Karabiner-Elements.app`; prints actionable error + exits 1 when absent (D-07); honours `PURPLEVOICE_OFFLINE=1` (D-08).
3. **Updates** README.md / SECURITY.md to document Karabiner dependency.
4. **Updates** `tests/manual/test_*.md` references from cmd+shift+e to F19 (mechanical text replacements).
5. **Closes** REQUIREMENTS.md QOL-01 + QOL-NEW-01 from `[ ]` Pending to `[x]` Complete via `gsd-tools requirements mark-complete`.
6. **Updates** ROADMAP.md Phase 4 progress row.
7. **Runs** the deferred Task 1-5 live walkthrough (test_repaste_walkthrough.md) + test_f19_walkthrough.md + test_setup_karabiner_missing.md.

After Plan 04-02: `bash tests/test_karabiner_check.sh` 8/8 GREEN; functional suite 11/0 (or remains 11 tests with all GREEN); security suite 5/0; brand consistency GREEN; framing lint GREEN. Phase 4 ready for verifier sign-off.

## Self-Check: PASSED

Files modified (verified):

- FOUND: purplevoice-lua/init.lua

Commits exist (verified via `git log --oneline`):

- FOUND: 5658f2f (Task 1-1)
- FOUND: c2d165c (Task 1-2)
- FOUND: 1be035c (Task 1-3)
- FOUND: d2b138d (Task 1-4)

Suite state verified:

- FOUND: 10 PASS + 1 FAIL functional (test_karabiner_check.sh RED — expected handoff to Plan 04-02)
- FOUND: 5 PASS + 0 FAIL security
- FOUND: brand consistency GREEN
- FOUND: Pattern 2 invariants intact (`WHISPER_BIN purplevoice-record == 2`; no `whisper-cli` in init.lua; no `voice-cc` in init.lua)

cmd+shift+e eradication verified:

- FOUND: 0 occurrences of literal `cmd+shift+e` in init.lua (was 4 at lines 2, 510, 514, 545 pre-plan)

All success criteria from PLAN.md `<success_criteria>` block satisfied (Task 1-5 deferred per plan's documented expected path; this is the recommended outcome, not a deviation).
