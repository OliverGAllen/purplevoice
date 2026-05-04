# Milestones

## v1.0 MVP — Local privacy-first dictation, public release (Shipped: 2026-05-04)

**Phases completed:** 7 phases, 29 plans, 62 tasks

**Key accomplishments:**

- Idempotent bash installer that lays down Hammerspoon + sox + whisper-cli + the small.en Whisper model (488 MB, SHA256-verified) into XDG-conventional paths with a no-clobber vocab seed; manual pipeline test deferred to the Plan 01-03 end-to-end walkthrough by user request.
- 79-line bash glue script (`voice-cc-record`) that owns the sox capture lifecycle, isolates whisper-cli inside a single `transcribe()` function (ARCHITECTURE.md Pattern 2 — the v1.1 warm-process swap site), traps SIGTERM/SIGINT to finalise the WAV cleanly, and emits the transcript on stdout with no trailing newline; symlinked into ~/.local/bin/ so Hammerspoon and manual invocation share one binary; manual invocation test (Task 2) deferred to Plan 01-03's end-to-end walkthrough per user directive.
- 82-line Lua module wires `cmd+shift+e` push-and-hold to `~/.local/bin/voice-cc-record` via `hs.task`, captures stdout, writes to clipboard with `hs.pasteboard.setContents`, and synthesises `cmd+v` via `hs.eventtap.keyStroke`; symlinked into `~/.hammerspoon/voice-cc/` and loaded by a freshly written 3-line `~/.hammerspoon/init.lua` (D-02: no prior content, no overwrite); Phase 1 spike loop demonstrably works end-to-end on Oliver's machine after a one-time manual Accessibility grant for Hammerspoon.
- Test infrastructure (tests/):
- 1. [Rule 1 - Bug] Pattern 2 boundary inflated by canonical block's existence checks
- sox stderr fingerprint
- voice-cc → PurpleVoice rebrand of bash glue + Lua module + user-paste snippet + 6 unit tests + 7 manual walkthroughs, with hs.notify orphan-tag cleanup, M.BRAND constants export, and the cache-path edit from Plan 02 consolidated to eliminate the Wave 2 race — Pattern 2 boundary intact, all 6 bash tests still GREEN.
- Idempotent 4-state migration block in setup.sh moves ~/.config|.local/share|.cache/voice-cc/ to /purplevoice/, removes stale symlinks, and creates new symlinks via ln -sfn; purplevoice-record + 5 tests + denylist all reference the new XDG paths; live migration verified on Oliver's machine (466 MB models moved; second run silent); 6 bash tests still GREEN; Pattern 2 invariant intact.
- 256x256 PNG icon (lavender bg + white lips) derived from a hand-authored SVG via sips, plus menubar migration from grey/red to unified lavender via BRAND.COLOUR_LAVENDER with filled-vs-outline glyph differentiation — closes BRD-03; Pattern 2 invariant intact; all 6 bash tests still GREEN.
- tests/security/ aggregator + 7 verify/test skeletons + SECURITY.md skeleton (18 H2 sections) + SBOM.spdx.json placeholder + setup.sh extended with 5 PURPLEVOICE_OFFLINE guards + unconditional Syft install, all preserving Pattern 2 invariant.
- §Scope subsections:
- Plan 02.7-02 in one line:
- Authored SECURITY.md §NIST SP 800-53 Rev 5 / Low-baseline Mapping with hybrid prose+table content (D-15) — framing prose + 20-row Applicability Matrix (family-level) + 20-row Per-Control Mapping (5 above the 15 minimum) + Out-of-Scope rationale for 10 organisational families — using disciplined Met / Partial / Not Pursued / N/A vocabulary (Pitfall 15) and Rev 5 IDs only (Pitfall 13).
- Status: Compatible with FIPS-validated cryptographic modules where the underlying macOS crypto APIs are FIPS-validated. PurpleVoice itself is not in scope for FIPS validation.
- 1. [Rule 1 - plan-prose-vs-verify-regex] TL;DR template literal contained banned phrase outside qualified context
- Validation contract for Plans 03-01..04 encoded as 5 RED unit tests + 4 manual walkthrough scaffolds + 1 benchmark regeneration reference doc — Pattern 2 invariant intact, suite at exact target 11/5.
- setup.sh -> install.sh rename + Step 0 curl-vs-clone detection + bootstrap_clone_then_re_exec inserted; D-13 typo sweep; brand-consistency exemption updated; Wave-0 RED tests turn GREEN; functional suite at exact 14/2 plan target; DST-01 idempotency walkthrough signed off live by Oliver 2026-05-01 with one structural deviation accepted.
- Wave 2 deliverables landed via 4 pre-walkthrough commits (c347ea8 LICENSE / d18a02d uninstall.sh + brand-exemption / 98c0018 README rewrite / 026c247 pre-walkthrough SBOM regen) + walkthrough sign-off commit (e8bd7bf, 2026-05-04). Functional suite 14 PASS / 2 FAIL → 16 PASS / 0 FAIL; security suite 5/0 unchanged; brand + framing lints GREEN; Pattern 2 invariant intact. DST-03 README recovery walkthrough signed off live by Oliver — all 4 items PASS (TCC reset, Karabiner Event Viewer, "I lost my hotkeys" 5-step, uninstall.sh + reinstall destructive run). Plans 03-03..04 unblocked.
- Status:
- COMPLETE 2026-05-04
- Wave 0 scaffolding for Phase 3.5 HUD — 2 bash unit tests + 5 manual walkthrough skeletons + REQUIREMENTS.md formalisation of HUD-01..04 + VALIDATION.md frontmatter flipped to wave_0_complete: true.
- Status:
- Status:
- Status:
- Stage all Phase 4 verification scaffolds (1 unit test + 3 manual walkthroughs + REQUIREMENTS.md QOL-01/QOL-NEW-01 stubs) in a single Wave 0 commit so Plans 04-01 + 04-02 implement against contracts that already exist on disk.
- Land the user-facing behaviour change for QOL-01 (cmd+shift+v re-paste) and QOL-NEW-01 (F19 trigger replacing cmd+shift+e) in a single surgical 7-edit pass over `purplevoice-lua/init.lua`. Plan 04-02 closes the Karabiner JSON + setup.sh Step 9 + docs.
- Karabiner JSON rule + setup.sh Step 9 + README/SECURITY.md updates + REQUIREMENTS.md/ROADMAP.md closure landed Phase 4 to completion. Mid-execution: D-02 cmd+shift+v re-paste hotkey superseded by F18-via-backtick-hold after live walkthrough surfaced an opaque clipboard-manager collision Hammerspoon's bind() couldn't detect.

---
