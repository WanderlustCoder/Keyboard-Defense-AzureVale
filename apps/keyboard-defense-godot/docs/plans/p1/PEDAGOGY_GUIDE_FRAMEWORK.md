# Pedagogy Guide Framework

**Created:** 2026-01-08

This document establishes the educational framework and content guidelines for typing instruction in Keyboard Defense.

## Educational Philosophy

### Core Principles

1. **Accuracy First, Speed Follows**
   - New typists should not worry about speed
   - 90% accuracy threshold before introducing speed goals
   - Speed naturally improves with muscle memory

2. **Proper Technique Prevents Injury**
   - Correct finger placement from day one
   - Ergonomic posture reminders
   - Encourage breaks and hand stretches

3. **Incremental Complexity**
   - One new concept per lesson
   - Build on previous knowledge
   - Provide scaffolding for challenging keys

4. **Positive Reinforcement**
   - Celebrate small wins
   - Frame mistakes as learning data
   - Never punish or shame errors

5. **Contextual Motivation**
   - Connect lessons to game progression
   - Use fantasy vocabulary for engagement
   - Make practice feel like play

## Finger Assignment Reference

### Standard QWERTY Layout

```
Left Hand                              Right Hand
┌─────┬─────┬─────┬─────┬─────┐      ┌─────┬─────┬─────┬─────┬─────┐
│  Q  │  W  │  E  │  R  │  T  │      │  Y  │  U  │  I  │  O  │  P  │
│ LP  │ LR  │ LM  │ LI  │ LI  │      │ RI  │ RI  │ RM  │ RR  │ RP  │
├─────┼─────┼─────┼─────┼─────┤      ├─────┼─────┼─────┼─────┼─────┤
│  A  │  S  │  D  │  F  │  G  │      │  H  │  J  │  K  │  L  │  ;  │
│ LP  │ LR  │ LM  │ LI  │ LI  │      │ RI  │ RI  │ RM  │ RR  │ RP  │
├─────┼─────┼─────┼─────┼─────┤      ├─────┼─────┼─────┼─────┼─────┤
│  Z  │  X  │  C  │  V  │  B  │      │  N  │  M  │  ,  │  .  │  /  │
│ LP  │ LR  │ LM  │ LI  │ LI  │      │ RI  │ RI  │ RM  │ RR  │ RP  │
└─────┴─────┴─────┴─────┴─────┘      └─────┴─────┴─────┴─────┴─────┘

LP = Left Pinky    RI = Right Index
LR = Left Ring     RM = Right Middle
LM = Left Middle   RR = Right Ring
LI = Left Index    RP = Right Pinky
```

### Number Row

```
┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐
│  1  │  2  │  3  │  4  │  5  │  6  │  7  │  8  │  9  │  0  │
│ LP  │ LR  │ LM  │ LI  │ LI  │ RI  │ RI  │ RM  │ RR  │ RP  │
└─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘
```

### Shift Key Usage
- Left Shift: Press with left pinky for right-hand letters
- Right Shift: Press with right pinky for left-hand letters
- Never use the same hand for Shift + letter

## Guide Content Templates

### Lesson Introduction Template

```json
{
  "speaker": "Elder Lyra",
  "title": "[Lesson Display Name]",
  "lines": [
    "[Narrative hook connecting to story]",
    "[Explanation of new keys/concepts]",
    "[Encouragement and motivation]"
  ],
  "finger_guide": {
    "new_keys": ["key1", "key2"],
    "finger_assignments": {
      "key1": "left ring",
      "key2": "right index"
    }
  },
  "practice_tip": "[Specific actionable advice]",
  "common_mistakes": [
    "[Mistake 1 and how to avoid]",
    "[Mistake 2 and how to avoid]"
  ],
  "difficulty": "beginner|intermediate|advanced|expert"
}
```

### Example: Home Row Introduction

```json
{
  "speaker": "Elder Lyra",
  "title": "The Foundation",
  "lines": [
    "The home row is where all keyboard magic begins.",
    "Rest your fingers on ASDF with your left hand, and JKL; with your right.",
    "Feel the small bump on F and J - these guide your index fingers home."
  ],
  "finger_guide": {
    "new_keys": ["a", "s", "d", "f", "j", "k", "l", ";"],
    "finger_assignments": {
      "a": "left pinky",
      "s": "left ring",
      "d": "left middle",
      "f": "left index",
      "j": "right index",
      "k": "right middle",
      "l": "right ring",
      ";": "right pinky"
    }
  },
  "practice_tip": "Keep your wrists straight and let your fingers curve naturally over the keys.",
  "common_mistakes": [
    "Looking at the keyboard - trust your fingers to find the keys",
    "Pressing too hard - a light touch is faster and less tiring"
  ],
  "difficulty": "beginner"
}
```

### Example: Reach Row Introduction

