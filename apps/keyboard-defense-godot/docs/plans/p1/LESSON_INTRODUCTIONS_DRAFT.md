# Draft Lesson Introductions

**Created:** 2026-01-08

These lesson introductions are ready to be added to `data/story.json` in the `lesson_introductions` section.

## Priority 1: Training & Foundation

### training_basics

```json
"training_basics": {
  "speaker": "Elder Lyra",
  "title": "First Steps",
  "lines": [
    "Welcome, young defender. Before you can protect the kingdom, you must learn the fundamentals.",
    "Place your left hand on A, S, D, and F. Feel the small bump on F? That's your guide home.",
    "These four keys are your foundation. Master them, and all else will follow."
  ],
  "finger_guide": {
    "new_keys": ["a", "s", "d", "f"],
    "finger_assignments": {
      "a": "left pinky",
      "s": "left ring",
      "d": "left middle",
      "f": "left index"
    }
  },
  "practice_tip": "Keep your wrist straight and fingers curved like you're holding a small ball.",
  "difficulty": "beginner"
}
```

### training_rhythm

```json
"training_rhythm": {
  "speaker": "Elder Lyra",
  "title": "Finding Your Rhythm",
  "lines": [
    "Now we add the right hand. J, K, L join your arsenal of keys.",
    "Feel the bump on J - it mirrors F on the left. These bumps are your anchors.",
    "Typing is like music. Find a steady rhythm and let your fingers dance."
  ],
  "finger_guide": {
    "new_keys": ["j", "k", "l"],
    "finger_assignments": {
      "j": "right index",
      "k": "right middle",
      "l": "right ring"
    }
  },
  "practice_tip": "Try typing to a mental beat - steady tempo builds speed naturally.",
  "difficulty": "beginner"
}
```

## Priority 2: Capitals

### capitals_1

```json
"capitals_1": {
  "speaker": "Elder Lyra",
  "title": "The Shift of Power",
  "lines": [
    "Capital letters announce importance - the names of heroes, the start of sentences.",
    "Use your pinky to hold Shift while another finger presses the letter.",
    "The secret: use the OPPOSITE hand's Shift. Right hand letter? Left Shift. Left hand letter? Right Shift."
  ],
  "finger_guide": {
    "new_keys": ["A", "S", "D", "F", "J", "K", "L"],
    "finger_assignments": {
      "shift_left": "left pinky",
      "shift_right": "right pinky"
    }
  },
  "practice_tip": "Press Shift before the letter, release after. Never same-hand Shift + letter.",
  "difficulty": "intermediate"
}
```

### capitals_2

```json
"capitals_2": {
  "speaker": "Elder Lyra",
  "title": "Capital Mastery",
  "lines": [
    "With full capital command, you can write proper names and titles with authority.",
    "CamelCase, SHOUTING, Proper Nouns - all are within your grasp.",
    "Speed comes from smooth Shift transitions. Practice makes permanent."
  ],
  "finger_guide": {
    "new_keys": ["all capitals"],
    "finger_assignments": {
      "technique": "opposite hand shift"
    }
  },
  "practice_tip": "Practice typing your name with proper capitalization until it feels natural.",
  "difficulty": "intermediate"
}
```

## Priority 3: Extended Characters

### punctuation_2

```json
"punctuation_2": {
  "speaker": "Elder Lyra",
  "title": "Punctuation Mastery",
  "lines": [
    "Question marks, exclamation points, hyphens - the tools of expression.",
    "These keys require Shift or reach, but they give your words power.",
    "A well-placed exclamation can rally troops. A question can probe enemy weakness."
  ],
  "finger_guide": {
    "new_keys": ["!", "?", "-"],
    "finger_assignments": {
      "!": "left pinky (Shift+1)",
      "?": "right pinky (Shift+/)",
      "-": "right pinky"
    }
  },
  "practice_tip": "! and ? require Shift - remember opposite-hand technique.",
  "difficulty": "intermediate"
}
```

### symbols_2

