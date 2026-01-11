class_name LessonsReferencePanel
extends PanelContainer
## Lessons Reference Panel - Shows typing curriculum and graduation paths

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Graduation paths overview
const GRADUATION_PATHS: Array[Dictionary] = [
	{
		"id": "beginner",
		"name": "Beginner Path",
		"desc": "Learn touch typing from scratch",
		"stages": 7,
		"goal": "Type all letters fluently",
		"color": Color(0.4, 0.8, 0.4)
	},
	{
		"id": "intermediate",
		"name": "Intermediate Path",
		"desc": "Improve speed and accuracy",
		"stages": 4,
		"goal": "Type sentences with flow",
		"color": Color(0.5, 0.7, 0.9)
	},
	{
		"id": "advanced",
		"name": "Advanced Path",
		"desc": "Master complex typing challenges",
		"stages": 5,
		"goal": "Complete legendary trials",
		"color": Color(0.8, 0.5, 0.9)
	},
	{
		"id": "coding",
		"name": "Programmer Path",
		"desc": "Typing for developers",
		"stages": 3,
		"goal": "Type code fluently",
		"color": Color(1.0, 0.7, 0.3)
	}
]

# Beginner path stages
const BEGINNER_STAGES: Array[Dictionary] = [
	{
		"stage": 1,
		"name": "First Keys",
		"lessons": "intro_left_hand, intro_right_hand, intro_home_row",
		"goal": "Learn where each key is",
		"color": Color(0.4, 0.8, 0.4)
	},
	{
		"stage": 2,
		"name": "Key Pairs",
		"lessons": "intro_pairs_left, intro_pairs_right, intro_pairs_all",
		"goal": "Practice two-key combinations",
		"color": Color(0.4, 0.8, 0.4)
	},
	{
		"stage": 3,
		"name": "Home Row Fundamentals",
		"lessons": "home_row_1, home_row_2, home_row_words",
		"goal": "Master the home row position",
		"color": Color(0.4, 0.8, 0.4)
	},
	{
		"stage": 4,
		"name": "Reach Row Addition",
		"lessons": "reach_row_1, reach_row_2, reach_row_words",
		"goal": "Add E, R, T, Y, U, I, O",
		"color": Color(0.4, 0.8, 0.4)
	},
	{
		"stage": 5,
		"name": "Bottom Row",
		"lessons": "bottom_row_1, bottom_row_2, bottom_row_words",
		"goal": "Master Z, X, C, V, B, N, M",
		"color": Color(0.4, 0.8, 0.4)
	},
	{
		"stage": 6,
		"name": "Full Alphabet",
		"lessons": "full_alpha, full_alpha_words, common_words",
		"goal": "Type all letters fluently",
		"color": Color(0.4, 0.8, 0.4)
	},
	{
		"stage": 7,
		"name": "Simple Sentences",
		"lessons": "sentence_basics, sentence_home_row, sentence_common",
		"goal": "Graduate to full sentences",
		"color": Color(0.4, 0.8, 0.4)
	}
]

# Intermediate path stages
const INTERMEDIATE_STAGES: Array[Dictionary] = [
	{
		"stage": 1,
		"name": "Word Mastery",
		"lessons": "full_alpha_words, common_words, bigram_flow",
		"goal": "Build vocabulary speed",
		"color": Color(0.5, 0.7, 0.9)
	},
	{
		"stage": 2,
		"name": "Pattern Training",
		"lessons": "double_letters, rhythm_words, alternating_hands",
		"goal": "Master common patterns",
		"color": Color(0.5, 0.7, 0.9)
	},
	{
		"stage": 3,
		"name": "Sentence Fluency",
		"lessons": "sentence_common, sentence_intermediate, sentence_pangrams",
		"goal": "Type sentences with flow",
		"color": Color(0.5, 0.7, 0.9)
	},
	{
		"stage": 4,
		"name": "Themed Content",
		"lessons": "biome_evergrove, biome_stonepass, sentence_fantasy",
		"goal": "Practice varied vocabulary",
		"color": Color(0.5, 0.7, 0.9)
	}
]

