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
	## Creates Elder Lyra's portrait procedurally (64x64 detailed pixel art)
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)

	# Color palette
	var bg := Color("#1a1a2e")           # Dark blue background
	var bg_accent := Color("#16213e")    # Slightly lighter bg accent

	var hair_dark := Color("#8e9aaf")    # Silver hair shadow
	var hair_mid := Color("#bdc3c7")     # Silver hair mid
	var hair_light := Color("#ecf0f1")   # Silver hair highlight
	var hair_shine := Color("#ffffff")   # Hair shine

	var skin := Color("#f5e6d3")         # Main skin tone
	var skin_shadow := Color("#d4c4a8")  # Skin shadow
	var skin_highlight := Color("#fdf6e3") # Skin highlight

	var eyes_outer := Color("#2c3e50")   # Eye outline
	var eyes_purple := Color("#8e44ad")  # Iris purple
	var eyes_light := Color("#af7ac5")   # Iris highlight
	var eyes_white := Color("#fdfefe")   # Eye whites
	var pupil := Color("#1a1a2e")        # Pupil

	var brow := Color("#7f8c8d")         # Eyebrow color
	var lips := Color("#d4a5a5")         # Lip color
	var blush := Color("#e8c4c4")        # Subtle blush

	var robe_dark := Color("#5b2c6f")    # Robe deep shadow
	var robe_mid := Color("#7d3c98")     # Robe mid tone
	var robe_light := Color("#9b59b6")   # Robe main
	var robe_highlight := Color("#bb8fce") # Robe highlight
	var robe_trim := Color("#d4ac0d")    # Gold trim
	var robe_trim_light := Color("#f4d03f") # Gold highlight

	var gem := Color("#3498db")          # Blue gem
	var gem_light := Color("#85c1e9")    # Gem highlight
	var magic := Color("#a569bd")        # Magic glow

	# Fill background with gradient effect
	img.fill(bg)
	_draw_rect(img, 0, 0, 64, 20, bg_accent)

	# === HAIR (flowing silver hair) ===
	_draw_rect(img, 12, 4, 40, 18, hair_dark)
	_draw_rect(img, 14, 5, 36, 15, hair_mid)
	_draw_rect(img, 16, 6, 32, 12, hair_light)

	# Hair top curve
	_draw_rect(img, 18, 3, 28, 4, hair_dark)
	_draw_rect(img, 20, 2, 24, 3, hair_mid)
	_draw_rect(img, 24, 1, 16, 2, hair_light)

	# Left flowing hair
	_draw_rect(img, 6, 14, 12, 32, hair_dark)
	_draw_rect(img, 8, 16, 8, 28, hair_mid)
	_draw_rect(img, 9, 18, 5, 24, hair_light)
	_draw_rect(img, 10, 20, 2, 8, hair_shine)

	# Right flowing hair
	_draw_rect(img, 46, 14, 12, 32, hair_dark)
	_draw_rect(img, 48, 16, 8, 28, hair_mid)
	_draw_rect(img, 50, 18, 5, 24, hair_light)
	_draw_rect(img, 51, 20, 2, 8, hair_shine)

	# Hair strands and highlights
	_draw_rect(img, 4, 20, 3, 20, hair_dark)
	_draw_rect(img, 57, 20, 3, 20, hair_dark)
	_draw_rect(img, 26, 4, 4, 2, hair_shine)
	_draw_rect(img, 34, 5, 3, 2, hair_shine)

	# === FACE ===
	_draw_rect(img, 18, 14, 28, 32, skin_shadow)
	_draw_rect(img, 20, 16, 24, 28, skin)
	_draw_rect(img, 22, 18, 20, 24, skin_highlight)

	# Cheek shading and blush
	_draw_rect(img, 18, 26, 4, 8, skin_shadow)
	_draw_rect(img, 42, 26, 4, 8, skin_shadow)
	_draw_rect(img, 20, 32, 4, 3, blush)
	_draw_rect(img, 40, 32, 4, 3, blush)

	# Chin
	_draw_rect(img, 26, 42, 12, 4, skin)
	_draw_rect(img, 28, 44, 8, 2, skin_shadow)

	# === EYES ===
	# Left eye
	_draw_rect(img, 22, 24, 8, 6, eyes_white)
	_draw_rect(img, 24, 25, 5, 4, eyes_purple)
	_draw_rect(img, 25, 26, 3, 2, eyes_light)
	_draw_rect(img, 26, 26, 2, 2, pupil)
	_draw_rect(img, 26, 26, 1, 1, eyes_white)
	_draw_rect(img, 22, 23, 8, 1, eyes_outer)
	_draw_rect(img, 22, 30, 8, 1, eyes_outer)

	# Right eye
	_draw_rect(img, 34, 24, 8, 6, eyes_white)
	_draw_rect(img, 35, 25, 5, 4, eyes_purple)
	_draw_rect(img, 36, 26, 3, 2, eyes_light)
	_draw_rect(img, 37, 26, 2, 2, pupil)
	_draw_rect(img, 37, 26, 1, 1, eyes_white)
	_draw_rect(img, 34, 23, 8, 1, eyes_outer)
	_draw_rect(img, 34, 30, 8, 1, eyes_outer)

	# Eyebrows
	_draw_rect(img, 21, 21, 9, 2, brow)
	_draw_rect(img, 22, 20, 6, 1, brow)
	_draw_rect(img, 34, 21, 9, 2, brow)
	_draw_rect(img, 36, 20, 6, 1, brow)

	# Crow's feet
	_draw_rect(img, 19, 26, 1, 3, skin_shadow)
	_draw_rect(img, 44, 26, 1, 3, skin_shadow)

	# === NOSE ===
	_draw_rect(img, 30, 30, 4, 6, skin_shadow)
	_draw_rect(img, 31, 31, 2, 4, skin)
	_draw_rect(img, 29, 35, 6, 2, skin_shadow)

	# === MOUTH ===
	_draw_rect(img, 28, 38, 8, 1, lips)
	_draw_rect(img, 27, 39, 10, 2, lips)
	_draw_rect(img, 29, 39, 6, 1, Color("#e8b4b4"))
	_draw_rect(img, 25, 39, 2, 1, skin_shadow)
	_draw_rect(img, 37, 39, 2, 1, skin_shadow)

	# === ROBE ===
	_draw_rect(img, 10, 46, 44, 18, robe_dark)
	_draw_rect(img, 12, 48, 40, 14, robe_mid)
	_draw_rect(img, 14, 50, 36, 10, robe_light)

	# V-neck collar
	_draw_rect(img, 26, 44, 12, 8, robe_mid)
	_draw_rect(img, 28, 45, 8, 6, robe_light)
	_draw_rect(img, 30, 46, 4, 4, skin_shadow)

	# Gold trim
	_draw_rect(img, 24, 44, 2, 10, robe_trim)
	_draw_rect(img, 38, 44, 2, 10, robe_trim)
	_draw_rect(img, 25, 45, 1, 8, robe_trim_light)
	_draw_rect(img, 39, 45, 1, 8, robe_trim_light)

	# Shoulder highlights and folds
	_draw_rect(img, 16, 50, 6, 4, robe_highlight)
	_draw_rect(img, 42, 50, 6, 4, robe_highlight)
	_draw_rect(img, 20, 54, 2, 8, robe_dark)
	_draw_rect(img, 32, 54, 2, 8, robe_dark)
	_draw_rect(img, 42, 54, 2, 8, robe_dark)

	# === DECORATIONS ===
	# Pendant with gem
	_draw_rect(img, 29, 52, 6, 6, robe_trim)
	_draw_rect(img, 30, 53, 4, 4, gem)
	_draw_rect(img, 31, 54, 2, 2, gem_light)

	# Magic sparkles
	_draw_rect(img, 8, 8, 2, 2, magic)
	_draw_rect(img, 54, 10, 2, 2, magic)
	_draw_rect(img, 4, 36, 2, 2, magic)
	_draw_rect(img, 58, 38, 2, 2, magic)
	_draw_rect(img, 12, 58, 1, 1, magic)
	_draw_rect(img, 52, 56, 1, 1, magic)

	return ImageTexture.create_from_image(img)

func _draw_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for px in range(x, x + w):
		for py in range(y, y + h):
			if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
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