```json
"symbols_2": {
  "speaker": "Elder Lyra",
  "title": "Symbol Mastery",
  "lines": [
    "Brackets, braces, and special symbols - the arcane runes of the keyboard.",
    "These keys are used by scribes and code-weavers alike.",
    "Master them, and no inscription will be beyond your skill."
  ],
  "finger_guide": {
    "new_keys": ["[", "]", "{", "}"],
    "finger_assignments": {
      "[": "right pinky",
      "]": "right pinky",
      "{": "right pinky (Shift+[)",
      "}": "right pinky (Shift+])"
    }
  },
  "practice_tip": "Bracket pairs always match - [ with ], { with }. Practice them together.",
  "difficulty": "advanced"
}
```

## Priority 4: Gauntlets

### gauntlet_speed

```json
"gauntlet_speed": {
  "speaker": "Elder Lyra",
  "title": "The Speed Gauntlet",
  "lines": [
    "Speed! Raw, unrelenting speed!",
    "Short words will fly at you. React instantly. Trust your fingers.",
    "This is not about perfect form - this is about survival reflexes."
  ],
  "finger_guide": null,
  "practice_tip": "Don't think - react. Let muscle memory take over.",
  "difficulty": "advanced"
}
```

### gauntlet_endurance

```json
"gauntlet_endurance": {
  "speaker": "Elder Lyra",
  "title": "The Endurance Gauntlet",
  "lines": [
    "Long words. Sustained focus. The true test of a keyboard warrior.",
    "Each word is a marathon. Pace yourself. Breathe.",
    "Accuracy matters more than speed here. One mistake costs precious time."
  ],
  "finger_guide": null,
  "practice_tip": "Read the whole word before you start typing. Plan your fingers' path.",
  "difficulty": "advanced"
}
```

### gauntlet_chaos

```json
"gauntlet_chaos": {
  "speaker": "Elder Lyra",
  "title": "The Chaos Gauntlet",
  "lines": [
    "Letters. Numbers. Symbols. Everything. All at once.",
    "This is the ultimate test. No pattern. No mercy. Pure chaos.",
    "If you survive this, you can survive anything the Typhos Horde throws at you."
  ],
  "finger_guide": null,
  "practice_tip": "Stay calm. Chaos is just complexity you haven't mastered yet.",
  "difficulty": "expert"
}
```

## Priority 5: Finger Training

### finger_gym_left

```json
"finger_gym_left": {
  "speaker": "Elder Lyra",
  "title": "Left Hand Forge",
  "lines": [
    "Your left hand guards the western keys. Today we strengthen it.",
    "Q, W, E, R, T - A, S, D, F, G - Z, X, C, V, B. All yours to command.",
    "A chain is only as strong as its weakest link. Find your weak fingers and forge them strong."
  ],
  "finger_guide": {
    "new_keys": ["all left hand"],
    "finger_assignments": {
      "columns": "pinky: QAZ, ring: WSX, middle: EDC, index: RFVTGB"
    }
  },
  "practice_tip": "Pay special attention to your pinky - it's often the weakest.",
  "difficulty": "intermediate"
}
```

### finger_gym_right

```json
"finger_gym_right": {
  "speaker": "Elder Lyra",
  "title": "Right Hand Forge",
  "lines": [
    "Your right hand guards the eastern keys. Now we strengthen it.",
    "Y, U, I, O, P - H, J, K, L, ; - N, M and the punctuation marks.",
    "Balance between hands creates harmony. Neither should dominate."
  ],
  "finger_guide": {
    "new_keys": ["all right hand"],
    "finger_assignments": {
      "columns": "index: YUHJNM, middle: IK,, ring: OL., pinky: P;/"
    }
  },
  "practice_tip": "Right pinky handles many keys - give it extra attention.",
  "difficulty": "intermediate"
}
```

### weak_fingers

```json
"weak_fingers": {
  "speaker": "Elder Lyra",
  "title": "Pinky Strengthening",
  "lines": [
    "Your pinkies are small but mighty. They guard the outer keys.",
    "Q, A, Z on the left. P, ;, / on the right. The edges of your domain.",
    "Weak pinkies slow your typing. Strong pinkies unlock true speed."
  ],
  "finger_guide": {
    "new_keys": ["q", "a", "z", "p", ";", "/"],
    "finger_assignments": {
      "q": "left pinky",
      "a": "left pinky",
      "z": "left pinky",
      "p": "right pinky",
      ";": "right pinky",
      "/": "right pinky"
    }
  },
  "practice_tip": "Isolate pinky practice - short sessions, frequent breaks.",
  "difficulty": "intermediate"
}
```

