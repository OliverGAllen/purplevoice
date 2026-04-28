# Roadmap: voice-cc

**Created:** 2026-04-23
**Updated:** 2026-04-27 (added Phase 2.5 Branding, extended Phase 3 with Public Install, added Phase 3.5 Hover UI)
**Granularity:** standard
**Coverage:** 26/26 original v1 requirements mapped; new branding/HUD/public-install requirements TBD during planning
**Build-order constraint:** manual pipeline → bash glue → Hammerspoon wiring (non-negotiable per ARCHITECTURE.md)

## Core Value

Speak → text appears in Claude Code, instantly and reliably, with no recurring cost or external dependency.

## Phases

- [x] **Phase 1: Spike** — Prove the end-to-end loop works on Oliver's machine. Thin slice, no polish. *(completed 2026-04-27)*
- [ ] **Phase 2: Hardening** — Make the loop robust against TCC silent-deny, hallucinations, re-entrancy, clipboard manager leakage, and AirPods surprises.
- [ ] **Phase 2.5: Branding** — Pick a public-facing product name and apply it across user-visible surfaces. Pre-requisite for Distribution and HUD because both reference the brand.
- [ ] **Phase 3: Distribution & Benchmarking + Public Install** — Reproducible local install, public one-line installer for sharing online, README, and `hyperfine` measurements that gate the v1.1 decision.
- [ ] **Phase 3.5: Hover UI / HUD** — Small floating recording-state indicator that complements the menu-bar indicator. Hideable. Branded per Phase 2.5.
- [ ] **Phase 4 (v1.x): Quality of Life** — Triggered by post-Phase-3 frustrations; queued, not blocking v1.
- [ ] **Phase 5 (v1.1, conditional): Warm-Process Upgrade** — Gated on Phase 3 hyperfine results.

## Phase Details

### Phase 1: Spike
**Goal**: Prove the end-to-end loop works — hold `cmd+shift+e`, say a sentence, release, watch the sentence appear in the focused window in under 2 seconds. No polish, no robustness, no installer.
**Depends on**: Nothing (first phase).
**Requirements**: CAP-01, CAP-02, CAP-03, CAP-04, TRA-01, TRA-02, TRA-03, INJ-01, ROB-03, ROB-05
**Success Criteria** (what must be TRUE):
  1. Holding `cmd+shift+e` and saying "refactor the auth middleware to use JWTs" results in that sentence appearing in the focused text field within ~2 seconds of release on Oliver's Apple Silicon Mac.
  2. The bash glue script can be invoked manually (outside Hammerspoon) and produces the same transcript on stdout for a hand-recorded WAV — the pipeline composes.
  3. Native Whisper punctuation and capitalisation appear in the pasted output (no post-processing pass yet).
  4. Custom vocabulary in `~/.config/voice-cc/vocab.txt` measurably biases recognition toward technical terms (Anthropic, Hammerspoon, MCP) when supplied via `--prompt`.
  5. All external binaries (sox, whisper-cli) are invoked by absolute path so the loop works under Hammerspoon's restricted PATH from day one.
**Plans:** 3 plans
  - [x] 01-01-PLAN.md — Setup script + manual sox/whisper-cli pipeline validation (TRA-01, CAP-03)
  - [x] 01-02-PLAN.md — Bash glue voice-cc-record with transcribe() abstraction (CAP-02, CAP-04, TRA-02, TRA-03, ROB-03)
  - [x] 01-03-PLAN.md — Hammerspoon Lua module — hotkey wiring + paste (CAP-01, INJ-01, ROB-05)
