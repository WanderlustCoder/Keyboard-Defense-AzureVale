extends RefCounted

const TestHelper = preload("res://scripts/tests/test_helper.gd")
const MANIFEST_PATH := "res://data/assets_manifest.json"
const ASSET_ROOT := "res://assets"
const ASSET_PREFIX := "res://assets/"
const TEXTURE_EXTENSIONS := ["png", "jpg", "jpeg", "webp"]
const AUDIO_EXTENSIONS := ["wav", "ogg", "mp3"]
const FILTER_SETTING := "rendering/textures/canvas_textures/default_texture_filter"

var name_regex := RegEx.new()

func run() -> Dictionary:
	var helper = TestHelper.new()
	var regex_err = name_regex.compile("^[a-z0-9_\\-\\.]+$")
	helper.assert_true(regex_err == OK, "asset name regex compiles")
	if regex_err != OK:
		return helper.summary()

	var manifest = _load_manifest(helper)
	if manifest.is_empty():
		return helper.summary()

	var textures: Array = manifest.get("textures", [])
	var audio: Array = manifest.get("audio", [])
	_assert_pixel_filter(helper, textures)

	var ids: Dictionary = {}
	var paths: Dictionary = {}
	_validate_textures(helper, textures, ids, paths)
	_validate_audio(helper, audio, ids, paths)
	_assert_manifest_complete(helper, textures, audio)
	return helper.summary()

func _load_manifest(helper: TestHelper) -> Dictionary:
	helper.assert_true(FileAccess.file_exists(MANIFEST_PATH), "asset manifest exists")
	if not FileAccess.file_exists(MANIFEST_PATH):
		return {}
	var file = FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	helper.assert_true(file != null, "asset manifest opens")
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	helper.assert_true(parsed is Dictionary, "asset manifest is dictionary")
	if parsed is Dictionary:
		return parsed
	return {}

func _assert_pixel_filter(helper: TestHelper, textures: Array) -> void:
	var requires_nearest := false
	for entry in textures:
		if entry is Dictionary and bool(entry.get("pixel_art", false)):
			requires_nearest = true
			break
	if not requires_nearest:
		return
	var filter_value = ProjectSettings.get_setting(FILTER_SETTING)
	helper.assert_true(filter_value != null, "default texture filter set")
	if filter_value != null:
		helper.assert_eq(int(filter_value), 0, "default texture filter is nearest")

func _validate_textures(helper: TestHelper, textures: Array, ids: Dictionary, paths: Dictionary) -> void:
	for entry in textures:
		helper.assert_true(entry is Dictionary, "texture entry is dictionary")
		if not entry is Dictionary:
			continue
		var entry_id := str(entry.get("id", ""))
		var path := str(entry.get("path", ""))
		helper.assert_true(entry_id != "", "texture id present")
		helper.assert_true(path != "", "texture path present")
		_register_id(helper, ids, entry_id, "texture")
		_register_path(helper, paths, path, "texture")
		_assert_path_rules(helper, path, TEXTURE_EXTENSIONS, "texture")
		_assert_import_exists(helper, path, "texture")
		_assert_size_budget(helper, path, entry, "texture")
		_assert_texture_dimensions(helper, path, entry, entry_id)

func _validate_audio(helper: TestHelper, audio: Array, ids: Dictionary, paths: Dictionary) -> void:
	for entry in audio:
		helper.assert_true(entry is Dictionary, "audio entry is dictionary")
		if not entry is Dictionary:
			continue
		var entry_id := str(entry.get("id", ""))
		var path := str(entry.get("path", ""))
		helper.assert_true(entry_id != "", "audio id present")
		helper.assert_true(path != "", "audio path present")
		_register_id(helper, ids, entry_id, "audio")
		_register_path(helper, paths, path, "audio")
		_assert_path_rules(helper, path, AUDIO_EXTENSIONS, "audio")
		_assert_import_exists(helper, path, "audio")
		_assert_size_budget(helper, path, entry, "audio")
		_assert_audio_stream(helper, path, entry, entry_id)

func _register_id(helper: TestHelper, ids: Dictionary, entry_id: String, label: String) -> void:
	if entry_id == "":
		return
	helper.assert_true(not ids.has(entry_id), "%s id unique: %s" % [label, entry_id])
	if not ids.has(entry_id):
		ids[entry_id] = true

func _register_path(helper: TestHelper, paths: Dictionary, path: String, label: String) -> void:
	if path == "":
		return
	helper.assert_true(not paths.has(path), "%s path unique: %s" % [label, path])
	if not paths.has(path):
		paths[path] = true

