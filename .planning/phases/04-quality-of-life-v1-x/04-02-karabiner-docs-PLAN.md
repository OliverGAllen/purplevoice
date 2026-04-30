---
phase: 04-quality-of-life-v1-x
plan: 02
type: execute
wave: 2
depends_on:
  - "04-01"
files_modified:
  - assets/karabiner-fn-to-f19.json
  - setup.sh
  - README.md
  - SECURITY.md
  - .planning/REQUIREMENTS.md
  - .planning/ROADMAP.md
  - tests/manual/test_accessibility_prompt.md
  - tests/manual/test_audio_cues.md
  - tests/manual/test_clipboard_restore.md
  - tests/manual/test_hud_appearance.md
  - tests/manual/test_hud_disable.md
  - tests/manual/test_hud_focus.md
  - tests/manual/test_hud_idle_cpu.md
  - tests/manual/test_hud_screen_capture.md
  - tests/manual/test_menubar.md
  - tests/manual/test_reentrancy.md
  - tests/manual/test_tcc_notification.md
  - tests/manual/test_transient_marker.md
autonomous: false
requirements:
  - QOL-01
  - QOL-NEW-01

must_haves:
  truths:
    - "assets/karabiner-fn-to-f19.json exists and is valid JSON with from.key_code='fn', to_if_held_down[0].key_code='f19', to_if_alone present (key_code='fn', halt=true), to_if_alone_timeout_milliseconds=200, to_if_held_down_threshold_milliseconds=200, top-level title='PurpleVoice — fn → F19'"
    - "setup.sh Step 9 detects /Applications/Karabiner-Elements.app, prints actionable error + exits non-zero when absent, prints OK + REMINDER + continues when present"
    - "setup.sh Step 9 includes the air-gap install path in the actionable error message (per D-08); the surrounding setup.sh script honours PURPLEVOICE_OFFLINE=1 globally as it has since Phase 2.7"
    - "setup.sh Step 9 placed AFTER Step 8 (Syft SBOM regen) and BEFORE the final banner — Option A reorganisation per RESEARCH §5 (existing 'Step 7' banner is renumbered/moved to be the LAST step)"
    - "Zero cmd+shift+e references remain in tests/manual/ (replaced with F19 or 'hold fn'), README.md, SECURITY.md, or setup.sh banner"
    - "README.md adds Karabiner-Elements as a required dependency in install flow with download URL https://karabiner-elements.pqrs.org/ + JSON-rule import instructions referencing assets/karabiner-fn-to-f19.json + Karabiner UI navigation (Preferences → Complex Modifications → Add rule → Import) + Cmd+K V VS Code Markdown Preview workaround note"
    - "README.md Hotkey section updated from cmd+shift+e to F19 (with brief note that fn-hold via Karabiner emits F19); cmd+shift+v re-paste binding documented"
    - "SECURITY.md SBOM scope disclaimer prepends 'Karabiner-Elements (kernel-extension-class daemon for the fn→F19 hotkey remap; user-installed)' to the carried-by-reference runtime-deps list alongside Hammerspoon"
    - "SECURITY.md TL;DR + Scope sections updated: cmd+shift+e references replaced with F19 (or 'hold fn (Karabiner-remapped to F19)')"
    - "REQUIREMENTS.md QOL-01 and QOL-NEW-01 rows flip from '[ ] Pending' to '[x] Complete' (both in the v1 'Quality of Life' subsection AND in the Traceability table); v1 coverage stat stays at 41 (Plan 04-00 already bumped it from 39 to 41)"
    - "ROADMAP.md Phase 4 row updated from 'Queued' / '0/0' to 'Complete' / '3/3' with the three plan filenames listed under the phase entry"
    - "tests/test_karabiner_check.sh reports 8/8 GREEN (Plan 04-01 already turned 6/7/8 GREEN; this plan turns 1-5 GREEN)"
    - "bash tests/run_all.sh reports 11/11 GREEN; bash tests/security/run_all.sh reports 5/5 GREEN"
    - "Pattern 2 invariant intact: grep -c WHISPER_BIN purplevoice-record == 2"
    - "Pattern 2 corollary intact: ! grep -q whisper-cli purplevoice-lua/init.lua"
    - "Brand consistency lint GREEN (no new voice-cc strings introduced; SECURITY.md is NOT on the test exemption list, so the brand check enforces voice-cc absence there); framing lint GREEN (SECURITY.md additions use neutral 'runtime dependency' language — no compliant/certified/guarantees without qualifier)"
    - "All 3 manual walkthroughs signed off live by Oliver (test_f19_walkthrough.md, test_repaste_walkthrough.md, test_setup_karabiner_missing.md) with PASS markers checked + Tester + Date filled in"
  artifacts:
    - path: "assets/karabiner-fn-to-f19.json"
      provides: "Karabiner-Elements complex-modification rule for fn → F19 (tap=fn passthrough with halt:true; hold=F19 emit at 200ms threshold) — verbatim from RESEARCH §4"
      contains: "to_if_held_down"
    - path: "setup.sh"
      provides: "Step 9 (Karabiner-Elements detection) inserted between Step 8 (SBOM regen) and the final banner; banner moved to be LAST step per Option A; Step 7 banner text updated cmd+shift+e → F19"
      contains: "setup_step_9_karabiner_check"
    - path: "README.md"
      provides: "Karabiner-Elements install instructions + JSON rule import + F19 push-to-talk usage + cmd+shift+v re-paste documentation + Cmd+K V VS Code workaround"
      contains: "karabiner-fn-to-f19.json"
    - path: "SECURITY.md"
      provides: "SBOM scope disclaimer updated for Karabiner-Elements as carried-by-reference runtime dep alongside Hammerspoon; cmd+shift+e references replaced with F19 in TL;DR + Scope"
      contains: "Karabiner-Elements"
    - path: ".planning/REQUIREMENTS.md"
      provides: "QOL-01 + QOL-NEW-01 marked [x] Complete (in v1 QOL subsection AND Traceability table)"
      contains: "QOL-NEW-01"
    - path: ".planning/ROADMAP.md"
      provides: "Phase 4 row marked Complete with 3/3 plans + plan list populated"
      contains: "04-02-PLAN.md"
    - path: "tests/manual/test_*.md"
      provides: "12 legacy walkthroughs (test_accessibility_prompt, test_audio_cues, test_clipboard_restore, test_hud_appearance, test_hud_disable, test_hud_focus, test_hud_idle_cpu, test_hud_screen_capture, test_menubar, test_reentrancy, test_tcc_notification, test_transient_marker) updated cmd+shift+e → F19/'hold fn'"
  key_links:
    - from: "setup.sh Step 9 actionable error heredoc"
      to: "assets/karabiner-fn-to-f19.json"
      via: "$KARABINER_JSON variable expansion in the printed error message"
      pattern: "assets/karabiner-fn-to-f19.json"
    - from: "README.md Setup section"
      to: "assets/karabiner-fn-to-f19.json"
      via: "Karabiner install instructions reference the JSON rule file path for UI Import"
      pattern: "karabiner-fn-to-f19.json"
    - from: "tests/test_karabiner_check.sh checks 1-3"
      to: "assets/karabiner-fn-to-f19.json"
      via: "jq-validate the JSON file (parse + structure + key codes)"
      pattern: "jq -r '.rules\\[0\\].manipulators\\[0\\].from.key_code'"
    - from: "tests/test_karabiner_check.sh checks 4-5"
      to: "setup.sh"
      via: "grep for /Applications/Karabiner-Elements.app + assets/karabiner-fn-to-f19.json string presence"
      pattern: "/Applications/Karabiner-Elements.app"
    - from: "SECURITY.md SBOM Scope disclaimer"
      to: "Karabiner-Elements"
      via: "Prepended to the existing 'carried by reference' parenthetical alongside Hammerspoon's bundled Lua + LuaSocket"
      pattern: "Karabiner-Elements \\(kernel-extension-class daemon"
---

<objective>
Land the final Phase 4 surface area: the Karabiner JSON rule file, setup.sh Step 9 (Karabiner-Elements presence check), the docs closure (README + SECURITY.md + REQUIREMENTS.md + ROADMAP.md), the legacy manual-walkthrough cmd+shift+e → F19 sweep, and the three live walkthrough sign-offs that gate the phase.

**Purpose:** Plan 04-01 turned 3 of the 8 `tests/test_karabiner_check.sh` checks GREEN (checks 6, 7, 8 — F19 binding present, cmd+shift+v binding present, cmd+shift+e binding absent in init.lua). Plan 04-02 turns the remaining 5 checks GREEN (checks 1-3 by creating the JSON rule file; checks 4-5 by adding setup.sh Step 9). Then it closes the phase: README + SECURITY.md updated to reflect the F19 hotkey + Karabiner dependency; legacy manual walkthroughs swept; REQUIREMENTS.md QOL-01 + QOL-NEW-01 flipped to Complete; ROADMAP.md Phase 4 row marked Complete; three live walkthroughs (`test_f19_walkthrough.md`, `test_repaste_walkthrough.md`, `test_setup_karabiner_missing.md`) signed off by Oliver on his actual hardware.

**Output:**
- 1 NEW file: `assets/karabiner-fn-to-f19.json` (verbatim RESEARCH §4 JSON content; passes `jq empty` + structural assertions in `tests/test_karabiner_check.sh`)
- `setup.sh` updated: Step 9 inserted (verbatim RESEARCH §5 bash content); banner reorganised per Option A (banner moves to be the LAST step; Karabiner check between Step 8 SBOM regen and the banner); banner text "Hotkey: cmd+shift+e (push-and-hold)." updated to F19
- `README.md` updated: Hotkey section + Setup section + new Karabiner subsection; Cmd+K V workaround note
- `SECURITY.md` updated: SBOM scope disclaimer prepended Karabiner-Elements; TL;DR + Scope cmd+shift+e references replaced
- 12 legacy `tests/manual/test_*.md` files swept (cmd+shift+e → F19 / "hold fn")
- `.planning/REQUIREMENTS.md` QOL-01 + QOL-NEW-01 → `[x]` Complete (both subsection rows + both traceability rows)
- `.planning/ROADMAP.md` Phase 4 row → `Complete` / `3/3 plans`; plan list populated
- 3 live walkthrough sign-offs captured

**autonomous: false** — Three `checkpoint:human-verify` tasks (one per walkthrough) require Oliver's live testing on macOS Sequoia with Karabiner-Elements installed + driver granted. The 7 file-edit tasks before them are autonomous.

**Phase-gate verification (Task 04-02-VERIFY):** All suites GREEN (functional 11/11, security 5/5); Pattern 2 invariants intact; brand + framing lints GREEN; all 3 walkthroughs signed off.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/REQUIREMENTS.md
@.planning/phases/04-quality-of-life-v1-x/04-CONTEXT.md
@.planning/phases/04-quality-of-life-v1-x/04-RESEARCH.md
@.planning/phases/04-quality-of-life-v1-x/04-VALIDATION.md
@.planning/phases/04-quality-of-life-v1-x/04-00-SUMMARY.md
@.planning/phases/04-quality-of-life-v1-x/04-01-SUMMARY.md

# Files this plan modifies — read in FULL before editing
@setup.sh
@README.md
@SECURITY.md

# Wave 0 contracts this plan satisfies (5 of 8 checks turn GREEN)
@tests/test_karabiner_check.sh

# Manual walkthrough scaffolds (created by Plan 04-00) — sign-off targets
@tests/manual/test_f19_walkthrough.md
@tests/manual/test_repaste_walkthrough.md
@tests/manual/test_setup_karabiner_missing.md

# Lints this plan must keep GREEN
@tests/test_brand_consistency.sh
@tests/test_security_md_framing.sh

<interfaces>
<!-- Existing setup.sh structure (line numbers verified 2026-04-30 against the live file) -->

setup.sh top-to-bottom step inventory (current state, BEFORE this plan):
  Lines 22-27   — Step 1: Apple Silicon Homebrew sanity check
  Lines 29-107  — Step 2: Homebrew dependencies (Hammerspoon + sox + whisper-cpp + Syft); each in PURPLEVOICE_OFFLINE-aware branches
  Lines 109-118 — Step 3: Verify binaries at expected absolute paths
  Lines 120-163 — Step 3b: One-time migration from voice-cc → purplevoice (idempotent)
  Lines 165-178 — Step 4: Create XDG directory tree
  Lines 180-230 — Step 5: Download Whisper model (resumable + SHA256)
  Lines 232-265 — Step 5b: Download Silero VAD weights
  Lines 267-281 — Step 6: Seed vocab.txt.default → ~/.config/purplevoice/vocab.txt (no-clobber)
  Lines 283-296 — Step 6b: Install denylist.txt (project-owned, always-overwrite)
  Lines 298-310 — Step 6c: Install symlinks (purplevoice-record + purplevoice-lua)
  Lines 312-334 — Step 7 (BANNER): "PurpleVoice setup complete." heredoc — INCLUDES the legacy line "Hotkey: cmd+shift+e (push-and-hold)." which Plan 04-02 must update to F19
  Lines 336-417 — Step 8: Regenerate SBOM if Syft is present (D-12, idempotent post-process via inject_system_context + deterministicise_sbom)

Phase 4 INSERT POINT (per RESEARCH §5 Option A — banner moves to be the LAST step):
  - Lines 312-334 (Step 7 BANNER) get MOVED to AFTER Step 8 SBOM regen
  - NEW Step 9 (Karabiner check) inserted BETWEEN Step 8 SBOM regen and the relocated banner
  - Final order: 1, 2, 3, 3b, 4, 5, 5b, 6, 6b, 6c, 8 (SBOM regen), 9 (Karabiner check), 7 (banner — kept at "Step 7" name OR renamed to "Step 10"; planner discretion — recommendation: rename to Step 10 for top-to-bottom clarity)

Key REPO_ROOT variable: defined at line 304 inside Step 6c. Step 9's `KARABINER_JSON="$REPO_ROOT/assets/karabiner-fn-to-f19.json"` reference relies on REPO_ROOT being in scope — it IS, since bash variables persist for the rest of the script after definition.

PURPLEVOICE_OFFLINE handling: setup.sh existing pattern (Step 2 lines 32-95) wraps each dep in an `if [ "${PURPLEVOICE_OFFLINE:-0}" = "1" ]` branch. Per CONTEXT.md D-08, Step 9's Karabiner check does NOT need OFFLINE branching — Karabiner detection is a local-only check (no network), so the SAME logic runs in both modes. The actionable error message INCLUDES the air-gap-install instruction (USB sneakernet of Karabiner-Elements.dmg) so OFFLINE users get the right next step from the same single error path.

<!-- README.md current Hotkey + Setup sections (line numbers verified 2026-04-30) -->

README.md line 32-36 — Current Hotkey section (Phase 1 / D-01 — Phase 4 D-05 REPLACES):
```
## Hotkey

`cmd+shift+e` (push-and-hold). Locked decision; see `.planning/phases/01-spike/01-CONTEXT.md` D-01.

(Known minor conflict: VS Code / Cursor "Show Explorer" sidebar — accepted.)
```

README.md line 38-46 — Current Setup section (Plan 04-02 inserts Karabiner subsection after this OR within it):
```
## Setup

```bash
bash setup.sh
```

`setup.sh` is idempotent — safe to re-run. It installs Homebrew dependencies (Hammerspoon, sox, whisper-cpp), creates the XDG directory layout (...), downloads the Whisper `small.en` model with SHA256 verification, downloads the Silero VAD weights, seeds a default vocabulary file, and seeds the hallucination-denylist...

After running `setup.sh`, paste the printed `require("purplevoice")` line into your `~/.hammerspoon/init.lua` and reload Hammerspoon.
```

<!-- SECURITY.md cmd+shift+e occurrences (verified via grep -n) -->

Two cmd+shift+e occurrences in SECURITY.md (both must be updated):
  Line 19: `**What PurpleVoice does:** You hold ` + cmd+shift+e + `, you speak, you release. ...`
  Line 51: `1. User holds ` + cmd+shift+e + `. Hammerspoon's hs.hotkey callback ...`

Both should become F19 (with a brief inline note about Karabiner remapping fn → F19).

<!-- SECURITY.md SBOM scope disclaimer target paragraph (line 223) -->

The carried-by-reference parenthetical sentence in §"Scope disclaimer: repo-only Syft scan" reads:
  "The transitive dependencies named above (sox audio libs, whisper.cpp / ggml internals, Hammerspoon's bundled Lua + LuaSocket) are **carried by reference**, not enumerated as separate `package` entries..."

Phase 4 prepends "Karabiner-Elements (kernel-extension-class daemon for the fn→F19 hotkey remap; user-installed)" to the parenthetical list — final form:
  "The transitive dependencies named above (Karabiner-Elements (kernel-extension-class daemon for the fn→F19 hotkey remap; user-installed), sox audio libs, whisper.cpp / ggml internals, Hammerspoon's bundled Lua + LuaSocket) are **carried by reference**, not enumerated as separate `package` entries..."

<!-- REQUIREMENTS.md current state (after Plan 04-00) -->

