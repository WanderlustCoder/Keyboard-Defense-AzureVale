class_name DesignSystem
extends RefCounted
## Centralized design system for Keyboard Defense.
## Provides typography, spacing, shadows, and animation constants.
## Use these instead of hardcoding values throughout the UI codebase.

# =============================================================================
# TYPOGRAPHY SCALE
# =============================================================================
# Based on a 1.25 modular scale with 16px base

## Display text - titles, victory screens, major announcements
const FONT_DISPLAY := 32

## H1 - Panel headers, major section titles
const FONT_H1 := 24

## H2 - Section headers within panels
const FONT_H2 := 20

## H3 - Subsection headers, emphasized labels
const FONT_H3 := 18

## Body - Standard text, descriptions, content
const FONT_BODY := 16

## Body Small - Secondary information, helper text
const FONT_BODY_SMALL := 14

## Caption - Labels, hints, timestamps, metadata
const FONT_CAPTION := 12

## Mono - Numbers, commands, typed text, code
const FONT_MONO := 16

## Line height multiplier for readable text blocks
const LINE_HEIGHT := 1.4

## Dictionary for easy lookup by name
const FONT_SIZES := {
	"display": FONT_DISPLAY,
	"h1": FONT_H1,
	"h2": FONT_H2,
	"h3": FONT_H3,
	"body": FONT_BODY,
	"body_small": FONT_BODY_SMALL,
	"caption": FONT_CAPTION,
	"mono": FONT_MONO,
}

# =============================================================================
# SPACING SCALE
# =============================================================================
# Based on 4px base unit for consistent rhythm

## Extra small - Tight internal padding, icon margins
const SPACE_XS := 4

## Small - Component internal spacing, between icons and text
const SPACE_SM := 8

## Medium - Between related elements, list item padding
const SPACE_MD := 12

## Large - Between sections, panel internal margins
const SPACE_LG := 16

## Extra large - Panel padding, major section separation
const SPACE_XL := 24

## Extra extra large - Page-level separation, modal margins
const SPACE_XXL := 32

## Dictionary for easy lookup by name
const SPACING := {
	"xs": SPACE_XS,
	"sm": SPACE_SM,
	"md": SPACE_MD,
	"lg": SPACE_LG,
	"xl": SPACE_XL,
	"xxl": SPACE_XXL,
}

# =============================================================================
# SIZING SCALE
# =============================================================================
# Standard component sizes for consistency

## Minimum touch target size (accessibility)
const SIZE_TOUCH_MIN := 44

## Small button height
const SIZE_BUTTON_SM := 32

## Medium button height (default)
const SIZE_BUTTON_MD := 40

## Large button height
const SIZE_BUTTON_LG := 48

## Icon sizes
const SIZE_ICON_SM := 16
const SIZE_ICON_MD := 24
const SIZE_ICON_LG := 32
const SIZE_ICON_XL := 48

## Panel widths
const SIZE_PANEL_SM := 320
const SIZE_PANEL_MD := 480
const SIZE_PANEL_LG := 640
const SIZE_PANEL_XL := 800

# =============================================================================
# BORDER RADIUS
# =============================================================================

## Small radius - buttons, inputs, chips
const RADIUS_SM := 4

## Medium radius - cards, panels
const RADIUS_MD := 8

## Large radius - modals, dialogs
const RADIUS_LG := 12

## Full radius - pills, circular elements
const RADIUS_FULL := 9999

# =============================================================================
# SHADOWS
# =============================================================================
# Shadow definitions as dictionaries for StyleBoxFlat

## Subtle shadow for cards and elevated elements
const SHADOW_SM := {
	"size": 2,
	"offset": Vector2(0, 1),
	"color": Color(0, 0, 0, 0.15)
}

## Medium shadow for floating panels
const SHADOW_MD := {
	"size": 4,
	"offset": Vector2(0, 2),
	"color": Color(0, 0, 0, 0.2)
}

## Large shadow for modals and overlays
const SHADOW_LG := {
	"size": 8,
	"offset": Vector2(0, 4),
	"color": Color(0, 0, 0, 0.25)
}

## Glow effect for focus states
const SHADOW_GLOW := {
	"size": 6,
	"offset": Vector2(0, 0),
	"color": Color(0.98, 0.84, 0.44, 0.3)  # Gold glow
}

# =============================================================================
# ANIMATION TIMING
# =============================================================================
# Consistent animation durations across the UI

## Instant feedback - button press, keystroke highlight
const ANIM_INSTANT := 0.05

## Fast transitions - hover states, small changes
const ANIM_FAST := 0.15

## Normal transitions - panel open/close, fades
const ANIM_NORMAL := 0.25

## Slow transitions - scene changes, major state shifts
const ANIM_SLOW := 0.4

## Very slow - dramatic reveals, story moments
const ANIM_DRAMATIC := 0.6

