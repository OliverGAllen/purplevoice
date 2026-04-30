#!/usr/bin/env bash
# tests/security/verify_air_gap.sh — PurpleVoice Phase 2.7 air-gap verification.
# Asserts: PURPLEVOICE_OFFLINE=1 mode in setup.sh is honoured.
#   Invariant 1: with PURPLEVOICE_OFFLINE=1 + all sideload artefacts present,
#                setup.sh exits 0 (no network calls).
#   Invariant 2: with PURPLEVOICE_OFFLINE=1 + Whisper model missing,
#                setup.sh exits 1 with actionable error message containing
#                'PURPLEVOICE_OFFLINE=1 set but Whisper model not sideloaded'.
# Source of claim: SECURITY.md §"Air-Gapped Installation".
# Sudo: not required. Disk: ~488 MB temp space (Pitfall 12).
set -uo pipefail
cd "$(dirname "$0")/../.."
REPO_ROOT="$(pwd)"

MODEL="$HOME/.local/share/purplevoice/models/ggml-small.en.bin"
SAVED_MODEL="/tmp/purplevoice-air-gap-saved-model.bin"
LOG_OFFLINE_OK="/tmp/purplevoice-offline-ok.log"
LOG_OFFLINE_MISSING="/tmp/purplevoice-offline-missing.log"

fail() {
  echo "FAIL [verify_air_gap.sh]: $1" >&2
  exit 1
}

# Pitfall 12: trap-restore the model on EXIT to guarantee restoration even
# if the test crashes mid-run.
cleanup() {
  if [ -f "$SAVED_MODEL" ] && [ ! -f "$MODEL" ]; then
    mv "$SAVED_MODEL" "$MODEL" 2>/dev/null || true
  fi
  rm -f "$LOG_OFFLINE_OK" "$LOG_OFFLINE_MISSING"
}
trap cleanup EXIT INT TERM

# -------------------------------------------------------------------------
# Pre-flight: model must currently exist (we're testing an installed system).
# -------------------------------------------------------------------------
if [ ! -f "$MODEL" ]; then
  fail "pre-flight: $MODEL not present — run setup.sh (online) before verify_air_gap.sh"
fi

# -------------------------------------------------------------------------
# Pre-flight: Karabiner-Elements.app must exist (Phase 4 / QOL-NEW-01 — setup.sh
# Step 9 refuses to declare install complete without it, per CONTEXT.md D-07).
# Mirrors verify_egress.sh's "weakened PASS" idiom for missing prerequisites:
# emit a documented PASS with explicit weakening note rather than hard-failing
# on a one-time user install gate.
# -------------------------------------------------------------------------
if [ ! -d /Applications/Karabiner-Elements.app ]; then
  echo "  verify_air_gap.sh: Karabiner-Elements.app absent — skipping setup.sh exec invariants."
  echo "  WEAKENED PASS [verify_air_gap.sh]: PURPLEVOICE_OFFLINE=1 mode invariants cannot be"
  echo "    exercised end-to-end without /Applications/Karabiner-Elements.app (Phase 4 Step 9"
  echo "    refuses install completion when absent — per CONTEXT.md D-07). Install Karabiner-"
  echo "    Elements (https://karabiner-elements.pqrs.org/) and re-run for full verification."
  exit 0
fi

# -------------------------------------------------------------------------
# Invariant 1: PURPLEVOICE_OFFLINE=1 + sideload populated → setup.sh exits 0
# -------------------------------------------------------------------------
echo "  verify_air_gap.sh: testing Invariant 1 (sideload populated)..."
if PURPLEVOICE_OFFLINE=1 bash setup.sh > "$LOG_OFFLINE_OK" 2>&1; then
  if ! grep -q "OFFLINE:" "$LOG_OFFLINE_OK"; then
    fail "Invariant 1: setup.sh ran but produced no OFFLINE log lines (guards may not be wired)"
  fi
  echo "  Invariant 1 PASS"
else
  fail "Invariant 1: PURPLEVOICE_OFFLINE=1 setup.sh exited non-zero with sideload populated. Log: $LOG_OFFLINE_OK"
fi

# -------------------------------------------------------------------------
# Invariant 2: PURPLEVOICE_OFFLINE=1 + missing model → setup.sh exits 1 with
#              actionable error containing the expected error message.
# -------------------------------------------------------------------------
echo "  verify_air_gap.sh: testing Invariant 2 (model missing — atomic mv per Pitfall 12)..."
mv "$MODEL" "$SAVED_MODEL"   # atomic same-fs mv
set +e
PURPLEVOICE_OFFLINE=1 bash setup.sh > "$LOG_OFFLINE_MISSING" 2>&1
EXIT_CODE=$?
set -e
mv "$SAVED_MODEL" "$MODEL"   # restore immediately

if [ "$EXIT_CODE" -eq 0 ]; then
  fail "Invariant 2: PURPLEVOICE_OFFLINE=1 setup.sh exited 0 with model missing (should exit 1)"
fi

if ! grep -q "PURPLEVOICE_OFFLINE=1 set but Whisper model not sideloaded" "$LOG_OFFLINE_MISSING"; then
  fail "Invariant 2: actionable error message missing from setup.sh stderr. Log: $LOG_OFFLINE_MISSING"
fi
echo "  Invariant 2 PASS"

# -------------------------------------------------------------------------
# Verify the actionable message contains the sideload guidance
# -------------------------------------------------------------------------
if ! grep -q "$MODEL" "$LOG_OFFLINE_MISSING"; then
  fail "Invariant 2: error message does not reference required path $MODEL"
fi

echo "PASS [verify_air_gap.sh]: PURPLEVOICE_OFFLINE=1 mode honoured (2 invariants verified)"
exit 0
