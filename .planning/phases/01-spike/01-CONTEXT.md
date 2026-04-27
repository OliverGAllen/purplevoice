# Phase 1: Spike — Context

**Gathered:** 2026-04-27
**Status:** Ready for planning

<domain>
## Phase Boundary

**What this phase delivers:** A working end-to-end push-to-talk dictation loop on Oliver's machine. Holding `cmd+shift+e`, speaking a sentence, and releasing causes that sentence to appear in the focused window in under 2 seconds.

**Thin slice — what is NOT in this phase:**
- Hallucination guards (VAD flag, denylist, duration gate) → Phase 2
- Clipboard preserve/restore + transient UTI marker → Phase 2
- Re-entrancy guard → Phase 2
- TCC silent-deny detection / failure notifications → Phase 2
- Menu-bar indicator + audio cues → Phase 2
- WAV trap-cleanup → Phase 2
- install.sh distribution + README + hyperfine benchmarks → Phase 3

**Requirements covered (10):** CAP-01, CAP-02, CAP-03, CAP-04, TRA-01, TRA-02, TRA-03, INJ-01, ROB-03, ROB-05

**Success criteria (from ROADMAP.md, used verbatim as the verification checklist):**
1. Holding `cmd+shift+e` and saying "refactor the auth middleware to use JWTs" results in that sentence appearing in the focused text field within ~2 seconds of release on Oliver's Apple Silicon Mac.
2. The bash glue script can be invoked manually (outside Hammerspoon) and produces the same transcript on stdout for a hand-recorded WAV — the pipeline composes.
3. Native Whisper punctuation and capitalisation appear in the pasted output (no post-processing pass yet).
4. Custom vocabulary in `~/.config/voice-cc/vocab.txt` measurably biases recognition toward technical terms (Anthropic, Hammerspoon, MCP) when supplied via `--prompt`.
5. All external binaries (sox, whisper-cli) are invoked by absolute path so the loop works under Hammerspoon's restricted PATH from day one.

</domain>

<decisions>
## Implementation Decisions

### Hammerspoon Setup
- **D-01:** Hotkey is `cmd+shift+e` (push-and-hold). Hammerspoon is installed via `brew install --cask hammerspoon` from inside `setup.sh`. Hammerspoon does not currently exist on this machine — clean install. Setup script is idempotent: re-running checks `/Applications/Hammerspoon.app` first and only installs if missing.
  # Hotkey was the original combo (cmd then option then the space bar) until 2026-04-27, when the user changed it to cmd+shift+e during Plan 01-01 execution. Known minor conflict: VS Code/Cursor "Show Explorer" — accepted.
- **D-02:** The voice-cc Lua module is loaded into Hammerspoon by symlinking `~/.hammerspoon/voice-cc/` → `<repo>/voice-cc-lua/` (or whatever the repo Lua source folder is named) and writing a minimal `~/.hammerspoon/init.lua` that does `require("voice-cc")`. Setup script will NOT overwrite an existing init.lua silently — if one exists with content, it asks (in Phase 1, this is fine because there is no existing init.lua).

### File Layout (XDG, from day one)
- **D-03:** Runtime files live in XDG-conventional paths from the spike onwards. Phase 3 install.sh has nothing to refactor:
  - `~/.config/voice-cc/vocab.txt` — custom vocabulary
  - `~/.local/share/voice-cc/models/ggml-small.en.bin` — Whisper model
  - `~/.cache/voice-cc/last.txt` — last transcript marker (used by bash → Lua handoff)
  - `~/.local/bin/voice-cc-record` — bash glue script (symlinked from repo)
  - `~/.hammerspoon/voice-cc/` — Lua module (symlinked from repo)
  - `/tmp/voice-cc/recording.wav` — single working WAV (overwritten per invocation; cleanup is Phase 2)
- **D-04:** Repo structure is **flat** for the spike — minimum files, easy to read end-to-end. No `bin/`, `lua/`, `scripts/` subfolders unless file count actually justifies them. Likely files: `setup.sh`, `voice-cc-record` (bash), `init.lua` or a `voice-cc/` Lua module dir, `vocab.txt.default`, `README.md` (stub), `.gitignore`.

