# Manual Test: HUD appearance + disappearance timing (HUD-01)

**Requirement:** HUD-01 — Floating canvas widget appears within ~50ms of hotkey press and disappears within ~250ms of release.

**Prerequisites:**
- Phase 3.5 PurpleVoice HUD deployed (Plans 03.5-01 + 03.5-02 complete)
- Hammerspoon launched + permissions granted (Microphone + Accessibility)
- `~/.hammerspoon/init.lua` contains `require("purplevoice")`
- PURPLEVOICE_HUD_OFF unset (or = anything other than "1")
- Default position (top-center) — i.e. PURPLEVOICE_HUD_POSITION unset or = "top-center"

## Steps
1. Reload Hammerspoon (menubar → Reload Config). Confirm the load alert appears.
2. Note the menubar dot is in idle (○ outline lavender) state.
3. Hold cmd+shift+e for ~2 seconds while watching the top-center of the active screen.
4. Observe: a lavender pill (~140×36) reading "● Recording" should appear at top-center, ~50px below the menubar, within one perceptual frame of the press (no visible lag).
5. Release cmd+shift+e. Observe: the pill should fade out within ~250ms (perceptually "just disappeared").
6. Repeat 3-5 times. Behaviour should be consistent.
7. Optional: a stopwatch on a phone can be used to confirm appearance < 100ms and disappearance < 300ms (the 50/250 numbers in HUD-01 are below human perception thresholds; observation suffices).

## Expected Outcome
- Press → pill appears at top-center, lavender, ● Recording text, no perceptible delay.
- Hold → pill stays visible.
- Release → pill fades out within a quarter second.
- Repeated press cycles produce the same behaviour.
- No HUD when idle.

## Failure modes
- Pill does not appear → check Hammerspoon console for `hs.canvas` errors; verify `_G._purplevoice_hud` is non-nil.
- Pill stuck visible after release → check `hideHUD()` is called from `resetState()` (RESEARCH Priority 12).
- Pill appears but on wrong screen → multi-monitor focused-window screen resolution check (`hs.window.focusedWindow():screen()` per RESEARCH Pattern 3).
- Pill flickers / double-render → check the defensive `_G._purplevoice_hud` cleanup at module load (RESEARCH Pitfall 6).

## Sign-off
- [ ] Pill appears within one frame of press (no perceptible delay)
- [ ] Pill is centered horizontally at top of active screen, ~50px below menubar
- [ ] Pill text is "● Recording" in white on lavender (#B388EB α≈0.85)
- [ ] Pill disappears within ~250ms of release
- [ ] Behaviour consistent across 3+ press cycles

**Tester:** _____________  **Date:** _____________

---

## Sign-off (Phase 3.5 close 2026-04-30)

- **Tester:** Oliver Allen (live verification on macOS Sequoia 15.7.5, Apple Silicon)
- **Date:** 2026-04-30
- **Result:** PASS — user confirmed "all complete" after walking through B + D + E (A + C already verified during Plan 03.5-01 sign-off `aebd505` / `932ca65`).
- **HUD live state at sign-off:** lavender translucent pill (alpha 0.70) at top-center of active screen, "● Recording" white text, fade-in instant + fade-out 150ms, focus passthrough confirmed, env-var disable confirmed via quit + relaunch with `PURPLEVOICE_HUD_OFF=1`.
