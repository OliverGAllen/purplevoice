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

### 2. Run Plan 03-03 Task 3-5 hyperfine benchmark walkthrough on Oliver's M2 Max

**Origin:** Phase 3 / Plan 03-03 Task 3-5 DEFERRED 2026-05-04 by Oliver (no time pressure; harness + reference WAVs + BENCHMARK.md template all committed; benchmark execution pending Oliver's hardware time).

**Description:** Plan 03-03 Wave 3 deliverables (Tasks 3-1..3-4) are complete and committed: 3 reference WAVs, hyperfine `run.sh` harness, jq-based `quantiles.sh`, BENCHMARK.md template with the Phase 5 trigger rule (`p50 > 2s OR p95 > 4s on 5s.wav` per CONTEXT D-09). Task 3-5 (the live benchmark on Oliver's hardware) was deferred per Oliver's explicit request during Phase 3 execution. Without these numbers, DST-04 stays `[ ]` Pending and the Phase 5 verdict stays "Conditional" in ROADMAP.md.

**Why this is a backlog item, not a deviation:**

- The harness was never broken or wrong. It's ready to run.
- The benchmark is a one-command operation (`bash tests/benchmark/run.sh`) once `hyperfine` is installed.
- The deferral is a scheduling preference, not a technical blocker.

**Resume recipe (verbatim):**

```bash
brew install hyperfine            # one-time prerequisite
brew info hyperfine | head -3     # confirm v1.20.0+
sw_vers -productVersion           # capture for BENCHMARK.md Environment block
sysctl -n machdep.cpu.brand_string  # capture for BENCHMARK.md Environment block
# (laptop on AC power per RESEARCH §Pitfall 10)
bash tests/benchmark/run.sh 2>&1 | tee /tmp/p3-benchmark.log
```

Then populate BENCHMARK.md `## Latest results` table + Environment block + Phase 5 verdict; populate README.md `## Performance` section placeholder rows; sign off `tests/manual/test_benchmark_run.md`; commit; flip REQUIREMENTS.md DST-04 [ ] → [x] in v1 subsection AND traceability table; update STATE.md + ROADMAP.md plan progress; flip Plan 03-03 SUMMARY status `walkthrough-deferred` → `complete`.

**Phase 5 verdict implications:**

- If 5s.wav `p50 ≤ 2s AND p95 ≤ 4s` → Phase 5 stays DEFERRED (ROADMAP "Conditional" → "Deferred"); v1.1 ships without the warm-process upgrade.
- Otherwise → Phase 5 ACTIVE (ROADMAP "Conditional" → "Planning v1.1"); next milestone cycle picks up the warm-process work.

**Priority:** v1 closure blocker for the formal 100% coverage signal, but not a ship-stopper — Plan 03-04 (public flip + DST-05) is technically unblocked from a code-deliverable standpoint and can run in parallel with Oliver scheduling the benchmark.

**Status:** Open

**Related:** Plan 03-03 partial SUMMARY (`status: walkthrough-deferred`), `tests/manual/test_benchmark_run.md` (DEFERRED sign-off block), and the existing pre-walkthrough infrastructure are all sized for the resume path. Same precedent as Phase 4 CHECKPOINT-3 deferral (sudo-mv) — destructive/time-cost walkthroughs that are DEFERRED with documented reason are a recognised GSD pattern, surfaced via `/gsd:audit-uat`.

---

## Closed

*(none yet)*
