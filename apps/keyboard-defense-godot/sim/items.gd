class_name SimItems
extends RefCounted
## Item and Equipment System

# Rarity constants
const RARITY_COMMON := "common"
const RARITY_UNCOMMON := "uncommon"
const RARITY_RARE := "rare"
const RARITY_EPIC := "epic"
const RARITY_LEGENDARY := "legendary"

# Slot constants
const SLOT_HEADGEAR := "headgear"
const SLOT_ARMOR := "armor"
const SLOT_GLOVES := "gloves"
const SLOT_BOOTS := "boots"
const SLOT_AMULET := "amulet"
const SLOT_RING := "ring"
const SLOT_BELT := "belt"
const SLOT_CAPE := "cape"

const EQUIPMENT_SLOTS: Array[String] = [
	SLOT_HEADGEAR, SLOT_ARMOR, SLOT_GLOVES, SLOT_BOOTS,
	SLOT_AMULET, SLOT_RING, SLOT_BELT, SLOT_CAPE
]

# Rarity colors for UI
const RARITY_COLORS: Dictionary = {
	"common": "#FFFFFF",
	"uncommon": "#00FF00",
	"rare": "#0088FF",
	"epic": "#AA00FF",
	"legendary": "#FF8800"
}

# Rarity drop weights
const RARITY_WEIGHTS: Dictionary = {
	"common": 60,
	"uncommon": 25,
	"rare": 10,
	"epic": 4,
	"legendary": 1
}

