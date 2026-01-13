extends Node
## Centralized color definitions for Keyboard Defense UI.
## Use these instead of hardcoding Color() values throughout the codebase.
## Registered as autoload - access via ThemeColors.CONSTANT_NAME

# ============================================================================
# BACKGROUND COLORS
# ============================================================================

## Main application background
const BG_DARK := Color(0.04, 0.035, 0.06, 1)
## Panel backgrounds
const BG_PANEL := Color(0.08, 0.07, 0.12, 0.95)
## Card backgrounds (unlocked/active state)
const BG_CARD := Color(0.14, 0.12, 0.22, 1)
## Card backgrounds (locked/disabled state)
const BG_CARD_DISABLED := Color(0.11, 0.1, 0.17, 1)
## Button normal state
const BG_BUTTON := Color(0.18, 0.16, 0.28, 1)
## Button hover state
const BG_BUTTON_HOVER := Color(0.22, 0.2, 0.35, 1)
## Input fields
const BG_INPUT := Color(0.06, 0.055, 0.09, 1)

# ============================================================================
# BORDER COLORS
# ============================================================================

## Standard border
const BORDER := Color(0.24, 0.22, 0.36, 1)
## Highlighted/completed border
const BORDER_HIGHLIGHT := Color(0.35, 0.32, 0.52, 1)
## Focused element border
const BORDER_FOCUS := Color(0.45, 0.42, 0.62, 1)
## Disabled element border
const BORDER_DISABLED := Color(0.2, 0.18, 0.28, 1)

# ============================================================================
# TEXT COLORS
# ============================================================================

## Primary text color
const TEXT := Color(0.94, 0.94, 0.98, 1)
## Dimmed/secondary text
const TEXT_DIM := Color(0.94, 0.94, 0.98, 0.55)
## Disabled text
const TEXT_DISABLED := Color(0.5, 0.5, 0.55, 0.6)
## Placeholder text
const TEXT_PLACEHOLDER := Color(0.5, 0.5, 0.55, 0.8)

# ============================================================================
# ACCENT COLORS
# ============================================================================

## Primary accent (gold)
const ACCENT := Color(0.98, 0.84, 0.44, 1)
## Secondary accent (sky blue)
const ACCENT_BLUE := Color(0.65, 0.86, 1, 1)
## Cool accent (cyan)
const ACCENT_CYAN := Color(0.45, 0.75, 0.95, 1)

# ============================================================================
# STATUS COLORS
# ============================================================================

## Success/positive
const SUCCESS := Color(0.45, 0.82, 0.55, 1)
## Warning/caution
const WARNING := Color(0.98, 0.84, 0.44, 1)
## Error/danger
const ERROR := Color(0.96, 0.45, 0.45, 1)
## Info/neutral
const INFO := Color(0.65, 0.86, 1, 1)

# ============================================================================
# GAMEPLAY COLORS
# ============================================================================

## Threat bar fill
const THREAT := Color(0.9, 0.4, 0.35, 1)
## Castle health positive
const CASTLE_HEALTHY := Color(0.45, 0.82, 0.55, 1)
## Castle health low
const CASTLE_DAMAGED := Color(0.96, 0.45, 0.45, 1)
## Buff active indicator
const BUFF_ACTIVE := Color(0.98, 0.84, 0.44, 1)
## Correctly typed text
const TYPED_CORRECT := Color(0.65, 0.86, 1, 1)
## Incorrectly typed text
const TYPED_ERROR := Color(0.96, 0.45, 0.45, 1)
## Pending text to type
const TYPED_PENDING := Color(0.94, 0.94, 0.98, 0.4)

# ============================================================================
# SHADOW COLORS
# ============================================================================

## Shadow for elevated elements
const SHADOW := Color(0, 0, 0, 0.25)
## Deeper shadow for modals
const SHADOW_DEEP := Color(0, 0, 0, 0.4)
## Glow effect (gold)
const GLOW := Color(0.98, 0.84, 0.44, 0.3)
## Glow effect (blue)
const GLOW_BLUE := Color(0.65, 0.86, 1, 0.3)
## Glow effect (error)
const GLOW_ERROR := Color(0.96, 0.45, 0.45, 0.3)

