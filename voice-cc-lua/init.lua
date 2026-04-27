-- voice-cc — Phase 1 spike Hammerspoon module
-- Wires cmd+shift+e (push-and-hold) to the bash glue at
-- ~/.local/bin/voice-cc-record. Captures stdout, copies to clipboard,
-- simulates cmd+v into the focused app.
--
-- Phase 1 deliberately OMITS: menu-bar indicator, audio cues, clipboard
-- preserve/restore, transient UTI marker, re-entrancy guard, TCC toast
-- detection, empty-transcript filter. All deferred to Phase 2.

local M = {}

-- Absolute path to the bash glue. Hammerspoon's hs.task does NOT do PATH
-- lookup, so this MUST be absolute. (Pitfall 2 mitigation extends to Lua.)
local SCRIPT_PATH = os.getenv("HOME") .. "/.local/bin/voice-cc-record"

-- Active task handle, so onRelease can :terminate() it.
local currentTask = nil

local function onPress()
  -- If a previous task is somehow still alive, drop this press. Phase 2
  -- will introduce a proper isRecording flag (ROB-01); Phase 1 just
  -- avoids spawning a second task on top of an unfinished first.
  if currentTask and currentTask:isRunning() then
    return
  end

  currentTask = hs.task.new(SCRIPT_PATH, function(exitCode, stdOut, stdErr)
    -- Phase 1: any non-zero exit means "no paste" and we silently move on.
    -- Phase 2 will introduce semantic exit-code dispatch (10/11/12 → toasts).
    if exitCode ~= 0 then
      currentTask = nil
      return
    end

    local transcript = stdOut or ""
    if transcript == "" then
      -- Phase 1: empty transcript = empty paste (observable, fine for spike).
      -- Phase 2 will silently abort instead (INJ-04).
      currentTask = nil
      return
    end

    -- Set clipboard then synthesise cmd+v.
    -- Phase 2 will: (a) preserve previous clipboard contents and restore
    -- after 250ms (INJ-02), (b) mark the set as transient via the
    -- nspasteboard transient-type marker (INJ-03).
    -- Phase 1 just clobbers the clipboard — observable, fine for spike.
    hs.pasteboard.setContents(transcript)
    hs.eventtap.keyStroke({"cmd"}, "v", 0)

    currentTask = nil
  end)

  if currentTask == nil then
    -- hs.task.new returns nil if the script path doesn't exist.
    hs.alert.show("voice-cc: script not found at " .. SCRIPT_PATH, 4)
    return
  end

  currentTask:start()
end

local function onRelease()
  if currentTask and currentTask:isRunning() then
    currentTask:terminate()
  end
end

-- Bind cmd+shift+e (CONTEXT.md D-01 + Pitfall 5).
-- Known minor conflict: VS Code/Cursor "Show Explorer" sidebar — accepted by user.
local hk = hs.hotkey.bind({"cmd", "shift"}, "e", onPress, onRelease)
if not hk then
  -- Pitfall 5: hs.hotkey.bind returns nil if the combo is already taken.
  -- Phase 1 surfaces this as an alert (visible during reload). Phase 2
  -- will swap this alert for an actionable toast notification.
  hs.alert.show("voice-cc: cmd+shift+e binding failed (in use?)", 4)
end

-- Confirmation message on Hammerspoon load (so we know the module ran).
hs.alert.show("voice-cc loaded (cmd+shift+e)", 1.5)

return M
