# Manual Test: Clipboard preserve/restore (INJ-02)

**Requirement:** INJ-02 — User's existing clipboard contents are preserved and restored after paste, with ≥250ms delay.

**Prerequisites:**
- Phase 2 voice-cc loop deployed (Plans 02-01 and 02-02 complete)
- Hammerspoon running, voice-cc module loaded
- Microphone + Accessibility granted to Hammerspoon

## Steps

1. Open a text editor (TextEdit, VS Code, anything). Click into an empty document.
2. In the URL bar of any browser (or another text field), type the literal string `ORIGINAL` and press cmd+a, cmd+c. The macOS clipboard now contains `ORIGINAL`.
3. Click back into the empty document from step 1.
4. Hold cmd+shift+e and say "test transcript please" (or any short phrase). Release.
5. Within ~2 seconds, "test transcript please" (or your phrase) appears in the document. **PASS-1:** transcript appeared.
6. **Wait ~500 ms** (one Mississippi). Now move to a SECOND text field (a different document or text input). Press cmd+v.
7. Expected: `ORIGINAL` pastes (NOT "test transcript please"). **PASS-2:** prior clipboard restored.

## Expected Outcome

- Step 5: voice transcript appears in the focused field.
- Step 7: `ORIGINAL` pastes from the restored prior clipboard.

## Failure modes

- Step 7 pastes the voice transcript again → restore failed. Check `hs.timer.doAfter(0.25, ...)` in voice-cc-lua/init.lua, and verify the prior clipboard was captured via `hs.pasteboard.readAllData()` *before* the transcript was written.
- Step 5 fails entirely → that's a different bug (paste path broken); rerun other walkthroughs first.
- Step 7 pastes empty / whitespace → prior clipboard was non-text (image, file ref) and the restore path didn't preserve all UTIs. Use `writeAllData` (multi-UTI) for restore, not `setContents` (text-only).

## Sign-off

- [ ] PASS-1 (transcript appeared in step 5)
- [ ] PASS-2 (`ORIGINAL` restored on cmd+v in second field)

**Tester:** _____________  **Date:** _____________
