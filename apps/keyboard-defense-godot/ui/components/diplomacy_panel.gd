class_name DiplomacyPanel
extends PanelContainer
## Diplomacy panel showing faction relations and diplomatic options.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed
signal diplomacy_action(action: String, faction_id: String, data: Dictionary)

const SimFactions = preload("res://sim/factions.gd")
const SimDiplomacy = preload("res://sim/diplomacy.gd")

var _state_ref = null
var _selected_faction: String = ""

# UI elements - built programmatically
var _title_label: Label
var _close_button: Button
var _faction_list: VBoxContainer
var _detail_panel: PanelContainer
var _detail_content: VBoxContainer


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 500)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	_title_label = Label.new()
	_title_label.text = "Diplomacy"
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	DesignSystem.style_label(_title_label, "h1", ThemeColors.ACCENT)
	header.add_child(_title_label)

	_close_button = Button.new()
	_close_button.text = "✕"
	_close_button.custom_minimum_size = Vector2(DesignSystem.SIZE_BUTTON_SM, DesignSystem.SIZE_BUTTON_SM)
	_style_close_button()
	_close_button.pressed.connect(_on_close_pressed)
	header.add_child(_close_button)

	# Separator
	main_vbox.add_child(DesignSystem.create_separator())

	# Content - split between faction list and detail
	var content := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content)

	# Faction list (left side)
	var list_scroll := ScrollContainer.new()
	list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(list_scroll)

	_faction_list = DesignSystem.create_vbox(DesignSystem.SPACE_SM)
	_faction_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.add_child(_faction_list)

	# Detail panel (right side)
	_detail_panel = PanelContainer.new()
	_detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var detail_style := DesignSystem.create_elevated_style(ThemeColors.BG_CARD)
	_detail_panel.add_theme_stylebox_override("panel", detail_style)
	content.add_child(_detail_panel)

	var detail_scroll := ScrollContainer.new()
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_detail_panel.add_child(detail_scroll)

	_detail_content = DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	_detail_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.add_child(_detail_content)

	# Empty state
	var empty_label := Label.new()
	empty_label.text = "Select a faction to view details"
	DesignSystem.style_label(empty_label, "body", ThemeColors.TEXT_DIM)
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_content.add_child(empty_label)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_button.add_theme_stylebox_override("normal", normal)
	_close_button.add_theme_stylebox_override("hover", hover)
	_close_button.add_theme_color_override("font_color", ThemeColors.TEXT)


func update_display(state) -> void:
	_state_ref = state
	_refresh_faction_list()

	if _selected_faction != "":
		_refresh_detail_panel(_selected_faction)


func _refresh_faction_list() -> void:
	# Clear existing entries
	for child in _faction_list.get_children():
		child.queue_free()

	if _state_ref == null:
		return

	var summary := SimDiplomacy.get_diplomacy_summary(_state_ref)

	for faction_info in summary:
		var entry := _create_faction_entry(faction_info)
		_faction_list.add_child(entry)


