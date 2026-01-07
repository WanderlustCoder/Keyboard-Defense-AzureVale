class_name ThemeColors
extends RefCounted
## Centralized color definitions for Keyboard Defense UI.
## Use these instead of hardcoding Color() values throughout the codebase.

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
