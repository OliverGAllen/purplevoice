-- purplevoice — Phase 2 hardened Hammerspoon module (PurpleVoice)
-- Wires cmd+shift+e (push-and-hold) to ~/.local/bin/purplevoice-record.
--
-- Phase 2 additions over Phase 1:
--   - hs.accessibilityState(true) on load (Phase-1 TODO a — surface prompt)
--   - Menubar indicator: grey ● idle, red ● recording (FBK-01)
--   - Audio cues: Pop on press, Tink on release; PURPLEVOICE_NO_SOUNDS=1 silences (FBK-02)
--   - Clipboard preserve/restore via hs.pasteboard.readAllData/writeAllData (INJ-02)
--   - Transient UTI marker so clipboard managers skip transcripts (INJ-03)
--   - Re-entrancy guard via isRecording boolean + pcall-wrapped resetState (ROB-01)
--   - handleExit() stub for Plan 02-03 to extend with hs.notify dispatch
--
-- Phase 2 deliberately OMITS (deferred to Plan 02-03):
--   - hs.notify with action button + System Settings deep links (FBK-03)
--   - notifyOnce dedup cooldown
--   - Exit-code 10/11/12 dispatch to user-visible toasts (currently logged only)

-- ----------------------------------------------------------------
-- hs.notify orphaned-tag cleanup (Phase 2.5 rebrand — RESEARCH §"Pattern 4")
-- ----------------------------------------------------------------
-- The Phase 2 init.lua registered callbacks under the old voicecc tag names.
-- Notification Center may still hold notifications referencing those tags;
-- clicking them after rebrand would raise the Hammerspoon console (default
-- orphaned-tag behaviour) instead of opening Settings. Unregistering the old
-- tags is a safe no-op if they don't exist and protective if they do.
pcall(hs.notify.unregister, "voiceccOpenMicSettings")
pcall(hs.notify.unregister, "voiceccOpenAccessibilitySettings")

-- ----------------------------------------------------------------
-- Brand constants (exposed for future Phase 3.5 HUD consumption)
-- ----------------------------------------------------------------
local BRAND = {
  NAME = "PurpleVoice",
  TAGLINE = "Local voice dictation. Nothing leaves your Mac.",
  COLOUR_LAVENDER = "#B388EB",
}

-- ----------------------------------------------------------------
-- HUD constants (Phase 3.5 — D-01..D-08 locked decisions)
-- ----------------------------------------------------------------
-- Form factor: 140x36 lavender pill with 18px corner radius (D-01, D-04).
-- Translucent (canvas-level alpha 0.85) — D-03 explicitly rejects backdrop blur.
-- White "● Recording" text on lavender (D-02).
-- Top-center default position (D-05); ~50px below menubar (D-08).
-- Plan 03.5-01 ships ONLY the default top-center position; Plan 03.5-02 adds
-- the env-var-driven six-named-position resolution + fallback warning.
local HUD_W = 140
local HUD_H = 36
local HUD_CORNER_RADIUS = 18
local HUD_ALPHA = 0.85
local HUD_FONT_SIZE = 14
local HUD_TOP_GAP = 50         -- ~50px below menubar (D-08)

local M = {}

-- ----------------------------------------------------------------
-- Surface Accessibility prompt deterministically on load (Phase-1 TODO a).
-- ----------------------------------------------------------------
-- Phase 1 walkthrough found Hammerspoon does NOT auto-prompt for Accessibility
-- on first hs.eventtap.keyStroke (silent no-op). Passing true requests the
-- prompt — idempotent if already granted, surfaces the dialog if not.
--
-- Plan 02-03 extension: capture return value so we can surface a notification
-- if the user dismissed the prompt without granting (defence-in-depth per
-- RESEARCH §11). The notification uses purplevoiceOpenAccessibilitySettings
-- (registered below) and is sent AFTER the hs.notify.register block so the
-- callback is wired before we fire. See "Defence-in-depth Accessibility deny"
-- block near the end of this file.
local accessibilityOk = hs.accessibilityState(true)