func _assert_path_rules(helper: TestHelper, path: String, extensions: Array, label: String) -> void:
	helper.assert_true(path.begins_with(ASSET_PREFIX), "%s path under assets: %s" % [label, path])
	helper.assert_true(path.to_lower() == path, "%s path lowercase: %s" % [label, path])
	var file_name = path.get_file()
	helper.assert_true(name_regex.search(file_name) != null, "%s name valid: %s" % [label, file_name])
	helper.assert_true(FileAccess.file_exists(path), "%s file exists: %s" % [label, path])
	var ext = path.get_extension().to_lower()
	helper.assert_true(extensions.has(ext), "%s extension allowed: %s" % [label, ext])

func _assert_import_exists(helper: TestHelper, path: String, label: String) -> void:
	var import_path = path + ".import"
	helper.assert_true(FileAccess.file_exists(import_path), "%s import exists: %s" % [label, import_path])

func _assert_size_budget(helper: TestHelper, path: String, entry: Dictionary, label: String) -> void:
	if not entry.has("max_kb"):
		return
	var max_kb = int(entry.get("max_kb", 0))
	if max_kb <= 0:
		return
	var file = FileAccess.open(path, FileAccess.READ)
	helper.assert_true(file != null, "%s file opens for size: %s" % [label, path])
	if file == null:
		return
	var length = file.get_length()
	var max_bytes = max_kb * 1024
	helper.assert_true(length <= max_bytes, "%s size within %dkb: %s" % [label, max_kb, path])

func _assert_texture_dimensions(helper: TestHelper, path: String, entry: Dictionary, entry_id: String) -> void:
	var texture = load(path)
	helper.assert_true(texture is Texture2D, "texture loads: %s" % entry_id)
	if not texture is Texture2D:
		return
	var width = texture.get_width()
	var height = texture.get_height()
	if entry.has("expected_width"):
		helper.assert_eq(width, int(entry.get("expected_width", 0)), "texture width matches: %s" % entry_id)
	if entry.has("expected_height"):
		helper.assert_eq(height, int(entry.get("expected_height", 0)), "texture height matches: %s" % entry_id)
	if entry.has("max_width"):
		helper.assert_true(width <= int(entry.get("max_width", 0)), "texture width under max: %s" % entry_id)
	if entry.has("max_height"):
		helper.assert_true(height <= int(entry.get("max_height", 0)), "texture height under max: %s" % entry_id)

func _assert_audio_stream(helper: TestHelper, path: String, entry: Dictionary, entry_id: String) -> void:
	var stream = load(path)
	helper.assert_true(stream is AudioStream, "audio stream loads: %s" % entry_id)
	if not stream is AudioStream:
		return
	var length = stream.get_length()
	if entry.has("min_seconds"):
		helper.assert_true(length >= float(entry.get("min_seconds", 0.0)), "audio min length ok: %s" % entry_id)
	if entry.has("max_seconds"):
		helper.assert_true(length <= float(entry.get("max_seconds", 0.0)), "audio max length ok: %s" % entry_id)
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		if entry.has("expected_sample_rate"):
			helper.assert_eq(wav.mix_rate, int(entry.get("expected_sample_rate", 0)), "audio sample rate ok: %s" % entry_id)
		if entry.has("expected_channels"):
			var expected_channels = int(entry.get("expected_channels", 0))
			var actual_channels = 2 if wav.stereo else 1
			helper.assert_eq(actual_channels, expected_channels, "audio channels ok: %s" % entry_id)

func _assert_manifest_complete(helper: TestHelper, textures: Array, audio: Array) -> void:
	var texture_paths: Dictionary = {}
	for entry in textures:
		if entry is Dictionary:
			var path = str(entry.get("path", ""))
			if path != "":
				texture_paths[path] = true
	var audio_paths: Dictionary = {}
	for entry in audio:
		if entry is Dictionary:
			var path = str(entry.get("path", ""))
			if path != "":
				audio_paths[path] = true

	var expected_textures = _collect_asset_paths(ASSET_ROOT, TEXTURE_EXTENSIONS)
	for path in expected_textures:
		helper.assert_true(texture_paths.has(path), "texture listed in manifest: %s" % path)
	var expected_audio = _collect_asset_paths(ASSET_ROOT, AUDIO_EXTENSIONS)
	for path in expected_audio:
		helper.assert_true(audio_paths.has(path), "audio listed in manifest: %s" % path)

func _collect_asset_paths(root: String, extensions: Array) -> Array:
	var results: Array = []
	var dir = DirAccess.open(root)
	if dir == null:
		return results
	dir.list_dir_begin()
	var name = dir.get_next()
	while name != "":
		if name != "." and name != "..":
			var path = root.path_join(name)
			if dir.current_is_dir():
				results.append_array(_collect_asset_paths(path, extensions))
			else:
				var ext = path.get_extension().to_lower()
				if extensions.has(ext):
					results.append(path)
		name = dir.get_next()
	dir.list_dir_end()
	return results
