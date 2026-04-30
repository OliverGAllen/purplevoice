# Manual Test: HUD idle CPU baseline (HUD-03)

**Requirement:** HUD-03 — Effectively zero CPU when idle (no animation loops; only redraws on state change).

**Status:** Documentation-only walkthrough — captures the baseline measurement; no specific pass/fail threshold.

**Prerequisites:**
- Phase 3.5 HUD deployed
- Activity Monitor available (or `top` CLI)
- HUD enabled (PURPLEVOICE_HUD_OFF unset)

## Steps
1. Open Terminal: `top -pid $(pgrep Hammerspoon | head -1) -stats pid,command,cpu`
2. Wait ~10 seconds for the CPU% column to stabilise. Record the BASELINE value (e.g., "0.2%").
3. Hold F19 (Karabiner-remapped from fn) for 2 seconds. Observe the CPU% column during the press. Record the ACTIVE value (e.g., "0.6%").
4. Release. Wait ~5 seconds. Observe the CPU% column should return to BASELINE ± noise (~0.2% on M-series).
5. Repeat the press cycle 5 times in quick succession. Confirm CPU% returns to baseline after each release.
6. Idle for 30 seconds with HUD hidden. Confirm CPU% does NOT drift upward.

## Expected Outcome
- Idle CPU: ~0.1-0.5% (matches Hammerspoon baseline; HUD adds no measurable cost when hidden).
- Active CPU during press: small bump (1-3%) — animation context + redraw, expected.
- Returns to baseline within ~5s of release.
- No CPU drift after sustained idle.

## Failure modes
- CPU stays elevated after release → an animation loop or timer is still running; check `:hide()` call ordering and that no `hs.timer.doEvery` was added accidentally.
- Baseline drifts upward over time → memory leak from canvas elements re-created per press; verify the create-once + show/hide pattern from RESEARCH Pattern 1 (no per-press `hs.canvas.new`).
- High baseline (>1%) before any press → `wantsLayer(true)` not set; Core Animation not engaged; AppKit fallback path is heavier (RESEARCH Pitfall 5).

## Sign-off (documentation-only)
- [ ] BASELINE CPU% recorded: _________ %
- [ ] ACTIVE CPU% during press recorded: _________ %
- [ ] CPU returns to baseline within 5s of release
- [ ] No drift after 30s sustained idle

**Tester:** _____________  **Date:** _____________

---

## Sign-off (Phase 3.5 close 2026-04-30)

- **Tester:** Oliver Allen (live verification on macOS Sequoia 15.7.5, Apple Silicon)
- **Date:** 2026-04-30
- **Result:** PASS — user confirmed "all complete" after walking through B + D + E (A + C already verified during Plan 03.5-01 sign-off `aebd505` / `932ca65`).
- **HUD live state at sign-off:** lavender translucent pill (alpha 0.70) at top-center of active screen, "● Recording" white text, fade-in instant + fade-out 150ms, focus passthrough confirmed, env-var disable confirmed via quit + relaunch with `PURPLEVOICE_HUD_OFF=1`.
