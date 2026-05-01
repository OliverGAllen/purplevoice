---
status: partial
phase: 04-quality-of-life-v1-x
source: [04-VERIFICATION.md, 04-02-karabiner-docs-PLAN.md CHECKPOINT-3]
started: 2026-05-01
updated: 2026-05-01
---

## Current Test

[awaiting human testing — deferred from Phase 4 execution per Oliver's mid-flow risk-aversion]

## Tests

### 1. setup.sh refuses install completion when Karabiner-Elements absent (test_setup_karabiner_missing.md)

expected: `bash setup.sh` after `sudo mv /Applications/Karabiner-Elements.app /tmp/Karabiner-Elements.app.parked` prints multi-line actionable error to stderr (5-step install procedure, references to BOTH JSON rule files, air-gap note) and exits with EXIT=1. Restore via `sudo mv /tmp/Karabiner-Elements.app.parked /Applications/Karabiner-Elements.app` returns to baseline (subsequent `bash setup.sh` exits 0).

result: [pending]

walkthrough_file: tests/manual/test_setup_karabiner_missing.md

substitute_coverage: tests/test_karabiner_check.sh checks 4-5 confirm setup.sh contains `[ -d /Applications/Karabiner-Elements.app ]` detection + actionable-error text + exit-1 guard. End-to-end runtime verification deferred — surface here until signed off.

deferral_rationale: Oliver opted not to run the destructive sudo-mv walkthrough mid-Phase-4-execution to avoid losing F18+F19 hotkeys if anything went wrong with the restore. Should be run at a deliberate safe break.

## Summary

total: 1
passed: 0
issues: 0
pending: 1
skipped: 0
blocked: 0

## Gaps
