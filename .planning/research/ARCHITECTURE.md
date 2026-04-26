# Architecture Research

**Domain:** Local push-to-talk macOS dictation tool (voice-cc) — Hammerspoon (Lua) hotkey + sox audio + whisper.cpp STT + clipboard injection into the focused terminal (Claude Code).
**Researched:** 2026-04-23
**Confidence:** HIGH on process model, data flow, and component boundaries (validated against two reference implementations: Spellspoon and local-whisper). HIGH on file layout (XDG conventions are settled). MEDIUM-HIGH on the warm-process upgrade path (whisper-server ships in whisper.cpp `examples/server` and is HTTP/JSON over localhost — straightforward, not yet stress-tested for our specific clip pattern).

---

## TL;DR — The Architecture in One Paragraph

**One-shot CLI per utterance, orchestrated by a single bash script that Hammerspoon spawns on hotkey press and signals on release.** No daemon. No shared state beyond the temp WAV path on disk. Hammerspoon owns the UX (hotkey, indicator, paste, clipboard preserve/restore); bash owns the pipeline (sox → whisper-cli → post-filter → pbcopy → write last-transcript marker); whisper.cpp owns inference. The seams are deliberately small: Hammerspoon launches one command and waits for one exit code; bash glues three CLIs together with files. The warm-process upgrade (`whisper-server` over localhost HTTP, managed by a LaunchAgent) is preserved as a v1.x drop-in by isolating the "transcribe a WAV" call to one bash function — when small.en cold-load becomes the bottleneck, swap that function from `whisper-cli ...` to `curl http://127.0.0.1:8080/inference -F file=@...` and nothing else changes.

---

## Process Model

### Decision: One-shot CLI per utterance (v1)

| Option | Cold-start cost | Complexity | Robustness | Verdict |
|---|---|---|---|---|
| **One-shot CLI per utterance** | ~200–500 ms model load + ~100 ms binary init per invocation | Lowest — no IPC, no daemon, no plist | Highest — every invocation is independent; a crash affects one utterance, not the system | **Pick for v1** |
| Long-running custom daemon (Go/Rust wrapper) | Zero after first load | Highest — hand-rolled IPC, lifecycle management, signals, log rotation, restart logic | Medium — daemon bugs persist across utterances | Skip — over-engineered for the budget |
| `whisper-server` warm process via LaunchAgent | Zero after first load | Medium — uses whisper.cpp's bundled HTTP server; LaunchAgent plist; bash glue switches to `curl` | Medium-high — server is upstream-maintained C++; LaunchAgent restarts on crash via `KeepAlive` | **Reserve for v1.1** if STACK.md's ~1.1–1.6 s budget proves tight |

### Why one-shot wins for v1

- The total **cold-start tax is ~300–600 ms** (model load + binary init), comfortably inside the 2 s budget. STACK.md's measured envelope of 1.1–1.6 s end-to-end on M2+ already includes this.
- Every utterance is **failure-isolated**. If whisper-cli segfaults on one weird clip, the next press works fine. No restart logic, no "is the daemon alive?" health checks.
- **No state to corrupt, no port to bind, no stale lockfiles, no LaunchAgent plist to debug.** This matches the "invisible, unattended" target — the right number of moving parts you can't see is zero.
- The reference implementations (Spellspoon, local-whisper) both use this model and it works.

### Why warm-process is the upgrade path, not the default

- The win is real but small (~300–500 ms saved per utterance) and only materialises **after** v1 is validated. Until we have measurement data on Oliver's actual M-series hardware, we don't know if we need it.
- whisper-server is an upstream-maintained binary in `examples/server` — HTTP over `127.0.0.1:8080`, multipart form upload, JSON response. Drop-in replaceable behind a one-line bash function (`transcribe_wav()`).
- LaunchAgent boilerplate is one plist file with `KeepAlive=true` and `RunAtLoad=true`. ~30 lines of XML; easy to ship in v1.1.

### Upgrade trigger

Add `whisper-server` mode in v1.x **if and only if** `hyperfine` measurements show end-to-end latency >2.0 s on Oliver's machine with `small.en` + Core ML encoder. Until then: don't pay the complexity tax.

---

## System Overview

