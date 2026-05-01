---
phase: 03-distribution-public-install
plan: 01
subsystem: distribution
tags: [bash, idempotent-installer, curl-bash, dst-05, dst-06, d-13-typo-sweep, sbom-annotator]

# Dependency graph
requires:
  - phase: 03-distribution-public-install
    plan: 00
    provides: Wave 0 RED tests (test_install_sh_detection.sh, test_install_sh_no_init_lua_edit.sh, test_install_sh_dst06_option_b.sh) staging the validation contract for this plan
  - phase: 02.7-security-posture
    provides: SBOM regen pipeline (Step 8 inject_system_context + deterministicise_sbom) + brand-consistency hook + framing lint pattern
  - phase: 04-quality-of-life-v1-x
    provides: Karabiner-Elements check (Step 9) + setup.sh Step 9 actionable-error pattern inherited verbatim under the renamed install.sh
provides:
  - install.sh (renamed from setup.sh) at repo root — single canonical idempotent installer with two valid invocation modes (clone + curl|bash)
  - detect_invocation_mode + bootstrap_clone_then_re_exec functions enabling DST-05 public curl|bash install path
  - Dual-mode banner (clone vs curl|bash) per RESEARCH §Pattern 3
  - SBOM annotator strings updated to "Tool: PurpleVoice-install.sh" (4 occurrences) — the lie-about-origin fix from RESEARCH §"Runtime State Inventory"
  - D-13 GitHub-owner casing typos eradicated from active surfaces (install.sh SBOM documentNamespace + SECURITY.md line 710 clone instruction)
  - tests/test_brand_consistency.sh exemption swept setup.sh -> install.sh + .claude/ exclusion added (Rule 3 — sibling worktrees were leaking voice-cc strings into the lint)
  - tests/test_install_sh_detection.sh rewritten so it actually exercises the function (Rule 1 — original test couldn't override BASH_SOURCE[0] because bash treats it specially)
  - tests/test_karabiner_check.sh + tests/security/verify_air_gap.sh updated to reference install.sh (Rule 3 — direct downstream of rename)
affects: [03-02-PLAN, 03-03-PLAN, 03-04-PLAN]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "curl-vs-clone detection via $0 + .git-presence check (POSIX `cd $(dirname) && pwd` over GNU realpath — Pitfall 7 idiom-portable on stock macOS)"
    - "Bootstrap-clone-then-re-exec pattern: `exec bash $CLONE_DIR/install.sh` so the curl|bash entry process exits with the install.sh exit code (no double-banner, no nested set -e drift)"
    - "Dual-mode banner block via `case $INVOCATION_MODE in clone) ... ;; curl) ... bootstrap ;; esac` so the rest of install.sh only runs in clone mode (re-exec'd from the local clone)"
    - "BASH_SOURCE override unreliable in bash subshells — to test clone-mode detection, use a real file via mktemp + git init + bash <real-file>; for curl-mode, use stdin pipe (printf | bash)"
    - ".claude/ untracked tool surface added to brand-consistency exemption list — sibling worktrees can otherwise leak historical voice-cc strings into the lint and block GREEN"

key-files:
  created: []
  modified:
    - install.sh  # renamed from setup.sh; Step 0 detection + bootstrap inserted
    - SECURITY.md  # D-13 typo fix (line 710 git clone URL)
    - tests/test_brand_consistency.sh  # exemption swept setup.sh -> install.sh + .claude/ added
    - tests/test_install_sh_detection.sh  # rewritten to use real subshell contexts
    - tests/test_karabiner_check.sh  # SETUP="setup.sh" -> SETUP="install.sh"
    - tests/security/verify_air_gap.sh  # 4 setup.sh -> install.sh references in invariant invocations
  removed:
    - setup.sh  # via git mv (history preserved on the renamed file)

key-decisions:
  - "SBOM annotator string update fixes 4 occurrences not 3 (plan stated 3) — there are 4 jq-merge entries (mv/arch/clt/brew). Used `replace_all: true` Edit on the literal substring; verified post-edit with grep -c (4 install / 0 setup)."
  - "Wave 0 test_install_sh_detection.sh design bug: original tried `BASH_SOURCE=($pwd/install.sh)` to fake clone mode but bash special-cases BASH_SOURCE — direct array assignment to BASH_SOURCE[0] is silently ignored (length-1 array but [0]=''). Rewrote to use real file in real git repo (mktemp + git init + bash probe.sh) for clone path and stdin pipe (printf %s | bash) for curl path. Both modes now genuinely exercise production paths."
  - ".claude/ added to brand-consistency exemption (Rule 3 unblock): sibling agent worktrees at .claude/worktrees/agent-{a097d9ba,aaf0eadb} contain pre-2.5-rebrand snapshots full of voice-cc strings. Without exemption, lint hits 100+ unrelated files. .claude/ is untracked tooling surface (analogous to .git/.planning/) — strict exemption is correct."
  - "Internal install.sh user-facing setup.sh references (PURPLEVOICE_OFFLINE retry hint, missing-source error messages, REPO_ROOT comment, Karabiner step-5 reminder) swept to install.sh — accuracy in error output. Single audit-trail comment retained at line 3 (`# Renamed from setup.sh in Phase 3 per CONTEXT.md D-05.`)."
  - "test_karabiner_check.sh + tests/security/verify_air_gap.sh both directly invoked `setup.sh` — required Rule 3 follow-up to keep them GREEN after the rename. Both now reference install.sh; both back to PASS."

patterns-established:
  - "When `git mv` renames a script, sweep the active downstream surfaces in a single commit: tests that grep the script's content (test_karabiner_check), tests that exec the script (verify_air_gap), brand-consistency exemption rules, internal user-facing error messages within the script. Keeps the rename atomic — no split GREEN/RED state across commits."
  - "When a Wave-0 test was authored from RESEARCH text without being run against a real implementation, expect a small re-test-of-the-test pass during Wave 1: the test design may have brittle mock idioms (BASH_SOURCE override) that look correct on paper but fail in practice. Fix the test, document as Rule 1 deviation, move on."

requirements-completed: [DST-01, DST-02, DST-05, DST-06]

# Metrics
duration: ~30min
completed: 2026-05-01
---

# Phase 3 Plan 01: Install.sh Rename + Curl|Bash Bootstrap Summary

**setup.sh -> install.sh rename + Step 0 curl-vs-clone detection + bootstrap_clone_then_re_exec inserted; D-13 typo sweep; brand-consistency exemption updated; Wave-0 RED tests turn GREEN; functional suite at exact 14/2 plan target — checkpoint reached at LIVE idempotency walkthrough (Task 1-3).**

## What was built

### 1. install.sh structural changes

- **`git mv setup.sh install.sh`** — rename preserves history (77% similarity).
- **Step 0 inserted** (before `set -euo pipefail`): two functions + a 2-arm dispatch case.
  - `detect_invocation_mode()` — POSIX-portable detection (no `realpath`); writes "clone" if `${BASH_SOURCE[0]:-$0}` is a real file inside a git checkout, "curl" otherwise.
  - `bootstrap_clone_then_re_exec()` — if invoked via curl|bash: pre-flight git presence; idempotently clone-or-pull `OliverGAllen/purplevoice` into `~/.local/share/purplevoice/src`; `exec bash $CLONE_DIR/install.sh`.
  - Dispatch: clone -> banner-and-fall-through; curl -> banner + bootstrap (re-exec, never returns).
- **Header docblock rewritten** to document the two valid invocation modes + the new Step-0 in the per-step list.
- **SBOM annotator strings updated** in the `inject_system_context` jq-merge: 4 occurrences of `"Tool: PurpleVoice-setup.sh"` -> `"Tool: PurpleVoice-install.sh"` (plan stated 3; actual count was 4 — recorded as Rule 1 deviation).
- **Internal user-facing setup.sh references swept** to install.sh (PURPLEVOICE_OFFLINE retry hint, missing-source errors for vocab.txt + denylist.txt, REPO_ROOT comment, Karabiner-missing error step 5, denylist install confirmation).

### 2. D-13 GitHub-owner casing fix

Two typos eradicated from active surfaces (the actual GitHub owner is `OliverGAllen`, not `oliverallen`):

| File | Line | Before | After |
|------|------|--------|-------|
| install.sh | 477 (post-rename) | `("https://github.com/oliverallen/PurpleVoice/sbom/" + $head)` | `("https://github.com/OliverGAllen/purplevoice/sbom/" + $head)` |
| SECURITY.md | 710 | `git clone https://github.com/oliverallen/PurpleVoice.git purplevoice` | `git clone https://github.com/OliverGAllen/purplevoice.git purplevoice` |

`.planning/` historical artefacts intentionally NOT swept (Phase 2.5 D-07 audit-trail discipline).

### 3. Test infrastructure updates

- **`tests/test_brand_consistency.sh`** — line 31 exemption changed `^\./setup\.sh$` -> `^\./install\.sh$`. Added `^\./\.claude/` exemption (sibling worktrees fix).
- **`tests/test_install_sh_detection.sh`** — rewritten (Rule 1 deviation): original test set `BASH_SOURCE=("$(pwd)/install.sh")` then called the function, expecting clone mode. But bash treats `BASH_SOURCE` specially (it's the call-stack array) and direct subscript assignment is silently ignored (`${BASH_SOURCE[0]}` stays empty). New test exercises the function in real subshell contexts: clone via mktemp + `git init` + `bash probe.sh`; curl via stdin pipe.
- **`tests/test_karabiner_check.sh`** — `SETUP="setup.sh"` -> `SETUP="install.sh"` (test grepped the renamed file's content for Karabiner-check + JSON ref).
- **`tests/security/verify_air_gap.sh`** — 4 occurrences of `setup.sh` (in invariant invocations + error-message references) updated to `install.sh`.

## Suite state at plan close (pre-walkthrough)

| Suite | Result | Notes |
|-------|--------|-------|
| `bash tests/run_all.sh` | **14 PASS / 2 FAIL** | EXACT plan target. The 2 RED are `test_uninstall_dryrun.sh` + `test_license_present.sh` — both wait on Plan 03-02 (uninstall.sh + LICENSE deliverables). |
| `bash tests/security/run_all.sh` | **5 PASS / 0 FAIL** | Unchanged baseline; `verify_air_gap.sh` recovered after the setup.sh -> install.sh references were swept. |
| `bash tests/test_brand_consistency.sh` | PASS | exemption updated; `.claude/` worktree-leak fixed. |
| `bash tests/test_security_md_framing.sh` | PASS | D-13 sweep on SECURITY.md introduced no banned-phrase regression. |
| Pattern 2 invariant | INTACT | `grep -c WHISPER_BIN purplevoice-record == 2`; `! grep -q whisper-cli purplevoice-lua/init.lua`. |

Wave-0 RED tests covering install.sh structure all turned GREEN as designed:
- `test_install_sh_detection.sh` — both clone and curl branches verified.
- `test_install_sh_no_init_lua_edit.sh` — no init.lua write idioms in install.sh.
- `test_install_sh_dst06_option_b.sh` — `brew install --cask hammerspoon` preserved; zero Option A/C signatures.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Plan miscount] SBOM annotator string count was 4, not 3**

- **Found during:** Task 1-1 action 4 (SBOM annotator update).
- **Issue:** Plan said "exactly 3 occurrences in the SBOM `inject_system_context` annotator helper". Pre-edit `grep -c 'PurpleVoice-setup.sh' setup.sh` returned `4` (mv, arch, clt, brew — one per system-context dimension).
- **Fix:** Used `Edit` with `replace_all: true` to handle all occurrences atomically. Post-edit verify: `grep -c 'PurpleVoice-install.sh' install.sh` = 4; `grep -c 'PurpleVoice-setup.sh' install.sh` = 0.
- **Files modified:** install.sh
- **Commit:** 9d68635

**2. [Rule 1 - Wave-0 test design bug] test_install_sh_detection.sh BASH_SOURCE mock unreliable**

- **Found during:** Task 1-1 verification — both test branches returned empty / wrong values.
- **Issue:** The Wave-0 test extracted the `detect_invocation_mode` function via `sed`, eval'd it in a subshell, then attempted `BASH_SOURCE=("$(pwd)/install.sh")` to mock clone mode. Bash treats `BASH_SOURCE` specially (it's the call-stack array): the subscript array assignment puts the value at length-1 but `${BASH_SOURCE[0]}` reads back as empty string. Both branches consequently fell through to the `curl` return path.
- **Investigation:** Verified by direct experimentation in a debug subshell (`echo "BASH_SOURCE[0]: '${BASH_SOURCE[0]}'"` printed empty after the assignment).
- **Fix:** Rewrote the test to use real production-equivalent invocation contexts:
  - Clone branch: `mktemp -d` -> `git init` -> drop a `probe.sh` containing the function definition + a call -> `bash ./probe.sh` (so `BASH_SOURCE[0]` is the real file path inside the real git checkout).
  - Curl branch: `printf '%s\ndetect_invocation_mode\n' "$DETECT_BLOCK" | bash` (stdin pipe matches `curl ... | bash` exactly: `BASH_SOURCE[0]` empty, `$0` is "bash", `-f "$script_path"` false).
- **Files modified:** tests/test_install_sh_detection.sh (full rewrite)
- **Commit:** 9d68635

**3. [Rule 3 - Direct downstream of rename] test_karabiner_check.sh referenced setup.sh**

- **Found during:** Task 1-1 full-suite run after the rename.
- **Issue:** `test_karabiner_check.sh` line 24 `SETUP="setup.sh"` — test then `grep "Karabiner-Elements.app" "$SETUP"` failed with `grep: setup.sh: No such file`.
- **Fix:** `SETUP="install.sh"` + updated 1 docblock comment line referencing setup.sh.
- **Files modified:** tests/test_karabiner_check.sh
- **Commit:** 9d68635

**4. [Rule 3 - Direct downstream of rename] verify_air_gap.sh ran setup.sh directly**

- **Found during:** Wave-1 security suite check.
- **Issue:** `tests/security/verify_air_gap.sh` invariants 1 + 2 invoked `bash setup.sh` directly with PURPLEVOICE_OFFLINE=1 to test offline mode; failed with `bash: setup.sh: No such file or directory`.
- **Fix:** `replace_all` setup.sh -> install.sh in verify_air_gap.sh (4 occurrences).
- **Files modified:** tests/security/verify_air_gap.sh
- **Commit:** 9d68635

**5. [Rule 3 - Pre-existing latent bug surfacing under rename] sibling worktrees leak voice-cc strings**

- **Found during:** Task 1-1 first brand-consistency run.
- **Issue:** `.claude/worktrees/agent-{a097d9ba,aaf0eadb}/` contain stale snapshots (pre-Phase-2.5 rename) with hundreds of `voice-cc` strings. `tests/test_brand_consistency.sh`'s grep -rln walks `.` and only excludes `.planning/`, `.git/`, plus a handful of named files. The worktrees leak through and produce a noisy FAIL listing 100+ unrelated files.
- **Why this is "blocking" not "out of scope":** The worktrees were created during the Wave-0 staging plan; they did not exist at Phase 2.5's brand-consistency hook design time. Without an exemption, the renamed-file work cannot pass GREEN, and the plan cannot meet its success criteria.
- **Fix:** Added `| grep -v "^\./\.claude/"` to the exemption pipe in test_brand_consistency.sh. Same kind of exemption as `.git/` and `.planning/` (tool-managed scratch surface, not committed product code).
- **Files modified:** tests/test_brand_consistency.sh
- **Commit:** 9d68635

### Plan executed otherwise as written

No Rule 4 deviations. Walkthrough task remains pending — see "Live walkthrough sign-off" section below.

## Live walkthrough sign-off (Task 1-3 — PENDING USER ACTION)

`tests/manual/test_install_idempotent.md` — **Status:** unsigned at this commit.

The walkthrough is a **`checkpoint:human-action`** gate — Oliver must execute install.sh twice on his real machine to validate DST-01 idempotency end-to-end (no sandbox can replicate his real ~/.hammerspoon/init.lua + user-edited vocab.txt + the actual SBOM regen idempotency on his exact hardware).

Continuation agent will:
1. Read `tests/manual/test_install_idempotent.md` for the verbatim Run 1 / Run 2 / no-clobber check / Pattern 2 invariant final-check / sign-off block.
2. Confirm Oliver completed the walkthrough successfully.
3. Either commit the sign-off (`test(03-01): DST-01 install.sh idempotency walkthrough signed off`) and finalise this SUMMARY, OR record the failure mode and replan.

## Plan 03-02 unblock signal

After Task 1-3 sign-off lands, Plan 03-02 (LICENSE + README rewrite + uninstall.sh) can begin:
- `bash tests/test_license_present.sh` — currently RED (Plan 03-02 creates `LICENSE`).
- `bash tests/test_uninstall_dryrun.sh` — currently RED (Plan 03-02 creates `uninstall.sh`).

## Self-Check: PENDING (finalised by continuation agent post-walkthrough)
