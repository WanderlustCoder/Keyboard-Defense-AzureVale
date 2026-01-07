extends Control

const VERSION_PATH := "res://VERSION.txt"
const ThemeColors = preload("res://ui/theme_colors.gd")

const FONT_SIZE_HELP_TITLE := 28
const FONT_SIZE_HELP_TEXT := 15

@onready var start_button: Button = $Center/MenuPanel/VBox/StartButton
@onready var kingdom_button: Button = $Center/MenuPanel/VBox/KingdomButton
@onready var settings_button: Button = $Center/MenuPanel/VBox/SettingsButton
@onready var quit_button: Button = $Center/MenuPanel/VBox/QuitButton
@onready var version_label: Label = $VersionLabel
@onready var menu_vbox: VBoxContainer = $Center/MenuPanel/VBox
@onready var game_controller = get_node("/root/GameController")
@onready var audio_manager = get_node_or_null("/root/AudioManager")

var help_button: Button = null
var help_panel: PanelContainer = null

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	kingdom_button.pressed.connect(_on_kingdom_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	_setup_tooltips()
	_load_version()
	_setup_help_button()
	if audio_manager != null:
		audio_manager.switch_to_menu_music()

func _setup_tooltips() -> void:
	if start_button:
		start_button.tooltip_text = "Begin your adventure on the campaign map"
	if kingdom_button:
		kingdom_button.tooltip_text = "Upgrade your castle and troops"
	if settings_button:
		settings_button.tooltip_text = "Adjust audio and display options"
	if quit_button:
		quit_button.tooltip_text = "Exit the game"

func _load_version() -> void:
	if version_label == null:
		return
	var file := FileAccess.open(VERSION_PATH, FileAccess.READ)
	if file != null:
		var version := file.get_as_text().strip_edges()
		if version != "":
			version_label.text = "v%s" % version
		else:
			version_label.text = "v0.0.0-dev"
		file.close()
	else:
		version_label.text = "v0.0.0-dev"

func _setup_help_button() -> void:
	# Insert How to Play button before Settings
	help_button = Button.new()
	help_button.text = "How to Play"
	help_button.custom_minimum_size = Vector2(0, 48)
	help_button.focus_mode = Control.FOCUS_ALL
	help_button.tooltip_text = "Learn game mechanics and controls"
	help_button.pressed.connect(_on_help_pressed)
	menu_vbox.add_child(help_button)
	# Move before Settings button (index 4: Title, Subtitle, Spacer, Start, Kingdom, then Help)
	menu_vbox.move_child(help_button, menu_vbox.get_child_count() - 3)

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
	game_controller.go_to_settings()

func _on_quit_pressed() -> void:
	if audio_manager != null:
		audio_manager.play_ui_cancel()
	get_tree().quit()

func _on_help_pressed() -> void:
	if audio_manager != null:
		audio_manager.play_ui_confirm()
	_show_help_panel()

func _show_help_panel() -> void:
	if help_panel != null:
		help_panel.visible = true
		return

	# Create help overlay
	help_panel = PanelContainer.new()
	help_panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var panel_style = StyleBoxFlat.new()
	var bg := ThemeColors.BG_DARK
	bg.a = 0.95
	panel_style.bg_color = bg
	help_panel.add_theme_stylebox_override("panel", panel_style)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	help_panel.add_child(center)

	var content_panel = PanelContainer.new()
	content_panel.custom_minimum_size = Vector2(600, 500)
	var content_style = StyleBoxFlat.new()
	content_style.bg_color = ThemeColors.BG_PANEL
	content_style.border_color = ThemeColors.ACCENT
	content_style.set_border_width_all(2)
	content_style.set_corner_radius_all(8)
	content_style.set_content_margin_all(24)
	content_panel.add_theme_stylebox_override("panel", content_style)
	center.add_child(content_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	content_panel.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "How to Play"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", FONT_SIZE_HELP_TITLE)
	title.add_theme_color_override("font_color", ThemeColors.ACCENT)
	vbox.add_child(title)

	# Help content
	var help_text = RichTextLabel.new()
	help_text.bbcode_enabled = true
	help_text.fit_content = true
	help_text.scroll_active = false
	help_text.custom_minimum_size = Vector2(0, 320)
	help_text.add_theme_font_size_override("normal_font_size", FONT_SIZE_HELP_TEXT)
	help_text.text = _get_help_text()
	vbox.add_child(help_text)

	# Close button
	var close_btn = Button.new()
	close_btn.text = "Got it!"
	close_btn.custom_minimum_size = Vector2(200, 48)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(_close_help_panel)
	vbox.add_child(close_btn)

	add_child(help_panel)

func _get_help_text() -> String:
	return """[color=#e6d770][b]⌨️ OBJECTIVE[/b][/color]
Type words to defeat enemies before they reach your castle!

[color=#a5dbff][b]🎯 GAMEPLAY[/b][/color]
• [color=#98d49a]Type the word[/color] shown on screen to attack enemies
• Each correct letter pushes enemies back
• [color=#f57373]Mistakes[/color] let enemies advance faster
• Complete all drill targets to win the battle

[color=#e6d770][b]⚔️ THREAT BAR[/b][/color]
• The red bar shows enemy progress toward your castle
• When it fills completely, you take damage
• Your castle has 3 health points - don't let it fall!

[color=#a5dbff][b]🔥 COMBOS & BUFFS[/b][/color]
• Build streaks by typing correctly without mistakes
• High combos grant temporary power buffs
• Power buffs increase your typing effectiveness

[color=#98d49a][b]💰 GOLD & UPGRADES[/b][/color]
• Win battles to earn gold
• Better performance = bonus gold rewards
• Spend gold on Kingdom upgrades to boost your power

[color=#b8a0d9][b]💡 TIPS[/b][/color]
• Focus on accuracy over speed at first
• Home row keys (ASDF JKL;) are your foundation
• Practice makes perfect - replay battles to improve!"""

func _close_help_panel() -> void:
	if audio_manager != null:
		audio_manager.play_ui_cancel()
	if help_panel != null:
		help_panel.visible = false

func _input(event: InputEvent) -> void:
	if help_panel != null and help_panel.visible:
		if event.is_action_pressed("ui_cancel"):
			_close_help_panel()
			get_viewport().set_input_as_handled()
