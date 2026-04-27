# Phase 1: Spike — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-27
**Phase:** 01-spike
**Areas discussed:** Hammerspoon state, File layout strategy, Model download flow, Spike done definition

---

## Pre-discussion: Selected Areas

**Question:** Which gray areas do you want to discuss for Phase 1 (Spike)?

| Option | Description | Selected |
|--------|-------------|----------|
| Hammerspoon state | Do you already have Hammerspoon installed/configured, or is this its first install? Affects init.lua integration | ✓ |
| File layout strategy | Quick-and-dirty (everything in voice-cc repo) vs 'right from day one' (proper XDG ~/.config, ~/.local/share paths). Big knock-on for Phase 3 install.sh | ✓ |
| Model download flow | How does ggml-small.en.bin (~190 MB) get onto your machine — manual one-time curl, scripted fetch in repo, or git-lfs? Affects reproducibility from day one | ✓ |
| Spike done definition | What's the actual test that proves it works? Specific utterance(s), a checklist of scenarios, or 'it feels right when I use it'? | ✓ |

**User's choice:** All four.

---

## Hammerspoon State

**Pre-flight scan:** `/Applications/Hammerspoon.app` not present, `~/.hammerspoon/` doesn't exist, no `init.lua`. Clean slate.

### Q1: How should Hammerspoon get installed for the spike?

| Option | Description | Selected |
|--------|-------------|----------|
| brew install in spike script | Add `brew install --cask hammerspoon` to a setup script in the repo. Reproducible, one command, you grant Accessibility permission once on first launch | ✓ |
| Manual install, you handle it | You install Hammerspoon yourself before the spike runs. Spike script just checks it's there and bails if not | |
| Skip Hammerspoon for Phase 1 | Get the bash pipeline working first; defer Hammerspoon wiring to its own slice (would split Phase 1 into two) | |

**User's choice:** brew install in spike script (recommended).

### Q2: How should the voice-cc Lua module be loaded into Hammerspoon's init.lua?

| Option | Description | Selected |
|--------|-------------|----------|
| Symlink module + write minimal init.lua | Symlink ~/.hammerspoon/voice-cc/ to the repo, write a one-line init.lua that does `require("voice-cc")`. You can edit the init.lua later if you add other Spoons | ✓ |
| Drop the whole init.lua (overwrite) | Spike writes init.lua directly. Faster but if you ever add other Hammerspoon stuff, you'd have to merge | |
| Print the require line, you paste it yourself | Phase 3 install.sh approach — conservative, won't touch your init.lua. Adds one manual step in Phase 1 | |

**User's choice:** Symlink module + write minimal init.lua (recommended).

**Notes:** Since there's no existing init.lua, writing one is non-destructive. Setup script should still check for a pre-existing one and refuse to overwrite without prompting (defensive for future re-runs / fresh machines that already have other Hammerspoon work).

---

## File Layout Strategy

### Q1: How should files be organized for the spike?

| Option | Description | Selected |
|--------|-------------|----------|
| Right from day one — XDG paths | Spike uses ~/.config/voice-cc/, ~/.local/share/voice-cc/models/, ~/.cache/voice-cc/, ~/.local/bin/voice-cc-record, ~/.hammerspoon/voice-cc/. Phase 3 install.sh has nothing to refactor | ✓ |
| Repo-local for spike, move later | Everything in voice-cc/scripts/, voice-cc/models/, voice-cc/lua/. Easier to inspect/edit; Phase 3 has to migrate to XDG | |
| Hybrid — model in repo, scripts in repo, Hammerspoon symlink to ~/.hammerspoon/ | Pragmatic middle ground. Model + scripts live in repo (easy to git-track changes); Lua module symlinked into Hammerspoon's expected location | |

**User's choice:** XDG from day one (recommended).

### Q2: How should the voice-cc repo itself be structured?

| Option | Description | Selected |
|--------|-------------|----------|
| Flat | voice-cc/{voice-cc-record,init.lua,setup.sh,vocab.txt} — minimum files, easy to read end-to-end | ✓ |
| Conventional folders from day one | voice-cc/{bin/,lua/,config/,scripts/} — cleaner once it grows but feels heavy for a 100-line tool | |
| You decide | Let Claude pick whatever's cleanest given the actual file count once Phase 1 is implemented | |

