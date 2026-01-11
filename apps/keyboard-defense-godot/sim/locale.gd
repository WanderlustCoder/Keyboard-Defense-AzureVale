class_name SimLocale
extends RefCounted

# =============================================================================
# LOCALE CONSTANTS
# =============================================================================

const LOCALE_EN := "en"
const LOCALE_ES := "es"
const LOCALE_DE := "de"
const LOCALE_FR := "fr"
const LOCALE_PT := "pt"

const DEFAULT_LOCALE := LOCALE_EN

const SUPPORTED_LOCALES: Array[String] = [
	LOCALE_EN,
	LOCALE_ES,
	LOCALE_DE,
	LOCALE_FR,
	LOCALE_PT
]

const LOCALE_NAMES: Dictionary = {
	LOCALE_EN: "English",
	LOCALE_ES: "Español",
	LOCALE_DE: "Deutsch",
	LOCALE_FR: "Français",
	LOCALE_PT: "Português"
}

# =============================================================================
# TRANSLATION CATEGORIES
# =============================================================================

# Categories for organizing translation keys
const CATEGORY_UI := "ui"
const CATEGORY_GAME := "game"
const CATEGORY_COMMANDS := "commands"
const CATEGORY_COMBAT := "combat"
const CATEGORY_RESOURCES := "resources"
const CATEGORY_MESSAGES := "messages"
const CATEGORY_HELP := "help"

# =============================================================================
# STATE
# =============================================================================

# Current locale (module-level state)
static var _current_locale: String = DEFAULT_LOCALE
static var _translations: Dictionary = {}
static var _fallback_translations: Dictionary = {}

# =============================================================================
# LOCALE MANAGEMENT
# =============================================================================


## Get the current locale
static func get_locale() -> String:
	return _current_locale


## Set the current locale
static func set_locale(locale: String) -> bool:
	if not is_valid_locale(locale):
		return false

	_current_locale = locale
	_load_translations(locale)
	return true


## Check if a locale is valid/supported
static func is_valid_locale(locale: String) -> bool:
	return locale in SUPPORTED_LOCALES


## Get display name for a locale
static func get_locale_name(locale: String) -> String:
	return str(LOCALE_NAMES.get(locale, locale))


## Get all supported locales with their display names
static func get_supported_locales() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for locale in SUPPORTED_LOCALES:
		result.append({
			"id": locale,
			"name": LOCALE_NAMES.get(locale, locale)
		})
	return result


# =============================================================================
# TRANSLATION LOADING
# =============================================================================


## Load translations for a locale
static func _load_translations(locale: String) -> void:
	# Load target locale
	var path: String = "res://data/translations/%s.json" % locale
	_translations = _load_translation_file(path)

	# Load fallback (English) if not already the target
	if locale != DEFAULT_LOCALE:
		var fallback_path: String = "res://data/translations/%s.json" % DEFAULT_LOCALE
		_fallback_translations = _load_translation_file(fallback_path)
	else:
		_fallback_translations = {}


## Load a translation file
static func _load_translation_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var content: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var error: int = json.parse(content)
	if error != OK:
		return {}

	var data = json.data
	if data is Dictionary:
		return data

	return {}


## Initialize locale system (call at game start)
static func init(locale: String = "") -> void:
	if locale.is_empty():
		locale = DEFAULT_LOCALE
	set_locale(locale)


# =============================================================================
# TRANSLATION LOOKUP
# =============================================================================


## Get a translated string by key
## Supports placeholder substitution with {key} syntax
## Note: Named get_text to avoid conflict with Object.tr() built-in method
static func get_text(key: String, placeholders: Dictionary = {}) -> String:
	var text: String = _lookup(key)

	# Substitute placeholders
	if not placeholders.is_empty():
		for placeholder_key in placeholders.keys():
			var pattern: String = "{%s}" % placeholder_key
			text = text.replace(pattern, str(placeholders[placeholder_key]))

	return text