func _create_faction_entry(faction_info: Dictionary) -> Control:
	var container := DesignSystem.create_hbox(DesignSystem.SPACE_SM)
	container.custom_minimum_size.y = DesignSystem.SIZE_TOUCH_MIN

	# Faction color indicator
	var color_rect := ColorRect.new()
	color_rect.custom_minimum_size = Vector2(DesignSystem.SPACE_SM, 40)
	color_rect.color = faction_info.get("color", Color.GRAY)
	container.add_child(color_rect)

	# Faction info
	var info_vbox := DesignSystem.create_vbox(2)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	name_label.text = str(faction_info.get("name", "Unknown"))
	DesignSystem.style_label(name_label, "body", ThemeColors.TEXT)
	info_vbox.add_child(name_label)

	var status_hbox := DesignSystem.create_hbox(DesignSystem.SPACE_XS)

	var relation_label := Label.new()
	var relation: int = faction_info.get("relation", 0)
	var status: String = faction_info.get("status", "neutral")
	relation_label.text = "%s (%+d)" % [status.capitalize(), relation]
	DesignSystem.style_label(relation_label, "caption", _get_relation_color(relation))
	status_hbox.add_child(relation_label)

	# Show agreements
	var agreements: Array = faction_info.get("agreements", [])
	if not agreements.is_empty():
		var agreements_label := Label.new()
		agreements_label.text = " - " + ", ".join(agreements)
		DesignSystem.style_label(agreements_label, "caption", ThemeColors.TEXT_DIM)
		status_hbox.add_child(agreements_label)

	# Show pending indicator
	var pending: Dictionary = faction_info.get("pending", {})
	if not pending.is_empty():
		var pending_label := Label.new()
		pending_label.text = " [!]"
		DesignSystem.style_label(pending_label, "caption", ThemeColors.WARNING)
		status_hbox.add_child(pending_label)

	info_vbox.add_child(status_hbox)
	container.add_child(info_vbox)

	# Select button
	var select_btn := Button.new()
	select_btn.text = "Details"
	select_btn.custom_minimum_size.x = 60
	var faction_id: String = faction_info.get("id", "")
	select_btn.pressed.connect(_on_faction_selected.bind(faction_id))
	_style_secondary_button(select_btn)
	container.add_child(select_btn)

	return container


func _style_secondary_button(button: Button) -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.BG_BUTTON_HOVER, ThemeColors.BORDER_HIGHLIGHT)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_color_override("font_color", ThemeColors.TEXT)
	button.add_theme_font_size_override("font_size", DesignSystem.FONT_BODY_SMALL)


func _get_relation_color(relation: int) -> Color:
	if relation >= SimFactions.RELATION_ALLIED:
		return ThemeColors.FACTION_ALLIED
	elif relation >= SimFactions.RELATION_FRIENDLY:
		return ThemeColors.SUCCESS.darkened(0.2)
	elif relation >= SimFactions.RELATION_NEUTRAL:
		return ThemeColors.TEXT
	elif relation >= SimFactions.RELATION_UNFRIENDLY:
		return ThemeColors.WARNING
	else:
		return ThemeColors.FACTION_HOSTILE


func _on_faction_selected(faction_id: String) -> void:
	_selected_faction = faction_id
	_refresh_detail_panel(faction_id)


func _refresh_detail_panel(faction_id: String) -> void:
	# Clear existing content
	for child in _detail_content.get_children():
		child.queue_free()

	if _state_ref == null or faction_id == "":
		return

	var faction_data := SimFactions.get_faction(faction_id)
	var relation := SimFactions.get_relation(_state_ref, faction_id)
	var status := SimFactions.get_relation_status(_state_ref, faction_id)

	# Faction name and description
	var header := Label.new()
	header.text = SimFactions.get_faction_name(faction_id)
	DesignSystem.style_label(header, "h2", SimFactions.get_faction_color(faction_id))
	_detail_content.add_child(header)

	var desc := Label.new()
	desc.text = str(faction_data.get("description", ""))
	DesignSystem.style_label(desc, "body_small", ThemeColors.TEXT_DIM)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_content.add_child(desc)

	# Relation bar
	var relation_container := DesignSystem.create_hbox(DesignSystem.SPACE_SM)
	var relation_title := Label.new()
	relation_title.text = "Relations: "
	DesignSystem.style_label(relation_title, "body_small", ThemeColors.TEXT)
	relation_container.add_child(relation_title)

	var relation_value := Label.new()
	relation_value.text = "%s (%+d)" % [status.capitalize(), relation]
	DesignSystem.style_label(relation_value, "body_small", _get_relation_color(relation))
	relation_container.add_child(relation_value)
	_detail_content.add_child(relation_container)

	# Separator
	_detail_content.add_child(DesignSystem.create_separator())

	# Check for pending offers
	if _state_ref.pending_diplomacy.has(faction_id):
		_add_pending_offer_ui(faction_id)
		_detail_content.add_child(DesignSystem.create_separator())

	# Diplomatic actions
	var actions_label := Label.new()
	actions_label.text = "Diplomatic Actions"
	DesignSystem.style_label(actions_label, "h3", ThemeColors.TEXT)
	_detail_content.add_child(actions_label)

	_add_action_buttons(faction_id)


