#!/usr/bin/env bash
# PurpleVoice setup — idempotent installer (Phase 2.5 rebrand of voice-cc).
#
# What this does (each step is safe to re-run):
#   1. Sanity-check that we are on Apple Silicon Homebrew (/opt/homebrew).
#   2. Install Hammerspoon (cask), sox, whisper-cpp via Homebrew if missing.
#   3. Verify the binaries exist at the expected absolute paths
#      (Pitfall 2: Hammerspoon hs.task does not see Homebrew binaries via PATH).
#   4. Create the XDG directory tree from day one (D-03).
#   5. Download the Whisper small.en GGML model with resumable curl and
#      verify SHA256 (D-05, D-06). Skip if file is already present and valid.
#   6. Seed ~/.config/purplevoice/vocab.txt from vocab.txt.default ONLY if absent
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
  echo "PurpleVoice requires Apple Silicon Homebrew at /opt/homebrew (not detected). Aborting." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Step 2: Homebrew dependencies (D-01, STACK.md "Installation")
# ---------------------------------------------------------------------------
if [ "${PURPLEVOICE_OFFLINE:-0}" = "1" ]; then
  if [ ! -d /Applications/Hammerspoon.app ]; then
    cat >&2 <<'EOF'
PurpleVoice: PURPLEVOICE_OFFLINE=1 set but Hammerspoon.app not present at /Applications/Hammerspoon.app.

  Air-gap install: download Hammerspoon-1.1.1.zip from https://www.hammerspoon.org/
  on a connected machine, USB-transfer, drag Hammerspoon.app to /Applications/,
  then re-run: PURPLEVOICE_OFFLINE=1 bash setup.sh

  (Homebrew cask install requires network access — see SECURITY.md "Air-Gapped Installation".)
EOF
    exit 1
  fi
  echo "OFFLINE: Hammerspoon.app present at /Applications/, skipping brew install."
elif [ ! -d /Applications/Hammerspoon.app ]; then
  echo "Installing Hammerspoon (cask)..."
  brew install --cask hammerspoon
else
  echo "Hammerspoon.app already present, skipping."
fi

if [ "${PURPLEVOICE_OFFLINE:-0}" = "1" ]; then
  if [ ! -x /opt/homebrew/bin/sox ]; then
    cat >&2 <<'EOF'
PurpleVoice: PURPLEVOICE_OFFLINE=1 set but sox not present at /opt/homebrew/bin/sox.

  Air-gap install: on a connected reference machine run
    brew fetch sox --bottle
  (produces tarball at ~/Library/Caches/Homebrew/downloads/), USB-transfer,
  then on this machine: brew install <local-bottle>.tar.gz
  OR sneakernet /opt/homebrew/bin/sox + /opt/homebrew/bin/soxi from the
  reference machine. See SECURITY.md "Air-Gapped Installation".
EOF
    exit 1
  fi
  echo "OFFLINE: sox present at /opt/homebrew/bin/, skipping brew install."
elif brew list sox &>/dev/null; then
  echo "sox already installed, skipping."
else
  echo "Installing sox..."
  brew install sox
fi

if [ "${PURPLEVOICE_OFFLINE:-0}" = "1" ]; then
  if [ ! -x /opt/homebrew/bin/whisper-cli ]; then
    cat >&2 <<'EOF'
PurpleVoice: PURPLEVOICE_OFFLINE=1 set but whisper-cli not present at /opt/homebrew/bin/whisper-cli.

  Air-gap install: on a connected reference machine run
    brew fetch whisper-cpp --bottle
  (produces tarball at ~/Library/Caches/Homebrew/downloads/), USB-transfer,
  then on this machine: brew install <local-bottle>.tar.gz
  OR sneakernet /opt/homebrew/bin/whisper-cli (and any required dylibs)
  from the reference machine. See SECURITY.md "Air-Gapped Installation".
EOF
    exit 1
  fi
  echo "OFFLINE: whisper-cli present at /opt/homebrew/bin/, skipping brew install."
elif brew list whisper-cpp &>/dev/null; then
  echo "whisper-cpp already installed, skipping."
