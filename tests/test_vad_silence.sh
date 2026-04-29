#!/usr/bin/env bash
# tests/test_vad_silence.sh — TRA-04 (integration)
#
# Synthesises 2s of pure silence, runs whisper-cli directly with the EXACT
# VAD flags Plan 02-01 must use, asserts the canonicalised output is empty
# OR a known hallucination phrase (both qualify as success — VAD trim or
# denylist catches the residual hallucination).
#
# Requires Silero VAD weights at the canonical path (installed by setup.sh
# Step 5b — Task 0-3 of this same plan).
set -uo pipefail
cd "$(dirname "$0")/.."

source tests/lib/sample_audio.sh
WHISPER_BIN="${WHISPER_BIN:-/opt/homebrew/bin/whisper-cli}"
MODEL="${MODEL:-$HOME/.local/share/voice-cc/models/ggml-small.en.bin}"
SILERO="${SILERO_MODEL:-$HOME/.local/share/voice-cc/models/ggml-silero-v6.2.0.bin}"

if [ ! -f "$SILERO" ]; then
  echo "FAIL: Silero VAD weights not at $SILERO (run setup.sh)"
  exit 1
fi
if [ ! -f "$MODEL" ]; then
  echo "FAIL: Whisper model not at $MODEL (run setup.sh)"
  exit 1
fi

WAV=$(mktemp -t purplevoice-test-vad-XXXXXX.wav)
trap 'rm -f "$WAV"' EXIT
silence_wav "$WAV" 2.0   # 2 seconds of digital silence

OUTPUT=$("$WHISPER_BIN" \
  -m "$MODEL" \
  --language en \
  --no-timestamps \
  --no-prints \
  --vad \
  --vad-model "$SILERO" \
  --vad-threshold 0.50 \
  --suppress-nst \
  -f "$WAV" 2>/dev/null | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')

# Acceptable outcomes: empty (VAD trimmed everything) OR output matches a
# known hallucination phrase (denylist would catch it downstream). Both
# satisfy success criterion #2 (silence does not paste a hallucination).
KNOWN_HALLUCINATIONS="thankyouthanksforwatching[blank_audio][silence]you."
if [ -z "$OUTPUT" ] || echo "$KNOWN_HALLUCINATIONS" | grep -q -F "$OUTPUT"; then
  echo "PASS: 2s silence with VAD produced empty/denylisted output (got: '$OUTPUT')"
  exit 0
else
  echo "FAIL: 2s silence with VAD produced unexpected output: '$OUTPUT'"
  exit 1
fi