func _add_pending_offer_ui(faction_id: String) -> void:
	var pending: Dictionary = _state_ref.pending_diplomacy.get(faction_id, {})
	var offer_type: String = pending.get("type", "")

	var pending_box := DesignSystem.create_vbox(DesignSystem.SPACE_SM)

	var pending_label := Label.new()

	match offer_type:
		"trade_offer":
			pending_label.text = "They are offering a trade agreement!"
		"pact_offer":
			pending_label.text = "They are offering a non-aggression pact!"
		"tribute_demand":
			var amount: int = pending.get("amount", 50)
			pending_label.text = "They demand %d gold in tribute!" % amount
		"peace_offer":
			pending_label.text = "They are seeking peace!"
		_:
			pending_label.text = "Pending diplomatic action"

	DesignSystem.style_label(pending_label, "body_small", ThemeColors.WARNING)
	pending_box.add_child(pending_label)

	var btn_row := DesignSystem.create_hbox(DesignSystem.SPACE_SM)

	var accept_btn := Button.new()
	accept_btn.text = "Accept"
	accept_btn.pressed.connect(_on_accept_offer.bind(faction_id))
	_style_success_button(accept_btn)
	btn_row.add_child(accept_btn)

	var decline_btn := Button.new()
	decline_btn.text = "Decline"
	decline_btn.pressed.connect(_on_decline_offer.bind(faction_id))
	_style_danger_button(decline_btn)
	btn_row.add_child(decline_btn)

	pending_box.add_child(btn_row)
	_detail_content.add_child(pending_box)


func _style_success_button(button: Button) -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.SUCCESS.darkened(0.5), ThemeColors.SUCCESS)
	var hover := DesignSystem.create_button_style(ThemeColors.SUCCESS.darkened(0.3), ThemeColors.SUCCESS)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_color_override("font_color", ThemeColors.TEXT)
	button.add_theme_font_size_override("font_size", DesignSystem.FONT_BODY_SMALL)


func _style_danger_button(button: Button) -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.5), ThemeColors.ERROR)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_color_override("font_color", ThemeColors.TEXT)
	button.add_theme_font_size_override("font_size", DesignSystem.FONT_BODY_SMALL)


