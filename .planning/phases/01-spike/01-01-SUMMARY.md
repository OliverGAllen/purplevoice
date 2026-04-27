---
phase: 01-spike
plan: 01
subsystem: infra
tags: [bash, homebrew, hammerspoon, sox, whisper.cpp, xdg, idempotent-setup, sha256]

# Dependency graph
requires: []
provides:
  - "Idempotent setup.sh installer (Homebrew deps + XDG dirs + Whisper model + vocab seed)"
  - "Whisper small.en model verified at ~/.local/share/voice-cc/models/ggml-small.en.bin (487,614,201 bytes, SHA256 c6138d6d…f9c41e5d)"
  - "Hammerspoon.app installed in /Applications/"
  - "sox + soxi + whisper-cli verified at /opt/homebrew/bin/"
  - "XDG runtime layout created (~/.config/voice-cc/, ~/.local/share/voice-cc/models/, ~/.cache/voice-cc/, ~/.local/bin/, ~/.hammerspoon/voice-cc/)"
  - "vocab.txt.default seeded with 18 AI/dev terms; copied to ~/.config/voice-cc/vocab.txt without clobbering existing"
  - ".gitignore configured to exclude *.bin, *.wav, /tmp artefacts, OS noise"
  - "README.md stub documenting hotkey choice and one-time setup"
  - "Locked decision: hotkey is cmd+shift+e (changed from the original combo using cmd plus option plus the space bar by user 2026-04-27 mid-execution)"
affects: [01-02-bash-glue, 01-03-hammerspoon-wiring, 02-hardening, 03-distribution]

# Tech tracking
tech-stack:
  added: [hammerspoon (cask, 1.x via brew), sox (14.4.2 via brew), whisper-cpp (brew bottle, includes whisper-cli + VAD flags), curl (resumable -C - download), shasum -a 256]
  patterns:
    - "Idempotent shell installers: existence-check before every install/download/copy step"
    - "XDG-conventional file layout from day one (no later refactor)"
    - "Absolute /opt/homebrew/bin/* paths from day one (Pitfall 2 prevention)"
    - "No-clobber config seed (vocab.txt only copied if absent)"
    - "SHA256 verification on downloaded model with explicit fail-loud on mismatch"

key-files:
  created:
    - "setup.sh (145 lines, executable, bash strict mode)"
    - "vocab.txt.default (1 line, 18 comma-separated AI/dev terms)"
    - ".gitignore (14 lines)"
    - "README.md (34 lines)"
    - ".planning/phases/01-spike/01-01-SUMMARY.md (this file)"
  modified:
    - "README.md (Directive 2: hotkey updated to cmd+shift+e)"
    - ".planning/REQUIREMENTS.md (CAP-03 default updated)"
    - ".planning/ROADMAP.md (Phase 1 goal + success criterion #1 updated)"
    - ".planning/STATE.md (decision row + position advance)"
    - ".planning/phases/01-spike/01-CONTEXT.md (D-01 + reference notes updated)"
    - ".planning/phases/01-spike/01-01-PLAN.md (hotkey strings updated for replay correctness)"
    - ".planning/phases/01-spike/01-03-PLAN.md (Lua bind args, alerts, walkthrough, automated greps updated)"
    - ".planning/research/PITFALLS.md (Pitfall 5 + table updated)"
    - ".planning/research/ARCHITECTURE.md (diagram + flow + walkthrough updated)"
    - ".planning/research/SUMMARY.md (key choice + implications updated)"
    - ".planning/research/FEATURES.md (key choice rows updated)"

key-decisions:
  - "MODEL_SHA256 corrected mid-execution: c6138d6d58ecc8322097e0f987c32f1be8bb0a18532a3f88f734d1bbf9c41e5d (sourced from HuggingFace x-linked-etag header for ggerganov/whisper.cpp/ggml-small.en.bin). Original constant in plan was stale and rejected the freshly-downloaded model."
  - "Hotkey changed from the original combo (cmd plus option plus the space bar) to cmd+shift+e on user instruction 2026-04-27. VS Code/Cursor 'Show Explorer' sidebar conflict acknowledged and accepted by user."
  - "Task 3 (manual sox+whisper-cli pipeline test) deferred — not skipped — to Plan 01-03's end-to-end button-press walkthrough on user instruction. Pipeline-isolation test deliberately collapsed into the product-UX test."
  - "VAD finding for Phase 2: whisper-cpp brew bottle ships VAD flags (--vad, --vad-model, --vad-threshold, --vad-min-speech-duration-ms, --vad-min-silence-duration-ms, --vad-max-speech-duration-s, --vad-speech-pad-ms, --vad-samples-overlap) but the default --vad-model value is empty. Phase 2 may need to source Silero VAD model weights separately (e.g., from snakers4/silero-vad) or rely on the bundled default if one materialises after a brew upgrade."

