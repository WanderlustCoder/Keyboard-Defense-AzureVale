extends Control

@onready var start_button: Button = $Center/MenuPanel/VBox/StartButton
@onready var kingdom_button: Button = $Center/MenuPanel/VBox/KingdomButton
@onready var settings_button: Button = $Center/MenuPanel/VBox/SettingsButton
@onready var quit_button: Button = $Center/MenuPanel/VBox/QuitButton
@onready var game_controller = get_node("/root/GameController")
@onready var audio_manager = get_node_or_null("/root/AudioManager")

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	kingdom_button.pressed.connect(_on_kingdom_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
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

func _on_settings_pressed() -> void:
	if audio_manager != null:
		audio_manager.play_ui_confirm()
	# Settings not yet implemented - placeholder
	push_warning("Settings menu not yet implemented")

func _on_quit_pressed() -> void:
	if audio_manager != null:
		audio_manager.play_ui_cancel()
	get_tree().quit()
