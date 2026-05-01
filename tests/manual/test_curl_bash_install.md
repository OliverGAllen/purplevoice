# Manual walkthrough: public curl|bash install (DST-05)

**Status:** unsigned
**Created:** 2026-05-01 (Plan 03-00)
**Sign-off path:** Plan 03-04 (autonomous: false; runs AFTER `gh repo edit --visibility public --accept-visibility-change-consequences` — this is the only end-to-end test of the public-installer story)
**Phase:** 3 — Distribution & Public Install
**Requirement:** DST-05 (public curl|bash one-liner clones repo + invokes install.sh; idempotent; prints next-step `require()` line)

## Why this is manual

The curl|bash entry point cannot be tested while the repo is private (anonymous curl will 404). It also cannot be tested against `localhost:python3 -m http.server` because the test must verify GitHub's actual raw.githubusercontent.com CDN behaviour for the actual `OliverGAllen/purplevoice` path. Oliver runs the one-liner from a fresh terminal AFTER the public flip and signs off.

## Prerequisites

- [ ] Plan 03-04 complete: `gh repo edit OliverGAllen/purplevoice --visibility public --accept-visibility-change-consequences` succeeded
- [ ] `gh repo view OliverGAllen/purplevoice --json visibility --jq '.visibility'` returns `"PUBLIC"`
- [ ] LICENSE present, README quickstart points at the production curl URL, SECURITY.md "Distribution model" subsection landed, brand+framing lints GREEN, full suite GREEN

## Steps

### Step 1 — Anonymous smoke test (no install)
1. Open a terminal that is NOT logged in to GitHub via Oliver's gh token (e.g., a fresh tmux window with `unset GH_TOKEN`, or an SSH session to a non-developer machine, or `incognito` browser fetching the URL).
2. `curl -fsSL https://raw.githubusercontent.com/OliverGAllen/purplevoice/main/install.sh | head -5`
3. **PASS criterion 1:** First 5 lines of install.sh print (shebang + comment header). NO 404, NO "Could not resolve host", NO timeout.

### Step 2 — Full curl|bash install on a clean-ish machine
4. **WARNING — this writes to ~/.local/share/purplevoice/src/.** If you already have a clone elsewhere, that's fine (curl|bash uses its own clone path).
5. `curl -fsSL https://raw.githubusercontent.com/OliverGAllen/purplevoice/main/install.sh | bash 2>&1 | tee /tmp/p3-curlbash.log`
6. **PASS criterion 2:** Banner says "PurpleVoice installer (via curl | bash)"; install.sh git-clones into `~/.local/share/purplevoice/src/`; install.sh re-execs from the clone; subsequent steps (Hammerspoon, sox, whisper-cpp, model, vocab, denylist, symlinks, SBOM, Karabiner check, banner) all run as if `bash install.sh` were invoked locally; exit 0.
7. **PASS criterion 3:** Final banner contains:
   - The `require("purplevoice")` paste line (DST-02 print-not-append)
   - F19 + backtick hotkey reminders (Phase 4 carryover)
   - HUD env var reminders (Phase 3.5 carryover)

### Step 3 — Idempotency on second curl|bash
8. Re-run the curl one-liner without changing anything.
9. **PASS criterion 4:** Banner says "existing clone at ~/.local/share/purplevoice/src — pulling latest..."; `git pull --ff-only` succeeds; install.sh re-executes; all idempotent steps print "already X / skipping"; exit 0.

## Sign-off

```
DST-05 curl|bash public install walkthrough — signed off YYYY-MM-DD by Oliver
- Anonymous smoke test (Step 1): PASS — first 5 lines of install.sh returned via curl
- Full curl|bash install (Step 2): PASS — clone + re-exec + final banner all correct
- Idempotency on re-run (Step 3): PASS — git pull + idempotent re-install
- gh repo view confirms PUBLIC: confirmed
```

## Failure modes

- Step 1 returns 404 → either repo is still PRIVATE (re-run `gh repo edit ... --visibility public --accept-visibility-change-consequences`) OR the URL is wrong-cased (Pitfall 2 — confirm `OliverGAllen/purplevoice` casing exactly).
- Step 2 banner says "PurpleVoice installer (local clone at...)" → curl-vs-clone detection is broken; install.sh thinks it's running from a clone when it isn't (RESEARCH §Pattern 1; debug `detect_invocation_mode`).
- Step 2 fails on "git: command not found" → user's machine lacks git (rare on macOS); install.sh's pre-flight error message should fire (RESEARCH §Pattern 2 fallback).
- Step 3 git pull fails → `--depth 1` + non-fast-forward (RESEARCH §Pitfall 3); printed instructions tell the user to `rm -rf` and re-run.
