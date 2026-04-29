#!/usr/bin/env bash
# tests/security/run_all.sh — Phase 2.7 security verification suite runner.
#
# Iterates every tests/security/verify_*.sh in alphabetical order, runs each
# with bash, captures pass/fail by exit code, prints per-test status, prints
# final summary, exits 0 only if ALL passed.
#
# Mirrors tests/run_all.sh structurally (Pattern A); two intentional differences:
#   - log path is /tmp/purplevoice-security-test.log (Pitfall 9 — distinguishable)
#   - per-line prefix is "[security]" (Pitfall 9 — distinguishable from [test])
#
# Deliberately omits `set -e` so a failing verify_*.sh doesn't abort the suite.
set -uo pipefail

cd "$(dirname "$0")/../.."   # repo root (one extra ../ — security/ is one level deeper than tests/)

PASS=0
FAIL=0
FAILED=()

for f in tests/security/verify_*.sh; do
  [ -f "$f" ] || continue
  printf "  [security] %-40s " "$(basename "$f")"
  if bash "$f" >/tmp/purplevoice-security-test.log 2>&1; then
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