**UI hint**: yes
**Verification**: User-validated end-to-end on 2026-04-27. Formal `gsd-verifier` skipped per user direction (manual walkthrough sufficient for spike). Three Phase 2 candidates surfaced — see Phase 1 Plan 03 SUMMARY "Quirks Discovered".

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
**Plans:** 4 plans
  - [x] 02-00-PLAN.md — Wave 0: test infrastructure + Silero VAD weights install + denylist.txt seed (no requirements; foundation) — completed 2026-04-28, see 02-00-SUMMARY.md
  - [x] 02-01-PLAN.md — Bash hardening: VAD + duration gate + denylist + empty-drop + TCC stderr fingerprint + EXIT-trap WAV cleanup + suppress whisper sibling .txt (TRA-04, TRA-05, TRA-06, INJ-04, ROB-02, ROB-04 + Phase-1 TODO c)
  - [ ] 02-02-PLAN.md — Lua hardening: hs.accessibilityState + menubar + audio cues + clipboard preserve/restore with transient UTI + re-entrancy guard + handleExit stub + require("hs.ipc") snippet (FBK-01, FBK-02, INJ-02, INJ-03, ROB-01 + Phase-1 TODOs a, b)
  - [ ] 02-03-PLAN.md — Failure surfacing: hs.notify dispatch for exit 10/11/12 + System Settings deep links + dedup cooldown + defence-in-depth Accessibility-deny notification (FBK-03)
**UI hint**: yes

### Phase 2.5: Branding
**Goal**: Pick a public-facing product name (replacing the working name "voice-cc") and apply it consistently across all user-visible surfaces. Establish enough brand presence that the public install (Phase 3) and HUD (Phase 3.5) can reference a stable identity. Small phase — naming and propagation, not a full design system.
**Depends on**: Phase 2 (brand the production behavior, not the spike). Could technically be done in parallel with Phase 2; sequencing it after keeps the brand decision informed by what users actually experience.
**Requirements**: TBD — defined during `/gsd:discuss-phase 2.5`. Likely shape:
  - **BRD-01** — Product name chosen and recorded as authoritative in PROJECT.md with brief rationale
  - **BRD-02** — All user-visible strings (README, Hammerspoon alerts, install messages, error messages) use the new name; "voice-cc" survives only in repo path, git history, and historical .planning/ artifacts
  - **BRD-03** *(optional)* — Minimal app icon or menu-bar glyph
**Success Criteria** (what must be TRUE):
  1. A name is chosen and documented in PROJECT.md as the official product name with a one-paragraph rationale (what it suggests, what it avoids).
  2. README.md, the Hammerspoon Lua module name (or alert strings if module name is preserved for backwards-compat), the `setup.sh` banner, and any other user-visible text use the new name consistently.
  3. The install process and any future public-facing artifacts (Phase 3) inherit the brand without rework.
  4. Optional: a minimal icon (Hammerspoon menu-bar glyph override or 256×256 PNG) — punted to Phase 4 QoL if not trivially achievable.
**Plans**: 4 plans
**UI hint**: light (naming + minor visual polish, no full design system)

### Phase 3: Distribution & Benchmarking + Public Install
**Goal**: Make voice-cc reproducible on a fresh machine via a single idempotent local script, AND make it shareable online via a one-line `curl ... | bash` public installer. Document the permission grants and recovery procedures. Produce `hyperfine` measurements on Oliver's actual hardware that determine whether Phase 5 (warm-process upgrade) is needed.
**Depends on**: Phase 2.5 (the public install banner, README, and any branded distribution artifacts must use the chosen name). Also Phase 2 (install.sh ships the production configuration, which only exists once hardening is in; benchmarks must measure that production configuration).
**Requirements**: DST-01, DST-02, DST-03, DST-04, **plus DST-05 (TBD — public one-line installer)**
**Success Criteria** (what must be TRUE):
  1. Running `./install.sh` on a clean machine installs Hammerspoon, sox, whisper-cpp, downloads `ggml-small.en.bin`, creates `~/.config/voice-cc/`, `~/.local/share/voice-cc/models/`, `~/.cache/voice-cc/`, and symlinks `voice-cc-record` into `~/.local/bin/`. Re-running it changes nothing and never clobbers user-edited config (`config.sh`, `vocab.txt`).
  2. `install.sh` finishes by *printing* (never auto-appending) the exact `require("voice-cc")` (or branded equivalent) line for the user to paste into their own `~/.hammerspoon/init.lua`.
  3. README walks through the Microphone + Accessibility grant for Hammerspoon, the macOS Dictation shortcut disable, and the `tccutil reset Microphone org.hammerspoon.Hammerspoon` recovery procedure.
  4. `hyperfine` produces p50 and p95 end-to-end latency numbers for short (~2 s), medium (~5 s), and long (~10 s) utterances on Oliver's machine; the numbers explicitly inform a documented go/no-go decision for Phase 5.
  5. **A public one-line installer** (`curl -fsSL https://<host>/install | bash`, where `<host>` is GitHub raw or a stable redirect) clones the repo (or downloads a release tarball) into a sensible location, then invokes the local `install.sh`. The public install is idempotent, prints next steps including the brand-aware `require()` line, and is documented in the README. The repo must be public on GitHub before this success criterion can pass.