```
┌──────────────────────────────────────────────────────────────────────┐
│                            User Input                                 │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  Push-and-hold global hotkey (e.g. cmd+option+space, fn, F19)  │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────┬───────────────────────────────────┘
                                   │ press / release
                                   ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    Hammerspoon (~/.hammerspoon/init.lua)             │
│                          UX + Orchestration Layer                    │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  hs.hotkey.bind(mods, key, onPress, onRelease)              │   │
│  │  hs.menubar  ── recording indicator (dot turns red)         │   │
│  │  hs.sound    ── start / stop / cancel cues                  │   │
│  │  hs.task     ── spawns the bash pipeline; signals on release│   │
│  │  hs.pasteboard / hs.eventtap.keyStroke({"cmd"}, "v")        │   │
│  │  hs.notify   ── error toasts (mic denied, model missing)    │   │
│  └─────────────────────────┬────────────────────────────────────┘   │
└────────────────────────────┼─────────────────────────────────────────┘
                             │ spawn  + SIGTERM
                             ▼
┌──────────────────────────────────────────────────────────────────────┐
│             bash glue:  ~/.local/bin/voice-cc-record                 │
│                  Pipeline / Filter / Lifecycle Layer                 │
│                                                                      │
│   ┌──────────┐    SIGTERM   ┌───────────────┐    exit code           │
│   │   sox    │◄─────────────│ trap handler  │──► closes WAV          │
│   │ (record) │              │ on release    │                        │
│   └────┬─────┘              └───────────────┘                        │
│        │ /tmp/voice-cc/utterance.wav                                 │
│        ▼                                                             │
│   ┌──────────────┐  duration < 250ms? ──► abort silently             │
│   │ duration gate│  (read with `soxi -D`)                            │
│   └────┬─────────┘                                                   │
│        ▼                                                             │
│   ┌──────────────┐                                                   │
│   │ transcribe() │  ◄── single function abstraction                  │
│   │              │      v1:  whisper-cli --vad --prompt "$(cat vocab)"│
│   │              │      v1.1: curl 127.0.0.1:8080/inference -F file= │
│   └────┬─────────┘                                                   │
│        ▼                                                             │
│   ┌────────────────────────┐                                         │
│   │ post-filter            │                                         │
│   │  • trim whitespace     │                                         │
│   │  • denylist (5 phrases)│                                         │
│   │  • apply replacements  │ (v1.x)                                  │
│   │  • drop if empty       │                                         │
│   └────┬───────────────────┘                                         │
│        ▼                                                             │
│   ┌──────────────────────────┐                                       │
│   │ write transcript →       │                                       │
│   │   stdout (read by Lua)   │                                       │
│   │   ~/.cache/voice-cc/last │                                       │
│   │   ~/.cache/voice-cc/log  │ (v1.x)                                │
│   └──────────────────────────┘                                       │
└─────────────────────────────────┬────────────────────────────────────┘
                                  │ stdout = transcript
                                  ▼
┌──────────────────────────────────────────────────────────────────────┐
│                  Hammerspoon (callback on task exit)                 │
│                                                                      │
│   1. Read transcript from task stdout                                │
│   2. Save current pasteboard:  saved = hs.pasteboard.getContents()   │
│   3. Set pasteboard:           hs.pasteboard.setContents(transcript) │
│   4. Synthesize paste:         hs.eventtap.keyStroke({"cmd"}, "v")   │
│   5. After 250 ms:             hs.pasteboard.setContents(saved)      │
│   6. Update menubar dot back to idle                                 │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Component Responsibilities

| Component | Owns | Doesn't Own | Implementation |
|-----------|------|-------------|----------------|
| **Hammerspoon `init.lua`** | Hotkey press/release events, menubar indicator, audible cues, clipboard preserve/restore, paste keystroke, error notifications, lifetime of the bash subprocess | Audio capture, transcription, file I/O on the WAV, vocab/prompt assembly | Lua, ~150 lines |
| **`voice-cc-record` (bash)** | sox lifecycle, WAV file location, duration gate, calling transcribe(), post-filter (denylist, whitespace, empty-drop), writing last-transcript marker, exit codes for Lua to act on | Hotkey detection, paste, clipboard, UI feedback | bash, ~80 lines |
| **`transcribe()` bash function** | The *one* abstraction boundary between voice-cc and the STT engine. v1: invokes `whisper-cli` with vocab `--prompt`. v1.1: POSTs WAV to `whisper-server` over HTTP. | Anything except producing transcript text from a WAV path | bash function, ~10 lines |
| **`sox`** | Capturing 16 kHz mono WAV from default mic until SIGTERM | Format conversion (none needed), VAD (whisper does it), permission handling (it just exits non-zero) | brew binary |
| **`whisper-cli`** (or `whisper-server` in v1.1) | STT inference, `--vad`, `--prompt` conditioning, JSON or text output | Audio capture, post-processing of output text | brew binary (or source build with Core ML) |
| **`pbcopy` / `pbpaste`** | Clipboard read/write at the shell level (used by bash glue's last-transcript marker write — though Hammerspoon's `hs.pasteboard` is preferred for the actual paste) | The paste keystroke itself | macOS built-in |
| **Vocab file** (`~/.config/voice-cc/vocab.txt`) | Domain terms passed via `--prompt` (Anthropic, Hammerspoon, MCP, npm, …) | Anything else | plain text, <224 tokens |
| **Replacements file** (v1.x, `~/.config/voice-cc/replacements.txt`) | Tab-separated find→replace pairs ("Versel\tVercel") applied as `sed` post-filter | | plain text |
| **Denylist** (embedded in bash glue or `~/.config/voice-cc/denylist.txt`) | Top 5 known hallucination phrases dropped from output | | plain text |
| **Models directory** (`~/.local/share/voice-cc/models/`) | `ggml-small.en.bin`, optional `ggml-small.en-encoder.mlmodelc`, optional `ggml-medium.en.bin` | Anything mutable | static blobs |

### What Lives Where (Summary)

| Layer | Tech | Why |
|---|---|---|
| **Hotkey + UX + paste** | Hammerspoon (Lua) | Hammerspoon owns macOS event handling, clipboard, keystroke synthesis. No need for a second event loop. |
| **Pipeline glue** | bash | sox + whisper-cli + post-filter is literal pipe-and-wait. Bash is the right tool. No interpreter cost, no venv. |
| **Inference** | C++ binary on PATH | whisper.cpp ships a static binary. Treat it as an opaque CLI. |
| **Config** | Plain text in `~/.config/voice-cc/` | Dotfile-able, grep-able, version-controllable, no parser needed. |
| **State** | Almost none — see State Model below | The fewer pieces of state, the fewer bugs. |

---

## Data Flow

### Single-utterance flow (the only path that matters)

```
T+0ms     User presses cmd+option+space
          ├─ Hammerspoon onPress fires
          ├─ Plays start.aiff (async, fire-and-forget)
          ├─ Sets menubar dot to red
          ├─ Spawns: hs.task.new("/Users/oliver/.local/bin/voice-cc-record", onExit)
          │           └─ task starts; bash script begins running
          │              └─ sox -d -r 16000 -c 1 -b 16 /tmp/voice-cc/utterance.wav &
          │                 SOX_PID=$!
          │              └─ trap "kill -TERM $SOX_PID" SIGTERM
          │              └─ wait $SOX_PID   # block until sox exits

T+1500ms  User releases cmd+option+space
          ├─ Hammerspoon onRelease fires
          ├─ Plays stop.aiff
          ├─ Calls task:terminate()  # sends SIGTERM
          │   └─ bash script's trap fires, kills sox -TERM
          │      └─ sox finalizes WAV header, exits 0
          │   └─ wait returns; script continues:
          │      ├─ DUR=$(soxi -D /tmp/voice-cc/utterance.wav)
          │      ├─ if (DUR < 0.25) exit 2   # silent abort
          │      ├─ TRANSCRIPT=$(transcribe /tmp/voice-cc/utterance.wav)
          │      │   └─ whisper-cli -m model.bin --vad --prompt "$(cat vocab.txt)" \
          │      │                  -f /tmp/voice-cc/utterance.wav --no-timestamps -otxt
          │      │      └─ writes /tmp/voice-cc/utterance.txt; reads back
          │      ├─ TRANSCRIPT=$(echo "$TRANSCRIPT" | post_filter)
          │      ├─ if [ -z "$TRANSCRIPT" ] exit 3   # empty abort
          │      ├─ echo "$TRANSCRIPT" > ~/.cache/voice-cc/last.txt
          │      └─ printf "%s" "$TRANSCRIPT"   # to stdout
          │
