# Backlog

Items surfaced during execution that are out of scope for the current phase but should not be lost. Each item records: **origin** (which plan / walkthrough / deviation surfaced it), **description**, **proposed approach**, **priority / target phase**, and **status**.

---

## Open

### 1. Fix install.sh `deterministicise_sbom()` documentNamespace circular reference

**Origin:** Phase 3 / Plan 03-01 walkthrough deviation D-02 (filed 2026-05-01; signed off in `tests/manual/test_install_idempotent.md` commit 191e4af; documented in 03-01-SUMMARY.md).

**Description:** `install.sh:472-478` (`deterministicise_sbom()`) derives the SBOM's SPDX `documentNamespace` from `git rev-parse HEAD`. This creates a circular self-reference:

1. Regen at HEAD `b52606b` → SBOM file references `b52606b` (matches HEAD).
2. Commit SBOM → HEAD becomes `f8cebb3`; the just-committed SBOM still references `b52606b` (now stale by 1 commit).
3. Re-run install.sh → regen at HEAD `f8cebb3` → working-tree SBOM references `f8cebb3` → `git diff` shows `documentNamespace` + `versionInfo` updated by 1 commit.

There is no commit chain that satisfies the "running install.sh post-SBOM-commit produces zero `git diff`" invariant under the current derivation logic. Phase 2.7 had the same latent issue, hidden because no one re-ran setup.sh after the SBOM commit during 2.7's walkthrough. Plan 03-01 surfaced it because the rename + D-13 sweep forced an SBOM regen, which in turn forced a re-run, which exposed the self-reference.

**Why intent is upheld today:** running install.sh twice on the same HEAD is provably a no-op — Run 1 / Run 2 logs both produce md5 `a48aae374ddb2ff908f6eade99282be8`; both regenerate SBOM at the same commit. DST-01 idempotency contract holds. The validation criterion (`git diff` zero output post-commit) is over-strict for the underlying invariant — but it would still be nice to satisfy it cleanly so future plans don't keep rediscovering this trap.

**Proposed approach:**

- **Option 1 (preferred):** Rewrite `documentNamespace` to derive from `git rev-list -1 HEAD -- ':!SBOM.spdx.json'` — the most recent commit that touched any file other than `SBOM.spdx.json`. This makes the namespace stable across SBOM-only commits.
- **Option 2:** Use a static milestone tag (e.g., `v1.0`) as the namespace anchor. Trades commit-level precision for stability.
- **Option 3:** Strip `documentNamespace` and `versionInfo` from the SBOM via `jq` post-process so the on-disk SBOM is content-only (auditor regenerates HEAD-tagged SBOM on demand). Loses provenance for casual auditors.

**Recommendation:** Option 1. Preserves provenance, makes invariant naturally hold, minimal code change (~3 lines in `deterministicise_sbom()`).

**Priority:** Phase 5 / v1.1. Does NOT block v1 ship — DST-01 walkthrough was signed off accepting the structural deviation; criterion 8 is documented as DEFERRED-structural inline in `tests/manual/test_install_idempotent.md`.

**Status:** Open

**Related:** SBOM regeneration is treated as a derived artifact synchronised by install.sh. When plans change install.sh's annotator/namespace logic, also regenerate the on-disk SBOM in the same commit (this lesson surfaced as Plan 03-01 deviation D-01; bake into future plan templates that touch install.sh's SBOM logic).

---

## Closed

*(none yet)*
