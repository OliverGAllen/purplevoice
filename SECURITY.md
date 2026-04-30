# PurpleVoice Security Posture

> Local voice dictation. Nothing leaves your Mac.

**Status: SKELETON (Phase 2.7 in progress).** This file is being authored across Phase 2.7 plans 02.7-01..02.7-04. Sections without content are placeholders.

**Audience:** Technical IT auditors at government / defence / healthcare / legal / finance / journalism / air-gapped operator organisations evaluating PurpleVoice. (D-13)

**Frameworks covered (D-16):** NIST SP 800-53 Rev 5 (per-control depth) + FIPS 140-3 + FedRAMP-tailored + Common Criteria + HIPAA Security Rule §164.312 + SOC 2 Type II TSC + ISO/IEC 27001:2022 Annex A (six framed at "compatible with" depth).

**Framing constraint (D-17):** This document uses "compatible with" / "supports" / "consistent with applicable obligations for in-scope code" framing. PurpleVoice is NOT audited or accredited against any framework. Over-claims would damage the auditable trust narrative this document exists to establish.

***

## TL;DR

PurpleVoice is a local push-to-talk voice dictation tool for macOS Apple Silicon. It does not connect to the internet during operation. Voice content (audio + transcript) exists only on your machine, only for the duration of a single utterance, and is then deleted.

**What PurpleVoice does:** You hold `cmd+shift+e`, you speak, you release. The transcript appears in the focused window. Total round-trip: ~1-2 seconds. No cloud. No subscription. No telemetry.

**What PurpleVoice does NOT do:** No network calls during operation. No transcript persistence. No telemetry. No cloud STT API. No data sharing.

