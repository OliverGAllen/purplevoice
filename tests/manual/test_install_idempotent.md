# Manual walkthrough: install.sh idempotency on Oliver's machine (DST-01)

**Status:** signed off 2026-05-01 by Oliver (criterion 8 DEFERRED — structural)
**Created:** 2026-05-01 (Plan 03-00)
**Sign-off path:** Plan 03-01 (autonomous: false; checkpoint after install.sh rename + Option B verification lands)
**Phase:** 3 — Distribution & Public Install
**Requirement:** DST-01 (single idempotent install.sh; safe to re-run; never clobbers user-edited config)

## Why this is manual

`tests/run_all.sh` covers static structure (rename, no init.lua edit, Option B). The only thing that cannot be unit-tested is the real-machine state: existing `~/.hammerspoon/init.lua` with the user's `require("purplevoice")` line, the user-edited `~/.config/purplevoice/vocab.txt`, the existing brew installations of Hammerspoon / sox / whisper-cpp / Karabiner-Elements, and the actual SBOM regen idempotency on this exact machine. Only Oliver running `install.sh` twice on his real machine validates DST-01 end-to-end.

## Prerequisites

- [ ] Plan 03-01 complete (install.sh exists at repo root; setup.sh removed; tests/test_brand_consistency.sh exemption updated)
- [ ] `bash tests/run_all.sh` reports ≥13 PASS / 0 FAIL on this branch
- [ ] Pre-existing user state to preserve: `~/.config/purplevoice/vocab.txt` exists with at least one user-added line; `~/.hammerspoon/init.lua` contains `require("purplevoice")`

## Steps

### Run 1 — first invocation
1. From repo root: `bash install.sh 2>&1 | tee /tmp/p3-install-run1.log`
2. **PASS criterion (Run 1):** Exit code 0; banner says "PurpleVoice installer (local clone at <REPO_ROOT>)"; SBOM regen line printed (`OK: SBOM regenerated`).

### Run 2 — second invocation (idempotency check)
3. Without changing anything: `bash install.sh 2>&1 | tee /tmp/p3-install-run2.log`
4. **PASS criterion (Run 2):** Exit code 0; banner says same as Run 1; "already" / "skipping" lines for each idempotent step (Hammerspoon, sox, whisper-cpp, model file, Silero, vocab.txt).

### No-clobber check
5. `diff ~/.config/purplevoice/vocab.txt /tmp/vocab-pre-install.txt` (where `vocab-pre-install.txt` is a snapshot taken before Run 1).
6. **PASS criterion:** zero diff — Run 1 + Run 2 left the user's edited vocab.txt untouched.
7. `git -C "$REPO_ROOT" diff --name-only SBOM.spdx.json` after both runs.
8. **PASS criterion:** zero diff (SBOM.spdx.json deterministicise — Phase 2.7 D-12 idempotency).

## Sign-off

Oliver to record below verbatim once all PASS criteria are met:

```
DST-01 install.sh idempotency walkthrough — signed off 2026-05-01 by Oliver
- Run 1 exit 0, banner correct: PASS (banner: "PurpleVoice installer (local clone at <REPO_ROOT>)")
- Run 2 exit 0, "already" lines printed: PASS (Hammerspoon already present, skipping; whisper-cpp already installed, skipping; Model present, checksum OK, skipping; Silero VAD weights present, skipping; vocab.txt already exists, preserving user edits)
- vocab.txt unchanged across both runs: PASS (zero diff between ~/.config/purplevoice/vocab.txt and /tmp/vocab-pre-install.txt)
- SBOM.spdx.json zero git diff after both runs: DEFERRED — STRUCTURAL LIMITATION (see "Criterion 8 deviation" below)
- Run 1 vs Run 2 SBOM byte-identity: PASS (both logs md5 a48aae374ddb2ff908f6eade99282be8; both regenerated SBOM at same commit b52606b — proves idempotency intent)
```

### Criterion 8 deviation (DST-04 SBOM determinism — DEFERRED)

`install.sh:472-478` (`deterministicise_sbom()`) derives `documentNamespace` from `git rev-parse HEAD`. Committing the regenerated SBOM moves HEAD by one commit, which makes the just-committed SBOM immediately 1-commit stale relative to its own self-reference. Verified empirically:

1. Regen at HEAD `b52606b` → SBOM file references `b52606b` (matches HEAD)
2. Commit SBOM → HEAD becomes `f8cebb3`; SBOM-in-HEAD still references `b52606b` (now stale)
3. Re-run install.sh → regen at HEAD `f8cebb3` → working-tree SBOM references `f8cebb3` → `git diff` shows documentNamespace + versionInfo updated by 1 commit

There is no commit chain that satisfies criterion 8 with current install.sh. The criterion is mathematically unsatisfiable due to the self-reference. Phase 2.7 had the same latent issue, hidden because no one re-ran install.sh after the SBOM commit during 2.7's walkthrough.

**The intent of criterion 8 is upheld** — running install.sh twice on the same HEAD is provably a no-op (Run 1 / Run 2 byte-identity verified above). The literal `git diff` check is over-strict for the underlying invariant.

**Follow-on (backlog item):** rewrite `install.sh:472-478` to derive `documentNamespace` from `git rev-list -1 HEAD -- ':!SBOM.spdx.json'` (last non-SBOM commit) or from a static milestone tag, so post-commit re-runs of install.sh produce zero diff. Defer to Phase 5 / v1.1 — does not block v1 ship.

## Failure modes (what to do if a criterion FAILs)

- Run 1 non-zero exit → file an issue with the failing step number; revert install.sh changes via `git revert` and replan.
- Run 2 prints "Installing X" instead of "X already installed" → idempotency regression; locate the missing presence-check guard.
- vocab.txt diff non-empty → Step 6 (`vocab.txt.default` seed) is clobbering instead of no-clobbering; fix the `[ ! -f "$VOCAB_DEST" ]` guard.
- SBOM.spdx.json git diff → `deterministicise_sbom()` produced volatile output; check `creationInfo.created` constant + `documentNamespace` derivation in install.sh Step 8.
