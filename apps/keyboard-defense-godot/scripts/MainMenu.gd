extends Control

@onready var start_button: Button = $Center/VBox/StartButton
@onready var kingdom_button: Button = $Center/VBox/KingdomButton
@onready var quit_button: Button = $Center/VBox/QuitButton
@onready var game_controller = get_node("/root/GameController")
@onready var audio_manager = get_node_or_null("/root/AudioManager")

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	kingdom_button.pressed.connect(_on_kingdom_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	# Start menu music
	if audio_manager != null:
		audio_manager.switch_to_menu_music()

func _on_start_pressed() -> void:
	if audio_manager != null:
		audio_manager.play_ui_confirm()
	game_controller.go_to_map()

func _on_kingdom_pressed() -> void:
	if audio_manager != null:
		audio_manager.play_ui_confirm()
	game_controller.go_to_kingdom()

func _on_quit_pressed() -> void:
	if audio_manager != null:
		audio_manager.play_ui_cancel()
	get_tree().quit()
