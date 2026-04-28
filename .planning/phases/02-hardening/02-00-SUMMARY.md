---
phase: 02-hardening
plan: 00
subsystem: test-infrastructure
tags: [tests, vad, denylist, setup, wave-0]
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-28
duration_minutes: ~9
dependency_graph:
  requires: []
  provides:
    - "tests/run_all.sh — Phase 2 test suite runner (iterates tests/test_*.sh, exit 0 only if all pass)"
    - "tests/lib/sample_audio.sh — silence_wav / tone_wav / short_tap_wav / medium_wav helpers"
    - "tests/test_*.sh × 6 — TRA-04, TRA-05, TRA-06, INJ-04, ROB-02, ROB-04 unit/integration coverage (most RED until Plan 02-01)"
    - "tests/manual/test_*.md × 7 — INJ-02, INJ-03, FBK-01, FBK-02, FBK-03, ROB-01, Phase-1 TODO (a) walkthrough scripts"
    - "config/denylist.txt — 19 canonical Whisper hallucination phrases (project-owned)"
    - "setup.sh Step 5b — Silero VAD weights downloader (885 KB, size sanity check ≥ 800,000 bytes, idempotent)"
    - "setup.sh Step 6b — denylist.txt installer (always-overwrite, project-owned)"
    - "~/.local/share/voice-cc/models/ggml-silero-v6.2.0.bin (885,098 bytes) installed on host"
    - "~/.config/voice-cc/denylist.txt installed on host"
  affects:
    - "Plan 02-01 (bash hardening) — must use the EXACT predicates encoded in test_duration_gate / test_denylist / test_tcc_grep, AND must implement the VOICE_CC_TEST_SKIP_SOX hook so test_wav_cleanup + test_sigint_cleanup turn GREEN"
    - "Plan 02-02 (lua hardening) — manual walkthroughs in tests/manual/ are its acceptance criteria"
    - "Plan 02-03 (failure surfacing) — test_tcc_notification.md + test_accessibility_prompt.md are its acceptance criteria"
tech-stack:
  added:
    - "Silero VAD ggml weights v6.2.0 (885 KB) — sourced from huggingface.co/ggml-org/whisper-vad"
  patterns:
    - "Bash test-suite runner pattern: standalone executables, exit 0/non-zero, no test-runner framework"
    - "WAV synthesis via `sox -n -r 16000 -c 1 -b 16 OUT synth DUR sine FREQ` — produces whisper.cpp-format WAVs without a microphone"
    - "Setup.sh idempotency pattern: `[ -f FILE ] && [ \"$(stat -f%z FILE)\" -ge MIN ] && skip || download` — extends Phase 1's checksum pattern to a size sanity check for files where SHA256 isn't pinned"
    - "Project-owned config files (always-overwrite) vs user-owned config files (no-clobber) — denylist.txt is the first project-owned config; vocab.txt remains user-owned"
key-files:
  created:
    - "tests/run_all.sh (39 lines, executable)"
    - "tests/lib/sample_audio.sh (44 lines, sourced)"
    - "tests/test_duration_gate.sh (53 lines, executable)"
    - "tests/test_denylist.sh (62 lines, executable)"
    - "tests/test_vad_silence.sh (53 lines, executable)"
    - "tests/test_tcc_grep.sh (37 lines, executable)"
    - "tests/test_wav_cleanup.sh (37 lines, executable)"
    - "tests/test_sigint_cleanup.sh (45 lines, executable)"
    - "tests/manual/test_clipboard_restore.md (33 lines)"
    - "tests/manual/test_transient_marker.md (40 lines)"
    - "tests/manual/test_menubar.md (31 lines)"
    - "tests/manual/test_audio_cues.md (39 lines)"
    - "tests/manual/test_tcc_notification.md (40 lines)"
    - "tests/manual/test_reentrancy.md (35 lines)"
    - "tests/manual/test_accessibility_prompt.md (34 lines)"
    - "config/denylist.txt (28 lines incl. comments; 19 phrase lines)"
  modified:
    - "setup.sh (146 → 165 lines; +Step 5b Silero VAD download + Step 6b denylist install; Phase 1 Steps 1-7 untouched)"
