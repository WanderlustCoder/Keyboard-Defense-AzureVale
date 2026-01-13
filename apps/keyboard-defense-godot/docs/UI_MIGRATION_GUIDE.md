# UI Component Migration Guide

This guide documents how to migrate existing UI components to use the DesignSystem and ThemeColors for consistency across the Keyboard Defense UI.

## Overview

The design system provides:
- **DesignSystem** (`ui/design_system.gd`) - Typography, spacing, sizing, shadows, animation constants
- **ThemeColors** (`ui/theme_colors.gd`) - All color definitions with accessibility support
- **BasePanel** (`ui/base_panel.gd`) - Base class for panels with common patterns
- **BaseButton** (`ui/base_button.gd`) - Button variant factory methods

## Migration Checklist

For each component, verify:
- [ ] No hardcoded Color() values (use ThemeColors)
- [ ] No hardcoded font sizes (use DesignSystem.FONT_*)
- [ ] No hardcoded spacing values (use DesignSystem.SPACE_*)
- [ ] No manual StyleBoxFlat creation for common patterns (use DesignSystem helpers)
- [ ] Uses DesignSystem.style_label() for label styling
- [ ] Uses DesignSystem.create_vbox/hbox() for containers

## Common Replacements

### Colors

```gdscript
# BEFORE: Hardcoded colors
var bg := Color(0.08, 0.09, 0.12, 0.98)
var text := Color(0.9, 0.9, 0.9)
var gold := Color(1.0, 0.84, 0.0)

# AFTER: ThemeColors
var bg := ThemeColors.BG_PANEL
var text := ThemeColors.TEXT
var gold := ThemeColors.ACCENT
```

### Resource Colors

```gdscript
# BEFORE: Local dictionary
const RESOURCE_COLORS = {
    "wood": Color(0.6, 0.4, 0.2),
    "stone": Color(0.6, 0.6, 0.7),
}
var color = RESOURCE_COLORS.get(resource_name, Color.WHITE)

# AFTER: ThemeColors helper
var color = ThemeColors.get_resource_color(resource_name)
```

### Font Sizes

```gdscript
# BEFORE: Hardcoded sizes
label.add_theme_font_size_override("font_size", 18)
label.add_theme_font_size_override("font_size", 12)
label.add_theme_font_size_override("font_size", 14)

# AFTER: DesignSystem typography scale
DesignSystem.style_label(label, "h2", ThemeColors.TEXT)  # 20px
DesignSystem.style_label(label, "caption", ThemeColors.TEXT_DIM)  # 12px
DesignSystem.style_label(label, "body_small", ThemeColors.TEXT)  # 14px
```

### Typography Levels

| Level | Size | Use Case |
|-------|------|----------|
| `display` | 32px | Victory screens, major titles |
| `h1` | 24px | Panel headers |
| `h2` | 20px | Section headers |
| `h3` | 18px | Subsection headers |
| `body` | 16px | Standard text |
| `body_small` | 14px | Secondary info |
| `caption` | 12px | Labels, hints |
| `mono` | 16px | Numbers, commands |

### Spacing

```gdscript
# BEFORE: Hardcoded spacing
vbox.add_theme_constant_override("separation", 10)
container.custom_minimum_size.y = 48
panel.set_content_margin_all(12)

# AFTER: DesignSystem spacing
vbox.add_theme_constant_override("separation", DesignSystem.SPACE_MD)  # 12
container.custom_minimum_size.y = DesignSystem.SIZE_TOUCH_MIN  # 44
panel.set_content_margin_all(DesignSystem.SPACE_MD)  # 12
```

### Spacing Scale

| Level | Size | Use Case |
|-------|------|----------|
| `SPACE_XS` | 4px | Tight internal padding |
| `SPACE_SM` | 8px | Component spacing |
| `SPACE_MD` | 12px | Between related elements |
| `SPACE_LG` | 16px | Between sections |
| `SPACE_XL` | 24px | Panel padding |
| `SPACE_XXL` | 32px | Major separation |

### Containers

```gdscript
# BEFORE: Manual container setup
var vbox := VBoxContainer.new()
vbox.add_theme_constant_override("separation", 10)

var hbox := HBoxContainer.new()
hbox.add_theme_constant_override("separation", 8)

# AFTER: DesignSystem helpers
var vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_SM)
```

### Panel Styling

```gdscript
# BEFORE: Manual StyleBoxFlat
var style := StyleBoxFlat.new()
style.bg_color = Color(0.08, 0.09, 0.12, 0.98)
style.border_color = Color(0.3, 0.3, 0.4)
style.set_border_width_all(1)
style.set_corner_radius_all(4)
style.set_content_margin_all(12)
add_theme_stylebox_override("panel", style)

# AFTER: DesignSystem helper
var style := DesignSystem.create_panel_style()
add_theme_stylebox_override("panel", style)

# Or with custom colors:
var style := DesignSystem.create_panel_style(
    ThemeColors.BG_CARD,
    ThemeColors.BORDER_HIGHLIGHT,
    DesignSystem.RADIUS_LG,
    2
)
```

### Elevated Cards

