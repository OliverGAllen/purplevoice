-- voice-cc — Phase 2 hardened Hammerspoon module
-- Wires cmd+shift+e (push-and-hold) to ~/.local/bin/voice-cc-record.
--
-- Phase 2 additions over Phase 1:
--   - hs.accessibilityState(true) on load (Phase-1 TODO a — surface prompt)
--   - Menubar indicator: grey ● idle, red ● recording (FBK-01)
--   - Audio cues: Pop on press, Tink on release; VOICE_CC_NO_SOUNDS=1 silences (FBK-02)
--   - Clipboard preserve/restore via hs.pasteboard.readAllData/writeAllData (INJ-02)
--   - Transient UTI marker so clipboard managers skip transcripts (INJ-03)
--   - Re-entrancy guard via isRecording boolean + pcall-wrapped resetState (ROB-01)
--   - handleExit() stub for Plan 02-03 to extend with hs.notify dispatch
--
-- Phase 2 deliberately OMITS (deferred to Plan 02-03):
--   - hs.notify with action button + System Settings deep links (FBK-03)
--   - notifyOnce dedup cooldown
--   - Exit-code 10/11/12 dispatch to user-visible toasts (currently logged only)

local M = {}

-- ----------------------------------------------------------------
-- Surface Accessibility prompt deterministically on load (Phase-1 TODO a).
-- ----------------------------------------------------------------
-- Phase 1 walkthrough found Hammerspoon does NOT auto-prompt for Accessibility
-- on first hs.eventtap.keyStroke (silent no-op). Passing true requests the
-- prompt — idempotent if already granted, surfaces the dialog if not.
hs.accessibilityState(true)

-- ----------------------------------------------------------------
-- Constants
-- ----------------------------------------------------------------
local SCRIPT_PATH = os.getenv("HOME") .. "/.local/bin/voice-cc-record"
local MENUBAR_IDLE_COLOR = "#888888"
local MENUBAR_RECORDING_COLOR = "#FF3B30"

-- ----------------------------------------------------------------
-- Module state (Lua-local, in-memory only)
-- ----------------------------------------------------------------
-- NOTE: prior clipboard contents are NOT held at module scope. Each
-- pasteWithRestore() call closure-captures its own `pendingSaved` local,
-- so a re-entrant press cannot accidentally clobber another in-flight
-- restore via shared module state. See pasteWithRestore() below.
local isRecording = false
local currentTask = nil

-- ----------------------------------------------------------------
-- Menubar (FBK-01)
-- ----------------------------------------------------------------
local menubar = hs.menubar.new()
local idleTitle = hs.styledtext.new("●", { color = { hex = MENUBAR_IDLE_COLOR } })
local recordingTitle = hs.styledtext.new("●", { color = { hex = MENUBAR_RECORDING_COLOR } })

local function setMenubarIdle()
  if menubar then menubar:setTitle(idleTitle) end
end

local function setMenubarRecording()
  if menubar then menubar:setTitle(recordingTitle) end
end

-- ----------------------------------------------------------------
-- Audio cues (FBK-02)
-- VOICE_CC_NO_SOUNDS read once at module load; reload Hammerspoon to change.
-- ----------------------------------------------------------------
local startSound = hs.sound.getByName("Pop")
local stopSound = hs.sound.getByName("Tink")
local soundsEnabled = (os.getenv("VOICE_CC_NO_SOUNDS") ~= "1")

local function playStartCue()
  if soundsEnabled and startSound then
    startSound:volume(0.3):play()
  end
end

local function playStopCue()
  if soundsEnabled and stopSound then
    stopSound:volume(0.3):play()
  end
end

-- ----------------------------------------------------------------
-- State reset — called from every callback exit path via pcall finally
-- ----------------------------------------------------------------
local function resetState()
  isRecording = false
  currentTask = nil
  -- savedClipboard intentionally NOT reset here: pasteWithRestore() uses
  -- a closure-captured local (`pendingSaved`) instead of module-level
  -- state, so there is no shared variable to reset. This avoids a latent
  -- footgun where a re-entrant press could nil out an in-flight restore.
  setMenubarIdle()
end