T+2700ms  Bash script exits 0 (success path)
          ├─ Hammerspoon onExit callback fires with stdout=TRANSCRIPT, exitCode=0
          ├─ saved = hs.pasteboard.getContents()
          ├─ hs.pasteboard.setContents(TRANSCRIPT)
          ├─ hs.eventtap.keyStroke({"cmd"}, "v")
          ├─ hs.timer.doAfter(0.25, function() hs.pasteboard.setContents(saved) end)
          ├─ Sets menubar dot back to idle
          └─ Done. (Total: ~2.7 s in this example; <2 s for shorter clips)
```

### Why files, not pipes or sockets, for the WAV

| Mechanism | Verdict |
|---|---|
| **File on disk (`/tmp/voice-cc/utterance.wav`)** | **Pick.** sox writes a proper WAV with a complete header on graceful exit. whisper-cli reads files. Nothing fancy needed. Cleanup: `rm` after transcription. |
| Named pipe (FIFO) between sox and whisper | Tempting but wrong — whisper needs the *complete* WAV (it processes the whole clip, not streaming), so the pipe would just be a slow file. |
| Unix socket | Same problem as FIFO. |
| In-memory only | sox can't write to whisper-cli stdin in WAV format reliably (header-at-end with `--show-progress` issues). Files just work. |

**Why one named WAV** (not a per-utterance UUID):
- v1 has no concurrent-utterance support (the hotkey is push-and-hold; you can't be holding it twice). One file, overwritten each utterance, atomically replaced.
- Cleanup is trivial. Disk usage is bounded (one WAV at a time, ~100 KB for a 5 s clip).
- If we ever want concurrent or queued mode, switch to UUID-named files in the same directory. Single point of change.

### Why the transcript flows back via stdout

- `hs.task` natively captures stdout in its exit callback. Zero glue.
- No need for a sidechannel file (though we *also* write `~/.cache/voice-cc/last.txt` for the v1.x paste-last-transcript hotkey — that's a deliberate redundancy, not a primary path).
- bash's `printf "%s"` (no trailing newline) gives Hammerspoon the exact bytes to set on the clipboard.

### Exit codes as control plane

bash glue exits with semantic codes; Lua dispatches:

| Exit code | Meaning | Hammerspoon action |
|---|---|---|
| 0 | Success — transcript on stdout | Paste path (preserve clipboard, set, cmd+v, restore) |
| 2 | Silent abort: clip too short | No-op (just reset indicator) |
| 3 | Silent abort: empty transcript after filter | No-op (just reset indicator) |
| 10 | Mic permission denied (sox returned non-zero with TCC error) | `hs.notify` "Grant Microphone access in System Settings" + open settings URL |
| 11 | Model file missing | `hs.notify` "Run install.sh to download whisper model" |
| 12 | whisper-cli failed (segfault, OOM, malformed WAV) | `hs.notify` "Transcription failed — check ~/.cache/voice-cc/log" |
| other | Unknown failure | `hs.notify` generic + log exit code |

This is the entire control protocol between bash and Lua. No JSON parsing, no IPC framework, no shared state file.

---

## State Model

### Decision: Almost stateless

The only persistent state across utterances:

| State | Where | Why it exists | Lifetime |
|---|---|---|---|
| **`isRecording` flag** (Lua-local) | In-memory in `init.lua` | Prevents re-entrancy if hotkey events somehow double-fire; gated check at top of onPress | Process lifetime of Hammerspoon |
| **`currentTask` handle** (Lua-local) | In-memory in `init.lua` | So onRelease has something to call `:terminate()` on | Single utterance |
| **`savedClipboard`** (Lua-local) | In-memory in `init.lua` | So we can restore after paste | ~250 ms (between paste and restore) |
| **`/tmp/voice-cc/utterance.wav`** | tmpfs | The audio buffer, one at a time | Lifetime of single utterance; overwritten on next |
| **`~/.cache/voice-cc/last.txt`** | Disk | Backup of last transcript for paste-last hotkey (v1.x) | Until next successful transcription |
| **`~/.cache/voice-cc/log`** (v1.x) | Disk | Rolling log of `[timestamp]\t[transcript]` for debugging | Manual rotation (or via `logrotate`) |
| **Models, vocab, replacements** | Disk | Configuration | User-managed |

### Anti-state (what we explicitly don't have)

- **No queue of pending transcriptions.** PTT is by definition one-at-a-time; the hotkey can't be re-pressed mid-flight. If user spams the key, ignore press while `isRecording==true`.
- **No history database.** v1.x adds an append-only text log; that's it. No SQLite, no cross-process indexing.
- **No "last app focused" memory.** We paste into whatever has focus *now*, at paste time. If the user changed windows during transcription, that's their action — we honor focus, not history.
- **No retry queue.** A failed transcription is a failed utterance. User retries by pressing the hotkey again.
- **No IPC state file.** `/tmp/voice-cc/` exists for the WAV only; no `.lockfile`, no `.recording`, no PID file.
- **No daemon process.** Hammerspoon is the only long-running thing, and it's already running for everything else.

### Why this minimalism is correct

Every piece of cross-utterance state is a potential bug source: stale lockfiles, mismatched flags, queue overflow, race conditions on history append. The PTT model is intrinsically stateless ("hold key → talk → release → text") and the architecture should mirror that.

The reference implementations confirm this: Spellspoon stores stats in SQLite (a feature we explicitly defer), and local-whisper writes refine/prompt config files that are *read*, not *coordinated*. Neither holds active state across utterances.

### Concurrency

There is no concurrency to manage. The hotkey is held by a human; humans can hold one key at a time. If a second hotkey press occurs while `isRecording==true`, drop it on the floor (ignore in onPress, no notification needed). This is the simplest possible mutex.

---

## Failure Boundaries & Handling

This is the matrix of what can go wrong and what catches each failure.

| Failure | Where it manifests | Detection | Handling | User-visible result |
|---|---|---|---|---|
| **Hotkey released before sox started capturing** (sub-50 ms tap) | `hs.task` may not have spawned yet on terminate() call | `hs.task` `onExit` fires with exit code from sox (likely 0 with empty WAV) | Duration gate (DUR<0.25) catches it | Silent (no paste, no error toast); menubar resets |
| **Hotkey released so quickly that audio is <250 ms** | Tiny WAV file | `soxi -D` in bash glue | `exit 2` → Lua no-op | Silent |
| **Mic permission denied (TCC silent-deny)** | sox returns non-zero with stderr containing "Permission denied" or "AudioObject" error | bash glue checks sox exit + greps stderr → `exit 10` | Lua: `hs.notify` "Grant Microphone access" + URL to System Settings → Privacy & Security → Microphone | Toast notification with actionable link |
| **sox process dies mid-recording (rare; likely OS audio glitch)** | sox exits non-zero before SIGTERM | bash glue: WAV may be unfinalized; `soxi -D` fails or returns 0 | `exit 12` → "Transcription failed" toast | Toast; mic indicator should clear via sox cleanup |
| **`whisper-cli` binary missing from PATH** | bash `command -v whisper-cli` check at script start | `exit 11` (treat as install issue) | "Run install.sh — whisper-cli not on PATH" toast | Toast |
| **Model file missing** | whisper-cli exits with "failed to load model" | bash detects → `exit 11` | "Run install.sh to download model" toast | Toast |
| **whisper-cli segfaults / OOM / produces garbage** | Non-zero exit or empty output | bash detects → `exit 12` | "Transcription failed" toast; WAV path logged | Toast; user can re-record |
| **Whisper hallucinates "thanks for watching" on silent tail** | Output text matches denylist | post-filter drops if line matches denylist (case-insensitive trim) | If full output dropped → `exit 3` (silent); else paste cleaned text | Either silent (rare) or user just sees clean transcript |
| **Paste target loses focus mid-transcribe** | Lua's `cmd+v` lands in different window | Not detectable — we paste into whatever has focus | **Accept this.** Document in README. v1.x adds paste-last-transcript hotkey to recover. | Text appears in unintended window |
| **Hammerspoon task captures only partial stdout (output buffer issue)** | Documented `hs.task` issue when subprocess produces output after exit code | Limit stdout to single line of transcript; everything else goes to stderr (not captured by `hs.task` callback) | Mitigated by writing transcript file *before* echoing to stdout — Lua can fall back to reading `~/.cache/voice-cc/last.txt` if stdout was truncated | Robust to the known Hammerspoon bug |
| **Hammerspoon process crashes mid-utterance** | Recording stuck, mic indicator stuck on | macOS will eventually reap orphaned sox via parent-death tracking; bash glue uses `set -m` and `trap "kill 0" EXIT` so sox dies with the script | Hammerspoon auto-relaunches via its built-in crash recovery (or relaunch script); WAV is stale but harmless on next utterance (overwritten) | Brief flicker; one lost utterance |
| **User holds hotkey for 2+ minutes** | Huge WAV, long inference, possible whisper-cli OOM on `small.en` (still fits in ~2 GB RAM) | Bash glue: `MAX_DURATION=120` cap via `timeout 120 sox ...` | If hit: still transcribe what we got; succeed with whatever fits | Long wait; eventually pastes |
| **Disk full when sox tries to write WAV** | sox exits non-zero | Bash detects | `exit 12` "Transcription failed" toast | Toast |
| **Two hotkey presses in quick succession (re-entrancy)** | Lua `isRecording` flag still true | Guard at top of onPress: `if isRecording then return end` | Second press ignored | No effect (not even an indicator change) |
| **Accessibility permission revoked** | `hs.eventtap.keyStroke` silently fails — text is on clipboard but not pasted | Hard to detect from Hammerspoon; Hammerspoon logs the eventtap rejection | Restore clipboard anyway after delay; show notification "Grant Accessibility access — re-paste manually with cmd+v" | Toast; user can manually paste from clipboard |

### Failure handling principles

1. **Fail silently for "normal" non-events** (too-short clip, empty transcript). Don't spam the user with "no speech detected" — it's annoying. Just reset the indicator.
2. **Toast loudly for permission and install issues** with an actionable next step ("Open System Settings", "Run install.sh"). These are the only failures the user can fix.
3. **Always clean up the WAV.** Bash glue: `trap "rm -f $WAV" EXIT` so we never leak.
4. **Always clean up the menubar indicator.** Lua: wrap onExit in `pcall` or `xpcall` so an unhandled error in the callback still resets the dot.
5. **Idempotent restart.** If anything is stuck, `killall sox; killall whisper-cli; rm -rf /tmp/voice-cc; reload Hammerspoon` brings everything back to clean. No state to recover.

---

## File Layout

### On-disk layout

```
~/.hammerspoon/
└── init.lua                              # main config; loads voice-cc.lua
└── voice-cc/
    ├── init.lua                          # the voice-cc Hammerspoon module
    └── README.md                         # how to wire into your hammerspoon

