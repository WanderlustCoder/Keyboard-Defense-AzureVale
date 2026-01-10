# Lesson and Guide Expansion Plan

**Created:** 2026-01-08
**Updated:** 2026-01-08

This document outlines the plan for expanding lesson content and pedagogical guides to create a comprehensive typing curriculum.

## Lesson Modes

The lesson system now supports three modes:

| Mode | Description | Example |
|------|-------------|---------|
| `charset` | Generates random pronounceable strings from character set | "asdfghjkl" → "ghads", "fslka" |
| `wordlist` | Selects from curated list of real words | "forest", "castle", "knight" |
| `sentence` | Presents full sentences for typing | "The cat sat on the mat." |

## Graduation Path System

Lessons are organized into progressive paths in `lessons.json`:

### Beginner Path (5 stages)
1. **Home Row Fundamentals** → home_row_1 → home_row_2 → home_row_words
2. **Reach Row Addition** → reach_row_1 → reach_row_2 → reach_row_words
3. **Bottom Row** → bottom_row_1 → bottom_row_2 → bottom_row_words
4. **Full Alphabet** → full_alpha → full_alpha_words → common_words
5. **Simple Sentences** → sentence_basics → sentence_home_row → sentence_common

### Intermediate Path (4 stages)
1. **Word Mastery** → full_alpha_words → common_words → bigram_flow
2. **Pattern Training** → double_letters → rhythm_words → alternating_hands
3. **Sentence Fluency** → sentence_common → sentence_intermediate → sentence_pangrams
4. **Themed Content** → biome_evergrove → biome_stonepass → sentence_fantasy

### Advanced Path (5 stages)
1. **Numbers and Symbols** → numbers_1/2 → symbols_1/2
2. **Precision Training** → precision_bronze → precision_silver → precision_gold
3. **Speed Challenges** → gauntlet_speed → time_trial_sprint → time_trial_marathon
4. **Advanced Sentences** → sentence_advanced → sentence_coding → sentence_pangrams
5. **Legendary Trials** → legendary_forest → legendary_citadel → legendary_apex

### Programmer Path (3 stages)
1. **Code Basics** → code_variables → code_keywords
2. **Symbols and Syntax** → symbols_1 → code_syntax → email_patterns
3. **Code Mastery** → code_master → mixed_case → sentence_coding

## Current State

### Lesson Inventory (95+ lessons in `data/lessons.json`)

| Category | Count | Lessons |
|----------|-------|---------|
| Core Progression (charset) | 12 | home_row_1/2, reach_row_1/2, bottom_row_1/2, upper_row_1/2, mixed_rows, speed_alpha, nexus_blend, apex_mastery |
| Word Lessons (wordlist) | 4 | home_row_words, reach_row_words, bottom_row_words, full_alpha_words |
| Sentence Lessons (sentence) | 8 | sentence_basics, sentence_home_row, sentence_common, sentence_pangrams, sentence_intermediate, sentence_advanced, sentence_fantasy, sentence_coding |
| Full Alphabet | 1 | full_alpha |
| Numbers & Punctuation | 6 | numbers_1/2, punctuation_1/2, symbols_1/2 |
| Gauntlets | 3 | gauntlet_speed, gauntlet_endurance, gauntlet_chaos |
| Training | 2 | training_basics, training_rhythm |
| Capitals | 2 | capitals_1/2 |
| Twilight Theme | 3 | twilight_whisper, twilight_shadow, twilight_void |
| Boss Battles | 6 | boss_grove_guardian, boss_citadel_warden, boss_twilight_lord, boss_eternal_scribe, boss_fen_seer, boss_sunlord |
| Realms | 9 | fire_realm_1/2/boss, ice_realm_1/2/boss, nature_realm_1/2/boss |
| Coding | 4 | code_variables, code_keywords, code_syntax, code_master |
| Precision | 3 | precision_bronze, precision_silver, precision_gold |
| Legendary | 3 | legendary_forest, legendary_citadel, legendary_apex |
| Time Trials | 2 | time_trial_sprint, time_trial_marathon |
| Finger Training | 6 | finger_gym_left, finger_gym_right, alternating_hands, weak_fingers, pinky_power, ring_finger_focus |
| Pattern Training | 5 | double_letters, consonant_clusters, vowel_flow, bigram_flow, rhythm_words |
| Biomes (wordlist) | 4 | biome_evergrove, biome_stonepass, biome_mistfen, biome_sunfields |
| Specialty | 5 | common_words, same_hand_words, mixed_case, email_patterns, weak_fingers_words |