-- ----------------------------------------------------------------
-- Constants
-- ----------------------------------------------------------------
local SCRIPT_PATH = os.getenv("HOME") .. "/.local/bin/purplevoice-record"
-- Menubar palette - Phase 2.5 visual identity (BRD-03, D-09).
-- Lavender for both states; recording-state differentiation via glyph shape (filled vs outline)
-- per RESEARCH Pattern 3. Single hex constant lives on M.BRAND.COLOUR_LAVENDER.
local MENUBAR_COLOR = BRAND.COLOUR_LAVENDER

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
-- Filled vs outline differentiation (RESEARCH Pattern 3 recommendation):
--   idle      = U+25CB white circle outline glyph
--   recording = U+25CF black circle filled glyph
-- Both styled lavender; the shape difference is what the user sees.
local idleTitle = hs.styledtext.new("○", { color = { hex = MENUBAR_COLOR } })
local recordingTitle = hs.styledtext.new("●", { color = { hex = MENUBAR_COLOR } })

local function setMenubarIdle()
  if menubar then menubar:setTitle(idleTitle) end
end

local function setMenubarRecording()
  if menubar then menubar:setTitle(recordingTitle) end
end

-- ----------------------------------------------------------------
-- HUD configuration (Phase 3.5 — D-09..D-11 locked decisions)
-- ----------------------------------------------------------------
-- Read once at module load; reload Hammerspoon to apply changes (D-11).
-- Default-ON (D-09): HUD enabled unless PURPLEVOICE_HUD_OFF == "1".
-- Mirrors the PURPLEVOICE_NO_SOUNDS idiom (audio cues block below).
--
-- Plan 03.5-01: only PURPLEVOICE_HUD_OFF is read here. Position is hard-coded
-- to "top-center" (D-05 default). Plan 03.5-02 adds PURPLEVOICE_HUD_POSITION
-- with the six-named-position validation + console fallback warning (D-07).
--
-- Declared HERE (above the HUD canvas block) because Lua locals are not
-- forward-visible — `if hudEnabled then` in the canvas block requires the
-- declaration to come first.
local hudEnabled = (os.getenv("PURPLEVOICE_HUD_OFF") ~= "1")
local hudPosition = "top-center"

