#!/usr/bin/env bash
# tests/security/lib/process_tree.sh — process-tree helpers for Phase 2.7 security verification.
# Source this from tests/security/verify_*.sh; do not invoke directly.
#
# ----- DESIGN NOTE (per checker M-6) -----
# synthesise_recording() pre-stages a silence WAV at /tmp/purplevoice/recording.wav
# — the SAME path that purplevoice-record uses for actual mic capture.
# This is INTENTIONAL because:
#   1. Pattern 2 / single-instance constraint: the Lua isRecording guard in
#      purplevoice-lua/init.lua prevents concurrent invocations of purplevoice-record.
#   2. PURPLEVOICE_TEST_SKIP_SOX=1 is set unconditionally in this test path, so
#      the bash glue does NOT spawn sox to capture mic audio (which would
#      otherwise overwrite the test's pre-staged WAV).
#   3. purplevoice-record does NOT support a path override (the WAV path is
#      hardcoded); using a separate test-only path would require modifying
#      purplevoice-record, which violates the Pattern 2 boundary protection
#      (SOLE editable surface for transcription invocation site).
# If a future revision of purplevoice-record exposes a WAV path env var, this
# helper should switch to /tmp/purplevoice/test-recording.wav. Until then, the
# production path is the correct test path under the constraints above.
# ----- END DESIGN NOTE -----
#
# purplevoice_pid_tree
# Echoes whitespace-separated PIDs of any active purplevoice process tree:
#   - bash glue (purplevoice-record), if running
#   - sox child(ren), if running
#   - transcription child(ren), if running
# Hammerspoon's main process is intentionally NOT included (D-06 scoping; Pitfall 5):
# Hammerspoon may hold long-lived TCP keepalives unrelated to PurpleVoice, and
# including its PID would muddy the egress claim with Hammerspoon-owned sockets.
purplevoice_pid_tree() {
  local pids
  pids=$(pgrep -f 'purplevoice-record' 2>/dev/null || true)
  for parent in $pids; do
    pids="$pids $(pgrep -P "$parent" 2>/dev/null || true)"
  done
  echo "$pids" | tr ' ' '\n' | grep -v '^$' | sort -u | tr '\n' ' '
}

# synthesise_recording DURATION
# Triggers a controlled recording for the egress test to capture against.
# Uses PURPLEVOICE_TEST_SKIP_SOX=1 so no actual mic capture happens (the test
# is about NETWORK egress, not audio); the bash glue still spawns the
# transcription binary against a pre-staged WAV. Caller pre-stages a silence
# WAV at /tmp/purplevoice/recording.wav.
# See DESIGN NOTE above re: production-path-as-test-path rationale.
# Pitfall 6: this helper does NOT call the transcription binary directly — it
# only invokes purplevoice-record, which keeps the Pattern 2 boundary intact.
synthesise_recording() {
  local dur="${1:-1.0}"
  # Resolve REPO_ROOT from caller context if unset
  REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
  # Source sample_audio.sh from the parent tests/lib/ (not security/lib/)
  source "$REPO_ROOT/tests/lib/sample_audio.sh"
  mkdir -p /tmp/purplevoice
  silence_wav /tmp/purplevoice/recording.wav "$dur"
  PURPLEVOICE_TEST_SKIP_SOX=1 bash "$REPO_ROOT/purplevoice-record" >/dev/null 2>&1 &
  echo $!  # PID of the bash glue (caller passes to purplevoice_pid_tree wait)
}
