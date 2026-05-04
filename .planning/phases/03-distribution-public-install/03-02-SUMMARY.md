---
phase: 03-distribution-public-install
plan: 02
subsystem: distribution
tags: [mit-license, uninstall-idempotent, readme-d11-d12, dst-03, walkthrough-signed-off]
status: complete

# Dependency graph
requires:
  - phase: 03-distribution-public-install
    plan: 00
    provides: Wave 0 RED tests (test_license_present.sh, test_uninstall_dryrun.sh) + manual walkthrough scaffold (tests/manual/test_readme_recovery_walkthrough.md)
  - phase: 03-distribution-public-install
    plan: 01
    provides: install.sh (renamed from setup.sh) + Step 0 curl-vs-clone detection + bootstrap_clone_then_re_exec + brand-consistency exemption pattern (.claude/ + install.sh exemptions) — the foundation Plan 03-02 builds README quickstart + recovery flow on top of
  - phase: 02.5-branding
    provides: Pattern 2 invariant discipline (purplevoice-record / init.lua untouched) + brand consistency exemption pattern + README header format (icon + tagline + audience list)
  - phase: 02.7-security-posture
    provides: SECURITY.md authority for README's ## Security & Privacy linkages + framing-lint discipline ("compatible with" not "compliant")
provides:
  - LICENSE at repo root (canonical MIT, Year=2026, Holder=Oliver Allen) — turns Wave-0 test_license_present.sh GREEN; auto-pickup by GitHub licensee for the public-flip License sidebar
  - uninstall.sh at repo root (mode 0755, idempotent, safe-by-default) — turns Wave-0 test_uninstall_dryrun.sh GREEN; removes 5 surfaces (3 XDG dirs + 2 symlinks); prints 4-item manual-cleanup banner
  - tests/test_brand_consistency.sh exemption row for uninstall.sh (legitimate `*purplevoice*|*voice-cc*` symlink-target case-pattern)
  - SBOM.spdx.json regenerated post-Wave-2 (mirrors Plan 03-01 f8cebb3 pre-walkthrough fix)
  - README.md rewritten per D-11/D-12 — Quickstart-top + Detailed-Install + 4-item Recovery (TCC reset + Karabiner troubleshoot incl. UK-vs-US gotcha + "I lost my hotkeys" 5-step + uninstall.sh full reset) + Uninstalling subsection
  - DST-03 walkthrough signed off live by Oliver 2026-05-04 — all 4 items PASS (commit e8bd7bf); README diagnostic flow validated end-to-end on Oliver's machine
affects: [03-03-PLAN, 03-04-PLAN]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "LICENSE-at-repo-root pattern for first-tier GitHub License sidebar auto-detection (GitHub's licensee tool picks LICENSE / LICENSE.md / LICENSE.txt)"
    - "Idempotent uninstall.sh structure mirrors install.sh's idempotent-step pattern: each removal is conditional on presence; re-runs print 'Already absent: <path>' and exit 0"
    - "Safe-by-default uninstall: no `read -p` confirms (consent is implicit per RESEARCH §Pattern 7); no auto-uninstall of brew packages or Karabiner rule files (those may serve other tools); no auto-edit of ~/.hammerspoon/init.lua require() line (DST-02 discipline mirrors install.sh — print, never auto-modify user config)"
    - "README D-11/D-12 structure: Quickstart-at-top (curl one-liner) → Hotkey → Performance → Detailed Install (Karabiner + Permissions + Recovery + Uninstalling) → Security & Privacy → identity/layout/why → Status (trimmed to summary + ROADMAP link)"
    - "Pre-walkthrough SBOM regen-and-commit pattern: re-running install.sh post-deliverable-commits shifts documentNamespace + versionInfo to current HEAD; commit the result so the walkthrough's install.sh runs are byte-equivalent (modulo BACKLOG#1 1-commit-stale shift). Plan 03-01 f8cebb3 precedent."

key-files:
  created:
    - LICENSE
    - uninstall.sh
  modified:
    - README.md  # full rewrite per D-11/D-12
    - SBOM.spdx.json  # regenerated post-Wave-2 (commit 026c247) — documentNamespace shifted b52606b → 98c0018
    - tests/test_brand_consistency.sh  # added uninstall.sh exemption row (code line + comment block)