-- ----------------------------------------------------------------
-- HUD canvas (Phase 3.5 — RESEARCH Pattern 1; defence-in-depth orphan
-- cleanup mirrors the pcall(hs.notify.unregister, ...) precedent at
-- line 26-27. _G._purplevoice_hud is a name-spaced global that survives
-- the Hammerspoon reload Lua-state teardown so the next reload can
-- delete the previous canvas instance explicitly. RESEARCH Priority 7.
-- ----------------------------------------------------------------
if _G._purplevoice_hud then
  pcall(function() _G._purplevoice_hud:delete() end)
  _G._purplevoice_hud = nil
end

-- Active-screen resolution (RESEARCH Pattern 3 / Priority 5).
-- Per-press resolution cost is microseconds — tiny vs. the press-hold loop.
local function activeScreen()
  local fw = hs.window.focusedWindow()
  if fw then
    local s = fw:screen()
    if s then return s end
  end
  return hs.screen.mainScreen()
end

-- Position arithmetic (Plan 03.5-01 STUB — top-center only; Plan 03.5-02
-- replaces this with the full six-named-position implementation per
-- RESEARCH Priority 6 / Pattern 5).
local function positionFor(name, screenFrame)
  -- screenFrame: hs.screen:fullFrame() — table with x, y, w, h in global coords.
  -- All coordinates are global (multi-monitor safe per RESEARCH Pitfall 7).
  return {
    x = screenFrame.x + (screenFrame.w - HUD_W) / 2,
    y = screenFrame.y + HUD_TOP_GAP,
  }
end

-- Canvas creation (RESEARCH Pattern 1). One canvas per module load,
-- hidden initially. Created only if hudEnabled — this preserves the
-- HUD-02 disable-via-env-var contract: env=1 -> canvas never allocated,
-- showHUD/hideHUD are no-ops via the `if not hudCanvas then return end`
-- guards.
--
-- Note: alpha is set at the CANVAS level (not the rectangle's fillColor)
-- per RESEARCH Pitfall 3 — single source of truth for translucency,
-- prevents text-edge double-composite haze.
local hudCanvas = nil
if hudEnabled then
  hudCanvas = hs.canvas.new({ x = 0, y = 0, w = HUD_W, h = HUD_H })
    :level("status")
    :behaviorAsLabels({"canJoinAllSpaces", "stationary", "transient"})
    :wantsLayer(true)
    :alpha(HUD_ALPHA)

  hudCanvas:appendElements(
    {
      type = "rectangle",
      action = "fill",
      frame = { x = 0, y = 0, w = HUD_W, h = HUD_H },
      roundedRectRadii = { xRadius = HUD_CORNER_RADIUS, yRadius = HUD_CORNER_RADIUS },
      fillColor = { hex = BRAND.COLOUR_LAVENDER, alpha = 1.0 },
    },
    {
      type = "text",
      text = hs.styledtext.new("● Recording", {
        font = { name = ".AppleSystemUIFont", size = HUD_FONT_SIZE },
        color = { white = 1, alpha = 1 },
        paragraphStyle = { alignment = "center" },
      }),
      frame = { x = 0, y = 9, w = HUD_W, h = 18 },
    }
  )

  _G._purplevoice_hud = hudCanvas
end

-- Show/hide functions (RESEARCH Pattern 2 / Priority 4).
-- :show(0) instant on press — press-hold indicators feel laggy with any
-- fade-in. :hide(0.15) on release — matches hs.alert.defaultStyle.fadeOutDuration;
-- well under HUD-01's 250ms budget. Both gated on hudCanvas non-nil so
-- env=1 produces clean no-ops.
--
-- Position recomputed each press (active screen may have changed since
-- module load — multi-monitor reshuffle, focused-window switch).
local function showHUD()
  if not hudCanvas then return end
  local screen = activeScreen()
  local screenFrame = screen:fullFrame()
  local pos = positionFor(hudPosition, screenFrame)
  hudCanvas:topLeft(pos)
  hudCanvas:show(0)
end

local function hideHUD()
  if not hudCanvas then return end
  hudCanvas:hide(0.15)
end

-- ----------------------------------------------------------------
-- Audio cues (FBK-02)
-- PURPLEVOICE_NO_SOUNDS read once at module load; reload Hammerspoon to change.
-- ----------------------------------------------------------------
local startSound = hs.sound.getByName("Pop")
local stopSound = hs.sound.getByName("Tink")
local soundsEnabled = (os.getenv("PURPLEVOICE_NO_SOUNDS") ~= "1")

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
  pcall(hideHUD)             -- Phase 3.5: hide HUD on every exit path
  setMenubarIdle()
end

-- ----------------------------------------------------------------
-- Notification callbacks (Plan 02-03) — registered at module load so they
-- survive Hammerspoon reload (Hammerspoon issue #1414). Tags are referenced
-- by handleExit() and the Accessibility-deny notification at the end of
-- this file. Both callbacks deep-link to System Settings via the
-- x-apple.systempreferences scheme (verified working on macOS Sequoia 15.7.5
-- per RESEARCH §4).
-- ----------------------------------------------------------------
-- NOTE: Hammerspoon's hs.urlevent.openURL() requires "://" in the URL —
-- the bare-colon form ("x-apple.systempreferences:...") that macOS `open`
-- accepts is rejected by Hammerspoon with "lacks '://'". Both forms route
-- to the same System Settings pane on Sequoia 15.7.5.
hs.notify.register("purplevoiceOpenMicSettings", function(notification)
  hs.urlevent.openURL("x-apple.systempreferences://com.apple.settings.PrivacySecurity.extension?Privacy_Microphone")
end)

hs.notify.register("purplevoiceOpenAccessibilitySettings", function(notification)
  hs.urlevent.openURL("x-apple.systempreferences://com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility")
end)

-- ----------------------------------------------------------------
-- Notification dedup (Plan 02-03) — prevents spam on repeated failures
-- (RESEARCH §9). 60s cooldown per key. Used both for numeric exit codes
-- (10/11/12) and string namespaces ("accessibility") — Hammerspoon reloads
-- on every config change, so the Accessibility-deny path needs dedup too
-- or every reload while permission is denied would re-fire the notification.
-- Numeric exit codes (0-12) cannot collide with string keys, so a single
-- shared dict is safe.
-- ----------------------------------------------------------------
local lastNotifyAt = {}   -- key -> timestamp seconds (key: number or string)
local NOTIFY_COOLDOWN_S = 60

local function notifyOnce(key, factory)
  local now = hs.timer.absoluteTime() / 1e9
  local last = lastNotifyAt[key] or 0
  if (now - last) < NOTIFY_COOLDOWN_S then
    return  -- recently notified for this key; suppress
  end
  lastNotifyAt[key] = now
  factory()
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
-- Phase 2 Plan 02-03: explicit 10 (TCC mic) / 11 (install) / 12 (failure)
-- branches using hs.notify with action button + 60s dedup cooldown.
-- ----------------------------------------------------------------
local function handleExit(exitCode, stdOut, stdErr)
  if exitCode == 0 then
    pasteWithRestore(stdOut)
  elseif exitCode == 2 then
    -- Silent abort: clip too short. No paste, no toast.
  elseif exitCode == 3 then
    -- Silent abort: empty / denylist match. No paste, no toast.
  elseif exitCode == 10 then
    -- TCC microphone permission denied (sox stderr matched the
    -- Permission denied / AudioObject*PropertyData / kAudio.*Error
    -- fingerprint emitted by Plan 02-01). Surface an actionable
    -- notification with a deep link to Privacy & Security → Microphone.
    notifyOnce(10, function()
      hs.notify.new("purplevoiceOpenMicSettings", {
        title = "PurpleVoice: microphone blocked",
        informativeText = "Grant Hammerspoon access in Privacy & Security → Microphone",
        actionButtonTitle = "Open Settings",
        hasActionButton = true,
        autoWithdraw = false,
        withdrawAfter = 0,
      }):send()
    end)
  elseif exitCode == 11 then
    -- Binary or model missing. No deep link — user needs to re-run setup.sh.
    notifyOnce(11, function()
      hs.notify.new({
        title = "PurpleVoice: install incomplete",
        informativeText = "Run setup.sh — model or binary missing",
        autoWithdraw = false,
      }):send()
    end)
  elseif exitCode == 12 then
    -- Generic sox / transcription failure (non-TCC). Log + notify.
    notifyOnce(12, function()
      hs.notify.new({
        title = "PurpleVoice: transcription failed",
        informativeText = "Check ~/.cache/purplevoice/error.log for details",
      }):send()
    end)
  else
    -- Truly unknown exit code — log + generic toast (still dedup'd by code).
    hs.console.printStyledtext("PurpleVoice unknown exit " .. tostring(exitCode))
    notifyOnce(exitCode, function()
      hs.notify.new({
        title = "PurpleVoice: unexpected exit " .. tostring(exitCode),
        informativeText = "Check Hammerspoon console for details",
      }):send()
    end)
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
  pcall(showHUD)             -- Phase 3.5: show HUD alongside menubar
  playStartCue()

  currentTask = hs.task.new(SCRIPT_PATH, function(exitCode, stdOut, stdErr)
    -- pcall-wrapped so an exception in handleExit still calls resetState.
    local ok, err = pcall(function()
      handleExit(exitCode, stdOut or "", stdErr or "")
    end)
    if not ok then
      hs.console.printStyledtext("PurpleVoice onExit error: " .. tostring(err))
    end
    resetState()
  end)

  if currentTask == nil then
    hs.alert.show("PurpleVoice: script not found at " .. SCRIPT_PATH, 4)
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
  hs.alert.show("PurpleVoice: cmd+shift+e binding failed (in use?)", 4)
end

-- Initialise menubar to idle BEFORE returning so idle dot is visible immediately.
setMenubarIdle()

-- ----------------------------------------------------------------
-- Defence-in-depth Accessibility deny (Plan 02-03; extends Phase-1 TODO a
-- per RESEARCH §11). If the user dismissed the prompt that
-- hs.accessibilityState(true) surfaced at module load, show a persistent
-- notification with an "Open Settings" deep link.
--
-- WRAPPED IN notifyOnce("accessibility", ...) — Hammerspoon reloads on every
-- config change; without this dedup, every reload while permission is denied
-- would fire ANOTHER notification (reload-spam). The string key
-- "accessibility" namespaces it from numeric exit codes (which are 0-12 only).
-- ----------------------------------------------------------------
if not accessibilityOk then
  notifyOnce("accessibility", function()
    hs.notify.new("purplevoiceOpenAccessibilitySettings", {
      title = "PurpleVoice: accessibility required",
      informativeText = "Grant Hammerspoon access in Privacy & Security → Accessibility",
      actionButtonTitle = "Open Settings",
      hasActionButton = true,
      autoWithdraw = false,
      withdrawAfter = 0,
    }):send()
  end)
end

-- Confirmation message on load
hs.alert.show("PurpleVoice loaded — local dictation, cmd+shift+e", 1.5)

M.BRAND = BRAND
return M