**User's choice:** Flat (recommended).

---

## Model Download Flow

### Q1: How should ggml-small.en.bin (~190 MB) get downloaded?

| Option | Description | Selected |
|--------|-------------|----------|
| Scripted in setup.sh, idempotent | setup.sh runs `curl -C - -L -o ...` from the official ggerganov HF mirror, with SHA256 check. Re-runs are no-ops if file exists and checksum matches | ✓ |
| Manual one-time download, README documents it | You curl it once and drop in ~/.local/share/voice-cc/models/. Setup.sh just verifies it's there | |
| whisper.cpp's own download script | whisper.cpp ships a `models/download-ggml-model.sh` — we shell out to that. Less code for us; less control | |

**User's choice:** Scripted in setup.sh, idempotent (recommended).

### Q2: Where should the model download URL point?

| Option | Description | Selected |
|--------|-------------|----------|
| HuggingFace ggerganov mirror | huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin — official upstream, no auth required | ✓ |
| Pin to specific HF revision/commit hash | Lock to an exact commit so future updates don't change the model under us. More careful but rare to matter for whisper models | |
| You decide | Pick whichever feels right when implementing | |

**User's choice:** HuggingFace ggerganov mirror (recommended).

---

## Spike Done Definition

### Q1: What test proves the spike is done?

| Option | Description | Selected |
|--------|-------------|----------|
| Roadmap success criteria as a checklist | Run through the 5 success criteria from ROADMAP.md verbatim — specific utterance test, manual bash invocation works, punctuation appears, vocab.txt biases recognition, absolute paths confirmed | ✓ |
| Three specific test utterances | Pick 3 sentences (short/medium/long) and run them through the loop. Document the latency and accuracy in a CHECK.md | |
| Just 'it works for me' in real Claude Code use | Use it for one real Claude Code session — if the loop holds together, ship Phase 1 | |
| You decide | Claude picks a sensible verification approach when implementing | |

**User's choice:** Roadmap success criteria as a checklist (recommended).

### Q2: What technical terms should `vocab.txt` ship with at spike time?

| Option | Description | Selected |
|--------|-------------|----------|
| AI/dev terminology pack | Anthropic, Claude, Hammerspoon, MCP, npm, TypeScript, GitHub, whisper.cpp, sox, Vercel, Supabase, JWT, OAuth, REPL, Tailwind, Next.js — covers your typical Claude Code vocabulary | ✓ |
| Empty file, you fill it as needed | Ship vocab.txt as a stub. You'll add terms organically when you notice mistranscriptions | |
| Pull from your recent prompts | Scan a sample of your recent Claude Code prompts to find recurring proper nouns; seed vocab from that | |

**User's choice:** AI/dev terminology pack (recommended).

---

## Final Gate

**Question:** We've discussed Hammerspoon state, File layout, Model download, and Spike verification. Anything else unclear, or ready for context?

| Option | Description | Selected |
|--------|-------------|----------|
| I'm ready for context | Write CONTEXT.md and proceed to plan-phase | ✓ |
| Explore more gray areas | There's more I want to nail down before planning — you'll surface 2-4 more candidates | |

**User's choice:** Ready for context.

---

## Claude's Discretion

The following implementation choices were left to Claude's judgement and recorded in CONTEXT.md `<decisions>` → "Claude's Discretion":

- Hotkey-event wiring details inside `hs.hotkey.bind(...)` (callback structure, `hs.task` spawn pattern)
- Exact bash glue control flow (functions vs inline, error propagation in Phase 1)
- Whether to ship a single `voice-cc.lua` file or `voice-cc/init.lua` module folder (pick whichever fits final line count)
- Whisper model quantisation suffix (un-quantised vs Q5_0, depending on availability and checksum verification)
- Whether to add `--language en` flag explicitly (research recommends always — Claude follows research)

---

## Deferred Ideas

None surfaced during discussion. The conversation stayed cleanly within Phase 1's "thin slice / no polish" scope. All robustness work that came up tangentially (TCC handling, hallucination guards, clipboard preserve, indicator) was correctly recognised as Phase 2 territory and not pursued.
