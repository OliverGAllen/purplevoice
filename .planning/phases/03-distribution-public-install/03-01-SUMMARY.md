---
phase: 03-distribution-public-install
plan: 01
subsystem: distribution
tags: [bash, idempotent-installer, curl-bash, dst-05, dst-06, d-13-typo-sweep, sbom-annotator, walkthrough-signed-off]

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
  - SBOM.spdx.json regenerated post-rename + post-D-13-sweep (commit f8cebb3) so on-disk SBOM matches install.sh's new annotator + corrected documentNamespace
  - DST-01 idempotency walkthrough signed off live by Oliver 2026-05-01 (5/6 PASS, criterion 8 DEFERRED-structural — see Deviations)
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
    - "Live walkthrough as authoritative gate for installer idempotency — sandbox cannot replicate user's actual ~/.hammerspoon/init.lua + edited vocab.txt + on-disk SBOM commit chain; only Oliver running install.sh twice on his real machine validates DST-01 end-to-end"

key-files:
  created: []
  modified:
    - install.sh  # renamed from setup.sh; Step 0 detection + bootstrap inserted
    - SECURITY.md  # D-13 typo fix (line 710 git clone URL)
    - SBOM.spdx.json  # regenerated post-rename + post-D-13 (commit f8cebb3)
    - tests/test_brand_consistency.sh  # exemption swept setup.sh -> install.sh + .claude/ added
    - tests/test_install_sh_detection.sh  # rewritten to use real subshell contexts
    - tests/test_karabiner_check.sh  # SETUP="setup.sh" -> SETUP="install.sh"
    - tests/security/verify_air_gap.sh  # 4 setup.sh -> install.sh references in invariant invocations
    - tests/manual/test_install_idempotent.md  # walkthrough signed off live by Oliver 2026-05-01 + criterion-8 deviation documented inline
  removed:
    - setup.sh  # via git mv (history preserved on the renamed file)

key-decisions:
  - "SBOM annotator string update fixes 4 occurrences not 3 (plan stated 3) — there are 4 jq-merge entries (mv/arch/clt/brew). Used `replace_all: true` Edit on the literal substring; verified post-edit with grep -c (4 install / 0 setup)."
  - "Wave 0 test_install_sh_detection.sh design bug: original tried `BASH_SOURCE=($pwd/install.sh)` to fake clone mode but bash special-cases BASH_SOURCE — direct array assignment to BASH_SOURCE[0] is silently ignored (length-1 array but [0]=''). Rewrote to use real file in real git repo (mktemp + git init + bash probe.sh) for clone path and stdin pipe (printf %s | bash) for curl path. Both modes now genuinely exercise production paths."
  - ".claude/ added to brand-consistency exemption (Rule 3 unblock): sibling agent worktrees at .claude/worktrees/agent-{a097d9ba,aaf0eadb} contain pre-2.5-rebrand snapshots full of voice-cc strings. Without exemption, lint hits 100+ unrelated files. .claude/ is untracked tooling surface (analogous to .git/.planning/) — strict exemption is correct."
  - "Internal install.sh user-facing setup.sh references (PURPLEVOICE_OFFLINE retry hint, missing-source error messages, REPO_ROOT comment, Karabiner step-5 reminder) swept to install.sh — accuracy in error output. Single audit-trail comment retained at line 3 (`# Renamed from setup.sh in Phase 3 per CONTEXT.md D-05.`)."
  - "test_karabiner_check.sh + tests/security/verify_air_gap.sh both directly invoked `setup.sh` — required Rule 3 follow-up to keep them GREEN after the rename. Both now reference install.sh; both back to PASS."
  - "SBOM regeneration after rename + D-13 was missing from the original task chain — orchestrator caught during walkthrough (Run 1 vs HEAD diff showed annotator + documentNamespace stale). Landed as f8cebb3 mid-walkthrough; pre-walkthrough state of repo had install.sh saying \"Tool: PurpleVoice-install.sh\" while SBOM.spdx.json on disk still said \"Tool: PurpleVoice-setup.sh\" — same plan-prose-vs-implementation pattern documented across Phase 2.7 / 02.5 / 04 deviation library. Surfaced as Rule 1 deviation (D-01 below)."
  - "Walkthrough criterion 8 (SBOM zero git diff) is mathematically unsatisfiable due to install.sh:472-478 deriving documentNamespace from `git rev-parse HEAD` (circular self-reference: committing the regenerated SBOM moves HEAD, making the just-committed SBOM 1-commit stale). Run 1 ↔ Run 2 byte-identity (md5 a48aae374ddb…) proves idempotency intent is upheld; literal git-diff check is over-strict for the underlying invariant. Deferred to Phase 5 / v1.1 follow-on (BACKLOG entry filed). Documented as Rule 1 STRUCTURAL deviation (D-02 below). Same latent issue existed in Phase 2.7 — hidden because no one re-ran setup.sh after the SBOM commit during 2.7's walkthrough."

