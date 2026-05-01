# Phase 3: Distribution & Benchmarking + Public Install — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-01
**Phase:** 03-distribution-public-install
**Areas discussed:** DST-06 wrapping + notarisation, DST-05 hosting + repo-public timing, hyperfine methodology + Phase 5 trigger, README + recovery flow depth

---

## Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| DST-06 wrapping + notarisation | A/B/C wrapping options + notarisation coupling | ✓ |
| Public installer hosting + repo-public timing (DST-05) | URL hosting + install.sh ↔ setup.sh + public flip timing | ✓ |
| hyperfine methodology + Phase 5 trigger | Benchmark approach + reporting + trigger threshold | ✓ |
| README + recovery flow depth | Onboarding depth + recovery procedures | ✓ |

**User's choice:** All 4 areas
**Notes:** Comprehensive coverage of phase scope.

---

## DST-06 Wrapping + Notarisation

### Q1: Which DST-06 wrapping option for Phase 3?

| Option | Description | Selected |
|--------|-------------|----------|
| B — Bundled installer, no fork (Recommended) | Stock Hammerspoon + purplevoice-lua/ via install.sh; ~1 day; honest substrate; defers SEC-04 | ✓ |
| A — Custom Hammerspoon fork | PurpleVoice.app with own bundle ID; ~1-2 weeks + maintenance; requires Apple Dev ID | |
| C — Hybrid signed-binary rename | Copy + rewrite Info.plist + re-sign; ~3-5 days; same notarisation cost as A | |

**User's choice:** B — Bundled installer, no fork
**Notes:** Aligns with Phase 2.7 honest-framing discipline + minimal-deps ethos + audience-of-one-plus-institutional-curious resource budget.

### Q2: On a fresh machine without Homebrew installed, what should the public installer do?

| Option | Description | Selected |
|--------|-------------|----------|
| Bail with clear instructions (Recommended) | Detect missing brew, print instructions to install via brew.sh, exit non-zero | ✓ |
| Auto-bootstrap Homebrew | Run the official Homebrew installer; smoother but escalates curl-pipe-bash trust chain | |
| Direct .dmg + tarball downloads (no brew) | Skip Homebrew entirely; download Hammerspoon.dmg + sox tarball + whisper-cpp tarball directly | |

**User's choice:** Bail with clear instructions
**Notes:** Honest about the dep chain; preserves minimal-curl-trust ethos.

---

## DST-05 Public Installer Hosting + Repo-Public Timing

### Q1 (initial): Where does `curl -fsSL https://X | bash` resolve to?

User responded with a clarifying question instead of selecting an option:
> "if the repo is pbulic for the install can they copy all files and recreate it or is it only the install part?"

This triggered an explanatory response covering:
- What becomes visible when the repo flips public (source, history, .planning/)
- The unavoidable visibility of source code inside the tarball regardless of repo-private vs public
- Three meaningful stances: public + MIT vs public + scrub-history vs source-available vs private + tarball-only

### Q2: How should `install.sh` (new) relate to `setup.sh` (existing)?

| Option | Description | Selected |
|--------|-------------|----------|
| Rename setup.sh → install.sh (Recommended) | Single canonical idempotent installer; matches roadmap success criterion 1 wording | ✓ |
| Keep setup.sh, add install.sh as wrapper | install.sh = thin shim that clones + runs setup.sh; two-step indirection | |
| Split: install.sh = bootstrap, setup.sh = dev | Different audiences, different responsibilities; cleanest separation but most surface | |

**User's choice:** Rename setup.sh → install.sh
**Notes:** Single source of truth.

### Q3: When in Phase 3 does the repo flip from PRIVATE → PUBLIC?

| Option | Description | Selected |
|--------|-------------|----------|
| After install.sh + DST-06 land, before DST-05 testing (Recommended) | Tightest review window; minimises pre-flip exposure | ✓ |
| At Phase 3 start (before any work) | Maximum transparency; surfaces in-progress messy commits during build | |
| At v1 release-gate (very end of Phase 3) | Most controlled exposure; requires private-repo token-auth path through DST-05 testing | |

