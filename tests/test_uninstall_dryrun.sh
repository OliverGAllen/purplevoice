#!/usr/bin/env bash
# tests/test_uninstall_dryrun.sh — uninstall.sh idempotency in a sandboxed $HOME.
#
# Per Phase 3 CONTEXT D-12 / RESEARCH §Pattern 7: uninstall.sh removes XDG dirs
# + symlinks idempotently; re-runs print "already absent" and exit 0.
#
# We sandbox $HOME via mktemp so we cannot accidentally touch the developer's
# real ~/.config/purplevoice/ etc. The trap unconditionally cleans up the temp dir.
#
# RED at Wave 0 commit — uninstall.sh does not yet exist (created in Plan 03-02).

set -uo pipefail
cd "$(dirname "$0")/.."   # repo root

if [ ! -f uninstall.sh ]; then
  echo "FAIL [test_uninstall_dryrun.sh]: uninstall.sh not found at repo root (Plan 03-02 creates it)"
  exit 1
fi

# Sandbox $HOME so destructive operations cannot touch the real $HOME.
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT

# Pre-seed the 5 surfaces uninstall.sh is supposed to remove.
mkdir -p "$SANDBOX/.config/purplevoice"
mkdir -p "$SANDBOX/.cache/purplevoice"
mkdir -p "$SANDBOX/.local/share/purplevoice/models"
mkdir -p "$SANDBOX/.local/bin"
mkdir -p "$SANDBOX/.hammerspoon"
echo "fake-vocab" > "$SANDBOX/.config/purplevoice/vocab.txt"
echo "fake-model" > "$SANDBOX/.local/share/purplevoice/models/ggml-small.en.bin"
ln -sfn "$(pwd)/purplevoice-record" "$SANDBOX/.local/bin/purplevoice-record"
ln -sfn "$(pwd)/purplevoice-lua"    "$SANDBOX/.hammerspoon/purplevoice"

FAIL=0

# First run: should remove all 5 surfaces and exit 0.
HOME="$SANDBOX" bash uninstall.sh >/tmp/purplevoice-uninstall-test-1.log 2>&1
RC=$?
if [ "$RC" -ne 0 ]; then
  echo "FAIL [test_uninstall_dryrun.sh]: first run exited $RC (expected 0)"
  cat /tmp/purplevoice-uninstall-test-1.log
  FAIL=1
fi
for path in "$SANDBOX/.config/purplevoice" "$SANDBOX/.cache/purplevoice" "$SANDBOX/.local/share/purplevoice" "$SANDBOX/.local/bin/purplevoice-record" "$SANDBOX/.hammerspoon/purplevoice"; do
  if [ -e "$path" ] || [ -L "$path" ]; then
    echo "FAIL [test_uninstall_dryrun.sh]: first run did not remove $path"
    FAIL=1
  fi
done

# Second run: must be idempotent (exit 0, "already absent" path).
HOME="$SANDBOX" bash uninstall.sh >/tmp/purplevoice-uninstall-test-2.log 2>&1
RC=$?
if [ "$RC" -ne 0 ]; then
  echo "FAIL [test_uninstall_dryrun.sh]: second run exited $RC (expected 0; idempotency broken)"
  cat /tmp/purplevoice-uninstall-test-2.log
  FAIL=1
fi
if ! grep -q "Already absent" /tmp/purplevoice-uninstall-test-2.log; then
  echo "FAIL [test_uninstall_dryrun.sh]: second run did not print 'Already absent' (idempotency signal missing)"
  FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS [test_uninstall_dryrun.sh]: uninstall.sh removes all 5 surfaces idempotently in sandbox"
  exit 0
fi
exit 1
