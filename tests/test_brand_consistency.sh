#!/usr/bin/env bash
# tests/test_brand_consistency.sh — Brand-consistency regression catch (Phase 2.5)
#
# Asserts that no `voice-cc` strings remain in user-visible source surfaces
# after the PurpleVoice rebrand, except in approved exemptions.
#
# Approved exemptions (preserved per Phase 2.5 decisions):
#   - .planning/                       - historical record (D-07)
#   - .git/                            - git history
#   - setup.sh                         - migrate_xdg_dir FROM-arg literals + stale-symlink cleanup; required for migration to work
#   - CLAUDE.md                        - GSD-auto-managed block; deferred to Phase 3 STACK.md update
#   - README.md                        - legitimate historical mention of working name 'voice-cc'
#   - tests/test_brand_consistency.sh  - this file (mentions the string in comments and grep patterns)
#
# Exit 0 = brand is consistent; exit 1 = drift detected.
set -uo pipefail
cd "$(dirname "$0")/.."   # repo root

FAIL=0

# 1. Audit non-exempt source surfaces for unexpected voice-cc strings.
HITS=$(grep -rln "voice-cc" \
  --include="*.lua" \
  --include="*.sh" \
  --include="*.md" \
  --include="*.txt" \
  . 2>/dev/null \
  | grep -v "^\./\.planning/" \
  | grep -v "^\./\.git/" \
  | grep -v "^\./setup\.sh$" \
  | grep -v "^\./CLAUDE\.md$" \
  | grep -v "^\./README\.md$" \
  | grep -v "^\./tests/test_brand_consistency\.sh$" \
  || true)

if [ -n "$HITS" ]; then
  echo "FAIL: voice-cc strings found in non-exempt source files:"
  printf "  %s\n" $HITS
  FAIL=1
fi

# 2. Pattern 2 boundary preserved on the renamed bash glue.
WHISPER_COUNT=$(grep -c WHISPER_BIN purplevoice-record 2>/dev/null || echo 0)
if [ "$WHISPER_COUNT" -ne 2 ]; then
  echo "FAIL: Pattern 2 boundary broken — WHISPER_BIN appears $WHISPER_COUNT times in purplevoice-record (expected 2: assignment + transcribe() use)"
  FAIL=1
fi

# 3. No whisper-cli reference in the Lua module (corollary of Pattern 2).
if grep -q "whisper-cli" purplevoice-lua/init.lua 2>/dev/null; then
  echo "FAIL: purplevoice-lua/init.lua mentions whisper-cli — violates Pattern 2 boundary"
  FAIL=1
fi

# 4. Brand assets exist.
if [ ! -f assets/icon-256.png ]; then
  echo "FAIL: assets/icon-256.png missing — BRD-03 broken"
  FAIL=1
fi
if [ ! -f assets/icon.svg ]; then
  echo "FAIL: assets/icon.svg missing — BRD-03 reproducibility broken"
  FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then
  exit 0
fi
exit 1