# ============================================================================
# OVERLAY COLORS
# ============================================================================

## Modal backdrop overlay
const OVERLAY := Color(0, 0, 0, 0.6)
## Light overlay for hover states
const OVERLAY_LIGHT := Color(1, 1, 1, 0.05)
## Dark overlay for dimmed states
const OVERLAY_DARK := Color(0, 0, 0, 0.3)

# ============================================================================
# RESOURCE COLORS
# ============================================================================

## Wood resource
const RESOURCE_WOOD := Color(0.6, 0.4, 0.2, 1)
## Stone resource
const RESOURCE_STONE := Color(0.5, 0.5, 0.55, 1)
## Food resource
const RESOURCE_FOOD := Color(0.4, 0.7, 0.3, 1)
## Gold resource
const RESOURCE_GOLD := Color(0.98, 0.84, 0.44, 1)

# ============================================================================
# FACTION COLORS
# ============================================================================

## Player kingdom
const FACTION_PLAYER := Color(0.3, 0.5, 0.9, 1)
## Neutral faction
const FACTION_NEUTRAL := Color(0.5, 0.5, 0.5, 1)
## Hostile faction
const FACTION_HOSTILE := Color(0.9, 0.3, 0.3, 1)
## Allied faction
const FACTION_ALLIED := Color(0.3, 0.7, 0.4, 1)

# ============================================================================
# RARITY COLORS
# ============================================================================

## Common tier
const RARITY_COMMON := Color(0.7, 0.7, 0.7, 1)
## Uncommon tier
const RARITY_UNCOMMON := Color(0.3, 0.8, 0.3, 1)
## Rare tier
const RARITY_RARE := Color(0.3, 0.5, 0.9, 1)
## Epic tier
const RARITY_EPIC := Color(0.7, 0.3, 0.9, 1)
## Legendary tier
const RARITY_LEGENDARY := Color(0.98, 0.84, 0.44, 1)

# ============================================================================
# MORALE/HAPPINESS COLORS
# ============================================================================

## Very low morale
const MORALE_CRITICAL := Color(0.9, 0.2, 0.2, 1)
## Low morale
const MORALE_LOW := Color(0.9, 0.5, 0.2, 1)
## Normal morale
const MORALE_NORMAL := Color(0.7, 0.7, 0.3, 1)
## High morale
const MORALE_HIGH := Color(0.4, 0.8, 0.4, 1)
## Excellent morale
const MORALE_EXCELLENT := Color(0.3, 0.9, 0.5, 1)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

## Returns text color with specified alpha
static func text_alpha(alpha: float) -> Color:
	var c := TEXT
	c.a = alpha
	return c

## Returns accent color with specified alpha
static func accent_alpha(alpha: float) -> Color:
	var c := ACCENT
	c.a = alpha
	return c

## Returns error color with specified alpha
static func error_alpha(alpha: float) -> Color:
	var c := ERROR
	c.a = alpha
	return c

## Returns success color with specified alpha
static func success_alpha(alpha: float) -> Color:
	var c := SUCCESS
	c.a = alpha
	return c

## Returns a color with modified alpha
static func with_alpha(color: Color, alpha: float) -> Color:
	var c := color
	c.a = alpha
	return c

## Returns a color lightened by amount (0-1)
static func lighten(color: Color, amount: float) -> Color:
	return color.lightened(amount)

## Returns a color darkened by amount (0-1)
static func darken(color: Color, amount: float) -> Color:
	return color.darkened(amount)

## Returns appropriate resource color by name
static func get_resource_color(resource: String) -> Color:
	match resource:
		"wood": return RESOURCE_WOOD
		"stone": return RESOURCE_STONE
		"food": return RESOURCE_FOOD
		"gold": return RESOURCE_GOLD
		_: return TEXT

## Returns appropriate rarity color by tier (1-5)
static func get_rarity_color(tier: int) -> Color:
	match tier:
		1: return RARITY_COMMON
		2: return RARITY_UNCOMMON
		3: return RARITY_RARE
		4: return RARITY_EPIC
		5: return RARITY_LEGENDARY
		_: return RARITY_COMMON

