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

## Quickstart

```bash
INSTALL_TOKEN=xxx curl -fsSL https://raw.githubusercontent.com/OliverGAllen/purplevoice/main/install.sh | bash
```

`INSTALL_TOKEN` is required — this installer is gated. To request a token, email **oliver@olivergallen.com** with subject prefix `[PurpleVoice install token]`. The repo source is fully public and reviewable; the token is a soft request-channel signal (see [Distribution model](SECURITY.md#distribution-model-phase-3-v1) in SECURITY.md for the honest framing — a determined party reading `install.sh` can bypass the gate, so its purpose is filtering casual installs and creating a "ping Oliver before installing" channel, not access control).

After install completes, paste `require("purplevoice")` into `~/.hammerspoon/init.lua` and reload Hammerspoon. Then:

- **Hold `fn`** to start recording, release to transcribe and paste into the focused window.
- **Hold `` ` ``** (backtick) to re-paste the most recent transcript.

If anything misbehaves, see [Detailed Install](#detailed-install) below — Karabiner-Elements is required, and macOS asks for Microphone + Accessibility permissions on first run.

## Hotkey

**Primary trigger: F19 (push-and-hold).** Karabiner-Elements remaps the `fn` key — hold fn for >200 ms to start recording, release to stop. A quick tap of fn (under 200 ms) preserves macOS's native fn behaviour (Globe / emoji popup, function-key row, dictation). Locked decision per `.planning/phases/04-quality-of-life-v1-x/04-CONTEXT.md` D-05 (replaces the original Cmd+Shift+E binding to eliminate the VS Code / Cursor "Show Explorer" collision).

**Re-paste last transcript: hold `` ` `` (backtick).** Pastes the most recent successful transcript into the focused window. Useful when focus shifted mid-paste and the transcript landed in the wrong app. The backtick key is remapped via Karabiner-Elements (`assets/karabiner-backtick-to-f18.json`): tap `` ` `` types a backtick normally; hold `` ` `` for ~200 ms emits F18, which Hammerspoon binds to the re-paste action. In-memory only — lost on Hammerspoon reload (privacy-first; per CONTEXT.md D-03).

> **Note on hotkey choice:** the original plan used `cmd+shift+v` (D-02), but live walkthrough on 2026-04-30 surfaced an opaque clipboard-manager collision (no Hammerspoon binding-failed alert; keystroke silently consumed) plus the documented VS Code / Cursor "Markdown Preview" cost. Switched to F18-via-backtick-hold to dodge both — F18 has zero collisions and the backtick key remains usable for typing.

## Performance

Latency benchmarks (whisper-cli transcription, hyperfine 10-run × 3-warmup) on Oliver's machine:

| Utterance length | p50 | p95 |
|---|---|---|
| 2s.wav | 0.583 s | 0.591 s |
| 5s.wav | 0.589 s | 0.605 s |
| 10s.wav | 1.093 s | 1.101 s |

**Phase 5 (warm-process upgrade) trigger:** `p50 > 2s OR p95 > 4s on the 5s.wav benchmark`. Currently: **DEFERRED** — 5s.wav p50 = 0.589 s and p95 = 0.605 s, both well within budget (~3.4× and ~6.6× margin). Cold-start pipeline is fast enough on M2 Max; warm-process daemon is not required for v1.x. Re-run `bash tests/benchmark/run.sh` on AC power if you change hardware or move to a larger model. See [BENCHMARK.md](BENCHMARK.md) for full methodology + Environment block + raw JSON.

## Detailed Install

The Quickstart curl one-liner runs `install.sh`, which is idempotent — safe to re-run. It installs Homebrew dependencies (Hammerspoon, sox, whisper-cpp, syft), creates the XDG directory layout (`~/.config/purplevoice/`, `~/.local/share/purplevoice/models/`, `~/.cache/purplevoice/`, `~/.local/bin/`, `~/.hammerspoon/purplevoice/`), downloads the Whisper `small.en` model with SHA256 verification, downloads the Silero VAD weights, seeds a default vocabulary file, seeds the hallucination-denylist, refuses to declare install complete without Karabiner-Elements (Step 9), and prints the `require("purplevoice")` line for you to paste into `~/.hammerspoon/init.lua`. If you're upgrading from the working name `voice-cc`, the migration is automatic (only-old → mv; both → warn+skip; only-new → no-op).

If you cloned the repo locally instead of using the curl one-liner: `bash install.sh` from the repo root does the same thing.

### Karabiner-Elements (required for the F19 + backtick hotkeys)

PurpleVoice's F19 push-to-talk and F18 re-paste hotkeys are produced by remapping the `fn` and backtick keys with [Karabiner-Elements](https://karabiner-elements.pqrs.org/) (free, open-source). `install.sh` Step 9 checks for `/Applications/Karabiner-Elements.app` and refuses to declare install complete without it.

One-time installation:

1. Download `Karabiner-Elements.dmg` from <https://karabiner-elements.pqrs.org/>.
2. Drag `Karabiner-Elements.app` to `/Applications/`.
3. Launch Karabiner-Elements once. macOS will prompt for the driver / system-extension grant — open System Settings → Privacy & Security and enable **"Allow software from Fumihiko Takayama"** (the Karabiner author). Restart Karabiner-Elements when prompted.
4. Import BOTH rules: Karabiner-Elements → **Preferences → Complex Modifications → Add rule → Import rule from file** → select these in turn from your PurpleVoice clone (or from `~/.local/share/purplevoice/src/assets/` if you used the curl one-liner):
   - `assets/karabiner-fn-to-f19.json` — click **Enable** next to **"Hold fn → F19 (PurpleVoice push-to-talk)"**.
   - `assets/karabiner-backtick-to-f18.json` — click **Enable** next to **"Hold ` (backtick) → F18 (PurpleVoice re-paste)"**.
5. Re-run `bash install.sh` — Step 9 should now print `OK: Karabiner-Elements detected at /Applications/Karabiner-Elements.app`.

Air-gapped users: copy `Karabiner-Elements.dmg` from a connected machine via USB sneakernet. The JSON rules are bundled in this repo at `assets/karabiner-*.json` — no additional download needed for the rules.

The recommended hold threshold is 200 ms (configured in each JSON rule via `basic.to_if_alone_timeout_milliseconds` and `basic.to_if_held_down_threshold_milliseconds`). If the threshold feels wrong on your hardware (false-positive recording on quick taps OR perceived lag on intentional holds), edit both values in the JSON file in 50 ms increments and re-import in Karabiner.

### Permissions (granted manually after first Hammerspoon launch)

- **Microphone** — System Settings → Privacy & Security → Microphone → enable Hammerspoon.app
- **Accessibility** — System Settings → Privacy & Security → Accessibility → enable Hammerspoon.app

Both are required for the press-to-talk loop. Hammerspoon will prompt for Microphone on first sox spawn; Accessibility is surfaced deterministically by `hs.accessibilityState(true)` on module load. If permission is denied, PurpleVoice fires an actionable macOS notification with a deep link to the relevant Privacy & Security pane (no silent failures — this was Phase 2's hardening contract).

### Conflicting macOS feature to disable

Disable the macOS Dictation hotkey to avoid conflicts:

- System Settings → Keyboard → Dictation → Shortcut → Off

### Recovery

If something stops working, work through these four items in order. Most "lost my hotkeys" reports resolve at item 3.

#### 1. TCC reset (permissions stuck weirdly)

```bash
tccutil reset Microphone org.hammerspoon.Hammerspoon
tccutil reset Accessibility org.hammerspoon.Hammerspoon
osascript -e 'tell application "Hammerspoon" to quit'
open -a Hammerspoon
```

Then re-grant when prompted.

#### 2. Karabiner rule troubleshoot

Open Karabiner-Elements → **Event Viewer**. Hold `fn` — F19 events should appear. Hold `` ` `` — F18 events should appear.

**Common UK-vs-US gotcha:** the backtick rule uses `non_us_backslash` (UK + most non-US keyboards). On ANSI/US keyboards, edit `assets/karabiner-backtick-to-f18.json` and change both `non_us_backslash` values to `grave_accent_and_tilde`, then re-import.

#### 3. "I lost my hotkeys" — 5-step triage

If holding `fn` no longer triggers PurpleVoice recording (or holding `` ` `` no longer re-pastes):

1. **Reload Hammerspoon.** Menubar → Hammerspoon → Reload Config. If still no response → continue to step 2.

2. **Check the Karabiner-Elements menubar icon is present.** If absent, launch Karabiner-Elements (`open /Applications/Karabiner-Elements.app`); the menubar icon should appear within 5 seconds. If launching produces no menubar icon → reinstall Karabiner-Elements (re-grant the system-extension prompt).

3. **Verify both rules are enabled.** Karabiner-Elements → Preferences → Complex Modifications. Both rules should be present + toggled ON:
   - "Hold fn → F19 (PurpleVoice push-to-talk)"
   - "Hold ` (backtick) → F18 (PurpleVoice re-paste)"
   If absent, re-import via "Add rule → Import rule from file" → select the JSON files in `assets/karabiner-*.json` from your PurpleVoice clone.

4. **Use Karabiner Event Viewer to confirm key codes.** Karabiner-Elements menubar → "Event Viewer".
   - Hold `fn`. The viewer should show `f19` events flowing.
   - Hold `` ` ``. The viewer should show `f18` events flowing.
   - If F19/F18 events are NOT flowing → the Karabiner rule isn't firing → re-check step 3.
   - If F19/F18 events ARE flowing but PurpleVoice doesn't react → continue to step 5.

5. **Check Hammerspoon console for binding-failed alerts.** Menubar → Hammerspoon → Console. Look for the most recent reload — is there a `PurpleVoice loaded` alert? If NO: `init.lua` failed to load → check `~/.hammerspoon/init.lua` contains `require("purplevoice")` and that no syntax error appears in the console. If YES (PurpleVoice loaded BUT keypresses don't trigger it): another app may be silently consuming the F19 / F18 key (Carbon `RegisterEventHotKey` collision — see Phase 4 D-02 SUPERSEDED notes). Try quitting clipboard managers / global-hotkey daemons one at a time and re-testing.

#### 4. uninstall.sh (full reset)

If the recovery steps above don't resolve the issue, you can fully remove PurpleVoice and re-install:

```bash
bash uninstall.sh
bash install.sh
```

See [Uninstalling](#uninstalling) for what `uninstall.sh` does and doesn't touch.

### Uninstalling

```bash
bash uninstall.sh
```

Removes:
- `~/.config/purplevoice/` (vocab.txt, denylist.txt)
- `~/.cache/purplevoice/`
- `~/.local/share/purplevoice/` (models + curl|bash clone destination at `src/`)
- `~/.local/bin/purplevoice-record` (symlink only)
- `~/.hammerspoon/purplevoice` (symlink or directory)

Does NOT touch:
- Hammerspoon, sox, whisper-cpp, Karabiner-Elements binaries (they may serve other tools)
- Karabiner rule JSONs in `~/.config/karabiner/` (user-owned; toggle off in Karabiner Preferences if you want to disable)
- The `require("purplevoice")` line in `~/.hammerspoon/init.lua` (manual removal — printed in the uninstall banner)
- TCC permissions for Hammerspoon (manual `tccutil reset` if desired)

If you want to preserve `vocab.txt` (the only file you may have edited), copy it out before running:

```bash
cp ~/.config/purplevoice/vocab.txt /tmp/my-vocab.txt
bash uninstall.sh
```

A local working clone of the PurpleVoice repo (e.g., at `~/dev/purplevoice/`) is NOT touched — that's a working copy under your control. Only the XDG-managed `~/.local/share/purplevoice/` tree is removed.

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

PurpleVoice supports air-gapped operation. Set `PURPLEVOICE_OFFLINE=1` before running `install.sh`:

```bash
PURPLEVOICE_OFFLINE=1 bash install.sh
```

Required pre-staging on a connected machine (USB sneakernet to the air-gapped target):

1. Download `ggml-small.en.bin` (~488 MB) from `https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin`. Verify SHA256 = `c6138d6d58ecc8322097e0f987c32f1be8bb0a18532a3f88f734d1bbf9c41e5d`. Place at `~/.local/share/purplevoice/models/ggml-small.en.bin`.
2. Download `ggml-silero-v6.2.0.bin` (~885 KB) from `https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v6.2.0.bin`. Place at `~/.local/share/purplevoice/models/ggml-silero-v6.2.0.bin`.
3. Download Hammerspoon `.zip` from `https://www.hammerspoon.org/`; drag `Hammerspoon.app` to `/Applications/`.
4. Sneakernet `sox` + `whisper-cpp` brew bottles (run `brew fetch sox whisper-cpp --bottle` on the connected machine; tarballs land at `~/Library/Caches/Homebrew/downloads/`).

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
install.sh                   # idempotent installer (renamed from setup.sh in Phase 3) + voice-cc → purplevoice migration + curl-vs-clone detection
uninstall.sh                 # idempotent removal of XDG dirs + symlinks
LICENSE                      # MIT
BENCHMARK.md                 # hyperfine performance numbers + Phase 5 trigger
SBOM.spdx.json               # Software Bill of Materials (SPDX 2.3 JSON)
assets/
  icon.svg                          # source SVG (lavender + white lips)
  icon-256.png                      # 256×256 PNG, sips-derived from icon.svg
  karabiner-fn-to-f19.json          # Karabiner rule: hold fn → F19 (push-to-talk)
  karabiner-backtick-to-f18.json    # Karabiner rule: hold ` → F18 (re-paste)
  README.md                         # icon regeneration instructions
config/denylist.txt          # canonical Whisper-hallucination phrases (filtered out)
tests/                       # bash unit tests + manual walkthroughs + benchmark harness
.planning/                   # GSD workflow artifacts (phase plans, requirements, state)
```

## Status

PurpleVoice v1 is **complete and shipping** as of Phase 3 close. Detailed phase progress, decisions, and historical context: [ROADMAP.md](.planning/ROADMAP.md).

Current phase coverage: 7 of 7 v1 phases complete (Spike → Hardening → Branding → Security Posture → HUD → Quality of Life → Distribution). Phase 5 (warm-process upgrade) is conditional on the hyperfine numbers in [BENCHMARK.md](BENCHMARK.md).

## Why "PurpleVoice"

The dictation tool space is crowded — Hush, Pip(it), Chirp, Magpie, Koe and others are all taken. PurpleVoice is a colour-noun compound that signals the brand visually (lavender + lips icon) without colliding with existing dictation products. The working name `voice-cc` survives in repo path, git history, and `.planning/` artifacts as historical record.