~/.config/voice-cc/                       # XDG config — user-editable, dotfile-able
├── config.sh                             # shell vars: MODEL, HOTKEY, ENABLE_SOUNDS, MAX_DURATION
├── vocab.txt                             # comma-separated terms for --prompt (<224 tokens)
├── replacements.txt                      # (v1.x) tab-separated from→to pairs
└── denylist.txt                          # (optional override) one phrase per line

~/.local/share/voice-cc/                  # XDG data — large, downloaded, machine-specific
└── models/
    ├── ggml-small.en.bin                 # ~190 MB, default model
    ├── ggml-small.en-encoder.mlmodelc/   # Core ML encoder (optional, recommended)
    └── ggml-medium.en.bin                # (optional fallback, ~1.5 GB)

~/.local/bin/                             # user PATH; install.sh symlinks here
└── voice-cc-record                       # the bash glue script (callable directly for debugging)

~/.cache/voice-cc/                        # XDG cache — disposable, regenerable
├── last.txt                              # last successful transcript (paste-last hotkey)
├── log                                   # (v1.x) rolling [timestamp]\t[transcript] log
└── error.log                             # bash glue stderr capture for debugging

/tmp/voice-cc/                            # transient — single utterance only
└── utterance.wav                         # current/last recording
└── utterance.txt                         # whisper-cli output buffer

