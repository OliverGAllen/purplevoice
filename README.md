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

The forthcoming `SECURITY.md` (Phase 2.7) substantiates these claims with a threat model, an auditable zero-egress verification methodology, an SBOM, and gap analysis against NIST SP 800-53 / FIPS 140-3 / FedRAMP / Common Criteria expectations.

## Status

- **Phase 1: Spike** — ✅ Complete (end-to-end loop validated on Apple Silicon)
- **Phase 2: Hardening** — ✅ Complete (TCC silent-deny detection, hallucination guards, clipboard preserve/restore, re-entrancy guard, failure notifications)
- **Phase 2.5: Branding** — ✅ Complete (this rebrand)
- **Phase 2.7: Security Posture** — ⏳ Queued (SECURITY.md, SBOM, zero-egress verification)
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
