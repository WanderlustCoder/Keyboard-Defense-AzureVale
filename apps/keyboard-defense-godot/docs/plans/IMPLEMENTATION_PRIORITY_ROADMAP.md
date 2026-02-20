# Implementation Priority Roadmap

## Executive Summary

This document provides a unified implementation schedule combining art assets, sound design, and polish/juice systems. The goal is a complete, polished game suitable for your son to enjoy.

**Timeline**: 16 weeks of implementation work
**Approach**: Vertical slices - each phase delivers playable improvements
**Principle**: Playable > Pretty > Perfect

---

## Phase Overview

| Phase | Focus | Weeks | Outcome |
|-------|-------|-------|---------|
| 1 | Core Feel | 1-2 | Typing feels great |
| 2 | Combat Juice | 3-4 | Battles are exciting |
| 3 | Audio Foundation | 5-6 | Everything has sound |
| 4 | Visual Upgrade | 7-9 | Art looks polished |
| 5 | Environmental | 10-11 | World feels alive |
| 6 | Final Polish | 12-14 | Everything shines |
| 7 | Music & Mastering | 15-16 | Complete experience |

---

## Phase 1: Core Feel (Weeks 1-2)

**Goal**: Make typing feel immediately satisfying

### Week 1: Input Feedback
| Task | Type | Priority | Time |
|------|------|----------|------|
| Screen shake system | Code | High | 2h |
| Hit pause system | Code | High | 1h |
| Damage numbers system | Code | High | 3h |
| Input flash feedback | Code | High | 2h |
| type_space sound | Audio | High | 15m |
| type_backspace sound | Audio | High | 15m |
| type_enter sound | Audio | High | 15m |
| type_target_lock sound | Audio | High | 15m |

### Week 2: Word Feedback
| Task | Type | Priority | Time |
|------|------|----------|------|
| Word complete animations | Code | High | 3h |
| Panel open/close animations | Code | Medium | 2h |
| word_perfect sound | Audio | High | 15m |
| speed_bonus sound | Audio | Medium | 15m |
| ui_hover sound | Audio | Medium | 10m |
| ui_click sound | Audio | Medium | 10m |
| Typing display character states | Code | High | 2h |

**Deliverable**: Type a word and feel amazing doing it.

---

## Phase 2: Combat Juice (Weeks 3-4)

**Goal**: Make combat exciting and readable

### Week 3: Enemy Feedback
| Task | Type | Priority | Time |
|------|------|----------|------|
| Enhanced enemy death particles | Code | High | 3h |
| Enemy hit flash shader | Code | High | 2h |
| Tower shot trail effects | Code | High | 3h |
| projectile_launch sound | Audio | High | 15m |
| projectile_impact sound | Audio | High | 15m |
| enemy_attack sound | Audio | High | 15m |
| enemy_grunt_hit sound | Audio | Medium | 15m |
| enemy_grunt_death sound | Audio | Medium | 15m |

### Week 4: Status Effects
| Task | Type | Priority | Time |
|------|------|----------|------|
| Status effect particles (burn, freeze, poison) | Code | High | 4h |
| Castle damage states | Code | High | 3h |
| armor_hit sound | Audio | Medium | 15m |
| chain_lightning sound | Audio | Medium | 15m |
| splash_damage sound | Audio | Medium | 15m |
| Critical hit visual enhancement | Code | Medium | 1h |

**Deliverable**: Battles feel impactful and readable.

---

## Phase 3: Audio Foundation (Weeks 5-6)

**Goal**: Everything in the game has appropriate audio feedback

### Week 5: UI & Environment Audio
| Task | Type | Priority | Time |
|------|------|----------|------|
| ui_open_panel sound | Audio | Medium | 15m |
| ui_close_panel sound | Audio | Medium | 15m |
| ui_tab_switch sound | Audio | Medium | 10m |
| ui_toggle_on/off sounds | Audio | Low | 20m |
| ui_error sound | Audio | Medium | 15m |
| ambient_wind_light sound | Audio | Medium | 30m |
| ambient_tension sound | Audio | High | 30m |
| day_dawn sound | Audio | Medium | 20m |
| night_fall sound | Audio | High | 20m |

