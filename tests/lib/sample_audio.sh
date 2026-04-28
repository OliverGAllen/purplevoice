#!/usr/bin/env bash
# tests/lib/sample_audio.sh — WAV synthesis helpers for Phase 2 unit tests.
# Source this from tests/test_*.sh; do not invoke directly.
#
# All helpers produce 16 kHz mono 16-bit PCM WAVs (the format whisper.cpp
# wants, identical to what voice-cc-record's sox capture produces).
SOX_BIN="${SOX_BIN:-/opt/homebrew/bin/sox}"

# silence_wav PATH DURATION_SECONDS
# Produces a 16 kHz mono 16-bit silent WAV at PATH for DURATION seconds.
# Implementation note: `synth ... sine 0 vol 0` produces audible-zero output;
# `sine 0` is a 0-Hz tone (DC) and `vol 0` mutes it — together this yields
# digital silence with valid WAV headers.
silence_wav() {
  local out="$1"
  local dur="$2"
  "$SOX_BIN" -n -r 16000 -c 1 -b 16 "$out" synth "$dur" sine 0 vol 0 2>/dev/null
}

# tone_wav PATH DURATION_SECONDS [FREQ_HZ]
# Produces a 16 kHz mono tone (use to confirm sox is producing real audio).
# Default frequency is 440 Hz (A4).
tone_wav() {
  local out="$1"
  local dur="$2"
  local freq="${3:-440}"
  "$SOX_BIN" -n -r 16000 -c 1 -b 16 "$out" synth "$dur" sine "$freq" 2>/dev/null
}

# short_tap_wav PATH
# Produces the canonical "100 ms accidental tap" WAV for the duration-gate
# test (TRA-05). 100 ms < 0.4 s threshold → must trigger silent abort.
short_tap_wav() {
  silence_wav "$1" 0.1
}

# medium_wav PATH
# Produces a 1.0-second tone WAV — long enough to clear the 0.4s duration gate
# in voice-cc-record. Used by tests that need to drive the script PAST the
# gate (e.g., test_sigint_cleanup.sh, which needs the script to reach a
# wait-able state where SIGINT can land — if the gate fires first, the script
# exits 2 in milliseconds and the SIGINT path is never exercised).
medium_wav() {
  tone_wav "$1" 1.0 440
}