# Advanced path stages
const ADVANCED_STAGES: Array[Dictionary] = [
	{
		"stage": 1,
		"name": "Numbers and Symbols",
		"lessons": "numbers_1, numbers_2, symbols_1, symbols_2",
		"goal": "Full keyboard proficiency",
		"color": Color(0.8, 0.5, 0.9)
	},
	{
		"stage": 2,
		"name": "Precision Training",
		"lessons": "precision_bronze, precision_silver, precision_gold",
		"goal": "Achieve 95%+ accuracy",
		"color": Color(0.8, 0.5, 0.9)
	},
	{
		"stage": 3,
		"name": "Speed Challenges",
		"lessons": "gauntlet_speed, time_trial_sprint, time_trial_marathon",
		"goal": "Push your speed limits",
		"color": Color(0.8, 0.5, 0.9)
	},
	{
		"stage": 4,
		"name": "Advanced Sentences",
		"lessons": "sentence_advanced, sentence_coding, sentence_pangrams",
		"goal": "Master complex content",
		"color": Color(0.8, 0.5, 0.9)
	},
	{
		"stage": 5,
		"name": "Legendary Trials",
		"lessons": "legendary_forest, legendary_citadel, legendary_apex",
		"goal": "Complete ultimate challenges",
		"color": Color(0.8, 0.5, 0.9)
	}
]

# Coding path stages
const CODING_STAGES: Array[Dictionary] = [
	{
		"stage": 1,
		"name": "Code Basics",
		"lessons": "code_variables, code_keywords",
		"goal": "Type common code patterns",
		"color": Color(1.0, 0.7, 0.3)
	},
	{
		"stage": 2,
		"name": "Symbols and Syntax",
		"lessons": "symbols_1, code_syntax, email_patterns",
		"goal": "Master brackets and operators",
		"color": Color(1.0, 0.7, 0.3)
	},
	{
		"stage": 3,
		"name": "Code Mastery",
		"lessons": "code_master, mixed_case, sentence_coding",
		"goal": "Type code fluently",
		"color": Color(1.0, 0.7, 0.3)
	}
]

# Lesson modes
const LESSON_MODES: Array[Dictionary] = [
	{
		"mode": "charset",
		"name": "Character Set",
		"desc": "Practice specific keys with generated combinations",
		"example": "Home Row: asdfghjkl",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"mode": "wordlist",
		"name": "Word List",
		"desc": "Type words from a curated word pool",
		"example": "Common words, fantasy terms",
		"color": Color(0.5, 0.7, 0.9)
	},
	{
		"mode": "sentence",
		"name": "Sentence",
		"desc": "Type full sentences and phrases",
		"example": "Pangrams, story excerpts",
		"color": Color(0.8, 0.5, 0.9)
	}
]

# Curriculum tips
const CURRICULUM_TIPS: Array[String] = [
	"Start with the Beginner Path if you're new to touch typing",
	"Complete all lessons in a stage before moving to the next",
	"The Intermediate Path builds on Beginner fundamentals",
	"Advanced Path includes numbers, symbols, and speed challenges",
	"Programmer Path focuses on code syntax and special characters",
	"Lessons adapt word length based on enemy type (scout/raider/armored)"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(560, 680)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.12, 0.98)
	style.border_color = ThemeColors.BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	add_theme_stylebox_override("panel", style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	add_child(main_vbox)

	# Header
	var header := HBoxContainer.new()
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "LESSON CURRICULUM"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.5, 0.8, 0.9))
	header.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_close_btn = Button.new()
	_close_btn.text = "X"
	_close_btn.custom_minimum_size = Vector2(30, 30)
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "4 graduation paths with 19 stages total"
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	main_vbox.add_child(subtitle)

	# Content scroll
	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_content_scroll)

	_content_vbox = VBoxContainer.new()
	_content_vbox.add_theme_constant_override("separation", 10)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_vbox)

	# Footer
	var footer := Label.new()
	footer.text = "Type 'lesson [name]' to switch lessons"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_lessons_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Graduation paths overview
	_build_paths_overview_section()

	# Lesson modes
	_build_modes_section()

	# Beginner Path
	_build_path_stages_section("BEGINNER PATH", Color(0.4, 0.8, 0.4), BEGINNER_STAGES)

	# Intermediate Path
	_build_path_stages_section("INTERMEDIATE PATH", Color(0.5, 0.7, 0.9), INTERMEDIATE_STAGES)

	# Advanced Path
	_build_path_stages_section("ADVANCED PATH", Color(0.8, 0.5, 0.9), ADVANCED_STAGES)

	# Coding Path
	_build_path_stages_section("PROGRAMMER PATH", Color(1.0, 0.7, 0.3), CODING_STAGES)

	# Tips
	_build_tips_section()