else
  echo "Installing whisper-cpp..."
  brew install whisper-cpp
fi

# Phase 2.7 / D-09 (revised): Syft for SBOM regeneration. Syft is a HARD DEP
# for Phase 2.7 setup (per checker M-3 Option A). SEC-03 substantiation
# requires a real Syft scan; verify_sbom.sh asserts name=="PurpleVoice".
# Idempotent install via standard `command -v` check. NOT under
# PURPLEVOICE_OFFLINE branching — Syft is a precondition for verify_sbom.sh.
if command -v syft >/dev/null 2>&1; then
  echo "syft already installed, skipping."
else
  echo "Installing syft (Anchore SBOM generator)..."
  brew install syft
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
# Step 3b: One-time migration from voice-cc → purplevoice (Phase 2.5)
# ---------------------------------------------------------------------------
# Idempotent migration of XDG dirs and symlinks created by older voice-cc
# installs. Per RESEARCH.md "Pattern 2", four-state guard:
#   only-old → mv          (one-shot migration of this user's data)
#   both     → warn+skip   (do not clobber either side; user resolves)
#   only-new → no-op       (already migrated, or fresh install)
#   neither  → no-op       (fresh install, nothing to do)
#
# Models (~190 MB) are MOVED, not copied — same APFS volume, atomic at
# directory inode level. mv preserves any user-managed symlinks inside the
# old dir.
migrate_xdg_dir() {
  local old="$1"
  local new="$2"
  local label="$3"
  if [ ! -d "$old" ] && [ ! -d "$new" ]; then return 0; fi
  if [ ! -d "$old" ] && [ -d "$new" ]; then return 0; fi
  if [ -d "$old" ] && [ -d "$new" ]; then
    echo "WARN: both $old AND $new exist — leaving both. Resolve manually." >&2
    return 0
  fi
  echo "Migrating $label: $old → $new"
  mkdir -p "$(dirname "$new")"
  mv "$old" "$new"
}

migrate_xdg_dir "$HOME/.config/voice-cc"      "$HOME/.config/purplevoice"      "config"
migrate_xdg_dir "$HOME/.local/share/voice-cc" "$HOME/.local/share/purplevoice" "data (~190 MB models)"
migrate_xdg_dir "$HOME/.cache/voice-cc"       "$HOME/.cache/purplevoice"       "cache"

# Symlink hygiene — old symlinks point at filenames that no longer exist
# (Plan 02.5-01 renamed voice-cc-record → purplevoice-record and
# voice-cc-lua/ → purplevoice-lua/). Remove stale symlinks before Step 4
# creates the new XDG dirs and Step 6c (below) recreates the symlinks.
if [ -L "$HOME/.local/bin/voice-cc-record" ]; then
  rm "$HOME/.local/bin/voice-cc-record"
  echo "Removed stale symlink: ~/.local/bin/voice-cc-record"
fi
if [ -L "$HOME/.hammerspoon/voice-cc" ]; then
  rm "$HOME/.hammerspoon/voice-cc"
  echo "Removed stale symlink: ~/.hammerspoon/voice-cc"
fi

# ---------------------------------------------------------------------------
# Step 4: Create XDG directory tree (D-03)
# ---------------------------------------------------------------------------
mkdir -p \
  "$HOME/.config/purplevoice" \
  "$HOME/.local/share/purplevoice/models" \
  "$HOME/.cache/purplevoice" \
  "$HOME/.local/bin" \
  "$HOME/.hammerspoon"
# NOTE: ~/.hammerspoon/purplevoice is intentionally NOT created here —
# Step 6c (below) creates it as a symlink via `ln -sfn`, which cannot
# overwrite an existing directory. Creating the dir here would race
# with the symlink install step.
echo "OK: XDG directories ensured (~/.config/purplevoice, ~/.local/share/purplevoice/models, ~/.cache/purplevoice, ~/.local/bin)"

# ---------------------------------------------------------------------------
# Step 5: Download Whisper model with resume + checksum verify (D-05, D-06)
# ---------------------------------------------------------------------------
MODEL="$HOME/.local/share/purplevoice/models/ggml-small.en.bin"
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
elif [ "${PURPLEVOICE_OFFLINE:-0}" = "1" ]; then
  cat >&2 <<EOF
