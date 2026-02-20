class_name Accessibility
extends RefCounted
## Accessibility utilities for colorblind support, focus indicators, and screen reader hints.

# =============================================================================
# COLORBLIND-SAFE PALETTES
# =============================================================================

## Standard game colors - used when colorblind mode is "none"
const PALETTE_NORMAL := {
	"enemy": Color("#dc143c"),       # Crimson red
	"friendly": Color("#32cd32"),    # Lime green
	"warning": Color("#ffa500"),     # Orange
	"info": Color("#4169e1"),        # Royal blue
	"success": Color("#32cd32"),     # Lime green
	"danger": Color("#dc143c"),      # Crimson red
	"gold": Color("#ffd700"),        # Gold
	"health_full": Color("#32cd32"), # Green
	"health_mid": Color("#ffa500"),  # Orange
	"health_low": Color("#dc143c"),  # Red
	"typed_correct": Color("#90ee90"), # Light green
	"typed_wrong": Color("#ff6b6b"),   # Light red
	"highlight": Color("#ffff00"),     # Yellow
}

## Protanopia-friendly palette (red-blind)
## Replaces red/green distinctions with blue/orange
const PALETTE_PROTANOPIA := {
	"enemy": Color("#0077bb"),       # Blue (instead of red)
	"friendly": Color("#ee7733"),    # Orange (instead of green)
	"warning": Color("#ccbb44"),     # Yellow
	"info": Color("#0077bb"),        # Blue
	"success": Color("#ee7733"),     # Orange
	"danger": Color("#0077bb"),      # Blue
	"gold": Color("#ccbb44"),        # Yellow
	"health_full": Color("#ee7733"), # Orange
	"health_mid": Color("#ccbb44"),  # Yellow
	"health_low": Color("#0077bb"),  # Blue
	"typed_correct": Color("#bbddff"), # Light blue
	"typed_wrong": Color("#0077bb"),   # Blue
	"highlight": Color("#ccbb44"),     # Yellow
}

## Deuteranopia-friendly palette (green-blind)
## Similar to protanopia, uses blue/orange distinction
const PALETTE_DEUTERANOPIA := {
	"enemy": Color("#0077bb"),       # Blue
	"friendly": Color("#ee7733"),    # Orange
	"warning": Color("#ccbb44"),     # Yellow
	"info": Color("#0077bb"),        # Blue
	"success": Color("#ee7733"),     # Orange
	"danger": Color("#0077bb"),      # Blue
	"gold": Color("#ccbb44"),        # Yellow
	"health_full": Color("#ee7733"), # Orange
	"health_mid": Color("#ccbb44"),  # Yellow
	"health_low": Color("#0077bb"),  # Blue
	"typed_correct": Color("#bbddff"), # Light blue
	"typed_wrong": Color("#0077bb"),   # Blue
	"highlight": Color("#ccbb44"),     # Yellow
}

## Tritanopia-friendly palette (blue-blind)
## Uses red/cyan distinction
const PALETTE_TRITANOPIA := {
	"enemy": Color("#cc3311"),       # Red-orange
	"friendly": Color("#009988"),    # Teal
	"warning": Color("#ee3377"),     # Magenta
	"info": Color("#009988"),        # Teal
	"success": Color("#009988"),     # Teal
	"danger": Color("#cc3311"),      # Red-orange
	"gold": Color("#ee3377"),        # Magenta
	"health_full": Color("#009988"), # Teal
	"health_mid": Color("#ee3377"),  # Magenta
	"health_low": Color("#cc3311"),  # Red-orange
	"typed_correct": Color("#88cccc"), # Light teal
	"typed_wrong": Color("#cc3311"),   # Red-orange
	"highlight": Color("#ee3377"),     # Magenta
}


## Get a color from the appropriate colorblind palette
static func get_color(color_key: String, mode: String = "none") -> Color:
	var palette: Dictionary
	match mode:
		"protanopia":
			palette = PALETTE_PROTANOPIA
		"deuteranopia":
			palette = PALETTE_DEUTERANOPIA
		"tritanopia":
			palette = PALETTE_TRITANOPIA
		_:
			palette = PALETTE_NORMAL

	return palette.get(color_key, Color.WHITE)


