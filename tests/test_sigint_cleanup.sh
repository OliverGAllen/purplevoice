#!/usr/bin/env bash
# tests/test_sigint_cleanup.sh — ROB-04 SIGINT path
#
# Verifies the EXIT trap Plan 02-01 must add cleans up /tmp/voice-cc/ even
# when the script is interrupted by SIGINT (Ctrl-C / kill -INT).
#
# CRITICAL design note: the naive approach of pre-staging a SHORT WAV and
# backgrounding purplevoice-record fails — the duration gate fires immediately
# (DURATION=0.1 < 0.4) and the script exits 2 in milliseconds, long before
# the test's `sleep 0.5; kill -INT` can land. The SIGINT path is then never
# exercised. Fix: pre-stage a 1-second WAV via `medium_wav`, which CLEARS
# the 0.4s gate. The script then proceeds past the gate into transcribe()
# — where the EXIT trap is the path we're actually testing.
set -uo pipefail
cd "$(dirname "$0")/.."

if ! grep -q 'PURPLEVOICE_TEST_SKIP_SOX' purplevoice-record 2>/dev/null; then
  echo "FAIL: purplevoice-record does not support PURPLEVOICE_TEST_SKIP_SOX hook (Plan 02-01 not yet implemented — expected RED)"
  exit 1
fi

source tests/lib/sample_audio.sh
mkdir -p /tmp/voice-cc
rm -f /tmp/voice-cc/* 2>/dev/null

# Pre-stage a 1-second tone WAV — long enough to clear the 0.4s duration
# gate in purplevoice-record. Without this, the gate fires immediately and the
# script exits before SIGINT can land.
medium_wav /tmp/voice-cc/recording.wav   # 1.0s tone @ 440Hz

# Background purplevoice-record (it will pass the gate and proceed into
# transcribe; whisper-cli on a 1s clip takes ~200-500ms even on M-series)
PURPLEVOICE_TEST_SKIP_SOX=1 ./purplevoice-record >/dev/null 2>&1 &
PID=$!

sleep 0.5
kill -INT "$PID" 2>/dev/null || true
wait "$PID" 2>/dev/null || true

LEFTOVERS=$(find /tmp/voice-cc -maxdepth 1 \( -name "*.wav" -o -name "*.txt" -o -name "sox.stderr" \) 2>/dev/null)
if [ -z "$LEFTOVERS" ]; then
  echo "PASS: /tmp/voice-cc/ empty after SIGINT (EXIT trap fired correctly)"
  exit 0
else
  echo "FAIL: /tmp/voice-cc/ has leftovers after SIGINT: $LEFTOVERS"
  exit 1
fi
