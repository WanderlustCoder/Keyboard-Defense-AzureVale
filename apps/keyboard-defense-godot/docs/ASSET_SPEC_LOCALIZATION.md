# Localization & Internationalization Asset Specifications

## Design Philosophy
- **Global Accessibility**: Game playable worldwide from day one
- **Text Expansion**: UI accommodates 40% text length increase
- **Cultural Sensitivity**: Art avoids culturally specific imagery
- **Typing Adaptability**: Core mechanics work across keyboard layouts

---

## LANGUAGE SUPPORT

### Tier 1 Languages (Launch)
```
English (en-US)    - Base language
Spanish (es)       - Large typing market
German (de)        - European market
French (fr)        - European market
Portuguese (pt-BR) - South American market
```

### Tier 2 Languages (Post-Launch)
```
Japanese (ja)      - Asian market (IME support needed)
Korean (ko)        - Asian market (IME support needed)
Chinese Simplified (zh-CN)
Italian (it)
Russian (ru)       - Cyrillic keyboard
Polish (pl)
```

### Tier 3 Languages (Future)
```
Arabic (ar)        - RTL support needed
Hebrew (he)        - RTL support needed
Thai (th)
Turkish (tr)
Dutch (nl)
Swedish (sv)
```

---

## KEYBOARD LAYOUT SUPPORT

### QWERTY Variants
```
en-US:    Standard QWERTY
en-UK:    QWERTY (different symbols)
es:       QWERTY with ñ
pt-BR:    QWERTY with ç
```

### QWERTZ Layout
```
de:       Z/Y swapped, umlauts (ä, ö, ü)
```

### AZERTY Layout
```
fr:       A/Q, Z/W swapped, accents
```

### Cyrillic Layout
```
ru:       Full Cyrillic character set
```

### Keyboard Layout Assets

#### Virtual Keyboard Variants (keyboard_layout_*)
**Dimensions**: 320x100 each

**Required Layouts**:
- keyboard_layout_qwerty_us.svg
- keyboard_layout_qwerty_uk.svg
- keyboard_layout_qwertz_de.svg
- keyboard_layout_azerty_fr.svg
- keyboard_layout_cyrillic_ru.svg
- keyboard_layout_japanese.svg (romaji mode)

---

## TEXT EXPANSION GUIDELINES

### Expansion Factors
| Source Length | Expansion |
|---------------|-----------|
| 1-10 chars | Up to 200% |
| 11-20 chars | Up to 100% |
| 21-30 chars | Up to 80% |
| 31-50 chars | Up to 60% |
| 51-70 chars | Up to 40% |
| 70+ chars | Up to 30% |

### UI Accommodation
```
Buttons:        Min 120% width of longest translation
Labels:         Allow 150% expansion
Tooltips:       Max 200px width, allow wrap
Dialogs:        Dynamic height
Menus:          Scrollable if needed
```

---

## TEXT ASSET STRUCTURE

### String Keys
```
Format: category.subcategory.identifier

Examples:
ui.menu.play
ui.menu.settings
game.tutorial.welcome
game.combat.wave_start
error.network.timeout
```

### Translation Files
```
localization/
├── en-US.json (base)
├── es.json
├── de.json
├── fr.json
├── pt-BR.json
└── ...
```

### JSON Structure
```json
{
  "ui": {
    "menu": {
      "play": "Play",
      "settings": "Settings",
      "quit": "Quit"
    }
  },
  "game": {
    "tutorial": {
      "welcome": "Welcome to Keyboard Defense!",
      "type_word": "Type the word to attack: {word}"
    }
  }
}
```

---

## STRING FORMATTING

### Placeholder Syntax
```
{variable}          - Simple replacement
{count:number}      - Formatted number
{score:comma}       - Comma-separated number
{time:duration}     - Duration formatting
{name}              - Player/entity name
```

### Pluralization
```json
{
  "enemies_defeated": {
    "one": "{count} enemy defeated",
    "other": "{count} enemies defeated"
  }
}
```

