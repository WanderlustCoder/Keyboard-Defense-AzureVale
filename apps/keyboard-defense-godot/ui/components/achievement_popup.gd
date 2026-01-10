extends PanelContainer
class_name AchievementPopup
## Popup notification when an achievement is unlocked

signal popup_finished

@export var display_duration: float = 3.0
@export var fade_duration: float = 0.5

var _timer: float = 0.0
var _state: String = "hidden"  # hidden, showing, visible, hiding

@onready var icon_label: Label = $Content/Icon
@onready var title_label: Label = $Content/TextBox/Title
@onready var name_label: Label = $Content/TextBox/Name
@onready var desc_label: Label = $Content/TextBox/Description

func _ready() -> void:
	visible = false
	modulate.a = 0.0

func _process(delta: float) -> void:
	match _state:
		"showing":
			_timer += delta
			modulate.a = minf(_timer / fade_duration, 1.0)
			if _timer >= fade_duration:
				_state = "visible"
				_timer = 0.0
		"visible":
			_timer += delta
			if _timer >= display_duration:
				_state = "hiding"
				_timer = 0.0
		"hiding":
			_timer += delta
			modulate.a = maxf(1.0 - (_timer / fade_duration), 0.0)
			if _timer >= fade_duration:
				_state = "hidden"
				visible = false
				popup_finished.emit()

func show_achievement(achievement_id: String, achievement_data: Dictionary) -> void:
	var icon: String = str(achievement_data.get("icon", "star"))
	var achievement_name: String = str(achievement_data.get("name", achievement_id))
	var description: String = str(achievement_data.get("description", ""))

	# Map icon names to emoji/symbols
	var icon_map := {
		"sword": "⚔",
		"flame": "🔥",
		"fire": "🔥",
		"lightning": "⚡",
		"star": "⭐",
		"home": "🏠",
		"book": "📖",
		"calculator": "🔢",
		"crown": "👑",
		"shield": "🛡",
		"heart": "❤",
		"skull": "💀"
	}

	icon_label.text = icon_map.get(icon, "🏆")
	title_label.text = "Achievement Unlocked!"
	name_label.text = achievement_name
	desc_label.text = description

	visible = true
	modulate.a = 0.0
	_state = "showing"
	_timer = 0.0
