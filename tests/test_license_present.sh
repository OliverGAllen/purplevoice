#!/usr/bin/env bash
# tests/test_license_present.sh — LICENSE file presence + canonical MIT text.
#
# Per Phase 3 CONTEXT D-07 / RESEARCH §"MIT LICENSE canonical text": LICENSE at
# repo root with the canonical opensource.org/license/mit text + Copyright
# (c) 2026 Oliver Allen.
#
# RED at Wave 0 commit — LICENSE does not yet exist (created in Plan 03-02).

set -uo pipefail
cd "$(dirname "$0")/.."   # repo root

if [ ! -f LICENSE ]; then
  echo "FAIL [test_license_present.sh]: LICENSE not found at repo root (Plan 03-02 creates it)"
  exit 1
fi

FAIL=0

# Required canonical phrases (verifying full MIT text was pasted, not paraphrased).
REQUIRED=(
  "MIT License"
  "Copyright (c) 2026 Oliver Allen"
  "Permission is hereby granted"
  'THE SOFTWARE IS PROVIDED "AS IS"'
)
for phrase in "${REQUIRED[@]}"; do
  if ! grep -qF "$phrase" LICENSE; then
    echo "FAIL [test_license_present.sh]: LICENSE missing required phrase: $phrase"
    FAIL=1
  fi
done

if [ "$FAIL" -eq 0 ]; then
  echo "PASS [test_license_present.sh]: LICENSE present with canonical MIT text + correct copyright"
  exit 0
fi
exit 1
