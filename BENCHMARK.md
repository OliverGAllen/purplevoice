# PurpleVoice Performance Benchmark

**Methodology:** transcription-only via [hyperfine](https://github.com/sharkdp/hyperfine) on 3 pre-recorded reference WAVs (synthetic TTS via macOS `say -v Daniel`, 16kHz mono PCM). Each benchmark: 10 runs + 3 warmup runs. Stage-1 (recording, user-bound) and Stage-3 (paste, near-constant) are NOT measured — Stage-2 (whisper-cli transcription) is the dominant + variable component.

**Reproducibility:**
- Whisper model: `ggml-small.en.bin`, SHA256 `c6138d6d58ecc8322097e0f987c32f1be8bb0a18532a3f88f734d1bbf9c41e5d` (488 MB). Download via `install.sh` Step 5; verify SHA via `shasum -a 256`.
- Reference WAVs: committed binary files at `tests/benchmark/{2,5,10}s.wav`. Regeneration command in [tests/benchmark/HOW-TO-REGENERATE.md](tests/benchmark/HOW-TO-REGENERATE.md).
- Benchmark runner: [tests/benchmark/run.sh](tests/benchmark/run.sh) (uses [tests/benchmark/quantiles.sh](tests/benchmark/quantiles.sh) for p50/p95 post-process).
- hyperfine version: 1.20.0+ (verified via `hyperfine --version`).

## Latest results

**Environment:** _filled by Plan 03-03 walkthrough sign-off_
- macOS version: ____
- Apple Silicon: M__ (cores: ___ E + ___ P)
- Power state: AC adapter (battery throttles aggressively per RESEARCH §Pitfall 10)
- Date: 2026-__-__
- hyperfine version: ____

| Utterance length | min | mean | median (p50) | p95 | max | stddev |
|---|---|---|---|---|---|---|
| 2s.wav | __ s | __ s | __ s | __ s | __ s | __ s |
| 5s.wav | __ s | __ s | __ s | __ s | __ s | __ s |
| 10s.wav | __ s | __ s | __ s | __ s | __ s | __ s |

## Phase 5 trigger evaluation

**Trigger rule (Phase 3 CONTEXT D-09):** Phase 5 (warm-process upgrade) becomes active scope IF the 5s.wav benchmark shows `p50 > 2s OR p95 > 4s`.

**Result:** _filled by run.sh / Oliver post-walkthrough_
- 5s.wav p50 = __ s
- 5s.wav p95 = __ s
- Phase 5: **DEFERRED** (delete one) / **ACTIVE** (delete one)

## Raw JSON

Full hyperfine output:
- [tests/benchmark/results-2s.json](tests/benchmark/results-2s.json)
- [tests/benchmark/results-5s.json](tests/benchmark/results-5s.json)
- [tests/benchmark/results-10s.json](tests/benchmark/results-10s.json)

## Re-running benchmarks

```bash
bash tests/benchmark/run.sh
```

The `run.sh` script regenerates the JSON + markdown exports + prints the Phase-5 trigger evaluation. Re-baseline this `BENCHMARK.md` after a meaningful environment change (new macOS version, model file change, hardware change).

## Caveats

- **Apple Silicon scheduler bimodality** (RESEARCH §Pitfall 10): hyperfine's `--warmup 3` warms filesystem cache + page cache, but macOS QoS scheduler decisions (E-cores vs P-cores) and thermal-throttling kick-in are not "warmable" in 3 sub-second runs. If stddev > 30% of mean, consider `--runs 30` or run on AC power.
- **TTS reproducibility drift** (RESEARCH §Pitfall 4): `say -v Daniel` synthesis is NOT byte-identical across macOS major versions. The committed WAVs in `tests/benchmark/` are the canonical reference. Re-running on a different macOS version may produce slightly different transcription times — re-baseline this document if drift exceeds ±10%.
- **Stage scope** (CONTEXT D-08): only Stage-2 (whisper-cli transcription) is measured. Stage-1 (recording duration; user-bound) and Stage-3 (paste; near-constant) are intentionally out of scope for v1. End-to-end benchmark harness deferred per CONTEXT D-08 — Stage-2 dominates anyway.

## Historical results

_Pre-Phase-3 measurements (if any) and post-environment-change re-baselines land here as new H3 sections._