~/Library/LaunchAgents/                   # (v1.1 only) for whisper-server warm process
└── com.olivergallen.voice-cc-server.plist
```

### Repo layout (the project itself)

```
voice-cc/
├── README.md                             # install + usage + troubleshooting
├── install.sh                            # idempotent setup
├── uninstall.sh                          # reverse of install
├── bin/
│   └── voice-cc-record                   # the bash glue (installed to ~/.local/bin/)
├── hammerspoon/
│   └── voice-cc/
│       ├── init.lua                      # the Lua module (installed to ~/.hammerspoon/voice-cc/)
│       └── README.md                     # how to require() it from your init.lua
├── config/
│   ├── config.sh.example                 # template (installed to ~/.config/voice-cc/)
│   ├── vocab.txt.example
│   └── denylist.txt
├── launchagents/                         # (v1.1)
│   └── com.olivergallen.voice-cc-server.plist.template
├── models/
│   └── README.md                         # how to download via install.sh
├── docs/
│   ├── ARCHITECTURE.md                   # this doc, ported in
│   ├── PERMISSIONS.md                    # mic + accessibility setup
│   └── TROUBLESHOOTING.md
└── .planning/                            # gsd planning artifacts (gitignored or kept, TBD)
```

### Why XDG (`~/.config/`) not `~/Library/Application Support/`

voice-cc is a CLI tool with dotfile-style config. Convention for CLI tools on macOS is XDG:

- `~/.config/<app>/` for editable config (vocab, replacements, hotkey choice)
- `~/.local/share/<app>/` for large data (models)
- `~/.cache/<app>/` for regenerable state (logs, last transcript)
- `~/.local/bin/` for user-PATH binaries

This matches the convention used by `gh`, `git`, `kubectl`, `docker`, `terraform`, `op`, `stripe`, and most CLI tooling on macOS in 2026. `~/Library/Application Support/` is for GUI apps (where finder visibility and macOS bundle integration matters); we have neither.

### `install.sh` idempotency

The script must be safe to re-run. Each step:

```bash
#!/usr/bin/env bash
set -euo pipefail

# 1. Homebrew packages (brew is idempotent already)
brew list hammerspoon &>/dev/null || brew install --cask hammerspoon
brew list sox &>/dev/null || brew install sox
brew list whisper-cpp &>/dev/null || brew install whisper-cpp

# 2. Directories (mkdir -p is idempotent)
mkdir -p "$HOME/.config/voice-cc"
mkdir -p "$HOME/.local/share/voice-cc/models"
mkdir -p "$HOME/.cache/voice-cc"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.hammerspoon/voice-cc"

# 3. Models (curl with -C - resumes; check existence first)
MODEL="$HOME/.local/share/voice-cc/models/ggml-small.en.bin"
[ -f "$MODEL" ] || curl -L -C - -o "$MODEL" https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin

# 4. Configs (only copy if missing — don't clobber user edits)
[ -f "$HOME/.config/voice-cc/config.sh" ] || cp config/config.sh.example "$HOME/.config/voice-cc/config.sh"
[ -f "$HOME/.config/voice-cc/vocab.txt" ] || cp config/vocab.txt.example "$HOME/.config/voice-cc/vocab.txt"
cp config/denylist.txt "$HOME/.config/voice-cc/denylist.txt"  # always overwrite — we own this

# 5. Symlinks (ln -sf is idempotent)
ln -sf "$(pwd)/bin/voice-cc-record" "$HOME/.local/bin/voice-cc-record"

# 6. Hammerspoon module (rsync preserves user edits to their init.lua;
#    only ships our module to ~/.hammerspoon/voice-cc/)
rsync -a hammerspoon/voice-cc/ "$HOME/.hammerspoon/voice-cc/"

# 7. Reminder for one-time manual steps (not idempotent — but safe to print)
echo "Setup complete. Manual steps:"
echo "  1. Add to ~/.hammerspoon/init.lua:  require('voice-cc')"
echo "  2. Reload Hammerspoon (menubar → Reload Config)"
echo "  3. Grant Microphone + Accessibility when prompted"
```

Key idempotency rules:
- **Never overwrite user-editable config** (`config.sh`, `vocab.txt`) — only copy if absent.
- **Always overwrite project-owned files** (`denylist.txt`) — we update this with new known-hallucinations.
- **Use `ln -sf`** for the binary so updates to the repo immediately reflect.
- **Use `rsync -a`** for the Lua module so changes propagate without disturbing the user's broader `init.lua`.
- **Don't auto-edit the user's `init.lua`** — print the one-liner they need to add. Auto-editing is the #1 source of "install.sh broke my setup" bug reports.

---

## Build Order (What Blocks What)

This determines phase ordering in the roadmap.

```
Phase 1: Spike — prove the loop works at all
  ├─ STEP 1.1: Manual sox recording → manual whisper-cli → manual paste
  │            (no Hammerspoon yet; just shell + finder)
  │            Validates: model works on Oliver's machine, latency budget hits, vocab.txt helps
  │
  ├─ STEP 1.2: bash glue script (sox → whisper-cli → stdout)
  │            Validates: pipeline composes; exit codes work; duration gate works
  │            UNBLOCKS: Hammerspoon integration (the script is the contract)
  │
  └─ STEP 1.3: Minimal Hammerspoon init.lua (hotkey → spawn script → paste stdout)
              Validates: end-to-end loop. THIS IS THE MILESTONE.

Phase 2: Hardening — make the loop robust
  ├─ STEP 2.1: Hallucination guards (VAD flag + denylist)
  ├─ STEP 2.2: Clipboard preserve/restore
  ├─ STEP 2.3: Permission failure detection (TCC silent-deny → toast)
  ├─ STEP 2.4: Empty/short-clip silent abort
  └─ STEP 2.5: Menubar dot indicator + audible cues

Phase 3: Distribution — make it reproducible
  ├─ STEP 3.1: install.sh + uninstall.sh
  ├─ STEP 3.2: Core ML encoder build (optional but documented)
  ├─ STEP 3.3: README + troubleshooting docs
  └─ STEP 3.4: hyperfine benchmarking on Oliver's actual hardware → tune model choice

Phase 4 (v1.x): Quality-of-life
  ├─ Paste-last-transcript hotkey
  ├─ Cancel-in-flight (Esc while recording)
  ├─ Custom replacements file
  ├─ Rolling history log

Phase 5 (v1.1, conditional): Warm process upgrade
  └─ ONLY IF Phase 3.4 measurements show >2s latency:
     ├─ Build whisper.cpp with whisper-server example
     ├─ LaunchAgent plist
     ├─ Swap transcribe() bash function: whisper-cli → curl POST
     └─ Validates: latency now <1s; same UX, faster
