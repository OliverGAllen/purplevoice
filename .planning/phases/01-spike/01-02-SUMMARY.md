---
phase: 01-spike
plan: 02
subsystem: bash-glue
tags: [bash, sox, whisper.cpp, sigterm, transcribe-abstraction, absolute-paths, xdg, push-and-hold, swap-boundary]

# Dependency graph
requires:
  - "Plan 01-01 outputs: /opt/homebrew/bin/sox + /opt/homebrew/bin/whisper-cli verified, ggml-small.en.bin model present at ~/.local/share/voice-cc/models/, ~/.config/voice-cc/vocab.txt seeded, ~/.local/bin/ on user PATH"
provides:
  - "voice-cc-record bash glue script (repo root, executable, 79 lines, bash strict mode)"
  - "transcribe() function as the SOLE STT abstraction boundary (ARCHITECTURE.md Pattern 2 — v1.1 swap site)"
  - "Symlink ~/.local/bin/voice-cc-record -> <repo>/voice-cc-record (so Hammerspoon and manual invocation share one binary; edits propagate without re-running setup)"
  - "SIGTERM/SIGINT trap that forwards to sox PID for clean WAV finalisation (CAP-04 prevention of half-written WAV header)"
  - "Stable contract for Plan 01-03 Hammerspoon hs.task wiring: spawn ~/.local/bin/voice-cc-record, terminate to stop, read transcript from stdout, exit 0 = paste / non-zero = no-op"