```gdscript
# BEFORE: Manual shadow setup
var style := StyleBoxFlat.new()
style.bg_color = some_color
style.shadow_size = 4
style.shadow_offset = Vector2(0, 2)
style.shadow_color = Color(0, 0, 0, 0.2)

# AFTER: DesignSystem helper
var style := DesignSystem.create_elevated_style(ThemeColors.BG_CARD)
# Or with specific shadow:
var style := DesignSystem.create_elevated_style(ThemeColors.BG_CARD, DesignSystem.SHADOW_LG)
```

### Button Styling

```gdscript
# BEFORE: Manual button styles
var normal := StyleBoxFlat.new()
normal.bg_color = Color(0.18, 0.16, 0.28)
# ... more setup

# AFTER: DesignSystem helper
var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
var hover := DesignSystem.create_button_style(ThemeColors.BG_BUTTON_HOVER, ThemeColors.BORDER_HIGHLIGHT)
button.add_theme_stylebox_override("normal", normal)
button.add_theme_stylebox_override("hover", hover)
```

### Labels

```gdscript
# BEFORE: Multiple overrides
label.add_theme_font_size_override("font_size", 14)
label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))

# AFTER: Single call
DesignSystem.style_label(label, "body_small", ThemeColors.TEXT_DIM)
```

### Spacers

```gdscript
# BEFORE: Manual spacer
var spacer := Control.new()
spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL

# AFTER: Helper
header.add_child(DesignSystem.create_spacer())
```

### Separators

```gdscript
# BEFORE: Manual separator
var sep := HSeparator.new()

# AFTER: Themed separator
content.add_child(DesignSystem.create_separator())
```

## ThemeColors Reference

### Backgrounds
- `BG_DARK` - Main app background
- `BG_PANEL` - Panel backgrounds
- `BG_CARD` - Card backgrounds
- `BG_CARD_DISABLED` - Disabled card state
- `BG_BUTTON` - Button normal state
- `BG_BUTTON_HOVER` - Button hover state
- `BG_INPUT` - Input fields

### Text
- `TEXT` - Primary text
- `TEXT_DIM` - Secondary/dimmed text
- `TEXT_DISABLED` - Disabled text
- `TEXT_PLACEHOLDER` - Placeholder text

### Status
- `SUCCESS` - Success/positive
- `WARNING` - Warning/caution
- `ERROR` - Error/danger
- `INFO` - Info/neutral

### Resources
- `RESOURCE_WOOD` - Wood color
- `RESOURCE_STONE` - Stone color
- `RESOURCE_FOOD` - Food color
- `RESOURCE_GOLD` - Gold color
- `get_resource_color(name)` - Helper function

### Factions
- `FACTION_PLAYER` - Player kingdom
- `FACTION_NEUTRAL` - Neutral faction
- `FACTION_HOSTILE` - Hostile faction
- `FACTION_ALLIED` - Allied faction

### Morale
- `MORALE_CRITICAL` - Very low (<20)
- `MORALE_LOW` - Low (20-40)
- `MORALE_NORMAL` - Normal (40-60)
- `MORALE_HIGH` - High (60-80)
- `MORALE_EXCELLENT` - Excellent (80+)
- `get_morale_color(value)` - Helper function

## Complete Migration Example

### Before Migration

```gdscript
class_name MyPanel
extends PanelContainer

const COLORS = {
    "wood": Color(0.6, 0.4, 0.2),
    "stone": Color(0.6, 0.6, 0.7),
}

func _ready() -> void:
    custom_minimum_size = Vector2(400, 300)

    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.08, 0.09, 0.12, 0.98)
    style.border_color = Color(0.3, 0.3, 0.4)
    style.set_border_width_all(1)
    style.set_corner_radius_all(4)
    style.set_content_margin_all(12)
    add_theme_stylebox_override("panel", style)

    var vbox := VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 10)
    add_child(vbox)

    var title := Label.new()
    title.text = "My Panel"
    title.add_theme_font_size_override("font_size", 18)
    title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
    vbox.add_child(title)

    var desc := Label.new()
    desc.text = "Description text"
    desc.add_theme_font_size_override("font_size", 12)
    desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
    vbox.add_child(desc)
```

### After Migration

```gdscript
class_name MyPanel
extends PanelContainer

func _ready() -> void:
    custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_SM, 300)

    var style := DesignSystem.create_panel_style()
    add_theme_stylebox_override("panel", style)

    var vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
    add_child(vbox)

    var title := Label.new()
    title.text = "My Panel"
    DesignSystem.style_label(title, "h2", ThemeColors.ACCENT)
    vbox.add_child(title)

    var desc := Label.new()
    desc.text = "Description text"
    DesignSystem.style_label(desc, "caption", ThemeColors.TEXT_DIM)
    vbox.add_child(desc)
```

## Migration Priority

High priority (user-facing, frequently used):
1. Settings panels
2. Game HUD components
3. Building/research/trade panels
4. Combat UI

Medium priority:
5. Encyclopedia/reference panels
6. Statistics/metrics panels
7. Achievement panels

Lower priority:
8. Debug panels
9. Developer tools

## Verification

After migration, verify:
1. Colors match the design system palette
2. Typography is consistent with the scale
3. Spacing feels balanced
4. High contrast mode still works
5. No hardcoded values remain