```

### Critical "must exist before X" relationships

| Before you can build | You must have |
|---|---|
| Any Lua hotkey wiring | A working bash glue script you can spawn (otherwise you have nothing to test the spawn against) |
| A working bash glue script | A working `sox -d ... && whisper-cli ...` pipeline (otherwise the script has nothing to glue) |
| A working pipeline | The model downloaded and `whisper-cli` on PATH |
| Clipboard preserve/restore | The paste path working at all (otherwise "preserve what?" — there's no baseline) |
| Permission failure handling | A way to *trigger* the failure (denied mic) and observe what sox stderr looks like — needs the pipeline first |
| Hallucination denylist | An observed hallucination (i.e. recordings of silent tails to know what whisper produces) — needs the pipeline first |
| install.sh | The other components, because install.sh is just "copy these files / run these brews to recreate the working state" |
| Warm-process upgrade | Measurements showing it's needed; the abstracted `transcribe()` function in bash glue (which exists from Phase 1.2) |

### The minimum viable end-to-end loop (Phase 1 exit criteria)

By the end of Phase 1, this must work:

1. Open Terminal, focus a text editor or Claude Code prompt
2. Hold `cmd+option+space`
3. Say: "Refactor the auth middleware to use JWTs instead of session cookies"
4. Release the key
5. Within ~2 seconds, the sentence appears in the focused text field

That's the entire validation target. Everything in Phase 2+ makes this *robust*; Phase 1 makes it *exist*.

---

## Architectural Patterns

### Pattern 1: Single-binary glue with file handoff

**What:** Each component is a CLI binary (sox, whisper-cli, pbcopy). Hand off state via files on disk. Coordinate lifecycle with signals + exit codes.
**When to use:** When components are mature, well-documented CLIs you don't want to wrap. When the data being passed is naturally file-shaped (a WAV, a transcript). When you want crash isolation between stages.
**Trade-offs:** ✅ Simple, debuggable (you can run each step manually), language-agnostic. ❌ Per-invocation cold-start cost; not suitable for streaming or sub-100ms-per-stage pipelines.

**Example (the entire bash glue, abridged):**
```bash
#!/usr/bin/env bash
set -euo pipefail
source "$HOME/.config/voice-cc/config.sh"   # MODEL, MAX_DURATION, etc.

WAV=/tmp/voice-cc/utterance.wav
TXT=/tmp/voice-cc/utterance.txt
mkdir -p /tmp/voice-cc
trap 'rm -f "$WAV" "$TXT"' EXIT

# Capture: SIGTERM from Hammerspoon causes graceful sox shutdown
timeout "${MAX_DURATION:-120}" sox -d -r 16000 -c 1 -b 16 "$WAV" 2>>"$HOME/.cache/voice-cc/error.log"

# Permission check (sox returns specific exit code on TCC denial — refine after observation)
SOX_EXIT=$?
if [ $SOX_EXIT -ne 0 ] && grep -q "Permission denied\|AudioObject" "$HOME/.cache/voice-cc/error.log"; then
  exit 10
fi

# Duration gate
DUR=$(soxi -D "$WAV" 2>/dev/null || echo 0)
awk -v d="$DUR" 'BEGIN { exit !(d < 0.25) }' && exit 2

# Transcribe (the abstraction boundary — see Pattern 2)
TRANSCRIPT=$(transcribe "$WAV")

# Post-filter
TRANSCRIPT=$(printf "%s" "$TRANSCRIPT" | post_filter)
[ -z "$TRANSCRIPT" ] && exit 3

# Persist + emit
printf "%s" "$TRANSCRIPT" > "$HOME/.cache/voice-cc/last.txt"
printf "%s" "$TRANSCRIPT"
```

### Pattern 2: Single-function abstraction boundary

**What:** Isolate the swappable component behind one function. Everything else in the pipeline calls only that function.
**When to use:** When you anticipate replacing or reconfiguring one component (here: STT engine — whisper-cli today, whisper-server tomorrow, parakeet-mlx the day after).
**Trade-offs:** ✅ Future change is one-line. ✅ Forces honest separation of concerns. ❌ Tiny bit of indirection cost.

**Example:**
```bash
# v1: one-shot CLI
transcribe() {
  local wav="$1"
  whisper-cli \
    -m "$HOME/.local/share/voice-cc/models/ggml-small.en.bin" \
    -f "$wav" \
    --vad --vad-threshold 0.5 \
    --prompt "$(cat "$HOME/.config/voice-cc/vocab.txt" 2>/dev/null)" \
    --no-timestamps \
    -otxt -of "${wav%.wav}" 2>>"$HOME/.cache/voice-cc/error.log"
  cat "${wav%.wav}.txt"
}

# v1.1 drop-in: warm whisper-server (LaunchAgent keeps it running)
transcribe() {
  local wav="$1"
  curl -s -X POST http://127.0.0.1:8080/inference \
    -H "Content-Type: multipart/form-data" \
    -F "file=@${wav}" \
    -F "response_format=text" \
    -F "prompt=$(cat "$HOME/.config/voice-cc/vocab.txt" 2>/dev/null)"
}
```

Same caller. Same return contract (transcript on stdout). Different implementation.

### Pattern 3: Stateful orchestration in Lua, stateless work in bash

**What:** Lua holds the small bits of in-process state (isRecording flag, current task handle, saved clipboard). Bash holds none.
**When to use:** When the orchestration layer naturally has session/event state (it owns the hotkey lifecycle) and the work layer is naturally per-invocation.
**Trade-offs:** ✅ Each layer owns what it's good at — Lua/Hammerspoon for events and UI, bash for processes and pipes. ❌ State is split across two languages; mitigated by keeping bash truly stateless.

### Pattern 4: Exit codes as control protocol

**What:** Use POSIX exit codes (0/2/3/10/11/12) as the IPC between bash and Lua. No JSON, no file flags.
**When to use:** When the orchestration layer needs to dispatch on a small enumerable set of outcomes.
**Trade-offs:** ✅ Universal, zero-overhead, debuggable from a terminal (just run the script and `echo $?`). ❌ Exit codes are 8-bit and not self-documenting — must keep a registry comment.

### Pattern 5: User-editable config as source files (no parser)

**What:** vocab.txt is just a text file. config.sh is sourced bash. denylist.txt is one phrase per line. No YAML, no TOML, no JSON.
**When to use:** When config is read by bash anyway, and the user is technically inclined.
**Trade-offs:** ✅ No parser to write or maintain. ✅ Comments work natively (`# this is a comment` in bash, easy in text). ❌ Doesn't generalize to a GUI or non-technical users — but that's explicitly out of scope.

---

## Anti-Patterns

### Anti-Pattern 1: Long-running daemon for v1

**What people do:** "It'll be faster — let's run a Python wrapper / Go daemon / Node service that keeps Whisper warm."
**Why it's wrong:** Adds a process to monitor, restart, and debug. Adds an IPC protocol (Unix socket? HTTP?) you have to design. Locks the architecture into "daemon is always running" — bad for laptops that sleep, bad for restarts. The cold-start savings (~300–500 ms) don't matter if you're inside the 2 s budget.
**Do this instead:** One-shot CLI. Measure latency. Add `whisper-server` (already-built upstream daemon) only if measurements demand it.

### Anti-Pattern 2: Python orchestration

