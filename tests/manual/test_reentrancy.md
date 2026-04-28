# Manual Test: Re-entrancy — rapid double-press produces ONE sox process (ROB-01)

**Requirement:** ROB-01 — Rapid repeated hotkey presses do not spawn duplicate recording processes (in-memory re-entrancy guard prevents overlapping captures).

**Prerequisites:** Phase 2 voice-cc loop deployed (Plan 02-02 complete). Terminal open for `pgrep`.

## Steps

1. In a Terminal: `watch -n 0.1 'pgrep -fa sox'` (or repeatedly `pgrep -fa sox` if `watch` isn't installed; `brew install watch` if needed).
2. Press cmd+shift+e and HOLD it. **Expected in `pgrep`:** ONE sox process appears.
3. While still holding, ask another person (or use a foot switch) to press cmd+shift+e a second time. **Expected:** STILL ONE sox process — the second press dropped silently.
4. Release the first press. **Expected:** the sox process exits (disappears from pgrep).
5. **Rapid-tap test:** press and release cmd+shift+e 10 times in 1 second (drum your finger). **Expected in pgrep:** at most ONE sox process at any moment.
6. After the burst, no sox process remains; menubar dot is grey.

## Expected Outcome

- At any instant, `pgrep -fa sox | wc -l` returns 0 or 1 (never 2+).
- Menubar dot reliably returns to grey after every release.
- No accumulation of WAV files in /tmp/voice-cc/ (cross-check with ROB-04 cleanup).

## Failure modes

- Two sox processes visible simultaneously → `isRecording` guard not honoured. Check `if isRecording then return end` at top of onPress.
- Dot stuck red after burst → state not reset; check pcall-wrapped finally block calls `resetState()` AND `setMenubarIdle()`.
- Multiple WAVs left in /tmp/voice-cc/ after burst → ROB-04 cleanup is broken, not ROB-01. Run `tests/test_wav_cleanup.sh` to confirm.
- pgrep shows TWO sox processes → re-entrancy guard is being bypassed. Likely cause: the guard is set inside the `hs.task` callback (async), so back-to-back press events fire before the guard is set. Move `isRecording = true` to the synchronous head of the press handler.

## Sign-off

- [ ] At most ONE sox process during burst
- [ ] Menubar returns to grey after every release
- [ ] No accumulation of WAV files in /tmp/voice-cc/

**Tester:** _____________  **Date:** _____________