**User's choice:** After install.sh + DST-06 land, before DST-05 testing
**Notes:** Pre-flip checklist documented in CONTEXT.md D-06 (LICENSE added, README updated, lints GREEN, .planning/ tone-reviewed).

### Q4 (clarifying): Given the trade-offs on public-vs-private, what's your stance?

| Option | Description | Selected |
|--------|-------------|----------|
| Public + MIT license + keep .planning/ visible (Recommended) | Full transparency; .planning/ as audit-trail aligned with Phase 2.7 audience | (initially declined; revisited after clarification) |
| Public + MIT license + filter-repo .planning/ from history | Source visible + permissively licensed but design history scrubbed | |
| Public + 'source available' (no permissive license) | Visible to all but legally restricted; harder to enforce | |
| Stay private — distribute via release tarball downloads only | Source repo private; public installer downloads pre-built tarballs | (initial pick) |

**User's initial choice:** Stay private — distribute via release tarball downloads only

After explanation that the source code is unavoidably visible inside the tarball regardless of repo privacy:

### Q5 (re-pose): Given the source is unavoidably in the tarball, is private-repo + release-tarball still your call?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — hiding git history + .planning/ is the goal | Stand by private-repo + release-tarball; value is hiding design discussions | |
| Switch to Public + MIT license + keep .planning/ visible | Audit-trail transparency angle wins | ✓ |
| Switch to Public + MIT license + scrub .planning/ from history | Compromise: hide design notes but accept source visibility + permissive license | |

**User's choice:** Switch to Public + MIT license + keep .planning/ visible
**Notes:** Once source-visibility-via-tarball was clarified, the audit-trail transparency angle of public + MIT became the clearer stance. Aligns with Phase 2.7 institutional audience discipline.

### Q6 (re-pose Q1): Where does `curl -fsSL https://X | bash` resolve to?

| Option | Description | Selected |
|--------|-------------|----------|
| GitHub raw URL on main (Recommended) | https://raw.githubusercontent.com/oliverallen/purplevoice/main/install.sh; install.sh git-clones repo + runs locally | ✓ |
| GitHub release tarball download | Pinned-version installs; requires release-tagging discipline | |
| Vanity domain redirect (e.g. get.purplevoice.com) | Cleaner URL; requires DNS setup; deferred to v1.5+ | |

**User's choice:** GitHub raw URL on main
**Notes:** Zero infra, audit-friendly, standard pattern matching oh-my-zsh / rust-up.

---

## hyperfine Methodology + Phase 5 Trigger

### Q1: Which hyperfine measurement approach?

| Option | Description | Selected |
|--------|-------------|----------|
| A — Transcription-only on pre-recorded WAVs (Recommended) | hyperfine 'whisper-cli ... < input.wav'; ship 3 reference WAVs; honest scope | ✓ |
| B — End-to-end harness (sim release → paste) | Custom harness; ~3-5 days extra; closer to user-perceived latency | |
| Both | Ship A as canonical + B as one-off measurement | |

**User's choice:** A — Transcription-only on pre-recorded WAVs
**Notes:** Stage 2 (transcription) dominates anyway; reproducible by anyone with the repo.

### Q2: What threshold triggers Phase 5 (warm-process upgrade)?

| Option | Description | Selected |
|--------|-------------|----------|
| p50 > 2s OR p95 > 4s on 5s utterances (Recommended) | Concrete numerical gate aligned with PROJECT.md "under ~2 seconds" goal | ✓ |
| Subjective — 'feels sluggish in daily use' | Skip numeric gate; matches audience-of-one constraint | |
| p50 > 1.5s OR p95 > 3s (more aggressive) | Tighter gate; risks over-triggering Phase 5 | |

