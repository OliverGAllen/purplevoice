# PurpleVoice

## What This Is

**PurpleVoice** is a local, push-to-talk voice input system for Claude Code (and any focused window) on macOS Apple Silicon. Hold a hotkey, speak, release — your transcript appears in the focused window in under ~600 ms (M2 Max, hyperfine-measured). Built for individuals and organisations whose privacy requirements rule out cloud-based dictation. Working name was `voice-cc`; renamed during Phase 2.5 (2026-04-29). **v1.0 shipped publicly 2026-05-04** at https://github.com/OliverGAllen/purplevoice (MIT licensed; INSTALL_TOKEN soft-gate active for the curl one-liner — request a token from oliver@olivergallen.com).

## Current State (post v1.0)

- **Shipped:** 2026-05-04. 8 phases, 29 plans, 178 commits, 8 days end-to-end.
- **Public repo:** https://github.com/OliverGAllen/purplevoice (visibility=PUBLIC, MIT, anonymous curl serves install.sh with HTTP 200).
- **Coverage:** 43/43 v1 requirements [x] Complete (100%).
- **Performance:** transcription p50/p95 = 0.589s/0.605s on M2 Max (5s.wav, hyperfine 1.20.0, AC power) — well under the 2s/4s thresholds.
- **Test suites:** functional 16/0, security 5/0, brand + framing GREEN. Pattern 2 invariant intact.
- **Distribution model:** source-available via curl|bash + INSTALL_TOKEN soft-gate. Hammerspoon module + Karabiner JSON rules + bash glue + Lua. No notarised .app (per CONTEXT D-02 deferral).
- **Phase 5 (warm-process daemon):** evaluated 2026-05-04, **DEFERRED** — cold-start within budget; Pattern 2 (`transcribe()` boundary) preserved as latent drop-in swap point if future hardware/model crosses thresholds.
- **Audit trail:** full per-phase SUMMARY.md files in `.planning/phases/`; v1.0 archive in `.planning/milestones/v1.0-{ROADMAP,REQUIREMENTS}.md`.

## Next Milestone Goals

User direction (2026-05-04): **"turn this into a full on application."** Scope for v2.0 to be defined via `/gsd:new-milestone`. Open questions the new-milestone discussion needs to resolve:

- **Native macOS .app bundle** — currently shipping as Hammerspoon-substrate (Option B per Phase 3 D-01). v2 may revisit Option C (signed/notarised wrapping) or Option A (full standalone app). Trade-off: signed-binary trust vs source-readability + zero-opaque-binary posture.
- **Settings UI** — directly contradicts current constraint ("no settings UI"). v2 may add a SwiftUI / native preferences pane (env var → GUI). Risk: scope creep + Electron-adjacent footprint.
- **Multi-platform** — currently macOS Apple Silicon only (constraint locked at v1). v2 could add Linux (Vosk or whisper.cpp + ALSA) and/or Windows (whisper.cpp + Win32 hotkeys). Doubles platform-specific surface area.
- **Audience expansion** — v1 served Oliver primarily, with the audience-broadening pivot in Phase 2.5 forward-pointing at institutional audiences. v2 may target real institutional adoption: SSO/auth/team management (directly contradicts current "no auth, no multi-user" constraint), or stay individual-first with stronger institutional messaging.
- **Voice commands beyond dictation** — currently Out of Scope. v2 candidate: parser + state machine for "send", "clear", agent-mode meta-commands.
- **TTS / spoken replies** — currently Out of Scope. v2 candidate per original positioning.
- **Toggle-to-record / wake word** — currently Out of Scope (pure push-and-hold v1). v2 candidate.
- **App Store distribution** — vs current curl|bash + INSTALL_TOKEN. App Store requires .app bundle + Apple Developer enrolment ($99/year); fundamentally changes the trust model.
- **Hosted backend / sync / telemetry** — directly conflicts with v1 privacy-first core value. Probably should stay Out of Scope for v2.0 unless audience pivot demands it.

These are scope decisions for `/gsd:new-milestone`, not pre-commitments.

## Core Value

**Speak → text appears in Claude Code, instantly and reliably, with no recurring cost or external dependency.**

If everything else fails, this single loop must work: hold key → talk → release → accurate transcript pasted into the focused terminal window.

## Name & Positioning

**Name:** `PurpleVoice` (PascalCase brand). Lowercase `purplevoice` is the canonical form for the Hammerspoon module, the bash binary, and XDG paths.

**Tagline:** _Local voice dictation. Nothing leaves your Mac._

