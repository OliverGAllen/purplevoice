#!/usr/bin/env bash
# tests/test_security_md_framing.sh — D-17 "compatible with" framing lint.
#
# Purpose: prevent drift toward "compliant" / "certified" / "guarantees" claims
# across edits to SECURITY.md (Pitfall 4). Also enforces table-cell status
# vocabulary (Met / Partial / Not Pursued / N/A) per Pitfall 15.
#
# Lives in the FUNCTIONAL suite (tests/run_all.sh) — runs per commit, NOT
# per release-gate. Drift caught at PR time, not at release time.
#
# Exit 0 if clean; exit 1 with diagnostic on first violation.
#
# Override target file with SECURITY_MD env var (used for negative-control
# self-tests; the verify clause in 02.7-01-PLAN.md exercises this path).
set -uo pipefail
cd "$(dirname "$0")/.."   # repo root

SECURITY_MD="${SECURITY_MD:-SECURITY.md}"

if [ ! -f "$SECURITY_MD" ]; then
  echo "FAIL [test_security_md_framing.sh]: $SECURITY_MD not found" >&2
  exit 1
fi

fail() {
  echo "FAIL [test_security_md_framing.sh]: $1" >&2
  exit 1
}

# -------------------------------------------------------------------------
# Check 1: required canonical tagline present (D-17 anchor + Phase 2.5 brand)
# -------------------------------------------------------------------------
if ! grep -q "Local voice dictation. Nothing leaves your Mac." "$SECURITY_MD"; then
  fail "canonical tagline 'Local voice dictation. Nothing leaves your Mac.' missing from $SECURITY_MD"
fi

# -------------------------------------------------------------------------
# Check 2: required H2 sections present (representative sample of the 18)
# -------------------------------------------------------------------------
REQUIRED_SECTIONS=(
  "## Threat Model"
  "## Egress Verification"
  "## Software Bill of Materials"
  "## NIST SP 800-53 Rev 5 / Low-baseline Mapping"
  "## FIPS 140-3"
  "## Common Criteria"
  "## HIPAA Security Rule"
  "## SOC 2 Type II Trust Services Criteria"
  "## ISO/IEC 27001:2022 Annex A"
  "## Code Signing & Notarisation"
  "## Reproducible Build"
  "## Vulnerability Disclosure"
)
for s in "${REQUIRED_SECTIONS[@]}"; do
  if ! grep -qF "$s" "$SECURITY_MD"; then
    fail "required section '$s' missing from $SECURITY_MD"
  fi
done

# -------------------------------------------------------------------------
# Check 3: banned phrases in PROSE outside qualified contexts (Pitfall 4)
# -------------------------------------------------------------------------
# We use the inverted-grep idiom: list all hits, then filter out qualified
# contexts. Any survivor is a violation.
#
# Qualifier patterns that exempt a hit:
#   - "not compliant" / "non-compliant"
#   - "compliant with applicable" / "compliant with the"
#   - quoted forms: "compliant" / "certified" / "guarantees"
#   - "not certified" / "is not certified" / "certifying authority"
#   - "does not guarantee" / "no guarantees"

check_banned_phrase() {
  local phrase="$1"
  local exempt_pattern="$2"
  local hits
  # First grep gathers all matches case-insensitively; second grep removes
  # qualified contexts. Anything that survives is a violation.
  hits=$(grep -niE "\\b${phrase}\\b" "$SECURITY_MD" | grep -viE "$exempt_pattern" || true)
  if [ -n "$hits" ]; then
    echo "FAIL [test_security_md_framing.sh]: banned phrase '$phrase' found outside qualified context:" >&2
    echo "$hits" | head -10 >&2
    exit 1
  fi
}

check_banned_phrase "compliant" '(not compliant|non-compliant|"compliant"|compliant with applicable|compliant with the)'
check_banned_phrase "certified" '(not certified|"certified"|certifying authority|is not certified)'
check_banned_phrase "guarantees" '(does not guarantee|no guarantees|"guarantees"|guarantees that .*not)'

# -------------------------------------------------------------------------
# Check 4: table-cell status vocabulary (Pitfall 15)
# -------------------------------------------------------------------------
# Markdown table rows start with `|` and contain status cells. Banned status
# values inside table cells: "Compliant", "Certified", "Compliance" (exact
# word, case-insensitive).
# We grep lines that look like table rows, exclude separator rows (|---|),
# then check for banned status words sandwiched between pipes.

table_violations=$(grep -nE '^\|' "$SECURITY_MD" \
                   | grep -viE '^\s*[0-9]+:\s*\|\s*-+' \
                   | grep -iE '\|\s*(Compliant|Certified|Compliance)\s*\|' \
                   || true)
if [ -n "$table_violations" ]; then
  echo "FAIL [test_security_md_framing.sh]: banned status vocabulary in table cells (use Met/Partial/Not Pursued/N/A):" >&2
  echo "$table_violations" | head -10 >&2
  exit 1
fi

# -------------------------------------------------------------------------
# Check 5: brand consistency — no voice-cc references (Phase 2.5 invariant)
# -------------------------------------------------------------------------
if grep -q "voice-cc" "$SECURITY_MD"; then
  fail "voice-cc strings present in $SECURITY_MD (Phase 2.5 brand invariant violated)"
fi

echo "PASS [test_security_md_framing.sh]: $SECURITY_MD framing clean (D-17, Pitfall 4, Pitfall 15, brand consistency)"
exit 0
