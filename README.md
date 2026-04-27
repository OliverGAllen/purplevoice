# voice-cc

**Speak → text appears in Claude Code, instantly and reliably, with no recurring cost or external dependency.**

A local, push-to-talk voice input system for Claude Code on macOS Apple Silicon. Hold a hotkey, speak, release — your transcript appears in the focused Claude Code terminal.

## Status

Phase 1 spike — proving the end-to-end loop on Oliver's machine. Not yet distributable.

## Hotkey

`cmd+option+space` (push-and-hold). Locked decision; see `.planning/phases/01-spike/01-CONTEXT.md` D-01.

## Setup

```bash
bash setup.sh
```

`setup.sh` is idempotent — safe to re-run. It installs Homebrew dependencies (Hammerspoon, sox, whisper-cpp), creates the XDG directory layout (`~/.config/voice-cc/`, `~/.local/share/voice-cc/models/`, `~/.cache/voice-cc/`, `~/.local/bin/`, `~/.hammerspoon/voice-cc/`), downloads the Whisper `small.en` model with SHA256 verification, and seeds a default vocabulary file.

## Permissions to grant manually after first Hammerspoon launch

- **Microphone** — System Settings → Privacy & Security → Microphone → enable Hammerspoon.app
- **Accessibility** — System Settings → Privacy & Security → Accessibility → enable Hammerspoon.app

Both are required for the press-to-talk loop. Hammerspoon will prompt for them on first use.

## Conflicting macOS feature to disable

Disable the macOS Dictation hotkey to avoid conflicts:

- System Settings → Keyboard → Dictation → Shortcut → Off