decisions:
  - "Denylist counts as 19 phrases (not 18 as the plan's min_lines suggested) — the canonical list from RESEARCH §3 has 19 entries including the bare `.` line. Both spec and host file match; min_lines was a soft floor."
  - "Test framework deliberately omits `set -e` in run_all.sh so a failing test doesn't abort the suite — every test runs every time."
  - "Integration assertions (e.g., voice-cc-record exits 2 on a 100ms WAV) are gated behind VOICE_CC_INTEGRATION=1 in test_duration_gate.sh, because they require Plan 02-01's VOICE_CC_TEST_SKIP_SOX hook. Logic-only assertions are unconditional."
metrics:
  duration: "~9 minutes (executor wall-clock from STATE.md last_updated 07:03 to final task commit 07:11)"
  completed_date: 2026-04-28
  task_count: 3
  file_count: 17
  commits: 3
---

# Phase 02 Plan 00: Wave 0 Test Infrastructure Summary

Bash test-suite scaffolding (run_all.sh + sample_audio.sh helpers + 6 unit/integration test_*.sh + 7 manual walkthrough .md), canonical 19-phrase Whisper hallucination denylist, and setup.sh extensions to install Silero VAD weights and seed the denylist — all delivered atomically before any Phase 2 implementation begins.

## What Was Built

**Test infrastructure (tests/):**

- **`run_all.sh`** — 39-line executable bash. Iterates every `tests/test_*.sh` in alphabetical order, captures pass/fail by exit code, prints per-test status + final summary, exits 0 only if all passed. Empty-suite case handled cleanly (exits 0). Deliberately omits `set -e` so one failing test doesn't abort the suite.

- **`lib/sample_audio.sh`** — 44-line sourced helper (not executed). Defines four WAV synthesis functions:
  - `silence_wav PATH DURATION` — 16 kHz mono 16-bit silent WAV via `sox -n synth ... sine 0 vol 0`
  - `tone_wav PATH DURATION [FREQ]` — 16 kHz mono tone (default 440 Hz)
  - `short_tap_wav PATH` — 100 ms silence (canonical "accidental tap" for TRA-05)
  - `medium_wav PATH` — 1.0s tone @ 440 Hz (long enough to clear the 0.4s duration gate; required by `test_sigint_cleanup.sh`)

- **6 unit/integration tests** — each standalone executable, sources `lib/sample_audio.sh` as needed, prints PASS/FAIL line, exits 0 / non-zero:
  - `test_duration_gate.sh` (TRA-05) — synthesises 100 ms WAV, runs the EXACT awk float-compare predicate Plan 02-01 must use (`awk -v d="$DURATION" 'BEGIN { exit !(d < 0.4) }'`)
  - `test_denylist.sh` (TRA-06 + INJ-04) — encodes the EXACT canonicalisation pipeline (`tr -d '[:space:]' | tr '[:upper:]' '[:lower:]'`), tests round-trip + substring-rejection ("thanks for adding dark mode" must NOT match "thanks for watching") + empty-string drop
  - `test_vad_silence.sh` (TRA-04) — synthesises 2s silence, runs whisper-cli with the EXACT VAD flags (`--vad --vad-model SILERO --vad-threshold 0.50 --suppress-nst`), asserts empty or known-hallucination output
  - `test_tcc_grep.sh` (ROB-02) — synthetic sox stderr through the EXACT regex (`Permission denied|AudioObject(GetPropertyData|SetPropertyData)|kAudio.*Error`); positive + negative (false-positive guard)
  - `test_wav_cleanup.sh` (ROB-04 + Phase-1 TODO c) — uses `VOICE_CC_TEST_SKIP_SOX=1` hook (Plan 02-01) + 100ms pre-staged WAV; asserts `/tmp/voice-cc/` has no leftover `*.wav`, `*.txt`, `sox.stderr`
  - `test_sigint_cleanup.sh` (ROB-04 SIGINT path) — uses `medium_wav` (1s tone) so duration gate is CLEARED and the SIGINT path is genuinely exercised; backgrounds voice-cc-record, sends `kill -INT` after 0.5s, asserts cleanup

**7 manual walkthrough scripts (tests/manual/):**

Each is self-contained — a tester can execute without reading the plan. Format: title + requirement ID + prerequisites + numbered steps + expected outcome per step + failure-mode hints + sign-off checklist with tester/date.

- `test_clipboard_restore.md` (INJ-02)
- `test_transient_marker.md` (INJ-03)
- `test_menubar.md` (FBK-01)
- `test_audio_cues.md` (FBK-02)
- `test_tcc_notification.md` (FBK-03)
- `test_reentrancy.md` (ROB-01)
- `test_accessibility_prompt.md` (Phase-1 TODO a)

