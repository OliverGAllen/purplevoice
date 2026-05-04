# Manual walkthrough: hyperfine benchmark on Oliver's hardware (DST-04)

**Status:** signed off 2026-05-04 by Oliver (initially DEFERRED earlier same day; benchmark ran later in the same session on AC power; Phase 5 verdict DEFERRED — 5s.wav within budget)
**Created:** 2026-05-01 (Plan 03-00)
**Sign-off path:** Plan 03-03 (autonomous: false; the only person who can produce the numbers is Oliver on his machine)
**Phase:** 3 — Distribution & Public Install
**Requirement:** DST-04 (hyperfine produces p50/p95 for 2s/5s/10s WAVs; gates Phase 5 go/no-go per CONTEXT D-09)

## Why this is manual

Benchmark numbers are hardware-specific. They cannot be mocked, pre-computed, or run in CI — they must come from Oliver's actual M-series MacBook Pro under his actual thermal state and his actual macOS version. The Phase 5 trigger (p50 > 2s OR p95 > 4s on 5s.wav) is a binary gate evaluated against numbers from this walkthrough.

## Prerequisites

- [ ] Plan 03-03 complete (`tests/benchmark/{2s,5s,10s}.wav` + `tests/benchmark/run.sh` + `tests/benchmark/quantiles.sh` + initial `BENCHMARK.md` template all exist)
- [ ] `brew install hyperfine` (one-time; not a runtime dep)
- [ ] `~/.local/share/purplevoice/models/ggml-small.en.bin` present and SHA256 matches (run `bash install.sh` if not)
- [ ] On AC power (battery throttles aggressively per RESEARCH §Pitfall 10)

## Steps

1. From repo root: `brew info hyperfine | head -3` → confirm v1.20.0+ installed.
2. `bash tests/benchmark/run.sh 2>&1 | tee /tmp/p3-benchmark.log`
   - The script runs hyperfine for each of 2s.wav, 5s.wav, 10s.wav (10 runs + 3 warmup each); writes JSON + markdown exports to `tests/benchmark/results-{2,5,10}s.{json,md}`; prints p50/p95 per length.
3. **PASS criterion 1:** Exit code 0; 3 JSON files written; 3 markdown files written.
4. `bash tests/benchmark/quantiles.sh tests/benchmark/results-5s.json` → confirm p50/p95 numbers reported.
5. **PASS criterion 2:** p50 + p95 numerical (not "?" or "null"); reproducible on re-run within ±10%.

### Populating BENCHMARK.md
6. Open `BENCHMARK.md`; fill the placeholders in the "Latest results" table:
   - macOS version: `sw_vers -productVersion`
   - Apple Silicon: `sysctl -n machdep.cpu.brand_string`
   - Date: today (YYYY-MM-DD)
   - Per-length min/mean/median/p95/max/stddev: copy from the hyperfine markdown exports
7. Fill the "Phase 5 trigger evaluation" block:
   - 5s.wav p50 = ___s
   - 5s.wav p95 = ___s
   - Phase 5: **DEFERRED** (if p50 ≤ 2s AND p95 ≤ 4s) OR **ACTIVE** (if either crosses)
8. **PASS criterion 3:** BENCHMARK.md "Phase 5: DEFERRED" or "Phase 5: ACTIVE" line is filled in (not a placeholder).
9. `git add tests/benchmark/results-*.{json,md} BENCHMARK.md && git commit -m "perf(03): populate hyperfine benchmark results + Phase 5 gate"`.

## Sign-off

```
DST-04 hyperfine benchmark walkthrough — signed off 2026-05-04 by Oliver
- 5s.wav p50: 0.589 s     5s.wav p95: 0.605 s
- 2s.wav p50: 0.583 s     2s.wav p95: 0.591 s
- 10s.wav p50: 1.093 s    10s.wav p95: 1.101 s
- Phase 5 verdict: DEFERRED (5s.wav p50 0.589s ≤ 2s threshold AND p95 0.605s ≤ 4s threshold; ~3.4× and ~6.6× margin; cold-start pipeline within budget on M2 Max — warm-process daemon not required for v1.x)
- Numbers committed to BENCHMARK.md + README.md ## Performance section
- Environment: M2 Max (8 P + 4 E), macOS 15.7.5 (Sequoia), AC power, hyperfine 1.20.0
- Stddev tiny (~5-6 ms across all lengths) — measurement very stable
```

### Live findings

1. **Initial deferral was reversed same-session.** The walkthrough scaffold initially recorded "DEFERRED 2026-05-04 by Oliver" earlier in the day; later in the same session Oliver chose to run the benchmark before kicking off Phase 5 to get an informed verdict. Both the pre-deferral state and the resume path were tested in real life — the resume path is just `brew install hyperfine && bash tests/benchmark/run.sh` exactly as documented in BACKLOG#2 + the partial-SUMMARY status block.

2. **Pattern 4 hyperfine harness held up under real load.** `--shell none` + absolute `whisper-cli` path + `$HOME` (not `~`) for the model produced clean numbers with no warnings. `--warmup 3` amortised the model-load cost as designed (initial smoke-test on 2s.wav had measured ~390ms total wall time; warmed runs land in the 583-590ms range — model-load contribution roughly half of cold-start, fully amortised).

3. **Phase 2 invariant ("transcribe() is a single bash function for v1.1 drop-in swap") preserved as Phase 5 future-proofing.** With Phase 5 now DEFERRED, the warm-process daemon stays as latent capability rather than active scope. If a future hardware change or larger model crosses the 5s.wav 2s/4s thresholds, only `transcribe()` body needs to swap — the rest of the bash glue + Hammerspoon module + Karabiner rules + HUD all stay untouched. Pattern 2 was load-bearing exactly here.

4. **Stddev across all 3 WAV lengths is sub-7ms.** Hyperfine's bimodality concern (RESEARCH §Pitfall 10 — Apple Silicon E-vs-P-core scheduling drift) did not manifest at this hardware/load combination; AC power + thermal headroom kept the M2 Max in a stable scheduling regime across all 30 measured runs.

## Failure modes

- hyperfine reports `command not found: whisper-cli` → install.sh did not install whisper-cpp on this machine; re-run install.sh.
- hyperfine fails with "file not found ~/.local/share/..." → tilde-expansion bug in run.sh (RESEARCH Pitfall 5); use `$HOME` not `~` in the hyperfine command.
- numbers wildly inconsistent (stddev > 30% of mean) → thermal throttling / E-vs-P-core scheduling drift (RESEARCH Pitfall 10); re-run on AC power; consider `--runs 30`.
- 5s.wav p95 > 4s → Phase 5 ACTIVE; surface to user; replan Phase 5 next.