### Lesson Introductions (18 lessons in `data/story.json`)

Currently have Elder Lyra introductions with finger guides:
- home_row_1, home_row_2
- reach_row_1, reach_row_2
- upper_row_1, upper_row_2
- bottom_row_1, bottom_row_2
- mixed_rows
- speed_alpha
- nexus_blend
- numbers_1, numbers_2
- apex_mastery
- punctuation_1
- symbols_1

### Gap Analysis

**62+ lessons lack introductions** - organized by priority:

#### High Priority (campaign progression)
- gauntlet_speed, gauntlet_endurance, gauntlet_chaos
- capitals_1, capitals_2
- punctuation_2, symbols_2

#### Medium Priority (themed content)
- All boss lessons (6)
- All realm lessons (9)
- All twilight lessons (3)
- All legendary lessons (3)

#### Lower Priority (specialty/optional)
- All coding lessons (4)
- All precision lessons (3)
- All finger training lessons (6)
- All pattern lessons (5)
- All biome lessons (4)
- Other specialty lessons

## Proposed Lesson Track Structure

### Track 1: Core Curriculum (Required)
The main progression path for new players.

```
Stage 1: Foundation
├── training_basics (ASDF only)
├── home_row_1 (ASDF JKL;)
└── home_row_2 (Home row mastery)

Stage 2: Reach Keys
├── reach_row_1 (E, R, T, G)
├── reach_row_2 (Full reach row)
└── upper_row_1 (Q, W, P)

Stage 3: Full Coverage
├── upper_row_2 (Full alphabet)
├── bottom_row_1 (Z, X, C, V)
├── bottom_row_2 (B, N, M)
└── mixed_rows (All rows)

Stage 4: Speed Building
├── training_rhythm
├── speed_alpha
├── nexus_blend
└── apex_mastery

Stage 5: Extended Characters
├── numbers_1, numbers_2
├── punctuation_1, punctuation_2
├── capitals_1, capitals_2
└── symbols_1, symbols_2
```

### Track 2: Skill Development (Optional)
Targeted practice for specific weaknesses.

```
Finger Strength
├── finger_gym_left
├── finger_gym_right
├── weak_fingers / pinky_power / ring_finger_focus
└── alternating_hands

Pattern Mastery
├── bigram_flow
├── double_letters
├── consonant_clusters
├── vowel_flow
└── rhythm_words
```

### Track 3: Challenge Modes (Endgame)

```
Gauntlets
├── gauntlet_speed (short bursts)
├── gauntlet_endurance (long words)
└── gauntlet_chaos (everything)

Precision Tiers
├── precision_bronze
├── precision_silver
└── precision_gold

Time Trials
├── time_trial_sprint
└── time_trial_marathon

Legendary
├── legendary_forest
├── legendary_citadel
└── legendary_apex
```

### Track 4: Themed Content (Story Integration)

```
Twilight Path
├── twilight_whisper
├── twilight_shadow
└── twilight_void

Realm Challenges
├── Fire: ember_path → inferno_core → flame_tyrant
├── Ice: frozen_approach → glacier_heart → frost_empress
└── Nature: living_grove → world_tree → ancient_treant

Boss Rush
├── boss_grove_guardian
├── boss_citadel_warden
├── boss_twilight_lord
├── boss_eternal_scribe
├── boss_fen_seer
└── boss_sunlord
```

### Track 5: Professional Skills

```
Coding
├── code_variables
├── code_keywords
├── code_syntax
└── code_master

Business
├── common_words
├── mixed_case (CamelCase)
└── email_patterns
```

## Lesson Introduction Template

Each lesson introduction should include:

```json
{
  "lesson_id": {
    "speaker": "Elder Lyra",
    "title": "Display Title",
    "lines": [
      "Opening narrative/motivation",
      "Brief explanation of new keys/skills",
      "Encouragement or tip"
    ],
    "finger_guide": {
      "new_keys": ["q", "p"],
      "finger_assignments": {
        "q": "left pinky",
        "p": "right pinky"
      }
    },
    "practice_tip": "Focus on keeping your wrists straight and fingers curved.",
    "prerequisites": ["previous_lesson_id"],
    "difficulty": "beginner|intermediate|advanced|expert"
  }
}
```

