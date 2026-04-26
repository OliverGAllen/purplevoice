# Roadmap: voice-cc

**Created:** 2026-04-23
**Granularity:** standard
**Coverage:** 26/26 v1 requirements mapped
**Build-order constraint:** manual pipeline → bash glue → Hammerspoon wiring (non-negotiable per ARCHITECTURE.md)

## Core Value

Speak → text appears in Claude Code, instantly and reliably, with no recurring cost or external dependency.

## Phases

- [ ] **Phase 1: Spike** — Prove the end-to-end loop works on Oliver's machine. Thin slice, no polish.
- [ ] **Phase 2: Hardening** — Make the loop robust against TCC silent-deny, hallucinations, re-entrancy, clipboard manager leakage, and AirPods surprises.
- [ ] **Phase 3: Distribution & Benchmarking** — Reproducible install + README + `hyperfine` measurements that gate the v1.1 decision.
- [ ] **Phase 4 (v1.x): Quality of Life** — Triggered by post-Phase-3 frustrations; queued, not blocking v1.
- [ ] **Phase 5 (v1.1, conditional): Warm-Process Upgrade** — Gated on Phase 3 hyperfine results.

## Phase Details

### Phase 1: Spike
**Goal**: Prove the end-to-end loop works — hold `cmd+option+space`, say a sentence, release, watch the sentence appear in the focused window in under 2 seconds. No polish, no robustness, no installer.
**Depends on**: Nothing (first phase).
**Requirements**: CAP-01, CAP-02, CAP-03, CAP-04, TRA-01, TRA-02, TRA-03, INJ-01, ROB-03, ROB-05
**Success Criteria** (what must be TRUE):
  1. Holding `cmd+option+space` and saying "refactor the auth middleware to use JWTs" results in that sentence appearing in the focused text field within ~2 seconds of release on Oliver's Apple Silicon Mac.
  2. The bash glue script can be invoked manually (outside Hammerspoon) and produces the same transcript on stdout for a hand-recorded WAV — the pipeline composes.
  3. Native Whisper punctuation and capitalisation appear in the pasted output (no post-processing pass yet).
  4. Custom vocabulary in `~/.config/voice-cc/vocab.txt` measurably biases recognition toward technical terms (Anthropic, Hammerspoon, MCP) when supplied via `--prompt`.
  5. All external binaries (sox, whisper-cli) are invoked by absolute path so the loop works under Hammerspoon's restricted PATH from day one.
**Plans**: TBD
**UI hint**: yes

