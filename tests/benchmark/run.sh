#!/usr/bin/env bash
# tests/benchmark/run.sh — Phase 3 hyperfine benchmark runner (DST-04).
#
# Runs whisper-cli via hyperfine on the 3 reference WAVs in this directory.
# Writes JSON + markdown exports; prints p50/p95 + Phase 5 trigger verdict for
# the 5s.wav benchmark.
#
# Per RESEARCH.md §Pattern 4: --warmup 3 + --runs 10 + --shell none (-N) +
# absolute whisper-cli path (Pattern 2 / ROB-03 invariant).
# Per RESEARCH.md §Pitfall 5: use $HOME not ~ for the model path (-N skips shell).
# Per RESEARCH.md §Pitfall 10: run on AC power for stable Apple Silicon scheduling.
#
# Prerequisites:
#   brew install hyperfine
#   bash install.sh    (provides ~/.local/share/purplevoice/models/ggml-small.en.bin)

set -euo pipefail
cd "$(dirname "$0")/../.."   # repo root

MODEL="$HOME/.local/share/purplevoice/models/ggml-small.en.bin"
WHISPER_BIN="/opt/homebrew/bin/whisper-cli"

# Pre-flight checks
if ! command -v hyperfine >/dev/null 2>&1; then
  echo "ERROR: hyperfine not found. Install via: brew install hyperfine" >&2
  exit 1
fi
if [ ! -f "$MODEL" ]; then
  echo "ERROR: Whisper model not found at $MODEL. Run: bash install.sh" >&2
  exit 1
fi
if [ ! -x "$WHISPER_BIN" ]; then
  echo "ERROR: whisper-cli not executable at $WHISPER_BIN. Run: bash install.sh" >&2
  exit 1
fi
for len in 2 5 10; do
  if [ ! -f "tests/benchmark/${len}s.wav" ]; then
    echo "ERROR: tests/benchmark/${len}s.wav not found. See tests/benchmark/HOW-TO-REGENERATE.md" >&2
    exit 1
  fi
done

mkdir -p tests/benchmark

for len in 2 5 10; do
  echo ""
  echo "================================================================="
  echo "Benchmarking ${len}s.wav (10 runs + 3 warmup; --shell none)"
  echo "================================================================="
  hyperfine \
    --warmup 3 \
    --runs 10 \
    --shell none \
    --command-name "whisper-cli small.en — ${len}s.wav" \
    --export-json   "tests/benchmark/results-${len}s.json" \
    --export-markdown "tests/benchmark/results-${len}s.md" \
    -- \
    "$WHISPER_BIN -m $MODEL -f tests/benchmark/${len}s.wav -nt"

  # Compute p50 / p95 from the JSON via the bundled jq quantile script.
  P50=$(bash tests/benchmark/quantiles.sh "tests/benchmark/results-${len}s.json" p50)
  P95=$(bash tests/benchmark/quantiles.sh "tests/benchmark/results-${len}s.json" p95)
  echo ""
  echo "  ${len}s.wav: p50=${P50}s  p95=${P95}s"

  # Phase-5 trigger gate (only the 5s.wav benchmark per CONTEXT D-09).
  if [ "$len" = "5" ]; then
    if (( $(echo "$P50 > 2 || $P95 > 4" | bc -l) )); then
      echo "  TRIGGER: Phase 5 ACTIVE (5s benchmark p50 > 2s OR p95 > 4s)"
    else
      echo "  OK: Phase 5 deferred (5s benchmark within budget)"
    fi
  fi
done

echo ""
echo "================================================================="
echo "Done. Update BENCHMARK.md with the numbers above + Phase 5 verdict."
echo "Raw JSON: tests/benchmark/results-{2,5,10}s.json"
echo "Markdown: tests/benchmark/results-{2,5,10}s.md"
echo "================================================================="
