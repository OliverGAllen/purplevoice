---
phase: 04-quality-of-life-v1-x
plan: 01
type: execute
wave: 1
depends_on:
  - "04-00"
files_modified:
  - purplevoice-lua/init.lua
autonomous: false
requirements:
  - QOL-01
  - QOL-NEW-01

must_haves:
  truths:
    - "Holding F19 (after Karabiner fn->F19 rule active) triggers PurpleVoice recording exactly as cmd+shift+e previously did (push-and-hold semantics preserved)"
    - "Pressing cmd+shift+v after a successful transcription re-pastes the same transcript into the focused window"
    - "Pressing cmd+shift+v before any successful recording (post-reload) shows brief alert 'PurpleVoice: nothing to re-paste yet' for ~1.5s — no crash, no paste"
    - "Pressing cmd+shift+e does nothing — the binding is removed, not supplemented (per CONTEXT.md D-05)"
    - "tests/test_karabiner_check.sh checks 6, 7, 8 turn GREEN after this plan (F19 binding present, cmd+shift+v binding present, cmd+shift+e binding absent)"
    - "Module-load alert reads 'PurpleVoice loaded — F19 to record, ⌘⇧V to re-paste' (or ASCII fallback) — not the prior cmd+shift+e text"
    - "Header comment on init.lua line 2 is updated from the cmd+shift+e wording to F19 (Karabiner-remapped from fn) — ZERO `cmd+shift+e` references remain anywhere in init.lua, including comments/headers"
  artifacts:
    - path: "purplevoice-lua/init.lua"
      provides: "F19 push-and-hold binding + cmd+shift+v re-paste binding + lastTranscript module-scope cache + nil-state alert + updated module-load alert text + updated line-2 header comment"
      contains: "lastTranscript"
  key_links:
    - from: "purplevoice-lua/init.lua hs.hotkey.bind({}, \"f19\", ...) line"
      to: "onPress / onRelease callbacks (existing line ~471 / ~499)"
      via: "Lua local function reference"
      pattern: "hs\\.hotkey\\.bind\\(\\{\\}, ?\"f19\", ?onPress, ?onRelease\\)"
    - from: "purplevoice-lua/init.lua pasteWithRestore() success path"
      to: "module-scope local lastTranscript"
      via: "lastTranscript = transcript assignment after hs.eventtap.keyStroke({\"cmd\"}, \"v\", 0)"
      pattern: "lastTranscript = transcript"
    - from: "purplevoice-lua/init.lua hs.hotkey.bind({\"cmd\", \"shift\"}, \"v\", repaste) line"
      to: "repaste() function reading lastTranscript"
      via: "Lua local function reference"
      pattern: "hs\\.hotkey\\.bind\\(\\{\"cmd\", ?\"shift\"\\}, ?\"v\""
---

<objective>
Land the Lua-side core of Phase 4 in a single surgical edit to `purplevoice-lua/init.lua`:

1. Add `local lastTranscript = nil` at module scope (alongside `isRecording` / `currentTask`)
2. Cache `lastTranscript = transcript` inside `pasteWithRestore()` AFTER the cmd+v keystroke fires (D-03: in-memory only; gated on non-empty by the function's existing guard)
3. Define a `repaste()` local function with nil-check + brief alert
4. REPLACE the existing `hs.hotkey.bind({"cmd", "shift"}, "e", onPress, onRelease)` with `hs.hotkey.bind({}, "f19", onPress, onRelease)` (D-05: no fallback; deliberate replacement)
5. ADD `hs.hotkey.bind({"cmd", "shift"}, "v", repaste)` immediately after the F19 binding
6. Update the module-load alert text from `"PurpleVoice loaded — local dictation, cmd+shift+e"` to `"PurpleVoice loaded — F19 to record, ⌘⇧V to re-paste"` (RESEARCH.md Pitfall 6)
7. Update the F19 binding's failure-alert from the cmd+shift+e wording to `"PurpleVoice: F19 binding failed (Karabiner fn→F19 rule active?)"` (RESEARCH.md §3)

**Purpose:** Deliver the user-facing behaviour change for both QOL-01 (re-paste) and QOL-NEW-01 (F19 trigger) in one Hammerspoon module edit. After this plan reloads cleanly:
- Holding fn (with Karabiner rule active — landed in Plan 04-02) triggers recording — the original VS Code/Cursor cmd+shift+e collision is resolved
- cmd+shift+v re-pastes the cached `lastTranscript` (or shows nil-state alert post-reload)
- cmd+shift+e is dead

**Output:** Modified `purplevoice-lua/init.lua` with 7 surgical edits (combined into 4 tasks); `tests/test_karabiner_check.sh` advances from 0/8 GREEN to 3/8 GREEN (checks 6, 7, 8). The remaining 5 checks (assets/karabiner-fn-to-f19.json + setup.sh Step 9) await Plan 04-02.

**autonomous: false** — Includes a `checkpoint:human-verify` task for the live re-paste walkthrough on Oliver's machine.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/04-quality-of-life-v1-x/04-CONTEXT.md
@.planning/phases/04-quality-of-life-v1-x/04-RESEARCH.md
@.planning/phases/04-quality-of-life-v1-x/04-VALIDATION.md
@.planning/phases/04-quality-of-life-v1-x/04-00-SUMMARY.md

# Existing Lua module — read in FULL before editing
@purplevoice-lua/init.lua

# Wave 0 contracts this plan satisfies (3 of 8 checks turn GREEN)
@tests/test_karabiner_check.sh
@tests/manual/test_repaste_walkthrough.md

<interfaces>
<!-- Existing init.lua structure (line numbers verified 2026-04-30 against the live file) -->

Line 2 — Header comment (Phase 1; Phase 4 REPLACES wording):
```lua
-- Wires cmd+shift+e (push-and-hold) to ~/.local/bin/purplevoice-record.
```
Phase 4 REPLACEMENT (Task 1-4 Edit C): replace this single line with the F19 wording (verbatim spec in `<reference_data>` §F). This is one of the 4 lines that contain the literal string `cmd+shift+e` (verified by `grep -c 'cmd+shift+e' purplevoice-lua/init.lua` returning 4 prior to this plan); the Task 1-4 acceptance gate REQUIRES that count to drop to 0, so the line-2 header MUST be updated alongside the binding (lines 510, 514) and the module-load alert (line 545).

Lines 90-91 — Module state block (Phase 2 hardening):
```lua
local isRecording = false
local currentTask = nil
```
Phase 4 INSERT POINT: add `local lastTranscript = nil` here (new line 92, after currentTask).

Lines 376-409 — pasteWithRestore() function (Phase 2 INJ-02 + INJ-03):
```lua
local function pasteWithRestore(transcript)
  if not transcript or transcript:match("^%s*$") then
    return  -- defence-in-depth empty drop (bash should have caught via exit 3)
  end
  local pendingSaved = hs.pasteboard.readAllData()
  hs.pasteboard.writeAllData({ ... })
  hs.eventtap.keyStroke({"cmd"}, "v", 0)
  -- ↑ Phase 4 INSERT one new line here: lastTranscript = transcript
  hs.timer.doAfter(0.25, function() ... end)
end
```

Lines 471-507 — onPress / onRelease functions (Phase 2 hardening; do NOT modify; these are referenced by name from the new F19 binding).

Lines 509-515 — cmd+shift+e binding block (Phase 1 / D-01 — Phase 4 D-05 REPLACES):
```lua
-- ----------------------------------------------------------------
-- Bind cmd+shift+e (push-and-hold)
-- ----------------------------------------------------------------
local hk = hs.hotkey.bind({"cmd", "shift"}, "e", onPress, onRelease)
if not hk then
  hs.alert.show("PurpleVoice: cmd+shift+e binding failed (in use?)", 4)
end
```
Phase 4 REPLACEMENT: replace this 7-line block with the new F19 + cmd+shift+v binding pair (verbatim spec in `<reference_data>` §D).

Line 545 — module-load alert (Phase 1 / D-02; Phase 4 updates wording):
```lua
hs.alert.show("PurpleVoice loaded — local dictation, cmd+shift+e", 1.5)
```
Phase 4 REPLACEMENT: `"PurpleVoice loaded — F19 to record, ⌘⇧V to re-paste"`.
</interfaces>

<reference_data>
<!-- Verbatim Lua snippets. Use EXACTLY — do NOT paraphrase. -->

## §A — Module-scope state insertion (Task 1-1)

INSERT after line 91 (`local currentTask = nil`):
```lua
local lastTranscript = nil  -- QOL-01: in-memory cache of last successful transcript (D-03 — lost on Hammerspoon reload by design)
```

## §B — pasteWithRestore() cache update (Task 1-2)

INSERT one line between line 398 (`hs.eventtap.keyStroke({"cmd"}, "v", 0)`) and line 400 (`hs.timer.doAfter(0.25, function()`):
```lua
  lastTranscript = transcript  -- QOL-01: cache for cmd+shift+v re-paste (after paste fires; gated on non-empty by guard at line 377)
```
Indentation: 2 spaces (matches surrounding pasteWithRestore body indent).

## §C — repaste() function definition (Task 1-3)

INSERT before the existing line 509 (start of cmd+shift+e binding header comment):
```lua
-- ----------------------------------------------------------------
-- Re-paste hotkey callback (QOL-01 / D-04 — brief-alert nil-state)
-- ----------------------------------------------------------------
local function repaste()
  if lastTranscript then
    pasteWithRestore(lastTranscript)
  else
    hs.alert.show("PurpleVoice: nothing to re-paste yet", 1.5)
  end
end

```
(Trailing blank line preserves spacing convention.)

## §D — Hotkey binding replacement + addition (Task 1-4)

REPLACE lines 509-515 (the entire cmd+shift+e binding block including header comment + binding + nil-check) with:

```lua
-- ----------------------------------------------------------------
-- Bind F19 (push-and-hold) — QOL-NEW-01 / D-05 replaces cmd+shift+e
-- F19 is emitted by Karabiner-Elements remapping fn -> F19 via
-- assets/karabiner-fn-to-f19.json (Plan 04-02). Empty modifier table {}
-- is documented in hs.hotkey.bind; lowercase "f19" is canonical in
-- hs.keycodes.map. Carbon RegisterEventHotKey precedence (system-global,
-- fires before app shortcuts) means F19 reaches Hammerspoon before any
-- focused app sees it.
-- ----------------------------------------------------------------
local hk = hs.hotkey.bind({}, "f19", onPress, onRelease)
if not hk then
  hs.alert.show("PurpleVoice: F19 binding failed (Karabiner fn→F19 rule active?)", 4)
end

-- ----------------------------------------------------------------
-- Bind cmd+shift+v (re-paste last transcript) — QOL-01 / D-02
-- Collides with VS Code/Cursor "Markdown Preview" by default — accepted
-- per CONTEXT.md D-02. Hammerspoon's Carbon hotkey wins precedence over
-- the IDE shortcut; user workaround for IDE Markdown preview is Cmd+K V.
-- ----------------------------------------------------------------
local repasteHk = hs.hotkey.bind({"cmd", "shift"}, "v", repaste)
if not repasteHk then
  hs.alert.show("PurpleVoice: cmd+shift+v binding failed (in use?)", 4)
end
```

Critical correctness:
- Empty modifier table `{}` (RESEARCH.md §3 / Hammerspoon docs)
- Lowercase `"f19"` (NOT `"F19"`; canonical per hs.keycodes.map)
- `onPress` / `onRelease` callback references unchanged (existing lines 471/499)
- Two SEPARATE locals (`hk` + `repasteHk`) — preserves per-binding nil-check pattern
- F19 binding's failure-alert mentions Karabiner specifically (right diagnostic per RESEARCH.md §3)

## §E — Module-load alert text update (Task 1-5)

REPLACE line 545:
```lua
hs.alert.show("PurpleVoice loaded — local dictation, cmd+shift+e", 1.5)
```
WITH (Unicode ⌘ U+2318 + ⇧ U+21E7):
```lua
hs.alert.show("PurpleVoice loaded — F19 to record, ⌘⇧V to re-paste", 1.5)
```
ASCII fallback (only if Unicode glyphs cannot be reliably written): `"PurpleVoice loaded — F19 to record, cmd+shift+v re-paste"`. Recommendation: Unicode form. Duration `1.5` unchanged.

## §F — Line-2 header comment update (Task 1-4 Edit C — REVISION ADDITION)

REPLACE line 2 of `purplevoice-lua/init.lua`:
```lua
-- Wires cmd+shift+e (push-and-hold) to ~/.local/bin/purplevoice-record.
```
WITH:
```lua
-- Wires F19 (push-and-hold; Karabiner-remapped from fn) to ~/.local/bin/purplevoice-record.
```

Why this matters: line 2 is one of 4 occurrences of the literal string `cmd+shift+e` in the live file (verified `grep -c 'cmd+shift+e' purplevoice-lua/init.lua == 4` on 2026-04-30 — lines 2, 510, 514, 545). Task 1-4's acceptance gate REQUIRES the count to drop to 0 (per `<acceptance_criteria>` and `<verification>` §6). Edits A and B (binding block + module-load alert) cover lines 510, 514, 545 — leaving line 2 as the residual that would otherwise fail the grep at execution time. This edit is surgical (one-line replacement) and semantic (the header now correctly describes the post-Phase-4 trigger).

Indentation / leading characters: none — line begins at column 1 with `-- ` (Lua single-line comment marker). Preserve the trailing newline. Do NOT touch lines 1, 3, or any subsequent header lines.
</reference_data>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1-1: Add `local lastTranscript = nil` at module scope (init.lua line ~92)</name>
  <read_first>
    - purplevoice-lua/init.lua (read FULL file — at minimum lines 80-110 around the module-state block)
    - .planning/phases/04-quality-of-life-v1-x/04-RESEARCH.md §"Pattern 4" + §2 "Code Examples"
    - .planning/phases/04-quality-of-life-v1-x/04-CONTEXT.md §decisions D-03 (in-memory only)
  </read_first>
  <files>purplevoice-lua/init.lua</files>
  <behavior>
    - Test 1: `grep -cE '^local lastTranscript = nil' purplevoice-lua/init.lua` outputs `1` (module-scope; not nested)
    - Test 2: Line is positioned IMMEDIATELY after `local currentTask = nil` (same state-variable cluster)
    - Test 3: Line carries comment naming `QOL-01` and `D-03` (or `in-memory`)
    - Test 4: No disk-persistence wiring (no file I/O, no `~/.cache/purplevoice/last.txt` reference)
    - Test 5: Existing `local isRecording = false` and `local currentTask = nil` lines unchanged
  </behavior>
  <action>
    Per `<reference_data>` §A: INSERT exactly one new line after `local currentTask = nil` (current line 91):

    ```lua
    local lastTranscript = nil  -- QOL-01: in-memory cache of last successful transcript (D-03 — lost on Hammerspoon reload by design)
    ```

    SURGICAL one-line addition. Do NOT refactor the existing module-state block, move other vars, add disk persistence, or add accessor functions. Lua lexical scope IS the accessor.

    The nil default is meaningful: subsequent tasks (1-2 cache update, 1-3 repaste function) treat `nil` as "no transcript yet" and `non-nil` as "transcript ready to re-paste".

    After this task: `grep -c "lastTranscript" purplevoice-lua/init.lua` returns 1.
  </action>
  <verify>
    <automated>test "$(grep -cE '^local lastTranscript = nil' purplevoice-lua/init.lua)" = "1" && grep -A1 'local currentTask = nil' purplevoice-lua/init.lua | grep -q 'local lastTranscript = nil' && { bash tests/run_all.sh; rc=$?; test "$rc" = "1"; }</automated>
  </verify>
  <acceptance_criteria>
    - `grep -cE '^local lastTranscript = nil' purplevoice-lua/init.lua` outputs `1`
    - `grep -A1 'local currentTask = nil' purplevoice-lua/init.lua | grep -q 'local lastTranscript = nil'` succeeds
    - Line contains `QOL-01` and `D-03` (or `in-memory`) in its comment
    - `local isRecording = false` line still present (count = 1)
    - `grep -c "last.txt" purplevoice-lua/init.lua` outputs `0` (no disk-persistence)
    - `grep -c "io.open" purplevoice-lua/init.lua` outputs `0`
    - `! grep -q whisper-cli purplevoice-lua/init.lua` (Pattern 2 corollary intact)
    - `! grep -q voice-cc purplevoice-lua/init.lua` (brand consistency)
    - `bash tests/run_all.sh` reports 10 PASS + 1 FAIL (Wave-0 RED unchanged; checks 6/7/8 not yet GREEN)
  </acceptance_criteria>
  <done>
    `local lastTranscript = nil` declaration present at module scope, positioned in the existing state-variable cluster. No persistence wiring; nil default ready for cache-update (1-2) and nil-check (1-3).
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 1-2: Cache lastTranscript inside pasteWithRestore() success path (init.lua line ~399)</name>
  <read_first>
    - purplevoice-lua/init.lua (read FULL file — at minimum lines 376-410 around pasteWithRestore())
    - .planning/phases/04-quality-of-life-v1-x/04-RESEARCH.md §"Pattern 4" + §2 explaining WHY caching inside pasteWithRestore (NOT handleExit) is correct
    - .planning/phases/04-quality-of-life-v1-x/04-CONTEXT.md §decisions D-03
  </read_first>
  <files>purplevoice-lua/init.lua</files>
  <behavior>
    - Test 1: `grep -cE 'lastTranscript = transcript' purplevoice-lua/init.lua` outputs `1`
    - Test 2: Line is positioned AFTER `hs.eventtap.keyStroke({"cmd"}, "v", 0)` and BEFORE `hs.timer.doAfter(0.25, function()`
    - Test 3: Line is INSIDE the `pasteWithRestore` function body (gated by the existing line-377 non-empty guard)
    - Test 4: The function's existing behaviour preserved: empty/whitespace transcripts still early-return at line 377
    - Test 5: handleExit() at line 417 NOT modified (RESEARCH.md Pattern 4 — caching there would risk caching empty values; the in-pasteWithRestore guard is the correct gate)
  </behavior>
  <action>
    Per `<reference_data>` §B: INSERT exactly one new line between `hs.eventtap.keyStroke({"cmd"}, "v", 0)` (current line 398) and `hs.timer.doAfter(0.25, function()` (current line 403). Indentation: 2 spaces (matches surrounding pasteWithRestore body):

    ```lua
      lastTranscript = transcript  -- QOL-01: cache for cmd+shift+v re-paste (after paste fires; gated on non-empty by guard at line 377)
    ```

    Final state of lines 397-403:
    ```lua
      -- 3. PASTE — synthesise cmd+v into the focused app.
      hs.eventtap.keyStroke({"cmd"}, "v", 0)
      lastTranscript = transcript  -- QOL-01: cache for cmd+shift+v re-paste (after paste fires; gated on non-empty by guard at line 377)

      -- 4. RESTORE prior clipboard after 250ms — but ONLY if the clipboard still
      --    contains our transcript (defends against user copying something else
      --    in the interim, which would otherwise be clobbered).
      hs.timer.doAfter(0.25, function()
    ```

    Why position MATTERS:
    - **AFTER `hs.eventtap.keyStroke`**: only cache values actually pasted; defence-in-depth if keyStroke ever throws
    - **BEFORE `hs.timer.doAfter`**: cache update is synchronous with paste lifecycle; restore timer is async (250 ms later) and unrelated to caching
    - **INSIDE pasteWithRestore (NOT handleExit)**: pasteWithRestore's existing guard at line 377 (`if not transcript or transcript:match("^%s*$") then return end`) means empty/whitespace transcripts early-return BEFORE reaching the cache line. Caching in handleExit would risk caching `""` (empty string is truthy in Lua — `if "" then ... end` enters the block — exactly the bug we're avoiding).

    DO NOT touch handleExit at line 417. DO NOT add a separate cache path. DO NOT add a redundant `if transcript ~= "" then ... end` guard.

    After this task: `grep -c "lastTranscript" purplevoice-lua/init.lua` returns 2.
  </action>
  <verify>
    <automated>test "$(grep -cE 'lastTranscript = transcript' purplevoice-lua/init.lua)" = "1" && grep -B2 'lastTranscript = transcript' purplevoice-lua/init.lua | grep -q 'hs\.eventtap\.keyStroke' && grep -A2 'lastTranscript = transcript' purplevoice-lua/init.lua | grep -q 'hs\.timer\.doAfter' && test "$(grep -c lastTranscript purplevoice-lua/init.lua)" = "2" && { bash tests/run_all.sh; rc=$?; test "$rc" = "1"; }</automated>
  </verify>
  <acceptance_criteria>
    - `grep -cE 'lastTranscript = transcript' purplevoice-lua/init.lua` outputs `1`
    - `grep -B2 'lastTranscript = transcript' purplevoice-lua/init.lua | grep -q 'hs\.eventtap\.keyStroke'` succeeds (preceded within 2 lines by the cmd+v keystroke)
    - `grep -A2 'lastTranscript = transcript' purplevoice-lua/init.lua | grep -q 'hs\.timer\.doAfter'` succeeds (followed within 2 lines by the restore timer)
    - `grep -c lastTranscript purplevoice-lua/init.lua` outputs `2` (declaration from Task 1-1 + this assignment)
    - The `pasteWithRestore` function's empty-guard line still present: `grep -c 'transcript:match' purplevoice-lua/init.lua` outputs `1`
    - handleExit() function body is UNCHANGED: lines 417-466 contain zero `lastTranscript` references — verified by extracting the function body and grepping
    - `! grep -q whisper-cli purplevoice-lua/init.lua` (Pattern 2 corollary)
    - `! grep -q voice-cc purplevoice-lua/init.lua` (brand)
    - `bash tests/run_all.sh` reports 10 PASS + 1 FAIL (still expected RED on test_karabiner_check.sh — checks 6/7/8 not yet GREEN until Task 1-4)
  </acceptance_criteria>
  <done>
    `pasteWithRestore()` caches `lastTranscript = transcript` immediately after the cmd+v keystroke fires, gated by the function's existing non-empty guard. `handleExit()` untouched. Cache update on success path only — empty/whitespace cannot pollute.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 1-3: Define repaste() function with nil-check + brief alert (init.lua before line 510)</name>
  <read_first>
    - purplevoice-lua/init.lua (read FULL file — at minimum lines 305-516 around existing local-function definitions and the cmd+shift+e binding)
    - .planning/phases/04-quality-of-life-v1-x/04-RESEARCH.md §1 "Code Examples" (verbatim repaste pattern)
    - .planning/phases/04-quality-of-life-v1-x/04-CONTEXT.md §decisions D-04 (nil-state = brief alert recommendation)
  </read_first>
  <files>purplevoice-lua/init.lua</files>
  <behavior>
    - Test 1: `grep -cE '^local function repaste\(\)' purplevoice-lua/init.lua` outputs `1`
    - Test 2: Function body contains `if lastTranscript then` (nil-check)
    - Test 3: Non-nil branch calls `pasteWithRestore(lastTranscript)`
    - Test 4: Nil branch calls EXACTLY `hs.alert.show("PurpleVoice: nothing to re-paste yet", 1.5)`
    - Test 5: Function positioned BEFORE the hotkey binding block (Lua locals are forward-not-visible)
    - Test 6: Function is `local` (not module-scope on `M`) — matches existing convention
  </behavior>
  <action>
    Per `<reference_data>` §C: INSERT a new local function definition `repaste` IMMEDIATELY before the comment block introducing the cmd+shift+e binding (current line 509 reads `-- ----------------------------------------------------------------`). Verbatim insertion:

    ```lua
    -- ----------------------------------------------------------------
    -- Re-paste hotkey callback (QOL-01 / D-04 — brief-alert nil-state)
    -- ----------------------------------------------------------------
    local function repaste()
      if lastTranscript then
        pasteWithRestore(lastTranscript)
      else
        hs.alert.show("PurpleVoice: nothing to re-paste yet", 1.5)
      end
    end

    ```

    (Trailing blank line preserves the existing 1-blank-line spacing convention.)

    Why position MATTERS:
    - Lua locals are NOT forward-visible. `local function foo()` is only in scope from its declaration line forward. The Task 1-4 binding `hs.hotkey.bind({"cmd", "shift"}, "v", repaste)` references `repaste` by name; that reference must come AFTER this declaration.
    - Positioning between `pasteWithRestore` (ends ~line 409) and the binding block (~line 510) keeps both `repaste`'s callees (`pasteWithRestore`, `lastTranscript`) and its caller (the cmd+shift+v hotkey) in scope.

    Implementation choices (per RESEARCH.md §1):
    - Named function (NOT anonymous closure inside hs.hotkey.bind) — matches `setMenubarIdle`, `playStartCue` convention
    - Direct nil-check `if lastTranscript then` — `lastTranscript` is either nil or a string (Task 1-2's positioning means non-empty string only)
    - Alert duration 1.5s — matches module-load alert + RESEARCH.md Pitfall 6
    - Alert text EXACTLY `"PurpleVoice: nothing to re-paste yet"` — D-04 / Wave-0 walkthrough scaffold expected-outcome text

    DO NOT:
    - Make `repaste` an anonymous closure in `hs.hotkey.bind(...)` (RESEARCH.md §1 — both forms equivalent, but named matches codebase convention)
    - Add fallback for "lastTranscript is empty string" — Task 1-2's positioning makes this impossible
    - Persist `lastTranscript` to disk on the nil branch (D-03 rejected)

    After this task: `grep -c "lastTranscript" purplevoice-lua/init.lua` returns 3 (declaration + cache + nil-check).
  </action>
  <verify>
    <automated>test "$(grep -cE '^local function repaste\(\)' purplevoice-lua/init.lua)" = "1" && grep -A6 '^local function repaste()' purplevoice-lua/init.lua | grep -q 'if lastTranscript then' && grep -A6 '^local function repaste()' purplevoice-lua/init.lua | grep -q 'pasteWithRestore(lastTranscript)' && grep -A6 '^local function repaste()' purplevoice-lua/init.lua | grep -q 'PurpleVoice: nothing to re-paste yet' && test "$(grep -c lastTranscript purplevoice-lua/init.lua)" = "3" && { bash tests/run_all.sh; rc=$?; test "$rc" = "1"; }</automated>
  </verify>
  <acceptance_criteria>
    - `grep -cE '^local function repaste\(\)' purplevoice-lua/init.lua` outputs `1`
    - Function body (within 6 lines of declaration) contains `if lastTranscript then`
    - Function body contains `pasteWithRestore(lastTranscript)`
    - Function body contains EXACT string `hs.alert.show("PurpleVoice: nothing to re-paste yet", 1.5)`
    - Function appears BEFORE any `hs.hotkey.bind({"cmd", "shift"}, "v"` line (forward-visibility)
    - Function appears AFTER `local function pasteWithRestore` (so pasteWithRestore is in scope)
    - `grep -c lastTranscript purplevoice-lua/init.lua` outputs `3`
    - `grep -c "nothing to re-paste yet" purplevoice-lua/init.lua` outputs `1`
    - `! grep -q whisper-cli purplevoice-lua/init.lua` AND `! grep -q voice-cc purplevoice-lua/init.lua`
    - `bash tests/run_all.sh` reports 10 PASS + 1 FAIL (test_karabiner_check.sh checks 6/7/8 not yet GREEN until Task 1-4)
  </acceptance_criteria>
  <done>
    `repaste()` local function exists with nil-check + brief alert + non-nil paste delegation. Positioned correctly for forward-visibility to Task 1-4. Alert text EXACTLY the D-04 specified string.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 1-4: Replace cmd+shift+e binding with F19 + cmd+shift+v binding pair, update line-2 header comment, AND update module-load alert (init.lua line 2 + lines 509-545)</name>
  <read_first>
    - purplevoice-lua/init.lua (read FULL file — line 2 header comment AND lines 509-547 around the binding block AND module-load alert)
    - .planning/phases/04-quality-of-life-v1-x/04-RESEARCH.md §3 "F19 binding" + §"Pattern 3" + §"Pitfall 4: cmd+shift+v binding nil" + §"Pitfall 6: HUD module-load alert text drift"
    - .planning/phases/04-quality-of-life-v1-x/04-CONTEXT.md §decisions D-02, D-05
    - tests/test_karabiner_check.sh (verify the regex this task must satisfy: checks 6, 7, 8)
  </read_first>
  <interfaces>
    Anchor lines for the 7 surgical edits in this task (verified 2026-04-30):
    - **Line 2** (header comment) — Edit C — ONE line replacement (REVISION ADDITION; per `<reference_data>` §F)
    - **Lines 509-515** (binding block: header comment + cmd+shift+e binding + nil-check) — Edit A — 7-line block replacement (per `<reference_data>` §D)
    - **Line 545** (module-load alert) — Edit B — ONE line replacement (per `<reference_data>` §E)

    All three regions contain the literal string `cmd+shift+e`. The acceptance gate `grep -c 'cmd+shift+e' purplevoice-lua/init.lua == 0` REQUIRES all three to be edited in this single task. If any one is missed, the task fails its own verify. Verified pre-revision: `grep -n 'cmd+shift+e' purplevoice-lua/init.lua` returns lines 2, 510, 514, 545 (four occurrences across three edit regions, since lines 510 and 514 are both inside the Edit A block).
  </interfaces>
  <files>purplevoice-lua/init.lua</files>
  <behavior>
    - Test 1: `grep -cE 'hs\.hotkey\.bind\(\{\}, ?"f19", ?onPress, ?onRelease\)' purplevoice-lua/init.lua` outputs `1` (F19 binding present — satisfies test_karabiner_check.sh check 6)
    - Test 2: `grep -cE 'hs\.hotkey\.bind\(\{"cmd", ?"shift"\}, ?"v"' purplevoice-lua/init.lua` outputs `1` (cmd+shift+v binding present — check 7)
    - Test 3: `grep -cE 'hs\.hotkey\.bind\(\{"cmd", ?"shift"\}, ?"e"' purplevoice-lua/init.lua` outputs `0` (cmd+shift+e binding absent — check 8 / D-05 deliberate replacement)
    - Test 4: F19 binding's nil-check alert references Karabiner: `grep -q "F19 binding failed (Karabiner" purplevoice-lua/init.lua`
    - Test 5: cmd+shift+v binding's nil-check alert: `grep -q "cmd+shift+v binding failed (in use?)" purplevoice-lua/init.lua`
    - Test 6: Module-load alert updated: `grep -q "PurpleVoice loaded — F19 to record" purplevoice-lua/init.lua` AND `! grep -q "PurpleVoice loaded — local dictation, cmd+shift+e" purplevoice-lua/init.lua`
    - Test 7: Line-2 header comment updated: `grep -q '^-- Wires F19 (push-and-hold; Karabiner-remapped from fn) to' purplevoice-lua/init.lua` AND `! grep -q '^-- Wires cmd+shift+e' purplevoice-lua/init.lua`
    - Test 8: ZERO `cmd+shift+e` references anywhere: `grep -c 'cmd+shift+e' purplevoice-lua/init.lua` outputs `0` (covers line 2 + bindings + module-load alert)
    - Test 9: After this task, `bash tests/test_karabiner_check.sh` advances from 0/8 to 3/8 GREEN — checks 6, 7, 8 PASS; checks 1-5 still FAIL (await Plan 04-02). The exit code is still 1 (overall RED) but failure messages list ONLY checks 1-5.
  </behavior>
  <action>
    Three coupled edits (combined into one task because they each touch one of the three init.lua regions still containing the literal string `cmd+shift+e`, and the Test 8 acceptance gate REQUIRES all three to land together):

    ### Edit A — Binding replacement (per `<reference_data>` §D)

    REPLACE the existing 7-line block at lines 509-515 of `purplevoice-lua/init.lua` (header comment + cmd+shift+e binding + nil-check) with the new 16-line block (F19 binding header + binding + nil-check + cmd+shift+v binding header + binding + nil-check). Use the verbatim block from `<reference_data>` §D.

    ### Edit B — Module-load alert (per `<reference_data>` §E)

    REPLACE the existing module-load alert at line 545:
    ```lua
    hs.alert.show("PurpleVoice loaded — local dictation, cmd+shift+e", 1.5)
    ```
    WITH (Unicode ⌘ U+2318 + ⇧ U+21E7):
    ```lua
    hs.alert.show("PurpleVoice loaded — F19 to record, ⌘⇧V to re-paste", 1.5)
    ```
    Duration `1.5` unchanged. ASCII fallback acceptable only if Unicode glyphs cannot be reliably written: `"PurpleVoice loaded — F19 to record, cmd+shift+v re-paste"`.

    ### Edit C — Line-2 header comment (per `<reference_data>` §F — REVISION ADDITION)

    REPLACE line 2 of `purplevoice-lua/init.lua`:
    ```lua
    -- Wires cmd+shift+e (push-and-hold) to ~/.local/bin/purplevoice-record.
    ```
    WITH:
    ```lua
    -- Wires F19 (push-and-hold; Karabiner-remapped from fn) to ~/.local/bin/purplevoice-record.
    ```

    Surgical one-line replacement. Do NOT touch lines 1, 3, or any other header lines. Preserve the `-- ` comment marker at column 1 and the trailing newline.

    Critical correctness (Edit A):
    - Empty modifier table `{}` (RESEARCH.md §3)
    - Lowercase `"f19"` (NOT `"F19"`; canonical per hs.keycodes.map)
    - `onPress` / `onRelease` references unchanged (existing lines 471/499)
    - Two SEPARATE locals (`hk` + `repasteHk`) — preserves per-binding nil-check
    - F19 binding's failure-alert mentions Karabiner specifically (RESEARCH.md §3)

    DO NOT:
    - Keep cmd+shift+e as fallback (D-05 rejected)
    - Change `onPress` / `onRelease` callback names
    - Inline `repaste` callback (Task 1-3 already created the named function)
    - Bind to uppercase `"F19"` or `"fn"` (both wrong per RESEARCH.md §3)
    - Replace the existing `setMenubarIdle()` call at line 518 (separate concern; module-load lifecycle preserved)
    - Change the alert duration (1.5 stays)
    - Add additional alerts at module load (one is enough)
    - Reference cmd+shift+e ANYWHERE in init.lua after this task (line 2 header, binding, alert text — all three must be clean)

    Verify post-edit: `grep -c 'cmd+shift+e' purplevoice-lua/init.lua` outputs `0` (zero occurrences anywhere — bindings AND alert text AND header comment all clean).

    After this task: `bash tests/test_karabiner_check.sh; echo $?` outputs `1` (still RED) but FAIL messages list ONLY checks 1-5 (assets/karabiner-fn-to-f19.json missing; setup.sh missing /Applications/Karabiner-Elements.app check; etc.). Checks 6, 7, 8 must NOT appear in the FAIL list.
  </action>
  <verify>
    <automated>test "$(grep -cE 'hs\.hotkey\.bind\(\{\}, ?"f19", ?onPress, ?onRelease\)' purplevoice-lua/init.lua)" = "1" && test "$(grep -cE 'hs\.hotkey\.bind\(\{"cmd", ?"shift"\}, ?"v"' purplevoice-lua/init.lua)" = "1" && test "$(grep -cE 'hs\.hotkey\.bind\(\{"cmd", ?"shift"\}, ?"e"' purplevoice-lua/init.lua)" = "0" && grep -q 'F19 binding failed (Karabiner' purplevoice-lua/init.lua && grep -q 'cmd+shift+v binding failed (in use?)' purplevoice-lua/init.lua && grep -q 'PurpleVoice loaded — F19 to record' purplevoice-lua/init.lua && ! grep -q 'PurpleVoice loaded — local dictation, cmd+shift+e' purplevoice-lua/init.lua && grep -q '^-- Wires F19 (push-and-hold; Karabiner-remapped from fn) to' purplevoice-lua/init.lua && ! grep -q '^-- Wires cmd+shift+e' purplevoice-lua/init.lua && test "$(grep -c 'cmd+shift+e' purplevoice-lua/init.lua)" = "0" && { bash tests/test_karabiner_check.sh; rc=$?; test "$rc" = "1"; }</automated>
  </verify>
  <acceptance_criteria>
    - F19 binding present with empty modifier table: `grep -cE 'hs\.hotkey\.bind\(\{\}, ?"f19", ?onPress, ?onRelease\)' purplevoice-lua/init.lua` outputs `1`
    - cmd+shift+v binding present: `grep -cE 'hs\.hotkey\.bind\(\{"cmd", ?"shift"\}, ?"v"' purplevoice-lua/init.lua` outputs `1`
    - cmd+shift+e binding ABSENT (D-05): `grep -cE 'hs\.hotkey\.bind\(\{"cmd", ?"shift"\}, ?"e"' purplevoice-lua/init.lua` outputs `0`
    - F19 binding nil-check alert: `grep -q 'F19 binding failed (Karabiner' purplevoice-lua/init.lua` succeeds
    - cmd+shift+v binding nil-check alert: `grep -q 'cmd+shift+v binding failed (in use?)' purplevoice-lua/init.lua` succeeds
    - Module-load alert updated: `grep -q 'PurpleVoice loaded — F19 to record' purplevoice-lua/init.lua` succeeds
    - Old module-load alert text gone: `! grep -q 'PurpleVoice loaded — local dictation, cmd+shift+e' purplevoice-lua/init.lua`
    - Line-2 header comment updated: `grep -q '^-- Wires F19 (push-and-hold; Karabiner-remapped from fn) to' purplevoice-lua/init.lua` succeeds
    - Old line-2 header gone: `! grep -q '^-- Wires cmd+shift+e' purplevoice-lua/init.lua`
    - ALL `cmd+shift+e` references gone: `grep -c 'cmd+shift+e' purplevoice-lua/init.lua` outputs `0`
    - Two `local` hotkey vars: `grep -cE '^local (hk|repasteHk) = hs\.hotkey\.bind' purplevoice-lua/init.lua` outputs `2`
    - `onPress` / `onRelease` callback definitions unchanged: `grep -c '^local function onPress()' purplevoice-lua/init.lua` outputs `1` AND `grep -c '^local function onRelease()' purplevoice-lua/init.lua` outputs `1`
    - `bash tests/test_karabiner_check.sh; echo $?` outputs `1` (still RED overall) — but FAIL messages list ONLY checks 1-5; check 6/7/8 messages must NOT appear in output
    - `! grep -q whisper-cli purplevoice-lua/init.lua` AND `! grep -q voice-cc purplevoice-lua/init.lua`
    - `bash tests/run_all.sh` reports 10 PASS + 1 FAIL (handoff state to Plan 04-02; test_karabiner_check.sh checks 1-5 still RED, checks 6-8 GREEN)
  </acceptance_criteria>
  <done>
    cmd+shift+e binding fully replaced by F19 binding (no modifiers); cmd+shift+v re-paste binding added; both have actionable nil-check alerts; module-load alert updated to reference F19 + ⌘⇧V; line-2 header comment updated to reference F19; ZERO `cmd+shift+e` references remain in init.lua (bindings + comments + headers + alert text all clean). test_karabiner_check.sh advances from 0/8 to 3/8 GREEN (checks 6, 7, 8). Plan 04-02 closes the remaining 5.
  </done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <name>Task 1-5 (checkpoint): Live re-paste walkthrough sign-off (QOL-01)</name>
  <what-built>
    `purplevoice-lua/init.lua` updated with:
    - `local lastTranscript = nil` at module scope
    - Cache assignment `lastTranscript = transcript` inside `pasteWithRestore` after the cmd+v keystroke fires
    - `local function repaste()` with nil-check + brief alert
    - `hs.hotkey.bind({"cmd", "shift"}, "v", repaste)` binding
    - `hs.hotkey.bind({}, "f19", onPress, onRelease)` (replaces cmd+shift+e per D-05)
    - Module-load alert text updated to `"PurpleVoice loaded — F19 to record, ⌘⇧V to re-paste"`
    - Line-2 header comment updated from `cmd+shift+e (push-and-hold)` to `F19 (push-and-hold; Karabiner-remapped from fn)`

    All 3 of test_karabiner_check.sh's init.lua-related checks (6, 7, 8) now GREEN; checks 1-5 (assets/karabiner-fn-to-f19.json + setup.sh Step 9) await Plan 04-02.

    The cmd+shift+v re-paste binding is testable today — only the F19 trigger requires Karabiner (Plan 04-02). For this checkpoint, the tester records via cmd+shift+e (which won't work, since the binding is removed) — wait. To enable testing of cmd+shift+v re-paste, the tester needs SOME way to fire `pasteWithRestore` and populate `lastTranscript`. Two paths:
    1. **Live walkthrough recommendation:** Defer this checkpoint to AFTER Plan 04-02 lands the Karabiner JSON + setup.sh check, install Karabiner, import the rule, then run `tests/manual/test_repaste_walkthrough.md` end-to-end with fn-hold as the recording trigger.
    2. **Alternative (if tester wants to verify Plan 04-01 in isolation):** Temporarily re-bind cmd+shift+e in a Hammerspoon console one-shot via `hs.hotkey.bind({"cmd", "shift"}, "e", onPress, onRelease)` — but this requires patching `onPress` / `onRelease` references which are local-scope. NOT recommended.

    **Recommended choice: defer this checkpoint to Plan 04-02 sign-off** — execute test_repaste_walkthrough.md only after Karabiner is installed and the F19 trigger is live. This matches the walkthrough's Prerequisites step 4 ("Karabiner-Elements imported and rule enabled") which itself blocks on Plan 04-02.

    If user accepts the deferral: this task auto-passes with note "deferred to Plan 04-02 phase-gate sign-off". If user wants to verify in isolation, follow the alternative above and document the temporary re-bind in the sign-off notes.
  </what-built>
  <how-to-verify>
    **Recommended path — deferred to Plan 04-02 sign-off:**
    1. Reload Hammerspoon (menubar -> Reload Config). Confirm load alert reads `PurpleVoice loaded — F19 to record, ⌘⇧V to re-paste`.
    2. Verify cmd+shift+e is dead: try cmd+shift+e — nothing should happen (no recording, no menubar change, no HUD).
    3. Verify the bindings registered: from Hammerspoon console, run `hs.inspect(hs.hotkey.getHotkeys())` — output should list two new entries (F19 with no modifiers; cmd+shift+v with cmd/shift mods). Both bindings should report `enabled = true`.
    4. Reply with "deferred to Plan 04-02 — Plan 04-01 verified in isolation: bindings registered, cmd+shift+e dead, load alert updated"

    **Optional immediate path — if user wants to verify cmd+shift+v re-paste isolated from F19:**
    Execute `tests/manual/test_repaste_walkthrough.md` adapted: skip Step 2's "hold fn" (Karabiner not yet installed); manually populate the cache by running this in the Hammerspoon console:
    ```lua
    -- Populate cache for testing without invoking the recording pipeline
    -- (Do NOT add this to init.lua — console-only diagnostic)
    package.loaded["purplevoice"] = nil  -- force reload of module
    -- The above does NOT expose lastTranscript externally — it's a local in the loaded chunk.
    -- Instead, simply invoke the recording flow by some other means (e.g. attach a temporary
    -- hs.hotkey via console: `hs.hotkey.bind({"cmd","alt"}, "p", function() hs.task.new(os.getenv("HOME").."/.local/bin/purplevoice-record", function(c,o,e) if c==0 then hs.eventtap.keyStroke({"cmd"},"v",0) end end):start() end)`)
    -- This is impractical for a 5-minute checkpoint. Defer to Plan 04-02 instead.
    ```
    Conclusion: recommend deferring rather than constructing an isolated test path.

    **Sign-off responses accepted:**
    - "deferred to Plan 04-02" (recommended)
    - "approved — bindings registered correctly, cmd+shift+e dead, load alert updated" (verifies Plan 04-01 in isolation without exercising re-paste)
    - "issues: [details]" (request fixes before Plan 04-02)
  </how-to-verify>
  <resume-signal>Reply with "deferred to Plan 04-02", "approved", or describe issues</resume-signal>
</task>

</tasks>

<verification>
After all 5 tasks complete (1-1 through 1-4 autonomous + 1-5 checkpoint):

```bash
# 1. Module-scope state added
grep -cE '^local lastTranscript = nil' purplevoice-lua/init.lua  # expect 1

# 2. Cache point in pasteWithRestore
grep -cE 'lastTranscript = transcript' purplevoice-lua/init.lua  # expect 1
grep -B2 'lastTranscript = transcript' purplevoice-lua/init.lua | grep -c 'hs\.eventtap\.keyStroke'  # expect 1

# 3. repaste function defined
grep -cE '^local function repaste\(\)' purplevoice-lua/init.lua  # expect 1
grep -A6 '^local function repaste()' purplevoice-lua/init.lua | grep -c 'PurpleVoice: nothing to re-paste yet'  # expect 1

# 4. F19 binding present
grep -cE 'hs\.hotkey\.bind\(\{\}, ?"f19", ?onPress, ?onRelease\)' purplevoice-lua/init.lua  # expect 1

# 5. cmd+shift+v binding present
grep -cE 'hs\.hotkey\.bind\(\{"cmd", ?"shift"\}, ?"v"' purplevoice-lua/init.lua  # expect 1

# 6. cmd+shift+e ZERO references anywhere (line 2 header + bindings + alert text — all 4 prior occurrences gone)
grep -c 'cmd+shift+e' purplevoice-lua/init.lua  # expect 0

# 7. Module-load alert updated
grep -c 'PurpleVoice loaded — F19 to record' purplevoice-lua/init.lua  # expect 1

# 8. Line-2 header comment updated
grep -c '^-- Wires F19 (push-and-hold; Karabiner-remapped from fn) to' purplevoice-lua/init.lua  # expect 1

# 9. test_karabiner_check.sh now passes 3 of 8 checks (6, 7, 8 GREEN; 1-5 still RED)
bash tests/test_karabiner_check.sh; echo "exit: $?"  # expect 1 (overall RED — checks 1-5 fail)
# But the failure messages should NOT include "FAIL: ... missing F19 binding" or
# "FAIL: ... missing cmd+shift+v" or "FAIL: ... still binds cmd+shift+e"

# 10. Functional suite — 10 prior PASS + 1 RED (test_karabiner_check still failing overall)
bash tests/run_all.sh; echo "exit: $?"  # expect 1 (one RED)

# 11. Security suite unchanged
bash tests/security/run_all.sh; echo "exit: $?"  # expect 0 (5/5 GREEN)

# 12. Brand consistency intact
bash tests/test_brand_consistency.sh; echo "exit: $?"  # expect 0

# 13. Pattern 2 invariants intact (purplevoice-record NOT touched in this plan)
test "$(grep -c WHISPER_BIN purplevoice-record)" = "2"
! grep -q whisper-cli purplevoice-lua/init.lua

# 14. lastTranscript reference total (declaration + cache + nil-check)
test "$(grep -c lastTranscript purplevoice-lua/init.lua)" = "3"
```

Expected end state: 10 PASS + 1 RED functional (test_karabiner_check.sh checks 1-5 still RED, checks 6-8 GREEN); 5/5 security GREEN; brand+framing GREEN; Pattern 2 invariants intact.
</verification>

<success_criteria>
- All 4 autonomous task `<acceptance_criteria>` blocks satisfied
- Checkpoint Task 1-5 received user response (deferred / approved / issues)
- `purplevoice-lua/init.lua` contains all 7 surgical edits: lastTranscript declaration, cache assignment, repaste function, F19 binding, cmd+shift+v binding, updated module-load alert, updated line-2 header comment
- Zero `cmd+shift+e` references anywhere in init.lua (line 2 header + bindings + comments + alert text all clean)
- `bash tests/test_karabiner_check.sh` advances from 0/8 to 3/8 GREEN (checks 6, 7, 8); failure messages list ONLY checks 1-5
- `bash tests/run_all.sh` reports 10 PASS + 1 RED (test_karabiner_check.sh still RED overall — handoff to Plan 04-02)
- Pattern 2 invariants intact: `grep -c WHISPER_BIN purplevoice-record == 2` AND `! grep -q whisper-cli purplevoice-lua/init.lua`
- Brand + framing lints stay GREEN
- handleExit() function untouched (caching lives in pasteWithRestore per RESEARCH.md Pattern 4)
</success_criteria>

<output>
After completion, create `.planning/phases/04-quality-of-life-v1-x/04-01-SUMMARY.md` covering:
- 4 autonomous task outcomes (each with the specific lines added/replaced)
- 1 checkpoint outcome (deferred to Plan 04-02 OR approved-in-isolation OR issues)
- The 7 surgical edits to init.lua, with before/after line numbers (Edit C: line 2 header; Edits A-B: lines 510/514/545)
- Confirmation that `cmd+shift+e` is fully eradicated (zero references — line 2 + lines 510/514/545 all updated)
- test_karabiner_check.sh state: 3/8 GREEN (checks 6, 7, 8); 5/8 RED (checks 1-5 — handoff to Plan 04-02)
- Suite state: 10/1 functional, 5/0 security, brand+framing GREEN
- Pattern 2 invariants intact + verified
- Any deviations (Rule 1 auto-fixes) recorded with root cause
- Handoff note for Plan 04-02: "land assets/karabiner-fn-to-f19.json + setup.sh Step 9 + docs closure to flip checks 1-5 GREEN; then run live walkthroughs"
</output>
