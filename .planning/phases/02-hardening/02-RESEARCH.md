---
phase: 02-hardening
document: research
status: complete
created: 2026-04-27
researched_by: gsd-researcher
confidence: HIGH
domain: macOS push-to-talk dictation hardening — Hammerspoon Lua + bash glue + whisper.cpp + sox
host_macos: 15.7.5 (Sequoia, build 24G624)
host_chip: Apple Silicon (M2 family per Metal init log: MTLGPUFamilyApple8)
---

# Phase 2: Hardening — Research

> **Deliverable:** Everything the planner needs to break Phase 2 into concrete implementation plans without further research. Each Phase 2 success criterion, requirement ID, and Phase-1-surfaced TODO has a section below with a recommended approach, exact API/flag/URL/code, and a validation plan. Be skeptical of anything not cross-cited.

## Project Constraints (from CLAUDE.md and PROJECT.md)

The following directives are authoritative and constrain every recommendation in this document. Any plan that contradicts them must be rewritten.

- **Platform:** macOS Apple Silicon only. No x86, no Linux, no Windows.
- **Stack ceiling:** Hammerspoon (Lua), whisper.cpp / mlx-whisper, sox/ffmpeg, bash glue. No heavy frameworks, no Electron, no Python web server unless strictly necessary. (sox + whisper.cpp + Hammerspoon already fixed in Phase 1; nothing new added in Phase 2.)
- **Cost:** Zero recurring cost. No API subscriptions, no paid services. (Means: no cloud STT, no managed services, no telemetry.)
- **Dependencies:** Only well-established open-source tools. The two new dependencies Phase 2 introduces are (a) the Silero VAD ggml model file from `ggml-org/whisper-vad` on Hugging Face, (b) optionally `hyperfine` for Phase 3 — not Phase 2.
- **Performance:** End-to-end latency < ~2 s for short utterances. Phase 2's hardening additions (VAD inference, denylist grep, duration gate, clipboard preserve/restore) must collectively add < ~100 ms.
- **Permissions:** Must work within macOS Microphone + Accessibility TCC permissions. Phase 2 must turn the silent-deny modes documented in Phase 1 into actionable surfaces.
- **Audience:** Built for one user (Oliver). No multi-user, no auth, no settings UI in v1.
- **GSD workflow:** All file edits go through GSD commands. No direct repo edits outside a workflow.

## User Constraints (from CONTEXT.md)

> **Note:** No `02-CONTEXT.md` exists yet — Phase 2 has not been through `/gsd:discuss-phase`. The constraints below are derived from the **Phase 2 success criteria in ROADMAP.md** (treated as locked per the prompt) and the **three Phase-1-surfaced Phase-2 candidates from STATE.md Open TODOs** (also treated as locked).

### Locked Decisions (from ROADMAP Phase 2 success criteria + STATE Open TODOs)

