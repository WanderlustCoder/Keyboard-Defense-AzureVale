# Finger Guide Reference

This document provides the canonical finger assignments for all keyboard keys, used by lesson introductions and the keyboard display.

## Standard QWERTY Finger Assignments

### Left Hand

| Finger | Home Key | All Keys |
|--------|----------|----------|
| Pinky | A | Q, A, Z, 1, `, Tab, Caps, Shift, Ctrl |
| Ring | S | W, S, X, 2 |
| Middle | D | E, D, C, 3 |
| Index | F | R, T, F, G, V, B, 4, 5 |

### Right Hand

| Finger | Home Key | All Keys |
|--------|----------|----------|
| Index | J | Y, U, H, J, N, M, 6, 7 |
| Middle | K | I, K, , (comma), 8 |
| Ring | L | O, L, . (period), 9 |
| Pinky | ; | P, ;, /, 0, -, =, [, ], \, ', Enter, Shift, Backspace |

### Thumbs
- Space bar (either thumb)

## Key-to-Finger Mapping (JSON Format)

```json
{
  "finger_map": {
    "q": {"finger": "left_pinky", "hand": "left", "row": "top"},
    "w": {"finger": "left_ring", "hand": "left", "row": "top"},
    "e": {"finger": "left_middle", "hand": "left", "row": "top"},
    "r": {"finger": "left_index", "hand": "left", "row": "top"},
    "t": {"finger": "left_index", "hand": "left", "row": "top"},
    "y": {"finger": "right_index", "hand": "right", "row": "top"},
    "u": {"finger": "right_index", "hand": "right", "row": "top"},
    "i": {"finger": "right_middle", "hand": "right", "row": "top"},
    "o": {"finger": "right_ring", "hand": "right", "row": "top"},
    "p": {"finger": "right_pinky", "hand": "right", "row": "top"},

    "a": {"finger": "left_pinky", "hand": "left", "row": "home"},
    "s": {"finger": "left_ring", "hand": "left", "row": "home"},
    "d": {"finger": "left_middle", "hand": "left", "row": "home"},
    "f": {"finger": "left_index", "hand": "left", "row": "home"},
    "g": {"finger": "left_index", "hand": "left", "row": "home"},
    "h": {"finger": "right_index", "hand": "right", "row": "home"},
    "j": {"finger": "right_index", "hand": "right", "row": "home"},
    "k": {"finger": "right_middle", "hand": "right", "row": "home"},
    "l": {"finger": "right_ring", "hand": "right", "row": "home"},
    ";": {"finger": "right_pinky", "hand": "right", "row": "home"},

    "z": {"finger": "left_pinky", "hand": "left", "row": "bottom"},
    "x": {"finger": "left_ring", "hand": "left", "row": "bottom"},
    "c": {"finger": "left_middle", "hand": "left", "row": "bottom"},
    "v": {"finger": "left_index", "hand": "left", "row": "bottom"},
    "b": {"finger": "left_index", "hand": "left", "row": "bottom"},
    "n": {"finger": "right_index", "hand": "right", "row": "bottom"},
    "m": {"finger": "right_index", "hand": "right", "row": "bottom"},
    ",": {"finger": "right_middle", "hand": "right", "row": "bottom"},
    ".": {"finger": "right_ring", "hand": "right", "row": "bottom"},
    "/": {"finger": "right_pinky", "hand": "right", "row": "bottom"},

    "1": {"finger": "left_pinky", "hand": "left", "row": "number"},
    "2": {"finger": "left_ring", "hand": "left", "row": "number"},
    "3": {"finger": "left_middle", "hand": "left", "row": "number"},
    "4": {"finger": "left_index", "hand": "left", "row": "number"},
    "5": {"finger": "left_index", "hand": "left", "row": "number"},
    "6": {"finger": "right_index", "hand": "right", "row": "number"},
    "7": {"finger": "right_index", "hand": "right", "row": "number"},
    "8": {"finger": "right_middle", "hand": "right", "row": "number"},
    "9": {"finger": "right_ring", "hand": "right", "row": "number"},
    "0": {"finger": "right_pinky", "hand": "right", "row": "number"},

    " ": {"finger": "thumb", "hand": "either", "row": "space"}
  }
}
```

## Lesson Key Progressions

### Stage 1: Home Row
**New Keys:** A, S, D, F, J, K, L, ;

| Key | Finger | Hand |
|-----|--------|------|
| A | Pinky | Left |
| S | Ring | Left |
| D | Middle | Left |
| F | Index | Left |
| J | Index | Right |
| K | Middle | Right |
| L | Ring | Right |
| ; | Pinky | Right |

**Teaching Notes:**
- F and J have tactile bumps for finger positioning
- Emphasize returning to home position after each keystroke
- Pinky keys (A, ;) are hardest - extra practice recommended

### Stage 2: Reach Row (E, R, T, G + Y, U, I, O)
**New Keys:** E, R, T, G, Y, U, I, O

| Key | Finger | Hand | Reach From |
|-----|--------|------|------------|
| E | Middle | Left | D |
| R | Index | Left | F |
| T | Index | Left | F (stretch) |
| G | Index | Left | F (stretch) |
| Y | Index | Right | J (stretch) |
| U | Index | Right | J |
| I | Middle | Right | K |
| O | Ring | Right | L |

**Teaching Notes:**
- Index fingers cover the most keys (F/R/T/G and J/Y/U/H)
- T and Y require a stretch - return to home immediately
- Common mistake: lifting whole hand instead of just finger

### Stage 3: Upper Row (Q, W, P)
**New Keys:** Q, W, P

| Key | Finger | Hand | Reach From |
|-----|--------|------|------------|
| Q | Pinky | Left | A |
| W | Ring | Left | S |
| P | Pinky | Right | ; |

**Teaching Notes:**
- Pinky reaches are challenging
- Q and P are mirror positions
- W is one of the most common letters - drill frequently

### Stage 4: Bottom Row (Z, X, C, V, B, N, M)
**New Keys:** Z, X, C, V, B, N, M

| Key | Finger | Hand | Reach From |
|-----|--------|------|------------|
| Z | Pinky | Left | A |
| X | Ring | Left | S |
| C | Middle | Left | D |
| V | Index | Left | F |
| B | Index | Left | F (stretch) |
| N | Index | Right | J |
| M | Index | Right | J |

**Teaching Notes:**
- Bottom row requires downward reach
- B and N are index finger stretches
- Z is rare but pinky needs practice

### Stage 5: Numbers
**New Keys:** 1, 2, 3, 4, 5, 6, 7, 8, 9, 0

| Key | Finger | Hand |
|-----|--------|------|
| 1 | Pinky | Left |
| 2 | Ring | Left |
| 3 | Middle | Left |
| 4 | Index | Left |
| 5 | Index | Left |
| 6 | Index | Right |
| 7 | Index | Right |
| 8 | Middle | Right |
| 9 | Ring | Right |
| 0 | Pinky | Right |

**Teaching Notes:**
- Number row is far from home - accuracy drops initially
- 5 and 6 share the center divide (either index can work)
- Return to home row after number sequences

### Stage 6: Punctuation & Symbols
**Common Punctuation:**

| Key | Finger | Hand | Notes |
|-----|--------|------|-------|
| . | Ring | Right | Common - drill frequently |
| , | Middle | Right | After letters, before space |
| ; | Pinky | Right | Home key |
| : | Pinky | Right | Shift + ; |
| ' | Pinky | Right | Apostrophes and quotes |
| " | Pinky | Right | Shift + ' |
| ? | Pinky | Right | Shift + / |
| ! | Pinky | Left | Shift + 1 |

### Stage 7: Shift Key Technique

**Rule:** Use opposite hand's shift for capital letters.

| Letter Hand | Use Shift |
|-------------|-----------|
| Left hand letters (Q-T, A-G, Z-B) | Right Shift |
| Right hand letters (Y-P, H-;, N-/) | Left Shift |

**Teaching Notes:**
- Never use same-hand shift + letter
- Hold shift before pressing letter, release after
- Practice capital letter patterns

## Finger Strength Exercises

### Weak Finger Training Order
1. **Pinky Strengthening:** Q, A, Z, P, ;, /
2. **Ring Finger Drill:** W, S, X, O, L, .
3. **Index Stretches:** T, G, B, Y, H, N
4. **Alternating Hands:** Words with left-right-left patterns

### Recommended Practice Sequences

**Home Row Warmup:**
```
asdf jkl; asdf jkl; asdf jkl;
fjfj dkdk slsl a;a; fjdk sla;
```

**Reach Row Drill:**
```
erer uiui erer uiui
rere iuiu rtrt yuyu
```

**Full Keyboard Flow:**
```
the quick brown fox jumps over the lazy dog
pack my box with five dozen liquor jugs
```

## Display Colors (for keyboard_display.gd)

```gdscript
const FINGER_COLORS = {
    "left_pinky": Color(0.9, 0.4, 0.4),   # Red
    "left_ring": Color(0.9, 0.7, 0.4),    # Orange
    "left_middle": Color(0.9, 0.9, 0.4),  # Yellow
    "left_index": Color(0.4, 0.9, 0.4),   # Green
    "right_index": Color(0.4, 0.9, 0.9),  # Cyan
    "right_middle": Color(0.4, 0.4, 0.9), # Blue
    "right_ring": Color(0.7, 0.4, 0.9),   # Purple
    "right_pinky": Color(0.9, 0.4, 0.7),  # Pink
    "thumb": Color(0.7, 0.7, 0.7)         # Gray
}
```

## References

- `data/lessons.json` - Lesson key sets
- `game/keyboard_display.gd` - Visual keyboard implementation
- `docs/plans/p1/PEDAGOGY_GUIDE_FRAMEWORK.md` - Educational framework