key-decisions:
  - "Plan task 2-1 'commit any resulting SBOM.spdx.json change in the same commit as the LICENSE add' executed: LICENSE commit (c347ea8) includes the 1-commit-shift SBOM regen output. Decision rationale: matches plan prose exactly; post-commit phantom diff is the known BACKLOG#1 deferred-structural issue, not a Plan 03-02 deliverable defect."
  - "Syft did NOT auto-promote licenseDeclared from NOASSERTION to MIT after LICENSE landed at repo root. Syft's directory-scan source ('PurpleVoice' synthetic root package) does not pick up top-level LICENSE files in the version Plan 03-01 installed (1.43.0). GitHub's licensee tool (separate path) WILL still detect LICENSE for the public-repo sidebar at flip time. No code change required — plan §Behavior already qualified this with 'Syft may have already had the license metadata' and 'GitHub will auto-detect this as MIT'."
  - "Brand-consistency exemption added unconditionally per plan task 2-2 step 4. uninstall.sh's `case TARGET in *purplevoice*|*voice-cc*) ... ;; esac` symlink-target pattern is required for upgrade-path cleanup (users who installed under the working name 'voice-cc' get their stale symlinks removed); without exemption, the legitimate `voice-cc` literal trips test_brand_consistency.sh's grep. Same exemption class as install.sh's migrate_xdg_dir FROM-arg literals."
  - "Final pre-walkthrough SBOM commit (026c247) mirrors Plan 03-01 f8cebb3 lesson: SBOM is a derived artifact synchronised by install.sh — re-derive after any commit that shifts repo HEAD or changes install.sh's annotator/namespace inputs. This minimises phantom-diff during the live walkthrough's `bash uninstall.sh && bash install.sh` sequence."
  - "README ## Status section trimmed from per-phase progress table to 3-line summary + ROADMAP link per RESEARCH §Pattern 8 recommendation. Maintenance burden reduced; institutional readers get the 'this is engineered, not a hack' signal via ROADMAP.md without README staleness risk."
  - "README ## Performance table populated with placeholder rows (`_filled by Plan 03-03_`) so the section's structure ships now; Plan 03-03 will replace placeholders with real hyperfine numbers + the Phase-5 trigger evaluation."

patterns-established:
  - "When a new file at repo root has a legitimate brand-name reference (case-pattern, migration logic, etc.), add the brand-consistency exemption UNCONDITIONALLY in the same commit as the file. Same class as install.sh's migrate_xdg_dir exemption from Phase 2.5 / 03-01."
  - "Pre-walkthrough SBOM regen-and-commit before checkpoint return is now a phase-3 plan-template pattern (Plan 03-01 surfaced it as deviation D-01; Plan 03-02 bakes it in as the final pre-walkthrough commit)."
  - "Plan-prose-vs-implementation discipline: when the plan's Behavior block says 'X may auto-update Y' and the live behavior shows X did not auto-update Y, document the discrepancy as a key-decision in SUMMARY (not a deviation — the plan's hedge language anticipated it). Treats 'Syft may have already had the license metadata' as the prose hedge it actually was."

requirements-completed: [DST-03]

# Metrics
duration: ~3 days wall-clock (commits 2026-05-01 → walkthrough sign-off 2026-05-04)
completed: 2026-05-04
---

# Phase 3 Plan 02: LICENSE + uninstall.sh + README D-11/D-12 Rewrite Summary

**Wave 2 deliverables landed via 4 pre-walkthrough commits (c347ea8 LICENSE / d18a02d uninstall.sh + brand-exemption / 98c0018 README rewrite / 026c247 pre-walkthrough SBOM regen) + walkthrough sign-off commit (e8bd7bf, 2026-05-04). Functional suite 14 PASS / 2 FAIL → 16 PASS / 0 FAIL; security suite 5/0 unchanged; brand + framing lints GREEN; Pattern 2 invariant intact. DST-03 README recovery walkthrough signed off live by Oliver — all 4 items PASS (TCC reset, Karabiner Event Viewer, "I lost my hotkeys" 5-step, uninstall.sh + reinstall destructive run). Plans 03-03..04 unblocked.**

