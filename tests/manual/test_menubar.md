# Manual Test: Menubar indicator state change (FBK-01)

**Requirement:** FBK-01 — Menu-bar indicator changes colour while recording is active (visual confirmation that hotkey registered).

**Prerequisites:** Phase 2 PurpleVoice loop deployed (Plan 02-02 complete).

## Steps

1. Look at the macOS menubar (top-right). The PurpleVoice indicator (`●`) should be visible in **grey** (#888888).
2. Press and HOLD cmd+shift+e. The `●` should turn **red** (#FF3B30) within ~50 ms.
3. While still holding, observe the dot stays red.
4. Release the hotkey. The `●` should return to **grey** within ~500 ms (after the bash glue exits and the Lua callback fires).
5. Repeat 3–4 times to confirm reliable state change.

## Expected Outcome

- Idle: grey dot (`●`).
- Holding hotkey: red dot (`●`).
- Release: returns to grey within ~500 ms.

## Failure modes

- No dot visible at all → menubar item failed to create. Check `hs.menubar.new()` returned non-nil, and `setTitle()` is being called with a styled-text dot.
- Dot stuck on red after release → state not reset. Check `setMenubarIdle()` in the resetState() / pcall finally block — must fire on EVERY exit path (success, denylist, TCC denial, SIGINT).
- Dot doesn't change colour → check `hs.styledtext.new("●", { color = ... })` syntax; verify the colour table uses `red`/`green`/`blue` 0..1 floats, not 0..255 ints.

## Sign-off

- [ ] Idle = grey
- [ ] Holding = red (within 50 ms of press)
- [ ] Release = grey (within 500 ms)

**Tester:** _____________  **Date:** _____________