### Week 6: Combat Audio
| Task | Type | Priority | Time |
|------|------|----------|------|
| enemy_special sound | Audio | Medium | 15m |
| enemy_elite_roar sound | Audio | High | 20m |
| enemy_elite_death sound | Audio | High | 20m |
| affix_armored_hit sound | Audio | Medium | 15m |
| affix_swift_dash sound | Audio | Medium | 15m |
| affix_explosive_boom sound | Audio | High | 20m |
| Wire up all combat sounds to events | Code | High | 3h |

**Deliverable**: Game has comprehensive audio feedback.

---

## Phase 4: Visual Upgrade (Weeks 7-9)

**Goal**: Art assets look polished and cohesive

### Week 7: Core Sprites
| Task | Type | Priority | Time |
|------|------|----------|------|
| Revise enemy_scout sprite | Art | High | 45m |
| Revise enemy_brute sprite | Art | High | 45m |
| Revise enemy_runner sprite | Art | High | 45m |
| Revise enemy_tank sprite | Art | High | 45m |
| Create enemy walk animations (4 frames each) | Art | High | 3h |
| Revise tower_arrow sprite | Art | High | 30m |
| Revise tower_fire sprite | Art | High | 30m |
| Revise tower_ice sprite | Art | High | 30m |

### Week 8: Tower & Building Sprites
| Task | Type | Priority | Time |
|------|------|----------|------|
| Create tower_lightning sprite | Art | High | 30m |
| Create tower_poison sprite | Art | High | 30m |
| Create tower_arcane sprite | Art | High | 30m |
| Create tower_holy sprite | Art | High | 30m |
| Revise building_farm sprite | Art | Medium | 30m |
| Revise building_mine sprite | Art | Medium | 30m |
| Revise building_barracks sprite | Art | Medium | 30m |
| Create building upgrade tiers (T2, T3) | Art | Medium | 2h |

### Week 9: Effects & UI Sprites
| Task | Type | Priority | Time |
|------|------|----------|------|
| Create effect_burn sprite | Art | High | 20m |
| Create effect_freeze sprite | Art | High | 20m |
| Create effect_poison sprite | Art | High | 20m |
| Create effect_shield sprite | Art | Medium | 20m |
| Create icon set (resources, status) | Art | Medium | 2h |
| Create UI frame elements | Art | Low | 1h |
| Create button states | Art | Low | 1h |

**Deliverable**: Game has cohesive, polished visual style.

---

## Phase 5: Environmental Polish (Weeks 10-11)

**Goal**: Game world feels alive and immersive

### Week 10: Day/Night & Weather
| Task | Type | Priority | Time |
|------|------|----------|------|
| Day/night transition system | Code | High | 4h |
| Weather particle system (rain, snow) | Code | Medium | 3h |
| Ambient particle system | Code | Medium | 2h |
| ambient_fire_crackle sound | Audio | Low | 20m |
| ambient_magic_hum sound | Audio | Low | 20m |
| thunder_distant sound | Audio | Medium | 20m |
| earthquake_rumble sound | Audio | Medium | 20m |

### Week 11: Building & Progress
| Task | Type | Priority | Time |
|------|------|----------|------|
| building_upgrade sound | Audio | Medium | 15m |
| building_destroy sound | Audio | Medium | 15m |
| worker_assign sound | Audio | Low | 15m |
| production_tick sound | Audio | Low | 15m |
| gold_coins sound | Audio | Medium | 15m |
| research_complete sound | Audio | Medium | 15m |
| tech_unlock sound | Audio | Medium | 15m |

**Deliverable**: World feels dynamic and responsive.

---

## Phase 6: Final Polish (Weeks 12-14)

**Goal**: Every interaction is polished and satisfying

### Week 12: Combo & Streak Visuals
| Task | Type | Priority | Time |
|------|------|----------|------|
| Combo counter visual scaling | Code | High | 2h |
| Combo milestone celebrations | Code | High | 3h |
| Streak flame indicator | Code | Medium | 2h |
| combo_2x through combo_5x sounds | Audio | High | 1h |
| combo_max sound | Audio | Medium | 15m |
| streak_5/10/25/50 sounds | Audio | Medium | 1h |

### Week 13: Victory/Defeat & Transitions
| Task | Type | Priority | Time |
|------|------|----------|------|
| Victory screen sequence | Code | High | 4h |
| Defeat screen sequence | Code | High | 2h |
| Scene transitions (5 types) | Code | Medium | 3h |
| Button hover/click animations | Code | Medium | 2h |
| Achievement popup animations | Code | Medium | 2h |

