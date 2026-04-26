# Project Research Summary

**Project:** voice-cc — local push-to-talk dictation for Claude Code on macOS Apple Silicon
**Domain:** Personal CLI tool / macOS power-user utility (Hammerspoon + whisper.cpp + sox + bash glue)
**Researched:** 2026-04-26
**Confidence:** HIGH

## Executive Summary

voice-cc is a single-user macOS Apple Silicon utility that turns a held hotkey into a transcript pasted into the focused window. Research across four dimensions converges on a deliberately small, file-handoff architecture that mirrors two production-validated reference implementations (Spellspoon and local-whisper): **Hammerspoon owns hotkey + clipboard + paste; a ~80-line bash glue script owns the sox → whisper.cpp → post-filter pipeline; whisper.cpp owns inference.** Every layer is a mature CLI binary or built-in macOS facility — no daemons, no Python, no IPC framework, no GUI. The 2-second latency budget is comfortably achievable on M2+ with `whisper.cpp` v1.8.4, the `small.en` model (Q5_0, ~190 MB), and an optional Core ML encoder that gives ~3× ANE speedup for ~5 minutes of one-time setup.

The dominant risk is not technical complexity (the stack is small) but **macOS TCC permission semantics**: permission attaches to the *responsible process* (Hammerspoon.app), not to sox or bash, and silent-deny is the default failure mode. Pitfall research identified ten classes of failure that all shipping competitors guard against — TCC silent-deny, Whisper's well-documented short-clip / silence hallucinations ("thanks for watching"), Hammerspoon's missing `/opt/homebrew/bin` PATH, hotkey conflicts (Globe key, Spotlight, system Dictation), re-entrancy on rapid presses, clipboard-manager retention of transcripts, paste-restore timing races, AirPods auto-switching mid-recording, and disk leak from un-trapped WAV cleanup. These map cleanly to a single hardening phase.

The strategic call is to build in three phases that mirror the build-order constraints surfaced by architecture research: **(1) a bare spike that proves the loop end-to-end, (2) a hardening phase that addresses the dense cluster of TCC + hallucination + re-entrancy + clipboard pitfalls, and (3) a distribution phase that produces an idempotent install.sh, a README, and `hyperfine` measurements that gate whether a v1.1 warm-process upgrade (`whisper-server` over localhost) is needed.** Two follow-on phases (v1.x quality-of-life and v1.1 conditional warm process) are sketched but only triggered by validated need.

## Key Findings

### Recommended Stack

The stack research returns one clear prescription with no genuine alternatives in the leading positions. whisper.cpp wins over mlx-whisper for push-to-talk because mlx-whisper's 1–3 s Python interpreter cold-start tax destroys responsiveness on the typical 2–10 s clip — even though mlx-whisper is ~2× faster on `large-v3-turbo`, that advantage doesn't materialise for short PTT use. Hammerspoon wins over Karabiner / skhd / BetterTouchTool / native Swift because it natively exposes `pressedfn` and `releasedfn` callbacks, owns clipboard manipulation and `cmd+v` synthesis, and is already the convention for every comparable open-source dictation script. sox wins over ffmpeg on simplicity (1 MB vs 80 MB) for a use case that is literally "record 16 kHz mono WAV from default mic." Bash wins over Python because the orchestration is genuinely 30 lines of "wait for one process, then run another" with no interpreter cost.

**Core technologies:**
- **Hammerspoon 1.1.1** — global hotkey + UX layer + paste — only mature scriptable macOS automation framework with native `releasedfn` PTT support, in-process clipboard control, and `cmd+v` keystroke synthesis
- **sox 14.4.2** — mic capture — produces exactly the 16 kHz mono PCM whisper.cpp wants, no resample step, ~1 MB binary
- **whisper.cpp v1.8.4 (`whisper-cli`)** — local STT — single static C++ binary with Metal default + Core ML ANE encoder option + bundled Silero VAD, ~30k stars, used in production by VoiceInk / MacWhisper / BetterDictation
- **`ggml-small.en.bin`** (~190 MB, Q5_0) — best speed/accuracy point for short English dictation; medium.en is 4× slower for ~2–3pp WER improvement, not worth it for the budget
- **bash glue** (~80 lines) — orchestration with no interpreter cost, files as the IPC, exit codes as the control protocol
- **Core ML encoder** (optional, recommended) — `ggml-small.en-encoder.mlmodelc` generated via one-time Python toolchain for ~3× encoder speedup on ANE; not in the brew bottle, requires source build

