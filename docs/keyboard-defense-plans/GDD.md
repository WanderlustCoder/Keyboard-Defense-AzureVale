# Keyboard Defense (Godot) - Game Design Document (GDD)

## 1) High-level overview
Keyboard Defense is a fantasy kingdom typing trainer with a campaign map and
battle drills. The loop is:
1. Choose a map node.
2. Fight a typing-driven battle using drill steps.
3. Earn performance-based rewards.
4. Spend gold on kingdom/unit upgrades.
5. Unlock new nodes and repeat.

The game teaches typing through:
- focused word packs per lesson,
- short, readable drills with feedback, and
- performance tiers that reward accuracy and rhythm.

## 2) Design goals and non-goals
### Goals
- Make deliberate typing practice feel like a heroic defense.
- Keep battles readable and repeatable for learning.
- Tie accuracy and WPM to tangible progression without hard gates.

### Non-goals
- Not a twitch action game.
- Not a pure typing tutor with no gameplay stakes.

## 3) Core game loop
### 3.1 Campaign structure
- Start on the campaign map.
- Each node references a lesson and a drill template.
- Battles run through a drill plan (lesson, targets, intermission).
- Victory grants gold and unlocks new routes.
- Defeat records a performance summary and offers a retry.

### 3.2 Battle pacing targets
- Drill steps: 4 to 6 per battle in early content.
- Intermissions: 2.0 to 3.0 seconds for reset.
- Overall battle: 2 to 4 minutes for early nodes.

## 4) Economy and rewards
### 4.1 Core resource
- Gold is the main currency for upgrades.

### 4.2 Reward model
- Practice gold is always awarded for completing a battle.
- First-clear reward adds a larger bonus.
- Performance tier (C/B/A/S) adds extra gold.

### 4.3 Typing linkage
- Accuracy and WPM determine the tier bonus.
- Bonus gold is sublinear to avoid forcing speed.

## 5) Defense (battle phase)
### 5.1 Threat model
- Threat rises over time and on mistakes.
- Correct typing relieves threat.
- Castle health decreases when threat breaches.

### 5.2 Intervention effects
- Correct words fire projectiles and grant relief.
- Streaks trigger buffs that boost typing power or slow threat.
- Intermissions provide recovery windows.

## 6) Typing pedagogy
### 6.1 Curriculum
- Start with home-row word packs.
- Expand to reach-row and upper-row lessons.
- Introduce longer words and mixed patterns gradually.

### 6.2 Adaptivity (future)
- Track weak letters and bigrams.
- Adjust target lists to emphasize weaknesses.
- Offer optional drills with rewards for focused practice.

## 7) Controls and UX
- Battles are keyboard-first; typing is the main interaction.
- ESC pauses and freezes timers.
- F1 opens a debug drill override panel for rapid iteration.
- UI emphasizes readability and calm feedback.

## 8) Content (current scope)
- Campaign nodes: forest gate through frost crown.
- Lessons: home row, reach row, upper row sequences.
- Upgrades: typing power, threat slow, forgiveness, castle health.

## 9) Win/lose and progression
- Victory: node completion, rewards, unlocks.
- Defeat: no unlock, record attempt, immediate retry option.
- Progression persists via save data.

## 10) Monetization
- Avoid pay-to-win mechanics.
- Prefer a single-purchase model if monetized.