patterns-established:
  - "Idempotent installer pattern: every step gated on existence check; second run produces only 'skipping' lines, never side effects"
  - "Fail-loud on integrity mismatch: SHA256 mismatch deletes corrupt file and exits non-zero rather than silently accepting"
  - "Locked-decision tracking: D-01..D-08 in CONTEXT.md are referenced verbatim from setup.sh and downstream plans (single source of truth)"

requirements-completed: [TRA-01, CAP-03]

# Metrics
duration: ~25min (estimate; spans Tasks 1+2 + the hotkey-rewrite directive)
completed: 2026-04-27
---

# Phase 1 Plan 1: Setup Script + Manual Pipeline Validation Summary

**Idempotent bash installer that lays down Hammerspoon + sox + whisper-cli + the small.en Whisper model (488 MB, SHA256-verified) into XDG-conventional paths with a no-clobber vocab seed; manual pipeline test deferred to the Plan 01-03 end-to-end walkthrough by user request.**

## Performance

- **Duration:** ~25 min (Tasks 1+2 + hotkey-rewrite directive; precise start/end not captured at task granularity)
- **Started:** 2026-04-27 (orchestrator-spawned executor)
- **Completed:** 2026-04-27
- **Tasks:** 2 of 3 completed; 1 deferred (see Deviations)
- **Files modified:** 4 created in repo (setup.sh, vocab.txt.default, .gitignore, README.md) + 11 modified for hotkey-rename directive + this SUMMARY

## Accomplishments

- `setup.sh` (145 lines, `bash -n` clean, `set -euo pipefail`, executable) covers all seven plan steps: Apple-Silicon prefix sanity check, Homebrew install of Hammerspoon/sox/whisper-cpp with skip-if-present, absolute-path binary verification, XDG mkdir tree, resumable+SHA256-verified model download, no-clobber vocab seed, next-step reminders.
- All eleven post-conditions from Task 2's acceptance grid printed `OK:` on first run; second back-to-back run printed only "skipping" log messages (idempotency proven).
- Whisper `ggml-small.en.bin` model present at `~/.local/share/voice-cc/models/ggml-small.en.bin`: 487,614,201 bytes, SHA256 `c6138d6d58ecc8322097e0f987c32f1be8bb0a18532a3f88f734d1bbf9c41e5d` (matches the constant now in setup.sh).
- vocab.txt seeded at `~/.config/voice-cc/vocab.txt` containing all 18 D-08 terms.
- VAD support audit completed: brew bottle's `whisper-cli --help` exposes `--vad` and related flags, but `--vad-model` default is empty (recorded for Phase 2 planning).
- Hotkey decision updated repository-wide from the original combo (cmd plus option plus the space bar) to `cmd+shift+e` per user instruction; grep for the old literal hotkey returns zero hits across `.planning` and `README.md`.

## Task Commits

Each task was committed atomically; later directives produced additional commits.

1. **Task 1: Write idempotent setup.sh + vocab seed + .gitignore + README stub** — `ccf34c2` (feat)
2. **Task 1 follow-up: Correct stale MODEL_SHA256 constant (deviation, Rule 1)** — `8b7e4d0` (fix)
3. **Task 2: Run setup.sh — install deps, download model, seed config** — verified in-place against the post-Task-1 state; no new repo files modified, so no commit (per task type "auto" with empty `<files>`).
4. **Task 3: DEFERRED** — see Deviations.
5. **Hotkey rename directive (cross-cutting, post-checkpoint)** — `7030eee` (docs)

**Plan metadata commit:** to be applied after this SUMMARY is written.

## Files Created/Modified

