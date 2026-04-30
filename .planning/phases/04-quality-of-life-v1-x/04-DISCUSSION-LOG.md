# Phase 4: Quality of Life (v1.x) — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in `04-CONTEXT.md`.

**Date:** 2026-04-30
**Phase:** 04-quality-of-life-v1-x
**Mode:** discuss (interactive, no advisor mode — no USER-PROFILE.md)
**Areas discussed:** Trigger inventory (scope), Brand carryover, Alternative hotkey, History log design

---

## Pre-discussion: ROADMAP parser fix

The `### Phase 4 (v1.x): Quality of Life` header tripped the gsd-tools parser (`(v1.x)` parens before colon). Renamed to `### Phase 4: Quality of Life (v1.x)` (suffix form). Same fix applied to Phase 5. Committed as `75e9fd4`.

---

## Trigger Inventory (Part 1 — 4 items)

| Option | Description | Selected |
|--------|-------------|----------|
| QOL-01: paste-last-transcript hotkey | Lost transcript when focus shifted mid-record | ✓ |
| QOL-02: Esc cancels in-flight recording | Abort press-hold without paste | |
| QOL-03: replacements.txt find/replace | Recurring mistranscriptions | |
| QOL-04: rolling history log | Recall earlier transcripts | |

**User's choice:** QOL-01 only.

## Trigger Inventory (Part 2 — 2 remaining + decline)

| Option | Description | Selected |
|--------|-------------|----------|
| QOL-05: PURPLEVOICE_MODEL runtime swap | Test alt models without code edits | |
| Alt hotkey: fn-press-and-hold or F19 | cmd+shift+e collisions annoy | |
| None of these triggered yet | Defer both | |
| Other (free text) | "lets set it up to run on fn can remapp it to f19" | ✓ |

**User's free-text response:** "lets set it up to run on fn can remapp it to f19" — interpreted as: alt hotkey IS triggered; user wants Karabiner-Elements to remap fn → F19; F19 becomes the PurpleVoice trigger.

**Net trigger inventory:** QOL-01 + alt hotkey (Karabiner fn→F19). Other 4 items defer to v2 / backlog.

---

## QOL-01 — Re-paste Hotkey Choice

| Option | Description | Selected |
|--------|-------------|----------|
| cmd+shift+v (Recommended) | Pairs with cmd+v; risk: Paste and Match Style collision | ✓ |
| cmd+option+e | Mirrors cmd+shift+e with modifier swap | |
| Same as alt hotkey approach | shift+F19 or cmd+F19 | |
| You decide | Pick during planning | |

**User's choice:** cmd+shift+v (Recommended)

## QOL-01 — Last Transcript Storage

| Option | Description | Selected |
|--------|-------------|----------|
| In-memory Lua only (Recommended) | Module-scope variable; lost on reload | ✓ |
| Persistent at ~/.cache/purplevoice/last.txt | Survives reload; privacy implication | |
| Both: in-memory + persistent fallback | More code; slightly better recovery | |

**User's choice:** In-memory Lua only (Recommended)

---

## Alt Hotkey — Replace vs Both

| Option | Description | Selected |
|--------|-------------|----------|
| Both active (Recommended) | F19 primary; cmd+shift+e fallback | |
| Replace cmd+shift+e with F19 only | Cleaner; requires Karabiner | |
| F19 default + env var fallback | More config surface | |
| Other (free text) | "we make it f19 only and include karabiner in the install" | ✓ |

**User's free-text response:** "we make it f19 only and include karabiner in the install" — interpreted as: F19 ONLY (replace cmd+shift+e completely) + Karabiner is part of the install flow (mechanism TBD via next question).

## Alt Hotkey — Karabiner Integration Mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Document only, no automation (Recommended) | setup.sh + README explain; user installs manually | ✓ (initial pick) |
| Detect + warn | setup.sh checks Karabiner.app presence; warns + prints rule | |
| Auto-install via brew cask | brew install --cask karabiner-elements | |
| Skip Karabiner; use raw hs.eventtap.flagsChanged | Documented race risk | |

**User's initial choice:** Document only (Recommended).

