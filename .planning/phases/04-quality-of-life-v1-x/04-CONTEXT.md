# Phase 4: Quality of Life (v1.x) — Context

**Gathered:** 2026-04-30
**Status:** Ready for planning

<domain>
## Phase Boundary

**What this phase delivers:** Trigger-validated quality-of-life improvements addressing the **two** real-use frustrations the user has actually hit: (1) lost transcripts when focus shifts mid-paste, and (2) the `cmd+shift+e` collision with VS Code/Cursor's "Show Explorer" shortcut. Specifically:

1. **QOL-01** — A re-paste hotkey (`cmd+shift+v`) that pastes the last successful transcript again. In-memory Lua storage; no disk persistence; lost on Hammerspoon reload.
2. **QOL-NEW-01 (alt hotkey)** — Replace `cmd+shift+e` with **F19 only** (no fallback). Karabiner-Elements remaps the fn key to F19; Hammerspoon binds F19 (no modifiers) for press-and-hold. setup.sh detects Karabiner-Elements presence, warns if missing, prints the complex-modification JSON rule to paste, and refuses to declare install "complete" without Karabiner present.

**Phase 4 IS:**
- A surgical extension to `purplevoice-lua/init.lua` (new `cmd+shift+v` hotkey + `lastTranscript` module-scope variable + replacement of `cmd+shift+e` binding with F19)
- A new bundled file: `assets/karabiner-fn-to-f19.json` (or similar) — the Karabiner complex-modification JSON rule that users paste into `~/.config/karabiner/karabiner.json`
- A `setup.sh` Step 9 (or similar) that checks for `/Applications/Karabiner-Elements.app` and prints the rule + paste instructions when found, OR prints actionable error + refuses install completion when absent
- A README + SECURITY.md update documenting the F19 hotkey + Karabiner dependency + privacy framing (Karabiner runs as a system extension; mention honestly)
- A REQUIREMENTS.md update formalising QOL-01 and adding QOL-NEW-01 (the F19 alt hotkey) — both `[x]` Complete after Phase 4 closes

**Phase 4 is NOT:**
- An implementation of QOL-02, QOL-03, QOL-04, or QOL-05. Per ROADMAP "Each item has a specific trigger; do not build speculatively." User confirmed in trigger inventory: only QOL-01 + alt-hotkey have been hit. The other four defer to v2 / backlog.
- An auto-install of Karabiner-Elements (rejected: "minimal deps" ethos + third-party system extension dependency)
- A `hs.eventtap.flagsChanged` raw-fn-key detection path (rejected: documented race with macOS emoji popup)
- A persistent `~/.cache/purplevoice/last.txt` for re-paste (rejected: privacy-first + simplicity)
- A history log, replacements.txt, runtime model swap, or Esc-cancel — all deferred to v2 with `purplevoice` paths/vars when they eventually trigger
- A removal of the menubar indicator or HUD (Phase 2 + 3.5 surfaces remain unchanged)

**Requirements covered:**
- **QOL-01** (formalised here from v2 stub) — re-paste hotkey
- **QOL-NEW-01** (new requirement added by Phase 4) — F19 alt hotkey via Karabiner