### Phase 2: Hardening
**Goal**: Make the loop trustworthy. Eliminate the documented failure modes — Whisper hallucinations, TCC silent-deny, clipboard manager retention, paste-restore races, re-entrant double-recordings, WAV leaks, and silent failures with no user-visible cause.
**Depends on**: Phase 1 (you cannot harden a loop that doesn't yet exist; you need observed hallucinations to design the denylist, you need a real paste path to know what to preserve).
**Requirements**: TRA-04, TRA-05, TRA-06, INJ-02, INJ-03, INJ-04, FBK-01, FBK-02, FBK-03, ROB-01, ROB-02, ROB-04
**Success Criteria** (what must be TRUE):
  1. A 100 ms accidental hotkey tap produces no paste and no error — silently aborted by the duration gate.
  2. Recording 2 seconds of pure silence does not paste "thanks for watching" or any other Whisper hallucination — caught by VAD + denylist exact-match.
  3. Revoking Hammerspoon's microphone permission via `tccutil reset` and pressing the hotkey produces an actionable macOS notification with a working deep link to System Settings → Privacy → Microphone — never silent failure.
  4. After a successful paste, the user's prior clipboard contents are restored within ~250 ms; clipboard managers (1Password, Raycast, Maccy) do not retain the transcript permanently because the clipboard set is marked `org.nspasteboard.TransientType`.
  5. Holding the hotkey shows a visible menu-bar indicator change and (unless `VOICE_CC_NO_SOUNDS=1`) plays brief start/stop audio cues; rapid double-presses do not spawn duplicate sox processes; no WAV files accumulate in `/tmp/voice-cc/` across exit paths including SIGINT.
**Plans**: TBD
**UI hint**: yes

### Phase 3: Distribution & Benchmarking
**Goal**: Make voice-cc reproducible on a fresh machine via a single idempotent script, document the permission grants and recovery procedures, and produce `hyperfine` measurements on Oliver's actual hardware that determine whether Phase 5 (warm-process upgrade) is needed.
**Depends on**: Phase 2 (install.sh ships the production configuration, which only exists once hardening is in; benchmarks must measure that production configuration).
**Requirements**: DST-01, DST-02, DST-03, DST-04
**Success Criteria** (what must be TRUE):
  1. Running `./install.sh` on a clean machine installs Hammerspoon, sox, whisper-cpp, downloads `ggml-small.en.bin`, creates `~/.config/voice-cc/`, `~/.local/share/voice-cc/models/`, `~/.cache/voice-cc/`, and symlinks `voice-cc-record` into `~/.local/bin/`. Re-running it changes nothing and never clobbers user-edited config (`config.sh`, `vocab.txt`).
  2. `install.sh` finishes by *printing* (never auto-appending) the exact `require("voice-cc")` line for the user to paste into their own `~/.hammerspoon/init.lua`.
  3. README walks through the Microphone + Accessibility grant for Hammerspoon, the macOS Dictation shortcut disable, and the `tccutil reset Microphone org.hammerspoon.Hammerspoon` recovery procedure.
  4. `hyperfine` produces p50 and p95 end-to-end latency numbers for short (~2 s), medium (~5 s), and long (~10 s) utterances on Oliver's machine; the numbers explicitly inform a documented go/no-go decision for Phase 5.
**Plans**: TBD

### Phase 4 (v1.x): Quality of Life
**Goal**: Address the first real-use frustrations once v1 is shipping. Each item has a specific trigger; do not build speculatively.
**Depends on**: Phase 3 (must be triggered by observed v1 frustrations, not anticipated).
**Requirements**: QOL-01, QOL-02, QOL-03, QOL-04, QOL-05 (all v2-tier, deferred until use-driven trigger fires)
**Success Criteria** (what must be TRUE):
  1. A second hotkey re-pastes the most recent transcript (recovery for focus-lost paste).
  2. Pressing Esc during recording cancels the in-flight capture without paste.
  3. `~/.config/voice-cc/replacements.txt` find/replace pairs are applied to transcripts as a `sed` post-filter step ("Versel" → "Vercel").
  4. A capped (≤10 MB) rolling history log lives at `~/.cache/voice-cc/history.log` for debugging.
  5. `VOICE_CC_MODEL=medium.en` (or any other model present in the models dir) is honoured at runtime without code changes.
**Plans**: TBD

### Phase 5 (v1.1, CONDITIONAL): Warm-Process Upgrade
**Goal**: Cut latency below 1 second by replacing per-utterance `whisper-cli` invocation with a long-running `whisper-server` over localhost HTTP, managed by a LaunchAgent. **CONDITIONAL: only triggered if Phase 3 hyperfine measurements show p50 > 2.0 s OR p95 > 3.0 s on Oliver's hardware.**
**Depends on**: Phase 3 (hyperfine measurements must demand it; until the data says we need it, the simpler one-shot architecture wins on every dimension that isn't latency).
**Requirements**: PERF-01, PERF-02 (both v2-tier, conditional)
**Success Criteria** (what must be TRUE):
  1. `whisper-server` runs as a LaunchAgent (`com.olivergallen.voice-cc-server.plist`) with `KeepAlive=true` and `RunAtLoad=true`; it survives reboots and self-restarts on crash.
  2. The bash `transcribe()` function swap from `whisper-cli` to `curl 127.0.0.1:8080/inference -F file=@...` is the *only* change in the pipeline — Hammerspoon code, file layout, config, and failure model are unchanged.
  3. Re-running the Phase 3 hyperfine benchmark shows p50 latency < 1.0 s for short utterances.
  4. An optional Core ML encoder build (`-DWHISPER_COREML=1`) for ~3× ANE encoder speedup is documented and either automated by an upgrade path in `install.sh` or covered by a clear manual-build section in the README.
**Plans**: TBD

## Research Flags

Phases that may need `/gsd:research-phase` during planning:

- **Phase 2 (Hardening)** — needs targeted spike on (a) the exact `hs.pasteboard` multi-type write API for the `org.nspasteboard.TransientType` UTI and (b) the macOS Settings deep-link URL format for the Microphone privacy pane (changes across major releases).
- **Phase 5 (v1.1)** — if it triggers, needs hands-on research on `whisper-server`'s exact HTTP API contract under high-frequency PTT load, LaunchAgent `KeepAlive` interactions, and Core ML compilation reproducibility.

Phases with well-documented standard patterns (skip research-phase):

- **Phase 1 (Spike)** — Spellspoon and local-whisper are direct reference implementations.
- **Phase 3 (Distribution)** — install.sh idempotency is solved; README + hyperfine are commodity work.
- **Phase 4 (v1.x)** — every item is < 1 day with an obvious implementation.

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Spike | 0/0 | Not started | - |
| 2. Hardening | 0/0 | Not started | - |
| 3. Distribution & Benchmarking | 0/0 | Not started | - |
| 4. (v1.x) Quality of Life | 0/0 | Queued (not blocking v1) | - |
| 5. (v1.1, conditional) Warm-Process Upgrade | 0/0 | Conditional on Phase 3 hyperfine | - |

## Coverage Summary

- **v1 requirements:** 26 total (CAP-01..04, TRA-01..06, INJ-01..04, FBK-01..03, ROB-01..05, DST-01..04)
- **Mapped to v1 phases (1–3):** 26
- **Unmapped v1:** 0
- **v2 requirements (deferred):** QOL-01..05, PERF-01..02 — assigned to Phase 4 (QoL) and Phase 5 (conditional warm process)

| Phase | v1 Requirements | Count |
|-------|-----------------|-------|
| 1. Spike | CAP-01, CAP-02, CAP-03, CAP-04, TRA-01, TRA-02, TRA-03, INJ-01, ROB-03, ROB-05 | 10 |
| 2. Hardening | TRA-04, TRA-05, TRA-06, INJ-02, INJ-03, INJ-04, FBK-01, FBK-02, FBK-03, ROB-01, ROB-02, ROB-04 | 12 |
| 3. Distribution & Benchmarking | DST-01, DST-02, DST-03, DST-04 | 4 |
| **Total v1** | | **26** |

---
*Roadmap created: 2026-04-23*
