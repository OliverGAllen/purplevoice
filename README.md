# PurpleVoice

**Local voice dictation. Nothing leaves your Mac.**

<p align="center">
  <img src="assets/icon-256.png" alt="PurpleVoice icon" width="128" height="128">
</p>

PurpleVoice is a push-to-talk voice input system for Claude Code (and any focused window) on macOS Apple Silicon. Hold a hotkey, speak, release — your transcript appears in the focused window in under 2 seconds. Every transcript is generated on-device by `whisper.cpp` using a local Whisper model. No accounts, no API keys, no telemetry, no opt-in cloud features.

## Who this is for

- **Privacy-conscious individuals** who don't want their voice — or its transcripts — leaving their machine
- **Government, defence, and intelligence personnel** whose data-handling policies prohibit cloud STT
- **Healthcare professionals** bound by HIPAA and equivalent privacy rules; **legal professionals** bound by attorney-client privilege
- **Finance and compliance roles** where voice content may include MNPI or regulated PII
- **Journalists** handling sensitive sources whose confidentiality is operational, not aspirational
- **Air-gapped or restricted-network operators** where cloud STT is technically impossible

[`SECURITY.md`](SECURITY.md) substantiates these claims with a threat model, framework gap analysis (NIST SP 800-53 + 6 framed frameworks: FIPS 140-3 / FedRAMP-tailored / Common Criteria / HIPAA / SOC 2 / ISO/IEC 27001), an auditable zero-egress verification methodology, an SBOM, and runnable verification scripts. See [Security & Privacy](#security--privacy) below.

## Status

- **Phase 1: Spike** — ✅ Complete (end-to-end loop validated on Apple Silicon)
- **Phase 2: Hardening** — ✅ Complete (TCC silent-deny detection, hallucination guards, clipboard preserve/restore, re-entrancy guard, failure notifications)
- **Phase 2.5: Branding** — ✅ Complete (this rebrand)
- **Phase 2.7: Security Posture** — ✅ Complete (SECURITY.md + SBOM.spdx.json + 5 runnable verify scripts)
- **Phase 3.5: Hover UI / HUD** — ⏳ Queued
- **Phase 4: Quality of Life** — ⏳ Queued
- **Phase 3: Distribution + Public Install** — ⏳ Queued (final v1 phase — installer + hyperfine benchmarks)

## Hotkey

`cmd+shift+e` (push-and-hold). Locked decision; see `.planning/phases/01-spike/01-CONTEXT.md` D-01.

(Known minor conflict: VS Code / Cursor "Show Explorer" sidebar — accepted.)

## Setup

```bash
bash setup.sh
```

`setup.sh` is idempotent — safe to re-run. It installs Homebrew dependencies (Hammerspoon, sox, whisper-cpp), creates the XDG directory layout (`~/.config/purplevoice/`, `~/.local/share/purplevoice/models/`, `~/.cache/purplevoice/`, `~/.local/bin/`, `~/.hammerspoon/purplevoice/`), downloads the Whisper `small.en` model with SHA256 verification, downloads the Silero VAD weights, seeds a default vocabulary file, and seeds the hallucination-denylist. If you're upgrading from the working name `voice-cc`, `setup.sh` migrates the old paths idempotently (only-old → mv; both → warn+skip; only-new → no-op).

After running `setup.sh`, paste the printed `require("purplevoice")` line into your `~/.hammerspoon/init.lua` and reload Hammerspoon.

## Permissions to grant manually after first Hammerspoon launch

- **Microphone** — System Settings → Privacy & Security → Microphone → enable Hammerspoon.app
- **Accessibility** — System Settings → Privacy & Security → Accessibility → enable Hammerspoon.app

Both are required for the press-to-talk loop. Hammerspoon will prompt for Microphone on first sox spawn; Accessibility is surfaced deterministically by `hs.accessibilityState(true)` on module load. If permission is denied, PurpleVoice fires an actionable macOS notification with a deep link to the relevant Privacy & Security pane (no silent failures — this was Phase 2's hardening contract).

## Conflicting macOS feature to disable

Disable the macOS Dictation hotkey to avoid conflicts:

- System Settings → Keyboard → Dictation → Shortcut → Off

## Recovery

If permissions get into a bad state, reset them:

```bash
tccutil reset Microphone org.hammerspoon.Hammerspoon
tccutil reset Accessibility org.hammerspoon.Hammerspoon
osascript -e 'tell application "Hammerspoon" to quit'
open -a Hammerspoon
```

Then re-grant when prompted.

## Security & Privacy

PurpleVoice is **auditable, verifiably-private dictation**. Voice content does not leave your machine during operation. The full security posture — threat model, framework gap analysis, runnable verification scripts — is documented in [`SECURITY.md`](SECURITY.md).

Audience-specific entry-points:

- **General readers / privacy-conscious users**: [SECURITY.md TL;DR](SECURITY.md#tldr)
- **Security engineers / sysadmins**: [SECURITY.md Threat Model](SECURITY.md#threat-model)
- **US federal IT auditors**: [SECURITY.md NIST 800-53 mapping](SECURITY.md#nist-sp-800-53-rev-5--low-baseline-mapping)
- **EU institutional buyers**: [SECURITY.md ISO/IEC 27001 framing](SECURITY.md#isoiec-270012022-annex-a)
- **Healthcare organisations**: [SECURITY.md HIPAA framing](SECURITY.md#hipaa-security-rule-164312)
- **Air-gapped operators**: [SECURITY.md Air-Gapped Installation](SECURITY.md#air-gapped-installation)

### Verifying the security claims

Run the verification suite from a clean clone:

```bash
bash tests/run_all.sh                       # Functional suite (~5s)
bash tests/security/run_all.sh              # Security suite (~30s)
```

The security suite verifies:

- **SEC-02 zero-egress** (`verify_egress.sh`) — 3-layer evidence chain: lsof + nettop + pf+tcpdump. **Requires `sudo`** for the strongest evidence layer (pf + tcpdump). Without sudo, lsof + nettop layers carry the claim with a "weakened PASS" message.
- **SEC-03 SBOM** (`verify_sbom.sh`) — `SBOM.spdx.json` validity + system-context annotations.
- **SEC-06 air-gap** (`verify_air_gap.sh`) — `PURPLEVOICE_OFFLINE=1` mode honoured.
- SEC-04 + SEC-05 documentation-presence stubs.

The framing lint (`tests/test_security_md_framing.sh`) enforces D-17 "compatible with" discipline across SECURITY.md edits — runs as part of `tests/run_all.sh` per commit.

### Air-gapped installation

PurpleVoice supports air-gapped operation. Set `PURPLEVOICE_OFFLINE=1` before running `setup.sh`:

```bash
PURPLEVOICE_OFFLINE=1 bash setup.sh
```

Required pre-staging on a connected machine (USB sneakernet to the air-gapped target):

1. Download `ggml-small.en.bin` (~488 MB) from `https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin`. Verify SHA256 = `c6138d6d58ecc8322097e0f987c32f1be8bb0a18532a3f88f734d1bbf9c41e5d`. Place at `~/.local/share/purplevoice/models/ggml-small.en.bin`.
2. Download `ggml-silero-v6.2.0.bin` (~885 KB) from `https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v6.2.0.bin`. Place at `~/.local/share/purplevoice/models/ggml-silero-v6.2.0.bin`.
3. Download Hammerspoon `.zip` from `https://www.hammerspoon.org/`; drag `Hammerspoon.app` to `/Applications/`.
4. Sneakernet `sox` + the transcription binary brew bottles (run `brew fetch sox whisper-cpp --bottle` on the connected machine; tarballs land at `~/Library/Caches/Homebrew/downloads/`).

The repo also publishes an SBOM at `SBOM.spdx.json` (SPDX 2.3 JSON) for procurement officers and auditors who need to enumerate the trusted compute base.

See [SECURITY.md Air-Gapped Installation](SECURITY.md#air-gapped-installation) for the full procedure with verification steps.

### Reporting a security issue

Email **oliver@olivergallen.com** with subject prefix `[PurpleVoice security]`. See [SECURITY.md Vulnerability Disclosure](SECURITY.md#vulnerability-disclosure).

### HUD privacy and screen-recording visibility

When recording, PurpleVoice shows a small lavender pill (`● Recording`) at the top-center of the active screen. The HUD complements the menubar indicator and disappears within ~250ms of releasing the hotkey. By default, no HUD is visible when idle.

**Visibility in screen recordings is limited.** PurpleVoice does not pursue `NSWindowSharingNone` exclusion in v1. Even if applied, Apple has stated that ScreenCaptureKit on macOS 15+ ignores window-level sharing flags ([Apple Developer Forums thread 792152, 2025](https://developer.apple.com/forums/thread/792152)) — modern capture tools (QuickTime, OBS, Zoom share-screen, Discord, Loom, Microsoft Teams) capture the HUD regardless. The legacy `screencapture` CLI and CGWindowList-based tools may still honour sharing flags, but this is incidental, not pursued.

**For sensitive sessions** (recorded demos, screen-shared meetings, journalist source-handling), run with `PURPLEVOICE_HUD_OFF=1` and rely on the menubar indicator alone — that is the only privacy guarantee. The Phase 2 menubar indicator is unaffected by HUD configuration.

Configuration:

| Env var | Effect | Default |
|---|---|---|
| `PURPLEVOICE_HUD_OFF=1` | Disable HUD entirely (menubar indicator unchanged) | unset (HUD enabled) |
| `PURPLEVOICE_HUD_POSITION` | One of: `top-center` (default) / `top-right` / `bottom-center` / `bottom-right` / `near-cursor` / `center` | `top-center` |

Both env vars are read once at module load — reload Hammerspoon (menubar → Reload Config) to apply changes. Note: changing an env var via `launchctl setenv` followed by `hs.reload()` does **not** propagate into Hammerspoon's existing `os.getenv` view (the process's `environ` array is exec-time-frozen). To apply env-var changes live, fully quit Hammerspoon and relaunch from a shell that already has the env var set, e.g. `PURPLEVOICE_HUD_POSITION=bottom-right open -a Hammerspoon`.

## Visual identity

Lavender (`#B388EB`) menubar indicator; the same lavender plus a white lips silhouette form the 256×256 icon at `assets/icon-256.png`. The icon's source SVG (`assets/icon.svg`) is committed for reproducibility — `assets/README.md` documents the regeneration command (`sips`).

## Project layout

```
purplevoice-record           # bash glue — sox capture + whisper-cli transcribe
purplevoice-lua/init.lua     # Hammerspoon module — hotkey + paste + notifications
setup.sh                     # idempotent installer + voice-cc → purplevoice migration
assets/
  icon.svg                   # source SVG (lavender + white lips)
  icon-256.png               # 256×256 PNG, sips-derived from icon.svg
  README.md                  # icon regeneration instructions
config/denylist.txt          # canonical Whisper-hallucination phrases (filtered out)
tests/                       # bash unit tests + manual walkthroughs
.planning/                   # GSD workflow artifacts (phase plans, requirements, state)
```

## Why "PurpleVoice"

The dictation tool space is crowded — Hush, Pip(it), Chirp, Magpie, Koe and others are all taken. PurpleVoice is a colour-noun compound that signals the brand visually (lavender + lips icon) without colliding with existing dictation products. The working name `voice-cc` survives in repo path, git history, and `.planning/` artifacts as historical record.
