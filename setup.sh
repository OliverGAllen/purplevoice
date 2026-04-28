#!/usr/bin/env bash
# voice-cc Phase 1 setup — idempotent installer.
#
# What this does (each step is safe to re-run):
#   1. Sanity-check that we are on Apple Silicon Homebrew (/opt/homebrew).
#   2. Install Hammerspoon (cask), sox, whisper-cpp via Homebrew if missing.
#   3. Verify the binaries exist at the expected absolute paths
#      (Pitfall 2: Hammerspoon hs.task does not see Homebrew binaries via PATH).
#   4. Create the XDG directory tree from day one (D-03).
#   5. Download the Whisper small.en GGML model with resumable curl and
#      verify SHA256 (D-05, D-06). Skip if file is already present and valid.
#   6. Seed ~/.config/voice-cc/vocab.txt from vocab.txt.default ONLY if absent
#      (D-08 — never clobber user edits).
#   7. Print next-step reminders for the user (Hammerspoon perms, macOS
#      Dictation hotkey conflict). Does NOT auto-edit any user config.
#
# Locked decisions: see .planning/phases/01-spike/01-CONTEXT.md (D-01..D-08).

set -euo pipefail

# ---------------------------------------------------------------------------
# Step 1: Apple Silicon Homebrew sanity check
# ---------------------------------------------------------------------------
if [ ! -d /opt/homebrew ]; then
  echo "voice-cc requires Apple Silicon Homebrew at /opt/homebrew (not detected). Aborting." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Step 2: Homebrew dependencies (D-01, STACK.md "Installation")
# ---------------------------------------------------------------------------
if [ ! -d /Applications/Hammerspoon.app ]; then
  echo "Installing Hammerspoon (cask)..."
  brew install --cask hammerspoon
else
  echo "Hammerspoon.app already present, skipping."
fi

if brew list sox &>/dev/null; then
  echo "sox already installed, skipping."
else
  echo "Installing sox..."
  brew install sox
fi

if brew list whisper-cpp &>/dev/null; then
  echo "whisper-cpp already installed, skipping."
else
  echo "Installing whisper-cpp..."
  brew install whisper-cpp
fi

# ---------------------------------------------------------------------------
# Step 3: Verify binaries exist at expected absolute paths (Pitfall 2)
# ---------------------------------------------------------------------------
for bin in /opt/homebrew/bin/sox /opt/homebrew/bin/soxi /opt/homebrew/bin/whisper-cli; do
  if [ ! -x "$bin" ]; then
    echo "Missing or non-executable: $bin" >&2
    exit 1
  fi
done
echo "OK: sox, soxi, whisper-cli present at /opt/homebrew/bin/"

# ---------------------------------------------------------------------------
# Step 4: Create XDG directory tree (D-03)
# ---------------------------------------------------------------------------
mkdir -p \
  "$HOME/.config/voice-cc" \
  "$HOME/.local/share/voice-cc/models" \
  "$HOME/.cache/voice-cc" \
  "$HOME/.local/bin" \
  "$HOME/.hammerspoon/voice-cc"
echo "OK: XDG directories ensured (~/.config/voice-cc, ~/.local/share/voice-cc/models, ~/.cache/voice-cc, ~/.local/bin, ~/.hammerspoon/voice-cc)"

# ---------------------------------------------------------------------------
# Step 5: Download Whisper model with resume + checksum verify (D-05, D-06)
# ---------------------------------------------------------------------------
MODEL="$HOME/.local/share/voice-cc/models/ggml-small.en.bin"
MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin"
# SHA256 for ggml-small.en.bin from the HuggingFace ggerganov/whisper.cpp mirror.
# Verified 2026-04-27 against the upstream `x-linked-etag` HTTP header on
#   https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin
# (file size 487,614,201 bytes, repo commit 5359861c739e955e79d9a303bcbc70fb988958b1).
# If verification fails, re-fetch the published checksum from that URL's
# response headers (or the model card on huggingface.co) and update this
# constant — do NOT silently accept a mismatched file.
MODEL_SHA256="c6138d6d58ecc8322097e0f987c32f1be8bb0a18532a3f88f734d1bbf9c41e5d"

verify_model_checksum() {
  local actual
  actual=$(shasum -a 256 "$MODEL" | awk '{print $1}')
  [ "$actual" = "$MODEL_SHA256" ]
}

if [ -f "$MODEL" ] && verify_model_checksum; then
  echo "Model present at $MODEL, checksum OK, skipping."
