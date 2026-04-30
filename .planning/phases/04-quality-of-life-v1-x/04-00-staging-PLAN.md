---
phase: 04-quality-of-life-v1-x
plan: 00
type: execute
wave: 0
depends_on: []
files_modified:
  - tests/test_karabiner_check.sh
  - tests/manual/test_repaste_walkthrough.md
  - tests/manual/test_f19_walkthrough.md
  - tests/manual/test_setup_karabiner_missing.md
  - .planning/REQUIREMENTS.md
autonomous: true
requirements:
  - QOL-01
  - QOL-NEW-01

must_haves:
  truths:
    - "tests/test_karabiner_check.sh exists with all 8 string-level assertions"
    - "Three manual walkthrough scaffolds exist (test_repaste_walkthrough.md, test_f19_walkthrough.md, test_setup_karabiner_missing.md)"
    - "REQUIREMENTS.md QOL-01 promoted to v1 with concrete language; QOL-NEW-01 row added; both [ ] Pending"
    - "tests/run_all.sh discovers test_karabiner_check.sh (suite count grows 10 -> 11; new test FAILS as expected — RED at Wave 0)"
  artifacts:
    - path: "tests/test_karabiner_check.sh"
      provides: "8-check string-level lint for Karabiner JSON + setup.sh Step 9 + init.lua F19 binding + cmd+shift+v binding + cmd+shift+e absence"
      contains: "jq empty"
    - path: "tests/manual/test_repaste_walkthrough.md"
      provides: "QOL-01 manual walkthrough scaffold (record -> focus shift -> cmd+shift+v re-paste; nil-state alert post-reload)"
    - path: "tests/manual/test_f19_walkthrough.md"
      provides: "QOL-NEW-01 manual walkthrough scaffold (Karabiner imported; fn-hold triggers; fn-tap preserves Globe; cmd+shift+e no longer triggers)"
    - path: "tests/manual/test_setup_karabiner_missing.md"
      provides: "QOL-NEW-01 negative-control walkthrough scaffold (sudo-move .app aside, run setup.sh, observe exit-1 + actionable error, restore)"
    - path: ".planning/REQUIREMENTS.md"
      provides: "QOL-01 promoted from v2 stub to v1 (concrete language: cmd+shift+v + in-memory cache + nil-state alert); QOL-NEW-01 row added (F19 alt hotkey + Karabiner dep)"
      contains: "QOL-NEW-01"
  key_links:
    - from: "tests/test_karabiner_check.sh"
      to: "purplevoice-lua/init.lua"
      via: "grep -qE 'hs\\.hotkey\\.bind\\(\\{\\}, ?\"f19\"'"
      pattern: "hs.hotkey.bind\\(\\{\\}, ?\"f19\""
    - from: "tests/test_karabiner_check.sh"
      to: "assets/karabiner-fn-to-f19.json"
      via: "jq -r '.rules[0].manipulators[0].from.key_code'"
      pattern: "from.key_code: fn"
    - from: "tests/test_karabiner_check.sh"
      to: "setup.sh"
      via: "grep -q 'Karabiner-Elements.app'"
      pattern: "/Applications/Karabiner-Elements.app"
---

<objective>
Stage all Phase 4 verification scaffolds in a single Wave 0 commit so subsequent plans (04-01 Lua core, 04-02 Karabiner integration + docs closure) implement against contracts that already exist on disk.

**Purpose:** Establish the validation gates for QOL-01 (re-paste hotkey) and QOL-NEW-01 (F19 alt hotkey via Karabiner) before any production code changes. This follows the Phase 02-00 / Phase 03.5-00 Wave-0 precedent — tests + REQUIREMENTS.md stubs land first, then implementation plans turn the tests GREEN.

**Output:**
- 1 new bash unit test (`tests/test_karabiner_check.sh`) — 8 string-level checks; FAILS at Wave 0 commit by design (init.lua + setup.sh + assets/karabiner-fn-to-f19.json not yet modified) and turns GREEN incrementally as Plans 04-01 + 04-02 land.
- 3 manual walkthrough scaffolds in `tests/manual/` — phase-gate sign-off targets for Oliver.
- REQUIREMENTS.md updated: QOL-01 promoted from v2 stub to v1 with concrete language; QOL-NEW-01 added as new row; both `[ ]` Pending until Phase 4 closes.

**RED-at-commit warning (read carefully):** The new `tests/test_karabiner_check.sh` will FAIL when committed at Wave 0. This is INTENTIONAL — it asserts wiring that does not yet exist. Wave 0's acceptance criterion is "test FILE exists + has 8 checks + scripts are discoverable by run_all.sh", NOT "test passes". DO NOT `chmod -x` to skip; DO NOT delete checks to make it pass; DO NOT inline-skip with early-exit. The RED state is the contract handoff to Plan 04-01.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/REQUIREMENTS.md
@.planning/phases/04-quality-of-life-v1-x/04-CONTEXT.md
@.planning/phases/04-quality-of-life-v1-x/04-RESEARCH.md
@.planning/phases/04-quality-of-life-v1-x/04-VALIDATION.md

# Reference patterns to mirror (read these first)
@tests/test_hud_env_off.sh
@tests/test_security_md_framing.sh
@tests/run_all.sh
@tests/manual/test_clipboard_restore.md
@tests/manual/test_hud_disable.md

<interfaces>
<!-- Existing patterns this plan mirrors -->

From tests/test_hud_env_off.sh (the Wave-0 RED-at-commit precedent for Phase 3.5):
```bash
# Header pattern: shebang, set -uo pipefail, cd repo root
#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")/.."   # repo root

# Per-check pattern: increment FAIL on miss; final summary
FAIL=0
if ! grep -qE 'pattern' "$FILE"; then
  echo "FAIL: <message>"
  FAIL=1
fi
# ... more checks ...
if [ "$FAIL" -eq 0 ]; then
  echo "PASS [test_NAME.sh]: <summary>"
  exit 0
fi
exit 1
```

From tests/run_all.sh:
- Iterates `tests/test_*.sh` alphabetically — new test_karabiner_check.sh discovered automatically (sorts after test_hud_position_validation.sh)
- Runs each via `bash "$f"`, captures exit code, prints PASS/FAIL
- Final summary: `Results: $PASS passed, $FAIL failed`
- Suite exits 0 only if all pass

From tests/manual/test_clipboard_restore.md (canonical scaffold structure):
- H1: `# Manual Test: <name> (<REQUIREMENT-ID>)`
- **Requirement:** one-line description
- **Prerequisites:** numbered list of state needed before test
- ## Steps — numbered, concrete actions
- ## Expected Outcome — what user should observe
- ## Failure modes — diagnosis hints
- ## Sign-off — checkboxes + Tester / Date fields
</interfaces>

<reference_data>
<!-- Verbatim values plan tasks must use. Do NOT paraphrase. -->

## REQUIREMENTS.md edits (Task 0-5)

### Section to MODIFY: `### Quality of Life` under `## v2 Requirements` (lines 80-86)

CURRENT (line 82):
```
- **QOL-01**: Paste-last-transcript hotkey re-pastes the most recent transcription (recovery from focus-lost paste)
```

REMOVE this v2 stub line (it gets promoted to v1).

### Section to ADD: New v1 subsection `### Quality of Life` (place AFTER `### Hover UI / HUD` v1 subsection, BEFORE `## v2 Requirements`)