## Returns appropriate morale color by value (0-100)
static func get_morale_color(morale: float) -> Color:
	if morale < 20:
		return MORALE_CRITICAL
	elif morale < 40:
		return MORALE_LOW
	elif morale < 60:
		return MORALE_NORMAL
	elif morale < 80:
		return MORALE_HIGH
	else:
		return MORALE_EXCELLENT

## Returns color interpolated between two colors based on t (0-1)
static func lerp_color(from: Color, to: Color, t: float) -> Color:
	return from.lerp(to, clampf(t, 0, 1))

## Returns health bar color based on percentage (0-1)
static func get_health_color(percentage: float) -> Color:
	if percentage > 0.6:
		return CASTLE_HEALTHY
	elif percentage > 0.3:
		return WARNING
	else:
		return CASTLE_DAMAGED

# ============================================================================
# HIGH CONTRAST MODE COLORS
# ============================================================================

const HC_BG := Color(0, 0, 0, 1)
const HC_FG := Color(1, 1, 1, 1)
const HC_ACCENT := Color(1, 1, 0, 1)  # Yellow for best visibility
const HC_ERROR := Color(1, 0.3, 0.3, 1)  # Bright red
const HC_SUCCESS := Color(0.3, 1, 0.3, 1)  # Bright green
const HC_BORDER := Color(1, 1, 1, 1)

## Get background color with high contrast support
static func get_bg(high_contrast: bool = false) -> Color:
	return HC_BG if high_contrast else BG_PANEL

## Get text color with high contrast support
static func get_text(high_contrast: bool = false) -> Color:
	return HC_FG if high_contrast else TEXT

## Get accent color with high contrast support
static func get_accent(high_contrast: bool = false) -> Color:
	return HC_ACCENT if high_contrast else ACCENT

## Get error color with high contrast support
static func get_error(high_contrast: bool = false) -> Color:
	return HC_ERROR if high_contrast else ERROR

## Get success color with high contrast support
static func get_success(high_contrast: bool = false) -> Color:
	return HC_SUCCESS if high_contrast else SUCCESS

## Get border color with high contrast support
static func get_border(high_contrast: bool = false) -> Color:
	return HC_BORDER if high_contrast else BORDER

## Get typed correct color with accessibility support
static func get_typed_correct(high_contrast: bool = false, colorblind_mode: String = "none") -> Color:
	if high_contrast:
		return HC_SUCCESS
	match colorblind_mode:
		"protanopia", "deuteranopia":
			return Color(0.73, 0.87, 1, 1)  # Light blue
		"tritanopia":
			return Color(0.53, 0.8, 0.8, 1)  # Light teal
		_:
			return TYPED_CORRECT

## Get typed error color with accessibility support
static func get_typed_error(high_contrast: bool = false, colorblind_mode: String = "none") -> Color:
	if high_contrast:
		return HC_ERROR
	match colorblind_mode:
		"protanopia", "deuteranopia":
			return Color(0, 0.47, 0.73, 1)  # Blue
		"tritanopia":
			return Color(0.8, 0.2, 0.07, 1)  # Red-orange
		_:
			return TYPED_ERROR

## Get enemy color with accessibility support
static func get_enemy_color(high_contrast: bool = false, colorblind_mode: String = "none") -> Color:
	if high_contrast:
		return HC_ERROR
	match colorblind_mode:
		"protanopia", "deuteranopia":
			return Color(0, 0.47, 0.73, 1)  # Blue
		"tritanopia":
			return Color(0.8, 0.2, 0.07, 1)  # Red-orange
		_:
			return FACTION_HOSTILE

## Get friendly/allied color with accessibility support
static func get_friendly_color(high_contrast: bool = false, colorblind_mode: String = "none") -> Color:
	if high_contrast:
		return HC_SUCCESS
	match colorblind_mode:
		"protanopia", "deuteranopia":
			return Color(0.93, 0.47, 0.2, 1)  # Orange
		"tritanopia":
			return Color(0, 0.6, 0.53, 1)  # Teal
		_:
			return FACTION_ALLIED
