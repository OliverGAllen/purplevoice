-- .hammerspoon-init-snippet.lua
-- PurpleVoice Phase 2.5 — paste this into ~/.hammerspoon/init.lua at the top.
--
-- PurpleVoice is local voice dictation for macOS. Nothing leaves your Mac.
--
-- Per ARCHITECTURE.md Anti-Pattern 4, PurpleVoice NEVER auto-edits your init.lua.
-- Apply this manually. Idempotent: if `require("hs.ipc")` is already present
-- (grep -F 'require("hs.ipc")' ~/.hammerspoon/init.lua), skip — no second
-- require is needed.

-- Enables the `hs` CLI tool at /opt/homebrew/bin/hs by opening a Mach
-- message port in the Hammerspoon process. After this is loaded:
--   hs -c "1+1"                 → prints 2
--   hs -c "hs.reload()"         → reloads Hammerspoon scriptably
--   echo 'print("hi")' | hs    → remote eval
--
-- TCC requirement: NONE (no system-protected resources accessed).
-- Side effects: one Mach port at Hammerspoon launch, no measurable overhead.
--
-- Source: PurpleVoice Phase 2 Plan 02-02; .planning/phases/02-hardening/02-RESEARCH.md §12.
require("hs.ipc")

-- After installing PurpleVoice (run setup.sh), also paste:
-- require("purplevoice")