```markdown
### Quality of Life

- [ ] **QOL-01**: Paste-last-transcript hotkey (`cmd+shift+v`) re-pastes the most recent successful transcript into the focused window. Implemented as `hs.hotkey.bind({"cmd","shift"}, "v", repaste)` in `purplevoice-lua/init.lua` calling `pasteWithRestore(lastTranscript)`. Storage = in-memory Lua module-scope `local lastTranscript = nil`, updated AFTER the `cmd+v` keystroke fires inside `pasteWithRestore()` (per CONTEXT.md D-03). NO disk persistence — `lastTranscript` is lost on Hammerspoon reload by design (privacy-first; institutional / healthcare audience). Nil-state behaviour: `hs.alert.show("PurpleVoice: nothing to re-paste yet", 1.5)` (per CONTEXT.md D-04). Verified by `tests/test_karabiner_check.sh` check 7 (string-level wiring) + `tests/manual/test_repaste_walkthrough.md` (live end-to-end sign-off).
- [ ] **QOL-NEW-01**: F19 alt hotkey replaces `cmd+shift+e` for push-and-hold recording. Implemented as `hs.hotkey.bind({}, "f19", onPress, onRelease)` in `purplevoice-lua/init.lua` (no modifier table; per CONTEXT.md D-05). The previous `cmd+shift+e` binding is REMOVED, not supplemented (D-05). Karabiner-Elements remaps `fn` -> `F19` via `assets/karabiner-fn-to-f19.json` (complex modification with `to_if_alone` + `to_if_held_down` + 200ms threshold; D-06). `setup.sh` Step 9 detects `/Applications/Karabiner-Elements.app` and refuses to declare install complete without it (D-07); `PURPLEVOICE_OFFLINE=1` mode notes USB-sneakernet path for the .dmg (D-08). Verified by `tests/test_karabiner_check.sh` checks 1-6 + 8 (string-level wiring) + `tests/manual/test_f19_walkthrough.md` + `tests/manual/test_setup_karabiner_missing.md` (live end-to-end + negative-control sign-offs).
```

### Section to MODIFY: `## Traceability` table

CURRENT (lines 161-165):
```
| QOL-01 | Phase 4 (v1.x): Quality of Life | Deferred |
| QOL-02 | Phase 4 (v1.x): Quality of Life | Deferred |
| QOL-03 | Phase 4 (v1.x): Quality of Life | Deferred |
| QOL-04 | Phase 4 (v1.x): Quality of Life | Deferred |
| QOL-05 | Phase 4 (v1.x): Quality of Life | Deferred |
```

REPLACE with:
```
| QOL-01 | Phase 4 (v1.x): Quality of Life | Pending |
| QOL-NEW-01 | Phase 4 (v1.x): Quality of Life | Pending |
| QOL-02 | v2 / backlog (deferred — no real-use trigger as of 2026-04-30 per Phase 4 CONTEXT.md D-01) | Deferred |
| QOL-03 | v2 / backlog (deferred — no real-use trigger as of 2026-04-30 per Phase 4 CONTEXT.md D-01) | Deferred |
| QOL-04 | v2 / backlog (deferred — no real-use trigger as of 2026-04-30 per Phase 4 CONTEXT.md D-01) | Deferred |
| QOL-05 | v2 / backlog (deferred — no real-use trigger as of 2026-04-30 per Phase 4 CONTEXT.md D-01) | Deferred |
```

### Section to MODIFY: Coverage stats (lines 169-181)

CURRENT line 170: `- v1 requirements: 39 total (35 prior + HUD-01..04 added 2026-04-30)`
REPLACE with: `- v1 requirements: 41 total (39 prior + QOL-01 promoted from v2 + QOL-NEW-01 new in Phase 4 2026-04-30)`

CURRENT line 171: `- Mapped to phases: 39 / 39 (100%)`
REPLACE with: `- Mapped to phases: 41 / 41 (100%)`

CURRENT line 173: `- v2 requirements: 7 total (5 QOL → Phase 4, 2 PERF → Phase 5 conditional)`
REPLACE with: `- v2 requirements: 6 total (4 QOL deferred — QOL-02 Esc, QOL-03 replacements.txt, QOL-04 history.log, QOL-05 PURPLEVOICE_MODEL — paths/vars use `purplevoice` namespace per Phase 2.5 D-05; 2 PERF → Phase 5 conditional)`

CURRENT line 175 (per-phase counts header) is unchanged. ADD a new row at end of the per-phase counts list (line 181):
```
- Phase 4 (v1.x): Quality of Life — 2 requirements (QOL-01, QOL-NEW-01) — Pending
```

### Section to MODIFY: `## v2 Requirements` -> `### Quality of Life` (lines 80-86)

After REMOVING QOL-01 stub (line 82), update remaining v2 stubs to use `purplevoice` paths/vars (per CONTEXT.md D-10 deferred-items rebrand note):

CURRENT lines 84-86:
```
- **QOL-03**: User can supply `~/.config/voice-cc/replacements.txt` (find/replace pairs) for recurring mis-transcriptions that `--prompt` doesn't fix ("Versel" → "Vercel")
- **QOL-04**: Rolling history log at `~/.cache/voice-cc/history.log` capped at 10 MB
- **QOL-05**: `VOICE_CC_MODEL` environment variable allows runtime model swap (e.g., `medium.en`)
```

REPLACE with:
```
- **QOL-03** *(deferred — Phase 4 D-01 / D-10 rebrand applied)*: User can supply `~/.config/purplevoice/replacements.txt` (find/replace pairs) for recurring mis-transcriptions that `--prompt` doesn't fix ("Versel" → "Vercel")
- **QOL-04** *(deferred — Phase 4 D-01 / D-10 rebrand applied)*: Rolling history log at `~/.cache/purplevoice/history.log` capped at 10 MB
- **QOL-05** *(deferred — Phase 4 D-01 / D-10 rebrand applied)*: `PURPLEVOICE_MODEL` environment variable allows runtime model swap (e.g., `medium.en`)
```

(Note: QOL-02 stub at line 83 is unchanged — it has no path/var to rebrand.)

## tests/test_karabiner_check.sh (Task 0-1) — VERBATIM CONTENT

See RESEARCH.md §6 (lines 651-746). The full file content is:

```bash
#!/usr/bin/env bash
# tests/test_karabiner_check.sh — Phase 4 Karabiner-check string-level wiring assertion
#
# Asserts that:
#   1. assets/karabiner-fn-to-f19.json exists and parses as valid JSON
#   2. The JSON has the documented top-level structure (title + rules + manipulators)
#   3. The from.key_code is "fn" and to_if_held_down has key_code "f19"
#   4. setup.sh contains the Karabiner-Elements check + actionable error
#   5. setup.sh contains the file-existence guard for the JSON
#   6. purplevoice-lua/init.lua binds F19 (no modifiers)
#   7. purplevoice-lua/init.lua binds cmd+shift+v for re-paste
#   8. purplevoice-lua/init.lua does NOT bind cmd+shift+e (deliberate replacement)
#
# RED-at-Wave-0 by design: assets/karabiner-fn-to-f19.json + setup.sh Step 9 +
# init.lua F19/cmd+shift+v bindings do not exist yet. Plan 04-01 turns checks
# 6, 7, 8 GREEN; Plan 04-02 turns checks 1-5 GREEN. Final state: 8/8 GREEN.
#
# Exit 0 = wiring intact; exit 1 = drift or missing file.
set -uo pipefail
cd "$(dirname "$0")/.."   # repo root

FAIL=0
KARABINER_JSON="assets/karabiner-fn-to-f19.json"
SETUP="setup.sh"
INIT="purplevoice-lua/init.lua"

# 1. JSON file exists and parses
if [ ! -f "$KARABINER_JSON" ]; then
  echo "FAIL: $KARABINER_JSON missing"
  FAIL=1
elif ! jq empty "$KARABINER_JSON" 2>/dev/null; then
  echo "FAIL: $KARABINER_JSON is not valid JSON"
  FAIL=1
fi

# 2. Documented top-level structure
if [ "$FAIL" -eq 0 ] && [ -f "$KARABINER_JSON" ]; then
  TITLE=$(jq -r '.title // empty' "$KARABINER_JSON")
  RULES_COUNT=$(jq '.rules | length' "$KARABINER_JSON" 2>/dev/null || echo 0)
  if [ -z "$TITLE" ]; then
    echo "FAIL: $KARABINER_JSON missing top-level 'title' field"
    FAIL=1
  fi
  if [ "$RULES_COUNT" -lt 1 ]; then
    echo "FAIL: $KARABINER_JSON has no rules"
    FAIL=1
  fi
fi

# 3. from.key_code=fn, to_if_held_down.key_code=f19
if [ "$FAIL" -eq 0 ] && [ -f "$KARABINER_JSON" ]; then
  FROM_KEY=$(jq -r '.rules[0].manipulators[0].from.key_code // empty' "$KARABINER_JSON")
  HELD_KEY=$(jq -r '.rules[0].manipulators[0].to_if_held_down[0].key_code // empty' "$KARABINER_JSON")
  if [ "$FROM_KEY" != "fn" ]; then
    echo "FAIL: $KARABINER_JSON from.key_code is '$FROM_KEY' (expected 'fn')"
    FAIL=1
  fi
  if [ "$HELD_KEY" != "f19" ]; then
    echo "FAIL: $KARABINER_JSON to_if_held_down.key_code is '$HELD_KEY' (expected 'f19')"
    FAIL=1
  fi
fi

# 4. setup.sh contains the Karabiner check
if ! grep -q "Karabiner-Elements.app" "$SETUP"; then
  echo "FAIL: $SETUP missing /Applications/Karabiner-Elements.app check"
  FAIL=1
fi

# 5. setup.sh contains the file-existence guard
if ! grep -q "karabiner-fn-to-f19.json" "$SETUP"; then
  echo "FAIL: $SETUP missing reference to assets/karabiner-fn-to-f19.json"
  FAIL=1
fi

# 6. init.lua binds F19 with empty modifier table
if ! grep -qE 'hs\.hotkey\.bind\(\{\}, ?"f19"' "$INIT"; then
  echo "FAIL: $INIT missing F19 binding (hs.hotkey.bind({}, \"f19\", ...))"
  FAIL=1
fi

# 7. init.lua binds cmd+shift+v for re-paste
if ! grep -qE 'hs\.hotkey\.bind\(\{"cmd", ?"shift"\}, ?"v"' "$INIT"; then
  echo "FAIL: $INIT missing cmd+shift+v re-paste binding"
  FAIL=1
fi

# 8. init.lua does NOT bind cmd+shift+e (deliberate replacement per CONTEXT.md D-05)
if grep -qE 'hs\.hotkey\.bind\(\{"cmd", ?"shift"\}, ?"e"' "$INIT"; then
  echo "FAIL: $INIT still binds cmd+shift+e (Phase 4 D-05 requires removal)"
  FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS [test_karabiner_check.sh]: Karabiner JSON valid; setup.sh check present; init.lua bindings correct"
  exit 0
fi
exit 1
```

Note the small additions vs RESEARCH.md §6 verbatim: checks 2 and 3 add `[ -f "$KARABINER_JSON" ]` re-guard so they do not invoke jq on a missing file when check 1 has already failed but FAIL is reset to 0 between checks. This is a defensive correctness fix, not a deviation.
</reference_data>
</context>

<tasks>

<task type="auto">
  <name>Task 0-1: Create tests/test_karabiner_check.sh (8 string-level checks; RED at Wave 0 by design)</name>
  <read_first>
    - tests/test_hud_env_off.sh (Wave-0 RED-at-commit precedent — read FULL file to mirror header style, set -uo pipefail, cd-to-repo-root pattern, FAIL counter idiom)
    - tests/test_security_md_framing.sh (alternate FAIL-on-first-violation pattern)
    - tests/run_all.sh (test discovery — confirms alphabetical iteration; new test_karabiner_check.sh sorts AFTER test_hud_position_validation.sh)
    - .planning/phases/04-quality-of-life-v1-x/04-RESEARCH.md §6 "Code Examples" (lines ~649-746) for the verbatim 8-check content
    - .planning/phases/04-quality-of-life-v1-x/04-VALIDATION.md (Per-Task Verification Map row 04-00-01)
  </read_first>
  <files>tests/test_karabiner_check.sh</files>
  <action>
    Create `tests/test_karabiner_check.sh` with the VERBATIM content from the `<reference_data>` block above (`tests/test_karabiner_check.sh (Task 0-1) — VERBATIM CONTENT`). The 8 checks are:

    1. JSON file `assets/karabiner-fn-to-f19.json` exists and parses via `jq empty`
    2. JSON has top-level `title` (non-empty) and `rules` (array length >= 1)
    3. `.rules[0].manipulators[0].from.key_code == "fn"` and `.rules[0].manipulators[0].to_if_held_down[0].key_code == "f19"`
    4. `setup.sh` contains the literal string `Karabiner-Elements.app` (the Step 9 check)
    5. `setup.sh` contains the literal string `karabiner-fn-to-f19.json` (the file-existence guard reference)
    6. `purplevoice-lua/init.lua` matches `grep -qE 'hs\.hotkey\.bind\(\{\}, ?"f19"'` (F19 binding with empty modifiers)
    7. `purplevoice-lua/init.lua` matches `grep -qE 'hs\.hotkey\.bind\(\{"cmd", ?"shift"\}, ?"v"'` (re-paste binding)
    8. `purplevoice-lua/init.lua` does NOT match `grep -qE 'hs\.hotkey\.bind\(\{"cmd", ?"shift"\}, ?"e"'` (cmd+shift+e removed per D-05)

    Header comment must explain RED-at-Wave-0 contract: "Plan 04-01 turns checks 6, 7, 8 GREEN; Plan 04-02 turns checks 1-5 GREEN. Final state: 8/8 GREEN."

    Use the verbatim content from `<reference_data>` — do NOT paraphrase the regex patterns or grep flags. The defensive `[ -f "$KARABINER_JSON" ]` re-guards on checks 2 and 3 are intentional (prevents jq errors when check 1 already FAILed).

    After writing the file: `chmod +x tests/test_karabiner_check.sh` is NOT required — `tests/run_all.sh` invokes via `bash "$f"` regardless of executable bit. Do NOT chmod.

    Do NOT add to test_brand_consistency.sh exemption list — this test file does not contain the literal `voice-cc` string (it references `karabiner-fn-to-f19.json` and Lua binding patterns only).
  </action>
  <verify>
    <automated>test -f tests/test_karabiner_check.sh && bash -n tests/test_karabiner_check.sh && grep -c "FAIL:" tests/test_karabiner_check.sh | grep -qE '^([8-9]|1[0-9])$' && grep -q 'jq empty' tests/test_karabiner_check.sh && grep -q 'hs\\.hotkey\\.bind' tests/test_karabiner_check.sh</automated>
  </verify>
  <acceptance_criteria>
    - File `tests/test_karabiner_check.sh` exists
    - `bash -n tests/test_karabiner_check.sh` exits 0 (no syntax errors)
    - File contains 8+ `FAIL:` echo lines (one per check; some checks have 2 sub-asserts so >= 8)
    - File contains `jq empty "$KARABINER_JSON"` (check 1)
    - File contains `'.rules[0].manipulators[0].from.key_code'` (check 3)
    - File contains `'.rules[0].manipulators[0].to_if_held_down[0].key_code'` (check 3)
    - File contains `Karabiner-Elements.app` (check 4)
    - File contains `karabiner-fn-to-f19.json` (check 5)
    - File contains `hs\\.hotkey\\.bind\\(\\{\\}, ?"f19"` regex (check 6)
    - File contains `hs\\.hotkey\\.bind\\(\\{"cmd", ?"shift"\\}, ?"v"` regex (check 7)
    - File contains `hs\\.hotkey\\.bind\\(\\{"cmd", ?"shift"\\}, ?"e"` regex (check 8 — negative)
    - File starts with `#!/usr/bin/env bash` and contains `set -uo pipefail`
    - File contains `cd "$(dirname "$0")/.."` (cd to repo root)
    - File contains `PASS [test_karabiner_check.sh]:` success line
    - Header comment contains "RED-at-Wave-0" or "Plan 04-01 turns checks 6, 7, 8 GREEN"
    - `bash tests/test_karabiner_check.sh; echo $?` exits 1 (RED at Wave 0 — by design)
    - `bash tests/run_all.sh` discovers it (output shows `[test] test_karabiner_check.sh ... FAIL` line); suite exit-code is 1 (one new failure; 10 prior PASS continue)
  </acceptance_criteria>
  <done>
    `tests/test_karabiner_check.sh` exists with 8 string-level assertions (RESEARCH.md §6 content), is bash-syntactically valid, runs RED at Wave 0 (exit 1) — proving the contract is in place for Plans 04-01 and 04-02 to satisfy. `tests/run_all.sh` discovers it (suite count 10 -> 11; one new FAIL).
  </done>
