# Manual Test: Transient UTI marker honoured by clipboard managers (INJ-03)

**Requirement:** INJ-03 — Clipboard set is marked with `org.nspasteboard.TransientType` UTI so clipboard-history managers (1Password, Raycast, Maccy, Alfred) do not retain transcripts permanently.

**Prerequisites:**
- Phase 2 PurpleVoice loop deployed (Plan 02-02 complete)
- **Maccy installed** (`brew install --cask maccy`) — primary verification target because Maccy explicitly honours the spec by default
- Hammerspoon running, PurpleVoice module loaded

## Steps

1. Open Maccy (cmd+shift+c default hotkey). Note the current top entry.
2. Open a text editor. Click into an empty document.
3. Hold cmd+shift+e, say "first test phrase". Release. Wait for paste.
4. Hold cmd+shift+e, say "second test phrase". Release. Wait for paste.
5. Hold cmd+shift+e, say "third test phrase". Release. Wait for paste.
6. Hold cmd+shift+e, say "fourth test phrase". Release. Wait for paste.
7. Hold cmd+shift+e, say "fifth test phrase". Release. Wait for paste.
8. Open Maccy. Inspect the history.

## Expected Outcome

- **ZERO of the 5 phrases appear in Maccy history.** The top entry should be the same as it was before step 1 (or any user-initiated cmd+c that happened in between).

## Optional: 1Password / Raycast / Alfred

- 1Password 8 "Recently copied" view: also expected ZERO transcripts.
- Raycast Clipboard History: **may** show transcripts (Raycast support for nspasteboard.org spec is unverified per 02-RESEARCH.md §5). This is a known residual risk; not a Phase 2 failure.
- Alfred Clipboard History: also expected ZERO transcripts (per nspasteboard.org honour-list).

## Failure modes

- Maccy shows any of the 5 phrases → `hs.pasteboard.writeAllData` is not setting the transient UTI correctly. Check purplevoice-lua/init.lua for `["org.nspasteboard.TransientType"] = ""` in the data table passed to `writeAllData`.
- Some appear, some don't → race between transient marker and Maccy's poll cycle; verify the transcript + marker are written ATOMICALLY in a single `writeAllData` call, not via sequential `setContents` then `writeDataForUTI`.

## Sign-off

- [ ] Maccy shows ZERO of 5 transcripts
- [ ] (Optional) 1Password "Recently copied" shows ZERO transcripts
- [ ] (Optional) Alfred Clipboard History shows ZERO transcripts

**Tester:** _____________  **Date:** _____________
