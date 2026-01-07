# Progression & Achievement Asset Specifications

## Design Philosophy
- **Visible Progress**: Players always see how far they've come
- **Meaningful Rewards**: Every unlock feels earned and valuable
- **Multiple Paths**: Various ways to progress suit different players
- **Celebration**: Achievements feel special and memorable

---

## PROGRESSION SYSTEMS

### Experience & Levels

#### XP Bar (ui_xp_bar)
**Dimensions**: 200x16 (9-slice)
**Components**:
- Background track
- Fill bar
- Level number
- XP text (optional)

**Color Palette**:
```
Track:      #1a252f
Fill:       #9b59b6 (purple)
Overflow:   #d2b4de (when near level)
Text:       #fdfefe
Level:      #f4d03f
```

**Animation**:
- Fill smoothly on XP gain
- Pulse when near level up
- Flash on level complete

---

#### Level Badge (badge_level)
**Dimensions**: 32x32
**Visual Design**:
- Circular badge
- Level number (centered)
- Decorative border
- Changes appearance per tier

**Level Tier Visuals**:
| Levels | Border Color | Background |
|--------|--------------|------------|
| 1-9 | #5d6d7e | Simple |
| 10-24 | #27ae60 | Bronze ring |
| 25-49 | #3498db | Silver ring |
| 50-74 | #9b59b6 | Gold ring |
| 75-99 | #f4d03f | Platinum ring |
| 100+ | Rainbow | Diamond/crystal |

---

#### Level Up Effect (fx_level_up)
**Dimensions**: Full screen
**Frames**: 16
**Duration**: 1500ms

**Visual**:
- Light pillar from character
- Radial burst
- Number flies up
- Particles scatter

**Color Palette**:
```
Pillar:     #f4d03f, #fdfefe
Burst:      #9b59b6
Particles:  #d2b4de
Number:     #f4d03f
```

---

### Skill Trees

#### Skill Node (skill_node_*)
**Dimensions**: 48x48

**States**:
| State | Visual |
|-------|--------|
| locked | Gray, lock icon |
| available | Glowing border, unlockable |
| purchased | Full color, checkmark |
| maxed | Gold border, star |

---

#### Skill Node Types

##### Passive Skill (skill_node_passive)
```
Shape:      Circle
Icon:       Skill-specific
Border:     Single line
```

##### Active Skill (skill_node_active)
```
Shape:      Hexagon
Icon:       Skill-specific
Border:     Double line
```

##### Ultimate Skill (skill_node_ultimate)
```
Shape:      Star/octagon
Icon:       Skill-specific
Border:     Ornate
Size:       64x64 (larger)
```

---

#### Skill Connectors (skill_line_*)
**Dimensions**: Variable length, 4px width

**Types**:
| Type | Visual | Meaning |
|------|--------|---------|
| locked | Dashed gray | Prerequisite not met |
| available | Solid gray | Can unlock |
| unlocked | Solid colored | Path completed |

---

#### Skill Point Display (ui_skill_points)
**Dimensions**: 80x24
**Components**:
- Point icon
- Point count
- Pulse when points available

---

### Mastery System

#### Mastery Icon (icon_mastery_*)
**Dimensions**: 24x24

**Mastery Levels**:
| Level | Icon | Requirement |
|-------|------|-------------|
| Novice | Bronze circle | Complete lesson |
| Apprentice | Silver circle | 90% accuracy |
| Journeyman | Gold circle | 95% accuracy |
| Expert | Gold star | 98% accuracy |
| Master | Platinum star | 100% accuracy × 3 |

---

#### Mastery Progress Ring (ui_mastery_ring)
**Dimensions**: 64x64
**Visual**:
- Circular progress
- Current tier icon center
- Next tier preview

---

### Star Rating

#### Star Icon (icon_star)
**Dimensions**: 16x16
**Frames**: 4 (twinkle)

**States**:
| State | Visual |
|-------|--------|
| empty | Gray outline |
| filled | Gold filled |
| perfect | Gold + sparkle |

---

#### Star Display (ui_stars)
**Dimensions**: 56x16 (3 stars)
**Animation**: Stars fill in sequence on earn

---

## ACHIEVEMENTS

### Achievement Panel (ui_achievement_panel)
**Dimensions**: 280x80
**Components**:
- Icon area (64x64)
- Title
- Description
- Progress bar (if incomplete)
- Unlock date (if complete)

**9-Slice Margins**:
```
margin_left: 8
margin_right: 8
margin_top: 8
margin_bottom: 8
```

---

### Achievement Icons (icon_achievement_*)
**Dimensions**: 48x48

