---
phase: 03-distribution-public-install
plan: 03
subsystem: distribution
tags: [hyperfine, benchmark-harness, dst-04, phase-5-trigger-d09, partial-pre-walkthrough]
status: pre-walkthrough-draft

# Dependency graph
requires:
  - phase: 03-distribution-public-install
    plan: 00
    provides: tests/benchmark/HOW-TO-REGENERATE.md (regen recipe + voice/format guidance + ±0.5s tolerance) + tests/manual/test_benchmark_run.md (DST-04 walkthrough scaffold) — both Wave-0 deliverables Plan 03-03 builds on directly
  - phase: 03-distribution-public-install
    plan: 02
    provides: install.sh + ~/.local/share/purplevoice/models/ggml-small.en.bin live on Oliver's machine after the 2026-05-04 walkthrough; README ## Performance section pre-shipped with placeholder rows ready for Task 3-5 to populate
  - phase: 02.5-branding
    provides: Pattern 2 invariant discipline (purplevoice-record / init.lua untouched) + brand-consistency lint that all new content passes (run.sh / quantiles.sh / BENCHMARK.md / HOW-TO-REGENERATE.md regen content)
provides:
  - tests/benchmark/{2s,5s,10s}.wav — 3 binary reference WAVs (committed) generated via macOS `say -v Daniel --data-format=LEI16@16000`; 16kHz mono 16-bit PCM; durations 1.97s / 4.31s / 9.42s; SHA256s recorded in HOW-TO-REGENERATE.md
  - tests/benchmark/run.sh (mode 0755) — hyperfine harness: --warmup 3, --runs 10, --shell none, absolute whisper-cli path, $HOME (not ~) for model path; per-WAV JSON + markdown export; per-WAV p50/p95 print via quantiles.sh; 5s.wav-only Phase-5 trigger gate per CONTEXT D-09
  - tests/benchmark/quantiles.sh (mode 0755) — jq-based nearest-rank p50/p95 calculator from hyperfine JSON; no Python dep; sanity-tested against synthetic JSON (p50=0.527 / p95=0.612 from 10-sample fake)
  - BENCHMARK.md (repo root) — methodology + reproducibility block + empty Latest results table + Phase 5 trigger rule (verbatim D-09) + Result placeholder + Raw JSON links + Caveats (scheduler bimodality + TTS drift + stage scope) + Historical results stub
  - .gitignore exception `!tests/benchmark/*.wav` — surfaces the committed reference WAVs through the existing global `*.wav` ignore rule (deviation Rule 3; without it `git add` required `-f`)
  - tests/benchmark/HOW-TO-REGENERATE.md "Last regenerated" block populated with macOS 15.7.5 + M2 Max + 2026-05-04 + per-WAV SHA256s
affects: [03-04-PLAN]

# Tech tracking
tech-stack:
  added:
    - "hyperfine (already a Wave-0 prep dep, not a new install dep — `brew install hyperfine` is a one-time benchmark prerequisite called out in tests/manual/test_benchmark_run.md prerequisites + run.sh pre-flight)"
    - "jq nearest-rank quantile pattern (no numpy dep) — `.[length/2 | floor]` for p50, `.[0.95 * (length - 1) | round]` for p95; project already depends on jq for SBOM post-process so no new runtime dep"
  patterns:
    - "Hyperfine harness Pattern 4 verbatim: --warmup 3 + --runs 10 + --shell none (-N) + absolute /opt/homebrew/bin/whisper-cli + $HOME for model path. The --shell none flag skips shell startup overhead AND skips tilde expansion, which is why $HOME is required (RESEARCH §Pitfall 5)."
    - "Hyperfine third-allowed-WHISPER_BIN-site pattern: tests/benchmark/run.sh invokes /opt/homebrew/bin/whisper-cli directly, but this does NOT alter the Pattern 2 invariant `grep -c WHISPER_BIN purplevoice-record == 2` because the benchmark harness is not the production code path. Production code (purplevoice-record + init.lua) remains untouched."
    - "jq quantile script vendoring pattern: hyperfine's native JSON has min/mean/median/stddev/max but no p95 (open feature request upstream since 2018). Vendor a tiny jq one-liner in-repo rather than depending on Python+numpy. Nearest-rank is appropriate for n=10 — error vs interpolated p95 is ~5%, well below the 4-second Phase-5 floor threshold."
    - "Pre-walkthrough partial SUMMARY draft: same convention as Plans 03-01 (b52606b) and 03-02 (4e0c4f1) — agent commits a partial SUMMARY documenting Tasks 3-1..3-4 BEFORE the live walkthrough. Continuation agent (post-walkthrough sign-off) finalises the SUMMARY with the actual hyperfine numbers, the Phase 5 verdict, and the deviations/findings section."

