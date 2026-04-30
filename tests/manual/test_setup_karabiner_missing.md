# Manual Test: setup.sh Step 9 actionable error when Karabiner-Elements missing (QOL-NEW-01)

**Requirement:** QOL-NEW-01 — setup.sh Step 9 refuses to declare install complete when /Applications/Karabiner-Elements.app is absent. Prints actionable instructions (download URL, JSON rule path, 5-step install procedure, air-gap fallback per D-08) and exits non-zero.

**Prerequisites:**

1. Plan 04-02 complete: `setup.sh` contains Step 9 (Karabiner-Elements check) BEFORE the final banner; `assets/karabiner-fn-to-f19.json` exists.
2. Karabiner-Elements currently installed at `/Applications/Karabiner-Elements.app` (we will temporarily move it aside).
3. **WARNING:** This walkthrough requires `sudo` to move a system .app aside. Restoring at the end is mandatory; do NOT skip the restore step or your machine loses the F19 hotkey.
4. Familiarity with macOS Recovery Mode is recommended in case of unexpected issues — though `sudo mv` to/from `/Applications/` is reversible without recovery.

## Steps

1. Verify baseline: `bash setup.sh` runs to completion (exit 0); the final banner mentions `setup complete`. **BASELINE-OK.**
2. Move Karabiner-Elements.app aside: `sudo mv /Applications/Karabiner-Elements.app /tmp/Karabiner-Elements.app.parked`
3. Verify the move: `ls -la /Applications/Karabiner-Elements.app` should report "No such file or directory"; `ls -la /tmp/Karabiner-Elements.app.parked` should show the bundle directory.
4. Run setup: `bash setup.sh; echo "EXIT=$?"`
5. Expected: setup.sh runs prior steps to completion, then at Step 9 prints a multi-line actionable error to stderr containing:
   - `PurpleVoice: Karabiner-Elements is required for the F19 hotkey.`
   - URL `https://karabiner-elements.pqrs.org/`
   - 5-step numbered install procedure (Download / Drag to /Applications / Launch + grant / Import JSON / Re-run setup.sh)
   - Reference to `assets/karabiner-fn-to-f19.json` (the bundled JSON rule path)
   - Air-gap note: `If air-gapped: copy Karabiner-Elements.dmg from a connected machine via USB`
   - Exit code: `EXIT=1`
   **PASS-1:** actionable error printed; exit code is non-zero.
6. Restore Karabiner: `sudo mv /tmp/Karabiner-Elements.app.parked /Applications/Karabiner-Elements.app`
7. Verify restore: `ls -la /Applications/Karabiner-Elements.app` shows the bundle directory; Karabiner-Elements menubar icon returns (may need to launch the .app once if the daemon was killed during the move).
8. Re-run setup: `bash setup.sh; echo "EXIT=$?"`
9. Expected: setup.sh runs to completion (exit 0); Step 9 prints `OK: Karabiner-Elements detected at /Applications/Karabiner-Elements.app` followed by the import-rule REMINDER. **PASS-2:** restore returns to baseline OK.

## Expected Outcome

- Step 5: actionable error with all required content; EXIT=1.
- Step 9: baseline restored; EXIT=0.

## Failure modes

- Step 5 EXIT=0 (setup.sh did not refuse) → Step 9 was added without `exit 1`. Re-check `setup.sh` Step 9 — verify the `if [ ! -d /Applications/Karabiner-Elements.app ]; then ... exit 1; fi` block.
- Step 5 prints terse one-line error → Step 9 was added but the actionable instructions are missing or truncated. Re-check the heredoc content matches RESEARCH.md §5 verbatim.
- Step 5 the prior banner `setup complete` printed BEFORE the Karabiner check fired → Step ordering is wrong. The Karabiner check must run AFTER all dep checks but BEFORE the final banner. Per RESEARCH.md §5 (Option A): banner is the LAST step; Karabiner check is Step 9 inserted between Step 8 SBOM regen and the banner. Re-order setup.sh.
- Step 7 Karabiner menubar icon does not return → Karabiner daemon needs a re-launch. Open `/Applications/Karabiner-Elements.app` from Finder; the daemon will spawn the menubar icon. If that fails, log out and back in.
- Cannot restore (sudo password forgotten / `/tmp/` cleared) → re-download Karabiner-Elements.dmg from https://karabiner-elements.pqrs.org/ and reinstall fresh.

## Sign-off

- [ ] BASELINE-OK (initial `bash setup.sh` run exits 0)
- [ ] PASS-1 (Karabiner-parked run prints actionable error; EXIT=1)
- [ ] PASS-2 (Karabiner-restored run exits 0; baseline returned)

**Tester:** _____________  **Date:** _____________
