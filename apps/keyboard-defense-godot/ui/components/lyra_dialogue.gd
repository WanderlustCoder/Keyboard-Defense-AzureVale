extends PanelContainer
class_name LyraDialogue
## Dialogue box with Lyra portrait - ONLY used by BattleTutorial.gd
## NOTE: KingdomDefense mode uses game/dialogue_box.gd instead!
## If fixing Lyra's portrait in Kingdom Defense, edit game/dialogue_box.gd

const AssetLoader = preload("res://game/asset_loader.gd")

signal dialogue_finished
signal dialogue_advanced

@export var typewriter_speed: float = 0.03
@export var auto_advance_delay: float = 0.0

var _full_text: String = ""
var _visible_chars: int = 0
var _is_typing: bool = false
var _can_advance: bool = false
var _dialogue_queue: Array[Dictionary] = []
var _auto_advance_pending: bool = false
var _asset_loader: AssetLoader = null

@onready var portrait: TextureRect = $Content/PortraitFrame/Portrait
@onready var name_label: Label = $Content/TextBox/NameLabel
@onready var dialogue_label: RichTextLabel = $Content/TextBox/DialogueLabel
@onready var continue_hint: Label = $Content/TextBox/ContinueHint
@onready var audio_manager = get_node_or_null("/root/AudioManager")

func _ready() -> void:
	visible = false
	continue_hint.visible = false
	_asset_loader = AssetLoader.new()
	_asset_loader._load_manifest()
	_load_lyra_portrait()
	# Ensure portrait is visible
	portrait.visible = true

func _load_lyra_portrait() -> void:
	# Try asset loader first
	if _asset_loader != null:
		var tex := _asset_loader.get_texture("portrait_lyra")
		if tex != null:
			portrait.texture = tex
			return

	# Try direct load
	if ResourceLoader.exists("res://assets/art/src-svg/portraits/portrait_lyra.svg"):
		var tex := load("res://assets/art/src-svg/portraits/portrait_lyra.svg") as Texture2D
		if tex != null:
			portrait.texture = tex
			return

	# Final fallback: create procedural portrait
	portrait.texture = _create_lyra_portrait()

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

func _process(delta: float) -> void:
	if not _is_typing:
		return

	_visible_chars += int(delta / typewriter_speed) + 1
	if _visible_chars >= _full_text.length():
		_visible_chars = _full_text.length()
		_is_typing = false
		_can_advance = true
		continue_hint.visible = true
		if auto_advance_delay > 0.0:
			_auto_advance_pending = true
			await get_tree().create_timer(auto_advance_delay).timeout
			if _auto_advance_pending and visible:
				_advance()
			_auto_advance_pending = false
	dialogue_label.visible_characters = _visible_chars

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		if _is_typing:
			# Skip to end of current text
			_visible_chars = _full_text.length()
			dialogue_label.visible_characters = _visible_chars
			_is_typing = false
			_can_advance = true
			continue_hint.visible = true
		elif _can_advance:
			_advance()
		accept_event()

func show_dialogue(speaker: String, text: String, portrait_path: String = "") -> void:
	_dialogue_queue.clear()
	_queue_line(speaker, text, portrait_path)
	_show_next()

func queue_dialogue(speaker: String, text: String, portrait_path: String = "") -> void:
	_queue_line(speaker, text, portrait_path)
	if not visible:
		_show_next()

func _queue_line(speaker: String, text: String, portrait_path: String) -> void:
	_dialogue_queue.append({
		"speaker": speaker,
		"text": text,
		"portrait": portrait_path
	})

func _show_next() -> void:
	if _dialogue_queue.is_empty():
		hide_dialogue()
		dialogue_finished.emit()
		return

	var line: Dictionary = _dialogue_queue.pop_front()
	_display_line(line)

func _display_line(line: Dictionary) -> void:
	var speaker: String = str(line.get("speaker", "Lyra"))
	var text: String = str(line.get("text", ""))
	var portrait_path: String = str(line.get("portrait", ""))

	name_label.text = speaker
	_full_text = text
	dialogue_label.text = text
	dialogue_label.visible_characters = 0
	_visible_chars = 0
	_is_typing = true
	_can_advance = false
	continue_hint.visible = false

	# Try to load portrait based on speaker name via asset loader
	var tex: Texture2D = null
	if portrait_path != "" and FileAccess.file_exists(portrait_path):
		tex = load(portrait_path) as Texture2D
	elif _asset_loader != null:
		tex = _asset_loader.get_portrait_texture(speaker)

	if tex != null:
		portrait.texture = tex
	else:
		_load_lyra_portrait()

	# Ensure portrait is visible
	portrait.visible = true
	visible = true

	if audio_manager != null:
		audio_manager.play_sfx(audio_manager.SFX.TUTORIAL_DING, -6.0)
		# Duck background music during dialogue
		audio_manager.start_ducking()

func _advance() -> void:
	_can_advance = false
	dialogue_advanced.emit()
	_show_next()

func hide_dialogue() -> void:
	visible = false
	_dialogue_queue.clear()
	_is_typing = false
	_can_advance = false
	_auto_advance_pending = false
	# Stop audio ducking when dialogue closes
	if audio_manager != null:
		audio_manager.stop_ducking()

func is_active() -> bool:
	return visible

func skip_all() -> void:
	_dialogue_queue.clear()
	hide_dialogue()
	dialogue_finished.emit()
