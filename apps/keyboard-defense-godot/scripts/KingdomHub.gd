extends Control

@onready var gold_label: Label = $TopBar/GoldLabel
@onready var back_button: Button = $TopBar/BackButton
@onready var modifiers_label: Label = $Scroll/Content/ModifiersLabel
@onready var kingdom_list: VBoxContainer = $Scroll/Content/KingdomList
@onready var unit_list: VBoxContainer = $Scroll/Content/UnitList
@onready var progression = get_node("/root/ProgressionState")
@onready var game_controller = get_node("/root/GameController")

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_refresh()

func _refresh() -> void:
	gold_label.text = "Gold: %d" % progression.gold
	modifiers_label.text = _format_modifiers(progression.get_combat_modifiers())
	_build_upgrade_section(kingdom_list, progression.get_kingdom_upgrades())
	_build_upgrade_section(unit_list, progression.get_unit_upgrades())

func _format_modifiers(modifiers: Dictionary) -> String:
	var parts: Array = []
	var typing_bonus = int(round((float(modifiers.get("typing_power", 1.0)) - 1.0) * 100.0))
	if typing_bonus != 0:
		parts.append("Typing Power %+d%%" % typing_bonus)
	var threat_bonus = int(round((1.0 - float(modifiers.get("threat_rate_multiplier", 1.0))) * 100.0))
	if threat_bonus != 0:
		parts.append("Threat Slow %+d%%" % threat_bonus)
	var forgiveness = int(round(float(modifiers.get("mistake_forgiveness", 0.0)) * 100.0))
	if forgiveness != 0:
		parts.append("Mistake Forgiveness %+d%%" % forgiveness)
	var castle_bonus = int(modifiers.get("castle_health_bonus", 0))
	if castle_bonus != 0:
		parts.append("Castle +%d" % castle_bonus)
	if parts.is_empty():
		return "Training bonuses: None yet. Upgrade to boost your typing impact."
	return "Training bonuses: " + ", ".join(parts)

func _format_upgrade_tags(effects: Dictionary) -> String:
	var tags: Array = []
	if float(effects.get("typing_power", 0.0)) != 0.0:
		tags.append("Typing Power")
	if float(effects.get("threat_rate_multiplier", 0.0)) != 0.0:
		tags.append("Threat Slow")
	if float(effects.get("mistake_forgiveness", 0.0)) != 0.0:
		tags.append("Mistake Forgiveness")
	if int(effects.get("castle_health_bonus", 0)) != 0:
		tags.append("Castle Health")
	if tags.is_empty():
		return ""
	return "Tags: " + ", ".join(tags)

func _build_upgrade_section(container: VBoxContainer, upgrades: Array) -> void:
	for child in container.get_children():
		child.queue_free()
	for upgrade in upgrades:
		var upgrade_id = str(upgrade.get("id", ""))
		var label = str(upgrade.get("label", ""))
		var cost = int(upgrade.get("cost", 0))
		var owned = progression.is_upgrade_owned(upgrade_id)
		var description = str(upgrade.get("description", ""))
		var effects: Dictionary = upgrade.get("effects", {})

		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(0, 120)
		var box = VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		panel.add_child(box)

		var title = Label.new()
		title.text = "%s (%dg)" % [label, cost]
		box.add_child(title)

		var desc = Label.new()
		desc.text = description
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		box.add_child(desc)

		var tags_text = _format_upgrade_tags(effects)
		if tags_text != "":
			var tags_label = Label.new()
			tags_label.text = tags_text
			tags_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			box.add_child(tags_label)

		var button = Button.new()
		button.custom_minimum_size = Vector2(0, 44)
		if owned:
			button.text = "Owned"
			button.disabled = true
		elif progression.gold < cost:
			button.text = "Need %dg" % cost
			button.disabled = true
		else:
			button.text = "Purchase"
			button.pressed.connect(_on_upgrade_pressed.bind(upgrade_id))
		box.add_child(button)

		container.add_child(panel)

func _on_upgrade_pressed(upgrade_id: String) -> void:
	if progression.apply_upgrade(upgrade_id):
		_refresh()

func _on_back_pressed() -> void:
	game_controller.go_to_map()
