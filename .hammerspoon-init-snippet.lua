-- .hammerspoon-init-snippet.lua
-- voice-cc Phase 2 — paste this into ~/.hammerspoon/init.lua at the top.
--
-- Per ARCHITECTURE.md Anti-Pattern 4, voice-cc NEVER auto-edits your init.lua.
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
-- Source: voice-cc Phase 2 Plan 02-02; .planning/phases/02-hardening/02-RESEARCH.md §12.
require("hs.ipc")
