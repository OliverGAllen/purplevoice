# Feature Research

**Domain:** Local push-to-talk dictation tool for macOS Apple Silicon, primary use case: speaking prompts into the focused Claude Code terminal.
**Researched:** 2026-04-23
**Confidence:** HIGH on table stakes / anti-features (cross-checked against 6+ shipping competitors). MEDIUM-HIGH on differentiator priority (informed by 2026 reviews; subjective per Oliver's preferences). HIGH on Whisper-specific feature mechanics (custom vocab via `--prompt`, hallucination patterns, punctuation behaviour all verified against whisper.cpp issues + research papers).

---

## Executive Summary

The 2026 dictation landscape sorts cleanly into three camps:

1. **Cloud "polish" tools** (Wispr Flow, $144/yr) — auto-edit your speech with cloud LLMs, app-aware tone shifting, screenshot-of-your-window context. Fast, polished, telemetry-heavy, subscription-locked.
2. **Local Whisper apps with modes** (SuperWhisper $250 lifetime, MacWhisper $80, BetterDictation $39) — on-device Whisper + optional cloud LLM post-processing, custom modes per app, configurable vocab. Privacy-friendly, paid, GUI-driven.
3. **Open-source Hammerspoon scripts** (Spellspoon, local-whisper, yemreak/hammerspoon-dictation, BetterDictation's archived predecessor) — exactly the architecture voice-cc is targeting. Free, dotfile-able, minimal UX.

**The genuine "must haves" for a Claude Code use case** boil down to a small list:

- Push-to-talk hotkey that doesn't conflict with editor/terminal keys
- Audio captured cleanly with a clear "recording now" signal
- Whisper invocation that produces punctuated, capitalised, cleanly-pasted text
- Hallucination suppression (the trailing-silence "thanks for watching" problem is real and shipping tools all guard against it)
- Clipboard preservation (don't clobber what the user had on their clipboard)
- Failure modes handled gracefully (mic muted, model missing, paste target lost focus)

**Everything else is differentiation, not table stakes.** The Wispr Flow polish (filler-word removal, tone matching) is genuinely loved but optional. SuperWhisper's "modes" are a power-user feature most people don't touch. Code-symbol dictation ("open paren") is a Talon-era technique that's *obsolete* for the Claude Code use case — modern voice coding is dictating natural-language prompts, not literal syntax.

**The Claude Code-specific insight:** the user is dictating prompts to an LLM that will write the code. So Whisper accuracy on technical *vocabulary* (Claude, Hammerspoon, MCP, npm, TypeScript, Anthropic) matters; Whisper accuracy on *symbols* (open brace, semicolon) does not. That's a one-line `--prompt` fix, not a code-grammar engine.

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = silent abandonment. Each row cites at least one shipping competitor that ships the feature so we know it's a real expectation, not theoretical.

| Feature | Why Expected | Complexity | Notes |
|---|---|---|---|
| **Push-and-hold hotkey with reliable press/release detection** | Universal — Wispr Flow, SuperWhisper, MacWhisper, BetterDictation, Spellspoon, local-whisper all support hold-to-record. Claude Code's own `/voice` defaults to hold mode. | LOW | Hammerspoon `hs.hotkey.bind(mods, key, pressedFn, releasedFn)` handles this natively. Choose a key that doesn't collide with bare-letter editor commands — `fn` (globe), `right_option`, or a chord like `cmd+`backtick`` are the established choices. Avoid bare `Space` (Claude Code's default) — fine in their input field where they handle key-repeat warmup, but a footgun for a system-wide hotkey. |
| **No conflict with focused-app keybindings** | If the hotkey eats a real keystroke (e.g., `space` in a terminal), the tool is unusable. Claude Code explicitly warns against bare letter keys for hold mode, and notes its own `Space` default leaks 1–2 spaces during warmup. | LOW (with right key choice) | voice-cc uses `cmd+shift+e` (user 2026-04-27; VS Code "Show Explorer" conflict accepted). Other safe options: modifier-key chord (previously-recommended combo using cmd plus option plus the space bar, `ctrl+`backtick``, `fn`) or a single non-printing key (`right_option`). Hammerspoon supports modifier-only triggers via `hs.hotkey` modifiers list. |
| **Clean audio capture from default mic at the right format for Whisper** | Whisper expects 16 kHz mono PCM. Wrong sample rate = transcription fails or degrades. SuperWhisper, MacWhisper, BetterDictation all do this transparently. | LOW | `sox -d -r 16000 -c 1 -b 16 -e signed-integer /tmp/voicecc.wav` produces exactly what `whisper-cli` wants. No resample step. |
| **Local Whisper transcription that returns punctuated text** | Whisper outputs punctuation and capitalisation natively (it's trained on internet captions which include both). Every Whisper-based competitor relies on this. Users would notice immediately if output were a comma-less wall of text. | LOW | Already happens by default with `whisper-cli`. **Caveat:** Whisper's punctuation is *inconsistent* (especially missing terminal periods on short utterances). The fix is either (a) a one-line "ensure trailing period" post-processor, or (b) live with it — Claude Code itself doesn't care about a missing period at the end of a prompt. Recommend (b) for v1. |
| **Hallucination suppression on silence/noise tails** | The "thanks for watching", "subtitles by amara.org", "subscribe to my channel" failure mode is the most-reported Whisper bug (whisper.cpp issue #1724, multiple academic papers). Every shipping tool mitigates it. Without mitigation, releasing the hotkey too early or having a quiet pause gives bizarre prompts. | LOW | Three layers: (1) `--vad --vad-threshold 0.5` flag on `whisper-cli` (Silero VAD bundled since v1.8.x), (2) `sox silence -1 0.5 1%` to trim trailing silence before passing to whisper, (3) a denylist post-filter for the 5–10 known hallucination phrases. Belt + braces; cheap insurance. |
| **Transcript inserted at cursor in focused window** | This is the entire product. SuperWhisper, Wispr Flow, MacWhisper Pro, BetterDictation, Claude Code's built-in dictation — all do cursor insertion. | LOW | `pbcopy` + `hs.eventtap.keyStroke({"cmd"}, "v")`. Canonical Hammerspoon pattern. |
| **Clipboard preservation (restore previous clipboard after paste)** | Wispr Flow, SuperWhisper, BetterDictation all explicitly do this. Users with copy-paste workflows are silently ruined if their clipboard gets clobbered with each dictation. | LOW | `hs.pasteboard.getContents()` → set new → keystroke `cmd+v` → `hs.timer.doAfter(0.2, restore)`. ~10 lines of Lua. **Important: keep a small delay before restoring (200–300 ms) to let the paste keystroke fire first.** |
| **Visual "I am recording" indicator** | Without it, the user can't tell whether the hotkey registered. Wispr Flow uses an on-screen pill, SuperWhisper has a menu-bar icon + waveform, local-whisper uses a pulsing red dot, BetterDictation uses menu-bar colour change, Claude Code's `/voice` shows `keep holding…` then a live waveform. **Universal.** | LOW–MEDIUM | Hammerspoon `hs.menubar` for a colour-changing menu icon (LOW), or `hs.canvas` for a small floating overlay/pill near the cursor (MEDIUM). Even a simple "menu bar dot turns red" beats nothing. |
| **Audible cue on start and stop** | Apple's built-in dictation, BetterDictation, and SuperWhisper all play subtle start/stop sounds. Combined with visual feedback, removes "did the hotkey work?" anxiety. Some users prefer silent — make it optional but default-on. | LOW | Hammerspoon `hs.sound.getByName("Pop"):play()` or `hs.sound.getByFile()` for a custom file. macOS system sounds work fine. |
| **Sub-2-second latency from key release to text appearing** | Claude Code's own `/voice` is sub-second on average. SuperWhisper users explicitly cite latency in reviews. Above ~3 s, the tool feels broken. STACK.md confirms the budget: ~1.1–1.6 s is achievable on M2+ with `small.en` + Core ML encoder. | MEDIUM | Already the central perf target. Met by the recommended stack; just don't introduce regressions (e.g., a Python wrapper). |
| **Microphone permission handling with clear error if denied** | macOS TCC denies silently if not granted — Claude Code itself documents this exact failure mode and provides a `tccutil reset Microphone` recovery step. Without a clear error, the user gets blank transcripts and no idea why. | LOW–MEDIUM | sox returns a non-zero exit code when mic access is denied. Detect in bash glue → `hs.notify.new()` with a "Grant Microphone access in System Settings → Privacy & Security" message. Optionally include a "Open settings" button via `hs.urlevent.openURL("x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")`. |
| **Graceful handling when hotkey released before audio captured (sub-250ms holds)** | Common accidental tap. Whisper on a near-empty clip is the #1 source of hallucinations ("thank you", "you"). Every tool either drops the recording or shows "no speech detected". | LOW | Check WAV file duration in bash glue. If `<= 0.25 s` (Silero VAD's minimum-speech-duration default), abort silently — no transcription, no notification, no clipboard mutation. |
| **Don't crash / hang the system if Whisper or sox dies mid-flight** | Stuck mic recording = system mic indicator stays on = privacy concern. A one-time hang teaches the user not to trust the tool. | LOW–MEDIUM | Hammerspoon `hs.task` with timeout + `SIGKILL` on hotkey release. Always write transcripts to a temp file first. Always clean up the WAV. |

### Differentiators (Competitive Advantage)

Features that meaningfully improve the experience but aren't required to feel "complete." Categorised by whether they're worth a v2 spot.

| Feature | Value Proposition | Complexity | v1/v2/Never | Notes |
|---|---|---|---|---|
| **Custom vocabulary via Whisper `--prompt` ("hot words")** | The single highest-leverage upgrade for the Claude Code use case. Whisper baseline mis-transcribes "Anthropic" as "anthropic" (lowercase), "MCP" as "MCB" or "M.C.B.", "Claude" sometimes as "cloud", "Hammerspoon" as nonsense. Research shows 40–60% WER reduction on domain vocab with prompt conditioning. SuperWhisper, BetterDictation, MacWhisper all expose this in their UIs. local-whisper does it via `~/.local-whisper/prompt`. | LOW | **v1 (must)** — too cheap to defer. | One file: `~/.config/voice-cc/vocab.txt` with comma-separated terms. Bash glue passes it as `--prompt "$(cat vocab.txt)"`. **Hard limit: ~224 tokens** (~150–200 words). For Oliver's likely vocab (Claude, Anthropic, MCP, Hammerspoon, whisper.cpp, sox, npm, TypeScript, REPL, framework names, common library names) this is plenty. Document the limit so the file doesn't grow unbounded. |
| **"No speech detected" silent abort** | Beyond the sub-250ms case above, Whisper sometimes returns empty or whitespace-only output on quiet/garbled clips. Pasting nothing is fine; pasting a single space or newline is annoying. | LOW | **v1** | Trim whitespace from transcript in bash glue. If empty, abort before clipboard. |
| **Paste-last-transcript hotkey** | If the paste fails (target window changed focus during transcription), or you want to paste the same prompt into another window, you'd otherwise lose the transcript. Wispr Flow, WhisperTyping, Raycast Whisper all ship this. | LOW | **v2** | Keep the last transcript in a file (`~/.cache/voice-cc/last.txt`); bind a second hotkey to `cat last.txt \| pbcopy && cmd+v`. Genuinely useful, very cheap. |
| **Dictation history (rolling N transcripts)** | Raycast Whisper keeps 100, Wispr Flow keeps full history in a hub UI. Useful for "what was that prompt I said earlier?" Doubles as a debugging log when transcription is wrong. | LOW | **v2** | Append to `~/.cache/voice-cc/history.log` with timestamps. Ship a `voice-cc-history` CLI to grep it. No GUI needed. |
| **Cancel-in-flight (release without pasting)** | Press `Esc` (or release-and-immediately-press a cancel hotkey) to throw away the recording without transcribing/pasting. macOS dictation supports this. Useful when you mis-spoke or got interrupted. | LOW | **v2** | Hammerspoon: bind `Esc` while recording state is true → kill sox process, skip whisper, skip paste. Add a "cancelled" sound for confirmation. |
| **Per-app vocabulary or behaviour** | SuperWhisper's "modes" route per-app to different vocabularies and post-processors. Genuinely valuable for someone bouncing between Slack (casual), Gmail (formal), and Claude Code (technical). | MEDIUM | **v2 candidate, possibly never for Oliver** | Detect frontmost app via `hs.application.frontmostApplication():bundleID()`. Switch `--prompt` file based on app. **PROJECT.md scopes this out for v1** ("project-aware context"); per-app context is the same idea. Defer. |
| **LLM post-processing for cleanup (filler removal, formatting)** | Wispr Flow's defining feature, also in BetterDictation Pro and SuperWhisper modes. Removes "um", "uh", normalises tone, fixes false starts ("actually make that a list"). | MEDIUM–HIGH | **v2, but probably never for Claude Code use case** | The receiving system (Claude Code → Claude) is itself an LLM that handles filler words and false starts effortlessly. Adding a *second* LLM pass for cleanup is wasted compute and adds latency. Genuinely valuable for Slack/Gmail/Notion; **net-zero or negative for the dictate-to-Claude flow**. Strong case for explicit anti-feature. |
| **Auto-submit (press Enter after paste)** | Claude Code's `autoSubmit: true` does this when transcript ≥3 words. Saves the explicit Return keypress. | LOW | **v2** | One additional `hs.eventtap.keyStroke({}, "return")` after paste, gated by a config flag. Recommend off by default — easy to mis-fire and submit a half-thought. |
| **Streaming/partial transcripts displayed live during recording** | Claude Code's `/voice` shows dimmed live text. Wispr Flow shows progressive transcription. Reassures the user that words are being heard. | HIGH | **Never for v1, possibly v2** | whisper.cpp `examples/stream` exists but is designed for continuous-listen (SDL2 dependency, sliding-window VAD). For PTT, the simpler model is "wait until release, then transcribe the whole clip" — lower complexity, often *lower* total latency, and avoids the partial-transcript flicker. Keep the simple model. |
| **Live waveform / VU meter while recording** | Wispr Flow, Claude Code, MacWhisper, SuperWhisper all show one. Reassures the user audio is being captured (vs mic muted). | MEDIUM | **v2 nice-to-have** | Hammerspoon `hs.canvas` can draw, but doesn't have native audio-level access. Would need a small Swift helper or sox's `--show-progress` parsed live. Decent UX win, real complexity. Defer. |
| **Custom replacement / find-and-replace post-processor** | Addy Osmani's "vibe coding" article calls this out specifically: "Versel" → "Vercel". MacWhisper has it. BetterDictation has it. Cheaper than `--prompt` for fixed corrections. | LOW | **v2** | A `~/.config/voice-cc/replacements.txt` of `from\tto` pairs, applied via `sed` in bash glue. Complements (doesn't replace) the `--prompt` vocab. |
| **Configurable model selection (small.en / medium.en / large)** | Power-user feature for accuracy tuning. SuperWhisper exposes per-mode model choice. | LOW | **v2 (or as a config var in v1)** | Single env var `VOICE_CC_MODEL=small.en` in the bash glue. Default to small.en. Defer the actual download-management UX. |
| **Statusline / menubar transcription stats** | Spellspoon tracks duration / word count / character count in its status line. Mostly a vanity metric, occasionally useful for debugging. | LOW | **v2 or never** | Easy if menubar already exists. Skip otherwise. |
| **Auto-update of model files / version checks** | None of the open-source competitors do this; it's a Wispr-Flow-class concern. | MEDIUM | **Never** | Single user, single machine. `brew upgrade whisper-cpp` is the update mechanism. |

### Anti-Features (Commonly Requested, Often Problematic)

Features that look good in marketing but actively damage this product. Documenting so they don't sneak into v2 backlog under "competitor X has this."

| Feature | Why Requested | Why Problematic | Alternative |
|---|---|---|---|
| **Always-on listening / wake word** ("Hey Flow", "Hey Whisper") | Hands-free convenience. Wispr Flow ships it. | (1) Mic is constantly hot — the entire reason this project picks PTT. (2) Wake-word detection on Apple Silicon at low power requires a custom always-running model — not whisper.cpp's job. (3) False activations are a constant annoyance documented in every smart-speaker review. (4) Explicitly excluded by PROJECT.md. | Push-to-talk only. The hotkey *is* the wake word. |
| **Cloud STT / Cloud post-processing** | "Better accuracy" (sometimes true), "lower latency" (often false on Apple Silicon for short clips), "no model downloads". | (1) Violates PROJECT.md no-subscription, no-API-key, no-network constraint. (2) Wispr Flow's privacy controversy (banned the Reddit user who raised audio-retention concerns; now retains audio 14 days by default) is the cautionary tale. (3) Network round-trip can blow the 2 s budget. | Local whisper.cpp. Already faster than cloud for short PTT clips on M-series. |
| **App-aware tone shifting / style adaptation** ("formal in Gmail, casual in Slack") | Wispr Flow's marquee feature. Genuinely cool. | (1) Requires reading the focused window (or worse, screenshotting it — Wispr Flow does this and ships the screenshot to cloud LLMs). Privacy regression. (2) For Claude Code, the "tone" is always "instructions to an LLM" — there's nothing to adapt. (3) Adds an LLM call → adds 500 ms+ latency. | Trust Claude to handle tone in the response. The dictation just needs to be accurate. |
| **Voice commands beyond dictation ("send", "clear", "new line", "delete that")** | Talon's bread and butter. Aspirational power-user feature. | (1) Requires a parser + state machine (PROJECT.md key decision: "voice commands need parser + state machine; defer"). (2) Conflicts with literal dictation — when user says "send this email", do they mean type "send this email" or perform a send action? Tools that ship this all have a "command mode prefix" hack ("voice command, send"), which is ugly. (3) Adds entire failure mode of "command not recognised". | v1 is pure dictation. If commands are needed later, prefix them with a separate hotkey, not a parser. |
| **Code-symbol dictation grammar ("open paren", "semicolon", "snake case foo bar")** | Talon's headline feature for hands-free coding. | **The Claude Code use case obviates this entirely.** Modern voice coding (Cursor, Claude Code, Windsurf, the entire "vibe coding" movement) is dictating *natural language prompts* to an AI that writes the code. Speaking literal syntax is a 2019-era pattern. Adds grammar, training, mental overhead — for a use case that doesn't exist for Oliver. | Dictate "make the auth middleware use JWTs instead of sessions" and let Claude Code write the syntax. |
| **Toggle / tap-to-record mode** | Some users prefer not holding a key for long dictations. Claude Code's `/voice tap` ships it. | (1) Adds state ("am I recording right now?") that PTT avoids by definition. (2) Failure mode: forget to stop → mic stays hot → 2-min auto-stop → garbage transcript pasted into focused window (which may have changed). (3) Explicitly excluded by PROJECT.md. | Push-and-hold. Forces an upper bound on recording length to "however long you can hold a key", which is exactly the right constraint for prompts. |
| **GUI / preferences app / Electron shell** | Discovery, "looks polished", easier first-run onboarding for normies. | Explicitly excluded by PROJECT.md. Adds 100+ MB, slower startup, Sparkle update server, signing/notarization headaches. The whole stack should be invisible. | Config in dotfiles (`~/.config/voice-cc/`). README with screenshots. |
| **Telemetry / analytics / "anonymised usage data"** | Standard SaaS pattern; helps developers improve the product. | Single-user personal tool — there's no aggregation to do. Violates the no-network constraint. Privacy regression for zero benefit. | None. Don't even open a logging pipe to anywhere off-machine. Local rotating log file only. |
| **Audio retention / cloud sync of transcripts** | Wispr Flow does this (14-day audio retention; transcripts forever). | Same as above. The user's spoken words are some of the most personal data possible. | Optional local rolling log of transcripts (text only, no audio). Audio WAVs deleted immediately after transcription. |
| **Multi-language / language auto-detect** | Whisper supports 100 languages; "why not?" | (1) `small.en` (English-only) is materially faster and more accurate on English than the multilingual `small`. (2) Auto-detect adds latency and is wrong on short clips. (3) Oliver dictates in English. (4) Easy to add later via env var if a real need emerges. | Hardcode `--language en` and use `.en` model variants. |
| **Speaker diarization** | "Who said what" labels — MacWhisper Pro has it. | Single-user PTT — there's only one speaker. Pure waste of compute. | None. |
| **Live streaming transcription (continuous)** | Looks impressive in demos. whisper.cpp `examples/stream` exists. | Wrong tool for PTT. Adds SDL2 dependency, sliding-window VAD tuning, partial-transcript management. For 2–10 s clips, transcribing the closed WAV is simpler, often faster end-to-end, and more accurate (no boundary effects between sliding windows). | Closed-WAV transcription via `whisper-cli`. |
| **Speech-to-speech / "talk to AI by voice, hear response"** | Conversational vibe. Future-cool. | Out of scope per PROJECT.md (text-only v1). TTS adds ElevenLabs/Coqui/macOS-say complexity. Doubles the surface area. Doesn't help the "type prompts faster" core use case — Oliver still wants to *read* responses, not be lectured at. | Text-only. If TTS matters in v2, bolt it on to a separate hotkey reading from `pbpaste`. |

---

## Feature Dependencies

```
[Push-to-talk hotkey]
    └──requires──> [Mic permission grant]
    └──requires──> [Conflict-free key choice]

[Audio capture]
    └──requires──> [sox installed + CoreAudio access]
    └──requires──> [Mic permission grant]

[Whisper transcription]
    └──requires──> [Audio capture] (closed WAV file)
    └──requires──> [Whisper model file present]
    └──requires──> [whisper-cli binary]
        └──enhances──> [Core ML encoder generated]

[Hallucination suppression]
    └──requires──> [Whisper transcription]
    └──enhanced-by──> [VAD flag]
    └──enhanced-by──> [sox silence trim]
    └──enhanced-by──> [Phrase denylist post-filter]

[Custom vocabulary --prompt]
    └──requires──> [Whisper transcription]
    └──requires──> [vocab.txt file under 224 tokens]

[Transcript paste]
    └──requires──> [Whisper transcription succeeded]
    └──requires──> [Accessibility permission grant]
    └──requires──> [pbcopy + Hammerspoon eventtap]

[Clipboard preservation]
    └──requires──> [Transcript paste]
    └──requires──> [Read clipboard before paste, restore after]

[Visual feedback (recording indicator)]
    └──requires──> [Push-to-talk hotkey events]
    └──independent-of──> [Audio/transcription pipeline]

[Audible feedback]
    └──requires──> [Push-to-talk hotkey events]
    └──independent-of──> [Audio/transcription pipeline]

[Paste-last-transcript hotkey] ──requires──> [Transcript history file written]

[Cancel-in-flight] ──requires──> [Recording state machine] ──conflicts──> [Pure stateless hold-only model] (mild)

[LLM post-processing] ──conflicts──> [Sub-2-second latency budget] (likely makes budget infeasible)

[Per-app modes] ──requires──> [App-context detection] ──out-of-scope──> [PROJECT.md v1]
```

### Dependency Notes

- **Mic permission and Accessibility permission are gating** — both need to be granted on first install. Combine into a single setup script that triggers both prompts at known points. Document the `tccutil reset` recovery step.
- **Custom vocabulary is independent of everything else** — can ship from day one with an empty file, populated incrementally as Oliver finds words Whisper mis-transcribes.
- **Clipboard preservation depends on paste timing** — restore must happen *after* `cmd+v` is processed by the focused app (~150–300 ms later). Don't restore synchronously.
- **Visual + audible feedback are decoupled from the transcription pipeline** — they fire on hotkey press/release. This means feedback works even if Whisper is broken (which is itself useful debugging signal — "I see the indicator but no text appears" → look at the bash glue, not the hotkey).
- **LLM post-processing fundamentally fights the latency budget** — every cloud LLM call is 300–1500 ms. Even local Ollama (qwen2.5-1.5b) is ~500 ms on M2. Defer not just for scope reasons but because it would require relaxing the 2 s target.

---

## MVP Definition

### Launch With (v1) — The Loop That Must Work

Ruthless minimum to validate "I can speak to Claude Code instead of typing."

- [ ] **Push-and-hold global hotkey** (Hammerspoon `pressedfn`/`releasedfn`) — the entire UX
- [ ] **sox audio capture to temp WAV** (16 kHz mono) — start on press, kill on release
- [ ] **whisper.cpp transcription** with Core ML encoder, `small.en` model, `--vad` flag — meets latency + accuracy budget
- [ ] **Custom vocabulary via `--prompt`** loaded from `~/.config/voice-cc/vocab.txt` — high-leverage, near-zero cost
- [ ] **Hallucination guards**: VAD flag + min-duration drop (<250 ms aborts) + denylist of top 5 hallucination phrases — necessary for trust
- [ ] **Transcript paste via clipboard + Hammerspoon `cmd+v`** — the delivery mechanism
- [ ] **Clipboard preserve/restore** — non-negotiable for power users
- [ ] **Visual recording indicator** — menu bar dot colour change (sufficient for v1, low effort)
- [ ] **Audible start/stop cue** — system sounds, default-on, env-var off — costs ~5 lines
- [ ] **Mic permission failure detection with notification** — must tell user *why* it's broken
- [ ] **Empty/whitespace transcript silent abort** — never paste garbage
- [ ] **Reproducible install script** — STACK.md install steps, scripted, idempotent

### Add After Validation (v1.x)

Features that became obvious necessities once the core loop is in real use, but aren't required to validate the concept.

- [ ] **Paste-last-transcript hotkey** — trigger: first time you lose a transcript because the focused window changed
- [ ] **Cancel-in-flight (`Esc` while recording)** — trigger: first time you mis-speak and have to delete-paste
- [ ] **Custom replacements file** (`~/.config/voice-cc/replacements.txt`) — trigger: a recurring mis-transcription that `--prompt` doesn't fix
- [ ] **Rolling transcript history log** (`~/.cache/voice-cc/history.log`) — trigger: first debugging session where you wish you had a paper trail
- [ ] **Configurable model via env var** (`VOICE_CC_MODEL=medium.en`) — trigger: first time you wish small.en were more accurate on a specific clip

### Future Consideration (v2+)

Features explicitly worth queuing up if v1 succeeds and Oliver finds himself wanting more.

- [ ] **Floating recording overlay near cursor** (vs menu bar only) — trigger: working in fullscreen apps where the menu bar is hidden
- [ ] **Live waveform / VU meter** — trigger: more "is the mic actually picking me up?" anxiety than the menu-bar dot resolves
- [ ] **Auto-submit after paste** (configurable, default-off) — trigger: dictating mostly long-form prompts where the trailing Enter feels redundant
- [ ] **Per-app vocabulary switching** — trigger: regularly using voice-cc outside Claude Code with materially different vocab needs
- [ ] **Optional local LLM post-processing via Ollama** — trigger: dictating into non-LLM apps (email, Slack) where filler-word cleanup actually matters. Even then, gate behind a per-app or per-mode flag — never apply to Claude Code prompts.
- [ ] **TTS for replies** — trigger: explicit eyes-busy use case emerges (the current product description doesn't suggest one)

### Never (Anti-Features Codified)

- Cloud STT, cloud post-processing
- Telemetry, analytics, audio retention beyond the working WAV
- Wake word / always-on listening
- Voice commands with parser
- Code-symbol grammars ("open paren")
- GUI preferences app
- App-aware tone shifting via screenshot
- Multi-language auto-detect
- Speaker diarization
- Streaming/continuous transcription
- Toggle/tap mode (PTT only by PROJECT.md decision)

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---|---|---|---|
| Push-and-hold hotkey | HIGH | LOW | P1 (v1) |
| Conflict-free key choice | HIGH | LOW | P1 (v1) |
| Audio capture (sox) | HIGH | LOW | P1 (v1) |
| Whisper transcription (whisper.cpp + Core ML) | HIGH | MEDIUM | P1 (v1) |
| Custom vocabulary `--prompt` | HIGH | LOW | P1 (v1) |
| Hallucination guards (VAD + min-duration + denylist) | HIGH | LOW | P1 (v1) |
| Transcript paste | HIGH | LOW | P1 (v1) |
| Clipboard preservation | HIGH | LOW | P1 (v1) |
| Visual recording indicator (menu bar) | HIGH | LOW | P1 (v1) |
| Audible start/stop cue | MEDIUM | LOW | P1 (v1) |
| Mic permission failure handling | HIGH | LOW–MEDIUM | P1 (v1) |
| Empty-transcript silent abort | MEDIUM | LOW | P1 (v1) |
| Reproducible install script | HIGH | MEDIUM | P1 (v1) |
| Paste-last-transcript hotkey | MEDIUM | LOW | P2 (v1.x) |
| Cancel-in-flight | MEDIUM | LOW | P2 (v1.x) |
| Custom replacements file | MEDIUM | LOW | P2 (v1.x) |
| Transcript history log | LOW–MEDIUM | LOW | P2 (v1.x) |
| Configurable model | LOW–MEDIUM | LOW | P2 (v1.x) |
| Live waveform / VU meter | MEDIUM | MEDIUM–HIGH | P3 (v2) |
| Floating overlay near cursor | MEDIUM | MEDIUM | P3 (v2) |
| Auto-submit after paste | LOW | LOW | P3 (v2) |
| Per-app vocab switching | LOW (for Oliver) | MEDIUM | P3 (v2) |
| Local LLM post-processing | LOW (for Claude Code use) | HIGH | P3 (v2, gated) |
| TTS replies | LOW (no clear use case) | HIGH | P3 (v2 candidate) |

**Priority key:** P1 = ship in v1 (the validation loop). P2 = ship within v1.x once a real need surfaces. P3 = v2+ candidate, only if a clear trigger emerges.

---

## Competitor Feature Analysis

| Feature | Wispr Flow | SuperWhisper | MacWhisper | BetterDictation | Claude Code `/voice` | Spellspoon / local-whisper | **voice-cc plan** |
|---|---|---|---|---|---|---|---|
| Push-to-talk | Yes (hold key) | Yes | Yes | Yes (signature) | Yes (`/voice hold`) | Yes | Yes (only mode) |
| Toggle/tap mode | Yes | Yes | Yes | Optional | Yes (`/voice tap`) | Varies | **No** (PROJECT.md) |
| Wake word | Yes ("Hey Flow") | No | No | No | No | No | **No** |
| Local STT | No (cloud) | Yes (Whisper) | Yes (Whisper) | Yes (Whisper-large-v3-turbo on ANE) | No (cloud — Anthropic-hosted) | Yes (Whisper) | Yes (whisper.cpp + Core ML) |
| Cloud STT option | Required | Optional | No | No | Required | No | **No** |
| Custom vocabulary | Yes (UI) | Yes (per-mode) | Yes (UI) | Yes (UI) | Auto (project name + git branch as hints) | Yes (text file) | **Yes** (`vocab.txt`) |
| Custom replacements | Yes | Yes | Yes | Yes | No | Spellspoon: yes; local-whisper: no | v1.x |
| LLM post-processing | Yes (built-in cloud) | Yes (per-mode, BYO API key) | Yes (chat with transcript) | Yes (Pro) | No (just transcript insertion) | Spellspoon: yes (BYO LLM); local-whisper: yes (Ollama) | **No** (anti-feature for Claude Code use) |
| Per-app modes | Yes (auto-tone) | Yes (manual switch) | No | Limited | No | No | **No** (anti-feature) |
| Visual recording indicator | On-screen pill + menubar | Menubar + waveform | Window | Menubar colour | `keep holding…` then live waveform in input | Pulsing red dot + menubar | Menubar colour change (v1); cursor overlay (v2) |
| Audible cues | Yes | Yes | Yes | Yes | No (silent) | Configurable | Yes (default-on) |
| Live waveform | Yes | Yes | Yes | No | Yes | Yes (overlay) | v2 |
| Streaming partial transcripts | Yes | No | No | No | Yes (dimmed) | No | **No** (closed-WAV is simpler + faster for PTT) |
| Hallucination suppression | Yes (cloud-side) | Yes (VAD + post-filter) | Yes | Yes | Yes (server-side) | Yes (VAD) | Yes (VAD + min-duration + denylist) |
| Clipboard preserve/restore | Yes | Yes | Yes | Yes | N/A (inserts in own input) | Spellspoon: yes; local-whisper: yes | Yes (v1) |
| Paste-last-transcript | Yes | Yes | No | No | N/A | No | v1.x |
| Transcript history | Yes (cloud hub) | Yes (local) | Yes (file-based) | Limited | No | local-whisper: menubar list | v1.x (text log) |
| Cancel-in-flight | Yes | Yes | No | Yes | N/A (release = stop) | No | v1.x |
| Auto-submit | No | Configurable | N/A | No | Yes (`autoSubmit: true`, ≥3 words) | No | v2 (off by default) |
| Code-symbol grammar | No | No | No | No | No | No | **No** (Talon-era, obsolete) |
| Voice commands beyond dictation | Yes ("Command Mode") | Custom prompts can do it | No | No | No | local-whisper: yes ("voice command" prefix) | **No** (PROJECT.md) |
| Telemetry | Yes (controversial) | Some | Minimal | None | Anthropic-side | None | **No** (anti-feature) |
| Pricing | $144/yr | $250 lifetime | $80 lifetime | $39 lifetime + $2/mo Pro | Free w/ Claude.ai account | Free | Free (own machine) |

**Pattern:** voice-cc lands closest to the open-source Hammerspoon scripts (Spellspoon, local-whisper) in feature surface, but with deliberately tighter scope — no LLM post-processing, no voice commands, no per-app modes. The intentional minimalism *is* a differentiator: zero subscriptions, zero network, zero state.

---

## Key Insights for the Claude Code Use Case

These shaped the v1/v2 calls above and warrant explicit documentation:

1. **Modern voice coding is dictating prompts, not syntax.** The Talon paradigm (literal symbol speech, code grammars) is obsolete when the user is talking to an LLM that writes the syntax. This collapses an enormous category of "code dictation" features into "Whisper accuracy on technical *vocabulary*" — solved with `--prompt`.

2. **The receiving system is itself an LLM, which absorbs many "polish" features.** Filler words, false starts, "actually make that…" mid-sentence corrections — Claude handles all of these natively. Wispr Flow's auto-edit pipeline is genuinely valuable for Slack/Gmail/Notion; for Claude Code it's redundant compute that adds latency to no benefit. **This is the strongest case for an explicit anti-feature in the v2 backlog: do not build LLM post-processing for the Claude Code flow.**

3. **Whisper's `--prompt` is the highest-leverage single feature.** 40–60% WER reduction on domain vocab for 5 lines of bash. Ship in v1. Limit: ~224 tokens (~150 words). For Oliver, the vocab is small, stable, and known: Anthropic, Claude, Hammerspoon, MCP, npm, TypeScript, REPL, library/framework names. Document the cap.

4. **Hallucination on silence is the most-cited Whisper failure mode in production.** Multiple academic papers, dozens of GitHub issues, every shipping tool guards against it. Three cheap layers (VAD + min-duration + denylist) cost ~30 minutes total and prevent the most embarrassing class of bug.

5. **Clipboard preservation is invisible when present, infuriating when absent.** Every paid competitor does it because power users immediately notice when their clipboard gets clobbered. Cheap to implement, non-negotiable.

6. **Visual feedback can be cheap and still sufficient.** A menu-bar dot changing colour is enough for v1. The pulsing-red-dot + waveform overlays are nice but require Hammerspoon `hs.canvas` work. Defer the polish; ship the signal.

7. **The "tap mode" temptation should be resisted hard.** PROJECT.md scopes it out, but it's worth restating *why*: tap mode introduces a state machine ("am I recording right now?") that PTT eliminates by definition. The failure mode of "forgot to stop recording → 2 minutes of mic-hot → garbage pasted" is real and the silent killer of toggle-based dictation tools. Stay PTT.

8. **The `Space` key is a bad default.** Claude Code chose it because they handle the warmup leak in their own input box (where they can erase the leaked spaces). For a system-wide hotkey, bare `Space` would mangle every text field. Use a modifier chord (`cmd+shift+e` — voice-cc's choice; or the previously-recommended combo using cmd plus option plus the space bar, `ctrl+`backtick``), a single non-printing key (`right_option`, `fn`), or a function key. Hammerspoon supports modifier-only triggers.

---

## Sources

### Competitor Documentation & Reviews
- [Wispr Flow — official site](https://wisprflow.ai/) — features, pricing, modes. HIGH.
- [Wispr Flow Privacy Policy](https://wisprflow.ai/privacy-policy) and [Privacy controls](https://wisprflow.ai/data-controls) — confirms cloud STT, audio retention, screenshot context. HIGH.
- [Wispr Flow review — eesel AI](https://www.eesel.ai/blog/wispr-flow-review) — privacy controversy summary, CTO response. MEDIUM.
- [Wispr Flow review — Voibe](https://www.getvoibe.com/resources/wispr-flow-review/) — feature checklist, RAM usage, telemetry concerns. MEDIUM.
- [SuperWhisper — official site](https://superwhisper.com/) — modes, custom prompts, per-mode model selection. HIGH.
- [SuperWhisper Custom Mode docs](https://superwhisper.com/docs/modes/custom) — post-processing pipeline structure. HIGH.
- [SuperWhisper review — Voibe](https://www.getvoibe.com/resources/superwhisper-review/) — feature surface, complaints (notification noise, plaintext API keys). MEDIUM.
- [MacWhisper review 2026 — Lumevoice](https://lumevoice.com/blog/macwhisper-review-2026/) — feature checklist, Parakeet integration. MEDIUM.
- [MacWhisper vs SuperWhisper — Voibe](https://www.getvoibe.com/resources/macwhisper-vs-superwhisper/) — explicit feature matrix. MEDIUM.
- [BetterDictation — official site](https://betterdictation.com/) — push-to-talk default, pricing, Whisper-large-v3-turbo on ANE. HIGH.
- [Aiko — Sindre Sorhus](https://sindresorhus.com/aiko) — file-transcription product, no live dictation (illuminating contrast). HIGH.
- [Talon Voice — official docs](https://talonvoice.com/docs/) — confirms Talon's command-based paradigm vs Whisper's prose paradigm. HIGH.
- [Hands-Free Coding — Talon in-depth review](https://handsfreecoding.org/2021/12/12/talon-in-depth-review/) — confirms Talon's "code grammar" approach is heavyweight and aimed at hands-free users. MEDIUM.
- [Josh W. Comeau — coding with Talon](https://www.joshwcomeau.com/blog/hands-free-coding/) — corroborates Talon's complexity for non-RSI users. MEDIUM.
- [Choosing the right Mac dictation app — afadingthought](https://afadingthought.substack.com/p/best-ai-dictation-tools-for-mac) — 2026 differentiator analysis. MEDIUM.
- [Mac dictation tools comparison — jamesm.blog](https://jamesm.blog/ai/mac-dictation-tools-comparison/) — table-stakes vs differentiators framing. MEDIUM.

### Reference Implementations
- [Spellspoon GitHub](https://github.com/kevinjalbert/spellspoon) — Hammerspoon dictation script with prompt-based LLM post-processing. HIGH (closest reference architecture).
- [local-whisper GitHub](https://github.com/luisalima/local-whisper) — Hammerspoon + whisper.cpp PTT with menubar UI, custom prompt file, voice-command prefix, optional Ollama. HIGH (most directly comparable to voice-cc).
- [Claude Code voice dictation docs](https://code.claude.com/docs/en/voice-dictation) — ships hold + tap modes, auto-submit, project-name as recognition hint, troubleshooting matrix. HIGH (directly informs feature parity decisions).
- [Raycast Whisper Dictation](https://www.raycast.com/finjo/whisper-dictation) — confirms 100-transcript history is a useful feature ceiling. MEDIUM.
- [WhisperTyping FAQ](https://whispertyping.com/support/faq/) — local history + paste-last patterns. MEDIUM.

### Whisper Mechanics
- [Whisper `--prompt` discussion — whisper.cpp #348](https://github.com/ggml-org/whisper.cpp/discussions/348) — confirms prompt flag exists in whisper.cpp. HIGH.
- [Whisper specialised vocabulary — whisper.cpp #235](https://github.com/ggml-org/whisper.cpp/issues/235) — community usage patterns for technical jargon. HIGH.
- [Whisper prompt engineering — Medium / David Cochard](https://medium.com/axinc-ai/prompt-engineering-in-whisper-6bb18003562d) — 224-token limit, prompt-as-stylistic-prefix mechanism. MEDIUM.
- [Whisper vocab improvement research](https://discuss.huggingface.co/t/adding-custom-vocabularies-on-whisper/29311) — 40–60% WER reduction figure. MEDIUM.
- [Whisper hallucination on silence — whisper.cpp #1724](https://github.com/ggml-org/whisper.cpp/issues/1724) — confirms the failure mode is real and ongoing. HIGH.
- [Whisper hallucination paper — arXiv 2501.11378](https://arxiv.org/html/2501.11378v1) — academic confirmation of non-speech-induced hallucination. HIGH.
- [Whisper auto-punctuation discussion — OpenAI community](https://community.openai.com/t/whispers-auto-punctuation/806764) — confirms native punctuation + capitalisation is included; inconsistent on terminal periods. MEDIUM.
- [No separate punctuation — whisper.cpp #1309](https://github.com/ggml-org/whisper.cpp/issues/1309) — confirms behaviour in whisper.cpp specifically. HIGH.

### Voice Coding Patterns
- [Speech-to-Code: Vibe Coding with Voice — Addy Osmani](https://addyo.substack.com/p/speech-to-code-vibe-coding-with-voice) — confirms natural-language-prompt is the modern pattern, not symbol dictation; custom-replacements ("Versel" → "Vercel") as essential differentiator. MEDIUM.
- [Voice Coding with SuperWhisper](https://superwhisper.com/voice-coding) — vendor article, confirms target use case (Cursor, Claude Code) is dictating prompts not syntax. MEDIUM (vendor-adjacent, but the framing is the industry consensus).
- [Voice Dictation for Coding — Whisper Dictation blog](https://dictationformac.com/blog/voice-dictation-for-coding/) — same pattern from a different vendor. MEDIUM.

### UX / Visual Feedback Patterns
- [Voice Principles — Clearleft](https://voiceprinciples.com/) — VUI design principles. MEDIUM.
- [VUI design best practices — Designlab](https://designlab.com/blog/voice-user-interface-design-best-practices) — multimodal feedback patterns (visual + audible + tactile). MEDIUM.
- [Visual Feedback — VocaMac](https://vocamac.com/features/visual-feedback/) — three-layer feedback model (status / level / cursor). MEDIUM.

### Failure Modes
- [Claude Code voice dictation troubleshooting](https://code.claude.com/docs/en/voice-dictation) — canonical list of mic-permission, no-audio-detected, no-speech-detected error states. HIGH.
- [Claude Code voice mic-entitlement bug — issue #33023](https://github.com/anthropics/claude-code/issues/33023) — confirms macOS silent-deny is a real failure mode shipping tools have to handle. HIGH.

### Privacy / Anti-Feature Validation
- [Smart speakers always-listening privacy](https://www.howtogeek.com/how-well-do-smart-speakers-protect-privacy-while-listening-to-everything/) — confirms accidental-activation and background-capture concerns are mainstream, not paranoid. MEDIUM.

---

*Feature research for: voice-cc — local push-to-talk dictation for Claude Code on macOS Apple Silicon*
*Researched: 2026-04-23*
