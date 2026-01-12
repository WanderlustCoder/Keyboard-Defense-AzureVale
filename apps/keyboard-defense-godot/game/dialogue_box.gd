extends Control

## Dialogue Box - Main dialogue system for KingdomDefense mode
## Displays story dialogue with character portraits, names, and text
## Press Enter or click to advance through lines
##
## NOTE: This is the PRIMARY dialogue system used by KingdomDefense.
## There's also ui/components/lyra_dialogue.gd which is ONLY for BattleTutorial.

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
	## Creates Elder Lyra's portrait procedurally (64x64 detailed pixel art with frame)
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)

	# Frame colors
	var frame_outer := Color("#1a1a2e")      # Outer frame dark
	var frame_gold := Color("#d4ac0d")       # Gold frame
	var frame_gold_light := Color("#f4d03f") # Gold highlight
	var frame_gold_dark := Color("#9a7b0a")  # Gold shadow
	var frame_inner := Color("#2c1810")      # Inner frame dark wood

	# Background colors (mystical purple gradient)
	var bg_dark := Color("#1a0a2e")          # Dark purple
	var bg_mid := Color("#2d1b4e")           # Mid purple
	var bg_light := Color("#3d2b5e")         # Lighter purple
	var bg_accent := Color("#4a3a6e")        # Accent

	# Character colors
	var hair_dark := Color("#8e9aaf")
	var hair_mid := Color("#bdc3c7")
	var hair_light := Color("#ecf0f1")
	var hair_shine := Color("#ffffff")

	var skin := Color("#f5e6d3")
	var skin_shadow := Color("#d4c4a8")
	var skin_highlight := Color("#fdf6e3")

	var eyes_outer := Color("#2c3e50")
	var eyes_purple := Color("#8e44ad")
	var eyes_light := Color("#af7ac5")
	var eyes_white := Color("#fdfefe")
	var pupil := Color("#1a1a2e")

	var brow := Color("#7f8c8d")
	var lips := Color("#d4a5a5")
	var blush := Color("#e8c4c4")

	var robe_dark := Color("#5b2c6f")
	var robe_mid := Color("#7d3c98")
	var robe_light := Color("#9b59b6")
	var robe_highlight := Color("#bb8fce")
	var robe_trim := Color("#d4ac0d")
	var robe_trim_light := Color("#f4d03f")

	var gem := Color("#3498db")
	var gem_light := Color("#85c1e9")
	var magic := Color("#a569bd")

	# === OUTER FRAME ===
	img.fill(frame_outer)

	# Gold frame border (3 pixels wide)
	_fill_rect(img, 1, 1, 62, 62, frame_gold_dark)
	_fill_rect(img, 2, 2, 60, 60, frame_gold)
	_fill_rect(img, 3, 3, 58, 58, frame_gold_light)

	# Frame highlight (top-left edges)
	_fill_rect(img, 2, 2, 60, 1, frame_gold_light)
	_fill_rect(img, 2, 2, 1, 60, frame_gold_light)

	# Frame shadow (bottom-right edges)
	_fill_rect(img, 3, 61, 60, 1, frame_gold_dark)
	_fill_rect(img, 61, 3, 1, 58, frame_gold_dark)

	# Corner ornaments
	_fill_rect(img, 1, 1, 4, 4, frame_gold_light)
	_fill_rect(img, 59, 1, 4, 4, frame_gold_light)
	_fill_rect(img, 1, 59, 4, 4, frame_gold_light)
	_fill_rect(img, 59, 59, 4, 4, frame_gold_light)
	_fill_rect(img, 2, 2, 2, 2, frame_gold)
	_fill_rect(img, 60, 2, 2, 2, frame_gold)
	_fill_rect(img, 2, 60, 2, 2, frame_gold)
	_fill_rect(img, 60, 60, 2, 2, frame_gold)

	# Inner dark border
	_fill_rect(img, 4, 4, 56, 56, frame_inner)

	# === BACKGROUND (mystical gradient) ===
	_fill_rect(img, 5, 5, 54, 54, bg_dark)
	_fill_rect(img, 5, 5, 54, 18, bg_mid)
	_fill_rect(img, 5, 5, 54, 10, bg_light)

	# Background magical swirls/accents
	_fill_rect(img, 7, 8, 3, 2, bg_accent)
	_fill_rect(img, 52, 12, 4, 2, bg_accent)
	_fill_rect(img, 8, 48, 2, 3, bg_accent)
	_fill_rect(img, 52, 45, 3, 2, bg_accent)

	# === HAIR (flowing silver hair) ===
	_fill_rect(img, 14, 8, 36, 16, hair_dark)
	_fill_rect(img, 16, 9, 32, 13, hair_mid)
	_fill_rect(img, 18, 10, 28, 10, hair_light)

	# Hair top curve
	_fill_rect(img, 20, 7, 24, 4, hair_dark)
	_fill_rect(img, 22, 6, 20, 3, hair_mid)
	_fill_rect(img, 26, 5, 12, 2, hair_light)

	# Left flowing hair
	_fill_rect(img, 8, 16, 10, 28, hair_dark)
	_fill_rect(img, 10, 18, 6, 24, hair_mid)
	_fill_rect(img, 11, 20, 4, 20, hair_light)
	_fill_rect(img, 12, 22, 2, 6, hair_shine)

	# Right flowing hair
	_fill_rect(img, 46, 16, 10, 28, hair_dark)
	_fill_rect(img, 48, 18, 6, 24, hair_mid)
	_fill_rect(img, 49, 20, 4, 20, hair_light)
	_fill_rect(img, 50, 22, 2, 6, hair_shine)

	# Hair strands
	_fill_rect(img, 6, 22, 3, 18, hair_dark)
	_fill_rect(img, 55, 22, 3, 18, hair_dark)

	# Top highlights
	_fill_rect(img, 28, 8, 3, 2, hair_shine)
	_fill_rect(img, 35, 9, 2, 2, hair_shine)

	# === FACE ===
	_fill_rect(img, 20, 16, 24, 28, skin_shadow)
	_fill_rect(img, 22, 18, 20, 24, skin)
	_fill_rect(img, 24, 20, 16, 20, skin_highlight)

	# Cheek shading
	_fill_rect(img, 20, 26, 4, 6, skin_shadow)
	_fill_rect(img, 40, 26, 4, 6, skin_shadow)

	# Blush
	_fill_rect(img, 22, 32, 3, 2, blush)
	_fill_rect(img, 39, 32, 3, 2, blush)

	# Chin
	_fill_rect(img, 28, 40, 8, 4, skin)
	_fill_rect(img, 30, 42, 4, 2, skin_shadow)

	# === EYES ===
	# Left eye
	_fill_rect(img, 24, 25, 7, 5, eyes_white)
	_fill_rect(img, 26, 26, 4, 3, eyes_purple)
	_fill_rect(img, 27, 27, 2, 2, eyes_light)
	_fill_rect(img, 28, 27, 1, 1, pupil)
	_fill_rect(img, 27, 26, 1, 1, eyes_white)
	_fill_rect(img, 24, 24, 7, 1, eyes_outer)
	_fill_rect(img, 24, 30, 7, 1, eyes_outer)

	# Right eye
	_fill_rect(img, 33, 25, 7, 5, eyes_white)
	_fill_rect(img, 34, 26, 4, 3, eyes_purple)
	_fill_rect(img, 35, 27, 2, 2, eyes_light)
	_fill_rect(img, 36, 27, 1, 1, pupil)
	_fill_rect(img, 35, 26, 1, 1, eyes_white)
	_fill_rect(img, 33, 24, 7, 1, eyes_outer)
	_fill_rect(img, 33, 30, 7, 1, eyes_outer)

	# Eyebrows
	_fill_rect(img, 23, 22, 8, 2, brow)
	_fill_rect(img, 24, 21, 5, 1, brow)
	_fill_rect(img, 33, 22, 8, 2, brow)
	_fill_rect(img, 35, 21, 5, 1, brow)

	# Crow's feet
	_fill_rect(img, 21, 27, 1, 2, skin_shadow)
	_fill_rect(img, 42, 27, 1, 2, skin_shadow)

	# === NOSE ===
	_fill_rect(img, 30, 30, 4, 5, skin_shadow)
	_fill_rect(img, 31, 31, 2, 3, skin)
	_fill_rect(img, 29, 34, 6, 2, skin_shadow)

	# === MOUTH ===
	_fill_rect(img, 29, 37, 6, 1, lips)
	_fill_rect(img, 28, 38, 8, 2, lips)
	_fill_rect(img, 30, 38, 4, 1, Color("#e8b4b4"))
	_fill_rect(img, 26, 38, 2, 1, skin_shadow)
	_fill_rect(img, 36, 38, 2, 1, skin_shadow)

	# === ROBE ===
	_fill_rect(img, 12, 44, 40, 14, robe_dark)
	_fill_rect(img, 14, 46, 36, 10, robe_mid)
	_fill_rect(img, 16, 48, 32, 6, robe_light)

	# V-neck collar
	_fill_rect(img, 27, 42, 10, 6, robe_mid)
	_fill_rect(img, 29, 43, 6, 4, robe_light)
	_fill_rect(img, 31, 44, 2, 2, skin_shadow)

	# Gold trim
	_fill_rect(img, 25, 42, 2, 8, robe_trim)
	_fill_rect(img, 37, 42, 2, 8, robe_trim)
	_fill_rect(img, 26, 43, 1, 6, robe_trim_light)
	_fill_rect(img, 38, 43, 1, 6, robe_trim_light)

	# Shoulder highlights
	_fill_rect(img, 18, 48, 5, 3, robe_highlight)
	_fill_rect(img, 41, 48, 5, 3, robe_highlight)

	# Robe folds
	_fill_rect(img, 22, 52, 2, 6, robe_dark)
	_fill_rect(img, 32, 52, 2, 6, robe_dark)
	_fill_rect(img, 40, 52, 2, 6, robe_dark)

	# === PENDANT ===
	_fill_rect(img, 30, 50, 4, 4, robe_trim)
	_fill_rect(img, 31, 51, 2, 2, gem)
	_fill_rect(img, 31, 51, 1, 1, gem_light)

	# === MAGIC SPARKLES ===
	_fill_rect(img, 9, 10, 2, 2, magic)
	_fill_rect(img, 52, 14, 2, 2, magic)
	_fill_rect(img, 7, 38, 1, 1, magic)
	_fill_rect(img, 55, 40, 1, 1, magic)

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
