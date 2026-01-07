# Tutorial & Onboarding Asset Specifications

## Design Philosophy
- **Learn by Doing**: Hands-on practice over passive reading
- **Progressive Disclosure**: Introduce concepts gradually
- **Safe Practice**: Low stakes, encouraging environment
- **Always Escapable**: Skip options available throughout

---

## TUTORIAL FLOW

### Onboarding Sequence
```
1. Welcome & Character Introduction
2. Basic Typing Mechanics
3. Enemy Interaction
4. Tower Placement
5. Wave Combat
6. Combo System
7. Upgrades Introduction
8. First Real Battle
```

---

## TUTORIAL UI ELEMENTS

### Tutorial Overlay (ui_tutorial_overlay)
**Dimensions**: Full screen
**Components**:
- Semi-transparent background
- Spotlight on focus area
- Instruction panel
- Skip button

**Background**: #1a252f at 70% opacity

---

### Spotlight Effect (fx_tutorial_spotlight)
**Dimensions**: Variable (targets element)
**Visual**:
- Circle or rectangle cutout
- Pulsing border
- Darken everything else

**Color Palette**:
```
Border:     #f4d03f
Pulse:      #fdfefe (glow)
Mask:       #1a252f (70%)
```

---

### Instruction Panel (ui_tutorial_panel)
**Dimensions**: 320x160 (9-slice)
**Position**: Configurable (avoid blocking focus)

**Components**:
- Mentor portrait (64x64)
- Speech bubble
- Instruction text
- Continue button
- Skip option

**9-Slice Margins**:
```
margin_left: 16
margin_right: 16
margin_top: 16
margin_bottom: 16
```

---

### Continue Button (btn_tutorial_continue)
**Dimensions**: 100x32
**Text**: "Continue" or "Got it!"
**Visual**: Primary button style

---

### Skip Button (btn_tutorial_skip)
**Dimensions**: 80x24
**Text**: "Skip Tutorial"
**Visual**: Subtle, bottom corner

---

### Progress Dots (ui_tutorial_progress)
**Dimensions**: 8x8 per dot, 80px total width
**Visual**: Dots showing current step

**Dot States**:
- Completed: Filled #27ae60
- Current: Filled #f4d03f + pulse
- Upcoming: Outline #5d6d7e

---

## TUTORIAL ARROWS & POINTERS

### Arrow Pointer (tutorial_arrow)
**Dimensions**: 32x32
**Frames**: 4 (bounce)
**Duration**: 600ms loop

**Directions**: 8 (cardinal + diagonal)
**Visual**: Golden arrow with sparkle

**Color Palette**:
```
Arrow:      #f4d03f
Outline:    #d4ac0d
Sparkle:    #fdfefe
```

---

### Hand Pointer (tutorial_hand)
**Dimensions**: 32x40
**Frames**: 4 (tap animation)
**Duration**: 800ms loop

**Visual**: Gloved hand with tap motion

---

### Circle Indicator (tutorial_circle)
**Dimensions**: Variable
**Frames**: 4 (pulse)
**Duration**: 1000ms loop

**Visual**: Dashed circle around target

---

### Highlight Box (tutorial_highlight)
**Dimensions**: Variable
**Frames**: 4 (pulse)
**Duration**: 800ms loop

**Visual**: Rounded rectangle border

**Color Palette**:
```
Border:     #f4d03f
Fill:       #f4d03f (10% opacity)
```

---

## MENTOR PRESENTATIONS

### Mentor Lyra - Typing Focus

#### Teaching Poses (sprite_lyra_teach_*)
**Dimensions**: 64x80

**Poses**:
| Pose | Usage |
|------|-------|
| welcome | Introduction |
| explain | Describing concept |
| demonstrate | Showing action |
| encourage | Positive feedback |
| patient | After mistakes |
| celebrate | Completion |

---

#### Lyra Speech Bubbles (bubble_lyra_*)
**Dimensions**: Variable (9-slice)

**Types**:
| Type | Visual | Usage |
|------|--------|-------|
| speak | Standard bubble | Normal instruction |
| think | Cloud bubble | Hints |
| exclaim | Jagged bubble | Important! |
| question | Bubble with "?" | Prompting action |

---

### Mentor Kael - Combat Focus

#### Teaching Poses (sprite_kael_teach_*)
**Dimensions**: 64x80

