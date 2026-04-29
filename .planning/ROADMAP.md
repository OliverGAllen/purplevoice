# Roadmap: voice-cc

**Created:** 2026-04-23
**Updated:** 2026-04-29 (Phase 2.7 Security Posture & Government Readiness added per user direction; positioning broadened to include institutional / government audiences)
**Granularity:** standard
**Coverage:** 26/26 original v1 requirements mapped; new branding/HUD/public-install requirements TBD during planning
**Build-order constraint:** manual pipeline → bash glue → Hammerspoon wiring (non-negotiable per ARCHITECTURE.md)

## Core Value

Speak → text appears in Claude Code, instantly and reliably, with no recurring cost or external dependency.

## Phases

- [x] **Phase 1: Spike** — Prove the end-to-end loop works on Oliver's machine. Thin slice, no polish. *(completed 2026-04-27)*
- [x] **Phase 2: Hardening** — Make the loop robust against TCC silent-deny, hallucinations, re-entrancy, clipboard manager leakage, and AirPods surprises. *(completed 2026-04-28)*
- [ ] **Phase 2.5: Branding** — Pick a public-facing product name and apply it across user-visible surfaces. Pre-requisite for HUD, Security, and Distribution because all three reference the brand.
- [ ] **Phase 2.7: Security Posture & Government Readiness** — Threat model + verifiable security claims for institutional / government / high-privacy audiences. Produces SECURITY.md as authoritative document; implements quick-win verification mechanisms (no-egress proof, SBOM generation, code signing setup). Research + verification depth, not formal certification.
- [ ] **Phase 3.5: Hover UI / HUD** — Small floating recording-state indicator that complements the menu-bar indicator. Hideable. Branded per Phase 2.5.
- [ ] **Phase 4 (v1.x): Quality of Life** — Address first real-use frustrations once the polished loop is stable.
- [ ] **Phase 3: Distribution & Benchmarking + Public Install** — Reproducible local install, public one-line installer, README, and `hyperfine` measurements that gate the v1.1 decision. **Reordered to end of v1 (2026-04-28) per user direction** — distribute the *finished, security-audited* product, not a half-polished one. Inherits SECURITY.md claims from Phase 2.7.
- [ ] **Phase 5 (v1.1, conditional): Warm-Process Upgrade** — Gated on Phase 3 hyperfine results.

> **Note on phase numbering:** Phase numbers are *identifiers*, not execution order. The list above shows the current execution order; Phase 3 (Distribution) is numerically third but executes seventh in v1 because it's the final polish step before the v1 release. Execution order: 1 → 2 → 2.5 → 2.7 → 3.5 → 4 → 3 → 5 (conditional).

## Phase Details

### Phase 1: Spike
**Goal**: Prove the end-to-end loop works — hold `cmd+shift+e`, say a sentence, release, watch the sentence appear in the focused window in under 2 seconds. No polish, no robustness, no installer.
**Depends on**: Nothing (first phase).
**Requirements**: CAP-01, CAP-02, CAP-03, CAP-04, TRA-01, TRA-02, TRA-03, INJ-01, ROB-03, ROB-05
**Success Criteria** (what must be TRUE):
  1. Holding `cmd+shift+e` and saying "refactor the auth middleware to use JWTs" results in that sentence appearing in the focused text field within ~2 seconds of release on Oliver's Apple Silicon Mac.
  2. The bash glue script can be invoked manually (outside Hammerspoon) and produces the same transcript on stdout for a hand-recorded WAV — the pipeline composes.
  3. Native Whisper punctuation and capitalisation appear in the pasted output (no post-processing pass yet).
  4. Custom vocabulary in `~/.config/voice-cc/vocab.txt` measurably biases recognition toward technical terms (Anthropic, Hammerspoon, MCP) when supplied via `--prompt`.
  5. All external binaries (sox, whisper-cli) are invoked by absolute path so the loop works under Hammerspoon's restricted PATH from day one.