patterns-established:
  - "When `git mv` renames a script, sweep the active downstream surfaces in a single commit: tests that grep the script's content (test_karabiner_check), tests that exec the script (verify_air_gap), brand-consistency exemption rules, internal user-facing error messages within the script. Keeps the rename atomic — no split GREEN/RED state across commits."
  - "When a Wave-0 test was authored from RESEARCH text without being run against a real implementation, expect a small re-test-of-the-test pass during Wave 1: the test design may have brittle mock idioms (BASH_SOURCE override) that look correct on paper but fail in practice. Fix the test, document as Rule 1 deviation, move on."
  - "When install.sh regenerates SBOM as part of its run, regenerate-and-commit SBOM in the SAME commit as any rename or annotator-string change (otherwise on-disk SBOM goes stale relative to install.sh's regen logic, which surfaces as a 'phantom diff' the moment anyone runs install.sh post-merge). Treat SBOM as a derived artifact synchronised by install.sh — and remember to re-derive it whenever its inputs change."
  - "Mathematically-unsatisfiable walkthrough criteria are NOT walkthrough failures — they are validation-contract design defects. When the criterion's underlying intent (idempotency) is provably upheld by an alternative measurement (Run 1 ↔ Run 2 byte-identity), accept the criterion as DEFERRED-structural and file a backlog item to fix the underlying derivation. Do not pretend the criterion failed; do not over-claim it passed; document the structural reason inline in the walkthrough sign-off."

requirements-completed: [DST-01, DST-02, DST-05, DST-06]

# Metrics
duration: ~30min wall-clock (executor + checkpoint + orchestrator-driven walkthrough + continuation)
completed: 2026-05-01
---

# Phase 3 Plan 01: Install.sh Rename + Curl|Bash Bootstrap Summary

**setup.sh -> install.sh rename + Step 0 curl-vs-clone detection + bootstrap_clone_then_re_exec inserted; D-13 typo sweep; brand-consistency exemption updated; Wave-0 RED tests turn GREEN; functional suite at exact 14/2 plan target; DST-01 idempotency walkthrough signed off live by Oliver 2026-05-01 with one structural deviation accepted.**

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

### 4. SBOM regeneration (orchestrator-applied mid-walkthrough — D-01)

- **`SBOM.spdx.json`** — regenerated by running install.sh once post-rename + post-D-13; committed at `f8cebb3` so on-disk SBOM matches install.sh's new annotator strings ("Tool: PurpleVoice-install.sh" — 4 occurrences) and corrected documentNamespace (`OliverGAllen/purplevoice/sbom/...`). This step was missing from the original task chain (plan-prose-vs-implementation gap) and was caught by the orchestrator during walkthrough Run 1 (the diff between regenerated-SBOM and on-disk SBOM showed annotator + documentNamespace stale).

### 5. DST-01 walkthrough sign-off (commit 191e4af)

`tests/manual/test_install_idempotent.md` signed off live by Oliver 2026-05-01:

| Criterion | Result | Detail |
|-----------|--------|--------|
| 1. Run 1 exit 0 + banner correct | PASS | Banner: "PurpleVoice installer (local clone at <REPO_ROOT>)"; `OK: SBOM regenerated` printed |
| 2. Run 2 exit 0 + skip lines | PASS | Hammerspoon already present, sox/whisper-cpp/syft already installed, Model present + checksum OK, Silero VAD weights present, vocab.txt preserved |
| 3-6. No-clobber check | PASS | `diff vocab.txt /tmp/vocab-pre-install.txt` = zero |
| 7. Pattern 2 invariant | PASS | `grep -c WHISPER_BIN purplevoice-record == 2`; `! grep -q whisper-cli purplevoice-lua/init.lua` |
| 8. SBOM zero git diff | DEFERRED — STRUCTURAL | Mathematically unsatisfiable (see D-02 below) — intent verified via Run 1 ↔ Run 2 byte-identity (md5 a48aae374ddb2ff908f6eade99282be8) |

**Run 1 vs Run 2 byte-identity:** both runs produced byte-identical install.sh logs; both regenerated SBOM at the same commit (b52606b); md5 a48aae374ddb2ff908f6eade99282be8 confirms DST-01 idempotency intent is upheld.

## Suite state at plan close (post-walkthrough)

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

### Deviations Surfaced During Walkthrough

**D-01. [Rule 1 - Plan-prose-vs-implementation gap] SBOM regeneration was missing from the original task chain**

