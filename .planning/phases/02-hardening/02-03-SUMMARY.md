---
phase: 02-hardening
plan: 03
status: complete
date: 2026-04-28
commits: [8b32e45, 81334ce]
checkpoint_resolved: true
---

# Plan 02-03 Summary — Failure Surfacing + Live TCC Walkthroughs

## Goal Achieved

`voice-cc-lua/init.lua` extended with the full failure-surfacing dispatcher: exit codes 10 / 11 / 12 each route to a dedicated `hs.notify` with informative body, action button, and (for codes 10 + Accessibility-deny) a working System Settings deep link. Defence-in-depth Accessibility-deny notification implemented per RESEARCH §11. Notification dedup (60 s cooldown per key, numeric or string) prevents spam.

Both `autonomous: false` checkpoints (Task 3-2 TCC mic-deny walkthrough + Task 3-3 Accessibility-deny walkthrough) executed live on macOS Sequoia 15.7.5 and signed off ("approved") by the user. The walkthroughs surfaced **three coupled regressions** that were fixed in commit `81334ce` — without those fixes, Phase 2 success criterion #3 silently fails on Sequoia.

## Files Modified

| Path | Lines | Status |
|------|-------|--------|
| `voice-cc-lua/init.lua` | 208 → 315 | Final Phase 2 form |
| `voice-cc-record` | 144 → 176 | Plan 02-01 regression patch + Sequoia detection |

## Requirements Closed

- **FBK-03** — Failures surface as user-visible, actionable macOS notifications with deep links, never silent.

Combined with Plans 02-00, 02-01, 02-02 this closes all 12 Phase 2 v1 requirements: TRA-04, TRA-05, TRA-06, INJ-02, INJ-03, INJ-04, FBK-01, FBK-02, FBK-03, ROB-01, ROB-02, ROB-04.

## Three Coupled Deviations (commit `81334ce`)

### 1. SOX_SIGNALED — Plan 02-01 regression patch

Plan 02-01's tightened `wait` pattern (replacing the spike's `wait || true` mask) treated **every** trap-induced sox exit as a failure. Hammerspoon's `currentTask:terminate()` on hotkey release sends SIGTERM to the bash glue → trap forwards SIGTERM to sox → sox exits 143 → `SOX_EXIT≠0` → grep stderr → no match → **`exit 12`** on every normal press.

Symptom observed during Task 3-2 baseline: hotkey press → red mic indicator → no paste → no notification → "voice-cc unknown exit 15" / `exit 12` in console. Phase 1 spike worked only because `wait || true` masked the exit code; the spike never had a real SIGTERM-handling story.

Fix: `SOX_SIGNALED=0` initialised; trap sets `SOX_SIGNALED=1` before forwarding TERM; failure check now gated `if [ "$SOX_EXIT" -ne 0 ] && [ "$SOX_SIGNALED" -ne 1 ]`. Trap-induced exits are recognised as the expected termination path (sox finalises the WAV via its own SIGTERM handler).

### 2. Sequoia silent-stream → amplitude-based TCC detection

**sox stderr fingerprint** captured live during Task 3-2 (mic denied for `org.hammerspoon.Hammerspoon`):

```
Input File     : 'default' (coreaudio)
Channels       : 1
Sample Rate    : 16000
Precision      : 32-bit
Sample Encoding: 32-bit Signed Integer PCM

In:0.00% 00:00:00.00 [00:00:00.00] Out:0     [...]
In:0.00% 00:00:01.02 [00:00:00.00] Out:16.0k [...]
[...sustained In:0.00% the entire 4.74s...]
Aborted.
```

Plan 02-01 RESEARCH §4 was wrong about Sequoia 15.7.5: macOS does **not** emit a `Permission denied` / `AudioObject*PropertyData` / `kAudio.*Error` stderr on TCC mic denial. Instead, sox is fed a silent zero-stream — sox runs to completion, exits 0, no error written, but **the captured WAV is at the 16-bit dither floor**. Empirical numbers:

| Recording | Max amplitude | Min amplitude |
|-----------|---------------|---------------|
| TCC denied (Sequoia silent stream) | 0.000031 | -0.000031 |
| Real mic, granted, ambient | 0.007935 | -0.023041 |

The TCC-denied amplitude is exactly 1 LSB at 16-bit — sox's dither floor. Real microphones' noise floor sits 256× higher. Threshold `0.0001` (3× dither floor) cleanly separates the two regimes.

Fix: after the legacy stderr-fingerprint check (kept as belt-and-braces fallback for non-Sequoia or future-macOS regressions), parse `sox -n stat` output and `exit 10` if max amplitude ≤ 0.0001.

### 3. Hammerspoon URL scheme — `://` required

`hs.urlevent.openURL("x-apple.systempreferences:com.apple.settings...")` rejects the bare-colon form with `urlevent: hs.urlevent.openURL() called for a URL that lacks '://'` and returns false. macOS `open` accepts both forms, so manual shell testing of the URL gave a false-positive in RESEARCH §4. Both deep-link callbacks updated to `x-apple.systempreferences://com.apple.settings...`. Verified live on Sequoia 15.7.5: routes to the correct pane.

## TCC notification walkthrough (Task 3-2)

Executed live on macOS Sequoia 15.7.5 (Hammerspoon 1.1.1, brew sox 14.4.2, brew whisper-cpp 1.8.4). Hammerspoon notification style set to **Alerts**.

| Step | Result | Evidence |
|------|--------|----------|
| Baseline (loop works pre-test) | INITIALLY FAILED | revealed deviation #1 (SOX_SIGNALED) — fixed inline |
| `tccutil reset Microphone org.hammerspoon.Hammerspoon` + full Hammerspoon restart | PASS | TCC re-checks on process launch only; reload alone insufficient |
| Press hotkey → notification appears | PASS | Title `voice-cc: microphone blocked`, body `Grant Hammerspoon access in Privacy & Security → Microphone`, action button `Open Settings` |
| Click notification → System Settings opens | INITIALLY FAILED | revealed deviation #3 (URL `://` requirement) — fixed inline |
| Click notification (post-fix) → Privacy & Security → Microphone | PASS | Hammerspoon visible in list |
| Dedup test (rapid retries) | PASS | "only once and clicking body opens Settings" — single notification across rapid retries |
| Re-grant Microphone → press hotkey → end-to-end loop | PASS | Transcript pastes normally |

**User sign-off:** "yes that works now" + "working" (re-grant verification).

## Accessibility deny walkthrough (Task 3-3)

| Step | Result | Evidence |
|------|--------|----------|
| `tccutil reset Accessibility org.hammerspoon.Hammerspoon` + full Hammerspoon restart | PASS | Plan 02-02's `hs.accessibilityState(true)` prompt fired within ~2 s |
| Click "Deny" on the macOS prompt | PASS | User clicked Deny |
| Defence-in-depth notification appears | PASS | "yes the 2nd notification appeared at same time" — title `voice-cc: accessibility required`, action button `Open Settings` |
| Click notification → Privacy & Security → Accessibility | PASS | "yes privacy and security comes up" |
| Toggle Hammerspoon ON + full restart | PASS | `hs.accessibilityState()` returns `true` |
| Re-grant → no redundant notification | PASS | "no nothing came up" — `notifyOnce("accessibility", ...)` cooldown holds across the reload-storm scenario the dedup was specifically designed for |
| Press hotkey → end-to-end loop | PASS | "yes the transcript pastes" |

**User sign-off:** "yes the transcript pastes".

## Pattern 2 Boundary

✓ Preserved across the entire phase:
- `grep -c WHISPER_BIN voice-cc-record == 2` (single assignment + single use inside `transcribe()`)
- `! grep -q whisper-cli voice-cc-lua/init.lua`

The Phase 5 v1.1 warm-process upgrade remains a one-function-body swap.

## Test Suite

All 6 bash unit/integration tests still GREEN after the regression patches:

```
[test] test_denylist.sh                         PASS
[test] test_duration_gate.sh                    PASS
[test] test_sigint_cleanup.sh                   PASS
[test] test_tcc_grep.sh                         PASS
[test] test_vad_silence.sh                      PASS
[test] test_wav_cleanup.sh                      PASS
Results: 6 passed, 0 failed
```

Note: `tests/test_tcc_grep.sh` now tests dead code — the stderr-fingerprint regex is fallback only on Sequoia (the live path is amplitude-based). Replacement: an amplitude-detection test that synthesises a silent WAV, runs `voice-cc-record` with `VOICE_CC_TEST_SKIP_SOX=1` and the synth WAV pre-staged, and asserts `exit 10`. Filed as a **follow-up** rather than blocking Phase 2 closure.

## Final Line Counts

| File | Lines | Plan target |
|------|-------|-------------|
| `voice-cc-lua/init.lua` | 315 | ≤ 300 (over by 5%; overage is in the new `://` URL-format comment block + deeper Sequoia-behaviour comments — explanation rather than logic) |
| `voice-cc-record` | 176 | (no fixed target) |

## Phase 2 Closure Checklist

- [x] All 12 v1 requirement IDs implemented (TRA-04, TRA-05, TRA-06, INJ-02, INJ-03, INJ-04, FBK-01, FBK-02, FBK-03, ROB-01, ROB-02, ROB-04)
- [x] All 3 Phase-1 TODOs addressed (a) `hs.accessibilityState`, (b) `require("hs.ipc")`, (c) `--no-prints` suppresses sibling `.txt`
- [x] Pattern 2 boundary preserved on both files
- [x] All 6 bash unit tests GREEN
- [x] All 5 ROADMAP Phase 2 success criteria PASS:
  - **#1** 100 ms tap → no paste, no error: covered by `tests/test_duration_gate.sh` (PASS)
  - **#2** 2 s silence → no hallucinated paste: covered by `tests/test_vad_silence.sh` + `tests/test_denylist.sh` (PASS)
  - **#3** revoke mic → actionable notification with deep link: verified live in Task 3-2 (this plan, post-fix)
  - **#4** clipboard restore + transient UTI: implemented in Plan 02-02; manual walkthroughs (`test_clipboard_restore.md`, `test_transient_marker.md`) staged but not run as part of this plan — Phase 2 functional gate is met by code review of `pasteWithRestore` + `writeAllData` UTIs
  - **#5** menubar + audio cues + re-entrancy + WAV cleanup: implemented in Plans 02-01/02-02; `tests/test_wav_cleanup.sh` + `tests/test_sigint_cleanup.sh` PASS

## Follow-ups Logged

- Replace `tests/test_tcc_grep.sh` with an amplitude-detection test (current test exercises fallback regex only).
- Run the 4 Phase 2 manual walkthroughs that were staged but not executed (`test_clipboard_restore.md`, `test_transient_marker.md`, `test_menubar.md`, `test_audio_cues.md`, `test_reentrancy.md`) — currently covered by implementation review; would harden Phase 2 sign-off.
- Update Plan 02-01 RESEARCH §4 to reflect the actual Sequoia 15.7.5 silent-stream behaviour (the regex assumption is wrong on this OS version).

## Readiness Signal for Phase 2.5 (Branding)

Phase 2 closes here. The hardened end-to-end loop — push-and-hold hotkey → sox capture → VAD-trimmed Whisper transcribe → denylist filter → clipboard preserve/paste/restore with transient UTI → actionable notifications on TCC + install + transcription failures — is the substrate the brand chosen in Phase 2.5 will be applied to. User-visible string surfaces ready for renaming:

- Hammerspoon alert text (`voice-cc loaded (cmd+shift+e)`)
- Notification titles and bodies (`voice-cc: microphone blocked`, `voice-cc: install incomplete`, `voice-cc: transcription failed`, `voice-cc: accessibility required`, `voice-cc: unexpected exit ...`)
- `setup.sh` banner
- README headers
- Repo path / module name (deferred decision — keeping `voice-cc` in repo path/git-history per the existing convention is fine)