</task>

<task type="auto">
  <name>Task 0-2: Create tests/manual/test_repaste_walkthrough.md (QOL-01 manual scaffold)</name>
  <read_first>
    - tests/manual/test_clipboard_restore.md (canonical scaffold structure to mirror)
    - tests/manual/test_hud_disable.md (env-var-affecting walkthrough idiom)
    - .planning/phases/04-quality-of-life-v1-x/04-CONTEXT.md §domain (re-paste UX expectations) and §decisions D-02, D-03, D-04
    - .planning/phases/04-quality-of-life-v1-x/04-VALIDATION.md "Manual-Only Verifications" rows for QOL-01
    - .planning/phases/04-quality-of-life-v1-x/04-RESEARCH.md §"Pitfall 2" (cmd+shift+v collision with VS Code/Cursor markdown preview — mention in scaffold so tester is not surprised)
  </read_first>
  <files>tests/manual/test_repaste_walkthrough.md</files>
  <action>
    Create the QOL-01 manual walkthrough scaffold mirroring `tests/manual/test_clipboard_restore.md` structure (H1 + Requirement + Prerequisites + Steps + Expected Outcome + Failure modes + Sign-off). Required content:

    **H1:** `# Manual Test: Re-paste hotkey cmd+shift+v (QOL-01)`

    **Requirement line:** `**Requirement:** QOL-01 — Paste-last-transcript hotkey re-pastes the most recent successful transcript into the focused window. Storage is in-memory Lua module-scope `local lastTranscript = nil`; lost on Hammerspoon reload by design (CONTEXT.md D-03).`

    **Prerequisites:** numbered list:
    1. Plan 04-01 complete (purplevoice-lua/init.lua has `local lastTranscript = nil` module-scope, `hs.hotkey.bind({"cmd","shift"}, "v", repaste)`, and `lastTranscript = transcript` cache point inside `pasteWithRestore`).
    2. Hammerspoon launched with the updated init.lua loaded; module-load alert reads `PurpleVoice loaded — F19 to record, ⌘⇧V to re-paste` (or ASCII fallback).
    3. Microphone + Accessibility granted to Hammerspoon (per Phase 2 setup).
    4. Karabiner-Elements imported and `Hold fn → F19 (PurpleVoice push-to-talk)` rule enabled — required because Plan 04-01 also removes the cmd+shift+e binding (D-05). Recording is triggered via fn-hold (which Karabiner remaps to F19).

    **## Steps:** (numbered)
    1. Open TextEdit (or any text editor with two open documents). Click into Document A.
    2. Hold fn for ~2 seconds (Karabiner emits F19; PurpleVoice begins recording). Say "this is the first test transcript". Release fn. Within ~2 seconds, "this is the first test transcript" pastes into Document A. **PASS-1:** initial paste succeeded.
    3. Switch focus to Document B (cmd+tab or click into the second document).
    4. Press cmd+shift+v.
    5. Expected: "this is the first test transcript" pastes into Document B (re-paste of the cached `lastTranscript`). **PASS-2:** re-paste fired correct transcript across focus shift.
    6. Reload Hammerspoon: menubar -> Reload Config (OR run `hs -c "hs.reload()"` from a Terminal that has Hammerspoon CLI configured). Wait for the load alert.
    7. Without recording anything new, press cmd+shift+v.
    8. Expected: a brief alert appears: `PurpleVoice: nothing to re-paste yet` (~1.5s fade). NO paste fires; NO crash. **PASS-3:** nil-state alert behaves correctly post-reload.
    9. (Optional regression check) Open a `.md` file in VS Code or Cursor. Press cmd+shift+v. Expected: re-paste fires (NOT the IDE's "Markdown Preview" feature) — Hammerspoon Carbon RegisterEventHotKey wins precedence over app shortcuts (RESEARCH.md Pitfall 2). Note this is a real cost: Markdown Preview is no longer accessible via cmd+shift+v while Hammerspoon is running. Workaround: Cmd+K V (VS Code split preview).

    **## Expected Outcome:**
    - Step 2: initial recording transcribes and pastes into Document A.
    - Step 5: cmd+shift+v in Document B pastes the cached transcript (proves QOL-01 cross-app re-paste).
    - Step 8: post-reload cmd+shift+v shows brief alert, no crash (proves nil-state behaviour D-04).
    - Step 9 (if exercised): cmd+shift+v in VS Code .md file fires PurpleVoice re-paste, NOT VS Code's Markdown Preview (proves Hammerspoon hotkey precedence).

    **## Failure modes:**
    - Step 5 produces no paste -> `lastTranscript` was not cached. Check `pasteWithRestore()` for `lastTranscript = transcript` line AFTER `hs.eventtap.keyStroke({"cmd"}, "v", 0)` (per RESEARCH.md Pattern 4 / §2 — cache point inside the success path, not in handleExit).
    - Step 5 pastes the wrong text -> `lastTranscript` was assigned the wrong value. Check that the assignment uses the `transcript` parameter of `pasteWithRestore()`, not `stdOut` from `handleExit()`.
    - Step 8 crashes / shows no alert -> `repaste()` does not nil-check `lastTranscript`. Required pattern: `if lastTranscript then pasteWithRestore(lastTranscript) else hs.alert.show("PurpleVoice: nothing to re-paste yet", 1.5) end`.
    - Step 8 alert does not appear -> Hammerspoon was not actually reloaded (state survived); confirm by checking the load alert fired between steps 6 and 7.
    - cmd+shift+v binding never fires anywhere -> hotkey conflict with another tool (Raycast, Alfred, BTT). Check for `PurpleVoice: cmd+shift+v binding failed (in use?)` alert at module load (RESEARCH.md Pitfall 4). Mitigation: rebind the conflicting tool, or revisit at plan-checker review per CONTEXT.md D-02.

    **## Sign-off:** checkboxes for PASS-1 / PASS-2 / PASS-3, then `**Tester:** _____________  **Date:** _____________`.

    Do NOT pre-fill the sign-off date or tester. Do NOT add a "Sign-off (Phase 4 close)" section yet — Plan 04-01 fills the live sign-off after Oliver runs the walkthrough.
  </action>
  <verify>
    <automated>test -f tests/manual/test_repaste_walkthrough.md && grep -q "QOL-01" tests/manual/test_repaste_walkthrough.md && grep -q "cmd+shift+v" tests/manual/test_repaste_walkthrough.md && grep -q "nothing to re-paste yet" tests/manual/test_repaste_walkthrough.md && grep -q "PASS-3" tests/manual/test_repaste_walkthrough.md</automated>
  </verify>
  <acceptance_criteria>
    - File `tests/manual/test_repaste_walkthrough.md` exists
    - First line is `# Manual Test: Re-paste hotkey cmd+shift+v (QOL-01)` (H1)
    - File contains `**Requirement:** QOL-01`
    - File contains `## Prerequisites` or `**Prerequisites:**` block
    - File contains `## Steps` heading with numbered steps (at least 8)
    - File contains the literal `cmd+shift+v` (the binding under test)
    - File contains `nothing to re-paste yet` (the D-04 nil-state alert text)
    - File contains `PASS-1`, `PASS-2`, AND `PASS-3` (three pass markers)
    - File contains `## Failure modes` section
    - File contains `## Sign-off` section with `Tester:` placeholder
    - File contains a reference to `lastTranscript` (so reader understands the storage mechanism)
    - File contains a reference to Hammerspoon reload (testing nil-state)
    - File mentions VS Code/Cursor cmd+shift+v collision OR Markdown Preview (RESEARCH.md Pitfall 2 documented for tester)
    - File mentions fn-hold or F19 (recording trigger after Plan 04-01 removes cmd+shift+e)
  </acceptance_criteria>
  <done>
    `tests/manual/test_repaste_walkthrough.md` is a complete, structured manual walkthrough scaffold — Oliver can execute it as-is to sign off QOL-01 after Plan 04-01 lands.
  </done>
</task>

<task type="auto">
  <name>Task 0-3: Create tests/manual/test_f19_walkthrough.md (QOL-NEW-01 manual scaffold — Karabiner positive path)</name>
  <read_first>
    - tests/manual/test_clipboard_restore.md (scaffold structure)
    - tests/manual/test_audio_cues.md (push-and-hold lifecycle walkthrough idiom)
    - .planning/phases/04-quality-of-life-v1-x/04-CONTEXT.md §decisions D-05, D-06, D-09
    - .planning/phases/04-quality-of-life-v1-x/04-RESEARCH.md §"Pitfall 1" (200ms threshold tuning) and §"Pitfall 3" (Karabiner driver/extension grant — silent failure if user skips)
    - .planning/phases/04-quality-of-life-v1-x/04-VALIDATION.md "Manual-Only Verifications" rows for QOL-NEW-01
  </read_first>
  <files>tests/manual/test_f19_walkthrough.md</files>
  <action>
    Create the QOL-NEW-01 positive-path manual walkthrough scaffold. Required content:

    **H1:** `# Manual Test: F19 hotkey via Karabiner fn-remap (QOL-NEW-01)`

    **Requirement:** `**Requirement:** QOL-NEW-01 — Replace cmd+shift+e with F19 push-and-hold. Karabiner-Elements remaps fn -> F19 via `assets/karabiner-fn-to-f19.json` (200ms hold threshold; tap routes back to macOS native fn behaviour).`

    **Prerequisites:** numbered list:
    1. Plan 04-02 complete: `assets/karabiner-fn-to-f19.json` exists; `setup.sh` Step 9 runs successfully.
    2. Karabiner-Elements installed at `/Applications/Karabiner-Elements.app` (download from https://karabiner-elements.pqrs.org/ — version >= 15.5.0 to avoid Sequoia 15.1.0 to_if_alone regression; cask 15.9.0 verified working as of 2026-04-30).
    3. Karabiner driver/extension grant completed (System Settings -> Privacy & Security -> "Allow software from Fumihiko Takayama" enabled; Karabiner-Elements.app launched once after grant; Karabiner menubar icon visible — RESEARCH.md Pitfall 3).
    4. `Hold fn → F19 (PurpleVoice push-to-talk)` rule imported and enabled in Karabiner -> Preferences -> Complex Modifications.
    5. Plan 04-01 complete: `purplevoice-lua/init.lua` has `hs.hotkey.bind({}, "f19", onPress, onRelease)` (and the cmd+shift+e binding REMOVED).
    6. Hammerspoon reloaded after Plan 04-01 changes; module-load alert reads `PurpleVoice loaded — F19 to record, ⌘⇧V to re-paste`.
    7. Microphone + Accessibility granted to Hammerspoon.

    **## Steps:**
    1. Open TextEdit (or any text editor). Click into a document.
    2. **Hold-and-record (positive path):** Press and hold fn for ~2 seconds. Say "this is the F19 push-to-talk test". Release fn. Within ~2 seconds, the transcript pastes. **PASS-1:** F19 hold triggers recording; release stops recording; transcript pastes.
    3. **Tap preserves Globe popup (or Dictation, or function-key row — depends on macOS Keyboard settings):** Tap fn briefly (< 200 ms) WITHOUT holding. Expected: macOS's native fn behaviour fires (the Globe / Emoji popup, OR the dictation panel, OR the function-key row remains accessible — varies by `System Settings -> Keyboard -> Press 🌐 key to`). PurpleVoice must NOT begin recording. **PASS-2:** quick fn-tap routes to macOS, not PurpleVoice.
    4. **cmd+shift+e is silent (negative regression):** Press cmd+shift+e. Expected: nothing happens — no recording, no menubar change, no HUD pill. The cmd+shift+e binding was removed in Plan 04-01 per D-05 ("F19 only — no fallback"). **PASS-3:** cmd+shift+e is dead.
    5. **VS Code/Cursor "Show Explorer" no longer hijacked:** Open VS Code (or Cursor). Press cmd+shift+e. Expected: the IDE's "Show Explorer" command opens normally — Hammerspoon no longer intercepts cmd+shift+e (the original collision that motivated QOL-NEW-01). **PASS-4:** the original VS Code/Cursor collision is resolved.
    6. **200ms threshold sanity (RESEARCH.md Pitfall 1 tuning anchor):** Record 5 utterances in a row (steps 2-style hold-record-release cycles). Note any false-positive (a tap accidentally crossed 200 ms) or perceived lag (held for >300 ms before recording started). If either is reported, document specifics in the Sign-off section so a follow-up can adjust the threshold by ± 50 ms (`assets/karabiner-fn-to-f19.json` -> `parameters.basic.to_if_held_down_threshold_milliseconds` and `basic.to_if_alone_timeout_milliseconds`). **PASS-5:** 200 ms threshold feels right (or adjustment notes captured).

    **## Expected Outcome:** Five PASS markers signal F19 push-to-talk works, fn-tap preserves macOS native behaviour, cmd+shift+e is fully dead, the IDE collision is resolved, and 200 ms feels right (or actionable adjustment is captured).

    **## Failure modes:**
    - Step 2 nothing happens -> Karabiner daemon not running. Check Karabiner menubar icon. If absent, the driver grant was skipped — re-launch Karabiner-Elements.app, accept the system-extension prompt (Privacy & Security -> "Allow software from Fumihiko Takayama"), restart Karabiner-Elements (RESEARCH.md Pitfall 3).
    - Step 2 nothing happens but Karabiner IS running -> rule not enabled. Open Karabiner-Elements -> Preferences -> Complex Modifications -> verify `Hold fn → F19 (PurpleVoice push-to-talk)` is in the enabled list (toggle the Enable button if not).
    - Step 2 nothing happens, rule enabled -> Hammerspoon F19 binding not registered. Check Hammerspoon console for `PurpleVoice: F19 binding failed (Karabiner fn→F19 rule active?)` alert at module load. Reload Hammerspoon. Verify the new `hs.hotkey.bind({}, "f19", ...)` line is present in the loaded init.lua via `hs -c 'print(hs.inspect(hs.hotkey.getHotkeys()))'`.
    - Step 3 fn-tap triggers PurpleVoice recording -> threshold too short (<200ms is being crossed by quick taps). Adjust both `to_if_alone_timeout_milliseconds` AND `to_if_held_down_threshold_milliseconds` upward by 50 ms in `assets/karabiner-fn-to-f19.json`, re-import the rule via Karabiner UI, retest.
    - Step 3 Globe popup never appears no matter what -> macOS Keyboard setting is "Do nothing" for Press 🌐 key to. This is fine — different users have different Globe-key bindings; the test passes if PurpleVoice does NOT trigger on the tap (the macOS-native fn behaviour is whatever the user has configured, including no-op).
    - Step 4 cmd+shift+e still triggers PurpleVoice -> Plan 04-01's binding-removal was incomplete. Re-grep `purplevoice-lua/init.lua` for `cmd", *"shift"\}, *"e"`; remove. Reload Hammerspoon.

    **## Sign-off:** checkboxes for PASS-1..PASS-5, then `**Tester:** _____________  **Date:** _____________  **200 ms threshold notes:** _____________`.

    Do NOT pre-fill any sign-off fields — Plan 04-02 fills them after Oliver runs the live walkthrough.
  </action>
  <verify>
    <automated>test -f tests/manual/test_f19_walkthrough.md && grep -q "QOL-NEW-01" tests/manual/test_f19_walkthrough.md && grep -q "F19" tests/manual/test_f19_walkthrough.md && grep -q "Karabiner" tests/manual/test_f19_walkthrough.md && grep -q "PASS-5" tests/manual/test_f19_walkthrough.md && grep -q "200" tests/manual/test_f19_walkthrough.md</automated>
  </verify>
  <acceptance_criteria>
    - File `tests/manual/test_f19_walkthrough.md` exists
    - First line H1 contains `QOL-NEW-01` and `F19`
    - File contains `**Requirement:** QOL-NEW-01`
    - File contains `## Prerequisites` or `**Prerequisites:**` block listing Karabiner install + driver grant + rule import + Plan 04-01 + Plan 04-02 dependencies
    - File contains `## Steps` heading
    - File contains `PASS-1`, `PASS-2`, `PASS-3`, `PASS-4`, AND `PASS-5` (5 pass markers)
    - File mentions `fn` (the source key being remapped)
    - File mentions `Karabiner-Elements.app` or `Karabiner-Elements` (the dependency)
    - File mentions `200` (the hold-threshold value being validated)
    - File mentions `cmd+shift+e` (the deliberately-removed binding being regression-tested)
    - File mentions VS Code or Cursor (the original collision being verified resolved)
    - File contains `## Failure modes` section
    - File contains `## Sign-off` with `Tester:` placeholder and `200 ms threshold notes:` field for the empirical-validation finding
  </acceptance_criteria>
  <done>
    `tests/manual/test_f19_walkthrough.md` is a complete 5-PASS manual walkthrough scaffold covering positive F19 trigger + fn-tap preservation + cmd+shift+e removal + IDE collision resolution + 200 ms tuning anchor. Ready for Oliver's live sign-off after Plan 04-02 lands.
  </done>
</task>

<task type="auto">
  <name>Task 0-4: Create tests/manual/test_setup_karabiner_missing.md (QOL-NEW-01 negative-control walkthrough)</name>
  <read_first>
    - tests/manual/test_clipboard_restore.md (scaffold structure)
    - .planning/phases/04-quality-of-life-v1-x/04-RESEARCH.md §5 "setup.sh Step 9 (full)" — for the actionable-error wording the tester verifies
    - .planning/phases/04-quality-of-life-v1-x/04-CONTEXT.md §decisions D-07, D-08
    - .planning/phases/04-quality-of-life-v1-x/04-VALIDATION.md "Manual-Only Verifications" row for setup.sh Step 9
  </read_first>
  <files>tests/manual/test_setup_karabiner_missing.md</files>
  <action>
    Create the QOL-NEW-01 negative-control walkthrough scaffold. Required content:

    **H1:** `# Manual Test: setup.sh Step 9 actionable error when Karabiner-Elements missing (QOL-NEW-01)`

    **Requirement:** `**Requirement:** QOL-NEW-01 — setup.sh Step 9 refuses to declare install complete when /Applications/Karabiner-Elements.app is absent. Prints actionable instructions (download URL, JSON rule path, 5-step install procedure, air-gap fallback per D-08) and exits non-zero.`

    **Prerequisites:** numbered list:
    1. Plan 04-02 complete: `setup.sh` contains Step 9 (Karabiner-Elements check) BEFORE the final banner; `assets/karabiner-fn-to-f19.json` exists.
    2. Karabiner-Elements currently installed at `/Applications/Karabiner-Elements.app` (we will temporarily move it aside).
    3. **WARNING:** This walkthrough requires `sudo` to move a system .app aside. Restoring at the end is mandatory; do NOT skip the restore step or your machine loses the F19 hotkey.
    4. Familiarity with macOS Recovery Mode is recommended in case of unexpected issues — though `sudo mv` to/from `/Applications/` is reversible without recovery.

    **## Steps:**
    1. Verify baseline: `bash setup.sh` runs to completion (exit 0); the final banner mentions `setup complete`. **BASELINE-OK.**
    2. Move Karabiner-Elements.app aside: `sudo mv /Applications/Karabiner-Elements.app /tmp/Karabiner-Elements.app.parked`
    3. Verify the move: `ls -la /Applications/Karabiner-Elements.app` should report "No such file or directory"; `ls -la /tmp/Karabiner-Elements.app.parked` should show the bundle directory.
    4. Run setup: `bash setup.sh; echo "EXIT=$?"`
    5. Expected: setup.sh runs prior steps to completion, then at Step 9 prints a multi-line actionable error to stderr containing:
       - `PurpleVoice: Karabiner-Elements is required for the F19 hotkey.`
       - URL `https://karabiner-elements.pqrs.org/`
       - 5-step numbered install procedure (Download / Drag to /Applications / Launch + grant / Import JSON / Re-run setup.sh)
       - Reference to `assets/karabiner-fn-to-f19.json` (the bundled JSON rule path)
       - Air-gap note: `If air-gapped: copy Karabiner-Elements.dmg from a connected machine via USB`
       - Exit code: `EXIT=1`
       **PASS-1:** actionable error printed; exit code is non-zero.
    6. Restore Karabiner: `sudo mv /tmp/Karabiner-Elements.app.parked /Applications/Karabiner-Elements.app`
    7. Verify restore: `ls -la /Applications/Karabiner-Elements.app` shows the bundle directory; Karabiner-Elements menubar icon returns (may need to launch the .app once if the daemon was killed during the move).
    8. Re-run setup: `bash setup.sh; echo "EXIT=$?"`
    9. Expected: setup.sh runs to completion (exit 0); Step 9 prints `OK: Karabiner-Elements detected at /Applications/Karabiner-Elements.app` followed by the import-rule REMINDER. **PASS-2:** restore returns to baseline OK.

    **## Expected Outcome:**
    - Step 5: actionable error with all required content; EXIT=1.
    - Step 9: baseline restored; EXIT=0.

    **## Failure modes:**
    - Step 5 EXIT=0 (setup.sh did not refuse) -> Step 9 was added without `exit 1`. Re-check `setup.sh` Step 9 — verify the `if [ ! -d /Applications/Karabiner-Elements.app ]; then ... exit 1; fi` block.
    - Step 5 prints terse one-line error -> Step 9 was added but the actionable instructions are missing or truncated. Re-check the heredoc content matches RESEARCH.md §5 verbatim.
    - Step 5 the prior banner `setup complete` printed BEFORE the Karabiner check fired -> Step ordering is wrong. The Karabiner check must run AFTER all dep checks but BEFORE the final banner. Per RESEARCH.md §5 (Option A): banner is the LAST step; Karabiner check is Step 9 inserted between Step 8 SBOM regen and the banner. Re-order setup.sh.
    - Step 7 Karabiner menubar icon does not return -> Karabiner daemon needs a re-launch. Open `/Applications/Karabiner-Elements.app` from Finder; the daemon will spawn the menubar icon. If that fails, log out and back in.
    - Cannot restore (sudo password forgotten / `/tmp/` cleared) -> re-download Karabiner-Elements.dmg from https://karabiner-elements.pqrs.org/ and reinstall fresh.

    **## Sign-off:** checkboxes for BASELINE-OK / PASS-1 / PASS-2, then `**Tester:** _____________  **Date:** _____________`.

    Do NOT pre-fill sign-off fields — Plan 04-02 fills after Oliver runs.
  </action>
  <verify>
    <automated>test -f tests/manual/test_setup_karabiner_missing.md && grep -q "QOL-NEW-01" tests/manual/test_setup_karabiner_missing.md && grep -q "Karabiner-Elements" tests/manual/test_setup_karabiner_missing.md && grep -q "sudo mv" tests/manual/test_setup_karabiner_missing.md && grep -q "PASS-2" tests/manual/test_setup_karabiner_missing.md && grep -q "EXIT=1" tests/manual/test_setup_karabiner_missing.md</automated>
  </verify>
  <acceptance_criteria>
    - File `tests/manual/test_setup_karabiner_missing.md` exists
    - First line H1 contains `QOL-NEW-01` AND `Karabiner` AND `setup.sh` (or `Step 9`)
    - File contains `**Requirement:** QOL-NEW-01`
    - File contains `## Prerequisites` block warning about sudo + restore-mandatory
    - File contains `sudo mv /Applications/Karabiner-Elements.app /tmp/` (the parking command)
    - File contains `sudo mv /tmp/Karabiner-Elements.app.parked /Applications/Karabiner-Elements.app` (the restore command)
    - File contains `bash setup.sh` (the command under test)
    - File contains `EXIT=1` (expected non-zero exit on Karabiner-missing branch)
    - File contains `karabiner-elements.pqrs.org` (URL the actionable error must include)
    - File contains `assets/karabiner-fn-to-f19.json` (file path the actionable error must reference)
    - File contains `BASELINE-OK`, `PASS-1`, AND `PASS-2` (3 pass markers)
    - File contains `## Failure modes` section
    - File contains `## Sign-off` with `Tester:` placeholder
  </acceptance_criteria>
  <done>
    `tests/manual/test_setup_karabiner_missing.md` is a complete negative-control walkthrough — Oliver can execute the parked-app procedure to sign off setup.sh's Karabiner-missing branch after Plan 04-02 lands. The walkthrough is reversible by design (restore step is mandatory + documented).
  </done>
</task>

<task type="auto">
  <name>Task 0-5: Update .planning/REQUIREMENTS.md — promote QOL-01 to v1, add QOL-NEW-01, update traceability + coverage stats + v2 path rebrands</name>
  <read_first>
    - .planning/REQUIREMENTS.md (full file — read offset 70-186 specifically for Quality of Life sections, Traceability table, Coverage Summary, per-phase counts)
    - .planning/phases/04-quality-of-life-v1-x/04-CONTEXT.md §decisions D-01 (scope = QOL-01 + QOL-NEW-01 only), D-02..D-08 (locked language for QOL-01 + QOL-NEW-01), D-10 (deferred-items path/var rebrand)
    - .planning/phases/04-quality-of-life-v1-x/04-RESEARCH.md §"Phase Requirements" table for the exact concrete-language descriptions
  </read_first>
  <files>.planning/REQUIREMENTS.md</files>
  <action>
    Apply five edits to `.planning/REQUIREMENTS.md` per the verbatim spec in the `<reference_data>` block above (`REQUIREMENTS.md edits (Task 0-5)`):

    **Edit 1:** REMOVE the v2-stub line `- **QOL-01**: Paste-last-transcript hotkey ...` from `## v2 Requirements / ### Quality of Life` (currently around line 82). The v1 promotion happens in Edit 2.

    **Edit 2:** ADD a new v1 subsection `### Quality of Life` placed between `### Hover UI / HUD` and `## v2 Requirements`. Contains two checkbox rows — QOL-01 (concrete language: cmd+shift+v + in-memory cache + nil-state alert) and QOL-NEW-01 (F19 binding + Karabiner JSON + setup.sh Step 9 + offline mode interaction). Both `[ ]` Pending. Use the verbatim text from `<reference_data>` -> "Section to ADD: New v1 subsection".

    **Edit 3:** REPLACE the 5 v2 QOL-* rows in the `## Traceability` table (currently lines 161-165) with the 6 new rows from `<reference_data>` -> "Section to MODIFY: ## Traceability table". Order: QOL-01 Pending, QOL-NEW-01 Pending, then QOL-02..05 Deferred (with rationale-in-cell pointing at CONTEXT.md D-01).

    **Edit 4:** UPDATE the Coverage stats lines (currently 169-181) per `<reference_data>` -> "Section to MODIFY: Coverage stats":
    - Line 170: bump `39 total` -> `41 total`; update parenthetical to mention QOL-01 promotion + QOL-NEW-01 addition
    - Line 171: bump `Mapped to phases: 39 / 39` -> `41 / 41`
    - Line 173: drop count from 7 to 6; rephrase v2 list to reflect 4 deferred QOLs (with `purplevoice` namespace per D-10) + 2 PERF
    - ADD a new per-phase counts row at end (after line 181 "Phase 3.5: Hover UI / HUD"): `- Phase 4 (v1.x): Quality of Life — 2 requirements (QOL-01, QOL-NEW-01) — Pending`

    **Edit 5:** UPDATE the remaining v2 QOL stubs (QOL-03, QOL-04, QOL-05 at current lines 84-86) to use `purplevoice` paths/vars per CONTEXT.md D-10 rebrand directive. Use the verbatim replacement text from `<reference_data>` -> "Section to MODIFY: ## v2 Requirements -> ### Quality of Life". (QOL-02 is unchanged — no path/var to rebrand.) Each rebranded row gains an italic `*(deferred — Phase 4 D-01 / D-10 rebrand applied)*` marker.

    **CRITICAL — DO NOT mark QOL-01 / QOL-NEW-01 as `[x]` Complete in this Wave 0 task.** They are `[ ]` Pending until Phase 4 closes (Plan 04-02 final closure task uses `gsd-tools requirements mark-complete` to flip them). Wave 0 stages stubs only.

    **CRITICAL — DO NOT touch the existing CAP / TRA / INJ / FBK / ROB / DST / BRD / SEC / HUD sections** — those are unrelated to Phase 4.

    After edits, sanity check: `grep -c 'QOL-NEW-01' .planning/REQUIREMENTS.md` should return >= 3 (one in the new v1 subsection, one in the Traceability table, one in the Per-phase counts comment if cited there).
  </action>
  <verify>
    <automated>grep -q "QOL-NEW-01" .planning/REQUIREMENTS.md && grep -qE '^\- \[ \] \*\*QOL-01\*\*: Paste-last-transcript hotkey \(`cmd\+shift\+v`\)' .planning/REQUIREMENTS.md && grep -qE '^\- \[ \] \*\*QOL-NEW-01\*\*' .planning/REQUIREMENTS.md && grep -qE '\| QOL-NEW-01 .* Pending' .planning/REQUIREMENTS.md && grep -qE 'v1 requirements: 41 total' .planning/REQUIREMENTS.md && grep -qE '~/\.config/purplevoice/replacements\.txt' .planning/REQUIREMENTS.md && grep -qE 'PURPLEVOICE_MODEL' .planning/REQUIREMENTS.md && ! grep -qE '~/\.config/voice-cc/replacements\.txt' .planning/REQUIREMENTS.md && ! grep -qE 'VOICE_CC_MODEL' .planning/REQUIREMENTS.md && bash tests/test_brand_consistency.sh</automated>
  </verify>
  <acceptance_criteria>
    - `.planning/REQUIREMENTS.md` contains `QOL-NEW-01` (at least 3 occurrences: v1 subsection + Traceability + per-phase row)
    - File contains the v1 row `- [ ] **QOL-01**: Paste-last-transcript hotkey (`cmd+shift+v`)` (Pending status, concrete language, NOT just the v2 stub)
    - File contains the v1 row `- [ ] **QOL-NEW-01**: F19 alt hotkey replaces` (or similar — concrete language per `<reference_data>`)
    - File NO LONGER contains the v2 stub `- **QOL-01**: Paste-last-transcript hotkey re-pastes` (the un-promoted v2 line is removed)
    - Traceability table contains row `| QOL-01 | Phase 4 (v1.x): Quality of Life | Pending |`
    - Traceability table contains row `| QOL-NEW-01 | Phase 4 (v1.x): Quality of Life | Pending |`
    - Traceability table rows for QOL-02, QOL-03, QOL-04, QOL-05 are marked `Deferred` (NOT `Pending`) with rationale referencing CONTEXT.md D-01 or "no real-use trigger"
    - Coverage stats: `v1 requirements: 41 total` (bumped from 39)
    - Coverage stats: `Mapped to phases: 41 / 41 (100%)`
    - Coverage stats: `v2 requirements: 6 total` (dropped from 7 — QOL-01 promoted out)
    - Per-phase counts contains `Phase 4 (v1.x): Quality of Life — 2 requirements (QOL-01, QOL-NEW-01)` row
    - QOL-03 stub (in v2 section) references `~/.config/purplevoice/replacements.txt` (NOT `~/.config/voice-cc/replacements.txt`)
    - QOL-04 stub references `~/.cache/purplevoice/history.log` (NOT `~/.cache/voice-cc/history.log`)
    - QOL-05 stub references `PURPLEVOICE_MODEL` (NOT `VOICE_CC_MODEL`)
    - `bash tests/test_brand_consistency.sh` exits 0 (REQUIREMENTS.md is on test exemption list — but the rebrand of QOL-03/04/05 stubs eliminates legacy `voice-cc` strings even from .planning/ which is good hygiene)
    - `bash tests/run_all.sh` continues to report 10 PASS + 1 FAIL (the Wave-0 RED `test_karabiner_check.sh` is the only new failure; existing 10 still GREEN)
    - QOL-01 and QOL-NEW-01 rows are `[ ]` Pending — NOT `[x]` Complete (Wave 0 only stages stubs; Plan 04-02 closes)
  </acceptance_criteria>
  <done>
    `.planning/REQUIREMENTS.md` reflects Phase 4 scope: QOL-01 promoted from v2 stub to v1 with concrete language; QOL-NEW-01 added as new v1 row; both `[ ]` Pending with traceability and coverage stats updated; QOL-02..05 explicitly marked Deferred with rationale; remaining v2 QOL stubs use `purplevoice` paths/vars per D-10. Brand consistency test still passes.
  </done>
</task>

</tasks>

<verification>
After all 5 tasks complete:

```bash
# 1. New test file exists, parses, fails as expected (RED at Wave 0)
test -f tests/test_karabiner_check.sh
bash -n tests/test_karabiner_check.sh
bash tests/test_karabiner_check.sh; echo "test_karabiner_check exit: $?"  # MUST be 1

# 2. All 3 manual scaffolds exist with required content
test -f tests/manual/test_repaste_walkthrough.md
test -f tests/manual/test_f19_walkthrough.md
test -f tests/manual/test_setup_karabiner_missing.md
grep -l "QOL-01" tests/manual/test_repaste_walkthrough.md
grep -l "QOL-NEW-01" tests/manual/test_f19_walkthrough.md
grep -l "QOL-NEW-01" tests/manual/test_setup_karabiner_missing.md

# 3. REQUIREMENTS.md updates
grep -E '^\- \[ \] \*\*QOL-NEW-01\*\*' .planning/REQUIREMENTS.md  # new row exists
grep -E '^\- \[ \] \*\*QOL-01\*\*: Paste-last-transcript hotkey \(`cmd\+shift\+v`\)' .planning/REQUIREMENTS.md  # promoted with concrete language
grep -E 'v1 requirements: 41 total' .planning/REQUIREMENTS.md  # coverage stat
grep -E '~/\.config/purplevoice/replacements\.txt' .planning/REQUIREMENTS.md  # D-10 rebrand applied
! grep -E '~/\.config/voice-cc/replacements\.txt' .planning/REQUIREMENTS.md  # legacy gone

# 4. Suite state — 10 prior PASS still green; 1 new FAIL (Wave 0 RED)
bash tests/run_all.sh; echo "run_all exit: $?"  # MUST be 1 (1 new FAIL on test_karabiner_check.sh)

# 5. Security suite unchanged (Phase 4 does not touch security infrastructure)
bash tests/security/run_all.sh; echo "security exit: $?"  # MUST be 0 (5/5 GREEN)

# 6. Brand consistency intact — REQUIREMENTS.md is on exemption list, but the
#    QOL-03/04/05 rebrand removes voice-cc strings even from there
bash tests/test_brand_consistency.sh; echo "brand exit: $?"  # MUST be 0

# 7. Pattern 2 invariants unchanged — no purplevoice-record / init.lua edits in Wave 0
[ "$(grep -c WHISPER_BIN purplevoice-record)" = "2" ]
! grep -q whisper-cli purplevoice-lua/init.lua
```

Expected end state: 10 PASS + 1 FAIL functional (`test_karabiner_check.sh` RED — by design); 5/5 security GREEN; brand consistency GREEN; Pattern 2 invariants intact.
</verification>

<success_criteria>
- All 5 task `<acceptance_criteria>` blocks satisfied
- `tests/test_karabiner_check.sh` exists, has 8 string-level checks, RED at commit (exit 1) — proving the contract handoff to Plan 04-01
- 3 manual walkthrough scaffolds exist (`test_repaste_walkthrough.md`, `test_f19_walkthrough.md`, `test_setup_karabiner_missing.md`) — phase-gate sign-off targets
- REQUIREMENTS.md: QOL-01 promoted from v2 stub to v1 with concrete language; QOL-NEW-01 added; coverage 39 -> 41; v2 QOL stubs rebranded with `purplevoice` paths/vars; both new rows `[ ]` Pending (Plan 04-02 closes)
- `bash tests/run_all.sh` reports 10 PASS + 1 FAIL (the Wave-0 RED `test_karabiner_check.sh`)
- `bash tests/security/run_all.sh` still reports 5/0 GREEN (no security infrastructure touched)
- Pattern 2 invariants intact: `grep -c WHISPER_BIN purplevoice-record == 2` AND `! grep -q whisper-cli purplevoice-lua/init.lua`
- Brand consistency lint stays GREEN
</success_criteria>

<output>
After completion, create `.planning/phases/04-quality-of-life-v1-x/04-00-SUMMARY.md` covering:
- 5 task outcomes (each with file path + line count + key invariants)
- The intentional RED-at-Wave-0 state of `tests/test_karabiner_check.sh` (8 checks, all FAIL until Plans 04-01 + 04-02 land)
- Suite state: 10/1 functional (1 new RED expected), 5/0 security, brand+framing GREEN
- Confirmation that REQUIREMENTS.md QOL-01 / QOL-NEW-01 are `[ ]` Pending (not yet `[x]` — Plan 04-02 closes)
- Any deviations (Rule 1 auto-fixes) recorded with root cause + same-pattern reference
- Handoff note for Plan 04-01: which 3 of the 8 test_karabiner_check.sh assertions Plan 04-01 turns GREEN (checks 6, 7, 8)
</output>
