#!/usr/bin/env bash
# tests/test_install_sh_dst06_option_b.sh — DST-06 invariant: install.sh implements
# Option B (bundled installer, no fork) and contains ZERO Option A/C fork-or-rename logic.
#
# Per Phase 3 CONTEXT D-01: PurpleVoice ships as a Hammerspoon module dropped into
# ~/.hammerspoon/purplevoice/ (existing pattern from setup.sh Step 6c). Hammerspoon
# stays as STOCK Hammerspoon — installed via brew cask, branded as Hammerspoon in TCC.
#
# RED at Wave 0 commit — install.sh does not yet exist (created in Plan 03-01).

set -uo pipefail
cd "$(dirname "$0")/.."   # repo root

if [ ! -f install.sh ]; then
  echo "FAIL [test_install_sh_dst06_option_b.sh]: install.sh not found at repo root (Plan 03-01 creates it)"
  exit 1
fi

FAIL=0

# Positive check: Option B path = brew install --cask hammerspoon present.
if ! grep -qE 'brew[[:space:]]+install[[:space:]]+--cask[[:space:]]+hammerspoon' install.sh; then
  echo "FAIL [test_install_sh_dst06_option_b.sh]: install.sh missing 'brew install --cask hammerspoon' (Option B path)"
  FAIL=1
fi

# Negative checks: Option A (fork) / Option C (rename signed binary) signatures must NOT appear.
FORK_HITS=$(grep -nE '(mv[[:space:]]+[^"]*Hammerspoon\.app[[:space:]]+[^"]*PurpleVoice\.app|cp[[:space:]]+-R[[:space:]]+[^"]*Hammerspoon\.app|codesign[[:space:]]+[^|]*PurpleVoice\.app|CFBundleIdentifier[[:space:]]*=[[:space:]]*[^"]*purplevoice)' install.sh || true)
if [ -n "$FORK_HITS" ]; then
  echo "FAIL [test_install_sh_dst06_option_b.sh]: install.sh contains Option A/C fork-or-rename signatures (DST-06 violation):"
  echo "$FORK_HITS"
  FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS [test_install_sh_dst06_option_b.sh]: install.sh implements Option B (bundled installer, no fork)"
  exit 0
fi
exit 1
