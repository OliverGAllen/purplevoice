# Manual Test: F19 hotkey via Karabiner fn-remap (QOL-NEW-01)

**Requirement:** QOL-NEW-01 — Replace cmd+shift+e with F19 push-and-hold. Karabiner-Elements remaps fn → F19 via `assets/karabiner-fn-to-f19.json` (200ms hold threshold; tap routes back to macOS native fn behaviour).

**Prerequisites:**

1. Plan 04-02 complete: `assets/karabiner-fn-to-f19.json` exists; `setup.sh` Step 9 runs successfully.
2. Karabiner-Elements installed at `/Applications/Karabiner-Elements.app` (download from https://karabiner-elements.pqrs.org/ — version >= 15.5.0 to avoid Sequoia 15.1.0 to_if_alone regression; cask 15.9.0 verified working as of 2026-04-30).
3. Karabiner driver/extension grant completed (System Settings → Privacy & Security → "Allow software from Fumihiko Takayama" enabled; Karabiner-Elements.app launched once after grant; Karabiner menubar icon visible — RESEARCH.md Pitfall 3).
4. `Hold fn → F19 (PurpleVoice push-to-talk)` rule imported and enabled in Karabiner → Preferences → Complex Modifications.
5. Plan 04-01 complete: `purplevoice-lua/init.lua` has `hs.hotkey.bind({}, "f19", onPress, onRelease)` (and the cmd+shift+e binding REMOVED).
6. Hammerspoon reloaded after Plan 04-01 changes; module-load alert reads `PurpleVoice loaded — F19 to record, ⌘⇧V to re-paste`.
7. Microphone + Accessibility granted to Hammerspoon.

## Steps

1. Open TextEdit (or any text editor). Click into a document.
2. **Hold-and-record (positive path):** Press and hold fn for ~2 seconds. Say "this is the F19 push-to-talk test". Release fn. Within ~2 seconds, the transcript pastes. **PASS-1:** F19 hold triggers recording; release stops recording; transcript pastes.
3. **Tap preserves Globe popup (or Dictation, or function-key row — depends on macOS Keyboard settings):** Tap fn briefly (< 200 ms) WITHOUT holding. Expected: macOS's native fn behaviour fires (the Globe / Emoji popup, OR the dictation panel, OR the function-key row remains accessible — varies by `System Settings → Keyboard → Press 🌐 key to`). PurpleVoice must NOT begin recording. **PASS-2:** quick fn-tap routes to macOS, not PurpleVoice.
4. **cmd+shift+e is silent (negative regression):** Press cmd+shift+e. Expected: nothing happens — no recording, no menubar change, no HUD pill. The cmd+shift+e binding was removed in Plan 04-01 per D-05 ("F19 only — no fallback"). **PASS-3:** cmd+shift+e is dead.
5. **VS Code/Cursor "Show Explorer" no longer hijacked:** Open VS Code (or Cursor). Press cmd+shift+e. Expected: the IDE's "Show Explorer" command opens normally — Hammerspoon no longer intercepts cmd+shift+e (the original collision that motivated QOL-NEW-01). **PASS-4:** the original VS Code/Cursor collision is resolved.
6. **200ms threshold sanity (RESEARCH.md Pitfall 1 tuning anchor):** Record 5 utterances in a row (steps 2-style hold-record-release cycles). Note any false-positive (a tap accidentally crossed 200 ms) or perceived lag (held for >300 ms before recording started). If either is reported, document specifics in the Sign-off section so a follow-up can adjust the threshold by ± 50 ms (`assets/karabiner-fn-to-f19.json` → `parameters.basic.to_if_held_down_threshold_milliseconds` and `basic.to_if_alone_timeout_milliseconds`). **PASS-5:** 200 ms threshold feels right (or adjustment notes captured).

## Expected Outcome

Five PASS markers signal F19 push-to-talk works, fn-tap preserves macOS native behaviour, cmd+shift+e is fully dead, the IDE collision is resolved, and 200 ms feels right (or actionable adjustment is captured).

## Failure modes

- Step 2 nothing happens → Karabiner daemon not running. Check Karabiner menubar icon. If absent, the driver grant was skipped — re-launch Karabiner-Elements.app, accept the system-extension prompt (Privacy & Security → "Allow software from Fumihiko Takayama"), restart Karabiner-Elements (RESEARCH.md Pitfall 3).
- Step 2 nothing happens but Karabiner IS running → rule not enabled. Open Karabiner-Elements → Preferences → Complex Modifications → verify `Hold fn → F19 (PurpleVoice push-to-talk)` is in the enabled list (toggle the Enable button if not).
- Step 2 nothing happens, rule enabled → Hammerspoon F19 binding not registered. Check Hammerspoon console for `PurpleVoice: F19 binding failed (Karabiner fn→F19 rule active?)` alert at module load. Reload Hammerspoon. Verify the new `hs.hotkey.bind({}, "f19", ...)` line is present in the loaded init.lua via `hs -c 'print(hs.inspect(hs.hotkey.getHotkeys()))'`.
- Step 3 fn-tap triggers PurpleVoice recording → threshold too short (<200ms is being crossed by quick taps). Adjust both `to_if_alone_timeout_milliseconds` AND `to_if_held_down_threshold_milliseconds` upward by 50 ms in `assets/karabiner-fn-to-f19.json`, re-import the rule via Karabiner UI, retest.
- Step 3 Globe popup never appears no matter what → macOS Keyboard setting is "Do nothing" for Press 🌐 key to. This is fine — different users have different Globe-key bindings; the test passes if PurpleVoice does NOT trigger on the tap (the macOS-native fn behaviour is whatever the user has configured, including no-op).
- Step 4 cmd+shift+e still triggers PurpleVoice → Plan 04-01's binding-removal was incomplete. Re-grep `purplevoice-lua/init.lua` for `cmd", *"shift"\}, *"e"`; remove. Reload Hammerspoon.

## Sign-off

- [x] PASS-1 (fn-hold triggers recording; release stops; transcript pastes)
- [x] PASS-2 (quick fn-tap routes to macOS native behaviour, not PurpleVoice)
- [x] PASS-3 (cmd+shift+e is silent — no recording, no menubar change, no HUD)
- [x] PASS-4 (cmd+shift+e in VS Code/Cursor opens "Show Explorer" normally)
- [x] PASS-5 (200 ms threshold feels right across 5 record cycles)

**Tester:** Oliver  **Date:** 2026-04-30  **200 ms threshold notes:** none — feels right out of the box
