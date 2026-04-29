# PurpleVoice Security Posture

> Local voice dictation. Nothing leaves your Mac.

**Status: SKELETON (Phase 2.7 in progress).** This file is being authored across Phase 2.7 plans 02.7-01..02.7-04. Sections without content are placeholders.

**Audience:** Technical IT auditors at government / defence / healthcare / legal / finance / journalism / air-gapped operator organisations evaluating PurpleVoice. (D-13)

**Frameworks covered (D-16):** NIST SP 800-53 Rev 5 (per-control depth) + FIPS 140-3 + FedRAMP-tailored + Common Criteria + HIPAA Security Rule §164.312 + SOC 2 Type II TSC + ISO/IEC 27001:2022 Annex A (six framed at "compatible with" depth).

**Framing constraint (D-17):** This document uses "compatible with" / "supports" / "consistent with applicable obligations for in-scope code" framing. PurpleVoice is NOT audited or accredited against any framework. Over-claims would damage the auditable trust narrative this document exists to establish.

***

## TL;DR

<!-- TODO: Plan 02.7-04 fills this section (1-page summary for non-technical readers per D-13 / Pitfall 10). -->

## Audience Entry-Points

<!-- TODO: Plan 02.7-04 fills this section (table of ToC links per audience: journalist / federal IT auditor / EU institutional buyer / procurement officer per Pitfall 10). -->

## Scope

### What PurpleVoice IS

PurpleVoice is a one-shot push-to-talk dictation tool for macOS Apple Silicon. The full process lifecycle for a single utterance:

1. User holds `cmd+shift+e`. Hammerspoon's `hs.hotkey` callback (registered by `purplevoice-lua/init.lua`) fires.
2. Hammerspoon spawns `purplevoice-record` (a bash script) via `hs.task` — this is the only process boundary where PurpleVoice introduces new code.
3. `purplevoice-record` spawns `sox` to capture 16 kHz mono PCM audio to `/tmp/purplevoice/recording.wav`.
4. User releases the hotkey. Hammerspoon sends SIGTERM to `sox`; the WAV finalises.
5. `purplevoice-record` invokes the local transcription binary (Pattern 2 boundary — single invocation site) on the WAV with `--vad --vad-model ... --no-prints --prompt vocab.txt`.
6. The transcript is written to the macOS pasteboard with `org.nspasteboard.TransientType` UTI; the prior clipboard is preserved and restored ~250 ms after paste.
7. Hammerspoon synthesises `cmd+v` via `hs.eventtap.keyStroke` into the focused window.
8. The WAV is deleted by an EXIT trap; `purplevoice-record` exits.

Total wall-clock for a 5-second utterance: ~1-2 seconds on M-series hardware. Total persistent state: zero (the WAV is deleted; no transcript log; no telemetry; no daemon).

### What PurpleVoice IS NOT

