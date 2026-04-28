---
phase: 02-hardening
plan: 02
status: complete
date: 2026-04-28
commits: [f4da016, deee0fe]
checkpoint_resolved: true
---

# Plan 02-02 Summary — Lua Hardening

## Goal Achieved

`voice-cc-lua/init.lua` rewritten from 82 → 208 lines with the full Phase 2 Lua surface: deterministic Accessibility prompt on load, menubar indicator, audio cues, clipboard preserve/restore with TransientType UTI, re-entrancy guard, and `handleExit` stub for Wave 3 to extend. Plus `.hammerspoon-init-snippet.lua` staged at repo root for the user to paste.

## Files Modified / Created

| Path | Lines | Status |
|------|-------|--------|
| `voice-cc-lua/init.lua` | 82 → 208 | Hardened |
| `.hammerspoon-init-snippet.lua` | new (20) | Reference snippet for `require("hs.ipc")` |

## Requirements Closed

- **FBK-01** — `hs.menubar` indicator (grey ● idle / red ● recording)
- **FBK-02** — `hs.sound` audio cues (Pop on press, Tink on release; silenced by `VOICE_CC_NO_SOUNDS=1`)
- **INJ-02** — Clipboard preserve via `hs.pasteboard.readAllData()` + restore after 250ms with content-equality guard
- **INJ-03** — Transcript paste tagged with `org.nspasteboard.TransientType` + `org.nspasteboard.ConcealedType` UTIs (clipboard managers like Maccy / 1Password / Alfred skip retention)
- **ROB-01** — `isRecording` boolean re-entrancy guard; rapid double-press doesn't spawn duplicate sox process; `pcall`-wrapped `resetState()` finally block

## Phase-1 TODOs Closed

- **(a)** `hs.accessibilityState(true)` called on module load — surfaces Accessibility prompt deterministically (the only first-run silent failure observed in Phase 1 walkthrough)
- **(b)** `require("hs.ipc")` — snippet staged at `.hammerspoon-init-snippet.lua`; user pasted it into `~/.hammerspoon/init.lua` (Task 2-3 checkpoint resolved 2026-04-28); `hs -c "1+1"` returns `2` confirming IPC works; Hammerspoon backup saved at `~/.hammerspoon/init.lua.bak.1777373014`

## Critical Revision Honoured

The revised plan (commit `033b951`) called for `pasteWithRestore()` to use a closure-captured `local pendingSaved` instead of a module-level `savedClipboard` (which was dead code shadowed by the local in iter 1, and a latent footgun for re-entrant clobber if "fixed" naively). Verified:
- `! grep -qE '^\s*local savedClipboard' voice-cc-lua/init.lua` (regression guard passes — no module-level declaration)
- `pasteWithRestore` uses `local pendingSaved = hs.pasteboard.readAllData()` (closure-captured)

## Pattern 2 Boundary

✓ Preserved: `! grep -q 'whisper-cli' voice-cc-lua/init.lua` (no whisper-cli reference in Lua; bash glue remains the SOLE invocation site).

## handleExit Stub for Wave 3

`handleExit(exitCode, stdOut, stdErr)` handles exit 0 (paste), 2 (clip-too-short silent abort), 3 (denylist silent abort), and other (logged to hs.console). Plan 02-03 will extend with `hs.notify` dispatch for exit codes 10 (TCC mic denied), 11 (binary/model missing), 12 (other detectable failure) + System Settings deep links + dedup cooldown via `notifyOnce(key, ...)` (extended to accept string keys per revision).

## Checkpoint Resolution (Task 2-3)

User opted for orchestrator-assisted paste rather than manual edit. Orchestrator backed up the existing init.lua, used Edit tool to insert `require("hs.ipc")` above `require("voice-cc")`, restarted Hammerspoon (PID 90755), and verified end-to-end:
- `hs -c "1+1"` → `2` ✓
- `hs -c "hs.reload()"` → reload fires (transport-invalidation warning during reload is normal)
- `hs -c 'print(package.loaded["voice-cc"] ~= nil)'` → `true` ✓

User signal: explicit "go ahead and do it for me" + post-action verification all green.

## Commits

| SHA | Message |
|-----|---------|
| `f4da016` | feat(02-02): harden voice-cc-lua/init.lua with Phase 2 menubar, sounds, clipboard preserve/restore, transient UTI, re-entrancy guard, accessibility prompt |
| `deee0fe` | feat(02-02): add .hammerspoon-init-snippet.lua with require("hs.ipc") for user paste |

## Deviations

- Executor agent hit usage limit AFTER reaching the Task 2-3 checkpoint (return message complete). Orchestrator wrapped up bookkeeping inline (this SUMMARY + roadmap update) and assisted user with the manual paste step at user request.
- `luac -p` syntax check skipped (luac not installed; `brew install lua` would provide it). Hammerspoon successfully loading the module + the verified `package.loaded["voice-cc"] == true` is the empirical proof of structural Lua correctness.

## Ready for Wave 3

Plan 02-03 (failure surfacing) depends on:
- This plan's `handleExit` stub → ✓ in place at line ~155-180 of voice-cc-lua/init.lua
- This plan's `notifyOnce(key, ...)` extended signature → ✓ in place
- Hammerspoon `hs.ipc` working for scripted reloads during Plan 02-03 development → ✓ verified

Wave 3 can launch.
