# Keyboard Defense Playtest Checklist

Use this checklist when testing the game in Godot to verify all systems work correctly.

## Quick Start
```bash
# Open project in Godot 4
cd apps/keyboard-defense-godot
godot --editor .
# Press F5 to run the game
```

---

## Core Systems Checklist

### 1. Main Menu
- [ ] Game starts without errors
- [ ] "New Game" button works
- [ ] "Continue" button works (if save exists)
- [ ] Music/audio plays (if implemented)

### 2. Campaign Map
- [ ] Map displays all nodes (should show 64 nodes)
- [ ] First node (Forest Gate or Training Grounds) is unlocked
- [ ] Locked nodes appear dimmed
- [ ] Clicking unlocked node starts battle
- [ ] Gold counter displays correctly
- [ ] Lesson names display (not "Training Drill")
- [ ] Completed nodes show "(cleared)" indicator

### 3. Battle System
- [ ] Battle loads without errors
- [ ] Drill title shows correct label
- [ ] Drill hints display during gameplay
- [ ] Typing input registers correctly
- [ ] Correct keystrokes advance the word
- [ ] Mistakes register and show feedback
- [ ] Threat bar fills on mistakes
- [ ] Castle health decreases on threat overflow

### 4. Word Generation (CRITICAL)
- [ ] **Home Row lessons**: Words use only `asdfjkl;` characters
- [ ] **Bottom Row lessons**: Words include `zxcvbnm` characters
- [ ] **Number lessons**: Words include `1234567890`
- [ ] **Punctuation lessons**: Words include `.,;:'"`
- [ ] Word lengths vary by enemy type (scout=short, armored=long)

### 5. Drill Modes
- [ ] **Lesson mode**: Uses generated words from lesson charset
- [ ] **Targets mode**: Uses specific words from drill definition
- [ ] **Intermission mode**: Shows message, pauses input, timer counts down

### 6. Progression
- [ ] Completing node grants gold
- [ ] Completed node unlocks dependent nodes
- [ ] Progress persists after closing game (check save file)
- [ ] Practice mode gives reduced gold for replaying cleared nodes

---

## Sample Playtest Path

### Early Game (5 min)
1. Start new game
2. Play **Training Grounds** → verify simple `asdf` words
3. Play **Training Arena** → verify `asdfjkl` words
4. Check that both nodes show as cleared on map

### Main Path (10 min)
5. Play **Forest Gate** → home row words
6. Play **Whisper Grove** → extended home row
7. Unlock both **Ember Bridge** and **Shadow Vale** paths
8. Play one node from each path

### Content Variety (5 min)
9. If post-game unlocked, try **Code Academy** → programming-style words
10. Try **Bronze Precision** → accuracy-focused
11. Try **Ember Path** → fire-themed fast words

---

## Known Issues to Watch For

| Issue | Expected | Report If |
|-------|----------|-----------|
| Word charset mismatch | Words match lesson charset | Words contain wrong letters |
| Drill mode crashes | All 3 modes work | Error on specific mode |
| Node unlock stuck | Prerequisites unlock nodes | Node stays locked incorrectly |
| Gold not awarded | Gold increases on victory | Gold stays same after win |
| Save corruption | Progress loads correctly | Progress lost or garbled |

---

## Test Node Sampling

These nodes exercise different content types:

| Node | Tests | Expected Behavior |
|------|-------|-------------------|
| Training Grounds | Basic tutorial | Very simple `asdf` words |
| Forest Gate | Home row | `asdfjkl` charset words |
| Shadow Vale | Bottom row | `zxcv` charset words |
| Number Spire | Numbers | Words with `12345` |
| Scribe's Hall | Punctuation | Words with `.,;:'` |
| Code Academy | Symbols | Words with `_` and code-style |
| Speed Arena | Short words | Very short burst words |
| Endurance Arena | Long words | 10+ character words |
| Chaos Arena | Everything | All characters mixed |

---

## Performance Checks

- [ ] No stuttering during typing
- [ ] Smooth drill transitions
- [ ] No memory leaks (RAM stable over 10+ minutes)
- [ ] No orphan nodes in scene tree

---

## Bug Report Template

```
**Node/Scene:** [e.g., Forest Gate battle]
**Steps to reproduce:**
1.
2.
3.

**Expected:**
**Actual:**
**Error log (if any):**
```

---

## After Playtest

1. Note any issues found
2. Check Godot console for warnings/errors
3. Verify save file exists in user data folder
4. Consider balance: Was difficulty appropriate?