# Equipment definitions
const EQUIPMENT: Dictionary = {
	# Headgear
	"helm_basic": {
		"name": "Leather Cap",
		"slot": "headgear",
		"rarity": "common",
		"stats": {"defense": 2},
		"description": "Simple protective headwear."
	},
	"helm_focus": {
		"name": "Scholar's Hood",
		"slot": "headgear",
		"rarity": "uncommon",
		"stats": {"accuracy_bonus": 0.03},
		"description": "Helps maintain focus while typing."
	},
	"helm_speed": {
		"name": "Windrunner Helm",
		"slot": "headgear",
		"rarity": "rare",
		"stats": {"wpm_bonus": 3},
		"effect": {"name": "Tailwind", "type": "first_word_speed", "value": 0.2},
		"description": "Blessed by wind spirits for swift action."
	},
	"helm_void": {
		"name": "Crown of Clarity",
		"slot": "headgear",
		"rarity": "epic",
		"stats": {"accuracy_bonus": 0.08, "defense": 5},
		"effect": {"name": "Clear Mind", "type": "scramble_immunity", "value": 1},
		"description": "Protects the mind from void corruption."
	},
	# Armor
	"armor_basic": {
		"name": "Cloth Robes",
		"slot": "armor",
		"rarity": "common",
		"stats": {"defense": 5},
		"description": "Simple protective clothing."
	},
	"armor_leather": {
		"name": "Leather Armor",
		"slot": "armor",
		"rarity": "uncommon",
		"stats": {"defense": 10, "gold_bonus": 0.05},
		"description": "Sturdy leather protection with pockets."
	},
	"armor_chain": {
		"name": "Chain Mail",
		"slot": "armor",
		"rarity": "rare",
		"stats": {"defense": 15},
		"effect": {"name": "Deflection", "type": "damage_reduction", "value": 0.1},
		"description": "Interlocking rings deflect glancing blows."
	},
	"armor_plate": {
		"name": "Plate Armor",
		"slot": "armor",
		"rarity": "epic",
		"stats": {"defense": 25},
		"effect": {"name": "Fortress", "type": "damage_reduction", "value": 0.2},
		"description": "Heavy but offers excellent protection."
	},
	# Gloves
	"gloves_basic": {
		"name": "Cloth Gloves",
		"slot": "gloves",
		"rarity": "common",
		"stats": {"accuracy_bonus": 0.01},
		"description": "Light gloves for comfort."
	},
	"gloves_typing": {
		"name": "Typist's Gloves",
		"slot": "gloves",
		"rarity": "uncommon",
		"stats": {"accuracy_bonus": 0.03, "wpm_bonus": 1},
		"description": "Designed for precise finger movements."
	},
	"gloves_swift": {
		"name": "Swift Fingers",
		"slot": "gloves",
		"rarity": "rare",
		"stats": {"wpm_bonus": 3},
		"effect": {"name": "Nimble", "type": "combo_bonus", "value": 0.05},
		"description": "Enchanted for lightning-fast typing."
	},
	"gloves_master": {
		"name": "Grandmaster's Gauntlets",
		"slot": "gloves",
		"rarity": "epic",
		"stats": {"accuracy_bonus": 0.1, "wpm_bonus": 5},
		"effect": {"name": "Perfection", "type": "crit_chance", "value": 0.1},
		"description": "Worn by legendary typing masters."
	},
	# Boots
	"boots_basic": {
		"name": "Leather Boots",
		"slot": "boots",
		"rarity": "common",
		"stats": {"defense": 2},
		"description": "Simple leather footwear."
	},
	"boots_swift": {
		"name": "Quickstep Boots",
		"slot": "boots",
		"rarity": "uncommon",
		"stats": {"gold_bonus": 0.05},
		"effect": {"name": "Fleet Footed", "type": "enemy_slow", "value": 0.05},
		"description": "Makes enemies seem slower by comparison."
	},
	"boots_grounded": {
		"name": "Grounded Treads",
		"slot": "boots",
		"rarity": "rare",
		"stats": {"defense": 8},
		"effect": {"name": "Stability", "type": "mistake_reduction", "value": 0.15},
		"description": "Stay steady under pressure."
	},
	# Amulet
	"amulet_basic": {
		"name": "Bronze Amulet",
		"slot": "amulet",
		"rarity": "common",
		"stats": {"gold_bonus": 0.05},
		"description": "A simple good luck charm."
	},
	"amulet_focus": {
		"name": "Focusing Crystal",
		"slot": "amulet",
		"rarity": "uncommon",
		"stats": {"accuracy_bonus": 0.05},
		"description": "Helps maintain concentration."
	},
	"amulet_power": {
		"name": "Power Pendant",
		"slot": "amulet",
		"rarity": "rare",
		"stats": {"damage_bonus": 0.1},
		"description": "Amplifies typing power."
	},
	"amulet_legend": {
		"name": "Heart of Keystonia",
		"slot": "amulet",
		"rarity": "legendary",
		"stats": {"damage_bonus": 0.2, "accuracy_bonus": 0.1, "gold_bonus": 0.15},
		"effect": {"name": "Kingdom's Blessing", "type": "all_stats", "value": 0.1},
		"description": "Contains the spirit of the kingdom."
	},
	# Ring
	"ring_basic": {
		"name": "Iron Ring",
		"slot": "ring",
		"rarity": "common",
		"stats": {"defense": 1},
		"description": "A simple iron band."
	},
	"ring_gold": {
		"name": "Gold Ring",
		"slot": "ring",
		"rarity": "uncommon",
		"stats": {"gold_bonus": 0.1},
		"description": "Attracts more gold from fallen enemies."
	},
	"ring_combo": {
		"name": "Combo Ring",
		"slot": "ring",
		"rarity": "rare",
		"stats": {},
		"effect": {"name": "Chain Reaction", "type": "combo_bonus", "value": 0.1},
		"description": "Combos build faster and stronger."
	},
	"ring_crit": {
		"name": "Critical Band",
		"slot": "ring",
		"rarity": "epic",
		"stats": {},
		"effect": {"name": "Deadly Precision", "type": "crit_damage", "value": 0.5},
		"description": "Critical hits deal devastating damage."
	},
	# Belt
	"belt_basic": {
		"name": "Leather Belt",
		"slot": "belt",
		"rarity": "common",
		"stats": {"defense": 2},
		"description": "A simple belt with pouches."
	},
	"belt_supply": {
		"name": "Supply Belt",
		"slot": "belt",
		"rarity": "uncommon",
		"stats": {"gold_bonus": 0.08},
		"description": "Extra pouches for loot."
	},
	"belt_hero": {
		"name": "Hero's Girdle",
		"slot": "belt",
		"rarity": "rare",
		"stats": {"defense": 5, "damage_bonus": 0.05},
		"effect": {"name": "Heroic", "type": "xp_bonus", "value": 0.1},
		"description": "Worn by heroes of old."
	},
	# Cape
	"cape_basic": {
		"name": "Traveler's Cloak",
		"slot": "cape",
		"rarity": "common",
		"stats": {"defense": 1},
		"description": "A simple traveling cloak."
	},
	"cape_wind": {
		"name": "Windswept Cape",
		"slot": "cape",
		"rarity": "uncommon",
		"stats": {"wpm_bonus": 2},
		"description": "Flows dramatically in the breeze."
	},
	"cape_shadow": {
		"name": "Shadow Cloak",
		"slot": "cape",
		"rarity": "rare",
		"stats": {"defense": 5},
		"effect": {"name": "Evasion", "type": "dodge_chance", "value": 0.1},
		"description": "Blend into the shadows."
	},
	"cape_royal": {
		"name": "Royal Mantle",
		"slot": "cape",
		"rarity": "legendary",
		"stats": {"defense": 10, "gold_bonus": 0.2},
		"effect": {"name": "Regal Presence", "type": "enemy_slow", "value": 0.15},
		"description": "The mantle of Keystonia's rulers."
	}
}