**Plans**: 4 plans

### Phase 3.5: Hover UI / HUD
**Goal**: A small floating HUD that surfaces voice-cc state at-a-glance — visible "● recording" indicator while the hotkey is held, fading or hideable when idle. Complements (does not replace) Phase 2's menu-bar indicator. Optimised for low CPU when idle and zero distraction when not actively recording.
**Depends on**: Phase 3 (HUD is polish — it ships after distribution proves the core loop is share-worthy and the brand from Phase 2.5 is stable). Also Phase 2 (the press/release lifecycle and menu-bar indicator are the layer the HUD piggybacks on).
**Requirements**: TBD — defined during `/gsd:discuss-phase 3.5`. Likely shape:
  - **HUD-01** — Floating canvas widget (`hs.canvas` or `hs.drawing`) appears within ~50 ms of hotkey press and disappears within ~250 ms of release
  - **HUD-02** — User-toggle-able visibility (env var or `~/.config/voice-cc/config.sh` setting)
  - **HUD-03** — Effectively zero CPU when idle (no animation loops; only redraws on state change)
  - **HUD-04** — Position configurable (near cursor / screen edge / fixed coordinates) with a sensible default
**Success Criteria** (what must be TRUE):
  1. While the hotkey is held, a floating HUD element appears with a visible "● recording" affordance using the brand chosen in Phase 2.5.
  2. The HUD disappears within ~250 ms of release; while idle, no HUD is on screen and no measurable CPU is consumed.
  3. A config toggle hides the HUD entirely for users who only want the menu-bar indicator (Phase 2 still ships the menu-bar indicator regardless of HUD state).
  4. The HUD does not steal focus, does not interfere with paste, and does not appear in screen recordings unless the user explicitly enables it.
**Plans**: 4 plans
**UI hint**: yes (this IS the UI phase)

### Phase 4 (v1.x): Quality of Life
**Goal**: Address the first real-use frustrations once v1 is shipping. Each item has a specific trigger; do not build speculatively.
**Depends on**: Phase 3.5 (must be triggered by observed v1 frustrations after the polished v1 ships, not anticipated).
**Requirements**: QOL-01, QOL-02, QOL-03, QOL-04, QOL-05 (all v2-tier, deferred until use-driven trigger fires)
**Success Criteria** (what must be TRUE):
  1. A second hotkey re-pastes the most recent transcript (recovery for focus-lost paste).
  2. Pressing Esc during recording cancels the in-flight capture without paste.
  3. `~/.config/voice-cc/replacements.txt` find/replace pairs are applied to transcripts as a `sed` post-filter step ("Versel" → "Vercel").
  4. A capped (≤10 MB) rolling history log lives at `~/.cache/voice-cc/history.log` for debugging.
  5. `VOICE_CC_MODEL=medium.en` (or any other model present in the models dir) is honoured at runtime without code changes.
**Plans**: 4 plans

