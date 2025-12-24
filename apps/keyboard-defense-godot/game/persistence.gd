class_name GamePersistence
extends RefCounted

const SimSave = preload("res://sim/save.gd")
const GameState = preload("res://sim/types.gd")

const SAVE_PATH := "user://savegame.json"

static func save_state(state: GameState) -> Dictionary:
	var data: Dictionary = SimSave.state_to_dict(state)
	var json_text: String = JSON.stringify(data, "  ")
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Save failed: %s" % error_string(FileAccess.get_open_error())}
	file.store_string(json_text)
	return {"ok": true, "path": SAVE_PATH}

static func load_state() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {"ok": false, "error": "Save file not found."}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Load failed: %s" % error_string(FileAccess.get_open_error())}
	var text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "error": "Save file is invalid JSON."}
	var result: Dictionary = SimSave.state_from_dict(parsed)
	if not result.get("ok", false):
		return result
	return {"ok": true, "state": result.state}
