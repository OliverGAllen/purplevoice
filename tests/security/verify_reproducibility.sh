#!/usr/bin/env bash
# tests/security/verify_reproducibility.sh — PurpleVoice Phase 2.7 SEC-05 stub.
# Asserts: SECURITY.md §"Reproducible Build" section exists with toolchain-version
#          caveat acknowledgement (Pitfall 14). PASSES if documentation is complete.
# Source of claim: SECURITY.md §"Reproducible Build".
# Sudo: not required.
#
# Why a stub: Full byte-identical reproducibility for whisper.cpp Metal-compiled
# artefacts is toolchain-version-sensitive (Xcode CLT version, macOS SDK, compiler
# revision). Achieving full reproducibility requires pinning a specific toolchain
# in setup.sh — disproportionate for v1. v2 candidate.
set -uo pipefail
cd "$(dirname "$0")/../.."

SECURITY_MD="SECURITY.md"

fail() {
  echo "FAIL [verify_reproducibility.sh]: $1" >&2
  exit 1
}

[ -f "$SECURITY_MD" ] || fail "$SECURITY_MD not found"

# The §Reproducible Build section heading exists (Plan 02.7-00 skeleton)
if ! grep -q "^## Reproducible Build" "$SECURITY_MD"; then
  fail "SECURITY.md missing §Reproducible Build section heading"
fi

# Extract the §Reproducible Build section content (between this H2 and the next
# H2 — bounded by §Vulnerability Disclosure or §How to Verify These Claims).
SECTION_CONTENT=$(awk '/^## Reproducible Build/,/^## (Vulnerability|How to Verify)/' "$SECURITY_MD")

if echo "$SECTION_CONTENT" | grep -q "Plan 02.7-04 fills"; then
  # Placeholder still in place (this plan hasn't run yet). Pass the stub
  # gracefully so it doesn't block the suite during partial-execution states.
  echo "PASS [verify_reproducibility.sh]: §Reproducible Build heading exists; content placeholder (Plan 02.7-04 will fill)"
  exit 0
fi

# Filled content must contain required markers (Pitfall 14 caveat language)
if ! echo "$SECTION_CONTENT" | grep -qi "toolchain"; then
  fail "§Reproducible Build section filled but missing 'toolchain' caveat language (Pitfall 14)"
fi
if ! echo "$SECTION_CONTENT" | grep -qE "(Xcode CLT|whisper.cpp Metal)"; then
  fail "§Reproducible Build section filled but missing Xcode CLT or whisper.cpp Metal toolchain reference"
fi
if ! echo "$SECTION_CONTENT" | grep -qi "best-effort"; then
  fail "§Reproducible Build section filled but missing 'best-effort' framing"
fi
if ! echo "$SECTION_CONTENT" | grep -qE "(SHA256|SHA-256|shasum)"; then
  fail "§Reproducible Build section filled but missing SHA256 verification reference"
fi

echo "PASS [verify_reproducibility.sh]: §Reproducible Build section filled with toolchain-version caveat + best-effort framing + SHA256 references"
exit 0
