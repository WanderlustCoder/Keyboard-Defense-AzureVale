# Accessibility Asset Specifications

## Design Philosophy
- **Universal Access**: Game playable by widest possible audience
- **Multiple Modalities**: Visual, audio, and haptic feedback options
- **Customization**: Players control their experience
- **No Compromise**: Accessibility features don't reduce quality

---

## ACCESSIBILITY CATEGORIES

### Visual Accessibility
- Color blindness support
- High contrast mode
- Screen reader compatibility
- Text scaling
- Motion reduction

### Motor Accessibility
- Input customization
- Auto-assist options
- Timing adjustments
- One-hand mode

### Cognitive Accessibility
- Simplified mode
- Extended timers
- Clear visual language
- Reduced complexity options

### Auditory Accessibility
- Visual audio cues
- Subtitles/captions
- Mono audio
- Volume controls

---

## COLORBLIND MODES

### Deuteranopia Mode (Red-Green)
**Most Common Type**

**Color Substitutions**:
```
Original          → Replacement
#27ae60 (Green)   → #3498db (Blue)
#2ecc71 (Lt Green)→ #5dade2 (Lt Blue)
#e74c3c (Red)     → #f39c12 (Orange)
#c0392b (Dk Red)  → #d35400 (Dk Orange)
```

**UI Indicators**:
- Add pattern overlays to color-coded elements
- Shape-based differentiation (circle=good, X=bad)

---

### Protanopia Mode (Red Weakness)
**Color Substitutions**:
```
Original          → Replacement
#e74c3c (Red)     → #f4d03f (Yellow)
#c0392b (Dk Red)  → #d4ac0d (Dk Yellow)
#27ae60 (Green)   → #1abc9c (Teal)
```

---

### Tritanopia Mode (Blue-Yellow)
**Color Substitutions**:
```
Original          → Replacement
#3498db (Blue)    → #1abc9c (Cyan)
#f4d03f (Yellow)  → #e91e63 (Pink)
#f39c12 (Orange)  → #e74c3c (Red)
```

---

### Colorblind Pattern Overlays

#### Positive Indicator (cb_pattern_positive)
```
Dimensions: 16x16 (tileable)
Pattern: Diagonal lines (top-left to bottom-right)
Color: Current theme positive color
Usage: Health bars, success states
```

#### Negative Indicator (cb_pattern_negative)
```
Dimensions: 16x16 (tileable)
Pattern: X crosshatch
Color: Current theme negative color
Usage: Damage, error states
```

#### Neutral Indicator (cb_pattern_neutral)
```
Dimensions: 16x16 (tileable)
Pattern: Dots
Color: Current theme neutral color
Usage: Inactive, pending states
```

#### Warning Indicator (cb_pattern_warning)
```
Dimensions: 16x16 (tileable)
Pattern: Horizontal stripes
Color: Current theme warning color
Usage: Caution states
```

---

## HIGH CONTRAST MODE

### Color Palette
```
Background:     #000000 (Pure Black)
Text:           #ffffff (Pure White)
Primary:        #00ff00 (Pure Green)
Danger:         #ff0000 (Pure Red)
Warning:        #ffff00 (Pure Yellow)
Info:           #00ffff (Pure Cyan)
Accent:         #ff00ff (Pure Magenta)
```

### UI Element Modifications

#### Buttons (btn_highcontrast_*)
```
Background:     #000000
Border:         #ffffff (3px)
Text:           #ffffff
Hover:          Invert colors
Focus:          #ffff00 (4px outline)
```

#### Panels (panel_highcontrast)
```
Background:     #000000
Border:         #ffffff (2px solid)
Corners:        Square (no rounding)
```

#### Icons
```
Style:          Solid filled (no gradients)
Outline:        #ffffff (2px)
Background:     #000000
```

### Enemy Visibility
```
All enemies:    White outline (2px)
Elite enemies:  Yellow outline (3px)
Boss enemies:   Pulsing white/yellow
```

### Projectiles
```
All projectiles: White trail
Enemy projectiles: Red core + white outline
Player projectiles: Green core + white outline
```

---

## TEXT SCALING

### Size Presets

#### Small (Default)
```
Body:           14px
Header:         18px
Large Header:   24px
Small:          12px
Tiny:           10px
```

#### Medium (+25%)
```
Body:           18px
Header:         22px
Large Header:   30px
Small:          15px
Tiny:           12px
```

#### Large (+50%)
```
Body:           21px
Header:         27px
Large Header:   36px
Small:          18px
Tiny:           15px
```

#### Extra Large (+100%)
```
Body:           28px
Header:         36px
Large Header:   48px
Small:          24px
Tiny:           20px
```

### Font Requirements
- **Standard**: Clean, readable pixel font
- **Dyslexic Option**: OpenDyslexic or similar
- **High Contrast**: Bold weight available
- **All Fonts**: Support full Unicode range

