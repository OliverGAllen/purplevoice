#!/usr/bin/env bash
# uninstall.sh — remove PurpleVoice user-installed surfaces.
# IDEMPOTENT — safe to re-run.
#
# Removes:
#   ~/.config/purplevoice/         (vocab.txt, denylist.txt, user config)
#   ~/.cache/purplevoice/          (transient cache)
#   ~/.local/share/purplevoice/    (models + the curl|bash clone destination
#                                   ~/.local/share/purplevoice/src/ if present)
#   ~/.local/bin/purplevoice-record (symlink only — leaves regular files alone)
#   ~/.hammerspoon/purplevoice     (symlink or directory)
#
# Does NOT remove (these may serve other tools on your machine):
#   Hammerspoon, sox, whisper-cpp, Karabiner-Elements
#   Karabiner rule files in ~/.config/karabiner/
#   Hammerspoon's ~/.hammerspoon/init.lua require() line
#   TCC permissions for Hammerspoon (Microphone / Accessibility)
#
# Manual-removal instructions for those are printed after the automated steps.
#
# A local clone of the PurpleVoice repo (e.g., at ~/dev/purplevoice/) is NOT
# touched — that's a working copy under user control. The XDG-managed
# ~/.local/share/purplevoice/ tree IS removed (PurpleVoice owns that).

set -uo pipefail

cat <<'EOF'
----------------------------------------------------------------------
PurpleVoice uninstaller — removes XDG dirs + symlinks + Hammerspoon module dir.

  Hammerspoon, sox, whisper-cpp, Karabiner-Elements, and the Karabiner rule
  files are NOT removed — they may serve other tools on your system.
  Manual-removal instructions are printed at the end.
----------------------------------------------------------------------

EOF

REMOVED=0

# 1. XDG directories
for d in "$HOME/.config/purplevoice" "$HOME/.cache/purplevoice" "$HOME/.local/share/purplevoice"; do
  if [ -d "$d" ]; then
    echo "Removing $d"
    rm -rf "$d"
    REMOVED=$((REMOVED + 1))
  else
    echo "Already absent: $d"
  fi
done

# 2. Symlinks (only if they point into the purplevoice install)
PV_BIN="$HOME/.local/bin/purplevoice-record"
if [ -L "$PV_BIN" ]; then
  TARGET="$(readlink "$PV_BIN")"
  case "$TARGET" in
    *purplevoice*|*voice-cc*)
      echo "Removing symlink $PV_BIN -> $TARGET"
      rm "$PV_BIN"
      REMOVED=$((REMOVED + 1))
      ;;
    *)
      echo "Skipping $PV_BIN -- points at $TARGET (not a PurpleVoice install; leaving alone)"
      ;;
  esac
elif [ -e "$PV_BIN" ]; then
  echo "WARN: $PV_BIN is a regular file, not a symlink -- leaving alone." >&2
else
  echo "Already absent: $PV_BIN"
fi

# 3. Hammerspoon module symlink (or directory if user installed manually)
HS_MODULE="$HOME/.hammerspoon/purplevoice"
if [ -L "$HS_MODULE" ]; then
  echo "Removing symlink $HS_MODULE"
  rm "$HS_MODULE"
  REMOVED=$((REMOVED + 1))
elif [ -d "$HS_MODULE" ]; then
  echo "Removing directory $HS_MODULE"
  rm -rf "$HS_MODULE"
  REMOVED=$((REMOVED + 1))
else
  echo "Already absent: $HS_MODULE"
fi

# 4. Final banner with manual-removal instructions
cat <<EOF

----------------------------------------------------------------------
Manual cleanup (PurpleVoice cannot do these for you):

  1. Remove the require("purplevoice") line from ~/.hammerspoon/init.lua
     (and reload Hammerspoon: menubar -> Reload Config).

  2. Disable the Karabiner rules (PurpleVoice -- fn -> F19 + PurpleVoice -- backtick -> F18):
     Karabiner-Elements -> Preferences -> Complex Modifications -> toggle off.
     The rule JSONs themselves stay in place; remove from ~/.config/karabiner/
     manually if you want a full cleanup.

  3. Optional: brew uninstall hammerspoon sox whisper-cpp
     (only if no other tools on your machine use them).

  4. Optional: revoke Hammerspoon's TCC permissions (if you don't use Hammerspoon for
     anything else):
       tccutil reset Microphone org.hammerspoon.Hammerspoon
       tccutil reset Accessibility org.hammerspoon.Hammerspoon

PurpleVoice removed $REMOVED user-data items. Bye.
----------------------------------------------------------------------
EOF

exit 0
