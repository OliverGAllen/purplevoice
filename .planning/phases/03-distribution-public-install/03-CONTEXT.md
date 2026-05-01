# Phase 3: Distribution & Benchmarking + Public Install — Context

**Gathered:** 2026-05-01
**Status:** Ready for planning

<domain>
## Phase Boundary

**What this phase delivers:** Make PurpleVoice **reproducible** on a fresh machine via a single idempotent local installer (`install.sh`), **shareable online** via a one-line `curl ... | bash` public installer that resolves to the GitHub raw URL, **benchmarked** via `hyperfine` on Oliver's actual hardware to inform a Phase 5 (warm-process upgrade) go/no-go decision, AND **decided** on the Hammerspoon-as-PurpleVoice wrapping question (DST-06) — chosen path: bundled installer, no fork (Option B).

**Phase 3 IS:**
- A renamed `install.sh` (was `setup.sh`) — same idempotent steps + Karabiner check + brand migration; single canonical installer
- A short public-installer entry point on `https://raw.githubusercontent.com/OliverGAllen/purplevoice/main/install.sh` that git-clones the repo into a sensible location (e.g., `~/.local/share/purplevoice/src/`) and invokes `install.sh` locally
- An `uninstall.sh` script (new) that removes XDG dirs + symlinks + prints manual-removal instructions for the Hammerspoon `require()` line + Karabiner rules (does NOT auto-uninstall Hammerspoon/sox/etc — those may serve other tools)
- A `BENCHMARK.md` documenting hyperfine methodology + raw numbers + Phase 5 go/no-go decision
- 3 pre-recorded reference WAVs in `tests/benchmark/` (2s / 5s / 10s) for reproducible transcription-only benchmarks
- A rewritten README with **quickstart at top** (5-line one-liner) + **detailed install below** (TCC grants + Karabiner JSON imports + recovery procedures + uninstall walkthrough)
- A LICENSE file (MIT) added before the public flip
- The repo flipped PRIVATE → PUBLIC after install.sh + DST-06 (bundled-Hammerspoon flow) land in Wave 1-2, immediately before DST-05 (curl|bash) is end-to-end-tested

