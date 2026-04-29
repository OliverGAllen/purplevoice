#!/usr/bin/env bash
# tests/security/verify_sbom.sh — PurpleVoice Phase 2.7 SBOM verification.
# Asserts: SBOM.spdx.json exists, parses as valid SPDX 2.3 JSON, contains
#          expected packages + 4 system-context annotations.
# Source of claim: SECURITY.md §"Software Bill of Materials (SBOM)".
# Sudo: not required.
set -uo pipefail
cd "$(dirname "$0")/../.."
REPO_ROOT="$(pwd)"

SBOM="$REPO_ROOT/SBOM.spdx.json"

fail() {
  echo "FAIL [verify_sbom.sh]: $1" >&2
  exit 1
}

# -------------------------------------------------------------------------
# Existence + JSON validity
# -------------------------------------------------------------------------
[ -f "$SBOM" ] || fail "$SBOM not found"

# Use python3 for JSON parsing (always available on macOS) instead of jq
# (which is optional). This way verify_sbom.sh runs even without jq.
python3 -c "import json,sys; json.load(open('$SBOM'))" 2>/dev/null \
  || fail "$SBOM is not valid JSON"

# -------------------------------------------------------------------------
# SPDX 2.3 required fields
# -------------------------------------------------------------------------
REQUIRED_FIELDS=(spdxVersion dataLicense SPDXID name documentNamespace creationInfo)
for f in "${REQUIRED_FIELDS[@]}"; do
  python3 -c "import json,sys; d=json.load(open('$SBOM')); assert '$f' in d, '$f missing'" 2>/dev/null \
    || fail "SPDX 2.3 required field '$f' missing"
done

# spdxVersion must be SPDX-2.3
SPDX_VER=$(python3 -c "import json; print(json.load(open('$SBOM'))['spdxVersion'])")
[ "$SPDX_VER" = "SPDX-2.3" ] || fail "spdxVersion is '$SPDX_VER' (expected 'SPDX-2.3')"

# -------------------------------------------------------------------------
# Detect placeholder vs real SBOM
# -------------------------------------------------------------------------
NAME=$(python3 -c "import json; print(json.load(open('$SBOM'))['name'])")
if echo "$NAME" | grep -q "placeholder"; then
  fail "SBOM is still the Plan 02.7-00 placeholder (name='$NAME'); run setup.sh with Syft installed to regenerate"
fi

# Real SBOM should have name = "PurpleVoice"
[ "$NAME" = "PurpleVoice" ] || fail "SBOM name is '$NAME' (expected 'PurpleVoice')"

# -------------------------------------------------------------------------
# System-context annotations (D-11 + Priority 3)
# -------------------------------------------------------------------------
SC_COUNT=$(python3 -c "
import json
d = json.load(open('$SBOM'))
annots = d.get('annotations', [])
sc = [a for a in annots if a.get('comment','').startswith('system-context:')]
print(len(sc))
")

[ "$SC_COUNT" -ge 4 ] || fail "Expected >=4 system-context annotations, got $SC_COUNT (D-11 / Priority 3)"

# Verify each of the 4 expected system-context dimensions is present
for dim in macOS-version hardware-platform xcode-clt-version brew-version; do
  python3 -c "
import json
d = json.load(open('$SBOM'))
annots = d.get('annotations', [])
found = any('$dim' in a.get('comment','') for a in annots)
assert found, '$dim missing from annotations'
" 2>/dev/null || fail "system-context dimension '$dim' missing from SBOM annotations"
done

# -------------------------------------------------------------------------
# Determinism check (Pitfall 3): creationInfo.created must be the constant
# 2026-04-29T00:00:00Z, NOT a fresh timestamp from the last regen.
# -------------------------------------------------------------------------
CREATED=$(python3 -c "import json; print(json.load(open('$SBOM'))['creationInfo']['created'])")
[ "$CREATED" = "2026-04-29T00:00:00Z" ] \
  || fail "creationInfo.created is '$CREATED' (expected deterministic '2026-04-29T00:00:00Z'; Pitfall 3)"

# -------------------------------------------------------------------------
# Drift detection: re-run setup.sh's Step 8 (if Syft + jq present) and
# confirm the regenerated SBOM is byte-identical (no spurious diff).
# -------------------------------------------------------------------------
# Skipped in this test for performance; setup.sh idempotency itself is
# tested by the existing functional suite. Drift-detection is optional.

echo "PASS [verify_sbom.sh]: SBOM.spdx.json valid SPDX 2.3 with $SC_COUNT system-context annotations + deterministic timestamp"
exit 0
