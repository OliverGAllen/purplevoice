# Manual Test: Re-paste hotkey cmd+shift+v (QOL-01)

**Requirement:** QOL-01 — Paste-last-transcript hotkey re-pastes the most recent successful transcript into the focused window. Storage is in-memory Lua module-scope `local lastTranscript = nil`; lost on Hammerspoon reload by design (CONTEXT.md D-03).

**Prerequisites:**

1. Plan 04-01 complete (purplevoice-lua/init.lua has `local lastTranscript = nil` module-scope, `hs.hotkey.bind({"cmd","shift"}, "v", repaste)`, and `lastTranscript = transcript` cache point inside `pasteWithRestore`).
2. Hammerspoon launched with the updated init.lua loaded; module-load alert reads `PurpleVoice loaded — F19 to record, ⌘⇧V to re-paste` (or ASCII fallback).
3. Microphone + Accessibility granted to Hammerspoon (per Phase 2 setup).
4. Karabiner-Elements imported and `Hold fn → F19 (PurpleVoice push-to-talk)` rule enabled — required because Plan 04-01 also removes the cmd+shift+e binding (D-05). Recording is triggered via fn-hold (which Karabiner remaps to F19).

## Steps

1. Open TextEdit (or any text editor with two open documents). Click into Document A.
2. Hold fn for ~2 seconds (Karabiner emits F19; PurpleVoice begins recording). Say "this is the first test transcript". Release fn. Within ~2 seconds, "this is the first test transcript" pastes into Document A. **PASS-1:** initial paste succeeded.
3. Switch focus to Document B (cmd+tab or click into the second document).
4. Press cmd+shift+v.
5. Expected: "this is the first test transcript" pastes into Document B (re-paste of the cached `lastTranscript`). **PASS-2:** re-paste fired correct transcript across focus shift.
6. Reload Hammerspoon: menubar → Reload Config (OR run `hs -c "hs.reload()"` from a Terminal that has Hammerspoon CLI configured). Wait for the load alert.
7. Without recording anything new, press cmd+shift+v.
8. Expected: a brief alert appears: `PurpleVoice: nothing to re-paste yet` (~1.5s fade). NO paste fires; NO crash. **PASS-3:** nil-state alert behaves correctly post-reload.
9. (Optional regression check) Open a `.md` file in VS Code or Cursor. Press cmd+shift+v. Expected: re-paste fires (NOT the IDE's "Markdown Preview" feature) — Hammerspoon Carbon RegisterEventHotKey wins precedence over app shortcuts (RESEARCH.md Pitfall 2). Note this is a real cost: Markdown Preview is no longer accessible via cmd+shift+v while Hammerspoon is running. Workaround: Cmd+K V (VS Code split preview).

## Expected Outcome

- Step 2: initial recording transcribes and pastes into Document A.
- Step 5: cmd+shift+v in Document B pastes the cached transcript (proves QOL-01 cross-app re-paste).
- Step 8: post-reload cmd+shift+v shows brief alert, no crash (proves nil-state behaviour D-04).
- Step 9 (if exercised): cmd+shift+v in VS Code .md file fires PurpleVoice re-paste, NOT VS Code's Markdown Preview (proves Hammerspoon hotkey precedence).

## Failure modes

- Step 5 produces no paste → `lastTranscript` was not cached. Check `pasteWithRestore()` for `lastTranscript = transcript` line AFTER `hs.eventtap.keyStroke({"cmd"}, "v", 0)` (per RESEARCH.md Pattern 4 / §2 — cache point inside the success path, not in handleExit).
- Step 5 pastes the wrong text → `lastTranscript` was assigned the wrong value. Check that the assignment uses the `transcript` parameter of `pasteWithRestore()`, not `stdOut` from `handleExit()`.
- Step 8 crashes / shows no alert → `repaste()` does not nil-check `lastTranscript`. Required pattern: `if lastTranscript then pasteWithRestore(lastTranscript) else hs.alert.show("PurpleVoice: nothing to re-paste yet", 1.5) end`.
- Step 8 alert does not appear → Hammerspoon was not actually reloaded (state survived); confirm by checking the load alert fired between steps 6 and 7.
- cmd+shift+v binding never fires anywhere → hotkey conflict with another tool (Raycast, Alfred, BTT). Check for `PurpleVoice: cmd+shift+v binding failed (in use?)` alert at module load (RESEARCH.md Pitfall 4). Mitigation: rebind the conflicting tool, or revisit at plan-checker review per CONTEXT.md D-02.

## Sign-off

- [ ] PASS-1 (initial recording transcribes and pastes into Document A)
- [ ] PASS-2 (cmd+shift+v in Document B pastes the cached transcript)
- [ ] PASS-3 (post-reload cmd+shift+v shows nil-state alert without crash)

**Tester:** _____________  **Date:** _____________