-- ----------------------------------------------------------------
-- Paste with clipboard preserve/restore + transient UTI (INJ-02 + INJ-03)
-- ----------------------------------------------------------------
local function pasteWithRestore(transcript)
  if not transcript or transcript:match("^%s*$") then
    return  -- defence-in-depth empty drop (bash should have caught via exit 3)
  end

  -- 1. SAVE prior clipboard (all UTIs) — restore-target.
  --    Closure-captured local (NOT module-level state) so a re-entrant
  --    press cannot clobber an in-flight restore.
  local pendingSaved = hs.pasteboard.readAllData()

  -- 2. WRITE transcript + transient marker atomically.
  --    Per nspasteboard.org spec: the marker's PRESENCE is the signal;
  --    the marker's value is irrelevant (empty string is canonical).
  --    Maccy default-on, 1Password 8, Alfred all honour this.
  --    Raycast support is unverified — see RESEARCH §5 known residual risk.
  hs.pasteboard.writeAllData({
    ["public.utf8-plain-text"] = transcript,
    ["org.nspasteboard.TransientType"] = "",
    ["org.nspasteboard.ConcealedType"] = "",
  })

  -- 3. PASTE — synthesise cmd+v into the focused app.
  hs.eventtap.keyStroke({"cmd"}, "v", 0)

  -- 4. RESTORE prior clipboard after 250ms — but ONLY if the clipboard still
  --    contains our transcript (defends against user copying something else
  --    in the interim, which would otherwise be clobbered).
  hs.timer.doAfter(0.25, function()
    local current = hs.pasteboard.readAllData()
    if current and current["public.utf8-plain-text"] == transcript then
      hs.pasteboard.writeAllData(pendingSaved)
    end
  end)
end

-- ----------------------------------------------------------------
-- Exit-code dispatcher
-- Phase 2 Plan 02-02: handles 0 (paste) + 2/3 (silent abort).
-- Phase 2 Plan 02-03: extends with 10 (TCC) / 11 (install) / 12 (failure)
--                     using hs.notify with action button + dedup cooldown.
-- ----------------------------------------------------------------
local function handleExit(exitCode, stdOut, stdErr)
  if exitCode == 0 then
    pasteWithRestore(stdOut)
  elseif exitCode == 2 then
    -- Silent abort: clip too short. No paste, no toast.
  elseif exitCode == 3 then
    -- Silent abort: empty / denylist match. No paste, no toast.
  else
    -- Plan 02-03 will surface 10/11/12 with hs.notify. For now log only
    -- so failures aren't fully silent during Plan 02-02 development.
    hs.console.printStyledtext(
      "voice-cc exit " .. tostring(exitCode) ..
      " (Plan 02-03 will surface this with hs.notify)"
    )
  end
end

-- ----------------------------------------------------------------
-- Hotkey callbacks
-- ----------------------------------------------------------------
local function onPress()
  if isRecording then
    return  -- ROB-01: silent drop on rapid double-press
  end
  isRecording = true
  setMenubarRecording()
  playStartCue()

  currentTask = hs.task.new(SCRIPT_PATH, function(exitCode, stdOut, stdErr)
    -- pcall-wrapped so an exception in handleExit still calls resetState.
    local ok, err = pcall(function()
      handleExit(exitCode, stdOut or "", stdErr or "")
    end)
    if not ok then
      hs.console.printStyledtext("voice-cc onExit error: " .. tostring(err))
    end
    resetState()
  end)

  if currentTask == nil then
    hs.alert.show("voice-cc: script not found at " .. SCRIPT_PATH, 4)
    resetState()
    return
  end
  currentTask:start()
end

local function onRelease()
  if not isRecording or not currentTask then
    return  -- ignore ghost release
  end
  playStopCue()
  if currentTask:isRunning() then
    currentTask:terminate()
  end
end

-- ----------------------------------------------------------------
-- Bind cmd+shift+e (push-and-hold)
-- ----------------------------------------------------------------
local hk = hs.hotkey.bind({"cmd", "shift"}, "e", onPress, onRelease)
if not hk then
  hs.alert.show("voice-cc: cmd+shift+e binding failed (in use?)", 4)
end

-- Initialise menubar to idle BEFORE returning so idle dot is visible immediately.
setMenubarIdle()

-- Confirmation message on load
hs.alert.show("voice-cc loaded (cmd+shift+e)", 1.5)

return M
