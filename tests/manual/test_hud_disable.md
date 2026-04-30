# Manual Test: HUD disabled via PURPLEVOICE_HUD_OFF=1 (HUD-02)

**Requirement:** HUD-02 — User-toggleable visibility via env var read once at module load.

**Prerequisites:**
- Phase 3.5 HUD deployed (Plans 03.5-01 + 03.5-02 complete)
- Hammerspoon launched + permissions granted
- test_hud_appearance.md previously confirmed PASS (HUD-01 baseline)

## Steps
1. From the shell: `export PURPLEVOICE_HUD_OFF=1`
2. Reload Hammerspoon: `hs -c "hs.reload()"` OR menubar → Reload Config.
3. Confirm the load alert appears.
4. Hold F19 (Karabiner-remapped from fn) for ~2 seconds.
5. Observe: NO HUD pill appears.
6. Confirm the menubar indicator DOES change to recording (filled ●) — Phase 2 menubar still ships per HUD-02 spec.
7. Confirm paste still works — type into a focused text editor first, hold hotkey, speak, release; transcript should paste normally.
8. Unset: `unset PURPLEVOICE_HUD_OFF` (or `export PURPLEVOICE_HUD_OFF=0` — anything other than "1").
9. Reload Hammerspoon.
10. Hold F19 — HUD should reappear (default-ON per D-09).

## Expected Outcome
- With PURPLEVOICE_HUD_OFF=1, no HUD on press; menubar indicator unchanged in behaviour; paste path unaffected.
- With env var unset / not "1", HUD reappears.

## Failure modes
- HUD still appears with PURPLEVOICE_HUD_OFF=1 → env var not being read at module load; check the `os.getenv("PURPLEVOICE_HUD_OFF")` call landed in init.lua and that Hammerspoon was actually reloaded after setting the env var (parent shell env propagates only on Hammerspoon launch from that shell, OR via `launchctl setenv PURPLEVOICE_HUD_OFF 1` for system-wide). If still failing: check `hs.execute("env | grep PURPLEVOICE")` from Hammerspoon console.
- Menubar indicator stops working when HUD off → `setMenubarRecording()` accidentally gated on `hudEnabled`; fix to keep menubar lifecycle independent.
- Paste broken with HUD off → HUD code accidentally interfered with `pasteWithRestore()`; should not be possible if HUD is purely additive.

## Sign-off
- [ ] PURPLEVOICE_HUD_OFF=1 + reload → no HUD on press
- [ ] Menubar still changes state (filled ● during press)
- [ ] Paste path unaffected (transcript appears in focused text field)
- [ ] Env var unset + reload → HUD returns

**Tester:** _____________  **Date:** _____________

---

## Sign-off (Phase 3.5 close 2026-04-30)

- **Tester:** Oliver Allen (live verification on macOS Sequoia 15.7.5, Apple Silicon)
- **Date:** 2026-04-30
- **Result:** PASS — user confirmed "all complete" after walking through B + D + E (A + C already verified during Plan 03.5-01 sign-off `aebd505` / `932ca65`).
- **HUD live state at sign-off:** lavender translucent pill (alpha 0.70) at top-center of active screen, "● Recording" white text, fade-in instant + fade-out 150ms, focus passthrough confirmed, env-var disable confirmed via quit + relaunch with `PURPLEVOICE_HUD_OFF=1`.