## Lookup a key in translations with fallback
static func _lookup(key: String) -> String:
	# Check current locale
	if _translations.has(key):
		return str(_translations[key])

	# Check nested lookup (e.g., "ui.save" -> translations["ui"]["save"])
	var nested: String = _lookup_nested(_translations, key)
	if not nested.is_empty():
		return nested

	# Check fallback
	if _fallback_translations.has(key):
		return str(_fallback_translations[key])

	nested = _lookup_nested(_fallback_translations, key)
	if not nested.is_empty():
		return nested

	# Return key as fallback (useful for debugging missing translations)
	return key


## Lookup nested keys like "ui.save" -> translations["ui"]["save"]
static func _lookup_nested(dict: Dictionary, key: String) -> String:
	var parts: PackedStringArray = key.split(".")
	var current = dict

	for part in parts:
		if current is Dictionary and current.has(part):
			current = current[part]
		else:
			return ""

	if current is String:
		return current

	return ""


# =============================================================================
# TRANSLATION KEY HELPERS
# =============================================================================


## Check if a translation key exists
static func has_key(key: String) -> bool:
	if _translations.has(key):
		return true
	if not _lookup_nested(_translations, key).is_empty():
		return true
	if _fallback_translations.has(key):
		return true
	if not _lookup_nested(_fallback_translations, key).is_empty():
		return true
	return false


## Get all keys for a category (e.g., "ui" returns all keys starting with "ui.")
static func get_category_keys(category: String) -> Array[String]:
	var keys: Array[String] = []
	var prefix: String = category + "."

	for key in _translations.keys():
		if str(key).begins_with(prefix):
			keys.append(str(key))

	return keys


# =============================================================================
# FORMATTING HELPERS
# =============================================================================


## Format a number with localized separators
static func format_number(value: int) -> String:
	var s: String = str(abs(value))
	var result: String = ""
	var count: int = 0

	# Use locale-appropriate separator
	var separator: String = ","  # Default English
	if _current_locale in [LOCALE_DE, LOCALE_FR, LOCALE_PT]:
		separator = "."
	elif _current_locale == LOCALE_ES:
		separator = "."

	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = separator + result
		result = s[i] + result
		count += 1

	if value < 0:
		result = "-" + result

	return result


## Format a percentage
static func format_percent(value: float, decimals: int = 1) -> String:
	var format_str: String = "%%.%df%%%%" % decimals
	return format_str % (value * 100.0)


## Format a time duration in seconds
static func format_duration(seconds: float) -> String:
	if seconds < 60:
		return get_text("time.seconds", {"value": int(seconds)})
	elif seconds < 3600:
		var mins: int = int(seconds / 60)
		var secs: int = int(seconds) % 60
		if secs > 0:
			return get_text("time.minutes_seconds", {"minutes": mins, "seconds": secs})
		return get_text("time.minutes", {"value": mins})
	else:
		var hours: int = int(seconds / 3600)
		var mins: int = (int(seconds) % 3600) / 60
		if mins > 0:
			return get_text("time.hours_minutes", {"hours": hours, "minutes": mins})
		return get_text("time.hours", {"value": hours})


# =============================================================================
# COMMAND HELP LOCALIZATION
# =============================================================================


## Get localized help text for a command
static func get_command_help(command: String) -> String:
	var key: String = "help.%s" % command
	if has_key(key):
		return get_text(key)
	return ""


## Get all localized command help as lines
static func get_all_command_help() -> Array[String]:
	var lines: Array[String] = []
	var keys: Array[String] = get_category_keys("help")

	for key in keys:
		lines.append(get_text(key))

	return lines


# =============================================================================
# LOCALE INFO
# =============================================================================


## Get info about current locale settings
static func get_locale_info() -> Dictionary:
	return {
		"current": _current_locale,
		"name": get_locale_name(_current_locale),
		"supported": SUPPORTED_LOCALES.duplicate(),
		"translations_loaded": not _translations.is_empty()
	}


## Format locale list for display
static func format_locale_list() -> String:
	var lines: Array[String] = []
	lines.append(get_text("ui.available_languages"))

	for locale in SUPPORTED_LOCALES:
		var marker: String = " *" if locale == _current_locale else ""
		lines.append("  %s - %s%s" % [locale, LOCALE_NAMES.get(locale, locale), marker])

	return "\n".join(lines)
