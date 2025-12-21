extends Control

@onready var gold_label: Label = $TopBar/GoldLabel
@onready var back_button: Button = $TopBar/BackButton
@onready var kingdom_list: VBoxContainer = $Scroll/Content/KingdomList
@onready var unit_list: VBoxContainer = $Scroll/Content/UnitList
@onready var progression = get_node("/root/ProgressionState")
@onready var game_controller = get_node("/root/GameController")

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_refresh()

func _refresh() -> void:
	gold_label.text = "Gold: %d" % progression.gold
	_build_upgrade_section(kingdom_list, progression.get_kingdom_upgrades())
	_build_upgrade_section(unit_list, progression.get_unit_upgrades())

func _build_upgrade_section(container: VBoxContainer, upgrades: Array) -> void:
	for child in container.get_children():
		child.queue_free()
	for upgrade in upgrades:
		var upgrade_id = str(upgrade.get("id", ""))
		var label = str(upgrade.get("label", ""))
		var cost = int(upgrade.get("cost", 0))
		var owned = progression.is_upgrade_owned(upgrade_id)
		var description = str(upgrade.get("description", ""))

		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(0, 86)
		var box = VBoxContainer.new()
		panel.add_child(box)

		var title = Label.new()
		title.text = "%s (%dg)" % [label, cost]
		box.add_child(title)

		var desc = Label.new()
		desc.text = description
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		box.add_child(desc)

		var button = Button.new()
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
