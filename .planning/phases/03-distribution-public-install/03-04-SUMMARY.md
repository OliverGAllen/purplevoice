---
phase: 03-distribution-public-install
plan: 04
status: complete
subsystem: distribution
tags: [security, distribution, public-install, mit, source-available, install-token-gate, repo-public]
date_started: 2026-05-04
date_completed: 2026-05-04
requirements: [DST-05, DST-06]   # both [x] Complete in REQUIREMENTS.md (DST-05 + DST-06 already Complete from Plan 03-01; this plan's DST-05 walkthrough confirmed end-to-end live)
dependency_graph:
  requires:
    - LICENSE present at repo root (Plan 03-02 commit c347ea8)
    - README.md production curl URL pointing at OliverGAllen/purplevoice (Plan 03-02 commit 98c0018)
    - install.sh curl-vs-clone bootstrap (Plan 03-01 commit 9d68635)
    - SECURITY.md ## Code Signing & Notarisation H2 (Phase 2.7)
  provides:
    - SECURITY.md ### Distribution model (Phase 3, v1) H3 (Task 4-1)
    - D-06 pre-flip checklist GREEN (Task 4-2)
  affects:
    - Task 4-3 public flip readiness (orchestrator + user gate)
tech-stack:
  added: []
  patterns:
    - "source-available framing under MIT (Phase 3 D-07 + 02.7 'compatible with' D-17 honest discipline)"
