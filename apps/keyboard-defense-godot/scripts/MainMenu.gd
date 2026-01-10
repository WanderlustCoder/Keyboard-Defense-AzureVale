extends Control

const VERSION_PATH := "res://VERSION.txt"
const SAVE_PATH := "user://typing_kingdom_save.json"
const ThemeColors = preload("res://ui/theme_colors.gd")

const FONT_SIZE_HELP_TITLE := 28
const FONT_SIZE_HELP_TEXT := 15
const HOVER_SCALE := 1.05
const HOVER_DURATION := 0.1
const PRESS_SCALE := 0.95
const PRESS_DURATION := 0.05

@onready var start_button: Button = $Center/MenuPanel/VBox/StartButton
@onready var kingdom_button: Button = $Center/MenuPanel/VBox/KingdomButton
@onready var settings_button: Button = $Center/MenuPanel/VBox/SettingsButton
@onready var quit_button: Button = $Center/MenuPanel/VBox/QuitButton
@onready var version_label: Label = $VersionLabel
@onready var menu_vbox: VBoxContainer = $Center/MenuPanel/VBox
@onready var game_controller = get_node("/root/GameController")
@onready var audio_manager = get_node_or_null("/root/AudioManager")
@onready var settings_manager = get_node_or_null("/root/SettingsManager")

var continue_button: Button = null
var help_button: Button = null
var help_panel: PanelContainer = null
var _button_tweens: Dictionary = {}  # button -> tween

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	kingdom_button.pressed.connect(_on_kingdom_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	_setup_continue_button()
	_setup_tooltips()
	_load_version()
	_setup_help_button()
	_setup_button_hover_effects()
	if audio_manager != null:
		audio_manager.switch_to_menu_music()

func _setup_continue_button() -> void:
	# Check if a save file exists
	if not FileAccess.file_exists(SAVE_PATH):
		return

	# Create continue button
	continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.custom_minimum_size = Vector2(0, 48)
	continue_button.focus_mode = Control.FOCUS_ALL
	continue_button.tooltip_text = "Resume your previous campaign"
	continue_button.pressed.connect(_on_continue_pressed)

	# Insert before start button
	var start_index := start_button.get_index()
	menu_vbox.add_child(continue_button)
	menu_vbox.move_child(continue_button, start_index)

	# Rename start button to "New Game"
	start_button.text = "New Game"
	start_button.tooltip_text = "Start a fresh campaign (overwrites save)"

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

func _on_continue_pressed() -> void:
	if audio_manager != null:
		audio_manager.play_ui_confirm()
	game_controller.go_to_map()

func _on_start_pressed() -> void:
	if audio_manager != null:
		audio_manager.play_ui_confirm()
	# If save exists (New Game mode), reset progression before starting
	if continue_button != null:
		var progression = get_node_or_null("/root/ProgressionState")
		if progression != null:
			progression.reset_campaign()
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

func _setup_button_hover_effects() -> void:
	# Setup hover for all menu buttons
	var buttons: Array[Button] = [start_button, kingdom_button, settings_button, quit_button]
	if continue_button != null:
		buttons.append(continue_button)
	if help_button != null:
		buttons.append(help_button)

	for btn in buttons:
		if btn == null:
			continue
		# Set pivot to center for proper scaling
		btn.pivot_offset = btn.size / 2.0
		btn.mouse_entered.connect(_on_button_hover_enter.bind(btn))
		btn.mouse_exited.connect(_on_button_hover_exit.bind(btn))
		btn.button_down.connect(_on_button_press_down.bind(btn))
		btn.button_up.connect(_on_button_press_up.bind(btn))

func _on_button_hover_enter(btn: Button) -> void:
	if _is_reduced_motion():
		return
	_tween_button_scale(btn, HOVER_SCALE, HOVER_DURATION)
	if audio_manager != null:
		audio_manager.play_ui_hover()

func _on_button_hover_exit(btn: Button) -> void:
	if _is_reduced_motion():
		return
	_tween_button_scale(btn, 1.0, HOVER_DURATION)

func _on_button_press_down(btn: Button) -> void:
	if _is_reduced_motion():
		return
	_tween_button_scale(btn, PRESS_SCALE, PRESS_DURATION)

func _on_button_press_up(btn: Button) -> void:
	if _is_reduced_motion():
		return
	# Return to hover scale if still hovered, otherwise normal
	var target_scale := HOVER_SCALE if btn.get_global_rect().has_point(btn.get_global_mouse_position()) else 1.0
	_tween_button_scale(btn, target_scale, HOVER_DURATION)

func _tween_button_scale(btn: Button, target_scale: float, duration: float) -> void:
	# Kill existing tween for this button
	if _button_tweens.has(btn):
		var old_tween = _button_tweens[btn]
		if old_tween != null and old_tween.is_valid():
			old_tween.kill()

	# Update pivot in case button size changed
	btn.pivot_offset = btn.size / 2.0

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(btn, "scale", Vector2(target_scale, target_scale), duration)
	_button_tweens[btn] = tween

func _is_reduced_motion() -> bool:
	if settings_manager != null:
		return settings_manager.reduced_motion
	return false