### Gender (if applicable)
```json
{
  "player_won": {
    "male": "{name} won his match",
    "female": "{name} won her match",
    "neutral": "{name} won their match"
  }
}
```

---

## FONT REQUIREMENTS

### Font Stacks
```
Primary (Latin):      PixelFont-Regular, fallback sans-serif
Extended Latin:       PixelFont-Extended (accents, diacritics)
Cyrillic:            PixelFont-Cyrillic or separate font
Japanese:            PixelFont-JP or system font
Chinese:             PixelFont-SC or system font
Korean:              PixelFont-KR or system font
Arabic/Hebrew:       System fonts (RTL)
```

### Character Coverage
| Language | Required Characters |
|----------|---------------------|
| English | A-Z, a-z, 0-9, punctuation |
| Spanish | + ñ, á, é, í, ó, ú, ü, ¿, ¡ |
| German | + ä, ö, ü, ß |
| French | + à, â, ç, é, è, ê, ë, î, ï, ô, ù, û, œ |
| Portuguese | + ã, õ, ç, á, é, í, ó, ú, â, ê, ô |
| Russian | Full Cyrillic А-Я, а-я |

### Font Assets
```
fonts/
├── pixel_font_latin.ttf      (base + extended)
├── pixel_font_cyrillic.ttf
├── pixel_font_japanese.ttf
├── pixel_font_chinese.ttf
├── pixel_font_korean.ttf
└── pixel_font_dyslexic.ttf   (accessibility)
```

---

## WORD LISTS PER LANGUAGE

### Typing Word Banks
Each language needs curated word lists:

```
wordlists/
├── en-US/
│   ├── common.json        (everyday words)
│   ├── lesson_homerow.json
│   ├── lesson_toprow.json
│   ├── lesson_bottomrow.json
│   ├── lesson_numbers.json
│   ├── difficulty_easy.json
│   ├── difficulty_medium.json
│   ├── difficulty_hard.json
│   └── thematic_fantasy.json
├── es/
│   └── ... (same structure)
└── ...
```

### Word List Criteria
```
Easy:       3-5 letters, common words
Medium:     5-8 letters, moderate frequency
Hard:       8+ letters, complex patterns
Thematic:   Game-relevant vocabulary
```

### Word Validation
- No offensive words
- No culturally sensitive terms
- Appropriate for all ages
- Typeable on target keyboard layout

---

## DATE/TIME FORMATTING

### Format Patterns
| Locale | Date | Time | Duration |
|--------|------|------|----------|
| en-US | MM/DD/YYYY | 12h AM/PM | 1h 23m 45s |
| en-UK | DD/MM/YYYY | 24h | 1h 23m 45s |
| de | DD.MM.YYYY | 24h | 1 Std. 23 Min. |
| fr | DD/MM/YYYY | 24h | 1h 23min 45s |
| ja | YYYY年MM月DD日 | 24h | 1時間23分45秒 |

---

## NUMBER FORMATTING

### Decimal/Thousand Separators
| Locale | Thousand | Decimal | Example |
|--------|----------|---------|---------|
| en-US | , | . | 1,234.56 |
| de | . | , | 1.234,56 |
| fr | (space) | , | 1 234,56 |

### Large Numbers
```
en:    1K, 1M, 1B
de:    1 Tsd., 1 Mio., 1 Mrd.
fr:    1 k, 1 M, 1 Md
```

---

## UI TEXT ASSETS

### Category: Menus
```
ui.menu.play
ui.menu.continue
ui.menu.settings
ui.menu.credits
ui.menu.quit
ui.menu.confirm
ui.menu.cancel
ui.menu.back
ui.menu.save
ui.menu.load
```

### Category: Settings
```
ui.settings.audio
ui.settings.video
ui.settings.controls
ui.settings.accessibility
ui.settings.language
ui.settings.master_volume
ui.settings.music_volume
ui.settings.sfx_volume
ui.settings.fullscreen
ui.settings.resolution
```