**What people do:** Use Python instead of bash because "Python is more readable."
**Why it's wrong:** ~150 ms interpreter startup *per utterance* (~10% of the budget). venv to manage. Module imports. No actual benefit for a 30-line `sox; wait; whisper-cli; pbcopy` pipeline.
**Do this instead:** bash. The orchestration is genuinely simple; bash is the right tool for "wait for one process, then run another."

### Anti-Pattern 3: Streaming partial transcripts

**What people do:** Use whisper.cpp's `examples/stream` for "live" transcription during recording.
**Why it's wrong:** Adds SDL2 dependency. Sliding-window VAD requires tuning. Boundary effects between chunks reduce accuracy. For 2–10 s PTT clips, transcribing the closed WAV is *simpler* and often *faster* end-to-end.
**Do this instead:** Closed-WAV transcription via `whisper-cli`. Show a static "recording…" indicator instead of partial text.

### Anti-Pattern 4: Auto-editing the user's `init.lua`

**What people do:** install.sh appends `require('voice-cc')` to `~/.hammerspoon/init.lua`.
**Why it's wrong:** First subtle bug in the append → corrupted config → user blames install.sh → bad day. Hammerspoon `init.lua` is sacred personal config.
**Do this instead:** Print the line; let the user paste it. One-time, two seconds, zero risk.

### Anti-Pattern 5: Storing config in `~/Library/Application Support/`

**What people do:** Follow Apple's GUI-app convention.
**Why it's wrong:** voice-cc is a CLI/dotfile tool; users expect `~/.config/`. macOS dotfile managers (chezmoi, GNU Stow, plain git) target `~/.config/`. Hidden in Finder, awkward for grep.
**Do this instead:** XDG (`~/.config/voice-cc/`, `~/.local/share/voice-cc/`, `~/.cache/voice-cc/`).

### Anti-Pattern 6: PID files, lockfiles, status files

**What people do:** Write `/tmp/voice-cc/recording.pid` so Lua can check "am I already recording?"
**Why it's wrong:** Stale lockfiles after crashes. Race conditions. The state already exists in Lua memory — that's the source of truth.
**Do this instead:** Lua-local `isRecording` flag. If Hammerspoon restarts, state is naturally cleared. No coordination file needed.

### Anti-Pattern 7: Synchronous clipboard restore

**What people do:** `pasteboard.set(transcript); keyStroke(cmd+v); pasteboard.set(saved)` back-to-back.
**Why it's wrong:** Some apps process `cmd+v` async; reading the pasteboard before the paste is processed gets the wrong content. Result: clipboard restored *before* the focused app reads it → user pastes the *previous* clipboard contents.
**Do this instead:** `hs.timer.doAfter(0.25, function() pasteboard.set(saved) end)`. 250 ms is the empirical sweet spot reported by every Hammerspoon dictation project.

---

## Integration Points

### External binaries (in user's PATH or known location)

| Binary | Source | Integration | Failure mode |
|---|---|---|---|
| `sox` | `brew install sox` | Spawned by bash glue with `-d` (default mic), 16 kHz mono, 16-bit PCM, terminated via SIGTERM from bash trap | Non-zero exit → check stderr for permission denial |
| `whisper-cli` | `brew install whisper-cpp` (or source build with Core ML) | Spawned by bash glue with `-m model -f wav --vad --prompt vocab` | Non-zero exit → exit code 12 → toast |
| `whisper-server` (v1.1) | source build of whisper.cpp | Long-running via LaunchAgent on `127.0.0.1:8080`; bash glue posts WAV via curl | curl fails → fall back to whisper-cli? Or just toast |
| `pbcopy` / `pbpaste` | macOS built-in | Used by bash glue's last-transcript writer (`echo "$T" | pbcopy`); Lua uses `hs.pasteboard` directly for actual paste | Effectively never fails |
| `soxi` | bundled with sox | Used to read WAV duration for the gate | Fail → assume 0 → silent abort (safe default) |
| `curl` | macOS built-in | (v1.1) for whisper-server | Standard |
| `hyperfine` | `brew install hyperfine` | (Phase 3.4 only) latency benchmarking | N/A |

### Internal boundaries

| Boundary | Communication | Notes |
|---|---|---|
| **Hammerspoon ↔ bash glue** | `hs.task.new(path, callback)` for spawn; `task:terminate()` sends SIGTERM; exit code + stdout in callback | The whole control surface. No JSON, no sockets. |
| **bash glue ↔ sox** | Subprocess + SIGTERM trap | sox is the only thing whose lifecycle matches the hotkey hold |
| **bash glue ↔ whisper-cli** | Subprocess; pass WAV file path; capture exit code; read transcript text file | Synchronous; no streaming |
| **bash glue ↔ whisper-server** (v1.1) | HTTP POST multipart to localhost:8080/inference | Drop-in replacement for whisper-cli call |
| **Lua ↔ macOS event system** | `hs.eventtap.keyStroke({"cmd"}, "v")` for paste; `hs.pasteboard` for clipboard; `hs.notify` for toasts | All native Hammerspoon |
| **bash glue ↔ config** | `source ~/.config/voice-cc/config.sh` at top of script; read text files via `cat` | No parser |

### Integration with the user's existing Hammerspoon config

voice-cc ships as a Lua module at `~/.hammerspoon/voice-cc/init.lua`. The user adds one line to their existing `~/.hammerspoon/init.lua`:

```lua
require("voice-cc")
```

The module exposes a configuration table (optional override of hotkey, sound enable, etc.):

```lua
require("voice-cc").configure({
  hotkey = { mods = {"cmd", "alt"}, key = "space" },
  sounds = true,
  scriptPath = os.getenv("HOME") .. "/.local/bin/voice-cc-record",
})
```

This is the **only** intrusion into the user's config. Everything else is in voice-cc's own files.

---

## Scaling Considerations

This is a single-user, single-machine personal tool. "Scaling" is mostly "won't break under personal-use load."

| Scale | Adjustments needed |
|---|---|
| **0–100 utterances/day** (typical use) | Default architecture is fine. ~10 KB transcripts/day, ~10 MB WAVs (immediately deleted), ~0 long-term storage growth. |
| **100–1000 utterances/day** (heavy use) | history.log (v1.x) starts to grow — add `logrotate` or a size cap (last 10 MB). WAVs still bounded (one at a time). |
| **Sustained recording > 60 s clips** | whisper-cli inference time grows linearly; medium.en may be needed for accuracy on long clips; budget no longer holds. PTT model discourages this; not a real scaling concern. |
| **Multiple concurrent recordings** | Not supported, not needed. PTT is one-at-a-time by definition. |
| **Multi-user (different macOS accounts)** | Architecture is per-user already (everything under `$HOME`). No sharing needed. |