**Phase 3 is NOT:**
- A custom Hammerspoon fork (DST-06 Option A — rejected; ~1-2 weeks + ongoing upstream tracking)
- A renamed signed Hammerspoon binary (DST-06 Option C — rejected; same notarisation cost as A without the brand-control upside)
- Apple Developer ID + notarisation pipeline (SEC-04 from Phase 2.7 — REMAINS DEFERRED indefinitely; Option B doesn't need it)
- A vanity domain redirect (`get.purplevoice.com` or similar) — deferred; v1 uses GitHub raw URL
- A versioned tarball / GitHub release pipeline — deferred; v1 ships from `main`
- A scrubbed `.planning/` directory — kept visible as part of the audit-trail transparency story for the institutional audience
- An end-to-end benchmark harness (sim-release → paste timing) — deferred; v1 uses transcription-only benchmarks (Stage 2 dominates anyway)
- An auto-Homebrew bootstrap — bail with clear instructions if Homebrew missing (preserves minimal-deps + minimal-curl-trust ethos)

**Requirements covered:** DST-01, DST-02, DST-03, DST-04, DST-05, DST-06

**Success criteria (from ROADMAP.md):**
1. `./install.sh` on a clean machine installs Hammerspoon, sox, whisper-cpp, downloads `ggml-small.en.bin`, creates XDG dirs, symlinks `purplevoice-record` into `~/.local/bin/`. Re-running changes nothing; never clobbers user-edited config.
2. `install.sh` finishes by *printing* (never auto-appending) the exact `require("purplevoice")` line.
3. README walks through Microphone + Accessibility grant for Hammerspoon, macOS Dictation shortcut disable, and `tccutil reset Microphone org.hammerspoon.Hammerspoon` recovery procedure.
4. `hyperfine` produces p50 + p95 end-to-end latency numbers on Oliver's machine for short (~2s), medium (~5s), long (~10s) utterances; numbers explicitly inform a documented go/no-go decision for Phase 5.
5. Public one-line installer (`curl -fsSL https://raw.githubusercontent.com/OliverGAllen/purplevoice/main/install.sh | bash`) clones the repo and invokes the local `install.sh`. Public install is idempotent, prints next steps including the brand-aware `require()` line, and is documented in the README. Repo must be public on GitHub before this can pass.
6. DST-06 — Hammerspoon-as-PurpleVoice wrapping decision documented (Option B) and implemented (the bundled-installer flow IS the implementation).

</domain>

<decisions>
## Implementation Decisions

### DST-06 Hammerspoon Wrapping (D-01..D-03)

- **D-01: Option B — Bundled installer, no fork.** PurpleVoice ships as a Hammerspoon module that the installer drops into `~/.hammerspoon/purplevoice/` (existing pattern from setup.sh Step 6c). Hammerspoon stays as stock Hammerspoon — installed via brew cask, branded as Hammerspoon in TCC + Activity Monitor + Dock. README + install.sh openly disclose: *"PurpleVoice runs on Hammerspoon (free, open-source, BSD-3 / MIT licensed)."* Honest substrate framing aligns with Phase 2.7 D-17 ("compatible with" not "compliant"). Effort: ~1 day (mostly already done by setup.sh; Phase 3 mostly cleans + extends).
- **D-02: SEC-04 (Apple Developer ID + notarisation) STAYS DEFERRED indefinitely.** Option B doesn't need it. If the project later ships a notarised .pkg or moves to DST-06 Option A/C, SEC-04 returns. Document in SECURITY.md that PurpleVoice is currently distributed as source — not a notarised binary — and that this is a deliberate design choice for the audit-trail audience.
- **D-03: install.sh bails (exit non-zero) if Homebrew is missing.** Print: *"PurpleVoice needs Homebrew. Install via https://brew.sh/, then re-run."* Do NOT auto-bootstrap Homebrew (escalates curl-pipe-bash trust chain). Do NOT direct-download Hammerspoon.dmg (too much complexity for v1; Homebrew is on essentially every Mac developer's machine). Honest about the dep chain.

### DST-05 Public Installer (D-04..D-07)

- **D-04: Public installer URL = `https://raw.githubusercontent.com/OliverGAllen/purplevoice/main/install.sh`.** The script `curl|bash` runs IS `install.sh` itself (not a separate bootstrap). install.sh detects whether it's running from a clone or via curl-pipe; if via curl, it `git clone`s the repo into `~/.local/share/purplevoice/src/` (or equivalent), then proceeds with the install steps locally. Audit-friendly (URL points at versioned source); zero new infra (no DNS, no CDN); standard pattern matching oh-my-zsh, rust-up, etc.
- **D-05: Rename `setup.sh` → `install.sh`.** Single canonical idempotent installer. `git mv setup.sh install.sh`; update all internal references (README, SECURITY.md mentions, REQUIREMENTS.md, ROADMAP.md, prior phase SUMMARYs may mention setup.sh — leave historical refs intact, only update active surfaces). Roadmap success criterion 1 says `./install.sh` — this is the exact rename.
- **D-06: Repo flips PRIVATE → PUBLIC after install.sh + DST-06 (Option B implementation) land in Wave 1-2; before DST-05 (curl|bash) is end-to-end tested.** Tightest review window. Pre-flip checklist before the `gh repo edit --visibility public` flip:
  - LICENSE (MIT) added and committed
  - README quickstart points to the production curl URL (not a placeholder)
  - SECURITY.md SBOM reflects the bundled-installer Hammerspoon dep
  - Brand consistency lint GREEN
  - Framing lint GREEN
  - All `.planning/` content reviewed for anything that should NOT be public (note: per D-07 nothing is being scrubbed; this review is a sanity check on tone, not a redaction step)
- **D-07: Repo goes PUBLIC + MIT-licensed + `.planning/` directory stays visible.** MIT license added explicitly so others can legitimately fork (matches Hammerspoon's BSD-3 + the project's permissive ethos). `.planning/` is part of the audit-trail story — institutional adopters can see *why* every decision was made + what alternatives were considered + how deviations were handled. Aligns with Phase 2.7 honest-framing discipline. Auto-memory note ("PurpleVoice repo stays private by default; flip needs explicit reason") is honoured: DST-05 IS the explicit reason; the public flip is gated on the Wave 1-2 deliverables landing first.

### hyperfine Methodology + Phase 5 Trigger (D-08..D-10)

- **D-08: Methodology = transcription-only via hyperfine on 3 pre-recorded WAVs.** `hyperfine 'whisper-cli -m ~/.local/share/purplevoice/models/ggml-small.en.bin -f tests/benchmark/2s.wav -nt'` (and similar for 5s.wav + 10s.wav). Each length: 10 runs, 3 warmup runs (hyperfine defaults). Ship the 3 reference WAVs in `tests/benchmark/` (commit them; ~50KB each at 16kHz mono; reproducible). Honest scope: measures Stage 2 (transcription latency — the dominant + variable component). Stages 1 (recording, user-bound) + 3 (paste, near-constant) are NOT measured. Reproducible by anyone with the repo + the model file (which install.sh handles).
- **D-09: Phase 5 trigger = `p50 > 2s OR p95 > 4s on the 5s.wav benchmark`.** Concrete numerical gate aligned with the project's "under ~2 seconds" goal (PROJECT.md Constraints). p50 captures typical experience; p95 catches worst-case frustrations. 5s utterances are the "normal use" anchor. Trigger is binary — measurements either cross or they don't. Documented in BENCHMARK.md as the Phase-5 go/no-go decision rule. If Oliver's machine produces p50 ≤ 2s + p95 ≤ 4s → Phase 5 stays deferred; if either crosses → Phase 5 becomes active scope.
- **D-10: Results land in dedicated `BENCHMARK.md` + README link.** BENCHMARK.md captures: hyperfine command for each benchmark (reproducible), raw numbers (min / max / mean / median / p95 / std-dev), the Phase-5 go/no-go decision, environment (macOS version, Apple Silicon model, model file SHA256). README has a brief "Performance" section with headline numbers (p50 / p95 for each length) + link to BENCHMARK.md. SECURITY.md unchanged (perf isn't security; Phase 2.7 framing-lint sensitivity stays scoped to security claims).

### README + Recovery Flow (D-11..D-12)

- **D-11: README onboarding = quickstart at top + detailed install below.** First section ("## Install"): 5-line quickstart for the curl|bash one-liner + "now hold fn to record / hold ` to re-paste." Second section ("## Detailed Install"): full walkthrough — Karabiner-Elements installation + JSON imports (both fn→F19 and backtick→F18) + TCC grants for Hammerspoon (Microphone + Accessibility) + macOS Dictation shortcut disable + recovery procedures + uninstall walkthrough. Best of both worlds for "I just want it" users + institutional reviewers.
- **D-12: README recovery section covers all 4 items:**
  1. **TCC reset:** `tccutil reset Microphone org.hammerspoon.Hammerspoon` + same for Accessibility. The "permissions are stuck weirdly" fix.
  2. **Karabiner rule troubleshoot:** Phase 4 deviation lessons codified. UK keyboard → `non_us_backslash`; ANSI/US → `grave_accent_and_tilde`. How to use Karabiner Event Viewer to diagnose. How to spot "Hammerspoon binding silently consumed" (no load alert; the binding looks registered but the keystroke never arrives — Phase 4 cmd+shift+v lesson).
  3. **"I lost my hotkeys" decision-tree triage:** (1) Reload Hammerspoon, (2) check Karabiner-Elements menubar icon, (3) check both rules enabled in Karabiner Preferences → Complex Modifications, (4) Karabiner Event Viewer key codes match what the JSONs expect, (5) check init.lua for binding-failed alerts at last load. Decision-tree style; user-friendly for non-developers.
  4. **`uninstall.sh` script:** New. Removes `~/.config/purplevoice/`, `~/.local/share/purplevoice/`, `~/.cache/purplevoice/`, the symlink in `~/.local/bin/`, and `~/.hammerspoon/purplevoice/`. Prints: *"Now manually remove the `require('purplevoice')` line from ~/.hammerspoon/init.lua + the Karabiner rules from Preferences → Complex Modifications. Hammerspoon, sox, and whisper-cpp were left installed (they may be used by other tools)."* Idempotent (re-running on a fresh machine prints "already removed" + exits 0).

### Claude's Discretion

- **Where exactly install.sh git-clones to** when invoked via curl|bash. Recommendation: `~/.local/share/purplevoice/src/`. Other reasonable options: `~/.purplevoice/`, `/usr/local/src/purplevoice/`. Planner picks based on XDG conventions + existing setup.sh paths.
- **Exact wording of the brew-missing actionable error** (D-03). Keep concise, link to https://brew.sh/, recommend `xcode-select --install` first if needed.
- **WAV reference content** for the 3 benchmark files. Recommendation: use synthetic TTS (`say` command on macOS) with consistent text — e.g., 2s.wav = "this is a quick test", 5s.wav = "this is a longer benchmark sentence for the small model", 10s.wav = "this is the longest benchmark utterance designed to stress the medium-quality transcription path with multiple clauses and natural punctuation". Reproducible (everyone gets the same WAV from `say -v`).
- **install.sh detection of curl-vs-clone** (D-04). Recommendation: check if `$0` resolves to a path inside a git checkout vs `bash -c` invocation. Standard idiom: `if [ -d "$REPO_ROOT/.git" ]; then echo "running from clone"; else echo "running via curl"; git clone ...; fi`. Planner refines.
- **Whether `uninstall.sh` should also remove the Karabiner rule files** from `~/.config/karabiner/assets/complex_modifications/`. Recommendation: NO (don't touch user's Karabiner config; print instructions to do it manually if desired). Less destructive default.
- **README "Performance" section presentation** — table vs prose, raw numbers vs ranges. Recommendation: small table with p50/p95 columns for each utterance length, then a one-line "On Oliver's M-series MacBook Pro, all measurements are well under the 2s target — Phase 5 deferred." Planner adapts to actual benchmark results.

### Pre-Existing Bugs Phase 3 Sweeps Up (D-13 — added 2026-05-01 post-research)

- **D-13: GitHub owner casing typo across the codebase.** Research surfaced (via `gh repo view`) that the actual GitHub owner is `OliverGAllen`, not `oliverallen`. Pre-existing wrong-cased references that Phase 3 must sweep:
  - `setup.sh` line 363 — SBOM `documentNamespace` URL hardcoded to `https://github.com/oliverallen/PurpleVoice/sbom/...` (Phase 2.7 deliverable; pre-dates Phase 3 by ~30 days). Currently produces a non-resolving SBOM URL but doesn't cause functional failure (verify_sbom.sh doesn't HTTP-resolve the namespace).
  - `SECURITY.md` line 710 — clone instruction `git clone https://github.com/oliverallen/PurpleVoice.git` would 404 on a fresh user's machine (pre-existing).
  - All Phase 3 deliverables (install.sh, README quickstart, BENCHMARK.md, uninstall.sh, LICENSE) MUST use the correct casing `OliverGAllen/purplevoice`.
  - Sweep is mechanical; one consolidated commit OR fold into the Wave 1 install.sh rename commit.

### Folded Todos

None — `gsd-tools todo match-phase 3` returned `todo_count: 0`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Context
- `.planning/PROJECT.md` — Vision, "Local voice dictation. Nothing leaves your Mac." ethos, audience constraints (one-user; institutional / privacy-first / air-gapped audiences validated by Phase 2.7).
- `.planning/REQUIREMENTS.md` §"Distribution" — DST-01..DST-04 prior reqs; DST-05 (TBD) public one-line installer; DST-06 (TBD) Hammerspoon wrapping decision.
- `.planning/ROADMAP.md` §"Phase 3: Distribution & Benchmarking + Public Install" — full success criteria including the 6-criterion list and the embedded DST-06 A/B/C trade-off table.

### Prior phase decisions (carried forward — locked)
- `.planning/phases/01-spike/01-CONTEXT.md` — Phase 1 D-01 (cmd+shift+e — superseded by F19 in Phase 4); D-02 (Hammerspoon `require()` load pattern — install.sh prints the line); D-03 (XDG paths originally `voice-cc`, rebranded to `purplevoice` per Phase 2.5).
- `.planning/phases/02.5-branding/02.5-CONTEXT.md` — D-02 (PurpleVoice brand for institutional / privacy-first audiences); D-03/D-05 (XDG paths use `purplevoice` namespace); D-06+ (brand consistency hook + framing lint).
- `.planning/phases/02.7-security-posture/02.7-CONTEXT.md` — D-17 ("compatible with" framing not "compliant"); D-08 (PURPLEVOICE_OFFLINE=1 air-gap mode); SEC-04 deferred (Apple notarisation — Phase 3 confirms STAYS DEFERRED per D-02).
- `.planning/phases/03.5-hover-ui-hud/03.5-CONTEXT.md` — D-11 (env-var-only config, no runtime toggle hotkey); D-14 (honest framing about ScreenCaptureKit limitation — same discipline applies to install/perf claims here).
- `.planning/phases/04-quality-of-life-v1-x/04-CONTEXT.md` — D-05 (F19 only, cmd+shift+e removed); D-06 (Karabiner JSON file path); D-07 (setup.sh "Document + check" pattern — Step 9 lives in install.sh after the rename); D-08 (PURPLEVOICE_OFFLINE=1 interaction with Karabiner check); D-02-SUPERSEDED (F18-via-backtick-hold for re-paste). The Karabiner discipline established in Phase 4 carries directly into Phase 3's install.sh.

### External / Karabiner-Elements (Phase 4 carryover; install.sh references)
- `https://karabiner-elements.pqrs.org/` — Karabiner-Elements home + download (referenced in install.sh actionable error)
- `assets/karabiner-fn-to-f19.json` (Phase 4 / Plan 04-02-01) — F19 push-to-talk rule
- `assets/karabiner-backtick-to-f18.json` (Phase 4 / D-02-SUPERSEDED deviation) — F18 re-paste rule

### External / Distribution patterns to mirror
- `https://github.com/Homebrew/install/blob/HEAD/install.sh` — Homebrew's curl|bash installer; reference for idiomatic bash detection of curl-vs-clone, idempotency, error handling
- `https://github.com/ohmyzsh/ohmyzsh/blob/master/tools/install.sh` — oh-my-zsh's installer; reference for the "git clone + invoke" pattern
- `https://github.com/sharkdp/hyperfine` — hyperfine docs + flags (reference for D-08 benchmark commands)

### Existing code that Phase 3 builds on (most is already-done; Phase 3 mostly renames + extends)
- `setup.sh` (~470 lines, 10 idempotent steps) — renamed to `install.sh` per D-05; existing logic mostly preserved
- `purplevoice-record` (Pattern 2 — `grep -c WHISPER_BIN purplevoice-record == 2` invariant; do NOT modify)
- `purplevoice-lua/init.lua` (Pattern 2 corollary — no whisper-cli refs; do NOT modify outside specific Phase 3 needs)
- `assets/icon-256.png`, `assets/karabiner-*.json` — bundled assets; install.sh symlinks/copies as needed
- `tests/test_brand_consistency.sh` — pre-commit hook; ensure all new content (LICENSE, BENCHMARK.md, uninstall.sh, README rewrites) has zero `voice-cc` strings
- `tests/test_security_md_framing.sh` — framing lint; SECURITY.md updates must avoid `compliant`/`certified`/`guarantees` without qualifier
- `tests/run_all.sh` + `tests/security/run_all.sh` — current state 11/0 + 5/0; Phase 3 must preserve and ideally extend

### Repo + License (Phase 3 deliverables)
- `LICENSE` (NEW) — MIT license, added before public flip per D-06/D-07
- `BENCHMARK.md` (NEW) — hyperfine methodology + raw numbers + Phase 5 go/no-go per D-08..D-10
- `uninstall.sh` (NEW) — XDG dir + symlink removal + manual-removal instructions per D-12
- `tests/benchmark/2s.wav`, `tests/benchmark/5s.wav`, `tests/benchmark/10s.wav` (NEW) — pre-recorded reference WAVs per D-08

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`setup.sh`** — 10 idempotent steps already in place. Phase 3 renames (D-05) + extends with curl-vs-clone detection (D-04) + adds detection-mode banner. Most of the work is already done; Phase 3 polish + the public-installer flow.
- **`purplevoice-record`** — bash glue, untouched in Phase 3 (Pattern 2 invariant).
- **`purplevoice-lua/init.lua`** — Phase 4 deliverable, untouched in Phase 3 except for any reference/path updates the rename might cascade.
- **`assets/karabiner-*.json`** — Phase 4 deliverables, install.sh references in Step 9 (already wired).
- **`SECURITY.md`** (761 lines) — Phase 2.7 deliverable, install.sh + README link to it. Phase 3 may add a short "Distribution model" subsection clarifying the bundled-installer / Option B stance + the deferred SEC-04 status.
- **`SBOM.spdx.json`** — Phase 2.7 deliverable, regenerated by install.sh Step 8 idempotently.
- **`tests/test_brand_consistency.sh`** — pre-commit hook; LICENSE + BENCHMARK.md + uninstall.sh + README rewrites must all pass.
- **`tests/test_security_md_framing.sh`** — framing lint; SECURITY.md updates must pass.
- **`tests/run_all.sh` + `tests/security/run_all.sh`** — 11/0 + 5/0 baseline.

### Established Patterns

- **Idempotent step pattern** — Each setup.sh step checks state before acting (e.g., `brew list X &>/dev/null`); no-clobber for user config; safe to re-run. Phase 3 install.sh inherits this; uninstall.sh mirrors (re-run prints "already removed" + exits 0).
- **Brand migration step** (setup.sh Step 3b) — Already idempotent voice-cc → purplevoice. Phase 3 keeps this for users upgrading from the working-name era.
- **Karabiner check + actionable-error pattern** (setup.sh Step 9, Phase 4) — install.sh inherits verbatim. Both JSON file paths referenced.
- **Final banner pattern** (setup.sh Step 10) — Phase 3 install.sh banner mentions: F19 record, ` (backtick) re-paste, BENCHMARK.md link, recovery section in README.
- **"Document + check" honest framing** (Phase 4 D-07) — install.sh refuses to declare install complete without dependencies (Karabiner). Phase 3 may add similar gates for `git` (clone path requires it) and `curl` (one-liner requires it).
- **Pre-commit hook discipline** — `tests/test_brand_consistency.sh` blocks commits with `voice-cc` strings; `tests/test_security_md_framing.sh` blocks framing-lint violations. New Phase 3 files honour this.

### Integration Points

- **install.sh entry point** — `install.sh` is invoked two ways: (1) via `curl|bash` (detects curl context, git-clones repo, then proceeds); (2) via local clone (already in repo, just runs steps). Detection logic: check whether `$0` resolves to a file inside a git checkout.
- **`~/.local/share/purplevoice/src/`** — recommended clone destination for the curl|bash path. Standard XDG location.
- **`~/.local/bin/purplevoice-record` symlink** — install.sh Step 6c (already exists). Public installer + local installer both produce the same final state.
- **`~/.hammerspoon/purplevoice/`** — Lua module destination. Existing pattern from setup.sh Step 6c.
- **`~/.config/purplevoice/`** + **`~/.cache/purplevoice/`** + **`~/.local/share/purplevoice/`** — XDG paths (Phase 2.5 D-03/D-05).
- **`~/.config/karabiner/assets/complex_modifications/`** — Karabiner JSON drop location (referenced in Phase 4 Step 9 actionable error; install.sh may also auto-copy if Karabiner is detected, OR keep manual-import per Phase 4 D-07's "minimal automation" stance — planner refines).
- **README hotkey table + setup.sh banner** — Phase 4 final state: F19 (record), backtick-hold (re-paste). Phase 3 README rewrite preserves these references.

### Constraints

- **Pattern 2 invariant** — `grep -c WHISPER_BIN purplevoice-record == 2`. Phase 3 does NOT modify purplevoice-record.
- **Pattern 2 corollary** — `! grep -q whisper-cli purplevoice-lua/init.lua`. Phase 3 does NOT modify init.lua.
- **Brand consistency** — no new `voice-cc` strings in any Phase 3 deliverable (LICENSE, BENCHMARK.md, README rewrites, install.sh, uninstall.sh, tests/benchmark/*).
- **Framing lint** — no `compliant`/`certified`/`guarantees` in SECURITY.md without qualifier. Phase 3 may add a "Distribution model" subsection there; must pass lint.
- **Functional + security suites GREEN** — `bash tests/run_all.sh` 11/0 + `bash tests/security/run_all.sh` 5/0 throughout.
- **No `setup.sh` references in active surfaces after the rename** — all README, SECURITY.md, REQUIREMENTS.md, ROADMAP.md mentions update to `install.sh`. Historical phase artifacts (prior CONTEXT.md, SUMMARY.md) leave `setup.sh` references intact (audit trail).
- **Repo privacy auto-memory honoured** — flip is gated on Wave 1-2 deliverables landing; explicit reason (DST-05) documented; not flipping silently.

</code_context>

<specifics>
## Specific Ideas

- **Honest substrate framing throughout** — Phase 3 documentation openly says "PurpleVoice is a Hammerspoon module shipped with a bundled installer; Hammerspoon is the underlying runtime." This is NOT a hidden cost — it's the audit-trail story. Institutional adopters care that you're not pretending to be a standalone .app when you're a Lua module.
- **The README quickstart should be SHORT enough to fit on one screen** (~10-15 lines including the curl one-liner + the hotkey reference + a "now go to detailed install" pointer). Pattern matched: oh-my-zsh README quickstart, Homebrew README quickstart.
- **BENCHMARK.md is a future-tense doc until Wave 3-ish** — written with the Phase 5 trigger gate explicitly stated; numbers populated only after install.sh + Hammerspoon module are wired and Oliver runs the benchmarks on his machine. The doc structure should make adding new measurements easy (a table per measurement run, with date + machine + numbers).
- **The Karabiner-rule-not-enabled troubleshoot section in README should reference the Phase 4 deviation lesson explicitly** — "If your hotkey isn't working after install, check Karabiner Event Viewer; UK keyboards need `non_us_backslash`, ANSI/US need `grave_accent_and_tilde`. The shipped JSON uses `non_us_backslash`."
- **Sensible "where to clone" default for the curl path** — `~/.local/share/purplevoice/src/` follows XDG conventions and matches the existing `~/.local/share/purplevoice/models/` pattern. Easy to find, doesn't pollute `$HOME`, doesn't need root.
- **Repo-flip checklist (D-06)** is operationally important — if DST-05 testing happens before any of those items land, it'll fail loudly (e.g., the README quickstart points at a private repo that returns 404 to anonymous curl). The plan should make this checklist a hard gate before the `gh repo edit --visibility public` task.
- **MIT license is the audit-friendly default** — matches Hammerspoon's BSD-3-clause permissiveness; no GPL transitivity concerns; widely understood by institutional review boards. Fastly/standard `LICENSE` text from https://opensource.org/license/mit.

</specifics>

<deferred>
## Deferred Ideas

### Items raised during discussion but explicitly out of scope for Phase 3

- **DST-06 Option A (custom Hammerspoon fork)** — rejected per D-01. Maintenance burden + Apple Dev ID + notarisation costs not worth the brand-polish gain for v1. May revisit at v2 / v1.5 if institutional adopters specifically request a standalone .app.
- **DST-06 Option C (hybrid signed-binary rename)** — rejected per D-01. Same notarisation cost as Option A without the upstream-control benefit. Some Gatekeeper risk with renamed binaries.
- **SEC-04 — Apple Developer ID + notarisation pipeline** — STAYS DEFERRED indefinitely per D-02. Returns to active scope only if Phase 3 ships a notarised .pkg or a future phase moves to DST-06 Option A/C.
- **Vanity domain redirect (`get.purplevoice.com` or similar)** — deferred. v1 uses GitHub raw URL; vanity domain may land at v1.5+ when there's a brand presence to justify the DNS/CDN setup.
- **GitHub Releases with versioned tarballs** — deferred. v1 ships from `main`; release-tagging discipline + tarball pipeline is over-engineering for the audience-of-one-plus-curious-strangers stage.
- **Auto-bootstrap Homebrew on missing-Homebrew** — rejected per D-03. Bail-with-instructions preserves the minimal-curl-trust ethos.
- **End-to-end benchmark harness (sim-release → paste timing)** — deferred per D-08. v1 measures transcription-only (Stage 2 dominates). May land at v2 if Stage 1/3 latency becomes a real complaint.
- **BENCHMARK.md SECURITY.md mirroring** — rejected per D-10. Performance isn't security; framing-lint scope stays clean. README + BENCHMARK.md is enough.
- **Scrubbing `.planning/` from git history** — rejected per D-07. Audit-trail transparency is the win; nothing in `.planning/` is sensitive enough to warrant a destructive history rewrite.
- **Source-available license (vs MIT)** — considered, rejected per D-07. MIT signals clearer intent + matches Hammerspoon's permissiveness.
- **Private-repo + release-tarball-only distribution** — considered, rejected per D-07 after Oliver realised the source is unavoidably visible in the tarball regardless. Public + MIT is the cleaner stance.
- **Auto-uninstall of Hammerspoon/sox/whisper-cpp** — rejected per D-12. uninstall.sh leaves these installed (they may serve other tools). Print instructions instead.
- **Auto-removal of Karabiner rule JSONs** — Claude's Discretion per the Karabiner notes; recommendation is NO (don't touch user's Karabiner config). Planner refines if warranted.

### Reviewed Todos (not folded)

None — `gsd-tools todo match-phase 3` returned `todo_count: 0`.

</deferred>

---

*Phase: 03-distribution-public-install*
*Context gathered: 2026-05-01*
