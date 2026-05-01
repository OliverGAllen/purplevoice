# Phase 3: Distribution & Benchmarking + Public Install — Research

**Researched:** 2026-04-30
**Domain:** Bash installer ergonomics (curl|bash + idempotent local), micro-benchmarking with hyperfine, MIT licensing for source-available macOS tooling, README rewriting for institutional audiences, GitHub repo public-flip mechanics.
**Confidence:** HIGH on stack + idioms + flip mechanics; MEDIUM on TTS reproducibility (`say` voices vary across macOS major versions); HIGH on hyperfine flag semantics + JSON schema (with one verified gap: percentile reporting requires the upstream `scripts/advanced_statistics.py`, not built-in).

---

## Summary

Phase 3 is mostly a **wiring + polish + framing** phase, not a deep technical phase. The hard architectural choices are already locked in CONTEXT.md (D-01..D-12). Of the 12 specific blockers in the brief, **none require new tooling or frameworks** — every problem maps to a well-trodden idiom (oh-my-zsh / Homebrew / rustup installer patterns; hyperfine's documented JSON schema; the canonical opensource.org MIT text; `gh repo edit --visibility`). The risk surface is *operational*, not *technical*: a forgotten `--accept-visibility-change-consequences` flag will silently fail the public flip in non-interactive mode; a wrong-cased GitHub owner ("OliverGAllen" — verified live, NOT "oliverallen") will produce a 404 on the public curl URL; a macOS minor-version drift will change `say -v Daniel` output bytes.

The single most important finding: **the canonical public install URL in CONTEXT.md D-04 (`https://raw.githubusercontent.com/oliverallen/purplevoice/main/install.sh`) is wrong-cased.** The actual GitHub owner (verified via `gh repo view` 2026-04-30) is **`OliverGAllen`** — capital G, capital A. GitHub is case-insensitive on the `git clone` path but case-sensitive on the raw.githubusercontent.com path in some CDN contexts. The plan MUST use `OliverGAllen/purplevoice` (or canonicalise to a chosen lowercase via repo rename — but renaming an existing repo invalidates older clone URLs). Defer to `OliverGAllen/purplevoice` and document this as the authoritative path.

**Primary recommendation:** Adopt the **single-script install.sh with stdin-TTY detection** pattern (Homebrew + rustup style), use **`hyperfine -N --warmup 3 --runs 10 --export-json`** + a small post-process script for p95 (hyperfine native stats stop at min/mean/median/stddev/max), pin `gh repo edit --visibility public --accept-visibility-change-consequences` for the flip, and frame everything else conservatively.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**DST-06 Hammerspoon Wrapping (D-01..D-03)**

- **D-01: Option B — Bundled installer, no fork.** PurpleVoice ships as a Hammerspoon module that the installer drops into `~/.hammerspoon/purplevoice/` (existing pattern from setup.sh Step 6c). Hammerspoon stays as stock Hammerspoon — installed via brew cask, branded as Hammerspoon in TCC + Activity Monitor + Dock. README + install.sh openly disclose: *"PurpleVoice runs on Hammerspoon (free, open-source, BSD-3 / MIT licensed)."* Honest substrate framing aligns with Phase 2.7 D-17 ("compatible with" not "compliant"). Effort: ~1 day (mostly already done by setup.sh; Phase 3 mostly cleans + extends).
- **D-02: SEC-04 (Apple Developer ID + notarisation) STAYS DEFERRED indefinitely.** Option B doesn't need it. If the project later ships a notarised .pkg or moves to DST-06 Option A/C, SEC-04 returns. Document in SECURITY.md that PurpleVoice is currently distributed as source — not a notarised binary — and that this is a deliberate design choice for the audit-trail audience.
- **D-03: install.sh bails (exit non-zero) if Homebrew is missing.** Print: *"PurpleVoice needs Homebrew. Install via https://brew.sh/, then re-run."* Do NOT auto-bootstrap Homebrew. Do NOT direct-download Hammerspoon.dmg.

**DST-05 Public Installer (D-04..D-07)**

- **D-04: Public installer URL = `https://raw.githubusercontent.com/oliverallen/purplevoice/main/install.sh`.** ⚠️ **Verified 2026-04-30: actual GitHub owner is `OliverGAllen` (capital G + A), repo `purplevoice` (lowercase). The CONTEXT.md URL is mis-cased and will be substituted to `OliverGAllen/purplevoice` by the planner — see "User Constraints / Required Correction" below.** install.sh detects clone-vs-curl; if curl, git-clones into `~/.local/share/purplevoice/src/`, then proceeds locally.
- **D-05: Rename `setup.sh` → `install.sh`.** Single canonical idempotent installer. `git mv setup.sh install.sh`; update active surfaces only. ROADMAP success criterion 1 says `./install.sh` — this is the exact rename.
- **D-06: Repo flips PRIVATE → PUBLIC after install.sh + DST-06 (Option B implementation) land in Wave 1-2; before DST-05 (curl|bash) is end-to-end tested.** Pre-flip checklist: LICENSE present, README quickstart points to production curl URL, SECURITY.md SBOM reflects bundled-installer Hammerspoon dep, brand consistency lint GREEN, framing lint GREEN, `.planning/` content tone-reviewed (NOT redacted).
- **D-07: Repo goes PUBLIC + MIT-licensed + `.planning/` directory stays visible.** MIT license added explicitly; `.planning/` is part of the audit-trail story.

**hyperfine Methodology + Phase 5 Trigger (D-08..D-10)**

- **D-08: Methodology = transcription-only via hyperfine on 3 pre-recorded WAVs.** `hyperfine 'whisper-cli -m ~/.local/share/purplevoice/models/ggml-small.en.bin -f tests/benchmark/2s.wav -nt'` (and 5s.wav + 10s.wav). 10 runs, 3 warmup. Ship 3 reference WAVs in `tests/benchmark/` (~50KB each at 16kHz mono). Honest scope: measures Stage 2 only.
- **D-09: Phase 5 trigger = `p50 > 2s OR p95 > 4s on the 5s.wav benchmark`.** Concrete numerical gate. Documented in BENCHMARK.md.
- **D-10: Results land in dedicated `BENCHMARK.md` + README link.** BENCHMARK.md captures: hyperfine command, raw numbers (min/max/mean/median/p95/std-dev), Phase-5 go/no-go decision, environment (macOS version, Apple Silicon model, model file SHA256). README has "Performance" section + link.

**README + Recovery Flow (D-11..D-12)**

- **D-11: README onboarding = quickstart at top + detailed install below.** First section ("## Install"): 5-line quickstart for curl|bash + "now hold fn to record / hold ` to re-paste." Second section ("## Detailed Install"): full walkthrough.
- **D-12: README recovery section covers all 4 items:** TCC reset; Karabiner rule troubleshoot (UK keyboard `non_us_backslash` vs ANSI/US `grave_accent_and_tilde`); "I lost my hotkeys" decision-tree triage (5-step); `uninstall.sh` script.

### Claude's Discretion

- Where exactly install.sh git-clones to → CONTEXT.md recommends `~/.local/share/purplevoice/src/`.
- Exact wording of brew-missing actionable error.
- WAV reference content — synthetic TTS via `say`.
- install.sh detection of curl-vs-clone.
- Whether `uninstall.sh` removes Karabiner rule files → recommendation NO.
- README "Performance" section presentation (table vs prose).

### Deferred Ideas (OUT OF SCOPE)

- DST-06 Option A (custom Hammerspoon fork)
- DST-06 Option C (hybrid signed-binary rename)
- SEC-04 Apple Developer ID + notarisation
- Vanity domain redirect
- GitHub Releases with versioned tarballs
- Auto-bootstrap Homebrew on missing-Homebrew
- End-to-end benchmark harness
- BENCHMARK.md SECURITY.md mirroring
- Scrubbing `.planning/` from git history
- Source-available license (vs MIT)
- Private-repo + release-tarball-only distribution
- Auto-uninstall of Hammerspoon/sox/whisper-cpp
- Auto-removal of Karabiner rule JSONs

### Required Correction (escalate to user before plan-write)

The CONTEXT.md `oliverallen/purplevoice` URL contradicts the verified live remote `https://github.com/OliverGAllen/purplevoice.git` (GitHub owner case: `OliverGAllen`). Two options:

1. **Use `OliverGAllen/purplevoice` everywhere** (lowest-friction; URL becomes `https://raw.githubusercontent.com/OliverGAllen/purplevoice/main/install.sh`). Mixed-case in URLs is uglier but works. CDN is case-sensitive in raw.githubusercontent.com paths.
2. **Rename the GitHub repo to `oliverallen/purplevoice`** before flipping public (requires creating a new GitHub user `oliverallen` if not owned, OR renaming the owner — owner-rename is per-user-account level and affects every repo Oliver owns). Probably not worth it.

Recommendation: **Option 1**. Planner should sweep CONTEXT.md, README references, SECURITY.md mentions, and the install.sh embedded URL to use `OliverGAllen/purplevoice`. This is a small in-place correction the planner can do without re-discussing.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| **DST-01** | A single `install.sh` (renamed from setup.sh per D-05) installs all dependencies (Hammerspoon, sox, whisper-cpp), creates required directories, downloads the model file, links binaries, and is fully idempotent (safe to re-run). | Already implemented in current `setup.sh`; rename is `git mv` + sweep-and-replace of active surfaces. See "Standard Stack" + "Architecture Patterns / install.sh rename" below. |
| **DST-02** | `install.sh` never auto-edits the user's `~/.hammerspoon/init.lua` — instead prints the one-line `require("purplevoice")` for the user to paste themselves. | Already implemented in current `setup.sh` Step 10 banner. Phase 3 preserves verbatim. |
| **DST-03** | README documents permission grants required (Microphone + Accessibility for Hammerspoon), how to disable conflicting macOS Dictation shortcut, and `tccutil reset` recovery procedure. | Already in current README §"Permissions" / §"Conflicting macOS feature" / §"Recovery". Phase 3 D-11 rewrite preserves and extends with the 4-item Recovery section per D-12. |
| **DST-04** | `hyperfine` benchmark on the install machine produces p50 / p95 latency numbers for short, medium, and long utterances — gates the v1.1 warm-process upgrade decision. | See "hyperfine flag specifics" + "BENCHMARK.md skeleton" sections below. p95 requires post-processing (hyperfine native stats stop at median/stddev/max; `scripts/advanced_statistics.py` is the upstream-blessed p95 source). |
| **DST-05** (TBD → confirmed by D-04) | Public one-line installer (`curl -fsSL https://raw.githubusercontent.com/OliverGAllen/purplevoice/main/install.sh \| bash`) clones the repo and invokes the local `install.sh`. Public install is idempotent, prints next steps including the brand-aware `require()` line, documented in the README. Repo must be public on GitHub before this can pass. | See "curl-vs-clone bash detection idiom" + "Repo-public flip mechanics" sections below. |
| **DST-06** (TBD → resolved by D-01) | Hammerspoon-as-PurpleVoice wrapping decision documented (Option B) and implemented (the bundled-installer flow IS the implementation). | D-01 selects Option B — no fork, no rename, ship as Hammerspoon module. The bundled-installer flow IS the implementation. Phase 3 documentation work only — no new code beyond the install.sh rename + the SECURITY.md "Distribution model" subsection. |

</phase_requirements>

## Project Constraints (from CLAUDE.md)

The project's `CLAUDE.md` carries Phase-2.5 / 2.7 / 4 invariants forward into Phase 3. Planner MUST honour:

- **Platform**: macOS Apple Silicon only — no x86 path. install.sh continues to enforce `/opt/homebrew` Step 1 sanity check.
- **Tech stack**: Hammerspoon (Lua), whisper.cpp, sox, bash glue — no heavy frameworks. Phase 3 adds only `hyperfine` (already a STACK.md "supporting" entry) as a bench-only tool, not a runtime dep.
- **Cost**: zero recurring cost. MIT license + GitHub raw URL + free public repo = $0 marginal cost.
- **GSD workflow enforcement**: do not edit files outside a GSD command. Phase 3 work happens via `/gsd:execute-phase 3`.
- **Brand consistency**: all Phase 3 deliverables must pass `tests/test_brand_consistency.sh` (zero `voice-cc` strings outside the documented exemption set).
- **Framing lint**: SECURITY.md additions in Phase 3 must pass `tests/test_security_md_framing.sh` (no `compliant`/`certified`/`guarantees` without qualifier; keep canonical tagline; required H2 sections present).
- **Pattern 2 invariant**: `grep -c WHISPER_BIN purplevoice-record == 2` and `! grep -q whisper-cli purplevoice-lua/init.lua`. Phase 3 does NOT modify either file.
- **Pre-commit hooks**: brand-consistency + framing-lint run per commit. Phase 3 deliverables (LICENSE, BENCHMARK.md, install.sh, uninstall.sh, README rewrites, tests/benchmark/) must all pass on first commit.

## Standard Stack

### Core (already installed; no new runtime deps)

| Library / Tool | Version (verified 2026-04-30) | Purpose | Why Standard |
|---|---|---|---|
| **bash** | system 5.x (or 3.2 fallback) | install.sh + uninstall.sh shells | Already the project's glue language; STACK.md HIGH confidence. |
| **git** | 2.50.1 (Apple Git-155 verified live) | Required by curl|bash path to clone the repo into `~/.local/share/purplevoice/src/` | macOS ships git via Xcode CLT; users with brew already have it. install.sh's pre-flight already implicitly assumes git for the existing brew workflow. |
| **curl** | system | Public-installer entry-point; model + Silero downloads | macOS-default; not added by install.sh. The user's `curl -fsSL https://...` is the entry point. |
| **gh CLI** | 2.86.0 (verified live) | One-shot `gh repo edit --visibility public` flip command | Maintainer-only tool; not a user-runtime dep. The flip is performed by Oliver via gh once, then never again. |

### Phase-3-new tools (bench-only / docs-only; not user runtime)

| Library / Tool | Version | Purpose | Why Standard |
|---|---|---|---|
| **hyperfine** | 1.20.0 (released 2025-11-18 per brew formula) | Micro-benchmarking the whisper-cli transcription path on 3 reference WAVs | STACK.md already lists hyperfine for benchmarking; v1.20.0 is current. `brew install hyperfine`. License: Apache-2.0 OR MIT (compatible with PurpleVoice MIT). |
| **macOS `say`** | system (built-in) | One-shot generation of the 3 reference benchmark WAVs (committed to repo; user never re-runs) | Built-in, free, deterministic-enough for one-shot generation; reproducibility caveat documented (TTS engine bytes drift across macOS major versions). |
| **macOS `afconvert`** | system (built-in) | Convert `say` AIFF output to 16kHz mono WAV (whisper-cli expects this format) | Built-in, free; alternatively use `sox` (already installed by install.sh Step 2) for the same conversion. `afconvert` is preferred — fewer dependencies on user env. |

### Already in the project (no version change)

`Hammerspoon 1.1.1`, `sox 14.4.2`, `whisper-cpp` (whisper-cli) `v1.8.4`, `Karabiner-Elements`, `Syft 1.43.0+`, `ggml-small.en.bin` SHA256 `c6138d6d58ecc8322097e0f987c32f1be8bb0a18532a3f88f734d1bbf9c41e5d` (488 MB; pinned in setup.sh Step 5).

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| `hyperfine` | `time` (built-in) + manual averaging | hyperfine handles warmup, statistical outlier detection, JSON export, multi-command comparison out of the box — `time` would require a hand-rolled aggregator. |
| `say` for ref WAVs | Hand-recorded WAVs from Oliver's mic | Hand-recorded WAVs would be more "real" but committing voice content of Oliver's actual speech to a public repo creates an unnecessary biometric surface. Synthetic TTS sidesteps that and keeps the WAVs reproducible (per documented caveat). |
| `say` + `afconvert` | `say` direct WAV output via `--data-format` flag | The direct route works (`say -o out.wav --data-format=LEI16@16000 "text"`) and is simpler. Recommend the direct route — see "Reference WAV generation" below. |
| `gh repo edit --visibility public` | GitHub web UI Settings → Danger Zone → Change visibility | gh CLI is scriptable + auditable; web UI requires manual confirmation. The plan should use gh + log the command in the PHASE-SUMMARY.md for auditability. |

**Installation:**

```bash
# Phase 3 adds one bench-only dep:
brew install hyperfine

# All other tools (gh, git, curl, say, afconvert, sox) are already installed.
```

**Version verification:** Run `brew info hyperfine` before Phase 3 Wave 0 to confirm 1.20.0+ is the current version. The `1.18.x` spec in STACK.md is stale; `1.20.0` (Nov 2025) is the current `brew install` resolution.

## Architecture Patterns

### Recommended Project Structure (Phase 3 additions in **bold**)

```
purplevoice-record           # bash glue (untouched)
purplevoice-lua/init.lua     # Hammerspoon module (untouched)
**install.sh**               # renamed from setup.sh; gains curl-vs-clone detection + banner
**uninstall.sh**             # NEW — XDG dir + symlink removal + manual-instructions print
setup.sh                     # DELETED after the `git mv setup.sh install.sh`
**LICENSE**                  # NEW — MIT, canonical text from opensource.org
**BENCHMARK.md**             # NEW — hyperfine methodology + raw numbers + Phase-5 trigger
README.md                    # REWRITTEN per D-11/D-12 (quickstart top + detailed below + 4 recovery items)
SECURITY.md                  # AMENDED — new "Distribution model" subsection; NO framing-lint regression
SBOM.spdx.json               # AUTO-REGENERATED by install.sh Step 8 (Syft); MIT license auto-picked-up
assets/
  icon-256.png                  # untouched (Phase 2.5)
  icon.svg                      # untouched
  karabiner-fn-to-f19.json      # untouched (Phase 4)
  karabiner-backtick-to-f18.json# untouched (Phase 4)
  README.md                     # untouched
config/denylist.txt          # untouched (Phase 2)
**tests/benchmark/**         # NEW — 3 reference WAVs + HOW-TO-REGENERATE.md
  **2s.wav**                 # ~50 KB, 16kHz mono, ~2s utterance via `say`
  **5s.wav**                 # ~50 KB, 16kHz mono, ~5s utterance
  **10s.wav**                # ~50 KB, 16kHz mono, ~10s utterance
  **HOW-TO-REGENERATE.md**   # the exact `say` command + version notes
**tests/test_install_sh_detection.sh**       # NEW — unit test for curl-vs-clone detection (mocks $0)
**tests/test_uninstall_dryrun.sh**           # NEW — unit test for uninstall.sh idempotency
tests/                       # rest unchanged; functional suite grows 11 → 13
.planning/                   # untouched (audit-trail visible after public flip per D-07)
```

### Pattern 1: curl|bash detection via `$0` + `.git`-presence (NOT `[ -t 0 ]`)

**What:** install.sh inspects whether `$0` resolves to a real file inside a git checkout. If yes → run from clone path. If no → curl|bash path; git-clone first, then re-exec.

**When to use:** PurpleVoice's install.sh has TWO valid invocation modes (clone-then-run AND curl|bash) — and the BEHAVIOUR DIFFERS between them (curl|bash needs to clone the repo first; clone-then-run does not). Homebrew uses `[ -t 0 ]` because its behaviour does NOT differ between modes (it just bails noisily in non-interactive). PurpleVoice is the opposite case.

**Why not `[ -t 0 ]`:** `[ -t 0 ]` only tells you "stdin is not a TTY" — which is true for curl|bash, BUT also true if the user runs `bash install.sh < /dev/null` from a clone. False positive.

**Why not `BASH_SOURCE`:** When bash receives a script via stdin (`curl ... | bash`), `BASH_SOURCE[0]` is the empty string AND `$0` is `bash`. When bash runs a script via `bash install.sh`, `BASH_SOURCE[0]` is `install.sh` and `$0` is `install.sh`. Distinguishing these cases via `BASH_SOURCE` works but the `.git`-presence check is more direct and survives any `bash <(curl ...)` exotic-invocation variants.

**Why not an explicit `--from-curl` flag:** Adding a flag means the public-installer URL stops being just `... | bash` and becomes `... | bash -s -- --from-curl`. Uglier; doesn't dodge the detection problem (the flag itself is the detection). Reject.

**Recommended idiom (cribbed shape from oh-my-zsh + Homebrew, adapted to PurpleVoice's two-mode behaviour):**

```bash
# install.sh — paste near the top, after the Apple-Silicon sanity check
# Source: synthesised from oh-my-zsh tools/install.sh + Homebrew install.sh + PurpleVoice CONTEXT.md D-04.

detect_invocation_mode() {
  # Returns "clone" or "curl" by writing to stdout.
  # Heuristic: $0 is a real file inside a git checkout → clone mode.
  #            otherwise → curl|bash mode.
  local script_path="${BASH_SOURCE[0]:-$0}"
  if [ -f "$script_path" ] && \
     git -C "$(dirname "$(realpath "$script_path" 2>/dev/null || echo "$script_path")")" rev-parse --git-dir >/dev/null 2>&1; then
    echo "clone"
  else
    echo "curl"
  fi
}

# Use it
INVOCATION_MODE="$(detect_invocation_mode)"
case "$INVOCATION_MODE" in
  clone)
    REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    print_banner_clone "$REPO_ROOT"
    ;;
  curl)
    print_banner_curl
    bootstrap_clone_then_re_exec   # see Pattern 2 below
    ;;
esac
```

**Source:** [oh-my-zsh installer line 9 (`set -e` + ZDOTDIR + ZSH default)](https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh) — pattern of "computed REPO_ROOT then proceed". [Homebrew install.sh `[ -t 0 ]` idiom](https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh) — confirms the TTY check is for non-interactive *prompting*, NOT mode detection.

### Pattern 2: bootstrap-clone-then-re-exec (curl|bash path)

**What:** When invoked via curl|bash, install.sh writes itself to a temp-dir-or-target-clone-dir, git-clones the repo, then re-execs install.sh from inside the clone (so all subsequent `$REPO_ROOT/...` references work).

**When to use:** Once `detect_invocation_mode` returns "curl".

**Recommended logic:**

```bash
bootstrap_clone_then_re_exec() {
  local CLONE_DIR="$HOME/.local/share/purplevoice/src"
  local REPO_URL="https://github.com/OliverGAllen/purplevoice.git"

  # Pre-flight: git available?
  if ! command -v git >/dev/null 2>&1; then
    echo "PurpleVoice: git is required for the curl|bash install path." >&2
    echo "  Install Xcode Command Line Tools: xcode-select --install" >&2
    echo "  Then re-run the curl one-liner." >&2
    exit 1
  fi

  # Pre-flight: parent dir creatable?
  mkdir -p "$(dirname "$CLONE_DIR")" || {
    echo "PurpleVoice: cannot create $(dirname "$CLONE_DIR"). Check disk + permissions." >&2
    exit 1
  }

  # Idempotency: clone dir exists?
  if [ -d "$CLONE_DIR/.git" ]; then
    echo "PurpleVoice: existing clone at $CLONE_DIR — pulling latest..."
    if ! git -C "$CLONE_DIR" pull --ff-only 2>&1; then
      echo "PurpleVoice: git pull failed (local edits or non-fast-forward). Inspect:" >&2
      echo "  cd $CLONE_DIR && git status" >&2
      echo "  Or remove and let curl|bash re-clone:  rm -rf $CLONE_DIR" >&2
      exit 1
    fi
  elif [ -e "$CLONE_DIR" ]; then
    echo "PurpleVoice: $CLONE_DIR exists but is not a git repo. Bailing." >&2
    echo "  Remove or rename it, then re-run." >&2
    exit 1
  else
    echo "PurpleVoice: cloning $REPO_URL into $CLONE_DIR..."
    git clone --depth 1 "$REPO_URL" "$CLONE_DIR" || {
      echo "PurpleVoice: git clone failed. Network down? Repo private?" >&2
      echo "  Verify: curl -fsSI $REPO_URL" >&2
      exit 1
    }
  fi

  # Re-exec from the clone — all subsequent $REPO_ROOT references work.
  echo "PurpleVoice: re-exec'ing install.sh from $CLONE_DIR..."
  exec bash "$CLONE_DIR/install.sh"
}
```

**Note on `--depth 1`:** Shallow clone halves disk + bandwidth on first install. Future `git pull --ff-only` from a shallow clone works for fast-forward updates from `main`. If the user later wants the full history (`.planning/` deep audit trail), they run `git -C ~/.local/share/purplevoice/src fetch --unshallow` manually — document this in HOW-TO-REGENERATE.md or README §"Detailed Install".

**Why `exec` rather than `bash $CLONE_DIR/install.sh`:** `exec` replaces the current shell, so the curl|bash bootstrap process exits as the install.sh process exits — clean exit codes, no double-banner, no nested set -e drift.

### Pattern 3: install.sh detect-mode banner

**Recommended banner text (matches existing setup.sh Step 10 banner conventions — `cat <<'EOF'` blocks + `----------` rule lines):**

For curl|bash:

```
----------------------------------------------------------------------
PurpleVoice installer (via curl | bash)

  Cloning OliverGAllen/purplevoice into ~/.local/share/purplevoice/src/
  All subsequent install steps run from that local clone.
  Re-running this one-liner is safe — git pull + idempotent re-install.

Local voice dictation. Nothing leaves your Mac.
----------------------------------------------------------------------
```

For local clone:

```
----------------------------------------------------------------------
PurpleVoice installer (local clone at <REPO_ROOT>)

  Idempotent — safe to re-run.
  Re-runs preserve user-edited config (~/.config/purplevoice/vocab.txt).

Local voice dictation. Nothing leaves your Mac.
----------------------------------------------------------------------
```

Both banners include the canonical tagline (Phase 2.5 BRD-02 / D-11 — required by `tests/test_security_md_framing.sh` if it ever sweeps install.sh, and a recognisable visual anchor for Oliver). Both banners reference the canonical paths so the user sees what's about to happen.

### Pattern 4: hyperfine command structure for the 3 benchmarks

**Recommended invocation per WAV length (run 3 times, once per WAV file):**

```bash
hyperfine \
  --warmup 3 \
  --runs 10 \
  --shell none \
  --command-name "whisper-cli small.en — 5s.wav" \
  --export-json tests/benchmark/results-5s.json \
  --export-markdown tests/benchmark/results-5s.md \
  -- \
  "/opt/homebrew/bin/whisper-cli -m $HOME/.local/share/purplevoice/models/ggml-small.en.bin -f tests/benchmark/5s.wav -nt"
```

**Flag justification:**

| Flag | Why |
|---|---|
| `--warmup 3` | hyperfine has no documented default warmup (man page silent); 3 is conservative — enough to warm filesystem cache + Apple Silicon thermal state. CONTEXT.md D-08 specifies "3 warmup runs (hyperfine defaults)" — 3 is the right number; we're being explicit. |
| `--runs 10` | hyperfine default is `--min-runs 10` with no upper bound (auto-determined). For PurpleVoice's transcription benchmark, 10 runs at ~0.5-1s per run = 5-10 seconds wall time per length. Predictable. CONTEXT.md D-08 confirms 10. |
| `--shell none` (`-N`) | Skip shell startup overhead; whisper-cli is invoked directly. Without `-N`, hyperfine wraps each run in `sh -c "..."` (~1-3ms shell startup tax). For sub-second benchmarks, the tax is non-negligible. |
| `--command-name` | Friendlier label in the markdown export; auditable when published in BENCHMARK.md. |
| `--export-json` | Machine-readable; feeds the post-process p95 calculator (see Pattern 5). |
| `--export-markdown` | Drop-in for BENCHMARK.md inclusion (the markdown table is hyperfine-formatted; just include it). |
| `-nt` (whisper-cli) | "no-timestamps" — verified via [ggml-org/whisper.cpp/examples/cli/cli.cpp line 544](https://github.com/ggml-org/whisper.cpp/blob/master/examples/cli/cli.cpp). Outputs plain text only; benchmarks Stage-2 transcription latency without the timestamp-formatting overhead. CONTEXT.md D-08 confirms. |
| absolute path to whisper-cli | Pattern 2 / ROB-03 invariant — Hammerspoon's PATH doesn't include `/opt/homebrew/bin` on Apple Silicon. Match the production path even when running under hyperfine in a normal shell. |

### Pattern 5: hyperfine JSON → p95 post-process

**The hyperfine native problem:** `hyperfine --export-json` writes mean / stddev / median / user / system / min / max / `times` (raw run-time array) / `exit_codes` per command. **It does NOT write p95 / p75 / p25 / IQR.** Confirmed via [hyperfine issue #22](https://github.com/sharkdp/hyperfine/issues/22) (still open as a feature request) and [the upstream `scripts/advanced_statistics.py`](https://github.com/sharkdp/hyperfine/blob/master/scripts/advanced_statistics.py) (author's own workaround — computes p5/p25/p75/p95 + IQR from `times[]` via numpy).

**Recommended approach:** Vendor a small Python or jq one-liner into the repo (e.g., `tests/benchmark/quantiles.py` or `tests/benchmark/quantiles.sh`) that ingests the hyperfine JSON and emits p95. Two viable implementations:

**Option A — Python (matches upstream `scripts/advanced_statistics.py`; requires `python3` + `numpy`):**

```python
#!/usr/bin/env python3
# tests/benchmark/quantiles.py
# Ingest hyperfine JSON; print p50 + p95 + the Phase-5 trigger evaluation.
import json, sys
import statistics

with open(sys.argv[1]) as f:
    data = json.load(f)

for r in data["results"]:
    times = sorted(r["times"])
    n = len(times)
    p50 = statistics.median(times)
    # nearest-rank p95 (no interpolation; matches numpy default for n=10 within ~50ms)
    p95_idx = int(round(0.95 * (n - 1)))
    p95 = times[p95_idx]
    cmd = r.get("command", "?")
    print(f"{cmd}: p50={p50:.3f}s p95={p95:.3f}s")
```

**Option B — jq (no Python dep; uses jq which is already a project dep for SBOM post-process):**

```bash
#!/usr/bin/env bash
# tests/benchmark/quantiles.sh — print p50 + p95 from hyperfine JSON via jq.
JSON="$1"
jq -r '
  .results[] |
  .times | sort as $t |
  ($t | length) as $n |
  ($t[($n / 2 | floor)]) as $p50 |
  ($t[(0.95 * ($n - 1) | round)]) as $p95 |
  "p50=\($p50 | tostring | .[0:5])s p95=\($p95 | tostring | .[0:5])s"
' "$JSON"
```

**Recommendation: Option B (jq).** Reasons: (1) Project already depends on jq (Phase 2.7 setup.sh Step 8 SBOM post-process). (2) No new Python runtime dep. (3) Adequate precision for the Phase-5 trigger (p95 > 4s is a coarse threshold; nearest-rank quantile error on n=10 is ~5%, well below the 4-second threshold's floor).

**The Phase-5 trigger evaluation:** wrap the jq output in a small bash gate:

```bash
P50=$(jq '.results[0].times | sort | .[length/2 | floor]' tests/benchmark/results-5s.json)
P95=$(jq '.results[0].times | sort | .[0.95 * (length - 1) | round]' tests/benchmark/results-5s.json)
if (( $(echo "$P50 > 2" | bc -l) )) || (( $(echo "$P95 > 4" | bc -l) )); then
  echo "TRIGGER: Phase 5 active (p50=${P50}s OR p95=${P95}s exceeds threshold)"
else
  echo "OK: Phase 5 deferred (p50=${P50}s ≤ 2s AND p95=${P95}s ≤ 4s)"
fi
```

### Pattern 6: Reference WAV generation (one-shot, committed)

**Recommended approach: macOS `say -v Daniel` direct WAV output.** Verified per [ss64.com `say` reference](https://ss64.com/mac/say.html) — `say` supports `--data-format=LEI16@16000` to emit 16-bit little-endian integer samples at 16kHz, which is exactly what whisper-cli ingests without resampling.

**Recommended utterance text (designed for ~2s, ~5s, ~10s when spoken at ~150 WPM by Daniel; tested empirically in HOW-TO-REGENERATE.md):**

| File | Approx duration | Text |
|---|---|---|
| `tests/benchmark/2s.wav` | ~2.0 s | `"Hammerspoon and whisper run locally."` |
| `tests/benchmark/5s.wav` | ~5.0 s | `"PurpleVoice transcribes voice into text without sending data to the cloud."` |
| `tests/benchmark/10s.wav` | ~10.0 s | `"PurpleVoice is a push to talk dictation tool for Apple Silicon Macs that uses whisper dot cpp running entirely on device with no telemetry and no subscription."` |

**Generation commands (one-shot; output committed to repo):**

```bash
mkdir -p tests/benchmark
say -v Daniel --data-format=LEI16@16000 -o tests/benchmark/2s.wav  "Hammerspoon and whisper run locally."
say -v Daniel --data-format=LEI16@16000 -o tests/benchmark/5s.wav  "PurpleVoice transcribes voice into text without sending data to the cloud."
say -v Daniel --data-format=LEI16@16000 -o tests/benchmark/10s.wav "PurpleVoice is a push to talk dictation tool for Apple Silicon Macs that uses whisper dot cpp running entirely on device with no telemetry and no subscription."

# Sanity check: file size + format
soxi tests/benchmark/{2,5,10}s.wav
```

**Voice choice rationale:**

- **`Daniel`** — UK English (matches Oliver's UK keyboard layout / regional context).
- Alternative: **`Samantha`** — US English; default for many users. Both are bundled with macOS Sequoia.
- Avoid Siri-quality "premium" voices (e.g., `Ava (Premium)`) — they require a separate download per macOS install, breaking reproducibility.

**Reproducibility caveat (DOCUMENT IN HOW-TO-REGENERATE.md):** `say` voice synthesis is NOT byte-identical across macOS major versions. The committed WAVs are the canonical reference. If a future contributor regenerates the WAVs from scratch on a different macOS version, the bytes will differ but the durations (~2s / ~5s / ~10s) and the transcript outputs (Whisper's view of the audio) should be ≥95% identical — sufficient for benchmark continuity.

**File format verification:** `soxi tests/benchmark/2s.wav` should show `Sample Rate: 16000`, `Channels: 1`, `Sample Encoding: 16-bit Signed Integer PCM`. If `--data-format=LEI16@16000` doesn't produce this exact format on Oliver's macOS version, fall back to:

```bash
# Fallback: generate AIFF then sox-convert
say -v Daniel -o tmp.aiff "..."
sox tmp.aiff -r 16000 -c 1 -b 16 tests/benchmark/2s.wav
rm tmp.aiff
```

### Pattern 7: uninstall.sh idempotent skeleton

**Structure:** mirror install.sh's idempotent step pattern. Each removal is conditional on presence; re-runs print "already removed" + exit 0.

```bash
#!/usr/bin/env bash
# uninstall.sh — remove PurpleVoice user-installed surfaces.
# IDEMPOTENT — safe to re-run.
# Does NOT remove: Hammerspoon, sox, whisper-cpp, Karabiner-Elements (may serve other tools).
# Does NOT remove: Karabiner rule files in ~/.config/karabiner/ (don't touch user config).
# Prints actionable manual-removal instructions for those.

set -uo pipefail

cat <<'EOF'
----------------------------------------------------------------------
PurpleVoice uninstaller — removes XDG dirs + symlinks + Hammerspoon module dir.

  Hammerspoon, sox, whisper-cpp, Karabiner-Elements, and the Karabiner rule
  files are NOT removed — they may serve other tools on your system.
  Manual-removal instructions are printed at the end.
----------------------------------------------------------------------

EOF

REMOVED=0

# 1. XDG directories
for d in "$HOME/.config/purplevoice" "$HOME/.cache/purplevoice" "$HOME/.local/share/purplevoice"; do
  if [ -d "$d" ]; then
    echo "Removing $d"
    rm -rf "$d"
    REMOVED=$((REMOVED + 1))
  else
    echo "Already absent: $d"
  fi
done

# 2. Symlinks (only if they point into the purplevoice install)
PV_BIN="$HOME/.local/bin/purplevoice-record"
if [ -L "$PV_BIN" ]; then
  TARGET="$(readlink "$PV_BIN")"
  case "$TARGET" in
    *purplevoice*|*voice-cc*)
      echo "Removing symlink $PV_BIN → $TARGET"
      rm "$PV_BIN"
      REMOVED=$((REMOVED + 1))
      ;;
    *)
      echo "Skipping $PV_BIN — points at $TARGET (not a PurpleVoice install; leaving alone)"
      ;;
  esac
elif [ -e "$PV_BIN" ]; then
  echo "WARN: $PV_BIN is a regular file, not a symlink — leaving alone." >&2
else
  echo "Already absent: $PV_BIN"
fi

# 3. Hammerspoon module symlink
HS_MODULE="$HOME/.hammerspoon/purplevoice"
if [ -L "$HS_MODULE" ]; then
  echo "Removing symlink $HS_MODULE"
  rm "$HS_MODULE"
  REMOVED=$((REMOVED + 1))
elif [ -d "$HS_MODULE" ]; then
  echo "Removing directory $HS_MODULE"
  rm -rf "$HS_MODULE"
  REMOVED=$((REMOVED + 1))
else
  echo "Already absent: $HS_MODULE"
fi

# 4. Final banner with manual-removal instructions
cat <<'EOF'

----------------------------------------------------------------------
Manual cleanup (PurpleVoice cannot do these for you):

  1. Remove the require("purplevoice") line from ~/.hammerspoon/init.lua
     (and reload Hammerspoon: menubar → Reload Config).

  2. Disable the Karabiner rules (PurpleVoice — fn → F19 + PurpleVoice — backtick → F18):
     Karabiner-Elements → Preferences → Complex Modifications → toggle off.
     The rule JSONs themselves stay in place; remove from ~/.config/karabiner/
     manually if you want a full cleanup.

  3. Optional: brew uninstall hammerspoon sox whisper-cpp
     (only if no other tools on your machine use them).

  4. Optional: revoke Hammerspoon's TCC permissions (if you don't use Hammerspoon for
     anything else):
       tccutil reset Microphone org.hammerspoon.Hammerspoon
       tccutil reset Accessibility org.hammerspoon.Hammerspoon

PurpleVoice removed $REMOVED user-data items. Bye.
----------------------------------------------------------------------
EOF

exit 0
```

**Safety-by-default rationale (Claude's Discretion answered):** The script removes everything PurpleVoice owns without prompting (no `read -p "Are you sure?"`). Reasons: (1) the user explicitly invoked uninstall.sh — consent is implicit. (2) The XDG dirs only contain PurpleVoice-owned files (vocab.txt, denylist.txt, model files, cache) — re-creatable by re-running install.sh. (3) Adding a confirm prompt breaks `bash uninstall.sh` in non-interactive scripts. (4) Mirrors `apt-get purge`-style discipline.

If the user wants to preserve `vocab.txt` (the only file they may have edited), they can copy it out before running:

```bash
cp ~/.config/purplevoice/vocab.txt /tmp/my-vocab.txt
bash uninstall.sh
```

This trade-off should be documented in README §"Detailed Install / Uninstall".

### Pattern 8: README structure for the rewrite (D-11)

Recommended ordering, modeled after [oh-my-zsh README](https://github.com/ohmyzsh/ohmyzsh#readme), [Homebrew README](https://github.com/Homebrew/brew#readme), and [rustup home page](https://www.rust-lang.org/tools/install) — institutional-friendly = "what is this" → "install in 30 seconds" → "what next" → "details below for those who care":

```markdown
# PurpleVoice

**Local voice dictation. Nothing leaves your Mac.**
[icon]
[1-paragraph what-it-is]

## Quickstart

curl -fsSL https://raw.githubusercontent.com/OliverGAllen/purplevoice/main/install.sh | bash

[3-line "now hold fn / hold backtick" pointer]
[1-line "see Detailed Install below if anything fails"]

## Hotkeys

[existing F19 + backtick table — preserved as-is from current README]

## Performance

[3-row hyperfine table: 2s / 5s / 10s × p50 / p95]
[1-line Phase 5 trigger status: deferred / active]
[link to BENCHMARK.md]

## Who this is for

[existing 6-bullet audience list — unchanged from current README §"Who this is for"]

## Detailed Install

### Karabiner-Elements
[unchanged from current README §"Karabiner-Elements"]

### Permissions
[unchanged from current README §"Permissions to grant manually"]

### Conflicting macOS feature
[unchanged]

### Recovery (D-12 4-item triage)
1. TCC reset
2. Karabiner rule troubleshoot (UK keyboard `non_us_backslash` vs ANSI/US `grave_accent_and_tilde`)
3. "I lost my hotkeys" decision-tree (see below)
4. uninstall.sh

### "I lost my hotkeys" decision-tree (D-12 item 3)
[5-step bullet list — see Pattern 9 below]

### Uninstalling
bash uninstall.sh
[1-paragraph: what gets removed + manual cleanup pointer]

## Security & Privacy

[unchanged from current README — links to SECURITY.md]

## HUD privacy and screen-recording visibility

[unchanged from current README]

## Visual identity / Project layout / Why "PurpleVoice"

[unchanged]

## Status

[KEEP the phase progress table — recommendation: trim to a 3-line summary + link to ROADMAP.md for detail. Maintenance burden reduced.]
```

**On the "Status" / "Phase progress" section (Claude's Discretion):** Recommend **trim to summary + link**, not drop. Reasons:
- Institutional readers want to see the project is alive + has structure (the phase progress signals "this is engineered, not a hack").
- Maintaining a 3-line summary on phase-transition is cheap (the `/gsd:transition` command prompts for it anyway).
- A separate CHANGELOG would duplicate ROADMAP — over-engineering.

### Pattern 9: "I lost my hotkeys" decision-tree (D-12 item 3)

**Format recommendation: numbered list with conditional branches** — readable for non-developer institutional reviewers (avoid ASCII art which renders inconsistently in GitHub vs Obsidian vs grep). Mark each step's *symptom* and *fix* explicitly:

```markdown
### "I lost my hotkeys" — 5-step triage

If holding fn no longer triggers PurpleVoice recording (or holding backtick no longer re-pastes):

1. **Reload Hammerspoon.**
   - Menubar → Hammerspoon → Reload Config.
   - Symptom of failure: still no response → continue to step 2.

2. **Check the Karabiner-Elements menubar icon is present.**
   - If absent: launch Karabiner-Elements (open `/Applications/Karabiner-Elements.app`); the menubar icon should appear within 5 seconds.
   - Symptom of failure: launching produces no menubar icon → reinstall Karabiner-Elements (re-grant the system-extension prompt).

3. **Verify both rules are enabled.**
   - Karabiner-Elements → Preferences → Complex Modifications.
   - Both rules should be present + toggled ON:
     - "Hold fn → F19 (PurpleVoice push-to-talk)"
     - "Hold ` (backtick) → F18 (PurpleVoice re-paste)"
   - If absent: re-import via "Add rule → Import rule from file" → select the JSON files in `assets/karabiner-*.json` from your PurpleVoice clone.

4. **Use Karabiner Event Viewer to confirm key codes.**
   - Karabiner-Elements menubar → "Event Viewer".
   - Hold `fn`. The viewer should show `f19` events flowing.
   - Hold `` ` ``. The viewer should show `f18` events flowing.
   - **Common UK-vs-US gotcha:** the backtick rule uses `non_us_backslash` (UK + most non-US keyboards). On ANSI/US keyboards, edit `assets/karabiner-backtick-to-f18.json` and change both `non_us_backslash` values to `grave_accent_and_tilde`, then re-import.
   - If F19/F18 events are NOT flowing: the Karabiner rule isn't firing → re-check step 3.
   - If F19/F18 events ARE flowing but PurpleVoice doesn't react: continue to step 5.

5. **Check Hammerspoon console for binding-failed alerts.**
   - Menubar → Hammerspoon → Console.
   - Look for the most recent reload — is there a `PurpleVoice loaded` alert? If NO: `init.lua` failed to load → check `~/.hammerspoon/init.lua` contains `require("purplevoice")` and that no syntax error appears in the console.
   - If YES (PurpleVoice loaded BUT keypresses don't trigger it): another app may be silently consuming the F19 / F18 key (Carbon `RegisterEventHotKey` collision — see Phase 4 D-02 SUPERSEDED notes). Try quitting clipboard managers / global-hotkey daemons one at a time and re-testing.
```

This format is plain markdown (renders identically everywhere), action-oriented (each step has a "do this" + "if it fails, do that"), and references the Phase 4 deviation lesson explicitly (item 4: UK vs ANSI keyboard; item 5: silent Carbon consumption).

### Anti-Patterns to Avoid

- **Auto-copying Karabiner JSONs into `~/.config/karabiner/assets/complex_modifications/`** — Phase 4 D-07 "Document + check" stance is explicit: minimal automation. Auto-copy violates that. If install.sh writes into the user's Karabiner config dir, idempotency questions multiply (overwrite if exists? merge if user customised?). KEEP the manual-import-from-repo-path workflow Phase 4 established. Banner pointer is sufficient.
- **`gh repo edit --visibility public` without `--accept-visibility-change-consequences`** — verified via [gh CLI manual](https://cli.github.com/manual/gh_repo_edit) that the flag is REQUIRED in non-interactive mode. Without it, the command fails silently in scripts. Always pass it for the flip.
- **`bash <(curl ...)` instead of `curl ... | bash`** — process substitution doesn't work consistently in zsh; users who paste `bash <(curl ...)` may hit "no such file" errors on certain shell configurations. Stick with the canonical `curl -fsSL ... | bash` idiom.
- **Removing `setup.sh` references from historical artifacts (`.planning/phases/*/`)** — those are audit trail per Phase 2.5 D-07. Only sweep ACTIVE surfaces (README, install.sh internal references, REQUIREMENTS.md, ROADMAP.md). Historical CONTEXT.md / SUMMARY.md keep `setup.sh` verbatim.
- **Adding `SPDX-License-Identifier: MIT` headers to every source file** — overkill for a 470-line bash script + 350-line Lua module. The root `LICENSE` file is sufficient. Linus-style minimalism. (Add headers ONLY if a downstream consumer specifically requests SPDX in source — defer).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Curl-vs-clone detection | A flag-based mode-selector (`install.sh --from-curl`) | `[ -f "$0" ]` + `git rev-parse --git-dir` check | Detection-by-state is more robust than detection-by-flag. Users may forget the flag; bash redirection + curl piping interact in surprising ways with positional arg parsing. |
| Bench statistics aggregator | A custom Python or bash script that times whisper-cli, runs N iterations, computes stats | `hyperfine` | hyperfine handles warmup, outlier detection, JSON+markdown export, multi-command comparison — replicating any of these is engineer-time wasted on a problem someone solved well. |
| p95 from raw timings | A custom bash array-sort + index calculation | `jq` (already a project dep) one-liner OR upstream `scripts/advanced_statistics.py` | jq sorts, slices, and arithmetic in 1 line. Hand-rolled bash array-sort is brittle (locale-dependent numeric sort, IFS handling). |
| MIT license boilerplate | Hand-typing the license text | Copy verbatim from [opensource.org/license/mit](https://opensource.org/license/mit) | Canonical text is 14 lines including blank lines; no value in re-typing. |
| Reference WAV recording | Recording your own voice on Oliver's mic | macOS `say -v Daniel` | Oliver's voice is biometric data; committing it to a public repo is an unnecessary surface. Synthetic TTS is reproducible-enough (caveat documented). |
| GitHub repo public flip | Manual click-through in GitHub Settings UI | `gh repo edit --visibility public --accept-visibility-change-consequences` | Scriptable, auditable, captured in PHASE-SUMMARY.md. |
| Public-installer URL hosting | Setting up DNS + CDN (`get.purplevoice.com`) | GitHub raw URL: `https://raw.githubusercontent.com/OliverGAllen/purplevoice/main/install.sh` | Per CONTEXT.md Deferred Ideas — vanity domain is a v1.5+ concern. GitHub raw is free, served over CDN, version-pinned to `main` HEAD by default. |
| Uninstall safety prompts | `read -p "Are you sure?" yn` confirm prompts | Trust the user's invocation; print a warning banner instead | The user explicitly invoked uninstall.sh; consent is implicit. Confirm prompts break non-interactive scripting. |
| Karabiner JSON auto-copy | Custom code that writes into `~/.config/karabiner/` | Manual import via Karabiner UI (current Phase 4 pattern) | Phase 4 D-07 minimal-automation stance; user owns their Karabiner config. |

**Key insight:** Phase 3 is dominated by problems with established solutions. Every Phase 3 deliverable should match an existing pattern from a high-trust open-source project (oh-my-zsh / Homebrew / rustup for installers; hyperfine for benchmarks; opensource.org for license). Innovation surface is near-zero. Discipline = recognise + apply, not invent.

## Runtime State Inventory

Phase 3 is mostly a **rename phase** for `setup.sh` → `install.sh` (D-05) plus net-new file additions. Per the planner's research protocol Step 2.5, the rename surface MUST be inventoried for runtime-state hazards:

| Category | Items Found | Action Required |
|---|---|---|
| **Stored data** | None — PurpleVoice's data layer is filesystem-only (XDG dirs); no databases, no ChromaDB, no Mem0, no Redis. The `setup.sh` filename does not appear inside any vocab.txt / denylist.txt / .config/purplevoice/ file. Verified by grep. | None |
| **Live service config** | None — PurpleVoice is not a service. No n8n / Datadog / Cloudflare config holds the string `setup.sh`. | None |
| **OS-registered state** | None — there is no LaunchAgent, launchd plist, or Task-Scheduler entry referencing `setup.sh`. The Hammerspoon `require("purplevoice")` line is in `~/.hammerspoon/init.lua` (user-owned; not a PurpleVoice-managed surface) and references the module name `purplevoice`, NOT the installer filename. | None |
| **Secrets and env vars** | The only env vars are `PURPLEVOICE_OFFLINE`, `PURPLEVOICE_HUD_OFF`, `PURPLEVOICE_HUD_POSITION`, `PURPLEVOICE_NO_SOUNDS` — set by user's shell, not stored in install.sh as a name. Renaming the script does not affect any env var name. | None |
| **Build artifacts / installed packages** | The `~/.local/bin/purplevoice-record` symlink target is `<repo>/purplevoice-record` (not `setup.sh`). The `~/.hammerspoon/purplevoice` symlink target is `<repo>/purplevoice-lua/` (not `setup.sh`). Neither symlink names `setup.sh`. SBOM.spdx.json's `documentNamespace` references the repo URL, not the script filename. | **Yes — re-run `install.sh` once after the rename** to re-trigger SBOM regen with the new script's `inject_system_context` annotation `Tool: PurpleVoice-setup.sh` field. The Syft annotation literally embeds the string `setup.sh` in the SBOM (verified at `setup.sh` line 348). After renaming to install.sh, that annotation field text should be updated to `PurpleVoice-install.sh` for honesty. The SBOM regen is automatic on re-run; the planner just needs to make sure the annotation string in the new install.sh is updated. |

**The rename "static analysis" reality check:**

```bash
# Before any rename, audit the surface:
grep -rln "setup\.sh" \
  --include="*.sh" --include="*.lua" --include="*.md" --include="*.txt" --include="*.json" \
  . 2>/dev/null \
  | grep -v "^\./\.planning/" \
  | grep -v "^\./\.git/" \
  | grep -v "^\./tests/security/run_all\.sh"
```

Run this BEFORE Phase 3 Wave 0; the planner uses the output as the exact list of files to sweep. The `.planning/` exclusion preserves audit trail (Phase 2.5 D-07).

**One subtlety the planner MUST address:** `setup.sh` line 348 hardcodes the string `Tool: PurpleVoice-setup.sh` in the Syft annotation. After rename, this should become `Tool: PurpleVoice-install.sh`. Otherwise the SBOM lies about its origin.

## Common Pitfalls

### Pitfall 1: `gh repo edit --visibility public` silently no-ops in scripts without `--accept-visibility-change-consequences`

**What goes wrong:** Running `gh repo edit OliverGAllen/purplevoice --visibility public` in a non-interactive context (e.g., as part of a release script, or with stdin redirected) fails to flip visibility. No error is raised; the repo stays private.
**Why it happens:** GitHub's CLI added the `--accept-visibility-change-consequences` flag as a safety guard in late-2024 because public-flips can lose stars/watchers and expose previously-hidden git history. In interactive mode, gh prompts; in non-interactive, it requires the explicit flag.
**How to avoid:** ALWAYS pass `--accept-visibility-change-consequences` for the flip. Verify with:
```bash
gh repo view OliverGAllen/purplevoice --json visibility --jq '.visibility'
# Should print "PUBLIC" — not "PRIVATE".
```
**Warning signs:** No `gh` error output AND `gh repo view` still shows `PRIVATE` after the flip.

### Pitfall 2: GitHub case-sensitivity on raw.githubusercontent.com

**What goes wrong:** `curl -fsSL https://raw.githubusercontent.com/oliverallen/purplevoice/main/install.sh | bash` fails with 404 because the actual owner is `OliverGAllen`.
**Why it happens:** GitHub's git-clone path is case-insensitive (`git clone https://github.com/oliverallen/purplevoice.git` works), but the raw.githubusercontent.com CDN path can be case-sensitive depending on the CDN's cache state. Even when it does work, the cached vs uncached behaviour is inconsistent across geographies.
**How to avoid:** Use the verified live owner casing `OliverGAllen/purplevoice` everywhere — install.sh embedded URL, README quickstart, REQUIREMENTS.md.
**Warning signs:** README shows the wrong-cased URL; first user trying the public installer reports 404.

### Pitfall 3: `git pull` from `--depth 1` shallow clone fails on non-fast-forward

**What goes wrong:** A user re-runs the curl|bash one-liner; install.sh's `git pull --ff-only` in the existing `~/.local/share/purplevoice/src/` clone fails because upstream `main` has had a history rewrite (force-push) or because the user accidentally edited a file in the clone.
**Why it happens:** Shallow clones cannot fast-forward across non-trivial history changes. PurpleVoice's `main` shouldn't be force-pushed (the repo has been safe so far), but defensive coding matters.
**How to avoid:** install.sh's pull failure path prints actionable instructions: `cd ~/.local/share/purplevoice/src && git status` to inspect, `rm -rf` to reset. Document in HOW-TO-REGENERATE.md.
**Warning signs:** Re-running curl|bash prints `error: failed to pull` or the install proceeds against stale code.

### Pitfall 4: `say -v Daniel` voice differences across macOS major versions

**What goes wrong:** A future contributor regenerates `tests/benchmark/2s.wav` from scratch on a different macOS version. The bytes differ; the duration may shift by ±0.5s; whisper-cli transcribes the new WAV slightly differently. Benchmark continuity broken.
**Why it happens:** Apple's TTS engine is not version-stable. Voice models are tweaked between macOS releases.
**How to avoid:** Commit the WAVs binary to the repo as the canonical reference. Document the regeneration command in `tests/benchmark/HOW-TO-REGENERATE.md` so future readers can reproduce *if their macOS version matches*. Note explicitly that re-running on a newer macOS may produce drift; in that case, the new WAVs should be re-committed and BENCHMARK.md re-baselined (one-time disruption).
**Warning signs:** Different transcription text from `whisper-cli -nt -f tests/benchmark/2s.wav` after macOS upgrade.

### Pitfall 5: hyperfine's `--shell none` (`-N`) interaction with `~` expansion in commands

**What goes wrong:** `hyperfine -N 'whisper-cli -m ~/.local/share/.../ggml-small.en.bin -f tests/benchmark/2s.wav -nt'` fails because `~` is shell-expanded by sh — but `-N` skips sh, so `~` is passed literally to whisper-cli, which tries to open the file `./~/.local/share/...` and fails.
**Why it happens:** `-N` (no shell) means hyperfine `exec`s the command directly; tilde expansion is a shell feature.
**How to avoid:** Use `$HOME` or absolute paths in the hyperfine command, NOT `~`. Example: `hyperfine -N "whisper-cli -m $HOME/.local/share/purplevoice/models/ggml-small.en.bin -f tests/benchmark/2s.wav -nt"` — bash expands `$HOME` BEFORE passing to hyperfine.
**Warning signs:** hyperfine reports `ERROR: failed to read file: ~/.local/share/...`.

### Pitfall 6: hyperfine `--export-json` lacks p95; naive bench reports mean only

**What goes wrong:** A reader looks at BENCHMARK.md, sees `mean: 0.523s`, assumes that's "typical" — but the distribution may have a long right tail (p95 = 1.8s) caused by occasional thermal-throttling or background-task contention. The Phase-5 trigger (p50 > 2 OR p95 > 4) needs p95.
**Why it happens:** hyperfine's native JSON has min/mean/median/stddev/max but no quantiles. [Issue #22](https://github.com/sharkdp/hyperfine/issues/22) is the open feature request; upstream's [`scripts/advanced_statistics.py`](https://github.com/sharkdp/hyperfine/blob/master/scripts/advanced_statistics.py) is the workaround.
**How to avoid:** Vendor the small jq quantile script (Pattern 5 above) into `tests/benchmark/quantiles.sh` and have BENCHMARK.md report p50 + p95 derived from `times[]` array, not just mean.
**Warning signs:** Phase 5 trigger logic in BENCHMARK.md cites `mean` not `p50` / `p95`.

### Pitfall 7: `realpath` not available on stock macOS

**What goes wrong:** install.sh's curl-vs-clone detection (Pattern 1) uses `realpath "$script_path"` to canonicalise the path before checking `git -C` — but stock macOS bash does NOT include GNU `realpath` (only the brew-installed `coreutils` package does).
**Why it happens:** macOS Apple Silicon ships with `/bin/bash 3.2` and BSD coreutils; `realpath` is GNU.
**How to avoid:** Two options: (a) use `cd "$(dirname "$script_path")" && pwd` instead of `realpath` (POSIX-portable). (b) Add a fallback: `realpath "$path" 2>/dev/null || (cd "$(dirname "$path")" && pwd)`.
**Warning signs:** `install.sh: line N: realpath: command not found` on a fresh macOS install (especially for a curl|bash user who hasn't installed coreutils).

### Pitfall 8: SBOM.spdx.json `documentNamespace` references repo path → public flip exposes path

**What goes wrong:** Phase 2.7's setup.sh Step 8 generates SBOM.spdx.json with `documentNamespace` = `https://github.com/oliverallen/PurpleVoice/sbom/<commit>` (verified at setup.sh line 363) — note the WRONG capitalisation (`oliverallen` lowercase user, `PurpleVoice` mixed-case repo) — neither matches the actual `OliverGAllen/purplevoice`. After public flip, the SBOM publicly references a wrong URL.
**Why it happens:** The hardcoded URL in the deterministicise step doesn't match GitHub's real owner casing.
**How to avoid:** The planner MUST also update `setup.sh` line 363 (now `install.sh` after rename) to use `https://github.com/OliverGAllen/purplevoice/sbom/<commit>` BEFORE the public flip. Re-regenerate SBOM.spdx.json after the fix. Add to the D-06 pre-flip checklist.
**Warning signs:** After public flip, SBOM.spdx.json `documentNamespace` 404s when an auditor tries to resolve it.

### Pitfall 9: Removing `setup.sh` from `tests/test_brand_consistency.sh` exemption list breaks the lint

**What goes wrong:** Phase 3 renames setup.sh → install.sh. The brand-consistency lint at `tests/test_brand_consistency.sh` line 31 has `| grep -v "^\./setup\.sh$"` — exempting setup.sh because of the `migrate_xdg_dir` literals that intentionally contain `voice-cc`. After rename, the exemption needs to update to `^\./install\.sh$` OR the migration logic moves to a separate file.
**Why it happens:** The exemption is a path string, not a content-based detection.
**How to avoid:** When the planner does `git mv setup.sh install.sh`, also update `tests/test_brand_consistency.sh` line 31 to `| grep -v "^\./install\.sh$"`. Add a Wave-0 task: run `bash tests/test_brand_consistency.sh` to verify it still passes after the rename.
**Warning signs:** `tests/run_all.sh` drops from 11/0 to 10/1 after the rename, with `test_brand_consistency.sh: FAIL voice-cc strings found in non-exempt source files: ./install.sh`.

### Pitfall 10: hyperfine warmup runs may not warm thermal state on Apple Silicon

**What goes wrong:** `--warmup 3` warms filesystem cache + page cache, but Apple Silicon's E-cores vs P-cores scheduling decisions and thermal-throttling kick-in are not "warmable" in 3 runs at sub-second per run. First production run may run on E-cores; second may switch to P-cores when scheduler notices the workload is CPU-bound.
**Why it happens:** macOS's QoS scheduler uses runtime heuristics; warmup doesn't guarantee P-core promotion.
**How to avoid:** Document in BENCHMARK.md that the benchmark is "best-effort" and that 10 runs may show a bimodal distribution (E-core vs P-core scheduling). Recommend running benchmarks on AC power, not battery (battery throttles aggressively). For higher-confidence numbers, increase to `--runs 30` if mean stddev > 20% of mean — but for the Phase-5 go/no-go decision, the existing 10 runs is adequate (the trigger is coarse).
**Warning signs:** stddev > 30% of mean in any of the 3 benchmarks; bimodal `times[]` distribution visible in JSON.

### Pitfall 11: README quickstart curl URL placeholder shipped to public

**What goes wrong:** During Phase 3 development, the README quickstart references `https://example.com/install.sh` or similar placeholder. The placeholder ships to public flip + first user copies it + curl 404s.
**Why it happens:** Common docs-development mistake — placeholder values get left in.
**How to avoid:** Add to the D-06 pre-flip checklist: `grep -E "example\.com|placeholder|TODO|FIXME" README.md` returns empty. Also: smoke-test the curl URL from a fresh terminal session AFTER the public flip but BEFORE announcing it to anyone.
**Warning signs:** First public user of the curl|bash installer reports 404.

### Pitfall 12: SECURITY.md "Distribution model" subsection trips framing-lint

**What goes wrong:** Phase 3 adds a "Distribution model" subsection to SECURITY.md per CONTEXT.md `<code_context>` line 148. The new subsection accidentally uses banned phrases like "this distribution model is compliant with..." or "we guarantee no notarised binary..." → `tests/test_security_md_framing.sh` fails on commit.
**Why it happens:** New prose written under time pressure tends toward marketing language.
**How to avoid:** Phase 3 plan task for the SECURITY.md update MUST run `bash tests/test_security_md_framing.sh` as a check step. Recommended framing: "PurpleVoice is **distributed as source-available code** under MIT license. No notarised installer artefact ships in v1; this is a deliberate trade-off (see [Code Signing & Notarisation](#code-signing--notarisation)). Operators wanting a notarised binary should consult the Phase-3-deferred path in that section."
**Warning signs:** `tests/run_all.sh` drops from 11/0 after a SECURITY.md edit.

## Code Examples

Verified patterns from the sources cited in each block.

### Curl-vs-clone detection (synthesised from oh-my-zsh + Homebrew)

See **Pattern 1** above. Idiom: `[ -f "$0" ] && git -C "$(dirname "$0")" rev-parse --git-dir` returns truthy → clone mode.

Source: [oh-my-zsh tools/install.sh](https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh) (computes ZSH default + checks if dir exists), [Homebrew install.sh `[ -t 0 ]` block](https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh) (TTY for prompting, NOT mode detection), [rustup-init.sh `need_tty` flag](https://sh.rustup.rs/) (TTY for `/dev/tty` redirection).

### MIT LICENSE canonical text (paste verbatim into `LICENSE` at repo root)

Source: [opensource.org/license/mit](https://opensource.org/license/mit). Substitutions: `<YEAR>` → `2026`, `<COPYRIGHT HOLDER>` → `Oliver Allen` (matches the canonical commit author per `git log -1 --format="%an"` = `Oliver Allen`; the per-CLAUDE.md memory email `oliver@olivergallen.com` is for the security-disclosure contact, not the LICENSE name).

```text
MIT License

Copyright (c) 2026 Oliver Allen

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

**On `(c)` vs `©`:** the canonical text from opensource.org uses `(c)` (ASCII; safer for grep / displays without Unicode). Keep it.

**On Syft auto-pickup:** Syft 1.x scans the repo root for a file named exactly `LICENSE` (or `LICENSE.md` / `LICENSE.txt`) and includes the license info under the SPDX `licenseDeclared` field automatically. The current `setup.sh` (post-rename: `install.sh`) Step 8 regenerates SBOM.spdx.json — re-running install.sh after committing the LICENSE will auto-update SBOM. NO manual SBOM edit needed. Verify with: `jq '.creationInfo.licenseListVersion, .packages[0].licenseDeclared' SBOM.spdx.json` after regen.

### gh repo edit public flip (run by Oliver during Wave 3)

Source: [cli.github.com/manual/gh_repo_edit](https://cli.github.com/manual/gh_repo_edit), [cli/cli discussion #9806](https://github.com/cli/cli/discussions/9806).

```bash
# Pre-flip verification (D-06 checklist)
test -f LICENSE
grep -q "raw.githubusercontent.com/OliverGAllen/purplevoice/main/install.sh" README.md
grep -q "bundled-installer" SECURITY.md  # or the agreed phrasing
bash tests/run_all.sh   # 11+ passed
bash tests/security/run_all.sh  # 5 passed

# THE FLIP
gh repo edit OliverGAllen/purplevoice \
  --visibility public \
  --accept-visibility-change-consequences

# Post-flip verification
gh repo view OliverGAllen/purplevoice --json visibility --jq '.visibility'
# Expect: "PUBLIC"

# Anonymous smoke-test (different terminal / private browser)
curl -fsSI https://raw.githubusercontent.com/OliverGAllen/purplevoice/main/install.sh
# Expect: HTTP/2 200, content-type: text/plain
curl -fsSL https://raw.githubusercontent.com/OliverGAllen/purplevoice/main/install.sh | head -5
# Expect: install.sh's first 5 lines (shebang + comments)
```

**Reversibility note:** flipping back to private is straightforward (`gh repo edit ... --visibility private`), but anyone who already cloned has a permanent local copy. There is no "un-publish" for git history once exposed. The repo can be re-privatised; the data cannot. Document this in the Wave-3 plan.

### hyperfine + post-process for BENCHMARK.md generation

Source: [github.com/sharkdp/hyperfine](https://github.com/sharkdp/hyperfine), [hyperfine man page (mankier mirror)](https://manpages.debian.org/testing/hyperfine/hyperfine.1.en.html), [hyperfine issue #22 (percentile feature request)](https://github.com/sharkdp/hyperfine/issues/22), [hyperfine scripts/advanced_statistics.py](https://github.com/sharkdp/hyperfine/blob/master/scripts/advanced_statistics.py).

```bash
#!/usr/bin/env bash
# tests/benchmark/run.sh — Phase 3 BENCHMARK.md regenerator.
# Run by Oliver on his M-series MacBook Pro; output committed to BENCHMARK.md.
set -euo pipefail
cd "$(dirname "$0")/../.."   # repo root

MODEL="$HOME/.local/share/purplevoice/models/ggml-small.en.bin"
WHISPER_BIN="/opt/homebrew/bin/whisper-cli"

mkdir -p tests/benchmark
for len in 2 5 10; do
  echo "## Benchmarking ${len}s.wav"
  hyperfine \
    --warmup 3 \
    --runs 10 \
    --shell none \
    --command-name "whisper-cli small.en — ${len}s.wav" \
    --export-json   "tests/benchmark/results-${len}s.json" \
    --export-markdown "tests/benchmark/results-${len}s.md" \
    -- \
    "$WHISPER_BIN -m $MODEL -f tests/benchmark/${len}s.wav -nt"

  # Compute p50 / p95 from the JSON via jq
  P50=$(jq -r '.results[0].times | sort | .[length/2 | floor]' "tests/benchmark/results-${len}s.json")
  P95=$(jq -r '.results[0].times | sort | .[0.95 * (length - 1) | round]' "tests/benchmark/results-${len}s.json")
  echo "  p50=${P50}s  p95=${P95}s"

  # Phase-5 trigger gate (only the 5s.wav benchmark per D-09)
  if [ "$len" = "5" ]; then
    if (( $(echo "$P50 > 2 || $P95 > 4" | bc -l) )); then
      echo "  TRIGGER: Phase 5 ACTIVE (5s benchmark p50 > 2s OR p95 > 4s)"
    else
      echo "  OK: Phase 5 deferred (5s benchmark within budget)"
    fi
  fi
done
```

**Sample hyperfine JSON output structure** (synthesised from the [hyperfine README](https://github.com/sharkdp/hyperfine) + [Issue #110 schema discussion](https://github.com/sharkdp/hyperfine/issues/110)):

```json
{
  "results": [
    {
      "command": "whisper-cli small.en — 5s.wav",
      "mean": 0.523,
      "stddev": 0.041,
      "median": 0.518,
      "user": 1.872,
      "system": 0.215,
      "min": 0.471,
      "max": 0.612,
      "times": [0.483, 0.512, 0.518, 0.520, 0.523, 0.527, 0.531, 0.541, 0.589, 0.612],
      "exit_codes": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    }
  ]
}
```

The `times` array (size = `--runs`, here 10) is the input to the post-process p95 calculation.

### BENCHMARK.md skeleton

```markdown
# PurpleVoice Performance Benchmark

**Methodology:** transcription-only via [hyperfine](https://github.com/sharkdp/hyperfine) on 3 pre-recorded reference WAVs (synthetic TTS via macOS `say -v Daniel`, 16kHz mono PCM). Each benchmark: 10 runs + 3 warmup runs. Stage-1 (recording, user-bound) and Stage-3 (paste, near-constant) are NOT measured — Stage-2 (whisper-cli transcription) is the dominant + variable component.

**Reproducibility:**
- Whisper model: `ggml-small.en.bin`, SHA256 `c6138d6d58ecc8322097e0f987c32f1be8bb0a18532a3f88f734d1bbf9c41e5d` (488 MB). Download via `install.sh` Step 5; verify SHA via `shasum -a 256`.
- Reference WAVs: committed binary files at `tests/benchmark/{2,5,10}s.wav`. Regeneration command in `tests/benchmark/HOW-TO-REGENERATE.md`.
- Benchmark runner: `tests/benchmark/run.sh`.
- hyperfine version: 1.20.0+ (verified via `hyperfine --version`).

## Latest results

**Environment:** [filled by Oliver post-Wave-3]
- macOS version: ____
- Apple Silicon: M__ ___ (cores: ___ E + ___ P)
- Power state: AC adapter (battery throttles aggressively)
- Date: 2026-__-__

| Utterance length | min | mean | median (p50) | p95 | max | stddev |
|---|---|---|---|---|---|---|
| 2s.wav | __ s | __ s | __ s | __ s | __ s | __ s |
| 5s.wav | __ s | __ s | __ s | __ s | __ s | __ s |
| 10s.wav | __ s | __ s | __ s | __ s | __ s | __ s |

## Phase 5 trigger evaluation

**Trigger rule (Phase 3 CONTEXT D-09):** Phase 5 (warm-process upgrade) becomes active scope IF the 5s.wav benchmark shows `p50 > 2s OR p95 > 4s`.

**Result:** [filled by run.sh / Oliver]
- 5s.wav p50 = __ s
- 5s.wav p95 = __ s
- Phase 5: **DEFERRED** / **ACTIVE** (delete one)

## Raw JSON

Full hyperfine output:
- [tests/benchmark/results-2s.json](tests/benchmark/results-2s.json)
- [tests/benchmark/results-5s.json](tests/benchmark/results-5s.json)
- [tests/benchmark/results-10s.json](tests/benchmark/results-10s.json)

## Re-running benchmarks

```bash
bash tests/benchmark/run.sh
```

The `run.sh` script regenerates the JSON + markdown exports + prints the Phase-5 trigger evaluation. Re-baseline this `BENCHMARK.md` after a meaningful environment change (new macOS version, model file change, hardware change).
```

### SECURITY.md "Distribution model" subsection (framing-lint compatible)

Recommended placement: as a new H3 *inside* `## Code Signing & Notarisation` (line 614 of current SECURITY.md), positioned before `### If PurpleVoice ever ships as a notarised .app (Phase 3 scope)`:

```markdown
### Distribution model (Phase 3, v1)

PurpleVoice is **distributed as source-available code** under the MIT license (see [LICENSE](LICENSE)). The v1 release ships via:

- **Public GitHub repository** at https://github.com/OliverGAllen/purplevoice — every line of bash glue, Lua module, install.sh, uninstall.sh, and configuration is plain text and reviewable.
- **One-line installer** at https://raw.githubusercontent.com/OliverGAllen/purplevoice/main/install.sh — invoked via `curl -fsSL ... | bash`. The installer git-clones the repo into `~/.local/share/purplevoice/src/` and runs the same idempotent `install.sh` a local-clone user runs.
- **No notarised installer artefact** — the architecture (Hammerspoon Spoon + bash glue + brew-installed binaries) does not produce a signable PurpleVoice bundle. The `Hammerspoon.app` users install via `brew install --cask hammerspoon` carries Hammerspoon's own Apple Developer ID notarisation.

This distribution model is a deliberate trade-off: zero opaque-binary surface in exchange for slightly higher install friction (the user manually adds `require("purplevoice")` to `~/.hammerspoon/init.lua`). For audiences whose threat model includes "distrust signed binaries and prefer reviewable source", source-available distribution is the load-bearing posture.

Operators who require a notarised binary distribution should consult the deferred Phase 3 path documented in [If PurpleVoice ever ships as a notarised .app](#if-purplevoice-ever-ships-as-a-notarised-app-phase-3-scope) below.
```

**Framing-lint compatibility check:**
- ✓ No "compliant" without qualifier ("compliant with") — none present.
- ✓ No "certified" without qualifier — none present.
- ✓ No "guarantees" without qualifier — phrase "load-bearing posture" used instead of "guarantee".
- ✓ No `voice-cc` strings — pure PurpleVoice references.
- ✓ Canonical tagline preserved (in TL;DR; this subsection doesn't need to repeat it).

## State of the Art

| Old approach | Current approach (2026) | When changed | Impact |
|---|---|---|---|
| Custom `time` + bash aggregator for micro-benchmarks | `hyperfine` | Stable since 2019; v1.20.0 Nov 2025 | Standard tool; eliminates statistical-naïveté pitfalls. |
| Manual git-clone + `cd` + `./install.sh` | `curl ... | bash` one-liner that auto-detects clone-vs-curl | oh-my-zsh popularised 2014; rustup ratified 2018 | Now the de facto "install" pattern for macOS dev tools. PurpleVoice CONTEXT D-04 follows. |
| GPL-3 / AGPL for "share-alike" tooling | MIT for permissive ecosystem coexistence | MIT became dominant for personal/team tools post-2010 | MIT signals "no transitivity concerns" to institutional reviewers. PurpleVoice D-07 chose MIT explicitly to match Hammerspoon's BSD-3-clause permissiveness. |
| GitHub releases with versioned tarballs | Live `main` install via raw URL | PurpleVoice CONTEXT Deferred Ideas — release tagging is a v1.5+ concern | One less moving part for v1. Risk: a `main` regression breaks new installers — mitigated by D-06 pre-flip checklist + smoke-test discipline. |
| Apple notarisation for ANY macOS-distributed code | Notarisation only for binary `.app` bundles; source-available source is fine without | Apple Notary Service became standard for `.app`/`.pkg` distribution post-Catalina (2019); plain bash + Lua source is exempt | PurpleVoice DST-06 Option B leans on this: stock Hammerspoon is notarised (by Hammerspoon project); PurpleVoice itself is unnotarised text and that's fine. |

**Deprecated / outdated approaches that PurpleVoice rejects:**

- **`bash <(curl ...)` process substitution** — works in bash but inconsistent in zsh; modern macOS defaults to zsh. Use the `curl ... | bash` pipe form. Rejected.
- **Self-extracting installer scripts** (binary tarball at the bottom of a bash script) — overkill for a 470-line bash + 350-line Lua codebase. PurpleVoice ships source. Rejected per D-07.
- **Unattended `brew install --cask hammerspoon` from install.sh under sudo** — Homebrew explicitly refuses to run as root (and warns against it for non-root). install.sh stays user-level; that's correct. No change needed.
- **`apt`/`yum`/`pacman`-style package definition** — out of scope. macOS-only project.

## Open Questions

### 1. Should install.sh's curl|bash bootstrap clone the FULL history or `--depth 1`?

- **What we know:** `--depth 1` halves disk + bandwidth (~50 MB vs ~110 MB for purplevoice's history including `.planning/`). Future `git pull --ff-only` from a shallow clone works for fast-forward updates.
- **What's unclear:** institutional auditors who want to walk `.planning/` deep audit-trail history may be frustrated by needing a manual `git fetch --unshallow`.
- **Recommendation:** Use `--depth 1` for the curl|bash bootstrap (faster install, lower bandwidth). Document the `git fetch --unshallow` command in HOW-TO-REGENERATE.md / README §"Detailed Install" for auditors. The default user-experience case (someone trying PurpleVoice for the first time) wins; the rare auditor case has a documented escape hatch.

### 2. Should the `tests/benchmark/HOW-TO-REGENERATE.md` describe the macOS version dependency in detail or just point at a known-working version?

- **What we know:** macOS major versions can change `say` voice synthesis bytes.
- **What's unclear:** the exact extent of drift — is `say -v Daniel "Hello"` byte-identical between macOS 15.7.5 and 16.0? No public source documents this.
- **Recommendation:** Document "WAVs were generated on macOS Sequoia 15.7.5 with `say -v Daniel`. If you regenerate on a different macOS version and the durations shift more than ±0.5s, please open an issue and re-baseline BENCHMARK.md." The exact-version drift catalogue is not worth pursuing.

### 3. Does the `tests/test_install_sh_detection.sh` unit-test need to mock `$0` or actually invoke install.sh in both modes?

- **What we know:** Unit-testing curl|bash detection is hard because the actual curl pipe needs network.
- **What's unclear:** how much fidelity the unit test needs. Mocking `$0` gives high confidence the function works for both branches; actually running curl|bash from a local tarball-served-via-`python3 -m http.server` gives end-to-end coverage but is fragile.
- **Recommendation:** Mock `$0` in the unit test (functional-level: assert `detect_invocation_mode` returns "clone" when `$0` points into a git checkout, returns "curl" when `$0` is `/dev/stdin` or `bash`). Add a manual walkthrough at `tests/manual/test_curl_bash_install.md` for end-to-end verification — Oliver runs the curl|bash path from his laptop after public flip and signs off live.

### 4. Should `uninstall.sh` also remove `~/.local/share/purplevoice/src/` (the curl|bash clone destination)?

- **What we know:** If a user installed via curl|bash, the clone dir at `~/.local/share/purplevoice/src/` exists. The Pattern 7 uninstall.sh script DOES remove `~/.local/share/purplevoice/` (the parent), which would take the `src/` subdir with it.
- **What's unclear:** but if a user installed via local clone (cloned themselves to `~/dev/purplevoice/`), the uninstall.sh shouldn't touch `~/dev/purplevoice/` — that's their working copy.
- **Recommendation:** uninstall.sh's `rm -rf ~/.local/share/purplevoice/` is correct (it's the XDG-managed share dir; users should not put working copies there). Local-clone users running uninstall.sh keep their working copy at `~/dev/purplevoice/` untouched. Add a one-line comment in uninstall.sh acknowledging this distinction.

### 5. After the public flip, does GitHub auto-render LICENSE under the repo's "License" field in the sidebar?

- **What we know:** GitHub auto-detects LICENSE files at repo root using [github/licensed](https://github.com/github/licensee). MIT is one of the first-tier auto-detected licenses.
- **What's unclear:** whether the auto-detection runs synchronously after a flip-to-public.
- **Recommendation:** Verify post-flip via `gh repo view OliverGAllen/purplevoice --json licenseInfo`. Currently (PRIVATE state) `licenseInfo` is `null`. After flip + LICENSE commit, expect `{"key": "mit", "name": "MIT License", ...}`. If it doesn't auto-detect within ~5 minutes, GitHub support may need to be poked, but this is rare for canonical MIT.

## Environment Availability

| Dependency | Required by | Available | Version | Fallback |
|---|---|---|---|---|
| `bash` | install.sh + uninstall.sh | ✓ | system 5.x (macOS Sequoia) | — |
| `git` | curl|bash bootstrap (clone the repo) | ✓ | 2.50.1 (Apple Git-155) | install.sh prints actionable error if missing: "Run `xcode-select --install`" |
| `curl` | model + Silero downloads + the public install entry-point | ✓ | system | — |
| `gh` (GitHub CLI) | Wave 3 public flip command (Oliver only; not user-runtime) | ✓ | 2.86.0 | Manual web-UI flip via GitHub Settings (slower; less auditable) |
| `say` (macOS TTS) | One-shot reference WAV generation | ✓ | system (Sequoia 15.7.5) | hand-recorded WAVs (rejected per "Don't Hand-Roll") |
| `afconvert` | Reference WAV format conversion (if `say --data-format` insufficient) | ✓ | /usr/bin/afconvert | `sox` already installed by install.sh Step 2 |
| `sox` | Already a project runtime dep | ✓ | 14.4.2 (`/opt/homebrew/bin/sox`) | — |
| `whisper-cli` | hyperfine benchmark target | ✓ | `/opt/homebrew/bin/whisper-cli` | — |
| `hyperfine` | Phase 3 Wave 3 benchmark | ✗ | — | `brew install hyperfine` — Wave 0 task |
| `jq` | hyperfine JSON post-process for p95 | ? (need to verify on fresh machine) | unknown | install.sh / brew (already used by setup.sh Step 8 SBOM post-process) |
| `bc` | Phase-5 trigger arithmetic | ✓ (typically built-in) | system | jq's arithmetic could replace bc; nice-to-have not critical |
| `Syft` | SBOM regeneration after LICENSE add | ✓ (1.43.0+) | — | install.sh handles missing-Syft case (skip + warn) |
| `Hammerspoon.app` | Runtime, not Phase 3 work | ✓ | 1.1.1 | install.sh installs via `brew install --cask hammerspoon` |
| `Karabiner-Elements.app` | Runtime, Phase 4 dep | ✓ | — | install.sh Step 9 enforces presence with actionable error |

**Missing dependencies with no fallback:** none.

**Missing dependencies with fallback:** `hyperfine` — install via `brew install hyperfine` as a Wave 0 task. Add to install.sh Step 2 as a NEW dep ONLY IF Phase 3 wants it auto-installed (recommendation: do NOT add to install.sh — hyperfine is bench-only, not a user runtime dep; add to a separate "developer setup" instruction in BENCHMARK.md or HOW-TO-REGENERATE.md).

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | Bash unit tests via `tests/run_all.sh` (functional suite) + `tests/security/run_all.sh` (security suite). No external test runner; each test is a standalone executable that exits 0 on PASS / non-zero on FAIL. |
| Config file | None (convention-based: any `tests/test_*.sh` is auto-discovered by `run_all.sh`; `tests/security/verify_*.sh` by the security suite). |
| Quick run command | `bash tests/run_all.sh` (current 11/0 baseline; Phase 3 grows to 13/0 with two new tests) |
| Full suite command | `bash tests/run_all.sh && bash tests/security/run_all.sh` (current 11/0 + 5/0; Phase 3 target 13/0 + 5/0) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| **DST-01** | install.sh idempotent installer | unit (regression) | `bash tests/test_brand_consistency.sh` (catches voice-cc drift in renamed install.sh) | ✅ |
| **DST-01** | install.sh re-run produces no clobber + stays GREEN | manual walkthrough | `tests/manual/test_install_idempotent.md` — Oliver runs install.sh twice on a clean machine and signs off | ❌ Wave 0 |
| **DST-02** | install.sh prints `require("purplevoice")` line, never auto-edits init.lua | unit | `bash tests/test_install_sh_no_init_lua_edit.sh` — grep install.sh for `init.lua` writes; expect zero | ❌ Wave 0 (or fold into existing brand-consistency check) |
| **DST-03** | README documents permission grants + recovery | manual | `tests/manual/test_readme_recovery_walkthrough.md` — Oliver follows README recovery steps verbatim and signs off | ❌ Wave 0 |
| **DST-04** | hyperfine benchmark produces p50/p95 + Phase-5 trigger eval | manual + automated | `bash tests/benchmark/run.sh` — Oliver runs once on his hardware; output committed to BENCHMARK.md. Manual sign-off in `tests/manual/test_benchmark_run.md`. | ❌ Wave 3 |
| **DST-05** | Public curl|bash one-liner works end-to-end on a fresh machine | manual (live walkthrough) | `tests/manual/test_curl_bash_install.md` — Oliver runs the one-liner from a fresh terminal AFTER public flip and signs off | ❌ Wave 4 |
| **DST-05** | curl-vs-clone detection function works in both modes | unit | `bash tests/test_install_sh_detection.sh` — sources the detection function, mocks `$0` for both modes, asserts correct branch | ❌ Wave 0 |
| **DST-06** | install.sh implements DST-06 Option B (bundled installer flow) | unit (presence check) | `bash tests/test_install_sh_dst06_option_b.sh` — grep install.sh for the brew-cask-hammerspoon line; assert no `.app` rename / fork logic exists | ❌ Wave 0 (or roll into brand-consistency) |
| Cross-cutting | uninstall.sh idempotent + safe | unit | `bash tests/test_uninstall_dryrun.sh` — runs uninstall.sh in a sandboxed `$HOME` (e.g., temp-dir override via env var `PURPLEVOICE_TEST_HOME`); asserts XDG dirs removed; re-runs and asserts "already removed" path | ❌ Wave 0 |
| Cross-cutting | LICENSE present at repo root, MIT canonical | unit | `bash tests/test_license_present.sh` — grep `LICENSE` for `MIT License` + `Permission is hereby granted` + `Oliver Allen` + `2026` | ❌ Wave 0 |
| Cross-cutting | SECURITY.md framing-lint still GREEN after "Distribution model" subsection | regression | `bash tests/test_security_md_framing.sh` (existing — runs in `tests/run_all.sh`) | ✅ |
| Cross-cutting | Brand consistency: no voice-cc strings in new files | regression | `bash tests/test_brand_consistency.sh` (existing) | ✅ |

### Sampling Rate

- **Per task commit:** `bash tests/run_all.sh` (functional suite — fast, ~5s; runs the brand-consistency + framing lint + the Phase-3 new tests).
- **Per wave merge:** `bash tests/run_all.sh && bash tests/security/run_all.sh` (full suite — security adds ~30s; required for Wave merges that touch SECURITY.md or SBOM).
- **Phase gate:** Full suite green + Oliver signs off the live walkthroughs (test_install_idempotent, test_readme_recovery, test_benchmark_run, test_curl_bash_install).

### Wave 0 Gaps

The Phase 3 plan should treat Wave 0 as the test-scaffold + LICENSE + (optional) sweep-prep wave. Tasks needed before Wave 1 implementation begins:

- [ ] `tests/test_install_sh_detection.sh` — covers DST-05 curl-vs-clone detection unit-level.
- [ ] `tests/test_install_sh_no_init_lua_edit.sh` — covers DST-02 (or fold into brand-consistency).
- [ ] `tests/test_install_sh_dst06_option_b.sh` — covers DST-06 (or fold into brand-consistency / smaller).
- [ ] `tests/test_uninstall_dryrun.sh` — covers uninstall.sh idempotency.
- [ ] `tests/test_license_present.sh` — covers LICENSE presence + canonical MIT text.
- [ ] `tests/manual/test_install_idempotent.md` — manual walkthrough scaffold for DST-01 idempotency.
- [ ] `tests/manual/test_readme_recovery_walkthrough.md` — manual walkthrough scaffold for DST-03.
- [ ] `tests/manual/test_benchmark_run.md` — manual walkthrough scaffold for DST-04 (Wave 3-time activation).
- [ ] `tests/manual/test_curl_bash_install.md` — manual walkthrough scaffold for DST-05 (Wave 4-time activation, post-flip).
- [ ] `tests/benchmark/HOW-TO-REGENERATE.md` — documents the `say -v Daniel ...` reference WAV generation commands + macOS-version caveats.
- [ ] **NO new framework install needed** — bash + grep + jq are already available; hyperfine install is a Wave 3 prep step (`brew install hyperfine`), not a Wave 0 test framework dep.

**Functional + security suite expected pass counts after Phase 3:**

- Functional: 11 (current) + 5 new unit tests = **16/0** (or fewer if some are folded into brand-consistency — minimum 13/0).
- Security: **5/0** (unchanged — Phase 3 doesn't add security-tier tests).

## Sources

### Primary (HIGH confidence)

- [oh-my-zsh tools/install.sh (canonical reference)](https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh) — established curl|bash installer; ZSH default + git-clone-aborts-if-exists pattern.
- [Homebrew install.sh](https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh) — `[ -t 0 ]` for non-interactive prompting (NOT for mode detection); `command -v git` + `find_tool` patterns.
- [rustup-init.sh (sh.rustup.rs)](https://sh.rustup.rs/) — `need_tty` flag + `/dev/tty` redirect idiom; downloads-then-execs binary pattern.
- [hyperfine GitHub README](https://github.com/sharkdp/hyperfine) — flag list, default behaviour, "at least 10 runs and 3 seconds" wording.
- [hyperfine man page (Debian mirror)](https://manpages.debian.org/testing/hyperfine/hyperfine.1.en.html) — full flag descriptions, defaults for --warmup / --runs.
- [hyperfine scripts/advanced_statistics.py](https://github.com/sharkdp/hyperfine/blob/master/scripts/advanced_statistics.py) — upstream-blessed p95 calculation from hyperfine JSON `times[]` array.
- [hyperfine issue #22 (percentile feature request)](https://github.com/sharkdp/hyperfine/issues/22) — confirms percentiles are NOT in native hyperfine output.
- [hyperfine issue #110 (JSON schema discussion)](https://github.com/sharkdp/hyperfine/issues/110) — the JSON output schema fields.
- [hyperfine via Homebrew formula](https://formulae.brew.sh/formula/hyperfine) — verified version 1.20.0, `brew install hyperfine`.
- [whisper.cpp examples/cli/cli.cpp](https://github.com/ggml-org/whisper.cpp/blob/master/examples/cli/cli.cpp) — verified `-nt` / `--no-timestamps` flag semantics (line 544).
- [opensource.org MIT License canonical text](https://opensource.org/license/mit) — the verbatim license text to paste into `LICENSE`.
- [GitHub CLI manual: gh repo edit](https://cli.github.com/manual/gh_repo_edit) — `--visibility` + `--accept-visibility-change-consequences` syntax.
- [cli/cli discussion #9806](https://github.com/cli/cli/discussions/9806) — confirms the `--accept-visibility-change-consequences` requirement in non-interactive mode.
- [ss64.com macOS `say` reference](https://ss64.com/mac/say.html) — `--data-format=LEI16@16000` for direct 16kHz mono WAV output.
- Verified live (2026-04-30 via `gh repo view OliverGAllen/purplevoice --json owner,visibility,licenseInfo`): repo owner `OliverGAllen`, visibility `PRIVATE`, licenseInfo `null`.
- Verified live (2026-04-30 via `bash tests/run_all.sh && bash tests/security/run_all.sh`): functional 11/0, security 5/0.
- Verified live (2026-04-30 via `git -C ... log -1 --format="%an"`): canonical commit author `Oliver Allen`.
- Verified live (2026-04-30): `hyperfine` NOT installed; `say`, `afconvert`, `sox`, `whisper-cli`, `gh`, `git` ALL installed.

### Secondary (MEDIUM confidence)

- [Karabiner-Elements docs (linked from CONTEXT.md canonical refs)](https://karabiner-elements.pqrs.org/) — Karabiner JSON rule schema; Phase 4 carryover.
- [imzye.com hyperfine usage tutorial](https://imzye.com/Tips/how-to-use-hyperfine/) — practical examples (didn't surface JSON schema verbatim but confirmed the flag set).
- [Tecmint hyperfine tutorial](https://www.tecmint.com/hyperfine-find-command-execution-time-linux/) — secondary corroboration.
- [GitHub licensee project (auto-detection)](https://github.com/github/licensee) — auto-detection of LICENSE files for the GitHub sidebar; first-tier MIT detection.

### Tertiary (LOW confidence — flagged for validation)

- The exact `say -v Daniel` voice byte-output stability across macOS major versions is not documented anywhere authoritative. The "10s of WAV ≤ ±0.5s drift across macOS versions" estimate is empirical / heuristic — verify on the Phase 3 actual benchmark machine.
- The `--depth 1` shallow clone size estimate (~50 MB vs ~110 MB full) is rough — actual size depends on `.planning/` history bloat and committed binary assets (icon-256.png, the Phase 3 reference WAVs).

## Metadata

**Confidence breakdown:**

- **Standard stack:** HIGH — hyperfine 1.20.0 + macOS built-ins + gh CLI 2.86.0 all verified live; no version uncertainty.
- **Architecture (curl-vs-clone, hyperfine flags, gh flip):** HIGH — synthesised from authoritative installers (oh-my-zsh, Homebrew, rustup) and verified upstream tool docs; the `--accept-visibility-change-consequences` requirement is a live-discovered detail not in CONTEXT.md.
- **Pitfalls:** HIGH on Pitfalls 1, 2, 5, 6, 8, 9, 11, 12 (verifiable directly against tools or current repo state); MEDIUM on Pitfalls 3, 4, 7, 10 (depend on macOS version drift, runtime env state).
- **Reference WAV reproducibility:** MEDIUM — Apple does not publish TTS-engine bytecode-stability guarantees across macOS versions; recommendation is to commit the WAVs as canonical and document drift mitigation.
- **Critical correction (URL casing):** HIGH — verified live with `gh repo view`; the planner MUST sweep this before any documentation lands.

**Research date:** 2026-04-30
**Valid until:** 2026-05-30 (30 days for stable installer patterns + hyperfine semantics; re-verify hyperfine version + gh CLI flag if research stale).

## RESEARCH COMPLETE

**Phase:** 3 — Distribution & Benchmarking + Public Install
**Confidence:** HIGH (with one critical correction surfaced)

### Key Findings

1. **GitHub owner casing mismatch:** CONTEXT.md uses `oliverallen/purplevoice`; verified live remote is `OliverGAllen/purplevoice`. The planner MUST sweep this in install.sh, README, SECURITY.md "Distribution model" subsection, and the gh flip command. This is a single-commit fix but skipping it produces a 404 on the public curl URL.
2. **`gh repo edit --visibility public` requires `--accept-visibility-change-consequences` in non-interactive mode** — must be in the Wave 3 flip command verbatim or the flip silently no-ops.
3. **hyperfine has no native p95** — vendor a small `jq`-based post-process script (`tests/benchmark/quantiles.sh`) to compute p50 + p95 from the `times[]` array. Phase-5 trigger evaluation depends on this.
4. **curl-vs-clone detection: use `[ -f "$0" ]` + `git rev-parse --git-dir`, NOT `[ -t 0 ]`.** The two valid PurpleVoice install paths (curl|bash AND local clone) need DIFFERENT behaviour; Homebrew's TTY-check pattern is for non-interactive *prompting* and isn't applicable.
5. **Reference WAV generation: macOS `say -v Daniel --data-format=LEI16@16000`** produces 16kHz mono PCM directly (no `afconvert` round-trip needed); commit binary WAVs to repo + document regeneration with macOS-version drift caveat.
6. **Phase 4 minimal-automation precedent (D-07) means uninstall.sh does NOT touch Karabiner config** + install.sh does NOT auto-copy Karabiner JSONs. Both surfaces stay user-driven; install.sh banner pointer is sufficient.
7. **SBOM hardcoded URL in setup.sh (line 363) currently uses wrong casing too** (`oliverallen/PurpleVoice`) — needs correction to `OliverGAllen/purplevoice` before public flip OR Pitfall 8 ships a broken `documentNamespace`.
8. **brand-consistency lint exemption (`tests/test_brand_consistency.sh` line 31) hardcodes `setup.sh`** — needs sweep to `install.sh` simultaneously with the rename.

### File Created

`/Users/oliverallen/Temp video/voice-cc/.planning/phases/03-distribution-public-install/03-RESEARCH.md`

### Confidence Assessment

| Area | Level | Reason |
|---|---|---|
| Standard Stack | HIGH | All tools verified live (hyperfine via brew formula; gh CLI installed; macOS built-ins). |
| Architecture (curl-vs-clone, banners, hyperfine flags, gh flip) | HIGH | Synthesised from oh-my-zsh + Homebrew + rustup + hyperfine + gh CLI authoritative docs; cross-verified with man pages + GitHub issues. |
| Pitfalls | HIGH on most; MEDIUM on macOS-version-drift items (TTS reproducibility, scheduler thermal-throttling). |
| Reference WAV reproducibility | MEDIUM | Apple TTS byte-stability across macOS versions undocumented; mitigation = commit canonical WAVs + document drift. |
| Repo public flip mechanics | HIGH | `gh repo edit --visibility` confirmed via CLI manual + community discussion; the `--accept-...` flag is a live-discovered necessity. |

### Open Questions

See `## Open Questions` above for the 5 items. None of them block planning; each has a recommended default (planner can adopt verbatim or refine).

### Ready for Planning

Research complete. The planner can now create PLAN.md files. The single MUST-DO before Wave 0 plans land is the URL-casing sweep (`oliverallen/purplevoice` → `OliverGAllen/purplevoice`) in CONTEXT.md, install.sh embedded URL, and the SBOM regeneration script.