**Poses**:
| Pose | Usage |
|------|-------|
| attention | Starting lesson |
| strategy | Explaining tactics |
| demonstrate | Combat example |
| approve | Good performance |
| concerned | Warning/danger |
| victory | Success |

---

## TYPING TUTORIAL ELEMENTS

### Key Highlight (tutorial_key_highlight)
**Dimensions**: 20x20
**Frames**: 4 (pulse)
**Duration**: 600ms loop

**Visual**: Key with glowing border
**Position**: Over virtual keyboard

---

### Finger Guide (tutorial_finger)
**Dimensions**: 24x32
**Purpose**: Show which finger to use

**Variants**:
| Finger | Color |
|--------|-------|
| Pinky | #9b59b6 |
| Ring | #3498db |
| Middle | #27ae60 |
| Index | #f39c12 |
| Thumb | #e74c3c |

---

### Hand Position Diagram (tutorial_hands)
**Dimensions**: 160x80
**Purpose**: Show proper hand placement

**Visual**:
- Both hands on home row
- Highlighted keys per finger
- Arrows showing reach

---

### Practice Word Display (tutorial_word)
**Dimensions**: Variable
**Visual**: Oversized word with letter spacing

**Features**:
- Large letters
- Current letter highlighted
- Finger indicator below each letter
- Slow-motion feedback

---

### Success Feedback (fx_tutorial_success)
**Dimensions**: 100x40
**Frames**: 6
**Duration**: 600ms

**Visual**: "Great!" or "Perfect!" with sparkles

**Variations**:
| Text | Color | Trigger |
|------|-------|---------|
| "Good!" | #27ae60 | Correct |
| "Great!" | #3498db | Fast |
| "Perfect!" | #f4d03f | 100% |
| "Try again" | #f39c12 | Mistake |

---

## COMBAT TUTORIAL ELEMENTS

### Enemy Introduction Card (tutorial_enemy_card)
**Dimensions**: 200x120
**Components**:
- Enemy sprite (preview)
- Enemy name
- Key behaviors
- Threat level

---

### Tower Introduction Card (tutorial_tower_card)
**Dimensions**: 200x140
**Components**:
- Tower sprite
- Tower name
- Attack type
- Range indicator
- Build cost

---

### Combat Zone Highlight (tutorial_zone)
**Dimensions**: Variable
**Visual**: Colored region overlay

**Zone Types**:
| Zone | Color | Purpose |
|------|-------|---------|
| Path | #e74c3c (20%) | Enemy route |
| Build | #27ae60 (20%) | Tower placement |
| Range | #3498db (20%) | Attack range |
| Castle | #f4d03f (20%) | Defense target |

---

### Wave Preview (tutorial_wave_preview)
**Dimensions**: 240x60
**Components**:
- Enemy icons
- Count per type
- Estimated difficulty

---

## INTERACTIVE PRACTICE

### Practice Area (ui_practice_area)
**Dimensions**: Full width, 200px height
**Purpose**: Safe typing practice space

**Components**:
- Word display
- Keyboard reference
- Score/feedback
- Infinite retry

---

### Practice Keyboard (ui_practice_keyboard)
**Dimensions**: 320x100
**Purpose**: Visual keyboard reference

**Features**:
- Next key highlighted
- Home row marked
- Finger colors shown
- Key labels clear

---

### Practice Target (tutorial_target)
**Dimensions**: 48x48
**Visual**: Stationary practice enemy

**Purpose**: Non-threatening practice target

---

### Sandbox Mode (ui_sandbox_panel)
**Dimensions**: 280x80
**Components**:
- Spawn controls
- Speed control
- Reset button
- No fail mode indicator

---

## TIPS & HINTS

### Tip Panel (ui_tip_panel)
**Dimensions**: 240x60 (9-slice)
**Position**: Bottom of screen

**Components**:
- Lightbulb icon
- Tip text
- Dismiss button

**Color Palette**:
```
Background: #2c3e50
Border:     #f4d03f
Icon:       #f4d03f
Text:       #fdfefe
```

---

### Loading Screen Tips (ui_loading_tip)
**Dimensions**: 280x40
**Position**: During loading

**Categories**:
- Typing tips
- Combat tips
- Advanced strategies
- Fun facts

---

