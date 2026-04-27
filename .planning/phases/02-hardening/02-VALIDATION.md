---
phase: 02
slug: hardening
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-27
---

# Phase 02 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Derived from `02-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash + standard POSIX utils (printf, grep, awk, sox, soxi); no test runner needed — each test is a standalone executable script that exits 0/non-zero |
| **Config file** | none — Wave 0 creates `tests/run_all.sh` and `tests/lib/sample_audio.sh` helpers |
| **Quick run command** | `bash tests/test_<name>.sh` for individual tests |
| **Full suite command** | `bash tests/run_all.sh` |
| **Estimated runtime** | ~10–20 seconds (unit tests synthesise short WAVs via `sox -n synth`; whisper-cli runs only in `test_vad_silence.sh`) |

---

## Sampling Rate

- **After every task commit:** Run the affected unit test (e.g., editing the duration gate code → `bash tests/test_duration_gate.sh`)
- **After every plan wave:** Run `bash tests/run_all.sh` (full unit suite)
- **Before phase verification:** Full suite must be green AND manual walkthroughs against the 5 ROADMAP success criteria completed
- **Max feedback latency:** ~20 seconds (full suite)

---

## Per-Task Verification Map

| Req ID | Behavior | Test Type | Automated Command | File Exists | Status |
|--------|----------|-----------|-------------------|-------------|--------|
| TRA-04 | VAD trims silence so silent recordings produce empty/denylisted output | integration | `bash tests/test_vad_silence.sh` | ❌ W0 | ⬜ pending |
| TRA-05 | Clips < 0.4 s exit 2 silently | unit | `bash tests/test_duration_gate.sh` | ❌ W0 | ⬜ pending |
| TRA-06 | Each denylist phrase triggers exit 3; non-denylist phrase passes through | unit | `bash tests/test_denylist.sh` | ❌ W0 | ⬜ pending |
| INJ-02 | Prior clipboard restored after paste | manual (Hammerspoon required) | `tests/manual/test_clipboard_restore.md` walkthrough | ❌ W0 | ⬜ pending |
| INJ-03 | Transcript marked transient — Maccy does NOT record | manual (Hammerspoon + Maccy required) | `tests/manual/test_transient_marker.md` walkthrough | ❌ W0 | ⬜ pending |
| INJ-04 | Empty/whitespace transcript → exit 3 silently | unit (covered by TRA-06 empty case) | `bash tests/test_denylist.sh` | ❌ W0 | ⬜ pending |
| FBK-01 | Menubar `●` is grey idle, red recording | manual (visual) | `tests/manual/test_menubar.md` walkthrough | ❌ W0 | ⬜ pending |
| FBK-02 | Pop on press, Tink on release; suppressed by VOICE_CC_NO_SOUNDS=1 | manual (audible) | `tests/manual/test_audio_cues.md` walkthrough | ❌ W0 | ⬜ pending |
| FBK-03 | Notification appears with deep link button on TCC denial | manual (TCC manipulation required) | `tests/manual/test_tcc_notification.md` walkthrough | ❌ W0 | ⬜ pending |
| ROB-01 | Rapid double-press shows ONE sox process | manual (`pgrep -fa sox`) | `tests/manual/test_reentrancy.md` walkthrough | ❌ W0 | ⬜ pending |
| ROB-02 | sox stderr fingerprint detected → exit 10 | unit (synthetic stderr) + live host | `bash tests/test_tcc_grep.sh` + manual | ❌ W0 | ⬜ pending |
| ROB-04 | After invocation, `/tmp/voice-cc/` is empty (or contains only in-flight WAV) | unit + signal | `bash tests/test_wav_cleanup.sh`, `bash tests/test_sigint_cleanup.sh` | ❌ W0 | ⬜ pending |
| Phase-1 TODO (a) | Module load surfaces Accessibility prompt deterministically | manual | `tests/manual/test_accessibility_prompt.md` walkthrough (requires `tccutil reset Accessibility`) | ❌ W0 | ⬜ pending |
| Phase-1 TODO (b) | `hs -c "1+1"` returns 2 after `require("hs.ipc")` | automated (post-reload) | `[ "$(hs -c '1+1' 2>/dev/null)" = '2' ]` | n/a | ⬜ pending |
| Phase-1 TODO (c) | After successful run, no .txt in /tmp/voice-cc/ | unit (covered by ROB-04 wav_cleanup) | `bash tests/test_wav_cleanup.sh` | ❌ W0 | ⬜ pending |
| Pattern 2 boundary | One WHISPER_BIN assignment + one use inside transcribe() | static | `[ "$(grep -c WHISPER_BIN voice-cc-record)" -eq 2 ]` | ✅ | ⬜ pending |
| Absolute paths | All binaries invoked via `${SOX|SOXI|WHISPER}_BIN` | static | `grep -E '"\$\{(SOX\|SOXI\|WHISPER)_BIN' voice-cc-record \| wc -l` ≥ 4 | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Wave 0 creates the bash test infrastructure before any hardening implementation begins. The planner may merge Wave 0 into the first implementation wave (test-driven) or run it standalone.