1. **Duration gate at 100 ms threshold** — A 100 ms accidental tap must produce no paste and no error. (Note: PITFALLS.md and ARCHITECTURE.md both reference 250 ms / 400 ms thresholds; ROADMAP success criterion #1 specifies 100 ms — see "Duration Gate (TRA-05)" below for resolution.)
2. **VAD must catch silence + denylist exact-match** — Recording 2 s of pure silence must not paste any Whisper hallucination. Means: `--vad` flag is mandatory, Silero weights are mandatory, denylist exact-match is mandatory. All three together.
3. **Revoking mic permission must produce an actionable notification with a System Settings deep link** — never silent failure. Means: bash glue detects sox TCC denial → returns semantic exit code → Lua dispatches `hs.notify` with `actionButtonTitle = "Open Settings"` and on click calls `hs.urlevent.openURL` with the Microphone privacy deep link.
4. **Clipboard preserve/restore within ~250 ms + transient UTI marker** — clipboard managers (1Password, Raycast, Maccy) must NOT retain the transcript permanently. Means: read prior contents, write transcript with `org.nspasteboard.TransientType` UTI alongside, paste, restore prior contents after `hs.timer.doAfter(0.25, ...)`.
5. **Menu-bar indicator + audio cues + re-entrancy + WAV cleanup** — visible menu-bar state change on press; brief start/stop sounds (suppressible via `VOICE_CC_NO_SOUNDS=1`); rapid double-presses produce ONE sox process; no WAVs in `/tmp/voice-cc/` after any exit path including SIGINT.
6. **Three Phase-1 follow-ups MUST be folded into Phase 2:**
   - (a) Add `hs.accessibilityState(true)` to voice-cc-lua/init.lua on load.
   - (b) Add `require("hs.ipc")` to ~/.hammerspoon/init.lua.
   - (c) Suppress whisper-cli's sibling `.txt` output.

### Claude's Discretion (research recommendations expected)

- Where the duration gate lives (Hammerspoon-side hold-time measurement vs bash-side WAV-duration measurement) — see Section 1.
- Exact VAD threshold value (default is 0.50 per `whisper-cli --help`) — see Section 2.
- Denylist phrase set — see Section 3.
- Whether to use the legacy or current System Settings deep-link URL — see Section 4.
- Whether to use `hs.pasteboard.writeAllData` (atomic multi-type) or `setContents` + `writeDataForUTI` (sequential) — see Section 5.
- Re-entrancy policy: ignore-second-press vs cancel-and-restart — see Section 6.
- Exact menubar glyph and audio cue sound files — see Sections 7 and 8.
- Where the `VOICE_CC_NO_SOUNDS` gate lives (bash, Lua, or both) — see Section 8.

### Deferred Ideas (OUT OF SCOPE for Phase 2)

- Branding (Phase 2.5).
- install.sh, README, hyperfine benchmarks (Phase 3).
- Hover UI / HUD (Phase 3.5).
- Quality-of-life features: paste-last-transcript hotkey, cancel-in-flight, replacements.txt, history log, model env-var swap (Phase 4).
- Warm-process upgrade with whisper-server + LaunchAgent (Phase 5, conditional).
- Custom icon/PNG menubar artwork (Phase 2.5 Branding or Phase 4 QoL — Phase 2 uses unicode glyph only).
- AirPods/device-pinning logic (PITFALLS Pitfall 9 — punted; ROB-04 covers WAV cleanup but not AirPods truncation; not in Phase 2's 12-requirement list).
- Vocab A/B comparison (Phase 1 walkthrough deferral; not needed unless it informs denylist tuning, which it doesn't on the evidence we have).

## Phase Requirements

The 12 requirements Phase 2 MUST address, with the research finding that enables each.

| ID | Description | Research Section |
|----|-------------|------------------|
| TRA-04 | Use `--vad` with Silero VAD to suppress silence-region hallucinations | §2 VAD Strategy |
| TRA-05 | Drop audio clips shorter than 0.4 s without invoking Whisper (defends against accidental hotkey taps) | §1 Duration Gate |
| TRA-06 | Filter whole-transcript matches against a denylist of known Whisper hallucinations | §3 Hallucination Denylist |
| INJ-02 | Preserve and restore user's existing clipboard contents after paste, ≥250 ms delay | §5 Clipboard Preserve/Restore |
| INJ-03 | Mark clipboard set with `org.nspasteboard.TransientType` UTI | §5 Clipboard Preserve/Restore |
| INJ-04 | Empty/whitespace-only transcripts silently discarded — no paste, no error toast | §3 Hallucination Denylist (covers empty drop too) |
| FBK-01 | Menu-bar indicator changes colour while recording is active | §7 Menu-bar Indicator |
| FBK-02 | Brief audible cue at recording start and end (default-on, suppressible via env var) | §8 Audio Cues |
| FBK-03 | Failure → actionable macOS notification with clear next step or deep link to System Settings — never silent failure | §4 TCC Detection + §9 Failure Notifications |
| ROB-01 | Rapid repeated hotkey presses do not spawn duplicate recording processes | §6 Re-entrancy Guard |
| ROB-02 | TCC microphone-permission denial detected from sox stderr, surfaced as notification with deep link | §4 TCC Detection |
| ROB-04 | Temporary WAV files cleaned up via shell trap on every exit path including SIGINT | §10 WAV Leak Prevention |

## Summary

Phase 2 is the densest pitfall-prevention phase in the v1 roadmap. Every Phase 1 silent-failure mode is a Phase 2 work item: silent hallucinations on accidental taps, silent paste failures on clipboard manager retention, silent paste failures on TCC denial, silent stuck-mic on rapid double-presses, silent WAV accumulation in /tmp, and silent first-run Accessibility no-op. The good news: the architecture decisions made in Phase 1 (Pattern 2 transcribe() boundary, exit-code control protocol, in-memory Lua state, single named WAV) leave clean insertion points for every fix.

**Primary recommendation:** Implement Phase 2 as additive layers on top of the existing 79-line bash glue and 82-line Lua module. No greenfield code, no new processes, no new dependencies (beyond the 885 KB Silero VAD ggml file from `ggml-org/whisper-vad`). The bash glue grows to ~150 lines (+ duration gate + VAD flags + denylist filter + TCC stderr grep + EXIT trap rewrite + sibling .txt suppression). The Lua module grows to ~200 lines (+ `hs.accessibilityState(true)` + menubar item + sound preload + clipboard preserve/restore with transient UTI + re-entrancy guard + exit-code dispatch with `hs.notify`). The `~/.hammerspoon/init.lua` grows by one line (`require("hs.ipc")`). Pattern 2 boundary is preserved: VAD flags go into `transcribe()`, denylist runs after `transcribe()` returns, nothing else invokes whisper-cli.

**Key insight for the planner:** The 5 ROADMAP success criteria map to natural plan boundaries. We recommend three plans:
- **Plan 02-01: Bash hardening** (TRA-04, TRA-05, TRA-06, INJ-04, ROB-02, ROB-04 + Phase-1 TODO c) — VAD flags + Silero weights install, duration gate, denylist, empty-drop, TCC stderr grep, EXIT trap covering SIGINT, suppress whisper sibling .txt by removing `-otxt -of` and capturing stdout. All in `voice-cc-record`.
- **Plan 02-02: Lua hardening** (FBK-01, FBK-02, INJ-02, INJ-03, ROB-01 + Phase-1 TODOs a, b) — `hs.accessibilityState(true)` on load, `require("hs.ipc")` in `~/.hammerspoon/init.lua`, menubar item, audio cue preload + play, re-entrancy guard, clipboard preserve/restore with transient UTI marker. All in `voice-cc-lua/init.lua` and (one line) `~/.hammerspoon/init.lua`.
- **Plan 02-03: Failure surfacing** (FBK-03 + completes ROB-02) — exit-code dispatch in Lua: `hs.notify` with `actionButtonTitle = "Open Settings"` for exit codes 10/11/12, with deep-link URLs verified for macOS Sequoia 15.

The five success criteria walk-through becomes the verification matrix; see §11 Validation Architecture.

---

## 1. Duration Gate (TRA-05, Success Criterion #1)

**Goal:** A 100 ms accidental hotkey tap produces no paste, no error, no audible cue beyond what's unavoidable from the press handler firing. Silently aborted.

### Threshold conflict — RESOLUTION

There is a documented conflict in the project's research:
- **ROADMAP.md success criterion #1:** "A 100 ms accidental hotkey tap produces no paste and no error." (HIGH authority — this is the locked criterion.)
- **REQUIREMENTS.md TRA-05:** "drops audio clips shorter than **0.4 seconds** without invoking Whisper" (HIGH authority — also locked).
- **PITFALLS.md Pitfall 3:** "if `soxi -D` reports < **0.4 s**, abort silently" — recommends 0.4 s, citing false-positive cost.
- **ARCHITECTURE.md data flow:** uses **0.25 s** as the gate.

**Resolution:** These are not actually in conflict. They describe two different gates layered together:
- **Lower bound (always abort):** any clip shorter than the **0.4 s TRA-05 threshold** (or a value the planner picks in `[0.25, 0.5]`) → silent abort with exit 2. This is the "obvious accidental tap" gate.
- **Upper bound on the success criterion:** a 100 ms tap must definitely fall below the lower bound and abort. 100 ms < 0.4 s, so any threshold in `[0.1, 0.4]` satisfies success criterion #1 by construction.

**Recommendation:** **Use 0.4 s** as the bash-side threshold (matches TRA-05 wording and PITFALLS rationale). Success criterion #1 is then satisfied as a side effect.

### Where to implement: bash-side, not Lua-side

| Approach | Pro | Con | Verdict |
|---|---|---|---|
| **Bash-side: `soxi -D "$WAV"` after sox finishes** | Single point of truth (the actual recorded WAV duration). Catches both genuine taps and edge cases like sox exiting before 100 ms of audio could be captured. Pattern 2 / boundary-preserving (gate runs before `transcribe()`). Works whether the script is invoked from Lua or manually. | Two extra processes (soxi + awk) per invocation — negligible (~2 ms). | **Pick.** |
| Lua-side: measure `os.time()` between press and release | Aborts before bash even spawns; saves the sox launch cost. | Splits the truth across two layers. Doesn't catch sox-failed-to-capture cases. Manual invocation of voice-cc-record bypasses the gate. Still need a bash-side gate as defence in depth. | Don't bother — the bash gate alone is sufficient. |
| Both | Belt + braces. | Two places to keep in sync. | Overkill for v1. |

### Implementation pattern

```bash
# After `wait "$SOX_PID" || true` and BEFORE calling transcribe()
DURATION=$("$SOXI_BIN" -D "$WAV" 2>/dev/null || echo 0)
# awk because bash arithmetic doesn't do floating point
if awk -v d="$DURATION" 'BEGIN { exit !(d < 0.4) }'; then
  exit 2  # silent abort: clip too short
fi
```

`SOXI_BIN` should be added to the absolute-path block at the top of voice-cc-record (currently only SOX_BIN and WHISPER_BIN are defined): `SOXI_BIN="${SOXI_BIN:-/opt/homebrew/bin/soxi}"`. soxi is bundled with sox — no separate install. **Verified present** at `/opt/homebrew/bin/soxi` per environment audit.

### Validation

- **Unit test:** `tests/test_duration_gate.sh` — generate a 100 ms silent WAV with `sox -n -r 16000 -c 1 -b 16 /tmp/test_short.wav synth 0.1 sine 0`, then run a stripped-down version of the gate logic against it; assert exit 2.
- **Integration:** Hammerspoon hold for ~100 ms (manual walkthrough). Expected: silent — no audio cue at all (because the cue plays on press, not release; Phase 2 plan must keep the cue scope-limited so 100 ms taps don't spam audio either — see §8).

### Sources
- ROADMAP.md success criterion #1 (locked).
- REQUIREMENTS.md TRA-05 (locked).
- PITFALLS.md Pitfall 3 (research).
- ARCHITECTURE.md data flow.

---

## 2. VAD Strategy (TRA-04, Success Criterion #2)

**Goal:** Recording 2 s of pure silence does not paste any Whisper hallucination — caught by VAD + denylist exact-match together. (Denylist is §3 below; this section covers VAD only.)

### Silero weights — sourcing and install

Phase 1's VAD audit established that the Homebrew bottle's `whisper-cli` exposes the full VAD CLI but `--vad-model` defaults to empty (no weights bundled). Phase 2 must source weights.

**HIGH-confidence canonical source:** the `ggml-org/whisper-vad` Hugging Face repo ([direct link](https://huggingface.co/ggml-org/whisper-vad)) hosts the official ggml-converted Silero VAD weights for use with whisper.cpp, maintained by the same upstream team that maintains whisper.cpp.

**Two model versions available:**

| File | Size | Status |
|---|---|---|
| `ggml-silero-v6.2.0.bin` | 885 kB | **Latest** (uploaded 5 months ago per Hugging Face) |
| `ggml-silero-v5.1.2.bin` | 885 kB | Previous; still works |

**Recommendation:** **Use v6.2.0** (latest, same size, same API contract). Pin the version in setup.sh / config.

**Install pattern (additive change to setup.sh in Phase 2 — install.sh proper is Phase 3):**

```bash
# In setup.sh additions for Phase 2:
SILERO_MODEL="$HOME/.local/share/voice-cc/models/ggml-silero-v6.2.0.bin"
SILERO_URL="https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v6.2.0.bin"
SILERO_SIZE_MIN=800000  # 885 KB; 800 KB is the cheap size sanity check

if [ ! -f "$SILERO_MODEL" ] || [ "$(stat -f%z "$SILERO_MODEL" 2>/dev/null || echo 0)" -lt "$SILERO_SIZE_MIN" ]; then
  echo "Downloading Silero VAD weights..."
  curl -L -C - -o "$SILERO_MODEL" "$SILERO_URL"
fi
```

(Optional: add SHA256 verification mirroring the small.en pattern. The Hugging Face `x-linked-etag` header gives the canonical hash; set it when running setup.sh once and pin.)

### whisper-cli VAD invocation flags

From `whisper-cli --help` (captured live from `/opt/homebrew/bin/whisper-cli` on the target machine — HIGH confidence):

```
Voice Activity Detection (VAD) options:
       --vad                           [false  ] enable Voice Activity Detection (VAD)
  -vm  --vad-model FNAME               [       ] VAD model path
  -vt  --vad-threshold N               [0.50   ] VAD threshold for speech recognition
  -vspd --vad-min-speech-duration-ms N [250    ] VAD min speech duration (0.0-1.0)
  -vsd --vad-min-silence-duration-ms N [100    ] VAD min silence duration (to split segments)
  -vmsd --vad-max-speech-duration-s  N [FLT_MAX] VAD max speech duration (auto-split longer)
  -vp  --vad-speech-pad-ms           N [30     ] VAD speech padding (extend segments)
  -vo  --vad-samples-overlap         N [0.10   ] VAD samples overlap (seconds between segments)
```

**Recommended `transcribe()` body (preserves Pattern 2 boundary — only the function body changes):**

```bash
transcribe() {
  local wav_path="$1"
  "$WHISPER_BIN" \
    -m "$MODEL" \
    --language en \
    --no-timestamps \
    --no-prints \
    --vad \
    --vad-model "$SILERO_MODEL" \
    --vad-threshold 0.50 \
    --suppress-nst \
    --prompt "$VOCAB" \
    -f "$wav_path" 2>/dev/null
}
```

**Changes vs Phase 1 transcribe():**
- **Removed `-otxt -of "$out_base"`** — eliminates the sibling .txt file (Phase-1 TODO c). Without `-otxt`, whisper-cli writes the transcript to **stdout only**.
- **Removed the `cat "${out_base}.txt"`** trailing read — stdout is the transcript directly.
- **Added `--no-prints`** — suppresses progress / debug noise that would otherwise pollute stdout. (Verified flag exists per `whisper-cli --help`.)
- **Added `--vad --vad-model "$SILERO_MODEL" --vad-threshold 0.50`** (TRA-04).
- **Added `--suppress-nst`** (suppress non-speech tokens like `[Music]`, `[Applause]` — defence in depth alongside the denylist; verified present per help output and per [PR #2649](https://github.com/ggerganov/whisper.cpp/pull/2649)).
- Stderr is redirected to `/dev/null` (Phase 1 routed it through `>/dev/null 2>&1`; Phase 2 needs stderr available for the TCC fingerprint check on **sox**, but whisper-cli stderr is a different process and can stay suppressed).

### Threshold tuning

The default `--vad-threshold 0.50` is documented as "VAD threshold for speech recognition" — higher values are more aggressive at filtering quiet/noise; lower values pass more borderline segments through to whisper. PITFALLS.md and STACK.md both recommend 0.50 as a sane default. **Recommendation: ship 0.50 by default; expose `VOICE_CC_VAD_THRESHOLD` env var for power-users.** Tuning happens in Phase 4 if needed.

### Sox-side silence detection — alternative considered, rejected

PITFALLS.md mentioned `sox ... silence -1 0.5 1%` as a possible alternative. **Rejected** because:
1. Silero VAD (Whisper-internal, post-recording) is more accurate than sox's amplitude-based silence detection.
2. Adds a sox processing pass between recording and transcription — extra latency.
3. Whisper-VAD is the upstream-maintained, integrated solution.
4. Doesn't avoid the need for the denylist (which catches non-silence hallucinations like brief "you" on coughs).

Use sox's `silence` effect only if Silero proves inadequate — Phase 4 fallback, not Phase 2 primary.

### Validation

- **Integration test:** `tests/test_vad_silence.sh` — record 2 s of silence (pad with sox synth), pipe through the bash glue with VAD enabled, assert empty output (or denylist-caught — both qualify as success).
- **Manual:** Phase 2 walkthrough — hold hotkey for 2 s in a quiet room, expect no paste.

### Sources
- [Hugging Face ggml-org/whisper-vad](https://huggingface.co/ggml-org/whisper-vad/tree/main) — HIGH (official upstream).
- [whisper.cpp Issue #3003 — built-in Silero VAD](https://github.com/ggml-org/whisper.cpp/issues/3003) — HIGH.
- Live `whisper-cli --help` output on Oliver's machine (captured 2026-04-27) — HIGH.
- [PR #2649 — Add option to suppress non-speech tokens](https://github.com/ggerganov/whisper.cpp/pull/2649) — confirms `--suppress-nst` is current and supported.

---

## 3. Hallucination Denylist (TRA-06, INJ-04, Success Criterion #2)

**Goal:** A whole-transcript exact-match against a known-hallucination phrase drops the transcript silently. Substring match is forbidden — a real prompt like "thanks for adding dark mode" must NOT be filtered.

### Phrase list — the canonical Whisper hallucinations

Synthesised from the most-cited community sources ([whisper.cpp #1592](https://github.com/ggml-org/whisper.cpp/issues/1592), [whisper.cpp #1724](https://github.com/ggml-org/whisper.cpp/issues/1724), [openai/whisper #1873](https://github.com/openai/whisper/discussions/1873), and PITFALLS.md). Ranked by how often each appears across multiple reports:

```
# ~/.config/voice-cc/denylist.txt — exact-match (case-insensitive, post-trim)
# Compiled from whisper.cpp #1592, #1724 and openai/whisper #1873.
# Each line is a complete hallucinated transcript that MUST be dropped silently.
# Substring matching is FORBIDDEN — only whole-transcript matches drop.

thank you
thank you.
thank you for watching
thank you for watching.
thanks for watching
thanks for watching!
thanks for watching.
subtitles by the amara.org community
transcription by castingwords
[blank_audio]
[silence]
[music]
[applause]
[typing]
you
you.
.
the end
the end.
```

**Notes on canonicalisation:**
- Compare in **lowercase, with all whitespace stripped** (handles "Thank you", " thank  you ", "thank you\n" all matching the same canonical form).
- Punctuation is part of the canonical form ("thank you" and "thank you." are different entries — Whisper sometimes adds the period, sometimes not).
- **Empty / whitespace-only** transcripts are caught by INJ-04 in the same step (trim → if empty → exit 3).

### Where to apply: post-`transcribe()` in bash

Pattern 2 boundary discipline: `transcribe()` is the SOLE whisper-cli invocation. The denylist filter runs **after** `transcribe()` returns, in the bash glue. Single point of filtering. The Lua side never sees the filtered-out content.

```bash
# After: TRANSCRIPT="$(transcribe "$WAV")"
# After: TRANSCRIPT="$(printf "%s" "$TRANSCRIPT" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

# INJ-04: empty/whitespace-only → silent abort
if [ -z "$TRANSCRIPT" ]; then
  exit 3
fi

# TRA-06: denylist exact-match (whole-transcript only, case-insensitive, whitespace-collapsed)
DENYLIST="$HOME/.config/voice-cc/denylist.txt"
if [ -r "$DENYLIST" ]; then
  CANON_TRANSCRIPT="$(printf "%s" "$TRANSCRIPT" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
  while IFS= read -r phrase; do
    # Skip blank lines and comments
    case "$phrase" in
      ''|'#'*) continue ;;
    esac
    CANON_PHRASE="$(printf "%s" "$phrase" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
    if [ "$CANON_TRANSCRIPT" = "$CANON_PHRASE" ]; then
      exit 3  # silent abort — denylist match
    fi
  done < "$DENYLIST"
fi
```

**Why exit 3 (not exit 2):** Phase 1's transcribe boundary uses exit 0 (success — paste) and exit 2/3 are reserved per ARCHITECTURE.md exit-code allocation. Exit 2 = "silent abort: clip too short"; exit 3 = "silent abort: empty transcript or denylist match." Lua treats both as "do nothing, just reset indicator." See §12 for the full exit-code matrix.

### Config file: `~/.config/voice-cc/denylist.txt`

Mirrors `vocab.txt` placement. Two distinct semantics:
- **vocab.txt** — no-clobber on setup.sh re-run (user owns it after first install).
- **denylist.txt** — **always overwrite** on setup.sh re-run (project owns it; we add new known-hallucinations as the community reports them, per ARCHITECTURE.md install.sh idempotency rules).

Phase 2 must:
1. Add a `denylist.txt.default` (or `denylist.txt` directly) to the repo `config/` directory.
2. Update setup.sh to copy it into `~/.config/voice-cc/denylist.txt` on every run (overwrite, not no-clobber). Reason: project owns the canonical list; user can `sudo chmod -w` if they really want to pin a stale version.

### Validation

- **Unit test:** `tests/test_denylist.sh` — for each phrase in `denylist.txt`, pipe it through the canonicalisation + match logic; assert that exit code is 3.
- **Negative test:** pipe "thanks for adding dark mode toggle" through the same logic; assert exit code is 0 (passes through) — confirms substring-matching is NOT happening.
- **Integration:** Phase 2 walkthrough — hold hotkey 2 s in silence, expect no paste (covered by either VAD or denylist; both qualify as success).

### Sources
- [whisper.cpp #1592 — Automatically adds "Thank you"](https://github.com/ggml-org/whisper.cpp/issues/1592) — HIGH.
- [whisper.cpp #1724 — Hallucination on silence](https://github.com/ggml-org/whisper.cpp/issues/1724) — HIGH.
- [openai/whisper #1873 — Share your hallucinations](https://github.com/openai/whisper/discussions/1873) — HIGH (community-curated).
- PITFALLS.md Pitfall 3 — exact-match-not-substring rule.

---

## 4. TCC Silent-Deny Detection (ROB-02, FBK-03, Success Criterion #3)

**Goal:** Revoke Hammerspoon's microphone permission via `tccutil reset Microphone org.hammerspoon.Hammerspoon`. Press the hotkey. Expect: actionable macOS notification with a working deep link to System Settings → Privacy → Microphone. Never silent failure.

### sox stderr fingerprint when mic permission is revoked

**HONESTY:** I could not capture this empirically without revoking the permission on Oliver's machine, which would disrupt the working setup. The recommended pattern below is based on three converging sources (PITFALLS.md, multiple community reports, the macOS CoreAudio API surface), but **the exact stderr text needs live verification during plan execution.** Plan 02-01 should include an explicit task: deliberately revoke mic permission, run voice-cc-record manually, capture exact stderr, paste into bash glue grep regex, restore permission.

**Recommended starting regex** (based on PITFALLS.md and Apple developer forum threads):

```
Permission denied|AudioObject(GetPropertyData|SetPropertyData)|kAudio.*Error|coreaudio.*can.t open
```

**Implementation pattern in bash glue:**

```bash
# Replace the current `>/dev/null 2>&1` on sox with stderr capture:
SOX_ERR=$("$SOX_BIN" -d -r 16000 -c 1 -b 16 "$WAV" 2>&1 >/dev/null) &
SOX_PID=$!
# Note: this captures sox stderr (we redirect stdout to /dev/null and 2>&1
# captures stderr into SOX_ERR via process substitution alternative below).

# Cleaner: redirect sox stderr to a per-invocation log, grep after exit.
SOX_ERR_LOG="/tmp/voice-cc/sox.stderr"
"$SOX_BIN" -d -r 16000 -c 1 -b 16 "$WAV" >/dev/null 2>"$SOX_ERR_LOG" &
SOX_PID=$!
trap 'kill -TERM "$SOX_PID" 2>/dev/null || true' TERM INT
wait "$SOX_PID"
SOX_EXIT=$?
trap - TERM INT

# TCC silent-deny detection
if [ "$SOX_EXIT" -ne 0 ]; then
  if grep -qE 'Permission denied|AudioObject(GetPropertyData|SetPropertyData)|kAudio.*Error' "$SOX_ERR_LOG"; then
    exit 10  # TCC mic denied
  fi
  # sox failed for some other reason
  exit 12  # generic sox/recording failure
fi
```

**Cleanup:** `SOX_ERR_LOG` should be added to the EXIT trap in §10.

### Lua-side dispatch (Plan 02-03)

The exit-code dispatcher in `voice-cc-lua/init.lua`:

```lua
-- Inside the hs.task callback, replacing the Phase 1 "any non-zero exit means no paste" block:

local function notifyTccDenied()
  hs.notify.new({
    title = "voice-cc: microphone blocked",
    informativeText = "Grant Hammerspoon access in Privacy & Security",
    actionButtonTitle = "Open Settings",
    hasActionButton = true,
    autoWithdraw = false,
    withdrawAfter = 0,  -- persist
  }, function(notif)
    hs.urlevent.openURL("x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Microphone")
  end):send()
end

-- Inside hs.task callback:
if exitCode == 10 then
  notifyTccDenied()
  currentTask = nil
  return
elseif exitCode == 11 then
  -- Model or binary missing — Phase 3 install.sh territory; for Phase 2 surface a generic message
  hs.notify.new({
    title = "voice-cc: install incomplete",
    informativeText = "Run setup.sh — model or binary missing",
    autoWithdraw = false,
  }):send()
  currentTask = nil
  return
elseif exitCode == 12 then
  hs.notify.new({
    title = "voice-cc: transcription failed",
    informativeText = "Check ~/.cache/voice-cc/error.log",
  }):send()
  currentTask = nil
  return
end
```

### macOS Settings deep-link URL — VERIFIED for Sequoia 15

There are TWO URL schemes for the Microphone privacy pane:

| URL | macOS versions | Status |
|---|---|---|
| `x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone` | Catalina–Monterey (current macOS keeps backwards compat) | **Still works** on Sequoia 15.7.5 (verified via web research; Apple maintains the legacy URL scheme for compat). |
| `x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Microphone` | Ventura+ (System Settings extension format) | **Preferred** for Sequoia and later. |

**Recommendation:** Use the **new format** (`com.apple.settings.PrivacySecurity.extension`). Falls in line with Sequoia's actual Settings app structure; the legacy URL is supported for compat but documented as legacy. If the new URL ever stops working in a future macOS release, the legacy URL is a safe fallback.

**For Accessibility (used in §12 Phase-1 TODO a notify path):**
```
x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility
```

### Validation

- **Live host test:** `tests/test_tcc_denial.sh` — manual procedure documented in the test file (cannot be fully automated):
  1. `tccutil reset Microphone org.hammerspoon.Hammerspoon`
  2. Restart Hammerspoon (`hs -c "hs.reload()"` once Phase-1 TODO b is in)
  3. Press the hotkey
  4. **Expected:** notification appears within 1 second, with title "voice-cc: microphone blocked" and an "Open Settings" button. Click the notification → System Settings opens to Privacy → Microphone with Hammerspoon listed.
  5. Re-grant Microphone in Settings; confirm next press works.
- **Bash unit test:** simulate the stderr fingerprint by pre-creating a fake sox.stderr containing "Permission denied" and running the grep block; assert exit 10.

### Sources
- [Apple System Preferences URL Schemes gist (rmcdongit)](https://gist.github.com/rmcdongit/f66ff91e0dad78d4d6346a75ded4b751) — last updated for Sequoia 15.2 — HIGH.
- [Apple Developer Forum — Deeplinks into new System Settings (Ventura+)](https://developer.apple.com/forums/thread/709289) — HIGH.
- PITFALLS.md "TCC Permission Flow" + Pitfall 1 — research notes.
- [Apple Developer Forum — tccutil reset microphone](https://developer.apple.com/forums/thread/679303) — HIGH.

---

## 5. Clipboard Preserve / Restore + Transient UTI (INJ-02, INJ-03, INJ-04, Success Criterion #4)

**Goal:** After a successful paste, the user's prior clipboard is restored within ~250 ms. Clipboard managers (1Password, Raycast, Maccy) DON'T retain the transcript permanently because the clipboard set is marked `org.nspasteboard.TransientType`.

### The `hs.pasteboard` API for multi-type writes — VERIFIED

From the Hammerspoon source ([extensions/pasteboard/pasteboard.lua](https://github.com/Hammerspoon/hammerspoon/blob/master/extensions/pasteboard/pasteboard.lua)):

| Function | Signature | What it does |
|---|---|---|
| `hs.pasteboard.readAllData([name])` | returns `table` of `{UTI = data}` | Reads all values from the first pasteboard item as a UTI-to-raw-data map. Use to **save** the prior clipboard. |
| `hs.pasteboard.writeAllData([name], table)` | returns `boolean` | Writes a complete UTI-to-data mapping in one operation. Use to **restore** the prior clipboard, OR to **set** the transcript with the transient UTI marker simultaneously. |
| `hs.pasteboard.setContents(text)` | returns `boolean` | Single-string convenience write. Doesn't accept multi-type — use `writeAllData` instead when you need the transient marker. |

### Recommended pattern — atomic transient write

```lua
-- In the hs.task onExit callback for exit code 0 (success):
local transcript = stdOut or ""

-- 1. SAVE prior clipboard contents (all UTIs) — restore-target.
local savedClipboard = hs.pasteboard.readAllData()

-- 2. WRITE transcript + transient marker atomically.
--    Per nspasteboard.org: the empty-string for the transient UTI is sufficient
--    (the marker's PRESENCE is the signal; the marker's VALUE is irrelevant).
--    Pasteboard managers that honour the spec (Maccy default-on, 1Password, Raycast)
--    skip recording entries containing this UTI.
hs.pasteboard.writeAllData({
  ["public.utf8-plain-text"] = transcript,
  ["org.nspasteboard.TransientType"] = "",
  ["org.nspasteboard.ConcealedType"] = "",  -- belt + braces
})

-- 3. PASTE — synthesise cmd+v into the focused app.
hs.eventtap.keyStroke({"cmd"}, "v", 0)

-- 4. RESTORE prior clipboard after 250 ms — but ONLY if the clipboard still
--    contains our transcript (defends against the user copying something else
--    in the interim, which would otherwise be clobbered).
hs.timer.doAfter(0.25, function()
  local current = hs.pasteboard.readAllData()
  -- Compare on the text field; if user copied something else, leave it alone.
  if current and current["public.utf8-plain-text"] == transcript then
    hs.pasteboard.writeAllData(savedClipboard)
  end
end)
```

### UTI specifics — VERIFIED from nspasteboard.org

| UTI | Purpose | Honoured by (verified) |
|---|---|---|
| `org.nspasteboard.TransientType` | "Content will be on pasteboard only momentarily; pasteboard managers should not record." | **Maccy** (default on — verified in Maccy README), **1Password 8** (verified per [1Password/arboard](https://github.com/1Password/arboard)), Alfred, CopyPaste Pro, iClip, Keyboard Maestro, Paste, TextExpander, Typinator |
| `org.nspasteboard.ConcealedType` | "Sensitive content (passwords); managers should redact or skip." | Same set (per nspasteboard.org and Maccy README) |
| `org.nspasteboard.AutoGeneratedType` | "Generated by software, not user-initiated." | Same set |

**Note on Raycast:** Web research could not confirm Raycast Clipboard History honours these markers explicitly (their docs don't mention nspasteboard.org). However, **including the marker is harmless** — at worst Raycast records the transcript like it would without it; at best Raycast does honour the spec (it implements many macOS conventions). Document this in README as a known residual risk.

### Why 250 ms?

- ARCHITECTURE.md and PITFALLS.md (Pitfall 8) both recommend 250–300 ms based on empirical timing of `cmd+v` propagation through macOS event queue + the receiving app's event loop.
- Faster (< 200 ms) → race risk: receiving app reads clipboard AFTER restore, gets the wrong content.
- Slower (> 500 ms) → user-perceptible "stale clipboard" window.
- **Recommendation: 250 ms** (matches ROADMAP success criterion #4 verbatim: "within ~250 ms"). The `hs.timer.doAfter(0.25, ...)` is exactly this.

### Empty / whitespace transcript handling (INJ-04)

INJ-04 ("Empty or whitespace-only transcripts are silently discarded — no paste, no error toast") is largely covered in the **bash glue** by exit 3 (§3). However, defence-in-depth in Lua:

```lua
-- After reading transcript from stdOut:
if not transcript or transcript:match("^%s*$") then
  currentTask = nil
  return  -- silent: no paste, no toast
end
```

This catches the edge case where bash returned exit 0 but the transcript is somehow empty (shouldn't happen if §3 is implemented correctly, but cheap insurance).

### Validation

- **Manual:** `cmd+c` to copy "ORIGINAL", trigger voice-cc, dictate "test transcript". Within ~250 ms after paste, `cmd+v` again into a different field — should paste "ORIGINAL", not "test transcript". (Pitfall 8 verification.)
- **Manual:** With Maccy installed, dictate 5 phrases. Open Maccy. Expect: ZERO of the 5 transcripts appear in Maccy history.
- **Manual:** Same with 1Password 8 "Recently copied" and Raycast Clipboard History (Raycast may show them — document as expected).
- **Lua test (synthetic):** unit test would require Hammerspoon running; defer to manual walkthrough as the canonical verification.

### Sources
- [Hammerspoon hs.pasteboard source](https://github.com/Hammerspoon/hammerspoon/blob/master/extensions/pasteboard/pasteboard.lua) — HIGH (canonical API).
- [Hammerspoon docs hs.pasteboard.html](https://www.hammerspoon.org/docs/hs.pasteboard.html) — HIGH (official).
- [nspasteboard.org spec](http://nspasteboard.org/) — HIGH (canonical spec).
- [Maccy README](https://github.com/p0deje/Maccy) — HIGH (explicit default support for TransientType, ConcealedType, AutoGeneratedType).
- [1Password/arboard repo](https://github.com/1Password/arboard) — HIGH (1Password's published clipboard library that uses these UTIs).

---

## 6. Re-entrancy Guard (ROB-01, Success Criterion #5)

**Goal:** Rapid double-presses don't spawn duplicate sox processes. Ignore the second press while the first is in flight.

### Decision: ignore-second-press, NOT cancel-and-restart

ROADMAP success criterion #5 says "rapid double-presses do not spawn duplicate sox processes." The simplest interpretation is **ignore the second press** while a recording is in flight. Not "cancel the first and start a new one" — that introduces audio-loss risk for the user who genuinely meant the longer hold.

The Phase 1 module already has the minimum-viable mutex (`if currentTask and currentTask:isRunning() then return end`). Phase 2 must add:
1. An explicit `isRecording` boolean (clearer intent than `currentTask:isRunning()`).
2. A guard on `onRelease` too — if `isRecording` is false, ignore (handles ghost releases after a press was rejected).
3. Reset of `isRecording = false` in **every** exit path of the callback (success, exit 2, exit 3, exit 10/11/12, error). Wrapped in `pcall` so an exception in the post-paste code still resets state.

### Implementation pattern

```lua
-- Module-level state:
local isRecording = false
local currentTask = nil
local savedClipboard = nil

local function resetState()
  isRecording = false
  currentTask = nil
  savedClipboard = nil
end

local function onPress()
  if isRecording then
    -- Already recording; drop this press silently.
    return
  end
  isRecording = true
  setMenubarRecording()  -- §7
  playStartCue()          -- §8

  currentTask = hs.task.new(SCRIPT_PATH, function(exitCode, stdOut, stdErr)
    -- Wrap the dispatch in pcall so an exception still calls resetState().
    local ok, err = pcall(function()
      handleExit(exitCode, stdOut or "", stdErr or "")
    end)
    if not ok then
      hs.console.printStyledtext("voice-cc onExit error: " .. tostring(err))
    end
    setMenubarIdle()      -- §7 — always reset menubar
    resetState()           -- always reset state
  end)

  if currentTask == nil then
    hs.alert.show("voice-cc: script not found at " .. SCRIPT_PATH, 4)
    setMenubarIdle()
    resetState()
    return
  end
  currentTask:start()
end

local function onRelease()
  if not isRecording or not currentTask then
    return  -- ignore ghost release
  end
  playStopCue()           -- §8
  if currentTask:isRunning() then
    currentTask:terminate()  -- sends SIGTERM; bash trap forwards to sox
  end
end
```

### Why no `flock` lockfile (per PITFALLS Pitfall 6 option 4)?

PITFALLS suggests an optional `flock` defensive lock in bash. **Not needed for v1** because:
1. The Lua re-entrancy guard above is the source of truth.
2. A second instance of voice-cc-record can only be spawned if the user manually invokes it from a terminal while Hammerspoon also has one in flight — a deliberate stress test, not a real failure mode.
3. If the user really runs concurrently from terminal, both will write to the same WAV, one will overwrite the other, neither hurts the other process — no system damage.

Defer the lockfile to Phase 4 if real-world failure surfaces it.

### Validation

- **Unit/Lua test (manual):** rapidly tap the hotkey 10 times within 1 second; observe via `pgrep -fa sox` — expect at most one sox process at any time.
- **Manual walkthrough:** matches Phase 2 success criterion #5 — "rapid double-presses do not spawn duplicate sox processes."

### Sources
- PITFALLS.md Pitfall 6 — re-entrancy guard pattern.
- ARCHITECTURE.md Anti-Pattern 6 — no PID files / lockfiles in normal flow.

---

## 7. Menu-bar Indicator (FBK-01, Success Criterion #5)

**Goal:** Holding the hotkey shows a visible menu-bar indicator change. (No PNG icon — that's Phase 2.5 Branding.)

### `hs.menubar` API — verified

| Method | Signature | Notes |
|---|---|---|
| `hs.menubar.new([inMenuBar], [autosaveName])` | returns `menubaritem` or `nil` | Creates menubar item. `inMenuBar=true` (default) places it in the right-side menubar; `false` keeps it hidden until shown explicitly. |
| `:setTitle(title)` | accepts string, `hs.styledtext`, or nil | Updates displayed text. **Cheap to call** — no observed performance warnings in upstream docs. |
| `:setIcon(imageData[, template])` | accepts `hs.image` object, file path, ASCII diagram, or nil | For Phase 2 we don't use this (unicode glyph in `setTitle` is sufficient). |
| `:delete()` | — | Removes from menubar. Phase 2 keeps the menubar item alive for the entire Hammerspoon session — never delete. |

### Recommendation: unicode glyph in `setTitle`, idle-state visible

**Why visible in idle:** Per FBK-01, the indicator "changes colour while recording is active." The user must be able to see the indicator change — implies there must be SOMETHING in the menubar even when idle, so the change is visible. (If we showed-only-on-press, the user would see "appear → disappear" which is less informative than "grey → red".)

**Glyph choice:**
- Idle: `●` (U+25CF Black Circle) — neutral, small, visually quiet.
- Recording: `●` styled red via `hs.styledtext` (or use a different glyph like `🔴` for visual punch).

**Recommendation: use `hs.styledtext` for colour control on the same `●` glyph.** Avoids emoji rendering inconsistency across macOS minor versions and keeps the visual size constant.

```lua
-- Module init (one time, persistent):
local menubar = hs.menubar.new()
local idleTitle = hs.styledtext.new("●", { color = { hex = "#888888" } })  -- grey
local recordingTitle = hs.styledtext.new("●", { color = { hex = "#FF3B30" } })  -- macOS system red

local function setMenubarIdle()
  if menubar then menubar:setTitle(idleTitle) end
end

local function setMenubarRecording()
  if menubar then menubar:setTitle(recordingTitle) end
end

-- At end of module init:
setMenubarIdle()
```

`hs.styledtext.new(string, table)` accepts a colour spec via `{ color = { hex = "#FF3B30" } }` (verified in [hs.styledtext docs](https://www.hammerspoon.org/docs/hs.styledtext.html)).

### Performance

- `setTitle` is called twice per utterance (recording start + recording end). Two calls per ~5 s loop is negligible.
- The menubar item is created once at module init; never re-created.
- No observable CPU cost at idle.

### Validation

- **Manual walkthrough:** Hammerspoon menubar shows `●` (grey). Hold hotkey — menubar `●` turns red. Release hotkey — menubar `●` returns to grey within a few hundred ms.

### Sources
- [Hammerspoon hs.menubar docs](https://www.hammerspoon.org/docs/hs.menubar.html) — HIGH.
- [Hammerspoon hs.styledtext docs](https://www.hammerspoon.org/docs/hs.styledtext.html) — HIGH.

---

## 8. Audio Cues (FBK-02, Success Criterion #5)

**Goal:** Brief start/stop sounds; default-on; suppressed when `VOICE_CC_NO_SOUNDS=1` is set.

### `hs.sound` API — verified

| Method | Signature | Notes |
|---|---|---|
| `hs.sound.getByFile(path)` | returns `sound` or `nil` | Loads from absolute path. |
| `hs.sound.getByName(name)` | returns `sound` or `nil` | Loads system sounds by name (filename without extension) from `~/Library/Sounds`, `/Library/Sounds`, `/Network/Library/Sounds`, `/System/Library/Sounds`. |
| `hs.sound.systemSounds()` | returns table of names | Lists all available system sounds. |
| `:play()` | returns `sound` | Plays the sound async (non-blocking). |
| `:volume([level])` | accepts 0.0–1.0 | Relative to system volume. |
| `:name(name)` | sets a name | After loading via getByFile, `:name("foo")` registers it for getByName. |

### Built-in macOS system sounds — verified live on Sequoia 15.7.5

`ls /System/Library/Sounds/` on the target machine returns:
```
Basso.aiff  Blow.aiff  Bottle.aiff  Frog.aiff  Funk.aiff  Glass.aiff
Hero.aiff   Morse.aiff  Ping.aiff   Pop.aiff   Purr.aiff  Sosumi.aiff
Submarine.aiff  Tink.aiff
```

**Recommendation:**
- **Start:** `Pop.aiff` — short, non-intrusive, suggests "begin."
- **Stop:** `Tink.aiff` — distinct from Pop, very short, suggests "completed."

Both are < 200 ms, system-resident (no I/O cost after first load), and respect the user's volume preferences.

### Pre-load at module init for low-latency playback

```lua
-- Module init:
local startSound = hs.sound.getByName("Pop")   -- system sound; returns nil on sound not found
local stopSound = hs.sound.getByName("Tink")
local soundsEnabled = (os.getenv("VOICE_CC_NO_SOUNDS") ~= "1")

local function playStartCue()
  if soundsEnabled and startSound then
    startSound:volume(0.3):play()
  end
end

local function playStopCue()
  if soundsEnabled and stopSound then
    stopSound:volume(0.3):play()
  end
end
```

### Where the `VOICE_CC_NO_SOUNDS` env var is read

**Recommendation: read it ONCE at Lua module load time, not in bash.** Reasons:
1. Phase 2 audio cues are Lua-side (Hammerspoon plays them via hs.sound). Bash has no audio-cue feature in Phase 2 — sox itself doesn't beep.
2. Reading once at module load is simpler than re-reading per press. If user changes the env var, they reload Hammerspoon — that's the documented config-change procedure anyway.
3. Hammerspoon inherits its environment from launchd at GUI launch time, so `VOICE_CC_NO_SOUNDS=1` set in `~/.zshenv` or via `launchctl setenv VOICE_CC_NO_SOUNDS 1` will be visible to `os.getenv`.

**Note for the planner:** if the user wants `VOICE_CC_NO_SOUNDS` to also affect the bash side later (e.g., if Phase 4 adds bash-side audible warnings for long-hold), the gate can be added in bash too — but it has no effect in Phase 2.

### Audio cue at 100 ms accidental tap — does the press cue fire?

Per ROADMAP success criterion #1 + #5: a 100 ms tap "produces no paste and no error" but #5 says "Holding the hotkey shows a visible menu-bar indicator change and ... plays brief start/stop audio cues." There's a mild tension: if `playStartCue` fires on press for any press (including a 100 ms tap), the user gets a Pop sound then a Tink sound for an accidental tap.

**Resolution:** Either acceptable. Spec doesn't say "audio cues must not fire on aborted recordings." The 100 ms tap criterion is specifically about "no paste and no error" — sound cues are neither. **Recommendation: let cues fire on press/release regardless** — they're brief, system sounds, and tell the user "yes, I registered your hotkey press" which is itself useful feedback (pressing a hotkey and getting nothing is its own confusion mode). Accept the tiny audible aftermath of a real accidental tap.

### Validation

- **Manual:** Hold hotkey briefly; expect Pop (start) then Tink (stop).
- **Manual:** `launchctl setenv VOICE_CC_NO_SOUNDS 1; killall Hammerspoon; open -a Hammerspoon`; press hotkey; expect silence (no Pop, no Tink).

### Sources
- [Hammerspoon hs.sound docs](https://www.hammerspoon.org/docs/hs.sound.html) — HIGH.
- Live `ls /System/Library/Sounds/` on Oliver's Sequoia 15.7.5 machine — HIGH.

---

## 9. Failure Notifications (FBK-03)

**Goal:** When the system fails (mic permission denied, model file missing, binary not found), user receives an actionable macOS notification with a clear next step or deep link to System Settings — never silent failure.

### `hs.notify` API — verified

| Property | Type | Default | Notes |
|---|---|---|---|
| `title` | string | required | Bold notification title |
| `subTitle` | string | nil | Smaller subtitle text |
| `informativeText` | string | nil | Body text |
| `actionButtonTitle` | string | "Show" | Text of the action button |
| `hasActionButton` | boolean | true (when actionButtonTitle set) | Show the action button |
| `autoWithdraw` | boolean | true | Auto-dismiss after `withdrawAfter` seconds |
| `withdrawAfter` | number | 5 | Seconds before auto-dismiss; **0 = persist forever** |
| `soundName` | string | nil | Optional sound name (use `hs.sound.systemSounds()` for valid names) |

**CRITICAL CAVEAT:** Per the Hammerspoon docs, `actionButtonTitle` and `hasActionButton` only have a visible effect when **the user has set Hammerspoon's notification style to "Alert"** in System Settings → Notifications → Hammerspoon. Banner-style notifications ignore these settings. **This must be documented in the README** and surfaced to the user during install (Phase 3, but flagged here so it's not forgotten).

If notification style is "Banner," the notification still appears with title and body — just no action button. The user can still click the notification body to trigger the callback. **So the implementation works in both modes; only the "Open Settings" button is invisible in Banner mode.**

### Pattern: registered callback (survives reload)

```lua
-- Register callbacks at module init (so they survive Hammerspoon reloads).
hs.notify.register("voiceccOpenMicSettings", function(notification)
  hs.urlevent.openURL("x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Microphone")
end)

hs.notify.register("voiceccOpenAccessibilitySettings", function(notification)
  hs.urlevent.openURL("x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility")
end)

-- Use the registered callback by tag:
local function notifyTccDenied()
  hs.notify.new("voiceccOpenMicSettings", {
    title = "voice-cc: microphone blocked",
    informativeText = "Grant Hammerspoon access in Privacy & Security",
    actionButtonTitle = "Open Settings",
    hasActionButton = true,
    autoWithdraw = false,
    withdrawAfter = 0,
  }):send()
end
```

The `hs.notify.register(tag, fn)` pattern avoids the "callback was lost on reload" problem documented in [Hammerspoon issue #1414](https://github.com/Hammerspoon/hammerspoon/issues/1414).

### Notification de-dup / spam control

**Concern:** if the user holds the hotkey 5 times in 30 seconds while Microphone is denied, we'd send 5 toasts — annoying.

**Recommendation:** track the last-notify timestamp per error type; suppress duplicates within 60 s. Simple module-level dict.

```lua
local lastNotifyAt = {}  -- exit_code -> timestamp
local NOTIFY_COOLDOWN_S = 60

local function notifyOnce(exitCode, factory)
  local now = hs.timer.absoluteTime() / 1e9
  local last = lastNotifyAt[exitCode] or 0
  if (now - last) < NOTIFY_COOLDOWN_S then
    return  -- recently notified; suppress
  end
  lastNotifyAt[exitCode] = now
  factory()
end

-- Usage:
if exitCode == 10 then
  notifyOnce(10, notifyTccDenied)
end
```

### Validation

- **Live:** trigger TCC denial (see §4 Validation); expect ONE notification, click "Open Settings" → System Settings opens.
- **Live:** trigger TCC denial again within 60 s; expect NO new notification.
- **Live:** wait 60+ s; trigger again; expect new notification.

### Sources
- [Hammerspoon hs.notify docs](https://www.hammerspoon.org/docs/hs.notify.html) — HIGH.
- [Hammerspoon hs.notify issue #1414 — callback persistence](https://github.com/Hammerspoon/hammerspoon/issues/1414) — HIGH.
- [Hammerspoon hs.urlevent docs](https://www.hammerspoon.org/docs/hs.urlevent.html) — HIGH.

---

## 10. WAV Leak Prevention + Whisper Sibling .txt Suppression (ROB-04, Success Criterion #5, Phase-1 TODO c)

**Goal:** No WAV files accumulate in `/tmp/voice-cc/` across exit paths including SIGINT. No `.txt` files left by whisper-cli either.

### Three sources of /tmp leaks in Phase 1

1. **The recording.wav itself** — never deleted in Phase 1 (left behind after every successful run).
2. **The recording.txt** — written by whisper-cli's `-otxt -of` flags; never deleted in Phase 1 (Phase-1 TODO c).
3. **Future: sox.stderr** — once §4 is implemented, the captured sox stderr log also needs cleanup.

### Solution: EXIT trap covering all paths

```bash
# At top of voice-cc-record (after defining paths, BEFORE the WAV is created):
WAV_DIR="/tmp/voice-cc"
WAV="$WAV_DIR/recording.wav"
SOX_ERR_LOG="$WAV_DIR/sox.stderr"

mkdir -p "$WAV_DIR"

# Sweep stale files from previous failed runs (>5 min old):
find "$WAV_DIR" -name "*.wav" -mmin +5 -delete 2>/dev/null
find "$WAV_DIR" -name "*.txt" -mmin +5 -delete 2>/dev/null
find "$WAV_DIR" -name "sox.stderr" -mmin +5 -delete 2>/dev/null

# EXIT trap covers ALL exit paths: success, exit 2/3/10/11/12, errors, SIGINT, SIGTERM.
# Bash's EXIT trap fires on every exit including signals (after the signal-specific
# trap runs). This is the canonical "always cleanup" pattern.
trap 'rm -f "$WAV" "$SOX_ERR_LOG"' EXIT
```

**Why `EXIT` not `SIGTERM` alone:** `SIGTERM` is the signal Hammerspoon sends on `task:terminate()`. The current Phase 1 trap is on `TERM INT` only — it forwards the signal to sox but doesn't clean up. The `EXIT` trap fires regardless of how the script ended (normal exit, killed, panic). It's the correct hook for cleanup.

**Note on signal handling:** The Phase 1 `trap 'kill -TERM "$SOX_PID" 2>/dev/null || true' TERM INT` is correct for **forwarding** signals to sox (so sox finalises its WAV cleanly). Phase 2 ADDs the `EXIT` trap on top; the two traps coexist. Order:
```bash
trap 'rm -f "$WAV" "$SOX_ERR_LOG"' EXIT
trap 'kill -TERM "$SOX_PID" 2>/dev/null || true' TERM INT
# ... later, after wait completes:
trap - TERM INT  # clear the signal-forward trap (EXIT trap stays armed)
```

### Suppress whisper-cli sibling .txt — the actual root cause

Looking at the current Phase 1 transcribe() (line 41-48 of voice-cc-record):
```bash
"$WHISPER_BIN" \
  -m "$MODEL" \
  --language en \
  --no-timestamps \
  --prompt "$VOCAB" \
  -otxt -of "$out_base" \
  -f "$wav_path" >/dev/null 2>&1
cat "${out_base}.txt"
```

The `-otxt -of "$out_base"` flag pair tells whisper-cli to write the transcript to `<out_base>.txt`, which is then `cat`-ed to stdout. **The .txt file is created on purpose then never deleted.**

**Two valid fixes:**

**Option A (RECOMMENDED): remove `-otxt -of`, capture stdout directly.**

```bash
# whisper-cli prints the transcript to stdout by default when no -o* flags are passed.
# Combine with --no-prints to suppress the metadata noise (model load, timing).
"$WHISPER_BIN" \
  -m "$MODEL" \
  --language en \
  --no-timestamps \
  --no-prints \
  --vad --vad-model "$SILERO_MODEL" --vad-threshold 0.50 \
  --suppress-nst \
  --prompt "$VOCAB" \
  -f "$wav_path" 2>/dev/null
```

Pros: zero .txt file ever created; simpler; one less trap path. Verified that `whisper-cli`'s default behavior is to emit transcript to stdout. The `--no-prints` flag (present per `whisper-cli --help`) suppresses non-transcript output.

**Option B: keep `-otxt -of`, add the .txt to the EXIT trap.**

```bash
trap 'rm -f "$WAV" "$SOX_ERR_LOG" "${WAV%.wav}.txt"' EXIT
```

Works but more fragile — relies on path conventions and the EXIT trap firing.

**Recommendation: Option A.** Cleaner, faster, no relevant downside. The transcript-via-stdout path is also more idiomatic for the Pattern 2 boundary (transcribe() returns its result on stdout — if whisper-cli already does that natively, don't add file I/O between).

### Validation

- **Unit test:** `tests/test_wav_cleanup.sh` — invoke voice-cc-record with a pre-recorded WAV, observe `/tmp/voice-cc/` contents during execution and after; assert post-run is empty.
- **Signal test:** `tests/test_sigint_cleanup.sh` — start voice-cc-record in background, send SIGINT after 0.5 s, assert `/tmp/voice-cc/` is empty.
- **Manual:** run voice-cc 100 times via the hotkey, then `ls /tmp/voice-cc/` — expect empty (or at most one in-flight WAV).

### Sources
- PITFALLS.md Pitfall 10 — disk leak prevention.
- Phase 1 SUMMARY 01-03 "Quirks Discovered" #4 — sibling .txt observation.
- Live `whisper-cli --help` (captured 2026-04-27) — confirms `--no-prints` flag exists.

---

## 11. Hammerspoon Accessibility Prompt Determinism (Phase-1 TODO a)

**Goal:** Resolve the Phase 1 walkthrough's only first-run silent failure mode: `hs.eventtap.keyStroke` silently no-ops if Accessibility hasn't been granted. Force the prompt to surface deterministically on module load.

### `hs.accessibilityState(shouldPrompt) -> isEnabled` — VERIFIED

From [Hammerspoon docs](https://www.hammerspoon.org/docs/hs.html):

> `shouldPrompt` — an optional boolean value indicating if the dialog box asking if the System Preferences application should be opened should be presented when Accessibility is not currently enabled.

Returns `true` if Accessibility is currently enabled for Hammerspoon, `false` otherwise.

**Honest caveat:** The official doc says the prompt "may be presented" — it is not guaranteed to fire 100% deterministically on every macOS version. In practice, it's the standard incantation that Hammerspoon-using projects use to surface the Accessibility prompt. The fallback on first install is the user's existing manual procedure (which is what they did during the Phase 1 walkthrough). With this call in place, the EXPECTED first-run experience is:
1. User installs voice-cc, runs setup.sh, adds `require("voice-cc")` to `~/.hammerspoon/init.lua`, launches Hammerspoon.
2. Module loads → `hs.accessibilityState(true)` runs → macOS dialog appears: "Hammerspoon would like to control this computer using accessibility features." → user clicks "Open System Settings."
3. (If not, the next press would still surface a "Microphone blocked" toast via §4 only after sox runs; but Accessibility itself is silent without the proactive call.)

### Implementation

```lua
-- At top of voice-cc-lua/init.lua, before any hotkey binding:
hs.accessibilityState(true)
```

One line. Idempotent on every Hammerspoon reload (no side effect if already granted; surfaces prompt if not).

**Optional defence-in-depth:** also surface a notification if Accessibility is still not granted after the prompt (user might have clicked "Don't Allow"):

```lua
local accessibilityOk = hs.accessibilityState(true)
if not accessibilityOk then
  hs.notify.new("voiceccOpenAccessibilitySettings", {
    title = "voice-cc: accessibility required",
    informativeText = "Grant Hammerspoon access in Privacy & Security → Accessibility",
    actionButtonTitle = "Open Settings",
    hasActionButton = true,
    autoWithdraw = false,
  }):send()
end
```

### Validation

- **Live:** `tccutil reset Accessibility org.hammerspoon.Hammerspoon`; reload Hammerspoon (`hs -c "hs.reload()"` once §12 is in); expect: prompt appears, OR if user dismisses prompt without granting, expect notification with "Open Settings" button.

### Sources
- [Hammerspoon hs.accessibilityState docs](https://www.hammerspoon.org/docs/hs.html#accessibilityState) — HIGH.
- Phase 1 SUMMARY 01-03 "Quirks Discovered" #1 — empirical observation.

---

## 12. hs.ipc CLI Enablement (Phase-1 TODO b)

**Goal:** Enable the `hs` CLI tool installed by the brew cask so scripted reloads work (`hs -c "hs.reload()"`). Phase 1 walkthrough confirmed it errors with "can't access Hammerspoon message port" without `require("hs.ipc")`.

### What it enables — verified

Per [Hammerspoon hs.ipc docs](https://www.hammerspoon.org/docs/hs.ipc.html): loading `hs.ipc` "provides the ability to create both local and remote message ports for inter-process communication." Most importantly: it enables the `hs` CLI tool functionality at `/opt/homebrew/bin/hs` (installed by the brew cask).

**TCC requirement:** None. `hs.ipc` opens a Mach message port within the Hammerspoon process; no system-protected resources accessed. Documented as "recommended" with no warnings about side effects.

**Side effects of adding `require("hs.ipc")` to `~/.hammerspoon/init.lua`:**
- One Mach message port created at Hammerspoon launch.
- The `hs` CLI tool starts working: `echo 'print("hello")' | /opt/homebrew/bin/hs`, `/opt/homebrew/bin/hs -c "hs.reload()"`.
- No additional permission prompts.
- No measurable startup overhead.

### Implementation

**File:** `~/.hammerspoon/init.lua` (NOT the voice-cc Lua module).

```lua
-- ~/.hammerspoon/init.lua — current Phase 1 contents:
-- Top-level Hammerspoon config (created by voice-cc Phase 1 spike).
-- Add other modules below as you adopt them.
require("voice-cc")

-- Phase 2 addition (one line):
require("hs.ipc")
```

**Where it lives:** `~/.hammerspoon/init.lua` is the user's top-level Hammerspoon config. Phase 1 honoured D-02 (don't overwrite a non-empty existing init.lua) — the file the executor wrote is in voice-cc's authority because it didn't exist before Phase 1.

**For Phase 2:** the planner has two options:
- **Option A (RECOMMENDED):** add `require("hs.ipc")` directly to `~/.hammerspoon/init.lua`. Honest because it lives in the user's config dir; users who adopt voice-cc are encouraged to scripts-reload during dev work. Adds one line. Idempotent.
- **Option B:** put `require("hs.ipc")` inside `voice-cc-lua/init.lua` (so it auto-loads as part of the module). Slightly intrusive — voice-cc owns a module-loading concern that arguably belongs to the user's top-level config. **Acceptable but Option A is cleaner.**

**Recommendation: Option A.** Plan 02-02 should include a task to write the additional line to `~/.hammerspoon/init.lua`, idempotently (check for "hs.ipc" before appending).

### Validation

- **CLI test:** `hs -c "1 + 1"` should print `2`.
- **Reload test:** `hs -c "hs.reload()"` should reload the config without error.
- **Unit test:** `grep -q 'require("hs.ipc")' ~/.hammerspoon/init.lua` should return 0.

### Sources
- [Hammerspoon hs.ipc docs](https://www.hammerspoon.org/docs/hs.ipc.html) — HIGH.
- Phase 1 SUMMARY 01-03 "Quirks Discovered" #2 + #3 — empirical observation.
- Live `/opt/homebrew/bin/hs` exists and is wired up by Homebrew per Phase 1 install — verified by environment audit.

---

## 13. Cross-cutting Concerns

### Pattern 2 Boundary Discipline (CRITICAL)

The Phase 1 grep test (`grep -c WHISPER_BIN voice-cc-record == 2` → one assignment, one use inside transcribe()) MUST remain green after Phase 2. The new VAD invocation goes inside the existing `transcribe()` body. The new denylist filter, duration gate, TCC stderr grep, and EXIT trap all run OUTSIDE transcribe() — none of them invoke whisper-cli.

**Verification command for plan automated checks:**
```bash
[ "$(grep -c WHISPER_BIN voice-cc-record)" -eq 2 ] && echo "OK: Pattern 2 preserved" || echo "FAIL: extra WHISPER_BIN reference"
```

### Exit Code Allocation (locked from ARCHITECTURE.md)

Phase 2 must implement these semantically:

| Exit code | Meaning | Lua action |
|---|---|---|
| 0 | Success — transcript on stdout | Paste path (preserve clipboard, set with transient UTI, cmd+v, restore after 250ms) |
| 2 | Silent abort: clip too short (< 0.4 s) | No-op — reset menubar to idle |
| 3 | Silent abort: empty/whitespace transcript OR denylist match | No-op — reset menubar to idle |
| 10 | Mic permission denied (sox stderr matched TCC pattern) | hs.notify "Microphone blocked" + Open Settings deep link |
| 11 | Model file or binary missing | hs.notify "Install incomplete — run setup.sh" |
| 12 | sox/whisper-cli generic failure | hs.notify "Transcription failed" |

### File Layout (no Phase 2 changes)

Phase 2 doesn't add any new top-level paths. It uses existing XDG locations:
- `~/.config/voice-cc/denylist.txt` — new (denylist)
- `~/.local/share/voice-cc/models/ggml-silero-v6.2.0.bin` — new (Silero VAD weights, 885 KB)
- `/tmp/voice-cc/sox.stderr` — new transient (per-invocation, EXIT-trap cleaned)

### Unicode-on-the-wire

`printf "%s"` in bash preserves bytes verbatim — no encoding issues with Whisper's UTF-8 output (smart quotes, em-dashes, etc.). Already verified in Phase 1.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Voice activity detection | Custom amplitude-based silence trim in sox | `whisper-cli --vad --vad-model ggml-silero-v6.2.0.bin` | Silero is purpose-built, 95%+ accurate; whisper.cpp integrates it natively; sox amplitude is fooled by background hum |
| Hallucination filter | ML-based confidence scoring on transcripts | Hardcoded denylist of known phrases (community-curated) | Known hallucinations are a small finite set; substring filtering is cheap and predictable; "smart" filters reject real prompts |
| Clipboard manager skip mechanism | App-by-app shimming (1Password API, Maccy API, etc.) | `org.nspasteboard.TransientType` UTI marker | Universal protocol; honoured by all major managers; one line of Lua via `writeAllData` |
| TCC permission state checks | `sqlite3 TCC.db` queries | Detect failure post-facto via sox stderr fingerprint | Querying TCC.db requires Full Disk Access for the system DB; user-local DB is queryable but parsing it adds complexity for no real win over the failure-fingerprint approach |
| System Settings deep links | Hand-rolled AppleScript chains to navigate | `hs.urlevent.openURL("x-apple.systempreferences:...")` | Single line; Apple's documented URL scheme is the supported path |
| Re-entrancy mutex | `flock` on a /tmp lockfile | In-memory Lua boolean (`isRecording`) | Single Hammerspoon process; one source of truth; no lockfile-stale-after-crash recovery needed |
| Audio cues | Custom WAV files shipped with the project | macOS system sounds via `hs.sound.getByName("Pop")` | System sounds respect user volume preferences; zero install overhead; consistent macOS feel |
| WAV cleanup | Periodic cron to sweep /tmp | Bash EXIT trap covering all exit paths + per-startup sweep of stale files | EXIT trap fires on every exit including signals; nothing to schedule, nothing to forget |
| Notification de-dup | Some external rate limiter | Module-level `lastNotifyAt` dict + 60s cooldown | Trivial; lives in the same Lua process as the notifications |

**Key insight:** Every Phase 2 hardening item has a battle-tested upstream solution. The instinct to roll custom (especially for VAD and clipboard-manager skipping) is wrong — both have universal upstream conventions that Just Work.

---

## Common Pitfalls (Phase 2-Specific)

These are pitfalls SPECIFIC to the Phase 2 implementation work, beyond the canonical 10 in PITFALLS.md.

### Pitfall A: Adding VAD without the Silero model file (silent no-op)

**What goes wrong:** `--vad` flag is passed but `--vad-model` is empty (or points to a missing file). VAD silently does nothing; whisper still hallucinates on silence.
**How to avoid:** setup.sh additions for Phase 2 must (a) download the Silero model with size verification, (b) bash glue must verify the model file exists at script start (exit 11 if not), (c) pass `--vad-model "$SILERO_MODEL"` explicitly, never rely on a default.
**Warning sign:** silence still produces "thank you" transcripts despite `--vad` being in the command line.

### Pitfall B: Denylist substring-matching by accident

**What goes wrong:** Implementing `grep -i "$TRANSCRIPT" "$DENYLIST"` instead of an exact-match comparison. A real prompt "thanks for adding dark mode" matches "thanks" in the denylist and gets silently dropped.
**How to avoid:** The canonicalisation pattern in §3 (`tr -d '[:space:]' | tr '[:upper:]' '[:lower:]'` on both sides, then `[ "$a" = "$b" ]`) is exact-match by construction. Code-review for any `grep -F` or `grep -i` against the denylist that doesn't anchor with `-x` (full-line match).
**Warning sign:** legitimate prompts vanish.

### Pitfall C: Clipboard restore races the receiving app

**What goes wrong:** Restoring at < 200 ms; some apps (Microsoft Word, MS Teams, slow Electron apps) don't process cmd+v that fast and end up reading the restored prior clipboard.
**How to avoid:** Use 250 ms (matches success criterion). Add the `getContents() == transcript` content-equality guard before restoring (defends against the user copying something else mid-flight).
**Warning sign:** "sometimes the wrong text appears" — specifically the prior clipboard's content. PITFALLS Pitfall 8.

### Pitfall D: Notification spam on repeated failures

**What goes wrong:** User holds hotkey 5 times in 10 seconds while mic is denied; gets 5 notifications.
**How to avoid:** §9's `notifyOnce` cooldown pattern.
**Warning sign:** notification list scrolling.

### Pitfall E: hs.notify action button invisible in Banner mode

**What goes wrong:** User has Hammerspoon notifications set to "Banner" (the macOS default). `actionButtonTitle = "Open Settings"` is invisible; user can't see the action button. Notification still works but loses the affordance.
**How to avoid:** README must instruct: System Settings → Notifications → Hammerspoon → switch to "Alerts." Phase 3 install-time prompt should also mention. Phase 2 itself can't enforce this — but the notification BODY must be informative enough to be useful even without the button. (Recommendation: include "Open System Settings → Privacy → Microphone" in `informativeText`, not just in the action button.)
**Warning sign:** user reports "I see the notification but no button to click."

### Pitfall F: EXIT trap not firing on SIGKILL

**What goes wrong:** `kill -9 $PID` doesn't fire any traps. WAV remains.
**How to avoid:** Cannot be prevented for SIGKILL specifically — that's the design. Mitigated by the per-startup sweep of stale files (`find /tmp/voice-cc -mmin +5 -delete` at script top).
**Warning sign:** WAV files older than 5 minutes in /tmp/voice-cc/.

### Pitfall G: VAD threshold too aggressive — drops real speech

**What goes wrong:** `--vad-threshold 0.80` drops quiet speech (ASMR voices, reluctant whispers). Real prompts vanish.
**How to avoid:** Default to 0.50 (whisper-cli's own default). Expose `VOICE_CC_VAD_THRESHOLD` env var for tuning. Don't tune without evidence.
**Warning sign:** legitimate transcripts go missing on quiet speakers.

### Pitfall H: Adding `require("hs.ipc")` to voice-cc-lua/init.lua instead of ~/.hammerspoon/init.lua

**What goes wrong:** Confused about which init.lua to modify. Putting `require("hs.ipc")` inside the voice-cc module works (Lua require is global) but blurs the boundary — voice-cc shouldn't be enabling user-level CLI features unilaterally.
**How to avoid:** Plan 02-02's task spec must be explicit: "Append `require("hs.ipc")` to `~/.hammerspoon/init.lua`, idempotently — check for the line first, only append if missing." See §12.
**Warning sign:** voice-cc-lua/init.lua contains hs.ipc.

---

## Code Examples

### A. Complete recommended `transcribe()` function (Plan 02-01)

```bash
# transcribe() — the SOLE STT abstraction boundary (ARCHITECTURE.md Pattern 2).
# v1: one-shot whisper-cli per utterance.
# v1.1 (deferred): swap body to `curl 127.0.0.1:8080/inference -F file=@"$1"`.
# NOTHING else in this script may invoke whisper-cli directly.
transcribe() {
  local wav_path="$1"
  "$WHISPER_BIN" \
    -m "$MODEL" \
    --language en \
    --no-timestamps \
    --no-prints \
    --vad \
    --vad-model "$SILERO_MODEL" \
    --vad-threshold 0.50 \
    --suppress-nst \
    --prompt "$VOCAB" \
    -f "$wav_path" 2>/dev/null
}
```

### B. Complete recommended bash glue post-`wait` block (Plan 02-01)

```bash
# (After wait "$SOX_PID" || true; SOX_EXIT=$?; trap - TERM INT)

# TCC silent-deny detection (ROB-02)
if [ "$SOX_EXIT" -ne 0 ]; then
  if grep -qE 'Permission denied|AudioObject(GetPropertyData|SetPropertyData)|kAudio.*Error' "$SOX_ERR_LOG" 2>/dev/null; then
    exit 10
  fi
  exit 12
fi

# Duration gate (TRA-05)
DURATION=$("$SOXI_BIN" -D "$WAV" 2>/dev/null || echo 0)
if awk -v d="$DURATION" 'BEGIN { exit !(d < 0.4) }'; then
  exit 2
fi

# Transcribe (Pattern 2 boundary — sole whisper-cli call)
TRANSCRIPT="$(transcribe "$WAV")"
TRANSCRIPT="$(printf "%s" "$TRANSCRIPT" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

# Empty drop (INJ-04)
if [ -z "$TRANSCRIPT" ]; then
  exit 3
fi

# Denylist exact-match (TRA-06)
DENYLIST="$HOME/.config/voice-cc/denylist.txt"
if [ -r "$DENYLIST" ]; then
  CANON_T="$(printf "%s" "$TRANSCRIPT" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
  while IFS= read -r phrase; do
    case "$phrase" in ''|'#'*) continue ;; esac
    CANON_P="$(printf "%s" "$phrase" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
    [ "$CANON_T" = "$CANON_P" ] && exit 3
  done < "$DENYLIST"
fi

# Emit
printf "%s" "$TRANSCRIPT"
```

### C. Complete recommended Lua paste block (Plan 02-02)

```lua
-- Inside hs.task callback, exit code 0 path:
local transcript = stdOut or ""
if transcript:match("^%s*$") then
  return  -- defence-in-depth empty drop (bash should have caught this)
end

local savedClipboard = hs.pasteboard.readAllData()

hs.pasteboard.writeAllData({
  ["public.utf8-plain-text"] = transcript,
  ["org.nspasteboard.TransientType"] = "",
  ["org.nspasteboard.ConcealedType"] = "",
})

hs.eventtap.keyStroke({"cmd"}, "v", 0)

hs.timer.doAfter(0.25, function()
  local current = hs.pasteboard.readAllData()
  if current and current["public.utf8-plain-text"] == transcript then
    hs.pasteboard.writeAllData(savedClipboard)
  end
end)
```

### D. Complete recommended Lua exit-code dispatcher (Plan 02-03)

```lua
local function handleExit(exitCode, stdOut, stdErr)
  if exitCode == 0 then
    pasteWithRestore(stdOut)
  elseif exitCode == 2 then
    -- Silent abort: clip too short
  elseif exitCode == 3 then
    -- Silent abort: empty / denylist match
  elseif exitCode == 10 then
    notifyOnce(10, function()
      hs.notify.new("voiceccOpenMicSettings", {
        title = "voice-cc: microphone blocked",
        informativeText = "Grant Hammerspoon access in Privacy & Security → Microphone",
        actionButtonTitle = "Open Settings",
        hasActionButton = true,
        autoWithdraw = false,
        withdrawAfter = 0,
      }):send()
    end)
  elseif exitCode == 11 then
    notifyOnce(11, function()
      hs.notify.new({
        title = "voice-cc: install incomplete",
        informativeText = "Run setup.sh — model or binary missing",
        autoWithdraw = false,
      }):send()
    end)
  elseif exitCode == 12 then
    notifyOnce(12, function()
      hs.notify.new({
        title = "voice-cc: transcription failed",
        informativeText = "Check ~/.cache/voice-cc/error.log",
      }):send()
    end)
  end
end
```

---

## Runtime State Inventory

> Phase 2 modifies code only — no rename, no migration of existing data. Most categories are empty.

| Category | Items Found | Action Required |
|---|---|---|
| Stored data | None — no databases, no datastores. The only persistent file Phase 2 adds is `~/.config/voice-cc/denylist.txt` (config, not stored data) and `~/.local/share/voice-cc/models/ggml-silero-v6.2.0.bin` (downloaded model, not stored data). | none |
| Live service config | None — no external services. | none |
| OS-registered state | None — no Task Scheduler, no LaunchAgent (LaunchAgent is Phase 5 conditional). Phase 2 leaves the running Hammerspoon process and its TCC grants unchanged. | none |
| Secrets / env vars | New env var added: `VOICE_CC_NO_SOUNDS=1` (suppress audio cues, §8). Optional: `VOICE_CC_VAD_THRESHOLD` (override 0.50 default, §2). Both are runtime-only — not persisted, not in any keystore. Existing `VOICE_CC_MODEL` (Phase 1) unchanged. `VOCAB`, `MODEL`, `WAV_DIR`, etc. are bash-internal vars, not env. | none — document new env vars in README during Phase 3 |
| Build artifacts / installed packages | The Silero VAD ggml file (885 KB) is a NEW download to `~/.local/share/voice-cc/models/`. Existing model (`ggml-small.en.bin`, 488 MB) and brew packages (sox, whisper-cpp, hammerspoon) unchanged. **Important:** the symlink `~/.hammerspoon/voice-cc → /repo/voice-cc-lua` is preserved by Phase 2's edits to `voice-cc-lua/init.lua` — Hammerspoon picks up the new Lua via `hs -c "hs.reload()"` (now possible thanks to Phase-1 TODO b). | Reload Hammerspoon after voice-cc-lua/init.lua edits. setup.sh additions handle the Silero download idempotently. |

**Nothing found in the categories marked "none":** verified by inspection — Phase 2 introduces no new external integrations, no new datastores, no new long-running processes.

---

## Environment Availability

Audited live on Oliver's machine (2026-04-27).

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Hammerspoon.app | All Lua features (FBK-01, FBK-02, FBK-03, INJ-02, INJ-03, ROB-01) | ✓ | (per Phase 1 install) | none — required |
| `/opt/homebrew/bin/sox` | Audio capture | ✓ | SoX v (version unspecified in --version output but functional) | none — required |
| `/opt/homebrew/bin/soxi` | Duration gate (TRA-05) | ✓ | bundled with sox | none — required |
| `/opt/homebrew/bin/whisper-cli` | Transcription + VAD (TRA-04) | ✓ | recent (--vad, --suppress-nst, --no-prints all present per --help) | none — required |
| `/opt/homebrew/bin/hs` (Hammerspoon CLI) | Scripted reloads (Phase-1 TODO b dev workflow) | ✓ (binary present) | (cask-bundled) | manual reload via menubar — works without hs.ipc |
| `~/.local/share/voice-cc/models/ggml-small.en.bin` | Transcription | ✓ | 488 MB, SHA256-verified per Phase 1 | none — required |
| `~/.local/share/voice-cc/models/ggml-silero-v6.2.0.bin` | VAD (TRA-04) | ✗ | — | Use v5.1.2 (also available); fallback to no-VAD + denylist-only if neither downloads (degraded but functional) |
| Internet (to download Silero) | One-time install | (assumed) | — | If offline, ship the file in the repo (885 KB) — not preferred but possible |
| macOS Sequoia 15.7.5 | All — TCC, hs.notify, deep links | ✓ | confirmed | n/a |
| `hyperfine` | Phase 3 only | ✗ | — | n/a — Phase 2 doesn't need it |

**Missing dependencies with no fallback:** none for Phase 2's core requirements.

**Missing dependencies with fallback:**
- **Silero VAD weights** (885 KB, downloadable in setup.sh additions). Fallback: use v5.1.2 (same size, also at the same HF repo). Worst case: skip `--vad` entirely and rely on denylist + duration gate (degraded — silence hallucinations would still occur in the gap between "duration > 0.4 s" and "all-quiet but no obvious denylisted phrase").

---

## State of the Art

| Old Approach (Phase 1) | Current Approach (Phase 2) | When Changed | Impact |
|---|---|---|---|
| `whisper-cli ... -otxt -of "$out_base"` + `cat "${out_base}.txt"` | `whisper-cli ... --no-prints` (capture stdout directly) | Phase 2 | Eliminates leftover .txt; one less file to clean |
| No `--vad` flag | `--vad --vad-model "$SILERO_MODEL" --vad-threshold 0.50` | Phase 2 | Silence regions trimmed before inference; major hallucination reduction |
| No denylist | Whole-transcript exact-match against `~/.config/voice-cc/denylist.txt` | Phase 2 | Belt + braces with VAD; catches the residual hallucinations VAD misses |
| `hs.pasteboard.setContents(transcript)` then `cmd+v` (clobbers prior clipboard forever) | `readAllData` → `writeAllData({text + transient UTI})` → `cmd+v` → `hs.timer.doAfter(0.25, restore)` | Phase 2 | Privacy: clipboard managers skip transcripts. UX: prior clipboard restored. |
| Trap on TERM/INT only (forwards to sox; no cleanup) | Trap on TERM/INT (forwards) + EXIT trap (cleanup) | Phase 2 | No /tmp WAV leaks across any exit path |
| Phase 1 minimum-viable mutex (`if currentTask:isRunning() return end`) | Explicit `isRecording` boolean + reset in pcall-wrapped finally + `setMenubarIdle` in same path | Phase 2 | Indicator never sticks; state never desyncs |
| `hs.alert.show("...")` for hotkey-bind / script-not-found errors | `hs.notify.new(...)` with action button + System Settings deep link | Phase 2 | User can act on the error, not just see it |
| No first-run Accessibility prompt (silent no-op on first cmd+v) | `hs.accessibilityState(true)` on module load | Phase 2 | Eliminates the only first-run silent failure observed in Phase 1 walkthrough |
| `osascript -e 'tell application "Hammerspoon" to reload config'` silently fails | `hs -c "hs.reload()"` works after `require("hs.ipc")` | Phase 2 | Dev workflow gains scripted reloads (also enables remote Lua eval) |

**Deprecated/outdated patterns being removed in Phase 2:**
- The `-otxt -of "$out_base"` whisper-cli flag pair (Phase 1 implementation) — replaced with `--no-prints` and stdout capture.
- The Phase 1 "if exitCode != 0 silently return" Lua dispatcher — replaced with the semantic exit-code dispatcher in §13.D.
- The Phase 1 `hs.pasteboard.setContents` single-write — replaced with the multi-type `writeAllData` write.

---

## Open Questions for Planner

These are items I could not fully resolve through documentation/web research. They need either live verification during plan execution or a deliberate planner decision.

1. **Exact sox stderr fingerprint when mic is denied on Sequoia 15.7.5.**
   - **What we know:** PITFALLS.md and community sources converge on `Permission denied|AudioObject(GetPropertyData|SetPropertyData)|kAudio.*Error`.
   - **What's unclear:** the exact text on Sequoia 15.7.5 with the brew-bottle sox v14.4.2 (the version on the target machine). Could be slightly different. Could be that sox returns a specific exit code (not just "non-zero") that's a stronger signal than stderr grep.
   - **Recommendation:** Plan 02-01 should include an explicit task: deliberately run `tccutil reset Microphone org.hammerspoon.Hammerspoon`, restart Hammerspoon, press hotkey, capture exact sox stderr output, then re-grant. The bash glue's grep regex should be tuned to match what was observed. (Make the task `checkpoint:human-verify` since it requires Hammerspoon UI interaction.)

2. **Does the new `com.apple.settings.PrivacySecurity.extension` URL actually work on Sequoia 15.7.5?**
   - **What we know:** Web research says yes, with the legacy `com.apple.preference.security` URL also working as fallback.
   - **What's unclear:** I haven't verified live on Oliver's exact macOS build (24G624). Apple has been known to silently rename/reroute these between minor versions.
   - **Recommendation:** Plan 02-03 should test the URL during the TCC denial walkthrough. If it fails, fall back to the legacy URL.

3. **Does Raycast Clipboard History honour `org.nspasteboard.TransientType`?**
   - **What we know:** Maccy explicitly does (default-on). 1Password uses the spec via arboard. Raycast docs don't mention nspasteboard.org.
   - **What's unclear:** Whether Raycast skips entries with the transient marker.
   - **Recommendation:** Document in README as a known residual risk for Raycast users. Don't block Phase 2 on resolving — the transient marker is harmless to add even if Raycast ignores it.

4. **Is the `--no-prints` flag available in the brew bottle's whisper-cli on the target?**
   - **What we know:** It IS in the help output captured live (line: `-np, --no-prints [false ] do not print anything other than the results`).
   - **Confidence:** HIGH (verified directly).

5. **Does VAD threshold 0.50 reliably trim 2 s of pure silence on Oliver's mic?**
   - **What we know:** 0.50 is the documented default and STACK.md/PITFALLS.md recommendation.
   - **What's unclear:** mic-specific noise floor characteristics.
   - **Recommendation:** Plan 02-01 should include a manual integration test as part of the walkthrough (record 2 s of silence, expect empty output). If it fails, tune up to 0.60 and re-test.

6. **Should the duration gate measure WAV length (current recommendation) or hotkey hold time?**
   - **What we know:** Bash-side WAV measurement is simpler and more truthful (catches sox-failed-to-capture cases).
   - **What's unclear:** Marginal extra latency of ~2 ms for soxi invocation — irrelevant.
   - **Decision:** Bash-side WAV measurement. Locked.

7. **Should we suppress audio cues for sub-100ms taps (avoid the Pop-then-Tink for accidental taps)?**
   - **What we know:** Spec is silent on this; my recommendation in §8 is "let them fire — the cues are part of useful feedback that the hotkey was heard."
   - **What's unclear:** UX preference call.
   - **Recommendation:** Ship as recommended. Revisit in Phase 4 if Oliver finds it annoying.

---

## Validation Architecture

> Per `workflow.nyquist_validation: true` in .planning/config.json. This section is what `02-VALIDATION.md` will be derived from.

### Test Framework

Phase 2 has no existing test infrastructure (Phase 1 deliberately skipped formal verifier per user direction). Phase 2 introduces shell-based tests for the bash-side hardening; Lua-side verification is manual walkthrough (Hammerspoon-internal state can't be unit-tested without significant infrastructure).

| Property | Value |
|---|---|
| Framework | bash + standard POSIX utils (printf, grep, awk, sox, soxi); no test runner needed — each test is a standalone executable script that exits 0/non-zero |
| Config file | none — see Wave 0 |
| Quick run command | `bash tests/test_<name>.sh` for individual tests; `bash tests/run_all.sh` for the suite |
| Full suite command | `bash tests/run_all.sh` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| TRA-04 | VAD trims silence so silent recordings produce empty/denylisted output | integration | `bash tests/test_vad_silence.sh` | ❌ Wave 0 |
| TRA-05 | Clips < 0.4 s exit 2 silently | unit | `bash tests/test_duration_gate.sh` | ❌ Wave 0 |
| TRA-06 | Each denylist phrase triggers exit 3; non-denylist phrase passes through | unit | `bash tests/test_denylist.sh` | ❌ Wave 0 |
| INJ-02 | Prior clipboard restored after paste | manual (Hammerspoon required) | `tests/manual/test_clipboard_restore.md` walkthrough | ❌ Wave 0 |
| INJ-03 | Transcript marked transient — Maccy does NOT record | manual (Hammerspoon + Maccy required) | `tests/manual/test_transient_marker.md` walkthrough | ❌ Wave 0 |
| INJ-04 | Empty/whitespace transcript → exit 3 silently | unit | covered by `bash tests/test_denylist.sh` (empty case) | ❌ Wave 0 |
| FBK-01 | Menubar `●` is grey idle, red recording | manual (visual) | `tests/manual/test_menubar.md` walkthrough | ❌ Wave 0 |
| FBK-02 | Pop on press, Tink on release; suppressed by VOICE_CC_NO_SOUNDS=1 | manual (audible) | `tests/manual/test_audio_cues.md` walkthrough | ❌ Wave 0 |
| FBK-03 | Notification appears with deep link button on TCC denial | manual (TCC manipulation required) | `tests/manual/test_tcc_notification.md` walkthrough | ❌ Wave 0 |
| ROB-01 | Rapid double-press shows ONE sox process | manual (`pgrep -fa sox`) | `tests/manual/test_reentrancy.md` walkthrough | ❌ Wave 0 |
| ROB-02 | sox stderr fingerprint detected → exit 10 | unit (synthetic stderr) + live host (Phase 2 walkthrough) | `bash tests/test_tcc_grep.sh` + manual | ❌ Wave 0 |
| ROB-04 | After invocation, `/tmp/voice-cc/` is empty (or contains only in-flight WAV) | unit + signal | `bash tests/test_wav_cleanup.sh`, `bash tests/test_sigint_cleanup.sh` | ❌ Wave 0 |

### Phase-1 follow-up TODOs → Test Map

| TODO | Behavior | Test Type | Command |
|---|---|---|---|
| (a) hs.accessibilityState(true) | Module load surfaces Accessibility prompt deterministically | manual | `tests/manual/test_accessibility_prompt.md` walkthrough (requires `tccutil reset Accessibility`) |
| (b) require("hs.ipc") | `hs -c "1+1"` returns 2 | automated (post-reload) | `[ "$(hs -c '1+1' 2>/dev/null)" = '2' ]` |
| (c) suppress whisper sibling .txt | After successful run, no .txt in /tmp/voice-cc/ | unit | covered by `bash tests/test_wav_cleanup.sh` (asserts /tmp/voice-cc empty post-run) |

### Cross-cutting verification (Pattern 2 boundary)

| Property | Test Type | Command |
|---|---|---|
| Pattern 2 preserved (one WHISPER_BIN assignment + one use inside transcribe()) | static | `[ "$(grep -c WHISPER_BIN voice-cc-record)" -eq 2 ]` |
| Absolute paths for all binaries | static | `grep -E '"\$\{(SOX|SOXI|WHISPER)_BIN' voice-cc-record \| wc -l` should be ≥ 4 |

### Sampling Rate

- **Per task commit:** affected unit tests (e.g., editing the duration gate code → run `bash tests/test_duration_gate.sh`)
- **Per wave merge:** full unit-test suite — `bash tests/run_all.sh` (all 5 unit tests in §11)
- **Phase gate:** full unit-test suite green + manual walkthrough completed against the 5 ROADMAP success criteria

### Wave 0 Gaps

A Wave 0 plan should create the test infrastructure before any hardening work begins:

- [ ] `tests/run_all.sh` — runs every `tests/test_*.sh` and reports pass/fail
- [ ] `tests/lib/sample_audio.sh` — helper to generate test WAVs (silence, short tap, clean speech) via `sox -n synth`
- [ ] `tests/test_duration_gate.sh` — covers TRA-05
- [ ] `tests/test_denylist.sh` — covers TRA-06 + INJ-04
- [ ] `tests/test_vad_silence.sh` — covers TRA-04 (integration; requires Silero model present)
- [ ] `tests/test_tcc_grep.sh` — covers ROB-02 (synthetic stderr in temp file)
- [ ] `tests/test_wav_cleanup.sh` — covers ROB-04 + Phase-1 TODO c
- [ ] `tests/test_sigint_cleanup.sh` — covers ROB-04 SIGINT path
- [ ] `tests/manual/test_*.md` — walkthrough scripts for the manual tests (clipboard, menubar, audio cues, notification, accessibility prompt, re-entrancy)

If the planner prefers, all of these can be created in the first wave alongside the implementation tasks (test-driven). Or as a Wave 0 specifically if test-first discipline is preferred.

---

## Sources

### Primary (HIGH confidence)
- [Hammerspoon hs.pasteboard docs + source](https://www.hammerspoon.org/docs/hs.pasteboard.html) and [pasteboard.lua source](https://github.com/Hammerspoon/hammerspoon/blob/master/extensions/pasteboard/pasteboard.lua) — `writeAllData` / `readAllData` / `writeDataForUTI` API
- [Hammerspoon hs.menubar docs](https://www.hammerspoon.org/docs/hs.menubar.html) — menubar item lifecycle
- [Hammerspoon hs.sound docs](https://www.hammerspoon.org/docs/hs.sound.html) — sound loading + playback
- [Hammerspoon hs.notify docs](https://www.hammerspoon.org/docs/hs.notify.html) — notification API + Alert-vs-Banner caveat
- [Hammerspoon hs.urlevent docs](https://www.hammerspoon.org/docs/hs.urlevent.html) — `openURL` for system deep links
- [Hammerspoon hs.task docs](https://www.hammerspoon.org/docs/hs.task.html) — `terminate()` sends SIGTERM; callback signature
- [Hammerspoon hs.accessibilityState docs](https://www.hammerspoon.org/docs/hs.html#accessibilityState) — `(true)` requests prompt
- [Hammerspoon hs.ipc docs](https://www.hammerspoon.org/docs/hs.ipc.html) — enables `hs` CLI tool, no TCC requirement
- [Hugging Face ggml-org/whisper-vad](https://huggingface.co/ggml-org/whisper-vad/tree/main) — Silero v6.2.0 weights, 885 KB
- [whisper.cpp issue #3003 — built-in Silero VAD](https://github.com/ggml-org/whisper.cpp/issues/3003) — VAD integration history
- [whisper.cpp PR #2649 — suppress non-speech tokens](https://github.com/ggerganov/whisper.cpp/pull/2649) — `--suppress-nst` flag
- [whisper.cpp issue #1592 — "Thank you" hallucination](https://github.com/ggml-org/whisper.cpp/issues/1592) — denylist source
- [whisper.cpp issue #1724 — Hallucination on silence](https://github.com/ggml-org/whisper.cpp/issues/1724) — denylist + VAD rationale
- [openai/whisper discussion #1873 — Share your hallucinations](https://github.com/openai/whisper/discussions/1873) — community-curated denylist phrases
- [nspasteboard.org spec](http://nspasteboard.org/) — official transient/concealed UTI spec
- [Maccy README](https://github.com/p0deje/Maccy) — explicit default support for TransientType, ConcealedType, AutoGeneratedType
- [1Password/arboard](https://github.com/1Password/arboard) — confirms 1Password 8 honours these UTIs
- [Apple Developer Forum — Deeplinks into new System Settings (Ventura+)](https://developer.apple.com/forums/thread/709289) — URL scheme history
- [rmcdongit System Settings URL Schemes gist](https://gist.github.com/rmcdongit/f66ff91e0dad78d4d6346a75ded4b751) — last updated for Sequoia 15.2; confirms both legacy + new URLs work
- Live `whisper-cli --help` captured from `/opt/homebrew/bin/whisper-cli` on Oliver's machine 2026-04-27
- Live `ls /System/Library/Sounds/` captured on Oliver's Sequoia 15.7.5 2026-04-27
- `.planning/research/PITFALLS.md` — internal research, especially the TCC primer + Pitfall 1, 3, 6, 7, 8, 10
- `.planning/research/ARCHITECTURE.md` — exit-code allocation, Pattern 2 boundary, file layout
- `.planning/phases/01-spike/01-01-SUMMARY.md` — VAD audit ("--vad-model default empty")
- `.planning/phases/01-spike/01-03-SUMMARY.md` — Quirks Discovered #1, #2, #3, #4 (Phase-1 TODOs a, b, c)

### Secondary (MEDIUM confidence)
- [Hammerspoon hs.notify issue #1414 — callback persistence across reloads](https://github.com/Hammerspoon/hammerspoon/issues/1414) — informs `hs.notify.register` recommendation
- [Hammerspoon hs.notify issue #2422 — autoWithdraw not working after reload](https://github.com/Hammerspoon/hammerspoon/issues/2422) — informs withdrawAfter=0 recommendation
- [Apple Developer Forum — tccutil reset microphone](https://developer.apple.com/forums/thread/679303) — TCC reset procedure
- [Hammerspoon FAQ](https://www.hammerspoon.org/faq/) — Accessibility re-grant procedure

### Tertiary (LOW confidence — flagged for live verification during plan execution)
- The exact sox stderr text on TCC denial — research couldn't pin it without revoking Oliver's mic permission. Plan 02-01 must verify live (see Open Question #1).
- Raycast Clipboard History support for `org.nspasteboard.TransientType` — research couldn't confirm. Document in README as residual risk (see Open Question #3).

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every API and flag verified against current Hammerspoon docs and live `whisper-cli --help`.
- Architecture: HIGH — preserves Phase 1's Pattern 2 boundary, ARCHITECTURE.md exit codes, XDG layout. No structural deviation.
- Pitfalls: HIGH for documented pitfalls (PITFALLS.md cross-cited); MEDIUM for the Phase 2-specific pitfalls in §13 (synthesised, not directly cited).
- Sox TCC fingerprint: LOW — needs live verification.

**Research date:** 2026-04-27
**Valid until:** 2026-07-01 estimate (Hammerspoon and whisper.cpp move slowly; macOS Sequoia minor updates may shift deep-link URLs — re-verify before Phase 3 README)
