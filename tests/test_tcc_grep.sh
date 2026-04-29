#!/usr/bin/env bash
# tests/test_tcc_grep.sh — ROB-02 (unit)
#
# Verifies the TCC fingerprint regex Plan 02-01 must use (RESEARCH §4):
#   Permission denied|AudioObject(GetPropertyData|SetPropertyData)|kAudio.*Error
#
# Positive: synthesises a fake sox stderr containing realistic TCC-denial
# text and asserts the regex matches.
# Negative: synthesises a benign sox warning and asserts the regex does NOT
# match (false-positive guard).
set -uo pipefail

FAKE_STDERR=$(mktemp -t purplevoice-test-stderr-XXXXXX)
trap 'rm -f "$FAKE_STDERR"' EXIT

# --- Positive: synthetic stderr that simulates sox on TCC denial ----------
cat > "$FAKE_STDERR" <<'EOF'
coreaudio: AudioObjectGetPropertyData failed (kAudioHardwareNoDeviceError)
sox FAIL formats: can't open input device `default': Permission denied
EOF

# The exact regex Plan 02-01 must use (RESEARCH §4)
if grep -qE 'Permission denied|AudioObject(GetPropertyData|SetPropertyData)|kAudio.*Error' "$FAKE_STDERR"; then
  : # match — expected
else
  echo "FAIL: TCC fingerprint regex failed to match synthetic sox TCC-denial stderr"
  exit 1
fi

# --- Negative: a benign sox warning should NOT match ----------------------
cat > "$FAKE_STDERR" <<'EOF'
sox WARN dither: dither clipped 1 sample
EOF
if grep -qE 'Permission denied|AudioObject(GetPropertyData|SetPropertyData)|kAudio.*Error' "$FAKE_STDERR"; then
  echo "FAIL: TCC fingerprint regex false-positive on benign sox warning"
  exit 1
fi

echo "PASS: TCC fingerprint regex matches denial + rejects benign stderr"
exit 0
