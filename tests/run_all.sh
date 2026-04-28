#!/usr/bin/env bash
# tests/run_all.sh — Phase 2 test suite runner
#
# Iterates every tests/test_*.sh in alphabetical order, runs each with bash,
# captures pass/fail by exit code, prints per-test status, prints final
# summary, exits 0 only if ALL passed.
#
# Deliberately omits `set -e` so a failing test doesn't abort the suite.
# Each test_*.sh is a standalone executable (no test runner needed).
set -uo pipefail

cd "$(dirname "$0")/.."   # repo root

PASS=0
FAIL=0
FAILED=()

for f in tests/test_*.sh; do
  [ -f "$f" ] || continue
  printf "  [test] %-40s " "$(basename "$f")"
  if bash "$f" >/tmp/voice-cc-test.log 2>&1; then
    echo "PASS"
    PASS=$((PASS + 1))
  else
    echo "FAIL"
    FAIL=$((FAIL + 1))
    FAILED+=("$f")
  fi
done

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  echo "Failed tests:"
  printf "  - %s\n" "${FAILED[@]}"
  exit 1
fi
exit 0
