# Priorities Analysis

**Generated:** 2026-01-08
**Last Updated:** 2026-01-11 (Audio integration complete)

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

#### Numbers/Symbols Lessons (Acts 4-5) - COMPLETED
~~The story defines lessons for days 17-20 that don't exist in `lessons.json`:~~
- [x] `numbers_1`, `numbers_2` - Number row (implemented in lessons.json)
- [x] `punctuation_1` - Basic punctuation (implemented)
- [x] `symbols_1` - Symbols (implemented)

**Status:** All campaign lessons exist in `data/lessons.json`.

#### Lesson Introductions - COMPLETED
~~Some lessons in `lessons.json` lack story introductions in `story.json`:~~
- [x] 75+ lesson introductions added to story.json (version 4)
- [x] Finger guides included for relevant lessons
- [x] Practice tips included

**Status:** Comprehensive lesson introductions added for all major lessons.

### Medium Priority - Feature Completion

#### Achievement System (F-ACH-001) - COMPLETED
~~Story defines 13 achievements but no UI or tracking~~
- [x] AchievementChecker in `game/achievement_checker.gd` with all check methods
- [x] AchievementPanel in `ui/components/achievement_panel.gd/.tscn`
- [x] AchievementPopup in `ui/components/achievement_popup.gd/.tscn`
- [x] Full integration in main.gd and kingdom_defense.gd
- [x] Profile persistence via TypingProfile

**Status:** Complete achievement system with UI, notifications, and gameplay integration.

#### Boss Differentiation (F-BOSS-001) - COMPLETED
~~Boss encounters use unique dialogue but identical mechanics~~
- [x] Multi-phase boss system in `sim/boss_encounters.gd`
- [x] 4 unique bosses with distinct mechanics:
  - Grove Guardian: regeneration, root snare, summon treants
  - Mountain King: ground pound, crystal barrier, summon sentinels
  - Fen Seer: word scramble, toxic cloud, mist veil, summon illusions
  - Sunlord: solar flare, burning ground, war banner, summon marauders
- [x] Phase transitions with HP thresholds
- [x] Phase-specific dialogue (intro, transitions, defeat)

**Status:** Comprehensive boss encounter system with unique mechanics per boss.

### Lower Priority - Polish - COMPLETED

#### Daily Streak Tracking (F-PROG-001) - COMPLETED
~~Story defines streak milestone messages but no tracking~~
- [x] Streak tracking in TypingProfile (daily_streak, best_streak, last_play_date)
- [x] update_daily_streak() function
- [x] Streak messages displayed on login

**Status:** Complete streak tracking and persistence.

#### Lore Browser (F-LORE-001) - COMPLETED
~~Rich lore content exists (kingdom, horde, characters) but no access UI~~
- [x] LorePanel in `ui/components/lore_panel.gd`
- [x] Category-based navigation (Kingdom, Horde, Characters)
- [x] Rich text formatting for lore entries
- [x] Accessible via "lore" command in kingdom_defense.gd

**Status:** Full lore browser with category selection and formatted display.

#### Contextual Tips (F-TIP-001) - COMPLETED
~~90+ typing tips defined but not surfaced contextually during gameplay~~
- [x] TipNotification in `ui/components/tip_notification.gd`
- [x] Context-aware tip selection (error, slow, tired, start, etc.)
- [x] Cooldown system to prevent spam
- [x] Auto-dismiss with animations

**Status:** Complete contextual tip system integrated with gameplay.

## Game Mode Integration Gaps

### Kingdom Defense Mode - UPDATED (2026-01-11)
- [x] Story integration complete (dialogue triggers, lesson intros, tips, feedback)
- [x] Audio integration added (music transitions, sound effects for combat events)
- [x] Practice mode uses story lesson intros via StoryManager
- [x] Act completion rewards implemented (gold, ability unlocks)

### Open World Mode - UPDATED (2026-01-12)
- [x] Story integration added (welcome dialogue, exploration milestones, combat intro, victory messages)
- [x] Roaming enemy / threat system enhanced with zone-aware spawning and threat calculations
- [x] POI events and discovery rewards added (interact command, event dialogues, choice resolution)

### Typing Defense Mode - COMPLETED (2026-01-10)
- [x] Story integration added (welcome dialogue, lesson intros, tips, game over)
- [x] Lesson progression with StoryManager integration
- [x] Contextual typing tips based on performance

**Recommendation:** Focus on Kingdom Defense mode as the primary story-driven experience. Open World and Typing Defense can remain as secondary modes.

## Technical Debt

### Data Schema Alignment
- `lessons.json` and `story.json` lesson IDs should be verified for consistency
- Consider merging lesson content (finger guides, tips) into lessons.json or creating a build-time validation

### Test Coverage - UPDATED (2026-01-11)
- [x] Kingdom Defense mode test coverage via boss encounters and difficulty tests
- [x] Story manager functions have unit tests (40+ assertions)
- [x] Boss encounter tests (phases, dialogue, mechanics)
- [x] Difficulty mode tests (modifiers, multipliers)
- [x] Dialogue flow tests (key dialogues, substitutions, act text, taunts, milestones)

## Recommended Priority Order

### Immediate (This Sprint)
1. Complete P0 checklists (balance validation, accessibility audit, export smoke)
2. ~~Add numbers/symbols lessons~~ - DONE
3. Verify lesson ID consistency between data files

### Short-Term (Next Sprint)
4. ~~Basic achievement tracking and display~~ - DONE
5. Kingdom Defense mode story integration polish
6. Test coverage for new game modes

### Medium-Term (Following Sprints)
7. ~~Boss differentiation mechanics~~ - DONE
8. ~~Daily streak and milestone tracking~~ - DONE
9. ~~Contextual tip surfacing~~ - DONE

### Future (Backlog)
10. ~~Lore browser UI~~ - DONE
11. Open World story integration
12. Additional game mode polish

## Updated Remaining Work (2026-01-11)

### P0 Checklist Items
The following P0 items remain:
1. Balance validation playtest (days 1-7)
2. Accessibility audit at 1280x720
3. Windows export smoke test

### Game Mode Polish - COMPLETED (2026-01-11)
1. ~~Kingdom Defense mode story integration polish~~ - DONE (2026-01-11, audio added)
2. ~~Open World mode story integration~~ - DONE (2026-01-10)
3. ~~Typing Defense mode story integration~~ - DONE (2026-01-10)
4. ~~Test coverage for all game modes~~ - DONE (2026-01-11, boss/difficulty tests)

### Technical Debt
1. ~~Verify lesson ID consistency between data files~~ - DONE (2026-01-10, all 98 lessons have introductions)
2. ~~Unit tests for story manager functions~~ - DONE (2026-01-10, 40+ test assertions added)
3. ~~Boss encounters and difficulty tests~~ - DONE (2026-01-11)
4. ~~Integration tests for dialogue flow~~ - DONE (2026-01-11, comprehensive tests in run_tests.gd)

## Success Metrics

A complete vertical slice should allow a player to:
- [ ] Start a new campaign and see Elder Lyra's introduction
- [ ] Progress through at least Act 1 (days 1-4) with lesson introductions
- [ ] Experience a boss encounter with unique dialogue
- [ ] See typing feedback (accuracy, speed, combo) with story-driven messages
- [ ] Have their progress persist across sessions
- [ ] Access accessibility options that work correctly
- [ ] Export and run a Windows build
