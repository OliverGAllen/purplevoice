# PurpleVoice Security Posture

> Local voice dictation. Nothing leaves your Mac.

**Status: SKELETON (Phase 2.7 in progress).** This file is being authored across Phase 2.7 plans 02.7-01..02.7-04. Sections without content are placeholders.

**Audience:** Technical IT auditors at government / defence / healthcare / legal / finance / journalism / air-gapped operator organisations evaluating PurpleVoice. (D-13)

**Frameworks covered (D-16):** NIST SP 800-53 Rev 5 (per-control depth) + FIPS 140-3 + FedRAMP-tailored + Common Criteria + HIPAA Security Rule §164.312 + SOC 2 Type II TSC + ISO/IEC 27001:2022 Annex A (six framed at "compatible with" depth).

**Framing constraint (D-17):** This document uses "compatible with" / "supports" / "consistent with applicable obligations for in-scope code" framing. PurpleVoice is NOT audited or accredited against any framework. Over-claims would damage the auditable trust narrative this document exists to establish.

***

## TL;DR

<!-- TODO: Plan 02.7-04 fills this section (1-page summary for non-technical readers per D-13 / Pitfall 10). -->

## Audience Entry-Points

<!-- TODO: Plan 02.7-04 fills this section (table of ToC links per audience: journalist / federal IT auditor / EU institutional buyer / procurement officer per Pitfall 10). -->

## Scope

<!-- TODO: Plan 02.7-01 fills this section (what PurpleVoice is/isn't; assets; trust boundaries). -->

## Threat Model

<!-- TODO: Plan 02.7-01 fills this section (STRIDE 6×N matrix + LINDDUN 7×N matrix per RESEARCH Priority 1; out-of-scope rationale). -->

## Egress Verification

<!-- TODO: Plan 02.7-02 fills this section (3-layer evidence chain: lsof + nettop + pf+tcpdump; Pitfall 1 caveat for macOS Sequoia 15.7.5; cross-ref tests/security/verify_egress.sh). -->

## Software Bill of Materials (SBOM)

<!-- TODO: Plan 02.7-02 fills this section (SPDX 2.3 SBOM.spdx.json; direct + transitive + system context per D-11; cross-ref tests/security/verify_sbom.sh). -->

## Air-Gapped Installation

<!-- TODO: Plan 02.7-02 fills setup procedure; Plan 02.7-04 cross-references README. PURPLEVOICE_OFFLINE=1 mode per D-08; Pitfall 8 brew limitation; sideload paths. -->

## NIST SP 800-53 Rev 5 / Low-baseline Mapping

<!-- TODO: Plan 02.7-03a fills this section (per-control table for AC, AU, IA, SC, SI, PT + LIMITED families; Met/Partial/Not Pursued/N/A vocabulary per Pitfall 15; Rev 5 IDs only per Pitfall 13). -->

## FIPS 140-3

<!-- TODO: Plan 02.7-03b fills this section (framed; "compatible with FIPS-validated cryptographic modules" framing). -->

## FedRAMP-tailored

<!-- TODO: Plan 02.7-03b fills this section (framed; "achievable IF a sponsoring agency pursues authorisation; not unilaterally pursuable" framing). -->

## Common Criteria

<!-- TODO: Plan 02.7-03b fills this section (framed; "out of scope for v1; ST-based future evaluation simplification" framing). -->

## HIPAA Security Rule §164.312

<!-- TODO: Plan 02.7-03b fills this section (framed; per-clause check-list 164.312(a)(1)/(b)/(c)(1)/(d)/(e)(1) with Met/N/A/Not Pursued; Pitfall 11 "issued to organisations" disclaimer first). -->

## SOC 2 Type II Trust Services Criteria

<!-- TODO: Plan 02.7-03b fills this section (framed; CC6.x / C1.x / P1-P8 partial; Pitfall 11 disclaimer first). -->

## ISO/IEC 27001:2022 Annex A

<!-- TODO: Plan 02.7-03b fills this section (framed; A.5/A.8/A.13/A.14 technical-controls subset; Pitfall 11 "issued to organisations" disclaimer first). -->

## Code Signing & Notarisation

<!-- TODO: Plan 02.7-04 fills this section (Phase 3 deferral; $99/yr Apple Developer Program; entitlements list; current "no signable artifact" framing). -->

## Reproducible Build

<!-- TODO: Plan 02.7-04 fills this section (best-effort; Pitfall 14 toolchain-version-sensitive caveat; what we DO have: SHA256-pinned model + git-tracked source + brew bottle SHA256). -->

## Vulnerability Disclosure

<!-- TODO: Plan 02.7-04 fills this section (email contact stub: oliver@olivergallen.com; no CVE authority / bounty programme; community-evolution note). -->

## How to Verify These Claims

<!-- TODO: Plan 02.7-04 fills this section (instructions: bash tests/run_all.sh && bash tests/security/run_all.sh; sudo requirement for verify_egress.sh; release-gate cadence per D-03). -->

***

*Phase 2.7 in progress. Last updated: <!-- updated by each plan -->.*
