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

	# Fallback to direct load
	var tex := load("res://assets/art/src-svg/portraits/portrait_lyra.svg") as Texture2D
	if tex != null:
		portrait.texture = tex
	else:
		push_warning("LyraDialogue: Failed to load Lyra portrait")

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