**Success criteria:**
1. Pressing `cmd+shift+v` after a successful transcription re-pastes the same transcript into the focused window. If no recording has occurred yet (post-reload, no `lastTranscript` cached), the hotkey is a silent no-op (or flashes a brief alert; Claude's discretion).
2. Holding F19 (after Karabiner fn→F19 remap is active) triggers PurpleVoice recording exactly as `cmd+shift+e` previously did. `cmd+shift+e` no longer triggers recording (binding removed).
3. setup.sh refuses to declare "install complete" if `/Applications/Karabiner-Elements.app` is absent. When absent, prints actionable instructions (download URL, JSON rule paste path) and exits with non-zero code.
4. README documents the Karabiner dependency prominently in the install flow (above or alongside the existing Hammerspoon setup steps); SECURITY.md mentions Karabiner as a documented runtime dependency in the SBOM scope or §"How to Verify These Claims".
5. REQUIREMENTS.md QOL-01 and QOL-NEW-01 marked `[x]` Complete with concrete language; traceability rows added; coverage stat updated (35 → 41 v1 reqs after HUD; +2 here = 41 → 43? Re-verify per the actual coverage table).
6. Pattern 2 invariant intact: `grep -c WHISPER_BIN purplevoice-record == 2`. Pattern 2 corollary intact: no `whisper-cli` strings in `purplevoice-lua/init.lua`. Functional suite stays GREEN; security suite stays 5/0.

</domain>

<decisions>
## Implementation Decisions

### Trigger Validation (D-01)

- **D-01:** **Phase 4 scope = QOL-01 + alt hotkey only.** User trigger inventory 2026-04-30:
  - **QOL-01** (paste-last-transcript hotkey) — TRIGGERED. User has lost transcripts when focus shifted mid-paste.
  - **QOL-NEW-01** (alt hotkey via Karabiner fn→F19) — TRIGGERED. cmd+shift+e collides with VS Code/Cursor "Show Explorer" annoyingly enough in practice to warrant a replacement.
  - **QOL-02** (Esc cancel) — NOT TRIGGERED. Defer to v2 backlog.
  - **QOL-03** (replacements.txt) — NOT TRIGGERED. Defer to v2 backlog.
  - **QOL-04** (history log) — NOT TRIGGERED. Defer to v2 backlog.
  - **QOL-05** (PURPLEVOICE_MODEL runtime swap) — NOT TRIGGERED. Defer to v2 backlog.

### QOL-01 — Re-paste Hotkey

- **D-02:** **Re-paste hotkey = `cmd+shift+v`.** Pairs visually with `cmd+v` (system paste). Risk acknowledged: collides with macOS "Paste and Match Style" in some apps — but PurpleVoice's paste IS plain text (transient marker per Phase 2 INJ-03), so the collision is semantically aligned. Plan-level review may revisit if a specific app's collision proves frustrating.

- **D-03:** **Last-transcript storage = in-memory Lua module-scope variable.** Stored as `local lastTranscript = nil` at module scope in `purplevoice-lua/init.lua`. Updated to the successful transcript inside `pasteWithRestore()` (or in `handleExit` exit-code-0 branch) AFTER the paste succeeds. Lost on Hammerspoon reload (acceptable — re-paste is for "I lost focus and need it back NOW", not "I want yesterday's transcript"). No disk persistence; matches privacy-first ethos.

- **D-04:** **Nil-state behaviour on first re-paste (no recording yet).** When `cmd+shift+v` is pressed before any successful recording has cached a `lastTranscript`, the binding either:
  - Silent no-op (simplest), OR
  - Flash a brief `hs.alert("PurpleVoice: no transcript to re-paste")` for ~1.5s
  - **Claude's discretion** — pick during planning. Recommendation: brief alert; better UX than silent no-op.

### QOL-NEW-01 — F19 Alt Hotkey via Karabiner

- **D-05:** **F19 only — `cmd+shift+e` binding removed.** Hammerspoon `hs.hotkey.bind({}, "f19", onPress, onRelease)` (no modifiers, push-and-hold semantics). The existing `hs.hotkey.bind({"cmd", "shift"}, "e", ...)` line is REPLACED, not supplemented. Reason: F19 (via Karabiner fn-remap) eliminates the VS Code/Cursor collision entirely; keeping cmd+shift+e as fallback would create a confusing dual-trigger experience.

- **D-06:** **Karabiner-Elements fn→F19 complex-modification rule** ships as a JSON file in the repo (suggested path: `assets/karabiner-fn-to-f19.json` or `config/karabiner-fn-to-f19.json` — Claude's discretion during planning). The rule remaps the fn key (when held) to F19, with appropriate hold-threshold to avoid breaking macOS's native fn-key behaviours (function-key row). User pastes the rule into Karabiner-Elements via:
  - Karabiner-Elements menubar → Preferences → Complex Modifications → Add rule → Import rule from file → select the JSON file from the PurpleVoice repo
  - OR drop the JSON into `~/.config/karabiner/assets/complex_modifications/` and import via Karabiner UI

- **D-07:** **Karabiner setup is "Document + check" (the user-confirmed Option 1).** `setup.sh` adds a new step (likely Step 9, before the final banner) that:
  1. Checks for `/Applications/Karabiner-Elements.app`
  2. **If absent:** prints actionable error — "PurpleVoice requires Karabiner-Elements for the F19 hotkey. Download from <https://karabiner-elements.pqrs.org/>, install, then re-run `bash setup.sh`. After install, import `assets/karabiner-fn-to-f19.json` into Karabiner-Elements (Preferences → Complex Modifications → Add rule)." — exits with non-zero code; refuses to declare install complete
  3. **If present:** prints reminder — "Karabiner-Elements detected. Import `assets/karabiner-fn-to-f19.json` into Preferences → Complex Modifications if you haven't already, and ensure the 'fn → F19' rule is active." — continues to the final banner

- **D-08:** **`PURPLEVOICE_OFFLINE=1` mode interaction.** When offline mode is active (Phase 2.7 SEC-06), the Karabiner check still runs (Karabiner is local-only software; no network required) but the actionable error message also notes the offline-install path: "If air-gapped, copy Karabiner-Elements.dmg from a connected machine via USB and install manually. The fn→F19 JSON rule is already in this repo at `assets/karabiner-fn-to-f19.json`."

- **D-09:** **No raw `hs.eventtap.flagsChanged` fn-detection path.** Explicitly rejected per RESEARCH 2026-04-28 race-with-emoji-popup finding. Karabiner is the only supported fn-trigger pathway in v1.x.

### Brand Carryover (D-10)

- **D-10:** **Phase 4 surfaces use `purplevoice` brand consistently** — `cmd+shift+v` re-paste binding lives in `purplevoice-lua/init.lua` (no path/var concerns). F19 binding same. Karabiner JSON rule references `org.hammerspoon.Hammerspoon` (the macOS app bundle ID — that's Hammerspoon-controlled, not PurpleVoice-renameable; honest about substrate). REQUIREMENTS.md QOL-01 final language replaces the v2 stub's `~/.config/voice-cc/...` references with `purplevoice` equivalents (although QOL-01 doesn't actually use a config path — re-paste is in-memory only).

  **For deferred items (QOL-02..05) when they eventually trigger:** REQUIREMENTS.md v2 stubs MUST be updated to use `~/.config/purplevoice/replacements.txt` (not `voice-cc/`), `~/.cache/purplevoice/history.log` (not `voice-cc/`), `PURPLEVOICE_MODEL` (not `VOICE_CC_MODEL`). Documented in `<deferred>` section below as a planning note for future-Oliver.

### Claude's Discretion

- **Nil-state behaviour for first re-paste** (D-04): silent no-op vs brief alert. Recommendation: alert.
- **JSON file location and name**: `assets/karabiner-fn-to-f19.json` vs `config/karabiner-fn-to-f19.json` vs other. Claude picks based on existing repo structure — `assets/` already houses `icon-256.png` from Phase 2.5, suggests it as the natural home.
- **Hold-threshold value in the Karabiner rule** — too short and quick fn taps trigger PurpleVoice (false positives); too long and the user perceives the hotkey as laggy. Karabiner default is ~200ms; researcher should validate empirically.
- **Exact wording of setup.sh's Karabiner-missing actionable error** — keep concise but actionable; researcher / planner refines.
- **Order of setup.sh steps** — Karabiner check should come AFTER all other deps are validated (so the user gets a holistic view of what's missing) but BEFORE the final banner.
- **Whether to add a `tests/test_karabiner_check.sh`** to lint the setup.sh new step. Likely yes — mirrors the existing test_security_md_framing.sh / test_hud_env_off.sh pattern.
- **Whether to bump the existing `tests/manual/test_*.md` walkthroughs to use F19 instead of cmd+shift+e** — yes, all references to `cmd+shift+e` in tests/manual/ + README + SECURITY.md need updating.
- **Hammerspoon `hs.hotkey.bind({}, "f19", ...)`** vs `bind({"fn"}, "...")` — which API surface actually catches the F19 keystroke after Karabiner has remapped it. Researcher to confirm.
- **Plan boundaries** — Phase 4 is small (2 trigger-validated items). Likely 2-3 plans:
  - Plan 04-00 (Wave 0 staging) — test scaffolds + REQUIREMENTS.md QOL-01/QOL-NEW-01 stubs
  - Plan 04-01 (HUD-style core) — F19 binding replacement + cmd+shift+v re-paste + lastTranscript caching in init.lua
  - Plan 04-02 (Karabiner integration + docs closure) — assets/karabiner-fn-to-f19.json + setup.sh Step 9 + README + SECURITY.md + REQUIREMENTS.md finalisation
  - Or 3 plans split. Planner discretion.

### Folded Todos

None — `gsd-tools todo match-phase 4` returned `todo_count: 0`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Context
- `.planning/PROJECT.md` — Core value, audience, "Local voice dictation. Nothing leaves your Mac." ethos.
- `.planning/REQUIREMENTS.md` §"v2 Requirements / Quality of Life" (lines 76-86) — QOL-01 v2 stub language; Phase 4 promotes QOL-01 to v1 and adds QOL-NEW-01 for the F19 alt hotkey.
- `.planning/ROADMAP.md` §"Phase 4: Quality of Life (v1.x)" — phase goal, trigger-based scope discipline, candidate items, ALSO has updated header per Phase-4 init parser fix (commit `75e9fd4`).

### Prior phase decisions (carried forward)
- `.planning/phases/01-spike/01-CONTEXT.md` — D-01 (cmd+shift+e hotkey decision; Phase 4 supersedes with F19); D-02 (Hammerspoon `require()` load pattern — F19 binding lives in same module). Phase 1 D-03 mentions `~/.cache/voice-cc/last.txt` as a "last transcript marker (used by bash → Lua handoff)" — never actually used; Phase 4 D-03 explicitly rejects disk persistence in favour of in-memory.
- `.planning/phases/02-hardening/02-03-SUMMARY.md` — `pasteWithRestore()` implementation; Phase 4 QOL-01 hooks into this same function to cache `lastTranscript` after successful paste.
- `.planning/phases/02.5-branding/02.5-CONTEXT.md` — D-02 brand audience (gov / healthcare / etc); D-03/D-05 XDG path rebrand `voice-cc` → `purplevoice`. Phase 4 D-10 honours.
- `.planning/phases/02.7-security-posture/02.7-CONTEXT.md` — D-17 framing constraint ("compatible with" not "compliant"); D-08 PURPLEVOICE_OFFLINE=1 air-gap mode (Phase 4 D-08 interacts with).
- `.planning/phases/03.5-hover-ui-hud/03.5-CONTEXT.md` — D-11 env-var-only config (no runtime toggle hotkey); Phase 4 follows the same pattern (no runtime toggle for re-paste; cmd+shift+v is statically bound).

### External / Karabiner-Elements
- `https://karabiner-elements.pqrs.org/` — Karabiner-Elements home + download
- `https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/` — Complex modification rule schema (researcher will use this to author the fn→F19 JSON rule)
- `https://github.com/pqrs-org/Karabiner-Elements` — Karabiner-Elements source / issues / examples
- `https://www.hammerspoon.org/docs/hs.hotkey.html#bind` — Hammerspoon `hs.hotkey.bind` API (verifies F19 with no modifiers is supported; Phase 4 binding shape)

### Existing Code Patterns to Match
- `purplevoice-lua/init.lua` lines 305-310 — Current `hs.hotkey.bind({"cmd", "shift"}, "e", onPress, onRelease)` line that Phase 4 D-05 REPLACES with `hs.hotkey.bind({}, "f19", onPress, onRelease)`.
- `purplevoice-lua/init.lua` lines ~170-200 — `pasteWithRestore()` function; QOL-01 hooks into the success path here to cache `lastTranscript`.
- `purplevoice-lua/init.lua` line 32-36 — `M.BRAND` constants block; Phase 4 may add a fourth field if it needs to surface the F19 binding name to other modules.
- `setup.sh` Step 7 — Existing banner pattern; Phase 4 Step 9 mirrors structure (named `setup_step_9_karabiner_check` or similar).
- `setup.sh` PURPLEVOICE_OFFLINE=1 guards — Phase 4 Step 9 wraps similarly.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`hs.hotkey.bind({}, "f19", onPress, onRelease)`** — Hammerspoon supports F19 binding natively; no modifier table needed (empty `{}`). Push-and-hold semantics work the same way as the existing cmd+shift+e binding (onPress + onRelease callbacks).
- **`pasteWithRestore()` in init.lua** — Called from `handleExit()` exit-code-0 branch when transcription succeeds. Phase 4 caches `lastTranscript = transcript` immediately after the call (or inside the function on the success path).
- **`hs.alert.show()`** — Already used at module load (line 339 "PurpleVoice loaded — local dictation, cmd+shift+e" — needs updating to "cmd+shift+e" → "F19" in Phase 4). Reusable for the nil-state re-paste alert (D-04).
- **`tests/test_brand_consistency.sh`** — Pre-commit hook; Phase 4's removal of cmd+shift+e from init.lua / README / setup.sh / tests/manual/ won't introduce voice-cc strings (cmd+shift+e is just a hotkey string, no brand drift).
- **`assets/icon-256.png`** — Existing assets/ directory established by Phase 2.5; natural home for `assets/karabiner-fn-to-f19.json`.

### Established Patterns

- **Push-and-hold hotkey lifecycle** — `onPress` / `onRelease` symmetric, `isRecording` guard, `pcall(showHUD)` / `pcall(hideHUD)`, `setMenubarRecording` / `setMenubarIdle`, `playStartCue` / `playStopCue`. Phase 4 changes the trigger key (cmd+shift+e → F19) but the lifecycle is unchanged.
- **In-memory Lua module-scope state** — `isRecording` (line 71), `currentTask` (line 72), `lastNotifyAt` table (line 156). Phase 4 adds `lastTranscript` to this group.
- **setup.sh idempotent step** — Each step checks state before acting (`brew list X &>/dev/null`); Phase 4 Step 9 follows the same shape.
- **Brand consistency hook + framing lint** — Both stay GREEN throughout. Phase 4's hotkey-string updates are mechanical text replacements that don't trip either.

### Integration Points

- **`purplevoice-lua/init.lua` line 305-310** — F19 binding replaces cmd+shift+e binding.
- **`purplevoice-lua/init.lua` `handleExit` line 213** — `lastTranscript = stdOut` cache point on exit code 0.
- **`purplevoice-lua/init.lua` line 339** — Module-load alert text update from `cmd+shift+e` to `F19`.
- **New `cmd+shift+v` binding** — added near the existing `hs.hotkey.bind` at line 305-310; calls a new `repaste()` function that reads `lastTranscript`.
- **`setup.sh` Step 9** — new step that checks `/Applications/Karabiner-Elements.app`.
- **`assets/karabiner-fn-to-f19.json`** — new file in `assets/` (already-established directory from Phase 2.5).
- **`README.md`** — install flow update to mention Karabiner; hotkey reference update from cmd+shift+e to F19.
- **`SECURITY.md`** — SBOM scope update (add Karabiner-Elements as runtime dep); §"How to Verify These Claims" mentions the F19 hotkey if any walkthroughs reference it.
- **`tests/manual/test_*.md`** — All references to cmd+shift+e (across hud + Phase 2 walkthroughs) updated to F19.
- **`.planning/REQUIREMENTS.md`** — QOL-01 promoted from v2 stub to v1 Complete; QOL-NEW-01 added; coverage stat bumped.
- **`.planning/ROADMAP.md`** — Phase 4 plan list + Progress table updated.

### Constraints

- **Pattern 2 invariant** — `grep -c WHISPER_BIN purplevoice-record == 2`. Phase 4 does NOT modify purplevoice-record.
- **Pattern 2 corollary** — `! grep -q whisper-cli purplevoice-lua/init.lua`. Re-paste / F19 code stays whisper-cli-free.
- **No new XDG paths** — Phase 4 D-03 explicitly rejects disk persistence for `lastTranscript`. The existing `~/.cache/purplevoice/last.txt` (Phase 1 D-03 marker — never used) stays unused.
- **Functional + security suites GREEN** — `bash tests/run_all.sh` 10/0 + `bash tests/security/run_all.sh` 5/0 throughout.
- **Brand consistency** — no new `voice-cc` strings.
- **Framing lint** — no `compliant` / `certified` / `guarantees` in SECURITY.md without qualifier.

</code_context>

<specifics>
## Specific Ideas

- **The "trigger-based scope" discipline matters more than the items themselves.** ROADMAP says "Each item has a specific trigger; do not build speculatively." User trigger inventory 2026-04-30 confirmed only 2 of 6 candidates are real frustrations. Phase 4 ships exactly those 2. The other 4 explicitly defer to v2 with brand-rebranded paths/vars when their triggers eventually fire.

- **F19-only is a deliberate breaking change.** The user chose to fully replace cmd+shift+e rather than running both bindings. Reason: simpler mental model, no dual-trigger confusion. Karabiner becomes a hard dependency for v1.x onwards. Setup.sh "Document + check" enforces this honestly without auto-installing third-party software.

- **In-memory re-paste is a privacy decision, not just a simplicity decision.** Persisting `lastTranscript` to `~/.cache/purplevoice/last.txt` would mean transcripts survive Hammerspoon reload + Mac restart. For the institutional / gov / healthcare audience (Phase 2.5/2.7), that's a measurable privacy regression vs the current "transcript exists only in-memory until paste fires + clipboard transient marker discards it ~250ms later". Re-paste's "I lost focus, give it back NOW" use case doesn't need persistence — if the user reloads Hammerspoon, the transcript is gone (acceptable trade-off).

- **Karabiner's substrate matters for the SBOM.** Phase 2.7 SBOM (`SBOM.spdx.json`) currently lists sox + whisper-cli + Hammerspoon + 2 GGML models. Phase 4 adds Karabiner-Elements as a runtime dependency. The SBOM regen via Syft (Phase 2.7 setup.sh Step 8) needs to pick up Karabiner-Elements; if Syft's repo-only scope (Pitfall 2) doesn't catch `/Applications/Karabiner-Elements.app`, the SBOM scope disclaimer (added 2026-04-30 commit `8b60b36`) already documents this — but the disclaimer should be updated to explicitly name Karabiner alongside Hammerspoon as the "scoped-out via Pitfall 2" deps.

- **The fn-key approach replaces a known collision (VS Code/Cursor "Show Explorer") with a guaranteed-non-collision (F19 isn't on most keyboards as a standalone key).** F19 is one of the "extra" function keys above F12; on Apple keyboards it doesn't physically exist. Karabiner's fn-remap is the only realistic pathway because raw F19 is unreachable without remapping.

- **The "include Karabiner in the install" framing led to Option 1 (Document + check)**, not auto-install. User wants Karabiner to be part of the install flow (acknowledged + checked + actionable error if missing) — but installation itself stays user-driven (third-party app + system-extension grant). This honours the privacy-first "minimal automated deps" ethos while not pretending Karabiner is optional.

</specifics>

<deferred>
## Deferred Ideas

### Other QOL items (untriggered as of 2026-04-30; defer to v2 / backlog)

- **QOL-02 — Esc cancels in-flight recording without paste.** No real-use trigger reported. When this fires (user accidentally records, wants to abort), implement via `hs.eventtap.new({hs.eventtap.event.types.keyDown})` watching for Esc during `isRecording == true`; on detection, terminate `currentTask` without invoking `pasteWithRestore`. Estimated effort: ~2-3 hours.

- **QOL-03 — `~/.config/purplevoice/replacements.txt` find/replace pairs.** Path REBRANDED from REQUIREMENTS.md v2 stub `~/.config/voice-cc/` → `~/.config/purplevoice/` per Phase 2.5 D-05. Implementation: bash `sed` post-filter step in `purplevoice-record` between whisper-cli output and stdout-print. Format: one rule per line, `s/find/replace/g` syntax (or simpler: tab-separated find\treplace). Privacy note: replacements.txt itself doesn't introduce new privacy concerns (transcripts still go through bash glue, not external services). Estimated effort: ~3-4 hours including tests.

- **QOL-04 — Rolling history log at `~/.cache/purplevoice/history.log`, capped 10MB.** Path REBRANDED. **Privacy implications worth re-discussing when this triggers** — a history log persists transcripts on disk (surface for forensics, leakage if Mac is shared/stolen). Phase 2.7 audience (gov / healthcare / journalists / air-gapped) may want this OFF by default with explicit opt-in env var (`PURPLEVOICE_HISTORY_LOG=1` or similar). Format: JSONL recommended (one record per line: timestamp, transcript, exit code, duration). Rotation: when file exceeds 10MB, truncate from the front (move tail to a `.1` file then drop the original) or use a circular-buffer approach. Estimated effort: ~6-8 hours.

- **QOL-05 — `PURPLEVOICE_MODEL` runtime model swap.** Var name REBRANDED from `VOICE_CC_MODEL` → `PURPLEVOICE_MODEL` per Phase 2.5 D-03 env-var rebrand. Implementation: bash `purplevoice-record` reads `${PURPLEVOICE_MODEL:-small.en}` and substitutes into the whisper-cli `-m` flag's path. setup.sh adds an idempotent download for the alt-model file (e.g., `ggml-medium.en.bin` if user sets `PURPLEVOICE_MODEL=medium.en`). Estimated effort: ~3-4 hours.

### Other items rejected during discussion

- **Persistent `lastTranscript` at `~/.cache/purplevoice/last.txt`** — rejected per D-03 (privacy + simplicity). Phase 1 D-03 mentioned this path as a marker but it was never used; Phase 4 keeps it unused.
- **Auto-install Karabiner via brew cask** — rejected per D-07 (third-party + system-extension dep; "Document + check" honours minimal-deps ethos).
- **Both cmd+shift+e + F19 active** — rejected per D-05 (dual-trigger confusion).
- **Raw `hs.eventtap.flagsChanged` fn-detection** — rejected per D-09 (race with macOS emoji popup).
- **PURPLEVOICE_HOTKEY env var** for runtime hotkey override — rejected (over-config; F19 is locked).
- **Brief alert vs silent no-op for first re-paste** — deferred to Claude's discretion during planning (D-04).
- **A `tests/test_replacements.sh` / `tests/test_history_log.sh` / `tests/test_model_swap.sh`** — N/A; deferred items don't get test scaffolds in Phase 4.

### Reviewed Todos (not folded)

None — `gsd-tools todo match-phase 4` returned `todo_count: 0`.

</deferred>

---

*Phase: 04-quality-of-life-v1-x*
*Context gathered: 2026-04-30*