### pinky_power

```json
"pinky_power": {
  "speaker": "Elder Lyra",
  "title": "Pinky Power",
  "lines": [
    "Intensive pinky training begins now.",
    "These small fingers control crucial territory - don't let them be your weakness.",
    "Short bursts of focused practice build pinky strength faster than marathon sessions."
  ],
  "finger_guide": {
    "new_keys": ["q", "a", "z", "p"],
    "finger_assignments": {
      "q": "left pinky",
      "a": "left pinky",
      "z": "left pinky",
      "p": "right pinky"
    }
  },
  "practice_tip": "Stretch your pinkies between drills to prevent strain.",
  "difficulty": "intermediate"
}
```

### ring_finger_focus

```json
"ring_finger_focus": {
  "speaker": "Elder Lyra",
  "title": "Ring Finger Focus",
  "lines": [
    "Ring fingers often lack independence - they want to follow their neighbors.",
    "W, S, X on the left. O, L, period on the right.",
    "Train them to move alone and your typing will flow like water."
  ],
  "finger_guide": {
    "new_keys": ["w", "s", "x", "o", "l", "."],
    "finger_assignments": {
      "w": "left ring",
      "s": "left ring",
      "x": "left ring",
      "o": "right ring",
      "l": "right ring",
      ".": "right ring"
    }
  },
  "practice_tip": "Practice lifting only your ring finger while keeping others still.",
  "difficulty": "intermediate"
}
```

### alternating_hands

```json
"alternating_hands": {
  "speaker": "Elder Lyra",
  "title": "Hand Alternation",
  "lines": [
    "The fastest typists alternate hands smoothly - left, right, left, right.",
    "While one hand types, the other prepares. No wasted motion.",
    "Words that alternate hands naturally flow faster. Learn to feel the rhythm."
  ],
  "finger_guide": null,
  "practice_tip": "Words like 'their', 'world', 'right' alternate hands - notice how fast they feel.",
  "difficulty": "intermediate"
}
```

## Priority 6: Coding Lessons

### code_variables

```json
"code_variables": {
  "speaker": "Elder Lyra",
  "title": "The Scribe's Variables",
  "lines": [
    "Code-weavers name their spells with variables - descriptive names that hold power.",
    "Underscores connect words. camelCase blends them. Both are common in the arcane arts.",
    "Practice these patterns and you'll transcribe code with ease."
  ],
  "finger_guide": {
    "new_keys": ["_"],
    "finger_assignments": {
      "_": "right pinky (Shift+-)"
    }
  },
  "practice_tip": "user_name, firstName, maxValue - these patterns appear constantly in code.",
  "difficulty": "intermediate"
}
```

### code_keywords

```json
"code_keywords": {
  "speaker": "Elder Lyra",
  "title": "Keywords of Power",
  "lines": [
    "Every spell has keywords - if, else, for, while, return.",
    "These words command the flow of magic. Type them until they become instinct.",
    "Speed with keywords separates apprentices from masters."
  ],
  "finger_guide": null,
  "practice_tip": "The most common keywords are short - 'if', 'for', 'var'. Drill them fast.",
  "difficulty": "intermediate"
}
```

### code_syntax

```json
"code_syntax": {
  "speaker": "Elder Lyra",
  "title": "Syntax and Structure",
  "lines": [
    "Brackets, parentheses, operators - the grammar of code.",
    "() for functions. {} for blocks. [] for arrays. <> for comparisons.",
    "Master these symbols and you can write any spell."
  ],
  "finger_guide": {
    "new_keys": ["(", ")", "{", "}", "[", "]", "<", ">", "=", "+", "-", "*", "/"],
    "finger_assignments": {
      "()": "right pinky/ring (Shift+9/0)",
      "{}[]": "right pinky",
      "<>": "right pinky/ring (Shift+,/.)",
      "=+-*/": "various"
    }
  },
  "practice_tip": "Brackets come in pairs - always type both, then fill the middle.",
  "difficulty": "advanced"
}
```