#### Typing Achievements
```
icon_ach_first_word:      Keyboard with checkmark
icon_ach_words_100:       "100" with star
icon_ach_words_1000:      "1K" badge
icon_ach_words_10000:     "10K" trophy
icon_ach_perfect_word:    Sparkle keyboard
icon_ach_perfect_streak:  Fire streak
icon_ach_wpm_40:          Speedometer 40
icon_ach_wpm_60:          Speedometer 60
icon_ach_wpm_80:          Speedometer 80
icon_ach_wpm_100:         Speedometer flame
icon_ach_accuracy_90:     Target 90%
icon_ach_accuracy_95:     Target 95%
icon_ach_accuracy_100:    Target perfect
```

#### Combat Achievements
```
icon_ach_first_enemy:     Defeated enemy
icon_ach_enemies_100:     Skull pile
icon_ach_enemies_1000:    Mountain of skulls
icon_ach_first_boss:      Boss crown
icon_ach_all_bosses:      Triple crown
icon_ach_no_damage:       Untouched shield
icon_ach_tower_master:    Tower with star
icon_ach_all_towers:      Tower collection
```

#### Combo Achievements
```
icon_ach_combo_5:         "x5" badge
icon_ach_combo_10:        "x10" fire badge
icon_ach_combo_20:        "x20" inferno badge
icon_ach_combo_50:        "x50" legendary badge
icon_ach_combo_100:       "x100" mythic badge
```

#### Progress Achievements
```
icon_ach_first_level:     Map pin
icon_ach_world_1:         World 1 emblem
icon_ach_world_2:         World 2 emblem
icon_ach_world_3:         World 3 emblem
icon_ach_all_stars:       Star collection
icon_ach_completionist:   Crown trophy
```

#### Secret Achievements
```
icon_ach_secret_locked:   Question mark
icon_ach_secret_hint:     Faded question
icon_ach_easter_egg:      Hidden egg
```

---

### Achievement Rarity Frames

#### Common Frame (frame_ach_common)
**Border**: #5d6d7e (gray)
**Effect**: None

#### Uncommon Frame (frame_ach_uncommon)
**Border**: #27ae60 (green)
**Effect**: Subtle glow

#### Rare Frame (frame_ach_rare)
**Border**: #3498db (blue)
**Effect**: Glow + sparkle

#### Epic Frame (frame_ach_epic)
**Border**: #9b59b6 (purple)
**Effect**: Strong glow + particles

#### Legendary Frame (frame_ach_legendary)
**Border**: #f4d03f (gold)
**Effect**: Animated gold shimmer

---

### Achievement Popup (notif_achievement)
**Dimensions**: 300x80
**Duration**: 4 seconds
**Position**: Top center or configurable

**Animation**:
- Slide down from top
- Icon pops in
- Text types out
- Particles burst
- Slide up to exit

**Sound**: Achievement fanfare

---

## UNLOCKABLES

### Unlock Types

#### Character Skin (unlock_skin)
**Preview**: 64x64 sprite
**Card**: 100x140

**Components**:
- Character preview
- Skin name
- Unlock requirement
- Equip button (if owned)

---

#### Tower Skin (unlock_tower_skin)
**Preview**: 48x48 sprite
**Card**: 100x140

---

#### Companion Pet (unlock_pet)
**Preview**: 48x48 sprite
**Card**: 100x140

---

#### Profile Border (unlock_border)
**Preview**: 80x80 frame
**Variations**: 20+ designs

---

#### Profile Badge (unlock_badge)
**Dimensions**: 32x32
**Purpose**: Displayed on profile

---

#### Title (unlock_title)
**Display**: Text with styling
**Examples**:
- "Typing Novice"
- "Keyboard Warrior"
- "Speed Demon"
- "Perfectionist"
- "Castle Defender"

---

### Unlock Card (ui_unlock_card)
**Dimensions**: 120x160 (9-slice)

**States**:
| State | Visual |
|-------|--------|
| locked | Grayed, lock icon |
| hidden | Silhouette, "?" |
| available | Colored, cost shown |
| owned | Full color, checkmark |
| equipped | Gold border, star |

---

### Unlock Celebration (fx_unlock)
**Dimensions**: 160x160
**Frames**: 12
**Duration**: 1000ms

**Visual**:
- Card reveals
- Sparkle burst
- Item preview
- Celebration particles

---

## PROGRESS INDICATORS

### Completion Bar (bar_completion)
**Dimensions**: 200x12
**Components**:
- Background track
- Fill segments
- Milestone markers
- Percentage text

**Color Palette**:
```
Track:      #1a252f
Fill:       #3498db
Milestones: #f4d03f
Text:       #fdfefe
```

---

### Milestone Marker (marker_milestone)
**Dimensions**: 12x16
**Position**: Above completion bar
**States**:
- Locked: Gray flag
- Reached: Colored flag
- Current: Glowing flag

---