**`config/denylist.txt`** — 19 canonical Whisper hallucination phrases verbatim from 02-RESEARCH §3 (sourced from whisper.cpp #1592, #1724, openai/whisper #1873). Header comment documents canonicalisation rules: whitespace-strip + lowercase, whole-transcript exact-match only, substring matching FORBIDDEN.

**`setup.sh` extensions** — additive, Phase 1 Steps 1–7 untouched:

- **Step 5b: Silero VAD weights download** — 19-line block inserted after Step 5. Downloads from `https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v6.2.0.bin` (885 KB). Idempotent: skips if file present and ≥ `SILERO_SIZE_MIN=800000` bytes. Deletes + aborts if downloaded file is suspiciously small.
- **Step 6b: denylist.txt install** — 11-line block inserted after Step 6. Always-overwrite copy from `config/denylist.txt` to `~/.config/voice-cc/denylist.txt`. Project-owned (we add new known hallucinations as the community reports them); user can `chmod -w` to pin.

## Suite First-Run Status (after all 3 tasks complete)

```
  [test] test_denylist.sh                         PASS
  [test] test_duration_gate.sh                    PASS
  [test] test_sigint_cleanup.sh                   FAIL
  [test] test_tcc_grep.sh                         PASS
  [test] test_vad_silence.sh                      PASS
  [test] test_wav_cleanup.sh                      FAIL

Results: 4 passed, 2 failed
```

**Why each PASS:**
- `test_duration_gate.sh` — pure logic test; the awk predicate works on a synthesised 100 ms WAV regardless of voice-cc-record state.
- `test_tcc_grep.sh` — pure logic test; the regex is verified against synthetic stderr files (positive + negative).
- `test_denylist.sh` — `~/.config/voice-cc/denylist.txt` was installed by Task 0-3 setup.sh run; canonicalisation predicate works end-to-end.
- `test_vad_silence.sh` — Silero weights at `~/.local/share/voice-cc/models/ggml-silero-v6.2.0.bin` (885,098 bytes) were installed by Task 0-3 setup.sh run; whisper-cli with VAD on 2s of silence produces empty / `[BLANK_AUDIO]` output (denylisted form).

**Why each FAIL — RED-and-expected (will turn GREEN under Plan 02-01):**
- `test_wav_cleanup.sh` — fast-fails with explicit message: "voice-cc-record does not support VOICE_CC_TEST_SKIP_SOX hook (Plan 02-01 not yet implemented — expected RED)". Plan 02-01 must add the hook + the EXIT trap that cleans `/tmp/voice-cc/*.wav`, `*.txt`, `sox.stderr`.
- `test_sigint_cleanup.sh` — same fast-fail message. Plan 02-01 must additionally ensure the EXIT trap fires on SIGINT (not just normal exit). Test uses `medium_wav` (1.0s tone, 440 Hz) to pre-stage a WAV that clears the 0.4s duration gate so the script reaches a wait-able state where SIGINT can land — see test file's CRITICAL design note for the rationale.

## RED Test Inventory (handoff to Plan 02-01)

The 2 RED tests above are the contract Plan 02-01 must satisfy to turn the suite fully GREEN. Plan 02-01 must:

1. Add `VOICE_CC_TEST_SKIP_SOX` env-var support to `voice-cc-record` (skip the actual sox capture; trust whatever WAV is at `/tmp/voice-cc/recording.wav`)
2. Add an EXIT trap that removes `/tmp/voice-cc/*.wav`, `*.txt`, `sox.stderr` on every exit path including SIGTERM/SIGINT
3. Implement the duration gate using the EXACT awk predicate from `test_duration_gate.sh`
4. Implement the denylist filter using the EXACT canonicalisation pipeline from `test_denylist.sh`
5. Implement the TCC stderr fingerprint check using the EXACT regex from `test_tcc_grep.sh`
6. Add the VAD flags from `test_vad_silence.sh` to `transcribe()`

Plan 02-02 has no automated-test acceptance from Wave 0; its acceptance is the 7 manual walkthrough scripts.

## Setup.sh Diff Summary

```
146 lines (Phase 1) → 165 lines (Phase 2 Wave 0)
+19 lines: Step 5b (Silero VAD weights download with size sanity check)
+11 lines: Step 6b (denylist.txt always-overwrite install)
 0 lines changed in Phase 1 Steps 1-7
```

Both extensions are idempotent. First setup.sh run downloads Silero (864 KB curl progress, 885,098 bytes on disk) and copies denylist; second run reports "Silero VAD weights present, skipping" and re-overwrites denylist (project-owned, expected). Both runs exit 0.

## Host State After Wave 0

| Path | Size | Source | Notes |
|------|------|--------|-------|
| `~/.local/share/voice-cc/models/ggml-silero-v6.2.0.bin` | 885,098 bytes | `huggingface.co/ggml-org/whisper-vad` | Above 800,000-byte sanity threshold; ready for whisper-cli `--vad-model` |
| `~/.config/voice-cc/denylist.txt` | 795 bytes | `config/denylist.txt` (project-owned) | 19 phrase lines + 7 comment lines; re-overwritten on every setup.sh run |
| `~/.config/voice-cc/vocab.txt` | (unchanged) | seeded Phase 1; user-owned | No-clobber (Phase 1 contract preserved) |
| `~/.local/share/voice-cc/models/ggml-small.en.bin` | (unchanged) | Phase 1 | Checksum-verified Phase 1 model |

## Pattern 2 Boundary

Verified preserved: `grep -c WHISPER_BIN voice-cc-record == 2` (single assignment + single use inside `transcribe()`). Wave 0 does NOT modify `voice-cc-record` (Plan 02-01's job). The transcribe boundary discipline established in Plan 01-02 is intact.

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written.

### Notes

**Acceptance criterion phrasing:** Plan 02-00 Task 0-3 acceptance criterion specified `grep -q "always overwrites" setup.sh`. The setup.sh comment block uses both forms: `always-overwrite` (hyphenated, line 154) and `Always overwrites` (line 157, capital A). The qualifier "(or similar always-overwrite comment)" in the plan was honoured — case-insensitive grep matches. No code change needed; flagged here for transparency.

**Plan min_lines vs canonical phrase count:** Plan said `config/denylist.txt min_lines: 18`. The canonical list from RESEARCH §3 has 19 phrase lines (including the bare `.` line). Used the canonical 19 as the source of truth — `min_lines` is a floor, not a ceiling.

## Authentication Gates

None. The Hugging Face URL (`huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v6.2.0.bin`) is publicly accessible — no token required. Curl with `--fail` returned 200 on first try.

## Readiness Signal

**Plan 02-01 (bash hardening) — READY.** All 6 unit-test predicates are encoded as literal strings in tests/test_*.sh (awk float-compare, denylist canonicalisation, TCC regex, VAD flags). Silero weights + denylist.txt are on disk. `voice-cc-record` is unchanged (Plan 02-01 will modify it). `VOICE_CC_TEST_SKIP_SOX` hook is the single new test-affordance Plan 02-01 must add — without it, 2 of 6 unit tests stay RED.

**Plan 02-02 (lua hardening) — READY.** All 7 manual walkthrough scripts exist with sign-off checklists; they are the acceptance criteria. No test-infra blockers.

**Plan 02-03 (failure surfacing) — READY.** `test_tcc_notification.md` and `test_accessibility_prompt.md` are its acceptance scripts.

## Self-Check: PASSED

**Files verified to exist:**
- FOUND: tests/run_all.sh
- FOUND: tests/lib/sample_audio.sh
- FOUND: tests/test_duration_gate.sh
- FOUND: tests/test_denylist.sh
- FOUND: tests/test_vad_silence.sh
- FOUND: tests/test_tcc_grep.sh
- FOUND: tests/test_wav_cleanup.sh
- FOUND: tests/test_sigint_cleanup.sh
- FOUND: tests/manual/test_clipboard_restore.md
- FOUND: tests/manual/test_transient_marker.md
- FOUND: tests/manual/test_menubar.md
- FOUND: tests/manual/test_audio_cues.md
- FOUND: tests/manual/test_tcc_notification.md
- FOUND: tests/manual/test_reentrancy.md
- FOUND: tests/manual/test_accessibility_prompt.md
- FOUND: config/denylist.txt
- FOUND: setup.sh (modified)
- FOUND: ~/.local/share/voice-cc/models/ggml-silero-v6.2.0.bin (885,098 bytes)
- FOUND: ~/.config/voice-cc/denylist.txt

**Commits verified to exist:**
- FOUND: b899c28 (Task 0-1: test scaffolding)
- FOUND: 01e6429 (Task 0-2: 6 unit tests)
- FOUND: ed32ad2 (Task 0-3: denylist + manual walkthroughs + setup.sh extensions)