### code_master

```json
"code_master": {
  "speaker": "Elder Lyra",
  "title": "Code Mastery",
  "lines": [
    "You've learned the pieces. Now we combine them all.",
    "Full code sequences - variables, keywords, syntax, numbers - flowing together.",
    "This is the true test of a code-weaver's typing skill."
  ],
  "finger_guide": null,
  "practice_tip": "Read code aloud in your head as you type - it helps with flow.",
  "difficulty": "expert"
}
```

## Priority 7: Boss Lessons

### boss_grove_guardian

```json
"boss_grove_guardian": {
  "speaker": "Elder Lyra",
  "title": "The Grove Guardian Awakens",
  "lines": [
    "The ancient protector of the Evergrove stirs from slumber.",
    "This guardian has watched over the forest for centuries. It will test your foundational skills.",
    "Remember your training. Steady hands defeat ancient foes."
  ],
  "finger_guide": null,
  "practice_tip": "Boss battles are marathons - pace yourself and stay accurate.",
  "difficulty": "intermediate"
}
```

### boss_citadel_warden

```json
"boss_citadel_warden": {
  "speaker": "Elder Lyra",
  "title": "The Citadel Warden",
  "lines": [
    "The Warden of the Citadel blocks your path. A formidable guardian.",
    "It will throw the full alphabet at you. No hiding behind simple keys.",
    "You've trained for this. Show the Warden what you've learned."
  ],
  "finger_guide": null,
  "practice_tip": "Full alphabet coverage required - warm up all fingers before this fight.",
  "difficulty": "advanced"
}
```

### boss_twilight_lord

```json
"boss_twilight_lord": {
  "speaker": "Elder Lyra",
  "title": "The Twilight Lord",
  "lines": [
    "Between light and shadow stands the Twilight Lord.",
    "This master of duality will test your speed AND accuracy. Neither alone will suffice.",
    "Find balance in your typing, and you will find victory."
  ],
  "finger_guide": null,
  "practice_tip": "Don't sacrifice accuracy for speed - the Twilight Lord punishes mistakes.",
  "difficulty": "advanced"
}
```

### boss_eternal_scribe

```json
"boss_eternal_scribe": {
  "speaker": "Elder Lyra",
  "title": "The Eternal Scribe",
  "lines": [
    "The keeper of all written knowledge challenges you.",
    "Punctuation, symbols, the full breadth of the keyboard - the Scribe commands it all.",
    "Prove that your typing wisdom matches your speed."
  ],
  "finger_guide": null,
  "practice_tip": "The Scribe uses punctuation heavily - warm up your pinky Shift technique.",
  "difficulty": "expert"
}
```

### boss_fen_seer

```json
"boss_fen_seer": {
  "speaker": "Elder Lyra",
  "title": "The Fen Seer",
  "lines": [
    "In the mists of Mistfen, the Seer awaits. They see all possibilities.",
    "Brackets, braces, the symbols of prophecy - the Seer speaks in code.",
    "Decode their words faster than they can speak them."
  ],
  "finger_guide": null,
  "practice_tip": "Heavy symbol usage - practice bracket pairs before this battle.",
  "difficulty": "expert"
}
```

### boss_sunlord

```json
"boss_sunlord": {
  "speaker": "Elder Lyra",
  "title": "The Sunlord Champion",
  "lines": [
    "The blazing champion of Sunfields stands before you, radiant with power.",
    "Speed is the Sunlord's weapon. Match it or be burned.",
    "This is a test of pure typing velocity. Let your fingers fly like flames."
  ],
  "finger_guide": null,
  "practice_tip": "Speed is everything here - accuracy matters less. Go fast!",
  "difficulty": "expert"
}
```

## Implementation Notes

To add these to story.json:

1. Open `data/story.json`
2. Find the `"lesson_introductions"` section
3. Add each lesson object inside the section
4. Validate JSON syntax
5. Test in-game that introductions appear correctly

Example merge:

```json
"lesson_introductions": {
  "home_row_1": { ... existing ... },
  "training_basics": { ... new from above ... },
  "training_rhythm": { ... new from above ... },
  ...
}
```