- **Found during:** Walkthrough Run 1 (orchestrator running install.sh on Oliver's machine).
- **Issue:** Plan 03-01 changed install.sh's SBOM annotator strings (Task 1-1) and the documentNamespace URL (Task 1-2), but did not include a step to regenerate `SBOM.spdx.json` after those changes. Result: pre-walkthrough state had install.sh saying `"Tool: PurpleVoice-install.sh"` while the on-disk SBOM still said `"Tool: PurpleVoice-setup.sh"` — the moment install.sh ran (which it does on every install) the SBOM regen logic correctly updated the annotators, producing a phantom git diff.
- **Why this is the same pattern as Phase 2.7 / 02.5 / 04:** plans frequently specify "what install.sh's logic outputs should be" without specifying "regenerate the on-disk artifact whose generation install.sh now controls". Each plan rediscovers this as a Rule 1 deviation.
- **Fix:** Orchestrator ran install.sh once on Oliver's real machine (which regenerated SBOM.spdx.json deterministically) and committed the result as `fix(03-01): regenerate SBOM after install.sh rename + D-13 typo fix` (f8cebb3).
- **Files modified:** SBOM.spdx.json
- **Commit:** f8cebb3
- **Pattern entry:** Treat SBOM as a derived artifact synchronised by install.sh — re-derive whenever its inputs change. Bake into future plans that touch install.sh's annotator/namespace logic.

**D-02. [Rule 1 - STRUCTURAL] Walkthrough criterion 8 (SBOM zero git diff) is mathematically unsatisfiable**

- **Found during:** Walkthrough criterion 8 final check (after Run 1 + Run 2 + the D-01 SBOM commit).
- **Issue:** install.sh:472-478 (`deterministicise_sbom()`) derives `documentNamespace` from `git rev-parse HEAD`. This creates a circular self-reference:
  1. Regen at HEAD `b52606b` → SBOM file references `b52606b` (matches HEAD).
  2. Commit SBOM → HEAD becomes `f8cebb3`; SBOM-in-HEAD still references `b52606b` (now stale by 1 commit).
  3. Re-run install.sh → regen at HEAD `f8cebb3` → working-tree SBOM references `f8cebb3` → `git diff` shows documentNamespace + versionInfo updated by 1 commit.
  There is no commit chain that satisfies criterion 8 with current install.sh derivation logic. Phase 2.7 had the same latent issue, hidden because no one re-ran setup.sh after the SBOM commit during 2.7's walkthrough.
- **Why intent is upheld:** running install.sh twice on the same HEAD is provably a no-op — Run 1 / Run 2 logs both produced md5 `a48aae374ddb2ff908f6eade99282be8`; both regenerated SBOM at the same commit `b52606b`. DST-01 idempotency contract holds. The literal `git diff` check in criterion 8 is over-strict for the underlying invariant.
- **Decision:** Accept criterion 8 as DEFERRED-structural, not as a walkthrough failure. Document the structural reason inline in `tests/manual/test_install_idempotent.md` (commit 191e4af) and file a follow-on backlog item.
- **Backlog entry:** `Fix install.sh deterministicise_sbom() documentNamespace circular reference` — rewrite documentNamespace derivation to use `git rev-list -1 HEAD -- ':!SBOM.spdx.json'` (last non-SBOM commit) or a static milestone tag, so post-commit re-runs of install.sh produce zero diff. Defer to Phase 5 / v1.1; does NOT block v1 ship.
- **Files modified:** tests/manual/test_install_idempotent.md (criterion-8 deviation block + sign-off)
- **Commit:** 191e4af
- **Pattern entry:** Mathematically-unsatisfiable walkthrough criteria are validation-contract design defects, not walkthrough failures. When the criterion's underlying intent is provably upheld by an alternative measurement, accept as DEFERRED-structural and file a backlog item.

### Plan executed otherwise as written

No Rule 4 deviations. Walkthrough signed off with one structural deviation explicitly accepted by Oliver ("approved"). All tasks complete; functional + security suites at exact plan targets; Pattern 2 invariant intact; brand + framing lints GREEN.

## Authentication gates

None — no auth flows in scope for this plan.

## Plan 03-02 unblock signal

Plan 03-02 (LICENSE + README rewrite + uninstall.sh) is now unblocked:
- `bash tests/test_license_present.sh` — currently RED (Plan 03-02 creates `LICENSE`).
- `bash tests/test_uninstall_dryrun.sh` — currently RED (Plan 03-02 creates `uninstall.sh`).

## Self-Check: PASSED

Verifications run at plan-close:

- `[ -f install.sh ] && ! [ -f setup.sh ]` — PASS (rename intact)
- `git log --oneline | grep -E '^(9d68635|da95dda|b52606b|f8cebb3|191e4af)'` — all 5 commits FOUND on main HEAD chain
- `bash tests/run_all.sh` — 14 PASS / 2 FAIL (exact plan target; the 2 RED are 03-02 contract)
- `bash tests/security/run_all.sh` — 5 PASS / 0 FAIL
- `bash tests/test_brand_consistency.sh` — PASS (exit 0)
- `bash tests/test_security_md_framing.sh` — PASS
- Pattern 2 invariant — `grep -c WHISPER_BIN purplevoice-record == 2`; `! grep -q whisper-cli purplevoice-lua/init.lua` — INTACT
- `grep -q "signed off 2026-05-01 by Oliver" tests/manual/test_install_idempotent.md` — PASS
- `grep -q "Status: unsigned" tests/manual/test_install_idempotent.md` — FAIL-as-expected (sign-off replaced "unsigned")
- DST-01, DST-02, DST-05, DST-06 marked complete in REQUIREMENTS.md (this plan + closing metadata commit)