---

## DYSLEXIC-FRIENDLY MODE

### Font (font_dyslexic)
```
Font Family:    OpenDyslexic or custom
Weight:         Medium (not too thin)
Letter Spacing: +10%
Line Height:    1.5x
Word Spacing:   +20%
```

### Text Presentation
```
Alignment:      Left-aligned only
Line Length:    Max 60 characters
Paragraph Gap:  1.5x line height
Avoid:          All caps, italics, justified text
```

### Word Display (Typing)
```
Letter Spacing: Increased
Current Letter: Larger, underlined
Word Breaks:    Syllable hints available
```

---

## MOTION REDUCTION

### Reduced Motion Mode
When enabled, disable or minimize:
- Screen shake
- Parallax scrolling
- Particle effects (reduce by 75%)
- Animation loops (reduce to 2 frames)
- Bouncing/pulsing UI
- Transition animations

### Replacement Visuals
```
Instead of:           Use:
Shake               → Brief flash
Bounce              → Static highlight
Pulse               → Solid glow
Spin                → Static rotation
Particles           → Simple shapes
Transitions         → Instant change
```

### Motion-Safe Animations
```
Fade in/out:        Allowed (300ms max)
Color change:       Allowed
Size change:        Minimal (5% max)
Position change:    Slow, smooth
```

---

## SCREEN READER SUPPORT

### Alt Text Requirements
Every visual element needs text alternative:

#### UI Elements
```
Button:         Action description + state
Icon:           Meaning + context
Progress Bar:   "X% complete"
Health Bar:     "Health: X of Y"
Timer:          "X seconds remaining"
```

#### Game Elements
```
Enemy:          Type + distance + threat
Tower:          Type + level + target
Word:           Word text + target enemy
Effect:         Effect name + remaining duration
```

### Focus Order
```
1. Main action area (typing input)
2. Critical status (health, wave)
3. Primary navigation
4. Secondary information
5. Decorative elements (skip)
```

### ARIA Labels
```
role="button"           Interactive elements
role="progressbar"      Bars with values
role="alert"            Important notifications
role="timer"            Countdown elements
aria-live="polite"      Status updates
aria-live="assertive"   Critical alerts
```

---

## AUDIO ACCESSIBILITY

### Visual Audio Indicators

#### Sound Visualization Panel (ui_sound_viz)
```
Dimensions: 120x40
Position: Configurable (corner)
Shows:
- Music level (waveform)
- SFX activity (flash indicators)
- Directional audio (left/right arrows)
```

#### Audio Alert Icons (icon_audio_*)
```
Dimensions: 16x16 each

icon_audio_music:     Musical notes
icon_audio_sfx:       Sound wave
icon_audio_voice:     Speech bubble
icon_audio_alert:     Exclamation in circle
icon_audio_direction: Directional arrow
```

### Subtitle System

#### Subtitle Panel (ui_subtitles)
```
Dimensions: Screen width × 80px
Position: Bottom of screen
Background: Semi-transparent black
Text: White, scalable
Speaker: Colored indicator per character
```

#### Subtitle Styles
```
Speech:         Normal text
Sound Effect:   [Brackets] + italics
Music:          ♪ Musical note prefix
Direction:      ← → arrow indicators
```

### Caption Options
```
Size:           Small / Medium / Large / XL
Background:     Transparent / 50% / 75% / Solid
Position:       Bottom / Top / Custom
Speaker Labels: On / Off
Sound Captions: On / Off (non-speech sounds)
```

---

## MOTOR ACCESSIBILITY

### Input Alternatives

#### One-Button Mode
```
Input:          Single key/button
Timing:         Press duration determines action
Short Press:    Type highlighted letter
Long Press:     Confirm word
Double Press:   Special action
```

#### Eye Tracking Support
```
Gaze Points:    Large hit areas (32x32 min)
Dwell Time:     Configurable (300-1000ms)
Visual Feedback: Gaze indicator circle
```

#### Switch Access
```
Scan Mode:      Auto-highlight options
Scan Speed:     Configurable
Selection:      Single switch confirm
Cancel:         Timeout or second switch
```

### Auto-Assist Options

#### Auto-Type Assist (accessibility_autoassist)
```
Levels:
- Off: Normal gameplay
- Light: Auto-complete after 80%
- Medium: Auto-complete after 50%
- Heavy: Auto-complete after first letter
```

#### Timing Assistance
```
Extended Timers:    +50% / +100% / Unlimited
Enemy Speed:        75% / 50% / 25%
Combo Window:       Extended / Frozen
```

### Input Visualization

#### On-Screen Keyboard (ui_virtual_keyboard)
```
Dimensions: Scalable
Style: Match game theme
Features:
- Highlight next key
- Show recent presses
- Click/touch support
- Customizable layout
```