### Created (Plan 01-01 in-scope outputs)
- `setup.sh` — Idempotent installer: brew deps, XDG dirs, model download with SHA256 verify, vocab seed, next-step reminders. 145 lines. Executable.
- `vocab.txt.default` — Seed vocabulary list (single comma-separated line of 18 D-08 terms). 1 line.
- `.gitignore` — Excludes models (`*.bin`), audio (`*.wav`), `/tmp/voice-cc/`, OS noise, editor cruft. 14 lines.
- `README.md` — Phase 1 stub with one-line value statement, status, hotkey, setup pointer, permissions reminder, Dictation-disable instruction. 34 lines.
- `.planning/phases/01-spike/01-01-SUMMARY.md` — This file.

### Modified (per Directive 2 hotkey rename — commit `7030eee`)
- `README.md` — Hotkey line + parenthetical historical note.
- `.planning/REQUIREMENTS.md` — CAP-03 default value.
- `.planning/ROADMAP.md` — Phase 1 goal line + success criterion #1.
- `.planning/STATE.md` — Decision-row entry + (separately) position advance for plan completion.
- `.planning/phases/01-spike/01-CONTEXT.md` — D-01 value + change-note + reference text.
- `.planning/phases/01-spike/01-01-PLAN.md` — Hotkey literal in frontmatter, interfaces, action steps, verify command, acceptance criterion (kept in sync so future replays validate against the new reality).
- `.planning/phases/01-spike/01-03-PLAN.md` — Lua bind tuple `{"cmd","shift"},"e"`, alert strings, walkthrough text, automated grep tests (anchored `'"e"[,)[:space:]]'` to avoid short-match false positives).
- `.planning/research/PITFALLS.md` — Pitfall 5 safe-list ordering + code example + table row.
- `.planning/research/ARCHITECTURE.md` — Diagram caption, T+0 / T+1500 flow lines, end-to-end walkthrough step.
- `.planning/research/SUMMARY.md` — Must-have list, honourable-mentions list, Phase-1 deliverable line, Pitfall-5 reference.
- `.planning/research/FEATURES.md` — Must-have table row + closing-thoughts §8.

## Decisions Made

- **MODEL_SHA256 corrected at execution time** (auto-fixed via Rule 1, see Deviations): plan's prefilled constant rejected the freshly-downloaded model; correct hash sourced from HuggingFace's `x-linked-etag` header.
- **Hotkey changed to `cmd+shift+e`** (user directive received post-checkpoint): all locked-decision documents updated; D-01 in CONTEXT.md now reflects the new value with a dated change-note. VS Code/Cursor "Show Explorer" conflict accepted.
- **Task 3 deferred to Plan 01-03's end-to-end walkthrough** (user directive): pipeline-isolation test merged into product-UX test.

## Deviations from Plan

Three deviations occurred during this plan's lifetime. All are documented below.

### Auto-fixed Issues

