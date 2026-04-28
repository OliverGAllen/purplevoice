# Manual Test: TCC denial → actionable notification with deep link (FBK-03)

**Requirement:** FBK-03 — When the system fails (mic permission denied), user receives an actionable macOS notification with a deep link to System Settings → Privacy → Microphone — never silent failure.

**Prerequisites:**
- Phase 2 voice-cc loop deployed (Plans 02-01, 02-02, 02-03 complete)
- Hammerspoon notification style set to "Alerts" (System Settings → Notifications → Hammerspoon → Alerts) for the action button to show. Banner mode also works but loses the button affordance.

## Steps

1. **CAPTURE BASELINE FIRST:** Confirm voice-cc currently works (hold hotkey, say something, transcript appears). This proves Microphone is currently granted.
2. In Terminal: `tccutil reset Microphone org.hammerspoon.Hammerspoon`
3. Restart Hammerspoon (menubar → Reload Config OR `hs -c "hs.reload()"`).
4. Press and hold cmd+shift+e for ~1 second. Release.
5. **Expected:** Within ~2 seconds, a macOS notification appears with:
   - Title: "voice-cc: microphone blocked"
   - Body: "Grant Hammerspoon access in Privacy & Security → Microphone"
   - Action button: "Open Settings" (visible only in Alerts mode)
6. Click the notification body (or the "Open Settings" button if visible).
7. **Expected:** System Settings opens directly to Privacy & Security → Microphone, with Hammerspoon listed.
8. Re-grant Microphone to Hammerspoon (toggle the switch on, OR click + → select Hammerspoon).
9. Press the hotkey again — voice-cc should now work normally.

## Optional: dedup test

10. After step 4 fires the notification, immediately press the hotkey 3 more times in quick succession (within 60 s). **Expected:** NO additional notifications (dedup cooldown). After 60 s, a new press triggers a new notification.

## Failure modes

- No notification appears → check exit-code dispatcher in voice-cc-lua/init.lua for the exit 10 case; verify bash glue is exiting 10 (not 12) by capturing the actual sox stderr first time you reset (see also Plan 02-01 stderr-capture task).
- "Open Settings" link goes to wrong pane → URL is wrong; try the legacy `x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone` (Sequoia accepts both; see 02-RESEARCH.md §4).
- Spam: every press fires a new notification → notifyOnce cooldown not implemented. Check Plan 02-03's `notifyOnce` table-keyed-by-exit-code dedup.

## Sign-off

- [ ] Notification appears within ~2s of denied press
- [ ] Title and body match expected text
- [ ] Click → System Settings → Privacy → Microphone (Hammerspoon visible)
- [ ] Re-grant restores normal operation
- [ ] No spam (60s cooldown)

**Tester:** _____________  **Date:** _____________
