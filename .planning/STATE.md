# State: voice-cc

**Last updated:** 2026-04-23

## Project Reference

- **Name:** voice-cc
- **Core value:** Speak → text appears in Claude Code, instantly and reliably, with no recurring cost or external dependency.
- **Current focus:** Roadmap created; awaiting Phase 1 planning.
- **Mode:** yolo
- **Granularity:** standard
- **Parallelization:** enabled

## Current Position

- **Milestone:** v1
- **Phase:** — (none in progress)
- **Plan:** — (none in progress)
- **Status:** Roadmap defined. Ready for `/gsd:plan-phase 1`.

### Progress

```
Phase 1: Spike                            ░░░░░░░░░░  0%   [Not started]
Phase 2: Hardening                        ░░░░░░░░░░  0%   [Not started]
Phase 3: Distribution & Benchmarking      ░░░░░░░░░░  0%   [Not started]
Phase 4 (v1.x): Quality of Life           ░░░░░░░░░░  0%   [Queued]
Phase 5 (v1.1, cond.): Warm-Process       ░░░░░░░░░░  0%   [Conditional on Phase 3]

Overall v1 (Phases 1–3):                  ░░░░░░░░░░  0%
```

## Performance Metrics

| Metric | Target | Current | Source |
|--------|--------|---------|--------|
| End-to-end latency (key release → text appears) | < 2.0 s for short utterance | unmeasured | ROB-05, DST-04 |
| p50 latency (Phase 3 hyperfine) | < 2.0 s | TBD | gates Phase 5 |
| p95 latency (Phase 3 hyperfine) | < 3.0 s | TBD | gates Phase 5 |
| Hallucination paste rate | 0 (caught by VAD + duration gate + denylist) | unmeasured | TRA-04..06 |
| Silent-failure rate on permission denial | 0 (all denials → actionable toast) | unmeasured | FBK-03, ROB-02 |

## Accumulated Context

### Key Decisions

| Decision | Source | Date |
|----------|--------|------|
| One-shot CLI per utterance for v1 (no daemon) | ARCHITECTURE.md | 2026-04-23 |
| whisper.cpp + `ggml-small.en.bin` (Q5_0, ~190 MB) | STACK.md / SUMMARY.md | 2026-04-23 |
| Hammerspoon (Lua) + sox + bash glue + whisper-cli | SUMMARY.md | 2026-04-23 |
| Default hotkey: `cmd+option+space` | PITFALLS.md (avoids Spotlight/Globe/Dictation conflicts) | 2026-04-23 |
| XDG file layout (`~/.config`, `~/.local/share`, `~/.cache`) | ARCHITECTURE.md | 2026-04-23 |
| `transcribe()` is a single bash function (Pattern 2) for v1.1 drop-in swap | ARCHITECTURE.md | 2026-04-23 |
| Exit codes (0/2/3/10/11/12) are the entire bash↔Lua control protocol | ARCHITECTURE.md | 2026-04-23 |
| Build order: manual pipeline → bash glue → Hammerspoon (non-negotiable) | ARCHITECTURE.md | 2026-04-23 |

### Open TODOs (cross-phase)

- [ ] Phase 1: validate Silero VAD is bundled in installed whisper.cpp (`whisper-cli --help | grep -i vad`)
- [ ] Phase 2: spike `hs.pasteboard` multi-type write API for `org.nspasteboard.TransientType`
- [ ] Phase 2: verify current macOS Settings deep-link URL for Microphone privacy pane
- [ ] Phase 2: deliberately revoke mic permission and capture sox stderr fingerprint for TCC detection grep
- [ ] Phase 3: produce hyperfine numbers; explicitly decide go/no-go on Phase 5

### Blockers

(None)

### Recently Validated

(None — ship to validate)

## Session Continuity

### Next Action

Run `/gsd:plan-phase 1` to decompose Phase 1 (Spike) into executable plans.

### Last Session Summary

- Initialized project (PROJECT.md, REQUIREMENTS.md, research bundle: STACK / FEATURES / ARCHITECTURE / PITFALLS / SUMMARY).
- Created ROADMAP.md with 3 v1 phases + 1 v1.x phase + 1 conditional v1.1 phase.
- 26/26 v1 requirements mapped; 0 orphans.

### Files of Record

- `.planning/PROJECT.md` — north star, constraints, decisions
- `.planning/REQUIREMENTS.md` — 26 v1 requirements (CAP/TRA/INJ/FBK/ROB/DST) + 7 v2 requirements (QOL/PERF) + traceability table
- `.planning/ROADMAP.md` — phase structure, success criteria, coverage map
- `.planning/research/SUMMARY.md` — synthesised findings + recommended phase shape
- `.planning/research/ARCHITECTURE.md` — process model, build-order constraints, file layout, exit codes
- `.planning/research/PITFALLS.md` — TCC primer + 10 critical pitfalls with prevention snippets
- `.planning/research/STACK.md` — tech selection rationale
- `.planning/research/FEATURES.md` — competitor analysis, must-have vs differentiator vs anti-feature

---
*State initialized: 2026-04-23 after roadmap creation*