### Model Download
- **D-05:** Model download is scripted in `setup.sh` and idempotent. Uses `curl -C - -L -o <path> <url>` (resumable) and verifies SHA256 against a hardcoded checksum. Re-runs are no-ops if file exists with correct hash.
- **D-06:** Source URL is the official HuggingFace ggerganov mirror: `https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin` — no auth required, upstream-maintained. (If this URL needs pinning to a specific revision later, that's a Phase 3 concern.)

### Verification
- **D-07:** Spike done = the 5 ROADMAP.md success criteria above pass when walked through manually as a checklist. Each criterion is a discrete observable test. No CHECK.md file required for Phase 1 — the criteria themselves are the spec.

### Vocab Seed
- **D-08:** `vocab.txt.default` ships with an AI/dev terminology pack: `Anthropic, Claude, Claude Code, Hammerspoon, MCP, Model Context Protocol, npm, TypeScript, GitHub, whisper.cpp, sox, Vercel, Supabase, JWT, OAuth, REPL, Tailwind, Next.js`. Setup script copies `vocab.txt.default` → `~/.config/voice-cc/vocab.txt` only if the destination doesn't already exist (never clobbers user edits). Whisper's `--prompt` has a ~224-token limit, so the seed list is intentionally short and high-leverage.

### Claude's Discretion
- Hotkey-event wiring details inside `hs.hotkey.bind(mods, key, pressedFn, releasedFn)` — the bash spawn pattern (`hs.task` with what callbacks) is up to Claude as long as the press/release semantics are correct.
- Exact bash glue control flow (functions vs inline, error propagation) — minimum viable per Phase 1, no exit-code registry yet (that's Phase 2).
- Whether to ship a single `voice-cc.lua` file or a `voice-cc/init.lua` module folder — pick whatever's cleaner given final line count.
- Whisper model quantisation suffix — `ggml-small.en.bin` is the un-quantised default; if Q5_0 (`ggml-small.en-q5_0.bin`) is available with proper checksums, Claude can substitute for the ~40% size reduction at negligible accuracy cost.
- Whether to add a `--language en` flag explicitly to whisper-cli (research says always pass it for `.en` models — Claude should follow the research recommendation).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Context
- `.planning/PROJECT.md` — Core value, requirements (Active/Out-of-Scope), constraints, key decisions
- `.planning/REQUIREMENTS.md` — All 26 v1 requirements; Phase 1 covers CAP-01..04, TRA-01..03, INJ-01, ROB-03, ROB-05
- `.planning/ROADMAP.md` §"Phase 1: Spike" — Goal, success criteria, build-order constraint

### Research (consume in full, especially the Phase-1-relevant sections)
- `.planning/research/SUMMARY.md` — Executive synthesis; phase implications
- `.planning/research/STACK.md` — Specific binaries, versions, install commands; whisper.cpp v1.8.4, sox 14.4.2, Hammerspoon 1.1.1, `ggml-small.en.bin` choice rationale
- `.planning/research/ARCHITECTURE.md` — Build order (manual pipeline → bash glue → Hammerspoon), one-shot CLI process model, `transcribe()` abstraction boundary, exit code registry (relevant for Phase 2 but informs Phase 1 structure)
- `.planning/research/FEATURES.md` — Phase 1 v1 must-haves vs deferred features; custom vocab via `--prompt` mechanics (224-token limit)
- `.planning/research/PITFALLS.md` §"Pitfall 2 (PATH on Apple Silicon)" — Why ROB-03 demands absolute paths from day one; §"Pitfall 5 (hotkey conflicts)" — `cmd+shift+e` selected by user; supersedes the original rationale (see Pitfall 5 update note)

### External (upstream)
- whisper.cpp repo: https://github.com/ggml-org/whisper.cpp — `whisper-cli` flags, model file naming, build instructions
- whisper.cpp models on HuggingFace: https://huggingface.co/ggerganov/whisper.cpp/tree/main — direct model download URLs and SHA256 checksums
- Hammerspoon docs: https://www.hammerspoon.org/docs/ — specifically `hs.hotkey`, `hs.task`, `hs.pasteboard`, `hs.eventtap.keyStroke`
- Spellspoon (reference impl): https://github.com/kevinjalbert/spellspoon — Hammerspoon dictation pattern, bash spawn approach
- local-whisper (reference impl): https://github.com/luisalima/local-whisper — alternative reference, similar pattern

### Internal Tooling (already installed in this session)
- MCP `context7` — Hammerspoon and whisper.cpp API docs lookup
- MCP `github` — read Spellspoon / local-whisper source directly
- MCP `firecrawl` — fresh web research if needed (e.g., HuggingFace SHA256 verification)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **None in this repo** — voice-cc is greenfield. The repo currently contains only `.planning/` and a `.git/`.

### Established Patterns (from upstream references)
- **Spellspoon pattern:** Hammerspoon hotkey → `hs.task.new(scriptPath, callback):start()` → bash script invokes sox → on release, `task:terminate()` → bash traps SIGTERM, finalises WAV, runs whisper-cli, prints transcript to stdout → Hammerspoon callback receives stdout, copies to clipboard, simulates `cmd+v`.
- **local-whisper pattern:** Identical shape with slightly different exit-code conventions and a separate Lua helper file. Confirms the architecture is settled.

### Integration Points (will exist after Phase 1)
- `~/.hammerspoon/init.lua` — voice-cc loads via `require("voice-cc")`. If the user adds other Spoons/modules later, voice-cc coexists by being just one require.
- `~/.local/bin/` — must be on the user's `PATH` for the script to be invokable manually (per success criterion 2). Setup script should check and warn if missing.
- macOS Privacy: Hammerspoon needs **Microphone** + **Accessibility** permissions granted (manual one-time grant on first launch). Phase 1 does not auto-detect denial (Phase 2 territory) — but README/setup output should tell the user to grant both.

</code_context>

<specifics>
## Specific Ideas

- **Reference utterance for success criterion 1:** "refactor the auth middleware to use JWTs" — captures medium-length English with a domain term (JWTs) and exercises punctuation. Use this exact sentence for the verification walkthrough.
- **Test technical terms for success criterion 4:** Anthropic, Hammerspoon, MCP. Try saying these in a sentence with vocab.txt populated vs empty (or commented out) to see the bias effect.
- **Hammerspoon module naming:** prefer `~/.hammerspoon/voice-cc/init.lua` (folder module) so future expansion (separate hotkey def, separate paste helper) is a non-event. `require("voice-cc")` resolves to that init.lua.
- **Bash script shebang and strict mode:** `#!/usr/bin/env bash` + `set -euo pipefail` from the start. Even Phase 1 should fail loudly on errors during the spike — research established this.

</specifics>

<deferred>
## Deferred Ideas

None surfaced during discussion — conversation stayed within Phase 1 scope. (The pitfall-prevention work is already roadmapped to Phase 2; the install.sh + README is already roadmapped to Phase 3. Both correctly out of Phase 1 scope.)

</deferred>

---

*Phase: 01-spike*
*Context gathered: 2026-04-27*