#### Input Buffer Display (ui_input_buffer)
```
Shows: Recent keystrokes
Purpose: Verify input registered
Position: Near typing area
```

---

## COGNITIVE ACCESSIBILITY

### Simplified Mode

#### Visual Simplification
```
Reduce:
- Background complexity
- Simultaneous enemies
- Particle effects
- UI elements shown
- Color variety
```

#### Gameplay Simplification
```
Reduce:
- Word difficulty
- Enemy variety
- Mechanic complexity
- Time pressure
```

### Tutorial Enhancements

#### Extended Tutorial (tutorial_extended)
```
Features:
- Slower pacing
- More repetition
- Clearer explanations
- Practice mode
- Skip confirmation
```

#### Hint System (ui_hints)
```
Hint Types:
- Visual arrows pointing to actions
- Text explanations
- Audio guidance
- Step highlighting
```

### Memory Aids

#### Persistent UI Elements
```
Always visible:
- Current objective
- Key controls reference
- Progress indicator
```

#### Session Summary (ui_session_summary)
```
Shows at session end:
- What was accomplished
- What's next
- Key learned skills
```

---

## ACCESSIBILITY ICONS

### Settings Icons (icon_a11y_*)
```
Dimensions: 24x24 each

icon_a11y_visual:       Eye symbol
icon_a11y_audio:        Ear symbol
icon_a11y_motor:        Hand symbol
icon_a11y_cognitive:    Brain symbol
icon_a11y_colorblind:   Color circles
icon_a11y_contrast:     Half-filled circle
icon_a11y_text:         "Aa" symbol
icon_a11y_motion:       Wavy lines crossed
icon_a11y_timing:       Clock symbol
icon_a11y_assist:       Helper hand
```

### Status Icons
```
icon_a11y_enabled:      Checkmark in circle
icon_a11y_disabled:     X in circle
icon_a11y_partial:      Half-filled circle
```

---

## ACCESSIBILITY SETTINGS UI

### Settings Panel Layout
```
┌─────────────────────────────────────┐
│ ACCESSIBILITY SETTINGS              │
├─────────────────────────────────────┤
│ [Visual] [Audio] [Motor] [Cognitive]│
├─────────────────────────────────────┤
│                                     │
│  Setting Name          [Control]    │
│  Description text                   │
│                                     │
│  Setting Name          [Control]    │
│  Description text                   │
│                                     │
├─────────────────────────────────────┤
│ [Reset to Defaults]    [Apply]      │
└─────────────────────────────────────┘
```

### Quick Access (ui_a11y_quick)
```
Dimensions: 48x48
Position: Corner of screen
Expands to: Quick toggle panel
Features:
- High contrast toggle
- Text size cycle
- Motion reduce toggle
- Audio description toggle
```

---

## TESTING REQUIREMENTS

### Accessibility Checklist

#### Visual
- [ ] Colorblind modes tested with simulator
- [ ] High contrast readable
- [ ] Text scalable to 200%
- [ ] Motion can be disabled
- [ ] Focus indicators visible

#### Audio
- [ ] All audio has visual alternative
- [ ] Subtitles accurate and timed
- [ ] Mono audio option works
- [ ] Volume independently controllable

#### Motor
- [ ] Playable with keyboard only
- [ ] Playable with mouse only
- [ ] Playable with controller
- [ ] Timing adjustable
- [ ] No rapid inputs required

#### Cognitive
- [ ] Tutorial completable at slow pace
- [ ] Instructions clear and simple
- [ ] Progress always visible
- [ ] No time-limited reading

### WCAG 2.1 Compliance Targets
```
Level A:      Minimum requirement
Level AA:     Target for all features
Level AAA:    Aspirational goals
```

---

## ASSET NAMING

```
accessibility/
├── colorblind/
│   ├── cb_palette_deuteranopia.json
│   ├── cb_palette_protanopia.json
│   ├── cb_palette_tritanopia.json
│   └── cb_pattern_*.png
├── high_contrast/
│   ├── hc_ui_buttons.png
│   ├── hc_ui_panels.png
│   └── hc_icons.png
├── fonts/
│   ├── font_dyslexic.ttf
│   └── font_standard.ttf
├── icons/
│   ├── icon_a11y_*.png
│   └── icon_audio_*.png
└── ui/
    ├── ui_subtitles.png
    ├── ui_sound_viz.png
    └── ui_virtual_keyboard.png
```

---

## IMPLEMENTATION PRIORITY

### Phase 1 (Launch Required)
- Colorblind modes (all 3)
- High contrast mode
- Text scaling (4 sizes)
- Subtitle system
- Volume controls
- Key remapping

### Phase 2 (Post-Launch)
- Dyslexic font option
- Motion reduction
- Extended timing options
- Auto-assist features
- Screen reader basics

### Phase 3 (Ongoing)
- Full screen reader support
- One-button mode
- Eye tracking
- Custom color palettes
- Community-requested features

