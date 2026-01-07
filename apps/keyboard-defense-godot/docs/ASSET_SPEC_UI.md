# UI/HUD Asset Specifications

## Design Philosophy
- **Clarity First**: Information readable at a glance during intense gameplay
- **Consistent Language**: Same visual patterns across all UI elements
- **Responsive Feedback**: Every interaction acknowledged visually
- **Accessibility**: High contrast, scalable elements, colorblind-safe

---

## HUD LAYOUT SYSTEM

### Screen Regions
```
┌─────────────────────────────────────────────────────────────┐
│  [WAVE INFO]           [SCORE/COMBO]           [MENU BTN]   │  ← Top Bar (32px)
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                                                             │
│                      GAMEPLAY AREA                          │
│                                                             │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  [CASTLE HP]        [TYPING INPUT]        [RESOURCES]       │  ← Bottom Bar (48px)
└─────────────────────────────────────────────────────────────┘
```

---

## TOP BAR ELEMENTS

### Wave Indicator (hud_wave_indicator)
**Dimensions**: 96x24
**Components**:
- Wave number display (large)
- Progress to next wave (bar)
- Enemy count remaining (icon + number)

**Color Palette**:
```
Background:   #1a252f (dark)
Text:         #fdfefe (white)
Progress:     #e74c3c (red) → #27ae60 (green as wave ends)
Border:       #5d6d7e
```

**States**:
- Normal: Static display
- Wave Starting: Pulse animation, yellow flash
- Wave Complete: Green flash, particles

---

### Score Display (hud_score_display)
**Dimensions**: 80x24
**Components**:
- Score number (right-aligned)
- Score icon (star/gem)
- Point popup anchor

**Color Palette**:
```
Background:   #1a252f
Text:         #f4d03f (gold)
Icon:         #f4d03f, #d4ac0d
Border:       #5d6d7e
```

**Animation**:
- Score change: Number scales up briefly
- Milestone: Gold burst effect

---

### Combo Display (hud_combo_display)
**Dimensions**: 64x32
**Components**:
- Multiplier text (x2, x3, etc.)
- Combo meter (filling arc/bar)
- Combo timer (draining indicator)

**Color Palette**:
```
x1-x2:    #3498db (blue)
x3-x4:    #27ae60 (green)
x5-x7:    #f39c12 (orange)
x8-x9:    #e74c3c (red)
x10+:     #9b59b6 (purple) + sparkle
```

**Animation**:
- Combo increase: Scale bounce + color shift
- Combo maintained: Gentle pulse
- Combo dropped: Crack effect, gray out

---

### Menu Button (hud_menu_btn)
**Dimensions**: 24x24
**Visual**: Three horizontal lines (hamburger menu)

**States**:
| State | Visual |
|-------|--------|
| Normal | Gray lines on dark |
| Hover | Lines brighten, subtle glow |
| Pressed | Inverted colors |
| Open | X transformation |

---

## BOTTOM BAR ELEMENTS

### Castle Health (hud_castle_health)
**Dimensions**: 128x32
**Components**:
- Castle icon (left)
- Health bar (center)
- HP numbers (right, optional)
- Damage warning overlay

**Color Palette**:
```
Bar Full:     #27ae60 (green)
Bar Medium:   #f39c12 (orange) at <50%
Bar Low:      #e74c3c (red) at <25%
Bar Critical: #922b21 (dark red) at <10%, pulsing
Background:   #1a252f
Border:       #5d6d7e
```

**Animation**:
- Damage taken: Bar flashes white, shakes
- Healing: Green particles rise
- Critical: Screen edge vignette pulses red

---

### Typing Input Display (hud_typing_input)
**Dimensions**: 256x40
**Components**:
- Input frame (background)
- Typed text (left-aligned)
- Cursor (blinking)
- Suggestion/autocomplete (ghosted)
- Match indicator

**Color Palette**:
```
Frame:        #2c3e50
Frame Focus:  #3498db border
Text Correct: #27ae60
Text Wrong:   #e74c3c
Cursor:       #fdfefe
Suggestion:   #5d6d7e (30% opacity)
```

**States**:
- Empty: Placeholder text "Type to attack..."
- Typing: Character-by-character reveal
- Match: Flash green, clear with particle
- No Match: Shake, red flash
- Disabled: Grayed out, no cursor