# Consumable items
const CONSUMABLES: Dictionary = {
	"potion_health": {
		"name": "Health Potion",
		"type": "potion",
		"rarity": "common",
		"effect": {"type": "heal", "value": 3},
		"description": "Restores 3 castle HP.",
		"price": 50
	},
	"potion_health_large": {
		"name": "Greater Health Potion",
		"type": "potion",
		"rarity": "uncommon",
		"effect": {"type": "heal", "value": 5},
		"description": "Restores 5 castle HP.",
		"price": 100
	},
	"scroll_damage": {
		"name": "Scroll of Power",
		"type": "scroll",
		"rarity": "uncommon",
		"effect": {"type": "damage_buff", "value": 0.5, "duration": 30.0},
		"description": "+50% damage for 30 seconds.",
		"price": 75
	},
	"scroll_freeze": {
		"name": "Scroll of Frost",
		"type": "scroll",
		"rarity": "rare",
		"effect": {"type": "freeze_all", "duration": 3.0},
		"description": "Freezes all enemies for 3 seconds.",
		"price": 150
	},
	"scroll_gold": {
		"name": "Scroll of Wealth",
		"type": "scroll",
		"rarity": "rare",
		"effect": {"type": "gold_buff", "value": 1.0, "duration": 60.0},
		"description": "Double gold for 60 seconds.",
		"price": 200
	},
	"food_bread": {
		"name": "Fresh Bread",
		"type": "food",
		"rarity": "common",
		"effect": {"type": "regen", "value": 1, "duration": 60.0},
		"description": "Regenerate 1 HP per wave for 1 minute.",
		"price": 30
	},
	"food_feast": {
		"name": "Hearty Feast",
		"type": "food",
		"rarity": "uncommon",
		"effect": {"type": "all_buff", "value": 0.1, "duration": 120.0},
		"description": "+10% all stats for 2 minutes.",
		"price": 100
	}
}


## Get item data by ID
static func get_item(item_id: String) -> Dictionary:
	if EQUIPMENT.has(item_id):
		var item: Dictionary = EQUIPMENT[item_id].duplicate()
		item["id"] = item_id
		item["category"] = "equipment"
		return item
	if CONSUMABLES.has(item_id):
		var item: Dictionary = CONSUMABLES[item_id].duplicate()
		item["id"] = item_id
		item["category"] = "consumable"
		return item
	return {}


## Get item name
static func get_item_name(item_id: String) -> String:
	var item: Dictionary = get_item(item_id)
	return str(item.get("name", item_id))