**User's choice:** p50 > 2s OR p95 > 4s on 5s utterances
**Notes:** Binary trigger; documented as Phase-5 go/no-go decision rule in BENCHMARK.md.

### Q3: Where do benchmark results land?

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated BENCHMARK.md + README link (Recommended) | Full methodology + raw numbers + Phase 5 decision in BENCHMARK.md; brief README "Performance" section | ✓ |
| README only (inline performance section) | Skip dedicated file; numbers + brief methodology in README | |
| README + SECURITY.md performance note | Numbers in README; methodology mirrored to SECURITY.md | |

**User's choice:** Dedicated BENCHMARK.md + README link
**Notes:** Clean separation; performance isn't security; easiest to update over time.

---

## README + Recovery Flow Depth

### Q1: README onboarding depth?

| Option | Description | Selected |
|--------|-------------|----------|
| Both — quickstart top, detailed install below (Recommended) | 5-line quickstart + full walkthrough; serves both quick-install and institutional-reviewer audiences | ✓ |
| Quickstart only (5 lines) | Minimal README; details pushed elsewhere | |
| Full walkthrough only (no quickstart shortcut) | No quickstart shortcut; safest for non-developers; tedious for power users | |

**User's choice:** Both — quickstart top, detailed install below
**Notes:** Best of both worlds; matches the audience mix (developer-power-users + institutional reviewers).

### Q2 (multi-select): What recovery procedures should the README document?

| Option | Description | Selected |
|--------|-------------|----------|
| tccutil reset Microphone + Accessibility (Recommended) | Standard "permissions stuck" fix; already in roadmap success criterion 3 | ✓ |
| Karabiner rule not enabled / wrong key code troubleshoot | Phase 4 deviation lesson codified; UK vs ANSI keyboard key codes | ✓ |
| 'I lost my hotkeys' triage flowchart | Decision-tree style for non-developer audiences | ✓ |
| Uninstall script | New uninstall.sh removing XDG dirs + symlinks + manual instructions for Hammerspoon line + Karabiner rules | ✓ |

**User's choice:** All 4 recovery items
**Notes:** Comprehensive recovery + uninstall surface for the institutional audience.

---

## Done Check

### Q: Anything still unclear?

| Option | Description | Selected |
|--------|-------------|----------|
| I'm ready for context (Recommended) | Decisions clear; write CONTEXT.md | ✓ |
| Explore more gray areas | Surface 2-4 additional gray areas | |

**User's choice:** I'm ready for context

---

## Claude's Discretion (captured in CONTEXT.md)

- Where exactly install.sh git-clones to (recommendation: `~/.local/share/purplevoice/src/`)
- Exact wording of brew-missing actionable error
- WAV reference content for the 3 benchmark files (recommendation: synthetic TTS via `say`)
- install.sh detection of curl-vs-clone idiom
- Whether uninstall.sh removes Karabiner rule JSONs (recommendation: NO — don't touch user's Karabiner config)
- README "Performance" section presentation (table vs prose; raw numbers vs ranges)

---

## Deferred Ideas (captured in CONTEXT.md)

- DST-06 Option A (custom Hammerspoon fork) — rejected
- DST-06 Option C (hybrid signed-binary rename) — rejected
- SEC-04 — Apple Developer ID + notarisation — STAYS DEFERRED indefinitely
- Vanity domain redirect — deferred to v1.5+
- GitHub Releases with versioned tarballs — deferred
- Auto-bootstrap Homebrew — rejected
- End-to-end benchmark harness — deferred
- BENCHMARK.md SECURITY.md mirroring — rejected
- Scrubbing .planning/ from git history — rejected (audit-trail transparency wins)
- Source-available license (vs MIT) — rejected
- Private-repo + release-tarball-only distribution — rejected after clarification
- Auto-uninstall of Hammerspoon/sox/whisper-cpp — rejected
- Auto-removal of Karabiner rule JSONs — Claude's Discretion (recommendation: NO)
