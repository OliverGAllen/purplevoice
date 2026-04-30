# Manual Test: HUD visibility in screen recordings (HUD-04 recordings — DOCUMENTATION-ONLY)

**Requirement:** HUD-04 — HUD hidden from screen recordings by default (best-effort / limited scope per RESEARCH Priority 2).

**Status:** **Documentation-only walkthrough.** This is NOT a pass/fail gate. Per RESEARCH Priority 2 (Apple Developer Forums thread 792152, 2025): on macOS 15+ (Sequoia), ScreenCaptureKit-based capture tools (modern QuickTime, OBS, Zoom share-screen, Discord, Loom, Teams) capture the HUD regardless of NSWindowSharingNone. Apple has stated there is no public API to prevent ScreenCaptureKit capture. This walkthrough documents the empirical state on Oliver's machine (macOS Sequoia 15.7.5).

**Prerequisites:**
- Phase 3.5 HUD deployed
- HUD enabled (default state)
- macOS Sequoia 15.7.5 or later (Oliver's current machine)

## Steps

### Sub-test A: legacy `screencapture` CLI
1. Trigger HUD: hold cmd+shift+e (HUD visible at top-center).
2. While HUD is visible, in a SEPARATE terminal: `screencapture -x /tmp/purplevoice_hud_test_legacy.png` (the `-x` flag suppresses the camera-shutter sound).
3. Release cmd+shift+e.
4. Open `/tmp/purplevoice_hud_test_legacy.png` in Preview.
5. **Document:** is the HUD pill visible in the screenshot? (Expected on Sequoia 15.7+: HUD likely ABSENT — legacy screencapture uses CGWindowList which honours kCGWindowSharingNone... but this is unverified for 15.7+; record the actual outcome.)

### Sub-test B: modern QuickTime screen recording
1. Open QuickTime Player → File → New Screen Recording.
2. Start recording the entire screen.
3. Trigger HUD: hold cmd+shift+e for ~3 seconds.
4. Stop the QuickTime recording.
5. Play back the recording.
6. **Document:** is the HUD pill visible in the playback? (Expected on macOS 15+: HUD PRESENT — QuickTime uses ScreenCaptureKit which ignores NSWindowSharingNone.)

### Sub-test C (optional): Zoom share-screen
Only run if Zoom is installed.
1. Start a Zoom meeting (with yourself, no other participants needed).
2. Click "Share Screen" → "Entire Screen".
3. Trigger HUD via cmd+shift+e.
4. Use Zoom's "view what's being shared" option (or screenshot the share-preview).
5. **Document:** is the HUD visible? (Expected: PRESENT — Zoom uses ScreenCaptureKit on macOS 15+.)

## Expected Outcome (NOT a pass/fail gate)
- Sub-test A (legacy screencapture): HUD likely ABSENT (CGWindowList path).
- Sub-test B (QuickTime): HUD likely PRESENT (ScreenCaptureKit path; Apple has no public API to prevent this).
- Sub-test C (Zoom): HUD likely PRESENT (ScreenCaptureKit path).
- **The README + SECURITY.md HUD caveat (Plan 03.5-03) is the load-bearing artefact for this requirement, not this walkthrough.** This walkthrough produces evidence for the caveat's accuracy.

## Documentation Output
Capture results in this format and link from the SUMMARY.md:

| Sub-test | Tool | macOS version | HUD visible in capture? |
|----------|------|---------------|-------------------------|
| A | screencapture CLI | 15.7.5 | Y / N |
| B | QuickTime screen recording | 15.7.5 | Y / N |
| C | Zoom share-screen | 15.7.5 | Y / N |

## Sign-off (documentation-only)
- [ ] Sub-test A run; result documented
- [ ] Sub-test B run; result documented
- [ ] Sub-test C run OR explicitly skipped (Zoom not available)
- [ ] README ## Security & Privacy + SECURITY.md §"How to Verify" caveat language matches observed behaviour

**Tester:** _____________  **Date:** _____________

## Reference: honest framing language for README + SECURITY.md (per RESEARCH Priority 2)
> "PurpleVoice attempts to hide the HUD via NSWindowSharingNone (Hammerspoon hs.canvas pathway). On macOS 15+ (Sequoia), ScreenCaptureKit-based capture tools (modern QuickTime, OBS, Zoom share-screen, Discord, Loom, Teams) capture the HUD regardless — Apple has not exposed a public API to exclude windows from ScreenCaptureKit. The legacy `screencapture` CLI and CGWindowList-based tools still honour NSWindowSharingNone. For sensitive sessions, run with `PURPLEVOICE_HUD_OFF=1`."

---

## Sign-off (Phase 3.5 close 2026-04-30)

- **Tester:** Oliver Allen (live verification on macOS Sequoia 15.7.5, Apple Silicon)
- **Date:** 2026-04-30
- **Result:** PASS — user confirmed "all complete" after walking through B + D + E (A + C already verified during Plan 03.5-01 sign-off `aebd505` / `932ca65`).
- **HUD live state at sign-off:** lavender translucent pill (alpha 0.70) at top-center of active screen, "● Recording" white text, fade-in instant + fade-out 150ms, focus passthrough confirmed, env-var disable confirmed via quit + relaunch with `PURPLEVOICE_HUD_OFF=1`.