- [ ] `tests/run_all.sh` — runs every `tests/test_*.sh` and reports pass/fail
- [ ] `tests/lib/sample_audio.sh` — helper to generate test WAVs (silence, short tap, clean speech) via `sox -n synth`
- [ ] `tests/test_duration_gate.sh` — covers TRA-05
- [ ] `tests/test_denylist.sh` — covers TRA-06 + INJ-04 (empty + whitespace cases)
- [ ] `tests/test_vad_silence.sh` — covers TRA-04 (integration; requires Silero VAD model present)
- [ ] `tests/test_tcc_grep.sh` — covers ROB-02 (synthetic stderr in temp file)
- [ ] `tests/test_wav_cleanup.sh` — covers ROB-04 + Phase-1 TODO c (asserts /tmp/voice-cc empty post-run)
- [ ] `tests/test_sigint_cleanup.sh` — covers ROB-04 SIGINT path
- [ ] `tests/manual/test_clipboard_restore.md` — walkthrough for INJ-02
- [ ] `tests/manual/test_transient_marker.md` — walkthrough for INJ-03 (Maccy verification)
- [ ] `tests/manual/test_menubar.md` — walkthrough for FBK-01
- [ ] `tests/manual/test_audio_cues.md` — walkthrough for FBK-02
- [ ] `tests/manual/test_tcc_notification.md` — walkthrough for FBK-03
- [ ] `tests/manual/test_reentrancy.md` — walkthrough for ROB-01
- [ ] `tests/manual/test_accessibility_prompt.md` — walkthrough for Phase-1 TODO (a)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Prior clipboard restored after paste | INJ-02 | Requires live Hammerspoon press → release → paste cycle; can't unit-test pasteboard timing | `tests/manual/test_clipboard_restore.md` |
| Maccy does NOT record transcript | INJ-03 | Requires Maccy installed + observation of its history | `tests/manual/test_transient_marker.md` |
| Menubar `●` grey/red state change | FBK-01 | Visual; can't programmatically inspect Hammerspoon menubar items reliably | `tests/manual/test_menubar.md` |
| Pop/Tink audio cues + VOICE_CC_NO_SOUNDS gate | FBK-02 | Audible; confirms cue presence + gate works | `tests/manual/test_audio_cues.md` |
| Notification + deep-link button on TCC denial | FBK-03 | Requires `tccutil reset Microphone org.hammerspoon.Hammerspoon` + observation of macOS notification UI | `tests/manual/test_tcc_notification.md` |
| Rapid double-press → ONE sox process | ROB-01 | Requires Hammerspoon press timing + `pgrep -fa sox` observation | `tests/manual/test_reentrancy.md` |
| Accessibility prompt fires on first reload | Phase-1 TODO (a) | Requires `tccutil reset Accessibility org.hammerspoon.Hammerspoon` + observation of macOS prompt | `tests/manual/test_accessibility_prompt.md` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 20s
- [ ] `nyquist_compliant: true` set in frontmatter (after Wave 0 completes)

**Approval:** pending

---
*Derived from 02-RESEARCH.md § Validation Architecture (committed 147e808)*