## What was built

### 1. LICENSE (canonical MIT)

`LICENSE` at repo root, 21 lines, verbatim from opensource.org/license/mit with the only substitutions being:
- Year = `2026`
- Copyright Holder = `Oliver Allen`
- ASCII `(c)` (per RESEARCH §"MIT LICENSE canonical text" — not Unicode `©`)

Required canonical phrases all present (asserted by test_license_present.sh):
- `MIT License`
- `Copyright (c) 2026 Oliver Allen`
- `Permission is hereby granted`
- `THE SOFTWARE IS PROVIDED "AS IS"`

GitHub's licensee tool will auto-detect this as MIT after the public flip (LICENSE / LICENSE.md / LICENSE.txt — first-tier auto-pickup per github/licensee). Syft's directory-scan source did NOT auto-promote `licenseDeclared` from `NOASSERTION` to `MIT` for the synthetic `DocumentRoot-Directory-PurpleVoice` package — recorded as a key-decision in frontmatter.

### 2. uninstall.sh (idempotent XDG removal + manual-cleanup banner)

`uninstall.sh` at repo root, mode 0755, 116 lines. Verbatim from RESEARCH §Pattern 7 with one inline-comment addition acknowledging the curl|bash clone-dir distinction (`~/.local/share/purplevoice/src/` IS removed; a working repo clone like `~/dev/purplevoice/` is NOT touched).

**Removes (5 surfaces, all 5 verified by sandbox unit test):**

| # | Surface | Type | Removal idiom |
|---|---------|------|---------------|
| 1 | `~/.config/purplevoice/` | XDG dir | `rm -rf` if `[ -d ]` |
| 2 | `~/.cache/purplevoice/` | XDG dir | `rm -rf` if `[ -d ]` |
| 3 | `~/.local/share/purplevoice/` | XDG dir (incl. curl|bash clone destination at `src/`) | `rm -rf` if `[ -d ]` |
| 4 | `~/.local/bin/purplevoice-record` | symlink | `rm` if `[ -L ]` AND target matches `*purplevoice*|*voice-cc*` |
| 5 | `~/.hammerspoon/purplevoice` | symlink OR dir | `rm` if `[ -L ]`; `rm -rf` if `[ -d ]` |

