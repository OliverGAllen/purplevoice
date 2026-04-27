---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: milestone
status: executing
last_updated: "2026-04-27T08:33:56Z"
progress:
  total_phases: 3
  completed_phases: 0
  total_plans: 3
  completed_plans: 2
---

# State: voice-cc

**Last updated:** 2026-04-27

## Project Reference

- **Name:** voice-cc
- **Core value:** Speak → text appears in Claude Code, instantly and reliably, with no recurring cost or external dependency.
- **Current focus:** Phase 01 — spike
- **Mode:** yolo
- **Granularity:** standard
- **Parallelization:** enabled

## Current Position

Phase: 01 (spike) — EXECUTING
Plan: 3 of 3 (next)

- **Milestone:** v1
- **Phase:** 01 (spike) — in progress
- **Plan:** 01-03 (Hammerspoon wiring) — next up (Wave 3)
- **Status:** Plans 01-01 and 01-02 complete (Task 2 of each deferred to Plan 01-03 end-to-end walkthrough); ready for Wave 3 (Plan 01-03)

### Progress

```
Phase 1: Spike                            ███████░░░  67%  [2/3 plans complete; Plan 01-03 next]
Phase 2: Hardening                        ░░░░░░░░░░  0%   [Not started]
Phase 3: Distribution & Benchmarking      ░░░░░░░░░░  0%   [Not started]
Phase 4 (v1.x): Quality of Life           ░░░░░░░░░░  0%   [Queued]
Phase 5 (v1.1, cond.): Warm-Process       ░░░░░░░░░░  0%   [Conditional on Phase 3]

Overall v1 (Phases 1–3):                  ██░░░░░░░░  22%
```

## Performance Metrics

| Metric | Target | Current | Source |
|--------|--------|---------|--------|
| End-to-end latency (key release → text appears) | < 2.0 s for short utterance | unmeasured | ROB-05, DST-04 |
| p50 latency (Phase 3 hyperfine) | < 2.0 s | TBD | gates Phase 5 |
| p95 latency (Phase 3 hyperfine) | < 3.0 s | TBD | gates Phase 5 |
| Hallucination paste rate | 0 (caught by VAD + duration gate + denylist) | unmeasured | TRA-04..06 |
| Silent-failure rate on permission denial | 0 (all denials → actionable toast) | unmeasured | FBK-03, ROB-02 |
| Plan 01-02 executor wall-clock | n/a | ~12 min (Task 1 only; Task 2 deferred) | this session |

## Accumulated Context

### Key Decisions

| Decision | Source | Date |
|----------|--------|------|
| One-shot CLI per utterance for v1 (no daemon) | ARCHITECTURE.md | 2026-04-23 |
| whisper.cpp + `ggml-small.en.bin` (Q5_0, ~190 MB) | STACK.md / SUMMARY.md | 2026-04-23 |
| Hammerspoon (Lua) + sox + bash glue + whisper-cli | SUMMARY.md | 2026-04-23 |
| Default hotkey: `cmd+shift+e` (changed from the original combo (cmd then option then the space bar) by user) | User decision 2026-04-27 during Plan 01-01 execution; VS Code/Cursor "Show Explorer" conflict accepted | 2026-04-27 |
| XDG file layout (`~/.config`, `~/.local/share`, `~/.cache`) | ARCHITECTURE.md | 2026-04-23 |
| `transcribe()` is a single bash function (Pattern 2) for v1.1 drop-in swap | ARCHITECTURE.md | 2026-04-23 |
| Exit codes (0/2/3/10/11/12) are the entire bash↔Lua control protocol | ARCHITECTURE.md | 2026-04-23 |
| Build order: manual pipeline → bash glue → Hammerspoon (non-negotiable) | ARCHITECTURE.md | 2026-04-23 |
| `transcribe()` Pattern 2 boundary discipline confirmed in voice-cc-record (grep -c WHISPER_BIN == 2 — single assignment + single use inside transcribe()); Phase 5 v1.1 warm-process upgrade is now a one-function-body swap | Plan 01-02 execution | 2026-04-27 |
| Plan 01-02 Task 2 (manual `voice-cc-record` invocation checkpoint) deferred to Plan 01-03 end-to-end walkthrough; matches Plan 01-01 Task 3 deferral precedent | User directive 2026-04-27 during Plan 01-02 execution | 2026-04-27 |

### Open TODOs (cross-phase)