---

### Resource Panel (hud_resource_panel)
**Dimensions**: 96x32
**Components**:
- Gold count (coin icon + number)
- Mana/Energy (if applicable)
- Special resource indicators

**Color Palette**:
```
Gold:         #f4d03f
Mana:         #3498db
Energy:       #27ae60
Background:   #1a252f
```

---

## PAUSE MENU

### Pause Overlay (menu_pause_overlay)
**Dimensions**: Full screen
**Visual**: Semi-transparent dark overlay (#1a252f at 80%)

---

### Pause Panel (menu_pause_panel)
**Dimensions**: 200x280 (9-slice)
**Components**:
- "PAUSED" header
- Resume button
- Settings button
- Restart button
- Quit button

**9-Slice Margins**:
```
margin_left: 8
margin_right: 8
margin_top: 12
margin_bottom: 8
```

**Color Palette**:
```
Panel:        #2c3e50
Header:       #34495e
Text:         #fdfefe
Buttons:      See button specifications
```

---

### Button Styles (btn_menu_*)

#### Primary Button (btn_menu_primary)
**Dimensions**: 160x32 (9-slice)
```
Normal:   #27ae60 (green)
Hover:    #2ecc71 (bright green)
Pressed:  #1e8449 (dark green)
Text:     #fdfefe
```

#### Secondary Button (btn_menu_secondary)
**Dimensions**: 160x32 (9-slice)
```
Normal:   #5d6d7e
Hover:    #85929e
Pressed:  #34495e
Text:     #fdfefe
```

#### Danger Button (btn_menu_danger)
**Dimensions**: 160x32 (9-slice)
```
Normal:   #c0392b
Hover:    #e74c3c
Pressed:  #922b21
Text:     #fdfefe
```

---

## SETTINGS MENU

### Settings Panel (menu_settings_panel)
**Dimensions**: 320x400 (9-slice)
**Components**:
- Tab row (Audio, Video, Controls, Accessibility)
- Settings list (scrollable)
- Close button

---

### Settings Categories

#### Audio Settings
| Setting | Control Type | Range |
|---------|--------------|-------|
| Master Volume | Slider | 0-100 |
| Music Volume | Slider | 0-100 |
| SFX Volume | Slider | 0-100 |
| Voice Volume | Slider | 0-100 |
| Mute All | Toggle | On/Off |

#### Video Settings
| Setting | Control Type | Options |
|---------|--------------|---------|
| Resolution | Dropdown | 720p, 1080p, 1440p, 4K |
| Fullscreen | Toggle | On/Off |
| VSync | Toggle | On/Off |
| Screen Shake | Slider | 0-100 |
| Particle Density | Dropdown | Low, Medium, High |

#### Controls Settings
| Setting | Control Type | Notes |
|---------|--------------|-------|
| Key Bindings | Button → Capture | Rebindable |
| Mouse Sensitivity | Slider | 0.1-2.0 |
| Confirm Key | Dropdown | Enter, Space, Tab |

#### Accessibility Settings
| Setting | Control Type | Options |
|---------|--------------|---------|
| Text Size | Dropdown | Small, Medium, Large, XL |
| High Contrast | Toggle | On/Off |
| Colorblind Mode | Dropdown | Off, Deuteranopia, Protanopia, Tritanopia |
| Dyslexic Font | Toggle | On/Off |
| Reduce Motion | Toggle | On/Off |
| Auto-Pause | Toggle | On/Off |

---

### Slider Control (ctrl_slider)
**Dimensions**: 120x16
**Components**:
- Track (background)
- Fill (current value)
- Thumb (draggable)
- Value label (optional)

**Color Palette**:
```
Track:        #1a252f
Fill:         #3498db
Thumb:        #fdfefe
Thumb Hover:  #aed6f1
```

---

### Toggle Control (ctrl_toggle)
**Dimensions**: 40x20
**Components**:
- Track (pill shape)
- Knob (circle)

**Color Palette**:
```
Off Track:    #5d6d7e
On Track:     #27ae60
Knob:         #fdfefe
```

**Animation**: Knob slides left/right (150ms ease)

---

### Dropdown Control (ctrl_dropdown)
**Dimensions**: 120x24 (collapsed), variable (expanded)
**Components**:
- Selected value display
- Arrow indicator
- Options list

**Color Palette**:
```
Background:   #2c3e50
Border:       #5d6d7e
Text:         #fdfefe
Hover:        #3498db
Selected:     #27ae60
```

---

## GAME OVER SCREENS

### Victory Panel (screen_victory)
**Dimensions**: 280x360 (9-slice)
**Components**:
- "VICTORY!" header (animated)
- Star rating (1-3 stars)
- Statistics list
- Rewards display
- Continue button

**Color Palette**:
```
Header:       #f4d03f (gold)
Stars:        #f4d03f (earned), #5d6d7e (unearned)
Panel:        #2c3e50
Text:         #fdfefe
```

**Animation**:
- Header: Scale in with bounce
- Stars: Pop in sequentially
- Stats: Count up from 0

---

### Defeat Panel (screen_defeat)
**Dimensions**: 280x320 (9-slice)
**Components**:
- "DEFEAT" header
- Wave reached display
- Statistics list
- Retry button
- Return to Menu button

**Color Palette**:
```
Header:       #e74c3c (red)
Panel:        #2c3e50
Text:         #fdfefe
```

---

### Statistics Display (stat_row)
**Dimensions**: 240x20
**Components**:
- Stat icon (16x16)
- Stat name
- Stat value (right-aligned)

**Statistics Tracked**:
| Stat | Icon |
|------|------|
| Words Typed | icon_word |
| Accuracy | icon_accuracy |
| WPM | icon_speed |
| Enemies Defeated | icon_skull |
| Damage Dealt | icon_sword |
| Gold Earned | icon_coin |
| Combo Max | icon_combo |
| Time Played | icon_clock |

---

## TOOLTIP SYSTEM

### Tooltip Frame (tooltip_frame)
**Dimensions**: Variable (9-slice)
**Max Width**: 200px
**Components**:
- Header (bold)
- Description (normal)
- Stats (if applicable)
- Hotkey hint (if applicable)

**9-Slice Margins**:
```
margin_left: 6
margin_right: 6
margin_top: 6
margin_bottom: 6
```

**Color Palette**:
```
Background:   #1a252f (95% opacity)
Border:       #5d6d7e
Header:       #f4d03f
Description:  #d5d8dc
Stats:        #27ae60 (positive), #e74c3c (negative)
Hotkey:       #aed6f1
```

**Positioning**:
- Prefer below cursor
- Flip if near screen edge
- 8px offset from cursor

---

### Tooltip Pointer (tooltip_pointer)
**Dimensions**: 8x4
**Visual**: Triangle pointing to anchor

---

## NOTIFICATION SYSTEM

### Toast Notification (notif_toast)
**Dimensions**: 240x48 (9-slice)
**Components**:
- Icon (left)
- Message text
- Optional action button
- Close button (X)

**Types**:
| Type | Icon Color | Border Color |
|------|------------|--------------|
| Info | #3498db | #3498db |
| Success | #27ae60 | #27ae60 |
| Warning | #f39c12 | #f39c12 |
| Error | #e74c3c | #e74c3c |

**Animation**:
- Enter: Slide in from right
- Exit: Fade out
- Duration: 3-5 seconds (configurable)

---

### Achievement Popup (notif_achievement)
**Dimensions**: 280x64
**Components**:
- Achievement icon (48x48)
- Achievement name
- Achievement description
- XP/reward display

**Color Palette**:
```
Background:   #2c3e50
Border:       #f4d03f (gold shimmer)
Name:         #f4d03f
Description:  #d5d8dc
```

**Animation**:
- Slide down from top
- Gold particle burst
- Hold for 4 seconds
- Slide up to exit

---

## DIALOGUE SYSTEM

### Dialogue Box (dialogue_box)
**Dimensions**: 400x100 (9-slice)
**Components**:
- Speaker portrait (optional, 64x64)
- Speaker name
- Dialogue text (typewriter effect)
- Continue indicator

**9-Slice Margins**:
```
margin_left: 12
margin_right: 12
margin_top: 12
margin_bottom: 12
```

**Color Palette**:
```
Background:   #2c3e50
Border:       #5d6d7e
Name:         #f4d03f
Text:         #fdfefe
Indicator:    #3498db (animated)
```

---

### Choice Button (dialogue_choice)
**Dimensions**: 360x28
**Components**:
- Choice number/letter
- Choice text
- Hover indicator

**Color Palette**:
```
Normal:       #34495e
Hover:        #3498db
Text:         #fdfefe
```

---

## LOADING SCREENS

### Loading Bar (loading_bar_large)
**Dimensions**: 300x20
**Components**:
- Track background
- Fill (animated)
- Percentage text
- Loading tip (below)

**Color Palette**:
```
Track:        #1a252f
Fill:         #3498db → #27ae60 (gradient as completes)
Text:         #fdfefe
```

**Animation**:
- Fill has moving highlight
- Shimmer effect on completion

---

### Loading Spinner (loading_spinner_large)
**Dimensions**: 48x48
**Frames**: 12
**Duration**: 1200ms
**Visual**: Rotating arc/dots

---

## CURRENCY DISPLAYS

### Gold Display (display_gold)
**Dimensions**: 80x24
**Components**:
- Coin icon (16x16)
- Gold amount

**Animation on Change**:
- Increase: Green flash, number counts up
- Decrease: Red flash, number counts down

---

### Gem Display (display_gem)
**Dimensions**: 80x24
**Components**:
- Gem icon (16x16)
- Gem amount

**Color Palette**:
```
Gem:          #9b59b6 (purple)
Text:         #fdfefe
```

---

## MODAL DIALOGS

### Confirm Dialog (modal_confirm)
**Dimensions**: 240x140 (9-slice)
**Components**:
- Warning icon
- Message text
- Confirm button
- Cancel button

**Color Palette**:
```
Background:   #2c3e50
Warning:      #f39c12
Text:         #fdfefe
```

---

### Input Dialog (modal_input)
**Dimensions**: 280x160 (9-slice)
**Components**:
- Prompt text
- Text input field
- Submit button
- Cancel button

---

## MINIMAP

### Minimap Frame (minimap_frame)
**Dimensions**: 128x128 (9-slice)
**Components**:
- Border frame
- Map area
- Zoom controls (optional)

**9-Slice Margins**:
```
margin_left: 4
margin_right: 4
margin_top: 4
margin_bottom: 4
```

**Color Palette**:
```
Background:   #1a252f (80% opacity)
Border:       #5d6d7e
```

---

### Minimap Icons
| Icon | Dimensions | Color |
|------|------------|-------|
| minimap_player | 6x6 | #3498db |
| minimap_enemy | 4x4 | #e74c3c |
| minimap_tower | 5x5 | #27ae60 |
| minimap_castle | 8x8 | #f4d03f |
| minimap_objective | 6x6 | #9b59b6 |
| minimap_boss | 8x8 | #c0392b |

---

## ACCESSIBILITY OVERLAYS

### High Contrast Mode
```
Background:   #000000 (pure black)
Text:         #ffffff (pure white)
Primary:      #00ff00 (green)
Danger:       #ff0000 (red)
Highlight:    #ffff00 (yellow)
```

### Large Text Mode
```
Base Size:    16px → 20px
Header:       24px → 30px
Small:        12px → 16px
```

### Colorblind Palettes

#### Deuteranopia Mode
```
Green → Blue:     #27ae60 → #3498db
Red → Orange:     #e74c3c → #f39c12
```

#### Protanopia Mode
```
Red → Yellow:     #e74c3c → #f4d03f
Green → Cyan:     #27ae60 → #1abc9c
```

#### Tritanopia Mode
```
Blue → Cyan:      #3498db → #1abc9c
Yellow → Pink:    #f4d03f → #e91e63
```

---

## ANIMATION STANDARDS

### Transition Timings
| Animation | Duration | Easing |
|-----------|----------|--------|
| Button Press | 100ms | ease-out |
| Menu Open | 200ms | ease-out |
| Menu Close | 150ms | ease-in |
| Tooltip Show | 150ms | ease-out |
| Tooltip Hide | 100ms | ease-in |
| Notification | 300ms | ease-out |
| Screen Transition | 400ms | ease-in-out |

### Hover Effects
- Scale: 1.0 → 1.05
- Brightness: +10%
- Border glow (optional)

### Focus Indicators
- 2px outline
- Color: #3498db
- Offset: 2px

