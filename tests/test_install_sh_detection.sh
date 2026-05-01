#!/usr/bin/env bash
# tests/test_install_sh_detection.sh — unit test for install.sh detect_invocation_mode (DST-05)
#
# Asserts the curl-vs-clone detection function returns the correct mode for both
# invocation modes. Mocks $0 / BASH_SOURCE so we can test without actually
# curl|bash-ing or git-cloning anything.
#
# Per Phase 3 RESEARCH §Pattern 1: detect_invocation_mode returns "clone" if
# $0/BASH_SOURCE points at a real file inside a git checkout, "curl" otherwise.
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

# Source the function in a subshell so we don't pollute this test's $0/BASH_SOURCE.
# Test 1: when invoked from a real file inside a git checkout (this repo) → "clone"
result_clone=$(
  eval "$DETECT_BLOCK"
  # BASH_SOURCE[0] points at install.sh in this very repo — should be "clone"
  BASH_SOURCE=("$(pwd)/install.sh")
  detect_invocation_mode
)
if [ "$result_clone" != "clone" ]; then
  echo "FAIL [test_install_sh_detection.sh]: clone-mode test returned '$result_clone' (expected 'clone')"
  FAIL=1
fi

# Test 2: when BASH_SOURCE is empty (curl|bash semantics) → "curl"
result_curl=$(
  eval "$DETECT_BLOCK"
  BASH_SOURCE=("")
  detect_invocation_mode
)
if [ "$result_curl" != "curl" ]; then
  echo "FAIL [test_install_sh_detection.sh]: curl-mode test returned '$result_curl' (expected 'curl')"
  FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS [test_install_sh_detection.sh]: detect_invocation_mode handles both modes"
  exit 0
fi
exit 1
