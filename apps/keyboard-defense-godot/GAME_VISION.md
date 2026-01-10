# Keyboard Defense - Game Vision & Design Bible

This document consolidates the core design vision for Claude Code reference. When making design decisions, refer back to these pillars.

## One-Liner

A typing-first fantasy kingdom defense trainer where battles are won by clean keystrokes, and campaign progress unlocks upgrades that make your typing power feel tangible.

## Player Fantasy

- "My typing skill protects the kingdom."
- "Accuracy and rhythm matter as much as speed."
- "Each battle shows measurable improvement, not just a score."

## Design Pillars (In Priority Order)

### 1. Typing is the Primary Skill AND Primary Input
- Every meaningful action comes from typing
- No mouse-required mechanics in core gameplay
- Typing quality (accuracy, rhythm) matters more than raw speed
- The keyboard IS the controller

### 2. Battles are Paced for Learning, Not Punishment
- Readable word displays with clear feedback
- Intermissions and breaks built into battle flow
- Mistakes are learning opportunities, not harsh penalties
- Difficulty curves teach rather than gatekeep

### 3. Progression is Clear: Map → Battle → Rewards → Upgrades
- Players always know what to do next
- Rewards feel earned and meaningful
- Upgrades provide tangible power increases
- No hidden mechanics or obscure systems

### 4. Accessibility and Clarity Over Twitch Mechanics
- High contrast, readable UI
- Adjustable speeds and difficulty
- No time-pressure that punishes slow typists unfairly
- Works for beginners through experts

## Core Loop

```
1. Choose a map node (lesson/battle)
2. Fight typing-driven battle (drill steps)
3. Earn performance-based rewards
4. Spend gold on kingdom/unit upgrades
5. Unlock new nodes and repeat
```

## What This Game IS

- A typing tutor disguised as a game
- A kingdom defense game powered by typing
- An edutainment experience where gameplay IS the reward
- A single-player progression-focused experience
- A feel-good power fantasy where typing = strength

## What This Game IS NOT

- A twitch action game requiring lightning reflexes
- A pure typing tutor with no gameplay stakes
- A competitive multiplayer game
- A free-to-play grind with pay-to-win
- A roguelike with permadeath frustration

## Inspirations

### Super Fantasy Kingdom
- Day/night cadence (build by day, defend at night)
- Resource chains and workforce allocation
- Roguelite meta progression with unlocks
- Pixel-art strategy presentation
- Clear silhouettes and readable UI

### Typing of the Dead / Epistory
- Typing as core combat mechanic
- Words attached to enemies
- Satisfying keystroke feedback
- Progressive difficulty based on typing skill

## Key Mechanics

### Typing Combat
- Words appear on enemies or as prompts
- Correct typing = attacks/actions
- Mistakes increase threat or have penalties
- Combos reward consistent accuracy

### Threat System
- Threat rises over time and on mistakes
- Correct typing relieves threat
- Castle health decreases when threat breaches
- Creates tension without frustration

### Intervention Effects
- Correct words fire projectiles
- Streaks trigger buffs (typing power, slow threat)
- Visual feedback shows impact of typing
- Powers scale with typing performance

### Curriculum/Lessons
- Start with home row (ASDF JKL;)
- Expand to reach row (QWERTY UIOP)
- Add bottom row (ZXCVBNM)
- Progress to full alphabet, numbers, symbols
- Each lesson has focused word packs

## Economy Principles

### Gold (Primary Currency)
- Earned through battle completion
- First-clear bonuses for new content
- Performance tier bonuses (C/B/A/S)
- NO real-money purchases

### Progression
- Practice gold always awarded (no empty-handed losses)
- Performance bonuses are sublinear (don't force speed)
- Upgrades provide meaningful but not mandatory boosts
- All content achievable through normal play

## Visual Style

### Art Direction
- Modern pixel art (32px base grid)
- Clear silhouettes readable at small sizes
- Consistent top-left lighting
- Limited color palette for cohesion

### UI Principles
- High contrast text on backgrounds
- Large, readable fonts for words
- Minimal clutter during combat
- Important info always visible

### Feedback
- Immediate keystroke response (< 16ms)
- Clear correct/incorrect indicators
- Satisfying hit effects
- Combo visuals that scale with performance

## Audio Direction

### Typing Sounds
- Satisfying mechanical key sounds
- Pitch variation for interest
- Different sounds for correct/incorrect
- Volume adjustable independently

### Music
- Calm during planning/map phases
- Intensifying during battles
- Dynamic based on threat level
- Never overwhelming or distracting

### SFX
- Clear, distinct sounds per action type
- Enemies have characteristic sounds
- Victory/defeat stings
- UI feedback sounds

## Pacing Targets

### Battle Duration
- Early battles: 2-4 minutes
- Mid-game battles: 4-6 minutes
- Boss battles: 6-10 minutes
- Never feels like a slog

### Drill Steps
- 4-6 steps per early battle
- Intermissions: 2-3 seconds
- Wave breaks for recovery
- Natural stopping points

### Session Length
- Meaningful progress in 15-30 minutes
- Can quit between any battle
- Auto-save preserves progress
- Respects player time

## Difficulty Philosophy

### Accessibility First
- Story mode for learning (reduced pressure)
- Adventure mode for balanced challenge
- Champion/Nightmare for experienced typists
- All modes complete the same content

### Adaptive Elements
- Word difficulty scales with performance
- Timing windows adjust to skill
- Never punish improvement with harder content immediately
- Let players feel their growth

### No Hard Gates
- All content reachable regardless of WPM
- Practice makes progress, always
- Skill expression in performance tier, not completion
- Struggle is optional, not required

## Content Philosophy

### Story
- Light narrative connecting regions
- NPCs with personality and tips
- Lore discoverable but not mandatory
- Motivates without blocking

### Lessons
- Educational value is real
- Fun disguises the learning
- Progress tracking shows improvement
- Achievements celebrate milestones

### Replayability
- Multiple difficulty modes
- Score chasing for competitive players
- Mastery challenges for experts
- New runs can try different strategies

---

## Quick Decision Framework

When unsure about a design choice, ask:

1. **Does this support typing as the core mechanic?**
2. **Is this accessible to beginners while interesting for experts?**
3. **Does this create clear, tangible progression?**
4. **Would this frustrate or delight a player trying to improve?**

If a feature doesn't clearly support these, reconsider it.