**1. [Rule 1 — Bug / stale data] Corrected MODEL_SHA256 constant**
- **Found during:** Task 2 (running setup.sh)
- **Issue:** The `MODEL_SHA256` constant baked into the plan was stale (placeholder `1be3a9b2…7b`). After `curl -C - -L` successfully downloaded the model, `shasum -a 256` produced `c6138d6d58ecc8322097e0f987c32f1be8bb0a18532a3f88f734d1bbf9c41e5d`, which the script correctly rejected as a mismatch (per the plan's own "do not silently accept a mismatched file" guidance). The model itself was uncorrupted — the constant was wrong, not the file.
- **Fix:** Sourced the authoritative SHA256 from HuggingFace's `x-linked-etag` HTTP response header on the model URL (the etag is the LFS object SHA256). Updated `MODEL_SHA256` in setup.sh to `c6138d6d58ecc8322097e0f987c32f1be8bb0a18532a3f88f734d1bbf9c41e5d`. Re-ran setup.sh; verification passed; idempotency re-proven on subsequent run.
- **Files modified:** `setup.sh`
- **Verification:** `shasum -a 256 ~/.local/share/voice-cc/models/ggml-small.en.bin` matches the new constant; setup.sh exits 0; second run prints "Model present, checksum OK, skipping".
- **Committed in:** `8b7e4d0` (`fix(01-01): correct stale ggml-small.en.bin SHA256 constant`)

### User-directed deviations (post-checkpoint)

**2. [Rule 4 → user decision] Task 3 deferred to Plan 01-03 end-to-end walkthrough**
- **Where in plan:** Task 3 (`type="checkpoint:human-verify"`) — manual sox + whisper-cli pipeline test (ARCHITECTURE.md STEP 1.1).
- **Why:** User requested that all manual verification for Phase 1 be consolidated into the actual product UX (the Plan 01-03 end-to-end button-press walkthrough that already exists as Task 2 of that plan), rather than performing intermediate terminal-only tests. Rationale per user: prefer to evaluate the system the way it will be used.
- **Where it migrates to:** Plan 01-03 Task 2 (`checkpoint:human-verify`, "End-to-end Phase 1 walkthrough — the 5 ROADMAP success criteria as a manual checklist"). That checkpoint already covers transcript correctness, vocab biasing, latency, punctuation/capitalisation, and absolute-path verification — i.e., the same ground Task 3 here would have covered, plus more.
- **Risk acknowledged:** If the end-to-end loop fails in Plan 01-03, debugging will be harder because pipeline-isolation tests were skipped — bash glue (Plan 02) and Hammerspoon wiring (Plan 03) will be debugged simultaneously rather than against a known-good pipeline baseline. Mitigation: Plan 02 includes its own manual `~/.local/bin/voice-cc-record` invocation test, which provides an intermediate isolation point if the Plan 03 walkthrough fails.
- **Status in this plan:** Task 3 marked **DEFERRED**, not "completed" and not "skipped". Manual pipeline test result section in this SUMMARY is `DEFERRED — see Plan 01-03 Task 2 walkthrough` rather than a fabricated transcript.
- **Files modified:** None for the deferral itself; documented in this SUMMARY.

**3. [Rule 4 → user decision] Hotkey changed from the original three-key combo to cmd+shift+e**
- **Where in plan:** D-01 in CONTEXT.md and every downstream reference (README.md, ROADMAP.md success criterion #1, REQUIREMENTS.md CAP-03, all research docs, 01-01-PLAN.md, 01-03-PLAN.md including the Lua bind code example).
- **Why:** User instruction received post-checkpoint. New locked decision: `cmd+shift+e` (Hammerspoon: `hs.hotkey.bind({"cmd", "shift"}, "e", ...)`).
- **Known conflict accepted by user:** VS Code / Cursor's "Show Explorer" sidebar shortcut. User has been informed and chosen to accept this trade-off.
- **Files updated:** README.md, .planning/REQUIREMENTS.md, .planning/ROADMAP.md, .planning/STATE.md, .planning/phases/01-spike/01-CONTEXT.md, .planning/phases/01-spike/01-01-PLAN.md, .planning/phases/01-spike/01-03-PLAN.md, .planning/research/PITFALLS.md, .planning/research/ARCHITECTURE.md, .planning/research/SUMMARY.md, .planning/research/FEATURES.md.
- **Verification:** the user-supplied audit grep over `.planning` and `README.md` for the old hotkey literal returns zero hits (verified post-edit).
- **Note on grep tests in 01-03-PLAN.md:** The automated verify command was updated from `grep -q '"alt"' && grep -q '"space"'` to `grep -q '"shift"' && grep -qE '"e"[,)[:space:]]'` — the trailing-character class on `"e"` prevents short-string false matches against any `e` literal that may appear elsewhere in the Lua source.
- **Note on 01-02-PLAN.md:** Per user "do not modify" instruction and per `grep -L` confirmation, Plan 02 contains zero hotkey references and was correctly left untouched.
- **Committed in:** `7030eee` (commit message: hotkey rename from the original three-key combo to cmd+shift+e per user request)

---

**Total deviations:** 1 auto-fixed (Rule 1, MODEL_SHA256), 2 user-directed (Task 3 deferral, hotkey rename).
**Impact on plan:** Auto-fix was essential (otherwise the model would never have been accepted by the integrity check). User-directed deviations are scope adjustments, not auto-decisions; both are documented for audit. No silent scope creep.

## Manual Pipeline Test Result

**DEFERRED — see Plan 01-03 Task 2 walkthrough.**

Per user directive, the Task 3 (`checkpoint:human-verify`) sox + whisper-cli pipeline-isolation test was not executed. The five-criterion end-to-end walkthrough at the close of Plan 01-03 will exercise the same pipeline through the actual product UX.

No transcript text, no measured latency, and no vocab-biasing A/B result are recorded here because none were observed. Future audits should not interpret the absence as a pass; it is a deliberate deferral.

## VAD Audit Result (Open TODO from STATE.md — Phase 2 reference)

`/opt/homebrew/bin/whisper-cli --help 2>&1 | grep -i vad` returned multiple lines confirming the brew bottle exposes the VAD interface:

- `--vad` (boolean flag to enable VAD)
- `--vad-model FNAME` — **default value is empty** (no Silero weights bundled)
- `--vad-threshold N` (default 0.50)
- `--vad-min-speech-duration-ms N` (default 250)
- `--vad-min-silence-duration-ms N` (default 100)
- `--vad-max-speech-duration-s N` (default FLT_MAX)
- `--vad-speech-pad-ms N` (default 30)
- `--vad-samples-overlap N` (default 0.10)

**Phase 2 implication:** the `--vad` flag exists, but `--vad-model` defaults to empty. Phase 2 must either (a) source Silero VAD model weights separately and set `--vad-model` explicitly, (b) determine whether a future brew bottle bundles them and pin the version that does, or (c) source-build whisper.cpp with VAD weights vendored. Recommend Phase 2 planning includes a small spike on Silero distribution mechanics before locking the VAD design.

## Issues Encountered

- **MODEL_SHA256 mismatch on first run** — resolved by Deviation #1 above. Setup.sh's fail-loud design caught it correctly (file deleted, exit non-zero, clear error message). No silent corruption risk.
- **No other issues during Tasks 1 or 2.** All other commands behaved as planned.

## User Setup Required

None — Plan 01-01 deliberately scopes out manual config. The setup script's final echo block does prompt the user to grant Microphone + Accessibility permissions to Hammerspoon (System Settings → Privacy & Security) and disable the macOS Dictation hotkey (System Settings → Keyboard → Dictation → Shortcut → Off). These are one-time actions due during/after Plan 01-03.

## Build-Order Status

**STEP 1.1 partial: deps installed and verified, manual pipeline test deferred to STEP 1.3 (Plan 03 end-to-end). Ready for Plan 02 (bash glue, STEP 1.2).**

The substantive prerequisites for Plan 02 are all satisfied:
- sox + whisper-cli reachable at absolute `/opt/homebrew/bin/*` paths.
- Model present and integrity-verified at `~/.local/share/voice-cc/models/ggml-small.en.bin`.
- Vocab present at `~/.config/voice-cc/vocab.txt`.
- XDG runtime layout in place (Plan 02 will create `~/.local/bin/voice-cc-record` as a symlink target).
- Hammerspoon installed (Plan 03 dependency, but not required for Plan 02 wave).

Plan 02 can begin in Wave 2 immediately.

## Next Phase Readiness

- **Wave 2 (Plan 01-02 — bash glue):** READY. All shell-side prerequisites in place.
- **Wave 3 (Plan 01-03 — Hammerspoon wiring):** READY when Plan 02 completes. Lua bind tuple + alert strings + walkthrough text in 01-03-PLAN.md already updated to the new `cmd+shift+e` hotkey.
- **Phase 2 (Hardening):** No new blockers. Note for Phase 2 planner: `--vad-model` default is empty in the brew bottle; budget time to source Silero weights or pin a bundled-VAD bottle version.

## Self-Check: PASSED

Files created — all exist:
- FOUND: setup.sh
- FOUND: vocab.txt.default
- FOUND: .gitignore
- FOUND: README.md

Commits referenced — all present in `git log`:
- FOUND: ccf34c2 (Task 1 setup.sh + vocab seed + .gitignore + README)
- FOUND: 8b7e4d0 (Deviation 1 — corrected MODEL_SHA256)
- FOUND: 7030eee (Deviation 3 — hotkey rename across repo)

Hotkey-rename grep test:
- The user-supplied audit grep over `.planning` and `README.md` for the old hotkey literal: exit 0, zero matches

---
*Phase: 01-spike*
*Plan: 01*
*Completed: 2026-04-27*
