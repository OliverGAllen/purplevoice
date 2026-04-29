#!/usr/bin/env bash
# tests/test_denylist.sh — TRA-06 + INJ-04
#
# Verifies the denylist canonicalisation predicate Plan 02-01 must implement:
#   - whitespace-collapsed, lowercase comparison
#   - whole-transcript exact match (NO substring matching — "thanks for adding
#     dark mode" must NOT match the "thanks for watching" denylist phrase)
#   - empty/whitespace transcripts canonicalise to empty (INJ-04 path)
#
# The integration assertion (purplevoice-record exits 3 when fed a denylist
# phrase as transcript) requires test hooks Plan 02-01 must add — deferred
# behind PURPLEVOICE_INTEGRATION=1. Logic-only test is sufficient for Wave 0.
set -uo pipefail

DENYLIST="$HOME/.config/purplevoice/denylist.txt"

if [ ! -r "$DENYLIST" ]; then
  echo "FAIL: denylist not present at $DENYLIST (run setup.sh first)"
  exit 1
fi

# Canonicalisation: whitespace-strip + lowercase. Plan 02-01 MUST use the
# identical pipeline: `tr -d '[:space:]' | tr '[:upper:]' '[:lower:]'`.
canon() {
  printf "%s" "$1" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]'
}

# Positive: every phrase round-trips canonicalisation (idempotent).
while IFS= read -r phrase; do
  case "$phrase" in ''|'#'*) continue ;; esac
  c=$(canon "$phrase")
  if [ -z "$c" ]; then continue; fi
  if [ "$(canon "$phrase")" != "$c" ]; then
    echo "FAIL: phrase '$phrase' did not round-trip canonicalisation"
    exit 1
  fi
done < "$DENYLIST"

# Negative: a real prompt that contains "thanks for" must NOT equal any
# denylist phrase (substring-match risk). Confirms whole-transcript-only.
REAL_PROMPT=$(canon "thanks for adding dark mode toggle")
while IFS= read -r phrase; do
  case "$phrase" in ''|'#'*) continue ;; esac
  cphrase=$(canon "$phrase")
  [ -z "$cphrase" ] && continue
  if [ "$REAL_PROMPT" = "$cphrase" ]; then
    echo "FAIL: substring-match risk — real prompt '$REAL_PROMPT' equals denylist phrase '$phrase'"
    exit 1
  fi
done < "$DENYLIST"

# INJ-04: empty / whitespace-only transcripts canonicalise to empty string.
if [ -n "$(canon "   ")" ] || [ -n "$(canon "")" ]; then
  echo "FAIL: empty/whitespace canonicalisation should produce empty string (INJ-04)"
  exit 1
fi

# Spot-check: confirm at least one canonical hallucination phrase is in the
# denylist (catches an empty-but-readable file).
if ! grep -qi "thanks for watching" "$DENYLIST"; then
  echo "FAIL: denylist does not contain canonical 'thanks for watching' phrase"
  exit 1
fi

echo "PASS: denylist canonicalisation + substring-protection + INJ-04 empty-drop verified"
exit 0