**Plans:** 3 plans
  - [x] 01-01-PLAN.md — Setup script + manual sox/whisper-cli pipeline validation (TRA-01, CAP-03)
  - [x] 01-02-PLAN.md — Bash glue voice-cc-record with transcribe() abstraction (CAP-02, CAP-04, TRA-02, TRA-03, ROB-03)
  - [x] 01-03-PLAN.md — Hammerspoon Lua module — hotkey wiring + paste (CAP-01, INJ-01, ROB-05)
**UI hint**: yes
**Verification**: User-validated end-to-end on 2026-04-27. Formal `gsd-verifier` skipped per user direction (manual walkthrough sufficient for spike). Three Phase 2 candidates surfaced — see Phase 1 Plan 03 SUMMARY "Quirks Discovered".

### Phase 2: Hardening
**Goal**: Make the loop trustworthy. Eliminate the documented failure modes — Whisper hallucinations, TCC silent-deny, clipboard manager retention, paste-restore races, re-entrant double-recordings, WAV leaks, and silent failures with no user-visible cause.
**Depends on**: Phase 1 (you cannot harden a loop that doesn't yet exist; you need observed hallucinations to design the denylist, you need a real paste path to know what to preserve).
**Requirements**: TRA-04, TRA-05, TRA-06, INJ-02, INJ-03, INJ-04, FBK-01, FBK-02, FBK-03, ROB-01, ROB-02, ROB-04
**Success Criteria** (what must be TRUE):
  1. A 100 ms accidental hotkey tap produces no paste and no error — silently aborted by the duration gate.
  2. Recording 2 seconds of pure silence does not paste "thanks for watching" or any other Whisper hallucination — caught by VAD + denylist exact-match.
  3. Revoking Hammerspoon's microphone permission via `tccutil reset` and pressing the hotkey produces an actionable macOS notification with a working deep link to System Settings → Privacy → Microphone — never silent failure.
  4. After a successful paste, the user's prior clipboard contents are restored within ~250 ms; clipboard managers (1Password, Raycast, Maccy) do not retain the transcript permanently because the clipboard set is marked `org.nspasteboard.TransientType`.
  5. Holding the hotkey shows a visible menu-bar indicator change and (unless `VOICE_CC_NO_SOUNDS=1`) plays brief start/stop audio cues; rapid double-presses do not spawn duplicate sox processes; no WAV files accumulate in `/tmp/voice-cc/` across exit paths including SIGINT.
**Plans:** 4 plans
  - [x] 02-00-PLAN.md — Wave 0: test infrastructure + Silero VAD weights install + denylist.txt seed (no requirements; foundation) — completed 2026-04-28, see 02-00-SUMMARY.md
  - [x] 02-01-PLAN.md — Bash hardening: VAD + duration gate + denylist + empty-drop + TCC stderr fingerprint + EXIT-trap WAV cleanup + suppress whisper sibling .txt (TRA-04, TRA-05, TRA-06, INJ-04, ROB-02, ROB-04 + Phase-1 TODO c) — completed 2026-04-28, subsequently patched in commit `81334ce` for the SOX_SIGNALED regression + Sequoia silent-stream amplitude detection
  - [x] 02-02-PLAN.md — Lua hardening: hs.accessibilityState + menubar + audio cues + clipboard preserve/restore with transient UTI + re-entrancy guard + handleExit stub + require("hs.ipc") snippet (FBK-01, FBK-02, INJ-02, INJ-03, ROB-01 + Phase-1 TODOs a, b) — completed 2026-04-28
  - [x] 02-03-PLAN.md — Failure surfacing: hs.notify dispatch for exit 10/11/12 + System Settings deep links + dedup cooldown + defence-in-depth Accessibility-deny notification (FBK-03) — completed 2026-04-28; both manual checkpoints signed off live; see 02-03-SUMMARY.md
**UI hint**: yes
**Verification**: Both `autonomous: false` checkpoints in Plan 02-03 (TCC notification walkthrough + Accessibility deny walkthrough) executed live on macOS Sequoia 15.7.5 and signed off ("approved"). Surfaced + fixed three coupled regressions (commit `81334ce`) — see 02-03-SUMMARY.md "Three Coupled Deviations".

### Phase 2.5: Branding
**Goal**: Apply the public-facing product name `PurpleVoice` consistently across all user-visible surfaces (replacing the working name "voice-cc"). Stage the brand assets (icon + lavender menubar) so Phase 3.5 HUD and Phase 3 Distribution inherit a stable identity. Small phase — naming and propagation, not a full design system.
**Depends on**: Phase 2 (brand the production behavior, not the spike). Could technically be done in parallel with Phase 2; sequencing it after keeps the brand decision informed by what users actually experience.
**Requirements**: BRD-01, BRD-02, BRD-03 (formalised during planning 2026-04-29 — name = `PurpleVoice`, privacy-first positioning, lavender #B388EB visual identity)
  - **BRD-01** — Product name `PurpleVoice` recorded in PROJECT.md as authoritative public-facing name with privacy-first positioning paragraph (load-bearing differentiator vs Koe / Wispr Flow / cloud dictation broadly)
  - **BRD-02** — All user-visible strings (README, Hammerspoon alerts + 5 notification titles, setup.sh banner, install snippet, error messages, manual walkthroughs) use `PurpleVoice` consistently. `voice-cc` is preserved only in repo path on disk, git history, .planning/ artifacts, and the setup.sh `migrate_xdg_dir` FROM-arg literals (intentional). Tagline `Local voice dictation. Nothing leaves your Mac.` placed in README header, setup.sh banner, and Hammerspoon load alert.
  - **BRD-03** — Minimal visual identity: 256×256 PNG icon at `assets/icon-256.png` (lavender #B388EB background, white lips silhouette) derived deterministically from `assets/icon.svg` via sips; lavender menubar glyph (#B388EB for both idle and recording, glyph-shape differentiation).
**Success Criteria** (what must be TRUE):
  1. `PurpleVoice` is recorded in `.planning/PROJECT.md` as the official product name with a one-paragraph privacy-first rationale.
  2. `README.md`, the Hammerspoon load alert + 5 notification titles, the `setup.sh` banner, the user-paste snippet, and all manual walkthroughs use `PurpleVoice` consistently. The `require("purplevoice")` line replaces the prior `require("voice-cc")`.
  3. `assets/icon-256.png` exists at 256×256 with lavender background; menubar is wired into `BRAND.COLOUR_LAVENDER` via hs.styledtext.
  4. `bash tests/run_all.sh` reports 7 passed / 0 failed (6 existing + new `tests/test_brand_consistency.sh` regression catch).
  5. Phase 2 hardening invariants survive: Pattern 2 boundary intact (`grep -c WHISPER_BIN purplevoice-record == 2`), all 6 prior unit tests still GREEN.
**Plans:** 4 plans
  - [x] 02.5-01-PLAN.md — String propagation in code surfaces (rename voice-cc-record → purplevoice-record, voice-cc-lua/ → purplevoice-lua/, env vars VOICE_CC_* → PURPLEVOICE_*, 5 notification titles, load alert, hs.notify orphan-tag cleanup); BRD-02 — completed 2026-04-29 (commits 2c9a7f2, 090c1dd; cache-path edit consolidated from Plan 02.5-02 per checker iter 1)
  - [x] 02.5-02-PLAN.md — XDG path rename + idempotent setup.sh migration (4-state guard for ~/.config|.local/share|.cache/voice-cc/ → purplevoice/, symlink hygiene, banner tagline + new require line); BRD-02 — completed 2026-04-29 (commits ca231e4, cc27db0; live migration moved 466 MB models on Oliver's machine; second run silent/idempotent; 6 bash tests still GREEN; 1 Rule 1 deviation auto-fixed — ~/.hammerspoon/purplevoice removed from mkdir block to fix mkdir/ln-sfn race)
  - [x] 02.5-03-PLAN.md — Visual identity (assets/icon.svg + sips → assets/icon-256.png, menubar lavender via BRAND.COLOUR_LAVENDER + outline/filled glyph differentiation); BRD-03
  - [ ] 02.5-04-PLAN.md — Documentation closure (PROJECT.md name + positioning, formal BRD-01..03 in REQUIREMENTS.md, expanded README, CLAUDE.md updates, tests/test_brand_consistency.sh regression catch); BRD-01, BRD-02, BRD-03
**UI hint**: light (naming + minor visual polish, no full design system)

### Phase 2.7: Security Posture & Government Readiness
**Goal**: Establish PurpleVoice as auditable, verifiably-private dictation suitable for institutional and government audiences with strict privacy requirements (defence, healthcare, legal, finance, journalists). Produces `SECURITY.md` as the authoritative security document — threat model, current posture audit, gap analysis vs government-grade frameworks (NIST SP 800-53, FIPS 140-3, FedRAMP, Common Criteria), and verification mechanisms a third party can independently confirm. Implements quick-win verification: zero-egress proof (Little Snitch / pf rules), SBOM generation, code signing + notarisation pipeline. **Research + verification depth — does NOT pursue formal certifications** (those are 6–18 month, $50k+ commitments and disproportionate for a free personal/team tool).
**Depends on**: Phase 2.5 (the brand + positioning the security claims attach to). The SECURITY.md document references PurpleVoice by name; the README claims (Phase 3) inherit this work.
**Requirements**: TBD — defined during `/gsd:discuss-phase 2.7`. Likely shape:
  - **SEC-01** — Authoritative `SECURITY.md` covering threat model (assets, adversaries, trust boundaries), current posture audit, gap analysis vs NIST SP 800-53 / FIPS 140-3 / FedRAMP / Common Criteria, and a roadmap for any pursued mitigations
  - **SEC-02** — Zero network egress demonstrably true: documented test methodology (Little Snitch / pf rules / packet capture during a recording session) with reproducible verification steps
  - **SEC-03** — Software Bill of Materials (SBOM) generated for runtime dependencies (sox, whisper.cpp, ggml model, Hammerspoon, Silero VAD); committed to repo; updated by setup.sh on dependency change
  - **SEC-04** — Code signing + notarisation infrastructure documented and applied to any binary distribution artifacts (relevant once Phase 3 ships an installer)
  - **SEC-05** — Reproducible build verification — anyone can clone repo + run setup.sh + arrive at byte-identical artifacts (or documented why not, with mitigation)
  - **SEC-06** *(stretch)* — Air-gapped operation supported and documented (machine never connects to internet — voice-cc still functions)
**Success Criteria** (what must be TRUE):
  1. `SECURITY.md` is published in repo root with all sections per SEC-01.
  2. A reader (journalist, sysadmin, government IT auditor) can independently verify the zero-egress claim by following the documented steps in SECURITY.md.
  3. SBOM file (`SBOM.spdx.json` or similar) exists in repo, lists all runtime dependencies with versions and licenses.
  4. Code signing + notarisation (or explicit "not yet — applies in Phase 3") status is documented honestly.
  5. PROJECT.md positioning paragraph includes governments / institutions in the audience description (this lands in Phase 2.5 BRD-01 but Phase 2.7 verifies the claims are substantiated).
**Plans:** 5 plans
  - [ ] 02.7-00-PLAN.md — Wave 0: test infrastructure (tests/security/) + Syft conditional install + setup.sh PURPLEVOICE_OFFLINE=1 guards + SECURITY.md skeleton + SBOM.spdx.json placeholder
  - [ ] 02.7-01-PLAN.md — Threat model (STRIDE + LINDDUN) + Scope (assets/trust boundaries) + tests/test_security_md_framing.sh D-17 lint (Wave 1, parallel with 02.7-02)
  - [ ] 02.7-02-PLAN.md — Verification scripts (verify_egress 3-layer chain, verify_sbom, verify_air_gap, verify_signing) + setup.sh Step 8 SBOM regen with deterministic post-process (Wave 1, parallel with 02.7-01)
  - [ ] 02.7-03-PLAN.md — Gap analysis: NIST SP 800-53 Rev 5 / Low-baseline (deep per-control) + 6 framed framework sections (FIPS 140-3 / FedRAMP / Common Criteria / HIPAA / SOC 2 / ISO 27001) (Wave 2)
  - [ ] 02.7-04-PLAN.md — Documentation finalisation: SECURITY.md complete (TL;DR + Audience Entry-Points + Code Signing + Reproducible Build + Vuln Disclosure + How to Verify) + verify_reproducibility.sh impl + REQUIREMENTS.md SEC-01..06 formalisation + README.md expansion (Wave 3)
**UI hint**: none (research + documentation + verification scripts; no user-visible UI surface)
**Research flag**: yes — needs `/gsd:research-phase 2.7` before planning. Government-grade software claims are subtle; researcher should investigate Apple notarisation tradeoffs, current SBOM tool ecosystem (Syft, CycloneDX), and the actual auditability gap between "claims" vs "verifiable claims" for an open-source local-only tool.

### Phase 3.5: Hover UI / HUD
**Goal**: A small floating HUD that surfaces voice-cc state at-a-glance — visible "● recording" indicator while the hotkey is held, fading or hideable when idle. Complements (does not replace) Phase 2's menu-bar indicator. Optimised for low CPU when idle and zero distraction when not actively recording.
**Depends on**: Phase 2.5 (HUD uses the brand chosen in Branding). Also Phase 2 (the press/release lifecycle and menu-bar indicator are the layer the HUD piggybacks on). *(Note: previously listed as depending on Phase 3 — flipped 2026-04-28 when Phase 3 was reordered to come last; the dependency on Distribution was sequencing-by-polish, not technical.)*
**Requirements**: TBD — defined during `/gsd:discuss-phase 3.5`. Likely shape:
  - **HUD-01** — Floating canvas widget (`hs.canvas` or `hs.drawing`) appears within ~50 ms of hotkey press and disappears within ~250 ms of release
  - **HUD-02** — User-toggle-able visibility (env var or `~/.config/voice-cc/config.sh` setting)
  - **HUD-03** — Effectively zero CPU when idle (no animation loops; only redraws on state change)
  - **HUD-04** — Position configurable (near cursor / screen edge / fixed coordinates) with a sensible default
**Success Criteria** (what must be TRUE):
  1. While the hotkey is held, a floating HUD element appears with a visible "● recording" affordance using the brand chosen in Phase 2.5.
  2. The HUD disappears within ~250 ms of release; while idle, no HUD is on screen and no measurable CPU is consumed.
  3. A config toggle hides the HUD entirely for users who only want the menu-bar indicator (Phase 2 still ships the menu-bar indicator regardless of HUD state).
  4. The HUD does not steal focus, does not interfere with paste, and does not appear in screen recordings unless the user explicitly enables it.
**Plans**: 4 plans
**UI hint**: yes (this IS the UI phase)

### Phase 4 (v1.x): Quality of Life
**Goal**: Address the first real-use frustrations now that the polished loop is stable. Each item has a specific trigger; do not build speculatively.
**Depends on**: Phase 3.5 (must be triggered by observed v1 frustrations after the loop is fully polished, not anticipated). *(Note: previously framed as "after v1 ships"; reordered 2026-04-28 to come BEFORE Phase 3 Distribution — distribute the QoL-included product, not bare hardening.)*
**Requirements**: QOL-01, QOL-02, QOL-03, QOL-04, QOL-05 (all v2-tier, deferred until use-driven trigger fires)
**Success Criteria** (what must be TRUE):
  1. A second hotkey re-pastes the most recent transcript (recovery for focus-lost paste).
  2. Pressing Esc during recording cancels the in-flight capture without paste.
  3. `~/.config/voice-cc/replacements.txt` find/replace pairs are applied to transcripts as a `sed` post-filter step ("Versel" → "Vercel").
  4. A capped (≤10 MB) rolling history log lives at `~/.cache/voice-cc/history.log` for debugging.
  5. `VOICE_CC_MODEL=medium.en` (or any other model present in the models dir) is honoured at runtime without code changes.
**Candidate items in backlog** (surface during `/gsd:discuss-phase 4`):
  - Alternative hotkey schemes — fn-press-and-hold via `hs.eventtap.flagsChanged` (with hold-threshold to avoid racing macOS's emoji popup), Karabiner-Elements remap-fn-to-F19 path. User-surfaced 2026-04-28.
**Plans**: 4 plans

### Phase 3: Distribution & Benchmarking + Public Install
**Goal**: Make voice-cc reproducible on a fresh machine via a single idempotent local script, AND make it shareable online via a one-line `curl ... | bash` public installer. Document the permission grants and recovery procedures. Produce `hyperfine` measurements on Oliver's actual hardware that determine whether Phase 5 (warm-process upgrade) is needed.
**Depends on**: Phase 4 (Distribution is the LAST step of v1 — distribute the finished, QoL-polished product, not a half-finished hardening pass). Transitively also depends on Phase 2.5 (brand) and Phase 2 (hardened production config).
**Phase order note**: Phase 3 is numerically third but executes sixth in v1 — reordered 2026-04-28 per user direction.
**Requirements**: DST-01, DST-02, DST-03, DST-04, **plus DST-05 (TBD — public one-line installer)**
**Success Criteria** (what must be TRUE):
  1. Running `./install.sh` on a clean machine installs Hammerspoon, sox, whisper-cpp, downloads `ggml-small.en.bin`, creates `~/.config/voice-cc/`, `~/.local/share/voice-cc/models/`, `~/.cache/voice-cc/`, and symlinks `voice-cc-record` into `~/.local/bin/`. Re-running it changes nothing and never clobbers user-edited config (`config.sh`, `vocab.txt`).
  2. `install.sh` finishes by *printing* (never auto-appending) the exact `require("voice-cc")` (or branded equivalent) line for the user to paste into their own `~/.hammerspoon/init.lua`.
  3. README walks through the Microphone + Accessibility grant for Hammerspoon, the macOS Dictation shortcut disable, and the `tccutil reset Microphone org.hammerspoon.Hammerspoon` recovery procedure.
  4. `hyperfine` produces p50 and p95 end-to-end latency numbers for short (~2 s), medium (~5 s), and long (~10 s) utterances on Oliver's machine; the numbers explicitly inform a documented go/no-go decision for Phase 5.
  5. **A public one-line installer** (`curl -fsSL https://<host>/install | bash`, where `<host>` is GitHub raw or a stable redirect) clones the repo (or downloads a release tarball) into a sensible location, then invokes the local `install.sh`. The public install is idempotent, prints next steps including the brand-aware `require()` line, and is documented in the README. The repo must be public on GitHub before this success criterion can pass.
**Plans**: 4 plans

### Phase 5 (v1.1, CONDITIONAL): Warm-Process Upgrade
**Goal**: Cut latency below 1 second by replacing per-utterance `whisper-cli` invocation with a long-running `whisper-server` over localhost HTTP, managed by a LaunchAgent. **CONDITIONAL: only triggered if Phase 3 hyperfine measurements show p50 > 2.0 s OR p95 > 3.0 s on Oliver's hardware.**
**Depends on**: Phase 3 (hyperfine measurements must demand it; until the data says we need it, the simpler one-shot architecture wins on every dimension that isn't latency).
**Requirements**: PERF-01, PERF-02 (both v2-tier, conditional)
**Success Criteria** (what must be TRUE):
  1. `whisper-server` runs as a LaunchAgent (`com.olivergallen.voice-cc-server.plist`) with `KeepAlive=true` and `RunAtLoad=true`; it survives reboots and self-restarts on crash.
  2. The bash `transcribe()` function swap from `whisper-cli` to `curl 127.0.0.1:8080/inference -F file=@...` is the *only* change in the pipeline — Hammerspoon code, file layout, config, and failure model are unchanged.
  3. Re-running the Phase 3 hyperfine benchmark shows p50 latency < 1.0 s for short utterances.
  4. An optional Core ML encoder build (`-DWHISPER_COREML=1`) for ~3× ANE encoder speedup is documented and either automated by an upgrade path in `install.sh` or covered by a clear manual-build section in the README.
**Plans**: 4 plans

## Research Flags

Phases that may need `/gsd:research-phase` during planning:

- **Phase 2 (Hardening)** — needs targeted spike on (a) the exact `hs.pasteboard` multi-type write API for the `org.nspasteboard.TransientType` UTI and (b) the macOS Settings deep-link URL format for the Microphone privacy pane (changes across major releases).
- **Phase 3 (Distribution)** — public one-line installer (`curl ... | bash`) needs a quick check on hosting (GitHub raw vs. release tarball vs. short URL), atomic-download safety, and whether to validate signatures.
- **Phase 3.5 (Hover UI)** — `hs.canvas` vs `hs.drawing` ergonomics for a low-CPU "show only on press" overlay; whether a transparent always-on-top window has any focus-stealing implications.
- **Phase 5 (v1.1)** — if it triggers, needs hands-on research on `whisper-server`'s exact HTTP API contract under high-frequency PTT load, LaunchAgent `KeepAlive` interactions, and Core ML compilation reproducibility.

Phases with well-documented standard patterns (skip research-phase):

- **Phase 1 (Spike)** — Spellspoon and local-whisper were direct reference implementations. ✓ DONE.
- **Phase 2.5 (Branding)** — naming and string propagation; standard work.
- **Phase 4 (v1.x)** — every item is < 1 day with an obvious implementation.

## Progress

Listed in **execution order** (Phase 3 reordered to come last in v1; phase numbers are identifiers, not sequence):

| # | Phase | Plans Complete | Status | Completed |
|---|-------|----------------|--------|-----------|
| 1 | Phase 1: Spike | 3/3 | Complete | 2026-04-27 |
| 2 | Phase 2: Hardening | 4/4 | Complete | 2026-04-28 |
| 3 | Phase 2.5: Branding | 3/4 | Wave 2 done — Plan 02.5-01, 02.5-02, 02.5-03 complete 2026-04-29; Wave 3 (02.5-04 docs closure) unblocked | 2026-04-29 |
| 4 | Phase 2.7: Security Posture & Government Readiness | 0/5 | Planned — 5 plans across 4 waves; ready for /gsd:execute-phase 2.7 | - |
| 5 | Phase 3.5: Hover UI / HUD | 0/0 | Queued | - |
| 6 | Phase 4 (v1.x): Quality of Life | 0/0 | Queued | - |
| 7 | Phase 3: Distribution & Benchmarking + Public Install | 0/0 | Queued (final v1 phase) | - |
| 8 | Phase 5 (v1.1, conditional): Warm-Process Upgrade | 0/0 | Conditional on Phase 3 hyperfine | - |

## Coverage Summary

- **Original v1 requirements:** 26 total (CAP-01..04, TRA-01..06, INJ-01..04, FBK-01..03, ROB-01..05, DST-01..04)
- **Mapped to v1 phases (1–3):** 26
- **Unmapped v1:** 0
- **New requirements added 2026-04-27 (TBD elaboration):** BRD-01..03 (Phase 2.5 — formalised 2026-04-29), DST-05 (Phase 3 extension), HUD-01..04 (Phase 3.5)
- **New requirements added 2026-04-29 (TBD elaboration):** SEC-01..06 (Phase 2.7 — formalised during `/gsd:discuss-phase 2.7`)
- **v2 requirements (deferred):** QOL-01..05, PERF-01..02 — assigned to Phase 4 (QoL) and Phase 5 (conditional warm process)

| Phase | v1 Requirements | Count |
|-------|-----------------|-------|
| 1. Spike | CAP-01, CAP-02, CAP-03, CAP-04, TRA-01, TRA-02, TRA-03, INJ-01, ROB-03, ROB-05 | 10 |
| 2. Hardening | TRA-04, TRA-05, TRA-06, INJ-02, INJ-03, INJ-04, FBK-01, FBK-02, FBK-03, ROB-01, ROB-02, ROB-04 | 12 |
| 2.5. Branding | BRD-01, BRD-02, (BRD-03) | 2-3 (TBD) |
| 3. Distribution & Benchmarking + Public Install | DST-01, DST-02, DST-03, DST-04, DST-05 | 5 |
| 3.5. Hover UI / HUD | HUD-01, HUD-02, HUD-03, HUD-04 | 4 (TBD) |
| **Total v1** | | **33-34** (was 26) |

---
*Roadmap created: 2026-04-23*
*Roadmap extended: 2026-04-27 (Phase 2.5 Branding, Phase 3 Public Install extension, Phase 3.5 Hover UI per user request)*
*Roadmap reordered: 2026-04-28 (Phase 3 Distribution moved to end of v1 per user direction; Phase 3.5 dependency flipped from Phase 3 to Phase 2.5; Phase 2 closed)*
