# Manual Test: Re-paste hotkey — hold ` (F18) (QOL-01)

**Requirement:** QOL-01 — Paste-last-transcript hotkey re-pastes the most recent successful transcript into the focused window. Storage is in-memory Lua module-scope `local lastTranscript = nil`; lost on Hammerspoon reload by design (CONTEXT.md D-03).

**Hotkey supersession (2026-05-01):** the original D-02 plan was `cmd+shift+v` — switched to F18-via-backtick-hold after live walkthrough surfaced an opaque clipboard-manager collision and the documented VS Code/Cursor "Markdown Preview" cost.

**Prerequisites:**

1. Plan 04-01 complete (purplevoice-lua/init.lua has `local lastTranscript = nil` module-scope, `hs.hotkey.bind({}, "f18", repaste)`, and `lastTranscript = transcript` cache point inside `pasteWithRestore`).
2. Hammerspoon launched with the updated init.lua loaded; module-load alert reads `PurpleVoice loaded — hold fn (F19) to record, hold ` (F18) to re-paste`.
3. Microphone + Accessibility granted to Hammerspoon (per Phase 2 setup).
4. Karabiner-Elements imported and BOTH rules enabled:
   - `Hold fn → F19 (PurpleVoice push-to-talk)` (assets/karabiner-fn-to-f19.json)
   - `Hold ` (backtick) → F18 (PurpleVoice re-paste)` (assets/karabiner-backtick-to-f18.json)

## Steps

1. Open TextEdit (or any text editor with two open documents). Click into Document A.
2. Hold fn for ~2 seconds (Karabiner emits F19; PurpleVoice begins recording). Say "this is the first test transcript". Release fn. Within ~2 seconds, "this is the first test transcript" pastes into Document A. **PASS-1:** initial paste succeeded.
3. Switch focus to Document B (cmd+tab or click into the second document).
4. Hold `` ` `` (backtick) for ~200 ms (Karabiner emits F18 once the threshold is crossed).
5. Expected: "this is the first test transcript" pastes into Document B (re-paste of the cached `lastTranscript`). **PASS-2:** re-paste fired correct transcript across focus shift.
6. Reload Hammerspoon: menubar → Reload Config (OR run `hs -c "hs.reload()"` from a Terminal that has Hammerspoon CLI configured). Wait for the load alert.
7. Without recording anything new, hold `` ` `` again.
8. Expected: a brief alert appears: `PurpleVoice: nothing to re-paste yet` (~1.5s fade). NO paste fires; NO crash. **PASS-3:** nil-state alert behaves correctly post-reload.
9. (Sanity check on backtick typing) Tap `` ` `` quickly (under 200 ms) in any text field. Expected: a backtick character types normally. The Karabiner `to_if_alone` clause preserves the original key on quick taps.

## Expected Outcome

- Step 2: initial recording transcribes and pastes into Document A.
- Step 5: hold-backtick (F18) in Document B pastes the cached transcript (proves QOL-01 cross-app re-paste).
- Step 8: post-reload hold-backtick (F18) shows brief alert, no crash (proves nil-state behaviour D-04).
- Step 9: tap-backtick still types `` ` `` (proves Karabiner tap-vs-hold split preserves the original key).

## Failure modes

- Step 4 hold types multiple backticks instead of firing re-paste → Karabiner rule not enabled OR wrong key code for keyboard layout. Open Karabiner-Elements → Preferences → Complex Modifications and confirm `Hold ` (backtick) → F18` is enabled. Use Karabiner Event Viewer to check the key code under the `` ` `` key — UK/EU layouts use `non_us_backslash`; ANSI/US uses `grave_accent_and_tilde`. The shipped JSON uses `non_us_backslash` (matches Oliver's keyboard).
- Step 5 produces no paste → `lastTranscript` was not cached. Check `pasteWithRestore()` for `lastTranscript = transcript` line AFTER `hs.eventtap.keyStroke({"cmd"}, "v", 0)` (per RESEARCH.md Pattern 4 / §2 — cache point inside the success path, not in handleExit).
- Step 5 pastes the wrong text → `lastTranscript` was assigned the wrong value. Check that the assignment uses the `transcript` parameter of `pasteWithRestore()`, not `stdOut` from `handleExit()`.
- Step 8 crashes / shows no alert → `repaste()` does not nil-check `lastTranscript`. Required pattern: `if lastTranscript then pasteWithRestore(lastTranscript) else hs.alert.show("PurpleVoice: nothing to re-paste yet", 1.5) end`.
- Step 8 alert does not appear → Hammerspoon was not actually reloaded (state survived); confirm by checking the load alert fired between steps 6 and 7.
- F18 binding never fires anywhere → check for `PurpleVoice: F18 binding failed (Karabiner ` rule active?)` alert at module load. F18 collisions are rare (no commonly-used app binds bare F18) — most likely cause is the Karabiner rule isn't enabled, not a Hammerspoon binding conflict.

## Sign-off

- [x] PASS-1 (initial recording transcribes and pastes into Document A)
- [x] PASS-2 (hold-backtick fires F18 in Document B → cached transcript pastes)
- [x] PASS-3 (post-reload hold-backtick shows nil-state alert without crash)

**Tester:** Oliver  **Date:** 2026-05-01  **Notes:** original cmd+shift+v plan (D-02) silently failed at runtime — no Hammerspoon binding-failed alert fired but the keystroke never reached repaste(). Switched to F18-via-backtick-hold mid-walkthrough; works cleanly. UK keyboard layout requires `non_us_backslash` key code (not `grave_accent_and_tilde`).
