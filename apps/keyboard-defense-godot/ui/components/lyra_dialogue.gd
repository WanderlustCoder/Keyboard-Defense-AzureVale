extends PanelContainer
class_name LyraDialogue
## Dialogue box with Lyra portrait for tutorial and story moments

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
	_draw_rect(img, 5, 2, 14, 8, hair_dark)
	_draw_rect(img, 6, 3, 12, 6, hair_light)
	_draw_rect(img, 4, 6, 4, 10, hair_dark)
	_draw_rect(img, 16, 6, 4, 10, hair_dark)
	_draw_rect(img, 5, 7, 3, 8, hair_light)
	_draw_rect(img, 16, 7, 3, 8, hair_light)

	# Face
	_draw_rect(img, 7, 6, 10, 12, skin_shadow)
	_draw_rect(img, 8, 7, 8, 10, skin)

	# Eyes (purple, wise)
	_draw_rect(img, 9, 9, 2, 2, eyes)
	_draw_rect(img, 13, 9, 2, 2, eyes)
	_draw_rect(img, 9, 9, 1, 1, eye_highlight)
	_draw_rect(img, 13, 9, 1, 1, eye_highlight)

	# Eyebrows
	_draw_rect(img, 9, 8, 2, 1, brow)
	_draw_rect(img, 13, 8, 2, 1, brow)

	# Nose
	_draw_rect(img, 11, 11, 2, 2, nose)

	# Gentle smile
	_draw_rect(img, 10, 14, 4, 1, Color("#c9a0dc"))

	# Purple robe
	_draw_rect(img, 4, 18, 16, 6, robe_dark)
	_draw_rect(img, 5, 19, 14, 4, robe_light)

	# Robe collar
	_draw_rect(img, 10, 17, 4, 2, robe_light)
	_draw_rect(img, 11, 18, 2, 1, robe_collar)

	# Wisdom symbol
	_draw_rect(img, 11, 20, 2, 2, gold)

	var tex := ImageTexture.create_from_image(img)
	return tex

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