## Get item rarity
static func get_item_rarity(item_id: String) -> String:
	var item: Dictionary = get_item(item_id)
	return str(item.get("rarity", "common"))


## Get rarity color
static func get_rarity_color(rarity: String) -> Color:
	var hex: String = RARITY_COLORS.get(rarity, "#FFFFFF")
	return Color.from_string(hex, Color.WHITE)


## Get item color by ID
static func get_item_color(item_id: String) -> Color:
	return get_rarity_color(get_item_rarity(item_id))


## Check if item is equipment
static func is_equipment(item_id: String) -> bool:
	return EQUIPMENT.has(item_id)


## Check if item is consumable
static func is_consumable(item_id: String) -> bool:
	return CONSUMABLES.has(item_id)


## Get equipment slot
static func get_slot(item_id: String) -> String:
	var item: Dictionary = get_item(item_id)
	return str(item.get("slot", ""))


## Get all items for a slot
static func get_items_for_slot(slot: String) -> Array[String]:
	var result: Array[String] = []
	for item_id in EQUIPMENT.keys():
		var item: Dictionary = EQUIPMENT[item_id]
		if str(item.get("slot", "")) == slot:
			result.append(item_id)
	return result


## Get item stats
static func get_item_stats(item_id: String) -> Dictionary:
	var item: Dictionary = get_item(item_id)
	return item.get("stats", {})


## Get item effect
static func get_item_effect(item_id: String) -> Dictionary:
	var item: Dictionary = get_item(item_id)
	return item.get("effect", {})


## Calculate total stats from equipped items
static func calculate_equipment_stats(equipped: Dictionary) -> Dictionary:
	var totals: Dictionary = {
		"defense": 0,
		"accuracy_bonus": 0.0,
		"wpm_bonus": 0,
		"damage_bonus": 0.0,
		"gold_bonus": 0.0,
		"crit_chance": 0.0,
		"crit_damage": 0.0,
		"combo_bonus": 0.0,
		"damage_reduction": 0.0,
		"enemy_slow": 0.0,
		"mistake_reduction": 0.0,
		"xp_bonus": 0.0,
		"dodge_chance": 0.0
	}

	for slot in EQUIPMENT_SLOTS:
		var item_id: String = str(equipped.get(slot, ""))
		if item_id.is_empty():
			continue

		var stats: Dictionary = get_item_stats(item_id)
		for stat_key in stats.keys():
			if totals.has(stat_key):
				if typeof(totals[stat_key]) == TYPE_FLOAT:
					totals[stat_key] = float(totals[stat_key]) + float(stats[stat_key])
				else:
					totals[stat_key] = int(totals[stat_key]) + int(stats[stat_key])

		# Also add effect bonuses
		var effect: Dictionary = get_item_effect(item_id)
		if not effect.is_empty():
			var effect_type: String = str(effect.get("type", ""))
			var effect_value: float = float(effect.get("value", 0))
			if totals.has(effect_type):
				totals[effect_type] = float(totals[effect_type]) + effect_value

	return totals


## Format item for display
static func format_item_display(item_id: String) -> String:
	var item: Dictionary = get_item(item_id)
	if item.is_empty():
		return "[color=gray]Empty[/color]"

	var name: String = str(item.get("name", item_id))
	var rarity: String = str(item.get("rarity", "common"))
	var color: String = RARITY_COLORS.get(rarity, "#FFFFFF")

	return "[color=%s]%s[/color]" % [color, name]


