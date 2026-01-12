extends Control

## Dialogue Box - Displays story dialogue with character name and text
## Press Enter or click to advance through lines

signal dialogue_finished

const FADE_IN_DURATION := 0.2
const FADE_OUT_DURATION := 0.15

@onready var panel: Panel = $Panel
@onready var portrait: TextureRect = $Panel/HBox/PortraitContainer/Portrait
@onready var speaker_label: Label = $Panel/HBox/VBox/SpeakerLabel
@onready var text_label: RichTextLabel = $Panel/HBox/VBox/TextLabel
@onready var continue_label: Label = $Panel/HBox/VBox/ContinueLabel
@onready var settings_manager = get_node_or_null("/root/SettingsManager")
@onready var asset_loader = get_node_or_null("/root/AssetLoader")

var dialogue_lines: Array[String] = []
var current_line_index: int = 0
var is_active: bool = false
var auto_advance_timer: float = 0.0
var auto_advance_delay: float = 0.0  # 0 = manual advance only
var _fade_tween: Tween = null

func _ready() -> void:
	visible = false
	is_active = false
	if continue_label:
		continue_label.text = "Press [Enter] or click to continue..."

func show_dialogue(speaker: String, lines: Array[String], auto_delay: float = 0.0) -> void:
	if lines.is_empty():
		return

	dialogue_lines = lines
	current_line_index = 0
	auto_advance_delay = auto_delay

	if speaker_label:
		speaker_label.text = speaker
		speaker_label.visible = not speaker.is_empty()

	# Load and display portrait for the speaker
	_update_portrait(speaker)

	_show_current_line()
	visible = true
	is_active = true

	# Fade in animation
	_fade_in()

	# Grab focus to capture input
	grab_focus()

func _update_portrait(speaker: String) -> void:
	if not portrait:
		return

	var texture: Texture2D = null

	# Try asset loader first
	if asset_loader != null:
		texture = asset_loader.get_portrait_texture(speaker)

	# Fallback: create procedural portrait for Elder Lyra
	if texture == null and speaker.to_lower().contains("lyra"):
		texture = _create_lyra_portrait()

	if texture:
		portrait.texture = texture
		portrait.visible = true
	else:
		portrait.texture = null
		portrait.visible = false

func _create_lyra_portrait() -> ImageTexture:
	## Creates Elder Lyra's portrait procedurally (24x24 pixel art)
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)

	# Colors
	var bg := Color("#2c3e50")
	var hair_dark := Color("#bdc3c7")
	var hair_light := Color("#ecf0f1")
	var skin := Color("#f5e6d3")
	var skin_shadow := Color("#e6d5c3")
	var eyes := Color("#8e44ad")
	var eye_highlight := Color("#fdfefe")
	var brow := Color("#95a5a6")
	var nose := Color("#d5c4a1")
	var robe_dark := Color("#8e44ad")
	var robe_light := Color("#9b59b6")
	var robe_collar := Color("#d7bde2")
	var gold := Color("#f1c40f")

	# Fill background
	img.fill(bg)

	# Hair (silver/white)
	_fill_rect(img, 5, 2, 14, 8, hair_dark)
	_fill_rect(img, 6, 3, 12, 6, hair_light)
	_fill_rect(img, 4, 6, 4, 10, hair_dark)
	_fill_rect(img, 16, 6, 4, 10, hair_dark)
	_fill_rect(img, 5, 7, 3, 8, hair_light)
	_fill_rect(img, 16, 7, 3, 8, hair_light)

	# Face
	_fill_rect(img, 7, 6, 10, 12, skin_shadow)
	_fill_rect(img, 8, 7, 8, 10, skin)

	# Eyes (purple, wise)
	_fill_rect(img, 9, 9, 2, 2, eyes)
	_fill_rect(img, 13, 9, 2, 2, eyes)
	_fill_rect(img, 9, 9, 1, 1, eye_highlight)
	_fill_rect(img, 13, 9, 1, 1, eye_highlight)

	# Eyebrows
	_fill_rect(img, 9, 8, 2, 1, brow)
	_fill_rect(img, 13, 8, 2, 1, brow)

	# Nose
	_fill_rect(img, 11, 11, 2, 2, nose)

	# Gentle smile
	_fill_rect(img, 10, 14, 4, 1, Color("#c9a0dc"))

	# Purple robe
	_fill_rect(img, 4, 18, 16, 6, robe_dark)
	_fill_rect(img, 5, 19, 14, 4, robe_light)

	# Robe collar
	_fill_rect(img, 10, 17, 4, 2, robe_light)
	_fill_rect(img, 11, 18, 2, 1, robe_collar)

	# Wisdom symbol
	_fill_rect(img, 11, 20, 2, 2, gold)

	return ImageTexture.create_from_image(img)

func _fill_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for px in range(x, mini(x + w, img.get_width())):
		for py in range(y, mini(y + h, img.get_height())):
			if px >= 0 and py >= 0:
				img.set_pixel(px, py, color)

func _show_current_line() -> void:
	if current_line_index >= dialogue_lines.size():
		_finish_dialogue()
		return

	var line: String = dialogue_lines[current_line_index]
	if text_label:
		text_label.text = line

	auto_advance_timer = 0.0

func advance_line() -> void:
	if not is_active:
		return

	current_line_index += 1
	if current_line_index >= dialogue_lines.size():
		_finish_dialogue()
	else:
		_show_current_line()

func _finish_dialogue() -> void:
	is_active = false
	dialogue_lines.clear()
	current_line_index = 0

	# Fade out then hide
	_fade_out()

func skip_dialogue() -> void:
	_finish_dialogue()

func _fade_in() -> void:
	# Kill existing tween
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()

	# Check reduced motion
	if settings_manager != null and settings_manager.reduced_motion:
		modulate.a = 1.0
		return

	# Fade from 0 to 1
	modulate.a = 0.0
	_fade_tween = create_tween()
	_fade_tween.set_ease(Tween.EASE_OUT)
	_fade_tween.tween_property(self, "modulate:a", 1.0, FADE_IN_DURATION)

func _fade_out() -> void:
	# Kill existing tween
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()

	# Check reduced motion
	if settings_manager != null and settings_manager.reduced_motion:
		visible = false
		modulate.a = 1.0
		emit_signal("dialogue_finished")
		return

	# Fade from current to 0
	_fade_tween = create_tween()
	_fade_tween.set_ease(Tween.EASE_IN)
	_fade_tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_DURATION)
	_fade_tween.tween_callback(_on_fade_out_complete)

func _on_fade_out_complete() -> void:
	visible = false
	modulate.a = 1.0  # Reset for next show
	emit_signal("dialogue_finished")

func _process(delta: float) -> void:
	if not is_active:
		return

	# Auto-advance if enabled
	if auto_advance_delay > 0:
		auto_advance_timer += delta
		if auto_advance_timer >= auto_advance_delay:
			advance_line()

func _gui_input(event: InputEvent) -> void:
	if not is_active:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			advance_line()
			accept_event()
		elif event.keycode == KEY_ESCAPE:
			skip_dialogue()
			accept_event()

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			advance_line()
			accept_event()

func _input(event: InputEvent) -> void:
	if not is_active:
		return

	# Global input handler for when focus isn't on the dialogue box
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			advance_line()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			skip_dialogue()
			get_viewport().set_input_as_handled()
