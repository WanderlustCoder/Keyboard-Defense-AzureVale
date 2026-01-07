# Typing Interface Asset Specifications

## Design Philosophy
- **Immediate Feedback**: Every keystroke produces visible response
- **Progress Clarity**: Player always knows their typing progress
- **Error Recovery**: Mistakes clearly shown but not punishing visually
- **Flow State Support**: UI fades when player is "in the zone"

---

## WORD DISPLAY SYSTEM

### Word Bubble (word_bubble)
**Dimensions**: Variable width, 24px height (9-slice)
**Components**:
- Background frame
- Word text
- Progress indicator (underline)
- Difficulty indicator (optional)

**9-Slice Margins**:
```
margin_left: 8
margin_right: 8
margin_top: 4
margin_bottom: 4
```

**Color Palette**:
```
Background:   #2c3e50 (80% opacity)
Border:       #5d6d7e
Text:         #fdfefe
Typed:        #27ae60 (green)
Current:      #f4d03f (gold, highlighted)
Remaining:    #d5d8dc (gray)
```

---

### Word Difficulty Indicators
| Difficulty | Border Color | Icon |
|------------|--------------|------|
| Easy | #27ae60 (green) | None |
| Medium | #f39c12 (orange) | Single dot |
| Hard | #e74c3c (red) | Double dot |
| Expert | #9b59b6 (purple) | Star |

---

### Word States

#### Inactive Word (word_inactive)
```
Opacity: 60%
Border: None
Text: Gray (#85929e)
Scale: 0.9x
```

#### Active Word (word_active)
```
Opacity: 100%
Border: #f4d03f (2px)
Text: White with progress coloring
Scale: 1.0x
Glow: Subtle golden aura
```

#### Completed Word (word_complete)
```
Animation: Flash green → shrink → particles
Duration: 300ms
Effect: Burst of letter particles
Sound: Satisfying "ding"
```

#### Failed Word (word_failed)
```
Animation: Flash red → shake → fade
Duration: 400ms
Effect: Letters scatter/fall
Sound: Error buzz
```

---

### Word Connection Line (word_connector)
**Dimensions**: Variable length, 2px height
**Purpose**: Connect word to its enemy

**Visual**:
- Dashed line from word to enemy
- Color matches word state
- Pulses when word is active

**Color Palette**:
```
Normal:       #5d6d7e (30% opacity)
Active:       #f4d03f (50% opacity)
Urgent:       #e74c3c (pulsing)
```

---

## CHARACTER-LEVEL FEEDBACK

### Letter States

#### Untyped Letter (letter_untyped)
```
Color: #d5d8dc
Background: None
```

#### Current Letter (letter_current)
```
Color: #fdfefe
Background: #f4d03f (highlight box)
Underline: Blinking cursor
Animation: Gentle pulse
```

#### Correct Letter (letter_correct)
```
Color: #27ae60
Background: None
Animation: Brief scale-up (100ms)
```

#### Wrong Letter (letter_wrong)
```
Color: #e74c3c
Background: #e74c3c (20% opacity)
Animation: Shake (50ms)
Strikethrough: Optional
```

---

### Keystroke Effects

#### Correct Keystroke (fx_key_correct)
```
Dimensions: 16x16
Frames: 4
Duration: 200ms
Visual: Green circle ripple
Particle: 2-3 green sparkles
```

#### Wrong Keystroke (fx_key_wrong)
```
Dimensions: 16x16
Frames: 4
Duration: 200ms
Visual: Red X flash
Particle: Red shake lines
Screen: Micro-shake (optional)
```

#### Word Complete (fx_word_complete)
```
Dimensions: 32x32
Frames: 6
Duration: 400ms
Visual: Golden burst, letters fly out
Particle: 8-12 letter-shaped particles
```

---

## KEYBOARD VISUALIZATION

### Virtual Keyboard (keyboard_full)
**Dimensions**: 320x100
**Purpose**: Show proper finger positions

