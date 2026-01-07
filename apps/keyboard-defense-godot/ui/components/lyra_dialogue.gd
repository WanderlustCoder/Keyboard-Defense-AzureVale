extends PanelContainer
class_name LyraDialogue
## Dialogue box with Lyra portrait for tutorial and story moments

const ThemeColors = preload("res://ui/theme_colors.gd")

signal dialogue_finished
signal dialogue_advanced

@export var typewriter_speed: float = 0.03
@export var auto_advance_delay: float = 0.0

var _full_text: String = ""
var _visible_chars: int = 0
var _is_typing: bool = false
var _can_advance: bool = false
var _dialogue_queue: Array[Dictionary] = []

@onready var portrait: TextureRect = $Content/Portrait
@onready var name_label: Label = $Content/TextBox/NameLabel
@onready var dialogue_label: RichTextLabel = $Content/TextBox/DialogueLabel
@onready var continue_hint: Label = $Content/TextBox/ContinueHint
@onready var audio_manager = get_node_or_null("/root/AudioManager")

func _ready() -> void:
	visible = false
	continue_hint.visible = false
	_load_lyra_portrait()

func _load_lyra_portrait() -> void:
	var tex := load("res://assets/sprites/npc_lyra.png") as Texture2D
	if tex != null:
		portrait.texture = tex

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
			await get_tree().create_timer(auto_advance_delay).timeout
			_advance()
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

	if portrait_path != "" and FileAccess.file_exists(portrait_path):
		var tex := load(portrait_path) as Texture2D
		if tex != null:
			portrait.texture = tex
	else:
		_load_lyra_portrait()

	visible = true

	if audio_manager != null:
		audio_manager.play_sfx(audio_manager.SFX.TUTORIAL_DING, -6.0)

func _advance() -> void:
	_can_advance = false
	dialogue_advanced.emit()
	_show_next()

func hide_dialogue() -> void:
	visible = false
	_dialogue_queue.clear()
	_is_typing = false
	_can_advance = false

func is_active() -> bool:
	return visible

func skip_all() -> void:
	_dialogue_queue.clear()
	hide_dialogue()
	dialogue_finished.emit()