PurpleVoice: PURPLEVOICE_OFFLINE=1 set but Whisper model not sideloaded (or SHA256 mismatch).

  Required path: $MODEL
  Required SHA256: $MODEL_SHA256

  To obtain on a connected machine:
    curl -L -o ggml-small.en.bin "$MODEL_URL"
    shasum -a 256 ggml-small.en.bin   # verify matches above
    # USB-transfer to this machine and place at the required path.
EOF
  exit 1
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
SILERO_MODEL="$HOME/.local/share/purplevoice/models/ggml-silero-v6.2.0.bin"
SILERO_URL="https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v6.2.0.bin"
SILERO_SIZE_MIN=800000

if [ -f "$SILERO_MODEL" ] && [ "$(stat -f%z "$SILERO_MODEL" 2>/dev/null || echo 0)" -ge "$SILERO_SIZE_MIN" ]; then
  echo "Silero VAD weights present at $SILERO_MODEL, skipping."
elif [ "${PURPLEVOICE_OFFLINE:-0}" = "1" ]; then
  cat >&2 <<EOF
PurpleVoice: PURPLEVOICE_OFFLINE=1 set but Silero VAD weights not sideloaded.

  Required path: $SILERO_MODEL
  Minimum size: $SILERO_SIZE_MIN bytes

  To obtain on a connected machine:
    curl -L -o ggml-silero-v6.2.0.bin "$SILERO_URL"
    # USB-transfer to this machine and place at the required path.
EOF
  exit 1
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
# Step 6: Seed vocab.txt.default -> ~/.config/purplevoice/vocab.txt (D-08, no-clobber)
# ---------------------------------------------------------------------------
VOCAB_DEST="$HOME/.config/purplevoice/vocab.txt"
VOCAB_SRC="$(dirname "$0")/vocab.txt.default"
if [ ! -f "$VOCAB_DEST" ]; then
  if [ ! -f "$VOCAB_SRC" ]; then
    echo "Missing source: $VOCAB_SRC (run setup.sh from the PurpleVoice repo root)." >&2
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
# the community reports them). Always overwrites ~/.config/purplevoice/denylist.txt.
# If a user wants to pin a custom version, they can `chmod -w` the destination.
DENYLIST_DEST="$HOME/.config/purplevoice/denylist.txt"
DENYLIST_SRC="$(dirname "$0")/config/denylist.txt"
if [ ! -f "$DENYLIST_SRC" ]; then
  echo "Missing source: $DENYLIST_SRC (run setup.sh from the PurpleVoice repo root)." >&2
  exit 1
fi
cp "$DENYLIST_SRC" "$DENYLIST_DEST"
echo "OK: denylist.txt installed at $DENYLIST_DEST (project-owned, overwritten on every setup.sh run)."

# ---------------------------------------------------------------------------
# Step 6c: Install symlinks (D-03, D-04 — purplevoice-record + purplevoice-lua)
# ---------------------------------------------------------------------------
# Idempotent. Recreate even if the source target was renamed (Plan 02.5-01).
# Uses absolute paths via $(pwd) which is the repo root because Step 0 hasn't
# changed directory; setup.sh is invoked as `bash setup.sh` from repo root.
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"

ln -sfn "$REPO_ROOT/purplevoice-record" "$HOME/.local/bin/purplevoice-record"
echo "OK: symlink ~/.local/bin/purplevoice-record → $REPO_ROOT/purplevoice-record"

ln -sfn "$REPO_ROOT/purplevoice-lua" "$HOME/.hammerspoon/purplevoice"
echo "OK: symlink ~/.hammerspoon/purplevoice → $REPO_ROOT/purplevoice-lua"