**Layout**:
```
Row 1: ` 1 2 3 4 5 6 7 8 9 0 - = [BACK]
Row 2: [TAB] Q W E R T Y U I O P [ ] \
Row 3: [CAPS] A S D F G H J K L ; ' [ENTER]
Row 4: [SHIFT] Z X C V B N M , . / [SHIFT]
Row 5: [CTRL] [WIN] [ALT] [SPACE] [ALT] [WIN] [MENU] [CTRL]
```

---

### Individual Key (key_*)
**Dimensions**: 16x16 (standard), 24x16 (wide), 32x16 (extra wide)

**States**:
| State | Visual |
|-------|--------|
| Normal | Dark gray (#34495e) |
| Highlighted | Golden border (#f4d03f) |
| Pressed | Darker, slight sink |
| Next Key | Pulsing highlight |
| Home Row | Subtle bump indicator |

---

### Finger Assignment Colors
```
Left Pinky:   #9b59b6 (purple)
Left Ring:    #3498db (blue)
Left Middle:  #27ae60 (green)
Left Index:   #f39c12 (orange)
Right Index:  #f39c12 (orange)
Right Middle: #27ae60 (green)
Right Ring:   #3498db (blue)
Right Pinky:  #9b59b6 (purple)
Thumbs:       #e74c3c (red)
```

---

### Key Hint Overlay (key_hint)
**Dimensions**: 24x24
**Purpose**: Show which finger to use

**Components**:
- Key letter (large)
- Finger indicator (small icon)
- Hand indicator (L/R)

**Color Palette**:
```
Background:   Finger color (see above)
Text:         #fdfefe
Hand Icon:    #fdfefe (outlined)
```

---

## TYPING INPUT BAR

### Input Frame (input_typing_frame)
**Dimensions**: 300x40 (9-slice)
**Components**:
- Background panel
- Text display area
- Cursor
- Clear button (X)

**9-Slice Margins**:
```
margin_left: 12
margin_right: 12
margin_top: 8
margin_bottom: 8
```

---

### Input States

#### Empty State
```
Text: "Type to attack..." (placeholder)
Color: #5d6d7e
Cursor: Hidden or slow blink
```

#### Typing State
```
Text: User input (white)
Matched: Green highlight
Cursor: Fast blink
Border: #3498db
```

#### Match Found State
```
Text: All green
Border: #27ae60 (flash)
Animation: Clear with particles
```

#### No Match State
```
Text: Red underline
Border: #e74c3c
Animation: Shake
Auto-clear: After 500ms (optional)
```

#### Disabled State
```
Background: Darkened
Text: Grayed out
Cursor: None
Reason: "Wave complete" or similar
```

---

### Cursor Variations

#### Standard Cursor (cursor_typing)
```
Dimensions: 2x16
Color: #fdfefe
Animation: Blink 500ms on/off
```

#### Block Cursor (cursor_block)
```
Dimensions: 10x16
Color: #fdfefe (50% opacity)
Animation: Blink 500ms on/off
```

#### Underline Cursor (cursor_underline)
```
Dimensions: 10x2
Color: #f4d03f
Animation: Blink 400ms on/off
```

---

## COMBO SYSTEM VISUALS

### Combo Meter (combo_meter)
**Dimensions**: 64x8
**Purpose**: Show combo timer draining

**Components**:
- Background track
- Fill bar (draining)
- Flash on extend

**Color Palette**:
```
Track:        #1a252f
Fill Full:    #27ae60
Fill Medium:  #f39c12 (at 50%)
Fill Low:     #e74c3c (at 25%)
Fill Empty:   Flash red, then reset
```

---

### Combo Multiplier Display (combo_display)
**Dimensions**: 48x32
**Components**:
- "x" prefix
- Multiplier number
- Glow effect

**Visual Progression**:
```
x1:  Small, no effect
x2:  Normal size, subtle glow
x3:  Larger, green glow
x5:  Golden glow, sparkles
x10: Rainbow glow, intense particles
x15+: Screen-edge effects
```

---

### Combo Popup (combo_popup_x*)
**Dimensions**: 32x24
**Frames**: 4
**Duration**: 400ms

**Animation**:
- Scale up from center
- Float upward
- Fade out

**Variations**:
- x2, x3, x4, x5 (standard)
- x10 (special golden)
- x15, x20 (legendary rainbow)

---

## ACCURACY FEEDBACK

### Accuracy Display (hud_accuracy)
**Dimensions**: 60x20
**Components**:
- Percentage number
- Grade letter (optional)
- Trend arrow

**Grade Thresholds**:
```
100%:     S+ (rainbow)
95-99%:   S (gold)
90-94%:   A (green)
80-89%:   B (blue)
70-79%:   C (yellow)
60-69%:   D (orange)
<60%:     F (red)
```

---

### Per-Word Accuracy Popup
**Dimensions**: 24x16
**Visual**: "100%", "95%", etc.
**Position**: Above completed word
**Duration**: 1 second fade

**Color by Accuracy**:
```
100%:     #f4d03f (gold)
90%+:     #27ae60 (green)
80%+:     #3498db (blue)
<80%:     #e74c3c (red)
```

---

## WPM (Words Per Minute) DISPLAY

### WPM Counter (hud_wpm)
**Dimensions**: 72x24
**Components**:
- WPM number (large)
- "WPM" label (small)
- Trend indicator

**Color Coding**:
```
<20 WPM:   #5d6d7e (gray - learning)
20-40:     #3498db (blue - beginner)
40-60:     #27ae60 (green - intermediate)
60-80:     #f39c12 (orange - advanced)
80-100:    #e74c3c (red - expert)
100+:      #9b59b6 (purple - master)
```

**Trend Indicator**:
- Arrow up (green): WPM increasing
- Arrow down (red): WPM decreasing
- Dash (gray): Stable

---

### WPM Graph (wpm_graph)
**Dimensions**: 120x40
**Purpose**: Real-time WPM visualization

**Components**:
- Line graph of last 30 seconds
- Current WPM highlighted
- Personal best line (dashed)

**Color Palette**:
```
Line:         #3498db
Current:      #f4d03f (dot)
Best:         #27ae60 (dashed line)
Background:   #1a252f
Grid:         #5d6d7e (10% opacity)
```

---

## PRACTICE/DRILL MODE UI

### Lesson Card (card_lesson)
**Dimensions**: 160x100 (9-slice)
**Components**:
- Lesson title
- Difficulty stars
- Completion status
- Best score
- Key focus (e.g., "Home Row")

**States**:
| State | Visual |
|-------|--------|
| Locked | Grayed out, lock icon |
| Available | Normal colors, glow |
| In Progress | Progress bar overlay |
| Completed | Check mark, stars |
| Mastered | Gold border, trophy |

---

### Drill Progress Bar (bar_drill_progress)
**Dimensions**: 200x16
**Components**:
- Background track
- Fill bar
- Word markers (vertical lines)
- Current position

**Color Palette**:
```
Track:        #1a252f
Fill:         #3498db
Markers:      #5d6d7e
Current:      #f4d03f (diamond)
```

---

### Letter Focus Display (drill_letter_focus)
**Dimensions**: 64x64
**Purpose**: Highlight current practice letter

**Components**:
- Large letter (centered)
- Finger assignment
- Hand diagram

**Animation**:
- Pulse on current
- Green flash on correct
- Red shake on mistake

---

## WORD QUEUE VISUALIZATION

### Incoming Words Queue (queue_words)
**Dimensions**: 200x24
**Purpose**: Show upcoming words

**Layout**:
```
[Current Word] → [Next 1] → [Next 2] → [Next 3]...
```

**Visual Treatment**:
- Current: Full size, bright
- Next: 90% size, slightly dim
- Future: 80% size, faded

---

### Word Priority Indicator
**Purpose**: Show which word to type first

**Visual**:
- Arrow pointing to priority word
- Enemy urgency shown by word color
- Distance indicator (if applicable)

---

## SPECIAL TYPING EVENTS

### Power Word Display (word_power)
**Dimensions**: Variable (larger than normal)
**Purpose**: Special command words

**Visual**:
- Glowing border
- Special icon prefix
- Unique color per type

**Power Word Types**:
```
HEAL:     Green glow, heart icon
SHIELD:   Blue glow, shield icon
BOMB:     Orange glow, bomb icon
FREEZE:   Cyan glow, snowflake icon
BOOST:    Gold glow, star icon
```

---

### Boss Word Challenge (word_boss)
**Dimensions**: Extra large
**Purpose**: Boss-specific long words/phrases

**Components**:
- Large word display
- Progress segments
- Timer bar
- Damage indicator

**Color Palette**:
```
Border:       #c0392b (dark red)
Text:         #fdfefe
Progress:     #e74c3c → #27ae60
Timer:        #f39c12
```

---

### Typing Challenge Popup (challenge_popup)
**Dimensions**: 280x80
**Purpose**: Special typing challenges

**Components**:
- Challenge title
- Word/phrase to type
- Timer
- Reward preview

**Animation**:
- Slide in from top
- Pulse urgency as timer drops
- Celebratory burst on complete

---

## ERROR HANDLING VISUALS

### Typo Indicator (fx_typo)
**Dimensions**: 12x12
**Frames**: 3
**Duration**: 200ms

**Visual**: Small red X or spark

---

### Backspace Effect (fx_backspace)
**Dimensions**: 16x16
**Frames**: 4
**Duration**: 150ms

**Visual**: Letter erasing/flying backward

---

### Word Reset Indicator (fx_word_reset)
**Dimensions**: 24x24
**Frames**: 6
**Duration**: 300ms

**Visual**: Circular arrow, word resets

---

## ACCESSIBILITY TYPING AIDS

### Next Key Indicator (aid_next_key)
**Dimensions**: 20x20
**Purpose**: Show which key to press next

**Visual**:
- Key letter enlarged
- Arrow pointing to keyboard position
- Color-coded by finger

---

### Finger Position Guide (aid_finger_guide)
**Dimensions**: 80x40
**Purpose**: Show correct finger for current key

**Components**:
- Hand silhouette
- Highlighted finger
- Key assignment

---

### Audio Typing Feedback
```
Correct Key:   Short click (high pitch)
Wrong Key:     Short buzz (low pitch)
Word Complete: Chime
Combo Up:      Rising tone
Combo Drop:    Falling tone
```

---

## ANIMATION TIMING STANDARDS

### Typing Feedback
| Event | Duration | Notes |
|-------|----------|-------|
| Key press visual | 100ms | Immediate |
| Letter confirm | 150ms | After key up |
| Word complete | 400ms | Full animation |
| Combo popup | 600ms | Float and fade |
| Error shake | 200ms | Quick, not jarring |

### Flow State Transitions
| Event | Duration | Notes |
|-------|----------|-------|
| HUD fade (in zone) | 500ms | After 5 correct words |
| HUD return | 200ms | On error or pause |
| Keyboard fade | 300ms | When not needed |

