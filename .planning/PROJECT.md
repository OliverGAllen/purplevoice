# voice-cc

## What This Is

A local, push-to-talk voice input system for Claude Code on macOS. Hold a hotkey, speak, release — your transcript appears in the focused Claude Code terminal. Built for one user (Oliver) who wants hands-on-keyboard speed without typing fatigue, with zero subscriptions, zero rate limits, and full ownership of the stack.

## Core Value

**Speak → text appears in Claude Code, instantly and reliably, with no recurring cost or external dependency.**

If everything else fails, this single loop must work: hold key → talk → release → accurate transcript pasted into the focused terminal window.

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
- [ ] **Public-facing product name (rebrand from working name "voice-cc")** *(Phase 2.5 — added 2026-04-27; BRD-01..03)*
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
