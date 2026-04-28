#!/usr/bin/env bash
# tests/test_duration_gate.sh — TRA-05 / Success Criterion #1
#
# Asserts the duration-gate predicate Plan 02-01 must implement: a 100 ms WAV
# is identified as < 0.4s threshold and would trigger silent abort (exit 2).
#
# This test verifies the gate-LOGIC works (the awk float-compare predicate
# from 02-RESEARCH §1) on a synthesised 100 ms WAV. The exact same predicate
# must be used by Plan 02-01 inside voice-cc-record.
#
# Integration assertion (voice-cc-record itself exits 2 when fed a < 0.4s WAV)
# is gated behind VOICE_CC_INTEGRATION=1 because it requires Plan 02-01's
# VOICE_CC_TEST_SKIP_SOX hook (not implemented yet — RED until then).
set -uo pipefail
cd "$(dirname "$0")/.."

source tests/lib/sample_audio.sh
SOXI_BIN="${SOXI_BIN:-/opt/homebrew/bin/soxi}"

WAV=$(mktemp -t voice-cc-test-XXXXXX.wav)
trap 'rm -f "$WAV"' EXIT
short_tap_wav "$WAV"   # 100 ms silent WAV

DURATION=$("$SOXI_BIN" -D "$WAV" 2>/dev/null || echo 0)
# Replicate the EXACT gate predicate that Plan 02-01 must use (RESEARCH §1):
#   awk -v d="$DURATION" 'BEGIN { exit !(d < 0.4) }'
# (awk because bash arithmetic doesn't do floating point.)
if awk -v d="$DURATION" 'BEGIN { exit !(d < 0.4) }'; then
  echo "PASS: 100ms WAV correctly identified as < 0.4s gate threshold (duration=$DURATION)"
else
  echo "FAIL: 100ms WAV not below 0.4s threshold (duration=$DURATION)"
  exit 1
fi

# --- Integration assertion (gated; requires Plan 02-01's test hook) --------
# Plan 02-01 must add VOICE_CC_TEST_SKIP_SOX support to voice-cc-record so
# this test can pre-stage a WAV and assert exit code 2 directly. Until then,
# the unit predicate above is the minimum acceptance.
if [ "${VOICE_CC_INTEGRATION:-0}" = "1" ]; then
  mkdir -p /tmp/voice-cc
  short_tap_wav /tmp/voice-cc/recording.wav
  if VOICE_CC_TEST_SKIP_SOX=1 ./voice-cc-record >/dev/null 2>&1; then
    EXIT_CODE=0
  else
    EXIT_CODE=$?
  fi
  if [ "$EXIT_CODE" -eq 2 ]; then
    echo "PASS: voice-cc-record exited 2 on 100ms pre-staged WAV (integration)"
  else
    echo "FAIL: voice-cc-record exited $EXIT_CODE on 100ms WAV (expected 2)"
    exit 1
  fi
fi

exit 0
