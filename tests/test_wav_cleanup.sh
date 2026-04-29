#!/usr/bin/env bash
# tests/test_wav_cleanup.sh — ROB-04 + Phase-1 TODO (c)
#
# Asserts that after a purplevoice-record invocation (any exit path), the
# /tmp/purplevoice/ directory contains no leftover *.wav, *.txt, or sox.stderr
# files. Tests the EXIT trap that Plan 02-01 must add.
#
# RED until Plan 02-01 adds the PURPLEVOICE_TEST_SKIP_SOX hook AND the EXIT
# trap. The test fails fast with an explicit "Plan 02-01 not yet implemented"
# message so the RED status is informative, not mysterious.
set -uo pipefail
cd "$(dirname "$0")/.."

# Skip if Plan 02-01's test hook isn't supported yet (RED until then)
if ! grep -q 'PURPLEVOICE_TEST_SKIP_SOX' purplevoice-record 2>/dev/null; then
  echo "FAIL: purplevoice-record does not support PURPLEVOICE_TEST_SKIP_SOX hook (Plan 02-01 not yet implemented — expected RED)"
  exit 1
fi

source tests/lib/sample_audio.sh
mkdir -p /tmp/purplevoice
rm -f /tmp/purplevoice/* 2>/dev/null

# Pre-stage a real (silent, 100ms) WAV so the duration gate aborts at exit 2
# — quickest path that exercises the EXIT trap without requiring a microphone
# or a slow whisper-cli invocation.
silence_wav /tmp/purplevoice/recording.wav 0.1

# Invoke purplevoice-record with the test hook; expect non-zero exit (gate aborts)
PURPLEVOICE_TEST_SKIP_SOX=1 ./purplevoice-record >/dev/null 2>&1 || true

# Now assert /tmp/purplevoice/ is empty (or contains no leftover *.wav, *.txt,
# sox.stderr — the three artifact types Plan 02-01 must clean up).
LEFTOVERS=$(find /tmp/purplevoice -maxdepth 1 \( -name "*.wav" -o -name "*.txt" -o -name "sox.stderr" \) 2>/dev/null)
if [ -z "$LEFTOVERS" ]; then
  echo "PASS: /tmp/purplevoice/ contains no *.wav, *.txt, or sox.stderr after invocation"
  exit 0
else
  echo "FAIL: /tmp/purplevoice/ has leftovers after invocation: $LEFTOVERS"
  exit 1
fi