## Get the full palette for current mode
static func get_palette(mode: String = "none") -> Dictionary:
	match mode:
		"protanopia":
			return PALETTE_PROTANOPIA.duplicate()
		"deuteranopia":
			return PALETTE_DEUTERANOPIA.duplicate()
		"tritanopia":
			return PALETTE_TRITANOPIA.duplicate()
		_:
			return PALETTE_NORMAL.duplicate()


# =============================================================================
# SHAPE INDICATORS (secondary identification beyond color)
# =============================================================================

## Shape indicators for elements that shouldn't rely solely on color
const SHAPE_INDICATORS := {
	"enemy": "diamond",      # ◆
	"friendly": "circle",    # ●
	"warning": "triangle",   # ▲
	"info": "square",        # ■
	"health_full": "heart",  # ♥
	"health_low": "cross",   # ✚
}


## Get shape indicator for an element type
static func get_shape_indicator(element_type: String) -> String:
	return SHAPE_INDICATORS.get(element_type, "circle")


## Unicode symbols for shape indicators
const SHAPE_SYMBOLS := {
	"diamond": "◆",
	"circle": "●",
	"triangle": "▲",
	"square": "■",
	"heart": "♥",
	"cross": "✚",
	"star": "★",
	"arrow_right": "►",
	"arrow_left": "◄",
	"check": "✓",
	"x": "✗",
}


## Get unicode symbol for a shape
static func get_shape_symbol(shape: String) -> String:
	return SHAPE_SYMBOLS.get(shape, "●")


# =============================================================================
# FOCUS INDICATORS
# =============================================================================

const FOCUS_OUTLINE_WIDTH := 3.0
const FOCUS_OUTLINE_COLOR := Color(1.0, 1.0, 1.0, 0.9)
const FOCUS_OUTLINE_COLOR_HIGH_CONTRAST := Color(1.0, 1.0, 0.0, 1.0)


## Get focus indicator style based on settings
static func get_focus_style(high_contrast: bool = false) -> Dictionary:
	return {
		"width": FOCUS_OUTLINE_WIDTH,
		"color": FOCUS_OUTLINE_COLOR_HIGH_CONTRAST if high_contrast else FOCUS_OUTLINE_COLOR,
		"offset": 2.0,
	}


## Apply focus indicator to a control
static func apply_focus_indicator(control: Control, high_contrast: bool = false) -> void:
	var style := get_focus_style(high_contrast)
	var stylebox := StyleBoxFlat.new()
	stylebox.draw_center = false
	stylebox.border_width_left = int(style.width)
	stylebox.border_width_right = int(style.width)
	stylebox.border_width_top = int(style.width)
	stylebox.border_width_bottom = int(style.width)
	stylebox.border_color = style.color
	stylebox.set_expand_margin_all(style.offset)
	control.add_theme_stylebox_override("focus", stylebox)


# =============================================================================
# SCREEN READER HINTS
# =============================================================================

## Generate screen reader hint for a button
static func button_hint(label: String, shortcut: String = "") -> String:
	if shortcut.is_empty():
		return "Button: %s. Press Enter to activate." % label
	return "Button: %s. Shortcut: %s. Press Enter to activate." % [label, shortcut]


## Generate screen reader hint for a slider
static func slider_hint(label: String, value: float, min_val: float, max_val: float) -> String:
	var percent := int((value - min_val) / (max_val - min_val) * 100)
	return "Slider: %s. Value: %d%%. Use arrow keys to adjust." % [label, percent]


## Generate screen reader hint for a checkbox
static func checkbox_hint(label: String, checked: bool) -> String:
	var state := "checked" if checked else "unchecked"
	return "Checkbox: %s. Currently %s. Press Space to toggle." % [label, state]


## Generate screen reader hint for a panel
static func panel_hint(title: String, item_count: int = -1) -> String:
	if item_count >= 0:
		return "Panel: %s. Contains %d items. Press Escape to close." % [title, item_count]
	return "Panel: %s. Press Escape to close." % title


## Generate screen reader hint for enemy
static func enemy_hint(enemy_name: String, word: String, hp: int, max_hp: int) -> String:
	return "Enemy: %s. Word: %s. Health: %d of %d." % [enemy_name, word, hp, max_hp]


