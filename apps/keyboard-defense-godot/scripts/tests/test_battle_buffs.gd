extends RefCounted

const TestHelper = preload("res://scripts/tests/test_helper.gd")
const BATTLE_SCENE = "res://scenes/Battlefield.tscn"
const ProgressionStateScript = preload("res://scripts/ProgressionState.gd")
const GameControllerScript = preload("res://scripts/GameController.gd")

const BUFF_FOCUS := "focus"
const BUFF_WARD := "ward"

func run() -> Dictionary:
	var helper = TestHelper.new()
	var progression = ProgressionStateScript.new()
	var game_controller = GameControllerScript.new()
	progression.persistence_enabled = false
	progression._load_static_data()
	_reset_progression(progression)

	var node_id = _pick_first_node_id(progression)
	helper.assert_true(node_id != "", "map node available for buff test")
	if node_id == "":
		_cleanup_battle(null, progression, game_controller)
		return helper.summary()

	game_controller.next_battle_node_id = node_id
	var battle = _spawn_battle(progression, game_controller)
	helper.assert_true(battle != null, "battle scene instantiates for buff test")
	if battle == null:
		_cleanup_battle(battle, progression, game_controller)
		return helper.summary()

	_drive_until_buff(battle, BUFF_FOCUS, helper)
	_drive_until_buff(battle, BUFF_WARD, helper)
	_verify_pause_freezes_buffs(battle, helper)

	_cleanup_battle(battle, progression, game_controller)
	return helper.summary()

func _reset_progression(progression) -> void:
	progression.gold = 0
	progression.completed_nodes = {}
	progression.purchased_upgrades = {}
	progression.modifiers = progression.DEFAULT_MODIFIERS.duplicate(true)
	progression.mastery = progression.DEFAULT_MASTERY.duplicate(true)
	progression.last_summary = {}

func _pick_first_node_id(progression) -> String:
	if progression.map_order.size() == 0:
		return ""
	return str(progression.map_order[0])

func _spawn_battle(progression, game_controller):
	var packed = load(BATTLE_SCENE)
	if packed == null:
		return null
	var instance = packed.instantiate()
	_wire_battle_nodes(instance, progression, game_controller)
	instance.result_panel.visible = false
	instance._initialize_battle()
	return instance

func _wire_battle_nodes(battle, progression, game_controller) -> void:
	battle.progression = progression
	battle.game_controller = game_controller
	battle.lesson_label = battle.get_node("TopBar/LessonLabel")
	battle.gold_label = battle.get_node("TopBar/GoldLabel")
	battle.exit_button = battle.get_node("TopBar/ExitButton")
	battle.battle_stage = battle.get_node("PlayField/BattleStage")
	battle.drill_title_label = battle.get_node("TypingPanel/Content/DrillTitle")
	battle.drill_target_label = battle.get_node("TypingPanel/Content/DrillTarget")
	battle.drill_progress_label = battle.get_node("TargetsLabel")
	battle.drill_hint_label = battle.get_node("TypingPanel/Content/DrillHint")
	battle.word_label = battle.get_node("TypingPanel/Content/TypingReadout/WordLabel")
	battle.typed_label = battle.get_node("TypingPanel/Content/TypingReadout/TypedLabel")
	battle.accuracy_label = battle.get_node("StatusPanel/Content/AccuracyLabel")
	battle.wpm_label = battle.get_node("StatusPanel/Content/WpmLabel")
	battle.mistakes_label = battle.get_node("StatusPanel/Content/MistakesLabel")
	battle.threat_bar = battle.get_node("ThreatPanel/ThreatBar")
	battle.castle_label = battle.get_node("StatusPanel/Content/CastleLabel")
	battle.bonus_label = battle.get_node("BonusPanel/BonusLabel")
	battle.result_panel = battle.get_node("ResultPanel")
	battle.result_label = battle.get_node("ResultPanel/Content/ResultLabel")
	battle.result_button = battle.get_node("ResultPanel/Content/ResultButton")

func _drive_until_buff(battle, buff_id: String, helper) -> void:
	var guard = 0
	while battle.active and guard < 160:
		if _has_buff(battle, buff_id):
			break
		if battle.drill_mode == "intermission":
			battle._process(1.0)
			guard += 1
			continue
		var current_word: String = battle.typing_system.get_current_word()
		if current_word == "":
			battle._process(0.1)
			guard += 1
			continue
		for i in range(current_word.length()):
			if not battle.active or battle.drill_mode == "intermission":
				break
			var letter = current_word.substr(i, 1)
			var result: Dictionary = battle.typing_system.input_char(letter)
			battle._handle_typing_result(result)
			if _has_buff(battle, buff_id):
				break
		guard += 1
	helper.assert_true(_has_buff(battle, buff_id), "buff triggered: %s" % buff_id)

func _verify_pause_freezes_buffs(battle, helper) -> void:
	if battle.active_buffs.is_empty():
		helper.assert_true(false, "buffs active before pause check")
		return
	var first_buff = battle.active_buffs[0]
	if not first_buff is Dictionary:
		helper.assert_true(false, "buff data is dictionary")
		return
	var before: float = float(first_buff.get("remaining", 0.0))
	battle._set_paused(true)
	battle._process(1.0)
	var after: float = float(first_buff.get("remaining", 0.0))
	helper.assert_eq(after, before, "pause freezes buff timers")
	battle._set_paused(false)

func _has_buff(battle, buff_id: String) -> bool:
	for buff in battle.active_buffs:
		if buff is Dictionary and str(buff.get("id", "")) == buff_id:
			return true
	return false

func _cleanup_battle(battle, progression, game_controller) -> void:
	if is_instance_valid(battle):
		battle.free()
	if is_instance_valid(progression):
		progression.free()
	if is_instance_valid(game_controller):
		game_controller.free()
