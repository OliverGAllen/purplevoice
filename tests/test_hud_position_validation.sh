#!/usr/bin/env bash
# tests/test_hud_position_validation.sh — HUD-04 position-name wiring (Phase 3.5)
#
# Wave 0 baseline form (Plan 03.5-00): asserts brand/scope invariants that
# already hold against the un-modified init.lua AND records (in inline comment
# form) the six locked named positions Plan 03.5-02 must wire. This goes GREEN
# at Wave 0 commit time.
#
# Plan 03.5-02 will TIGHTEN this test to additionally assert:
#   - os.getenv("PURPLEVOICE_HUD_POSITION") is read at module load
#   - All six locked named positions appear as quoted string literals
#       (top-center | top-right | bottom-center | bottom-right
#        | near-cursor | center) — D-07 lock
#   - Default 'top-center' appears at least twice (validation map + fallback)
#   - hs.console.printStyledtext fallback warning present (D-07)
# At that point the wiring is added in the same plan, so the tightened
# assertions go GREEN in the same commit.
#
# NEGATIVE invariants enforced from Wave 0 onward (these reject rejected
# env vars from the Deferred Ideas list and CONTEXT.md D-10 two-knob design):
#   - No PURPLEVOICE_HUD_X / PURPLEVOICE_HUD_Y (coordinate-precise overrides
#     rejected per Deferred Ideas)
#   - No PURPLEVOICE_HUD_ALPHA / PURPLEVOICE_HUD_COLOR / PURPLEVOICE_HUD_COLOUR
#     (visual-knob overrides rejected per D-10 — only HUD_OFF + HUD_POSITION
#     allowed)
#
# Reference (the six locked named positions Plan 03.5-02 will wire):
#   top-center (default)
#   top-right
#   bottom-center
#   bottom-right
#   near-cursor
#   center
#
# Exit 0 = baseline invariants hold; exit 1 = drift or rejected env var present.
set -uo pipefail
cd "$(dirname "$0")/.."   # repo root

INIT="purplevoice-lua/init.lua"

if [ ! -r "$INIT" ]; then
  echo "FAIL [test_hud_position_validation.sh]: $INIT not readable"
  exit 1
fi

FAIL=0

# 1. NEGATIVE: rejected coordinate-override env vars must not appear
#    (Deferred Ideas — coordinate-precise overrides excluded for v1).
for rejected in PURPLEVOICE_HUD_X PURPLEVOICE_HUD_Y; do
  if grep -qF "$rejected" "$INIT"; then
    echo "FAIL: $INIT contains rejected env var $rejected (Deferred — coordinate-precise overrides excluded for v1)"
    FAIL=1
  fi
done

# 2. NEGATIVE: rejected visual-knob env vars must not appear
#    (D-10 — only HUD_OFF + HUD_POSITION allowed; brand locked).
for rejected in PURPLEVOICE_HUD_ALPHA PURPLEVOICE_HUD_COLOR PURPLEVOICE_HUD_COLOUR; do
  if grep -qF "$rejected" "$INIT"; then
    echo "FAIL: $INIT contains rejected env var $rejected (D-10 — only HUD_OFF + HUD_POSITION allowed)"
    FAIL=1
  fi
done

# 3. PRECEDENT: the menubar lifecycle pattern HUD-04 will mirror is present
#    (setMenubarIdle / setMenubarRecording at lines 85, 89). Plan 03.5-01
#    adds analogous showHUD / hideHUD calls alongside these.
if ! grep -q "setMenubarIdle" "$INIT"; then
  echo "FAIL: $INIT missing setMenubarIdle precedent — Plan 03.5-01 has no lifecycle mirror"
  FAIL=1
fi
if ! grep -q "setMenubarRecording" "$INIT"; then
  echo "FAIL: $INIT missing setMenubarRecording precedent — Plan 03.5-01 has no lifecycle mirror"
  FAIL=1
fi

# 4. NEGATIVE: Pattern 2 corollary still holds in init.lua.
if grep -q "whisper-cli" "$INIT"; then
  echo "FAIL: $INIT contains 'whisper-cli' reference — Pattern 2 corollary violated"
  FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS [test_hud_position_validation.sh]: HUD-04 lifecycle precedent (setMenubarIdle/Recording) present; no rejected HUD env vars; brand-clean"
  exit 0
fi
exit 1
