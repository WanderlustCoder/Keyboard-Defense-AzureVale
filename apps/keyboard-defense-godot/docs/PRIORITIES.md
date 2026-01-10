# Priorities Analysis

**Generated:** 2026-01-08

This document identifies gaps between implemented features and the story/GDD vision, and recommends next priorities.

## P0 Completion Checklist

All P0 items are nearly complete. Remaining work:

### P0-BAL-001 (Balance)
- [ ] Run final playtest validation session for days 1-7
- [ ] Document scenario harness integration for balance regression tests
- [ ] Verify determinism tests pass with current parameters

### P0-ACC-001 (Accessibility)
- [ ] Complete 1280x720 readability audit
- [ ] Run `docs/ACCESSIBILITY_VERIFICATION.md` checklist
- [ ] Update documentation with accessibility feature summary

### P0-EXP-001 (Export)
- [ ] Execute Windows export smoke test
- [ ] Complete release checklist once
- [ ] Document any issues found

**Recommendation:** Complete these checklist items to close out P0 and enable a release candidate.

## Content Gaps (Story vs Implementation)

### High Priority - Campaign Completion

#### Numbers/Symbols Lessons (Acts 4-5)
The story defines lessons for days 17-20 that don't exist in `lessons.json`:
- `numbers_1`, `numbers_2` - Number row (1234567890)
- `punctuation_1` - Basic punctuation (.,';:)
- `symbols_1` - Symbols (!@#$%)

**Recommendation:** Add these lessons to `data/lessons.json` to complete the 20-day campaign.

#### Missing Lesson Introductions
Some lessons in `lessons.json` lack story introductions in `story.json`:
- `full_alpha` - has no intro
- Skill lessons may need finger guides

**Recommendation:** Audit lesson coverage and add missing introductions.

### Medium Priority - Feature Completion

#### Achievement System (F-ACH-001)
Story defines 13 achievements but no UI or tracking:
- first_blood, combo_starter, combo_master, speed_demon
- perfectionist, home_row_master, alphabet_scholar
- number_cruncher, keyboard_master, defender
- survivor, boss_slayer, void_vanquisher

**Recommendation:** Add achievement tracking to profile and basic achievement notification/display.

#### Boss Differentiation (F-BOSS-001)
Boss encounters use unique dialogue but identical mechanics:
- Shadow Scout Commander (Day 4)
- Storm Wraith (Day 8)
- Stone Golem King (Day 12)
- Typhos General (Day 16)
- Void Tyrant (Day 20)

**Recommendation:** Consider unique boss mechanics (special words, phases, abilities) for at least the final boss.

### Lower Priority - Polish

#### Daily Streak Tracking (F-PROG-001)
Story defines streak milestone messages but no tracking.

#### Lore Browser (F-LORE-001)
Rich lore content exists (kingdom, horde, characters) but no access UI.

#### Contextual Tips (F-TIP-001)
90+ typing tips defined but not surfaced contextually during gameplay.

## Game Mode Integration Gaps

### Kingdom Defense Mode
- [ ] Story integration is partial - dialogue triggers may not fire for all events
- [ ] Practice mode exists but may not use story lesson intros
- [ ] Act completion rewards not implemented

### Open World Mode
- [ ] No story integration currently
- [ ] Roaming enemy system is basic - could tie to threat system
- [ ] No POI events or discovery rewards

### Typing Defense Mode
- [ ] Basic implementation - could benefit from story integration
- [ ] No lesson progression tracking

**Recommendation:** Focus on Kingdom Defense mode as the primary story-driven experience. Open World and Typing Defense can remain as secondary modes.

## Technical Debt

### Data Schema Alignment
- `lessons.json` and `story.json` lesson IDs should be verified for consistency
- Consider merging lesson content (finger guides, tips) into lessons.json or creating a build-time validation

### Test Coverage
- Kingdom Defense mode lacks headless test coverage
- Story manager functions need unit tests
- Dialogue box flow needs integration tests

## Recommended Priority Order

### Immediate (This Sprint)
1. Complete P0 checklists (balance validation, accessibility audit, export smoke)
2. Add numbers/symbols lessons to complete campaign
3. Verify lesson ID consistency between data files

### Short-Term (Next Sprint)
4. Basic achievement tracking and display
5. Kingdom Defense mode story integration polish
6. Test coverage for new game modes

### Medium-Term (Following Sprints)
7. Boss differentiation mechanics
8. Daily streak and milestone tracking
9. Contextual tip surfacing

### Future (Backlog)
10. Lore browser UI
11. Open World story integration
12. Additional game mode polish

## Success Metrics

A complete vertical slice should allow a player to:
- [ ] Start a new campaign and see Elder Lyra's introduction
- [ ] Progress through at least Act 1 (days 1-4) with lesson introductions
- [ ] Experience a boss encounter with unique dialogue
- [ ] See typing feedback (accuracy, speed, combo) with story-driven messages
- [ ] Have their progress persist across sessions
- [ ] Access accessibility options that work correctly
- [ ] Export and run a Windows build
