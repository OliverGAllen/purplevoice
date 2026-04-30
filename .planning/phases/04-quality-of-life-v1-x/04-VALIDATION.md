---
phase: 04
slug: quality-of-life-v1-x
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-30
---

# Phase 04 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash test scripts (no test runner — each `tests/test_*.sh` is standalone, returns 0/1) |
| **Config file** | None — `tests/run_all.sh` iterates `tests/test_*.sh` alphabetically |
| **Quick run command** | `bash tests/run_all.sh` |
| **Full suite command** | `bash tests/run_all.sh && bash tests/security/run_all.sh` |
| **Estimated runtime** | ~5 seconds quick / ~35 seconds full |

Baseline: 10/0 functional + 5/0 security. Phase 4 grows to 11/0 + 5/0 (adds `tests/test_karabiner_check.sh`).

---

## Sampling Rate

- **After every task commit:** Run `bash tests/run_all.sh` (~5 seconds; all 11 tests must be green)
- **After every plan wave:** Run `bash tests/run_all.sh && bash tests/security/run_all.sh` (full suite)
- **Before `/gsd:verify-work`:** Full suite green + 3 manual walkthroughs signed off live (re-paste, F19, setup-karabiner-missing)
- **Max feedback latency:** ~5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 04-00-01 | 00 | 0 | QOL-NEW-01 | unit (string) | `bash tests/test_karabiner_check.sh` (checks 1-8) | ❌ W0 creates | ⬜ pending |
| 04-00-02 | 00 | 0 | QOL-01 | manual scaffold | `tests/manual/test_repaste_walkthrough.md` exists | ❌ W0 creates | ⬜ pending |
| 04-00-03 | 00 | 0 | QOL-NEW-01 | manual scaffold | `tests/manual/test_f19_walkthrough.md` exists | ❌ W0 creates | ⬜ pending |
| 04-00-04 | 00 | 0 | QOL-NEW-01 | manual scaffold | `tests/manual/test_setup_karabiner_missing.md` exists | ❌ W0 creates | ⬜ pending |
| 04-00-05 | 00 | 0 | QOL-01, QOL-NEW-01 | doc (req stubs) | `grep -q 'QOL-NEW-01' .planning/REQUIREMENTS.md` | ❌ W0 creates | ⬜ pending |
| 04-01-01 | 01 | 1 | QOL-NEW-01 | unit (string) | `bash tests/test_karabiner_check.sh` (check 6: F19 binding) | ✅ W0 | ⬜ pending |
| 04-01-02 | 01 | 1 | QOL-NEW-01 | unit (negative) | `bash tests/test_karabiner_check.sh` (check 8: cmd+shift+e absent) | ✅ W0 | ⬜ pending |
| 04-01-03 | 01 | 1 | QOL-01 | unit (string) | `bash tests/test_karabiner_check.sh` (check 7: cmd+shift+v binding) | ✅ W0 | ⬜ pending |
| 04-01-04 | 01 | 1 | QOL-01 | unit (string) | `grep -E 'lastTranscript = ' purplevoice-lua/init.lua` | ✅ W0 | ⬜ pending |
| 04-01-05 | 01 | 1 | QOL-01 | manual walkthrough | `tests/manual/test_repaste_walkthrough.md` (live sign-off) | ✅ W0 | ⬜ pending |
| 04-02-01 | 02 | 2 | QOL-NEW-01 | unit (JSON) | `bash tests/test_karabiner_check.sh` (checks 1-3: JSON valid + structure) | ✅ W0 | ⬜ pending |
| 04-02-02 | 02 | 2 | QOL-NEW-01 | unit (string) | `bash tests/test_karabiner_check.sh` (checks 4-5: setup.sh Step 9 wiring) | ✅ W0 | ⬜ pending |
| 04-02-03 | 02 | 2 | QOL-NEW-01 | manual walkthrough | `tests/manual/test_f19_walkthrough.md` (live sign-off w/ Karabiner installed) | ✅ W0 | ⬜ pending |
| 04-02-04 | 02 | 2 | QOL-NEW-01 | manual walkthrough | `tests/manual/test_setup_karabiner_missing.md` (live sign-off, negative branch) | ✅ W0 | ⬜ pending |
| 04-02-05 | 02 | 2 | (invariant) | unit (existing) | `bash tests/test_brand_consistency.sh` | ✅ existing | ⬜ pending |
| 04-02-06 | 02 | 2 | (invariant) | unit (existing) | `bash tests/test_security_md_framing.sh` | ✅ existing | ⬜ pending |
| 04-02-07 | 02 | 2 | QOL-01, QOL-NEW-01 | doc (req closure) | `grep -E '^\| QOL-NEW-01.*\[x\].*Complete' .planning/REQUIREMENTS.md` | ✅ existing | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/test_karabiner_check.sh` — 8 string-level assertions (JSON validity + structure + setup.sh wiring + init.lua F19 binding present + cmd+shift+v binding present + cmd+shift+e binding absent). RED at Wave 0 commit; turns GREEN as plans 04-01 and 04-02 land.
- [ ] `tests/manual/test_repaste_walkthrough.md` — manual walkthrough scaffold for QOL-01 (record → paste → cmd+shift+v re-paste → verify same transcript appears in focused window; nil-state shows brief alert).
- [ ] `tests/manual/test_f19_walkthrough.md` — manual walkthrough scaffold for QOL-NEW-01 (Karabiner rule imported, fn-hold triggers PurpleVoice, fn-tap preserves Globe popup, cmd+shift+e no longer triggers).
- [ ] `tests/manual/test_setup_karabiner_missing.md` — manual walkthrough scaffold for setup.sh Step 9 actionable-error branch (sudo-move Karabiner.app aside, run setup.sh, observe non-zero exit + actionable instructions, restore).
- [ ] `.planning/REQUIREMENTS.md` — QOL-01 promoted from v2 stub to v1 with concrete language (re-paste hotkey + in-memory cache + nil-state behaviour); QOL-NEW-01 row added (F19 alt hotkey + Karabiner dependency); both `[ ]` Pending until Phase 4 closes.

*Framework install:* None — bash test runner already in use; jq already installed and required by setup.sh Step 8.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| F19 hotkey actually triggers PurpleVoice when held (after Karabiner rule imported + driver granted) | QOL-NEW-01 | Requires Karabiner-Elements installed + driver/extension grant + rule imported via Karabiner UI; impossible to mock at the OS HID layer | `tests/manual/test_f19_walkthrough.md` — fresh Hammerspoon reload → hold fn for >200ms → verify recording starts → release → verify recording stops + transcript pastes |
| Quick fn-tap (<200ms) does NOT trigger PurpleVoice; preserves macOS native fn behaviour (Globe popup, dictation, function-key row) | QOL-NEW-01 | Requires the live Karabiner `to_if_alone`/`to_if_held_down` split timing on Oliver's hardware | Included in `test_f19_walkthrough.md` — tap fn briefly → Globe popup OR dictation panel appears (depends on macOS Keyboard settings); function-key row keys still work |
| cmd+shift+v re-paste fires correct transcript into focused window after focus shift | QOL-01 | Requires cross-app behaviour (record → switch to different app → cmd+shift+v) and visual confirmation in a real text field | `tests/manual/test_repaste_walkthrough.md` — record into Notes, switch to TextEdit, cmd+shift+v, verify same transcript appears |
| Re-paste nil-state shows brief alert without crashing on first cmd+shift+v after Hammerspoon reload | QOL-01 | Requires live Hammerspoon reload + visual confirmation of `hs.alert` overlay | Included in `test_repaste_walkthrough.md` — Cmd+R Hammerspoon → cmd+shift+v immediately → verify "PurpleVoice: nothing to re-paste yet" alert ~1.5s, no crash |
| setup.sh Step 9 prints actionable error + non-zero exit when Karabiner absent | QOL-NEW-01 | Requires sudo to move /Applications/Karabiner-Elements.app aside; reversal of system state is hand-managed | `tests/manual/test_setup_karabiner_missing.md` — `sudo mv /Applications/Karabiner-Elements.app /tmp/`, `bash setup.sh`, observe exit-1 + 5-step instructions, `sudo mv /tmp/Karabiner-Elements.app /Applications/` |
| 200ms hold-threshold feels right on Oliver's hardware | QOL-NEW-01 | Subjective UX — needs live use to feel laggy (too long) or false-positive-prone (too short) | Included in `test_f19_walkthrough.md` Pitfall 1 section — record 5+ times across a session, judge feel; ± 50ms adjustment if needed |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify (manual walkthroughs paired with automated string-checks)
- [ ] Wave 0 covers all MISSING references (test_karabiner_check.sh + 3 manual scaffolds + REQUIREMENTS.md stubs)
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s (bash test suite)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