func _add_action_buttons(faction_id: String) -> void:
	var actions_grid := GridContainer.new()
	actions_grid.columns = 2
	actions_grid.add_theme_constant_override("h_separation", DesignSystem.SPACE_SM)
	actions_grid.add_theme_constant_override("v_separation", DesignSystem.SPACE_SM)

	# Trade Agreement
	var trade_check := SimDiplomacy.can_propose_trade(_state_ref, faction_id)
	var trade_btn := Button.new()
	trade_btn.text = "Propose Trade"
	trade_btn.disabled = not trade_check.ok
	trade_btn.tooltip_text = trade_check.get("reason", "Establish a trade agreement for better prices")
	trade_btn.pressed.connect(_on_propose_trade.bind(faction_id))
	_style_secondary_button(trade_btn)
	actions_grid.add_child(trade_btn)

	# Non-Aggression Pact
	var pact_check := SimDiplomacy.can_propose_pact(_state_ref, faction_id)
	var pact_btn := Button.new()
	pact_btn.text = "Propose Pact"
	pact_btn.disabled = not pact_check.ok
	pact_btn.tooltip_text = pact_check.get("reason", "Establish a non-aggression pact")
	pact_btn.pressed.connect(_on_propose_pact.bind(faction_id))
	_style_secondary_button(pact_btn)
	actions_grid.add_child(pact_btn)

	# Alliance
	var alliance_check := SimDiplomacy.can_propose_alliance(_state_ref, faction_id)
	var alliance_btn := Button.new()
	alliance_btn.text = "Propose Alliance"
	alliance_btn.disabled = not alliance_check.ok
	alliance_btn.tooltip_text = alliance_check.get("reason", "Form an alliance")
	alliance_btn.pressed.connect(_on_propose_alliance.bind(faction_id))
	_style_secondary_button(alliance_btn)
	actions_grid.add_child(alliance_btn)

	# Pay Tribute
	var tribute_check := SimDiplomacy.can_pay_tribute(_state_ref, faction_id)
	var tribute_btn := Button.new()
	var tribute_cost: int = SimFactions.get_tribute_demand(_state_ref, faction_id)
	tribute_btn.text = "Pay Tribute (%dg)" % tribute_cost
	tribute_btn.disabled = not tribute_check.ok
	tribute_btn.tooltip_text = tribute_check.get("reason", "Pay tribute to improve relations")
	tribute_btn.pressed.connect(_on_pay_tribute.bind(faction_id))
	_style_secondary_button(tribute_btn)
	actions_grid.add_child(tribute_btn)

	# Send Gift
	var gift_btn := Button.new()
	gift_btn.text = "Send Gift"
	gift_btn.tooltip_text = "Send resources to improve relations"
	gift_btn.pressed.connect(_on_send_gift.bind(faction_id))
	_style_secondary_button(gift_btn)
	actions_grid.add_child(gift_btn)

	# Declare War / Offer Peace
	if SimFactions.is_at_war(_state_ref, faction_id):
		var peace_check := SimDiplomacy.can_offer_peace(_state_ref, faction_id)
		var peace_btn := Button.new()
		peace_btn.text = "Offer Peace"
		peace_btn.disabled = not peace_check.ok
		peace_btn.tooltip_text = peace_check.get("reason", "End the war")
		peace_btn.pressed.connect(_on_offer_peace.bind(faction_id))
		_style_success_button(peace_btn)
		actions_grid.add_child(peace_btn)
	else:
		var war_check := SimDiplomacy.can_declare_war(_state_ref, faction_id)
		var war_btn := Button.new()
		war_btn.text = "Declare War"
		war_btn.disabled = not war_check.ok
		war_btn.tooltip_text = war_check.get("reason", "Start a war")
		war_btn.pressed.connect(_on_declare_war.bind(faction_id))
		_style_danger_button(war_btn)
		actions_grid.add_child(war_btn)

	_detail_content.add_child(actions_grid)


func _on_propose_trade(faction_id: String) -> void:
	diplomacy_action.emit("propose_trade", faction_id, {})


func _on_propose_pact(faction_id: String) -> void:
	diplomacy_action.emit("propose_pact", faction_id, {})


func _on_propose_alliance(faction_id: String) -> void:
	diplomacy_action.emit("propose_alliance", faction_id, {})


func _on_pay_tribute(faction_id: String) -> void:
	diplomacy_action.emit("pay_tribute", faction_id, {})


func _on_send_gift(faction_id: String) -> void:
	# For now, send a default gift of 20 gold
	diplomacy_action.emit("send_gift", faction_id, {"type": "gold", "amount": 20})


func _on_declare_war(faction_id: String) -> void:
	diplomacy_action.emit("declare_war", faction_id, {})


func _on_offer_peace(faction_id: String) -> void:
	diplomacy_action.emit("offer_peace", faction_id, {})


func _on_accept_offer(faction_id: String) -> void:
	diplomacy_action.emit("accept_offer", faction_id, {})


func _on_decline_offer(faction_id: String) -> void:
	diplomacy_action.emit("decline_offer", faction_id, {})


func _on_close_pressed() -> void:
	closed.emit()
	hide()
