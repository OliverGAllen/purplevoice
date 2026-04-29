---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: milestone
status: executing
last_updated: "2026-04-29T09:30:00.000Z"
progress:
  total_phases: 5
  completed_phases: 2
  total_plans: 7
  completed_plans: 7
---

# State: voice-cc

**Last updated:** 2026-04-29 (Phase 2.5 context gathered — name `PurpleVoice` locked, privacy-first positioning established as load-bearing differentiator vs Koe/cloud dictation)

## Project Reference

- **Name:** voice-cc *(working name; new product brand TBD in Phase 2.5)*
- **Core value:** Speak → text appears in Claude Code, instantly and reliably, with no recurring cost or external dependency.
- **Current focus:** Phase 02 — hardening
- **Mode:** yolo
- **Granularity:** standard
- **Parallelization:** enabled

## Current Position

Phase: 02.5 (branding) — DISCUSSION COMPLETE, ready for `/gsd:plan-phase 2.5`
Next: Plan Phase 2.5 with the captured context

- **Milestone:** v1
- **Phase:** 02.5 (branding) — context gathered 2026-04-29
- **Plan:** 0/N (not yet planned; CONTEXT.md captures decisions)
- **Status:** Name = `PurpleVoice` (PascalCase brand, lowercase `purplevoice` for module/binary/paths). Privacy-first positioning is the load-bearing differentiator vs Koe (cloud default) / Wispr Flow (subscription) / market broadly. Visual identity locked: lavender `#B388EB` menubar + purple-bg-white-lips 256×256 icon. Tagline: "Local voice dictation. Nothing leaves your Mac." Resumed from 2026-04-28 strategic-decision pause — user chose path A (keep building, position against Koe's cloud default).

### Progress

```
Phase 1: Spike                            ██████████  100% [3/3 plans; user-validated end-to-end 2026-04-27]
Phase 2: Hardening                        ██████████  100% [4/4 plans — Plan 02-03 walkthroughs signed off 2026-04-28]
Phase 2.5: Branding                       ░░░░░░░░░░  0%   [Added 2026-04-27 — needs planning]
Phase 3.5: Hover UI / HUD                 ░░░░░░░░░░  0%   [Added 2026-04-27 — needs planning]
Phase 4 (v1.x): Quality of Life           ░░░░░░░░░░  0%   [Queued]
Phase 3: Distribution + Public Install    ░░░░░░░░░░  0%   [Reordered to end 2026-04-28 per user direction]
Phase 5 (v1.1, cond.): Warm-Process       ░░░░░░░░░░  0%   [Conditional on Phase 3 hyperfine]

Overall v1 (Phases 1, 2, 2.5, 3.5, 4, 3): ████░░░░░░  ~33% (2 of 6 effective v1 phases complete)
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
| Plan 02-00 executor wall-clock | n/a | ~9 min (3 tasks autonomous; setup.sh Silero download + denylist seed; 17 files created) | this session |
| Phase 02 P00 | 9 min | 3 tasks | 18 files |

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
- [x] Phase 2: add `hs.accessibilityState(true)` to voice-cc-lua/init.lua on load — landed in Plan 02-02; verified live in Plan 02-03 Task 3-3 walkthrough.
- [x] Phase 2: add `require("hs.ipc")` to ~/.hammerspoon/init.lua — `.hammerspoon-init-snippet.lua` staged in Plan 02-02; user pasted; `hs -c "1+1"` returns `2`.
- [x] Phase 2: suppress whisper-cli's sibling `.txt` output — Plan 02-01 added `--no-prints` to the `transcribe()` call; `/tmp/voice-cc/recording.txt` no longer leaked.
- [ ] Phase 2 follow-up: vocab A/B comparison — deferred (not gating).
- [x] Phase 2: spike `hs.pasteboard` multi-type write API for `org.nspasteboard.TransientType` — implemented in Plan 02-02 (`hs.pasteboard.writeAllData` with TransientType + ConcealedType UTIs).
- [x] Phase 2: verify current macOS Settings deep-link URL for Microphone privacy pane — verified live 2026-04-28; Hammerspoon's `hs.urlevent.openURL` requires `://` (deviation captured in 02-03-SUMMARY.md).
- [x] Phase 2: capture sox stderr fingerprint on TCC denial — captured live 2026-04-28; **regex assumption was wrong on Sequoia** (silent stream, not stderr error); detection switched to amplitude-based. See 02-03-SUMMARY.md.
- [x] Phase 2: source Silero VAD model weights — handled in Plan 02-00 (setup.sh Step 5b downloads `ggml-silero-v6.2.0.bin`; idempotent, sanity-checked).
- [ ] Phase 2 follow-up: replace `tests/test_tcc_grep.sh` with an amplitude-detection test (current test exercises the fallback regex only; the live path is amplitude-based).
- [ ] Phase 2 follow-up: run the 4 manual walkthroughs that were staged but not executed (test_clipboard_restore.md, test_transient_marker.md, test_menubar.md, test_audio_cues.md, test_reentrancy.md). Code review currently covers them.
- [ ] Phase 4 candidate: alternative hotkey schemes — fn-press-and-hold via `hs.eventtap` flagsChanged (races against macOS emoji popup; needs hold-threshold logic), Karabiner-remap-fn-to-F19 path. User-surfaced 2026-04-28.
- [ ] Phase 3: produce hyperfine numbers; explicitly decide go/no-go on Phase 5

### Blockers

(None)

### Recently Validated

- Plan 02-03 (2026-04-28): voice-cc-lua/init.lua final form (315 lines) — full `hs.notify` dispatch for exit codes 10 / 11 / 12 + System Settings deep links + 60s notifyOnce dedup + defence-in-depth Accessibility-deny notification. Both manual checkpoints signed off live by user ("approved"). Three coupled regressions fixed inline (commit 81334ce): (a) SOX_SIGNALED flag distinguishes trap-induced sox exit from real failure, (b) Sequoia silent-stream amplitude detection replaces dead stderr-fingerprint, (c) deep-link URLs use `://` instead of bare `:` for Hammerspoon's openURL API. All 6 bash unit tests still GREEN. Pattern 2 boundary preserved. Commits: 8b32e45 (Task 3-1 dispatcher), 81334ce (3 deviations fix). See 02-03-SUMMARY.md.
- Plan 02-02 (2026-04-28): voice-cc-lua/init.lua hardened (82 → 208 lines). Menubar indicator + audio cues + clipboard preserve/restore with TransientType UTI + re-entrancy guard + handleExit stub + hs.accessibilityState(true) on load. `.hammerspoon-init-snippet.lua` staged for `require("hs.ipc")`; user pasted; IPC working. FBK-01, FBK-02, INJ-02, INJ-03, ROB-01 closed. Phase-1 TODOs (a) and (b) closed. Commits: f4da016, deee0fe.
- Plan 02-01 (2026-04-28): voice-cc-record hardened. VAD + duration gate + denylist exact-match + EXIT trap + TCC stderr fingerprint (later superseded by Plan 02-03's amplitude detection on Sequoia) + semantic exit codes 2/3/10/11/12. Phase-1 TODO (c) closed via `--no-prints`. Commits: 47193f0, 691f030. **Note: subsequently patched in commit 81334ce** for the `wait`-pattern regression that broke every normal hotkey release on Sequoia.
- Plan 02-00 (2026-04-28): Wave 0 test infra. 17 files created: tests/run_all.sh (suite runner), tests/lib/sample_audio.sh (4 WAV-synthesis helpers incl. medium_wav for SIGINT path), 6 unit/integration tests (test_duration_gate/denylist/vad_silence/tcc_grep/wav_cleanup/sigint_cleanup), 7 manual walkthroughs (test_clipboard_restore/transient_marker/menubar/audio_cues/tcc_notification/reentrancy/accessibility_prompt), config/denylist.txt (19 phrases). setup.sh extended with Step 5b (Silero VAD download) + Step 6b (denylist install) — both idempotent. Pattern 2 boundary preserved. Commits: b899c28, 01e6429, ed32ad2.
- Plan 01-01 (2026-04-27): setup.sh idempotent, model SHA256 verified, Hammerspoon + sox + whisper-cli installed, XDG layout + vocab seed in place. Manual pipeline test deferred to Plan 01-03 walkthrough per user.
- Plan 01-02 (2026-04-27): voice-cc-record bash glue written + symlinked into ~/.local/bin/. transcribe() Pattern 2 boundary discipline confirmed (grep -c WHISPER_BIN == 2). All 16 plan automated-verify clauses pass. Manual invocation Task 2 deferred to Plan 01-03 walkthrough per user (precedent: Plan 01-01 Task 3 deferral).
- Plan 01-03 (2026-04-27): voice-cc-lua/init.lua written (82 lines) + symlinked into ~/.hammerspoon/voice-cc/ + minimal ~/.hammerspoon/init.lua written fresh (D-02 honoured — no prior content). End-to-end walkthrough: user approved after 4 PASS criteria + 1 SKIPPED-BUT-NOT-GATING (Criterion #4 vocab A/B explicitly skipped by user). Phase 1 spike loop demonstrably works end-to-end. Three Phase 2 candidates surfaced (hs.accessibilityState, hs.ipc, suppress whisper sibling .txt) — all logged in Open TODOs.

## Session Continuity

### Next Action

Phase 2.5 context captured. Run `/gsd:plan-phase 2.5` to break the rebrand into atomic plans (likely shape: Plan 02.5-01 string propagation in `voice-cc-record` + `voice-cc-lua/init.lua` + `setup.sh` + `.hammerspoon-init-snippet.lua`; Plan 02.5-02 XDG path rename + setup.sh idempotent migration; Plan 02.5-03 visual identity — menubar lavender colour + 256×256 PNG icon asset; Plan 02.5-04 README header + tagline placement + REQUIREMENTS.md BRD-01..03 elaboration).

After 2.5: Phase 3.5 (HUD), Phase 4 (QoL), Phase 3 (Distribution + hyperfine + public install), Phase 5 (Warm-Process, conditional).

### Stopped At

Phase 2.5 discuss-phase complete. CONTEXT.md + DISCUSSION-LOG.md committed at `a34dcdb`. No code changes yet — implementation begins with `/gsd:plan-phase 2.5`.

Local environment: Hammerspoon restored (~/.hammerspoon/init.lua requires uncommented; Hammerspoon launched; Accessibility = true; cmd+shift+e bound). voice-cc dictation loop is functional under the placeholder name; rename ships in Plan 02.5-* execution.

User intent stated: proceed to plan 2.5 next.

### Last Session Summary

- Plan 02-00 executed (autonomous, Wave 1, no checkpoints, ~9 min wall-clock):
  - Task 0-1 (commit `b899c28`): tests/run_all.sh (39 lines, exec) iterates tests/test_*.sh, captures pass/fail, exits 0 only if all pass; tests/lib/sample_audio.sh (44 lines, sourced) exposes silence_wav / tone_wav / short_tap_wav / medium_wav helpers. Empty suite handled cleanly (exit 0).
  - Task 0-2 (commit `01e6429`): 6 unit/integration tests written. test_duration_gate uses the EXACT awk float-compare predicate Plan 02-01 must use. test_denylist encodes the EXACT canonicalisation pipeline. test_vad_silence runs whisper-cli with --vad/--vad-model on synthesised silence. test_tcc_grep uses the EXACT fingerprint regex (positive + negative). test_wav_cleanup + test_sigint_cleanup use VOICE_CC_TEST_SKIP_SOX hook (Plan 02-01 dependency); sigint test uses medium_wav (1s) so duration gate is cleared and SIGINT path is genuinely exercised.
  - Task 0-3 (commit `ed32ad2`): config/denylist.txt seeded with 19 canonical phrases. setup.sh extended with Step 5b (Silero VAD download, idempotent, size-sanity-check ≥ 800,000 bytes) + Step 6b (denylist always-overwrite copy). 7 manual walkthrough .md files (clipboard_restore, transient_marker, menubar, audio_cues, tcc_notification, reentrancy, accessibility_prompt) — all self-contained, ~30-50 lines each, with sign-off checklists. Ran setup.sh: Silero downloaded (885,098 bytes) + denylist installed. Idempotent on second run.
  - Suite final state: 4 PASS / 2 RED-and-expected. RED tests (test_wav_cleanup, test_sigint_cleanup) fast-fail with explicit "Plan 02-01 not yet implemented" message.
  - Pattern 2 boundary preserved (voice-cc-record unchanged in Wave 0).
  - 02-00-SUMMARY.md authored at .planning/phases/02-hardening/02-00-SUMMARY.md with full file inventory, RED test inventory, setup.sh diff summary, host state table, deviations (none), readiness signals for Plans 02-01/02-02/02-03.
  - Self-check PASSED (all 18 expected files exist, all 3 commits exist).

#### Prior session

- Plan 01-03 executed: voice-cc-lua/init.lua (82 lines, Lua) created in repo root; symlinked from ~/.hammerspoon/voice-cc/ → repo `voice-cc-lua/`; ~/.hammerspoon/init.lua written fresh (3 lines, contains `require("voice-cc")`) — D-02 verified no prior content existed. Hammerspoon launched and module loaded (`voice-cc loaded (cmd+shift+e)` alert observed). Committed by prior executor at `0fbbcc0`.
- End-to-end walkthrough (Task 2, `checkpoint:human-verify`): user approved verbatim ("approved") after a two-stage diagnostic walkthrough.
  - First test (Microphone granted, Accessibility not yet granted): bash glue + sox + whisper-cli all worked end-to-end. WAV captured (`/tmp/voice-cc/recording.wav`, ~43 KB), transcript "Hello, hello, hello." reached the clipboard, but auto-paste was a silent no-op (eventtap blocked by missing Accessibility — clipboard had right content, nothing pasted).
  - User diagnosed inline (clipboard correct → eventtap is the gated API → Accessibility), navigated to System Settings → Privacy & Security → Accessibility, granted Hammerspoon access.
  - Second test (after Accessibility granted): full end-to-end success including auto-paste. User confirmed "yes, that works".
- Walkthrough verdict: 4 PASS (#1 end-to-end loop, #2 manual invocation parity implicit, #3 native punctuation/capitalisation inferred, #5 absolute paths) + 1 SKIPPED-BUT-NOT-GATING (#4 vocab A/B, explicitly skipped by user).
- Three Phase 2 candidates surfaced: (a) `hs.accessibilityState(true)` to deterministically surface Accessibility prompt on first run, (b) `require("hs.ipc")` to enable scripted reload + the `hs` CLI tool (currently errors "can't access Hammerspoon message port"), (c) suppress whisper-cli's sibling `.txt` output (`/tmp/voice-cc/recording.txt` left after every run). All logged in Open TODOs.
- Continuation agent authored 01-03-SUMMARY.md with full walkthrough evidence + quirks captured. STATE.md, ROADMAP.md (per-plan checkbox), REQUIREMENTS.md (CAP-01, INJ-01, ROB-05) updated. Phase 1 awaiting orchestrator-side verifier.

#### Older session

- Plan 01-02 executed: voice-cc-record (79 lines, bash strict mode, executable) created in repo root; symlinked into ~/.local/bin/voice-cc-record (committed in `b6dbf74`).
- transcribe() function isolates the SOLE whisper-cli invocation (Pattern 2 / v1.1 swap site). Absolute /opt/homebrew/bin/* paths used (Pitfall 2 / ROB-03). --language en + --prompt vocab.txt passed (Pitfall 4 + TRA-03). SIGTERM/SIGINT trap forwards to sox PID for clean WAV finalisation (CAP-04).
- Auto-fix (Rule 1): plan template's two `denylist` literal occurrences in comments contradicted the plan's own `! grep -q denylist` automated-verify clause; replaced with "hallucination filter" (functionality unchanged).
- User directive: Plan 01-02 Task 2 (manual `~/.local/bin/voice-cc-record` invocation + reference-utterance transcript test) deferred (not skipped) to Plan 01-03 end-to-end walkthrough — same precedent as Plan 01-01 Task 3.
- 01-02-SUMMARY.md authored with full deviation audit trail and Pattern 2 boundary confirmation.

#### Earliest session

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