# ---------------------------------------------------------------------------
# Step 8: Regenerate SBOM if Syft is present (D-12, idempotent)
# ---------------------------------------------------------------------------
# Syft 1.43.0+ generates SPDX 2.3 JSON. We post-process the output to:
#   - inject 4 system-context annotations (macOS version, hardware, Xcode CLT,
#     brew version) via SPDX-2.3-spec-compliant Annotation blocks (Priority 3).
#   - deterministicise volatile fields (creationInfo.created + documentNamespace)
#     so re-runs produce zero git diff when the package set is unchanged
#     (Pitfall 3).
#
# If Syft is absent, the committed SBOM.spdx.json applies; we print a notice.
# If jq is absent, system-context annotations are skipped with a notice
# (committed SBOM is still valid SPDX, just without system context).

inject_system_context() {
  local sbom="$1"
  if ! command -v jq >/dev/null 2>&1; then
    echo "  jq not found — system-context annotations skipped." >&2
    return 0
  fi
  # Use a constant timestamp derived from the repo HEAD so re-runs are
  # deterministic when packages are unchanged (Pitfall 3).
  local timestamp="2026-04-29T00:00:00Z"  # constant; deterministicise by package-set hash
  local macos_version; macos_version=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
  local macos_build; macos_build=$(sw_vers -buildVersion 2>/dev/null || echo "unknown")
  local arch; arch=$(uname -m 2>/dev/null || echo "unknown")
  local clt_version; clt_version=$(pkgutil --pkg-info=com.apple.pkg.CLTools_Executables 2>/dev/null | awk -F': ' '/^version:/ {print $2}')
  [ -z "$clt_version" ] && clt_version="not-installed"
  local brew_version; brew_version=$(brew --version 2>/dev/null | head -1 | awk '{print $2}')
  [ -z "$brew_version" ] && brew_version="unknown"

  jq --arg ts "$timestamp" \
     --arg mv "system-context: macOS-version=$macos_version ($macos_build)" \
     --arg arch "system-context: hardware-platform=$arch (Apple Silicon)" \
     --arg clt "system-context: xcode-clt-version=$clt_version" \
     --arg brew "system-context: brew-version=$brew_version" \
     '.annotations = (.annotations // []) + [
        {annotationDate: $ts, annotationType: "OTHER", annotator: "Tool: PurpleVoice-setup.sh", comment: $mv},
        {annotationDate: $ts, annotationType: "OTHER", annotator: "Tool: PurpleVoice-setup.sh", comment: $arch},
        {annotationDate: $ts, annotationType: "OTHER", annotator: "Tool: PurpleVoice-setup.sh", comment: $clt},
        {annotationDate: $ts, annotationType: "OTHER", annotator: "Tool: PurpleVoice-setup.sh", comment: $brew}
      ]' "$sbom" > "$sbom.tmp" && mv "$sbom.tmp" "$sbom"
}

deterministicise_sbom() {
  local sbom="$1"
  if ! command -v jq >/dev/null 2>&1; then return 0; fi
  local repo_head; repo_head="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo 'unversioned')"
  # Replace creationInfo.created with constant + documentNamespace with deterministic URI.
  jq --arg head "$repo_head" \
     '.creationInfo.created = "2026-04-29T00:00:00Z"
      | .documentNamespace = ("https://github.com/oliverallen/PurpleVoice/sbom/" + $head)' \
     "$sbom" > "$sbom.tmp" && mv "$sbom.tmp" "$sbom"
}

if command -v syft >/dev/null 2>&1; then
  if [ "${PURPLEVOICE_OFFLINE:-0}" = "1" ]; then
    echo "OFFLINE: Skipping SBOM regen (committed SBOM.spdx.json applies)."
  else
    echo "Regenerating SBOM (Syft 1.43.0+ detected)..."
    REPO_VERSION="$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo 'unversioned')"

    # Pitfall 2: scope discipline. Scan repo only (NOT $HOME, NOT /).
    # /opt/homebrew/Cellar/{sox,whisper-cpp} and /Applications/Hammerspoon.app
    # are scoped scans for the binary deps; merge happens via Syft's native
    # multi-source aggregation. For v1, repo-only scan is the baseline; the
    # wider scopes are documented as "release-only comprehensive regen".
    syft scan dir:"$REPO_ROOT" \
        --source-name "PurpleVoice" \
        --source-version "$REPO_VERSION" \
        --source-supplier "PurpleVoice Project" \
        -o spdx-json="$REPO_ROOT/SBOM.spdx.json" \
        >/dev/null 2>&1

    # Post-process for determinism + system context (Pitfall 3, Priority 3)
    inject_system_context "$REPO_ROOT/SBOM.spdx.json"
    deterministicise_sbom "$REPO_ROOT/SBOM.spdx.json"
    echo "OK: SBOM regenerated at SBOM.spdx.json (commit $REPO_VERSION)"
  fi
