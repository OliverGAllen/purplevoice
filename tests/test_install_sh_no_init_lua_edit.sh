#!/usr/bin/env bash
# tests/test_install_sh_no_init_lua_edit.sh — DST-02 invariant: install.sh PRINTS the
# require("purplevoice") line, never auto-edits ~/.hammerspoon/init.lua.
#
# Per Phase 3 CONTEXT D-02 (carried from setup.sh Step 10 banner pattern):
# install.sh must NOT contain any append/overwrite/in-place-edit of init.lua.
#
# RED at Wave 0 commit — install.sh does not yet exist (created in Plan 03-01).

set -uo pipefail
cd "$(dirname "$0")/.."   # repo root

if [ ! -f install.sh ]; then
  echo "FAIL [test_install_sh_no_init_lua_edit.sh]: install.sh not found at repo root (Plan 03-01 creates it)"
  exit 1
fi

# Forbidden idioms (any of these against init.lua = DST-02 violation):
#   >> ~/.hammerspoon/init.lua    (append redirect)
#   > ~/.hammerspoon/init.lua     (overwrite redirect)
#   tee ... .hammerspoon/init.lua (tee write)
#   sed -i ... .hammerspoon/init.lua (in-place edit)
#   echo ... >> ... .hammerspoon/init.lua

VIOLATIONS=$(grep -nE '(>>?[[:space:]]*[^"]*\.hammerspoon/init\.lua|tee[[:space:]]+[^|]*\.hammerspoon/init\.lua|sed[[:space:]]+-i[[:space:]][^|]*\.hammerspoon/init\.lua)' install.sh || true)

if [ -n "$VIOLATIONS" ]; then
  echo "FAIL [test_install_sh_no_init_lua_edit.sh]: install.sh contains init.lua write/append (DST-02 violation):"
  echo "$VIOLATIONS"
  exit 1
fi

echo "PASS [test_install_sh_no_init_lua_edit.sh]: install.sh does not auto-edit ~/.hammerspoon/init.lua"
exit 0
