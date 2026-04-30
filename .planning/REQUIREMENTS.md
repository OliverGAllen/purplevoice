# Requirements: voice-cc

**Defined:** 2026-04-26
**Core Value:** Speak → text appears in Claude Code, instantly and reliably, with no recurring cost or external dependency.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Capture

- [x] **CAP-01**: User holds a global hotkey to start recording, releases to stop (push-and-hold semantics; press and release events both detected reliably)
- [x] **CAP-02**: System captures clean 16 kHz mono PCM audio from the default macOS input device while hotkey is held
- [x] **CAP-03**: Hotkey choice does not collide with macOS Spotlight, system Dictation, or commonly-used app shortcuts (default: `cmd+shift+e`, configurable; VS Code/Cursor "Show Explorer" conflict accepted by user 2026-04-27)
- [x] **CAP-04**: Recording cleanly truncates on hotkey release (sox receives SIGTERM, WAV is finalised, no partial-buffer corruption)

### Transcription

- [x] **TRA-01**: Audio is transcribed locally via whisper.cpp using the `small.en` model — no network calls, no API keys, no quotas
- [x] **TRA-02**: Transcript includes native punctuation and capitalisation as Whisper produces them (no post-processing pass beyond filtering)
- [x] **TRA-03**: User can supply custom vocabulary in `~/.config/voice-cc/vocab.txt` which is passed to Whisper via `--prompt` to bias recognition toward technical terms (Claude, MCP, Hammerspoon, etc.)
- [ ] **TRA-04**: System uses `--vad` flag with Silero VAD to suppress silence-region hallucinations
- [ ] **TRA-05**: System drops audio clips shorter than 0.4 seconds without invoking Whisper (defends against accidental hotkey taps)
- [ ] **TRA-06**: System filters whole-transcript matches against a denylist of known Whisper hallucinations ("thanks for watching", "thank you", "[BLANK_AUDIO]", "subtitles by amara.org" etc.) — exact-match only, never substring

### Injection

- [x] **INJ-01**: Final transcript is pasted into the currently focused application via clipboard + simulated `cmd+v` keystroke
- [ ] **INJ-02**: User's existing clipboard contents are preserved and restored after paste, with ≥250 ms delay before restore to avoid racing the paste keystroke
- [ ] **INJ-03**: Clipboard set is marked with `org.nspasteboard.TransientType` UTI so clipboard-history managers (1Password, Raycast, Maccy, Alfred) do not retain transcripts permanently
- [ ] **INJ-04**: Empty or whitespace-only transcripts are silently discarded — no paste, no error toast

### Feedback

- [ ] **FBK-01**: Menu-bar indicator changes colour while recording is active (visual confirmation that hotkey registered)
- [ ] **FBK-02**: System plays a brief audible cue at recording start and end (default-on, suppressible via env var)
- [ ] **FBK-03**: When the system fails (mic permission denied, model file missing, binary not found), user receives an actionable macOS notification with a clear next step or deep link to System Settings — never silent failure

### Robustness