else
  echo "Syft not found — SBOM regen skipped. Committed SBOM.spdx.json applies."
fi

# ---------------------------------------------------------------------------
# Step 9: Karabiner-Elements check (Phase 4 / QOL-NEW-01 / CONTEXT.md D-07)
# ---------------------------------------------------------------------------
# Karabiner-Elements is REQUIRED for the F19 hotkey (fn-key remap). PurpleVoice
# does NOT auto-install third-party kernel-driver software — minimal-deps ethos.
# We refuse to declare install complete without it, and print actionable
# instructions. PURPLEVOICE_OFFLINE=1 mode behaves identically (Karabiner is
# local-only; no network needed for the check itself).

KARABINER_JSON="$REPO_ROOT/assets/karabiner-fn-to-f19.json"
if [ ! -f "$KARABINER_JSON" ]; then
  echo "PurpleVoice: $KARABINER_JSON missing from repo (run setup.sh from a Phase-4-or-later checkout)." >&2
  exit 1
fi

if [ ! -d /Applications/Karabiner-Elements.app ]; then
  cat >&2 <<EOF

----------------------------------------------------------------------
PurpleVoice: Karabiner-Elements is required for the F19 hotkey.

Install Karabiner-Elements (free, open-source — https://karabiner-elements.pqrs.org/):
  1. Download Karabiner-Elements.dmg from https://karabiner-elements.pqrs.org/
  2. Drag Karabiner-Elements.app to /Applications/.
  3. Launch once and grant the driver/extension prompt
     (System Settings → Privacy & Security → "Allow software from Fumihiko Takayama").
  4. Open Karabiner-Elements → Preferences → Complex Modifications → Add rule →
     Import rule from file → choose:
       $KARABINER_JSON
     Then click "Enable" next to "Hold fn → F19 (PurpleVoice push-to-talk)".
  5. Re-run: bash setup.sh

If air-gapped: copy Karabiner-Elements.dmg from a connected machine via USB
and install manually. The fn→F19 JSON rule is already in this repo at
$KARABINER_JSON.
----------------------------------------------------------------------
EOF
  exit 1
fi

echo "OK: Karabiner-Elements detected at /Applications/Karabiner-Elements.app"
echo "    REMINDER: ensure 'Hold fn → F19 (PurpleVoice push-to-talk)' is enabled in"
echo "    Karabiner-Elements → Preferences → Complex Modifications. If not yet"
echo "    imported, see $KARABINER_JSON"

# ---------------------------------------------------------------------------
# Step 10: Next-step reminders (banner — final step)
# ---------------------------------------------------------------------------
cat <<'EOF'

----------------------------------------------------------------------
PurpleVoice setup complete.

Local voice dictation. Nothing leaves your Mac.

HUD options: PURPLEVOICE_HUD_OFF=1 to disable, PURPLEVOICE_HUD_POSITION=top-right (or top-center, bottom-center, bottom-right, near-cursor, center)

Next manual steps (one-time):
  - Add to ~/.hammerspoon/init.lua (paste this exact line):
      require("purplevoice")
    (If you previously had `require("voice-cc")`, replace it with the line above.)
  - On first Hammerspoon launch, grant Microphone + Accessibility permissions
    (System Settings -> Privacy & Security -> Microphone / Accessibility).
  - Disable the macOS Dictation hotkey to avoid conflicts
    (System Settings -> Keyboard -> Dictation -> Shortcut -> Off).
  - Hotkey: F19 push-and-hold (Karabiner remaps fn → F19 — see Step 9 reminder above).
  - Re-paste last transcript: cmd+shift+v.
----------------------------------------------------------------------
EOF