**Tension surfaced and clarified:** F19-only + Document-only would leave fresh users with broken hotkey until manual Karabiner install. Claude asked plain-text follow-up:

> "Three ways to interpret your 'include karabiner in the install':
> 1. Document + check — setup.sh checks Karabiner.app, warns if missing, refuses install-complete without it
> 2. Auto-install via brew cask — single-command experience, breaks minimal-deps ethos
> 3. Documented in README only, setup.sh stays silent
>
> Which did you mean? 1, 2, or 3?"

**User's clarification:** "1"

**Final decision:** Karabiner integration = **Document + check (Option 1)**. setup.sh detects `/Applications/Karabiner-Elements.app` presence, warns + prints fn→F19 JSON rule when missing, refuses install completion until Karabiner present.

---

## Brand Carryover (deferred to documentation only)

After scope-shrunk (only QOL-01 + alt hotkey in scope), brand carryover became minimal — re-paste is in-memory only (no path concerns); F19 binding is a Hammerspoon hotkey string (no brand drift). Carryover note for deferred items (QOL-03/04/05) captured in CONTEXT.md `<deferred>` section: when those eventually trigger, REQUIREMENTS.md stubs need rebrand `voice-cc` → `purplevoice` for paths and `VOICE_CC_*` → `PURPLEVOICE_*` for env vars per Phase 2.5 D-03/D-05.

## History Log Design (N/A)

Skipped — QOL-04 deferred to v2. Captured in CONTEXT.md `<deferred>` section with privacy framing note (history log persists transcripts on disk — Phase 2.7 audience may want OFF-by-default with explicit opt-in env var when this eventually triggers).

---

## Wrap-Up

| Option | Description | Selected |
|--------|-------------|----------|
| Ready for context | Phase 4 scoped to QOL-01 + alt hotkey only | ✓ |
| More questions | Surface follow-ups | |

**User's choice:** Ready for context.

---

## Claude's Discretion (carried to CONTEXT.md)

- Nil-state behaviour for first re-paste (silent no-op vs brief alert)
- JSON file location for Karabiner rule (`assets/` vs `config/`)
- Hold-threshold value in Karabiner rule (Karabiner default ~200ms)
- Exact wording of setup.sh's Karabiner-missing actionable error
- Order of setup.sh steps (Karabiner check after other deps, before final banner)
- Whether to add `tests/test_karabiner_check.sh`
- Whether/how to bump existing `tests/manual/test_*.md` walkthroughs from cmd+shift+e to F19
- `hs.hotkey.bind({}, "f19", ...)` API surface verification
- Plan boundaries (likely 2-3 plans)

## Deferred Ideas (carried to CONTEXT.md)

- QOL-02 (Esc cancel) — defer to v2 / backlog
- QOL-03 (replacements.txt) — defer to v2 / backlog with rebrand to `~/.config/purplevoice/`
- QOL-04 (history log) — defer to v2 / backlog with rebrand to `~/.cache/purplevoice/` + privacy framing
- QOL-05 (PURPLEVOICE_MODEL runtime swap) — defer to v2 / backlog with rebrand to `PURPLEVOICE_MODEL`
- Persistent re-paste storage at last.txt — rejected
- Auto-install Karabiner via brew cask — rejected
- Both cmd+shift+e + F19 active — rejected
- Raw fn-detection via `hs.eventtap.flagsChanged` — rejected
- PURPLEVOICE_HOTKEY env var — rejected
- Test scaffolds for deferred items — N/A this phase

---

## Auto-Resolved

Not applicable — interactive mode, no `--auto` flag.

## External Research

Not performed during this discussion. Phase 4 doesn't have a research flag in ROADMAP — but planner may need a quick spike on:
- Karabiner-Elements complex-modification JSON schema for fn→F19 with hold-threshold
- Hammerspoon `hs.hotkey.bind({}, "f19", ...)` empirical confirmation
- Whether Syft's existing setup.sh Step 8 scope picks up Karabiner-Elements automatically

---

*Mode: discuss (default). USER-PROFILE.md absent → advisor mode disabled. Auto-advance config: false (disabled by user 2026-04-30 after Phase 2.7) — workflow will NOT auto-proceed to plan-phase after commit.*