key-files:
  created: []
  modified:
    - SECURITY.md (+13 net; new H3 inserted at line 626 inside ## Code Signing & Notarisation H2)
decisions:
  - "Task 4-2 placeholder gate (gate 8) WARN-not-FAIL: README.md + BENCHMARK.md retain '_filled by Plan 03-03_' placeholders because DST-04 walkthrough was deferred (REQUIREMENTS.md line 153; STATE.md line 33; BACKLOG.md item 2). The plan's verbatim <verify> clause (line 299) does not include placeholder-detection — it's only in the action-step-1 script's gate 8, which self-classifies as WARN unless Task 4-5 has already run. Per plan-verify contract, Task 4-2 is GREEN; per WARN status, the orchestrator should be aware that the public README.md will visibly carry these placeholders until DST-04 lands."
metrics:
  duration_min: ~120
  tasks_complete: 5
  tasks_total: 5
  files_modified: 7
---

# Phase 3 Plan 04: Public Flip + DST-05/DST-06 Closure Summary

> **Status:** COMPLETE 2026-05-04. All 5 tasks landed. Repo PUBLIC. INSTALL_TOKEN soft-gate live. DST-05 walkthrough signed off. Phase 3 row in ROADMAP flipped to 5/5 Complete with DST-04 deferred annotation. v1 publicly shipping.

## One-liner

SECURITY.md "### Distribution model (Phase 3, v1)" H3 added (honest source-available + MIT + Hammerspoon-substrate framing); D-06 pre-flip checklist 8/8 hard-gates GREEN + 1 WARN (DST-04 placeholders deliberately deferred); Task 4-3 public flip blocked on orchestrator + user gate.

## What was built (Tasks 4-1 + 4-2)

### Task 4-1: SECURITY.md `### Distribution model (Phase 3, v1)` H3 added

- **Insertion point:** new H3 sibling under `## Code Signing & Notarisation` (line 614), placed BEFORE the existing `### If PurpleVoice ever ships as a notarised .app (Phase 3 scope)` H3.
- **Content (verbatim from 03-04-PLAN.md interfaces, sourced from 03-RESEARCH.md §"SECURITY.md Distribution model subsection"):**
  - source-available framing under MIT (links LICENSE)
  - public GitHub repo at `https://github.com/OliverGAllen/purplevoice`
  - one-line installer at `raw.githubusercontent.com/.../install.sh`
  - no notarised installer artefact (Hammerspoon Spoon + bash + brew)
  - deliberate-trade-off paragraph (zero opaque-binary surface in exchange for slightly higher install friction; "load-bearing posture" qualifier preserves D-17 framing)
  - anchor link `#if-purplevoice-ever-ships-as-a-notarised-app-phase-3-scope` to the deferred .app notarisation H3
- **Framing-lint compatibility verified:**
  - no `compliant` without qualifier
  - no `certified` without qualifier
  - no `guarantees` without qualifier (uses "load-bearing posture")
  - no `voice-cc` strings
- **Commit:** cf20e93 (`docs(03-04): add SECURITY.md ### Distribution model (Phase 3, v1) H3`)
- **Verify GREEN:** framing lint PASS; brand-consistency lint PASS; all 4 plan-required grep landmarks present.

### Task 4-2: D-06 pre-flip checklist verification (no commit — verification-only)

| # | Gate | Result |
|---|------|--------|
| 1 | LICENSE present | OK (canonical MIT @ commit c347ea8) |
| 2 | README.md production curl URL | OK (`raw.githubusercontent.com/OliverGAllen/purplevoice/main/install.sh`) |
| 3 | SECURITY.md "Distribution model (Phase 3, v1)" H3 | OK (line 626; from Task 4-1 commit cf20e93) |
| 4 | brand-consistency lint | GREEN |
| 5 | framing lint (D-17) | GREEN |
| 6 | functional suite | 16 PASS / 0 FAIL |
| 7 | security suite | 5 PASS / 0 FAIL |
| 8 | placeholder-detection (README.md + BENCHMARK.md) | **WARN** — `_filled by Plan 03-03_` placeholders preserved; DST-04 deferred per Oliver (REQUIREMENTS.md line 153; STATE.md line 33; BACKLOG.md item 2) |
| 9 | Pattern 2 invariant | OK (`grep -c WHISPER_BIN purplevoice-record == 2`; no `whisper-cli` in init.lua) |

- **Plan-verbatim `<verify>` automated clause (line 299): PASS.** The verify clause does not include placeholder-detection; only the action-step-1 script's gate 8 mentions placeholders, and that gate self-classifies as WARN unless Task 4-5 has already run.
- **Logs captured:**
  - `/tmp/p3-w4-functional.log` — full functional run
  - `/tmp/p3-w4-security.log` — full security run

## Suite state at Task 4-2 close (HEAD = cf20e93)

| Suite | Result | Note |
|-------|--------|------|
| `tests/run_all.sh` | 16 PASS / 0 FAIL | unchanged from Plan 03-02 close |
| `tests/security/run_all.sh` | 5 PASS / 0 FAIL | unchanged |
| `tests/test_brand_consistency.sh` | GREEN | unchanged |
| `tests/test_security_md_framing.sh` | GREEN | new H3 framing-lint compatible |
| `grep -c WHISPER_BIN purplevoice-record` | 2 | Pattern 2 boundary intact |
| `grep -c whisper-cli purplevoice-lua/init.lua` | 0 | Pattern 2 corollary intact |

## Pre-flight state for Task 4-3 (orchestrator handoff)

| Pre-flight gate | Value | Status |
|-----------------|-------|--------|
| `git rev-parse HEAD` | cf20e93a5749d6a746b95c8819a318a34516c25a | clean |
| `git status --short` | _empty_ | no uncommitted changes |
| `git log origin/main..HEAD --oneline \| wc -l` | **117** | **PUSH REQUIRED before flip** |
| `git rev-parse --abbrev-ref @{u}` | `origin/main` | tracking configured |
| `git remote -v` | `https://github.com/OliverGAllen/purplevoice.git` | matches plan target |
| `gh auth status` | logged in as `OliverGAllen` (keyring); scopes: gist, read:org, repo | OK |
| `gh repo view OliverGAllen/purplevoice --json visibility` | `"PRIVATE"` | as expected pre-flip |

**Critical pre-flight blocker:** local `main` is 117 commits ahead of `origin/main`. The public flip is meaningful only if the commits that the README + install.sh promise actually exist on `origin/main` — without `git push origin main` first, anonymous `curl https://raw.githubusercontent.com/OliverGAllen/purplevoice/main/install.sh` will either 404 or return stale (pre-Plan-03-01-rename) `setup.sh`. **Must `git push origin main` BEFORE the gh repo edit visibility command, or the post-flip Task 4-3 anonymous smoke test (PASS-criterion 5) will fail.**

## Task 4-3 command (verbatim, NOT executed)

```bash
# Step 0 — push local commits to origin so the public repo content matches what install.sh advertises
git push origin main

# Step 1 — re-confirm pre-flip suite state
bash tests/run_all.sh 2>&1 | tail -3        # expect: 16 passed, 0 failed
bash tests/security/run_all.sh 2>&1 | tail -3  # expect: 5 passed, 0 failed

# Step 2 — confirm gh CLI auth + correct repo
gh auth status
gh repo view OliverGAllen/purplevoice --json visibility,owner,name
# expect: visibility "PRIVATE", owner OliverGAllen, name purplevoice

# Step 3 — THE FLIP (--accept-visibility-change-consequences REQUIRED in non-interactive mode per RESEARCH §Pitfall 1)
gh repo edit OliverGAllen/purplevoice \
  --visibility public \
  --accept-visibility-change-consequences

# Step 4 — post-flip verification
gh repo view OliverGAllen/purplevoice --json visibility --jq '.visibility'
# expect: "PUBLIC"

# Step 5 — anonymous smoke test (DST-05 string-level proof)
unset GH_TOKEN; unset GITHUB_TOKEN
curl -fsSI https://raw.githubusercontent.com/OliverGAllen/purplevoice/main/install.sh
# expect: HTTP/2 200, content-type text/plain or text/x-shellscript

curl -fsSL https://raw.githubusercontent.com/OliverGAllen/purplevoice/main/install.sh | head -5
# expect: install.sh shebang + comment header (NOT 404, NOT Not Found)

# Step 6 — capture audit log to /tmp/p3-flip-audit.log per plan
```

## What landed in Tasks 4-3 + 4-4 + 4-5

### Task 4-3: PUBLIC FLIP

- Pre-flip: 117 commits ahead of origin/main + INSTALL_TOKEN soft-gate not yet implemented. Both addressed in commit `4d43035` (gate + placeholder cleanup) before push.
- `git push origin main` — 118 commits landed on origin (`9033622..4d43035 main -> main`).
- `gh repo edit OliverGAllen/purplevoice --visibility public --accept-visibility-change-consequences` — succeeded.
- Post-flip verification: `gh repo view --json visibility --jq '.visibility'` returned `"PUBLIC"`. Anonymous `curl -fsSI https://raw.githubusercontent.com/OliverGAllen/purplevoice/main/install.sh` returned HTTP/2 200; `curl -fsSL` served install.sh shebang + comment header (the gated installer).

### INSTALL_TOKEN soft-gate (introduced in Task 4-3 prep, commit 4d43035)

Not in the original Plan 03-04 scope — surfaced during Task 4-3 user-decision phase when Oliver requested "can we add a key so only certain people can install it?" alongside the public flip approval. Implementation:

- `install.sh`: added `verify_install_token()` function after `bootstrap_clone_then_re_exec`. Reads `INSTALL_TOKEN` env var; hashes with `shasum -a 256`; compares to baked-in expected hash (`5b7e4cb039c83f6ebd2be83d618ccf7056f0e368aede366a0e438303073a7907`). Honors `PURPLEVOICE_TEST_BYPASS_TOKEN_CHECK=1` for tests. Friendly error block + request-channel message on empty/wrong; exit 1.
- `tests/security/verify_air_gap.sh`: added `PURPLEVOICE_TEST_BYPASS_TOKEN_CHECK=1` to the 2 install.sh invocations so the air-gap suite still runs.
- `README.md`: Quickstart curl one-liner now requires `INSTALL_TOKEN=xxx`; added paragraph explaining the soft-gate framing + how to request a token.
- `SECURITY.md`: added an `**Install gate**` paragraph inside `### Distribution model (Phase 3, v1)` honestly framing the gate as a soft signal, not access control. Framing-lint compatible (no "compliant"/"certified"/"guarantees" without qualifier).
- Token: `f2a5df2986976ed8` (16-char random hex, confirmed by Oliver before commit).

**Honest framing recorded in SECURITY.md:** "Treat it as the internet-friendly equivalent of a 'members only' sign on an unlocked door — useful as a request norm, not as a control surface." Public source means a determined party can read install.sh on GitHub, see the expected hash, and remove the gate. The gate's actual purposes are (1) filtering casual / accidental installs and (2) creating a "ping Oliver before installing" channel.

### Placeholder cleanup (commit 4d43035)

Because DST-04 was deferred 2026-05-04 by Oliver (Plan 03-03 Task 3-5), the README `## Performance` placeholder rows + BENCHMARK.md placeholder block were rewritten from `_filled by Plan 03-03_` (which would look unfinished publicly) to honest `_pending DST-04 walkthrough_` framing pointing at BACKLOG#2. Phase 5 verdict line in BENCHMARK.md now reads `PENDING DST-04` instead of `DEFERRED / ACTIVE` placeholder.

### Task 4-4: DST-05 walkthrough — orchestrator-led 3 sub-checks on Oliver's machine

| Sub-check | Command | Expected | Result |
|-----------|---------|----------|--------|
| 1 (empty token) | `curl ... \| bash` | gate fires + exit 1 + no clone | PASS |
| 2 (wrong token) | `INSTALL_TOKEN=wrong curl ... \| bash` | "INSTALL_TOKEN does not match" + exit 1 | PASS |
| 3 (correct token + curl\|bash bootstrap) | `INSTALL_TOKEN=f2a5df2986976ed8 curl ... \| bash` | curl banner → bootstrap clone → re-exec → idempotent install → final banner | PASS |

`tests/manual/test_curl_bash_install.md` signed off live by Oliver — all 3 sub-checks PASS. Walkthrough sign-off committed.

### Task 4-5: REQUIREMENTS.md + ROADMAP.md + STATE.md closure

- REQUIREMENTS.md: DST-01..03, DST-05, DST-06 already [x] Complete from Plans 03-01 / 03-02. DST-04 stays [ ] Pending with DEFERRED annotation pointing at BACKLOG#2. Final footer entry added (2026-05-04 closure log).
- ROADMAP.md: Phase 3 row in Progress table flipped from `2/5 | In Progress` to `5/5 | Complete 2026-05-04`. Final footer log entry added.
- STATE.md: Phase 3 frontmatter + body updated to reflect closure.
- `03-04-SUMMARY.md`: this file flipped from `pre-flip-draft` to `complete`.

## Plan 03-04 deviations (post-flip)

### Deviation D-04A: INSTALL_TOKEN soft-gate scope addition (mid-plan)

- **Surfaced during:** Task 4-3 user-decision phase
- **Trigger:** Oliver asked "can we add a key so only certain people can install it?" alongside approving the public flip
- **Resolution:** Plan scope extended in-flight to include the gate. Implementation, README + SECURITY.md updates, and verify_air_gap.sh test bypass all landed in commit 4d43035 before the public flip + Task 4-4 walkthrough. Honestly framed as a soft signal in SECURITY.md (matches D-17 "compatible with" discipline).
- **Why it's a deviation worth recording:** the original plan didn't anticipate any access-control story for the public installer. The gate is a meaningful new surface — visible in install.sh, README quickstart, and SECURITY.md — that future plans may need to evolve (e.g., per-person tokens, hash rotation, deprecation).

### DST-04 deferral cascade (already documented in Plan 03-03)

Plan 03-04's original Task 4-5 prose expected DST-04 to flip to `[x] Complete`. Because DST-04 was deferred 2026-05-04 by Oliver (Plan 03-03 Task 3-5), Task 4-5 closure preserves DST-04 [ ] Pending with DEFERRED annotation, and the v1 coverage figure is 42/43 (97.7%) instead of 43/43. Phase 5 trigger verdict stays "Conditional" until DST-04 lands. This is the Phase 4 CHECKPOINT-3 precedent applied — destructive/time-cost walkthroughs DEFERRED with documented reason, surfaced via `/gsd:audit-uat`, are a recognised GSD pattern.

## Plan 03-04 commits (so far)

- cf20e93 — `docs(03-04): add SECURITY.md ### Distribution model (Phase 3, v1) H3` (Task 4-1)
- _no commit for Task 4-2 — verification-only per plan_

## Self-Check (pre-flip)

- [x] Task 4-1 commit cf20e93 exists in `git log` (verified: `git log --oneline --all | grep -q cf20e93`).
- [x] SECURITY.md H3 lands at line 626 (verified: `grep -n "^### Distribution model (Phase 3, v1)" SECURITY.md`).
- [x] H3 ordering correct (verified: `grep -n "^## Code Signing\|^### If PurpleVoice ever ships" SECURITY.md` returns 614 + 639 — sibling H3s under the H2).
- [x] No SUMMARY-claimed file is missing.
- [x] No SUMMARY-claimed commit is missing.

## Status

**COMPLETE 2026-05-04** — All 5 tasks landed. Repo PUBLIC at https://github.com/OliverGAllen/purplevoice. INSTALL_TOKEN soft-gate live + honestly framed in SECURITY.md. DST-05 walkthrough signed off live by Oliver (3/3 sub-checks PASS). REQUIREMENTS.md DST-05 + DST-06 [x] Complete (already from Plan 03-01); DST-04 [ ] Pending DEFERRED per BACKLOG#2. ROADMAP Phase 3 row 5/5 Complete. v1 publicly shipping.

**Phase 3 closure summary:**
- 5/5 plans complete (with Plan 03-03 Task 3-5 walkthrough deferred to BACKLOG#2 — harness ready, benchmark execution pending Oliver's hardware time)
- v1 coverage 42/43 = 97.7% (DST-04 deferred)
- Repo flipped PUBLIC; INSTALL_TOKEN soft-gate active; anonymous curl serves install.sh with HTTP 200
- Suite at close: functional 16/0; security 5/0; brand + framing GREEN; Pattern 2 invariant intact
- Phase 5 trigger verdict stays "Conditional" pending DST-04

## Final Plan 03-04 commits

| Commit | Type | Files | Summary |
|--------|------|-------|---------|
| `cf20e93` | docs(03-04) | SECURITY.md | Distribution model H3 |
| `4d43035` | feat(03-04) | install.sh + verify_air_gap.sh + README.md + SECURITY.md + BENCHMARK.md | INSTALL_TOKEN soft-gate + honest pending-DST-04 framing |
| _push_ | _push origin main_ | (118 commits) | origin/main synced before public flip |
| _gh repo edit_ | _public flip_ | _GitHub repo metadata_ | visibility PRIVATE → PUBLIC |
| _walkthrough_ | test(03-04) | tests/manual/test_curl_bash_install.md | DST-05 sign-off (3/3 sub-checks PASS) |
| _closure_ | docs(03-04) | REQUIREMENTS.md + ROADMAP.md + STATE.md + 03-04-SUMMARY.md | Phase 3 5/5 Complete; DST-04 deferred annotation preserved |
