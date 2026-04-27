# Pitfalls Research

**Domain:** Local push-to-talk dictation tool for macOS Apple Silicon (Hammerspoon → bash → sox → whisper.cpp → clipboard paste into Claude Code).
**Researched:** 2026-04-23
**Confidence:** HIGH on TCC/permission flow (cross-verified across Apple docs, hacktricks, multiple GitHub issues, Hammerspoon FAQ). HIGH on whisper.cpp short-clip + silence behaviour (multiple GitHub issues + academic paper). HIGH on Hammerspoon `hs.task` PATH and re-entrancy (confirmed in upstream issues #644, #1963, #2275, #3016). MEDIUM on clipboard-manager interception specifics (depends on which manager is installed; pattern is well-attested across 1Password, Raycast, Maccy, Alfred but exact behaviour varies).

---

## Reading Order

This file is structured in three layers:

1. **The TCC Permission Flow** — A standalone primer because permissions are the #1 "works for the developer, breaks for the user" trap and the model is non-obvious. Read this first.
2. **Critical Pitfalls** — Issues that will silently break the product or leak data. Numbered 1–10. Each has warning signs, prevention, phase mapping, severity, and (where available) a concrete code/config snippet.
3. **Supporting Tables** — Technical Debt, Performance Traps, Security Mistakes, UX Pitfalls, "Looks Done But Isn't" checklist, Recovery Strategies, and Pitfall-to-Phase Mapping.

---

## The TCC Permission Flow (Primer)

The single biggest source of "it works for me, breaks for them" is misunderstanding which process needs which permission. The summary is short, but every word matters.

### Rule 1: TCC attributes permissions to the *responsible process*, not the binary actually performing the access.

When Hammerspoon spawns `bash`, which spawns `sox`, the macOS kernel/audio stack walks up the parent chain to find the "responsible" process — the one with a code signature and bundle identifier. For our architecture, that's **Hammerspoon.app**.

This means:

- `sox` does **not** need Microphone permission. Hammerspoon does.
- `whisper-cli` needs no special permission (no protected resource).
- `bash` needs no special permission.
- The `cmd+v` paste keystroke is performed by Hammerspoon via `hs.eventtap.keyStroke`, so **Hammerspoon needs Accessibility permission** for the paste to work.

### Rule 2: First-time mic access from `sox` triggers a TCC prompt — but the prompt is for *Hammerspoon*, not for `sox`.

The user will see: *"Hammerspoon would like to access the microphone."*

This confuses users who think they're installing "voice-cc" — there is no voice-cc.app, just Hammerspoon and a script. The README must explicitly say: *"You will be prompted to grant Microphone access to Hammerspoon. This is voice-cc — Hammerspoon is the host process."*

### Rule 3: TCC silent-deny is the failure mode you must instrument for.

If the user accidentally clicks "Don't Allow" on the prompt — or if Hammerspoon's code signature is invalidated by an update — TCC denies *silently*. `sox` exits non-zero with `coreaudio: AudioObjectGetPropertyData ...` on stderr. No prompt re-appears. No system notification. Just empty WAVs forever.

The bash glue **must** detect this exit pattern and translate it into a `hs.notify` toast with a deep link to System Settings.

### Rule 4: "Run from a terminal" testing produces misleading results.

If you test the bash glue by running `voice-cc-record` from your terminal, the responsible process is **the terminal**, not Hammerspoon. The terminal needs its own Microphone grant. **The dev workflow's permission state is unrelated to the production workflow's permission state.** Always test the full Hammerspoon-spawned path before declaring victory.

Worse: **VS Code / Cursor / Claude Code's *integrated* terminal silently fails the TCC prompt** — the integrated terminal is a child of the editor, the editor doesn't have the right Info.plist entitlements, prompt never appears. Confirmed in [pingdotgg/t3code#728](https://github.com/pingdotgg/t3code/issues/728) and Apple developer forums. Tell the user: when developing/testing voice-cc-record manually, use **Terminal.app or iTerm2.app**, not an editor's integrated terminal.

### Rule 5: Permission grants are tied to the binary's code signature and version.

When Hammerspoon updates (Sparkle auto-update or `brew upgrade --cask hammerspoon`), TCC may consider it "a different app" and require re-granting. This is rare with signed apps but documented. The Hammerspoon FAQ describes an "accessibility appears enabled but isn't" failure mode that requires removing Hammerspoon from the list and re-adding.

### The complete permission table

| Permission | Granted to | Triggers when | Failure mode | Recovery |
|---|---|---|---|---|
| **Microphone** | `org.hammerspoon.Hammerspoon` (the bundle ID, *not* sox or bash) | First time `sox -d` is invoked from `hs.task` | sox exits ~1, stderr contains `AudioObjectGetPropertyData` or `Permission denied` | `tccutil reset Microphone org.hammerspoon.Hammerspoon` then re-trigger |
| **Accessibility** | `org.hammerspoon.Hammerspoon` | First time `hs.eventtap.keyStroke` or `hs.hotkey.bind` is invoked. Hammerspoon prompts on launch if not granted. | `cmd+v` silently no-ops; clipboard has correct text but nothing pastes | System Settings → Privacy & Security → Accessibility → toggle Hammerspoon off and on |
| **Input Monitoring** | `org.hammerspoon.Hammerspoon` (only required for some `hs.eventtap` usage patterns) | When using `hs.eventtap.new()` to *observe* keystrokes (not `hs.hotkey.bind` for hotkeys) | Hotkey may stop firing; eventtap callbacks silent | Settings → Privacy & Security → Input Monitoring → toggle Hammerspoon |
| Automation/AppleScript | not required for v1 | If we ever add `hs.osascript` for app control | osascript prompt | grant per-target-app |
| Full Disk Access | not required | n/a | n/a | n/a |

For v1 you need: **Microphone + Accessibility for Hammerspoon.** That's it.

### Verification one-liner

To check TCC state without granting/denying:

```bash
# Microphone permission status for Hammerspoon
sqlite3 "$HOME/Library/Application Support/com.apple.TCC/TCC.db" \
  "SELECT client, auth_value, datetime(last_modified, 'unixepoch') FROM access WHERE service='kTCCServiceMicrophone' AND client LIKE '%hammerspoon%';" 2>/dev/null
# auth_value: 0=denied, 2=allowed, 3=allowed-via-prompt, 4=limited
```

(Read-only access to TCC.db works without SIP exemption; *modifying* requires the system one in `/Library/...` and Full Disk Access. Reading the user one in `~/Library/...` is fine.)

---

## Critical Pitfalls

### Pitfall 1: Mic permission attributed to the wrong process

**What goes wrong:**
Bash glue is tested by running `~/.local/bin/voice-cc-record` directly from a terminal. It works perfectly. The Hammerspoon hotkey is wired up. On hotkey press, sox produces a 0-byte WAV and the bash glue exits cleanly with no transcript. No errors visible. Repeats forever.

**Why it happens:**
When invoked from the terminal, **Terminal.app** is the responsible process and Terminal already has Mic permission granted. When invoked from `hs.task`, **Hammerspoon.app** is the responsible process and Hammerspoon does *not* have Mic permission yet — the prompt was never triggered because Hammerspoon's first child to request mic was sox-via-bash, not Hammerspoon itself. macOS may or may not surface the prompt depending on whether Hammerspoon's Info.plist declares `NSMicrophoneUsageDescription` (it does, since 1.0.0). When the prompt is suppressed (denied earlier, or another invisible TCC interaction) sox just exits non-zero and bash sees stderr full of CoreAudio errors.

**How to avoid:**
1. **Always test the full path end-to-end before declaring done.** Hotkey → Hammerspoon → bash → sox. Never trust "I ran the script and it worked."
2. **Probe permission explicitly at install time.** Add to install.sh: a one-line Hammerspoon snippet that calls `hs.task.new(...)` to invoke a `sox -d -n trim 0 0.1 2>&1` (record to /dev/null for 100 ms) — this triggers the prompt at the *right* moment, with the right responsible process, with the user clearly knowing why they're being asked.
3. **Detect TCC silent-deny in bash glue** and emit exit code 10 → toast with link to System Settings:

```bash
# In voice-cc-record, after sox completes:
if [ $SOX_EXIT -ne 0 ]; then
  if grep -qE 'Permission denied|AudioObject(GetPropertyData|SetPropertyData)|kAudio.*Error' \
       "$HOME/.cache/voice-cc/error.log"; then
    exit 10  # Lua maps to: "Grant Microphone to Hammerspoon" toast + open Settings URL
  fi
  exit 12    # Generic sox failure
fi
```

In Hammerspoon `init.lua`:

```lua
if exitCode == 10 then
  hs.notify.new({
    title = "voice-cc: microphone blocked",
    informativeText = "Grant Hammerspoon access in Privacy & Security",
    actionButtonTitle = "Open Settings",
    hasActionButton = true,
    autoWithdraw = false,
  }):send()
  hs.urlevent.openURL(
    "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
end
```

**Warning signs:**
- WAV files exist but are 0 bytes or contain only silence.
- `~/.cache/voice-cc/error.log` contains `AudioObjectGetPropertyData` errors.
- `tccutil` query shows `auth_value=0` for `org.hammerspoon.Hammerspoon` and `kTCCServiceMicrophone`.

**Phase to address:** Phase 2 (Hardening — TCC failure detection); Phase 3 (Distribution — install.sh permission probe).

**Severity:** **Loud failure if instrumented; silent annoyance if not.** With instrumentation: a clear actionable toast. Without: the product appears to work (recording indicator turns on/off, no errors) but never produces output. This is the single worst failure mode for "I installed it and nothing happens."

---

### Pitfall 2: Hammerspoon `hs.task` doesn't see Homebrew binaries on Apple Silicon

**What goes wrong:**
Bash glue runs `sox` and `whisper-cli` by name (relying on PATH). When invoked from `hs.task`, both fail with `command not found`. Bash exits 127. The user sees a generic "Transcription failed" toast and no diagnostic information.

**Why it happens:**
`hs.task` does **not** spawn through a login shell. The PATH inherited by Hammerspoon at GUI launch typically lacks `/opt/homebrew/bin` (the Apple Silicon Homebrew prefix) — Hammerspoon was historically written when `/usr/local/bin` was the only Homebrew location. Confirmed in [Hammerspoon issue #2275](https://github.com/Hammerspoon/hammerspoon/issues/2275) and [Homebrew discussion #938](https://github.com/orgs/Homebrew/discussions/938). Apps launched from Finder/Dock inherit the very minimal `launchd` PATH (`/usr/bin:/bin:/usr/sbin:/sbin`).

**How to avoid:**
Use **absolute paths** in the bash glue. Don't rely on PATH at all.

```bash
# At top of voice-cc-record, after sourcing config.sh
SOX_BIN="${SOX_BIN:-/opt/homebrew/bin/sox}"
SOXI_BIN="${SOXI_BIN:-/opt/homebrew/bin/soxi}"
WHISPER_BIN="${WHISPER_BIN:-/opt/homebrew/bin/whisper-cli}"

# Sanity check before doing anything else
for bin in "$SOX_BIN" "$SOXI_BIN" "$WHISPER_BIN"; do
  if [ ! -x "$bin" ]; then
    echo "voice-cc: $bin not found or not executable" >> "$HOME/.cache/voice-cc/error.log"
    exit 11
  fi
done
```

Make these overridable in `~/.config/voice-cc/config.sh` so users on Intel Macs (`/usr/local/bin`) or with custom installs can adjust. The defaults should target Apple Silicon Homebrew per STACK.md.

Alternative: in Hammerspoon, set `task:setEnvironment({PATH = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"})` before `:start()`. Less robust than absolute paths because the env-set approach silently masks the *actual* missing-binary case in the future.

**Warning signs:**
- Bash glue exit code 127 ("command not found") when invoked from Hammerspoon, but works when run from terminal.
- `~/.cache/voice-cc/error.log` contains `voice-cc-record: line N: sox: command not found`.
- Works on Intel Macs (`/usr/local/bin` is on Hammerspoon's default PATH) but breaks on Apple Silicon.

**Phase to address:** Phase 1 (Spike — discovered immediately if you use absolute paths from the start); Phase 3 (install.sh validates the binaries exist where expected).

**Severity:** **Loud failure** — the script never produces output. Easy to diagnose if logged; impossible if not.

---

### Pitfall 3: Whisper hallucinates on short clips and silence

**What goes wrong:**
User accidentally taps the hotkey instead of holding it. The 200 ms WAV gets passed to whisper-cli. Whisper produces `"Thank you."`, `"you"`, `"Thanks for watching!"`, `"Subtitles by the Amara.org community"`, or `[BLANK_AUDIO]`. The transcript gets pasted into the focused Claude Code prompt, and the user is confused why their accidental tap inserted "thanks for watching."

**Why it happens:**
Whisper was trained on YouTube subtitles, where end-of-video silence is followed by credits, sponsor cards, and outros. The model learned to generate these tokens when the audio signal is too weak to match anything else. This is the most-cited Whisper failure mode in production — see [whisper.cpp #1724](https://github.com/ggml-org/whisper.cpp/issues/1724), [whisper.cpp #1592](https://github.com/ggml-org/whisper.cpp/issues/1592), [openai/whisper #1873 — share your hallucinations thread](https://github.com/openai/whisper/discussions/1873), and the academic paper [arXiv 2501.11378](https://arxiv.org/html/2501.11378v1).

**How to avoid:**
Belt + braces — three layers, each cheap:

1. **Duration gate (in bash glue)**: if `soxi -D` reports < 0.4 s, abort silently with exit 2. Higher than the 0.25 s in ARCHITECTURE.md because real human dictation is rarely under 400 ms and the false-positive cost (user said "yes" and got nothing) is much lower than the false-negative cost (hallucinated text in their prompt).

2. **Silero VAD flag**: pass `--vad --vad-threshold 0.5` to whisper-cli. Silero is bundled with whisper.cpp v1.8+. This trims silent prefix/suffix internally before inference.

3. **Hallucination denylist post-filter**: a hardcoded list of the top phrases that appear when Whisper hallucinates on noise/silence:

```bash
# ~/.config/voice-cc/denylist.txt — exact-match (case-insensitive, post-trim)
thank you
thank you.
thanks for watching
thanks for watching!
thanks for watching.
subtitles by the amara.org community
[blank_audio]
[silence]
[music]
[applause]
you
you.
yeah
.
```

Apply in bash:

```bash
# After whisper produces TRANSCRIPT
TRIMMED=$(printf "%s" "$TRANSCRIPT" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
while IFS= read -r phrase; do
  CANON=$(printf "%s" "$phrase" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
  if [ "$TRIMMED" = "$CANON" ]; then
    exit 3  # silent abort
  fi
done < "$HOME/.config/voice-cc/denylist.txt"
```

Note: only drop if the *entire* transcript matches a denylist phrase. Don't substring-match — a real prompt like "thank you for adding the dark mode toggle" must pass through.

**Warning signs:**
- "Thank you" or "thanks for watching" pasted after very short hotkey holds.
- Transcripts that are unrelated to what the user said when the user mumbled or coughed.
- Empty/whitespace-only transcripts on quiet clips (handled by the empty-string drop in `transcribe()`).

**Phase to address:** Phase 2 (Hardening). The denylist + VAD flag + duration gate together are <30 minutes of work and prevent the most-embarrassing class of bug.

**Severity:** **Silent annoyance escalating to data corruption.** If the hallucinated text is pasted into a Claude Code prompt and Oliver doesn't notice, Claude wastes inference on a non-prompt and may produce surprising responses. Critical to suppress.

---

### Pitfall 4: Whisper language auto-detect picks wrong language on short English clips

**What goes wrong:**
You use the multilingual `small` model instead of `small.en`. Whisper auto-detects language from the first ~30 s window (which for short clips is "the entire clip"). On a 2-second utterance with background noise, it sometimes guesses Welsh, Maori, or Galician. The transcript is correct words in the wrong language, or worse, translated into English with the `--translate` flag accidentally on.

**Why it happens:**
Confirmed in [whisper.cpp #1831](https://github.com/ggml-org/whisper.cpp/issues/1831), [chidiwilliams/buzz#1212](https://github.com/chidiwilliams/buzz/issues/1212), and [openai/whisper #529](https://github.com/openai/whisper/discussions/529). Whisper's language ID head is trained on 30 s windows; performance degrades sharply on shorter inputs, and tiny/base models guess wildly.

**How to avoid:**
1. **Always use the `.en` model** (`ggml-small.en.bin`, not `ggml-small.bin`). The `.en` variants are English-only — there is no language-detection step. Confirmed already prescribed in STACK.md but worth restating because the multilingual model is the more obvious download.
2. **Pass `--language en` explicitly** as belt-and-braces. Even on `.en` models, this prevents any future regression if whisper.cpp ever adds language hints.
3. **Never pass `--translate`.** That flag means "transcribe and translate to English" — useless and harmful for English-input dictation.

```bash
WHISPER_BIN="$WHISPER_BIN" \
  whisper-cli \
    -m "$HOME/.local/share/voice-cc/models/ggml-small.en.bin" \
    --language en \
    --vad --vad-threshold 0.5 \
    --no-timestamps \
    --prompt "$(cat "$HOME/.config/voice-cc/vocab.txt" 2>/dev/null)" \
    -otxt -of "${WAV%.wav}" \
    -f "$WAV" 2>>"$HOME/.cache/voice-cc/error.log"
```

**Warning signs:**
- `[Speaking foreign language]` markers in output.
- Transcripts in non-Latin scripts (Cyrillic, Devanagari) for English speech.
- whisper-cli stderr contains `auto-detected language: cy` (Welsh) or other unexpected codes.

**Phase to address:** Phase 1 (Spike — get the `.en` model from day one); Phase 2 (Hardening — add explicit `--language en`).

**Severity:** **Loud failure.** Wrong-language transcripts are obviously bad and immediately noticeable.

---

### Pitfall 5: Hammerspoon hotkey conflicts with system shortcuts

**What goes wrong:**
You bind `cmd+space` (Spotlight), `ctrl+cmd+space` (Character Picker / Emoji), `fn` (Globe key — system Dictation/Emoji on modern Macs), or one of the F-keys macOS reserves. The hotkey either fails to bind (Hammerspoon logs an error you don't see), or it works but also triggers the system feature, or worse, the system feature swallows the keystroke and Hammerspoon never sees it.

**Why it happens:**
- macOS reserves many shortcuts at the system level; they intercept events before they reach Hammerspoon's `hs.eventtap`. See [Hammerspoon hotkey.lua](https://github.com/Hammerspoon/hammerspoon/blob/master/extensions/hotkey/hotkey.lua) — `bind` returns nil for unbindable combos but only logs to the Hammerspoon console.
- The `fn` key on modern Apple keyboards is the **Globe key** and triggers macOS Dictation by default (single press) or the Emoji picker (configured in System Settings → Keyboard → Press Globe key to). It is **not exposed as a regular modifier** in Hammerspoon's hotkey API — confirmed in [Hammerspoon #689](https://github.com/Hammerspoon/hammerspoon/issues/689) and [#922](https://github.com/Hammerspoon/hammerspoon/issues/922).
- macOS dictation itself can be triggered by various combos (default: press Control twice; or fn key) — and macOS dictation will *speak through your microphone simultaneously with sox*, leading to garbled audio if both are active.

**How to avoid:**
1. **Pick a hotkey from the safe list** (confirmed by reference implementations and FEATURES.md):
   - `cmd+shift+e` — voice-cc's chosen hotkey (per user, 2026-04-27). Known minor conflict: VS Code/Cursor's "Show Explorer" sidebar — accepted trade-off. The original recommendation was the original combo (cmd then option then the space bar); user changed during Plan 01-01 execution.
   - The original combo (cmd then option then the space bar) — works, no system conflict on macOS 14+. (Was the original recommendation; remains a safe fallback.)
   - `ctrl+option+space` — works.
   - `right_option` (alone) — non-trivial; requires `hs.eventtap` not `hs.hotkey`. Defer unless wanted.
   - `F18`, `F19`, `F20` — unused by macOS; map a real key to F19 via `hidutil` if your keyboard lacks F-keys.
2. **Avoid:** bare `fn`, `cmd+space`, `ctrl+cmd+space`, anything involving `Function (globe) → Dictation`.
3. **Disable the macOS Dictation hotkey** so it doesn't fight us. System Settings → Keyboard → Dictation → set shortcut to "Off" (or document the disable step in the README).
4. **Validate at startup**: check `hs.hotkey.bind(...)` return value; if nil, `hs.notify` an error.

```lua
local hk = hs.hotkey.bind({"cmd", "shift"}, "e",
  function() startRecording() end,
  function() stopRecording() end)
if not hk then
  hs.notify.new({
    title = "voice-cc: hotkey binding failed",
    informativeText = "cmd+shift+e is in use by another app or macOS",
  }):send()
end
```

5. **For `fn` as a modifier**: use `hidutil` to remap `fn` to `F18`, then bind `F18` as a regular key. Document in README; don't try to bind `fn` directly via Hammerspoon (won't work).

**Warning signs:**
- Hotkey "doesn't fire" — recording indicator never turns on.
- Spotlight opens when you press the voice-cc hotkey.
- macOS Dictation activates simultaneously, producing garbled overlapping audio.
- Hammerspoon console shows `error binding hotkey ... (already in use)`.

**Phase to address:** Phase 1 (Spike — pick the right hotkey day one); Phase 3 (Distribution — README documents disabling macOS Dictation shortcut).

**Severity:** **Loud failure** during setup; **silent failure** if Hammerspoon swallows the bind error and the user just thinks "the hotkey doesn't work."

---

### Pitfall 6: Re-entrancy on rapid key presses → stuck recording / orphan sox

**What goes wrong:**
User presses-and-releases the hotkey rapidly twice. The second press fires `onPress` while the first `onRelease` callback is still resolving. Two `hs.task` instances spawn. Two `sox` processes both try to open the default audio device — only one succeeds; the other holds a half-open audio handle. The mic indicator gets stuck "on" in the menu bar (macOS shows it because at least one process holds the mic). Bash glue's lifecycle gets tangled. WAV file written by sox A is overwritten by sox B mid-write.

**Why it happens:**
Hammerspoon's hotkey events fire on the main Lua thread, which is single-threaded — but `hs.task` is async, so the callbacks for "task started" and "task exited" interleave with new hotkey events. Without an explicit re-entrancy guard, two recordings can be in flight at once. Also documented at [Hammerspoon #1963 — partial stdout on exit](https://github.com/Hammerspoon/hammerspoon/issues/1963), where rapid task lifecycle confuses the callback ordering.

**How to avoid:**
1. **Re-entrancy guard in Lua** — single source of truth for "am I recording":

```lua
local M = {}
local isRecording = false
local currentTask = nil

function M.onPress()
  if isRecording then
    -- already recording; ignore extra press
    return
  end
  isRecording = true
  hs.menubar:setIcon(redIcon)
  currentTask = hs.task.new(scriptPath, function(exitCode, stdout, stderr)
    isRecording = false  -- always clear, even on error
    currentTask = nil
    handleResult(exitCode, stdout, stderr)
  end)
  currentTask:start()
end

function M.onRelease()
  if not isRecording or not currentTask then return end
  -- terminate sends SIGTERM; bash trap kills sox cleanly
  currentTask:terminate()
end
```

2. **Use a single, named WAV path** — `/tmp/voice-cc/utterance.wav` — so even if two scripts somehow race, they overwrite (one set of bytes wins) rather than producing two stale files. ARCHITECTURE.md already prescribes this.

3. **Bash defensive cleanup**: `trap 'kill 0; rm -f "$WAV"' EXIT` so script exit (normal or signaled) reaps any child processes (`kill 0` kills the process group) — prevents orphan sox holding the mic.

4. **Guard sox itself with a lockfile** (defensive, only if Lua guard somehow leaks):
```bash
exec 9>/tmp/voice-cc/.lock
flock -n 9 || exit 0  # silently abort if another instance holds lock
```

**Warning signs:**
- macOS mic indicator (orange dot in menu bar / status area) stays on after recording should have stopped.
- `pgrep -fa sox` shows multiple instances running.
- Pasted transcripts are scrambled or contain audio from previous utterance.
- Hammerspoon console shows `hs.task object already running`.

**Phase to address:** Phase 2 (Hardening) — guard goes in with the rest of the Lua wiring.

**Severity:** **Silent annoyance + privacy concern.** Stuck mic indicator is a privacy red flag for users; orphan sox processes can hold the mic open indefinitely.

---

### Pitfall 7: Clipboard manager (1Password / Raycast / Maccy / Alfred) captures every transcript permanently

**What goes wrong:**
voice-cc sets the clipboard to the transcript, fires `cmd+v`, waits 250 ms, restores the previous clipboard. Clean. Except: any clipboard manager (1Password, Raycast Clipboard History, Maccy, Alfred Clipboard History, Paste, CopyClip, Pastebot) **observes every clipboard change and saves a copy**. The user's clipboard manager now has a permanent record of every prompt they've dictated to Claude Code, including any sensitive content. Restoring the original clipboard does nothing to evict the transcript from the manager's history.

**Why it happens:**
macOS `NSPasteboard` notifications fire on every change. Clipboard managers subscribe to these notifications via `NSPasteboardChangedNotification` or by polling `changeCount`. They append to their history regardless of how briefly the content was on the clipboard. 1Password's clipboard auto-clear after 90 s only clears the *current* clipboard; history is permanent. Same for Raycast and Maccy.

This is the **invisible privacy regression** of clipboard-based paste injection — and the architecture has no way to know the user has a clipboard manager installed.

**How to avoid:**
Three options, not mutually exclusive:

1. **Mark the clipboard set as "concealed" / "transient"** — macOS supports a hint to clipboard managers via the `org.nspasteboard.ConcealedType` UTI and `org.nspasteboard.TransientType` UTI. 1Password (>=8), Maccy, Raycast, Pastebot, and several others honour these — see [nspasteboard.org spec](http://nspasteboard.org/) and [1Password/arboard](https://github.com/1Password/arboard) which uses this convention. Hammerspoon `hs.pasteboard.writeObjects` doesn't expose this directly, but `hs.pasteboard.writeAllData` plus `setContents` with the special types does:

```lua
-- Write transcript + transient marker so clipboard managers skip it
local pb = hs.pasteboard.uniquePasteboard()
hs.pasteboard.setContents(transcript)  -- the actual transcript
-- Add the transient/concealed UTIs as additional empty types
hs.pasteboard.writeAllData(nil, {
  ["public.utf8-plain-text"] = transcript,
  ["org.nspasteboard.TransientType"] = "",
  ["org.nspasteboard.ConcealedType"] = "",  -- belt + braces
})
```

(This API surface needs verifying against your installed Hammerspoon version; if the Lua `setContents` API doesn't expose multi-type writes cleanly, use `hs.task` to invoke a tiny Swift helper that calls `NSPasteboard.declareTypes` with both the text type and the transient type.)

2. **Document the limitation in README**: "If you use 1Password, Raycast Clipboard History, Maccy, or another clipboard manager, transcripts may be retained in their history. We mark each clipboard set as Transient (per nspasteboard.org spec); managers that honour this will skip voice-cc transcripts."

3. **Alternative paste mechanism (last resort)**: synthesise the transcript as keystrokes via `hs.eventtap.keyStrokes(transcript)` (note: `keyStrokes` plural — types out the string character by character) instead of using the clipboard at all. **Trade-offs**: ~5–10× slower for long transcripts; can be confused by certain key handlers (deadkeys, IME); mishandles non-ASCII text; user can interrupt mid-paste by pressing keys. **Not recommended as default**, but worth offering as an env-var opt-in (`VOICE_CC_PASTE_MODE=keystrokes`) for paranoid users.

**Warning signs:**
- Open clipboard manager (Raycast: `cmd+shift+v`; Maccy: configured key) — see every voice-cc transcript in history.
- 1Password 8 → "Recently copied" surface shows transcripts.
- User reports "all my voice prompts are being saved somewhere I didn't expect."

**Phase to address:** Phase 2 (Hardening) — privacy concerns shouldn't wait for v2. At minimum: emit the transient UTI; document the residual risk in README.

**Severity:** **Security risk / silent privacy regression.** This is the only true privacy concern in the local-only architecture. Worth solving even if imperfectly.

---

### Pitfall 8: Synchronous clipboard restore races the paste keystroke

**What goes wrong:**
Lua sets clipboard to transcript, sends `cmd+v`, immediately sets clipboard back to saved content. The focused app processes `cmd+v` ~100–300 ms later (apps debounce/queue events), at which point the clipboard already contains the *original* content again. User pastes their previous clipboard into Claude Code instead of the transcript.

**Why it happens:**
`hs.pasteboard.setContents` returns immediately. `hs.eventtap.keyStroke` posts the event but doesn't wait for the target app to consume it. Documented in the [Hammerspoon eventtap.keyStroke discussion](https://groups.google.com/g/hammerspoon/c/qNyursx38ZA): "the keyDown, the delay, and the keyUp all occur in one operation of the Hammerspoon dispatch queue, so the other application doesn't truly get focus back until all three have completed." The default 200 ms delay between keyDown and keyUp helps but doesn't span the app's event loop pickup.

**How to avoid:**
Restore via `hs.timer.doAfter()` with at least 250 ms (and tolerate up to 500 ms for slow apps like Microsoft Word, MS Teams):

```lua
local saved = hs.pasteboard.getContents()
hs.pasteboard.setContents(transcript)
hs.eventtap.keyStroke({"cmd"}, "v")
hs.timer.doAfter(0.30, function()
  -- Only restore if clipboard is still our transcript
  -- (defends against the user copying something else in the interim)
  if hs.pasteboard.getContents() == transcript then
    hs.pasteboard.setContents(saved)
  end
end)
```

The `getContents() == transcript` guard prevents the rare case where the user `cmd+c`s something between paste and restore — without the guard, voice-cc would clobber their fresh copy.

**Warning signs:**
- "Sometimes" the wrong text appears — specifically, the user's previous clipboard content.
- Works in TextEdit but fails in slower/heavier apps.

**Phase to address:** Phase 2 (Hardening — clipboard preserve/restore step).

**Severity:** **Silent annoyance, occasionally data loss.** If user's "previous clipboard" was a password (their copy from 1Password), pasting that into a Claude Code prompt is a real leak.

---

### Pitfall 9: AirPods auto-switch / device change mid-recording silently breaks audio

**What goes wrong:**
User starts dictating with the MacBook's built-in mic. Mid-sentence, their AirPods finish syncing from their iPhone (Apple's "automatic device switching"), and macOS swaps the default input device to the AirPods. sox was opened against the previous device's audio HAL handle — depending on the underlying CoreAudio behaviour, sox either gets silence, cuts off, or continues recording from a now-disconnected device. Whisper sees a half-clip; transcript is truncated or empty. Wispr Flow documents the same failure mode for their tool and recommends restarting the recording.

**Why it happens:**
- macOS routes audio through `kAudioHardwarePropertyDefaultInputDevice`. When the default changes, existing handles to the previous device may keep working *or* silently fail depending on whether the previous device was disconnected.
- AirPods auto-switching: if you have AirPods set to "Connect to This Mac: Automatically," they auto-switch when picking up nearby device usage.
- Bluetooth devices have audio profile switching (HFP for mic vs A2DP for music) which can also disrupt recording mid-flight.
- Confirmed in [Wispr Flow audio playback troubleshooting docs](https://docs.wisprflow.ai/articles/8533503284-knwon-audio-playback-airpod-issues-ios-macos) and [SoX users mailing list](https://sourceforge.net/p/sox/mailman/message/28200865/).

**How to avoid:**
Single-user product, so the cleanest answers are: **document the limitation, don't try to recover.**

1. **Document in README**: "If you use AirPods or other Bluetooth audio devices, set them to 'Connect to This Mac: When Last Connected to This Mac' (System Settings → Bluetooth → AirPods info → Connect to This Mac) to prevent mid-dictation auto-switching."

2. **Validate the captured WAV before transcription** — if duration is far shorter than the hotkey hold time, that's a signal of mid-recording device loss. Log it; consider toasting "recording was cut short — check audio device".

```bash
# In bash glue, compare expected vs actual duration
HOLD_DURATION="$1"  # passed in from Hammerspoon (seconds key was held)
ACTUAL_DURATION=$(soxi -D "$WAV" 2>/dev/null || echo 0)
if [ -n "$HOLD_DURATION" ]; then
  RATIO=$(awk -v a="$ACTUAL_DURATION" -v h="$HOLD_DURATION" \
            'BEGIN { print (h > 0 ? a/h : 0) }')
  awk -v r="$RATIO" 'BEGIN { exit !(r < 0.5) }' && \
    echo "WARN: actual recording $ACTUAL_DURATION s vs hold $HOLD_DURATION s" \
      >> "$HOME/.cache/voice-cc/error.log"
fi
```

3. **Allow explicit device pinning** via env var: `VOICE_CC_INPUT_DEVICE="MacBook Pro Microphone"` → `sox -t coreaudio "$VOICE_CC_INPUT_DEVICE"`. This circumvents the default-device problem entirely. Document in README; default to `-d` (default device) for v1.

```bash
if [ -n "$VOICE_CC_INPUT_DEVICE" ]; then
  "$SOX_BIN" -t coreaudio "$VOICE_CC_INPUT_DEVICE" \
    -r 16000 -c 1 -b 16 "$WAV" ...
else
  "$SOX_BIN" -d -r 16000 -c 1 -b 16 "$WAV" ...
fi
```

4. **Discover available device names** for documentation: `sox -V6 -d -n trim 0 0 2>&1 | grep "Found Audio Device"` lists CoreAudio device names. Include this command in README troubleshooting.

**Warning signs:**
- Transcripts mysteriously cut off mid-sentence.
- Transcripts work fine when AirPods are off, fail when AirPods are connected.
- WAV files are far shorter than the hotkey hold duration.

**Phase to address:** Phase 2 (Hardening — duration ratio check); Phase 3 (Distribution — README documents AirPods setting + device pinning option).

**Severity:** **Silent annoyance.** Truncated transcripts confuse the user but don't lose data permanently.

---

### Pitfall 10: Disk fills with WAV files / log grows unbounded

**What goes wrong:**
Months into use, `~/.cache/voice-cc/` or `/tmp/voice-cc/` accumulates WAV files (if cleanup races, or if the script crashes before cleanup). Or the rolling history log (v1.x) grows to gigabytes because it's append-only. SSD slowly fills up; macOS gets sluggish; mysterious "disk almost full" warnings.

**Why it happens:**
- `/tmp/` on macOS is **not** auto-cleaned aggressively — it persists across reboots in many cases, contrary to Linux assumption (macOS clears on a periodic launchd job, but failures can leak).
- If bash glue dies between `sox` exit and the `trap EXIT` cleanup (e.g., killed externally with SIGKILL), the WAV stays on disk.
- History logs are inherently append-only.

**How to avoid:**
1. **Always trap-cleanup the WAV** — and ensure the trap is set *before* the WAV is created:

```bash
mkdir -p /tmp/voice-cc
WAV=/tmp/voice-cc/utterance.wav
TXT=/tmp/voice-cc/utterance.txt
trap 'rm -f "$WAV" "$TXT"' EXIT  # Set BEFORE sox runs
```

2. **Use a single named WAV** (per ARCHITECTURE.md) so worst case is one stale file, not N.

3. **Sweep stale files at script startup**:

```bash
# At top of voice-cc-record (after defining paths)
find /tmp/voice-cc -name "*.wav" -mmin +5 -delete 2>/dev/null
find /tmp/voice-cc -name "*.txt" -mmin +5 -delete 2>/dev/null
```

(5-minute threshold catches anything from a previous failed run; current invocation always finishes in seconds.)

4. **Cap the history log** (v1.x):

```bash
# After append, trim to last 10000 lines
LOG="$HOME/.cache/voice-cc/history.log"
if [ -f "$LOG" ] && [ "$(wc -l < "$LOG")" -gt 10000 ]; then
  tail -n 10000 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi
```

5. **Cap the error log similarly** — error.log can grow if there's a recurring failure mode. Same pattern, smaller cap (1000 lines).

**Warning signs:**
- `~/.cache/voice-cc/history.log` > 100 MB.
- `/tmp/voice-cc/` contains old WAV files (timestamped days ago).
- macOS "About This Mac → Storage" shows growth in Caches.

**Phase to address:** Phase 2 (Hardening — sweep + traps); Phase 4 / v1.x (history cap).

**Severity:** **Silent annoyance** for v1 (one WAV at most), **resource leak** for v1.x (uncapped history log).

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems specific to this stack.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Hardcode `/opt/homebrew/bin/sox` instead of supporting `config.sh` override | One less config knob | Breaks on Intel Macs and on anyone with Nix or custom prefixes | Personal v1 only; revisit before sharing |
| Skip the Core ML encoder build (use Metal-only) | Skip the one-time Python venv setup (~5 min) | Encoder is ~3× slower; if latency tightens you'll have to come back | Only if hyperfine measurements show comfortable margin without it |
| Skip the duration gate / VAD / denylist | Less code | Hallucinated text in prompts is a regular embarrassment | Never. These are 30 minutes total. |
| Use `sleep 0.3` in bash instead of Lua `hs.timer.doAfter` for paste-restore timing | Keeps the timing logic in one place (bash) | Bash sleep blocks the whole script; Lua timer is async and lets the script exit faster | Never (Lua timer is the right tool) |
| Auto-edit user's `~/.hammerspoon/init.lua` to add `require("voice-cc")` | Slightly nicer install UX | One bad parse → corrupted user config → support nightmare | Never. Print the line and let the user paste it. |
| Use `~/Library/Application Support/voice-cc/` instead of XDG dirs | Matches Apple convention | Breaks dotfile management (chezmoi, Stow, plain git); user can't easily inspect | Never for CLI tools. |
| Write WAV to `~/Library/Caches/voice-cc/` instead of `/tmp/` | Survives reboots (could enable history) | macOS Caches survives reboots → bloat persists; PII (audio) lives longer than necessary | Never. Audio WAVs should be ephemeral. |
| Skip TCC silent-deny detection in bash glue | Less code | Permission denial appears as "tool just doesn't work" — worst possible UX | Never. The 6 lines of grep-and-exit-10 are non-negotiable. |
| Skip transient-clipboard marker (Pitfall 7 mitigation) | Don't need to figure out the multi-type write API | Transcripts in clipboard manager history forever | Acceptable for v1 *only* if README explicitly warns; resolve in v1.1. |
| Skip the re-entrancy guard in Lua | One less variable to track | Stuck mic, orphan sox, scrambled WAVs on accidental double-tap | Never. ~5 lines. |
| Skip checksum verification on model download | Faster install | Truncated download → cryptic whisper-cli "failed to load model" error → user re-runs install with no diagnosis | Acceptable if you also add **size check** as a cheap proxy: `[ "$(stat -f%z "$MODEL")" -gt 180000000 ]` for small.en (~190 MB). |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| **TCC / Microphone** | Granting mic to "sox" or "voice-cc" expecting it to apply when run from Hammerspoon | Permission attaches to the *responsible process* — Hammerspoon.app. Test the full hotkey-to-paste path; don't trust standalone script execution. |
| **TCC / Accessibility** | Forgetting that `cmd+v` synthesis requires Accessibility, not just Mic | Hammerspoon must be in System Settings → Privacy → **Accessibility** *and* **Microphone**. The Accessibility prompt fires on Hammerspoon's own first-launch eventtap call; the Mic prompt fires on first sox spawn. |
| **Hammerspoon `hs.task`** | Relying on PATH; using `setEnvironment` and assuming it's additive (it's not) | Use absolute paths in bash. Configure `SOX_BIN`, `WHISPER_BIN` in `config.sh` with sensible Apple-Silicon defaults. |
| **Hammerspoon `hs.task` stdout** | Reading transcript from stdout but losing trailing chars due to [#1963](https://github.com/Hammerspoon/hammerspoon/issues/1963) | Write transcript to `~/.cache/voice-cc/last.txt` *before* echoing to stdout; Lua reads stdout but falls back to file if empty. |
| **Hammerspoon hotkey API** | Trying to bind `fn` directly | Use `hidutil` to remap `fn` → `F18`, then bind `F18`. Or pick a regular modifier chord. |
| **macOS Dictation** | Letting it stay enabled — both system Dictation and voice-cc try to use the mic | System Settings → Keyboard → Dictation → set shortcut to "Off". README mentions this. |
| **whisper.cpp `--vad`** | Forgetting to download the Silero VAD model (it's bundled in v1.8.x but not all binary distributions ship it) | Verify Silero is present after install: `whisper-cli --help | grep -i vad` should show vad-related flags. The model file `ggml-silero-v6.2.0.bin` should be present in whisper.cpp's models dir or the flag will silently no-op. |
| **whisper.cpp `--prompt`** | Passing a prompt longer than 224 tokens — silently truncated, with the *tail* of the prompt taking effect (i.e., your most-recent vocab additions get cut) | Cap `vocab.txt` at ~150 words. Document the cap. Order matters — most-important terms last (because the prompt is conditioning the *start* of the next prediction). |
| **sox CoreAudio `-d` (default device)** | Assuming "default" is stable through a recording | Default can change mid-recording (AirPods auto-switch). Document `VOICE_CC_INPUT_DEVICE` env var override. |
| **pbcopy** | Using `echo "$T" \| pbcopy` (adds trailing newline) | `printf "%s" "$T" \| pbcopy` (no trailing newline). The newline shows up in the paste and looks like a stray Enter in apps that auto-submit on newline (e.g., chat apps). |
| **Clipboard managers (1Password, Raycast, Maccy)** | Treating them as out-of-scope for the architecture | Mark clipboard sets as transient via `org.nspasteboard.TransientType` UTI. Document residual risk for non-conforming managers. |
| **Homebrew updates** | `brew upgrade --cask hammerspoon` triggers re-prompts for permissions in some cases | Stable enough for personal use, but document: "If hotkey stops working after a Hammerspoon update, re-grant Accessibility." |
| **Globe key** | Trying to use it as a hotkey | Globe key triggers macOS Dictation (or Emoji) at the system level — system intercepts before Hammerspoon. Pick a different key. |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| **Cold model load every invocation** (~300–500 ms) | p50 latency stuck at ~1.5 s even on M3+; doesn't improve with bigger machine | Plan for `whisper-server` LaunchAgent upgrade in v1.1 (ARCHITECTURE.md Section: Warm-Process Upgrade) | Becomes the dominant cost on M3+; matters when total budget tightens below 1.5 s |
| **`sox -d` on a Bluetooth device** | Recordings have audible compression artefacts; whisper accuracy degrades | Document: prefer wired or built-in mic for dictation | Bluetooth audio adds 100–500 ms latency *and* downgrades sample to 16 kHz HFP profile |
| **Loading `medium.en` instead of `small.en`** | p50 latency 3–5 s; over budget | small.en is the ceiling for v1; medium only via env-var opt-in for power users | medium.en breaks the 2 s budget for clips > 5 s on most M-series |
| **History log on hot path** | bash glue blocks for 50–200 ms per invocation as log file grows | Append should be `>> log` (one syscall, no file rewrite); cap log size; never `sed -i` on append | Never if implemented with bare `>>`; breaks if naively rewriting the whole log to add an entry |
| **Synchronous Whisper invocation in Lua main thread** (anti-pattern) | UI freezes during transcription; menubar can't update; other Hammerspoon hotkeys fire late | Use `hs.task` async (already prescribed) | Always — Lua is single-threaded. |
| **Shipping uncompressed model** in repo | Repo is 200+ MB to clone | Download in install.sh; never commit models | Always when distributing |
| **Reading vocab.txt on every invocation** | One `cat` syscall per utterance — trivial cost | Don't optimise. <1 ms. | Never |

---

## Security Mistakes

Despite local-only STT, several real concerns.

| Mistake | Risk | Prevention |
|---------|------|------------|
| **Transcripts captured by clipboard managers** (Pitfall 7) | Permanent retention of dictated content (potentially passwords, API keys, personal info) in 3rd-party app history | Mark clipboard as transient via `org.nspasteboard.TransientType`; document residual risk for non-conforming managers |
| **WAV files persist on disk** | Audio recording (more sensitive than text) sitting in /tmp where any process with read access could grab it | Trap-cleanup on bash exit (every path); sweep stale files at script startup; tmpfs (`/tmp`) is process-local enough that this is low risk but still worth doing |
| **History log of all transcripts** (v1.x) | An attacker (or a stolen/lost laptop) reading `~/.cache/voice-cc/log` learns everything you ever dictated | (a) Cap log size aggressively, (b) document the file's existence in README so the user can `rm` it, (c) chmod 600 the log file. Don't log audio. |
| **Error log captures sox / whisper stderr** | Could contain partial WAV path leaks, or whisper telemetry-like info | chmod 600 on `error.log`; sweep at install/uninstall |
| **Vocab file with sensitive terms** | If user puts client names or proprietary tech terms in `vocab.txt`, that file is in their dotfiles | If they version-control dotfiles publicly, they leak the vocab. README should warn: "vocab.txt is the hint to Whisper — be aware of what you put in it." |
| **System Settings deep-link URL** (`x-apple.systempreferences:...`) | Generally fine, but blindly opening URLs from a script is a soft anti-pattern | The specific URL we use is documented and stable; restrict bash glue to only the Privacy_Microphone deep link |
| **macOS code signing** for distribution | If voice-cc ever ships as a downloadable bundle (vs personal install from source), an unsigned binary triggers Gatekeeper warnings and TCC silent-deny | Out of scope for v1 (personal install). If distributed: would need Apple Developer ID + notarization. The current architecture (just bash + Lua + bundled brew tools) sidesteps this — the user installs Hammerspoon (signed by upstream) and brew installs sox/whisper-cpp (signed by their respective formulae). voice-cc itself is plain text files. |
| **Hammerspoon update invalidates TCC entries** | Permissions silently lost; tool stops working | Document the recovery: System Settings → Privacy → toggle Hammerspoon off and on |
| **TCC.db direct manipulation** (e.g., via `tccutil`) | Pre-granting permissions via scripts requires SIP disabled or a notarized app — and is fragile | Don't try to script TCC grants. Trigger the prompts at known points; let the user click through. |
| **Microphone always-hot during PTT hold** | The mic indicator (orange dot) shows during recording — correct, transparent, expected | This is the right behaviour. Don't suppress it. The PTT model (vs always-on) is itself the security stance. |
| **Network calls leaking transcripts** | Telemetry or accidental analytics calls would defeat the local-only premise | Audit `voice-cc-record` and `init.lua`: zero `curl`, `wget`, `nc`, `nslookup`. The only network call planned is v1.1's localhost-only `curl 127.0.0.1:8080` to whisper-server (not leaving the machine). |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Silent failure on no-audio (mic muted, hardware mute toggle on Mac) | User holds key, says something, releases — nothing happens, no feedback | Detect WAV is silent (e.g., `sox $WAV -n stat 2>&1 | grep -i 'maximum amplitude' | awk '{print $3}'` near 0) and toast "Microphone may be muted" |
| No feedback when hotkey is pressed but recording fails to start | User can't distinguish "I held the key wrong" from "the tool is broken" | Recording indicator (menubar dot + audible cue) fires immediately on press, even before sox is confirmed running. If sox fails, indicator goes red→idle and toast appears. |
| Recording indicator doesn't reset on error | Mic stuck "on" indicator → user thinks mic is permanently hot | Wrap onExit callback in `pcall`; always clear indicator in cleanup branch |
| Hallucinated text pasted into Claude Code | User submits "thanks for watching" as a prompt and Claude responds confusingly | Denylist + duration gate (Pitfall 3). Belt + braces. |
| Transcript pasted into wrong window (focus changed during transcription) | User pastes into Slack what they meant for Claude Code | Documented limitation in README; v1.x adds paste-last-transcript hotkey for recovery |
| User holds hotkey for 30+ seconds (long thought) | Whisper takes 5+ s to transcribe; user assumes broken; presses key again | Add a `MAX_DURATION=120` cap in bash (`timeout 120 sox ...`) so recording can't run away; consider an audible cue at 30 s ("you've been holding for 30 seconds") in v2 |
| No way to know if vocab.txt is being applied | User adds technical terms; Whisper still gets them wrong; user gives up on `--prompt` | Add a `voice-cc-debug` command that runs the last WAV through whisper-cli with verbose output and shows the prompt being used |
| User installs but never grants Accessibility (only Mic) | Hotkey records audio fine but `cmd+v` never fires; user sees clipboard has correct text but nothing pastes | Hammerspoon's own startup prompt for Accessibility helps; install.sh README step explicitly mentions both grants |
| Audible cue too loud / too quiet / wrong sound | Annoyance | Make sounds toggleable via `ENABLE_SOUNDS=true/false` in config.sh; use macOS system sounds (consistent with user's volume preferences) not custom WAVs |
| No way to retry a failed/wrong transcription | User has to re-speak the whole thing | v1.x: paste-last-transcript hotkey; v2: cancel-in-flight; the current WAV stays in /tmp until next run, so could even add a `voice-cc-redo` that re-transcribes the existing WAV |
| First-time experience: user doesn't know what hotkey is bound | Tries random keys, gives up | README screenshot + the install completion message explicitly states the hotkey: `cmd+shift+e` |
| pbcopy adds newline (using `echo` not `printf`) | Pasted text includes trailing `\n` which auto-submits in some chat UIs | Use `printf "%s"` not `echo "$T"` |
| No way to know which model is loaded | If user has both small.en and medium.en, can't tell which is in use | `voice-cc-record --version` or include in install completion: "Using model: $MODEL" |

---

## "Looks Done But Isn't" Checklist

Things that pass casual demo but break in real use.

- [ ] **Hotkey works:** Verified by holding-and-releasing while a *real* text input has focus, *not* by running the bash script standalone. (Pitfall 1.)
- [ ] **Mic permission:** Verified Hammerspoon (not Terminal, not VS Code, not the integrated terminal of any IDE) is granted Microphone. Verified by `tccutil` query, not just by "the script seems to work."
- [ ] **Accessibility permission:** Verified Hammerspoon is granted Accessibility. Verified the paste actually fires (not just that the clipboard has correct content).
- [ ] **Absolute paths:** Verified bash glue uses `/opt/homebrew/bin/sox` etc., not bare `sox`. Test by removing `/opt/homebrew/bin` from the active shell's PATH and re-running.
- [ ] **Re-entrancy:** Verified rapid-press of the hotkey doesn't spawn two recordings. Test: hold-release-hold-release within 200 ms; check `pgrep sox` shows at most one process.
- [ ] **Hallucination guards:** Verified accidental short tap (< 200 ms) doesn't paste "Thank you" or similar. Test: tap the hotkey 10 times; expect 0 pastes.
- [ ] **Empty audio:** Verified holding the hotkey in silence (mic muted or in a quiet room with no speech) produces no paste. Test: physically mute mic, hold hotkey 3 s; expect no paste.
- [ ] **Duration gate:** Verified < 0.4 s recordings abort silently (exit 2).
- [ ] **VAD flag is honoured:** Verified by checking whisper-cli stderr for `"vad: ..."` log lines on a real recording, not just by passing the flag.
- [ ] **Clipboard restored:** Verified by `cmd+c`-ing arbitrary content, dictating, then immediately `cmd+v` into a different app — should paste the original content, not the transcript.
- [ ] **Clipboard restored at right time:** Verified the *paste* gets the transcript (not the previous content) — because timing race in Pitfall 8 produces this exact bug.
- [ ] **Clipboard manager interaction:** If 1Password/Raycast/Maccy installed, verified transcripts do *not* appear in their history (or that the user has been warned in README).
- [ ] **AirPods sanity:** Verified recording works with AirPods connected. Verified the `VOICE_CC_INPUT_DEVICE` env var override works for explicit device pinning.
- [ ] **TCC silent-deny:** Verified that revoking Microphone permission produces a *toast*, not silent failure. Test: `tccutil reset Microphone org.hammerspoon.Hammerspoon`, then trigger hotkey.
- [ ] **Cleanup:** Verified `/tmp/voice-cc/` doesn't accumulate WAV files after 100 invocations. `ls /tmp/voice-cc/` should show at most one current WAV.
- [ ] **Mic indicator clears:** Verified macOS menu bar mic indicator turns off within 2 s of hotkey release on every invocation, including failure paths.
- [ ] **Re-install / re-run idempotency:** Verified install.sh can be run twice with no breakage and no duplicate config.
- [ ] **Hammerspoon update survival:** Documented (and ideally verified once) that updating Hammerspoon doesn't break voice-cc. Permission re-grant procedure documented.
- [ ] **No network calls:** Verified by `tcpdump` or `lsof -i` while running a recording — the bash glue and Lua should make zero outgoing connections (v1).
- [ ] **`.en` model in use:** Verified by `whisper-cli --help` output and inspecting the model path used. Easy to slip the multilingual `small.bin` into the models dir by accident.
- [ ] **Vocab applied:** Verified by recording "Hammerspoon" and checking transcript capitalization (lowercased = vocab not loaded; correctly cased = working).
- [ ] **Hotkey doesn't conflict:** Verified the chosen hotkey doesn't open Spotlight, trigger Dictation, or get swallowed by another tool. macOS Dictation explicitly disabled (Settings → Keyboard → Dictation → Off) or remapped.

---

## Recovery Strategies

When pitfalls occur despite prevention.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Mic permission lost / silently denied | LOW | `tccutil reset Microphone org.hammerspoon.Hammerspoon`; restart Hammerspoon; trigger hotkey to re-prompt. If prompt doesn't appear, manually toggle in Settings → Privacy & Security → Microphone. |
| Accessibility permission lost | LOW | Settings → Privacy & Security → Accessibility → toggle Hammerspoon off and on. May need to remove and re-add in extreme cases ([Hammerspoon FAQ](https://www.hammerspoon.org/faq/)). |
| Hotkey stopped working | LOW–MEDIUM | (a) Reload Hammerspoon (menubar → Reload Config); (b) check Hammerspoon console for binding errors; (c) verify the hotkey isn't newly conflicting with a system shortcut you enabled |
| Stuck "recording" — mic indicator on, hotkey unresponsive | LOW | `killall sox; killall whisper-cli; rm -rf /tmp/voice-cc`; reload Hammerspoon. Idempotent restart works because there's no persistent state. |
| Whisper transcribing wrong language | LOW | Verify `--language en` is passed and `.en` model is used. If still wrong, model file may be the multilingual variant — re-download `ggml-small.en.bin` and verify size > 180 MB. |
| WAV files leaking in /tmp | LOW | `rm -f /tmp/voice-cc/*.wav`; verify trap is set in bash glue; verify no stale process holding the file. |
| History log too big | LOW | `tail -n 1000 ~/.cache/voice-cc/log > tmp && mv tmp ~/.cache/voice-cc/log`; add the cap-on-write code if not present. |
| Transcripts in clipboard manager history | MEDIUM | (a) Clear the manager's history; (b) implement transient-clipboard-marker fix (Pitfall 7); (c) for paranoid recovery, switch to keystroke-injection mode (`VOICE_CC_PASTE_MODE=keystrokes`). |
| Hammerspoon update broke voice-cc | LOW–MEDIUM | (a) Reload config; (b) check console for errors; (c) re-grant Accessibility + Microphone if prompted; (d) worst case: `brew reinstall --cask hammerspoon` and re-grant from scratch. |
| Wrong text pasted (focus changed mid-transcribe) | LOW (with v1.x) | Hit `cmd+z` in the wrong window, then trigger paste-last-transcript hotkey (v1.x feature); paste into intended window. |
| Recording cut short by AirPods switch | LOW | Re-record. Long-term: configure AirPods auto-switch off, or pin device via `VOICE_CC_INPUT_DEVICE`. |
| Model file corrupted (truncated download) | LOW | `rm ~/.local/share/voice-cc/models/ggml-small.en.bin && bash install.sh`; install.sh should resume with `curl -C -` |
| TCC.db corruption / desynchronization | MEDIUM | `tccutil reset All org.hammerspoon.Hammerspoon` then re-grant. Last resort per [Hammerspoon FAQ](https://www.hammerspoon.org/faq/): remove from Accessibility list, restart, re-add. |

---

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| 1: Mic permission attributed to wrong process | **Phase 1** (use absolute paths + test full Hammerspoon → bash → sox path immediately, not standalone) **+ Phase 2** (TCC silent-deny detection in bash glue → exit 10 → toast) **+ Phase 3** (install.sh probe triggers prompt at right moment) | "Looks Done" item: `tccutil` query confirms grant attached to `org.hammerspoon.Hammerspoon`; revoke-and-retest produces a toast |
| 2: Hammerspoon `hs.task` doesn't see Homebrew binaries | **Phase 1** (use absolute paths from day one); **Phase 2** (sanity check binaries exist at script start with exit 11) | Test with PATH cleared: `env -i bash voice-cc-record` from Hammerspoon should still work |
| 3: Whisper short-clip / silence hallucinations | **Phase 2** (Hardening: VAD flag + duration gate + denylist post-filter) | Tap-the-hotkey-10-times test produces 0 pastes |
| 4: Whisper language auto-detect wrong | **Phase 1** (use `.en` model from start); **Phase 2** (add `--language en` explicitly) | whisper-cli stderr never logs auto-detected language; transcripts are always English |
| 5: Hotkey conflicts with system shortcuts | **Phase 1** (pick `cmd+shift+e` per user choice 2026-04-27 — supersedes the original recommendation that used cmd plus option plus the space bar; never bare `fn`); **Phase 3** (README documents disabling macOS Dictation + the VS Code "Show Explorer" override) | `hs.hotkey.bind` returns non-nil; manual test of Spotlight / Emoji / Dictation does not interfere |
| 6: Re-entrancy on rapid keypresses | **Phase 2** (Lua re-entrancy guard + bash `kill 0` on EXIT trap) | Rapid hold-release-hold-release test shows at most one sox process |
| 7: Clipboard manager captures transcripts | **Phase 2** (transient clipboard UTI marker); **Phase 3** (README documents residual risk) | Install Maccy/Raycast/Maccy in test; verify transcripts don't appear in history |
| 8: Synchronous clipboard restore race | **Phase 2** (use `hs.timer.doAfter(0.30, ...)` with content-equality guard) | Test in Microsoft Word (slow paste path): transcript pastes correctly, original clipboard restored intact |
| 9: AirPods auto-switch breaks recording | **Phase 2** (duration-ratio sanity check); **Phase 3** (README documents AirPods setting + `VOICE_CC_INPUT_DEVICE` env var) | Test with AirPods connected — recordings complete without truncation; warning logged if mid-recording device change detected |
| 10: Disk fills with WAV / log unbounded | **Phase 2** (trap cleanup, sweep stale, log cap) | After 100 invocations: `/tmp/voice-cc/` has at most one WAV; log file is bounded |

### Phase summary

- **Phase 1 (Spike — prove the loop)** must establish: absolute paths, `.en` model, conflict-free hotkey, the right responsible-process testing discipline. These are architectural choices, not "features"; getting them wrong in Phase 1 means rework everywhere.
- **Phase 2 (Hardening — make it robust)** is where most pitfalls are addressed: TCC detection, hallucination guards, re-entrancy guard, clipboard timing, transient-marker, sweep, cap. This is the densest pitfall-prevention phase.
- **Phase 3 (Distribution — install.sh + README)** addresses the install-time TCC probe, hotkey conflict documentation, AirPods documentation, model checksum/size verification.
- **Phase 4 (v1.x QoL)** addresses log capping, paste-last-transcript (recovery for Pitfall 8 fallout), cancel-in-flight.
- **Phase 5 (v1.1 warm-process)** is conditional on measurements; doesn't introduce new pitfall categories beyond the LaunchAgent lifecycle (which is well-trodden ground).

---

## Sources

### TCC and macOS permissions

- [macOS TCC — HackTricks](https://angelica.gitbook.io/hacktricks/macos-hardening/macos-security-and-privilege-escalation/macos-security-protections/macos-tcc) — comprehensive TCC primer including responsible-process semantics. HIGH.
- [The Curious Case of the Responsible Process — Qt blog](https://www.qt.io/blog/the-curious-case-of-the-responsible-process) — definitive explanation of how TCC attributes permissions to parent processes. HIGH.
- [macOS: apps launched from integrated terminal can't request TCC permissions — pingdotgg/t3code#728](https://github.com/pingdotgg/t3code/issues/728) — confirms VS Code / IDE integrated terminals silently fail TCC prompts. HIGH.
- [Privacy & Security settings reset on reboot — kevinyank.com](https://kevinyank.com/posts/privacy-security-settings-reset/) — confirms TCC entries can disappear unexpectedly. MEDIUM.
- [How to fix macOS Accessibility permission — Macworld](https://www.macworld.com/article/347452/how-to-fix-macos-accessibility-permission-when-an-app-cant-be-enabled.html) — practical recovery steps. MEDIUM.
- [Hammerspoon FAQ](https://www.hammerspoon.org/faq/) — explicit discussion of accessibility-status desynchronization and recovery. HIGH.
- [Accessibility is not enabled when it is — Hammerspoon #3301](https://github.com/Hammerspoon/hammerspoon/issues/3301) — confirms the FAQ scenario is encountered in practice. HIGH.
- [Apple Developer Forum — `tccutil` reset microphone](https://developer.apple.com/forums/thread/679303) — confirms `tccutil reset Microphone <bundle-id>` is the correct recovery. HIGH.
- [tccutil — jacobsalmela/tccutil](https://github.com/jacobsalmela/tccutil) — utility for managing TCC.db; documents the schema we query for verification. HIGH.

### Hammerspoon `hs.task` and PATH

- [Hammerspoon Home Environment Variable — #2275](https://github.com/Hammerspoon/hammerspoon/issues/2275) — confirms environment inheritance gotchas. HIGH.
- [hs.task and some modifications — #644](https://github.com/Hammerspoon/hammerspoon/issues/644) — documents environment + signal handling subtleties. HIGH.
- [Unable to launch hs.task process — #3016](https://github.com/Hammerspoon/hammerspoon/issues/3016) — "launch path not accessible" error pattern. HIGH.
- [hs.task partial stdout on exit — #1963](https://github.com/Hammerspoon/hammerspoon/issues/1963) — informs the "always also write transcript file" defensive pattern. HIGH.
- [Mac M1 /opt/homebrew/bin not in PATH — Homebrew #938](https://github.com/orgs/Homebrew/discussions/938) — confirms Apple Silicon Homebrew prefix issue. HIGH.

### Hammerspoon hotkey + eventtap

- [General Slowness of `hs.eventtap.keyStroke` — Google Group](https://groups.google.com/g/hammerspoon/c/qNyursx38ZA) — explains the synchronous keyDown/delay/keyUp issue and the focus-race rationale. HIGH.
- [Can't use keyStroke to send the same key you're binding — Google Group](https://groups.google.com/g/hammerspoon/c/yp4AvJr5v7Q) — informs the timer-defer-restore pattern. MEDIUM.
- [hs.eventtap docs](https://www.hammerspoon.org/docs/hs.eventtap.html) — official source for the 200 µs default delay and keyStrokes() vs keyStroke(). HIGH.
- [fn key as modifier — Hammerspoon #689](https://github.com/Hammerspoon/hammerspoon/issues/689) — confirms `fn` cannot be used as a modifier in `hs.hotkey.bind`. HIGH.
- [How to use fn as a mod key — Hammerspoon #922](https://github.com/Hammerspoon/hammerspoon/issues/922) — documents the `hidutil` workaround. HIGH.
- [Unable to bind to certain function keys — Hammerspoon #901](https://github.com/Hammerspoon/hammerspoon/issues/901) — informs the F-key safe choices. HIGH.

### Whisper short-clip + silence + language detection

- [whisper.cpp #1724 — Hallucination on silence](https://github.com/ggml-org/whisper.cpp/issues/1724) — primary citation for the silent-tail hallucination class. HIGH.
- [whisper.cpp #1592 — Automatically adds "Thank you"](https://github.com/ggml-org/whisper.cpp/issues/1592) — specific failure mode. HIGH.
- [openai/whisper #1873 — Share your hallucinations](https://github.com/openai/whisper/discussions/1873) — community-curated list of hallucination phrases (informs denylist). HIGH.
- [openai/whisper #1783 — Whisper Models Poisoned](https://github.com/openai/whisper/discussions/1783) — confirms training-data origin of hallucinations. MEDIUM.
- [Stops working after long gap — openai/whisper #29](https://github.com/openai/whisper/discussions/29) — confirms silence as the trigger. HIGH.
- [Careless Whisper paper — arXiv 2501.11378](https://arxiv.org/html/2501.11378v1) — academic confirmation. HIGH.
- [whisper.cpp #1831 — language/detect_language ignored](https://github.com/ggml-org/whisper.cpp/issues/1831) — confirms language-detection issues. HIGH.
- [chidiwilliams/buzz #1212 — Detect Language only transcribes English](https://github.com/chidiwilliams/buzz/issues/1212) — symptom in a downstream tool. MEDIUM.
- [openai/whisper #529 — wrong language detection and forcing the right one](https://github.com/openai/whisper/discussions/529) — informs the `--language en` belt-and-braces recommendation. HIGH.

### sox and CoreAudio

- [SoX users — using sox with external audio devices on OSX](https://sourceforge.net/p/sox/mailman/message/28200865/) — confirms `sox -V6 -d -n trim 0 0` for device discovery. MEDIUM.
- [Wispr Flow audio playback / AirPod issues](https://docs.wisprflow.ai/articles/8533503284-knwon-audio-playback-airpod-issues-ios-macos) — vendor confirms AirPods auto-switching is a recording disruptor. MEDIUM.
- [SDL CoreAudio failure modes — libsdl-org/SDL #10432](https://github.com/libsdl-org/SDL/issues/10432) — same family of audio device handle issues. MEDIUM.
- [How we fixed the mic on macOS Monterey — octopusthink](https://octopusthink.com/blog/2022-01-26-how-we-fixed-the-mic-on-macos-monterey) — community write-up of mic / TCC issues. MEDIUM.

### Clipboard managers and paste timing

- [nspasteboard.org — Concealed/Transient pasteboard types spec](http://nspasteboard.org/) — specifies the UTIs that clipboard managers honour to skip sensitive content. HIGH.
- [1Password/arboard](https://github.com/1Password/arboard) — confirms 1Password uses these UTIs. HIGH.
- [1Password — clipboard auto-clear behaviour](https://www.1password.community/discussions/1password/clipboard-clearing----too-aggressive/123881) — confirms 90 s auto-clear is *current clipboard only*; history is permanent. MEDIUM.
- [1Password — copy and paste into apps that don't work with 1Password](https://support.1password.com/copy-passwords/) — confirms clipboard-manager interaction patterns. HIGH.
- [Alfred Clipboard History — 1Password not shown when not ignored](https://www.alfredforum.com/topic/10430-1password-is-not-shown-on-clipboard-even-though-its-not-ignored-fixed-341-b858-pre-release/) — confirms transient marker semantics in another manager. MEDIUM.
- [Keyboard Maestro — excluded clipboard history](https://forum.keyboardmaestro.com/t/preferences-excluded-clipboard-history-confusion/11482) — same pattern, third manager. MEDIUM.

### whisper.cpp model corruption

- [Model download fails if folder includes space — whisper.cpp #1038](https://github.com/ggml-org/whisper.cpp/issues/1038) — confirms truncation-without-error pattern. HIGH.
- [SHA256 checksum doesn't match — openai/whisper #1027](https://github.com/openai/whisper/discussions/1027) — informs the size-check mitigation. MEDIUM.
- [whisper.cpp HuggingFace model repo](https://huggingface.co/ggerganov/whisper.cpp) — source of canonical file sizes for the size-check. HIGH.

### Cross-references (re-cited from STACK.md / FEATURES.md / ARCHITECTURE.md)

- [Claude Code voice dictation troubleshooting](https://code.claude.com/docs/en/voice-dictation) — explicit `tccutil reset Microphone` step in their docs. HIGH.
- [whisper.cpp examples/server](https://github.com/ggml-org/whisper.cpp/tree/master/examples/server) — relevant for v1.1 LaunchAgent design. HIGH.
- [Spellspoon](https://github.com/kevinjalbert/spellspoon) — reference implementation; same architecture, same pitfalls survived. HIGH.
- [local-whisper](https://github.com/luisalima/local-whisper) — closest reference implementation; informs the testing-discipline patterns. HIGH.

---

*Pitfalls research for: voice-cc — local push-to-talk dictation for Claude Code on macOS Apple Silicon*
*Researched: 2026-04-23*