- [ ] **ROB-01**: Rapid repeated hotkey presses do not spawn duplicate recording processes (in-memory re-entrancy guard prevents overlapping captures)
- [ ] **ROB-02**: TCC microphone-permission denial is detected from sox stderr and surfaced as a notification with a deep link to System Settings → Privacy → Microphone
- [x] **ROB-03**: All external binaries (sox, whisper-cli) are invoked by absolute path so the system works when Hammerspoon spawns them (Hammerspoon's `hs.task` does not include `/opt/homebrew/bin` in PATH on Apple Silicon)
- [ ] **ROB-04**: Temporary WAV files are cleaned up via shell trap on every exit path, including signal interruption — no accumulation in `/tmp/voice-cc/`
- [x] **ROB-05**: End-to-end latency (key release to text appearing in focused window) is under 2 seconds for a typical 5-second utterance on Apple Silicon

### Distribution

- [ ] **DST-01**: A single `install.sh` script installs all dependencies (Hammerspoon, sox, whisper-cpp), creates required directories, downloads the model file, links binaries, and is fully idempotent (safe to re-run)
- [ ] **DST-02**: `install.sh` never auto-edits the user's `~/.hammerspoon/init.lua` — instead prints the one-line `require("voice-cc")` for the user to paste themselves
- [ ] **DST-03**: README documents permission grants required (Microphone + Accessibility for Hammerspoon), how to disable conflicting macOS Dictation shortcut, and `tccutil reset` recovery procedure
- [ ] **DST-04**: `hyperfine` benchmark on the install machine produces p50 / p95 latency numbers for short, medium, and long utterances — gates the v1.1 warm-process upgrade decision

### Branding

- [x] **BRD-01**: Product name `PurpleVoice` is recorded in `.planning/PROJECT.md` as the authoritative public-facing name with a rationale paragraph that anchors the privacy-first positioning across the broadened audience: privacy-conscious individuals, government / defence / intelligence personnel, healthcare professionals (HIPAA), legal professionals (attorney-client privilege), finance / compliance roles (MNPI / regulated PII), journalists handling sensitive sources, and air-gapped / restricted-network operators. The positioning forward-references Phase 2.7 `SECURITY.md` as the document that substantiates the institutional claims with a threat model, auditable zero-egress verification methodology, SBOM, and gap analysis. The positioning uses "auditable" / "verifiable" language rather than over-claiming.
- [x] **BRD-02**: All user-visible strings (README, Hammerspoon alerts and notification titles, setup.sh banner, install snippet, error messages, manual walkthroughs) use `PurpleVoice` (PascalCase) or `purplevoice` (lowercase paths/modules/binaries) consistently. The original working name `voice-cc` is preserved verbatim ONLY in: the repo working directory path on disk, the git history, all `.planning/` artifacts (historical record), the `migrate_xdg_dir` FROM-arg literals in `setup.sh` (intentional — needed for the migration logic), and the GSD-auto-managed CLAUDE.md block (deferred to Phase 3 STACK.md update — see STATE.md Open TODOs). The canonical tagline `Local voice dictation. Nothing leaves your Mac.` is placed in the README header, the setup.sh banner, and the Hammerspoon module load alert.
- [x] **BRD-03**: Minimal visual identity — a 256×256 PNG icon at `assets/icon-256.png` (lavender `#B388EB` background, centred white lips silhouette, flat-design) derived deterministically from a hand-authored `assets/icon.svg` source via `sips`; AND a Hammerspoon menubar glyph styled with the same lavender `#B388EB` for both idle and recording states (recording-state differentiation via glyph shape — outline circle U+25CB for idle, filled circle U+25CF for recording).

### Security

- [x] **SEC-01**: Authoritative `SECURITY.md` published in repo root containing: 1-page TL;DR + audience entry-point ToC + Scope (assets, trust boundaries, out-of-scope rationale) + Threat Model (STRIDE 6×N + LINDDUN 7×N matrices) + Egress Verification methodology + SBOM cross-reference + Air-Gapped Installation procedure + per-control NIST SP 800-53 Rev 5 / Low-baseline mapping + 6 framed framework sections (FIPS 140-3, FedRAMP-tailored, Common Criteria, HIPAA Security Rule §164.312, SOC 2 Type II TSC, ISO/IEC 27001:2022 Annex A) + Code Signing & Notarisation (Phase 3 deferral) + Reproducible Build (best-effort caveat) + Vulnerability Disclosure stub + How to Verify These Claims instructions. "Compatible with" framing (D-17) enforced consistently throughout, verified by `tests/test_security_md_framing.sh` lint.
- [x] **SEC-02**: Zero outbound network egress from the PurpleVoice process tree (`purplevoice-record` + `sox` + transcription children) during a recording window, demonstrably true via `tests/security/verify_egress.sh` 3-layer evidence chain (lsof + nettop + pf+tcpdump) with positive-control pf-efficacy check (Pitfall 1 — macOS Sequoia 15.7.5 regression detection). Hammerspoon main process explicitly excluded from scope (D-06; Pitfall 5).
- [x] **SEC-03**: Software Bill of Materials at `SBOM.spdx.json` in repo root (SPDX 2.3 JSON format), covering direct + transitive + system-context dependencies (D-11 full scope). System context = macOS version, hardware platform (Apple Silicon variant), Xcode CLT version, brew version (carried via SPDX 2.3 Annotation blocks). Regenerated idempotently by `setup.sh` Step 8 if Syft is present (deterministic post-process per Pitfall 3 — zero spurious git diff). Verified by `tests/security/verify_sbom.sh`.
- [x] **SEC-04**: Code signing & notarisation status documented honestly in `SECURITY.md` §"Code Signing & Notarisation" — current architecture (Hammerspoon Spoon + bash glue + brew binaries + GGML model) produces no signable PurpleVoice artifact; Phase 3 deferral with $99/year Apple Developer Program cost framing + Hardened Runtime + entitlements scope; verified by `tests/security/verify_signing.sh` documentation-presence stub. Real signing infrastructure work belongs to Phase 3 when an installer artifact ships.
- [x] **SEC-05**: Reproducible build status documented in `SECURITY.md` §"Reproducible Build" — full byte-identical reproducibility deferred (toolchain-version-sensitive; whisper.cpp Metal compilation depends on Xcode CLT version + macOS SDK + compiler revision per Pitfall 14). Best-effort reproducibility documented: SHA256-pinned model + git-tracked source + brew-bottle SHA256 verification + reviewable plain-text bash + Lua. Verified by `tests/security/verify_reproducibility.sh` documentation-presence stub.
- [x] **SEC-06**: Air-gapped operation supported via `PURPLEVOICE_OFFLINE=1` mode in `setup.sh` (D-08). Sets the env var → setup.sh skips network calls (Hammerspoon brew install, Whisper model download, Silero VAD download) and verifies sideloaded artefacts at documented paths. Sideload paths: `~/.local/share/purplevoice/models/{ggml-small.en.bin,ggml-silero-v6.2.0.bin}`, `/Applications/Hammerspoon.app`, `/opt/homebrew/bin/{sox,soxi,whisper-cli}`. Verified by `tests/security/verify_air_gap.sh` (2 invariants: sideload populated → exit 0; missing → exit 1 with actionable error). Hammerspoon brew gap (Pitfall 8) is acknowledged honestly — operators must dmg-copy Hammerspoon from a connected machine.

### Hover UI / HUD

- [ ] **HUD-01**: Floating canvas widget appears within ~50ms of hotkey press and disappears within ~250ms of release. Implemented as `hs.canvas` overlay in `purplevoice-lua/init.lua`; lifecycle hooked into existing `onPress` (line 266) and `resetState()` (line 116) alongside `setMenubarRecording()`/`setMenubarIdle()`. Verified by `tests/manual/test_hud_appearance.md`.
- [ ] **HUD-02**: User-toggleable visibility via `PURPLEVOICE_HUD_OFF=1` env var read once at module load (mirrors existing `PURPLEVOICE_NO_SOUNDS` line 99 idiom; default-ON per D-09). Verified by `tests/test_hud_env_off.sh` (string-level wiring) + `tests/manual/test_hud_disable.md` (live end-to-end).
- [ ] **HUD-03**: Effectively zero CPU when idle — no animation loops, no timers; `hs.canvas` `:hide()` orders the NSWindow out and stops compositing; `wantsLayer(true)` engages Core Animation GPU compositing during visible state. Verified by `tests/manual/test_hud_idle_cpu.md` (documentation-driven `top -pid` baseline measurement; no specific pass/fail threshold).
- [ ] **HUD-04**: Position configurable via `PURPLEVOICE_HUD_POSITION` env var with six locked named positions (`top-center` (default) | `top-right` | `bottom-center` | `bottom-right` | `near-cursor` | `center`); invalid values fall back to `top-center` with a single warning to the Hammerspoon console at module load (D-07). HUD does not steal focus (`hs.canvas` defaults `ignoresMouseEvents=YES`, `canBecomeKeyWindow=NO`). HUD visibility in screen recordings is **limited** — `NSWindowSharingNone` is honoured by legacy `screencapture` CLI but ignored by ScreenCaptureKit on macOS 15+ (Apple Developer Forums thread 792152, 2025); for sensitive sessions, run with `PURPLEVOICE_HUD_OFF=1`. Verified by `tests/test_hud_position_validation.sh` + `tests/manual/test_hud_focus.md` + `tests/manual/test_hud_screen_capture.md` (documentation-only).

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Quality of Life

- **QOL-01**: Paste-last-transcript hotkey re-pastes the most recent transcription (recovery from focus-lost paste)
- **QOL-02**: Pressing Esc while recording cancels the in-flight capture without paste
- **QOL-03**: User can supply `~/.config/voice-cc/replacements.txt` (find/replace pairs) for recurring mis-transcriptions that `--prompt` doesn't fix ("Versel" → "Vercel")
- **QOL-04**: Rolling history log at `~/.cache/voice-cc/history.log` capped at 10 MB
- **QOL-05**: `VOICE_CC_MODEL` environment variable allows runtime model swap (e.g., `medium.en`)

### Performance

- **PERF-01**: Optional warm-process upgrade — `whisper-server` runs as a LaunchAgent with `KeepAlive=true`; bash `transcribe()` swaps from `whisper-cli` invocation to localhost HTTP. Targets sub-1-second latency. Triggered only if v1 hyperfine measurements show p50 > 2.0 s or p95 > 3.0 s.
- **PERF-02**: Optional Core ML encoder build (`-DWHISPER_COREML=1`) for ~3× ANE speedup on the encoder pass — documented in v1 README, automated in v1.x install.sh upgrade path

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| TTS / spoken replies | v1 is text-only; TTS is additive and easy to bolt on later if a real need surfaces |
| Voice commands beyond dictation ("send", "clear") | Defer until pure dictation loop is rock-solid; voice commands need parser + state machine |
| Toggle / tap-to-record mode | Push-and-hold only; toggle introduces stuck-mic failure mode and recording-state ambiguity |
| Wake words / always-on listening | Adds false-trigger and always-on-mic concerns; explicit hotkey only |
| Project-aware context / per-project hotkeys | v1 just injects into focused window; per-project routing is v2 candidate |
| Cloud STT (Whisper API, Deepgram) | Violates the no-subscriptions / no-limits / no-network constraint |
| LLM post-processing (Wispr Flow style) | Receiving system is itself an LLM (Claude); a second LLM polish pass adds latency to no benefit |
| Multi-language / language auto-detect | English-only `.en` model used; auto-detect causes wrong-language transcription on short clips |
| Streaming / partial transcription | PTT clips are short; streaming adds complexity for no perceptible win |
| Speaker diarization | Single-user single-speaker tool; diarization is overhead with no use case |
| Code-symbol grammar dictation ("open paren") | Obsolete in the LLM-prompt era; users dictate natural-language prompts, not literal syntax |
| GUI / preferences app | Config lives in dotfiles; no Electron/SwiftUI shell needed |
| Cross-platform support (Linux, Windows) | macOS Apple Silicon only; Metal acceleration is the local-STT unlock |
| Telemetry / audio retention beyond ephemeral WAV | Privacy-preserving by design; nothing leaves the machine, nothing persists beyond the current invocation |
| Distribution to other users | Personal tool first; if it generalises, package later |
| App-aware tone/format shifting | Out of scope; transcript goes in raw, formatting is the receiving app's job |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| CAP-01 | Phase 1: Spike | Complete |
| CAP-02 | Phase 1: Spike | Complete |
| CAP-03 | Phase 1: Spike | Complete |
| CAP-04 | Phase 1: Spike | Complete |
| TRA-01 | Phase 1: Spike | Complete |
| TRA-02 | Phase 1: Spike | Complete |
| TRA-03 | Phase 1: Spike | Complete |
| TRA-04 | Phase 2: Hardening | Pending |
| TRA-05 | Phase 2: Hardening | Pending |
| TRA-06 | Phase 2: Hardening | Pending |
| INJ-01 | Phase 1: Spike | Complete |
| INJ-02 | Phase 2: Hardening | Pending |
| INJ-03 | Phase 2: Hardening | Pending |
| INJ-04 | Phase 2: Hardening | Pending |
| FBK-01 | Phase 2: Hardening | Pending |
| FBK-02 | Phase 2: Hardening | Pending |
| FBK-03 | Phase 2: Hardening | Pending |
| ROB-01 | Phase 2: Hardening | Pending |
| ROB-02 | Phase 2: Hardening | Pending |
| ROB-03 | Phase 1: Spike | Complete |
| ROB-04 | Phase 2: Hardening | Pending |
| ROB-05 | Phase 1: Spike | Complete |
| DST-01 | Phase 3: Distribution & Benchmarking | Pending |
| DST-02 | Phase 3: Distribution & Benchmarking | Pending |
| DST-03 | Phase 3: Distribution & Benchmarking | Pending |
| DST-04 | Phase 3: Distribution & Benchmarking | Pending |
| BRD-01 | Phase 2.5: Branding | Complete |
| BRD-02 | Phase 2.5: Branding | Complete |
| BRD-03 | Phase 2.5: Branding | Complete |
| SEC-01 | Phase 2.7: Security Posture & Government Readiness | Complete |
| SEC-02 | Phase 2.7: Security Posture & Government Readiness | Complete |
| SEC-03 | Phase 2.7: Security Posture & Government Readiness | Complete |
| SEC-04 | Phase 2.7: Security Posture & Government Readiness | Complete |
| SEC-05 | Phase 2.7: Security Posture & Government Readiness | Complete |
| SEC-06 | Phase 2.7: Security Posture & Government Readiness | Complete |
| HUD-01 | Phase 3.5: Hover UI / HUD | Pending |
| HUD-02 | Phase 3.5: Hover UI / HUD | Pending |
| HUD-03 | Phase 3.5: Hover UI / HUD | Pending |
| HUD-04 | Phase 3.5: Hover UI / HUD | Pending |
| QOL-01 | Phase 4 (v1.x): Quality of Life | Deferred |
| QOL-02 | Phase 4 (v1.x): Quality of Life | Deferred |
| QOL-03 | Phase 4 (v1.x): Quality of Life | Deferred |
| QOL-04 | Phase 4 (v1.x): Quality of Life | Deferred |
| QOL-05 | Phase 4 (v1.x): Quality of Life | Deferred |
| PERF-01 | Phase 5 (v1.1, conditional): Warm-Process Upgrade | Conditional |
| PERF-02 | Phase 5 (v1.1, conditional): Warm-Process Upgrade | Conditional |

**Coverage:**
- v1 requirements: 39 total (35 prior + HUD-01..04 added 2026-04-30)
- Mapped to phases: 39 / 39 (100%)
- Unmapped: 0
- v2 requirements: 7 total (5 QOL → Phase 4, 2 PERF → Phase 5 conditional)

**Per-phase counts (v1 only):**
- Phase 1: Spike — 10 requirements (CAP-01..04, TRA-01..03, INJ-01, ROB-03, ROB-05)
- Phase 2: Hardening — 12 requirements (TRA-04..06, INJ-02..04, FBK-01..03, ROB-01, ROB-02, ROB-04)
- Phase 2.5: Branding — 3 requirements (BRD-01..03) — Complete 2026-04-29
- Phase 2.7: Security Posture & Government Readiness — 6 requirements (SEC-01..06) — Pending
- Phase 3: Distribution & Benchmarking — 4 requirements (DST-01..04)
- Phase 3.5: Hover UI / HUD — 4 requirements (HUD-01..04) — Pending

---
*Requirements defined: 2026-04-26*
*Last updated: 2026-04-30 — four HUD requirements added for Phase 3.5 (Pending); traceability table extended.*
