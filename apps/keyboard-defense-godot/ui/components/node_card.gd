@tool
class_name NodeCard
extends PanelContainer
## A card component for displaying campaign map nodes.
## Handles its own styling based on locked/completed state.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal pressed(node_id: String)

const TITLE_FONT_SIZE := DesignSystem.FONT_BODY
const LESSON_FONT_SIZE := DesignSystem.FONT_BODY_SMALL
const REWARD_FONT_SIZE := DesignSystem.FONT_CAPTION
const BORDER_WIDTH := 2
const CORNER_RADIUS := 6
const CONTENT_MARGIN := 8

@export var node_id: String = ""
@export var title: String = "Node":
	set(value):
		title = value
		_update_display()

@export var lesson_name: String = "":
	set(value):
		lesson_name = value
		_update_display()

@export var reward_gold: int = 0:
	set(value):
		reward_gold = value
		_update_display()

@export var is_unlocked: bool = true:
	set(value):
		is_unlocked = value
		_update_display()
		_update_style()

@export var is_completed: bool = false:
	set(value):
		is_completed = value
		_update_display()
		_update_style()

@onready var title_label: Label = $Content/TitleLabel
@onready var lesson_label: Label = $Content/LessonLabel
@onready var reward_label: Label = $Content/RewardLabel
@onready var audio_manager = get_node_or_null("/root/AudioManager")

var _style_unlocked: StyleBoxFlat
var _style_locked: StyleBoxFlat

func _ready() -> void:
	_create_styles()
	_update_display()
	_update_style()

	if is_unlocked:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		focus_mode = Control.FOCUS_ALL
		gui_input.connect(_on_gui_input)
	else:
		mouse_default_cursor_shape = Control.CURSOR_ARROW
		focus_mode = Control.FOCUS_NONE

func _create_styles() -> void:
	_style_unlocked = StyleBoxFlat.new()
	_style_unlocked.bg_color = ThemeColors.BG_CARD
	_style_unlocked.border_color = ThemeColors.BORDER_HIGHLIGHT
	_style_unlocked.set_border_width_all(BORDER_WIDTH)
	_style_unlocked.set_corner_radius_all(CORNER_RADIUS)
	_style_unlocked.set_content_margin_all(CONTENT_MARGIN)

	_style_locked = StyleBoxFlat.new()
	_style_locked.bg_color = ThemeColors.BG_CARD_DISABLED
	_style_locked.border_color = ThemeColors.BORDER_DISABLED
	_style_locked.set_border_width_all(BORDER_WIDTH)
	_style_locked.set_corner_radius_all(CORNER_RADIUS)
	_style_locked.set_content_margin_all(CONTENT_MARGIN)

func _update_display() -> void:
	if not is_inside_tree():
		return

	var text_color := ThemeColors.TEXT if is_unlocked else ThemeColors.TEXT_DIM

	if title_label:
		var display_title := title
		if is_completed:
			display_title += " (cleared)"
		title_label.text = display_title
		title_label.add_theme_color_override("font_color", text_color)
		title_label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)

	if lesson_label:
		if lesson_name != "":
			lesson_label.text = "Lesson: " + lesson_name
			lesson_label.visible = true
		else:
			lesson_label.visible = false
		lesson_label.add_theme_color_override("font_color", text_color)
		lesson_label.add_theme_font_size_override("font_size", LESSON_FONT_SIZE)

	if reward_label:
		if reward_gold > 0:
			if is_completed:
				reward_label.text = "Reward: %dg (first clear)" % reward_gold
			else:
				reward_label.text = "Reward: %dg" % reward_gold
			reward_label.visible = true
		else:
			reward_label.visible = false
		reward_label.add_theme_color_override("font_color", text_color)
		reward_label.add_theme_font_size_override("font_size", REWARD_FONT_SIZE)

	# Set tooltip for accessibility
	if is_unlocked:
		tooltip_text = "Click to start battle"
	else:
		tooltip_text = "Complete prerequisites to unlock"

func _update_style() -> void:
	if not is_inside_tree():
		return
	if _style_unlocked == null:
		_create_styles()

	if is_completed:
		_style_unlocked.border_color = ThemeColors.ACCENT
	else:
		_style_unlocked.border_color = ThemeColors.BORDER_HIGHLIGHT

	add_theme_stylebox_override("panel", _style_unlocked if is_unlocked else _style_locked)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_activate_card()
		accept_event()
	# Handle keyboard activation
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			_activate_card()
			accept_event()

func _activate_card() -> void:
	if not Engine.is_editor_hint() and audio_manager != null:
		audio_manager.play_ui_confirm()
	pressed.emit(node_id)

## Configure the card with node data
func setup(data: Dictionary, unlocked: bool, completed: bool) -> void:
	node_id = str(data.get("id", ""))
	title = str(data.get("label", ""))
	lesson_name = str(data.get("lesson_name", ""))
	reward_gold = int(data.get("reward_gold", 0))
	is_unlocked = unlocked
	is_completed = completed