### Contextual Hint (hint_contextual)
**Dimensions**: 160x40
**Trigger**: After idle or failure

**Visual**: Speech bubble from mentor

---

## TUTORIAL LEVELS

### Tutorial Stage Card (card_tutorial_stage)
**Dimensions**: 160x120

**Components**:
- Stage number
- Focus topic
- Completion status
- Estimated time

**States**:
| State | Visual |
|-------|--------|
| Locked | Grayed, lock |
| Available | Colored, glow |
| Completed | Checkmark |
| Current | Pulsing border |

---

### Tutorial Map (ui_tutorial_map)
**Dimensions**: 320x240
**Visual**: Linear path through stages

**Features**:
- Connected nodes
- Current position
- Mentor at next stage

---

## COMPLETION ELEMENTS

### Stage Complete (fx_stage_complete)
**Dimensions**: 200x100
**Frames**: 12
**Duration**: 1000ms

**Visual**:
- Checkmark appears
- Stars fly in
- Celebration particles

---

### Tutorial Complete (fx_tutorial_complete)
**Dimensions**: Full screen
**Frames**: 24
**Duration**: 2000ms

**Visual**:
- Grand celebration
- Both mentors appear
- "Ready for Battle!" text
- Transition to main game

---

### Skill Learned Badge (badge_skill_learned)
**Dimensions**: 64x64

**Components**:
- Skill icon
- "Learned" banner
- Sparkle effect

---

## HELP SYSTEM

### Help Button (btn_help)
**Dimensions**: 32x32
**Visual**: "?" in circle
**Position**: Corner of screen

---

### Help Panel (ui_help_panel)
**Dimensions**: 300x400 (9-slice)

**Sections**:
- Controls
- Objectives
- Tips
- Return to Tutorial

---

### Control Reference (ui_controls_reference)
**Dimensions**: 280x200

**Content**:
```
[Key Icon] Action description
[Key Icon] Action description
...
```

---

### Quick Help Popup (popup_quick_help)
**Dimensions**: 200x120
**Trigger**: "?" hover or long-press
**Content**: Context-sensitive help

---

## FEEDBACK MESSAGES

### Message Types

#### Success Messages
```
"Well done!"
"Excellent typing!"
"You've got it!"
"Perfect accuracy!"
"Great combo!"
```

#### Encouragement Messages
```
"Keep trying!"
"Almost there!"
"You're improving!"
"Take your time."
"Practice makes perfect!"
```

#### Instruction Messages
```
"Type the word to attack"
"Place your tower here"
"Watch your combo timer"
"Defend the castle!"
```

---

### Message Display (ui_feedback_message)
**Dimensions**: 200x40
**Duration**: 2 seconds
**Position**: Above action area

**Animation**:
- Fade in
- Hold
- Fade out

---

## ACCESSIBILITY IN TUTORIALS

### Extended Tutorial Mode
- Slower pacing
- More repetition
- Additional practice rounds
- No time pressure

### Tutorial Narration
- Voice option for all text
- Sound effects described
- Audio cues for actions

### Visual Clarity
- Extra-large text option
- High contrast mode compatible
- Clear pointer animations

---

## ASSET CHECKLIST

### Per Tutorial Stage
- [ ] Instruction panels (3-5 per stage)
- [ ] Spotlight targets defined
- [ ] Mentor poses assigned
- [ ] Success/failure feedback
- [ ] Skip functionality
- [ ] Completion celebration

### Mentor Assets
- [ ] All teaching poses
- [ ] Speech bubble variants
- [ ] Expressions for feedback
- [ ] Audio lines (if voiced)

### Interactive Elements
- [ ] Arrow/pointer animations
- [ ] Highlight effects
- [ ] Practice area UI
- [ ] Virtual keyboard display

### Help System
- [ ] Help button placement
- [ ] Control reference complete
- [ ] Contextual hints written
- [ ] Quick help popups

---

## IMPLEMENTATION NOTES

### Skip Logic
```
First-time player: Encourage completion, skip after each section
Returning player: Global skip available
Specific lesson: Can replay any completed section
```

### Progress Saving
```
Save after each section
Resume from last incomplete section
Mark completed sections
Track time spent
```

### Adaptive Difficulty
```
If struggling: Slow pace, more hints
If succeeding: Faster pace, less handholding
Track accuracy/speed to adjust
```