### Week 14: Boss Encounters
| Task | Type | Priority | Time |
|------|------|----------|------|
| Boss entrance sequence | Code | High | 3h |
| Boss phase transition effects | Code | High | 2h |
| Boss death sequence | Code | High | 2h |
| enemy_boss_roar sound | Audio | High | 20m |
| enemy_boss_phase sound | Audio | High | 20m |
| Create boss sprites (3 bosses) | Art | High | 3h |

**Deliverable**: Game has complete polish pass.

---

## Phase 7: Music & Mastering (Weeks 15-16)

**Goal**: Complete audio experience with dynamic music

### Week 15: Music Implementation
| Task | Type | Priority | Time |
|------|------|----------|------|
| Implement procedural music generator | Code | High | 6h |
| Main menu theme | Audio | High | 2h |
| Kingdom hub theme | Audio | High | 2h |
| Day phase theme | Audio | High | 2h |
| Night phase theme | Audio | High | 2h |

### Week 16: Audio Mastering & QoL
| Task | Type | Priority | Time |
|------|------|----------|------|
| Boss battle theme | Audio | High | 2h |
| Crossfade transitions | Code | High | 2h |
| Audio ducking system | Code | Medium | 2h |
| Reduced motion mode | Code | High | 2h |
| High contrast mode | Code | Medium | 2h |
| Final balance pass | QA | High | 4h |

**Deliverable**: Complete, polished game experience.

---

## Priority Legend

| Priority | Meaning | Impact |
|----------|---------|--------|
| **High** | Core experience | Game feels incomplete without |
| **Medium** | Expected polish | Noticeable improvement |
| **Low** | Nice to have | Extra polish |

---

## Quick Reference: File Locations

| Asset Type | Location |
|------------|----------|
| SVG sources | `assets/art/src-svg/` |
| PNG exports | `assets/sprites/` |
| Sound presets | `data/audio/sfx_presets.json` |
| Animation data | `data/assets_manifest.json` |
| Polish code | `game/` |
| UI code | `ui/` |

---

## Implementation Notes

### Art Workflow
1. Create SVG in `assets/art/src-svg/[category]/`
2. Export PNG to `assets/sprites/[category]/`
3. Update `data/assets_manifest.json`
4. Run `./scripts/convert_assets.sh --dry-run` to verify

### Audio Workflow
1. Add preset to `data/audio/sfx_presets.json`
2. Test with audio preview tool
3. Wire up in relevant game code
4. Balance volume relative to category

### Code Workflow
1. Create/modify file in appropriate directory
2. Run `godot --headless --path . --script res://tests/run_tests.gd`
3. Playtest in actual game
4. Commit changes

---

## Success Criteria

### Per-Phase Gate
- [ ] All High priority tasks complete
- [ ] Tests passing
- [ ] Playable without crashes
- [ ] Feels better than before

### Final Game Gate
- [ ] Complete playthrough possible
- [ ] All systems have audio feedback
- [ ] Art style is consistent
- [ ] No major performance issues
- [ ] Fun to play

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Art takes too long | Use simpler placeholders, iterate |
| Audio fatigue | Add variations, lower volume |
| Performance issues | Profile early, pool objects |
| Scope creep | Stick to High priority first |
| Burnout | Take breaks, celebrate progress |

---

## Summary Statistics

### Total Estimated Work
| Category | Items | Est. Time |
|----------|-------|-----------|
| Art assets | ~100 | 40-50h |
| Audio presets | ~130 | 15-20h |
| Code systems | ~35 | 60-80h |
| Testing/QA | - | 20-30h |
| **Total** | - | **135-180h** |

### By Phase
| Phase | Weeks | Focus |
|-------|-------|-------|
| 1 | 1-2 | Core feel |
| 2 | 3-4 | Combat |
| 3 | 5-6 | Audio |
| 4 | 7-9 | Art |
| 5 | 10-11 | Environment |
| 6 | 12-14 | Polish |
| 7 | 15-16 | Music |

---

## Getting Started

**First Task**: Implement screen shake system (`game/screen_shake.gd`)
- Simple, high-impact improvement
- Touches all game events
- Foundation for other polish

**Command to start**:
```bash
godot --headless --path . --script res://tests/run_tests.gd
```

Let's make this game feel amazing!