Plan 04-00 already:
  - Promoted QOL-01 from v2 stub to v1 with concrete language; both rows `[ ] Pending`
  - Added QOL-NEW-01 row in new v1 subsection `### Quality of Life`; `[ ] Pending`
  - Updated Traceability table with `| QOL-01 | Phase 4 (v1.x): Quality of Life | Pending |` AND `| QOL-NEW-01 | Phase 4 (v1.x): Quality of Life | Pending |`
  - Bumped v1 coverage stat: `v1 requirements: 41 total` (was 39)
  - Added per-phase row: `Phase 4 (v1.x): Quality of Life — 2 requirements (QOL-01, QOL-NEW-01) — Pending`
  - Rebranded QOL-03/04/05 v2 stubs to use purplevoice paths/vars

Plan 04-02 must:
  - Flip QOL-01 row in v1 subsection from `- [ ] **QOL-01**` to `- [x] **QOL-01**`
  - Flip QOL-NEW-01 row in v1 subsection from `- [ ] **QOL-NEW-01**` to `- [x] **QOL-NEW-01**`
  - Flip Traceability table cells: `| QOL-01 | Phase 4 (v1.x): Quality of Life | Pending |` → `| QOL-01 | Phase 4 (v1.x): Quality of Life | Complete |`
  - Flip Traceability cells for QOL-NEW-01 the same way
  - Update per-phase counts row: `Phase 4 (v1.x): Quality of Life — 2 requirements (QOL-01, QOL-NEW-01) — Pending` → `Phase 4 (v1.x): Quality of Life — 2 requirements (QOL-01, QOL-NEW-01) — Complete`
  - Coverage stats lines (170, 171, 173) need NO further change — Plan 04-00 already set them correctly (41 / 41 / 100% / 6 v2)

<!-- ROADMAP.md current state -->

ROADMAP.md Phase 4 row (line 199): `| 6 | Phase 4 (v1.x): Quality of Life | 0/0 | Queued | - |`

Plan 04-02 must:
  - Flip to `| 6 | Phase 4 (v1.x): Quality of Life | 3/3 | Complete | 2026-04-30 |` (or whatever Oliver's actual sign-off date is — use today's date when the plan executes)
  - Flip the Phase 4 entry under "## Phases" (line 20): `- [ ] **Phase 4 (v1.x): Quality of Life**` → `- [x] **Phase 4 (v1.x): Quality of Life**`
  - Update the "## Phase Details" Phase 4 block (lines 130-142): change `**Plans**: 4 plans` to `**Plans:** 3 plans` and add the populated plan list:
    ```
    Plans:
    - [x] 04-00-staging-PLAN.md — Wave 0: test_karabiner_check.sh + 3 manual walkthrough scaffolds + REQUIREMENTS.md QOL-01/QOL-NEW-01 stubs
    - [x] 04-01-lua-core-PLAN.md — Wave 1: F19 binding + cmd+shift+v re-paste + lastTranscript caching in init.lua (turns checks 6/7/8 GREEN)
    - [x] 04-02-karabiner-docs-PLAN.md — Wave 2: assets/karabiner-fn-to-f19.json + setup.sh Step 9 + README + SECURITY.md + manual walkthroughs sweep + REQUIREMENTS.md/ROADMAP.md closure (turns checks 1-5 GREEN)
    ```
  - Update Coverage Summary "Phase 4" row if present in the per-phase v1 requirements table — verify by reading lines 213-220
</interfaces>

<reference_data>
<!-- Verbatim content. Use EXACTLY — do NOT paraphrase. -->

## §A — assets/karabiner-fn-to-f19.json (Task 04-02-01) — VERBATIM

Copy this content EXACTLY. The JSON is the canonical RESEARCH §4 content (lines 549-581). Do NOT paraphrase, do NOT reformat, do NOT add or remove fields. Indentation: 2 spaces (standard JSON).

```json
{
  "title": "PurpleVoice — fn → F19",
  "rules": [
    {
      "description": "Hold fn → F19 (PurpleVoice push-to-talk). Quick tap → native macOS fn behaviour (Globe popup, function-key row, dictation).",
      "manipulators": [
        {
          "type": "basic",
          "from": {
            "key_code": "fn"
          },
          "to_if_alone": [
            {
              "key_code": "fn",
              "halt": true
            }
          ],
          "to_if_held_down": [
            {
              "key_code": "f19"
            }
          ],
          "parameters": {
            "basic.to_if_alone_timeout_milliseconds": 200,
            "basic.to_if_held_down_threshold_milliseconds": 200
          }
        }
      ]
    }
  ]
}
```

