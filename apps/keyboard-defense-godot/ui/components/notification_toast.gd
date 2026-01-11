class_name NotificationToast
extends PanelContainer
## Notification Toast - Shows popup notifications for events

signal notification_dismissed

# Notification types with colors and icons
const NOTIFICATION_TYPES: Dictionary = {
	"achievement": {"color": Color(1.0, 0.84, 0.0), "icon": "[ACH]", "duration": 4.0},
	"level_up": {"color": Color(0.5, 1.0, 0.5), "icon": "[LVL]", "duration": 3.5},
	"milestone": {"color": Color(0.8, 0.6, 1.0), "icon": "[!!]", "duration": 3.5},
	"streak": {"color": Color(1.0, 0.6, 0.2), "icon": "[>>]", "duration": 3.0},
	"reward": {"color": Color(1.0, 0.84, 0.0), "icon": "[+]", "duration": 2.5},
	"warning": {"color": Color(1.0, 0.4, 0.4), "icon": "[!]", "duration": 3.0},
	"info": {"color": Color(0.4, 0.8, 1.0), "icon": "[i]", "duration": 2.5},
	"combo": {"color": Color(1.0, 0.5, 0.8), "icon": "[C]", "duration": 2.0},
	"record": {"color": Color(1.0, 1.0, 0.5), "icon": "[*]", "duration": 3.5},
	"loot": {"color": Color(0.4, 1.0, 0.6), "icon": "[+]", "duration": 2.5}
}

var label: RichTextLabel
var progress_bar: ProgressBar
var close_button: Button

var current_notification: Dictionary = {}
var notification_queue: Array[Dictionary] = []
var display_timer: float = 0.0
var is_displaying: bool = false
var fade_duration: float = 0.3


func _init() -> void:
	custom_minimum_size = Vector2(300, 80)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	# Create vertical container
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vbox)

	# Create header with close button
	var header: HBoxContainer = HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(header)

	# Label
	label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(label)

	# Close button
	close_button = Button.new()
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(24, 24)
	close_button.pressed.connect(_on_close_pressed)
	header.add_child(close_button)

	# Progress bar for duration
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 4)
	progress_bar.show_percentage = false
	progress_bar.max_value = 1.0
	progress_bar.value = 1.0
	vbox.add_child(progress_bar)

	# Initially hidden
	visible = false
	modulate.a = 0.0


func _ready() -> void:
	# Apply theme
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_width_left = 4
	style.border_width_right = 0
	style.border_width_top = 0
	style.border_width_bottom = 0
	style.border_color = Color.WHITE
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 12
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", style)


func _process(delta: float) -> void:
	if not is_displaying:
		return

	display_timer -= delta

	# Update progress bar
	var total_duration: float = float(current_notification.get("duration", 3.0))
	progress_bar.value = max(0.0, display_timer / total_duration)

	if display_timer <= 0:
		_dismiss_notification()


## Queue a notification to display
func queue_notification(type: String, title: String, message: String = "", extra_data: Dictionary = {}) -> void:
	var type_info: Dictionary = NOTIFICATION_TYPES.get(type, NOTIFICATION_TYPES["info"])

	var notification: Dictionary = {
		"type": type,
		"title": title,
		"message": message,
		"color": type_info.get("color", Color.WHITE),
		"icon": str(type_info.get("icon", "[?]")),
		"duration": float(type_info.get("duration", 3.0)),
		"extra": extra_data
	}

	notification_queue.append(notification)

	if not is_displaying:
		_show_next_notification()


## Show next notification in queue
func _show_next_notification() -> void:
	if notification_queue.is_empty():
		is_displaying = false
		return

	current_notification = notification_queue.pop_front()
	is_displaying = true
	display_timer = float(current_notification.get("duration", 3.0))

	# Update display
	var color: Color = current_notification.get("color", Color.WHITE)
	var icon: String = str(current_notification.get("icon", ""))
	var title: String = str(current_notification.get("title", ""))
	var message: String = str(current_notification.get("message", ""))

	var text: String = "[color=#%s]%s %s[/color]" % [color.to_html(false), icon, title]
	if not message.is_empty():
		text += "\n[color=gray]%s[/color]" % message

	label.text = text

	# Update border color
	var style: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
	style.border_color = color
	add_theme_stylebox_override("panel", style)

	# Fade in
	visible = true
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)


## Dismiss current notification
func _dismiss_notification() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	tween.tween_callback(_on_fade_complete)


func _on_fade_complete() -> void:
	visible = false
	notification_dismissed.emit()

	# Show next if queued
	if not notification_queue.is_empty():
		_show_next_notification()
	else:
		is_displaying = false


func _on_close_pressed() -> void:
	display_timer = 0.0
	_dismiss_notification()


## Clear all pending notifications
func clear_queue() -> void:
	notification_queue.clear()


## Get number of pending notifications
func get_queue_size() -> int:
	return notification_queue.size()


## Check if currently displaying
func is_active() -> bool:
	return is_displaying
