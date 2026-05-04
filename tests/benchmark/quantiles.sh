#!/usr/bin/env bash
# tests/benchmark/quantiles.sh — print p50 OR p95 from a hyperfine JSON file.
#
# Per RESEARCH.md §Pattern 5 / Pitfall 6: hyperfine native JSON has min/mean/
# median/stddev/max but no p95. We post-process the times[] array via jq
# nearest-rank quantile (no interpolation; matches numpy default within ~5%
# for n=10, well below the Phase 5 4-second threshold floor).
#
# Usage:
#   bash tests/benchmark/quantiles.sh tests/benchmark/results-5s.json p50
#   bash tests/benchmark/quantiles.sh tests/benchmark/results-5s.json p95

set -euo pipefail

JSON="${1:-}"
QUANTILE="${2:-p50}"

if [ -z "$JSON" ] || [ ! -f "$JSON" ]; then
  echo "Usage: $0 <hyperfine-results.json> <p50|p95>" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq not found (required for quantile computation)" >&2
  exit 1
fi

case "$QUANTILE" in
  p50)
    # Median: middle index (length/2 floor) of sorted times[]
    jq -r '.results[0].times | sort | .[length/2 | floor]' "$JSON"
    ;;
  p95)
    # Nearest-rank p95: index round(0.95 * (n-1)) of sorted times[]
    jq -r '.results[0].times | sort | .[0.95 * (length - 1) | round]' "$JSON"
    ;;
  *)
    echo "ERROR: quantile '$QUANTILE' unknown. Use 'p50' or 'p95'." >&2
    exit 1
    ;;
esac
