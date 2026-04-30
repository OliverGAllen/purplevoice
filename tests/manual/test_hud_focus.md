# Manual Test: HUD does not steal focus (HUD-04 focus)

**Requirement:** HUD-04 — HUD does not steal focus, does not interfere with paste, and does not appear in screen recordings (this walkthrough covers the focus half — focus passes through to the app behind).

**Prerequisites:**
- Phase 3.5 HUD deployed
- HUD enabled (default state)
- Any text editor or terminal available for the focus check

## Steps
1. Open a text editor (TextEdit, VS Code, Terminal). Click into it. Confirm the cursor is blinking (text-input focus).
2. Hold F19 (Karabiner-remapped from fn). Observe the HUD appear at top-center. The cursor should STILL be in the editor (focus did not move to the HUD).
3. While holding, type a few keys (the keys may go to recording — that's the point; we're just confirming focus is in the editor, not the HUD).
4. Release. Observe HUD disappear. Cursor stays in editor.
5. Click somewhere on the HUD pill area while a press cycle is active (rapid: press hotkey, click on the pill area, release — or use a second hotkey if needed). The click should pass THROUGH the HUD to whatever app is behind. The HUD should not become focused or move (focus passes through).
6. Trigger cmd+tab while idle (no press). The HUD should NOT appear in the app switcher list.
7. Open Mission Control (F3 or 4-finger swipe up). The HUD should NOT appear as a window in any Space (it has `canJoinAllSpaces` + `transient` behavior — system-managed-overlay style).

## Expected Outcome
- Cursor stays in editor across press / hold / release.
- Clicks on the HUD pass through to the app behind (focus passes through).
- HUD does not appear in cmd+tab.
- HUD does not appear in Mission Control as a manageable window.

## Failure modes
- Cursor moves out of editor during press → `canBecomeKeyWindow` returning true on the HUD canvas; check the canvas has no input elements that override this (RESEARCH Priority 3).
- Clicks land on HUD instead of app behind → `ignoresMouseEvents` not set; default is YES per `hs.canvas` libcanvas.m source — should not happen unless explicitly overridden.
- HUD shows in cmd+tab → window collection behavior missing `transient`; verify `:behaviorAsLabels({"canJoinAllSpaces", "stationary", "transient"})` was applied (RESEARCH Pattern 1).

## Sign-off
- [ ] Focus stays in editor during press / hold / release
- [ ] Clicks pass through HUD to app behind (focus passes through)
- [ ] HUD absent from cmd+tab switcher
- [ ] HUD absent from Mission Control window list

**Tester:** _____________  **Date:** _____________

---

## Sign-off (Phase 3.5 close 2026-04-30)

- **Tester:** Oliver Allen (live verification on macOS Sequoia 15.7.5, Apple Silicon)
- **Date:** 2026-04-30
- **Result:** PASS — user confirmed "all complete" after walking through B + D + E (A + C already verified during Plan 03.5-01 sign-off `aebd505` / `932ca65`).
- **HUD live state at sign-off:** lavender translucent pill (alpha 0.70) at top-center of active screen, "● Recording" white text, fade-in instant + fade-out 150ms, focus passthrough confirmed, env-var disable confirmed via quit + relaunch with `PURPLEVOICE_HUD_OFF=1`.
