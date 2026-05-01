#!/usr/bin/env bash
# tests/test_install_sh_detection.sh — unit test for install.sh detect_invocation_mode (DST-05)
#
# Asserts the curl-vs-clone detection function returns the correct mode for both
# invocation modes.
#
# Per Phase 3 RESEARCH §Pattern 1: detect_invocation_mode returns "clone" if
# $0/BASH_SOURCE[0] points at a real file inside a git checkout, "curl" otherwise.
#
# Implementation note (Wave 1 / Plan 03-01): bash treats BASH_SOURCE specially —
# the array tracks the call stack and direct assignment to BASH_SOURCE[0] from
# user code is unreliable across bash versions. We therefore exercise the
# function in two real invocation contexts that mirror production use:
#   - clone:  copy install.sh into a temp dir, `git init` it, then `bash -c
#             'source <copy>; detect_invocation_mode'` so BASH_SOURCE[0] is the
#             real file inside a real git checkout.
#   - curl:   pipe just the function definition into bash via stdin so
#             BASH_SOURCE[0] is empty (matches `curl ... | bash` semantics).
#
# RED at Wave 0 commit — install.sh does not yet exist (created in Plan 03-01).

set -uo pipefail
cd "$(dirname "$0")/.."   # repo root

FAIL=0

if [ ! -f install.sh ]; then
  echo "FAIL [test_install_sh_detection.sh]: install.sh not found at repo root (Plan 03-01 creates it)"
  exit 1
fi

# Extract just the detect_invocation_mode function definition (the brace-balanced
# block between `detect_invocation_mode() {` and the matching `}`).
DETECT_BLOCK=$(sed -n '/^detect_invocation_mode()[[:space:]]*{/,/^}/p' install.sh)
if [ -z "$DETECT_BLOCK" ]; then
  echo "FAIL [test_install_sh_detection.sh]: detect_invocation_mode function not defined in install.sh"
  exit 1
fi

# Test 1: clone mode — a real file inside a real git checkout.
# Set up a sandbox: temp dir, git init, drop a tiny script that defines + calls
# the detection function. Source-invoke it so BASH_SOURCE[0] is the file path.
SANDBOX=$(mktemp -d -t purplevoice-detect-test.XXXXXX)
trap 'rm -rf "$SANDBOX"' EXIT
(
  cd "$SANDBOX"
  git init -q . >/dev/null 2>&1
  cat > probe.sh <<EOF
$DETECT_BLOCK
detect_invocation_mode
EOF
  # Use `bash probe.sh` so BASH_SOURCE[0] = $SANDBOX/probe.sh (real file in git repo).
  result_clone=$(bash ./probe.sh 2>/dev/null)
  if [ "$result_clone" != "clone" ]; then
    echo "FAIL [test_install_sh_detection.sh]: clone-mode test returned '$result_clone' (expected 'clone')"
    exit 1
  fi
) || FAIL=1

# Test 2: curl mode — pipe the function body via stdin (no file-backed BASH_SOURCE[0]).
# This mirrors `curl ... | bash` exactly: bash reads the script from stdin,
# BASH_SOURCE[0] is empty, $0 is "bash", and -f "$script_path" is false.
result_curl=$(printf '%s\ndetect_invocation_mode\n' "$DETECT_BLOCK" | bash 2>/dev/null)
if [ "$result_curl" != "curl" ]; then
  echo "FAIL [test_install_sh_detection.sh]: curl-mode test returned '$result_curl' (expected 'curl')"
  FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS [test_install_sh_detection.sh]: detect_invocation_mode handles both modes"
  exit 0
fi
exit 1