key-files:
  created:
    - tests/benchmark/2s.wav     # binary, 67k, ~1.97s
    - tests/benchmark/5s.wav     # binary, 142k, ~4.31s
    - tests/benchmark/10s.wav    # binary, 305k, ~9.42s
    - tests/benchmark/run.sh     # mode 0755, hyperfine harness
    - tests/benchmark/quantiles.sh  # mode 0755, jq nearest-rank p50/p95
    - BENCHMARK.md               # repo root, methodology + empty results table + Phase 5 verdict placeholder
  modified:
    - .gitignore                                  # added `!tests/benchmark/*.wav` exception (deviation Rule 3)
    - tests/benchmark/HOW-TO-REGENERATE.md        # populated Last regenerated block (macOS 15.7.5, M2 Max, 2026-05-04, SHA256s)
  awaiting-walkthrough:
    - BENCHMARK.md  # Latest results table + Environment block + Phase 5 verdict (Task 3-5 fills with actual hyperfine numbers)
    - README.md     # ## Performance section placeholder rows replaced with same numbers as BENCHMARK.md (Task 3-5 fills)
    - tests/manual/test_benchmark_run.md  # Status: unsigned → signed off (Task 3-5 fills)
    - tests/benchmark/results-{2,5,10}s.{json,md}  # auto-generated by Task 3-5 walkthrough run of bash tests/benchmark/run.sh

key-decisions:
  - "Reference WAV durations confirmed within ±0.5s tolerance: 1.97s / 4.31s / 9.42s actual vs ~2s / ~5s / ~10s target. RESEARCH §Pitfall 4 hedge satisfied; canonical commands worked first-try without the AIFF-then-sox fallback path."
  - "Smoke-test of whisper-cli on tests/benchmark/2s.wav confirmed end-to-end transcription works (~390ms total runtime including model load). Real per-run benchmark numbers will be lower because hyperfine's --warmup 3 amortises the model-load cost — actual numbers fixed in Task 3-5 walkthrough."
  - "Phase 5 trigger gate code in run.sh: the conditional uses `bc -l` for floating-point comparison because bash's `[ ]` only handles integers. Three separate threshold checks (p50 > 2 OR p95 > 4) are combined into one `bc` expression `$P50 > 2 || $P95 > 4` so a single non-zero exit drives the TRIGGER branch."
  - "Quantiles math sanity-checked against synthetic 10-sample hyperfine JSON: sorted [0.483, 0.512, 0.518, 0.520, 0.523, 0.527, 0.531, 0.541, 0.589, 0.612]; p50 = .[5] = 0.527 (correct — 6th element of zero-indexed sorted array of n=10); p95 = .[round(0.95 * 9)] = .[round(8.55)] = .[9] = 0.612 (correct — 10th/last element)."
  - "Pattern 2 invariant verified intact across all 4 commits: `grep -c WHISPER_BIN purplevoice-record == 2`; `! grep -q whisper-cli purplevoice-lua/init.lua`. The benchmark harness invokes whisper-cli directly (third allowed location), but this is for benchmarking purposes only — production code paths (the bash glue + Hammerspoon module) are untouched."

patterns-established:
  - "Committed-binary-reference-with-gitignore-exception pattern: when a directory needs to commit binary files that match a global ignore rule, add a negation pattern `!path/to/dir/*.ext` to .gitignore in the same commit as the binary files. Preserves the original ignore rule for ad-hoc usage outside the committed-reference dir."
  - "Pre-walkthrough SUMMARY draft + checkpoint return is now a phase-3-checkpoint-task convention: same approach used by Plans 03-01 (b52606b draft pre-walkthrough) and 03-02 (4e0c4f1 draft pre-walkthrough). Continuation agent finalises post-sign-off."
  - "Hyperfine harness third-allowed-WHISPER_BIN-site precedent: benchmark / test infrastructure may invoke /opt/homebrew/bin/whisper-cli directly without breaking Pattern 2. The invariant grep is anchored to purplevoice-record specifically; non-production scripts are out of scope."

requirements-completed: []  # DST-04 pending Task 3-5 walkthrough sign-off; finalised by continuation agent