### Collection Progress (ui_collection_progress)
**Dimensions**: Variable
**Format**: "X / Y collected"
**Visual**: Grid of item silhouettes

---

### Daily Challenge Progress (ui_daily_progress)
**Dimensions**: 180x40
**Components**:
- Challenge description
- Progress bar
- Reward preview
- Time remaining

---

## REWARDS DISPLAY

### Reward Card (ui_reward_card)
**Dimensions**: 80x100

**Components**:
- Item icon (48x48)
- Item name
- Quantity (if applicable)
- Rarity border

---

### Reward Chest Opening (fx_reward_open)
**Dimensions**: 200x200
**Frames**: 24
**Duration**: 2000ms

**Sequence**:
1. Chest shakes
2. Light beams from seams
3. Lid opens
4. Items fly out
5. Items arrange for viewing

---

### Reward Stack (ui_reward_stack)
**Dimensions**: Variable
**Layout**: Horizontal row of reward cards
**Animation**: Cards deal in from left

---

## LEADERBOARD ELEMENTS

### Rank Badge (badge_rank)
**Dimensions**: 40x40

**Rank Visuals**:
| Rank | Visual |
|------|--------|
| 1st | Gold crown |
| 2nd | Silver crown |
| 3rd | Bronze crown |
| Top 10 | Blue ribbon |
| Top 100 | Green ribbon |
| Other | Gray circle + number |

---

### Leaderboard Row (ui_leaderboard_row)
**Dimensions**: 280x40

**Components**:
- Rank badge
- Player avatar (24x24)
- Player name
- Score
- Highlight if current player

---

### Personal Best Indicator (indicator_pb)
**Dimensions**: 24x24
**Visual**: Star with "PB" or trophy

---

## SEASONAL CONTENT

### Season Pass Track (ui_season_track)
**Dimensions**: Full width, 80px height
**Components**:
- Track line
- Reward nodes
- Current position
- Free/Premium rows

---

### Season Tier Badge (badge_season_tier)
**Dimensions**: 48x48
**Tiers**: 1-100

**Tier Milestones**:
| Tier | Badge Style |
|------|-------------|
| 1-24 | Bronze |
| 25-49 | Silver |
| 50-74 | Gold |
| 75-99 | Platinum |
| 100 | Diamond + animation |

---

### Limited Time Icon (icon_limited_time)
**Dimensions**: 16x16
**Visual**: Clock with exclamation
**Usage**: On time-limited items

---

## STATISTICS DISPLAY

### Stat Panel (ui_stat_panel)
**Dimensions**: 240x40

**Components**:
- Stat icon (24x24)
- Stat name
- Stat value
- Trend indicator (if applicable)

---

### Stat Icons (icon_stat_*)
**Dimensions**: 24x24

```
icon_stat_words:      Keyboard
icon_stat_accuracy:   Target
icon_stat_wpm:        Speedometer
icon_stat_time:       Clock
icon_stat_enemies:    Skull
icon_stat_gold:       Coin
icon_stat_xp:         Star
icon_stat_combo:      Fire
icon_stat_damage:     Sword
icon_stat_levels:     Map
```

---

### Graph Display (ui_graph)
**Dimensions**: 200x100
**Types**:
- Line graph (progress over time)
- Bar graph (comparisons)
- Pie chart (distributions)

**Color Palette**:
```
Background: #1a252f
Grid:       #5d6d7e (20%)
Line:       #3498db
Fill:       #3498db (30%)
Highlight:  #f4d03f
```

---

## ANIMATION TIMINGS

### Progress Animations
| Event | Duration | Notes |
|-------|----------|-------|
| XP gain | 300ms | Smooth fill |
| Level up | 1500ms | Full celebration |
| Star earn | 500ms | Pop in |
| Achievement | 4000ms | Full popup cycle |
| Unlock reveal | 1000ms | Card flip |
| Rank change | 600ms | Slide + flash |

### Celebration Effects
| Effect | Duration | Trigger |
|--------|----------|---------|
| Confetti | 2000ms | Major unlock |
| Fireworks | 3000ms | Level milestone |
| Spotlight | 1000ms | Achievement |
| Particle burst | 500ms | General reward |

---

## ASSET CHECKLIST

### Per Achievement
- [ ] Icon (48x48)
- [ ] Locked state
- [ ] Unlocked state
- [ ] Popup notification
- [ ] Sound effect
- [ ] Description text
- [ ] Unlock criteria

### Per Unlockable
- [ ] Preview image
- [ ] Card design
- [ ] Locked silhouette
- [ ] Unlock animation
- [ ] Equip indication
- [ ] Category icon

### Per Progress System
- [ ] Bar/meter design
- [ ] Fill animation
- [ ] Milestone markers
- [ ] Completion celebration
- [ ] Statistics integration

