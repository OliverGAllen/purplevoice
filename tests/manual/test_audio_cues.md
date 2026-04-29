# Manual Test: Audio cues + PURPLEVOICE_NO_SOUNDS gate (FBK-02)

**Requirement:** FBK-02 — System plays a brief audible cue at recording start and end (default-on, suppressible via env var).

**Prerequisites:** Phase 2 PurpleVoice loop deployed (Plan 02-02 complete). System volume audible.

## Steps — default-on (cues play)

1. Confirm `PURPLEVOICE_NO_SOUNDS` is NOT set: `echo "${PURPLEVOICE_NO_SOUNDS:-unset}"` in a Terminal — should print `unset`.
2. Hold cmd+shift+e. **Expected:** brief Pop sound on press.
3. Release. **Expected:** brief Tink sound on release.
4. Repeat to confirm reliable cue playback.

## Steps — suppressed via env var

5. In Terminal: `launchctl setenv PURPLEVOICE_NO_SOUNDS 1`
6. Restart Hammerspoon: menubar → Hammerspoon icon → Reload Config (or `hs -c "hs.reload()"` if hs.ipc is wired).
7. Confirm PurpleVoice loaded successfully (alert "PurpleVoice loaded ...").
8. Hold cmd+shift+e. **Expected: SILENCE** — no Pop sound.
9. Release. **Expected: SILENCE** — no Tink sound.
10. The transcript should still paste normally (sound suppression does not affect functionality).

## Cleanup

11. `launchctl unsetenv PURPLEVOICE_NO_SOUNDS` and reload Hammerspoon — cues should return.

## Failure modes

- No Pop/Tink sounds in default-on mode → `hs.sound.getByName("Pop")` returned nil; check sounds present at `/System/Library/Sounds/Pop.aiff` and `/System/Library/Sounds/Tink.aiff`. Confirm system volume isn't muted.
- Sounds still play with PURPLEVOICE_NO_SOUNDS=1 → env var not read at module load; check `os.getenv("PURPLEVOICE_NO_SOUNDS")` runs once at module init (NOT inside the press handler — `launchctl setenv` only affects newly-spawned processes, so a module load is required to pick it up).
- 100 ms accidental tap plays Pop but nothing else → that's correct behaviour: the Pop fires on press (before the duration gate runs), and short taps still get the Pop. Tink only fires on successful paste path.

## Sign-off

- [ ] Pop on press, Tink on release (default-on)
- [ ] Silence on press, silence on release (PURPLEVOICE_NO_SOUNDS=1)
- [ ] Transcript still pastes correctly in suppressed mode

**Tester:** _____________  **Date:** _____________
