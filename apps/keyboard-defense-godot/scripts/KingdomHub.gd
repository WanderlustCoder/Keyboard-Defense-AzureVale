extends Control

@onready var gold_label: Label = $TopBar/GoldLabel
@onready var back_button: Button = $TopBar/BackButton
@onready var modifiers_label: Label = $Scroll/Content/ModifiersLabel
@onready var kingdom_list: VBoxContainer = $Scroll/Content/KingdomList
@onready var unit_list: VBoxContainer = $Scroll/Content/UnitList
@onready var progression = get_node("/root/ProgressionState")
@onready var game_controller = get_node("/root/GameController")
@onready var audio_manager = get_node_or_null("/root/AudioManager")

var icon_cache: Dictionary = {}

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_refresh()
	# Play kingdom music
	if audio_manager != null:
		audio_manager.switch_to_kingdom_music()

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

func _get_upgrade_tags(effects: Dictionary) -> Array:
	var tags: Array = []
	if float(effects.get("typing_power", 0.0)) != 0.0:
		tags.append(_make_tag("res://assets/icons/typing_power.png", "Typing Power"))
	if float(effects.get("threat_rate_multiplier", 0.0)) != 0.0:
		tags.append(_make_tag("res://assets/icons/threat_slow.png", "Threat Slow"))
	if float(effects.get("mistake_forgiveness", 0.0)) != 0.0:
		tags.append(_make_tag("res://assets/icons/mistake_forgiveness.png", "Mistake Forgiveness"))
	if int(effects.get("castle_health_bonus", 0)) != 0:
		tags.append(_make_tag("res://assets/icons/castle_health.png", "Castle Health"))
	return tags

func _make_tag(icon_path: String, tooltip: String) -> Dictionary:
	return {"icon_path": icon_path, "tooltip": tooltip}

func _load_icon(path: String) -> Texture2D:
	if icon_cache.has(path):
		return icon_cache[path]
	var image = Image.new()
	if image.load(path) != OK:
		return null
	var texture = ImageTexture.create_from_image(image)
	icon_cache[path] = texture
	return texture

func _build_tag_badge(tag: Dictionary) -> TextureRect:
	var icon = TextureRect.new()
	var icon_path = str(tag.get("icon_path", ""))
	icon.texture = _load_icon(icon_path)
	icon.custom_minimum_size = Vector2(20, 20)
	icon.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.tooltip_text = str(tag.get("tooltip", ""))
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon

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

		var tags = _get_upgrade_tags(effects)
		if not tags.is_empty():
			var tag_row = HBoxContainer.new()
			tag_row.add_theme_constant_override("separation", 8)
			for tag in tags:
				tag_row.add_child(_build_tag_badge(tag))
			box.add_child(tag_row)

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
		if audio_manager != null:
			audio_manager.play_upgrade_purchase()
		_refresh()

func _on_back_pressed() -> void:
	if audio_manager != null:
		audio_manager.play_ui_cancel()
	game_controller.go_to_map()
