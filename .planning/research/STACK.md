# Stack Research

**Domain:** Local push-to-talk macOS dictation tool that injects transcripts into the focused application (Claude Code in a terminal).
**Researched:** 2026-04-23
**Overall confidence:** HIGH on hotkey/audio capture/orchestration, MEDIUM-HIGH on STT engine choice (clear winner emerges, but exact RTF varies by chip and is best confirmed with `hyperfine` on Oliver's actual machine).

---

## TL;DR — The Prescription

| Layer | Pick | Version | Confidence |
|---|---|---|---|
| Hotkey + injection orchestrator | **Hammerspoon** | 1.1.1 (Feb 2026) | HIGH |
| Audio capture | **sox** via CoreAudio | 14.4.2 | HIGH |
| STT engine | **whisper.cpp** (`whisper-cli`) with Core ML encoder | v1.8.4 (March 2025) | HIGH |
| Whisper model | **`small.en`** (default) with `medium.en` fallback build flag | ggml + Core ML encoder | MEDIUM-HIGH |
| Glue language | **bash** (one shell script invoked by Hammerspoon's `hs.task`) | system | HIGH |
| Persistent STT daemon (perf upgrade) | Optional: tiny **Go** wrapper or `whisper-server` over Unix socket | whisper.cpp `examples/server` | MEDIUM (defer to v1.1) |

**One-liner rationale:** whisper.cpp ships a single static binary with native Metal + ANE acceleration, installs in one `brew` command, has zero runtime dependencies, and on Apple Silicon hits sub-realtime latency on `small.en`. mlx-whisper is ~2× faster on `large-v3-turbo` but pays a 1–3 s Python interpreter + framework cold-start tax that destroys responsiveness for push-to-talk where the typical clip is 2–10 s. Hammerspoon natively supports `pressedfn`/`releasedfn` callbacks on `hs.hotkey.bind`, so push-and-hold is a one-liner. sox is the smaller, simpler tool for "record while a hotkey is held" — `ffmpeg -f avfoundation` works but is overkill (~80 MB binary, more complex CLI surface for a 16 kHz mono WAV).

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|---|---|---|---|
| **Hammerspoon** | 1.1.1 (released 2026-02-26) | Global hotkey, process orchestration, clipboard manipulation, `cmd+v` injection | Mature (12+ years), free, single .app, native Lua scripting. `hs.hotkey.bind(mods, key, pressedFn, releasedFn)` is a literal one-liner for push-to-talk. `hs.task` spawns child processes asynchronously without blocking the UI. `hs.pasteboard` + `hs.eventtap.keyStroke({"cmd"}, "v")` is the canonical injection path used by every Hammerspoon dictation project (Spellspoon, Dictator, BetterDictation, yemreak/hammerspoon-dictation). Min macOS 13.0 — fine for any M-series. |
| **sox (Sound eXchange)** | 14.4.2 | Capture mic audio to a temp WAV while hotkey is held | Native CoreAudio support: `sox -d -r 16000 -c 1 -b 16 /tmp/voicecc.wav` produces exactly the 16 kHz mono PCM whisper.cpp wants — no resample step. ~1 MB binary. `brew install sox` and you're done. Stable since 2015 (a feature, not a bug — the format conversion math doesn't need updating). Spawned from `hs.task`, killed on hotkey release with `SIGTERM`. |
| **whisper.cpp** (`whisper-cli`) | v1.8.4 (released 2025-03-19) | Local STT inference | Single statically-linked C++ binary. Native Metal backend (default on Apple Silicon). Optional Core ML encoder routes ANE for ~3× encoder speedup. Flash attention enabled by default since v1.8.0 (~30–50% speedup on M-series). VAD support (`--vad`) added recently — useful for trimming trailing silence that causes Whisper hallucinations on push-to-talk clips. Active maintenance (ggml-org), 30k+ stars, used in production by VoiceInk (4.3k stars), MacWhisper, BetterDictation, Spellspoon. `brew install whisper-cpp`. |
| **GGML model: `ggml-small.en.bin`** | Q5_0 quantized, ~190 MB | English-only Whisper small model | Best speed/accuracy point for short-form English dictation. small.en typically transcribes 5–10 s clips in ~0.3–0.6 s on M2 with Metal + Core ML encoder — meets the <2 s end-to-end budget with margin. medium.en is 4× the params (769M vs 244M) and 4× the latency for ~2–3 percentage points of WER improvement on conversational speech — not worth it for the dictation loop unless Oliver discovers small.en mis-transcribes domain jargon. |
| **bash** | system (3.2 or 5.x) | Glue: orchestrates `sox` → `whisper-cli` → `pbcopy` | One ~30-line script invoked by Hammerspoon. No interpreter to install, no venv to manage, no module imports to slow startup. Bash is the right tool for "wait for one process, then run another, then write to clipboard." |

### Supporting Libraries / Tools

| Library | Version | Purpose | When to Use |
|---|---|---|---|
| **Core ML model** (`ggml-small.en-encoder.mlmodelc`) | generated locally | ANE-accelerated encoder | Generate once via `models/generate-coreml-model.sh small.en`. ~3× faster encoder on first run after a one-time ANE compile (~30 s). HIGHLY recommended — measurable latency win for ~5 minutes of one-time setup. Built into whisper.cpp when compiled with `-DWHISPER_COREML=1`; the Homebrew formula does **not** ship Core ML support, so this requires a source build (see Installation below). |
| **ffmpeg** | 7.x | Optional alternative to sox; required by `parakeet-mlx` if you ever switch STT engines | Skip for v1. Only install if a specific dependency (e.g., a future MLX engine) requires it. |
| **pbcopy / pbpaste** | system | Clipboard write/read | Built into macOS. Used by the bash glue: `cat transcript.txt \| pbcopy`. Hammerspoon then synthesises `cmd+v`. |
| **Silero VAD model** (bundled by whisper.cpp v1.8.x) | v6.2.0 | Trim leading/trailing silence to reduce hallucination | Use `--vad --vad-threshold 0.5` flags on whisper-cli. Cheap insurance against the well-documented "Whisper invents text on silent tails" failure mode. |
| **hyperfine** | 1.18.x | Benchmarking harness | `brew install hyperfine`. Use during Phase 2 to measure end-to-end latency on Oliver's specific machine and pick the right model size empirically. |

### Development Tools

| Tool | Purpose | Notes |
|---|---|---|
| Xcode Command Line Tools | Required to build whisper.cpp from source for Core ML support | `xcode-select --install` |
| `cmake` | Build whisper.cpp | `brew install cmake` |
| Python 3.11 (one-shot, transient) | Convert Whisper PyTorch encoder → Core ML mlpackage | Only needed for the one-time Core ML model generation. After conversion, can be deleted. Uses `pip install ane_transformers openai-whisper coremltools`. Do NOT make Python a runtime dependency. |

---

## Installation

```bash
# Core runtime — five commands, no venv
brew install --cask hammerspoon
brew install sox
brew install whisper-cpp        # gets v1.8.x with Metal; no Core ML support in the bottle
brew install hyperfine          # for Phase 2 benchmarking only

# Whisper model (small.en is default; download once)
mkdir -p ~/.local/share/voice-cc/models
curl -L -o ~/.local/share/voice-cc/models/ggml-small.en.bin \
  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin
# Optional fallback: medium.en (~1.5 GB)
# curl -L -o ~/.local/share/voice-cc/models/ggml-medium.en.bin \
#   https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.en.bin

# OPTIONAL but RECOMMENDED: build whisper.cpp from source with Core ML for ANE acceleration
# (~5 min of setup buys ~3× encoder speedup)
git clone https://github.com/ggml-org/whisper.cpp.git ~/src/whisper.cpp
cd ~/src/whisper.cpp
python3.11 -m venv .venv && source .venv/bin/activate
pip install ane_transformers openai-whisper coremltools
./models/generate-coreml-model.sh small.en
mv models/ggml-small.en-encoder.mlmodelc ~/.local/share/voice-cc/models/
cmake -B build -DWHISPER_COREML=1 -DGGML_METAL=1
cmake --build build -j --config Release
# Binary at build/bin/whisper-cli — point your bash glue at this instead of the brew binary

# Hammerspoon: launch once, grant Accessibility + Mic in System Settings, drop init.lua in ~/.hammerspoon/
```

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|---|---|---|
| **whisper.cpp** | mlx-whisper | If batch-transcribing long audio (10+ min files) where the 1–3 s Python cold-start is amortised. For push-to-talk it loses on every dimension that matters: cold-start tax, install complexity (Python + MLX + venv), no native ANE path. Speed advantage (2× on `large-v3-turbo`) only manifests on models we shouldn't be running for short dictation anyway. |
| **whisper.cpp** | parakeet-mlx (NVIDIA Parakeet via MLX) | Genuinely tempting — Parakeet 0.6B v2 is reportedly ~3–10× faster than Whisper Large-v3-Turbo on Apple Silicon and was specifically trained on non-speech audio to suppress hallucinations (the #1 Whisper failure mode for push-to-talk). **Strongly consider for v1.1** once the v1 loop is stable. Defer because: (a) Python/MLX cold-start still applies, (b) parakeet-mlx is younger (~12 months), (c) WER is comparable to Whisper-Turbo, not better, so the win is speed and silence-handling, not accuracy. Revisit after Phase 3. |
| **whisper.cpp** | WhisperKit (Apple's Swift port) | If building a polished Swift app. Overkill for a personal CLI tool — adds Xcode project, framework imports, App Sandbox concerns. |
| **sox** | ffmpeg `-f avfoundation` | If you also need video, RTSP, or non-trivial filter graphs. For "record 16 kHz mono WAV from default mic", sox wins on size, simplicity, and clarity. ffmpeg device-index discovery (`ffmpeg -f avfoundation -list_devices true -i ""`) is more brittle than sox's `-d` (default input). |
| **sox** | Native AVFoundation Swift helper | If Hammerspoon ever proves limiting. Adds Swift toolchain + signed binary headache for zero functional gain over `sox -d`. |
| **Hammerspoon** | Karabiner-Elements | Karabiner is a kernel extension for key remapping; great for "tap-vs-hold" semantics on bare keys but doesn't expose process-spawning, async tasks, clipboard, or `cmd+v` injection. You'd end up needing both, and they have known interaction bugs (Karabiner intercepting events before Hammerspoon sees them). Skip. |
| **Hammerspoon** | skhd | Lightweight hotkey daemon designed for simple key→command bindings. **Does not natively expose key-release events** (it's press-only via the daemon's DSL). Not a fit for push-and-hold. |
| **Hammerspoon** | BetterTouchTool | Paid (~$22 lifetime). Functional but proprietary, GUI-driven config, harder to dotfile. Violates the "free + scriptable" constraint. |
| **Hammerspoon** | Native Swift LaunchAgent | Theoretically cleanest. Practically: you're writing your own `CGEventTap` for global hotkeys, your own `NSPasteboard` glue, your own `NSWorkspace` calls, signing the binary, dealing with App Sandbox. Hammerspoon already solved all this. Don't rebuild it. |
| **bash glue** | Python orchestrator | Adds ~150 ms interpreter startup per invocation and a venv to maintain. Bash has no interpreter cost (already loaded) and the orchestration is 30 lines of `sox & ; wait ; whisper-cli ; pbcopy`. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|---|---|---|
| **Cloud STT** (OpenAI Whisper API, Deepgram, AssemblyAI, Groq) | Violates the no-subscriptions / no-API-keys constraint stated in PROJECT.md. Adds a network round-trip (~200–500 ms) that blows the 2 s budget. Privacy regression — every utterance leaves the machine. | whisper.cpp local |
| **Talon Voice** | Dictation is a side feature; Talon is a full hands-free OS-control system requiring phonetic alphabet learning, custom Python "talon files", and community scripts. Months of ramp-up for a tool Oliver wants working in a weekend. The free tier works but the polished community models are paywalled (Patreon $25/mo). | whisper.cpp + Hammerspoon |
| **Aiko / Whisper Transcription / SuperWhisper / Wispr Flow** | Either GUI-only (Aiko) or subscription-based (Wispr Flow ~$15/mo, SuperWhisper has paid tier). Both are explicitly excluded by PROJECT.md. | Roll our own with the recommended stack |
| **OpenAI Whisper Python package** (the original `pip install openai-whisper`) | 5–10 s cold-start, requires PyTorch (~3 GB install), no Metal acceleration without third-party patches. Strictly worse than whisper.cpp on Apple Silicon for this use case. | whisper.cpp |
| **lightning-whisper-mlx** | Claims "10× faster than whisper.cpp" but the repo has been quiet for ~18 months, has known correctness issues with timestamps, and inherits the Python cold-start problem. Not in the "mature and well-maintained" tier. | whisper.cpp; revisit parakeet-mlx for v1.1 if speed becomes the bottleneck |
| **Apple's built-in Dictation** | Closed-source, can't be triggered programmatically with reliable hold-to-record semantics, model is meaningfully less accurate than Whisper small.en, and requires the system Dictation language toggle. The whole reason this project exists. | whisper.cpp |
| **whisper.cpp `examples/stream`** | Designed for *continuous* real-time streaming with sliding-window VAD, not push-to-talk. Adds SDL2 dependency, requires tuning step/length/VAD-threshold flags, and the README explicitly notes its VAD is "very basic". For PTT, plain `whisper-cli` on a complete WAV file is simpler, more accurate, and lower-latency for 2–10 s clips. | `whisper-cli` on the closed-out WAV |
| **Electron / Tauri / any web-shell wrapper** | Explicitly excluded by PROJECT.md ("no Electron"). Adds 100+ MB and seconds of startup. The whole stack should be invisible. | Hammerspoon's invisible background process |
| **Python web server / FastAPI / Flask wrapper around whisper** | Adds a daemon to manage, ports to bind, venv to maintain, ~500 ms uvicorn warmup. Overkill until/unless we need a long-lived warm-model process — and even then, whisper.cpp ships its own `whisper-server` binary that does this in C++ with no Python at all. | Native `whisper-cli` for v1; if cold-load latency is a problem, switch to whisper.cpp's bundled `whisper-server` over a Unix socket |

---

## Stack Patterns by Variant

**If end-to-end latency exceeds 2 s on `small.en` after warm-up:**
- The model load time (~200–500 ms for small.en off SSD) is being paid every invocation. Switch to a persistent warm process: run `whisper.cpp/build/bin/whisper-server` as a LaunchAgent, have the bash glue POST the WAV path to it. Inference time is unchanged but model-load is paid once at boot.

**If accuracy on technical/code-related vocabulary is poor:**
- Try `medium.en` first (4× slower but materially better on jargon). If still poor, use the `--prompt` flag with a hot-start prompt of likely terms ("Claude, Hammerspoon, npm, TypeScript, …"). This is a Whisper-native feature and meaningfully improves rare-word accuracy.

**If trailing-silence hallucinations appear** ("thanks for watching", "subscribe to my channel"):
- Add `--vad --vad-threshold 0.5` to `whisper-cli`. If still present, post-trim with `sox` using `silence -1 0.5 1%` to clip the tail before passing to whisper.

**If Oliver later wants toggle mode (v2 per PROJECT.md):**
- Same stack — Hammerspoon `hs.hotkey.bind` returns a hotkey object you can rebind. Add a state variable. No stack change.

**If a new release of Parakeet-MLX shows < 100 ms latency on small clips and stable maintenance:**
- Consider swapping the STT layer in v1.1. The bash glue is the abstraction boundary — only the STT command line changes; sox + Hammerspoon + clipboard injection stay identical.

---

## Version Compatibility

| Package A | Compatible With | Notes |
|---|---|---|
| Hammerspoon 1.1.1 | macOS 13.0+ | Min macOS bumped in 1.0; any M-series Mac is fine. |
| whisper.cpp v1.8.4 | macOS 14+ recommended | macOS Sonoma+ recommended to avoid older-CoreML hallucination issues called out by upstream. |
| whisper.cpp Core ML build | Python 3.11 (build-time only) | 3.12+ has known issues with `coremltools` conversion as of late 2025. Use 3.11 for the one-shot conversion. |
| `ggml-small.en.bin` (Q5_0) | whisper.cpp 1.5+ | All current versions; no version pin needed. |
| Core ML encoder `.mlmodelc` | Must match the GGML model | Generated alongside; ship them as a pair. |
| sox 14.4.2 | macOS 11+ (CoreAudio backend) | Stable since 2015 — no compatibility concerns on Apple Silicon. |

---

## Performance Notes (Verified Benchmarks)

| Setup | Hardware | Workload | Result | Source / Confidence |
|---|---|---|---|---|
| whisper.cpp `medium` model | M1 | 10-min audio | RTF 0.3 (~3 min wall) | voicci.com / MEDIUM |
| whisper.cpp `medium` model | M2 | 10-min audio | RTF 0.25 (~2.5 min wall) | voicci.com / MEDIUM |
| whisper.cpp `medium` model | M3 Pro | 10-min audio | RTF 0.15 (~1.5 min wall) | voicci.com / MEDIUM |
| whisper.cpp `medium` model | M4 Pro | 10-min audio | RTF 0.08 (~50 s wall) | voicci.com / MEDIUM |
| whisper.cpp `base.en` | M2 Pro | jfk.wav (~11 s) | 0.369 s total runtime | medium.com (Vashchuk) / MEDIUM |
| mlx-whisper vs whisper.cpp | unspecified Apple Silicon | `large-v3-turbo`, ~30 s clip | mlx 13.1 s vs cpp 26.7 s — mlx 2.03× faster | llimllib notes Jan 2026 / MEDIUM |
| Cold-start (CLI invocation) | any | small.en GGML model load from SSD | ~200–500 ms model load + ~50–150 ms binary init | inferred from CLI design + multiple sources / MEDIUM |
| Parakeet 0.6B on Apple Silicon | M-series | short clips | ~80 ms inference, 3–10× faster than Whisper-Turbo | dicta.to / whispernotes.app — LOW (vendor-adjacent), but consistent across multiple sources |

**Implication for our 2 s budget:** small.en cold-load (~400 ms) + sox stop overhead (~50 ms) + whisper-cli warmup (~100 ms) + inference on a 5 s clip at RTF 0.1–0.2 (~0.5–1 s) + pbcopy + cmd+v (~50 ms) = **~1.1–1.6 s end-to-end** for a typical short utterance on M2+. Comfortably under the 2 s target. medium.en would push to ~3–5 s — over budget.

---

## Sources

- [whisper.cpp GitHub](https://github.com/ggml-org/whisper.cpp) — version, build instructions, Core ML setup. HIGH confidence.
- [whisper.cpp Releases](https://github.com/ggml-org/whisper.cpp/releases) — v1.8.4 (March 2025), flash attention default, Silero VAD integration. HIGH.
- [Homebrew whisper-cpp formula](https://formulae.brew.sh/formula/whisper-cpp) — installation. HIGH.
- [Homebrew sox formula](https://formulae.brew.sh/formula/sox) — installation, version. HIGH.
- [Hammerspoon hs.hotkey docs](https://www.hammerspoon.org/docs/hs.hotkey.html) — `pressedfn`/`releasedfn`/`repeatfn` callback signature, native PTT support. HIGH.
- [Hammerspoon Releases](https://github.com/Hammerspoon/hammerspoon/releases) — v1.1.1 (2026-02-26), min macOS 13. HIGH.
- [VoiceInk source](https://github.com/Beingpax/VoiceInk) — confirms whisper.cpp is the production-tier choice for Mac dictation apps in 2025/2026. HIGH.
- [llimllib mlx vs whisper.cpp benchmark (Jan 2026)](https://notes.billmill.org/dev_blog/2026/01/updated_my_mlx_whisper_vs._whisper.cpp_benchmark.html) — 2.03× speedup for mlx on `large-v3-turbo`. MEDIUM (single benchmark, hardware not disclosed).
- [Voicci Apple Silicon Whisper benchmarks](https://www.voicci.com/blog/apple-silicon-whisper-performance.html) — RTF table M1→M4 for medium model. MEDIUM (single source, methodology not deeply documented).
- [parakeet-mlx](https://github.com/senstella/parakeet-mlx) — confirms NVIDIA Parakeet runs on Apple Silicon via MLX, latest release Feb 2026. HIGH (existence + maturity), MEDIUM on perf claims.
- [Dicta.to Parakeet vs Whisper vs Apple Speech (2026)](https://dicta.to/blog/whisper-vs-parakeet-vs-apple-speech-engine/) — 80 ms latency claim for Parakeet. LOW-MEDIUM (vendor-adjacent blog, but consistent with multiple other sources).
- [whisper.cpp Issue #1724 — Hallucination on silence](https://github.com/ggml-org/whisper.cpp/issues/1724) — confirms the silent-tail hallucination failure mode is real and common. HIGH.
- [whisper.cpp `examples/stream` README](https://github.com/ggml-org/whisper.cpp/blob/master/examples/stream/README.md) — confirms stream example is for continuous use, not PTT; requires SDL2. HIGH.
- [Spellspoon](https://github.com/kevinjalbert/spellspoon), [yemreak/hammerspoon-dictation](https://github.com/yemreak/hammerspoon-dictation), [Dictator HN thread](https://news.ycombinator.com/item?id=46443082) — multiple existing implementations of exactly this pattern (Hammerspoon + audio capture + Whisper-class STT) confirm the architecture is proven. HIGH.
- [Talon EULA + pricing](https://talonvoice.com/) — confirms Talon is too heavyweight a paradigm for pure dictation. HIGH.

---

*Stack research for: local push-to-talk macOS dictation tool*
*Researched: 2026-04-23*