else
  if [ -f "$MODEL" ]; then
    echo "Model file exists but checksum mismatched or absent — will resume/redownload."
  else
    echo "Model not present — downloading ggml-small.en.bin (~488 MB) from HuggingFace..."
  fi
  curl -C - -L --fail -o "$MODEL" "$MODEL_URL"
  if ! verify_model_checksum; then
    echo "SHA256 mismatch after download — model corrupt or checksum stale." >&2
    echo "  expected: $MODEL_SHA256" >&2
    echo "  got:      $(shasum -a 256 "$MODEL" | awk '{print $1}')" >&2
    rm -f "$MODEL"
    exit 1
  fi
  echo "OK: model downloaded and checksum verified."
fi

# ---------------------------------------------------------------------------
# Step 5b: Download Silero VAD weights (Phase 2 / TRA-04)
# ---------------------------------------------------------------------------
# Silero VAD ggml weights for whisper.cpp's --vad flag. Without this file,
# --vad is a silent no-op. Sourced from the official ggml-org Hugging Face
# repo (see 02-RESEARCH.md §2). 885 KB; size sanity check >= 800000 bytes.
SILERO_MODEL="$HOME/.local/share/voice-cc/models/ggml-silero-v6.2.0.bin"
SILERO_URL="https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v6.2.0.bin"
SILERO_SIZE_MIN=800000

if [ -f "$SILERO_MODEL" ] && [ "$(stat -f%z "$SILERO_MODEL" 2>/dev/null || echo 0)" -ge "$SILERO_SIZE_MIN" ]; then
  echo "Silero VAD weights present at $SILERO_MODEL, skipping."
else
  echo "Downloading Silero VAD weights (~885 KB) from huggingface.co/ggml-org/whisper-vad ..."
  curl -L -C - --fail -o "$SILERO_MODEL" "$SILERO_URL"
  if [ "$(stat -f%z "$SILERO_MODEL" 2>/dev/null || echo 0)" -lt "$SILERO_SIZE_MIN" ]; then
    echo "Silero VAD download size suspiciously small (< $SILERO_SIZE_MIN bytes). Aborting." >&2
    rm -f "$SILERO_MODEL"
    exit 1
  fi
  echo "OK: Silero VAD weights downloaded."
fi

# ---------------------------------------------------------------------------
# Step 6: Seed vocab.txt.default -> ~/.config/voice-cc/vocab.txt (D-08, no-clobber)
# ---------------------------------------------------------------------------
VOCAB_DEST="$HOME/.config/voice-cc/vocab.txt"
VOCAB_SRC="$(dirname "$0")/vocab.txt.default"
if [ ! -f "$VOCAB_DEST" ]; then
  if [ ! -f "$VOCAB_SRC" ]; then
    echo "Missing source: $VOCAB_SRC (run setup.sh from the voice-cc repo root)." >&2
    exit 1
  fi
  cp "$VOCAB_SRC" "$VOCAB_DEST"
  echo "Seeded $VOCAB_DEST"
else
  echo "vocab.txt already exists at $VOCAB_DEST, preserving user edits."
fi

# ---------------------------------------------------------------------------
# Step 6b: Install denylist.txt (Phase 2 / TRA-06) — project-owned, always-overwrite
# ---------------------------------------------------------------------------
# Hallucination denylist is project-owned (we add new known-hallucinations as
# the community reports them). Always overwrites ~/.config/voice-cc/denylist.txt.
# If a user wants to pin a custom version, they can `chmod -w` the destination.
DENYLIST_DEST="$HOME/.config/voice-cc/denylist.txt"
DENYLIST_SRC="$(dirname "$0")/config/denylist.txt"
if [ ! -f "$DENYLIST_SRC" ]; then
  echo "Missing source: $DENYLIST_SRC (run setup.sh from the voice-cc repo root)." >&2
  exit 1
fi
cp "$DENYLIST_SRC" "$DENYLIST_DEST"
echo "OK: denylist.txt installed at $DENYLIST_DEST (project-owned, overwritten on every setup.sh run)."

# ---------------------------------------------------------------------------
# Step 7: Next-step reminders (do NOT auto-edit anything)
# ---------------------------------------------------------------------------
cat <<'EOF'

----------------------------------------------------------------------
Phase 1 setup complete.

Next manual steps (one-time):
  - Hotkey will be cmd+option+space (push-and-hold) once Plan 03 wires Hammerspoon.
  - On first Hammerspoon launch, grant Microphone + Accessibility permissions
    (System Settings -> Privacy & Security -> Microphone / Accessibility).
  - Disable the macOS Dictation hotkey to avoid conflicts
    (System Settings -> Keyboard -> Dictation -> Shortcut -> Off).
----------------------------------------------------------------------
EOF
