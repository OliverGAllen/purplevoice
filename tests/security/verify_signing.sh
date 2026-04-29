#!/usr/bin/env bash
# tests/security/verify_signing.sh — PurpleVoice Phase 2.7 code-signing stub.
# Asserts: SECURITY.md §"Code Signing & Notarisation" exists with Phase 3
#          deferral language. PASSES if documentation is complete; replaced
#          by real signing verification in Phase 3 when an installer artifact
#          ships.
# Source of claim: SECURITY.md §"Code Signing & Notarisation".
# Sudo: not required.
#
# Why a stub: PurpleVoice's current architecture (Hammerspoon Spoon + bash
# glue + brew binaries + GGML model) does NOT produce a signable artifact.
# Hammerspoon is signed by its upstream project; brew binaries are signed by
# Homebrew formula maintainers. PurpleVoice itself ships text files. Phase 3
# (Distribution & Public Install) introduces a public installer; if that
# installer is wrapped as a notarised .app, this stub is replaced by a real
# codesign + notarytool verification.
set -uo pipefail
cd "$(dirname "$0")/../.."

SECURITY_MD="SECURITY.md"

fail() {
  echo "FAIL [verify_signing.sh]: $1" >&2
  exit 1
}

[ -f "$SECURITY_MD" ] || fail "$SECURITY_MD not found"

# The §Code Signing & Notarisation section heading exists (Plan 02.7-00 skeleton)
if ! grep -q "^## Code Signing & Notarisation" "$SECURITY_MD"; then
  fail "SECURITY.md missing §Code Signing & Notarisation section heading"
fi

# The section content (filled by Plan 02.7-04) MUST contain Phase 3 deferral
# language. While Plan 02.7-04 hasn't run yet, Plan 02.7-00 placed a TODO
# placeholder. We accept either the placeholder OR the filled content.
# Acceptance criteria:
#   - Either the section contains "Plan 02.7-04 fills" (placeholder)
#   - OR the section contains "Phase 3" + ("deferred" OR "applies when") +
#     "$99" (Apple Developer Program cost reference)

# Extract the §Code Signing section content (between this H2 and the next H2)
SECTION_CONTENT=$(awk '/^## Code Signing & Notarisation/,/^## (Reproducible|Vulnerability|How to Verify)/' "$SECURITY_MD")

if echo "$SECTION_CONTENT" | grep -q "Plan 02.7-04 fills"; then
  echo "PASS [verify_signing.sh]: §Code Signing & Notarisation section heading exists; content placeholder (Plan 02.7-04 will fill with Phase 3 deferral language)"
  exit 0
fi

# Otherwise, validate the filled content contains required markers.
if ! echo "$SECTION_CONTENT" | grep -qi "phase 3"; then
  fail "§Code Signing & Notarisation section filled but missing 'Phase 3' deferral reference"
fi
if ! echo "$SECTION_CONTENT" | grep -qE "(deferred|applies when)"; then
  fail "§Code Signing & Notarisation section filled but missing 'deferred' or 'applies when' framing"
fi
if ! echo "$SECTION_CONTENT" | grep -q '\$99'; then
  fail "§Code Signing & Notarisation section filled but missing Apple Developer Program cost reference (\$99)"
fi

echo "PASS [verify_signing.sh]: §Code Signing & Notarisation section filled with Phase 3 deferral + cost framing"
exit 0