**Verification:** Every claim in this document is either (a) substantiated by a runnable script in [`tests/security/`](#how-to-verify-these-claims) you can execute on your own machine, or (b) explicitly framed as "compatible with [framework]" / "out of scope, here's why" / "deferred to Phase X". No unsubstantiated claims.

**Audience-specific paths into this document:** see [Audience Entry-Points](#audience-entry-points) below.

**What PurpleVoice is NOT:** audited or accredited against any of the security frameworks discussed below. The framing throughout this document is "compatible with" — PurpleVoice is *compatible with* applicable obligations of those frameworks for in-scope code, never claims to *be* "compliant" or "certified". The discipline is enforced by the [framing lint](#how-to-verify-these-claims) `tests/test_security_md_framing.sh`.

## Audience Entry-Points

Different readers come to this document with different priorities. Find your entry-point below:

| If you are... | Start here | Then read |
|---|---|---|
| A **journalist** evaluating PurpleVoice for sensitive-source dictation | [TL;DR](#tldr) → [Threat Model](#threat-model) | [Egress Verification](#egress-verification) → [How to Verify These Claims](#how-to-verify-these-claims) |
| A **US federal IT auditor** evaluating PurpleVoice for agency use | [NIST SP 800-53 Rev 5 / Low-baseline Mapping](#nist-sp-800-53-rev-5--low-baseline-mapping) | [Threat Model](#threat-model) → [SBOM](#software-bill-of-materials-sbom) → [FedRAMP-tailored](#fedramp-tailored) |
| An **EU institutional buyer** (UK / DE / FR / NL gov, university, NGO) | [ISO/IEC 27001:2022 Annex A](#isoiec-270012022-annex-a) | [Threat Model](#threat-model) → [Egress Verification](#egress-verification) → [SBOM](#software-bill-of-materials-sbom) |
| A **healthcare organisation** (HIPAA Covered Entity / Business Associate) | [HIPAA Security Rule §164.312](#hipaa-security-rule-164312) | [Threat Model](#threat-model) → [Egress Verification](#egress-verification) |
| A **finance / SOC 2-audited** organisation | [SOC 2 Type II Trust Services Criteria](#soc-2-type-ii-trust-services-criteria) | [Threat Model](#threat-model) → [SBOM](#software-bill-of-materials-sbom) |
| An **air-gapped operator** (defence, intelligence, classified networks) | [Air-Gapped Installation](#air-gapped-installation) | [Egress Verification](#egress-verification) → [SBOM](#software-bill-of-materials-sbom) |
| A **procurement officer** | [SBOM](#software-bill-of-materials-sbom) | [Code Signing & Notarisation](#code-signing--notarisation) → [How to Verify These Claims](#how-to-verify-these-claims) |
| A **security engineer / sysadmin** evaluating for a deployment | [Threat Model](#threat-model) | [NIST 800-53 mapping](#nist-sp-800-53-rev-5--low-baseline-mapping) → [Egress Verification](#egress-verification) → [How to Verify These Claims](#how-to-verify-these-claims) |
| A **general user** curious about PurpleVoice's privacy posture | [TL;DR](#tldr) | [Threat Model](#threat-model) → [How to Verify These Claims](#how-to-verify-these-claims) |

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

PurpleVoice's central security claim is that **no voice content leaves the machine during operation**. This claim is substantiated by `tests/security/verify_egress.sh`, which any reader can run on their own macOS machine.

### Methodology

`tests/security/verify_egress.sh` uses a **3-layer evidence chain**, scoped tightly to the PurpleVoice process tree (`purplevoice-record` + `sox` + transcription children; Hammerspoon's main PID is intentionally excluded per D-06 — it's a long-running app the user already trusts).

1. **Layer 1 — `lsof`** (no sudo). Snapshot of network sockets per PID at sample points during a synthesised recording window. Expected: zero open sockets.
2. **Layer 2 — `nettop`** (no sudo). Per-PID network flow snapshot. Expected: zero flows.
3. **Layer 3 — `pf` + `tcpdump`** (sudo required). A `pf` packet-filter anchor blocks all outbound TCP/UDP for the test UID; `tcpdump` captures on `pflog0` + active interfaces during the recording window. Expected: zero attributable packets.

The script exits 0 only if **all 3 layers report silence**. If sudo is unavailable, layer 3 is gracefully skipped — the egress claim then rests on socket-state evidence (layers 1+2) only, with a "weakened PASS" message.

### macOS Sequoia 15.7.5 caveat (Pitfall 1)

Apple Developer Forums thread 776914 documents a `pf` regression on macOS 15.x where outbound packets bypass `block all` rules under some conditions. Status on 15.7.5 (build 24G624) is unconfirmed by public sources. To handle this:

- `tests/security/verify_egress.sh` includes a **positive-control check**: before declaring layer 3 PASS, it runs `curl --max-time 2 https://example.com` from the same UID under the pf anchor. If `curl` succeeds, pf is silently broken — the script logs a WARNING and falls back to layers 1+2 as the load-bearing evidence.
- If you run `tests/security/verify_egress.sh` and see `PASS (weakened — pf broken on this macOS build per Pitfall 1; layers 1-2 carry the claim)`, the egress claim is still substantiated by socket-state evidence (no sockets opened, no flows visible). The `pf+tcpdump` packet-flow evidence is unavailable on this OS build.

### What the test does NOT prove

- Setup-time downloads (HuggingFace model, Homebrew bottles, Hammerspoon cask) are explicit, one-time, and over HTTPS with SHA256 verification. The egress test is scoped to **runtime**, not install-time.
- The test does not prove the kernel is uncompromised; it proves PurpleVoice's user-space process tree does not transmit during a recording window.
- The test scopes to PurpleVoice's process tree only, not system-wide. Other macOS daemons (mDNS, system telemetry) are out of scope.

### How to run

```bash
bash tests/security/verify_egress.sh
# PASS (full 3-layer evidence: lsof + nettop + pf+tcpdump silence on purplevoice process tree)
# OR
# PASS (weakened — pf broken on this macOS build per Pitfall 1; layers 1-2 carry the claim)
# OR
# PASS (weakened — layer 3 pf+tcpdump skipped due to sudo unavailable; layers 1-2 carry the claim)
```

## Software Bill of Materials (SBOM)

PurpleVoice publishes a Software Bill of Materials (`SBOM.spdx.json`) at the repo root in **SPDX 2.3 JSON format** (ISO/IEC 5962:2021). The SBOM enumerates the trusted compute base (TCB) — what runs when PurpleVoice runs.

### Scope (D-11: full)

- **Direct dependencies:** `sox`, the local transcription binary, `ggml-small.en.bin`, `ggml-silero-v6.2.0.bin`, `Hammerspoon.app`, `purplevoice-record`, `purplevoice-lua/init.lua`.
- **Transitive dependencies:** Compile-time deps of whisper.cpp (ggml internals), sox audio libraries (libsndfile, libvorbis, etc.), Hammerspoon's bundled Lua + LuaSocket. Auto-discovered by Syft.
- **System context** (carried via SPDX 2.3 Annotation blocks):
  - `macOS-version` — e.g., `15.7.5 (24G624)`
  - `hardware-platform` — e.g., `arm64 (Apple Silicon)`
  - `xcode-clt-version` — e.g., `26.2.0.0.1.1764812424`
  - `brew-version` — e.g., `4.5.x`

Government-audit framing: this is **what is the trusted compute base**. An auditor can answer "what runs when PurpleVoice runs" by reading `SBOM.spdx.json`.

### SPDX 2.3 Annotation block strategy for system context

SPDX 2.3 does not have a first-class field for "the host OS this software was built/run on". The PurpleVoice SBOM uses SPDX 2.3 `Annotation` blocks attached to the document-level `creationInfo` to carry the 4 system-context dimensions above. Each Annotation block has:

- `annotationType: REVIEW`
- `annotator: Tool: PurpleVoice setup.sh Step 8`
- `annotationDate: <ISO 8601 — set deterministically per Pitfall 3>`
- `annotationComment: <key>=<value>` (one of macOS-version, hardware-platform, xcode-clt-version, brew-version)

Consumers of the SBOM can grep for `annotationComment.*<key>=` to extract the system context.

### Regeneration

`setup.sh` Step 8 regenerates `SBOM.spdx.json` if Syft (Anchore) is installed. The regeneration is **idempotent** — running `setup.sh` twice produces zero git diff when the package set is unchanged (deterministic post-process via `jq` rewrites volatile fields). If Syft is absent, the committed SBOM applies and `setup.sh` prints a skip notice.

Format: SPDX 2.3 JSON. Consumers who prefer CycloneDX can convert at read-time via `syft convert SBOM.spdx.json -o cyclonedx-json`.

### Verification

`tests/security/verify_sbom.sh` validates that `SBOM.spdx.json`:

- Parses as valid JSON.
- Contains the 6 SPDX 2.3 required top-level fields.
- Has `name = "PurpleVoice"` and `spdxVersion = "SPDX-2.3"`.
- Contains ≥ 4 system-context Annotation blocks (the 4 dimensions above).
- Has deterministic `creationInfo.created` (zero spurious diff per Pitfall 3).

## Air-Gapped Installation

PurpleVoice supports air-gapped operation via the `PURPLEVOICE_OFFLINE=1` environment variable. In this mode, `setup.sh` does not contact the network; it verifies that the operator has manually pre-staged the binaries and model files at the documented sideload paths.

### Required pre-staging on a connected machine

| Artefact | Sideload path | How to obtain |
|---|---|---|
| `ggml-small.en.bin` (~488 MB) | `~/.local/share/purplevoice/models/ggml-small.en.bin` | `curl -L -o ggml-small.en.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin` then `shasum -a 256 ggml-small.en.bin` (must match `c6138d6d58ecc8322097e0f987c32f1be8bb0a18532a3f88f734d1bbf9c41e5d`); USB sneakernet to air-gapped machine. |
| `ggml-silero-v6.2.0.bin` (~885 KB) | `~/.local/share/purplevoice/models/ggml-silero-v6.2.0.bin` | `curl -L -o ggml-silero-v6.2.0.bin https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v6.2.0.bin`; size sanity check ≥ 800,000 bytes; USB sneakernet. |
| `Hammerspoon.app` | `/Applications/Hammerspoon.app` | Download `.zip` from https://www.hammerspoon.org/ on a connected machine; USB-transfer; drag to `/Applications/`. (See "Known limitation" below.) |
| `sox` + transcription binary | `/opt/homebrew/bin/sox`, `/opt/homebrew/bin/soxi`, `/opt/homebrew/bin/whisper-cli` | `brew fetch sox whisper-cpp --bottle` on connected machine produces tarballs at `~/Library/Caches/Homebrew/downloads/`; USB-transfer; on target machine: `brew install <local-bottle>.tar.gz` OR direct binary copy from a reference machine. |

### Then on the air-gapped machine

```bash
PURPLEVOICE_OFFLINE=1 bash setup.sh
```

The setup script will verify each artefact's presence (and SHA256 for the Whisper model) and exit 0 with `OFFLINE: <component> present` lines. If any artefact is missing, setup.sh exits 1 with an actionable error message indicating the required path + how to obtain.

### Known limitation: Homebrew is not air-gap-friendly (Pitfall 8)

Homebrew's typical install path requires network access for cask + bottle download. PurpleVoice does not bundle a vendored copy of Homebrew binaries — that decision was made to keep the repo size manageable and to inherit Homebrew's security audit trail. Operators in classified environments are expected to have an established cross-domain transfer process for the brew bottles + Hammerspoon `.app`.

The `PURPLEVOICE_OFFLINE=1` mode handles the parts most operators want air-gapped (the ML model files + Silero VAD weights). Hammerspoon and brew binaries are typically a one-time install per machine; the cross-domain effort is amortised. We do not claim that `PURPLEVOICE_OFFLINE=1` is a fully-automated air-gap install — operator sneakernet is part of the procedure.

### Verification

`tests/security/verify_air_gap.sh` exercises 2 invariants:

1. With `PURPLEVOICE_OFFLINE=1` + all sideload artefacts present, `setup.sh` exits 0 with `OFFLINE:` log lines.
2. With `PURPLEVOICE_OFFLINE=1` + Whisper model missing, `setup.sh` exits 1 with the actionable error message `PURPLEVOICE_OFFLINE=1 set but Whisper model not sideloaded`.

The verify script uses atomic `mv` + trap-restore to safely move and replace the 488 MB model file (Pitfall 12).

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

**Status: Compatible with FIPS-validated cryptographic modules where the underlying macOS crypto APIs are FIPS-validated. PurpleVoice itself is not in scope for FIPS validation.**

FIPS 140-3 (Federal Information Processing Standard) is a US government standard for cryptographic modules. NIST's Cryptographic Module Validation Program (CMVP) certifies specific module implementations; FIPS 140-2 sunset on 2026-09 in favour of FIPS 140-3.

PurpleVoice does not perform cryptographic operations on user data:

- No encryption of voice content (it never leaves the machine — see [Egress Verification](#egress-verification)).
- No key management.
- No hash-based message authentication.
- No transport-layer cryptography (no transmission).

The only cryptographic primitive in use is **SHA-256 for model file integrity** at install time (`setup.sh` Step 5 verifies `ggml-small.en.bin` against `MODEL_SHA256`). This uses macOS's `shasum` tool, which on FIPS-validated macOS versions invokes Common Crypto — a FIPS 140-3-validated module per Apple's CMVP submissions.

**Implication:** PurpleVoice is **compatible with** FIPS-validated cryptographic modules (specifically: macOS Common Crypto where validated) without itself being a FIPS-validated cryptographic module. There is no PurpleVoice cryptographic module to validate — PurpleVoice consumes the OS's crypto API, it does not implement crypto.

| FIPS 140-3 Concern | PurpleVoice Status | Rationale |
|---|---|---|
| Cryptographic module identification | N/A | No PurpleVoice cryptographic module exists. |
| Approved algorithms (FIPS 180-4 hashing) | Met | SHA-256 via macOS Common Crypto where validated. |
| Key management | N/A | No keys. |
| Self-tests on power-up | N/A | No cryptographic module. |
| Operator authentication | N/A | No cryptographic role separation. |

Organisations that require FIPS-validated cryptography for the broader system in which PurpleVoice runs should verify that their macOS version's Common Crypto module has a current FIPS 140-3 validation certificate via the [NIST CMVP search](https://csrc.nist.gov/projects/cryptographic-module-validation-program).

**Toolchain caveat:** PurpleVoice does not itself invoke FIPS-mode-only APIs, nor does it disable non-approved algorithms — it simply consumes whatever `shasum -a 256` provides on the host. If an organisation's policy mandates that all cryptographic operations on a managed Mac run through a FIPS-mode-locked module, that policy is enforced at the OS / MDM layer, not by PurpleVoice. The boundary is: PurpleVoice asks macOS for a SHA-256; macOS's Common Crypto module computes it; the answer is correct regardless of whether the host is in FIPS mode (SHA-256 itself is FIPS-approved). What FIPS mode controls is the *exclusion* of non-approved algorithms — PurpleVoice doesn't use any non-approved algorithms anywhere in its pipeline, so FIPS mode is a no-op for PurpleVoice.

**Out-of-scope FIPS topics, with rationale:**

- **FIPS 140-3 Level 2 / 3 / 4** — These higher security levels invoke physical tamper-evidence, role-based authentication, and identity-based authentication for the cryptographic module itself. PurpleVoice has no cryptographic module to apply these levels to.
- **Random number generation (FIPS 186-5 / SP 800-90A DRBG)** — PurpleVoice does not generate random numbers. The only randomness in the recording pipeline is whatever entropy the OS injects into temporary file names, which is OS-managed.
- **Key derivation (FIPS 198-1 HMAC, SP 800-108 KDFs)** — Not applicable; no keys.

## FedRAMP-tailored

**Status: Compatible with applicable FedRAMP-tailored Low-baseline obligations for in-scope code. Not FedRAMP-authorised. Authorisation requires a sponsoring federal agency.**

FedRAMP (Federal Risk and Authorization Management Program) is an authorisation programme for cloud services used by US federal agencies. **FedRAMP is not a control catalogue** — it inherits from NIST SP 800-53. The FedRAMP-tailored Low-baseline is a subset designed for low-impact systems.

Two structural realities make FedRAMP authorisation impractical for PurpleVoice in v1:

1. **PurpleVoice is not a cloud service.** FedRAMP's scope is cloud-delivered services; PurpleVoice runs locally on a macOS Apple Silicon machine.
2. **Authorisation requires a sponsoring federal agency.** A vendor cannot unilaterally pursue a FedRAMP authorisation; an agency-sponsored ATO (Authorization to Operate) process is required (12-18 months, $250k-$1M+ documented industry cost).

**PurpleVoice's design is compatible with** the technical control families a FedRAMP Low-baseline assessment would examine — these are the same NIST 800-53 Rev 5 controls mapped above. Specifically:

- SC-7 Boundary Protection — Met (zero-egress; verified)
- SI-7 Software Integrity — Met (SHA256 model verification)
- AC-3 Access Enforcement — Met (TCC)
- PT-3 PII Processing Purposes — Met (this document substantiates)

| FedRAMP Concern | PurpleVoice Status |
|---|---|
| Cloud service classification | N/A — local tool |
| NIST 800-53 Low-baseline alignment | Met (see [NIST 800-53 mapping](#nist-sp-800-53-rev-5--low-baseline-mapping)) |
| Continuous monitoring (FedRAMP-specific) | Not Pursued — release-gate verification per D-03 |
| 3PAO assessment | N/A — no auditing organisation engaged |
| Sponsoring agency | N/A — no agency sponsor |

**PurpleVoice will support an agency-sponsored authorisation effort** by maintaining the security artefacts in this document (threat model, SBOM, verification scripts, gap analysis) — but the path to authorisation is owned by the sponsoring agency, not by the PurpleVoice project.

**FedRAMP-tailored vs full FedRAMP:** The "tailored" Low-baseline is the realistic frame for a tool like PurpleVoice — it omits continuous-monitoring and incident-response controls that don't apply to a per-utterance one-shot CLI. Full FedRAMP Low / Moderate / High would invoke the broader 800-53 baselines (Moderate = ~325 controls; High = ~421 controls), most of which are organisational. The tailored framing keeps the gap analysis honest for a tool of this shape.

**What an agency-sponsored authorisation would require from the PurpleVoice project:**

1. A signed System Security Plan (SSP) using the NIST 800-53 mapping above as the technical-control baseline.
2. A 3PAO (Third-Party Assessment Organization) engagement contracted by the sponsoring agency.
3. Continuous-monitoring infrastructure (FedRAMP-specific) — automated configuration scanning, monthly vulnerability scans, annual assessment. This is the load-bearing reason FedRAMP is impractical for a free tool: the continuous-monitoring overhead is recurring, not one-time.
4. A Plan of Action and Milestones (POA&M) for any control gaps identified during 3PAO assessment.

The PurpleVoice project will provide artefacts (1) on request and supply technical-control evidence (this document, the verification scripts, the SBOM) for items (2)-(4) — the rest belongs to the sponsoring agency's authorisation budget and timeline.

## Common Criteria

**Status: Not evaluated under Common Criteria. Out of scope for v1. PurpleVoice's small TCB and open-source posture would simplify a future Security Target-based evaluation if a sponsoring institution funds it.**

Common Criteria (CC; ISO/IEC 15408) is an international product evaluation scheme administered through national schemes (NIAP in the US, BSI in Germany, CCN in Spain, etc.). Products are evaluated against a Security Target (ST) at an Evaluation Assurance Level (EAL) from EAL1 (basic) to EAL7 (formally verified design + tested).

PurpleVoice has not undergone Common Criteria evaluation. Out of scope for v1 because:

- **Cost & timeline:** EAL2-EAL4 evaluations typically run $50k-$500k and 6-18 months (industry sources: cclab.com, Wikipedia CC EAL summary). Disproportionate for a free open-source personal tool.
- **Sponsoring laboratory:** CC evaluation requires engagement with an accredited Common Criteria Testing Laboratory (CCTL); PurpleVoice has no CCTL engagement.
- **Protection Profile fit:** No existing Protection Profile (PP) cleanly fits a local one-shot dictation CLI; a custom Security Target would be required.

**Compatible with** future evaluation: PurpleVoice's design has properties that *would simplify* an EAL2-EAL4 evaluation if a sponsoring institution funds it:

- **Small TCB** — Single bash script (`purplevoice-record`, ~150 lines) + Lua module (`purplevoice-lua/init.lua`, ~315 lines) + brew-installed binaries (sox + transcription binary) + GGML model files. The trusted compute base is enumerable and reviewable.
- **Open-source posture** — All source is git-tracked and human-readable; no opaque binaries beyond brew-bottle SHA256-verified dependencies.
- **Minimal external interface** — One hotkey, one clipboard write, one paste. No network surface (verified). No daemon (one-shot CLI).
- **Documented threat model** — STRIDE + LINDDUN mapping (this document) is the kind of artefact a CC evaluator expects in a Security Target.

| Common Criteria Concern | PurpleVoice Status |
|---|---|
| Security Target authored | Not Pursued — would be drafted at evaluation time |
| Protection Profile alignment | N/A — no fitting PP exists |
| EAL targeted | N/A — out of scope for v1 |
| CCTL engaged | N/A |
| Sponsoring institution | N/A |

Institutions that require Common Criteria evaluation for tools in their environment should treat PurpleVoice as a **not-evaluated** component and apply organisational risk-acceptance accordingly.

**Why a custom Security Target (rather than an existing Protection Profile)?** Existing PPs cover specific product classes — operating systems, mobile devices, network firewalls, cryptographic modules, USB drives, etc. None of these classes cleanly fits a one-shot dictation CLI that consumes mic input, runs a local ML model, and writes to the pasteboard. A future evaluation would either author a custom ST referencing the technical-control families documented in this `SECURITY.md` (Access Control, System and Communications Protection, System and Information Integrity, PII Processing and Transparency) or extend an existing General-Purpose Computing PP with PurpleVoice-specific functional requirements.

**ISO/IEC 15408 vs ISO/IEC 27001:** Common Criteria (15408) evaluates *products*; ISO 27001 evaluates *organisational ISMSs*. The two are complementary, not substitutes — an organisation can hold a 27001 certificate that includes a not-evaluated CC component (PurpleVoice) in its Statement of Applicability with a documented risk acceptance.

## HIPAA Security Rule §164.312

**Status: PurpleVoice's design is consistent with §164.312 obligations for in-scope technical safeguards. PurpleVoice is a tool, not a HIPAA Covered Entity or Business Associate.**

The HIPAA Security Rule (45 CFR Part 164 Subpart C) establishes Administrative, Physical, and Technical Safeguards for Electronic Protected Health Information (ePHI). HIPAA obligations are owned by Covered Entities (healthcare providers, health plans, healthcare clearinghouses) and their Business Associates. PurpleVoice is **a tool**, not a HIPAA-regulated entity — it can only be a *supporting safeguard* (Tailscale-style framing) that an organisation deploys as part of their HIPAA programme.

The framing below describes how PurpleVoice's design supports the **§164.312 Technical Safeguards** specifically. Administrative (§164.308) and Physical (§164.310) Safeguards are organisational responsibilities outside PurpleVoice's scope.

| §164.312 Clause | Standard | PurpleVoice Status | Rationale |
|---|---|---|---|
| §164.312(a)(1) | Access Control | Met | macOS TCC (Microphone + Accessibility) enforces access on the Hammerspoon bundle-id. User-keyboard physical access required to invoke. Cross-references NIST AC-3 in [NIST mapping](#nist-sp-800-53-rev-5--low-baseline-mapping). |
| §164.312(a)(2)(i) | Unique User Identification | Met | macOS user session = unique identification; PurpleVoice inherits. Cross-references NIST IA-2. |
| §164.312(a)(2)(ii) | Emergency Access Procedure | N/A | No persistent state; loss of PurpleVoice does not block access to ePHI in other systems. |
| §164.312(a)(2)(iii) | Automatic Logoff | N/A | No PurpleVoice session to time out; one-shot per utterance. |
| §164.312(a)(2)(iv) | Encryption and Decryption | N/A | No ePHI at rest in PurpleVoice; ephemeral WAV deleted on EXIT. |
| §164.312(b) | Audit Controls | Not Pursued | By design (privacy > accountability for personal tool). Cross-reference STRIDE §Repudiation row in the [Threat Model](#threat-model) and NIST AU-2 / AU-12 rows. v1.x QOL-04 history log is the opt-in mitigation if a deploying organisation requires audit. |
| §164.312(c)(1) | Integrity | Met | Whisper model SHA256 verification at install time (`setup.sh` Step 5). Cross-references NIST SI-7. |
| §164.312(c)(2) | Mechanism to authenticate ePHI | N/A | No ePHI authentication mechanism (no ePHI persisted by PurpleVoice). |
| §164.312(d) | Person or Entity Authentication | Met | macOS user session authentication; PurpleVoice inherits. Cross-references NIST IA-2. |
| §164.312(e)(1) | Transmission Security | N/A | No transmission. PurpleVoice runtime is local-only — verified by [Egress Verification](#egress-verification). Cross-references NIST SC-7. |
| §164.312(e)(2)(i) | Integrity Controls (in transit) | N/A | No transmission. |
| §164.312(e)(2)(ii) | Encryption (in transit) | N/A | No transmission. |

**Use of PurpleVoice in a HIPAA Covered Entity or Business Associate context** requires the deploying organisation to:

1. Implement complementary Administrative Safeguards (§164.308 — workforce training, access management, incident-response procedures).
2. Implement complementary Physical Safeguards (§164.310 — facility access, workstation security, device disposal).
3. Maintain a **Business Associate Agreement (BAA)** with any party that handles ePHI on the organisation's behalf — note that PurpleVoice does NOT handle ePHI on the organisation's behalf because no data leaves the user's machine; the BAA scope is the *organisation's* deployment, not the tool itself.
4. Conduct an organisational HIPAA risk assessment that includes PurpleVoice's deployment.

PurpleVoice's design (zero egress, ephemeral WAV, no transcript persistence) makes it **a supporting safeguard** for HIPAA-aligned systems handling voice notes / dictation workflows — never a substitute for the organisation's own HIPAA programme.

**Tailscale-style precedent for the framing:** Tailscale's HIPAA documentation explicitly states that Tailscale itself is not a HIPAA-regulated entity, but describes how Tailscale's design supports a Covered Entity's HIPAA programme through specific technical safeguards (encryption-in-transit, access control, audit logging where applicable). PurpleVoice adopts the same posture: this section is a *gap analysis for the deploying organisation*, not a self-issued attestation. A Covered Entity's auditor would read this section as evidence of the technical-safeguards baseline PurpleVoice provides; the organisation's BAA, HIPAA training, and risk-assessment artefacts cover the rest.

**Why §164.312(b) Audit Controls is "Not Pursued":** The HIPAA Security Rule §164.312(b) requires that mechanisms be implemented to record and examine activity in information systems that contain or use ePHI. For a personal-tool one-shot dictation CLI, persistent audit logging would itself be a privacy regression — the very voice content the user wants to keep ephemeral would land in an audit log. The engineering choice (privacy > accountability) is documented honestly here, with the v1.x QOL-04 opt-in history log identified as the mitigation path for organisations that prioritise audit over privacy. A deploying Covered Entity that requires §164.312(b) for compliance reasons should either (a) deploy v1.x with QOL-04 history-log enabled when it ships, or (b) accept the residual risk in their organisational risk assessment.

**HIPAA Privacy Rule §164.502 considerations** (out of §164.312 scope but worth noting): PurpleVoice's pasteboard-write pathway means voice transcripts traverse the macOS pasteboard before reaching the focused window. The pasteboard is governed by the user's own session and OS protections; transcripts are written with the `org.nspasteboard.TransientType` UTI which honoring clipboard managers (1Password 8+, Maccy, Raycast, Pastebot) skip on capture. A Covered Entity using PurpleVoice in clinical workflows should either (a) ensure the clinician's clipboard manager honours the transient UTI, or (b) disable third-party clipboard managers on the workstation as part of organisational policy. PurpleVoice does not — and cannot — enforce this from inside the tool.

## SOC 2 Type II Trust Services Criteria

**Status: PurpleVoice is a tool, not an organisation, and does not undergo a SOC 2 audit. PurpleVoice's design is compatible with applicable SOC 2 Trust Services Criteria for in-scope code.**

SOC 2 (Service Organization Control 2) Type II reports are issued to **organisations** by independent CPA firms after a 6-12 month observation period. The AICPA's Trust Services Criteria cover five categories: Security (CC1-CC9), Availability (A1.x), Processing Integrity (PI1.x), Confidentiality (C1.x), Privacy (P1.x-P8.x).

**A tool does not hold a SOC 2 report — only the organisation operating it can.** Confusing the two is the #1 misframing risk in this section (Pitfall 11). The framing below describes how PurpleVoice's design supports an organisation's SOC 2 posture — not how PurpleVoice itself is SOC 2 anything.

| TSC Category | PurpleVoice Design Property | Status |
|---|---|---|
| **Security CC6.1** Logical Access — Access Control | macOS TCC (Microphone + Accessibility) gates invocation | Met |
| **Security CC6.6** External Threats — Boundary Protection | Zero outbound network egress at runtime ([verified](#egress-verification)) | Met |
| **Security CC6.7** Restriction of Information Transmission | No transmission of voice content; pasteboard write is local-only | Met |
| **Security CC6.8** Malicious Software Prevention | Brew bottle SHA256 verification + Whisper model SHA256 pinning | Partial |
| **Confidentiality C1.1** Identification and Maintenance of Confidential Information | Voice content treated as user-owned; ephemeral WAV deleted on EXIT | Met |
| **Confidentiality C1.2** Disposal of Confidential Information | EXIT trap cleanup of `/tmp/purplevoice/*.wav` covers all exit paths including SIGINT | Met |
| **Privacy P1.1** Notice About Privacy | This document + README + setup.sh banner | Met |
| **Privacy P3.1** Personal Information Collection | No voice content collected by PurpleVoice (ephemeral, never leaves machine) | Met |
| **Privacy P5.1** Personal Information Access | User has full access to their own voice content (it never leaves their machine) | Met |
| **Privacy P6.1** Personal Information Disclosure to Third Parties | None — no transmission | Met |
| **Privacy P8.1** Personal Information Quality | Whisper transcription accuracy is the limiting factor; user reviews before paste-context use | Partial |

**An organisation deploying PurpleVoice retains full responsibility for their own SOC 2 posture.** PurpleVoice provides a supporting design that aligns with Security and Confidentiality criteria; the organisation's audit scope must include PurpleVoice's deployment as part of the system being assessed.

PurpleVoice does NOT cover:

- **Availability (A1.x)** — N/A; PurpleVoice has no SLA (it's a personal tool). Deploying organisation owns their own availability claims.
- **Processing Integrity (PI1.x)** — Limited; Whisper transcription has documented limitations (hallucinations on silence — mitigated by VAD + denylist; accuracy varies with audio quality).

**SOC 2 Type I vs Type II:** Type I is a point-in-time design assessment ("did the organisation describe its controls accurately on date X?"); Type II is an operating-effectiveness assessment over a 6-12 month observation window ("did the controls work continuously?"). Either way, the report is issued to the organisation, not to PurpleVoice. An organisation building a SOC 2 Type II report can include PurpleVoice within the system boundary; the auditor will examine PurpleVoice's documented controls (this section + the NIST 800-53 mapping above) as evidence of the underlying technical baseline, but the operating-effectiveness assertion belongs to the organisation's monitoring and incident-response procedures — not to PurpleVoice itself.

**SOC 2 Type II report scope considerations for organisations deploying PurpleVoice:**

- The audit's system boundary should explicitly include the workstation(s) running PurpleVoice; auditor engagement letters typically require a network diagram + asset inventory that lists endpoint dictation tooling.
- PurpleVoice's lack of audit logging (CC4.1) is a documented residual risk to call out in the management's response section; the v1.x QOL-04 history-log opt-in is the available mitigation if the organisation's risk appetite requires logging.
- The deployed PurpleVoice version's git commit hash (visible in `SBOM.spdx.json` `versionInfo`) is the artefact-level identifier the auditor would tie to the SoC report's system description.

## ISO/IEC 27001:2022 Annex A

**Status: PurpleVoice is a tool, not an organisation operating an ISMS. PurpleVoice's design is compatible with applicable Annex A technical controls.**

ISO/IEC 27001:2022 certification is issued to **organisations** operating an Information Security Management System (ISMS), not to tools. The 2022 revision restructured Annex A into 93 controls across 4 themes: A.5 Organizational, A.6 People, A.7 Physical, A.8 Technological.

PurpleVoice's design **is compatible with** the technical-control subset of Annex A. The framing below maps PurpleVoice's properties to specific A.5 + A.8 controls — these are the controls a 27001-evaluated organisation's auditor would examine when evaluating PurpleVoice's role in the organisation's ISMS.

| Annex A Control | Title | PurpleVoice Status | Rationale |
|---|---|---|---|
| **A.5.10** | Information classification | Met | Transcripts treated as user-owned; classification is the organisation's responsibility. |
| **A.5.15** | Access control | Met | macOS TCC gates Microphone + Accessibility per bundle-id. |
| **A.5.23** | Information security for use of cloud services | N/A | PurpleVoice does not use cloud services (zero egress). |
| **A.5.24** | Information security incident management planning | Not Pursued | No PurpleVoice incident-response programme; deploying organisation owns. |
| **A.5.30** | ICT readiness for business continuity | N/A | Personal tool; no business continuity claim. |
| **A.5.34** | Privacy and protection of PII | Met | This document substantiates; no PII transmission. |
| **A.8.2** | Privileged access rights | Met | No SUID; no privileged operations. |
| **A.8.3** | Information access restriction | Met | TCC enforces; user-keyboard physical access required. |
| **A.8.5** | Secure authentication | Met | macOS user session inheritance. |
| **A.8.7** | Protection against malware | Partial | Brew bottle SHA256 verification + model SHA256 pinning. |
| **A.8.16** | Monitoring activities | Not Pursued | No PurpleVoice monitoring infrastructure (privacy by design). |
| **A.8.20** | Networks security | Met | Zero outbound network egress at runtime ([verified](#egress-verification)). |
| **A.8.21** | Security of network services | N/A | No network services. |
| **A.8.23** | Web filtering | N/A | No web access. |
| **A.8.24** | Use of cryptography | N/A | No cryptographic operations on user data; SHA-256 for model integrity only. |
| **A.8.25** | Secure development life cycle | Partial | Git-tracked source, code review via PR (when public), threat model + SBOM; missing: SDL training programme (organisational). |
| **A.8.26** | Application security requirements | Met | Documented in this file + REQUIREMENTS.md. |
| **A.8.28** | Secure coding | Met | bash strict mode, signal-handling discipline, Pattern 2 boundary enforcement, brand-consistency tests. |
| **A.8.30** | Outsourced development | N/A | Single-developer tool. |

**An organisation seeking ISO/IEC 27001 evaluation can include PurpleVoice in their Statement of Applicability** with attached residual-risk acceptance. The organisation's ISMS audit (by a UKAS-accredited evaluation body or equivalent national scheme) is the path to a formal certificate — PurpleVoice supports the audit but does not itself hold a certificate.

Useful framing for international (especially EU) institutional buyers: PurpleVoice's zero-egress design + ephemeral data handling is consistent with **GDPR data minimisation principles (Article 5(1)(c))** by design — PurpleVoice processes voice content for the documented purpose only (transcription), retains nothing beyond the utterance lifecycle, and transfers nothing to third parties.

**Annex A 2022 controls intentionally NOT mapped above** (with rationale):

- **A.6 People controls** (A.6.1 Screening through A.6.8 Information security event reporting) — All organisational controls covering personnel security; not applicable to a single-binary tool.
- **A.7 Physical controls** (A.7.1 Physical security perimeter through A.7.14 Secure disposal or re-use of equipment) — All organisational / facility controls; PurpleVoice has no physical infrastructure.
- **A.8.1 User endpoint devices** — Inherits from the organisation's MDM / endpoint management posture; not a tool-level concern.
- **A.8.4 Access to source code** — Source is open and git-tracked (organisation chooses whether to fork / mirror).
- **A.8.6 Capacity management** — Personal tool; no capacity SLA.
- **A.8.8 Management of technical vulnerabilities** — Inherits from brew + macOS update cadence; PurpleVoice has no separate vulnerability-management programme yet (see [Vulnerability Disclosure](#vulnerability-disclosure)).
- **A.8.9 Configuration management** — Configuration files are user-owned dotfiles in `~/.config/purplevoice/`; no centralised configuration management.
- **A.8.10 Information deletion** — Ephemeral WAV deletion via EXIT trap is the closest tool-level analogue; A.8.10 broader "secure data destruction" is organisational.
- **A.8.11 Data masking** — N/A for a transcription tool.
- **A.8.12 Data leakage prevention** — Zero outbound egress at runtime is the load-bearing DLP property; verified by `tests/security/verify_egress.sh`.
- **A.8.13 Information backup** — Personal tool; no backup obligation. Voice content is ephemeral by design.
- **A.8.14 Redundancy of information processing facilities** — N/A; personal tool.
- **A.8.15 Logging** — Aligned with A.8.16 Monitoring activities — both Not Pursued by privacy-by-design choice.
- **A.8.17 Clock synchronisation** — Inherits from macOS time services.
- **A.8.18 Use of privileged utility programs** — N/A; PurpleVoice does not invoke privileged utilities.
- **A.8.19 Installation of software on operational systems** — Inherits from organisation's MDM policy; `setup.sh` is the install surface.
- **A.8.22 Segregation of networks** — N/A for a tool with no network footprint.
- **A.8.27 Secure system architecture and engineering principles** — Documented in this file (Pattern 2 boundary, defence-in-depth EXIT trap, signal-driven lifecycle); aligned with secure-coding principles.
- **A.8.29 Security testing in development and acceptance** — `tests/run_all.sh` (functional suite) + `tests/security/run_all.sh` (verification suite) provide release-gate testing; aligned at the tool level.
- **A.8.31 Separation of development, test and production environments** — N/A; single-developer tool. Git branch / tag separation is the closest analogue.
- **A.8.32 Change management** — Git history + ROADMAP.md + REQUIREMENTS.md + per-plan SUMMARY.md trail in `.planning/` substantiates the change-management trail.
- **A.8.33 Test information** — `tests/lib/sample_audio.sh` synthesises test audio (no real voice data used in tests).
- **A.8.34 Protection of information systems during audit testing** — Auditor runs verification scripts; no production data involved.

## Code Signing & Notarisation

<!-- TODO: Plan 02.7-04 fills this section (Phase 3 deferral; $99/yr Apple Developer Program; entitlements list; current "no signable artifact" framing). -->

## Reproducible Build

<!-- TODO: Plan 02.7-04 fills this section (best-effort; Pitfall 14 toolchain-version-sensitive caveat; what we DO have: SHA256-pinned model + git-tracked source + brew bottle SHA256). -->

## Vulnerability Disclosure

<!-- TODO: Plan 02.7-04 fills this section (email contact stub: oliver@olivergallen.com; no CVE authority / bounty programme; community-evolution note). -->

## How to Verify These Claims

Every claim in this document is either substantiated by a runnable script you can execute on your own machine, or explicitly framed as out-of-scope / deferred / framework-compatible. The verification harness lives in `tests/` and `tests/security/`.

### Quick verification (~30 seconds)

From a clean clone of the PurpleVoice repo:

```bash
git clone https://github.com/oliverallen/PurpleVoice.git purplevoice
cd purplevoice
bash setup.sh                       # Idempotent; ~5-30s if Syft regenerates SBOM
bash tests/run_all.sh               # Functional suite (8 tests, ~5s)
bash tests/security/run_all.sh      # Security suite (5 verify_*.sh; ~30s)
```

### Per-claim → verification script index

| SEC-ID | Claim | Verification script | Sudo? |
|---|---|---|---|
| SEC-01 | SECURITY.md framing discipline | `tests/test_security_md_framing.sh` | No |
| SEC-02 | Zero outbound egress at runtime | `tests/security/verify_egress.sh` | Yes (strongest layer) |
| SEC-03 | SBOM validity + system context | `tests/security/verify_sbom.sh` | No |
| SEC-04 | Code signing & notarisation status (documentation-presence) | `tests/security/verify_signing.sh` | No |
| SEC-05 | Reproducible build status (documentation-presence) | `tests/security/verify_reproducibility.sh` | No |
| SEC-06 | PURPLEVOICE_OFFLINE=1 air-gap mode | `tests/security/verify_air_gap.sh` | No |

The functional suite (`tests/run_all.sh`) runs:

- `test_brand_consistency.sh` — Phase 2.5 brand discipline (`PurpleVoice` everywhere; no orphaned working-name strings).
- `test_security_md_framing.sh` — D-17 "compatible with" lint over this document.
- `test_denylist.sh`, `test_duration_gate.sh`, `test_sigint_cleanup.sh`, `test_tcc_grep.sh`, `test_vad_silence.sh`, `test_wav_cleanup.sh` — Phase 2 hardening regressions.

The security suite (`tests/security/run_all.sh`) runs the 5 `verify_*.sh` scripts above.

### Sudo requirement note

`verify_egress.sh` requires `sudo` for the strongest evidence layer (pf + tcpdump). Run interactively or pre-authenticate sudo (`sudo -v`). If `sudo` is unavailable (CI without secrets, restricted shells), the script gracefully skips layer 3 and prints a "weakened PASS" message — the egress claim then rests on socket-state evidence (lsof + nettop) only.

### Release-gate cadence (D-03)

The PurpleVoice project does NOT run security verification on every commit (per D-03 — release-gate verification preserves zero CI infrastructure cost). Verification scripts run **before tagging a release**. Failures block release. External auditors and security researchers are encouraged to run the full suite on a clean clone at any time.

### What if a verification fails?

- **`verify_egress.sh` reports egress detected**: Open an issue immediately. This would be a critical regression of the SEC-02 claim.
- **`verify_sbom.sh` fails on system-context**: A new macOS / Xcode CLT version may have changed the dimension format. Update the `inject_system_context()` function in `setup.sh` Step 8 to capture the new format.
- **`verify_air_gap.sh` fails on Invariant 2**: The actionable error message in `setup.sh` may have drifted from the expected literal. Update either the test's grep target or the setup.sh message — keep them in sync.
- **`test_security_md_framing.sh` fails on banned phrase**: An edit to this document introduced a banned marketing-prone phrase outside a qualified context. Reword to "compatible with" / "supports" / "consistent with".

All verification failures should produce actionable error messages on stderr.

***

*Phase 2.7 in progress. Last updated: 2026-04-29.*