- [x] Phase 1: validate Silero VAD is bundled in installed whisper.cpp — VAD flags exposed by brew bottle (`--vad`, `--vad-model`, etc.) but `--vad-model` default is empty; Phase 2 must source Silero weights separately. See 01-01-SUMMARY.md "VAD Audit Result".
- [ ] Phase 1: end-to-end manual walkthrough of the 5 ROADMAP success criteria (consolidates the deferred Plan 01-01 Task 3 pipeline-isolation test) — happens in Plan 01-03 Task 2.
- [ ] Phase 2: spike `hs.pasteboard` multi-type write API for `org.nspasteboard.TransientType`
- [ ] Phase 2: verify current macOS Settings deep-link URL for Microphone privacy pane
- [ ] Phase 2: deliberately revoke mic permission and capture sox stderr fingerprint for TCC detection grep
- [ ] Phase 2: source Silero VAD model weights (or pin a brew bottle version that bundles them, or source-build whisper.cpp with VAD vendored) — surfaced by Plan 01-01 VAD audit
- [ ] Phase 3: produce hyperfine numbers; explicitly decide go/no-go on Phase 5

### Blockers

(None)

### Recently Validated

- Plan 01-01 (2026-04-27): setup.sh idempotent, model SHA256 verified, Hammerspoon + sox + whisper-cli installed, XDG layout + vocab seed in place. Manual pipeline test deferred to Plan 01-03 walkthrough per user.
- Plan 01-02 (2026-04-27): voice-cc-record bash glue written + symlinked into ~/.local/bin/. transcribe() Pattern 2 boundary discipline confirmed (grep -c WHISPER_BIN == 2). All 16 plan automated-verify clauses pass. Manual invocation Task 2 deferred to Plan 01-03 walkthrough per user (precedent: Plan 01-01 Task 3 deferral).

## Session Continuity

### Next Action

Run Plan 01-03 (Wave 3 — Hammerspoon wiring: hotkey + hs.task spawn + clipboard + cmd+v paste). Wave dependency satisfied: bash glue contract in place (~/.local/bin/voice-cc-record honours spawn + SIGTERM + stdout-transcript semantics). Plan 01-03 Task 2 (end-to-end walkthrough) will also exercise the deferred Plan 01-01 Task 3 and Plan 01-02 Task 2 manual-verification work.

### Stopped At

Completed Plan 01-02 (`.planning/phases/01-spike/01-02-PLAN.md`). Task 2 of that plan deferred to Plan 01-03 Task 2 per user directive (consolidated end-to-end walkthrough). voice-cc-record committed at `b6dbf74`. Ready for Plan 01-03 executor.

### Last Session Summary

- Plan 01-02 executed: voice-cc-record (79 lines, bash strict mode, executable) created in repo root; symlinked into ~/.local/bin/voice-cc-record (committed in `b6dbf74`).
- transcribe() function isolates the SOLE whisper-cli invocation (Pattern 2 / v1.1 swap site). Absolute /opt/homebrew/bin/* paths used (Pitfall 2 / ROB-03). --language en + --prompt vocab.txt passed (Pitfall 4 + TRA-03). SIGTERM/SIGINT trap forwards to sox PID for clean WAV finalisation (CAP-04).
- Auto-fix (Rule 1): plan template's two `denylist` literal occurrences in comments contradicted the plan's own `! grep -q denylist` automated-verify clause; replaced with "hallucination filter" (functionality unchanged).
- User directive: Plan 01-02 Task 2 (manual `~/.local/bin/voice-cc-record` invocation + reference-utterance transcript test) deferred (not skipped) to Plan 01-03 end-to-end walkthrough — same precedent as Plan 01-01 Task 3.
- 01-02-SUMMARY.md authored with full deviation audit trail and Pattern 2 boundary confirmation.

#### Prior session

- Plan 01-01 executed: setup.sh + vocab seed + .gitignore + README stub created and committed (`ccf34c2`); MODEL_SHA256 corrected mid-execution (`8b7e4d0`); setup.sh proven idempotent on re-run; VAD audit completed (flags present, model weights absent — Phase 2 follow-up logged).
- User directive: hotkey changed from the original three-key combo to `cmd+shift+e`; updated across README + REQUIREMENTS + ROADMAP + CONTEXT + 01-01-PLAN + 01-03-PLAN + all 4 research docs (`7030eee`).
- User directive: Plan 01-01 Task 3 manual pipeline test deferred (not skipped) to Plan 01-03 end-to-end walkthrough.
- 01-01-SUMMARY.md authored with full deviation audit trail.

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
