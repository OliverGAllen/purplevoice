---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: milestone
status: executing
last_updated: "2026-04-29T06:55:33.404Z"
progress:
  total_phases: 6
  completed_phases: 2
  total_plans: 11
  completed_plans: 10
---

# State: voice-cc

**Last updated:** 2026-04-29 (Plan 02.5-02 complete in parallel with Plan 02.5-03 — XDG path rename + idempotent setup.sh migration block + symlink hygiene; live-migrated Oliver's machine 466 MB models from voice-cc → purplevoice; both stale symlinks removed; both new symlinks resolve; 6 bash tests still GREEN; Pattern 2 invariant intact; touched zero Lua files per Wave 2 race elimination)

## Project Reference

- **Name:** voice-cc *(working name; new product brand TBD in Phase 2.5)*
- **Core value:** Speak → text appears in Claude Code, instantly and reliably, with no recurring cost or external dependency.
- **Current focus:** Phase 02.5 — branding
- **Mode:** yolo
- **Granularity:** standard
- **Parallelization:** enabled

## Current Position

Phase: 02.5 (branding) — EXECUTING
Plan: 4 of 4 (Wave 3 — final plan)
Next: Plan 02.5-04 (PROJECT.md positioning paragraph + REQUIREMENTS.md BRD-01..03 elaboration + README expansion + tests/test_brand_consistency.sh regression catch). All upstream dependencies stabilized: setup.sh + symlinks (Plan 02), assets/* + menubar lavender (Plan 03), bash glue + Lua identifiers (Plan 01).

- **Milestone:** v1
- **Phase:** 02.5 (branding) — Plans 01, 02, 03 complete 2026-04-29 (Wave 1 + Wave 2 parallel)
- **Plan:** 3/4 complete
- **Status:** Executing Phase 02.5 — Wave 2 complete, Wave 3 unblocked

### Progress

```
Phase 1: Spike                            ██████████  100% [3/3 plans; user-validated end-to-end 2026-04-27]
Phase 2: Hardening                        ██████████  100% [4/4 plans — Plan 02-03 walkthroughs signed off 2026-04-28]
Phase 2.5: Branding                       ████████░░  75%  [3/4 plans — Plan 02.5-01 (string propagation) + Plan 02.5-02 (XDG migration) + Plan 02.5-03 (visual identity) complete 2026-04-29; Plan 02.5-04 (docs closure) is final Wave 3]
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
| Plan 02.5-01 executor wall-clock | n/a | ~8 min (2 tasks autonomous; voice-cc → PurpleVoice rebrand of bash glue + Lua module + snippet + 6 tests + 7 manual walkthroughs; Pattern 2 invariant preserved; cache-path edit consolidated from Plan 02 per checker iter 1; 4 Rule 1 deviations auto-fixed) | this session |
| Phase 02.5 P03 | 3min | 2 tasks | 5 files |
| Phase 02.5 P02 | 5m 47s | 2 tasks | 9 files |

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
| Hard env-var rename (VOICE_CC_* → PURPLEVOICE_*) with no fallback shim — personal-tool ethos, single user, no shell-rc references observed; documented as breaking change in 02.5-01-SUMMARY.md | Plan 02.5-01 execution per RESEARCH §State of the Art Q1 | 2026-04-29 |
| Cache-path edit (~/.cache/voice-cc → ~/.cache/purplevoice in init.lua exit-12 informativeText) consolidated from Plan 02.5-02 into Plan 02.5-01 Task 2 — eliminates Wave 2 init.lua file-write race with Plan 02.5-03; Plan 02.5-02 NO LONGER touches init.lua at all | Checker revision iter 1 (commit 5667503), executed by Plan 02.5-01 Task 2 | 2026-04-29 |
| OLD voicecc* tag strings preserved verbatim inside `pcall(hs.notify.unregister, ...)` calls per RESEARCH Pitfall 4 — protects against orphaned-tag console-raise on stale notifications in macOS Notification Center | Plan 02.5-01 Task 2 | 2026-04-29 |
| Visual identity (BRD-03) closed by Plan 02.5-03 — assets/icon.svg (hand-authored 256×256 lavender + white-lips, four-quadratic-curve path) + assets/icon-256.png (sips-derived, verified 256×256 RGBA) + assets/README.md (sips regenerate command); menubar migrated from grey/red MENUBAR_IDLE_COLOR/MENUBAR_RECORDING_COLOR to single `MENUBAR_COLOR = BRAND.COLOUR_LAVENDER` reference (DRY: one source of truth for #B388EB) | Plan 02.5-03 Tasks 1+2 | 2026-04-29 |
| Filled-vs-outline glyph (U+25CF recording / U+25CB idle) chosen for menubar recording-state differentiation per RESEARCH Pattern 3 — visually clearest within single-lavender palette, no font dependency, single colour constant | Plan 02.5-03 Task 2 | 2026-04-29 |
| Idempotent 4-state migration block (only-old / both / only-new / neither) in setup.sh closes XDG path rebrand (BRD-02 path half) — live migration on Oliver's machine moved 466 MB models from voice-cc → purplevoice atomically (APFS same-volume mv); both stale symlinks removed; both new symlinks resolve via `ln -sfn`; second run idempotent (no Migrating log lines) | Plan 02.5-02 execution | 2026-04-29 |
| BSD grep escape form `'$HOME/\\.config/voice-cc'` (escape only the dot, not the dollar) — verified empirically on macOS Sequoia 15.7.5 BSD `/usr/bin/grep` treats `$` as literal in middle of BRE pattern; revision iter 1 corrected from `'\\$HOME/.config/voice-cc'` form which BSD grep would treat as literal-backslash-then-dollar | Plan 02.5-02 verify clauses | 2026-04-29 |
| Plan 02.5-02 deviation Rule 1: removed `~/.hammerspoon/purplevoice` from setup.sh Step 4 mkdir — `ln -sfn` cannot overwrite a directory; mkdir-then-ln race surfaced on first live run. Fix: mkdir creates only `~/.hammerspoon` parent; Step 6c's `ln -sfn` creates the child as symlink. Verified via second run: `[ -L "$HOME/.hammerspoon/purplevoice" ]` passes | Plan 02.5-02 Task 2 (live verification) | 2026-04-29 |

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

- Plan 02.5-02 (2026-04-29): XDG path rename + idempotent setup.sh migration block — Wave 2 parallel execution alongside Plan 02.5-03. Inserted Step 3b `migrate_xdg_dir` 4-state guard function (only-old / both / only-new / neither) + 3 calls (config, data, cache) + symlink hygiene block (`rm` stale `~/.local/bin/voice-cc-record` + `~/.hammerspoon/voice-cc` if symlinks). Renamed all XDG paths in setup.sh: mkdir block, MODEL constant, SILERO_MODEL constant, VOCAB_DEST, DENYLIST_DEST. Inserted Step 6c `ln -sfn` symlink installer for `~/.local/bin/purplevoice-record` + `~/.hammerspoon/purplevoice`. Rewrote Step 7 banner: `PurpleVoice setup complete.` + canonical tagline `Local voice dictation. Nothing leaves your Mac.` (D-12) + literal `require("purplevoice")` line for user paste (D-08 + Anti-Pattern 4). Renamed runtime XDG paths in `purplevoice-record` (MODEL/SILERO_MODEL/VOCAB_FILE/DENYLIST/WAV_DIR), 5 bash test files (test_denylist/test_wav_cleanup/test_sigint_cleanup/test_duration_gate/test_vad_silence), 1 manual walkthrough (test_reentrancy.md), and config/denylist.txt header comments. Live migration on Oliver's machine performed and verified: only-old branch fired for all 3 dirs (config 8K, data 466M models, cache 0B); both stale symlinks removed; both new symlinks resolve correctly. Second run silent (idempotent only-new branch). 6 bash unit tests still GREEN with new `/tmp/purplevoice` + `~/.config/purplevoice` paths. Pattern 2 invariant intact (`grep -c WHISPER_BIN purplevoice-record == 2`). One Rule 1 deviation auto-fixed: removed `~/.hammerspoon/purplevoice` from Step 4 mkdir block (mkdir-then-ln race; `ln -sfn` cannot overwrite a directory). Touched ZERO Lua files (revision iter 1 race elimination held — `git diff --name-only` shows no `purplevoice-lua/` entries). Used `--no-verify` on commits per parallel-execution guidance to avoid hook contention with Plan 02.5-03. BRD-02 path-half closed. Commits: `ca231e4` (Task 1 — setup.sh migration block + XDG rename), `cc27db0` (Task 2 — purplevoice-record + tests + denylist runtime path migration + mkdir/ln-sfn race fix). See 02.5-02-SUMMARY.md.
- Plan 02.5-03 (2026-04-29): visual identity — Wave 2 parallel execution. Created `assets/` directory with 3 files: `assets/icon.svg` (960 bytes, hand-authored 256×256 lavender bg `#B388EB` + centred white lips silhouette via four-quadratic-curve closed path; explicit width/height/viewBox per RESEARCH Pitfall 6), `assets/icon-256.png` (4079 bytes, sips-derived, verified 256×256 RGBA non-interlaced PNG via `sips -g pixelWidth -g pixelHeight` and `file`), `assets/README.md` (16 lines, single-line sips regenerate command + brand colour note). Visual sanity check passed (clearly recognisable lips on lavender, cupid's bow indent visible, no rendering artifacts — first-pass path geometry accepted, no iteration). Migrated `purplevoice-lua/init.lua` menubar palette from grey/red MENUBAR_IDLE_COLOR (#888888) + MENUBAR_RECORDING_COLOR (#FF3B30) to single `MENUBAR_COLOR = BRAND.COLOUR_LAVENDER` reference (DRY: one source of truth for #B388EB, references M.BRAND constants table set up by Plan 02.5-01). Idle/recording glyphs swapped to filled-vs-outline differentiation (idle = U+25CB white circle outline `○`, recording = U+25CF black circle filled `●`) — both styled lavender per RESEARCH Pattern 3 (visually clearest, no font dependency, single colour constant). Pattern 2 invariant intact (grep -c WHISPER_BIN purplevoice-record == 2; ! grep -q whisper-cli purplevoice-lua/init.lua). All 6 bash unit tests still GREEN. File scope discipline preserved during parallel Wave 2 execution: my commits touched only `assets/*` + `purplevoice-lua/init.lua`; `setup.sh` (parallel Plan 02.5-02 scope) untouched. Used `--no-verify` on both task commits per parallel-execution guidance. BRD-03 closed. No deviations — plan executed exactly as written. Hammerspoon live reload deferred (hs.ipc port returned transport errors; user must paste `require("purplevoice")` into ~/.hammerspoon/init.lua per Plan 02.5-02 follow-up before live menubar visual is observable). Commits: 07b1ac1 (Task 1 — icon assets), 309221a (Task 2 — menubar lavender wiring). See 02.5-03-SUMMARY.md.
- Plan 02.5-01 (2026-04-29): voice-cc → PurpleVoice rebrand of bash glue + Lua module + user-paste snippet + 6 unit tests + 7 manual walkthroughs. File renames: `voice-cc-record` → `purplevoice-record`, `voice-cc-lua/` → `purplevoice-lua/`. 5 hs.notify titles use `PurpleVoice:` prefix; module load alert uses `PurpleVoice loaded — local dictation, cmd+shift+e` (D-12 form factor); hs.notify orphan-tag cleanup (`pcall(hs.notify.unregister, "voiceccOpen{Mic,Accessibility}Settings")`) inserted at module top per RESEARCH Pattern 4; new `purplevoice*` tag namespace in register + send call sites; `M.BRAND` constants table (NAME / TAGLINE / COLOUR_LAVENDER) exported for Phase 3.5 HUD. Cache-path edit consolidated from Plan 02.5-02 per checker iter 1: exit-12 informativeText now references `~/.cache/purplevoice/error.log` — eliminates Wave 2 init.lua file-write race with Plan 02.5-03. 6 env vars renamed (`VOICE_CC_*` → `PURPLEVOICE_*`) — hard rename, no fallback shim per personal-tool ethos. Pattern 2 invariant verified post-edit (`grep -c WHISPER_BIN purplevoice-record == 2`); Pattern 2 corollary verified (`! grep -q "whisper-cli" purplevoice-lua/init.lua`). 4 Rule 1 deviations auto-fixed inline (stale comments referring to old `voiceccOpenAccessibilitySettings`, `VOICE_CC_NO_SOUNDS`, `whisper-cli`, and `voice-cc` strings). All 6 bash unit tests still GREEN. BRD-02 closed for code surfaces (runtime XDG paths intentionally preserved for Plan 02.5-02 ownership). Commits: 2c9a7f2 (Task 1 — file/dir renames + bash glue + tests + manual walkthroughs), 090c1dd (Task 2 — Lua module strings + orphan-tag cleanup + cache-path edit). See 02.5-01-SUMMARY.md.
- Plan 02-03 (2026-04-28): voice-cc-lua/init.lua final form (315 lines) — full `hs.notify` dispatch for exit codes 10 / 11 / 12 + System Settings deep links + 60s notifyOnce dedup + defence-in-depth Accessibility-deny notification. Both manual checkpoints signed off live by user ("approved"). Three coupled regressions fixed inline (commit 81334ce): (a) SOX_SIGNALED flag distinguishes trap-induced sox exit from real failure, (b) Sequoia silent-stream amplitude detection replaces dead stderr-fingerprint, (c) deep-link URLs use `://` instead of bare `:` for Hammerspoon's openURL API. All 6 bash unit tests still GREEN. Pattern 2 boundary preserved. Commits: 8b32e45 (Task 3-1 dispatcher), 81334ce (3 deviations fix). See 02-03-SUMMARY.md.
- Plan 02-02 (2026-04-28): voice-cc-lua/init.lua hardened (82 → 208 lines). Menubar indicator + audio cues + clipboard preserve/restore with TransientType UTI + re-entrancy guard + handleExit stub + hs.accessibilityState(true) on load. `.hammerspoon-init-snippet.lua` staged for `require("hs.ipc")`; user pasted; IPC working. FBK-01, FBK-02, INJ-02, INJ-03, ROB-01 closed. Phase-1 TODOs (a) and (b) closed. Commits: f4da016, deee0fe.
- Plan 02-01 (2026-04-28): voice-cc-record hardened. VAD + duration gate + denylist exact-match + EXIT trap + TCC stderr fingerprint (later superseded by Plan 02-03's amplitude detection on Sequoia) + semantic exit codes 2/3/10/11/12. Phase-1 TODO (c) closed via `--no-prints`. Commits: 47193f0, 691f030. **Note: subsequently patched in commit 81334ce** for the `wait`-pattern regression that broke every normal hotkey release on Sequoia.
- Plan 02-00 (2026-04-28): Wave 0 test infra. 17 files created: tests/run_all.sh (suite runner), tests/lib/sample_audio.sh (4 WAV-synthesis helpers incl. medium_wav for SIGINT path), 6 unit/integration tests (test_duration_gate/denylist/vad_silence/tcc_grep/wav_cleanup/sigint_cleanup), 7 manual walkthroughs (test_clipboard_restore/transient_marker/menubar/audio_cues/tcc_notification/reentrancy/accessibility_prompt), config/denylist.txt (19 phrases). setup.sh extended with Step 5b (Silero VAD download) + Step 6b (denylist install) — both idempotent. Pattern 2 boundary preserved. Commits: b899c28, 01e6429, ed32ad2.
- Plan 01-01 (2026-04-27): setup.sh idempotent, model SHA256 verified, Hammerspoon + sox + whisper-cli installed, XDG layout + vocab seed in place. Manual pipeline test deferred to Plan 01-03 walkthrough per user.
- Plan 01-02 (2026-04-27): voice-cc-record bash glue written + symlinked into ~/.local/bin/. transcribe() Pattern 2 boundary discipline confirmed (grep -c WHISPER_BIN == 2). All 16 plan automated-verify clauses pass. Manual invocation Task 2 deferred to Plan 01-03 walkthrough per user (precedent: Plan 01-01 Task 3 deferral).
- Plan 01-03 (2026-04-27): voice-cc-lua/init.lua written (82 lines) + symlinked into ~/.hammerspoon/voice-cc/ + minimal ~/.hammerspoon/init.lua written fresh (D-02 honoured — no prior content). End-to-end walkthrough: user approved after 4 PASS criteria + 1 SKIPPED-BUT-NOT-GATING (Criterion #4 vocab A/B explicitly skipped by user). Phase 1 spike loop demonstrably works end-to-end. Three Phase 2 candidates surfaced (hs.accessibilityState, hs.ipc, suppress whisper sibling .txt) — all logged in Open TODOs.

## Session Continuity

### Next Action

Phase 2.5 Wave 2 complete. Plans 02.5-01, 02.5-02, 02.5-03 done — code surfaces, XDG paths, setup.sh migration, and visual identity all stable. Execute Wave 3 next:

- **Plan 02.5-04** (PROJECT.md + REQUIREMENTS.md + README + tests/test_brand_consistency.sh): Record `PurpleVoice` in PROJECT.md as authoritative product name with privacy-first positioning paragraph (BRD-01); formalise BRD-01..03 in REQUIREMENTS.md; expand README with H1 + tagline + install instructions referencing the new symlinks/paths/banner; add `tests/test_brand_consistency.sh` regression catch (asserts ZERO `voice-cc` strings outside `.planning/`/`.git/` AND inside the 3 setup.sh `migrate_xdg_dir` FROM args).

After 2.5: Phase 3.5 (HUD), Phase 4 (QoL), Phase 3 (Distribution + hyperfine + public install), Phase 5 (Warm-Process, conditional).

### Stopped At

Plan 02.5-02 complete (2 tasks autonomous, 5m 47s wall-clock, 1 Rule 1 deviation auto-fixed). 02.5-02-SUMMARY.md authored at `.planning/phases/02.5-branding/02.5-02-SUMMARY.md`. Live migration successful on Oliver's machine — all 3 XDG dirs migrated (~466 MB models moved atomically via APFS rename), both stale symlinks removed, both new symlinks resolve. setup.sh idempotent on second run. All 6 bash unit tests GREEN. Pattern 2 boundary intact.

Local environment: `~/.hammerspoon/init.lua` still references `require("voice-cc")` — but `~/.hammerspoon/voice-cc` symlink no longer exists (Plan 02.5-02 removed it). Live PurpleVoice dictation loop is currently broken until the user manually edits `~/.hammerspoon/init.lua` from `require("voice-cc")` to `require("purplevoice")`. setup.sh prints the new line at completion (Anti-Pattern 4 boundary — no auto-edit of user dotfiles). Plan 02.5-04's README expansion will document this manual step prominently.

User intent stated: proceed through Phase 2.5 plan-by-plan.

### Last Session Summary

- Plan 02.5-02 executed (autonomous, Wave 2 parallel with Plan 02.5-03, no checkpoints, ~5m 47s wall-clock):
  - Task 1 (commit `ca231e4`): rewrote setup.sh — inserted Step 3b `migrate_xdg_dir` 4-state guard function + 3 calls (config/data/cache) + symlink hygiene block; renamed all XDG paths in mkdir block, MODEL constant (Step 5), SILERO_MODEL constant (Step 5b), VOCAB_DEST (Step 6), DENYLIST_DEST (Step 6b); inserted Step 6c `ln -sfn` symlink installer; rewrote Step 7 banner with `PurpleVoice setup complete.` + canonical tagline `Local voice dictation. Nothing leaves your Mac.` (D-12) + literal `require("purplevoice")` line for user paste (D-08 + Anti-Pattern 4). Header (line 2), Step 6 comment (line 12), Step 1 stderr (line 25), and 2 `repo root` strings updated to PurpleVoice. Verified: `bash -n setup.sh` exits 0; `grep -c migrate_xdg_dir` returns 4; tagline + require line present; old voice-cc paths each appear exactly once (only as `migrate_xdg_dir` FROM args — RESEARCH Pitfall 1 sed-protection).
  - Task 2 (commit `cc27db0`): renamed runtime XDG paths in `purplevoice-record` lines 32-37 (MODEL, SILERO_MODEL, VOCAB_FILE, DENYLIST, WAV_DIR — the `$WAV_DIR` rename auto-propagates to WAV, SOX_ERR_LOG, mkdir, find sweep, EXIT trap). Pattern 2 invariant verified: `grep -c WHISPER_BIN purplevoice-record == 2`. Updated 5 bash test files (test_denylist DENYLIST path; test_wav_cleanup 8 occurrences; test_sigint_cleanup 7 occurrences; test_duration_gate 2 occurrences; test_vad_silence MODEL+SILERO defaults). Updated `tests/manual/test_reentrancy.md` (3 occurrences). Updated `config/denylist.txt` header comments (lines 1, 7).
  - **Live migration on Oliver's machine** (`bash setup.sh`): only-old branch fired for all 3 XDG dirs — config 8K, data 466M (Whisper small.en + Silero VAD models moved atomically via APFS rename), cache 0B. Both stale symlinks (`~/.local/bin/voice-cc-record`, `~/.hammerspoon/voice-cc`) removed. Both new symlinks created via `ln -sfn`. Second run: silent (zero `Migrating`/`Removed stale`/`WARN` log lines — idempotent only-new branch).
  - **One Rule 1 deviation auto-fixed**: plan instructed `mkdir -p ... ~/.hammerspoon/purplevoice` in Step 4, but Step 6c uses `ln -sfn` to create the same path as a symlink — `ln -sfn` cannot overwrite a directory. First live run created an empty dir at `~/.hammerspoon/purplevoice` (mkdir succeeded), then `ln -sfn` was a no-op. Auto-fix: removed `~/.hammerspoon/purplevoice` from mkdir block; kept `~/.hammerspoon` (parent dir). Verified via second run: `[ -L "$HOME/.hammerspoon/purplevoice" ]` passes; `readlink` returns `/Users/oliverallen/Temp video/voice-cc/purplevoice-lua`.
  - All 6 bash unit tests still GREEN with new `/tmp/purplevoice` + `~/.config/purplevoice` paths. Pattern 2 boundary preserved (`grep -c WHISPER_BIN purplevoice-record == 2`).
  - **Touched ZERO Lua files** — `git diff --name-only ca231e4^..HEAD` confirms no `purplevoice-lua/` entries (revision iter 1 race elimination held; cache-path edit was consolidated into Plan 02.5-01 Task 2).
  - Used `--no-verify` on commits per parallel-execution guidance to avoid pre-commit hook contention with concurrent Plan 02.5-03.
  - 02.5-02-SUMMARY.md authored at `.planning/phases/02.5-branding/02.5-02-SUMMARY.md` with full deviation audit trail (1 Rule 1 fix), live migration log evidence, BSD grep escape note, self-check results.

- Plan 02.5-01 executed (autonomous, Wave 1, no checkpoints, ~8 min wall-clock):
  - Task 1 (commit `2c9a7f2`): `git mv voice-cc-record purplevoice-record` + `git mv voice-cc-lua purplevoice-lua`. Rewrote bash glue's brand strings: stderr messages (whisper-cli missing, Whisper model missing, Silero VAD weights missing) now use `PurpleVoice:` prefix; env vars `VOICE_CC_MODEL/SILERO_MODEL/VAD_THRESHOLD/TEST_SKIP_SOX` renamed to `PURPLEVOICE_*`. Pattern 2 invariant verified: `grep -c WHISPER_BIN purplevoice-record == 2`. Header comment + test-hook comments updated. Rebranded 6 unit tests (test_duration_gate / test_denylist / test_wav_cleanup / test_sigint_cleanup / test_tcc_grep / test_vad_silence) — all env-var refs and script-name refs updated together; runtime XDG paths intentionally preserved for Plan 02.5-02. Rebranded 7 manual walkthroughs (test_clipboard_restore / test_transient_marker / test_menubar / test_audio_cues / test_tcc_notification / test_reentrancy / test_accessibility_prompt) — voice-cc-record / voice-cc-lua refs replaced with PurpleVoice equivalents. tests/run_all.sh log path renamed.
  - Task 2 (commit `090c1dd`): Inserted `pcall(hs.notify.unregister, "voiceccOpen{Mic,Accessibility}Settings")` cleanup at module top per RESEARCH Pattern 4 (uses OLD tag strings — protects against orphaned-tag console-raise on stale notifications in macOS Notification Center). Inserted `local BRAND = { NAME, TAGLINE, COLOUR_LAVENDER }` constants block + `M.BRAND = BRAND` export for Phase 3.5 HUD. Replaced 5 hs.notify titles with `PurpleVoice:` prefix (microphone blocked, install incomplete, transcription failed, accessibility required, unexpected exit N). Module load alert: `PurpleVoice loaded — local dictation, cmd+shift+e` (D-12 form factor). Two hs.notify.register tags + 2 hs.notify.new call sites use new `purplevoiceOpen*Settings` namespace. SCRIPT_PATH points to `~/.local/bin/purplevoice-record`. `os.getenv("PURPLEVOICE_NO_SOUNDS")` replaces VOICE_CC_NO_SOUNDS. Cache-path edit consolidated from Plan 02.5-02 per checker iter 1: exit-12 `informativeText` now references `~/.cache/purplevoice/error.log` (eliminates Wave 2 init.lua file-write race with Plan 02.5-03). Two alert texts rebranded (script-not-found, cmd+shift+e binding failed). `.hammerspoon-init-snippet.lua` rewritten to recommend `require("purplevoice")` + brand-explanation comment per D-08. **4 Rule 1 deviations auto-fixed inline:** (a) stale comment referencing old `voiceccOpenAccessibilitySettings` tag → `purplevoiceOpenAccessibilitySettings`; (b) stale comment referencing old `VOICE_CC_NO_SOUNDS` env var → `PURPLEVOICE_NO_SOUNDS`; (c) pre-existing comment violating Pattern 2 corollary "whisper-cli" → "transcription"; (d) plan-required ZERO `voice-cc` strings violated by my own initial cleanup-comment insertion ("old voice-cc tag names" → "old voicecc tag names").
  - All 6 bash unit tests still GREEN post-rebrand. Pattern 2 boundary preserved (grep -c WHISPER_BIN purplevoice-record == 2). Pattern 2 corollary preserved (! grep -q whisper-cli purplevoice-lua/init.lua).
  - 02.5-01-SUMMARY.md authored at `.planning/phases/02.5-branding/02.5-01-SUMMARY.md` with full deviation audit trail (4 Rule 1 fixes), self-check results, and Wave 2 readiness signals.

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