### Category: Gameplay
```
game.hud.wave
game.hud.score
game.hud.combo
game.hud.accuracy
game.hud.wpm
game.hud.health
game.hud.gold
game.wave_start
game.wave_complete
game.victory
game.defeat
```

### Category: Tutorial
```
tutorial.welcome
tutorial.typing_intro
tutorial.attack_enemy
tutorial.build_tower
tutorial.upgrade_tower
tutorial.combo_explain
tutorial.complete
tutorial.skip
tutorial.continue
```

### Category: Errors
```
error.save_failed
error.load_failed
error.network
error.generic
```

---

## IMAGE LOCALIZATION

### Text-in-Image Avoidance
Never embed text in images. Instead:
- Use overlays for labels
- Dynamic text rendering
- Separate text layers

### Culturally Neutral Art
Avoid:
- Hand gestures (meanings vary)
- Religious symbols
- National flags
- Culturally specific clothing (unless intentional)

### Direction-Aware Art
For RTL languages:
- UI layouts can mirror
- Directional icons may flip
- Progress bars reverse

---

## RTL (RIGHT-TO-LEFT) SUPPORT

### Layout Mirroring
```
Standard LTR:    [Icon] [Label] [Value] [→]
RTL Mirror:      [←] [Value] [Label] [Icon]
```

### UI Elements to Mirror
- Menu layouts
- Progress bars
- Navigation arrows
- Text alignment
- List indentation

### Non-Mirrored Elements
- Playfield (gameplay remains LTR)
- Media controls
- Numeric displays
- Brand logos

---

## LOCALIZATION TESTING

### Test Checklist
- [ ] All strings translated
- [ ] No hardcoded text
- [ ] Text fits in UI
- [ ] Special characters display
- [ ] Plurals work correctly
- [ ] Date/time formats correct
- [ ] Number formats correct
- [ ] Keyboard layout works
- [ ] Font renders correctly
- [ ] No text truncation
- [ ] RTL layout (if applicable)

### Pseudo-Localization
```
Enable pseudo-locale for testing:
"Play" → "[Þļäÿ one two]"
- Accented characters test rendering
- Brackets show string boundaries
- Padding tests expansion
```

---

## VOICE LOCALIZATION

### Dubbed Content
| Priority | Content |
|----------|---------|
| High | Tutorial narration |
| Medium | Mentor dialogue |
| Low | Enemy taunts |
| Optional | Ambient voices |

### Subtitles for All
- Always provide subtitles
- Include speaker identification
- Sound effect captions
- Configurable display options

---

## ASSET NAMING FOR L10N

### Localized Assets
```
assets/
├── textures/
│   └── title_screen.png       (no text)
├── localized/
│   ├── en-US/
│   │   └── logo_with_text.png
│   ├── es/
│   │   └── logo_with_text.png
│   └── ...
└── audio/
    └── voice/
        ├── en-US/
        │   └── tutorial_01.ogg
        └── es/
            └── tutorial_01.ogg
```

---

## TRANSLATION WORKFLOW

### Process
1. Extract strings to base JSON
2. Send to translators
3. Review translations
4. Import to game
5. Test in context
6. Fix issues
7. Repeat for updates

### Translator Notes
```json
{
  "key": "wave_start",
  "value": "Wave {wave_number} begins!",
  "context": "Displayed when new enemy wave starts",
  "max_length": 30,
  "placeholders": {
    "wave_number": "Number, 1-99"
  }
}
```

### String Freeze
- Freeze strings before translation
- Minimize changes during localization
- Track string modifications
- Version control translations

---

## IMPLEMENTATION NOTES

### Godot Integration
```gdscript
# Load translation
TranslationServer.set_locale("es")

# Get translated string
var text = tr("ui.menu.play")

# With formatting
var text = tr("game.score").format({"score": score})
```

### Font Fallback
```gdscript
# Dynamic font loading based on locale
var font_path = "res://fonts/" + get_font_for_locale(locale)
```

### Keyboard Detection
```gdscript
# Detect and adapt to keyboard layout
var layout = Input.get_keyboard_layout()
load_word_list_for_layout(layout)
```