**The first thing that "breaks" at scale is `~/.cache/voice-cc/log` if v1.x is used heavily.** Mitigation: cap at 10 MB with a tail-and-overwrite trim, or document `logrotate` config in the README.

---

## Warm-Process Upgrade Path (v1.1, Reserved Capacity)

This section exists so v1's design doesn't preclude v1.1.

### What changes

- **Add:** `~/Library/LaunchAgents/com.olivergallen.voice-cc-server.plist` — a LaunchAgent that runs `whisper-server` on `127.0.0.1:8080` with `KeepAlive=true` and `RunAtLoad=true`. Loads the model into memory at boot and keeps it there.
- **Modify:** `transcribe()` function in bash glue — swap `whisper-cli ...` for `curl ... 127.0.0.1:8080/inference -F file=@...`.
- **Build:** Source-build whisper.cpp's `examples/server` (Homebrew bottle doesn't include it; same source-build flow as the Core ML encoder).

### What stays the same

- Hammerspoon code: zero changes.
- Bash glue structure: zero changes (except inside one function).
- Config files: zero changes.
- File layout: zero changes (one new plist).
- Failure model: largely unchanged (curl exit codes mapped to whisper-cli exit codes).

### What needs to be in v1 to enable v1.1

- ✅ `transcribe()` is its own bash function (Pattern 2) — already in the v1 plan.
- ✅ The script reads its model path from config, not hardcoded — already in `config.sh`.
- ✅ stdout is the transcript-delivery mechanism — works for both backends.

### When to actually do v1.1

Only when Phase 3.4 hyperfine measurements show:
- p50 latency > 2.0 s on `small.en` + Core ML encoder, **OR**
- p95 latency > 3.0 s (cold-start tail outliers degrade UX even if median is fine), **OR**
- Oliver subjectively reports "feels slow" after a week of v1 usage

Until then, the simpler one-shot architecture wins on every dimension that isn't latency, and we don't yet know if latency is a problem.

### What v1.1 explicitly doesn't change

- Still single-user.
- Still no telemetry, no network calls outside localhost.
- Still no GUI.
- Still no toggle/tap mode (PTT only per PROJECT.md).
- Still uses `whisper.cpp` (no engine swap; that would be v2.0 if it ever happens).

---

## Sources

### Reference implementations (validated the chosen patterns)
- [Spellspoon — kevinjalbert/spellspoon](https://github.com/kevinjalbert/spellspoon) — Hammerspoon + ffmpeg + whisper-cli with shell scripts as glue. Uses `~/.spellspoon/` config dir, modules/scripts/prompts split. Confirms the bash-glue pattern works in production. HIGH.
- [local-whisper — luisalima/local-whisper](https://github.com/luisalima/local-whisper) — Hammerspoon + ffmpeg + whisper.cpp with eventtap-driven press/release detection, state files in `~/.local-whisper/`, models in `~/whisper.cpp/`. Closest reference architecture. HIGH.
- [Hammerspoon hs.task docs](https://www.hammerspoon.org/docs/hs.task.html) — `task:terminate()` semantics, callback signature with exitCode + stdout + stderr. HIGH.
- [hs.task issue #1963 — partial stdout on exit](https://github.com/Hammerspoon/hammerspoon/issues/1963) — confirms the stdout-after-exit edge case; mitigated by writing transcript file before stdout echo. HIGH.
- [hs.task issue #1263 — signal options](https://github.com/Hammerspoon/hammerspoon/issues/1263) — confirms terminate sends SIGTERM (not SIGKILL); graceful shutdown is the default. HIGH.

### Warm-process upgrade path
- [whisper.cpp examples/server](https://github.com/ggml-org/whisper.cpp/tree/master/examples/server) — HTTP server bundled with whisper.cpp; multipart/form-data on `/inference`; JSON or text response; model stays loaded. HIGH.
- [whisper-cpp-server fork — litongjava](https://github.com/litongjava/whisper-cpp-server) — confirms server pattern is in active use. MEDIUM.
- [Voice Mode whisper.cpp docs](https://voice-mode.readthedocs.io/en/stable/whisper.cpp/) — references the server pattern in production tooling. MEDIUM.
- [How I got SuperWhisper-quality voice typing on Linux — guillaume.id](https://guillaume.id/blog/how-i-got-superwhisper-quality-voice-typing-on-linux/) — describes a unix-socket control daemon pattern; useful framing even though we're using HTTP not socket. MEDIUM.

### LaunchAgent (for v1.1)
- [Apple — Creating Launch Daemons and Agents](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html) — official docs for plist structure. HIGH.
- [launchd.info tutorial](https://launchd.info/) — practical KeepAlive examples. HIGH.
- [tjluoma/launchd-keepalive examples](https://github.com/tjluoma/launchd-keepalive) — sample plists with KeepAlive subkeys. HIGH.

### Config layout (XDG vs Apple convention)
- [macOS dotfiles should not go in ~/Library/Application Support — becca.ooo](https://becca.ooo/blog/macos-dotfiles/) — argument for XDG over Apple convention for CLI tools; cites gh, git, kubectl, terraform precedent. HIGH.
- [XDG Base Directory and macOS — aliquote.org](https://aliquote.org/post/xdg-specs-on-macos/) — practical XDG paths on macOS. HIGH.
- [XDG Base Directory Specification](https://wiki.archlinux.org/title/XDG_Base_Directory) — canonical spec. HIGH.

### Process model + signals
- [GNU C Library — Termination Signals](https://www.gnu.org/software/libc/manual/html_node/Termination-Signals.html) — SIGTERM vs SIGINT vs SIGKILL semantics; SIGTERM is the right choice for graceful sox shutdown. HIGH.

### Cross-cutting (already in STACK.md / FEATURES.md, re-cited for architecture relevance)
- [whisper.cpp issue #1724 — silent-tail hallucination](https://github.com/ggml-org/whisper.cpp/issues/1724) — informs the denylist post-filter design. HIGH.
- [Claude Code voice dictation troubleshooting](https://code.claude.com/docs/en/voice-dictation) — informs the failure-handling matrix (mic permission errors, no-speech-detected silent abort). HIGH.

---

*Architecture research for: voice-cc — local push-to-talk dictation for Claude Code on macOS Apple Silicon*
*Researched: 2026-04-23*
