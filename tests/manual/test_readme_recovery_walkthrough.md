# Manual walkthrough: README recovery procedures (DST-03)

**Status:** unsigned
**Created:** 2026-05-01 (Plan 03-00)
**Sign-off path:** Plan 03-02 (autonomous: false; checkpoint after README rewrite + uninstall.sh land)
**Phase:** 3 — Distribution & Public Install
**Requirement:** DST-03 (README documents permission grants + Dictation disable + tccutil reset recovery + 4-item recovery section per CONTEXT D-12)

## Why this is manual

The README's "Recovery" section claims 4 procedures work: TCC reset, Karabiner rule troubleshoot, "I lost my hotkeys" 5-step decision tree, uninstall.sh. None can be unit-tested — they require real TCC state, real Karabiner UI interaction, real Hammerspoon reload, and a real (sandboxable) uninstall run. Oliver follows each verbatim and signs off.

## Prerequisites

- [ ] Plan 03-02 complete (README.md rewritten per D-11/D-12; uninstall.sh exists at repo root; LICENSE committed)
- [ ] `bash tests/run_all.sh` reports ≥13 PASS / 0 FAIL on this branch
- [ ] Hammerspoon currently running with `require("purplevoice")` loaded; F19 push-to-talk works (sanity check)

## Steps

### Recovery item 1 — TCC reset (DST-03 verbatim)
1. Open the README, find "## Recovery" → "TCC reset" block.
2. Run the documented commands literally:
   ```bash
   tccutil reset Microphone org.hammerspoon.Hammerspoon
   tccutil reset Accessibility org.hammerspoon.Hammerspoon
   osascript -e 'tell application "Hammerspoon" to quit'
   open -a Hammerspoon
   ```
3. **PASS criterion:** Hammerspoon prompts for Microphone + Accessibility on next press; granting them restores F19 push-to-talk.

### Recovery item 2 — Karabiner rule troubleshoot
4. Find "## Recovery" → "Karabiner rule troubleshoot" block.
5. Open Karabiner-Elements → Event Viewer; hold `fn`; verify F19 events flow as the README says.
6. **PASS criterion:** README accurately describes the Event Viewer location + the UK (`non_us_backslash`) vs ANSI/US (`grave_accent_and_tilde`) gotcha for the backtick rule.

### Recovery item 3 — "I lost my hotkeys" 5-step decision tree
7. Find "## Recovery" → "I lost my hotkeys" block.
8. Walk all 5 steps verbatim (Reload Hammerspoon → Karabiner menubar icon present → both rules enabled → Event Viewer key codes → Hammerspoon console binding-failed alerts).
9. **PASS criterion:** Each step has a clear "do this" + "if it fails, do that" (not aspirational; actual diagnostic actions).

### Recovery item 4 — uninstall.sh
10. Snapshot pre-state: `ls ~/.config/purplevoice ~/.cache/purplevoice ~/.local/share/purplevoice ~/.local/bin/purplevoice-record ~/.hammerspoon/purplevoice`.
11. **DESTRUCTIVE — only run if you're prepared to re-install afterwards.** `bash uninstall.sh`.
12. **PASS criterion:** All 5 surfaces removed; manual-cleanup banner printed; exit 0.
13. Re-install: `bash install.sh` — verify state restored.

## Sign-off

```
DST-03 README recovery walkthrough — signed off YYYY-MM-DD by Oliver
- TCC reset (item 1): PASS
- Karabiner troubleshoot (item 2): PASS
- "I lost my hotkeys" 5-step (item 3): PASS
- uninstall.sh + reinstall (item 4): PASS [or DEFERRED if destructive run skipped per Phase 4 CHECKPOINT-3 precedent — record reason]
```

## Failure modes

- TCC reset commands wrong syntax → README error; fix the README block + re-walk.
- Karabiner Event Viewer location moved → Karabiner version drift; update the README screenshot/path; re-walk.
- "I lost my hotkeys" step ambiguous → reword for unambiguous decision; re-walk.
- uninstall.sh leaves debris → either fix uninstall.sh OR document the residual files in the README.
