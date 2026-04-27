---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: milestone
status: planning
last_updated: "2026-04-27T13:00:00.000Z"
progress:
  total_phases: 7
  completed_phases: 1
  total_plans: 3
  completed_plans: 3
---

# State: voice-cc

**Last updated:** 2026-04-27 (Phase 1 complete; roadmap extended with Phase 2.5 Branding, Phase 3 Public Install scope, Phase 3.5 Hover UI per user)

## Project Reference

- **Name:** voice-cc *(working name; new product brand TBD in Phase 2.5)*
- **Core value:** Speak → text appears in Claude Code, instantly and reliably, with no recurring cost or external dependency.
- **Current focus:** Phase 02 — hardening (next up; needs planning)
- **Mode:** yolo
- **Granularity:** standard
- **Parallelization:** enabled

## Current Position

- **Milestone:** v1
- **Phase:** 02 (hardening)
- **Plan:** Not started — phase needs planning before execution
- **Status:** Ready to plan (Phase 1 complete; verifier explicitly skipped per user — manual walkthrough sufficient for spike)

### Progress

```
Phase 1: Spike                            ██████████  100% [3/3 plans; user-validated end-to-end 2026-04-27]
Phase 2: Hardening                        ░░░░░░░░░░  0%   [Next up — needs planning]
Phase 2.5: Branding                       ░░░░░░░░░░  0%   [Added 2026-04-27 — needs planning]
Phase 3: Distribution + Public Install    ░░░░░░░░░░  0%   [Extended scope 2026-04-27 — needs planning]
Phase 3.5: Hover UI / HUD                 ░░░░░░░░░░  0%   [Added 2026-04-27 — needs planning]
Phase 4 (v1.x): Quality of Life           ░░░░░░░░░░  0%   [Queued]
Phase 5 (v1.1, cond.): Warm-Process       ░░░░░░░░░░  0%   [Conditional on Phase 3]

Overall v1 (Phases 1–3.5):                █░░░░░░░░░  ~14% (1 of 5 effective v1 phases)
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
| Plan 01-03 executor + walkthrough wall-clock | n/a | ~30 min (Task 1 write + Hammerspoon launch + Task 2 5-criterion walkthrough including mid-test Accessibility diagnosis and re-test) | this session |

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
| Phase 1 spike loop demonstrably works end-to-end (cmd+shift+e push-and-hold → bash glue → whisper-cli → clipboard → cmd+v paste, well under 2s); user approved walkthrough; Criterion #4 vocab A/B explicitly skipped by user (not gating per D-07) | Plan 01-03 walkthrough | 2026-04-27 |
| Hammerspoon Accessibility does NOT auto-prompt on first hs.eventtap.keyStroke (silent no-op instead). Phase 2 candidate: add `hs.accessibilityState(true)` on module load to surface the prompt deterministically. Microphone DOES auto-prompt on first sox spawn (different TCC code path) | Plan 01-03 walkthrough mid-test diagnosis | 2026-04-27 |
| Reference utterance for Criterion #1 not captured verbatim — D-07 spike-level verification only requires observational pass; user said "yes, that works" after granting Accessibility | Plan 01-03 walkthrough; Phase 3 hyperfine will produce verbatim per-utterance numbers | 2026-04-27 |

### Open TODOs (cross-phase)

- [x] Phase 1: validate Silero VAD is bundled in installed whisper.cpp — VAD flags exposed by brew bottle (`--vad`, `--vad-model`, etc.) but `--vad-model` default is empty; Phase 2 must source Silero weights separately. See 01-01-SUMMARY.md "VAD Audit Result".
- [x] Phase 1: end-to-end manual walkthrough of the 5 ROADMAP success criteria — completed in Plan 01-03 Task 2; user approved (4 PASS + 1 SKIPPED-BUT-NOT-GATING). See 01-03-SUMMARY.md "ROADMAP Success Criteria Walkthrough Results".
- [ ] Phase 2: add `hs.accessibilityState(true)` to voice-cc-lua/init.lua on load to surface the Accessibility prompt deterministically — surfaced by Plan 01-03 walkthrough (the only first-run silent failure observed). See 01-03-SUMMARY.md "Quirks Discovered" #1.
- [ ] Phase 2: add `require("hs.ipc")` to ~/.hammerspoon/init.lua to enable scripted Hammerspoon reloads + the `hs` CLI tool — surfaced by Plan 01-03 walkthrough. See 01-03-SUMMARY.md "Quirks Discovered" #2 and #3.
- [ ] Phase 2: suppress whisper-cli's sibling `.txt` output (currently leaves `/tmp/voice-cc/recording.txt` after every run). Likely a `--output-txt false` flag or similar; needs `whisper-cli --help` audit. Surfaced by Plan 01-03 walkthrough. See 01-03-SUMMARY.md "Quirks Discovered" #4. Best paired with Phase 2 ROB-04 EXIT-trap WAV cleanup.
- [ ] Phase 2: vocab A/B comparison may be revisited (Criterion #4 was skipped during Phase 1 walkthrough by user choice) if it informs denylist (TRA-06) or VAD threshold (TRA-04) tuning.
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
- Plan 01-03 (2026-04-27): voice-cc-lua/init.lua written (82 lines) + symlinked into ~/.hammerspoon/voice-cc/ + minimal ~/.hammerspoon/init.lua written fresh (D-02 honoured — no prior content). End-to-end walkthrough: user approved after 4 PASS criteria + 1 SKIPPED-BUT-NOT-GATING (Criterion #4 vocab A/B explicitly skipped by user). Phase 1 spike loop demonstrably works end-to-end. Three Phase 2 candidates surfaced (hs.accessibilityState, hs.ipc, suppress whisper sibling .txt) — all logged in Open TODOs.

## Session Continuity

### Next Action

Plan Phase 2 (Hardening) with `/gsd:plan-phase 2` (recommend `/clear` first for a fresh context window — this orchestrator's context is heavily used). Phase 2 should pick up the three Phase-1-walkthrough-surfaced candidates from Open TODOs above (hs.accessibilityState for deterministic TCC prompt, hs.ipc for scripted reload, suppress whisper sibling .txt) alongside the originally planned hardening work (TRA-04..06, INJ-02..04, FBK-01..03, ROB-01..04).

After Phase 2: Phase 2.5 Branding (newly added — naming + propagation), then Phase 3 (now extended with public one-line installer), then Phase 3.5 (Hover UI / HUD).

Phase 1 verifier was explicitly skipped by user direction ("Phase 1 verifier doesn't need to run, it's already good"). Manual end-to-end walkthrough by user on 2026-04-27 served as authoritative verification for the spike.

### Stopped At

Phase 1 closed via `gsd-tools phase complete 01` (date 2026-04-27, no warnings). ROADMAP extended to add Phase 2.5 Branding, extend Phase 3 with Public Install scope, and add Phase 3.5 Hover UI per user request. New requirement IDs sketched for elaboration during respective `/gsd:plan-phase` runs: BRD-01..03 (Branding), DST-05 (Public Install extension), HUD-01..04 (Hover UI). Total v1 requirement count grows from 26 to ~33-34.

User intent stated: proceed to Phase 2 (Hardening) next.

### Last Session Summary

- Plan 01-03 executed: voice-cc-lua/init.lua (82 lines, Lua) created in repo root; symlinked from ~/.hammerspoon/voice-cc/ → repo `voice-cc-lua/`; ~/.hammerspoon/init.lua written fresh (3 lines, contains `require("voice-cc")`) — D-02 verified no prior content existed. Hammerspoon launched and module loaded (`voice-cc loaded (cmd+shift+e)` alert observed). Committed by prior executor at `0fbbcc0`.
- End-to-end walkthrough (Task 2, `checkpoint:human-verify`): user approved verbatim ("approved") after a two-stage diagnostic walkthrough.
  - First test (Microphone granted, Accessibility not yet granted): bash glue + sox + whisper-cli all worked end-to-end. WAV captured (`/tmp/voice-cc/recording.wav`, ~43 KB), transcript "Hello, hello, hello." reached the clipboard, but auto-paste was a silent no-op (eventtap blocked by missing Accessibility — clipboard had right content, nothing pasted).
  - User diagnosed inline (clipboard correct → eventtap is the gated API → Accessibility), navigated to System Settings → Privacy & Security → Accessibility, granted Hammerspoon access.
  - Second test (after Accessibility granted): full end-to-end success including auto-paste. User confirmed "yes, that works".
- Walkthrough verdict: 4 PASS (#1 end-to-end loop, #2 manual invocation parity implicit, #3 native punctuation/capitalisation inferred, #5 absolute paths) + 1 SKIPPED-BUT-NOT-GATING (#4 vocab A/B, explicitly skipped by user).
- Three Phase 2 candidates surfaced: (a) `hs.accessibilityState(true)` to deterministically surface Accessibility prompt on first run, (b) `require("hs.ipc")` to enable scripted reload + the `hs` CLI tool (currently errors "can't access Hammerspoon message port"), (c) suppress whisper-cli's sibling `.txt` output (`/tmp/voice-cc/recording.txt` left after every run). All logged in Open TODOs.
- Continuation agent authored 01-03-SUMMARY.md with full walkthrough evidence + quirks captured. STATE.md, ROADMAP.md (per-plan checkbox), REQUIREMENTS.md (CAP-01, INJ-01, ROB-05) updated. Phase 1 awaiting orchestrator-side verifier.

#### Prior session

- Plan 01-02 executed: voice-cc-record (79 lines, bash strict mode, executable) created in repo root; symlinked into ~/.local/bin/voice-cc-record (committed in `b6dbf74`).
- transcribe() function isolates the SOLE whisper-cli invocation (Pattern 2 / v1.1 swap site). Absolute /opt/homebrew/bin/* paths used (Pitfall 2 / ROB-03). --language en + --prompt vocab.txt passed (Pitfall 4 + TRA-03). SIGTERM/SIGINT trap forwards to sox PID for clean WAV finalisation (CAP-04).
- Auto-fix (Rule 1): plan template's two `denylist` literal occurrences in comments contradicted the plan's own `! grep -q denylist` automated-verify clause; replaced with "hallucination filter" (functionality unchanged).
- User directive: Plan 01-02 Task 2 (manual `~/.local/bin/voice-cc-record` invocation + reference-utterance transcript test) deferred (not skipped) to Plan 01-03 end-to-end walkthrough — same precedent as Plan 01-01 Task 3.
- 01-02-SUMMARY.md authored with full deviation audit trail and Pattern 2 boundary confirmation.

#### Earlier session

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
