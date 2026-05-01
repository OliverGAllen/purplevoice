#!/usr/bin/env bash
# tests/test_karabiner_check.sh — Phase 4 Karabiner-check string-level wiring assertion
#
# Asserts that:
#   1. assets/karabiner-fn-to-f19.json exists and parses as valid JSON
#   2. The JSON has the documented top-level structure (title + rules + manipulators)
#   3. The from.key_code is "fn" and to_if_held_down has key_code "f19"
#   4. install.sh contains the Karabiner-Elements check + actionable error
#   5. install.sh contains the file-existence guard for the JSON
#   6. purplevoice-lua/init.lua binds F19 (no modifiers)
#   7. purplevoice-lua/init.lua binds F18 for re-paste (Karabiner backtick-hold)
#   8. purplevoice-lua/init.lua does NOT bind cmd+shift+e (deliberate replacement)
#
# RED-at-Wave-0 by design: assets/karabiner-fn-to-f19.json + install.sh Step 9 +
# init.lua F19/F18 bindings do not exist yet. Plan 04-01 turns checks
# 6, 7, 8 GREEN; Plan 04-02 turns checks 1-5 GREEN. Final state: 8/8 GREEN.
# (Phase 3 / Plan 03-01: setup.sh renamed to install.sh per D-05; references updated.)
#
# Exit 0 = wiring intact; exit 1 = drift or missing file.
set -uo pipefail
cd "$(dirname "$0")/.."   # repo root

FAIL=0
KARABINER_JSON="assets/karabiner-fn-to-f19.json"
SETUP="install.sh"
INIT="purplevoice-lua/init.lua"

# 1. JSON file exists and parses
if [ ! -f "$KARABINER_JSON" ]; then
  echo "FAIL: $KARABINER_JSON missing"
  FAIL=1
elif ! jq empty "$KARABINER_JSON" 2>/dev/null; then
  echo "FAIL: $KARABINER_JSON is not valid JSON"
  FAIL=1
fi

# 2. Documented top-level structure
if [ "$FAIL" -eq 0 ] && [ -f "$KARABINER_JSON" ]; then
  TITLE=$(jq -r '.title // empty' "$KARABINER_JSON")
  RULES_COUNT=$(jq '.rules | length' "$KARABINER_JSON" 2>/dev/null || echo 0)
  if [ -z "$TITLE" ]; then
    echo "FAIL: $KARABINER_JSON missing top-level 'title' field"
    FAIL=1
  fi
  if [ "$RULES_COUNT" -lt 1 ]; then
    echo "FAIL: $KARABINER_JSON has no rules"
    FAIL=1
  fi
fi

# 3. from.key_code=fn, to_if_held_down.key_code=f19
if [ "$FAIL" -eq 0 ] && [ -f "$KARABINER_JSON" ]; then
  FROM_KEY=$(jq -r '.rules[0].manipulators[0].from.key_code // empty' "$KARABINER_JSON")
  HELD_KEY=$(jq -r '.rules[0].manipulators[0].to_if_held_down[0].key_code // empty' "$KARABINER_JSON")
  if [ "$FROM_KEY" != "fn" ]; then
    echo "FAIL: $KARABINER_JSON from.key_code is '$FROM_KEY' (expected 'fn')"
    FAIL=1
  fi
  if [ "$HELD_KEY" != "f19" ]; then
    echo "FAIL: $KARABINER_JSON to_if_held_down.key_code is '$HELD_KEY' (expected 'f19')"
    FAIL=1
  fi
fi

# 4. setup.sh contains the Karabiner check
if ! grep -q "Karabiner-Elements.app" "$SETUP"; then
  echo "FAIL: $SETUP missing /Applications/Karabiner-Elements.app check"
  FAIL=1
fi

# 5. setup.sh contains the file-existence guard
if ! grep -q "karabiner-fn-to-f19.json" "$SETUP"; then
  echo "FAIL: $SETUP missing reference to assets/karabiner-fn-to-f19.json"
  FAIL=1
fi

# 6. init.lua binds F19 with empty modifier table
if ! grep -qE 'hs\.hotkey\.bind\(\{\}, ?"f19"' "$INIT"; then
  echo "FAIL: $INIT missing F19 binding (hs.hotkey.bind({}, \"f19\", ...))"
  FAIL=1
fi

# 7. init.lua binds F18 for re-paste (emitted by Karabiner backtick-hold rule)
if ! grep -qE 'hs\.hotkey\.bind\(\{\}, ?"f18"' "$INIT"; then
  echo "FAIL: $INIT missing F18 re-paste binding (hs.hotkey.bind({}, \"f18\", ...))"
  FAIL=1
fi

# 8. init.lua does NOT bind cmd+shift+e (deliberate replacement per CONTEXT.md D-05)
if grep -qE 'hs\.hotkey\.bind\(\{"cmd", ?"shift"\}, ?"e"' "$INIT"; then
  echo "FAIL: $INIT still binds cmd+shift+e (Phase 4 D-05 requires removal)"
  FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS [test_karabiner_check.sh]: Karabiner JSON valid; setup.sh check present; init.lua bindings correct"
  exit 0
fi
exit 1