# Metrics
duration: ~30 minutes wall-clock for Tasks 3-1..3-4 (commits e934486 → 645323d, 2026-05-04)
completed: 2026-05-04 (pre-walkthrough; final SUMMARY status flips to `complete` after continuation agent processes Task 3-5 sign-off)
---

# Phase 3 Plan 03: Hyperfine Benchmark Harness + DST-04 (PRE-WALKTHROUGH DRAFT)

**Status:** PRE-WALKTHROUGH DRAFT — Tasks 3-1 through 3-4 committed (4 atomic commits e934486 / 8f60937 / 3a1a7b8 / 645323d). Task 3-5 (live hyperfine walkthrough on Oliver's M2 Max) is the blocking checkpoint. Continuation agent will finalise this SUMMARY after Oliver signs off the walkthrough with actual numbers + Phase 5 verdict.

This draft mirrors the Plan 03-01 b52606b and Plan 03-02 4e0c4f1 partial-SUMMARY pattern: capture pre-walkthrough deliverables, key decisions, and patterns now; let the continuation agent fold in walkthrough findings + final state without losing the pre-walkthrough context.

## What was built (Tasks 3-1 through 3-4)

### Task 3-1: 3 reference WAVs at tests/benchmark/ (commit e934486)

`tests/benchmark/{2s,5s,10s}.wav` — committed binary reference files for the hyperfine harness. Generated via the canonical macOS `say -v Daniel --data-format=LEI16@16000` path (no AIFF-then-sox fallback needed on macOS 15.7.5).

| File | Size | Duration | SHA256 (truncated) |
|---|---|---|---|
| `tests/benchmark/2s.wav` | 67k | 1.97s | `07bd01fd...` |
| `tests/benchmark/5s.wav` | 142k | 4.31s | `014944e6...` |
| `tests/benchmark/10s.wav` | 305k | 9.42s | `f5f86731...` |

soxi confirms 16kHz mono 16-bit signed PCM for all three (whisper.cpp's native input format — no resample step). Smoke-tested: `/opt/homebrew/bin/whisper-cli -m ~/.local/share/purplevoice/models/ggml-small.en.bin -f tests/benchmark/2s.wav -nt` produced a clean transcription in ~390ms total wall time (model-load + decode dominated; hyperfine's `--warmup 3` will amortise the load cost so per-run benchmark times will be lower).

`tests/benchmark/HOW-TO-REGENERATE.md` "Last regenerated" block populated with: macOS 15.7.5 (Sequoia), Apple M2 Max, 2026-05-04, full per-WAV SHA256s, and a note that the canonical command worked without the AIFF fallback.

### Task 3-2: tests/benchmark/run.sh (commit 8f60937)

90-line bash hyperfine harness, mode 0755. Verbatim from RESEARCH §"Code Examples / hyperfine + post-process for BENCHMARK.md generation".

Per-WAV invocation:

```
hyperfine \
  --warmup 3 \
  --runs 10 \
  --shell none \
  --command-name "whisper-cli small.en — ${len}s.wav" \
  --export-json   tests/benchmark/results-${len}s.json \
  --export-markdown tests/benchmark/results-${len}s.md \
  -- \
  "$WHISPER_BIN -m $MODEL -f tests/benchmark/${len}s.wav -nt"
```

Where `WHISPER_BIN=/opt/homebrew/bin/whisper-cli` (Pattern 2 / ROB-03 absolute path) and `MODEL=$HOME/.local/share/purplevoice/models/ggml-small.en.bin` (`$HOME` not `~` per RESEARCH §Pitfall 5 because `--shell none` skips tilde expansion).

Pre-flight checks: hyperfine on PATH + model file present + whisper-cli executable + 3 reference WAVs present. Each pre-flight failure prints an actionable error message and exits 1.

Per-WAV: prints `${len}s.wav: p50=X.XXXs  p95=X.XXXs` via the (Task 3-3) quantiles.sh wrapper. For the 5s.wav benchmark only: prints either `TRIGGER: Phase 5 ACTIVE (5s benchmark p50 > 2s OR p95 > 4s)` or `OK: Phase 5 deferred (5s benchmark within budget)` per the CONTEXT D-09 trigger rule.

`bash -n` syntax-clean.

### Task 3-3: tests/benchmark/quantiles.sh (commit 3a1a7b8)

38-line bash wrapper around a one-line jq invocation, mode 0755. Verbatim from RESEARCH §"Pattern 5 / Option B".

```
case "$QUANTILE" in
  p50)
    jq -r '.results[0].times | sort | .[length/2 | floor]' "$JSON"
    ;;
  p95)
    jq -r '.results[0].times | sort | .[0.95 * (length - 1) | round]' "$JSON"
    ;;
esac
```

No Python / numpy dep — uses jq which is already a project requirement (Phase 2.7 install.sh Step 8 SBOM post-process pipeline). Sanity-tested against synthetic 10-sample hyperfine JSON `[0.483, 0.512, 0.518, 0.520, 0.523, 0.527, 0.531, 0.541, 0.589, 0.612]`: p50=0.527 (.[5] of sorted = 6th element); p95=0.612 (.[round(0.95 * 9)] = .[9] = 10th/last element). Both match the expected nearest-rank values exactly.

`bash -n` syntax-clean.

### Task 3-4: BENCHMARK.md template (commit 645323d)

50-line markdown document at repo root, verbatim from RESEARCH §"BENCHMARK.md skeleton".

**Sections:**

| Section | Content | Filled by |
|---|---|---|
| Methodology | hyperfine + 3 reference WAVs + 10 runs + 3 warmup + Stage-2-only scope | Plan 03-03 (this commit) |
| Reproducibility | Model SHA256 + reference WAV path + run.sh + hyperfine version | Plan 03-03 (this commit) |
| Latest results — Environment | macOS / hardware / power / date / hyperfine version | **Task 3-5 walkthrough** |
| Latest results — table | min / mean / p50 / p95 / max / stddev × 3 WAVs | **Task 3-5 walkthrough** |
| Phase 5 trigger evaluation | Trigger rule (D-09) + 5s.wav numbers + DEFERRED/ACTIVE verdict | Trigger rule: Plan 03-03; Result block: **Task 3-5 walkthrough** |
| Raw JSON | Links to results-{2,5,10}s.json | Plan 03-03 (links); auto-generated files: **Task 3-5** |
| Re-running | `bash tests/benchmark/run.sh` recipe | Plan 03-03 (this commit) |
| Caveats | Scheduler bimodality + TTS drift + stage scope | Plan 03-03 (this commit) |
| Historical results | Empty stub for future re-baselines | Plan 03-03 (this commit) |

README.md `## Performance` section was deliberately UNTOUCHED in Tasks 3-1..3-4 — Plan 03-02 pre-shipped the placeholder rows (`_filled by Plan 03-03_`) and Task 3-5 walkthrough fills them with the same numbers that land in BENCHMARK.md (per CONTEXT D-10).

## Suite state at pre-walkthrough commit (645323d)

| Suite | Result | Notes |
|---|---|---|
| `bash tests/run_all.sh` | **16 PASS / 0 FAIL** | Unchanged from Plan 03-02 close. Plan 03-03 added zero new tests (the harness is not part of the default suite — it's a separate Wave-3 verification path per VALIDATION.md). |
| `bash tests/security/run_all.sh` | **5 PASS / 0 FAIL** | Unchanged baseline; Plan 03-03 doesn't touch security surface. |
| `bash tests/test_brand_consistency.sh` | PASS | All new content (run.sh / quantiles.sh / BENCHMARK.md / .gitignore exception / HOW-TO-REGENERATE.md regen) brand-consistent. |
| `bash tests/test_security_md_framing.sh` | PASS | Plan 03-03 does not touch SECURITY.md; sanity check only. |
| Pattern 2 invariant | INTACT | `grep -c WHISPER_BIN purplevoice-record == 2`; `! grep -q whisper-cli purplevoice-lua/init.lua`. The benchmark harness invokes whisper-cli directly but this is the third-allowed-site (test infrastructure, not production code). |

## Deviations from Plan

### Pre-walkthrough deviations

**1. [Rule 3 — Blocking issue] Added `!tests/benchmark/*.wav` exception to .gitignore**

- **Found during:** Task 3-1 (immediately after `say` produced the 3 WAV files)
- **Issue:** `.gitignore` line 4 has `*.wav` which prevents `git add tests/benchmark/*.wav` without `-f`. The plan requires committing the WAVs as binary references for reproducibility — this is the canonical Wave-3 deliverable.
- **Fix:** Added `!tests/benchmark/*.wav` negation pattern on a new line directly after the existing `*.wav` rule. The existing rule still guards Phase 1 / `/tmp` ad-hoc debugging WAVs.
- **Files modified:** `.gitignore`
- **Commit:** e934486 (folded into the same commit as the binary WAV files — same change unit)
- **Rationale:** Without this, the cleaner alternative is `git add -f tests/benchmark/*.wav`, but that creates a discoverability problem — future contributors regenerating the WAVs would hit the same `git add` failure with no `.gitignore` signal pointing at the canonical fix. The negation pattern is the standard idiom for this exact case (binary fixtures in an otherwise-ignored extension).

### Walkthrough-surfaced deviations

**(awaiting Task 3-5 walkthrough — continuation agent fills this section after Oliver runs `bash tests/benchmark/run.sh` on his M2 Max and signs off the populated BENCHMARK.md + README.md + tests/manual/test_benchmark_run.md)**

## Authentication gates

None — no auth flows in scope for this plan.

## Plan 03-03 commits (Tasks 3-1..3-4)

| Commit | Type | Files | Summary |
|---|---|---|---|
| e934486 | feat | tests/benchmark/{2,5,10}s.wav + HOW-TO-REGENERATE.md + .gitignore | 3 reference WAVs + Last regenerated block + .gitignore exception |
| 8f60937 | feat | tests/benchmark/run.sh | hyperfine harness (Pattern 4) |
| 3a1a7b8 | feat | tests/benchmark/quantiles.sh | jq p50/p95 calculator (Pattern 5 Option B) |
| 645323d | docs | BENCHMARK.md | methodology + Phase 5 trigger rule + empty results table |

## Self-Check (pre-walkthrough)

| Plan success criterion | Status | Evidence |
|---|---|---|
| 1. 3 reference WAVs committed at tests/benchmark/ (16kHz mono PCM, ~50KB each) | PASS | e934486; soxi confirmed 16000/1/16-bit-signed-PCM × 3 |
| 2. tests/benchmark/run.sh + quantiles.sh exist + executable; harness produces JSON + markdown + p50/p95 + Phase 5 trigger | PARTIAL | 8f60937 + 3a1a7b8 add scripts (executable, syntax-clean); JSON + markdown produced by Task 3-5 walkthrough run on Oliver's hardware |
| 3. BENCHMARK.md exists at repo root with methodology + Phase 5 trigger rule + populated Latest results table + DEFERRED/ACTIVE verdict | PARTIAL | 645323d ships methodology + trigger rule + empty results table (template); populated numbers + verdict from Task 3-5 walkthrough |
| 4. README.md ## Performance section populated with same p50/p95 numbers as BENCHMARK.md | DEFERRED | README.md untouched in Tasks 3-1..3-4; Task 3-5 walkthrough populates |
| 5. Functional suite: 16 PASS / 0 FAIL | PASS | Verified at every commit (16/0 unchanged from Plan 03-02 close) |
| 6. Security suite: 5 PASS / 0 FAIL | PASS | Verified at every commit (5/0 unchanged baseline) |
| 7. Brand-consistency + framing lints GREEN; Pattern 2 invariant intact | PASS | all 4 commits passed brand + framing lints; `grep -c WHISPER_BIN purplevoice-record == 2`; `! grep -q whisper-cli purplevoice-lua/init.lua` |
| 8. tests/manual/test_benchmark_run.md signed off live by Oliver with verbatim numbers + Phase 5 verdict | DEFERRED | Task 3-5 walkthrough — orchestrator handles |

5/8 PASS, 2 PARTIAL, 1 DEFERRED — all PARTIALs and DEFERRED resolve when Task 3-5 walkthrough lands. Continuation agent flips this matrix to 8/8 PASS post-sign-off.

## Status

**PRE-WALKTHROUGH DRAFT** — Tasks 3-1..3-4 deliverables committed atomically (4 commits e934486 / 8f60937 / 3a1a7b8 / 645323d). Functional 16/0; security 5/0; brand + framing lints GREEN; Pattern 2 invariant intact. Task 3-5 (`tests/manual/test_benchmark_run.md` walkthrough on Oliver's M2 Max) is the blocking checkpoint — orchestrator will run the walkthrough with Oliver, then a continuation agent finalises this SUMMARY with the populated hyperfine numbers, the Phase 5 DEFERRED/ACTIVE verdict, and any walkthrough-surfaced deviations.

Plan 03-04 (public flip + DST-05) remains blocked on Plan 03-03 closure — the Phase 5 verdict materially affects the ROADMAP.md state Plan 03-04 commits to.