## Implementation Tasks

### Phase 1: Core Curriculum Guides
1. [ ] Add introductions for training_basics, training_rhythm
2. [ ] Add introductions for capitals_1, capitals_2
3. [ ] Add introduction for punctuation_2
4. [ ] Add introduction for symbols_2
5. [ ] Add introductions for gauntlet_speed/endurance/chaos

### Phase 2: Finger Training Guides
6. [ ] Add introductions for finger_gym_left, finger_gym_right
7. [ ] Add introductions for weak_fingers, pinky_power, ring_finger_focus
8. [ ] Add introduction for alternating_hands

### Phase 3: Pattern Guides
9. [ ] Add introductions for bigram_flow, double_letters
10. [ ] Add introductions for consonant_clusters, vowel_flow
11. [ ] Add introduction for rhythm_words

### Phase 4: Themed Content Guides
12. [ ] Add introductions for twilight lessons (3)
13. [ ] Add introductions for realm lessons (9)
14. [ ] Add introductions for boss lessons (6)

### Phase 5: Challenge Mode Guides
15. [ ] Add introductions for precision lessons (3)
16. [ ] Add introductions for time trial lessons (2)
17. [ ] Add introductions for legendary lessons (3)

### Phase 6: Professional Skills Guides
18. [ ] Add introductions for coding lessons (4)
19. [ ] Add introductions for specialty lessons (common_words, mixed_case, email_patterns)

### Phase 7: Biome Wordlist Guides
20. [ ] Add introductions for biome lessons (4)

## Story Integration

### Act-to-Lesson Mapping

| Act | Days | Lessons | Theme |
|-----|------|---------|-------|
| 1 | 1-4 | home_row_1/2 | Foundation |
| 2 | 5-8 | reach_row_1/2, upper_row_1 | Expansion |
| 3 | 9-12 | bottom_row_1/2, mixed_rows | Depth |
| 4 | 13-16 | speed_alpha, full_alpha, nexus_blend | Speed |
| 5 | 17-20 | numbers_1, apex_mastery | Mastery |

### Boss Lesson Mapping

| Boss | Day | Recommended Lesson |
|------|-----|-------------------|
| Shadow Scout | 4 | boss_grove_guardian |
| Storm Wraith | 8 | boss_citadel_warden |
| Stone Golem | 12 | boss_twilight_lord |
| Typhos General | 16 | boss_eternal_scribe |
| Void Tyrant | 20 | boss_fen_seer or boss_sunlord |

## Pedagogical Principles

### 1. Progressive Complexity
- Start with home row only
- Add one row at a time
- Increase word length gradually
- Introduce special characters after alphabet mastery

### 2. Accuracy Before Speed
- Beginners should aim for 90%+ accuracy
- Speed naturally increases with accuracy
- Provide feedback that emphasizes accuracy first

### 3. Finger Assignment Clarity
- Every new key introduction includes finger assignment
- Visual keyboard display shows correct fingers
- Practice mode isolates individual key drills

### 4. Positive Reinforcement
- Celebrate progress milestones
- Frame errors as learning opportunities
- Provide specific, actionable feedback

### 5. Contextual Learning
- Tie lessons to story progression
- Use thematic wordlists (fantasy vocabulary)
- Make practice feel like gameplay

## Metrics for Success

### Lesson Effectiveness
- Average accuracy per lesson
- Completion rate per lesson
- Time to mastery (80%+ accuracy, 3+ completions)

### Curriculum Coverage
- % of lessons with introductions
- % of lessons with finger guides
- Player coverage (how many lessons are attempted)

### Player Progression
- Average WPM increase per act
- Average accuracy increase per act
- Lesson unlock rate

## Dependencies

- `data/lessons.json` - lesson definitions
- `data/story.json` - lesson introductions
- `game/story_manager.gd` - introduction retrieval
- `game/kingdom_defense.gd` - lesson integration

## References

- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/TYPING_PEDAGOGY.md`
- `docs/ROADMAP.md` (P1-CNT-001)
- `data/story.json` (lesson_introductions section)