## Generate screen reader hint for resource
static func resource_hint(resource_name: String, amount: int, max_amount: int = -1) -> String:
	if max_amount > 0:
		return "Resource: %s. Amount: %d of %d." % [resource_name, amount, max_amount]
	return "Resource: %s. Amount: %d." % [resource_name, amount]


# =============================================================================
# HIGH CONTRAST MODE
# =============================================================================

## High contrast background colors
const HIGH_CONTRAST_BG := Color(0.0, 0.0, 0.0, 1.0)
const HIGH_CONTRAST_FG := Color(1.0, 1.0, 1.0, 1.0)
const HIGH_CONTRAST_ACCENT := Color(1.0, 1.0, 0.0, 1.0)
const HIGH_CONTRAST_BORDER := Color(1.0, 1.0, 1.0, 1.0)


## Get high contrast color replacement
static func get_high_contrast_color(original: Color, is_foreground: bool = true) -> Color:
	if is_foreground:
		# Make foreground colors either white or yellow for visibility
		if original.get_luminance() < 0.5:
			return HIGH_CONTRAST_FG
		return original
	else:
		# Make background colors solid black
		return HIGH_CONTRAST_BG


## Create high contrast stylebox
static func create_high_contrast_panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = HIGH_CONTRAST_BG
	style.border_color = HIGH_CONTRAST_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(0)  # Sharp corners for clarity
	style.set_content_margin_all(8)
	return style


# =============================================================================
# REDUCED MOTION HELPERS
# =============================================================================

## Get appropriate animation duration based on reduced motion setting
static func get_animation_duration(base_duration: float, reduced_motion: bool) -> float:
	if reduced_motion:
		return 0.0  # Instant
	return base_duration


## Get appropriate particle count based on reduced motion setting
static func get_particle_count(base_count: int, reduced_motion: bool) -> int:
	if reduced_motion:
		return 0  # No particles
	return base_count


## Check if animation should be skipped
static func should_skip_animation(reduced_motion: bool) -> bool:
	return reduced_motion


# =============================================================================
# LARGE TEXT HELPERS
# =============================================================================

const LARGE_TEXT_SCALE := 1.25


## Get font size adjusted for large text mode
static func get_font_size(base_size: int, large_text: bool) -> int:
	if large_text:
		return int(base_size * LARGE_TEXT_SCALE)
	return base_size


## Get minimum touch target size (for large text / accessibility)
static func get_min_touch_target(large_text: bool) -> Vector2:
	if large_text:
		return Vector2(56, 56)  # Larger targets
	return Vector2(44, 44)  # Standard minimum


# =============================================================================
# KEYBOARD NAVIGATION HELPERS
# =============================================================================

## Standard focusable control types
const FOCUSABLE_TYPES := [
	"Button",
	"CheckBox",
	"CheckButton",
	"OptionButton",
	"SpinBox",
	"LineEdit",
	"TextEdit",
	"HSlider",
	"VSlider",
	"TabBar",
	"ItemList",
	"Tree",
]


## Check if a control should be focusable
static func is_focusable_type(control: Control) -> bool:
	for type_name in FOCUSABLE_TYPES:
		if control.is_class(type_name):
			return true
	return false


## Setup keyboard navigation for a container
static func setup_keyboard_nav(container: Control) -> void:
	var focusables: Array[Control] = []
	_collect_focusables(container, focusables)

	if focusables.is_empty():
		return

	# Link focus neighbors
	for i in range(focusables.size()):
		var current: Control = focusables[i]
		var prev_idx: int = (i - 1) if i > 0 else (focusables.size() - 1)
		var next_idx: int = (i + 1) % focusables.size()

		current.focus_neighbor_top = current.get_path_to(focusables[prev_idx])
		current.focus_neighbor_bottom = current.get_path_to(focusables[next_idx])
		current.focus_mode = Control.FOCUS_ALL


## Recursively collect focusable controls
static func _collect_focusables(node: Node, result: Array[Control]) -> void:
	if node is Control:
		var control := node as Control
		if is_focusable_type(control) and control.visible:
			result.append(control)

	for child in node.get_children():
		_collect_focusables(child, result)


## Find first focusable control in container
static func find_first_focusable(container: Control) -> Control:
	var focusables: Array[Control] = []
	_collect_focusables(container, focusables)
	if focusables.is_empty():
		return null
	return focusables[0]
