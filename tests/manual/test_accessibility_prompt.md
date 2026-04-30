# Manual Test: Accessibility prompt fires on module load (Phase-1 TODO a)

**Requirement:** Phase-1 TODO (a) — Add `hs.accessibilityState(true)` to purplevoice-lua/init.lua on load to surface the Accessibility prompt deterministically.

**Background:** Phase 1 walkthrough (01-03-SUMMARY.md "Quirks Discovered" #1) found that Hammerspoon does NOT auto-prompt for Accessibility on first `hs.eventtap.keyStroke`. The fix: call `hs.accessibilityState(true)` at module load to surface the prompt proactively.

**Prerequisites:** Phase 2 PurpleVoice loop deployed (Plan 02-02 complete). Hammerspoon currently has Accessibility granted (we'll revoke and re-grant).

## Steps

1. **CAPTURE BASELINE:** Confirm PurpleVoice paste works currently. Hold hotkey, say something, transcript appears.
2. In Terminal: `tccutil reset Accessibility org.hammerspoon.Hammerspoon`
3. Restart Hammerspoon (Cmd-Q the app, relaunch from /Applications/, OR `osascript -e 'tell application "Hammerspoon" to quit'` then `open /Applications/Hammerspoon.app`).
4. **Expected:** Within ~2 seconds of Hammerspoon launch (and the PurpleVoice module loading), a macOS dialog appears: "Hammerspoon would like to control this computer using accessibility features." with an "Open System Settings" button.
5. Click "Open System Settings" — System Settings opens to Privacy & Security → Accessibility.
6. Toggle Hammerspoon to ON. Close System Settings.
7. Press and hold F19 (Karabiner-remapped from fn), say "test phrase", release. Transcript should paste normally.

## Optional: deny path

8. Repeat steps 2–3, but click "Deny" (or close the dialog without granting).
9. **Expected (if defence-in-depth notification implemented per 02-RESEARCH.md §11):** A persistent notification appears: "PurpleVoice: accessibility required" with an "Open Settings" button.

## Failure modes

- No dialog appears at all → `hs.accessibilityState(true)` not in the module, or being called too early/late. Check it's at the top of purplevoice-lua/init.lua, before any hs.hotkey.bind.
- Dialog appears but says "PurpleVoice" instead of "Hammerspoon" → impossible (TCC always names the responsible process); if you see this, your eyes are tired.
- Step 7 fails silently after granting Accessibility → Hammerspoon needs a restart to pick up the new permission. Reload via Cmd-Q + relaunch, or `hs -c "hs.reload()"`.

## Sign-off

- [ ] Dialog appears within ~2s of Hammerspoon launch (after tccutil reset)
- [ ] "Open System Settings" deep-links to Privacy & Security → Accessibility
- [ ] Toggle on → PurpleVoice paste works again

**Tester:** _____________  **Date:** _____________