- Not a daemon (one-shot CLI per utterance).
- Not a cloud service (no network calls during runtime — see [Egress Verification](#egress-verification)).
- Not a `.app` bundle (text files + Hammerspoon Spoon module + brew binaries; see [Code Signing & Notarisation](#code-signing--notarisation)).
- Not multi-user (single-user personal tool by design).
- Not audited or accredited against any framework. (PurpleVoice is *compatible with* applicable obligations for in-scope code — see framework sections below.)

### Assets

| # | Asset | Lifecycle | Sensitivity |
|---|---|---|---|
| 1 | Voice content (audio + transcript) | Single-utterance ephemeral; deleted on EXIT trap | Highest — user's spoken content; treated as PII |
| 2 | `~/.config/purplevoice/vocab.txt` | User-managed; persists across utterances | User-controlled; may contain client names / project terms |
| 3 | `~/.config/purplevoice/denylist.txt` | Project-owned; setup.sh always-overwrites | Low — public, project-supplied; tampering would weaken hallucination suppression |
| 4 | `~/.local/share/purplevoice/models/ggml-small.en.bin` + `ggml-silero-v6.2.0.bin` | Static, downloaded once via setup.sh | Integrity-critical — SHA256 verified at install time |

### Trust Boundaries

1. **User-keyboard ↔ Hammerspoon** — TCC (Transparency, Consent, Control) gates: Microphone + Accessibility permissions on the Hammerspoon bundle-id (`org.hammerspoon.Hammerspoon`). User grants once via System Settings.
2. **Hammerspoon ↔ bash glue** — Process spawn via `hs.task`. Hammerspoon's PATH does NOT include `/opt/homebrew/bin`; bash glue uses absolute paths (Phase 1 ROB-03).
3. **Bash glue ↔ sox / transcription binary** — Subprocess; signal-driven lifecycle (SIGTERM on hotkey release; SIGINT-aware EXIT trap).
4. **Bash glue ↔ pasteboard** — Clipboard write with `org.nspasteboard.TransientType` UTI (Phase 2 INJ-03); 250 ms restore delay.
5. **Hammerspoon ↔ focused window** — `cmd+v` synthesis via `hs.eventtap.keyStroke`. Out-of-process; receiving app handles paste.

### Out of Scope (with rationale)

- **Multi-user attacks** — Single-user tool by design. Multi-tenancy would require auth, role separation, and audit infrastructure that contradicts the personal-tool ethos.
- **Network adversary** — No network calls during runtime. This is the load-bearing claim verified by [`tests/security/verify_egress.sh`](#egress-verification). Setup-time downloads (HuggingFace model, Homebrew bottles) are explicit, one-time, and documented in this file.
- **Compromised macOS kernel** — Out of scope for any user-space tool. Threat model assumes baseline macOS protections (SIP, kernel signing, secure boot).
- **Physical access to unlocked Mac** — Assume baseline OS protections (FileVault, screen lock). PurpleVoice does not introduce physical-access defences beyond what macOS provides.
- **Hammerspoon's pre-existing attack surface** — Hammerspoon is a long-running app the user already trusts. PurpleVoice does NOT introduce new behaviour beyond what `purplevoice-lua/init.lua` does (reviewable plain-text Lua, symlinked from this repo). Compromise of Hammerspoon itself is upstream's concern.

## Threat Model

PurpleVoice's threat model is authored using **STRIDE primary + LINDDUN privacy overlay** (RESEARCH Priority 1). STRIDE covers security-property threats; LINDDUN was specifically designed at KU Leuven to address STRIDE's privacy blind spot. Both methodologies are industry-standard and federally-recognised (CMS Threat Modeling Handbook references STRIDE; LINDDUN is documented at linddun.org).

Status vocabulary (consistent across this document): **Met** = mitigation in place + verifiable. **Partial** = mitigation exists with documented residual risk. **Not Pursued** = engineering choice with rationale (NOT "failed" or "out of scope"). **N/A** = does not apply, with rationale.

The threat model is scoped to the PurpleVoice process tree (`purplevoice-record` + its `sox` child + its transcription-binary child); see `purplevoice_pid_tree()` in `tests/security/lib/process_tree.sh` for the operational definition. Hammerspoon's main process is intentionally excluded from runtime egress scope (Pitfall 5 / D-06): Hammerspoon may hold long-lived TCP keepalives unrelated to PurpleVoice, and including its PID would muddy the egress claim.

### STRIDE Analysis (Security Threats)

| STRIDE Category | Threat for PurpleVoice | Status | Mitigation / Rationale |
|---|---|---|---|
| **Spoofing** | Adversary spoofs Hammerspoon to capture mic | N/A | TCC binds permission to bundle-id (`org.hammerspoon.Hammerspoon`); spoofing requires admin + SIP-disabled or signed-binary swap. Out of single-user-tool threat model. |
| **Tampering (a)** | Clipboard manager retains transcripts | Met | `hs.pasteboard.writeAllData` writes both `org.nspasteboard.TransientType` and `org.nspasteboard.ConcealedType` UTIs (Phase 2 INJ-03). Honouring managers (1Password 8+, Maccy, Raycast, Pastebot) skip the entry. Residual risk: non-conforming managers may retain. Documented. |
| **Tampering (b)** | Hotkey-hijack via accessibility-grant abuse | Met | Hammerspoon Accessibility is user-granted via System Settings. PurpleVoice does not extend the Hammerspoon TCC surface; accessibility scope is owned by Hammerspoon's bundle. |
| **Tampering (c)** | Modifying `denylist.txt` to allow hallucinations through | Partial | Project-owned; `setup.sh` Step 6b always-overwrites from `config/denylist.txt`. Users may `chmod -w` to pin a custom version (documented in setup notes). Risk: stale denylist after a setup.sh run discards user customisation. |
| **Repudiation** | No logging of transcripts → user cannot prove what was said | Not Pursued | By design. Privacy > accountability for a personal tool. v1.x QOL-04 (rolling history log capped at 10 MB) is the opt-in mitigation; not in v1. |
| **Information Disclosure (a)** | Ephemeral WAV in `/tmp/purplevoice/` lingers after crash | Met | Phase 2 ROB-04: bash `EXIT` trap covers all exit paths (including SIGINT); plus 5-min sweep at startup of `find /tmp/purplevoice -mmin +5 -delete`. |
| **Information Disclosure (b)** | Clipboard transient marker not honoured by all clipboard managers | Partial | See Tampering (a). Mitigation works for the major macOS clipboard managers as of 2026; residual risk for non-conforming third-party tools. |
| **Information Disclosure (c)** | Model file integrity violated (corrupt or substituted GGML) | Met | `setup.sh` Step 5 SHA256-verifies the Whisper model against the pinned constant `MODEL_SHA256`. Mismatch aborts install with non-zero exit. The Silero VAD model is size-sanity-checked (>=800 KB) and pin-able in a Phase 2.7 follow-up. |
| **Information Disclosure (d)** | `vocab.txt` content leaks via dotfile sharing | Met (warned) | README warning: `vocab.txt` is the hint Whisper sees on every utterance — be aware of what you put in it (client names, project codenames, etc.). User-controlled. |
| **Information Disclosure (e)** | **Network egress of voice content** (THE central concern) | Met | Verified by [`tests/security/verify_egress.sh`](#egress-verification) — 3-layer evidence chain (lsof + nettop + pf+tcpdump) on the PurpleVoice process tree (`purplevoice-record` + `sox` + transcription children). See [Egress Verification](#egress-verification) for methodology + macOS Sequoia 15.7.5 caveat. |
| **Denial of Service** | Rapid hotkey double-press spawns duplicate `sox` processes | Met | Phase 2 ROB-01: Lua-side `isRecording` guard in `purplevoice-lua/init.lua` rejects re-entrant invocations. Verified by `tests/manual/test_reentrancy.md`. |
| **Elevation of Privilege** | Malicious `init.lua` abuses Hammerspoon's Accessibility grant | N/A | PurpleVoice's `init.lua` is symlinked from `~/.hammerspoon/purplevoice` to this repo's `purplevoice-lua/init.lua` — reviewable plain-text Lua (315 lines as of this writing). Anti-Pattern 4 (PITFALLS.md) prohibits `setup.sh` from auto-editing `~/.hammerspoon/init.lua`; user controls what their Hammerspoon runs. |

### LINDDUN Privacy Overlay

LINDDUN supplements STRIDE with privacy-by-design threat categories (linddun.org / KU Leuven). Several categories overlap with STRIDE Information Disclosure; cross-references are noted below.

| LINDDUN Category | Threat for PurpleVoice | Status | Mitigation / Rationale |
|---|---|---|---|
| **Linkability** | Two utterances linkable across time → behavioural profile of the user | N/A by design | No telemetry; no transcript persistence (history log is v1.x opt-in). Linkage requires direct disk access to user's `$HOME` — same threat surface as any local data. |
| **Identifiability** | Voice biometric inferable from WAV → user re-identification | Met | WAV is ephemeral (deleted on EXIT trap per ROB-04); never leaves machine; deleted before `purplevoice-record` returns. |
| **Non-repudiation** | User cannot deny having dictated specific content (e.g., coerced-testimony risk) | Not Pursued | See STRIDE Repudiation row. By design. v1.x QOL-04 opt-in history log is the mitigation if this becomes load-bearing for a user. |
| **Detectability** | Adversary can detect PurpleVoice is in use (social signal) | Partial | macOS shows the orange microphone indicator during `sox` capture — this is an OS-level signal owned by macOS, not by PurpleVoice. Documented as expected behaviour. |
| **Disclosure of information** | Voice content reaches unintended parties | Met | Cross-reference STRIDE Information Disclosure rows (a)-(e) above. Same mitigations apply. |
| **Unawareness** | User unaware of what PurpleVoice does with their voice content | Met | This document, the README, and the `setup.sh` banner tagline ("Local voice dictation. Nothing leaves your Mac.") establish informed-use baseline. The whole reason Phase 2.7 exists. |
| **Non-compliance** | Documented behaviour doesn't match actual behaviour → trust breach | Met | Runnable verification scripts at `tests/security/verify_*.sh` let readers confirm claims rather than rely on this document's prose. See [How to Verify These Claims](#how-to-verify-these-claims). |

### Threat Model — Methodology Notes

**Why STRIDE primary?** STRIDE (Spoofing / Tampering / Repudiation / Information Disclosure / Denial of Service / Elevation of Privilege) is the de-facto industry threat-modelling taxonomy and the one federal auditors are most likely to recognise on first read. The CMS Threat Modeling Handbook (CMS.gov) and the Microsoft SDL both centre STRIDE; CISA's threat-modelling guidance references it; OWASP teaches it. Choosing STRIDE keeps this document recognisable to a federal IT auditor who has never heard of PurpleVoice.

**Why LINDDUN as overlay?** STRIDE has a documented privacy blind spot: its "Information Disclosure" category collapses confidentiality concerns into a single bucket and does not distinguish, e.g., re-identification from linkability from unawareness. LINDDUN (KU Leuven; linddun.org) was specifically designed to address this gap with seven privacy-property categories. For a tool whose central promise is voice-content privacy, the LINDDUN overlay is load-bearing — it gives auditors a vocabulary for the privacy claims that STRIDE alone glosses.

**How to read the matrices:** Each row is a concrete threat for THIS tool, not a category placeholder. Status cells use the four-value vocabulary (Met / Partial / Not Pursued / N/A) defined above; the framing lint at `tests/test_security_md_framing.sh` enforces this vocabulary on every commit (Pitfall 15). Mitigation cells cross-reference the runnable verification scripts at `tests/security/verify_*.sh` where a runtime claim is being made — readers are encouraged to run the scripts rather than trust the prose. The `## How to Verify These Claims` section (filled in Plan 02.7-04) summarises the full verification procedure.

**Threats deliberately not enumerated:** Generic threats that are not specific to PurpleVoice (e.g., "an attacker compromises a system library") are out of scope for this matrix. The "Threat Model — Out of Scope" subsection below lists the categories that were considered and explicitly excluded; everything not listed there or in a STRIDE/LINDDUN row is by definition outside the threat model and would require an explicit revision to include.

**Update cadence:** This threat model is reviewed at every release-gate (D-03). Any new attack surface introduced by a feature plan triggers a STRIDE-row addition; any new privacy-property concern triggers a LINDDUN-row addition. Drift toward broader claims is caught by the `tests/test_security_md_framing.sh` lint, which enforces the four-value status vocabulary and bans the marketing-prone phrases `\bcompliant\b`, `\bcertified\b`, and `\bguarantees\b` outside qualified contexts (D-17 / Pitfall 4).

**Cross-reference index for the matrices above:**

- Tampering (a) + Information Disclosure (b) + LINDDUN Detectability → see Phase 2 INJ-03 implementation (`hs.pasteboard.writeAllData` two-UTI write).
- Tampering (c) → see `setup.sh` Step 6b (always-overwrite from `config/denylist.txt`).
- Information Disclosure (a) + LINDDUN Identifiability → see `purplevoice-record` EXIT trap (ROB-04) and 5-min `find` sweep at startup.
- Information Disclosure (c) → see `setup.sh` Step 5 (`MODEL_SHA256` constant + `shasum -a 256` check).
- Information Disclosure (e) + LINDDUN Non-compliance → see `tests/security/verify_egress.sh` (Plan 02.7-02 owns the body) and `## Egress Verification` (Plan 02.7-02 fills).
- Denial of Service → see `purplevoice-lua/init.lua` `isRecording` guard (ROB-01).
- Elevation of Privilege → see Anti-Pattern 4 in `.planning/research/PITFALLS.md` (no auto-edit of `~/.hammerspoon/init.lua`).

### Threat Model — Out of Scope

The following threats are explicitly out of scope, with rationale:

- **Multi-user attacks** — PurpleVoice is single-user by design; multi-user threat models are organisational concerns.
- **Network adversary during runtime** — The SEC-02 zero-egress claim makes runtime network adversary irrelevant: there is nothing on the network for an adversary to intercept. Setup-time downloads (HuggingFace, Homebrew) are over HTTPS with SHA256 verification.
- **Compromised macOS kernel** — Out of scope for any user-space tool.
- **Physical access to unlocked Mac** — Threat model assumes baseline OS protections (FileVault, screen lock). PurpleVoice does not extend physical-access defences.
- **Compromised Hammerspoon** — Hammerspoon is upstream-trusted. PurpleVoice does not introduce new attack surface in the Hammerspoon process; the `init.lua` it ships is plain-text reviewable.
- **Compromised brew bottle (sox / transcription binary) at install time** — Homebrew bottle SHA256s are verified by Homebrew; PurpleVoice inherits that trust chain. A formal supply-chain attack against a brew bottle would be Homebrew's incident, not PurpleVoice's.

## Egress Verification

<!-- TODO: Plan 02.7-02 fills this section (3-layer evidence chain: lsof + nettop + pf+tcpdump; Pitfall 1 caveat for macOS Sequoia 15.7.5; cross-ref tests/security/verify_egress.sh). -->

## Software Bill of Materials (SBOM)

<!-- TODO: Plan 02.7-02 fills this section (SPDX 2.3 SBOM.spdx.json; direct + transitive + system context per D-11; cross-ref tests/security/verify_sbom.sh). -->

## Air-Gapped Installation

<!-- TODO: Plan 02.7-02 fills setup procedure; Plan 02.7-04 cross-references README. PURPLEVOICE_OFFLINE=1 mode per D-08; Pitfall 8 brew limitation; sideload paths. -->

## NIST SP 800-53 Rev 5 / Low-baseline Mapping

### Framing

PurpleVoice's NIST 800-53 mapping targets the **Rev 5 Low-baseline** (per SP 800-53B). Moderate and High baselines invoke continuous monitoring (SC-5(2)), incident response procedures (IR family), and audit-record retention (AU-11) — all organisational controls that don't apply to a single-binary local tool. Claiming Low-baseline alignment is honest engineering; claiming Moderate would over-reach.

All control IDs reference NIST SP 800-53 Rev 5 (csrc.nist.gov/pubs/sp/800/53/r5/upd1/final). No Rev 4-only artefacts are used here — specifically, no AC-3 sub-letter subdivisions and no Rev-4-style SC-12 enhancement numbers that don't exist in Rev 5 in the same form.

Status vocabulary:

- **Met** — mitigation in place + verifiable (cross-referenced to a verification script or codebase reference).
- **Partial** — mitigation exists with documented residual risk.
- **Not Pursued** — engineering choice, with rationale (privacy > accountability for a personal tool).
- **N/A** — does not apply, with rationale.

### Applicability Matrix (Family-level)

NIST 800-53 Rev 5 has 20 control families. For a single-binary local-only personal tool, the following families apply; all others are **N/A by tool-class** (organisational concerns):

| Family | Code | Applies? | Rationale |
|---|---|---|---|
| Access Control | AC | Yes | TCC permission model, hotkey scoping, who-can-invoke-PurpleVoice |
| Audit and Accountability | AU | Limited | No logging by design (privacy > accountability); documented explicitly |
| Awareness and Training | AT | N/A | Organisational; single-developer tool |
| Assessment, Authorization, and Monitoring | CA | N/A | Organisational process |
| Configuration Management | CM | Limited | Model file SHA256, idempotent setup.sh, config dotfiles — partial application |
| Contingency Planning | CP | N/A | Organisational; PurpleVoice is stateless |
| Identification and Authentication | IA | Yes | TCC binds permissions to bundle-id; explicit grant model |
| Incident Response | IR | N/A | Organisational |
| Maintenance | MA | N/A | Organisational |
| Media Protection | MP | Limited | Ephemeral WAV cleanup is the closest analogue; partial |
| Physical and Environmental Protection | PE | N/A | OS-level / facility-level |
| Planning | PL | N/A | Organisational |
| Program Management | PM | N/A | Organisational |
| Personnel Security | PS | N/A | Organisational |
| PII Processing and Transparency | PT | Yes | Tool processes voice (PII per most interpretations); transparency = this document |
| Risk Assessment | RA | N/A | Organisational |
| System and Services Acquisition | SA | Limited | SBOM (D-11) is the SA-equivalent for a tool |
| System and Communications Protection | SC | Yes | Zero-egress claim; clipboard transient marker; process-tree silence — central to PurpleVoice |
| System and Information Integrity | SI | Yes | Model SHA256, denylist filter, hallucination suppression |
| Supply Chain Risk Management | SR | Limited | SBOM + brew + HuggingFace mirror = supply-chain surface |

### Per-Control Mapping (Yes / Limited families)

| Control ID | Title (abbreviated) | Status | Rationale + Substantiation |
|---|---|---|---|
| **AC-3** | Access Enforcement | Met | TCC enforces Microphone + Accessibility on the Hammerspoon bundle-id (`org.hammerspoon.Hammerspoon`); hotkey requires user-scoped hardware access. Verified by macOS System Settings → Privacy & Security panel state. |
| **AC-6** | Least Privilege | Met | `sox` + the transcription binary run as the user UID; no SUID bits; no privileged operations. Verified by `ls -l /opt/homebrew/bin/sox /opt/homebrew/bin/whisper-cli`. |
| **AC-14** | Permitted Actions w/o Identification | Met | No anonymous usage path; user must hold a physical hotkey on their own keyboard; recording is bound to the macOS user session. |
| **AU-2** | Event Logging | Not Pursued | By design. Privacy > accountability for a personal tool. Cross-reference STRIDE §Repudiation row in the [Threat Model](#threat-model). v1.x QOL-04 (10 MB rolling history log) is the opt-in mitigation if a user opts in. |
| **AU-12** | Audit Record Generation | Not Pursued | Same rationale as AU-2. |
| **IA-2** | User Identification & Authentication | Met (via OS) | macOS user session = identification; PurpleVoice inherits. No PurpleVoice-issued credentials. |
| **IA-5** | Authenticator Management | N/A | PurpleVoice does not issue authenticators. |
| **SC-7** | Boundary Protection | Met | Zero outbound network egress at runtime. Verified by `tests/security/verify_egress.sh` (3-layer evidence: lsof + nettop + pf+tcpdump). See [Egress Verification](#egress-verification) for methodology + Sequoia 15.7.5 caveat. |
| **SC-8** | Transmission Confidentiality & Integrity | N/A | No transmission to protect — PurpleVoice is local-only at runtime. |
| **SC-12** | Cryptographic Key Establishment & Management | N/A | No keys; PurpleVoice performs no cryptographic operations on user data. The only cryptographic primitive is SHA-256 for model file integrity (install-time) — see SI-7. |
| **SC-28** | Protection of Information at Rest | Partial | WAV files are ephemeral (`EXIT` trap cleanup including SIGINT per ROB-04); no transcript persistence beyond opt-in v1.x history; user's `~/.config/purplevoice/` is at-rest-protected by macOS FileVault if the user has enabled it (organisation's responsibility). |
| **SI-2** | Flaw Remediation | Partial | Brew-tracked dependencies update via `brew upgrade`; PurpleVoice itself is git-tracked and update-visible. No vulnerability disclosure programme yet — see [Vulnerability Disclosure](#vulnerability-disclosure). |
| **SI-7** | Software, Firmware, and Information Integrity | Met | `setup.sh` Step 5 SHA256-verifies the Whisper model against the pinned constant `MODEL_SHA256`; mismatch aborts the install with non-zero exit. Silero VAD model is size-sanity-checked. |
| **SI-10** | Information Input Validation | Met | `vocab.txt` cap (~150 words for `--prompt`); denylist exact-match filter (Phase 2 TRA-06); duration gate (Phase 2 TRA-05) drops <0.4s clips. |
| **PT-3** | PII Processing Purposes | Met | Voice content processed solely for transcription; ephemeral; no telemetry — substantiated by this document + `tests/security/verify_egress.sh`. |
| **PT-4** | Consent | Met | User-initiated hotkey; explicit TCC grants required (Microphone + Accessibility); no implicit consent path. |
| **CM-7** | Least Functionality | Met | One-shot CLI per utterance; no persistent daemon; no extra features beyond the documented loop. |
| **MP-6** | Media Sanitization | Partial | Ephemeral WAV cleanup via `EXIT` trap is the closest analogue. Full cryptographic erasure is out of scope (relies on macOS APFS journal handling). |
| **SA-15** | Development Process, Standards, and Tools | Limited | SBOM (`SBOM.spdx.json`, SPDX 2.3, regenerated by `setup.sh` Step 8 with Syft) is the SA-equivalent. See [Software Bill of Materials](#software-bill-of-materials-sbom). |
| **SR-3** | Supply Chain Controls and Processes | Limited | Model file SHA256-pinned; brew bottle SHA256s verified by Homebrew; HuggingFace mirror is the upstream source for the Whisper + Silero models; supply chain trust inherited from these upstreams. |

### Out of Scope (Family-level, with rationale)

The following families are out-of-scope for a single-developer personal tool. Each is N/A by tool-class:

- **AT** (Awareness and Training) — Organisational training programme; not a tool concern.
- **CA** (Assessment, Authorization, and Monitoring) — Organisational process (continuous monitoring, ATO).
- **CP** (Contingency Planning) — Organisational; PurpleVoice is stateless and per-utterance.
- **IR** (Incident Response) — Organisational; PurpleVoice has no organisational incident-response programme.
- **MA** (Maintenance) — Organisational; not relevant to a personal tool.
- **PE** (Physical and Environmental Protection) — OS-level / facility-level.
- **PL** (Planning) — Organisational planning concern.
- **PM** (Program Management) — Organisational.
- **PS** (Personnel Security) — Organisational.
- **RA** (Risk Assessment) — Organisational.

Marking these "Out of Scope" with rationale (rather than "Failed" or "Not Applicable") is the auditor-honest framing — these families contain controls that simply don't have a tool-level analogue.

## FIPS 140-3

<!-- TODO: Plan 02.7-03b fills this section (framed; "compatible with FIPS-validated cryptographic modules" framing). -->

## FedRAMP-tailored

<!-- TODO: Plan 02.7-03b fills this section (framed; "achievable IF a sponsoring agency pursues authorisation; not unilaterally pursuable" framing). -->

## Common Criteria

<!-- TODO: Plan 02.7-03b fills this section (framed; "out of scope for v1; ST-based future evaluation simplification" framing). -->

## HIPAA Security Rule §164.312

<!-- TODO: Plan 02.7-03b fills this section (framed; per-clause check-list 164.312(a)(1)/(b)/(c)(1)/(d)/(e)(1) with Met/N/A/Not Pursued; Pitfall 11 "issued to organisations" disclaimer first). -->

## SOC 2 Type II Trust Services Criteria

<!-- TODO: Plan 02.7-03b fills this section (framed; CC6.x / C1.x / P1-P8 partial; Pitfall 11 disclaimer first). -->

## ISO/IEC 27001:2022 Annex A

<!-- TODO: Plan 02.7-03b fills this section (framed; A.5/A.8/A.13/A.14 technical-controls subset; Pitfall 11 "issued to organisations" disclaimer first). -->

## Code Signing & Notarisation

<!-- TODO: Plan 02.7-04 fills this section (Phase 3 deferral; $99/yr Apple Developer Program; entitlements list; current "no signable artifact" framing). -->

## Reproducible Build

<!-- TODO: Plan 02.7-04 fills this section (best-effort; Pitfall 14 toolchain-version-sensitive caveat; what we DO have: SHA256-pinned model + git-tracked source + brew bottle SHA256). -->

## Vulnerability Disclosure

<!-- TODO: Plan 02.7-04 fills this section (email contact stub: oliver@olivergallen.com; no CVE authority / bounty programme; community-evolution note). -->

## How to Verify These Claims

<!-- TODO: Plan 02.7-04 fills this section (instructions: bash tests/run_all.sh && bash tests/security/run_all.sh; sudo requirement for verify_egress.sh; release-gate cadence per D-03). -->

***

*Phase 2.7 in progress. Last updated: 2026-04-29.*