Critical correctness:
- Top-level `title` MUST be EXACTLY `"PurpleVoice — fn → F19"` (with the em-dash U+2014 and the right-arrow U+2192; both already in the codebase per RESEARCH).
- `from.key_code` MUST be `"fn"` (lowercase string).
- `to_if_alone[0].key_code` MUST be `"fn"` AND `halt: true` MUST be present (prevents alone+held double-firing per RESEARCH §4 schema verification).
- `to_if_held_down[0].key_code` MUST be `"f19"` (lowercase string; matches Hammerspoon's `hs.keycodes.map`).
- BOTH `basic.to_if_alone_timeout_milliseconds` AND `basic.to_if_held_down_threshold_milliseconds` MUST be `200` (RESEARCH Pitfall 1 sweet spot; symmetric values).
- Final newline at EOF (standard text-file convention).

After writing: `jq empty assets/karabiner-fn-to-f19.json` exits 0.

## §B — setup.sh Step 9 + Option A reorganisation (Task 04-02-02)

### B.1 — The Step 9 bash function/block (verbatim from RESEARCH §5)

```bash
# ---------------------------------------------------------------------------
# Step 9: Karabiner-Elements check (Phase 4 / QOL-NEW-01 / CONTEXT.md D-07)
# ---------------------------------------------------------------------------
# Karabiner-Elements is REQUIRED for the F19 hotkey (fn-key remap). PurpleVoice
# does NOT auto-install third-party kernel-driver software — minimal-deps ethos.
# We refuse to declare install complete without it, and print actionable
# instructions. PURPLEVOICE_OFFLINE=1 mode behaves identically (Karabiner is
# local-only; no network needed for the check itself).

KARABINER_JSON="$REPO_ROOT/assets/karabiner-fn-to-f19.json"
if [ ! -f "$KARABINER_JSON" ]; then
  echo "PurpleVoice: $KARABINER_JSON missing from repo (run setup.sh from a Phase-4-or-later checkout)." >&2
  exit 1
fi

if [ ! -d /Applications/Karabiner-Elements.app ]; then
  cat >&2 <<EOF

----------------------------------------------------------------------
PurpleVoice: Karabiner-Elements is required for the F19 hotkey.

Install Karabiner-Elements (free, open-source — https://karabiner-elements.pqrs.org/):
  1. Download Karabiner-Elements.dmg from https://karabiner-elements.pqrs.org/
  2. Drag Karabiner-Elements.app to /Applications/.
  3. Launch once and grant the driver/extension prompt
     (System Settings → Privacy & Security → "Allow software from Fumihiko Takayama").
  4. Open Karabiner-Elements → Preferences → Complex Modifications → Add rule →
     Import rule from file → choose:
       \$KARABINER_JSON
     Then click "Enable" next to "Hold fn → F19 (PurpleVoice push-to-talk)".
  5. Re-run: bash setup.sh

If air-gapped: copy Karabiner-Elements.dmg from a connected machine via USB
and install manually. The fn→F19 JSON rule is already in this repo at
\$KARABINER_JSON.
----------------------------------------------------------------------
EOF
  exit 1
fi

echo "OK: Karabiner-Elements detected at /Applications/Karabiner-Elements.app"
echo "    REMINDER: ensure 'Hold fn → F19 (PurpleVoice push-to-talk)' is enabled in"
echo "    Karabiner-Elements → Preferences → Complex Modifications. If not yet"
echo "    imported, see \$KARABINER_JSON"
```

CRITICAL bash escaping note: the heredoc above uses an `EOF` delimiter WITHOUT quotes, which means `$KARABINER_JSON` IS expanded inside the heredoc. The `\$KARABINER_JSON` escape sequences in the verbatim block above are SHOWN escaped only because this Markdown block is a representation — when written into setup.sh, the heredoc body MUST contain unescaped `$KARABINER_JSON` so bash expands the variable to the actual file path at runtime. If you copy-paste mechanically and end up with literal `\$` in setup.sh, the printed error message will show `$KARABINER_JSON` as literal text instead of the path — fix by removing the backslashes inside the heredoc.

### B.2 — Option A reorganisation (banner moves to LAST step)

Current setup.sh structure (lines 312-334 = Step 7 banner; lines 336-417 = Step 8 SBOM regen):

```
... Step 6c symlinks (lines 298-310) ...
... Step 7 BANNER (lines 312-334) ...
... Step 8 SBOM regen (lines 336-417) ...
[EOF]
```

REORGANISED structure (after this task):

```
... Step 6c symlinks (lines 298-310) ...
... Step 8 SBOM regen (currently 336-417, MOVES UP to immediately after Step 6c) ...
... Step 9 Karabiner check (NEW — content from §B.1 above) ...
... Step 10 BANNER (was Step 7; renamed to Step 10; content unchanged EXCEPT cmd+shift+e → F19 line — see §B.3 below) ...
[EOF]
```

Step header comment renumbering:
- Existing line 314 `# Step 7: Next-step reminders ...` → `# Step 10: Next-step reminders (banner — final step)`
- Existing line 338 `# Step 8: Regenerate SBOM if Syft is present` — UNCHANGED (still Step 8; just gets relocated UP)
- NEW Step 9 header inserted BETWEEN Step 8 SBOM regen end (current line 417) and the relocated Step 10 banner

Implementation tactic — DO NOT use sed multi-line moves (fragile). Recommended approach:
1. Read setup.sh in full.
2. Mentally segment into 4 chunks:
   - Chunk A: lines 1-310 (Steps 1 through 6c) — UNCHANGED
   - Chunk B: lines 312-334 (current Step 7 banner) — this becomes the LAST chunk; rename header `Step 7` → `Step 10`; update the cmd+shift+e line per §B.3
   - Chunk C: lines 336-417 (current Step 8 SBOM regen) — UNCHANGED content, MOVED to immediately follow Chunk A (becomes the new Chunk 2 of 4)
   - Chunk D: NEW — the verbatim §B.1 Step 9 Karabiner-check block — inserted between Chunk C and Chunk B
3. Write the final file as: Chunk A + Chunk C + Chunk D + Chunk B (renamed Step 10).

Use Read on setup.sh first, then Write the entire reorganised file. Do NOT use Edit for the move — the displacement is too large.

### B.3 — Step 7 banner cmd+shift+e → F19 update

Current setup.sh line 332 (inside the heredoc):
```
  - Hotkey: cmd+shift+e (push-and-hold).
```

REPLACE with:
```
  - Hotkey: F19 push-and-hold (Karabiner remaps fn → F19 — see Step 9 reminder above).
  - Re-paste last transcript: cmd+shift+v.
```

(Two lines now, not one — adds the cmd+shift+v re-paste reference. Both bullets nest at the same `  - ` indent as the surrounding bullets.)

This is the ONLY content change inside the relocated banner; the rest of the heredoc (lines 312-334) stays VERBATIM.

## §C — README.md updates (Task 04-02-04)

### C.1 — Hotkey section REPLACEMENT (lines 32-36)

CURRENT:
```markdown
## Hotkey

`cmd+shift+e` (push-and-hold). Locked decision; see `.planning/phases/01-spike/01-CONTEXT.md` D-01.

(Known minor conflict: VS Code / Cursor "Show Explorer" sidebar — accepted.)
```

REPLACE with:
```markdown
## Hotkey

**Primary trigger: F19 (push-and-hold).** Karabiner-Elements remaps the `fn` key — hold fn for >200 ms to start recording, release to stop. A quick tap of fn (under 200 ms) preserves macOS's native fn behaviour (Globe / emoji popup, function-key row, dictation). Locked decision per `.planning/phases/04-quality-of-life-v1-x/04-CONTEXT.md` D-05 (replaces the original `cmd+shift+e` binding to eliminate the VS Code / Cursor "Show Explorer" collision).

**Re-paste last transcript: `cmd+shift+v`.** Pastes the most recent successful transcript into the focused window. Useful when focus shifted mid-paste and the transcript landed in the wrong app. In-memory only — lost on Hammerspoon reload (privacy-first; per CONTEXT.md D-03).

> **VS Code / Cursor users:** the `cmd+shift+v` re-paste binding hijacks the IDE's default "Markdown Preview" shortcut whenever Hammerspoon is running. Workaround: use **`Cmd+K V`** for split-pane Markdown preview instead. The collision is documented and accepted per CONTEXT.md D-02.
```

### C.2 — Setup section ADDITION (insert AFTER current line 46 `After running setup.sh, paste the printed require("purplevoice")...`)

ADD a new H3 subsection AFTER the existing Setup paragraph:

```markdown
### Karabiner-Elements (required for the F19 hotkey)

PurpleVoice's F19 push-to-talk hotkey is produced by remapping the `fn` key with [Karabiner-Elements](https://karabiner-elements.pqrs.org/) (free, open-source). `setup.sh` Step 9 checks for `/Applications/Karabiner-Elements.app` and refuses to declare install complete without it.

One-time installation:

1. Download `Karabiner-Elements.dmg` from <https://karabiner-elements.pqrs.org/>.
2. Drag `Karabiner-Elements.app` to `/Applications/`.
3. Launch Karabiner-Elements once. macOS will prompt for the driver / system-extension grant — open System Settings → Privacy & Security and enable **"Allow software from Fumihiko Takayama"** (the Karabiner author). Restart Karabiner-Elements when prompted.
4. Import the `fn → F19` rule: Karabiner-Elements → **Preferences → Complex Modifications → Add rule → Import rule from file** → select `assets/karabiner-fn-to-f19.json` from this repository. Click **Enable** next to **"Hold fn → F19 (PurpleVoice push-to-talk)"**.
5. Re-run `bash setup.sh` — Step 9 should now print `OK: Karabiner-Elements detected at /Applications/Karabiner-Elements.app`.

Air-gapped users: copy `Karabiner-Elements.dmg` from a connected machine via USB sneakernet. The `fn → F19` JSON rule is already bundled in this repo at `assets/karabiner-fn-to-f19.json` — no additional download needed for the rule itself.

The recommended hold threshold is 200 ms (configured in the JSON rule via `basic.to_if_alone_timeout_milliseconds` and `basic.to_if_held_down_threshold_milliseconds`). If the threshold feels wrong on your hardware (false-positive recording on quick taps OR perceived lag on intentional holds), edit both values in the JSON file in 50 ms increments and re-import in Karabiner.
```

### C.3 — No other README sections need changes

The "Permissions" section (lines 48-53), "Recovery" section (lines 62-72), "Security & Privacy" section (lines 74+), and other sections do NOT mention cmd+shift+e directly. Confirm via `grep -n cmd+shift+e README.md` AFTER the edit — should return 0 hits.

## §D — SECURITY.md updates (Task 04-02-05)

### D.1 — TL;DR cmd+shift+e → F19 (line 19)

CURRENT line 19:
```
**What PurpleVoice does:** You hold `cmd+shift+e`, you speak, you release. The transcript appears in the focused window. Total round-trip: ~1-2 seconds. No cloud. No subscription. No telemetry.
```

REPLACE with:
```
**What PurpleVoice does:** You hold **F19** (Karabiner-Elements remaps the `fn` key — see [README.md Hotkey](README.md#hotkey)), you speak, you release. The transcript appears in the focused window. Total round-trip: ~1-2 seconds. No cloud. No subscription. No telemetry.
```

### D.2 — Scope Description (line 51)

CURRENT line 51:
```
1. User holds `cmd+shift+e`. Hammerspoon's `hs.hotkey` callback (registered by `purplevoice-lua/init.lua`) fires.
```

REPLACE with:
```
1. User holds **F19** (Karabiner-Elements remaps the `fn` key per `assets/karabiner-fn-to-f19.json` — see [SBOM Scope disclaimer](#scope-disclaimer-repo-only-syft-scan) for the runtime-dep framing). Hammerspoon's `hs.hotkey` callback (registered by `purplevoice-lua/init.lua`) fires.
```

### D.3 — SBOM scope disclaimer prepend (line 223 — the long paragraph)

The target sentence is the parenthetical inside line 223 of SECURITY.md:
```
The transitive dependencies named above (sox audio libs, whisper.cpp / ggml internals, Hammerspoon's bundled Lua + LuaSocket) are **carried by reference**, not enumerated as separate `package` entries:
```

REPLACE with:
```
The transitive dependencies named above (Karabiner-Elements (kernel-extension-class daemon for the fn→F19 hotkey remap; user-installed), sox audio libs, whisper.cpp / ggml internals, Hammerspoon's bundled Lua + LuaSocket) are **carried by reference**, not enumerated as separate `package` entries:
```

(Karabiner-Elements is prepended FIRST in the list — alphabetical order would actually put Hammerspoon and Karabiner adjacent, but RESEARCH §"Key Findings" recommends prepending for emphasis since it's a NEW addition that auditors should notice. Use this prepended order.)

### D.4 — Framing-lint check

After edits, run `bash tests/test_security_md_framing.sh; echo $?` — MUST exit 0. The new content uses neutral language ("kernel-extension-class daemon", "user-installed", "runtime dependency") with NO "compliant" / "certified" / "guarantees" without qualifier.

### D.5 — Brand-consistency check

After edits, run `bash tests/test_brand_consistency.sh; echo $?` — MUST exit 0. SECURITY.md is NOT on the brand-test exemption list (per `tests/test_brand_consistency.sh` lines 32-35 the only exempted .md files are CLAUDE.md and README.md). Phase 4 introduces ZERO new `voice-cc` strings into SECURITY.md (the additions are all `purplevoice` / `Karabiner-Elements` / `Hammerspoon`).

## §E — Manual walkthroughs sweep (Task 04-02-03)

12 files contain `cmd+shift+e` and need updating. Confirmed list (from `grep -rl 'cmd+shift+e' tests/manual/` 2026-04-30):

  1. tests/manual/test_accessibility_prompt.md (1 occurrence)
  2. tests/manual/test_audio_cues.md (2 occurrences)
  3. tests/manual/test_clipboard_restore.md (1 occurrence)
  4. tests/manual/test_hud_appearance.md (2 occurrences)
  5. tests/manual/test_hud_disable.md (2 occurrences)
  6. tests/manual/test_hud_focus.md (1 occurrence)
  7. tests/manual/test_hud_idle_cpu.md (1 occurrence)
  8. tests/manual/test_hud_screen_capture.md (4 occurrences)
  9. tests/manual/test_menubar.md (1 occurrence)
  10. tests/manual/test_reentrancy.md (3 occurrences)
  11. tests/manual/test_tcc_notification.md (1 occurrence)
  12. tests/manual/test_transient_marker.md (5 occurrences)

Total: 24 occurrences across 12 files.

NOT in the sweep list (already use F19 — created by Plan 04-00):
  - tests/manual/test_f19_walkthrough.md
  - tests/manual/test_repaste_walkthrough.md
  - tests/manual/test_setup_karabiner_missing.md

Replacement strategy:
- For walkthrough STEPS that say "Hold cmd+shift+e" or "press cmd+shift+e": replace `cmd+shift+e` with `F19` (or `fn (held)` if the surrounding narrative reads better with the human-friendly form — planner judgment, but consistency within each file).
- For introductory paragraphs: replace `cmd+shift+e` with `F19` and add a brief parenthetical the FIRST time per file: `F19 (Karabiner-remapped from fn)` so the reader has context.
- DO NOT modify any other content — these sweeps are mechanical replacements, not content updates.

After sweep: `! grep -rq 'cmd+shift+e' tests/manual/` — should report nothing.

## §F — REQUIREMENTS.md final flips (Task 04-02-06)

### F.1 — v1 QOL subsection rows (Plan 04-00 created these as `[ ]` Pending; Plan 04-02 flips to `[x]` Complete)

CURRENT (after Plan 04-00 — locate via `grep -n 'QOL-01\|QOL-NEW-01' .planning/REQUIREMENTS.md`; the v1 subsection rows are above the v2 subsection):
```markdown
- [ ] **QOL-01**: Paste-last-transcript hotkey (`cmd+shift+v`) re-pastes the most recent successful transcript into the focused window. ...
- [ ] **QOL-NEW-01**: F19 alt hotkey replaces `cmd+shift+e` for push-and-hold recording. ...
```

REPLACE both `- [ ]` markers with `- [x]`. The body text (`**QOL-01**: Paste-last-transcript ...` and `**QOL-NEW-01**: F19 alt hotkey ...`) is UNCHANGED — only the checkbox flips.

### F.2 — Traceability table cells

CURRENT (after Plan 04-00):
```
| QOL-01 | Phase 4 (v1.x): Quality of Life | Pending |
| QOL-NEW-01 | Phase 4 (v1.x): Quality of Life | Pending |
```

REPLACE both `Pending` cells with `Complete`. Final form:
```
| QOL-01 | Phase 4 (v1.x): Quality of Life | Complete |
| QOL-NEW-01 | Phase 4 (v1.x): Quality of Life | Complete |
```

### F.3 — Per-phase counts row

CURRENT (after Plan 04-00, near line 184):
```
- Phase 4 (v1.x): Quality of Life — 2 requirements (QOL-01, QOL-NEW-01) — Pending
```

REPLACE with:
```
- Phase 4 (v1.x): Quality of Life — 2 requirements (QOL-01, QOL-NEW-01) — Complete
```

### F.4 — Last updated footer

CURRENT (line 185):
```
*Last updated: 2026-04-30 — four HUD requirements completed for Phase 3.5 (Complete); traceability table extended.*
```

REPLACE (or APPEND a new line below) with the Phase 4 closure note:
```
*Last updated: 2026-04-30 — Phase 4 Quality of Life closed: QOL-01 (cmd+shift+v re-paste) + QOL-NEW-01 (F19 alt hotkey via Karabiner) marked Complete; v1 coverage stays at 41/41 (100%); 12 manual walkthroughs swept cmd+shift+e → F19; SECURITY.md SBOM scope updated to enumerate Karabiner-Elements as carried-by-reference runtime dep alongside Hammerspoon.*
```

(Use today's actual date when the plan executes — `date +%Y-%m-%d`.)

### F.5 — DO NOT touch

Coverage stats (`v1 requirements: 41 total` / `Mapped to phases: 41 / 41 (100%)` / `v2 requirements: 6 total`) are CORRECT after Plan 04-00 and need NO further change in 04-02. The 41 stays 41; Phase 4 doesn't add to v1 count, it just flips Pending → Complete on rows that already exist.

## §G — ROADMAP.md final flips (Task 04-02-07)

### G.1 — Phase list checkbox (line 20)

CURRENT:
```
- [ ] **Phase 4 (v1.x): Quality of Life** — Address first real-use frustrations once the polished loop is stable.
```

REPLACE with:
```
- [x] **Phase 4 (v1.x): Quality of Life** — Address first real-use frustrations once the polished loop is stable. *(completed YYYY-MM-DD)*
```
(Use today's actual date.)

### G.2 — "## Phase Details" Phase 4 entry (lines 130-142)

The current `**Plans**: 4 plans` line is wrong (Phase 4 actually shipped 3 plans, not 4). REPLACE the line with the populated plan list:

CURRENT:
```
**Plans**: 4 plans
```

REPLACE with:
```
**Plans:** 3 plans
  - [x] 04-00-staging-PLAN.md — Wave 0: test_karabiner_check.sh + 3 manual walkthrough scaffolds + REQUIREMENTS.md QOL-01/QOL-NEW-01 stubs
  - [x] 04-01-lua-core-PLAN.md — Wave 1: F19 binding + cmd+shift+v re-paste + lastTranscript caching in init.lua (turns checks 6/7/8 GREEN)
  - [x] 04-02-karabiner-docs-PLAN.md — Wave 2: assets/karabiner-fn-to-f19.json + setup.sh Step 9 + README + SECURITY.md + REQUIREMENTS.md/ROADMAP.md closure (turns checks 1-5 GREEN; 3 live walkthrough sign-offs)
```

### G.3 — Progress table row (line 199)

CURRENT:
```
| 6 | Phase 4 (v1.x): Quality of Life | 0/0 | Queued | - |
```

REPLACE with:
```
| 6 | Phase 4 (v1.x): Quality of Life | 3/3 | Complete — QOL-01 (cmd+shift+v re-paste) + QOL-NEW-01 (F19 alt hotkey via Karabiner) shipped; test_karabiner_check.sh 8/8 GREEN; 3 manual walkthroughs signed off live | YYYY-MM-DD |
```
(Use today's actual date.)

### G.4 — Coverage Summary per-phase row (lines 213-220)

CURRENT (no Phase 4 row exists in the Coverage Summary table — only Phases 1, 2, 2.5, 3, 3.5):
```
| 3.5. Hover UI / HUD | HUD-01, HUD-02, HUD-03, HUD-04 | 4 |
| **Total v1** | | **39** (was 26 → 29 with BRD → 35 with SEC → 39 with HUD) |
```

ADD a new row BETWEEN "Phase 3.5" and "Total v1":
```
| 4 (v1.x). Quality of Life | QOL-01, QOL-NEW-01 | 2 |
```

UPDATE the Total v1 row arithmetic:
```
| **Total v1** | | **41** (was 26 → 29 with BRD → 35 with SEC → 39 with HUD → 41 with QOL) |
```

### G.5 — Footer "Roadmap updated" line (line 225)

APPEND a new italics line below the existing updated line:
```
*Roadmap updated: YYYY-MM-DD — Phase 4 Quality of Life closed (3/3 plans; QOL-01 + QOL-NEW-01 Complete; coverage 39 → 41 v1 reqs; F19 push-to-talk + cmd+shift+v re-paste shipped; Karabiner-Elements added as carried-by-reference runtime dep in SBOM scope).*
```
(Use today's actual date.)
</reference_data>
</context>

<tasks>

<task type="auto">
  <name>Task 04-02-01: Create assets/karabiner-fn-to-f19.json (verbatim Karabiner complex-modification rule)</name>
  <read_first>
    - .planning/phases/04-quality-of-life-v1-x/04-RESEARCH.md "Code Examples §4" (lines 547-581) — the verbatim JSON content
    - .planning/phases/04-quality-of-life-v1-x/04-CONTEXT.md §decisions D-06 (Karabiner JSON ships in repo) and D-09 (no raw flagsChanged path — Karabiner is the only fn-trigger pathway)
    - tests/test_karabiner_check.sh checks 1-3 (the exact jq assertions this file must satisfy)
    - This plan's `<reference_data>` §A — verbatim file content
  </read_first>
  <files>assets/karabiner-fn-to-f19.json</files>
  <action>
    Create `assets/karabiner-fn-to-f19.json` with the EXACT verbatim content from this plan's `<reference_data>` §A. The full file content (NO paraphrasing, NO reformatting, NO field additions/removals):

    ```json
    {
      "title": "PurpleVoice — fn → F19",
      "rules": [
        {
          "description": "Hold fn → F19 (PurpleVoice push-to-talk). Quick tap → native macOS fn behaviour (Globe popup, function-key row, dictation).",
          "manipulators": [
            {
              "type": "basic",
              "from": {
                "key_code": "fn"
              },
              "to_if_alone": [
                {
                  "key_code": "fn",
                  "halt": true
                }
              ],
              "to_if_held_down": [
                {
                  "key_code": "f19"
                }
              ],
              "parameters": {
                "basic.to_if_alone_timeout_milliseconds": 200,
                "basic.to_if_held_down_threshold_milliseconds": 200
              }
            }
          ]
        }
      ]
    }
    ```

    Critical correctness:
    - Top-level `title` MUST be EXACTLY `"PurpleVoice — fn → F19"` — uses em-dash (U+2014) and right-arrow (U+2192). These exact glyphs appear in RESEARCH §4 source; use them, not ASCII substitutes.
    - `from.key_code` MUST be `"fn"` (lowercase string).
    - `to_if_alone[0]` MUST contain BOTH `key_code: "fn"` AND `halt: true` (halt prevents the alone event from also firing the held event — RESEARCH §4 schema verification).
    - `to_if_held_down[0].key_code` MUST be `"f19"` (lowercase; matches Hammerspoon's `hs.keycodes.map`).
    - BOTH `basic.to_if_alone_timeout_milliseconds` AND `basic.to_if_held_down_threshold_milliseconds` MUST be `200` (RESEARCH Pitfall 1 sweet spot; symmetric values).
    - File MUST end with a final newline (standard text-file convention).
    - 2-space JSON indentation (matches Karabiner's own example files).

    DO NOT:
    - Add `to_after_key_up` (RESEARCH Open Question 1 — not needed for v1.x; defer to "if-needed" addition).
    - Use ASCII `-` or `->` for the title — keep the em-dash and right-arrow glyphs verbatim.
    - Add comments inside the JSON (JSON does not support `//` or `/* */`).
    - Capitalise the key codes (`"FN"` or `"F19"` are wrong; lowercase is canonical).

    After this task: `bash tests/test_karabiner_check.sh; echo $?` exits with 1 still (checks 4/5 RED — setup.sh Step 9 not yet added) BUT the failure messages should NO LONGER include checks 1, 2, 3 (those are now GREEN). Specifically:
    - Check 1 (jq empty): GREEN
    - Check 2 (top-level structure title + rules): GREEN
    - Check 3 (from.key_code=fn, to_if_held_down.key_code=f19): GREEN
    - Checks 4, 5 still RED (await Task 04-02-02)
    - Checks 6, 7, 8 still GREEN (from Plan 04-01)
    Net: test_karabiner_check.sh advances from 3/8 GREEN to 6/8 GREEN.
  </action>
  <verify>
    <automated>test -f assets/karabiner-fn-to-f19.json && jq empty assets/karabiner-fn-to-f19.json && [ "$(jq -r '.title' assets/karabiner-fn-to-f19.json)" = "PurpleVoice — fn → F19" ] && [ "$(jq -r '.rules[0].manipulators[0].from.key_code' assets/karabiner-fn-to-f19.json)" = "fn" ] && [ "$(jq -r '.rules[0].manipulators[0].to_if_held_down[0].key_code' assets/karabiner-fn-to-f19.json)" = "f19" ] && [ "$(jq -r '.rules[0].manipulators[0].to_if_alone[0].key_code' assets/karabiner-fn-to-f19.json)" = "fn" ] && [ "$(jq -r '.rules[0].manipulators[0].to_if_alone[0].halt' assets/karabiner-fn-to-f19.json)" = "true" ] && [ "$(jq -r '.rules[0].manipulators[0].parameters["basic.to_if_alone_timeout_milliseconds"]' assets/karabiner-fn-to-f19.json)" = "200" ] && [ "$(jq -r '.rules[0].manipulators[0].parameters["basic.to_if_held_down_threshold_milliseconds"]' assets/karabiner-fn-to-f19.json)" = "200" ]</automated>
  </verify>
  <acceptance_criteria>
    - File `assets/karabiner-fn-to-f19.json` exists
    - `jq empty assets/karabiner-fn-to-f19.json` exits 0 (valid JSON)
    - `jq -r '.title' assets/karabiner-fn-to-f19.json` outputs EXACTLY `PurpleVoice — fn → F19` (em-dash + right-arrow)
    - `jq -r '.rules[0].manipulators[0].from.key_code' assets/karabiner-fn-to-f19.json` outputs `fn`
    - `jq -r '.rules[0].manipulators[0].to_if_alone[0].key_code' assets/karabiner-fn-to-f19.json` outputs `fn`
    - `jq -r '.rules[0].manipulators[0].to_if_alone[0].halt' assets/karabiner-fn-to-f19.json` outputs `true`
    - `jq -r '.rules[0].manipulators[0].to_if_held_down[0].key_code' assets/karabiner-fn-to-f19.json` outputs `f19`
    - `jq -r '.rules[0].manipulators[0].parameters["basic.to_if_alone_timeout_milliseconds"]' assets/karabiner-fn-to-f19.json` outputs `200`
    - `jq -r '.rules[0].manipulators[0].parameters["basic.to_if_held_down_threshold_milliseconds"]' assets/karabiner-fn-to-f19.json` outputs `200`
    - `! grep -q '"to_after_key_up"' assets/karabiner-fn-to-f19.json` (deferred per RESEARCH Open Question 1)
    - `bash tests/test_karabiner_check.sh; echo $?` exits 1 still (checks 4/5 RED — setup.sh Step 9 not yet added) BUT failure output does NOT include `FAIL:` lines for the JSON file (checks 1, 2, 3 now GREEN)
    - `bash tests/test_brand_consistency.sh` exits 0 (no voice-cc strings)
    - `bash tests/run_all.sh` reports 10 PASS + 1 FAIL (test_karabiner_check.sh still RED overall — handoff to Task 04-02-02)
  </acceptance_criteria>
  <done>
    `assets/karabiner-fn-to-f19.json` exists with the verbatim RESEARCH §4 content. JSON is valid; all 7 jq assertions pass. test_karabiner_check.sh advances 3/8 GREEN → 6/8 GREEN (checks 1-3 turn GREEN; 4-5 still RED awaiting Task 04-02-02; 6-8 stay GREEN from Plan 04-01).
  </done>
</task>

<task type="auto">
  <name>Task 04-02-02: Add setup.sh Step 9 (Karabiner-Elements check) + Option A reorganisation (banner moves to LAST step)</name>
  <read_first>
    - setup.sh (read in FULL — verify the current step ordering 1, 2, 3, 3b, 4, 5, 5b, 6, 6b, 6c, 7-banner, 8-SBOM matches the `<interfaces>` section's inventory)
    - .planning/phases/04-quality-of-life-v1-x/04-RESEARCH.md "Code Examples §5" (lines 594-647) — the verbatim Step 9 bash content + Option A reorganisation rationale
    - .planning/phases/04-quality-of-life-v1-x/04-CONTEXT.md §decisions D-07 (Karabiner setup is "Document + check"; refuses install complete without Karabiner) and D-08 (PURPLEVOICE_OFFLINE=1 still runs the check; air-gap path mentioned in error message)
    - tests/test_karabiner_check.sh checks 4-5 (the exact grep assertions this task must satisfy)
    - This plan's `<reference_data>` §B — verbatim Step 9 bash + Option A reorg + banner cmd+shift+e → F19 update
  </read_first>
  <files>setup.sh</files>
  <action>
    Three coupled edits to `setup.sh`:

    ### Edit A — Insert Step 9 (Karabiner check) — VERBATIM from `<reference_data>` §B.1

    Insert the EXACT bash block from §B.1 between the current Step 8 SBOM regen end (line 417) and the relocated banner (per Edit B below). Critical correctness:
    - Heredoc delimiter is `EOF` (NOT `'EOF'`) — variables ARE expanded inside the heredoc; `$KARABINER_JSON` becomes the actual file path at runtime.
    - The `\$KARABINER_JSON` escape sequences shown in §B.1 are MARKDOWN escaping; when written into setup.sh the heredoc body MUST contain unescaped `$KARABINER_JSON` (no backslash). Sanity check: `grep -c '\\$KARABINER_JSON' setup.sh` after the edit should output 0; `grep -c '\$KARABINER_JSON' setup.sh` should output >= 3 (variable references in the heredoc).
    - The `KARABINER_JSON="$REPO_ROOT/assets/karabiner-fn-to-f19.json"` assignment relies on `REPO_ROOT` being in scope from line 304 of the existing setup.sh — verify by reading setup.sh first.
    - Keep all 5 numbered install steps inside the heredoc verbatim (Download / Drag / Launch + grant / Import JSON / Re-run setup.sh).
    - Keep the air-gap note ("If air-gapped: copy Karabiner-Elements.dmg from a connected machine via USB ...") verbatim — this is the D-08 OFFLINE compatibility path.
    - Both `exit 1` branches (file-existence guard + .app-existence guard) MUST be present.
    - Both success-path `echo` lines (`OK: Karabiner-Elements detected ...` + `REMINDER: ensure 'Hold fn → F19 (PurpleVoice push-to-talk)' is enabled ...`) MUST be present.

    ### Edit B — Option A reorganisation (banner moves to LAST step)

    The current setup.sh order is 1, 2, 3, 3b, 4, 5, 5b, 6, 6b, 6c, **7-banner (lines 312-334)**, **8-SBOM (lines 336-417)**. After this task, the order MUST be 1, 2, 3, 3b, 4, 5, 5b, 6, 6b, 6c, **8-SBOM (relocated to immediately after Step 6c)**, **9-Karabiner (NEW — Edit A content)**, **10-banner (was Step 7; renamed Step 10; relocated to LAST)**.

    Rename the current Step 7 header `# Step 7: Next-step reminders ...` (line 314) to `# Step 10: Next-step reminders (banner — final step)`. Step 8 SBOM regen header (line 338 `# Step 8: Regenerate SBOM if Syft is present`) is UNCHANGED in name; it just gets relocated UP to immediately follow Step 6c symlinks.

    Implementation tactic — Read setup.sh in full (use the Read tool, all 417 lines). Then Write the entire file with the new ordering: Chunk A (lines 1-310, Steps 1 through 6c, UNCHANGED) + Chunk C (lines 336-417, Step 8 SBOM regen, UNCHANGED content but relocated UP) + Chunk D (NEW — verbatim §B.1 Step 9 Karabiner-check block) + Chunk B (lines 312-334, was Step 7 banner, header renamed to Step 10, cmd+shift+e line updated per Edit C). DO NOT use sed multi-line moves — fragile. The Write tool with the full reorganised file is the correct mechanism.

    ### Edit C — Banner cmd+shift+e → F19 update (inside the relocated Step 10 / former Step 7)

    Inside the heredoc at the (now-relocated) banner step, line currently reads:
    ```
      - Hotkey: cmd+shift+e (push-and-hold).
    ```

    REPLACE with TWO bullet lines (per `<reference_data>` §B.3):
    ```
      - Hotkey: F19 push-and-hold (Karabiner remaps fn → F19 — see Step 9 reminder above).
      - Re-paste last transcript: cmd+shift+v.
    ```

    All other content inside the banner heredoc (lines 312-334) stays VERBATIM.

    ### Sanity checks AFTER all three edits

    - `bash -n setup.sh` exits 0 (no syntax errors)
    - `grep -c 'cmd+shift+e' setup.sh` outputs 0 (zero references — banner cleaned)
    - `grep -q '/Applications/Karabiner-Elements.app' setup.sh` succeeds (Step 9 check present)
    - `grep -q 'KARABINER_JSON=.\$REPO_ROOT/assets/karabiner-fn-to-f19.json' setup.sh` succeeds (variable assignment present)
    - `grep -q 'Step 9: Karabiner-Elements check' setup.sh` succeeds (header comment present)
    - `grep -q 'Step 10: Next-step reminders' setup.sh` succeeds (banner renamed)
    - The line order `Step 8` → `Step 9` → `Step 10` is preserved when grep'ing for headers in line order: `grep -nE '^# Step (8|9|10):' setup.sh` shows ascending line numbers with Step 8, Step 9, Step 10.

    DO NOT:
    - Modify Steps 1 through 6c
    - Modify Step 8 SBOM regen content (only its file-position changes)
    - Add a PURPLEVOICE_OFFLINE branch around Step 9 (D-08: same logic in both modes; offline path is in the error message)
    - Auto-install Karabiner via brew or any other path (D-07: Document + check, NOT auto-install)
    - Use `'EOF'` (quoted) heredoc delimiter — variable expansion is REQUIRED for `$KARABINER_JSON` to print the actual path

    After this task: `bash tests/test_karabiner_check.sh; echo $?` exits 0 (all 8 checks GREEN). `bash tests/run_all.sh` reports 11 PASS / 0 FAIL.
  </action>
  <verify>
    <automated>bash -n setup.sh && [ "$(grep -c 'cmd+shift+e' setup.sh)" = "0" ] && grep -q '/Applications/Karabiner-Elements.app' setup.sh && grep -q 'assets/karabiner-fn-to-f19.json' setup.sh && grep -q 'Step 9: Karabiner-Elements check' setup.sh && grep -q 'Step 10: Next-step reminders' setup.sh && grep -q 'F19 push-and-hold' setup.sh && grep -q 'Re-paste last transcript: cmd+shift+v' setup.sh && bash tests/test_karabiner_check.sh && bash tests/run_all.sh</automated>
  </verify>
  <acceptance_criteria>
    - `bash -n setup.sh` exits 0 (valid bash syntax)
    - `grep -c 'cmd+shift+e' setup.sh` outputs 0 (zero remaining references)
    - `grep -q '/Applications/Karabiner-Elements.app' setup.sh` succeeds (Step 9 .app-existence check present)
    - `grep -q 'assets/karabiner-fn-to-f19.json' setup.sh` succeeds (Step 9 file-existence guard reference present)
    - `grep -q 'Step 9: Karabiner-Elements check' setup.sh` succeeds (Step 9 header comment present)
    - `grep -q 'Step 10: Next-step reminders' setup.sh` succeeds (banner renamed from Step 7 to Step 10)
    - `grep -q 'F19 push-and-hold' setup.sh` succeeds (banner cmd+shift+e replacement bullet)
    - `grep -q 'Re-paste last transcript: cmd+shift+v' setup.sh` succeeds (banner re-paste bullet)
    - `grep -q 'Karabiner remaps fn → F19' setup.sh` succeeds (banner explanatory note)
    - `grep -q 'If air-gapped: copy Karabiner-Elements.dmg' setup.sh` succeeds (D-08 air-gap path in error message)
    - `grep -q 'Allow software from Fumihiko Takayama' setup.sh` succeeds (Step 9 driver-grant instruction in error message)
    - Step ordering verified — `grep -nE '^# Step (8|9|10):' setup.sh | awk -F: '{print $1}' | sort -nc` exits 0 (line numbers ascending)
    - `bash tests/test_karabiner_check.sh; echo $?` exits 0 (all 8 checks GREEN — final state)
    - `bash tests/run_all.sh; echo $?` exits 0 (11 PASS / 0 FAIL — full functional suite GREEN)
    - `bash tests/security/run_all.sh; echo $?` exits 0 (5/5 GREEN — security suite untouched)
    - `bash tests/test_brand_consistency.sh; echo $?` exits 0 (no new voice-cc strings)
    - `bash tests/test_security_md_framing.sh; echo $?` exits 0 (SECURITY.md untouched in this task)
    - `! grep -q whisper-cli purplevoice-lua/init.lua` (Pattern 2 corollary intact)
    - `[ "$(grep -c WHISPER_BIN purplevoice-record)" = "2" ]` (Pattern 2 invariant intact)
  </acceptance_criteria>
  <done>
    `setup.sh` has Step 9 (Karabiner-Elements check) inserted verbatim per RESEARCH §5; Option A reorg complete (banner moved to LAST step, renamed Step 10; SBOM regen relocated to position immediately after Step 6c); banner cmd+shift+e → F19 + cmd+shift+v references updated. test_karabiner_check.sh advances from 6/8 GREEN to 8/8 GREEN — full functional suite is now 11/0. Security suite stays 5/0. All lints GREEN. Pattern 2 invariants intact.
  </done>
</task>

<task type="auto">
  <name>Task 04-02-03: Sweep tests/manual/ — replace cmd+shift+e with F19 across 12 legacy walkthrough files</name>
  <read_first>
    - tests/manual/test_accessibility_prompt.md, test_audio_cues.md, test_clipboard_restore.md, test_hud_appearance.md, test_hud_disable.md, test_hud_focus.md, test_hud_idle_cpu.md, test_hud_screen_capture.md, test_menubar.md, test_reentrancy.md, test_tcc_notification.md, test_transient_marker.md (all 12 files — read each in full BEFORE editing to understand surrounding narrative tone)
    - tests/manual/test_f19_walkthrough.md (Plan 04-00 created — DO NOT modify; reference for the F19 narrative tone you should use in the swept files)
    - .planning/phases/04-quality-of-life-v1-x/04-CONTEXT.md §decisions D-05 (cmd+shift+e binding REMOVED — sweeps are aligning the docs with the new reality)
    - This plan's `<reference_data>` §E — replacement strategy + confirmed file list with occurrence counts
  </read_first>
  <files>tests/manual/test_accessibility_prompt.md, tests/manual/test_audio_cues.md, tests/manual/test_clipboard_restore.md, tests/manual/test_hud_appearance.md, tests/manual/test_hud_disable.md, tests/manual/test_hud_focus.md, tests/manual/test_hud_idle_cpu.md, tests/manual/test_hud_screen_capture.md, tests/manual/test_menubar.md, tests/manual/test_reentrancy.md, tests/manual/test_tcc_notification.md, tests/manual/test_transient_marker.md</files>
  <action>
    Mechanical sweep across 12 legacy manual walkthrough files. Confirmed list with occurrence counts (verified 2026-04-30 via `grep -c 'cmd+shift+e' tests/manual/*.md`):

    | File | Occurrences |
    |---|---|
    | test_accessibility_prompt.md | 1 |
    | test_audio_cues.md | 2 |
    | test_clipboard_restore.md | 1 |
    | test_hud_appearance.md | 2 |
    | test_hud_disable.md | 2 |
    | test_hud_focus.md | 1 |
    | test_hud_idle_cpu.md | 1 |
    | test_hud_screen_capture.md | 4 |
    | test_menubar.md | 1 |
    | test_reentrancy.md | 3 |
    | test_tcc_notification.md | 1 |
    | test_transient_marker.md | 5 |
    | **TOTAL** | **24** |

    **Replacement strategy (per `<reference_data>` §E):**
    - For walkthrough STEP lines that say "Hold cmd+shift+e" or "press cmd+shift+e" or similar imperatives: replace `cmd+shift+e` with `F19` (or `fn (held)` if the surrounding narrative reads better with the human-friendly form — pick one consistently within each file).
    - For introductory paragraphs / requirement descriptions: replace `cmd+shift+e` with `F19` and add a brief parenthetical the FIRST time per file: `F19 (Karabiner-remapped from fn)` so the reader has context when picking up the file cold.
    - For any inline-code spans (backtick-wrapped `cmd+shift+e`): replace with `F19` in backticks (`` `F19` ``).

    **Recommended workflow per file:**
    1. Read the file in full (Read tool).
    2. Identify each cmd+shift+e occurrence + its surrounding narrative context (1-2 lines around it).
    3. Decide F19 vs "fn (held)" based on which reads better in that context. Be CONSISTENT within each file.
    4. Use Edit tool for each occurrence (or multiple Edit calls if multiple occurrences in the same file).
    5. After editing, re-grep that single file: `grep -c 'cmd+shift+e' tests/manual/<file>.md` should output 0.

    **DO NOT:**
    - Modify any other content in these files (test steps, expected outcomes, sign-off sections, prerequisites — all stay verbatim except the cmd+shift+e references).
    - Touch the 3 Phase-4 files Plan 04-00 created (test_f19_walkthrough.md, test_repaste_walkthrough.md, test_setup_karabiner_missing.md). Those already use F19 by design.
    - Use sed -i for the bulk replace — too easy to introduce subtle whitespace or escaping issues across 12 files. The Read + Edit per file workflow is more auditable.
    - Add a "F19 explained" preamble paragraph to each file — that's content drift. The brief `(Karabiner-remapped from fn)` parenthetical at first reference is enough.

    **Sanity checks AFTER the sweep:**
    - `grep -rl 'cmd+shift+e' tests/manual/` returns NO files (zero matches across the whole directory).
    - All 12 files still parse as Markdown (no broken table cells / list items).
    - `bash tests/run_all.sh; echo $?` exits 0 (11 PASS / 0 FAIL — sweep doesn't affect functional suite, but verify nothing else regressed).
    - `bash tests/test_brand_consistency.sh; echo $?` exits 0 (sweeps don't introduce voice-cc strings — F19 / fn / Karabiner are not brand strings).

    After this task: `tests/manual/` is fully consistent with the F19 push-to-talk reality. All 15 manual walkthroughs (12 swept + 3 Phase-4-native) reference F19 / fn-hold; cmd+shift+e is fully eradicated from the test corpus.
  </action>
  <verify>
    <automated>! grep -rq 'cmd+shift+e' tests/manual/ && [ "$(grep -rl 'F19' tests/manual/ | wc -l | tr -d ' ')" -ge "12" ] && bash tests/run_all.sh && bash tests/test_brand_consistency.sh</automated>
  </verify>
  <acceptance_criteria>
    - `! grep -rq 'cmd+shift+e' tests/manual/` succeeds (zero matches across the entire `tests/manual/` directory)
    - Each of the 12 listed files has zero `cmd+shift+e` occurrences (per-file verification: `for f in tests/manual/test_{accessibility_prompt,audio_cues,clipboard_restore,hud_appearance,hud_disable,hud_focus,hud_idle_cpu,hud_screen_capture,menubar,reentrancy,tcc_notification,transient_marker}.md; do [ "$(grep -c 'cmd+shift+e' $f)" = "0" ] || echo "FAIL: $f still has cmd+shift+e"; done` produces NO FAIL lines)
    - At least 12 files in `tests/manual/` mention `F19` (the swept files all gained F19 references; original Phase-4 files already had them)
    - The 3 Phase-4-native files (test_f19_walkthrough.md, test_repaste_walkthrough.md, test_setup_karabiner_missing.md) are UNCHANGED (verify via git diff that those filenames are NOT in the modified set)
    - Each swept file's surrounding narrative still parses as valid Markdown (no broken `## Steps` headings / `1.` numbered lists / `- ` bullets)
    - `bash tests/run_all.sh; echo $?` exits 0 (11/11 GREEN)
    - `bash tests/security/run_all.sh; echo $?` exits 0 (5/5 GREEN)
    - `bash tests/test_brand_consistency.sh; echo $?` exits 0 (no new voice-cc strings)
    - `bash tests/test_security_md_framing.sh; echo $?` exits 0 (SECURITY.md untouched in this task)
    - `! grep -q whisper-cli purplevoice-lua/init.lua` AND `[ "$(grep -c WHISPER_BIN purplevoice-record)" = "2" ]` (Pattern 2 invariants intact)
  </acceptance_criteria>
  <done>
    All 12 legacy manual walkthroughs swept — cmd+shift+e fully eradicated from `tests/manual/`. The 3 Phase-4 walkthroughs (created by Plan 04-00) are untouched. Suites stay GREEN. Brand consistency intact.
  </done>
</task>

<task type="auto">
  <name>Task 04-02-04: Update README.md — Hotkey section + Karabiner setup subsection + Cmd+K V workaround</name>
  <read_first>
    - README.md (read in FULL — at minimum lines 1-100 covering Hotkey, Setup, Permissions sections; verify no other cmd+shift+e references via `grep -n cmd+shift+e README.md`)
    - .planning/phases/04-quality-of-life-v1-x/04-RESEARCH.md §"Pitfall 2" Key Findings (cmd+shift+v collision audit + Cmd+K V workaround)
    - .planning/phases/04-quality-of-life-v1-x/04-CONTEXT.md §decisions D-02 (cmd+shift+v re-paste; collision accepted), D-05 (F19 only), D-07 (Karabiner Document + check)
    - This plan's `<reference_data>` §C — verbatim Hotkey replacement + Karabiner subsection content + Cmd+K V workaround
  </read_first>
  <files>README.md</files>
  <action>
    Three edits to `README.md`:

    ### Edit A — REPLACE Hotkey section (lines 32-36) with the F19 + cmd+shift+v + Cmd+K V content

    CURRENT:
    ```markdown
    ## Hotkey

    `cmd+shift+e` (push-and-hold). Locked decision; see `.planning/phases/01-spike/01-CONTEXT.md` D-01.

    (Known minor conflict: VS Code / Cursor "Show Explorer" sidebar — accepted.)
    ```

    REPLACE with EXACTLY (per `<reference_data>` §C.1):
    ```markdown
    ## Hotkey

    **Primary trigger: F19 (push-and-hold).** Karabiner-Elements remaps the `fn` key — hold fn for >200 ms to start recording, release to stop. A quick tap of fn (under 200 ms) preserves macOS's native fn behaviour (Globe / emoji popup, function-key row, dictation). Locked decision per `.planning/phases/04-quality-of-life-v1-x/04-CONTEXT.md` D-05 (replaces the original `cmd+shift+e` binding to eliminate the VS Code / Cursor "Show Explorer" collision).

    **Re-paste last transcript: `cmd+shift+v`.** Pastes the most recent successful transcript into the focused window. Useful when focus shifted mid-paste and the transcript landed in the wrong app. In-memory only — lost on Hammerspoon reload (privacy-first; per CONTEXT.md D-03).

    > **VS Code / Cursor users:** the `cmd+shift+v` re-paste binding hijacks the IDE's default "Markdown Preview" shortcut whenever Hammerspoon is running. Workaround: use **`Cmd+K V`** for split-pane Markdown preview instead. The collision is documented and accepted per CONTEXT.md D-02.
    ```

    ### Edit B — INSERT Karabiner subsection AFTER the existing Setup paragraph (after line 46)

    The current Setup section ends at line 46 with the paragraph beginning `After running setup.sh, paste the printed require("purplevoice")...`. INSERT the following H3 subsection IMMEDIATELY AFTER that paragraph (before line 47 which is the blank-line + `## Permissions` heading):

    ```markdown
    ### Karabiner-Elements (required for the F19 hotkey)

    PurpleVoice's F19 push-to-talk hotkey is produced by remapping the `fn` key with [Karabiner-Elements](https://karabiner-elements.pqrs.org/) (free, open-source). `setup.sh` Step 9 checks for `/Applications/Karabiner-Elements.app` and refuses to declare install complete without it.

    One-time installation:

    1. Download `Karabiner-Elements.dmg` from <https://karabiner-elements.pqrs.org/>.
    2. Drag `Karabiner-Elements.app` to `/Applications/`.
    3. Launch Karabiner-Elements once. macOS will prompt for the driver / system-extension grant — open System Settings → Privacy & Security and enable **"Allow software from Fumihiko Takayama"** (the Karabiner author). Restart Karabiner-Elements when prompted.
    4. Import the `fn → F19` rule: Karabiner-Elements → **Preferences → Complex Modifications → Add rule → Import rule from file** → select `assets/karabiner-fn-to-f19.json` from this repository. Click **Enable** next to **"Hold fn → F19 (PurpleVoice push-to-talk)"**.
    5. Re-run `bash setup.sh` — Step 9 should now print `OK: Karabiner-Elements detected at /Applications/Karabiner-Elements.app`.

    Air-gapped users: copy `Karabiner-Elements.dmg` from a connected machine via USB sneakernet. The `fn → F19` JSON rule is already bundled in this repo at `assets/karabiner-fn-to-f19.json` — no additional download needed for the rule itself.

    The recommended hold threshold is 200 ms (configured in the JSON rule via `basic.to_if_alone_timeout_milliseconds` and `basic.to_if_held_down_threshold_milliseconds`). If the threshold feels wrong on your hardware (false-positive recording on quick taps OR perceived lag on intentional holds), edit both values in the JSON file in 50 ms increments and re-import in Karabiner.
    ```

    ### Edit C — Sanity check NO other cmd+shift+e references remain

    After Edits A and B, run `grep -n 'cmd+shift+e' README.md` — MUST return 0 hits. If any remain (e.g. a forgotten reference deeper in the file), Edit them out. Confirmed via 2026-04-30 grep that line 34 is the ONLY occurrence — Edit A handles it.

    ### DO NOT

    - Modify the README's "Status" section (lines 22-30) — those are phase-completion markers; they get updated when Phase 4 closes via the ROADMAP.md update (Task 04-02-07), NOT in README directly.
    - Modify the "Permissions" / "Recovery" / "Security & Privacy" sections — they don't reference cmd+shift+e and don't need Karabiner-specific updates beyond the new Setup subsection.
    - Add a new top-level `## Karabiner` section — the H3 nesting under `## Setup` is correct because Karabiner is a setup dependency, not a parallel concern to setup.
    - Use ASCII `->` for `fn → F19` — keep the right-arrow glyph (U+2192) for typographic consistency with the JSON title and Karabiner UI naming.

    ### Sanity checks AFTER all edits

    - `grep -c 'cmd+shift+e' README.md` outputs 0
    - `grep -q 'Karabiner-Elements' README.md` succeeds (multiple occurrences expected)
    - `grep -q 'karabiner-fn-to-f19.json' README.md` succeeds (Karabiner subsection references the bundled JSON)
    - `grep -q 'F19' README.md` succeeds (Hotkey section + Karabiner subsection reference F19)
    - `grep -q 'Cmd+K V' README.md` succeeds (VS Code workaround documented)
    - `bash tests/test_brand_consistency.sh` exits 0 (README.md is on the brand-test exemption list, but the changes don't introduce voice-cc strings anyway — defense in depth)
    - `bash tests/run_all.sh; echo $?` exits 0 (11/11 GREEN)
  </action>
  <verify>
    <automated>[ "$(grep -c 'cmd+shift+e' README.md)" = "0" ] && grep -q 'Karabiner-Elements' README.md && grep -q 'karabiner-fn-to-f19.json' README.md && grep -q 'F19' README.md && grep -q 'Cmd+K V' README.md && grep -q 'Allow software from Fumihiko Takayama' README.md && grep -q 'Re-paste last transcript' README.md && bash tests/test_brand_consistency.sh && bash tests/run_all.sh</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c 'cmd+shift+e' README.md` outputs 0 (zero remaining references — was 1 at line 34)
    - `grep -q 'Karabiner-Elements' README.md` succeeds (multiple references in Hotkey + Karabiner subsections)
    - `grep -q 'karabiner-fn-to-f19.json' README.md` succeeds (subsection references bundled JSON file path — at least 2 occurrences)
    - `grep -q 'F19' README.md` succeeds (multiple references)
    - `grep -q 'Cmd+K V' README.md` succeeds (VS Code Markdown Preview workaround note documented per RESEARCH Pitfall 2)
    - `grep -q 'fn → F19' README.md` succeeds (em-dash + right-arrow glyph used consistently with JSON title)
    - `grep -q 'Allow software from Fumihiko Takayama' README.md` succeeds (driver-grant instruction present in Karabiner subsection step 3)
    - `grep -q 'Re-paste last transcript' README.md` succeeds (cmd+shift+v re-paste documented in Hotkey section)
    - `grep -q 'Karabiner-Elements (required for the F19 hotkey)' README.md` succeeds (H3 subsection heading present)
    - `grep -q 'in-memory only' README.md` OR `grep -q 'In-memory only' README.md` succeeds (D-03 in-memory storage documented)
    - `bash tests/test_brand_consistency.sh; echo $?` exits 0 (no new voice-cc strings — README.md is on exemption list anyway)
    - `bash tests/test_security_md_framing.sh; echo $?` exits 0 (SECURITY.md untouched in this task)
    - `bash tests/run_all.sh; echo $?` exits 0 (11/11 GREEN)
    - `bash tests/security/run_all.sh; echo $?` exits 0 (5/5 GREEN)
  </acceptance_criteria>
  <done>
    `README.md` Hotkey section fully replaces cmd+shift+e with F19 + cmd+shift+v + Cmd+K V workaround note; new Karabiner subsection added under Setup with 5-step install flow + air-gap path + 200 ms tuning note. Zero cmd+shift+e references remain in README. All lints + suites GREEN.
  </done>
</task>

<task type="auto">
  <name>Task 04-02-05: Update SECURITY.md — TL;DR + Scope cmd+shift+e → F19; SBOM scope disclaimer adds Karabiner-Elements</name>
  <read_first>
    - SECURITY.md (read in FULL or at minimum lines 1-60 for TL;DR + Scope, AND lines 220-225 for SBOM scope disclaimer paragraph; use `grep -n 'cmd+shift+e\|carried by reference' SECURITY.md` to locate both edit targets precisely)
    - .planning/phases/04-quality-of-life-v1-x/04-RESEARCH.md "Key Findings" Karabiner-Elements SBOM scope disclaimer recommendation (lines ~912-913)
    - .planning/phases/04-quality-of-life-v1-x/04-CONTEXT.md §specifics "Karabiner's substrate matters for the SBOM" + §decisions D-10 (brand carryover — Karabiner JSON references org.hammerspoon.Hammerspoon honestly)
    - tests/test_security_md_framing.sh (read in full — verify what banned phrases the new content must avoid: "compliant", "certified", "guarantees" without qualifier; banned table-cell statuses; voice-cc strings)
    - tests/test_brand_consistency.sh (read in full — verify SECURITY.md is NOT on the exemption list; confirms voice-cc absence is enforced)
    - This plan's `<reference_data>` §D — verbatim TL;DR + Scope replacements + SBOM scope disclaimer prepend text
  </read_first>
  <files>SECURITY.md</files>
  <action>
    Three edits to `SECURITY.md`:

    ### Edit A — TL;DR cmd+shift+e → F19 (line 19, verified via grep 2026-04-30)

    CURRENT line 19:
    ```
    **What PurpleVoice does:** You hold `cmd+shift+e`, you speak, you release. The transcript appears in the focused window. Total round-trip: ~1-2 seconds. No cloud. No subscription. No telemetry.
    ```

    REPLACE with EXACTLY (per `<reference_data>` §D.1):
    ```
    **What PurpleVoice does:** You hold **F19** (Karabiner-Elements remaps the `fn` key — see [README.md Hotkey](README.md#hotkey)), you speak, you release. The transcript appears in the focused window. Total round-trip: ~1-2 seconds. No cloud. No subscription. No telemetry.
    ```

    ### Edit B — Scope description cmd+shift+e → F19 (line 51, verified via grep 2026-04-30)

    CURRENT line 51:
    ```
    1. User holds `cmd+shift+e`. Hammerspoon's `hs.hotkey` callback (registered by `purplevoice-lua/init.lua`) fires.
    ```

    REPLACE with EXACTLY (per `<reference_data>` §D.2):
    ```
    1. User holds **F19** (Karabiner-Elements remaps the `fn` key per `assets/karabiner-fn-to-f19.json` — see [SBOM Scope disclaimer](#scope-disclaimer-repo-only-syft-scan) for the runtime-dep framing). Hammerspoon's `hs.hotkey` callback (registered by `purplevoice-lua/init.lua`) fires.
    ```

    ### Edit C — SBOM scope disclaimer prepend Karabiner-Elements (line 223, verified via grep 2026-04-30)

    The target sentence is the parenthetical inside line 223 of SECURITY.md. It currently reads (find via `grep -n 'carried by reference' SECURITY.md`):
    ```
    The transitive dependencies named above (sox audio libs, whisper.cpp / ggml internals, Hammerspoon's bundled Lua + LuaSocket) are **carried by reference**, not enumerated as separate `package` entries:
    ```

    REPLACE with EXACTLY (per `<reference_data>` §D.3):
    ```
    The transitive dependencies named above (Karabiner-Elements (kernel-extension-class daemon for the fn→F19 hotkey remap; user-installed), sox audio libs, whisper.cpp / ggml internals, Hammerspoon's bundled Lua + LuaSocket) are **carried by reference**, not enumerated as separate `package` entries:
    ```

    Note the doubled-paren pattern `(Karabiner-Elements (kernel-extension-class daemon for the fn→F19 hotkey remap; user-installed), ...)` — the outer parens are the original sentence's parenthetical; the inner parens contain the Karabiner descriptor. This is intentional per RESEARCH §"Key Findings" recommendation. If the doubled-paren reads awkwardly to the executor, an alternative phrasing is acceptable so long as it preserves: (a) Karabiner-Elements named, (b) "kernel-extension-class daemon" or equivalent honest descriptor, (c) "fn→F19 hotkey remap" purpose statement, (d) "user-installed" provenance note, (e) appears IN the carried-by-reference list (NOT a separate sentence). Recommended alternative if the doubled paren reads badly: split into two sentences — first sentence updates the carried-by-reference list to include Karabiner-Elements (as just `Karabiner-Elements`), second sentence (NEW, inserted immediately before "Auditors who require...") reads:
    > Karabiner-Elements (added in Phase 4 for the fn→F19 hotkey remap) is a kernel-extension-class daemon installed by the user via `setup.sh` Step 9 — it is not enumerated as a separate `package` entry because it is user-installed via a documented .dmg flow (see [README.md Karabiner-Elements section](README.md#karabiner-elements-required-for-the-f19-hotkey)) and does not run inside the PurpleVoice process tree at all (it is a peer macOS daemon).

    Either form is acceptable; pick the one that reads better in the surrounding paragraph context. The verbatim form in `<reference_data>` §D.3 is the recommended default.

    ### DO NOT

    - Use the words `compliant`, `certified`, or `guarantees` without an existing qualifier — the framing lint will fail. The new content uses only `runtime dependency`, `kernel-extension-class daemon`, `user-installed`, `carried by reference` — all neutral.
    - Introduce any `voice-cc` strings — SECURITY.md is NOT on the brand-test exemption list. The Karabiner descriptor uses `purplevoice` namespace (the JSON file path `assets/karabiner-fn-to-f19.json` does not contain `voice-cc`).
    - Modify any other SECURITY.md section beyond the three named edits — Threat Model / NIST mapping / framework sections / Air-Gapped Installation are out of scope for this task.
    - Replace the `(Karabiner-Elements (kernel-extension-class daemon ...))` doubled-paren with a different framing word like "compliant kernel extension" — that introduces the banned phrase.

    ### Sanity checks AFTER all edits

    - `grep -c 'cmd+shift+e' SECURITY.md` outputs 0 (zero remaining references — was 2 at lines 19 + 51)
    - `grep -q 'Karabiner-Elements' SECURITY.md` succeeds (at least 3 occurrences: TL;DR + Scope + SBOM)
    - `grep -q 'kernel-extension-class daemon' SECURITY.md` succeeds (SBOM scope disclaimer descriptor)
    - `grep -q 'fn→F19' SECURITY.md` OR `grep -q 'fn → F19' SECURITY.md` succeeds (the remap purpose statement; em-dash form preferred)
    - `bash tests/test_security_md_framing.sh; echo $?` exits 0 (no new compliant/certified/guarantees without qualifier; voice-cc absence enforced; required H2 sections still present)
    - `bash tests/test_brand_consistency.sh; echo $?` exits 0 (no new voice-cc strings — SECURITY.md is NOT exempt from brand check)
    - `bash tests/run_all.sh; echo $?` exits 0 (11/11 GREEN — the framing lint runs as part of run_all.sh)
    - `bash tests/security/run_all.sh; echo $?` exits 0 (5/5 GREEN — security suite verifies SBOM file structure, not SECURITY.md prose)
  </action>
  <verify>
    <automated>[ "$(grep -c 'cmd+shift+e' SECURITY.md)" = "0" ] && grep -q 'Karabiner-Elements' SECURITY.md && grep -q 'kernel-extension-class daemon' SECURITY.md && grep -qE 'fn[ -→]→[ ]?F19' SECURITY.md && grep -q 'You hold \*\*F19\*\*' SECURITY.md && grep -q 'User holds \*\*F19\*\*' SECURITY.md && bash tests/test_security_md_framing.sh && bash tests/test_brand_consistency.sh && bash tests/run_all.sh && bash tests/security/run_all.sh</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c 'cmd+shift+e' SECURITY.md` outputs 0 (zero remaining references — was 2 at lines 19 + 51)
    - `grep -q 'Karabiner-Elements' SECURITY.md` succeeds (at least 3 occurrences across TL;DR + Scope + SBOM)
    - `grep -q 'kernel-extension-class daemon' SECURITY.md` succeeds (SBOM scope disclaimer descriptor present)
    - `grep -qE 'fn[ -→]→[ ]?F19' SECURITY.md` succeeds (remap purpose statement; em-dash + right-arrow form expected)
    - `grep -q 'You hold \*\*F19\*\*' SECURITY.md` succeeds (TL;DR replacement applied)
    - `grep -q 'User holds \*\*F19\*\*' SECURITY.md` succeeds (Scope replacement applied)
    - `grep -q 'user-installed' SECURITY.md` succeeds (Karabiner provenance note in SBOM disclaimer)
    - `grep -q 'carried by reference' SECURITY.md` STILL succeeds (the existing phrase wasn't deleted; it was extended with Karabiner-Elements)
    - `bash tests/test_security_md_framing.sh; echo $?` exits 0 (D-17 framing intact: no compliant/certified/guarantees without qualifier; required H2 sections still present; canonical tagline still present)
    - `bash tests/test_brand_consistency.sh; echo $?` exits 0 (no new voice-cc strings — SECURITY.md is NOT on the exemption list)
    - `bash tests/run_all.sh; echo $?` exits 0 (11/11 GREEN)
    - `bash tests/security/run_all.sh; echo $?` exits 0 (5/5 GREEN)
    - `! grep -q whisper-cli purplevoice-lua/init.lua` AND `[ "$(grep -c WHISPER_BIN purplevoice-record)" = "2" ]` (Pattern 2 invariants intact — SECURITY.md edits don't touch those files)
    - SECURITY.md required sections (Threat Model / Egress Verification / Software Bill of Materials / NIST / FIPS / Common Criteria / HIPAA / SOC 2 / ISO 27001 / Code Signing / Reproducible Build / Vulnerability Disclosure) are ALL still present (verified by the framing lint's required-section check)
  </acceptance_criteria>
  <done>
    `SECURITY.md` TL;DR + Scope description updated to reference F19 (with Karabiner remap context) instead of cmd+shift+e; SBOM scope disclaimer prepends Karabiner-Elements as carried-by-reference runtime dep alongside Hammerspoon. Zero cmd+shift+e references remain. Framing lint stays GREEN; brand consistency stays GREEN; both suites stay GREEN.
  </done>
</task>

<task type="auto">
  <name>Task 04-02-06: Update .planning/REQUIREMENTS.md — flip QOL-01 + QOL-NEW-01 from Pending to Complete</name>
  <read_first>
    - .planning/REQUIREMENTS.md (read in FULL — verify Plan 04-00's edits landed correctly: v1 QOL subsection exists with both rows `[ ] Pending`; Traceability table has both rows `Pending`; per-phase counts row has Phase 4 entry; coverage stat = 41 v1 reqs; QOL-03/04/05 v2 stubs use purplevoice paths)
    - .planning/phases/04-quality-of-life-v1-x/04-00-staging-PLAN.md (Task 0-5 — review what Plan 04-00 already changed so this task only flips state, doesn't re-do edits)
    - .planning/phases/04-quality-of-life-v1-x/04-CONTEXT.md §domain "Success criteria" item 5 (REQUIREMENTS.md QOL-01 / QOL-NEW-01 Complete with concrete language — Plan 04-00 added the concrete language; this task just flips checkboxes)
    - This plan's `<reference_data>` §F — verbatim flip targets (4 cells + 1 footer line)
  </read_first>
  <files>.planning/REQUIREMENTS.md</files>
  <action>
    Four targeted edits to `.planning/REQUIREMENTS.md` — all simple `Pending` → `Complete` and `[ ]` → `[x]` flips. Plan 04-00 did the heavy lifting (created the rows with concrete language); this task just promotes them.

    ### Edit A — v1 QOL subsection: flip both checkboxes from `[ ]` to `[x]`

    Locate the v1 `### Quality of Life` subsection (added by Plan 04-00; should be after `### Hover UI / HUD` and BEFORE `## v2 Requirements`). Find the two rows starting with `- [ ] **QOL-01**:` and `- [ ] **QOL-NEW-01**:`.

    REPLACE both `- [ ]` markers with `- [x]`. The body text after the checkbox is UNCHANGED — only the checkbox flips.

    Sanity check pre-edit: `grep -nE '^- \[ \] \*\*QOL-(01|NEW-01)\*\*:' .planning/REQUIREMENTS.md` should match 2 lines.
    Sanity check post-edit: `grep -nE '^- \[x\] \*\*QOL-(01|NEW-01)\*\*:' .planning/REQUIREMENTS.md` should match 2 lines (and the `[ ]` form should match 0).

    ### Edit B — Traceability table: flip both `Pending` cells to `Complete`

    Locate the Traceability table (around line 162). Find the two rows:
    ```
    | QOL-01 | Phase 4 (v1.x): Quality of Life | Pending |
    | QOL-NEW-01 | Phase 4 (v1.x): Quality of Life | Pending |
    ```

    REPLACE both `Pending` cells with `Complete`. Final form:
    ```
    | QOL-01 | Phase 4 (v1.x): Quality of Life | Complete |
    | QOL-NEW-01 | Phase 4 (v1.x): Quality of Life | Complete |
    ```

    DO NOT modify the QOL-02..05 rows (they remain `Deferred` with the rationale-in-cell from Plan 04-00).

    ### Edit C — Per-phase counts row: flip Phase 4 entry from `Pending` to `Complete`

    Locate the per-phase counts row added by Plan 04-00 (around line 184):
    ```
    - Phase 4 (v1.x): Quality of Life — 2 requirements (QOL-01, QOL-NEW-01) — Pending
    ```

    REPLACE with:
    ```
    - Phase 4 (v1.x): Quality of Life — 2 requirements (QOL-01, QOL-NEW-01) — Complete
    ```

    ### Edit D — Footer "Last updated" line: APPEND a Phase 4 closure note

    Locate the last italics line at the bottom of the file (around line 185):
    ```
    *Last updated: 2026-04-30 — four HUD requirements completed for Phase 3.5 (Complete); traceability table extended.*
    ```

    APPEND a new italics line BELOW it (preserving the existing line; adding a new one):
    ```
    *Last updated: YYYY-MM-DD — Phase 4 Quality of Life closed: QOL-01 (cmd+shift+v re-paste) + QOL-NEW-01 (F19 alt hotkey via Karabiner) marked Complete; v1 coverage stays at 41/41 (100%); 12 manual walkthroughs swept cmd+shift+e → F19; SECURITY.md SBOM scope updated to enumerate Karabiner-Elements as carried-by-reference runtime dep alongside Hammerspoon.*
    ```

    Use today's actual date for `YYYY-MM-DD` — substitute via `$(date +%Y-%m-%d)` at execute-time. The original "2026-04-30" line is PRESERVED (don't delete it; just add a new line below).

    ### DO NOT

    - Modify the v1 QOL subsection BODY text (it was set to the canonical concrete language by Plan 04-00; only flip the checkbox).
    - Modify any other CAP / TRA / INJ / FBK / ROB / DST / BRD / SEC / HUD section (those are Phase 1-3.5 — out of scope).
    - Re-bump the v1 coverage stat (`v1 requirements: 41 total`) — it's correct as-is. Plan 04-00 already moved it from 39 to 41; Phase 4 just flips status, doesn't add new requirements.
    - Modify the v2 QOL-02..05 stubs (Plan 04-00 already rebranded them to purplevoice paths; they remain Deferred).
    - Delete the existing "Last updated: 2026-04-30 — four HUD requirements completed" line — append the new line; don't replace.

    ### Sanity checks AFTER all edits

    - `grep -E '^- \[x\] \*\*QOL-01\*\*:' .planning/REQUIREMENTS.md` matches exactly 1 line
    - `grep -E '^- \[x\] \*\*QOL-NEW-01\*\*:' .planning/REQUIREMENTS.md` matches exactly 1 line
    - `grep -E '^- \[ \] \*\*QOL-(01|NEW-01)\*\*:' .planning/REQUIREMENTS.md` matches 0 lines (both flipped)
    - `grep -E '^\| QOL-01 .*\| Complete \|' .planning/REQUIREMENTS.md` matches 1 line
    - `grep -E '^\| QOL-NEW-01 .*\| Complete \|' .planning/REQUIREMENTS.md` matches 1 line
    - `grep -E '^\| QOL-(01|NEW-01) .*\| Pending \|' .planning/REQUIREMENTS.md` matches 0 lines
    - `grep -q 'Phase 4 (v1.x): Quality of Life — 2 requirements (QOL-01, QOL-NEW-01) — Complete' .planning/REQUIREMENTS.md` succeeds
    - `grep -q 'Phase 4 Quality of Life closed' .planning/REQUIREMENTS.md` succeeds (footer note added)
    - `grep -q 'v1 requirements: 41 total' .planning/REQUIREMENTS.md` STILL succeeds (Plan 04-00's coverage stat unchanged)
    - `bash tests/test_brand_consistency.sh; echo $?` exits 0 (no new voice-cc strings)
    - `bash tests/run_all.sh; echo $?` exits 0 (11/11 GREEN — REQUIREMENTS.md edits don't affect functional suite)
  </action>
  <verify>
    <automated>[ "$(grep -cE '^- \[x\] \*\*QOL-01\*\*:' .planning/REQUIREMENTS.md)" = "1" ] && [ "$(grep -cE '^- \[x\] \*\*QOL-NEW-01\*\*:' .planning/REQUIREMENTS.md)" = "1" ] && [ "$(grep -cE '^- \[ \] \*\*QOL-(01|NEW-01)\*\*:' .planning/REQUIREMENTS.md)" = "0" ] && [ "$(grep -cE '^\| QOL-01 .*\| Complete \|' .planning/REQUIREMENTS.md)" = "1" ] && [ "$(grep -cE '^\| QOL-NEW-01 .*\| Complete \|' .planning/REQUIREMENTS.md)" = "1" ] && grep -q 'Phase 4 (v1.x): Quality of Life — 2 requirements (QOL-01, QOL-NEW-01) — Complete' .planning/REQUIREMENTS.md && grep -q 'Phase 4 Quality of Life closed' .planning/REQUIREMENTS.md && grep -q 'v1 requirements: 41 total' .planning/REQUIREMENTS.md && bash tests/test_brand_consistency.sh && bash tests/run_all.sh</automated>
  </verify>
  <acceptance_criteria>
    - QOL-01 v1 subsection row flipped: `grep -E '^- \[x\] \*\*QOL-01\*\*: Paste-last-transcript hotkey' .planning/REQUIREMENTS.md` matches 1 line
    - QOL-NEW-01 v1 subsection row flipped: `grep -E '^- \[x\] \*\*QOL-NEW-01\*\*: F19 alt hotkey' .planning/REQUIREMENTS.md` matches 1 line (or whatever exact body text Plan 04-00 set — the checkbox is the load-bearing flip)
    - Zero `[ ]` Pending checkboxes remain on QOL-01 / QOL-NEW-01
    - Traceability table: `| QOL-01 | Phase 4 (v1.x): Quality of Life | Complete |` present (1 occurrence)
    - Traceability table: `| QOL-NEW-01 | Phase 4 (v1.x): Quality of Life | Complete |` present (1 occurrence)
    - QOL-02, QOL-03, QOL-04, QOL-05 traceability rows STILL marked `Deferred` (unchanged from Plan 04-00 — verify NOT accidentally flipped)
    - Per-phase counts row: `Phase 4 (v1.x): Quality of Life — 2 requirements (QOL-01, QOL-NEW-01) — Complete` present
    - Footer note: `Phase 4 Quality of Life closed` present (the existing 2026-04-30 HUD line is preserved; Phase 4 line added below)
    - Coverage stat unchanged: `v1 requirements: 41 total` STILL present (was set correctly by Plan 04-00; Phase 4 doesn't add to v1 count)
    - Coverage stat unchanged: `Mapped to phases: 41 / 41 (100%)` STILL present
    - Coverage stat unchanged: `v2 requirements: 6 total` STILL present
    - QOL-03 stub references `~/.config/purplevoice/replacements.txt` (Plan 04-00 rebrand preserved)
    - QOL-04 stub references `~/.cache/purplevoice/history.log` (Plan 04-00 rebrand preserved)
    - QOL-05 stub references `PURPLEVOICE_MODEL` (Plan 04-00 rebrand preserved)
    - `bash tests/test_brand_consistency.sh; echo $?` exits 0 (no new voice-cc strings; Plan 04-00 rebrand still intact)
    - `bash tests/run_all.sh; echo $?` exits 0 (11/11 GREEN)
    - `bash tests/security/run_all.sh; echo $?` exits 0 (5/5 GREEN)
  </acceptance_criteria>
  <done>
    `.planning/REQUIREMENTS.md`: QOL-01 + QOL-NEW-01 flipped from `[ ] Pending` to `[x] Complete` in BOTH the v1 subsection AND the Traceability table; per-phase counts row updated; closure footer note appended. Plan 04-00's heavy lifting (concrete language, Traceability rows, coverage stat bump, v2 rebrand) is fully preserved. All suites + lints GREEN.
  </done>
</task>

<task type="auto">
  <name>Task 04-02-07: Update .planning/ROADMAP.md — Phase 4 row Complete; plan list populated; Coverage Summary updated</name>
  <read_first>
    - .planning/ROADMAP.md (read in FULL — verify the current Phase 4 placeholders: line 20 `- [ ] **Phase 4 (v1.x): Quality of Life**`, lines 130-142 `## Phase Details` Phase 4 block with `**Plans**: 4 plans` placeholder, line 199 Progress table row `0/0 | Queued`, lines 213-220 Coverage Summary table without a Phase 4 row)
    - .planning/phases/04-quality-of-life-v1-x/04-00-SUMMARY.md (verify Plan 04-00 completed and what it produced)
    - .planning/phases/04-quality-of-life-v1-x/04-01-SUMMARY.md (verify Plan 04-01 completed and what it produced)
    - This plan's `<reference_data>` §G — verbatim flip targets (5 separate edits across the file)
  </read_first>
  <files>.planning/ROADMAP.md</files>
  <action>
    Five targeted edits to `.planning/ROADMAP.md`. All are status flips + plan-list population; no new requirements or phase additions.

    ### Edit A — Phase list checkbox (line 20)

    CURRENT:
    ```
    - [ ] **Phase 4 (v1.x): Quality of Life** — Address first real-use frustrations once the polished loop is stable.
    ```

    REPLACE with (use today's actual date for YYYY-MM-DD):
    ```
    - [x] **Phase 4 (v1.x): Quality of Life** — Address first real-use frustrations once the polished loop is stable. *(completed YYYY-MM-DD)*
    ```

    ### Edit B — "## Phase Details" Phase 4 entry: replace `**Plans**: 4 plans` with populated plan list (around line 142)

    CURRENT (the Phase 4 Phase Details block at lines 130-142 ends with the line):
    ```
    **Plans**: 4 plans
    ```

    REPLACE with:
    ```
    **Plans:** 3 plans
      - [x] 04-00-staging-PLAN.md — Wave 0: test_karabiner_check.sh + 3 manual walkthrough scaffolds + REQUIREMENTS.md QOL-01/QOL-NEW-01 stubs
      - [x] 04-01-lua-core-PLAN.md — Wave 1: F19 binding + cmd+shift+v re-paste + lastTranscript caching in init.lua (turns checks 6/7/8 GREEN)
      - [x] 04-02-karabiner-docs-PLAN.md — Wave 2: assets/karabiner-fn-to-f19.json + setup.sh Step 9 + README + SECURITY.md + REQUIREMENTS.md/ROADMAP.md closure (turns checks 1-5 GREEN; 3 live walkthrough sign-offs)
    ```

    Note: `**Plans:**` (with colon AFTER the bold) matches the convention used in other completed-phase Plan lists (e.g., Phase 1, Phase 2) — verify by `grep -A2 '\*\*Plans:\*\*' .planning/ROADMAP.md | head -10` shows the indented `- [x]` pattern. The `**Plans**: 4 plans` (colon OUTSIDE the bold) form was the placeholder; the colon-inside form is the canonical completed format.

    ### Edit C — Progress table row (line 199)

    CURRENT:
    ```
    | 6 | Phase 4 (v1.x): Quality of Life | 0/0 | Queued | - |
    ```

    REPLACE with (use today's actual date for YYYY-MM-DD):
    ```
    | 6 | Phase 4 (v1.x): Quality of Life | 3/3 | Complete — QOL-01 (cmd+shift+v re-paste) + QOL-NEW-01 (F19 alt hotkey via Karabiner) shipped; test_karabiner_check.sh 8/8 GREEN; 3 manual walkthroughs signed off live | YYYY-MM-DD |
    ```

    ### Edit D — Coverage Summary per-phase row (lines 213-220)

    The current Coverage Summary table has no Phase 4 row. Locate the row `| 3.5. Hover UI / HUD | HUD-01, HUD-02, HUD-03, HUD-04 | 4 |` (around line 218-219) and the `**Total v1**` row immediately after.

    INSERT a new row BETWEEN them:
    ```
    | 4 (v1.x). Quality of Life | QOL-01, QOL-NEW-01 | 2 |
    ```

    UPDATE the Total v1 row:

    CURRENT:
    ```
    | **Total v1** | | **39** (was 26 → 29 with BRD → 35 with SEC → 39 with HUD) |
    ```

    REPLACE with:
    ```
    | **Total v1** | | **41** (was 26 → 29 with BRD → 35 with SEC → 39 with HUD → 41 with QOL) |
    ```

    ### Edit E — Footer "Roadmap updated" italics line (line 225)

    APPEND a new italics line BELOW the existing "Roadmap updated: 2026-04-30" line (preserve existing line; add new):

    ```
    *Roadmap updated: YYYY-MM-DD — Phase 4 Quality of Life closed (3/3 plans; QOL-01 + QOL-NEW-01 Complete; coverage 39 → 41 v1 reqs; F19 push-to-talk + cmd+shift+v re-paste shipped; Karabiner-Elements added as carried-by-reference runtime dep in SBOM scope).*
    ```
    Use today's actual date for `YYYY-MM-DD`.

    ### DO NOT

    - Modify any other phase's Progress table row (Phases 1, 2, 2.5, 2.7, 3.5 are unchanged).
    - Modify the "## Research Flags" section or "## Coverage Summary" header lines beyond the targeted Edit D inserts.
    - Add a Phase 4 entry to "## Research Flags" — Phase 4 had research (RESEARCH.md exists) but the flag system tracks WHAT NEEDS research, not what's been done. Phase 4 is closed; no new research flag needed.
    - Touch Phases 3 (Distribution), 5 (Warm-Process Upgrade) — they're queued; Phase 4 closure doesn't promote them.
    - Delete the existing 2026-04-30 footer line — append the new line.

    ### Sanity checks AFTER all edits

    - `grep -E '^- \[x\] \*\*Phase 4 \(v1\.x\): Quality of Life\*\*' .planning/ROADMAP.md` matches 1 line (Edit A)
    - `grep -E '^\| 6 \| Phase 4 \(v1\.x\): Quality of Life \| 3/3 \| Complete' .planning/ROADMAP.md` matches 1 line (Edit C)
    - `grep -E '^\| 4 \(v1\.x\)\. Quality of Life \| QOL-01, QOL-NEW-01 \| 2 \|' .planning/ROADMAP.md` matches 1 line (Edit D row insert)
    - `grep -E '\*\*Total v1\*\* \| \| \*\*41\*\*' .planning/ROADMAP.md` matches 1 line (Edit D total update)
    - `grep -q '04-00-staging-PLAN.md' .planning/ROADMAP.md` succeeds (Edit B plan list populated)
    - `grep -q '04-01-lua-core-PLAN.md' .planning/ROADMAP.md` succeeds
    - `grep -q '04-02-karabiner-docs-PLAN.md' .planning/ROADMAP.md` succeeds
    - `grep -q 'Phase 4 Quality of Life closed' .planning/ROADMAP.md` succeeds (Edit E footer note)
    - `bash tests/test_brand_consistency.sh; echo $?` exits 0 (no new voice-cc strings)
    - `bash tests/run_all.sh; echo $?` exits 0 (11/11 GREEN)
  </action>
  <verify>
    <automated>[ "$(grep -cE '^- \[x\] \*\*Phase 4 \(v1\.x\): Quality of Life\*\*' .planning/ROADMAP.md)" = "1" ] && [ "$(grep -cE '^\| 6 \| Phase 4 \(v1\.x\): Quality of Life \| 3/3 \| Complete' .planning/ROADMAP.md)" = "1" ] && [ "$(grep -cE '^\| 4 \(v1\.x\)\. Quality of Life \| QOL-01, QOL-NEW-01 \| 2 \|' .planning/ROADMAP.md)" = "1" ] && grep -qE '\*\*Total v1\*\* \| \| \*\*41\*\*' .planning/ROADMAP.md && grep -q '04-00-staging-PLAN.md' .planning/ROADMAP.md && grep -q '04-01-lua-core-PLAN.md' .planning/ROADMAP.md && grep -q '04-02-karabiner-docs-PLAN.md' .planning/ROADMAP.md && grep -q 'Phase 4 Quality of Life closed' .planning/ROADMAP.md && bash tests/test_brand_consistency.sh && bash tests/run_all.sh</automated>
  </verify>
  <acceptance_criteria>
    - Phase list checkbox (Edit A): `^- \[x\] \*\*Phase 4 \(v1\.x\): Quality of Life\*\*` matches 1 line; previous `- [ ]` form matches 0 lines
    - Phase Details plan list (Edit B): all three plan filenames present (04-00-staging-PLAN.md, 04-01-lua-core-PLAN.md, 04-02-karabiner-docs-PLAN.md), each with `[x]` marker
    - Phase Details "Plans:" header (Edit B): `**Plans:** 3 plans` present (3, not the placeholder 4); the `**Plans**: 4 plans` placeholder no longer appears
    - Progress table (Edit C): `| 6 | Phase 4 (v1.x): Quality of Life | 3/3 | Complete` matches 1 line; previous `0/0 | Queued` matches 0 lines for Phase 4
    - Coverage Summary insert (Edit D row): `| 4 (v1.x). Quality of Life | QOL-01, QOL-NEW-01 | 2 |` present
    - Coverage Summary total (Edit D total): `**Total v1** | | **41** (was 26 → 29 with BRD → 35 with SEC → 39 with HUD → 41 with QOL)` present; previous `**39**` total matches 0 lines
    - Footer (Edit E): `Phase 4 Quality of Life closed (3/3 plans` present in italics line; existing 2026-04-30 line preserved
    - Other phases (1, 2, 2.5, 2.7, 3.5, 3, 5) Progress table rows UNCHANGED
    - `bash tests/test_brand_consistency.sh; echo $?` exits 0 (no new voice-cc strings)
    - `bash tests/run_all.sh; echo $?` exits 0 (11/11 GREEN)
    - `bash tests/security/run_all.sh; echo $?` exits 0 (5/5 GREEN)
    - `! grep -q whisper-cli purplevoice-lua/init.lua` AND `[ "$(grep -c WHISPER_BIN purplevoice-record)" = "2" ]` (Pattern 2 invariants intact)
  </acceptance_criteria>
  <done>
    `.planning/ROADMAP.md`: Phase 4 row marked Complete (3/3 plans); Phase Details block has populated plan list; Progress table row updated; Coverage Summary table gets the new Phase 4 row + Total v1 bump (39 → 41); footer note appended. All other phases untouched. Lints + suites GREEN.
  </done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <name>Task 04-02-CHECKPOINT-1 (live walkthrough): tests/manual/test_f19_walkthrough.md sign-off (QOL-NEW-01 positive path)</name>
  <what-built>
    By this point in the plan, the following are in place:
    - `assets/karabiner-fn-to-f19.json` exists (Task 04-02-01)
    - `setup.sh` Step 9 detects Karabiner-Elements and prints OK + REMINDER on success (Task 04-02-02)
    - `purplevoice-lua/init.lua` has `hs.hotkey.bind({}, "f19", onPress, onRelease)` (Plan 04-01)
    - The cmd+shift+e binding is removed (Plan 04-01)
    - tests/manual/test_f19_walkthrough.md exists with 5-PASS scaffold (Plan 04-00)

    The walkthrough verifies the F19 push-to-talk loop end-to-end on Oliver's actual macOS Sequoia hardware with Karabiner-Elements installed + driver-extension granted + the rule imported and enabled.
  </what-built>
  <how-to-verify>
    1. **Karabiner-Elements installed:** Verify `/Applications/Karabiner-Elements.app` exists. If not, install per the README's new "Karabiner-Elements (required for the F19 hotkey)" subsection (download dmg, drag to /Applications, launch once, accept driver-extension grant in System Settings → Privacy & Security → "Allow software from Fumihiko Takayama").

    2. **Import the JSON rule:** Open Karabiner-Elements → Preferences → Complex Modifications → Add rule → Import rule from file → choose `assets/karabiner-fn-to-f19.json` from this repository. Click "Enable" next to "Hold fn → F19 (PurpleVoice push-to-talk)".

    3. **Reload Hammerspoon:** menubar → Reload Config. Confirm load alert reads `PurpleVoice loaded — F19 to record, ⌘⇧V to re-paste`.

    4. **Execute `tests/manual/test_f19_walkthrough.md` end-to-end:**
       - Step 2 (PASS-1): Hold fn for ~2 seconds in TextEdit, say "this is the F19 push-to-talk test", release. Verify transcript pastes.
       - Step 3 (PASS-2): Tap fn briefly (<200ms). Verify macOS native fn behaviour fires (Globe popup, dictation panel, OR function-key row — depends on Keyboard settings). Verify PurpleVoice does NOT begin recording.
       - Step 4 (PASS-3): Press cmd+shift+e. Verify nothing happens (no recording, no menubar change, no HUD pill). The cmd+shift+e binding was removed in Plan 04-01.
       - Step 5 (PASS-4): Open VS Code (or Cursor). Press cmd+shift+e. Verify the IDE's "Show Explorer" command opens normally — Hammerspoon no longer hijacks cmd+shift+e (the original collision is resolved).
       - Step 6 (PASS-5): Record 5 utterances back-to-back. Note any 200ms-tuning observations (false positives on quick taps OR perceived lag on intentional holds). If either is reported, document specifics in the Sign-off section so a follow-up can adjust the threshold by ± 50ms in `assets/karabiner-fn-to-f19.json`.

    5. **Sign off in `tests/manual/test_f19_walkthrough.md`:** Check the PASS-1 / PASS-2 / PASS-3 / PASS-4 / PASS-5 boxes; fill in Tester (Oliver) + Date + 200ms threshold notes (if any).

    6. **Reply with:** "approved — F19 walkthrough signed off; threshold notes: [none / adjusted to Xms]" OR "issues: [details]"

    Reference: RESEARCH.md Pitfall 1 (200ms tuning), Pitfall 3 (driver/extension grant — silent failure if user skips).
  </how-to-verify>
  <resume-signal>Reply "approved", "approved with threshold notes: ...", or describe issues</resume-signal>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <name>Task 04-02-CHECKPOINT-2 (live walkthrough): tests/manual/test_repaste_walkthrough.md sign-off (QOL-01 re-paste + nil-state)</name>
  <what-built>
    By this point:
    - The F19 trigger works (verified in Checkpoint 1)
    - `purplevoice-lua/init.lua` has `local lastTranscript = nil` at module scope (Plan 04-01)
    - `pasteWithRestore()` caches `lastTranscript = transcript` AFTER the cmd+v keystroke fires (Plan 04-01)
    - `hs.hotkey.bind({"cmd", "shift"}, "v", repaste)` binding exists with nil-check + brief alert (Plan 04-01)
    - tests/manual/test_repaste_walkthrough.md exists with 3-PASS scaffold (Plan 04-00)

    The walkthrough verifies the cmd+shift+v re-paste loop end-to-end including the post-reload nil-state alert.
  </what-built>
  <how-to-verify>
    1. **Hammerspoon loaded with Plan 04-01 + 04-02 changes** (load alert reads `PurpleVoice loaded — F19 to record, ⌘⇧V to re-paste`).

    2. **Execute `tests/manual/test_repaste_walkthrough.md` end-to-end:**
       - Step 2 (PASS-1 initial paste): Open TextEdit Document A. Hold fn ~2s, say "this is the first test transcript", release. Verify transcript pastes into Document A.
       - Step 5 (PASS-2 cross-app re-paste): Switch focus to Document B. Press cmd+shift+v. Verify "this is the first test transcript" pastes into Document B (proves QOL-01 cross-app re-paste from cached `lastTranscript`).
       - Step 8 (PASS-3 nil-state post-reload): Reload Hammerspoon (menubar → Reload Config). Wait for the load alert. Press cmd+shift+v WITHOUT recording anything new. Verify a brief alert appears: `PurpleVoice: nothing to re-paste yet` (~1.5s fade); no paste fires; no crash.
       - Optional Step 9: Open a `.md` file in VS Code or Cursor. Press cmd+shift+v. Verify re-paste fires (NOT VS Code's "Markdown Preview"). Note: the IDE's Markdown Preview is now hijacked while Hammerspoon is running — the README documents Cmd+K V as the workaround.

    3. **Sign off in `tests/manual/test_repaste_walkthrough.md`:** Check the PASS-1 / PASS-2 / PASS-3 boxes; fill in Tester (Oliver) + Date.

    4. **Reply with:** "approved — re-paste walkthrough signed off" OR "issues: [details]"

    Reference: CONTEXT.md D-02 (cmd+shift+v collision accepted), D-03 (in-memory only — lost on reload), D-04 (brief alert nil-state); RESEARCH.md Pattern 4 (cache point inside pasteWithRestore success path).
  </how-to-verify>
  <resume-signal>Reply "approved" or describe issues</resume-signal>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <name>Task 04-02-CHECKPOINT-3 (live walkthrough): tests/manual/test_setup_karabiner_missing.md sign-off (QOL-NEW-01 negative-control)</name>
  <what-built>
    By this point:
    - `setup.sh` Step 9 contains the actionable error block (Task 04-02-02) with 5-step install instructions + air-gap path
    - `setup.sh` Step 10 (relocated banner) only appears AFTER all checks pass
    - `assets/karabiner-fn-to-f19.json` exists (Task 04-02-01 — file-existence guard at top of Step 9 will pass)
    - tests/manual/test_setup_karabiner_missing.md exists with BASELINE-OK / PASS-1 / PASS-2 scaffold (Plan 04-00)

    The walkthrough verifies setup.sh's negative-control path (Karabiner missing → exit 1 + actionable error) on Oliver's actual machine. **REQUIRES sudo** to temporarily move /Applications/Karabiner-Elements.app aside; restore step is mandatory and documented.
  </what-built>
  <how-to-verify>
    1. **WARNING:** This walkthrough requires `sudo` to move a system .app aside. Restore step is mandatory; do NOT skip or your machine loses the F19 hotkey until you reinstall Karabiner.

    2. **Execute `tests/manual/test_setup_karabiner_missing.md` end-to-end:**
       - Step 1 (BASELINE-OK): Run `bash setup.sh` from the repo root. Verify exit 0; final banner (now "Step 10") prints `setup complete` AFTER `OK: Karabiner-Elements detected` + REMINDER.
       - Step 2: `sudo mv /Applications/Karabiner-Elements.app /tmp/Karabiner-Elements.app.parked`
       - Step 3: Verify `ls /Applications/Karabiner-Elements.app` reports "No such file or directory"; verify `ls -d /tmp/Karabiner-Elements.app.parked` shows the bundle.
       - Step 4-5 (PASS-1): Run `bash setup.sh; echo "EXIT=$?"`. Verify the multi-line actionable error to stderr containing:
         - `PurpleVoice: Karabiner-Elements is required for the F19 hotkey.`
         - URL `https://karabiner-elements.pqrs.org/`
         - 5-step numbered install procedure
         - Reference to `assets/karabiner-fn-to-f19.json`
         - Air-gap note: `If air-gapped: copy Karabiner-Elements.dmg from a connected machine via USB`
         - Final line: `EXIT=1`
         **CRITICAL:** Verify the final banner ("Step 10 setup complete") did NOT print BEFORE the Karabiner error. If banner appeared first, the Option A reorganisation in Task 04-02-02 was incomplete — file the issue.
       - Step 6: `sudo mv /tmp/Karabiner-Elements.app.parked /Applications/Karabiner-Elements.app`
       - Step 7: Verify `ls -d /Applications/Karabiner-Elements.app` shows the bundle; Karabiner menubar icon returns (may need to launch /Applications/Karabiner-Elements.app once if daemon was killed during the move).
       - Step 8-9 (PASS-2): Re-run `bash setup.sh; echo "EXIT=$?"`. Verify exit 0; Step 9 prints `OK: Karabiner-Elements detected` + REMINDER; final banner prints `setup complete`.

    3. **Sign off in `tests/manual/test_setup_karabiner_missing.md`:** Check the BASELINE-OK / PASS-1 / PASS-2 boxes; fill in Tester (Oliver) + Date.

    4. **Reply with:** "approved — setup-karabiner-missing walkthrough signed off; restore verified" OR "issues: [details]"

    Reference: CONTEXT.md D-07 (Document + check, refuse install complete), D-08 (PURPLEVOICE_OFFLINE compatible — same logic, air-gap path in error message), RESEARCH.md §5 Option A (banner is LAST step).
  </how-to-verify>
  <resume-signal>Reply "approved" (with restore confirmation) or describe issues</resume-signal>
</task>

<task type="auto">
  <name>Task 04-02-VERIFY: Final phase-gate verification — all suites + Pattern 2 invariants + brand/framing lints + walkthrough sign-offs</name>
  <read_first>
    - All 3 manual walkthrough files (test_f19_walkthrough.md, test_repaste_walkthrough.md, test_setup_karabiner_missing.md) — verify all PASS markers checked + Tester + Date filled in by Oliver via Checkpoints 1, 2, 3
    - tests/test_karabiner_check.sh (the contract this entire phase satisfies — 8 checks all GREEN)
    - tests/run_all.sh, tests/security/run_all.sh (the suite drivers)
    - tests/test_brand_consistency.sh, tests/test_security_md_framing.sh (the lints)
    - .planning/REQUIREMENTS.md (verify Task 04-02-06 closure flips landed)
    - .planning/ROADMAP.md (verify Task 04-02-07 closure flips landed)
  </read_first>
  <files>(no file modifications — verification-only task)</files>
  <action>
    Run the comprehensive phase-gate verification battery. This task makes NO file changes — it only runs commands and reports results. If any verification fails, the failure must be diagnosed and fixed in a follow-up task BEFORE the phase is declared closed.

    **Verification battery (run all 12 commands; collect exit codes; report PASS/FAIL summary):**

    ```bash
    # 1. Karabiner check — all 8 sub-checks GREEN (THE phase contract)
    bash tests/test_karabiner_check.sh; echo "test_karabiner_check exit: $?"  # MUST be 0
    
    # 2. Functional suite — 11/11 GREEN
    bash tests/run_all.sh; echo "run_all exit: $?"  # MUST be 0
    
    # 3. Security suite — 5/5 GREEN
    bash tests/security/run_all.sh; echo "security exit: $?"  # MUST be 0
    
    # 4. Brand consistency — no new voice-cc strings
    bash tests/test_brand_consistency.sh; echo "brand exit: $?"  # MUST be 0
    
    # 5. Framing lint — SECURITY.md additions kept neutral
    bash tests/test_security_md_framing.sh; echo "framing exit: $?"  # MUST be 0
    
    # 6. Pattern 2 invariant — purplevoice-record untouched
    [ "$(grep -c WHISPER_BIN purplevoice-record)" = "2" ] && echo "Pattern 2: PASS" || echo "Pattern 2: FAIL"
    
    # 7. Pattern 2 corollary — init.lua whisper-cli-free
    ! grep -q whisper-cli purplevoice-lua/init.lua && echo "Pattern 2 corollary: PASS" || echo "Pattern 2 corollary: FAIL"
    
    # 8. cmd+shift+e fully eradicated from manual tests
    ! grep -rq 'cmd+shift+e' tests/manual/ && echo "tests/manual/ cmd+shift+e: ABSENT (PASS)" || echo "tests/manual/ cmd+shift+e: PRESENT (FAIL)"
    
    # 9. cmd+shift+e absent from README
    [ "$(grep -c 'cmd+shift+e' README.md)" = "0" ] && echo "README cmd+shift+e: ABSENT (PASS)" || echo "README cmd+shift+e: PRESENT (FAIL)"
    
    # 10. cmd+shift+e absent from SECURITY.md
    [ "$(grep -c 'cmd+shift+e' SECURITY.md)" = "0" ] && echo "SECURITY.md cmd+shift+e: ABSENT (PASS)" || echo "SECURITY.md cmd+shift+e: PRESENT (FAIL)"
    
    # 11. cmd+shift+e absent from setup.sh banner
    [ "$(grep -c 'cmd+shift+e' setup.sh)" = "0" ] && echo "setup.sh cmd+shift+e: ABSENT (PASS)" || echo "setup.sh cmd+shift+e: PRESENT (FAIL)"
    
    # 12. REQUIREMENTS.md QOL-01 + QOL-NEW-01 marked Complete
    grep -E '^- \[x\] \*\*QOL-01\*\*:' .planning/REQUIREMENTS.md > /dev/null && \
    grep -E '^- \[x\] \*\*QOL-NEW-01\*\*:' .planning/REQUIREMENTS.md > /dev/null && \
    grep -E '^\| QOL-01 .*\| Complete \|' .planning/REQUIREMENTS.md > /dev/null && \
    grep -E '^\| QOL-NEW-01 .*\| Complete \|' .planning/REQUIREMENTS.md > /dev/null && \
      echo "REQUIREMENTS.md closure: PASS" || echo "REQUIREMENTS.md closure: FAIL"
    
    # 13. ROADMAP.md Phase 4 marked Complete
    grep -E '^\| 6 \| Phase 4 \(v1\.x\): Quality of Life \| 3/3 \| Complete' .planning/ROADMAP.md > /dev/null && \
    grep -E '^- \[x\] \*\*Phase 4 \(v1\.x\): Quality of Life\*\*' .planning/ROADMAP.md > /dev/null && \
      echo "ROADMAP.md closure: PASS" || echo "ROADMAP.md closure: FAIL"
    
    # 14. Manual walkthrough sign-offs present (look for the canonical "Tester:" non-blank pattern)
    for f in tests/manual/test_f19_walkthrough.md tests/manual/test_repaste_walkthrough.md tests/manual/test_setup_karabiner_missing.md; do
      if grep -qE '\*\*Tester:\*\* [^_]' "$f"; then
        echo "$f sign-off: PRESENT (PASS)"
      else
        echo "$f sign-off: MISSING — Tester field still has placeholder _____ (FAIL — return to Checkpoints 1/2/3)"
      fi
    done
    ```

    **PASS criteria for this task:** All 14 numbered checks (1-12 + 14 with 3 walkthroughs) report PASS / exit 0. If any FAIL, do NOT declare the phase closed — diagnose and route fix back to the appropriate task (e.g. cmd+shift+e leftover in tests/manual/ → return to Task 04-02-03 and re-sweep; sign-off missing → return to Checkpoint 1/2/3 and re-execute walkthrough).

    **DO NOT:**
    - Modify any file in this task — verification-only, no edits allowed.
    - Skip any of the 14 checks — they're cumulative; missing one risks shipping with a known broken invariant.
    - Auto-approve checkpoints — Checkpoints 1, 2, 3 must have actual Tester/Date entries from Oliver, not placeholders.
    - Mark the phase complete if even ONE walkthrough has unfilled Tester/Date — return the user to the appropriate Checkpoint task.

    Report results in a clean summary table at the end of execution: `| Check | Result | Notes |`. Total: 14 rows. If all PASS, declare "Phase 4 verification complete — ready for /gsd:verify-work or commit". If any FAIL, list the failures with diagnostic hints + the task to return to.
  </action>
  <verify>
    <automated>bash tests/test_karabiner_check.sh && bash tests/run_all.sh && bash tests/security/run_all.sh && bash tests/test_brand_consistency.sh && bash tests/test_security_md_framing.sh && [ "$(grep -c WHISPER_BIN purplevoice-record)" = "2" ] && ! grep -q whisper-cli purplevoice-lua/init.lua && ! grep -rq 'cmd+shift+e' tests/manual/ && [ "$(grep -c 'cmd+shift+e' README.md)" = "0" ] && [ "$(grep -c 'cmd+shift+e' SECURITY.md)" = "0" ] && [ "$(grep -c 'cmd+shift+e' setup.sh)" = "0" ] && grep -qE '^- \[x\] \*\*QOL-01\*\*:' .planning/REQUIREMENTS.md && grep -qE '^- \[x\] \*\*QOL-NEW-01\*\*:' .planning/REQUIREMENTS.md && grep -qE '^\| QOL-01 .*\| Complete \|' .planning/REQUIREMENTS.md && grep -qE '^\| QOL-NEW-01 .*\| Complete \|' .planning/REQUIREMENTS.md && grep -qE '^\| 6 \| Phase 4 \(v1\.x\): Quality of Life \| 3/3 \| Complete' .planning/ROADMAP.md && grep -qE '^- \[x\] \*\*Phase 4 \(v1\.x\): Quality of Life\*\*' .planning/ROADMAP.md</automated>
  </verify>
  <acceptance_criteria>
    - `bash tests/test_karabiner_check.sh; echo $?` exits 0 (8/8 GREEN — the phase contract)
    - `bash tests/run_all.sh; echo $?` exits 0 (11/11 GREEN — full functional suite)
    - `bash tests/security/run_all.sh; echo $?` exits 0 (5/5 GREEN — security suite untouched)
    - `bash tests/test_brand_consistency.sh; echo $?` exits 0 (no new voice-cc strings)
    - `bash tests/test_security_md_framing.sh; echo $?` exits 0 (framing intact)
    - Pattern 2 invariant: `[ "$(grep -c WHISPER_BIN purplevoice-record)" = "2" ]` succeeds
    - Pattern 2 corollary: `! grep -q whisper-cli purplevoice-lua/init.lua` succeeds
    - `! grep -rq 'cmd+shift+e' tests/manual/` succeeds (zero matches across manual test corpus)
    - `[ "$(grep -c 'cmd+shift+e' README.md)" = "0" ]` succeeds (README clean)
    - `[ "$(grep -c 'cmd+shift+e' SECURITY.md)" = "0" ]` succeeds (SECURITY.md clean)
    - `[ "$(grep -c 'cmd+shift+e' setup.sh)" = "0" ]` succeeds (setup.sh banner clean)
    - REQUIREMENTS.md QOL-01 + QOL-NEW-01 marked Complete in BOTH v1 subsection AND traceability table
    - ROADMAP.md Phase 4 row marked Complete with 3/3 plans
    - All 3 manual walkthrough files (test_f19_walkthrough.md, test_repaste_walkthrough.md, test_setup_karabiner_missing.md) have actual Tester names + Dates filled in (NOT the `_____________` placeholder)
    - The verification report summary table prints clean — all 14 rows show PASS
  </acceptance_criteria>
  <done>
    Phase 4 fully verified. All suites GREEN (11/0 functional + 5/0 security + brand + framing). All Pattern 2 invariants intact. Zero cmd+shift+e references anywhere in user-facing surfaces (README, SECURITY.md, setup.sh, tests/manual/). REQUIREMENTS.md + ROADMAP.md reflect closure. All 3 live walkthroughs signed off by Oliver. Phase ready for `/gsd:verify-work 4` or final commit.
  </done>
</task>

</tasks>

<verification>
After all 11 tasks (7 autonomous + 3 checkpoints + 1 verify) complete:

```bash
# 1. The 8-check phase contract — final state 8/8 GREEN
bash tests/test_karabiner_check.sh; echo "test_karabiner_check exit: $?"  # MUST be 0

# 2. Full functional suite — 11/11 GREEN
bash tests/run_all.sh; echo "run_all exit: $?"  # MUST be 0

# 3. Security suite — 5/5 GREEN (untouched by Phase 4)
bash tests/security/run_all.sh; echo "security exit: $?"  # MUST be 0

# 4. Brand + framing lints
bash tests/test_brand_consistency.sh; echo "brand: $?"  # MUST be 0
bash tests/test_security_md_framing.sh; echo "framing: $?"  # MUST be 0

# 5. Pattern 2 invariants intact
test "$(grep -c WHISPER_BIN purplevoice-record)" = "2"
! grep -q whisper-cli purplevoice-lua/init.lua

# 6. cmd+shift+e fully eradicated from user-facing surfaces
! grep -rq 'cmd+shift+e' tests/manual/
[ "$(grep -c 'cmd+shift+e' README.md)" = "0" ]
[ "$(grep -c 'cmd+shift+e' SECURITY.md)" = "0" ]
[ "$(grep -c 'cmd+shift+e' setup.sh)" = "0" ]

# 7. New JSON file exists + parses + has correct structure
test -f assets/karabiner-fn-to-f19.json
jq empty assets/karabiner-fn-to-f19.json
[ "$(jq -r '.rules[0].manipulators[0].from.key_code' assets/karabiner-fn-to-f19.json)" = "fn" ]
[ "$(jq -r '.rules[0].manipulators[0].to_if_held_down[0].key_code' assets/karabiner-fn-to-f19.json)" = "f19" ]

# 8. setup.sh Step 9 + Option A reorg present
grep -q 'Step 9: Karabiner-Elements check' setup.sh
grep -q 'Step 10: Next-step reminders' setup.sh
grep -q '/Applications/Karabiner-Elements.app' setup.sh

# 9. README + SECURITY.md updates
grep -q 'Karabiner-Elements (required for the F19 hotkey)' README.md
grep -q 'karabiner-fn-to-f19.json' README.md
grep -q 'Cmd+K V' README.md
grep -q 'kernel-extension-class daemon' SECURITY.md
grep -q 'Karabiner-Elements' SECURITY.md

# 10. REQUIREMENTS.md + ROADMAP.md closure
grep -qE '^- \[x\] \*\*QOL-01\*\*:' .planning/REQUIREMENTS.md
grep -qE '^- \[x\] \*\*QOL-NEW-01\*\*:' .planning/REQUIREMENTS.md
grep -qE '^\| 6 \| Phase 4 \(v1\.x\): Quality of Life \| 3/3 \| Complete' .planning/ROADMAP.md

# 11. All 3 walkthrough sign-offs present (look for non-placeholder Tester field)
for f in tests/manual/test_f19_walkthrough.md tests/manual/test_repaste_walkthrough.md tests/manual/test_setup_karabiner_missing.md; do
  grep -qE '\*\*Tester:\*\* [^_]' "$f" && echo "$f: signed off" || echo "$f: NOT SIGNED OFF — return to checkpoint"
done
```

Expected end state: 11/0 functional, 5/0 security, brand+framing GREEN; Pattern 2 invariants intact; zero cmd+shift+e references in user-facing surfaces; assets/karabiner-fn-to-f19.json valid + structurally correct; setup.sh has Step 9 with Option A banner-last reorg; README + SECURITY.md fully updated; REQUIREMENTS.md + ROADMAP.md reflect Phase 4 closure; all 3 walkthroughs signed off live.
</verification>

<success_criteria>
- All 7 autonomous task `<acceptance_criteria>` blocks satisfied (Tasks 04-02-01 through 04-02-07)
- All 3 `checkpoint:human-verify` tasks received "approved" sign-off from Oliver with PASS markers checked + Tester + Date filled in their respective walkthrough files
- Task 04-02-VERIFY all 14 verification checks PASS
- `assets/karabiner-fn-to-f19.json` exists with verbatim RESEARCH §4 content; jq-validates as the contract requires
- `setup.sh` has Step 9 (Karabiner check) inserted between Step 8 SBOM regen and the relocated Step 10 banner; banner cmd+shift+e line replaced with F19 + cmd+shift+v bullets
- 12 legacy manual walkthroughs swept cmd+shift+e → F19 / "fn (held)"; the 3 Phase-4-native walkthroughs untouched
- `README.md` Hotkey section replaced with F19 + cmd+shift+v + Cmd+K V workaround; new Karabiner-Elements subsection under Setup
- `SECURITY.md` TL;DR + Scope updated to F19; SBOM scope disclaimer prepends Karabiner-Elements as carried-by-reference runtime dep
- `.planning/REQUIREMENTS.md` QOL-01 + QOL-NEW-01 flipped to `[x] Complete` in both v1 subsection and Traceability table; per-phase counts row updated; closure footer note appended
- `.planning/ROADMAP.md` Phase 4 row → Complete (3/3 plans); Phase Details plan list populated; Coverage Summary gets new Phase 4 row + Total v1 bumped 39 → 41
- Zero `cmd+shift+e` references remain in setup.sh, README.md, SECURITY.md, tests/manual/
- `bash tests/test_karabiner_check.sh` exits 0 (8/8 GREEN — the phase contract fulfilled)
- `bash tests/run_all.sh` reports 11/0 GREEN; `bash tests/security/run_all.sh` reports 5/0 GREEN
- Pattern 2 invariants intact: `grep -c WHISPER_BIN purplevoice-record == 2` AND `! grep -q whisper-cli purplevoice-lua/init.lua`
- Brand consistency lint GREEN; framing lint GREEN
- All 3 walkthrough sign-offs (test_f19_walkthrough.md, test_repaste_walkthrough.md, test_setup_karabiner_missing.md) have actual Tester + Date entries (not `_____________` placeholders)
</success_criteria>

<output>
After completion, create `.planning/phases/04-quality-of-life-v1-x/04-02-SUMMARY.md` covering:
- 7 autonomous task outcomes (each with file path + lines added/replaced + verification result)
- 3 checkpoint outcomes (one per walkthrough — sign-off date + PASS markers checked + any 200ms tuning notes from F19 walkthrough Pitfall 1 anchor)
- 1 phase-gate verification outcome (the 14-check report from Task 04-02-VERIFY)
- The complete state of test_karabiner_check.sh after this plan: 8/8 GREEN (Plan 04-01 took it from 0/8 to 3/8 GREEN; Plan 04-02 took it from 3/8 to 8/8)
- Suite state: 11/0 functional, 5/0 security, brand + framing GREEN
- Pattern 2 invariants verified intact
- All cmd+shift+e references eradicated from user-facing surfaces (README, SECURITY.md, setup.sh, tests/manual/) — confirmed via grep counts
- REQUIREMENTS.md + ROADMAP.md closure verified
- Any deviations (Rule 1 auto-fixes) recorded with root cause + same-pattern reference
- Confirmation Phase 4 is ready for `/gsd:verify-work 4` (Sonnet sign-off) or direct close
- Handoff note: "Phase 4 (v1.x) Quality of Life is COMPLETE. F19 push-to-talk via Karabiner replaces cmd+shift+e (eliminates the VS Code/Cursor 'Show Explorer' collision). cmd+shift+v re-pastes the last successful transcript (in-memory only; lost on Hammerspoon reload by design). Karabiner-Elements is now a documented runtime dependency surfaced in setup.sh Step 9 + README + SECURITY.md SBOM scope. Next phase per ROADMAP execution order: Phase 3 (Distribution & Benchmarking + Public Install) — final v1 polish step."
</output>

## PLANNING COMPLETE