```json
{
  "speaker": "Elder Lyra",
  "title": "Reaching Beyond",
  "lines": [
    "Now we venture beyond the home row to keys above.",
    "Your fingers will reach up to find E, R, T, and other letters.",
    "Return to home position after each reach - that's the key to accuracy."
  ],
  "finger_guide": {
    "new_keys": ["e", "r", "t", "y", "u", "i", "o"],
    "finger_assignments": {
      "e": "left middle",
      "r": "left index",
      "t": "left index",
      "y": "right index",
      "u": "right index",
      "i": "right middle",
      "o": "right ring"
    }
  },
  "practice_tip": "After pressing a reach key, return your finger to its home position immediately.",
  "common_mistakes": [
    "Lifting your whole hand - only the finger pressing should move",
    "Losing home position - always return to ASDF/JKL;"
  ],
  "difficulty": "beginner"
}
```

## Typing Tips Library

### Posture Tips
- Keep your back straight and shoulders relaxed
- Elbows at 90 degrees, wrists straight
- Screen at eye level, keyboard at elbow height
- Feet flat on the floor

### Technique Tips
- Use the correct finger for each key
- Press keys with fingertips, not pads
- Use a light, bouncy touch
- Keep unused fingers resting on home row

### Practice Tips
- Short, frequent sessions beat long marathons
- Focus on accuracy before speed
- Take breaks every 20-30 minutes
- Stretch your hands and wrists regularly

### Rhythm Tips
- Aim for even timing between keystrokes
- Don't rush - steady typing is faster than bursts
- Breathe normally while typing
- Let mistakes go - keep the rhythm flowing

### Advanced Tips
- Look at the screen, not the keyboard
- Trust your muscle memory
- Anticipate the next letter while typing
- Practice difficult combinations in isolation

## Feedback Messages

### Accuracy Feedback

| Accuracy | Message |
|----------|---------|
| 95-100% | "Perfect precision! Your keystrokes ring true." |
| 90-94% | "Excellent accuracy! A few small slips won't stop you." |
| 80-89% | "Good work! Focus on the tricky keys and you'll master them." |
| 70-79% | "Keep practicing! Accuracy improves with each battle." |
| <70% | "Slow down a bit. Accuracy is more important than speed right now." |

### Speed Feedback

| WPM | Level | Message |
|-----|-------|---------|
| 60+ | Expert | "Lightning fast! You type like a true master." |
| 45-59 | Advanced | "Swift keystrokes! Your speed serves you well." |
| 30-44 | Intermediate | "Steady pace! Speed will come with practice." |
| 15-29 | Beginner | "Building momentum! Focus on accuracy first." |
| <15 | Novice | "Take your time. Every journey begins with a single keystroke." |

### Combo Feedback

| Combo | Message |
|-------|---------|
| 5 | "Nice streak!" |
| 10 | "You're on fire!" |
| 15 | "Unstoppable!" |
| 20 | "LEGENDARY!" |
| 25+ | "BEYOND LEGENDARY!" |

### Milestone Messages

| Milestone | Message |
|-----------|---------|
| First word | "Your first word! The journey begins." |
| 10 words | "Ten words strong! Keep going." |
| First lesson complete | "Lesson mastered! New skills unlocked." |
| First boss defeated | "The boss falls! Your typing prowess grows." |
| 100 WPM reached | "Triple digits! You've joined the elite." |

## Lesson Progression Rules

### Unlock Criteria

| Next Lesson | Requires |
|-------------|----------|
| home_row_2 | home_row_1 at 80%+ accuracy |
| reach_row_1 | home_row_2 at 85%+ accuracy |
| reach_row_2 | reach_row_1 at 80%+ accuracy |
| bottom_row_1 | reach_row_2 at 80%+ accuracy |
| numbers_1 | full_alpha at 80%+ accuracy |
| gauntlet_* | apex_mastery at 75%+ accuracy |

### Difficulty Scaling

| Difficulty | Word Length | Enemy Speed | Accuracy Goal |
|------------|-------------|-------------|---------------|
| Beginner | 3-5 letters | Slow | 80% |
| Intermediate | 4-7 letters | Normal | 85% |
| Advanced | 5-9 letters | Fast | 90% |
| Expert | 6-12 letters | Very Fast | 95% |

## Implementation Checklist

### story.json Updates
- [ ] Add lesson_introductions for all 80+ lessons
- [ ] Include finger_guide for lessons introducing new keys
- [ ] Add practice_tip for each lesson
- [ ] Set difficulty level for each lesson

### story_manager.gd Updates
- [ ] Add get_finger_guide(lesson_id) function
- [ ] Add get_practice_tip(lesson_id) function
- [ ] Add get_difficulty(lesson_id) function
- [ ] Support difficulty-based word length scaling

### UI Updates
- [ ] Display finger assignments in keyboard_display.gd
- [ ] Show practice tips in lesson selection
- [ ] Visual indicator for lesson difficulty
- [ ] Progress tracking per lesson

## References

- `docs/plans/p1/LESSON_GUIDE_PLAN.md` - Lesson inventory and gaps
- `data/lessons.json` - Lesson definitions
- `data/story.json` - Current lesson introductions
- `game/story_manager.gd` - Story/lesson integration