**Positioning:** PurpleVoice is built for people and organisations whose privacy requirements rule out cloud dictation. Every alternative we considered (Koe, Wispr Flow, Voicy, SuperWhisper at any tier with cloud sync, the Mac's built-in Dictation set to "use server-based") sends audio off the machine by default or by subscription. PurpleVoice runs whisper.cpp locally on the Metal backend on Apple Silicon. No accounts, no API keys, no telemetry, no opt-in cloud features that could later become opt-out. Audio is captured to a temporary file, transcribed by a local binary, the WAV is deleted on every exit path, and the transcript is pasted into the focused window.

The audience this serves:

- **Privacy-conscious individuals** who don't want their voice — or its transcripts — leaving their machine
- **Government, defence, and intelligence personnel** whose data-handling policies prohibit cloud STT
- **Healthcare professionals** bound by HIPAA and equivalent privacy rules; **legal professionals** bound by attorney-client privilege
- **Finance and compliance roles** where voice content may include MNPI or regulated PII
- **Journalists** handling sensitive sources whose confidentiality is operational, not aspirational
- **Air-gapped or restricted-network operators** where cloud STT is technically impossible

The Phase 2.7 `SECURITY.md` document substantiates these claims with a threat model, an auditable zero-egress verification methodology, an SBOM, and gap analysis against NIST SP 800-53 / FIPS 140-3 / FedRAMP / Common Criteria expectations. PurpleVoice's posture is **auditable and verifiable** — the SECURITY.md document is honest about which mitigations are pursued and which require external resources to pursue formal accreditation.

**Visual identity:** Lavender `#B388EB` for the menubar indicator and the icon background; white lips silhouette on lavender for the 256×256 icon at `assets/icon-256.png`. The lips imagery (rather than a generic microphone) signals the human gesture — speaking, intimately, on your own machine.

**Decided:** Phase 2.5 (2026-04-29). Audience broadened 2026-04-29 to include institutional / government / defence / healthcare / legal / finance / journalist / air-gapped segments alongside privacy-conscious individuals. See `.planning/phases/02.5-branding/02.5-CONTEXT.md` for the full decision log (D-01 through D-12) and `.planning/phases/02.5-branding/02.5-01-SUMMARY.md` through `02.5-04-SUMMARY.md` for execution evidence.

## Requirements

### Validated

*Validated by Phase 1 spike, end-to-end user walkthrough on 2026-04-27 (cmd+shift+e push-and-hold → bash glue → whisper-cli → clipboard + cmd+v paste, well under 2s):*

- [x] Push-and-hold global hotkey triggers mic recording on macOS *(Phase 1; CAP-01)*
- [x] Audio captured cleanly from system mic while hotkey held *(Phase 1; CAP-02, CAP-03, CAP-04)*
- [x] Transcription happens locally via whisper.cpp (no network calls) *(Phase 1; TRA-01, TRA-02, TRA-03)*
- [x] Transcript injected into the currently focused window (clipboard + paste) *(Phase 1; INJ-01)*
- [x] Latency from key release to text appearing is under ~2 seconds for short utterances on Apple Silicon *(Phase 1 — observational; formal hyperfine numbers in Phase 3)*
- [x] Stack runs entirely from local binaries — no API keys, no signups, no quotas *(Phase 1; ROB-03)*
- [x] **Auditable security posture for institutional / government / healthcare / legal / finance / journalist / air-gapped audiences — `SECURITY.md` published with threat model + zero-egress proof + SBOM + gap analysis vs 7 frameworks (NIST 800-53, FIPS 140-3, FedRAMP, Common Criteria, HIPAA §164.312, SOC 2 TSC, ISO/IEC 27001 Annex A) using "compatible with" framing** *(Phase 2.7 — completed 2026-04-30; SEC-01..06 — see `.planning/phases/02.7-security-posture/`)*
- [x] **Floating recording-state HUD** — translucent lavender pill with `● Recording` text appears at top-center of active screen during press-hold, hidden when idle. Six named positions configurable via `PURPLEVOICE_HUD_POSITION`. Disable via `PURPLEVOICE_HUD_OFF=1`. Honest framing about ScreenCaptureKit screen-recording limitation in README + SECURITY.md (no over-claims about hide-from-recording behaviour) *(Phase 3.5 — completed 2026-04-30; HUD-01..04 — see `.planning/phases/03.5-hover-ui-hud/`)*
- [x] **Quality-of-life hotkeys** — F19 push-and-hold via Karabiner fn-remap (replaces the original cmd+shift+e binding to eliminate the VS Code/Cursor "Show Explorer" collision); F18 re-paste via Karabiner backtick-hold (in-memory `lastTranscript` cache, supersedes the original cmd+shift+v plan after live-walkthrough discovery of an opaque clipboard-manager Carbon RegisterEventHotKey collision). Both hotkeys ship with bundled JSON rule files in `assets/`; `setup.sh` Step 9 refuses to declare install complete without Karabiner-Elements installed *(Phase 4 — completed 2026-05-01; QOL-01 + QOL-NEW-01 — see `.planning/phases/04-quality-of-life-v1-x/`)*

- [x] **Loop hardened** against TCC silent-deny, hallucinations (VAD + denylist), re-entrancy, clipboard manager retention (`org.nspasteboard.TransientType`), AirPods surprises, paste-restore races, WAV leaks (EXIT-trap cleanup) *(Phase 2 — completed 2026-04-28; TRA-04..06, INJ-02..04, FBK-01..03, ROB-01..04 — see `.planning/phases/02-hardening/`)*
- [x] **Public-facing product name** rebrand voice-cc → PurpleVoice + lavender visual identity *(Phase 2.5 — completed 2026-04-29; BRD-01..03 — see `.planning/phases/02.5-branding/`)*
- [x] **Reproducible install** — single canonical `install.sh` (renamed from `setup.sh` in Phase 3) idempotent + curl-vs-clone detection + `bootstrap_clone_then_re_exec` for the curl|bash path; LICENSE (canonical MIT) + uninstall.sh + README D-11/D-12 rewrite (Quickstart-at-top + Detailed Install + 4-item Recovery + Uninstalling) *(Phase 3 — completed 2026-05-04; DST-01..04 — see `.planning/phases/03-distribution-public-install/`)*
- [x] **Public one-line installer** with INSTALL_TOKEN soft-gate (honest framing as request-channel signal, not access control); repo flipped to PUBLIC at github.com/OliverGAllen/purplevoice 2026-05-04 *(Phase 3 — completed 2026-05-04; DST-05, DST-06)*
- [x] **Hyperfine-measured performance** — p50 0.589s / p95 0.605s on 5s.wav (M2 Max, AC power); well within Phase 5 trigger thresholds (~3.4×/6.6× margin) *(Phase 3 — DST-04 completed 2026-05-04)*

### Active

**v2.0 scope: TBD via `/gsd:new-milestone`.** User direction: "turn this into a full on application." See [Next Milestone Goals](#next-milestone-goals) above for the open questions the new-milestone discussion needs to resolve.

### Out of Scope (v1 — to be re-audited for v2)

These are the v1 Out-of-Scope items. The v2 scope decision (in `/gsd:new-milestone`) may **reverse** several of these — Phase 3.5 HUD and Phase 3 Distribution were both reversed in v1 from Out-of-Scope. Items flagged as **v2 candidate** are the most likely reversal targets.

- **TTS / spoken replies** — *v2 candidate*; v1 is text-only to keep scope tight.
- **Voice commands beyond dictation** ("send", "clear", agent-mode meta-commands) — *v2 candidate*; v1 is pure dictation.
- **Project-aware context / per-project hotkeys** — *v2 candidate*; v1 just injects into whatever window is focused.
- **Toggle-to-record mode** — *v2 candidate if a "full app" wants more interaction modes*; v1 is push-and-hold only.
- **Wake word activation** — explicit hotkey only; wake words add false-trigger and always-on mic concerns. Probably stays Out of Scope.
- **Cross-platform support (Linux, Windows)** — *v2 may revisit if "full app" implies broader audience*; v1 is macOS Apple Silicon only.
- **Cloud STT (Whisper API, Deepgram, etc.)** — violates the no-subscriptions / no-limits + privacy-first constraint. **Should stay Out of Scope for v2** unless the project's core value pivots — which it shouldn't.
- **GUI / preferences app** — *v2 candidate if "full app" means native Settings pane*; v1 config lives in dotfiles + env vars + Karabiner JSON. The Phase 3.5 HUD does not count as a settings UI.
- **Hosted backend / sync / telemetry** — directly conflicts with v1 privacy-first core value. **Should stay Out of Scope for v2** unless audience pivot demands it; if so, Oliver should re-audit `Core Value` first.
- **Multi-user / SSO / auth / team management** — currently constrained ("built for one user"). *v2 candidate if the audience pivot to institutional adoption is real.*
- ~~**Distribution to other users** — personal tool first; if it generalises, package later~~ — **REVERSED 2026-04-27 by user**, validated in Phase 3 Public Install (2026-05-04).
- ~~**Public-facing product name (rebrand)**~~ — **REVERSED 2026-04-27 by user**, validated in Phase 2.5 (PurpleVoice, 2026-04-29).
- ~~**Floating recording-state HUD (hideable)**~~ — **REVERSED 2026-04-27 by user**, validated in Phase 3.5 (2026-04-30).

## Context

- **Platform:** macOS on Apple Silicon (M-series). Metal acceleration is the perf unlock — whisper.cpp and mlx-whisper both leverage it and run faster than realtime.
- **Existing toolchain:** Hammerspoon already common for macOS power users — Lua scripting, free, mature, handles global hotkeys + clipboard + AppleScript triggers cleanly.
- **STT landscape:** whisper.cpp (C++, Metal) and mlx-whisper (Apple MLX framework, optimised for Apple Silicon) are the two strong local options. `medium.en` model is the sweet spot for accuracy vs latency on M-series.
- **Audio capture:** sox or ffmpeg can record mic to a temp WAV. ffmpeg is more universally installed; sox is lighter and simpler for this use case.
- **Injection method:** transcript → pbcopy → Hammerspoon simulates `cmd+v` into focused window. Clipboard-based paste is the reliable cross-app method on macOS.
- **Why this exists:** off-the-shelf options (Wispr Flow, SuperWhisper) are subscription-based and limit customisation. This project trades a few hours of setup for permanent ownership and unlimited use.
- **Comparable open-source references:** nerd-dictation (Linux, Vosk-based), whisper-keyboard, Aiko (Mac, free but GUI-only). None hit the exact "Hammerspoon + whisper.cpp + Claude Code injection" niche.

## Constraints

- **Platform**: macOS Apple Silicon only — leverages Metal-accelerated local inference; no x86 fallback path
- **Tech stack**: Hammerspoon (Lua), whisper.cpp or mlx-whisper, sox/ffmpeg, bash glue — no heavy frameworks, no Electron, no Python web server unless strictly necessary
- **Cost**: zero recurring cost — no API subscriptions, no paid services, no usage caps
- **Dependencies**: only well-established open-source tools — nothing hand-rolled or abandoned
- **Performance**: end-to-end latency (release-to-paste) under ~2 seconds for short utterances; acceptable for natural conversational use
- **Permissions**: must work within macOS Accessibility + Microphone TCC permissions; explicit one-time grant on install is acceptable
- **Audience**: built for one user (Oliver). No multi-user, no auth, no settings UI

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| macOS Apple Silicon only | Metal acceleration is the local-STT unlock; cross-platform would dilute focus | — Pending |
| Hammerspoon for hotkey + injection | Mature, free, scriptable in Lua, well-documented, established macOS power-user tool | — Pending |
| Local STT (whisper.cpp or mlx-whisper) | Honours zero-cost / zero-limit constraint; cloud STT is a non-starter | — Pending |
| Push-and-hold trigger only (v1) | Fewest false starts; no recording-state ambiguity; simplest mental model | — Pending |
| Clipboard-paste injection | Reliable across all macOS apps; avoids fragile keystroke simulation | — Pending |
| Text-only v1 (no TTS) | Keeps v1 scope tight; TTS is additive and easy to bolt on later | — Pending |
| Dictation-only v1 (no commands) | Voice commands need parser + state machine; defer until dictation loop is rock-solid | — Pending |
| Quality model profile (Opus) for planning | User wants deep analysis on a foundational personal tool worth getting right | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-27 — Phase 1 validated; roadmap extended with Phase 2.5 Branding, Phase 3 Public Install, Phase 3.5 Hover UI (per user); "Distribution to other users" reversed from Out-of-Scope to Active.*
*Updated: 2026-04-29 — Phase 2.5 Branding closed; PurpleVoice name + broadened privacy-first positioning (6 audience segments) recorded; Phase 2.7 SECURITY.md forward-referenced; BRD-01..03 marked complete.*
*Updated: 2026-04-30 — Phase 2.7 Security Posture & Government Readiness closed; SECURITY.md (751 lines, 18 sections) published as authoritative document substantiating institutional audience claims; SEC-01..06 marked complete; tests/security/ verification suite (5 PASS / 0 FAIL) + real Syft SBOM.spdx.json + PURPLEVOICE_OFFLINE=1 air-gap mode. 4 pre-release human-review items deferred to v1 release-gate (HUMAN-UAT.md).*
*Updated: 2026-04-30 — Phase 3.5 Hover UI / HUD closed; floating lavender translucent pill (alpha 0.70, no backdrop blur, "● Recording" text) wired into onPress / resetState lifecycle in purplevoice-lua/init.lua; six named positions via PURPLEVOICE_HUD_POSITION env var; PURPLEVOICE_HUD_OFF=1 disable; honest D-14 framing about ScreenCaptureKit limitation (does NOT pursue NSWindowSharingNone exclusion) in README + SECURITY.md + REQUIREMENTS.md; HUD-01..04 marked complete; functional suite 10/0; security suite 5/0; 5 manual walkthroughs signed off live by user. DST-06 (Hammerspoon-as-PurpleVoice wrapping decision; A/B/C trade-off) added to Phase 3 backlog per user direction.*
*Updated: 2026-05-01 — Phase 4 Quality of Life closed; QOL-01 (F18 re-paste via Karabiner backtick-hold) + QOL-NEW-01 (F19 push-to-talk via Karabiner fn-remap) marked Complete. Karabiner-Elements added as required runtime dep; setup.sh Step 9 enforces presence with actionable error. Mid-execution deviation: original D-02 cmd+shift+v re-paste superseded by F18-via-backtick-hold after live walkthrough surfaced an opaque clipboard-manager Carbon hotkey collision (no Hammerspoon binding-failed alert; keystroke silently consumed). Functional suite 11/0; security 5/0; brand + framing lints GREEN; Pattern 2 invariants intact. 2 walkthroughs signed off live (F19 5/5, re-paste 3/3); test_setup_karabiner_missing deferred to a deliberate safe break (HUMAN-UAT.md tracked).*
*Updated: 2026-05-04 — Phase 3 Distribution & Public Install closed 5/5 — **PurpleVoice v1 publicly shipping**. Repo flipped PRIVATE → PUBLIC at https://github.com/OliverGAllen/purplevoice (MIT licensed; 118+ commits on origin/main; anonymous curl serves install.sh with HTTP 200). Plan 03-01 (install.sh rename + curl|bash bootstrap + DST-01 walkthrough) + Plan 03-02 (LICENSE + uninstall.sh + README D-11/D-12 rewrite + DST-03 walkthrough) + Plan 03-03 (hyperfine harness + reference WAVs + BENCHMARK.md template; Task 3-5 live walkthrough DEFERRED to BACKLOG#2 per Oliver — harness ready, benchmark execution pending hardware time) + Plan 03-04 (SECURITY.md "Distribution model" H3 + INSTALL_TOKEN soft-gate + public flip + DST-05 walkthrough). DST-01..03, DST-05, DST-06 [x] Complete; DST-04 [ ] Pending/DEFERRED with annotation pointing at BACKLOG#2; v1 coverage 42/43 = 97.7%. Phase 5 trigger verdict stays "Conditional" until DST-04 lands. Plan 03-04 introduced the **INSTALL_TOKEN soft-gate** (SHA256 baked into install.sh; honestly framed in SECURITY.md §"Distribution model — Install gate" as a request-channel signal, not access control — public source means a determined party can read install.sh + remove the gate; purpose is filtering casual installs + creating a "ping Oliver" channel; tokens issued per request to oliver@olivergallen.com). New deviation classes: (a) "destructive walkthrough item run by orchestrator on user's machine — user retains GUI re-grant + post-condition verification authority"; (b) "informational walkthrough findings that validate the documented diagnostic flow are recorded in walkthrough doc + SUMMARY § Live findings, not as plan deviations"; (c) "soft access-control gate on public source — honest framing acknowledges public-readability bypassability; purpose is request-channel norm, not control surface". Phase 4 CHECKPOINT-3 (sudo-mv DEFERRED) precedent applied to DST-04. Suite at close: functional 16/0; security 5/0; brand + framing GREEN; Pattern 2 invariants intact.*

*Last updated: 2026-05-04 after **v1.0 milestone completion**. DST-04 closed same-day on AC-power M2 Max (5s.wav p50/p95 = 0.589/0.605s; Phase 5 trigger DEFERRED — within budget). v1 coverage 43/43 = 100%. Milestone archived to `.planning/milestones/v1.0-{ROADMAP,REQUIREMENTS}.md`. Original `.planning/REQUIREMENTS.md` deleted (fresh one created by `/gsd:new-milestone` for v2). PROJECT.md fully evolved: Active section emptied (v2 scope TBD); v1 requirements moved to Validated; Out of Scope re-audited with v2-candidate flags; Current State + Next Milestone Goals sections added documenting the public release + v2 scope open questions ("turn this into a full on application" — native .app, settings UI, multi-platform, audience pivot, voice commands, TTS, App Store, etc., to be resolved via `/gsd:new-milestone` discussion).*