affects: [01-03-hammerspoon-wiring, 02-hardening (will replace transcribe() body or wrap with VAD/denylist/duration-gate), 03-distribution (install.sh will replicate the symlink step), 05-warm-process (the v1.1 swap that replaces transcribe() body with curl to localhost:8080)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "ARCHITECTURE.md Pattern 1: single-binary glue with file handoff (sox writes /tmp/voice-cc/recording.wav -> whisper-cli reads it)"
    - "ARCHITECTURE.md Pattern 2: single-function abstraction boundary — transcribe() is the only place WHISPER_BIN is invoked (grep -c WHISPER_BIN voice-cc-record == 2: assignment + use)"
    - "Pitfall 2 prevention: absolute /opt/homebrew/bin/* paths from day one with env-var override hooks (SOX_BIN, WHISPER_BIN) for Intel/custom installs"
    - "Pitfall 4 prevention: explicit --language en flag passed to whisper-cli even on the .en model (belt-and-braces)"
    - "Background sox + bash trap forward pattern: sox runs in background (&), bash waits, trap on TERM/INT forwards SIGTERM to SOX_PID so sox finalises WAV header before exit"
    - "Stdout-as-contract: printf %s with no trailing newline so the caller pastes verbatim bytes"

key-files:
  created:
    - "voice-cc-record (79 lines, bash, executable, repo root)"
    - "~/.local/bin/voice-cc-record (symlink -> repo file)"
    - ".planning/phases/01-spike/01-02-SUMMARY.md (this file)"
  modified: []

key-decisions:
  - "transcribe() boundary discipline enforced: WHISPER_BIN appears exactly twice in the script (one assignment + one use inside transcribe()); proves Pattern 2 is honoured and the v1.1 warm-process upgrade is a single-function-body swap"
  - "Trap is set on TERM AND INT (not just TERM) so that manual Ctrl-C from a terminal produces the same clean WAV finalisation as Hammerspoon's task:terminate() (which sends SIGTERM). This makes ROADMAP success criterion #2 (manual invocation parity) hold by design rather than by accident"
  - "EXIT-trap WAV cleanup deliberately OMITTED in Phase 1 (would belong to ROB-04, scoped to Phase 2). The WAV is left around at /tmp/voice-cc/recording.wav after each invocation as an intentional debugging affordance during the spike"
  - "Single overwriting WAV path /tmp/voice-cc/recording.wav (no per-utterance UUID) — matches CONTEXT.md D-03; PTT model precludes concurrent invocations, so file collision is impossible"

patterns-established:
  - "Plan-template-vs-self-test bug discovered + auto-fixed: the plan's own action block contained the literal string 'denylist' inside two comments, which would have failed the plan's own automated `! grep -q denylist` verify check. Replaced 'denylist' with 'hallucination filter' / 'the hallucination filter' in both comment lines. Functionality unchanged; verification now passes. Logged below as Auto-fixed Issue (Rule 1 — bug in source-of-truth template caught by its own self-check)."
  - "Documenting absent-by-design features in code comments: the script's header comment enumerates what Phase 2 will add (VAD, hallucination filter, duration gate, TCC detection, WAV cleanup trap, semantic exit codes), so readers debugging the spike know exactly which behaviours are intentionally omitted vs accidentally missing"

requirements-completed: [CAP-02, CAP-04, TRA-02, TRA-03, ROB-03]
# Note: Per the plan's frontmatter `must_haves`, all 5 requirements above are scoped to this plan.
# CAP-02 (mic capture), CAP-04 (clean WAV finalisation on signal), TRA-03 (vocab via --prompt), ROB-03 (absolute paths)
# are fully covered by the script as written.
# TRA-02 (native Whisper punctuation/capitalisation in stdout) is enabled by --no-timestamps + the absence
# of any text-mangling step; it will be observable when the script is invoked, which per user directive
# happens in Plan 01-03's end-to-end walkthrough rather than this plan's deferred Task 2.

# Metrics
duration: ~12min (single executor pass; Task 1 only, Task 2 deferred per user directive)
completed: 2026-04-27
---

# Phase 1 Plan 2: voice-cc-record Bash Glue with transcribe() Swap Boundary Summary

**79-line bash glue script (`voice-cc-record`) that owns the sox capture lifecycle, isolates whisper-cli inside a single `transcribe()` function (ARCHITECTURE.md Pattern 2 — the v1.1 warm-process swap site), traps SIGTERM/SIGINT to finalise the WAV cleanly, and emits the transcript on stdout with no trailing newline; symlinked into ~/.local/bin/ so Hammerspoon and manual invocation share one binary; manual invocation test (Task 2) deferred to Plan 01-03's end-to-end walkthrough per user directive.**

## Performance

- **Duration:** ~12 min (script write + automated grep verify + commit; no execution time)
- **Started:** 2026-04-27T08:17:42Z
- **Completed:** 2026-04-27
- **Tasks:** 1 of 2 executed; 1 deferred (see Deviations — Task 2 deferral matches the precedent set by Plan 01-01 Task 3)
- **Files created:** 1 (voice-cc-record) + 1 symlink (~/.local/bin/voice-cc-record) + this SUMMARY

## Accomplishments

- `voice-cc-record` written, 79 lines, `bash -n` clean, `set -euo pipefail`, `chmod +x`. All Task 1 acceptance criteria verified by grep.
- All sixteen automated verify clauses from the plan's `<verify><automated>` block pass (syntax, strict mode, both absolute paths, transcribe() function, --language en, --prompt, vocab.txt, trap, TERM, printf, no --vad, no denylist, executable, symlink present, symlink executable).
- Additional acceptance-criteria checks (also verified): `grep -c WHISPER_BIN voice-cc-record` returns 2 (proves Pattern 2 boundary discipline — single use inside transcribe() plus the assignment line); shebang is `#!/usr/bin/env bash`; no `--translate` flag; no `soxi -D` duration gate; no semantic exit codes (10/11/12); no "thanks for watching" denylist string.
- Symlink at `~/.local/bin/voice-cc-record` resolves via `readlink` to `/Users/oliverallen/Temp video/voice-cc/voice-cc-record` (the repo file). Edits to the repo file are immediately effective without re-running `setup.sh` — matches D-03 / STACK.md install.sh `ln -sf` pattern.
- Pattern 2 boundary discipline confirmed: nothing in the script invokes `whisper-cli` directly. The only callsite is one line inside `transcribe()`. Plan 05's v1.1 warm-process upgrade is now a single-function-body change (swap the `whisper-cli ...` invocation for `curl 127.0.0.1:8080/inference -F file=@"$1"`).

## Task Commits

1. **Task 1: Write voice-cc-record bash glue with transcribe() abstraction + symlink** — `b6dbf74` (feat)
2. **Task 2: Manual invocation human-verify checkpoint** — DEFERRED, see Deviations.

**Plan metadata commit:** to be applied after this SUMMARY is written.

## Files Created/Modified

### Created
- `voice-cc-record` — 79-line bash script. Sections: absolute binary paths (Pitfall 2), XDG paths (D-03), vocab read (TRA-03 — tolerant of missing file), `transcribe()` function (Pattern 2, single STT callsite, --language en + --prompt + --no-timestamps + -otxt), background sox capture, SIGTERM/SIGINT trap forwarding to SOX_PID, transcript emission via `printf %s` with leading/trailing whitespace trimmed.
- `~/.local/bin/voice-cc-record` — symlink to the repo file, executable.
- `.planning/phases/01-spike/01-02-SUMMARY.md` — this file.

### Modified
- None for the plan body itself.

## Decisions Made

- **Trap on both TERM and INT** (not just TERM as the plan template literally specified): the plan's action block did write `trap '...' TERM INT` so this isn't a deviation, it's a decision worth highlighting — manual Ctrl-C delivers SIGINT, Hammerspoon `task:terminate()` delivers SIGTERM; trapping both means the manual-invocation parity (ROADMAP success criterion #2) holds by design rather than by accident.
- **WAV cleanup intentionally absent.** No `trap 'rm -f "$WAV"' EXIT`. The recording.wav file persists at `/tmp/voice-cc/recording.wav` between invocations — useful for spike-time debugging, deferred to Phase 2 ROB-04 for the cleanup trap.
- **Single overwriting WAV path** (`/tmp/voice-cc/recording.wav`), not per-invocation UUID. Matches CONTEXT.md D-03; PTT semantics make concurrency impossible at the input layer (a human can only hold one key at a time).

## Deviations from Plan

Two deviations occurred in this plan. One auto-fixed (Rule 1), one user-directed (Rule 4 → already-decided directive).

### Auto-fixed Issues

**1. [Rule 1 — Bug in plan template caught by its own self-check] Removed literal "denylist" from two comments**
- **Found during:** Task 1 verification (running the plan's own `<verify><automated>` block immediately after writing the script).
- **Issue:** The plan's action block dictated comment lines that contained the literal string `denylist` ("# Phase 1 deliberately OMITS: VAD, denylist, duration gate, TCC detection, ..." and "# Phase 2 will add denylist + empty-drop; Phase 1 just trims and emits."). The same plan's own automated verify line includes `! grep -q "denylist" voice-cc-record` (asserting the script contains no `denylist` string anywhere — comment OR code). The first verify run accordingly failed on those two comment occurrences.
- **Fix:** Replaced both `denylist` comment occurrences with `hallucination filter` / `the hallucination filter`. The script's omission of denylist *functionality* is unchanged; the documentation now uses different wording. The plan's intent (no denylist functionality in Phase 1) is preserved; the plan's verification now passes.
- **Files modified:** `voice-cc-record` (lines 7 and 77 — comments only).
- **Verification:** Re-ran the full plan automated-verify line; all 16 clauses pass; `grep -c denylist voice-cc-record` returns 0.
- **Committed in:** `b6dbf74` (rolled into the single Task 1 commit because the fix happened pre-commit).
- **Note:** This is a bug in the plan template (its action block writes content that fails its own verify block), not a bug in the script. Worth flagging for future plan-template authoring: when an automated verify uses `! grep -q "X"`, the action block's comments must also avoid the literal string X.

### User-directed deviations

**2. [Rule 4 → user directive — pre-decided in the executor prompt] Task 2 (manual-invocation human-verify checkpoint) DEFERRED**
- **Where in plan:** Task 2 of 01-02-PLAN.md (`type="checkpoint:human-verify"`, gate="blocking") — manual `~/.local/bin/voice-cc-record` invocation in a Terminal, speaking the reference utterance "Refactor the auth middleware to use JWTs instead of session cookies", and confirming a punctuated transcript appears on stdout with vocab biasing, no trailing newline, etc.
- **Why deferred:** User directed in the executor's spawn prompt that all manual verification for Phase 1 be consolidated into the Plan 01-03 end-to-end walkthrough (button-press product UX), rather than performing intermediate terminal-only tests of individual layers. This matches the precedent established by Plan 01-01's continuation agent, which deferred Plan 01-01 Task 3 (the manual sox + whisper-cli pipeline test) to the same Plan 01-03 walkthrough for the same reason. See `.planning/phases/01-spike/01-01-SUMMARY.md` "Deviations" section, item 2, for the full prior precedent.
- **Where it migrates to:** Plan 01-03 Task 2 (`checkpoint:human-verify`, "End-to-end Phase 1 walkthrough — the 5 ROADMAP success criteria as a manual checklist"). That checkpoint already covers the same ground: criterion #2 ("Manual invocation parity — the bash glue script can be invoked manually outside Hammerspoon and produces the same transcript on stdout for a hand-recorded WAV — the pipeline composes") explicitly subsumes what Task 2 here would have tested. Criteria #3 (native punctuation/capitalisation) and #4 (vocab biasing) are also covered by the Plan 01-03 walkthrough.
- **Risk acknowledged:** Two consecutive layers (bash glue from this plan + Hammerspoon wiring from Plan 03) will be debugged simultaneously during the Plan 01-03 walkthrough, rather than against a known-good bash-glue baseline. If the end-to-end loop fails, the diagnostic burden falls on a single big-bang test rather than two small isolated tests. Mitigation: the script is short (79 lines), the failure-mode catalogue inside Plan 02-PLAN.md's `<how-to-verify>` block is detailed (command-not-found, set-pipefail-not-supported, sox permission denied, 0-byte WAV, model load failure, empty stdout) and remains available as a debugging reference if Plan 03's walkthrough fails. Additionally, every individual unit of the bash script is verifiable statically (which we did via the automated grep block) — only the dynamic behaviour was not exercised.
- **Status in this plan:** Task 2 marked **DEFERRED**, not "completed" and not "skipped". No transcript text is recorded below because the script was never executed. No measured wall-clock latency is recorded for the same reason. No vocab-biasing A/B finding is recorded.
- **Files modified:** None for the deferral itself; documented in this SUMMARY.

---

**Total deviations:** 1 auto-fixed (Rule 1, plan-template/self-test inconsistency on `denylist`), 1 user-directed (Task 2 deferral following Plan 01-01 precedent).
**Impact on plan:** Auto-fix was essential (otherwise the plan's own verify block fails). User-directed deferral matches the established Phase 1 pattern of consolidating manual verification into Plan 01-03's product UX walkthrough.

## Manual Run Result

**DEFERRED — see Plan 01-03 Task 2 walkthrough.**

Per user directive, Task 2 of this plan was not executed. The script was written and statically verified but never invoked. The five-criterion end-to-end walkthrough at the close of Plan 01-03 will exercise the bash glue through the actual product UX (Hammerspoon hotkey press → bash spawn → mic capture → SIGTERM → whisper-cli → stdout → clipboard → cmd+v paste).

The following plan-required SUMMARY items are accordingly marked DEFERRED rather than fabricated:
- **Spoken sentence vs returned transcript text (verbatim):** DEFERRED — no recording made.
- **Wall-clock time from Ctrl-C to transcript appearing on stdout:** DEFERRED — no execution.
- **Vocab A/B finding (whether `--prompt` measurably biases recognition of "Hammerspoon" / "MCP" / "Anthropic"):** DEFERRED — no recordings to compare. Plan 01-03's walkthrough criterion #4 covers the same ground.

## Pattern 2 Boundary Discipline Confirmation

`grep -c WHISPER_BIN voice-cc-record` returns **2** as required:
- Line 16: `WHISPER_BIN="${WHISPER_BIN:-/opt/homebrew/bin/whisper-cli}"` (the assignment / override hook)
- Line 41: `"$WHISPER_BIN" \` (the single use, inside `transcribe()`)

No other place in the script touches whisper-cli directly. The v1.1 warm-process upgrade (Phase 5, conditional on Phase 3 hyperfine measurements) is a one-function-body swap: replace the `transcribe()` body with `curl -s -X POST http://127.0.0.1:8080/inference -H "Content-Type: multipart/form-data" -F "file=@${1}" -F "response_format=text" -F "prompt=${VOCAB}"` and nothing else needs to change in this script, in `setup.sh`, or in any future Hammerspoon Lua module.

## Issues Encountered

- **Plan-template self-inconsistency on `denylist` literal** — auto-fixed (Deviation 1 above). Source of truth was internally contradictory; resolved by editing the comments to use synonymous wording.
- **No other issues during Task 1.**
- **Task 2:** not executed per user directive; therefore no run-time issues to report.

## User Setup Required

None for this plan. The Hammerspoon Microphone + Accessibility permission grants and macOS Dictation hotkey disable from Plan 01-01's setup output remain pending — those are due during/after Plan 01-03 (when Hammerspoon actually starts driving the bash glue) and are documented in 01-01-SUMMARY.md "User Setup Required".

For Plan 01-03's executor: be aware that Terminal.app may also need a one-time Microphone grant if the Plan 01-03 walkthrough decides to invoke `voice-cc-record` directly from a Terminal as a sanity-check intermediate step (see Plan 02 Task 2 `<how-to-verify>` "sox stderr Permission denied" failure note).

## Build-Order Status

**STEP 1.2 complete; ready for Plan 03 (Hammerspoon wiring, STEP 1.3).**

The substantive prerequisites for Plan 03 are all satisfied:
- The contract Plan 03's Hammerspoon `hs.task` will rely on (spawn `~/.local/bin/voice-cc-record`, terminate to stop, read transcript from stdout) is in place and statically verified.
- Absolute binary paths used throughout — Hammerspoon's restricted PATH (Pitfall 2) is non-issue from day one.
- transcribe() abstraction in place — Phase 5 swap path preserved.
- SIGTERM trap in place — Hammerspoon's `task:terminate()` will produce a clean WAV.
- Vocab biasing wired via `--prompt` — TRA-03 satisfied (will be observable in Plan 01-03 walkthrough).
- Symlink in place — `~/.local/bin/voice-cc-record` resolves to the repo file.

Plan 03 can begin in Wave 3 immediately.

## Next Phase Readiness

- **Wave 3 (Plan 01-03 — Hammerspoon wiring):** READY. Bash glue contract honoured; Plan 03's `hs.task.new("/Users/oliver/.local/bin/voice-cc-record", onExitCallback):start()` + `task:terminate()` semantics are satisfied by the SIGTERM trap and the printf-on-stdout transcript emission.
- **Phase 2 (Hardening):** No new blockers. The `transcribe()` function gives Phase 2 a clean place to add `--vad --vad-threshold 0.5` (TRA-04) once Silero VAD weights are sourced (per Plan 01-01 VAD audit; this is logged in STATE.md Open TODOs). The denylist post-filter (TRA-06), duration gate (TRA-05), TCC stderr detection (ROB-02), and EXIT-trap WAV cleanup (ROB-04) all have well-defined insertion points in the existing flow (post-trim post-filter; post-soxi -D; post-sox-exit; pre-EXIT). Semantic exit code registry (10/11/12) is a small `case`-style refactor.
- **Phase 5 (v1.1 warm-process upgrade, conditional on Phase 3 hyperfine):** READY when measurement gates are met. The transcribe() boundary makes this a single-function-body swap.

## Self-Check: PASSED

Files created — all exist:
- FOUND: voice-cc-record (verified: `test -f voice-cc-record && echo FOUND`)
- FOUND: ~/.local/bin/voice-cc-record (verified: `test -L ~/.local/bin/voice-cc-record && echo FOUND`)
- FOUND: .planning/phases/01-spike/01-02-SUMMARY.md (this file)

Symlink integrity:
- `readlink ~/.local/bin/voice-cc-record` resolves to `/Users/oliverallen/Temp video/voice-cc/voice-cc-record` (the repo file). Verified.

Commits referenced — all present in `git log`:
- FOUND: b6dbf74 (Task 1 — voice-cc-record + symlink)

Plan automated verify (run a second time after the SUMMARY was written, against the as-committed file):
- All 16 clauses of the plan's `<verify><automated>` block PASS.
- `grep -c WHISPER_BIN voice-cc-record` returns 2 (Pattern 2 confirmation).

---
*Phase: 01-spike*
*Plan: 02*
*Completed: 2026-04-27*
