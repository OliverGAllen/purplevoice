# PurpleVoice

## What This Is

**PurpleVoice** is a local, push-to-talk voice input system for Claude Code on macOS Apple Silicon. Hold a hotkey, speak, release — your transcript appears in the focused Claude Code terminal. Built for individuals and organisations whose privacy requirements rule out cloud-based dictation. Working name was `voice-cc`; renamed during Phase 2.5 (2026-04-29).

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

### Active

- [ ] Loop is robust against TCC silent-deny, hallucinations, re-entrancy, clipboard manager retention *(Phase 2; TRA-04..06, INJ-02..04, FBK-01..03, ROB-01..04)*
- [x] **Public-facing product name (rebrand from working name "voice-cc")** *(Phase 2.5 — completed 2026-04-29; BRD-01..03 — see `.planning/phases/02.5-branding/`)*
- [ ] Setup is reproducible from a single install script / README *(Phase 3; DST-01..04)*
- [ ] **Public one-line installer (`curl ... | bash`) so others can install voice-cc** *(Phase 3 extension — added 2026-04-27; DST-05)*
- [ ] **Small floating recording-state HUD (hideable)** *(Phase 3.5 — added 2026-04-27; HUD-01..04)*

### Out of Scope

- **TTS / spoken replies** — v2 candidate; v1 is text-only to keep scope tight
- **Voice commands beyond dictation** ("send", "clear", agent-mode meta-commands) — v2 candidate; v1 is pure dictation
- **Project-aware context / per-project hotkeys** — v2 candidate; v1 just injects into whatever window is focused
- **Toggle-to-record mode** — push-and-hold only for v1; toggle adds state management complexity
- **Wake word activation** — explicit hotkey only; wake words add false-trigger and always-on mic concerns
- **Cross-platform support (Linux, Windows)** — macOS Apple Silicon only; cross-platform deferred indefinitely
- **Cloud STT (Whisper API, Deepgram, etc.)** — violates the no-subscriptions / no-limits constraint
- **GUI / preferences app** — config lives in dotfiles; no Electron/SwiftUI shell needed (a small floating HUD is in scope per Phase 3.5, but it's not a settings UI)
- ~~**Distribution to other users** — personal tool first; if it generalises, package later~~ — **REVERSED 2026-04-27 by user**: now in scope as Phase 3 Public Install + Phase 2.5 Branding. Phase 1 demonstrably worked, so the case for sharing it has materialised earlier than anticipated.

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
