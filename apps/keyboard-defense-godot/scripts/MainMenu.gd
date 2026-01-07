extends Control

@onready var start_button: Button = $Center/VBox/StartButton
@onready var kingdom_button: Button = $Center/VBox/KingdomButton
@onready var quit_button: Button = $Center/VBox/QuitButton
@onready var game_controller = get_node("/root/GameController")

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	kingdom_button.pressed.connect(_on_kingdom_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	game_controller.go_to_map()

func _on_kingdom_pressed() -> void:
	game_controller.go_to_kingdom()

func _on_quit_pressed() -> void:
	get_tree().quit()