Detailed rationale + version-compatibility matrix + alternatives considered: see `.planning/research/STACK.md`.

### Expected Features

Feature research surveyed six shipping competitors (Wispr Flow, SuperWhisper, MacWhisper, BetterDictation, Claude Code's own `/voice`, plus the open-source Hammerspoon scripts Spellspoon and local-whisper) and found that the v1 must-have list is short, the differentiator list is mostly v2 candidates, and several "obvious" features are explicit anti-features for the Claude Code use case specifically.

**Must have (table stakes confirmed across all competitors):**
- Push-and-hold global hotkey with reliable press/release detection
- Conflict-free key choice (NOT bare `Space`, NOT `fn`/Globe, NOT `cmd+space`) — recommend `cmd+option+space`, `ctrl+option+space`, or remapped F18/F19
- Clean 16 kHz mono audio capture from default mic
- Local Whisper transcription with native punctuation/capitalisation
- **Hallucination suppression** (VAD flag + min-duration drop + denylist of top 5–10 known phrases like "thanks for watching", "[BLANK_AUDIO]")
- Transcript paste via clipboard + `cmd+v`
- **Clipboard preserve/restore** with ≥250 ms delay before restore
- Visual recording indicator (menu-bar dot colour change is sufficient for v1)
- Audible start/stop cue (default-on, env-var off)
- **Mic permission failure detection** with actionable toast + deep link to System Settings
- Empty/whitespace-only transcript silent abort
- Sub-2-second latency from key release to text appearing
- Reproducible install script

**Should have (high-leverage v1 differentiators):**
- **Custom vocabulary via `--prompt`** loaded from `~/.config/voice-cc/vocab.txt` — the single highest-leverage feature for the Claude Code use case (40–60% WER reduction on domain vocab for ~5 lines of bash; cap at ~150 words / 224 tokens)
- Paste-last-transcript hotkey (v1.x — recovery for focus-lost paste)
- Cancel-in-flight via Esc (v1.x)
- Custom replacements file `replacements.txt` (v1.x — "Versel" → "Vercel")
- Rolling history log capped at 10 MB (v1.x)

**Defer (v2+):**
- Floating cursor-adjacent overlay (vs menu-bar only)
- Live waveform / VU meter
- Auto-submit after paste (off by default if ever shipped)
- Per-app vocabulary modes (PROJECT.md scopes this out)
- Configurable model selection beyond env-var

**Explicit anti-features (competitor patterns to NOT adopt — surface to PROJECT.md Out of Scope):**
- LLM post-processing (Wispr Flow's marquee feature; redundant when receiving system is itself an LLM)
- Voice commands beyond dictation ("send", "clear")
- Toggle / tap-to-record mode (PROJECT.md decision; introduces stuck-mic failure mode)
- Wake words / always-on listening
- Cloud STT / cloud post-processing
- Code-symbol grammars ("open paren") — obsolete in the LLM-prompt era
- Telemetry, audio retention, cross-app screenshot context
- Multi-language / language auto-detect (use `.en` model)
- Speaker diarization, streaming partial transcripts, GUI/Electron shell

Detailed feature matrix + competitor analysis + dependency graph: see `.planning/research/FEATURES.md`.

### Architecture Approach

The architecture is **one-shot CLI per utterance, orchestrated by a single bash script that Hammerspoon spawns on hotkey press and signals on release.** No daemon, no shared state beyond the temp WAV path, no IPC framework. Hammerspoon owns the UX layer (hotkey, indicator, paste, clipboard preserve/restore); bash owns the pipeline lifecycle (sox → duration gate → whisper-cli → post-filter → stdout); whisper.cpp owns inference. The seams are small and well-defined: Hammerspoon launches one command and waits for one exit code; bash glues three CLIs with files; transcript flows back via stdout + a redundant `~/.cache/voice-cc/last.txt` write to defend against a known `hs.task` partial-stdout bug. Exit codes (0/2/3/10/11/12) are the entire control protocol between bash and Lua — no JSON, no sockets, no lockfiles.

The architecture is intentionally future-aware: the STT call is isolated to a single bash function `transcribe()`, so the v1.1 warm-process upgrade (`whisper-server` over localhost HTTP via LaunchAgent) is a one-line change inside that function — Hammerspoon code, file layout, config, and failure model all stay identical. The upgrade only triggers if Phase 3 `hyperfine` measurements show p50 latency > 2.0 s or p95 > 3.0 s on Oliver's hardware.

**Major components:**
1. **Hammerspoon `~/.hammerspoon/voice-cc/init.lua`** (~150 lines Lua) — hotkey press/release events, menu-bar indicator, audible cues, clipboard preserve/restore via `hs.timer.doAfter(0.30, ...)`, paste keystroke, error notifications, lifetime of the bash subprocess, in-memory `isRecording` re-entrancy guard
2. **`~/.local/bin/voice-cc-record`** (~80 lines bash) — sox lifecycle with SIGTERM trap, WAV duration gate, calls `transcribe()`, post-filter (whitespace trim, denylist exact-match drop, replacements in v1.x), writes last-transcript marker, returns semantic exit codes
3. **`transcribe()` bash function** (~10 lines) — the *one* abstraction boundary between voice-cc and the STT engine. v1: `whisper-cli --vad --prompt`. v1.1 drop-in: `curl 127.0.0.1:8080/inference -F file=@`.
4. **External binaries** (sox, whisper-cli, whisper-server-in-v1.1) — opaque CLIs invoked by absolute path
5. **XDG-conventional file layout** — `~/.config/voice-cc/` (vocab, denylist, replacements, config.sh), `~/.local/share/voice-cc/models/` (190 MB+ model files), `~/.cache/voice-cc/` (last.txt, history.log, error.log), `/tmp/voice-cc/` (single named WAV, trap-cleaned), `~/.local/bin/voice-cc-record` (PATH-installed glue)
6. **Idempotent `install.sh`** — homebrew formula installs, mkdir -p for dirs, curl with `-C -` for resumable model downloads, `cp` only if config absent (never clobbers user edits), `ln -sf` for binary, `rsync -a` for Hammerspoon module, prints (does NOT auto-edit) the `require("voice-cc")` line for the user's own `init.lua`

Detailed component responsibilities + data flow diagram + state model + failure boundary matrix + warm-process upgrade reservation: see `.planning/research/ARCHITECTURE.md`.

### Critical Pitfalls

Pitfall research identified ten failure classes, of which the top five are non-negotiable to address. Severity skews toward "silent" — these are not crashes, they are the loop appearing to work while producing wrong output, leaking data, or never producing output at all.

1. **TCC permission attributed to wrong process** (silent failure if not instrumented) — Mic permission attaches to Hammerspoon.app (the responsible process), not to sox or bash. Testing the bash script directly from Terminal works (Terminal has its own grant); the Hammerspoon-spawned path silently produces 0-byte WAVs forever if Hammerspoon hasn't been granted mic. **Prevention:** detect TCC silent-deny in bash glue (grep sox stderr for `AudioObjectGetPropertyData` / `Permission denied`) → exit 10 → Lua toast with "Open System Settings" deep link. Always test the full hotkey-to-paste path; never trust standalone script execution.
2. **Hammerspoon `hs.task` doesn't see Homebrew binaries on Apple Silicon** (loud failure) — `hs.task` doesn't spawn through a login shell; PATH doesn't include `/opt/homebrew/bin`. **Prevention:** use absolute paths in bash glue from day one (`SOX_BIN=/opt/homebrew/bin/sox`, etc.); make overridable via `config.sh`; sanity-check binaries exist with exit 11 if missing.
3. **Whisper short-clip / silence hallucinations** (silent annoyance escalating to data corruption) — Whisper trained on YouTube subtitles produces "Thank you", "Thanks for watching", "Subtitles by the Amara.org community", "[BLANK_AUDIO]" on silence/short audio. Most-cited Whisper failure mode in production. **Prevention (belt + braces):** duration gate (drop < 0.4 s in bash), `--vad --vad-threshold 0.5` flag on whisper-cli, hardcoded denylist exact-match post-filter (only drop if entire transcript matches a phrase, never substring-match).
4. **Re-entrancy on rapid hotkey presses** (silent annoyance + privacy concern) — Two `hs.task` instances spawn, two sox processes both try to grab the audio device, mic indicator gets stuck on. **Prevention:** Lua `isRecording` boolean guard at top of `onPress`; bash `trap 'kill 0; rm -f "$WAV"' EXIT` to reap process group; optional `flock` defensive lock.
5. **Clipboard manager (1Password / Raycast / Maccy / Alfred) captures every transcript permanently** (silent privacy regression) — Clean clipboard restore does nothing to evict transcripts from clipboard-manager history. **Prevention:** mark clipboard set as transient via `org.nspasteboard.TransientType` UTI (honoured by 1Password 8, Maccy, Raycast, Pastebot per nspasteboard.org spec); document residual risk in README; offer keystroke-injection mode as opt-in for paranoid users.

Honourable mentions (also addressed in Phase 2):
- **Synchronous clipboard restore races paste keystroke** — restore via `hs.timer.doAfter(0.30, ...)` with `getContents() == transcript` content-equality guard
- **Whisper language auto-detect picks wrong language on short English clips** — always use `.en` model, always pass `--language en`, never `--translate`
- **Hotkey conflicts** (`fn`/Globe, Spotlight, system Dictation) — pick `cmd+option+space` or `ctrl+option+space`; document disabling macOS Dictation shortcut in README
- **AirPods auto-switch breaks mid-recording** — duration-ratio sanity check; document `VOICE_CC_INPUT_DEVICE` env var pinning
- **Disk fills with WAV / log unbounded** — trap-cleanup BEFORE WAV creation; sweep stale files at startup; cap history log at 10 MB

Full list with prevention code snippets, warning signs, severity, and "Looks Done But Isn't" verification checklist: see `.planning/research/PITFALLS.md`.

## Implications for Roadmap

The build order is non-negotiable and was established by architecture research: **manual pipeline first → bash glue script second → Hammerspoon wiring third**. Each step has nothing to test against without the previous. The phases below mirror this directly.

### Phase 1: Spike — Prove the End-to-End Loop

**Rationale:** Architecture research is unambiguous that you cannot build the Hammerspoon wiring before there is a bash script to spawn, and you cannot build the bash script before you have a working manual pipeline. This phase is intentionally a thin slice: minimum viable end-to-end loop, no polish.

**Delivers:** Holding `cmd+option+space`, saying "refactor the auth middleware to use JWTs instead of session cookies", releasing — within ~2 seconds the sentence appears in the focused text field. That's the entire validation target.

**Sub-steps (from ARCHITECTURE.md build order):**
- 1.1: Manual `sox -d -r 16000 -c 1 -b 16 /tmp/test.wav` → manual `whisper-cli` → manual paste — validates model + latency + vocab.txt help on Oliver's actual machine
- 1.2: Bash glue script (`voice-cc-record`) with sox SIGTERM trap, `transcribe()` function abstraction, exit codes — validates pipeline composes; UNBLOCKS Hammerspoon work
- 1.3: Minimal Hammerspoon `init.lua` with `hs.hotkey.bind(mods, key, pressedFn, releasedFn)` → spawn script via `hs.task` → paste stdout

**Addresses:** Push-and-hold hotkey, audio capture, Whisper transcription, transcript paste, custom vocab via `--prompt`, sub-2-second latency target.

**Avoids (architectural choices that prevent rework later):**
- Pitfall 2: absolute paths in bash from day one
- Pitfall 4: `.en` model from day one
- Pitfall 5: pick `cmd+option+space`
- Pitfall 1 awareness: test end-to-end, NOT standalone bash, before declaring done

### Phase 2: Hardening — Make the Loop Robust

**Rationale:** This is the densest pitfall-prevention phase — most of the ten critical pitfalls cluster here. Hardening cannot happen meaningfully before the loop exists (you need observed hallucinations to design the denylist, you need a real paste path to know what to preserve), and shipping must wait for it.

**Delivers:** A loop that is robust to the documented failure modes — no hallucinations slipping through, no silent permission denies, no orphan sox, no clobbered clipboard, no AirPods truncation surprises, no WAV leaks.

**Implements:**
- Hallucination guards: VAD flag + duration gate at 0.4 s + denylist exact-match
- TCC silent-deny detection → exit 10 → toast with Settings deep link
- Re-entrancy guard in Lua + `kill 0` EXIT trap in bash
- Clipboard preserve via `hs.timer.doAfter(0.30, ...)` with content-equality guard
- Transient-clipboard UTI marker for clipboard-manager privacy
- Empty/whitespace silent abort (exit 3)
- Menu-bar dot indicator + audible start/stop cues
- Trap-cleanup of WAV BEFORE sox runs + sweep stale files at startup
- Duration-ratio sanity check for AirPods mid-recording switch
- Hammerspoon `pcall`-wrapped onExit so indicator always resets

**Avoids:** Pitfalls 1, 3, 6, 7, 8, 9, 10, plus UX pitfalls (silent failure, stuck indicator, hallucinated text in prompts).

### Phase 3: Distribution — Make It Reproducible + Measure

**Rationale:** Until install.sh exists, voice-cc is "works on Oliver's specific machine after a weekend of fiddling" — not a tool. Until `hyperfine` measurements exist, the v1.1 warm-process upgrade decision is speculation.

**Delivers:**
- `install.sh` (idempotent, never clobbers user config) and `uninstall.sh`
- Optional Core ML encoder build documented (~5 min one-time setup for ~3× encoder speedup)
- README with install steps, hotkey choice rationale, permission grant walkthrough, troubleshooting matrix
- TROUBLESHOOTING.md including AirPods setting, `VOICE_CC_INPUT_DEVICE` override, macOS Dictation shortcut disable, `tccutil reset` recovery
- `hyperfine` benchmark on Oliver's actual hardware producing p50/p95 latency numbers — **gates v1.1 decision**

**Decision gate at end of Phase 3:** if hyperfine shows p50 > 2.0 s OR p95 > 3.0 s, queue Phase 5 (warm process). Otherwise, Phase 5 stays deferred indefinitely and v1 ships.

### Phase 4 (v1.x): Quality-of-Life

**Rationale:** Triggered by the first real-use frustrations after Phase 3 ships. Each item below has a specific trigger; do not build speculatively.

**Delivers:**
- Paste-last-transcript hotkey (trigger: first lost transcript from focus change)
- Cancel-in-flight via Esc while recording (trigger: first mis-spoken utterance)
- Custom replacements file `replacements.txt` (trigger: recurring mis-transcription `--prompt` doesn't fix)
- Rolling capped history log `~/.cache/voice-cc/history.log` (trigger: first debugging session you wish you had a paper trail)
- `VOICE_CC_MODEL=medium.en` env-var support (trigger: first time small.en accuracy disappoints)

### Phase 5 (v1.1, conditional): Warm-Process Upgrade

**Rationale:** Only triggered if Phase 3 measurements demand it. Don't pay the LaunchAgent + source-build complexity tax until the data says you need to.

**Delivers:**
- Source-build of whisper.cpp's `examples/server` with Core ML
- LaunchAgent plist (`com.olivergallen.voice-cc-server.plist`) with `KeepAlive=true` and `RunAtLoad=true`
- `transcribe()` bash function swap: `whisper-cli ...` → `curl 127.0.0.1:8080/inference -F file=@...`
- Validation that latency now < 1 s

**Crucially, what stays the same:** Hammerspoon code (zero changes), bash glue structure (zero changes outside `transcribe()`), config files (zero changes), file layout (one new plist), failure model (largely unchanged).

### Phase Ordering Rationale

- **Build order is dictated by composition dependencies**, not by feature priority.
- **Hardening is its own phase** because the pitfalls cluster: TCC, hallucination, re-entrancy, clipboard timing — these all need the loop to exist, all need to ship before the tool is trustworthy.
- **Distribution + benchmarking go together** because the hyperfine measurements reflect the production configuration only after install.sh produces that configuration reproducibly.
- **v1.x and v1.1 are deliberately separated and conditional** — research found explicit triggers for each. Building speculatively risks adding the LLM-post-processing-style features that anti-feature analysis flagged as net-negative.

### Research Flags

**Phases that may need `/gsd:research-phase` during planning:**

- **Phase 2 (Hardening):** likely needs targeted research on (a) the exact `hs.pasteboard` API surface for multi-type writes that include the `org.nspasteboard.TransientType` UTI; (b) the precise Settings deep-link URLs that survive macOS minor versions.
- **Phase 5 (Warm-Process v1.1):** if it triggers, needs hands-on research on `whisper-server`'s exact HTTP API contract under high-frequency PTT load, LaunchAgent `KeepAlive` interactions, and Core ML compilation reproducibility.

**Phases with well-documented standard patterns (skip research-phase):**

- **Phase 1 (Spike):** Spellspoon and local-whisper are direct reference implementations.
- **Phase 3 (Distribution):** install.sh idempotency is a solved problem; README + hyperfine are commodity work.
- **Phase 4 (v1.x):** all items are < 1 day each with obvious implementations.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | whisper.cpp + Hammerspoon + sox is the established pattern across multiple production tools. Versions, capabilities, and trade-offs cross-verified against official docs and recent benchmarks. |
| Features | HIGH (table stakes) / MEDIUM-HIGH (differentiator priority) | Cross-checked against six shipping competitors. Whisper-specific feature mechanics verified against whisper.cpp issues + research papers. |
| Architecture | HIGH | Process model, data flow, and component boundaries validated against two reference implementations. File layout follows established XDG conventions. |
| Pitfalls | HIGH | TCC permission flow cross-verified across Apple docs, hacktricks, Hammerspoon FAQ. Whisper short-clip + silence behaviour confirmed by multiple GitHub issues + an academic paper. |

**Overall confidence:** HIGH

### Gaps to Address

- **`hs.pasteboard` multi-type write API** for the transient-clipboard UTI (Pitfall 7 mitigation) — needs Phase 2 spike to verify against installed Hammerspoon version. Fallback is a tiny Swift helper.
- **macOS Settings deep-link URL** for Microphone privacy pane — format has changed across major releases; needs Phase 2 verification on current macOS.
- **Oliver-specific latency profile** — STACK.md predicts 1.1–1.6 s end-to-end; resolves in Phase 3 with hyperfine.
- **Sox CoreAudio TCC stderr fingerprint** — exact pattern varies by macOS version; resolve in Phase 2 by deliberately revoking and observing.
- **Silero VAD model presence** — bundled in whisper.cpp v1.8.x but not all binary distributions ship it; verify in Phase 1 with `whisper-cli --help | grep -i vad`.
- **Out-of-Scope items needing PROJECT.md addition** — anti-feature research surfaced six items already implied or explicit in PROJECT.md.
- **v1 must-have requirements not yet in PROJECT.md Active list** — features research surfaced these as v1 must-haves: custom vocab via `--prompt`, hallucination denylist + duration gate + VAD, clipboard preserve/restore, menu-bar visual indicator, audible start/stop cues, mic-permission failure detection with toast, empty-transcript silent abort. Should be reflected in REQUIREMENTS.md.

## Sources

### Primary (HIGH confidence)
- [whisper.cpp GitHub + Releases](https://github.com/ggml-org/whisper.cpp) — v1.8.4, Metal default, Silero VAD bundled, Core ML build path
- [Hammerspoon docs](https://www.hammerspoon.org/docs/) — pressedfn/releasedfn semantics, task signal handling, eventtap focus-race
- [Hammerspoon issues #644, #689, #922, #1963, #2275, #3016, #3301, #1263](https://github.com/Hammerspoon/hammerspoon/issues) — fn key as modifier, hs.task PATH on Apple Silicon, partial stdout
- [whisper.cpp issues #1592, #1724, #1831](https://github.com/ggml-org/whisper.cpp/issues) — silent-tail hallucination, "Thank you" insertion, language-detect ignored
- [Apple Developer — TCC + tccutil](https://developer.apple.com/forums/thread/679303), [HackTricks macOS TCC](https://angelica.gitbook.io/hacktricks/macos-hardening/macos-security-and-privilege-escalation/macos-security-protections/macos-tcc) — TCC primer + responsible-process semantics
- [nspasteboard.org spec](http://nspasteboard.org/) + [1Password/arboard](https://github.com/1Password/arboard) — Concealed/Transient pasteboard UTIs
- [Spellspoon](https://github.com/kevinjalbert/spellspoon), [local-whisper](https://github.com/luisalima/local-whisper), [yemreak/hammerspoon-dictation](https://github.com/yemreak/hammerspoon-dictation) — direct reference implementations

### Secondary (MEDIUM confidence)
- [Wispr Flow privacy + AirPod issues](https://docs.wisprflow.ai/articles/8533503284-knwon-audio-playback-airpod-issues-ios-macos) — informs anti-features and AirPods pitfall
- [SuperWhisper docs + Custom Mode](https://superwhisper.com/docs/modes/custom) — informs differentiator analysis
- [Voicci Apple Silicon Whisper benchmarks](https://www.voicci.com/blog/apple-silicon-whisper-performance.html), [llimllib mlx vs whisper.cpp Jan 2026](https://notes.billmill.org/dev_blog/2026/01/updated_my_mlx_whisper_vs._whisper.cpp_benchmark.html) — RTF data
- [Whisper prompt engineering — Medium](https://medium.com/axinc-ai/prompt-engineering-in-whisper-6bb18003562d) — 224-token cap + WER reduction figures for `--prompt`
- [Addy Osmani — Speech-to-Code Vibe Coding with Voice](https://addyo.substack.com/p/speech-to-code-vibe-coding-with-voice) — confirms natural-language-prompt is the modern voice-coding pattern

---
*Research completed: 2026-04-26*
*Ready for roadmap: yes*