## Dictionary for easy lookup by name
const ANIM_DURATIONS := {
	"instant": ANIM_INSTANT,
	"fast": ANIM_FAST,
	"normal": ANIM_NORMAL,
	"slow": ANIM_SLOW,
	"dramatic": ANIM_DRAMATIC,
}

# =============================================================================
# EASING CURVES
# =============================================================================
# Standard easing for consistent motion feel

## Default ease for most transitions
const EASE_DEFAULT := Tween.EASE_OUT

## Transition type for smooth animations
const TRANS_DEFAULT := Tween.TRANS_QUAD

## Bounce for playful feedback
const TRANS_BOUNCE := Tween.TRANS_BOUNCE

## Elastic for attention-grabbing effects
const TRANS_ELASTIC := Tween.TRANS_ELASTIC

# =============================================================================
# Z-INDEX LAYERS
# =============================================================================
# Consistent layering for UI elements

## Base game content
const Z_GAME := 0

## HUD elements (always visible)
const Z_HUD := 10

## Floating panels
const Z_PANEL := 20

## Tooltips
const Z_TOOLTIP := 30

## Modals and dialogs
const Z_MODAL := 40

## Notifications and toasts
const Z_NOTIFICATION := 50

## Loading overlays
const Z_LOADING := 60

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

## Creates a StyleBoxFlat with standard panel styling
static func create_panel_style(
	bg_color: Color = ThemeColors.BG_PANEL,
	border_color: Color = ThemeColors.BORDER,
	corner_radius: int = RADIUS_MD,
	border_width: int = 1
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = SPACE_XL
	style.content_margin_right = SPACE_XL
	style.content_margin_top = SPACE_LG
	style.content_margin_bottom = SPACE_LG
	return style


## Creates a StyleBoxFlat with shadow
static func create_elevated_style(
	bg_color: Color = ThemeColors.BG_CARD,
	shadow: Dictionary = SHADOW_MD
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(RADIUS_MD)
	style.shadow_size = shadow.size
	style.shadow_offset = shadow.offset
	style.shadow_color = shadow.color
	style.content_margin_left = SPACE_LG
	style.content_margin_right = SPACE_LG
	style.content_margin_top = SPACE_MD
	style.content_margin_bottom = SPACE_MD
	return style


## Creates a standard button StyleBoxFlat
static func create_button_style(
	bg_color: Color = ThemeColors.BG_BUTTON,
	border_color: Color = ThemeColors.BORDER,
	pressed: bool = false
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color if not pressed else bg_color.darkened(0.1)
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(RADIUS_SM)
	style.content_margin_left = SPACE_LG
	style.content_margin_right = SPACE_LG
	style.content_margin_top = SPACE_SM
	style.content_margin_bottom = SPACE_SM
	return style


## Applies standard label styling with typography level
static func style_label(label: Label, level: String = "body", color: Color = ThemeColors.TEXT) -> void:
	label.add_theme_font_size_override("font_size", FONT_SIZES.get(level, FONT_BODY))
	label.add_theme_color_override("font_color", color)


## Creates a horizontal spacer Control
static func create_spacer(expand: bool = true) -> Control:
	var spacer := Control.new()
	if expand:
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spacer


## Creates a vertical separator with spacing
static func create_separator(height: int = 1, color: Color = ThemeColors.BORDER) -> ColorRect:
	var sep := ColorRect.new()
	sep.color = color
	sep.custom_minimum_size.y = height
	return sep


## Creates an HBoxContainer with standard spacing
static func create_hbox(spacing: int = SPACE_MD) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", spacing)
	return hbox


## Creates a VBoxContainer with standard spacing
static func create_vbox(spacing: int = SPACE_MD) -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", spacing)
	return vbox


## Creates a MarginContainer with uniform margins
static func create_margin(margin: int = SPACE_LG) -> MarginContainer:
	var container := MarginContainer.new()
	container.add_theme_constant_override("margin_left", margin)
	container.add_theme_constant_override("margin_right", margin)
	container.add_theme_constant_override("margin_top", margin)
	container.add_theme_constant_override("margin_bottom", margin)
	return container


## Configures a tween with standard settings
static func configure_tween(tween: Tween, duration: float = ANIM_NORMAL) -> Tween:
	return tween.set_ease(EASE_DEFAULT).set_trans(TRANS_DEFAULT)


## Returns appropriate font size for a typography level
static func get_font_size(level: String) -> int:
	return FONT_SIZES.get(level, FONT_BODY)


## Returns appropriate spacing for a spacing level
static func get_spacing(level: String) -> int:
	return SPACING.get(level, SPACE_MD)


## Returns appropriate animation duration for a speed level
static func get_anim_duration(speed: String) -> float:
	return ANIM_DURATIONS.get(speed, ANIM_NORMAL)
