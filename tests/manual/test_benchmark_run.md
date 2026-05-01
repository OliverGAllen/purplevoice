# Manual walkthrough: hyperfine benchmark on Oliver's hardware (DST-04)

**Status:** unsigned
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
DST-04 hyperfine benchmark walkthrough — signed off YYYY-MM-DD by Oliver
- 5s.wav p50: __ s     5s.wav p95: __ s
- 2s.wav p50: __ s     2s.wav p95: __ s
- 10s.wav p50: __ s    10s.wav p95: __ s
- Phase 5 verdict: DEFERRED / ACTIVE
- Numbers committed to BENCHMARK.md
```

## Failure modes

- hyperfine reports `command not found: whisper-cli` → install.sh did not install whisper-cpp on this machine; re-run install.sh.
- hyperfine fails with "file not found ~/.local/share/..." → tilde-expansion bug in run.sh (RESEARCH Pitfall 5); use `$HOME` not `~` in the hyperfine command.
- numbers wildly inconsistent (stddev > 30% of mean) → thermal throttling / E-vs-P-core scheduling drift (RESEARCH Pitfall 10); re-run on AC power; consider `--runs 30`.
- 5s.wav p95 > 4s → Phase 5 ACTIVE; surface to user; replan Phase 5 next.