func _build_paths_overview_section() -> void:
	var section := _create_section_panel("GRADUATION PATHS", Color(0.5, 0.8, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for path in GRADUATION_PATHS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(path.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", path.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(130, 0)
		hbox.add_child(name_label)

		var stages_label := Label.new()
		stages_label.text = "%d stages" % path.get("stages", 0)
		stages_label.add_theme_font_size_override("font_size", 9)
		stages_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
		stages_label.custom_minimum_size = Vector2(60, 0)
		hbox.add_child(stages_label)

		var desc_label := Label.new()
		desc_label.text = str(path.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_modes_section() -> void:
	var section := _create_section_panel("LESSON MODES", Color(0.6, 0.6, 0.8))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for mode in LESSON_MODES:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 1)
		vbox.add_child(container)

		var header_hbox := HBoxContainer.new()
		header_hbox.add_theme_constant_override("separation", 10)
		container.add_child(header_hbox)

		var name_label := Label.new()
		name_label.text = str(mode.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", mode.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(100, 0)
		header_hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(mode.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		header_hbox.add_child(desc_label)

		var example_label := Label.new()
		example_label.text = "  Ex: " + str(mode.get("example", ""))
		example_label.add_theme_font_size_override("font_size", 9)
		example_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
		container.add_child(example_label)


func _build_path_stages_section(title: String, color: Color, stages: Array[Dictionary]) -> void:
	var section := _create_section_panel(title, color)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for stage in stages:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 1)
		vbox.add_child(container)

		# Stage header
		var header_hbox := HBoxContainer.new()
		header_hbox.add_theme_constant_override("separation", 10)
		container.add_child(header_hbox)

		var stage_label := Label.new()
		stage_label.text = "Stage %d:" % stage.get("stage", 0)
		stage_label.add_theme_font_size_override("font_size", 9)
		stage_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
		stage_label.custom_minimum_size = Vector2(55, 0)
		header_hbox.add_child(stage_label)

		var name_label := Label.new()
		name_label.text = str(stage.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", stage.get("color", color))
		name_label.custom_minimum_size = Vector2(140, 0)
		header_hbox.add_child(name_label)

		var goal_label := Label.new()
		goal_label.text = str(stage.get("goal", ""))
		goal_label.add_theme_font_size_override("font_size", 9)
		goal_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.3))
		header_hbox.add_child(goal_label)

		# Lessons
		var lessons_label := Label.new()
		lessons_label.text = "  Lessons: " + str(stage.get("lessons", ""))
		lessons_label.add_theme_font_size_override("font_size", 9)
		lessons_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		lessons_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		container.add_child(lessons_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("CURRICULUM TIPS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in CURRICULUM_TIPS:
		var tip_label := Label.new()
		tip_label.text = "- " + tip
		tip_label.add_theme_font_size_override("font_size", 9)
		tip_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(tip_label)


func _create_section_panel(title: String, color: Color) -> PanelContainer:
	var container := PanelContainer.new()

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = color.darkened(0.85)
	panel_style.border_color = color.darkened(0.5)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	container.add_child(vbox)

	var header := Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", color)
	vbox.add_child(header)

	return container


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
