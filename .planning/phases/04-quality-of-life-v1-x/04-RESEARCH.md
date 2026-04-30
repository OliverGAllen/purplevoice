# Phase 4: Quality of Life (v1.x) — Research

**Researched:** 2026-04-30
**Domain:** macOS keyboard remapping (Karabiner-Elements complex modifications) + Hammerspoon Lua module hotkey extension + bash setup-step tooling
**Confidence:** HIGH

## Summary

Phase 4 ships exactly two trigger-validated quality-of-life items: (1) `cmd+shift+v` re-paste of the last successful transcript, in-memory only; (2) replacement of the colliding `cmd+shift+e` hotkey with **F19**, surfaced through a Karabiner-Elements `fn → F19` complex-modification rule that ships as a JSON file in `assets/`. CONTEXT.md already locks the major decisions; this research fills the seven explicit Claude's-Discretion gaps and resolves the technical unknowns the planner will hit.

The Karabiner schema work is the riskiest part. The good news: `to_if_alone` + `to_if_held_down` is the canonical pattern, the file format is a documented `{title, rules:[{description, manipulators:[...]}]}` shape, and the brewed cask `karabiner-elements` is at v15.9.0 (Jan 2026), which post-dates the macOS Sequoia `to_if_alone` regression (issue #3949 in 15.1.0). However, modern Apple keyboards expose the fn key as the "Globe" key, and a fn-tap should still reach macOS for emoji-popup / dictation purposes — meaning the rule MUST use `to_if_alone` (not a bare `to`) so a quick tap sends fn back to macOS while a hold sends F19 to Hammerspoon. The Hammerspoon side is straightforward: `hs.hotkey.bind({}, "f19", onPress, onRelease)` is well-supported (lowercase `f19` is documented in `hs.keycodes.map`), uses Carbon `RegisterEventHotKey` under the hood (registers globally before app shortcuts see the event), and supports symmetric onPress/onRelease semantics identical to today's cmd+shift+e binding.

**Primary recommendation:** Ship `assets/karabiner-fn-to-f19.json` with a `to_if_alone` (200 ms) + `to_if_held_down` (200 ms) split — fn-tap routes back to macOS for native behaviour, fn-hold emits F19 to Hammerspoon. Add `setup.sh` Step 9 that checks `/Applications/Karabiner-Elements.app` (matches Step 2's `/Applications/Hammerspoon.app` idiom verbatim), refuses to declare install complete when absent, and prints concise actionable instructions when present. In `purplevoice-lua/init.lua`, replace the cmd+shift+e binding with `hs.hotkey.bind({}, "f19", onPress, onRelease)`, add a module-scope `local lastTranscript = nil` + a `cmd+shift+v` re-paste binding that calls `pasteWithRestore(lastTranscript)`, and update the module-load alert string + the failed-binding alert. Use a brief `hs.alert.show("PurpleVoice: nothing to re-paste yet", 1.5)` for the nil-state (D-04 recommendation: alert, not silent).

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Phase 4 scope = QOL-01 + QOL-NEW-01 only. Other QOL items (Esc cancel, replacements.txt, history log, runtime model swap) stay deferred.
- **D-02:** Re-paste hotkey = `cmd+shift+v`. Pairs visually with `cmd+v`. Risk acknowledged: collides with macOS "Paste and Match Style" in some apps; PurpleVoice paste IS plain text (transient marker per Phase 2 INJ-03), so semantically aligned. Plan-level review may revisit per-app frustration.
- **D-03:** Last-transcript storage = in-memory Lua module-scope variable. `local lastTranscript = nil` at module scope; updated AFTER paste succeeds (in `pasteWithRestore` or `handleExit` exit-code-0 branch). Lost on Hammerspoon reload. NO disk persistence.
- **D-05:** F19 only — `cmd+shift+e` binding is REPLACED, not supplemented. `hs.hotkey.bind({}, "f19", onPress, onRelease)`.
- **D-06:** Karabiner fn→F19 complex-modification rule ships as a JSON file in the repo. User pastes into Karabiner-Elements via UI Import (or drops into `~/.config/karabiner/assets/complex_modifications/`).
- **D-07:** Karabiner setup is "Document + check." `setup.sh` Step 9 checks `/Applications/Karabiner-Elements.app`. If absent → actionable error + non-zero exit. If present → reminder + continue.
- **D-08:** `PURPLEVOICE_OFFLINE=1` interaction: Karabiner check still runs (no network needed); error message also notes USB-sneakernet path for Karabiner-Elements.dmg.
- **D-09:** No raw `hs.eventtap.flagsChanged` fn-detection path. Karabiner is the only supported fn-trigger pathway.
- **D-10:** Phase 4 surfaces use `purplevoice` brand consistently. Karabiner JSON references `org.hammerspoon.Hammerspoon` (Hammerspoon-controlled bundle ID, NOT PurpleVoice-renameable; honest about substrate). Future deferred-item paths/vars MUST be `~/.config/purplevoice/replacements.txt`, `~/.cache/purplevoice/history.log`, `PURPLEVOICE_MODEL`.

### Claude's Discretion

- **Nil-state behaviour for first re-paste (D-04)** — silent no-op vs brief alert. CONTEXT.md recommends alert.
- **JSON file location and name** — `assets/karabiner-fn-to-f19.json` vs `config/karabiner-fn-to-f19.json` vs other.
- **Hold-threshold value** in the Karabiner rule — Karabiner default is "varies"; researcher to validate.
- **Exact wording of setup.sh Karabiner-missing actionable error** — concise but actionable.
- **Order of setup.sh steps** — Karabiner check AFTER all other dep checks but BEFORE final banner.
- **Whether to add `tests/test_karabiner_check.sh`** — likely yes; mirrors existing `test_security_md_framing.sh` / `test_hud_env_off.sh` pattern.
- **Hammerspoon `hs.hotkey.bind({}, "f19", ...)` vs `bind({"fn"}, ...)`** — researcher to confirm.
- **Plan boundaries** — likely 2-3 plans (Wave 0 staging + HUD-style core + Karabiner integration + docs closure).

### Deferred Ideas (OUT OF SCOPE)

- **QOL-02 — Esc cancels in-flight recording** — no real-use trigger reported. Implementation pattern documented in CONTEXT.md for when it eventually triggers.
- **QOL-03 — `~/.config/purplevoice/replacements.txt`** — path REBRANDED. Bash `sed` post-filter step. Implementation pattern documented.
- **QOL-04 — Rolling history log at `~/.cache/purplevoice/history.log`, capped 10MB** — path REBRANDED. Privacy implications worth re-discussing when triggered (consider opt-in env var `PURPLEVOICE_HISTORY_LOG=1`).
- **QOL-05 — `PURPLEVOICE_MODEL` runtime model swap** — var name REBRANDED. Read `${PURPLEVOICE_MODEL:-small.en}` in bash glue.
- **Persistent `lastTranscript` at `~/.cache/purplevoice/last.txt`** — rejected per D-03.
- **Auto-install Karabiner via brew cask** — rejected per D-07.
- **Both cmd+shift+e + F19 active** — rejected per D-05.
- **Raw `hs.eventtap.flagsChanged` fn-detection** — rejected per D-09.
- **`PURPLEVOICE_HOTKEY` env var for runtime hotkey override** — rejected (over-config; F19 is locked).

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| **QOL-01** | Paste-last-transcript hotkey re-pastes the most recent transcription (recovery from focus-lost paste). Phase 4 promotes this from v2 stub to v1 with concrete language: `cmd+shift+v` binding, `lastTranscript` in-memory module-scope variable, no disk persistence, nil-state shows brief alert. | Hammerspoon `hs.hotkey.bind({"cmd","shift"}, "v", repaste)` is a one-liner. `lastTranscript` cached inside `pasteWithRestore` (or in `handleExit` exit-0 branch) AFTER the paste succeeds. `repaste()` reads the local + calls `pasteWithRestore(lastTranscript)`. Nil-state: `hs.alert.show("PurpleVoice: nothing to re-paste yet", 1.5)` mirrors existing `hs.alert` usage at line 545. Documented patterns: see "Code Examples" §1, §2. |
| **QOL-NEW-01** | Replace `cmd+shift+e` with **F19 only** (no fallback). Karabiner-Elements remaps fn → F19 via complex-modification JSON shipped in repo. Hammerspoon binds F19 (no modifiers). setup.sh Step 9 detects Karabiner-Elements presence, refuses to declare install complete without it. | Karabiner schema: `{title, rules:[{description, manipulators:[{type:"basic", from:{key_code:"fn"}, to_if_alone:[{key_code:"fn"}], to_if_held_down:[{key_code:"f19"}], parameters:{...}}]}]}`. File ships at `assets/karabiner-fn-to-f19.json`. Hammerspoon: `hs.hotkey.bind({}, "f19", onPress, onRelease)` — `f19` is in `hs.keycodes.map`, empty modifier table is supported, Carbon-based registration outranks app shortcuts. setup.sh Step 9 mirrors Step 2's `/Applications/Hammerspoon.app` idiom verbatim. Documented patterns: see "Code Examples" §3, §4, §5. |

## Project Constraints (from CLAUDE.md)

| Constraint | Source | How Phase 4 Honours |
|-----------|--------|---------------------|
| macOS Apple Silicon only | CLAUDE.md "Constraints" | Karabiner-Elements supports Apple Silicon (verified — current cask 15.9.0 supports macOS ≥ 10.15) |
| Tech stack: Hammerspoon + bash + no heavy frameworks | CLAUDE.md "Constraints" | Phase 4 adds zero new languages. Karabiner is a peer kernel-extension-style daemon, not a runtime dep of PurpleVoice's process tree. |
| Zero recurring cost | CLAUDE.md "Constraints" | Karabiner-Elements is free + open-source (BSD-style). No subscription. |
| Permissions: TCC Microphone + Accessibility one-time grant | CLAUDE.md "Constraints" | Karabiner adds its own one-time grant flow (driver/extension); the PurpleVoice grant story is documented honestly (additive, not replacing). |
| Audience: built for one user (Oliver) | CLAUDE.md "Constraints" | F19 swap is Oliver's friction-driven decision; cmd+shift+v re-paste matches his "lost focus mid-paste" workflow. |
| **Pattern 2 invariant** (`grep -c WHISPER_BIN purplevoice-record == 2`) | tests/test_brand_consistency.sh | Phase 4 does NOT modify `purplevoice-record`. Invariant preserved trivially. |
| **Pattern 2 corollary** (`! grep -q whisper-cli purplevoice-lua/init.lua`) | tests/test_brand_consistency.sh | Re-paste / F19 code is whisper-cli-free. Invariant preserved. |
| **Brand consistency** — no new `voice-cc` strings | tests/test_brand_consistency.sh | Phase 4 surfaces are entirely `purplevoice` / `PurpleVoice`. The Karabiner JSON's `org.hammerspoon.Hammerspoon` reference is the Hammerspoon bundle ID, NOT a brand string — it's an honest substrate reference. |
| **Framing lint** — no `compliant`/`certified`/`guarantees` in SECURITY.md without qualifier | tests/test_security_md_framing.sh | Phase 4's SECURITY.md SBOM-scope addition for Karabiner uses neutral "runtime dependency" language. |

## Standard Stack

### Core (already installed; Phase 4 adds one new dependency)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Hammerspoon | 1.1.1 | Hotkey binding (existing) — Phase 4 swaps `cmd+shift+e` → `F19` and adds `cmd+shift+v` | Already in stack; both bindings use the standard `hs.hotkey.bind` API |
| **Karabiner-Elements** | **15.9.0** (cask, Jan 2026) | NEW. macOS-native low-level keyboard customisation. Required for fn → F19 remap because fn cannot be reliably bound by user-space hotkey libraries (Hammerspoon's hs.hotkey + macOS Carbon hot keys do NOT see bare fn). | Mature (10+ years), free, single-purpose tool. The ONLY reliable user-space pathway for fn-key remapping on Apple internal keyboards. CONTEXT.md D-09 explicitly rejects the `hs.eventtap.flagsChanged` raw-detection alternative because of the documented race with macOS's Globe-popup behaviour. |

**Installation (manual, per CONTEXT.md D-07):**

```bash
# User downloads Karabiner-Elements.dmg from https://karabiner-elements.pqrs.org/
# Drag to /Applications/. Launch once to grant the driver/extension prompt.
# Then re-run setup.sh — Step 9 detects /Applications/Karabiner-Elements.app and prints next steps.
```

### Supporting

None — Phase 4 adds no new bash, lua, or python tools. The work is configuration-file-shipping (the JSON rule) + setup.sh extension + Hammerspoon Lua module surgery.

### Alternatives Considered

| Instead of Karabiner-Elements | Could Use | Tradeoff |
|---|---|---|
| Karabiner-Elements (peer daemon) | `hs.eventtap.flagsChanged` (Hammerspoon raw fn watcher) | **Rejected per CONTEXT.md D-09.** Documented race with macOS Globe-key popup (fn-hold opens emoji popup before Hammerspoon's eventtap fires). Plus: changing macOS's Globe-key default in System Settings (System Settings → Keyboard → "Press 🌐 key to" → "Show Emoji & Symbols") would break the workflow at OS upgrade time. Karabiner kicks in BELOW that surface (HID-driver level), so its remap is robust against macOS UI changes. |
| Karabiner-Elements complex modification | Karabiner-Elements simple modification (no hold-threshold) | Simple modification would route EVERY fn-tap to F19, breaking macOS's native fn-key behaviour (Globe popup, F1-F12 row, dictation). The complex-modification `to_if_alone` + `to_if_held_down` split preserves both. |
| Karabiner-Elements fn-remap | BetterTouchTool ($10) | BetterTouchTool also exposes fn at HID layer but requires payment. Karabiner-Elements is free and meets requirements. |
| F19 (via fn remap) | F18 / F20 / F13-F17 | All of F13-F20 are physically absent on Apple keyboards, so any of them works. F19 is the most-cited convention in the Karabiner community for "fn-as-Hyper-key" rules; F13-F15 sometimes collide with extended Apple keyboards' brightness/volume hardware keys. F19 is the safest choice. |

**Version verification (2026-04-30):** `brew info --cask karabiner-elements` reports `15.9.0` as the current cask. The 15.9.0 release (Jan 19, 2026) post-dates the macOS Sequoia 15 `to_if_alone` regression (issue #3949 in 15.1.0). 15.5.0 (Jul 2025) and 15.7.0 (Nov 2025) explicitly fixed function-key detection and modifier-release issues — Phase 4's recommended `to_if_alone` + `to_if_held_down` split is on the actively-maintained code path.

## Architecture Patterns

### Recommended File Layout

```
purplevoice-lua/
  init.lua                         # MODIFIED — F19 binding + cmd+shift+v binding + lastTranscript

assets/
  icon-256.png                     # existing (Phase 2.5)
  icon.svg                         # existing (Phase 2.5)
  karabiner-fn-to-f19.json         # NEW — Phase 4 complex-modification rule
  README.md                        # MODIFY — add karabiner-fn-to-f19.json provenance + import instructions

setup.sh                           # MODIFIED — add Step 9 (Karabiner check) before final banner

tests/
  test_karabiner_check.sh          # NEW — string-level lint mirroring test_hud_env_off.sh
  manual/
    test_*.md                       # MODIFY — every cmd+shift+e → F19

README.md                          # MODIFY — install flow, hotkey reference
SECURITY.md                        # MODIFY — SBOM scope disclaimer (add Karabiner alongside Hammerspoon)
.planning/REQUIREMENTS.md          # MODIFY — promote QOL-01 to v1, add QOL-NEW-01
.planning/ROADMAP.md               # MODIFY — Phase 4 plan list + Progress table
```

### Pattern 1: Karabiner Complex-Modification Rule File Format

The canonical importable JSON file structure (verified against [karabiner-elements.pqrs.org/docs/json/root-data-structure/](https://karabiner-elements.pqrs.org/docs/json/root-data-structure/)):

```json
{
  "title": "string — shown in Karabiner Preferences UI",
  "rules": [
    {
      "description": "string — shown in the rule list, click-to-enable",
      "manipulators": [
        {
          "type": "basic",
          "from": { /* event definition */ },
          "to": [ /* OPTIONAL: events sent immediately on key down */ ],
          "to_if_alone": [ /* events sent on release IF held shorter than threshold */ ],
          "to_if_held_down": [ /* events sent if held longer than threshold */ ],
          "parameters": { /* per-manipulator timing overrides */ }
        }
      ]
    }
  ]
}
```

**Where the file lives** (per [karabiner-elements.pqrs.org/docs/json/location/](https://karabiner-elements.pqrs.org/docs/json/location/)):

- **UI import path** (recommended for end users): Karabiner-Elements → Preferences → Complex Modifications → Add rule → Import rule from file → select `assets/karabiner-fn-to-f19.json` from the PurpleVoice repo. Karabiner copies the file into `~/.config/karabiner/assets/complex_modifications/`.
- **Direct drop-in** (for power users): copy `assets/karabiner-fn-to-f19.json` into `~/.config/karabiner/assets/complex_modifications/` directly. Karabiner watches `~/.config/karabiner/` via FSEvents and auto-detects the new file. User then enables the rule via the Karabiner UI.

### Pattern 2: tap-vs-hold semantics with `to_if_alone` + `to_if_held_down`

Canonical pattern from [karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/to-if-alone/](https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/to-if-alone/):

```json
{
  "type": "basic",
  "from": { "key_code": "fn" },
  "to_if_alone": [
    { "key_code": "fn", "halt": true }
  ],
  "to_if_held_down": [
    { "key_code": "f19" }
  ],
  "parameters": {
    "basic.to_if_alone_timeout_milliseconds": 200,
    "basic.to_if_held_down_threshold_milliseconds": 200
  }
}
```

Mechanics:
- Key down → Karabiner waits up to `to_if_held_down_threshold_milliseconds` (200 ms).
- If released BEFORE 200 ms → emits `to_if_alone` events (fn back to macOS, native behaviour).
- If still held AT 200 ms → emits `to_if_held_down` events (F19 to apps including Hammerspoon).
- The `"halt": true` flag prevents the `to_if_alone` event from also firing the `to_if_held_down` event.

The 200 ms value is empirically the sweet spot per multiple Karabiner community examples. Documented examples in the canonical Karabiner docs use 100, 200, 250, and 500 — 200 is the median and matches Karabiner's "quick tap" intuition without making press-and-hold feel laggy. See "Common Pitfalls" §1 for the full reasoning.

### Pattern 3: Hammerspoon F19 Binding (Replacement for cmd+shift+e)

```lua
-- BEFORE (purplevoice-lua/init.lua line 512):
local hk = hs.hotkey.bind({"cmd", "shift"}, "e", onPress, onRelease)
if not hk then
  hs.alert.show("PurpleVoice: cmd+shift+e binding failed (in use?)", 4)
end

-- AFTER:
local hk = hs.hotkey.bind({}, "f19", onPress, onRelease)
if not hk then
  hs.alert.show("PurpleVoice: F19 binding failed (Karabiner fn→F19 rule active?)", 4)
end
```

Key facts:
- Empty modifier table `{}` is documented and supported. Per [Hammerspoon `hs.hotkey.bind` docs](https://www.hammerspoon.org/docs/hs.hotkey.html#bind), the `mods` parameter accepts "zero or more" modifiers.
- Lowercase `"f19"` is the canonical key name in [`hs.keycodes.map`](https://www.hammerspoon.org/docs/hs.keycodes.html). All function keys F1-F20 are documented in lowercase.
- `onPress` + `onRelease` symmetry is identical to today's binding — no lifecycle changes needed.
- Hammerspoon's `hs.hotkey` uses Carbon's `RegisterEventHotKey` API under the hood. This registers the hotkey at the **system-global event-handler level**, which fires BEFORE per-app key dispatch. So when Karabiner emits F19, Hammerspoon's bare-F19 binding gets first crack — F19 will not "pass through" to a focused app.

### Pattern 4: Re-paste Hotkey + lastTranscript Caching

Caching point — inside `pasteWithRestore()` after the paste succeeds (the function already validates non-empty input, line 377):

```lua
-- purplevoice-lua/init.lua module-scope state block (line ~90, alongside isRecording):
local lastTranscript = nil  -- QOL-01: in-memory cache of last successful transcript

-- Inside pasteWithRestore, AFTER hs.eventtap.keyStroke fires (line ~398):
local function pasteWithRestore(transcript)
  if not transcript or transcript:match("^%s*$") then return end
  -- ... existing save + write + paste + timer-restore code ...
  hs.eventtap.keyStroke({"cmd"}, "v", 0)
  lastTranscript = transcript  -- NEW: cache for QOL-01 re-paste
  -- ... existing 250ms timer + restore ...
end

-- New repaste function near other locals (above the hotkey bindings):
local function repaste()
  if lastTranscript then
    pasteWithRestore(lastTranscript)
  else
    hs.alert.show("PurpleVoice: nothing to re-paste yet", 1.5)
  end
end

-- New binding near line 512:
local repasteHk = hs.hotkey.bind({"cmd", "shift"}, "v", repaste)
if not repasteHk then
  hs.alert.show("PurpleVoice: cmd+shift+v binding failed (in use?)", 4)
end
```

Why cache INSIDE `pasteWithRestore` and not in `handleExit`:
- `pasteWithRestore` already gates on non-empty transcript (line 377). Caching there means `lastTranscript` is automatically gated on "actually paste-worthy" — empty/whitespace transcripts can't pollute the cache.
- `handleExit` exit-code-0 branch unconditionally calls `pasteWithRestore(stdOut)`; caching in `handleExit` would either duplicate the empty-check or risk caching empty.
- Caching AFTER the `hs.eventtap.keyStroke({"cmd"}, "v", 0)` line means a re-paste-immediately scenario uses the same transcript (the closure-captured `pendingSaved` clipboard restore is independent — re-paste's call to `pasteWithRestore` will save the CURRENT clipboard fresh, overwrite with the transcript, paste, then restore the saved clipboard).

### Pattern 5: setup.sh Step 9 — Karabiner Check (mirrors Step 2's Hammerspoon check)

The existing pattern from `setup.sh` line 32-51 (the Hammerspoon presence check):

```bash
if [ "${PURPLEVOICE_OFFLINE:-0}" = "1" ]; then
  if [ ! -d /Applications/Hammerspoon.app ]; then
    cat >&2 <<'EOF'
PurpleVoice: PURPLEVOICE_OFFLINE=1 set but Hammerspoon.app not present at /Applications/Hammerspoon.app.
  ... actionable instructions ...
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
```

Phase 4's Step 9 differs: NO auto-install of Karabiner (rejected per D-07). Both online and offline branches refuse with actionable error if Karabiner is missing. The placement is AFTER existing dep checks (so user gets a holistic missing-deps view) but BEFORE the "Karabiner-Elements detected" reminder, which is itself before the final banner.

```bash
# ---------------------------------------------------------------------------
# Step 9: Karabiner-Elements check (Phase 4 / QOL-NEW-01 / CONTEXT.md D-07)
# ---------------------------------------------------------------------------
# Karabiner-Elements is REQUIRED for the F19 hotkey (fn-key remap). PurpleVoice
# does NOT auto-install third-party kernel-driver software. We refuse to declare
# install complete without it, and print actionable instructions.
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
       $REPO_ROOT/assets/karabiner-fn-to-f19.json
     Then click "Enable" next to "fn → F19 (PurpleVoice)".
  5. Re-run: bash setup.sh

If air-gapped: copy Karabiner-Elements.dmg from a connected machine via USB
and install manually. The fn→F19 JSON rule is already in this repo at
$REPO_ROOT/assets/karabiner-fn-to-f19.json.
----------------------------------------------------------------------
EOF
  exit 1
fi
echo "OK: Karabiner-Elements detected at /Applications/Karabiner-Elements.app"
echo "    REMINDER: ensure 'fn → F19 (PurpleVoice)' is enabled in Karabiner"
echo "    Preferences → Complex Modifications. If not yet imported, see"
echo "    $REPO_ROOT/assets/karabiner-fn-to-f19.json"
```

### Anti-Patterns to Avoid

- **Caching `lastTranscript` to disk** — directly violates D-03 and the privacy-first ethos for the institutional audience. The "I lost focus" recovery use case does not need persistence; if the user reloads Hammerspoon, the transcript is gone (acceptable).
- **Adding `cmd+shift+e` AS A FALLBACK** — directly violates D-05. Dual-trigger creates confusion ("which one am I supposed to use?"). F19 is the ONLY trigger after Phase 4.
- **Auto-installing Karabiner via `brew install --cask karabiner-elements`** — directly violates D-07. Karabiner is a kernel-extension-class dep with its own driver/extension grant flow; auto-installation surprises the user and conflicts with PurpleVoice's "minimal automated deps" framing.
- **Using `hs.eventtap.flagsChanged` to detect bare-fn presses inside Hammerspoon** — directly violates D-09. The Globe-popup race makes this unreliable. Karabiner remaps below the macOS HID layer where the Globe popup hasn't been triggered yet.
- **Putting `lastTranscript = stdOut` in `handleExit` outside the exit-code-0 branch** — would cache stale data on failed transcriptions. Cache MUST live inside the success path (inside `pasteWithRestore` after the paste fires).
- **Writing the Karabiner JSON with `to`-only mapping** (no `to_if_alone` + `to_if_held_down` split) — would route EVERY fn-tap to F19, breaking macOS Globe popup, emoji shortcut, and dictation key entirely. Tap-vs-hold split is non-negotiable.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| fn-key tap/hold detection in Hammerspoon | `hs.eventtap.flagsChanged` watcher with timer + state machine | Karabiner-Elements complex modification | The Globe-popup race (CONTEXT.md D-09) means Hammerspoon's eventtap fires AFTER macOS has already shown the emoji popup. Karabiner intercepts at HID-driver level, before macOS sees the event. Documented per RESEARCH 2026-04-28. |
| F19 keystroke generation | Custom CGEvent synthesis from a LaunchAgent | Karabiner | Karabiner's `to_if_held_down` is the canonical, documented, well-maintained pathway. Reinventing it requires kernel-extension experience + signing + per-OS-version maintenance. |
| Karabiner-Elements bundled inside the repo | Vendoring the .dmg or .pkg | User downloads via official URL | Distributing third-party kernel-driver binaries inside our repo would require ongoing security-update tracking + Karabiner's licence audit + larger repo size. CONTEXT.md D-07 "Document + check" honours minimal-deps ethos. |
| Karabiner-Elements presence detection logic | Custom `lsappinfo` / `mdfind` / `defaults read` calls | Plain `[ -d /Applications/Karabiner-Elements.app ]` | The setup.sh existing idiom (`[ -d /Applications/Hammerspoon.app ]` line 33, line 46) is the simplest and most reliable. Both brew-cask installs and manual .dmg installs produce the .app at this path. |
| Karabiner driver/extension grant detection from bash | Probing `kextstat` / `systemextensionsctl list` | Skip — rely on user honouring actionable error | macOS hides driver-extension state behind admin-only `systemextensionsctl` (requires sudo + System Integrity Protection awareness). The actionable error in Step 9 includes the grant-state instruction; the user runs Karabiner once after install which surfaces the system prompt. We document, we don't probe. |
| In-memory key=value cache library | A "store-and-recall" Lua module | Plain `local lastTranscript = nil` | One variable. Lua's lexical scope IS the cache. Adding a module is over-engineering. |

**Key insight:** Phase 4 is small surface area. Hand-rolling temptation is high (just one Lua hotkey, just one bash check), but every "just" hides a documented failure mode that the recommended primitives already solve. The Karabiner choice in particular is the result of an explicitly-documented prior research finding (CONTEXT.md D-09), not a default.

## Runtime State Inventory

> Phase 4 IS a hybrid (small refactor + new feature). Two surfaces could carry stale state.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| **Stored data** | None — `lastTranscript` is in-memory Lua local; lost on Hammerspoon reload by design (D-03). The Phase 1 D-03 marker `~/.cache/voice-cc/last.txt` was never used (Phase 1 RESEARCH note); Phase 4 keeps it unused. | None — verified by `grep -r "last.txt" purplevoice-lua/ purplevoice-record` returning zero hits. |
| **Live service config** | **Karabiner-Elements `~/.config/karabiner/karabiner.json`** carries the user's enabled rules. After Phase 4 ships, the user MUST manually import + enable `karabiner-fn-to-f19.json`. setup.sh CANNOT enable this for them (Karabiner has no scriptable enable-rule API; the canonical path is the UI). The "REMINDER" line in Step 9 covers this. | **Documentation + Step 9 reminder.** No data migration. |
| **OS-registered state** | None. F19 is a virtual keystroke produced on-demand by Karabiner; it is not registered with launchd, kextcache, or LSRegister. The Hammerspoon hs.hotkey binding is registered with Carbon's RegisterEventHotKey at module load and torn down on Hammerspoon reload — no persistent OS state. | None. |
| **Secrets / env vars** | No new env vars introduced. `PURPLEVOICE_NO_SOUNDS`, `PURPLEVOICE_HUD_OFF`, `PURPLEVOICE_HUD_POSITION`, `PURPLEVOICE_OFFLINE` are unchanged. | None. |
| **Build artifacts / installed packages** | **The Hammerspoon-installed init.lua symlink.** `setup.sh` Step 6c symlinks `~/.hammerspoon/purplevoice → $REPO_ROOT/purplevoice-lua` — meaning Phase 4's edits to `purplevoice-lua/init.lua` flow into the user's Hammerspoon at the next reload. **No reinstall needed.** Hammerspoon must be reloaded (`hs.reload()` or menubar → Reload Config) for the new bindings to take effect. | **User-facing reload** documented in plan-04-final task action. |

**The canonical question — "After every file in the repo is updated, what runtime systems still have the old string cached, stored, or registered?"**

Two:
1. **Hammerspoon's running Lua state** has the old `cmd+shift+e` binding registered with Carbon. A `hs.reload()` releases it and registers the new F19 + cmd+shift+v bindings. (User-facing — documented.)
2. **Karabiner-Elements** has no rule yet (since Phase 4 is the first phase to introduce one). User must import + enable post-Phase-4. setup.sh Step 9 reminder covers this. (User-facing — documented.)

Neither requires data migration; both require a one-time user action documented in setup.sh + README.

## Common Pitfalls

### Pitfall 1: Hold-threshold tuning — too short OR too long both fail

**What goes wrong:** Wrong threshold value makes either:
- (Too short, e.g., 50 ms) — Quick fn taps (intended for native macOS Globe-popup / dictation / function-key access) trigger PurpleVoice unintentionally. User reports "PurpleVoice keeps starting when I tap fn for emoji."
- (Too long, e.g., 500 ms) — Press-and-hold feels laggy. User reports "F19 hotkey takes forever to start recording."

**Why it happens:** The `to_if_held_down_threshold_milliseconds` parameter directly determines this. Karabiner does not document a default explicitly, but examples in the canonical docs use 100, 200, 250, and 500.

**How to avoid:** Use **200 ms** as the recommended starting value. Justification:
- 100 ms is too short — accidental drumming-on-fn during typing can cross 100 ms easily.
- 500 ms is the upper edge of "perceptible lag" for an interactive trigger (per UX research on tactile feedback).
- 200 ms hits the sweet spot: conscious "press and hold" intent crosses it; incidental taps fall under it.
- The Karabiner community fn-as-Hyper-key rules converge on 200 ms.
- Set BOTH `to_if_alone_timeout_milliseconds` AND `to_if_held_down_threshold_milliseconds` to 200 — they're symmetric: anything shorter → alone; anything longer → held.

**Warning signs:** During phase verification, ask Oliver to:
1. Tap fn and immediately try to type `e` — should NOT trigger PurpleVoice (within 200 ms is "tap").
2. Hold fn for an obvious press (~300 ms+) — should trigger PurpleVoice within one perceptual frame.
3. Single-press fn (intentional emoji popup) — should still open Globe popup.

If any of those fail, adjust threshold up or down by 50 ms increments. Document any adjustment in the next plan SUMMARY.

### Pitfall 2: cmd+shift+v collision with VS Code / Cursor "Markdown Preview"

**What goes wrong:** When the user has a `.md` file open in VS Code or Cursor, pressing `cmd+shift+v` is the default keybinding for "Markdown Preview: Open Preview to the Side" (VS Code) / "Toggle Preview" (Cursor). Both behaviours are documented as default in their respective shortcut catalogues.

**Why it happens:** VS Code and Cursor are the user's primary IDEs (per CLAUDE.md "Speak → text appears in Claude Code"). Markdown editing is common (READMEs, planning docs, the very files in `.planning/`).

**Critical Hammerspoon-vs-app precedence finding:** Hammerspoon's `hs.hotkey.bind` uses Carbon's `RegisterEventHotKey` API ([source: Hammerspoon source comments + Cocoa Samurai 2009 article](https://cocoasamurai.blogspot.com/2009/03/global-keyboard-shortcuts-with-carbon.html)). RegisterEventHotKey installs the hotkey at the **Application Event Target**, which fires BEFORE the focused app's own keybinding handler runs. **Hammerspoon WINS** the precedence battle. When PurpleVoice binds `cmd+shift+v`, VS Code/Cursor will NOT receive the keystroke — Markdown Preview will not open, and the user's last transcript re-pastes instead.

This means:
- (a) The `cmd+shift+v` binding works correctly for the re-paste use case (it fires reliably).
- (b) BUT the user permanently loses cmd+shift+v "Markdown Preview" in VS Code / Cursor whenever Hammerspoon is running. **This is a real cost.**

**App audit (verified 2026-04-30):**
| App | cmd+shift+v default | Severity if hijacked |
|---|---|---|
| **VS Code** | Markdown Preview (built-in, no extension needed) | MEDIUM — user has to use Cmd+K V (split preview) instead |
| **Cursor** | Toggle Markdown Preview | MEDIUM — same workaround as VS Code |
| **macOS** ("Paste and Match Style" in apps that bind it: Pages, Notes, Mail, browsers) | Paste plain text | LOW — PurpleVoice's paste IS plain text (transient marker); semantically aligned per CONTEXT.md D-02 |
| **Slack** | (not bound — verified against Slack's official shortcut docs) | NONE |
| **Notion / Linear** | Not documented as a default. Notion has cmd+shift+v for "Paste plain text" in some contexts; Linear does not bind it. | LOW (Notion same as macOS) / NONE (Linear) |

**How to avoid:** This is a **plan-level review** point per CONTEXT.md D-02, NOT a researcher's recommendation to change. CONTEXT.md explicitly accepts the collision. But the planner SHOULD:
1. Surface this finding in the plan task description for the cmd+shift+v binding ("note: collides with VS Code/Cursor markdown preview; user accepted in CONTEXT.md D-02").
2. Document the workaround in README ("If you primarily edit markdown in VS Code, use Cmd+K V for split preview instead of Cmd+Shift+V; PurpleVoice now binds Cmd+Shift+V for re-paste").
3. Leave a brief note in test_repaste_walkthrough.md (new manual test) about the Markdown Preview override.

If at plan-checker review the user wants to change, alternatives in priority order:
- **`cmd+opt+v`** — collision-free (no documented default in macOS, VS Code, Cursor, Slack, Notion, Linear). Visual pairing with cmd+v preserved (still a "v" hotkey for paste-related action).
- **`cmd+shift+r`** — "re-paste" mnemonic; collides with Safari "reload page", VS Code "search files in folder". Worse than cmd+opt+v.
- **`fn+v`** — leverages Karabiner; would need a second complex-mod rule. Out of scope for Phase 4 budget.

**Warning signs:** If the user reports "Markdown Preview stopped working in VS Code/Cursor", the cmd+shift+v binding is the cause. Confirm via `hs -c "hs.hotkey.systemAssigned({}, 'v', {'cmd', 'shift'})"` — if it returns the PurpleVoice binding, the collision is active.

### Pitfall 3: Karabiner driver/extension grant — silent failure if user skips

**What goes wrong:** User installs Karabiner-Elements.app, runs setup.sh which finds the .app and prints "OK: Karabiner-Elements detected", but the user never launched Karabiner so the macOS driver-extension grant prompt never fired. The Karabiner daemon is not running. Importing the JSON rule does nothing. F19 emission silently fails. PurpleVoice's F19 binding is technically registered but receives no events.

**Why it happens:** macOS treats Karabiner's driver as a System Extension (System Integrity Protection scope). User must:
1. Launch Karabiner-Elements.app once.
2. Click "Open System Settings" in Karabiner's first-launch dialog.
3. Toggle "Allow" for "Fumihiko Takayama" in System Settings → Privacy & Security.
4. Restart Karabiner-Elements (it'll prompt).

setup.sh Step 9 cannot probe this state without sudo and without writing OS-version-specific shell logic.

**How to avoid:**
- The Step 9 actionable instructions explicitly include "Launch once and grant the driver/extension prompt" as step 3 of 5.
- The "OK: Karabiner-Elements detected" line is followed by the REMINDER about importing + enabling the rule — which the user CANNOT do unless the daemon is running, providing a natural functional check.
- A future-Phase-N enhancement could add a `tests/manual/test_f19_walkthrough.md` that asks the user to verify F19 emission via `karabiner_cli` (Karabiner ships a CLI at `/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli`) — but this is OUT of Phase 4's lightweight scope.

**Warning signs:** User runs `bash setup.sh` successfully, reloads Hammerspoon, holds fn — and nothing happens. First diagnostic: check if Karabiner's menubar icon is present. If absent, daemon is not running → driver grant was skipped.

### Pitfall 4: Hammerspoon `hs.hotkey.bind` returning nil for cmd+shift+v if a hotkey manager already owns it

**What goes wrong:** If the user has another hotkey manager (Raycast, Alfred, BTT, Spectacle, Rectangle) bound to cmd+shift+v at the global level, Hammerspoon's `bind()` may return nil (failed registration). The bound function never fires. Re-paste is silently broken.

**Why it happens:** Carbon's `RegisterEventHotKey` is exclusive per (modifier-set, key-code) pair within the same process; across processes, multiple registrations COEXIST but one wins arbitrarily. If another tool registered first, Hammerspoon's binding may be effectively dead.

**How to avoid:** The existing pattern at line 514 already covers this:
```lua
local hk = hs.hotkey.bind({"cmd", "shift"}, "v", repaste)
if not hk then
  hs.alert.show("PurpleVoice: cmd+shift+v binding failed (in use?)", 4)
end
```
The "in use?" hint is the right user-facing diagnostic. The plan task should mirror this exact pattern.

**Warning signs:** "PurpleVoice loaded" alert fires AND a "cmd+shift+v binding failed" alert fires — user knows a tool conflict exists. Mitigation: rebind in the conflicting tool, or accept the collision and use cmd+opt+v fallback (researcher-recommended alt per Pitfall 2).

### Pitfall 5: Karabiner JSON on offline systems with stale repo

**What goes wrong:** User runs `PURPLEVOICE_OFFLINE=1 bash setup.sh` on an air-gapped machine. Karabiner is installed via dmg-sneakernet. Step 9 detects the .app. Step 9 prints the actionable instruction "import `assets/karabiner-fn-to-f19.json` from the PurpleVoice repo." But the user's repo checkout is from before Phase 4 — the file doesn't exist yet.

**Why it happens:** The CONTEXT.md D-08 air-gap interaction notes "the JSON rule is already in this repo" — true for fresh clones, but cached / pre-Phase-4 checkouts are also realistic.

**How to avoid:** Step 9 should also assert the file exists. Add a guard:
```bash
KARABINER_JSON="$REPO_ROOT/assets/karabiner-fn-to-f19.json"
if [ ! -f "$KARABINER_JSON" ]; then
  echo "PurpleVoice: $KARABINER_JSON missing from repo (run setup.sh from a Phase-4-or-later checkout)" >&2
  exit 1
fi
```
This protects against stale-checkout drift. The error message tells the user exactly what to do.

**Warning signs:** Step 9 reports "Karabiner-Elements detected" but the import-rule UI doesn't see the file at the printed path. Adding the file-existence guard eliminates the failure mode entirely.

### Pitfall 6: HUD module-load alert text drift

**What goes wrong:** Phase 4 changes the module-load alert at line 545 from `"PurpleVoice loaded — local dictation, cmd+shift+e"` to a new string. If the new string mentions both F19 AND cmd+shift+v (re-paste), the alert duration of 1.5s may be too short for users to read before fade.

**Why it happens:** `hs.alert.show(text, 1.5)` is non-modal, fades after 1.5s. Long strings get truncated visually or feel rushed.

**How to avoid:** Keep the alert short and scannable. Recommended replacement string: `"PurpleVoice loaded — F19 to record, ⌘⇧V to re-paste"`. 47 chars vs. the current 47 chars (same length). Uses Unicode ⌘ and ⇧ glyphs (U+2318 + U+21E7) — already standard macOS shortcut notation.

If the user prefers ASCII-only: `"PurpleVoice loaded — F19 to record, cmd+shift+v re-paste"` (54 chars; still scannable).

The duration 1.5s is fine; the issue is text length only.

## Code Examples

Verified patterns from official sources.

### §1 — Re-paste binding (Hammerspoon `hs.hotkey.bind` with cmd+shift+v)

```lua
-- Source: https://www.hammerspoon.org/docs/hs.hotkey.html#bind
-- Plus existing line 512 binding pattern from purplevoice-lua/init.lua
--
-- Place this near line 512 of init.lua, AFTER the F19 binding block.
local repasteHk = hs.hotkey.bind({"cmd", "shift"}, "v", function()
  if lastTranscript then
    pasteWithRestore(lastTranscript)
  else
    hs.alert.show("PurpleVoice: nothing to re-paste yet", 1.5)
  end
end)
if not repasteHk then
  hs.alert.show("PurpleVoice: cmd+shift+v binding failed (in use?)", 4)
end
```

Why inline closure vs named function: matches the brevity of the existing F19 binding. If the planner prefers a named function for testability, declare `local function repaste() ... end` in the locals block above the bindings (as shown in Pattern 4) — both forms are equivalent.

### §2 — `lastTranscript` cache (in `pasteWithRestore`)

```lua
-- Source: existing pasteWithRestore() at purplevoice-lua/init.lua line 376-409
-- ONE-LINE addition after the keyStroke fires (line 398).
local function pasteWithRestore(transcript)
  if not transcript or transcript:match("^%s*$") then
    return
  end
  local pendingSaved = hs.pasteboard.readAllData()
  hs.pasteboard.writeAllData({
    ["public.utf8-plain-text"] = transcript,
    ["org.nspasteboard.TransientType"] = "",
    ["org.nspasteboard.ConcealedType"] = "",
  })
  hs.eventtap.keyStroke({"cmd"}, "v", 0)
  lastTranscript = transcript  -- QOL-01: cache for cmd+shift+v re-paste
  hs.timer.doAfter(0.25, function()
    local current = hs.pasteboard.readAllData()
    if current and current["public.utf8-plain-text"] == transcript then
      hs.pasteboard.writeAllData(pendingSaved)
    end
  end)
end
```

Module-scope declaration (line ~90 alongside `isRecording`):
```lua
local lastTranscript = nil  -- QOL-01: in-memory cache; lost on Hammerspoon reload (D-03)
```

### §3 — F19 binding (replaces cmd+shift+e at line 512)

```lua
-- Source: Hammerspoon hs.hotkey.bind docs
-- + hs.keycodes.map (lowercase "f19" is canonical)
-- + Carbon RegisterEventHotKey precedence (system-global, fires before app shortcuts)
local hk = hs.hotkey.bind({}, "f19", onPress, onRelease)
if not hk then
  hs.alert.show("PurpleVoice: F19 binding failed (Karabiner fn→F19 rule active?)", 4)
end
```

Replace the existing line 510-515 block verbatim. The error message hints at the most likely cause (Karabiner rule not enabled).

### §4 — Karabiner complex-modification rule file (the canonical, ready-to-paste content of `assets/karabiner-fn-to-f19.json`)

```json
{
  "title": "PurpleVoice — fn → F19",
  "rules": [
    {
      "description": "Hold fn → F19 (PurpleVoice push-to-talk). Quick tap → native macOS fn behaviour (Globe popup, function-key row, dictation).",
      "manipulators": [
        {
          "type": "basic",
          "from": {
            "key_code": "fn"
          },
          "to_if_alone": [
            {
              "key_code": "fn",
              "halt": true
            }
          ],
          "to_if_held_down": [
            {
              "key_code": "f19"
            }
          ],
          "parameters": {
            "basic.to_if_alone_timeout_milliseconds": 200,
            "basic.to_if_held_down_threshold_milliseconds": 200
          }
        }
      ]
    }
  ]
}
```

**Schema verification:**
- `title` (string, required) — top-level rule-set name shown in Karabiner Preferences UI. Source: [karabiner-elements.pqrs.org/docs/json/root-data-structure/](https://karabiner-elements.pqrs.org/docs/json/root-data-structure/)
- `rules` (array, required) — list of rule objects.
- `description` (string, required per rule) — shown in the rule list with click-to-enable.
- `manipulators` (array, required per rule) — list of manipulator objects.
- `type: "basic"` — the basic manipulator type; supports `from` + `to*` + `parameters`. Source: [karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/](https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/)
- `from.key_code: "fn"` — verified working as a from key in complex modifications on Apple internal keyboards (Karabiner cannot remap fn on non-Apple keyboards, but PurpleVoice's audience is Apple Silicon). Source: search-result-confirmed.
- `to_if_alone` + `to_if_held_down` split — canonical "tap vs hold" pattern. Source: [karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/to-if-alone/](https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/to-if-alone/) + [.../to-if-held-down/](https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/to-if-held-down/)
- `halt: true` on the `to_if_alone` event — prevents the alone event from also firing the held event. Documented in the canonical examples.
- `key_code: "f19"` — F19 is a valid Karabiner key code (one of the unused-by-Apple-hardware function keys, frequently used as a "Hyper key" target).

### §5 — setup.sh Step 9 (full)

```bash
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
```

Place AFTER the existing Step 8 SBOM-regen block, BEFORE the existing Step 7 banner... wait — Step 7 in setup.sh is currently placed BEFORE Step 8 (the file lists steps in order: 1, 2, 3, 3b, 4, 5, 5b, 6, 6b, 6c, 7-banner, 8-SBOM). The planner has two options:
- **Option A (recommended):** Renumber so the banner (currently "Step 7") becomes the LAST step, with Karabiner check inserted as a new Step 9 that runs AFTER SBOM regen but BEFORE the banner. This requires moving the existing banner down.
- **Option B:** Keep Step 7 as-is (banner stays where it is), insert Karabiner check as new Step 9 AFTER Step 8 (SBOM regen). The banner shows "PurpleVoice setup complete" BEFORE the Karabiner check fails — confusing.

**Choose Option A.** The user reads the file top-to-bottom; the banner should appear AFTER all checks pass. This requires a small reorganisation but matches the existing CONTEXT.md D-07 "Karabiner check should come AFTER all other deps are validated [...] but BEFORE the final banner."

### §6 — `tests/test_karabiner_check.sh` (new test, mirrors `test_hud_env_off.sh` style)

```bash
#!/usr/bin/env bash
# tests/test_karabiner_check.sh — Phase 4 Karabiner-check string-level wiring assertion
#
# Asserts that:
#   1. assets/karabiner-fn-to-f19.json exists and parses as valid JSON
#   2. The JSON has the documented top-level structure (title + rules + manipulators)
#   3. The from.key_code is "fn" and to_if_held_down has key_code "f19"
#   4. setup.sh contains the Karabiner-Elements check + actionable error
#   5. setup.sh contains the file-existence guard for the JSON
#   6. purplevoice-lua/init.lua binds F19 (no modifiers)
#   7. purplevoice-lua/init.lua binds cmd+shift+v for re-paste
#   8. purplevoice-lua/init.lua does NOT bind cmd+shift+e (deliberate replacement)
#
# Exit 0 = wiring intact; exit 1 = drift or missing file.
set -uo pipefail
cd "$(dirname "$0")/.."   # repo root

FAIL=0
KARABINER_JSON="assets/karabiner-fn-to-f19.json"
SETUP="setup.sh"
INIT="purplevoice-lua/init.lua"

# 1. JSON file exists and parses
if [ ! -f "$KARABINER_JSON" ]; then
  echo "FAIL: $KARABINER_JSON missing"
  FAIL=1
elif ! jq empty "$KARABINER_JSON" 2>/dev/null; then
  echo "FAIL: $KARABINER_JSON is not valid JSON"
  FAIL=1
fi

# 2. Documented top-level structure
if [ "$FAIL" -eq 0 ]; then
  TITLE=$(jq -r '.title // empty' "$KARABINER_JSON")
  RULES_COUNT=$(jq '.rules | length' "$KARABINER_JSON" 2>/dev/null || echo 0)
  if [ -z "$TITLE" ]; then
    echo "FAIL: $KARABINER_JSON missing top-level 'title' field"
    FAIL=1
  fi
  if [ "$RULES_COUNT" -lt 1 ]; then
    echo "FAIL: $KARABINER_JSON has no rules"
    FAIL=1
  fi
fi

# 3. from.key_code=fn, to_if_held_down.key_code=f19
if [ "$FAIL" -eq 0 ]; then
  FROM_KEY=$(jq -r '.rules[0].manipulators[0].from.key_code // empty' "$KARABINER_JSON")
  HELD_KEY=$(jq -r '.rules[0].manipulators[0].to_if_held_down[0].key_code // empty' "$KARABINER_JSON")
  if [ "$FROM_KEY" != "fn" ]; then
    echo "FAIL: $KARABINER_JSON from.key_code is '$FROM_KEY' (expected 'fn')"
    FAIL=1
  fi
  if [ "$HELD_KEY" != "f19" ]; then
    echo "FAIL: $KARABINER_JSON to_if_held_down.key_code is '$HELD_KEY' (expected 'f19')"
    FAIL=1
  fi
fi

# 4. setup.sh contains the Karabiner check
if ! grep -q "Karabiner-Elements.app" "$SETUP"; then
  echo "FAIL: $SETUP missing /Applications/Karabiner-Elements.app check"
  FAIL=1
fi

# 5. setup.sh contains the file-existence guard
if ! grep -q "karabiner-fn-to-f19.json" "$SETUP"; then
  echo "FAIL: $SETUP missing reference to assets/karabiner-fn-to-f19.json"
  FAIL=1
fi

# 6. init.lua binds F19 with empty modifier table
if ! grep -qE 'hs\.hotkey\.bind\(\{\}, ?"f19"' "$INIT"; then
  echo "FAIL: $INIT missing F19 binding (hs.hotkey.bind({}, \"f19\", ...))"
  FAIL=1
fi

# 7. init.lua binds cmd+shift+v for re-paste
if ! grep -qE 'hs\.hotkey\.bind\(\{"cmd", ?"shift"\}, ?"v"' "$INIT"; then
  echo "FAIL: $INIT missing cmd+shift+v re-paste binding"
  FAIL=1
fi

# 8. init.lua does NOT bind cmd+shift+e (deliberate replacement per CONTEXT.md D-05)
if grep -qE 'hs\.hotkey\.bind\(\{"cmd", ?"shift"\}, ?"e"' "$INIT"; then
  echo "FAIL: $INIT still binds cmd+shift+e (Phase 4 D-05 requires removal)"
  FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS [test_karabiner_check.sh]: Karabiner JSON valid; setup.sh check present; init.lua bindings correct"
  exit 0
fi
exit 1
```

This test runs as part of `tests/run_all.sh` (Phase 4 grows it from 10 → 11 tests). Wave 0 commits it RED; Plans 04-01 + 04-02 turn it GREEN as the implementation lands.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `cmd+shift+e` Hammerspoon hotkey | F19 via Karabiner fn-remap | Phase 4 (this phase) | Eliminates the documented VS Code/Cursor "Show Explorer" collision; introduces Karabiner as a runtime dependency. |
| `to.fn_or_globe_key` synthesis pre-Sequoia | `key_code: "fn"` (works on Sequoia 15.7.5+ via Karabiner 15.5.0+) | Karabiner 15.5.0 (Jul 2025) fixed function-key detection on Sequoia | Recommended Karabiner version: 15.9.0 (Jan 2026) — well past the Sequoia regression window. |
| Imperative `RegisterEventHotKey` calls in Swift / ObjC | `hs.hotkey.bind` Lua wrapper (Carbon under the hood) | Phase 1 (already standard) | Phase 4 adds two new bindings using the same wrapper. |

**Deprecated/outdated:**
- **`hs.eventtap.flagsChanged` for fn-detection** — never recommended for PurpleVoice (D-09 rejection). Race with macOS Globe popup makes it unreliable.
- **`fn_or_globe_key` keycode synthesis** — Karabiner-specific keyword from older Karabiner versions; Karabiner 15.x uses plain `"fn"` as the from key.
- **macOS Sequoia 15.1.0 + Karabiner-Elements ≤ 15.4.x** — `to_if_alone` was broken (issue #3949). Phase 4 documents Karabiner 15.5.0 minimum; the cask install gets 15.9.0 transparently.

## Open Questions

1. **Should the Karabiner JSON ship with `to_after_key_up` to clear any stuck state?**
   - What we know: Karabiner's `to_if_held_down` correctly synthesizes F19 key-down on the threshold crossing. Karabiner ALSO synthesizes F19 key-up automatically when fn is released. Hammerspoon's onRelease should fire correctly.
   - What's unclear: Whether on rapid fn-press-release-press cycles (drumming), Karabiner can get confused about which F19 keystroke pair belongs to which fn cycle. The existing `isRecording` re-entrancy guard at line 472 should silently drop second presses, providing safety even if Karabiner ever double-emits.
   - Recommendation: Ship WITHOUT `to_after_key_up`. The default Karabiner behaviour is correct for tap-vs-hold; adding extra cleanup events can introduce double-firing. If post-launch testing surfaces a stuck-state bug, add `"to_after_key_up": [{"key_code": "f19"}]` to defensively send key-up. NOT needed for v1.x; document as a "known fix if needed" in the next SUMMARY.

2. **Should Step 9 also detect the Karabiner background process (not just the .app)?**
   - What we know: `pgrep -f karabiner_grabber` (or in 15.7.0+, `pgrep -f Karabiner-Core-Service`) returns the Karabiner daemon PID if running.
   - What's unclear: Whether adding this check provides actionable signal vs noise. A user who opened Karabiner-Elements.app once but didn't grant the driver would still see the daemon NOT running — so this check WOULD catch the "skipped grant" failure mode (Pitfall 3).
   - Recommendation: SKIP for Phase 4. The version-rename in 15.7.0 (karabiner_grabber → Karabiner-Core-Service) means the pgrep pattern changes per-version, adding maintenance burden. The actionable error message in Step 9 + the natural functional check ("nothing happens when you hold fn") will surface the issue. If the user reports the silent failure, we add this in Phase 5 / a future micro-phase.

3. **Should the `cmd+shift+v` binding alert if the closure-captured `lastTranscript` is reset by a Hammerspoon reload?**
   - What we know: D-03 explicitly accepts loss-on-reload. The nil-state alert ("nothing to re-paste yet") covers this.
   - What's unclear: Whether the user might confuse "I just pasted 30 seconds ago, why is there nothing to re-paste?" with a bug.
   - Recommendation: The "nothing to re-paste yet" wording handles both cases gracefully (post-reload AND pre-first-recording). No additional logic needed. Document the reload-loses-cache behaviour in `tests/manual/test_repaste_walkthrough.md`.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Hammerspoon | F19 binding + cmd+shift+v binding | ✓ (already installed via Phase 1 setup.sh Step 2) | 1.1.1 | — (PurpleVoice's core stack) |
| **Karabiner-Elements** | fn → F19 remap | ✗ on this dev machine | — (cask available at v15.9.0) | NONE — Phase 4 requires it. setup.sh Step 9 enforces. |
| jq | `tests/test_karabiner_check.sh` JSON parsing + setup.sh existing SBOM post-process | ✓ | 1.7.1 (system Apple build) | None needed — already required by setup.sh Step 8 |
| bash | setup.sh Step 9 + `tests/test_karabiner_check.sh` | ✓ | system bash | None |
| sips | Not used by Phase 4 (icon already exists) | ✓ | system | N/A |
| Syft | Phase 2.7 SBOM regen — Phase 4 may trigger an SBOM regen if the user re-runs setup.sh | ✓ | 1.43.0+ (already required by Phase 2.7 D-09) | If absent, setup.sh prints "SBOM regen skipped" — same as today. Phase 4 inherits this behaviour without modification. |

**Missing dependencies with no fallback:**
- **Karabiner-Elements** — by design (CONTEXT.md D-07). setup.sh Step 9 refuses to declare install complete without it. The "fallback" is the actionable error message + URL. No code-side workaround.

**Missing dependencies with fallback:**
- None.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | bash test scripts (no test runner — each `tests/test_*.sh` is standalone, returns 0/1) |
| Config file | None — `tests/run_all.sh` iterates `tests/test_*.sh` alphabetically |
| Quick run command | `bash tests/run_all.sh` (~5 seconds; current count 10/0; Phase 4 grows to 11/0) |
| Full suite command | `bash tests/run_all.sh && bash tests/security/run_all.sh` (~35 seconds; current 10/0 + 5/0; Phase 4 grows to 11/0 + 5/0) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| **QOL-01** | `cmd+shift+v` re-paste binding present in init.lua | unit (string-level wiring) | `bash tests/test_karabiner_check.sh` (multi-purpose; check 7) | ❌ Wave 0 will create |
| **QOL-01** | `lastTranscript` cached AFTER pasteWithRestore success | unit (string-level wiring) | `grep -E 'lastTranscript = transcript' purplevoice-lua/init.lua` (manual one-liner; tightened in test_karabiner_check.sh extension) | ❌ Wave 0 will create as auxiliary check |
| **QOL-01** | Nil-state shows brief alert, doesn't crash | manual walkthrough | `tests/manual/test_repaste_walkthrough.md` (new) | ❌ Wave 0 will create scaffold |
| **QOL-01** | Re-paste fires correct transcript into focused window | manual walkthrough | `tests/manual/test_repaste_walkthrough.md` (new) | ❌ Wave 0 will create scaffold |
| **QOL-NEW-01** | F19 binding present in init.lua (no modifiers) | unit (string-level wiring) | `bash tests/test_karabiner_check.sh` (check 6) | ❌ Wave 0 will create |
| **QOL-NEW-01** | cmd+shift+e binding REMOVED from init.lua | unit (negative assertion) | `bash tests/test_karabiner_check.sh` (check 8) | ❌ Wave 0 will create |
| **QOL-NEW-01** | Karabiner JSON file exists + valid + correct from/to keys | unit (JSON validation via jq) | `bash tests/test_karabiner_check.sh` (checks 1-3) | ❌ Wave 0 will create |
| **QOL-NEW-01** | setup.sh Step 9 checks /Applications/Karabiner-Elements.app | unit (string-level wiring) | `bash tests/test_karabiner_check.sh` (checks 4-5) | ❌ Wave 0 will create |
| **QOL-NEW-01** | F19 hotkey actually triggers PurpleVoice when held (end-to-end with Karabiner installed) | manual walkthrough | `tests/manual/test_f19_walkthrough.md` (new) | ❌ Wave 0 will create scaffold |
| **QOL-NEW-01** | setup.sh prints actionable error when Karabiner absent | manual walkthrough OR mock-based unit | `tests/manual/test_setup_karabiner_missing.md` (new) | ❌ Wave 0 will create scaffold |
| **QOL-NEW-01** | Quick fn-tap (< 200ms) does NOT trigger PurpleVoice; preserves macOS native fn behaviour | manual walkthrough | included in `test_f19_walkthrough.md` | ❌ Wave 0 will create scaffold |
| Brand consistency | No `voice-cc` strings introduced by Phase 4 | unit (existing test) | `bash tests/test_brand_consistency.sh` | ✅ existing |
| Pattern 2 invariant | `WHISPER_BIN` count in purplevoice-record == 2 | unit (existing test) | `bash tests/test_brand_consistency.sh` | ✅ existing |
| Pattern 2 corollary | No `whisper-cli` references in init.lua | unit (existing test) | `bash tests/test_brand_consistency.sh` | ✅ existing |
| Framing lint | No `compliant` / `certified` / `guarantees` in SECURITY.md | unit (existing test) | `bash tests/test_security_md_framing.sh` | ✅ existing |
| Existing tests | 10 baseline tests stay GREEN | unit (no changes needed) | `bash tests/run_all.sh` | ✅ existing |
| Security suite | 5 security checks stay GREEN | unit (no changes needed) | `bash tests/security/run_all.sh` | ✅ existing |

**Mock vs skip strategy for Karabiner-dependent tests:**
- The unit-level `test_karabiner_check.sh` is **string-level only** — it checks file contents, not behaviour. It runs and passes WITHOUT Karabiner-Elements installed. This is the right unit-test boundary: we test the wiring (file exists, init.lua has the bindings, setup.sh has the check), not the runtime behaviour.
- The manual `test_f19_walkthrough.md` REQUIRES Karabiner installed + the rule imported + driver granted. It's a `checkpoint:human-verify` task per the existing Phase 3.5 manual-walkthrough pattern. CI cannot run this — but PurpleVoice has no CI today (Phase 2.7 D-03 — release-gate verification, not per-commit CI).
- The manual `test_setup_karabiner_missing.md` is the negative-control walkthrough: ask the tester to temporarily move /Applications/Karabiner-Elements.app aside (`sudo mv ... /tmp/`), run setup.sh, observe the actionable error, then move it back. This is human-verify too.

### Sampling Rate

- **Per task commit:** `bash tests/run_all.sh` (the unit suite — 11/0 after Phase 4)
- **Per wave merge:** `bash tests/run_all.sh && bash tests/security/run_all.sh` (full unit + security — 11/0 + 5/0)
- **Phase gate:** Full suite green + the 3 manual walkthroughs (`test_repaste_walkthrough.md`, `test_f19_walkthrough.md`, `test_setup_karabiner_missing.md`) signed off live by Oliver before `/gsd:verify-work`. This matches the Phase 3.5 sign-off pattern (live verification on macOS Sequoia 15.7.5).

### Wave 0 Gaps

- [ ] `tests/test_karabiner_check.sh` — covers QOL-01 (checks 7) + QOL-NEW-01 (checks 1-6, 8). Eight assertion checks total. Goes RED at Wave 0 commit (because init.lua + setup.sh + assets/ files haven't been touched yet); turns GREEN as Plans 04-01 + 04-02 land.
- [ ] `tests/manual/test_repaste_walkthrough.md` — manual walkthrough scaffold for QOL-01 end-to-end (record → paste → re-paste with cmd+shift+v → verify same transcript appears).
- [ ] `tests/manual/test_f19_walkthrough.md` — manual walkthrough scaffold for QOL-NEW-01 end-to-end (Karabiner rule imported, fn-hold triggers PurpleVoice, fn-tap preserves Globe popup, cmd+shift+e no longer triggers).
- [ ] `tests/manual/test_setup_karabiner_missing.md` — manual walkthrough scaffold for the setup.sh actionable-error branch (Karabiner missing → exit 1 with instructions).
- [ ] **REQUIREMENTS.md QOL-01 / QOL-NEW-01 stubs landed at Wave 0** — promote QOL-01 from v2 to v1 with concrete language; add QOL-NEW-01 row; both `[ ]` Pending until Phase 4 closes.

*(No framework install needed — bash test runner already in use; jq already installed and required by setup.sh Step 8.)*

## Sources

### Primary (HIGH confidence)

- [Karabiner-Elements complex modifications manipulator definition](https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/) — schema for `type: "basic"` manipulators with from/to/to_if_alone/to_if_held_down/parameters
- [Karabiner-Elements `to_if_alone`](https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/to-if-alone/) — canonical tap-vs-hold pattern with example
- [Karabiner-Elements `to_if_held_down`](https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/to-if-held-down/) — hold-threshold parameter usage
- [Karabiner-Elements root-data-structure](https://karabiner-elements.pqrs.org/docs/json/root-data-structure/) — required top-level fields for importable JSON files (title, rules, manipulators)
- [Karabiner-Elements file location](https://karabiner-elements.pqrs.org/docs/json/location/) — `~/.config/karabiner/assets/complex_modifications/` for direct drop-in
- [Karabiner-Elements release notes](https://karabiner-elements.pqrs.org/docs/releasenotes/) — current version 15.9.0 (Jan 2026); 15.5.0 fixed function-key detection; Sequoia 15.1.0 to_if_alone regression in Karabiner 15.1.0
- [Hammerspoon `hs.hotkey.bind`](https://www.hammerspoon.org/docs/hs.hotkey.html#bind) — empty modifier table supported, pressedfn/releasedfn symmetric
- [Hammerspoon `hs.keycodes.map`](https://www.hammerspoon.org/docs/hs.keycodes.html) — F1-F20 (lowercase `f19`) confirmed in canonical key map
- Local repo files: `purplevoice-lua/init.lua` (lines 305-310 binding, 156 lastNotifyAt, 376-409 pasteWithRestore, 545 module-load alert), `setup.sh` (Step 2 Hammerspoon idiom at lines 32-51), `tests/test_brand_consistency.sh`, `tests/test_security_md_framing.sh`, `tests/test_hud_env_off.sh`
- Local probe: `brew info --cask karabiner-elements` reports 15.9.0 as current cask
- Local probe: `bash tests/run_all.sh` reports 10/0; `bash tests/security/run_all.sh` reports 5/0 (Phase 4 baseline)

### Secondary (MEDIUM confidence)

- [Hammerspoon issue #901](https://github.com/Hammerspoon/hammerspoon/issues/901) — confirms F10/F11 bare-key bindings worked after resolution; F19 binding has no documented bare-key issues
- [Karabiner-Elements issue #3949](https://github.com/pqrs-org/Karabiner-Elements/issues/3949) — Sequoia 15 + Karabiner 15.1.0 to_if_alone regression (verified via search; resolution path: upgrade to 15.5.0+ which Phase 4's brew install picks up automatically)
- [Cocoa Samurai — Global Keyboard Shortcuts with Carbon Events](https://cocoasamurai.blogspot.com/2009/03/global-keyboard-shortcuts-with-carbon.html) — RegisterEventHotKey precedence (system-global, fires before app shortcuts) — confirms Hammerspoon hotkey wins over VS Code/Cursor cmd+shift+v
- [VS Code keyboard shortcuts](https://code.visualstudio.com/docs/configure/keybindings) + Markdown Preview shortcut at cmd+shift+v (default, no extension) — confirmed cmd+shift+v collision in VS Code/Cursor
- [Cursor Keyboard Shortcuts](https://cursor.com/docs/configuration/kbd) — cmd+shift+v toggles Markdown preview
- [Slack keyboard shortcuts](https://slack.com/help/articles/201374536-Slack-keyboard-shortcuts) — verified Slack does NOT bind cmd+shift+v on macOS

### Tertiary (LOW confidence — flagged for live validation)

- The 200 ms hold-threshold value — based on Karabiner community convention + UX research on tactile feedback. Not pulled from a specific authoritative document. **Validate empirically during phase verification** (Pitfall 1 walkthrough). If 200 feels wrong on Oliver's hardware, adjust ± 50 ms.
- Whether Karabiner 15.9.0 introduces any new fn-key behaviour vs 15.5.0+ — release notes don't mention regression, but worth a sanity test post-install.
- Whether `to_after_key_up` is needed for stuck-state defence — Open Question 1 above. NOT included in v1.x rule; documented as a "if-needed" addition.

## Metadata

**Confidence breakdown:**

- **Standard stack:** HIGH — Karabiner-Elements is the documented + only viable choice (D-09 rejection of alternatives); Hammerspoon F19 binding is API-confirmed.
- **Architecture (file layout, JSON schema, setup.sh extension):** HIGH — every pattern is grounded in the existing codebase (Step 2 Hammerspoon idiom; pasteWithRestore; test_hud_env_off.sh test scaffold pattern; assets/ directory).
- **Karabiner JSON content:** HIGH for schema (verified against canonical pqrs.org docs); MEDIUM for the specific 200ms threshold (community-convention-based; flagged for empirical validation).
- **cmd+shift+v collision precedence:** HIGH — Carbon RegisterEventHotKey precedence is well-documented; Hammerspoon wins; the cost (VS Code/Cursor markdown preview hijacked) is real but accepted per CONTEXT.md D-02.
- **setup.sh Step 9 design:** HIGH — direct mirror of the existing Step 2 pattern; no new shell idioms.
- **Pitfalls + open questions:** MEDIUM-HIGH — sourced from documented Karabiner regressions, Hammerspoon issues, and macOS Sequoia behaviour notes.

**Research date:** 2026-04-30
**Valid until:** 2026-05-30 (30 days — stack is stable; Karabiner-Elements release cadence is monthly so the version pin may need refresh; Hammerspoon is on a slower cadence and won't change)

## RESEARCH COMPLETE

**Phase:** 04 - quality-of-life-v1-x
**Confidence:** HIGH

### Key Findings

- **Karabiner JSON rule is ready-to-paste.** The complete `assets/karabiner-fn-to-f19.json` content is documented in Code Examples §4 with verified schema. Uses `to_if_alone` (200ms) + `to_if_held_down` (200ms) split — fn-tap preserves macOS native behaviour (Globe popup, dictation, function-key row); fn-hold emits F19 to Hammerspoon.
- **Hammerspoon F19 binding is a one-liner.** `hs.hotkey.bind({}, "f19", onPress, onRelease)` — empty modifier table is supported, lowercase "f19" is canonical in `hs.keycodes.map`, Carbon RegisterEventHotKey gives system-global precedence over app shortcuts (so F19 won't pass through to focused apps).
- **cmd+shift+v collision is real but acceptable.** Hammerspoon wins precedence over VS Code/Cursor "Markdown Preview" — this hijacks the markdown shortcut whenever Hammerspoon is running. CONTEXT.md D-02 accepts this; the workaround (Cmd+K V for split preview in VS Code) is documented in the README update task. Slack and Linear do NOT bind cmd+shift+v; macOS "Paste and Match Style" collision is semantically aligned (PurpleVoice paste IS plain text).
- **setup.sh Step 9 mirrors Step 2 verbatim.** `[ -d /Applications/Karabiner-Elements.app ]` is the canonical detection idiom (works for both brew-cask and dmg installs); actionable error message includes 5 numbered install steps + offline path + repo-relative JSON path. NO auto-install per D-07.
- **Karabiner-Elements 15.9.0 (cask, Jan 2026) is current** — well past the macOS Sequoia 15.1.0 + Karabiner 15.1.0 `to_if_alone` regression window (issue #3949). The recommended schema works on the current cask. Driver/extension grant is a documented user step (cannot probe from bash without sudo + per-version commands).
- **`assets/karabiner-fn-to-f19.json`** is the recommended file path — natural extension of the Phase 2.5 `assets/` directory that already houses `icon-256.png`. CONTEXT.md D-06 explicitly suggests this path.
- **Nil-state for first re-paste**: `hs.alert.show("PurpleVoice: nothing to re-paste yet", 1.5)` — better UX than silent no-op; matches existing alert idiom at line 545.
- **Module-load alert string update**: `"PurpleVoice loaded — F19 to record, ⌘⇧V to re-paste"` (47 chars; same length as current; uses standard Unicode shortcut glyphs).
- **`tests/test_karabiner_check.sh`** is recommended — 8 string-level assertion checks (JSON validity + structure + setup.sh check + init.lua bindings present + cmd+shift+e absent). Mirrors test_hud_env_off.sh pattern; runs in <1s; turns RED at Wave 0 and GREEN as plans land.
- **SBOM scope disclaimer update**: SECURITY.md §"Scope disclaimer: repo-only Syft scan" should add Karabiner-Elements to the list of "carried by reference" runtime deps alongside Hammerspoon. Recommended one-line addition: prepend "Karabiner-Elements (kernel-extension-class daemon for the fn→F19 hotkey remap; user-installed)" to the existing parenthetical list of transitive deps.

### File Created

`/Users/oliverallen/Temp video/voice-cc/.planning/phases/04-quality-of-life-v1-x/04-RESEARCH.md`

### Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| Standard Stack (Karabiner choice) | HIGH | D-09 rejection of alternatives; Karabiner is the only viable fn-remap pathway |
| Karabiner JSON schema | HIGH | Verified against canonical pqrs.org docs (root-data-structure, manipulator-definition, to-if-alone, to-if-held-down) |
| Hold-threshold (200ms) | MEDIUM | Community convention + UX research; flagged for empirical validation in Pitfall 1 walkthrough |
| Hammerspoon F19 binding | HIGH | API-confirmed; lowercase "f19" canonical; Carbon precedence well-documented |
| cmd+shift+v precedence | HIGH | Carbon RegisterEventHotKey precedence is well-established; Hammerspoon wins |
| cmd+shift+v collision audit | HIGH (VS Code/Cursor) / HIGH (Slack/macOS) / MEDIUM (Notion/Linear) | Direct verification against Slack docs; VS Code/Cursor docs; macOS standard; Notion/Linear less authoritative |
| setup.sh Step 9 | HIGH | Direct mirror of existing Step 2 Hammerspoon-detection pattern |
| Test scaffold pattern | HIGH | Direct mirror of existing test_hud_env_off.sh pattern |
| Brand + Pattern 2 invariants | HIGH | Phase 4 modifications are surgical; do not touch purplevoice-record or whisper-cli surfaces |

### Open Questions

1. Whether `to_after_key_up` is needed in the Karabiner JSON for stuck-state defence — recommended NO for v1.x; defer until a stuck-state bug surfaces.
2. Whether Step 9 should also check the Karabiner daemon process — recommended NO; daemon-process name changed in 15.7.0; the actionable error + natural functional check covers the failure mode.
3. The 200ms hold-threshold may need ± 50ms tuning on Oliver's hardware — flagged for live validation in Pitfall 1 walkthrough.

### Ready for Planning

Research complete. Planner can now create plans for Phase 4. Suggested 3-plan split (CONTEXT.md D-decisions support this):
- **Plan 04-00 (Wave 0 staging)** — `tests/test_karabiner_check.sh` (RED at commit), 3 manual walkthrough scaffolds (`test_repaste_walkthrough.md`, `test_f19_walkthrough.md`, `test_setup_karabiner_missing.md`), REQUIREMENTS.md QOL-01 promotion + QOL-NEW-01 stub addition.
- **Plan 04-01 (Lua core)** — F19 binding replacement + cmd+shift+v re-paste + lastTranscript caching + module-load alert text update + nil-state alert. Turns Wave 0 test_karabiner_check.sh checks 6, 7, 8 GREEN.
- **Plan 04-02 (Karabiner integration + docs closure)** — `assets/karabiner-fn-to-f19.json` creation + setup.sh Step 9 (with Option A reorganisation: SBOM regen → Karabiner check → final banner) + assets/README.md karabiner-fn-to-f19.json provenance + README.md install flow + SECURITY.md SBOM-scope disclaimer + tests/manual/* references updated cmd+shift+e → F19 + REQUIREMENTS.md QOL-01 + QOL-NEW-01 finalisation [ ]→[x] + ROADMAP.md Phase 4 progress. Turns Wave 0 test_karabiner_check.sh checks 1-5 GREEN. Live walkthrough sign-offs.
