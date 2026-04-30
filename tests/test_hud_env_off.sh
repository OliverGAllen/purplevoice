#!/usr/bin/env bash
# tests/test_hud_env_off.sh — HUD-02 string-level env-var wiring assertion (Phase 3.5)
#
# Wave 0 baseline form (Plan 03.5-00): asserts the PRECEDENT for HUD-02 wiring
# exists (the existing PURPLEVOICE_NO_SOUNDS read at line 99 of init.lua) AND
# that the legacy/forbidden namespaces (`VOICE_CC_HUD`, `whisper-cli`) are NOT
# present. This goes GREEN at Wave 0 commit time because all invariants
# already hold against the un-modified init.lua.
#
# Plan 03.5-01 will TIGHTEN this test to additionally assert:
#   - os.getenv("PURPLEVOICE_HUD_OFF") is read at module load
#   - The read uses the ~= "1" default-ON idiom (mirrors line 99)
# At that point the wiring is added in the same plan, so the tightened
# assertions go GREEN in the same commit.
#
# Default-ON semantics (D-09): HUD enabled unless env var equals "1".
# Brand invariant (D-10 + Pitfall 10): no legacy VOICE_CC_HUD namespace.
# Pattern 2 corollary: HUD code stays whisper-cli-free.
#
# Exit 0 = baseline invariants hold; exit 1 = drift or missing precedent.
set -uo pipefail
cd "$(dirname "$0")/.."   # repo root

INIT="purplevoice-lua/init.lua"

if [ ! -r "$INIT" ]; then
  echo "FAIL [test_hud_env_off.sh]: $INIT not readable"
  exit 1
fi

FAIL=0

# 1. PRECEDENT (always GREEN — locked invariant): the env-var read pattern
#    HUD-02 will mirror is the existing PURPLEVOICE_NO_SOUNDS read at line 99.
#    Plan 03.5-01 lifts this exact idiom for PURPLEVOICE_HUD_OFF.
if ! grep -q "PURPLEVOICE_NO_SOUNDS" "$INIT"; then
  echo "FAIL: $INIT missing PURPLEVOICE_NO_SOUNDS precedent — Plan 03.5-01 has no idiom to mirror"
  FAIL=1
fi
# The full default-ON idiom must be present so Plan 03.5-01 can copy it verbatim.
if ! grep -qE 'PURPLEVOICE_NO_SOUNDS.*~= ?"1"' "$INIT"; then
  echo "FAIL: $INIT PURPLEVOICE_NO_SOUNDS read does not use ~= \"1\" default-ON idiom (D-09 precedent)"
  FAIL=1
fi

# 2. NEGATIVE: no legacy VOICE_CC_HUD namespace anywhere in init.lua
#    (Phase 2.5 brand invariant + D-10 — PURPLEVOICE_ namespace only).
if grep -qE 'VOICE_CC_HUD' "$INIT"; then
  echo "FAIL: $INIT contains legacy VOICE_CC_HUD reference — Phase 2.5 brand invariant violated (D-10)"
  FAIL=1
fi

# 3. NEGATIVE: Pattern 2 corollary — no whisper-cli reference in init.lua.
if grep -q "whisper-cli" "$INIT"; then
  echo "FAIL: $INIT contains 'whisper-cli' reference — Pattern 2 corollary violated"
  FAIL=1
fi

# 4. Brand consistency: no working-name literal in init.lua — HUD code must
#    use PurpleVoice / purplevoice surfaces only (Phase 2.5 D-07). The literal
#    being scanned for is constructed at runtime so this test file itself
#    stays clean against tests/test_brand_consistency.sh (which globs every
#    *.sh / *.md / *.lua / *.txt for the bare working-name string).
LEGACY_NAME="voice""-cc"
if grep -q "$LEGACY_NAME" "$INIT"; then
  echo "FAIL: $INIT contains '$LEGACY_NAME' literal — Phase 2.5 brand drift"
  FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS [test_hud_env_off.sh]: HUD-02 precedent (PURPLEVOICE_NO_SOUNDS ~= \"1\") present; brand-clean; Pattern 2 corollary intact"
  exit 0
fi
exit 1