## Format item with stats
static func format_item_full(item_id: String) -> String:
	var item: Dictionary = get_item(item_id)
	if item.is_empty():
		return "[color=gray]Unknown item[/color]"

	var name: String = str(item.get("name", item_id))
	var rarity: String = str(item.get("rarity", "common"))
	var color: String = RARITY_COLORS.get(rarity, "#FFFFFF")
	var desc: String = str(item.get("description", ""))

	var lines: Array[String] = []
	lines.append("[color=%s]%s[/color] (%s)" % [color, name, rarity.capitalize()])

	var stats: Dictionary = item.get("stats", {})
	if not stats.is_empty():
		var stat_parts: Array[String] = []
		for key in stats.keys():
			var value: Variant = stats[key]
			if typeof(value) == TYPE_FLOAT:
				stat_parts.append("%s +%.0f%%" % [key.replace("_", " ").capitalize(), float(value) * 100])
			else:
				stat_parts.append("%s +%d" % [key.replace("_", " ").capitalize(), value])
		lines.append("  Stats: %s" % ", ".join(stat_parts))

	var effect: Dictionary = item.get("effect", {})
	if not effect.is_empty():
		var effect_name: String = str(effect.get("name", ""))
		var effect_desc: String = str(effect.get("description", ""))
		if effect_desc.is_empty():
			effect_desc = "%s: %s" % [str(effect.get("type", "")), str(effect.get("value", ""))]
		lines.append("  [color=yellow]%s[/color]: %s" % [effect_name, effect_desc])

	lines.append("  %s" % desc)

	return "\n".join(lines)


## Roll for item drop (returns item_id or empty string)
static func roll_drop(day: int, is_boss: bool, rng_seed: int) -> String:
	# Base drop chance increases with day
	var base_chance: float = 0.05 + (float(day) * 0.01)
	if is_boss:
		base_chance = 0.5  # Bosses have 50% drop chance

	# Use deterministic random
	var roll: float = fmod(float(rng_seed * 7919 + day * 1009) / 100000.0, 1.0)
	if roll > base_chance:
		return ""

	# Roll rarity
	var rarity_roll: int = int(fmod(float(rng_seed * 3571 + day * 2003) / 100.0, 100.0))
	var rarity: String = "common"
	var cumulative: int = 0
	for r in ["common", "uncommon", "rare", "epic", "legendary"]:
		cumulative += RARITY_WEIGHTS[r]
		if rarity_roll < cumulative:
			rarity = r
			break

	# Boss drops are at least uncommon
	if is_boss and rarity == "common":
		rarity = "uncommon"

	# Pick random item of that rarity
	var candidates: Array[String] = []
	for item_id in EQUIPMENT.keys():
		if str(EQUIPMENT[item_id].get("rarity", "")) == rarity:
			candidates.append(item_id)

	if candidates.is_empty():
		return ""

	var item_index: int = int(fmod(float(rng_seed * 1237 + day * 503), float(candidates.size())))
	return candidates[item_index]


## Create empty equipment loadout
static func empty_equipment() -> Dictionary:
	var result: Dictionary = {}
	for slot in EQUIPMENT_SLOTS:
		result[slot] = ""
	return result


## Equip item (returns updated equipment dict)
static func equip_item(equipment: Dictionary, item_id: String) -> Dictionary:
	var slot: String = get_slot(item_id)
	if slot.is_empty():
		return equipment

	var result: Dictionary = equipment.duplicate()
	result[slot] = item_id
	return result


## Unequip slot (returns updated equipment dict and item_id)
static func unequip_slot(equipment: Dictionary, slot: String) -> Dictionary:
	var result: Dictionary = equipment.duplicate()
	var removed: String = str(result.get(slot, ""))
	result[slot] = ""
	return {"equipment": result, "removed": removed}


## Serialize equipment for save
static func serialize_equipment(equipment: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for slot in EQUIPMENT_SLOTS:
		result[slot] = str(equipment.get(slot, ""))
	return result


## Deserialize equipment from save
static func deserialize_equipment(data: Dictionary) -> Dictionary:
	var result: Dictionary = empty_equipment()
	for slot in EQUIPMENT_SLOTS:
		if data.has(slot):
			result[slot] = str(data.get(slot, ""))
	return result


## Serialize inventory (array of item_ids)
static func serialize_inventory(inventory: Array) -> Array:
	var result: Array = []
	for item in inventory:
		result.append(str(item))
	return result


## Deserialize inventory
static func deserialize_inventory(data: Array) -> Array[String]:
	var result: Array[String] = []
	for item in data:
		result.append(str(item))
	return result