**Does NOT remove (per CONTEXT D-12 + Claude's Discretion):**
- Hammerspoon, sox, whisper-cpp, Karabiner-Elements binaries (may serve other tools)
- Karabiner rule JSONs in `~/.config/karabiner/` (user-owned)
- Hammerspoon's `~/.hammerspoon/init.lua` `require("purplevoice")` line
- TCC permissions for Hammerspoon

**Final banner prints 4 manual-cleanup items:**
1. Remove `require("purplevoice")` from init.lua
2. Disable Karabiner rules (toggle off in Preferences → Complex Modifications)
3. Optional: `brew uninstall hammerspoon sox whisper-cpp`
4. Optional: `tccutil reset Microphone/Accessibility org.hammerspoon.Hammerspoon`

**Safety properties:**
- `set -uo pipefail` (intentionally NOT `-e` — graceful rm-not-found semantics)
- No `read -p` confirms (consent is implicit per Plan 03-02 RESEARCH §Pattern 7)
- Symlink target check (`*purplevoice*|*voice-cc*`) prevents accidental removal of unrelated symlinks at the same path
- File-not-symlink defensive branch for `~/.local/bin/purplevoice-record` (`elif [ -e "$PV_BIN" ]` warns rather than removes)
- Idempotent: re-runs print "Already absent: <path>" for each surface, exit 0

**Brand-consistency exemption:** `uninstall.sh` added to `tests/test_brand_consistency.sh` exemption list (legitimate `voice-cc` symlink-target literal in `case TARGET in *purplevoice*|*voice-cc*)` upgrade-path cleanup pattern; same exemption class as install.sh's migrate_xdg_dir).

### 3. README.md rewrite per D-11/D-12

Restructured per Phase 3 CONTEXT D-11 (quickstart-first) and D-12 (4-item recovery section).

**Section ordering:**

```
# PurpleVoice
[tagline + icon + 1-paragraph what-it-is]

## Who this is for
[6-bullet audience list — preserved verbatim]

## Quickstart                                  ← NEW (D-11 quickstart-top)
[curl one-liner + 3-line "now hold fn / hold backtick"]

## Hotkey
[F19 + backtick + supersession note — preserved]

## Performance                                 ← NEW (placeholder for Plan 03-03)
[3-row p50/p95 table + Phase-5 trigger threshold + BENCHMARK.md link]

## Detailed Install                            ← NEW H2 wrapping the install detail
  ### Karabiner-Elements (required)            ← preserved + extended (BOTH JSONs)
  ### Permissions                              ← preserved
  ### Conflicting macOS feature                ← preserved
  ### Recovery                                 ← NEW (D-12 4-item triage)
    #### 1. TCC reset
    #### 2. Karabiner rule troubleshoot         (UK vs ANSI gotcha)
    #### 3. "I lost my hotkeys" — 5-step triage
    #### 4. uninstall.sh (full reset)
  ### Uninstalling                             ← NEW

## Security & Privacy
[audience entry-points + verify suite + sudo note + air-gap install (setup.sh → install.sh) + SBOM mention + reporting + HUD subsection — preserved with install.sh sweep]

## Visual identity
## Project layout                              ← UPDATED (install.sh + uninstall.sh + LICENSE + BENCHMARK.md + SBOM.spdx.json + both Karabiner JSONs)

## Status                                      ← TRIMMED (3-line summary + ROADMAP link, per RESEARCH §Pattern 8)

## Why "PurpleVoice"
```

**Quickstart curl one-liner (verbatim):**

```bash
curl -fsSL https://raw.githubusercontent.com/OliverGAllen/purplevoice/main/install.sh | bash
```

Points at the production URL post-Plan-03-04 public flip. No vanity domain (deferred per CONTEXT.md §Deferred).

**Recovery 4-item triage (D-12 verbatim coverage):**

| # | Item | Verbatim coverage |
|---|------|-------------------|
| 1 | TCC reset | 4-line bash block (tccutil Microphone + Accessibility + osascript quit + open) + "re-grant when prompted" |
| 2 | Karabiner rule troubleshoot | Event Viewer location + F19/F18 event flow + UK-vs-US `non_us_backslash` ↔ `grave_accent_and_tilde` gotcha |
| 3 | "I lost my hotkeys" — 5-step triage | (1) Reload Hammerspoon → (2) Karabiner menubar icon → (3) both rules enabled → (4) Event Viewer key codes → (5) Hammerspoon console binding-failed alerts (incl. Carbon RegisterEventHotKey collision reference to Phase 4 D-02 SUPERSEDED) |
| 4 | uninstall.sh (full reset) | `bash uninstall.sh && bash install.sh` recipe + link to ## Uninstalling for what's removed/preserved |

**vocab.txt preserve recipe** included in ## Uninstalling per RESEARCH §Pattern 7:

```bash
cp ~/.config/purplevoice/vocab.txt /tmp/my-vocab.txt
bash uninstall.sh
```

### 4. Pre-walkthrough SBOM regeneration (commit 026c247)

Mirrors Plan 03-01's f8cebb3 fix: post-deliverable re-run of install.sh shifted SBOM `documentNamespace` + `versionInfo` to current HEAD (98c0018). Committed so the README walkthrough's `bash uninstall.sh && bash install.sh` recovery item 4 doesn't surface a phantom git diff. Walkthrough criterion-style "SBOM zero git diff post-commit" remains BACKLOG#1 deferred-structural — running install.sh after THIS commit produces a 1-commit shift to the metadata commit's HEAD (the same circular reference Plan 03-01 surfaced as D-02; documented in `.planning/BACKLOG.md` item 1).

## Suite state at plan close (post-walkthrough — TBD)

| Suite | Result | Notes |
|-------|--------|-------|
| `bash tests/run_all.sh` | **16 PASS / 0 FAIL** | EXACT plan target. The 2 Wave-0 RED tests (test_uninstall_dryrun.sh + test_license_present.sh) BOTH turn GREEN as designed. |
| `bash tests/security/run_all.sh` | **5 PASS / 0 FAIL** | Unchanged baseline; verify_sbom.sh + verify_air_gap.sh + verify_egress.sh + verify_signing.sh + verify_reproducibility.sh all pass. |
| `bash tests/test_brand_consistency.sh` | PASS | uninstall.sh exemption added; .claude/ + install.sh + uninstall.sh + CLAUDE.md + README.md + 2 self-references all exempt. |
| `bash tests/test_security_md_framing.sh` | PASS | Plan 03-02 does not touch SECURITY.md; sanity check only. |
| Pattern 2 invariant | INTACT | `grep -c WHISPER_BIN purplevoice-record == 2`; `! grep -q whisper-cli purplevoice-lua/init.lua`. |

## Deviations from Plan

### Pre-walkthrough deviations

**(none yet — plan executed verbatim through Tasks 2-1 / 2-2 / 2-3 with one key-decision recorded per task)**

This section will be expanded by the continuation agent if any deviations surface during the live walkthrough on Oliver's machine.

### Walkthrough-surfaced deviations

**(none — walkthrough surfaced 4 informational findings, all of which the README diagnostic flow correctly handles. No README, uninstall.sh, or LICENSE edits required post-walkthrough.)**

Findings (recorded in `tests/manual/test_readme_recovery_walkthrough.md` § Live findings):

1. **Post-TCC-reset F18 half-bound state.** After Item 1 (TCC reset + Hammerspoon relaunch), F19 push-to-talk worked once Mic + Accessibility re-grant prompts fired and were granted, but F18 backtick re-paste was silent until a separate Reload Config (menubar → Hammerspoon → Reload Config). Plausible cause: init.lua loaded before Accessibility was granted; F19 path picks up the grant on first push-to-talk via natural rebind, but F18 binding requires a fresh init.lua load. README Item 3 ("I lost my hotkeys") Step 1 (Reload Hammerspoon) catches this exact symptom — diagnostic flow validated in real life. **No README fix needed.**

2. **HUD env var change recipe verified.** `osascript -e 'tell application "Hammerspoon" to quit'` followed by `PURPLEVOICE_HUD_POSITION=top-right open -a Hammerspoon` successfully repositioned the HUD; confirms the README §HUD privacy table's "fully quit Hammerspoon and relaunch from a shell that already has the env var set" recipe is accurate. Env var persisted across the install.sh module-symlink rotation in Item 4 (Hammerspoon process stayed alive — Reload Config sufficient post-reinstall).

3. **vocab.txt loss confirms README preserve recipe is load-bearing.** Item 4's destructive uninstall removed `~/.config/purplevoice/vocab.txt`; install.sh re-seeded a fresh default. README's `### Uninstalling` `cp ~/.config/purplevoice/vocab.txt /tmp/my-vocab.txt` recipe is accurate and necessary for users with edited vocab. **No README fix needed; recipe already prominent.**

4. **install.sh Step 9 Karabiner check passed without re-import after destructive uninstall.** Karabiner-Elements rules (PurpleVoice — fn → F19 + PurpleVoice — backtick → F18) survived the uninstall — uninstall.sh correctly does NOT touch `~/.config/karabiner/` or Karabiner Preferences. Reinstall picked up the existing rules cleanly. Validates the uninstall.sh "Does NOT remove" contract.

### Walkthrough commands run by orchestrator on Oliver's machine

| Command | Item | Outcome |
|---------|------|---------|
| `tccutil reset Microphone org.hammerspoon.Hammerspoon` + Accessibility variant + osascript quit + open -a Hammerspoon | Item 1 | All 4 commands ran exactly as documented; Mic + Accessibility re-grant prompts fired on first push-to-talk; F19 restored. |
| `osascript -e 'tell application "Hammerspoon" to quit'` + `PURPLEVOICE_HUD_POSITION=top-right open -a Hammerspoon` | (config tweak surfaced mid-walkthrough — not part of DST-03 sign-off scope but exercises the README §HUD env var recipe) | First attempt hit transient `_LSOpenURLsWithCompletionHandler` error -600 (LaunchServices race between osascript-quit and open-a-relaunch); retry of `open -a` resolved. PID 26587 confirmed running with new env. **Worth noting in README §HUD section as a known transient — but low-priority since the natural workaround is the same as the error recovery (just retry `open -a`).** |
| `bash uninstall.sh` | Item 4 (destructive uninstall) | Exit 0; 5 surfaces removed exactly per documented contract; manual-cleanup banner printed verbatim. |
| `bash install.sh` (from local clone) | Item 4 (reinstall) | Exit 0; ~488MB ggml-small.en.bin re-downloaded with SHA256 verification (~27s); Silero VAD downloaded; symlinks recreated; SBOM regenerated; Karabiner-Elements detected at Step 9 (existing rules picked up cleanly). |

## Authentication gates

None — no auth flows in scope for this plan.

## Plan 03-03 unblock signal

Plan 03-03 (hyperfine benchmarks + BENCHMARK.md + DST-04 walkthrough) is now unblocked:
- README ## Performance section ships with placeholder hyperfine table + Phase-5 trigger threshold; Plan 03-03 fills the numbers.
- BENCHMARK.md does not yet exist (Plan 03-03 creates).
- tests/benchmark/ contains HOW-TO-REGENERATE.md only (Plan 03-03 adds 2s.wav / 5s.wav / 10s.wav reference WAVs + run.sh + quantiles.sh).

## Self-Check

| Plan success criterion | Status | Evidence |
|---|---|---|
| 1. LICENSE exists at repo root with canonical MIT text + correct copyright | PASS | `LICENSE` file at repo root since c347ea8; verified by `tests/test_license_present.sh` GREEN |
| 2. uninstall.sh exists at repo root, idempotent in sandbox, manual-cleanup banner printed | PASS | `uninstall.sh` mode 0755 since d18a02d; `tests/test_uninstall_dryrun.sh` GREEN; live walkthrough Item 4 confirmed all 5 surfaces removed + 4-item banner printed verbatim |
| 3. README has Quickstart at top + Detailed Install + 4-item Recovery + Uninstalling subsection | PASS | `## Quickstart` (top), `## Detailed Install` H2 wrapping Karabiner / Permissions / Conflicting feature / `### Recovery` (4 items) / `### Uninstalling` — all present; walkthrough Items 1-4 PASS |
| 4. README quickstart curl one-liner uses production URL | PASS | `curl -fsSL https://raw.githubusercontent.com/OliverGAllen/purplevoice/main/install.sh \| bash` present; awaits Plan 03-04 public-flip live test |
| 5. Functional suite: 16 PASS / 0 FAIL | PASS | Wave-0 RED tests (test_uninstall_dryrun.sh + test_license_present.sh) both GREEN post-Wave-2 deliverables; verified at commit-time |
| 6. Security suite: 5 PASS / 0 FAIL | PASS | Plan 03-02 doesn't touch security surface; baseline 5/0 unchanged |
| 7. Brand-consistency + framing lints GREEN; Pattern 2 invariant intact | PASS | uninstall.sh exemption added unconditionally per plan; `! grep -q whisper-cli purplevoice-lua/init.lua` + `grep -c WHISPER_BIN purplevoice-record == 2` |
| 8. tests/manual/test_readme_recovery_walkthrough.md signed off live by Oliver (item 4 may be DEFERRED) | PASS | Signed off 2026-05-04, all 4 items PASS (no DEFERRED — Oliver chose the destructive run) — commit e8bd7bf |

8/8 PASS.

## Status

**COMPLETE** — DST-03 walkthrough signed off live by Oliver 2026-05-04 (commit e8bd7bf). All 4 README recovery items PASS; no walkthrough-surfaced deviations requiring code/doc fixes. Functional suite 16/0; security 5/0; brand + framing GREEN; Pattern 2 invariant intact. REQUIREMENTS.md DST-03 [ ] → [x] in v1 subsection AND traceability table; v1 coverage stays 43/43 (100%). Plan 03-03 (hyperfine + DST-04) and Plan 03-04 (public flip + DST-05 end-to-end) unblocked.