### Phase 5 (v1.1, CONDITIONAL): Warm-Process Upgrade
**Goal**: Cut latency below 1 second by replacing per-utterance `whisper-cli` invocation with a long-running `whisper-server` over localhost HTTP, managed by a LaunchAgent. **CONDITIONAL: only triggered if Phase 3 hyperfine measurements show p50 > 2.0 s OR p95 > 3.0 s on Oliver's hardware.**
**Depends on**: Phase 3 (hyperfine measurements must demand it; until the data says we need it, the simpler one-shot architecture wins on every dimension that isn't latency).
**Requirements**: PERF-01, PERF-02 (both v2-tier, conditional)
**Success Criteria** (what must be TRUE):
  1. `whisper-server` runs as a LaunchAgent (`com.olivergallen.voice-cc-server.plist`) with `KeepAlive=true` and `RunAtLoad=true`; it survives reboots and self-restarts on crash.
  2. The bash `transcribe()` function swap from `whisper-cli` to `curl 127.0.0.1:8080/inference -F file=@...` is the *only* change in the pipeline — Hammerspoon code, file layout, config, and failure model are unchanged.
  3. Re-running the Phase 3 hyperfine benchmark shows p50 latency < 1.0 s for short utterances.
  4. An optional Core ML encoder build (`-DWHISPER_COREML=1`) for ~3× ANE encoder speedup is documented and either automated by an upgrade path in `install.sh` or covered by a clear manual-build section in the README.
**Plans**: 4 plans

## Research Flags

Phases that may need `/gsd:research-phase` during planning:

- **Phase 2 (Hardening)** — needs targeted spike on (a) the exact `hs.pasteboard` multi-type write API for the `org.nspasteboard.TransientType` UTI and (b) the macOS Settings deep-link URL format for the Microphone privacy pane (changes across major releases).
- **Phase 3 (Distribution)** — public one-line installer (`curl ... | bash`) needs a quick check on hosting (GitHub raw vs. release tarball vs. short URL), atomic-download safety, and whether to validate signatures.
- **Phase 3.5 (Hover UI)** — `hs.canvas` vs `hs.drawing` ergonomics for a low-CPU "show only on press" overlay; whether a transparent always-on-top window has any focus-stealing implications.
- **Phase 5 (v1.1)** — if it triggers, needs hands-on research on `whisper-server`'s exact HTTP API contract under high-frequency PTT load, LaunchAgent `KeepAlive` interactions, and Core ML compilation reproducibility.

Phases with well-documented standard patterns (skip research-phase):

- **Phase 1 (Spike)** — Spellspoon and local-whisper were direct reference implementations. ✓ DONE.
- **Phase 2.5 (Branding)** — naming and string propagation; standard work.
- **Phase 4 (v1.x)** — every item is < 1 day with an obvious implementation.

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Spike | 3/3 | Complete | 2026-04-27 |
| 2. Hardening | 0/4 | Not started | - |
| 2.5. Branding | 0/0 | Not started | - |
| 3. Distribution & Benchmarking + Public Install | 0/0 | Not started | - |
| 3.5. Hover UI / HUD | 0/0 | Not started | - |
| 4. (v1.x) Quality of Life | 0/0 | Queued (not blocking v1) | - |
| 5. (v1.1, conditional) Warm-Process Upgrade | 0/0 | Conditional on Phase 3 hyperfine | - |

## Coverage Summary

- **Original v1 requirements:** 26 total (CAP-01..04, TRA-01..06, INJ-01..04, FBK-01..03, ROB-01..05, DST-01..04)
- **Mapped to v1 phases (1–3):** 26
- **Unmapped v1:** 0
- **New requirements added 2026-04-27 (TBD elaboration):** BRD-01..03 (Phase 2.5), DST-05 (Phase 3 extension), HUD-01..04 (Phase 3.5)
- **v2 requirements (deferred):** QOL-01..05, PERF-01..02 — assigned to Phase 4 (QoL) and Phase 5 (conditional warm process)

| Phase | v1 Requirements | Count |
|-------|-----------------|-------|
| 1. Spike | CAP-01, CAP-02, CAP-03, CAP-04, TRA-01, TRA-02, TRA-03, INJ-01, ROB-03, ROB-05 | 10 |
| 2. Hardening | TRA-04, TRA-05, TRA-06, INJ-02, INJ-03, INJ-04, FBK-01, FBK-02, FBK-03, ROB-01, ROB-02, ROB-04 | 12 |
| 2.5. Branding | BRD-01, BRD-02, (BRD-03) | 2-3 (TBD) |
| 3. Distribution & Benchmarking + Public Install | DST-01, DST-02, DST-03, DST-04, DST-05 | 5 |
| 3.5. Hover UI / HUD | HUD-01, HUD-02, HUD-03, HUD-04 | 4 (TBD) |
| **Total v1** | | **33-34** (was 26) |

---
*Roadmap created: 2026-04-23*
*Roadmap extended: 2026-04-27 (Phase 2.5 Branding, Phase 3 Public Install extension, Phase 3.5 Hover UI per user request)*
