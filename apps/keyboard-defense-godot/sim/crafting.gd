class_name SimCrafting
extends RefCounted
## Crafting System - Combine materials to create equipment and consumables

# Material definitions
const MATERIALS: Dictionary = {
	# Basic materials (drop from enemies)
	"scrap_metal": {"name": "Scrap Metal", "tier": 1, "description": "Common metal scraps"},
	"leather_scraps": {"name": "Leather Scraps", "tier": 1, "description": "Bits of leather"},
	"crystal_shard": {"name": "Crystal Shard", "tier": 1, "description": "Small magical crystal"},
	"herb_common": {"name": "Common Herb", "tier": 1, "description": "A useful herb"},

	# Uncommon materials (drop from elites)
	"iron_ingot": {"name": "Iron Ingot", "tier": 2, "description": "Refined iron"},
	"quality_leather": {"name": "Quality Leather", "tier": 2, "description": "Well-tanned leather"},
	"crystal_cluster": {"name": "Crystal Cluster", "tier": 2, "description": "Larger magical crystal"},
	"herb_rare": {"name": "Rare Herb", "tier": 2, "description": "Hard to find herb"},

	# Rare materials (drop from bosses)
	"steel_ingot": {"name": "Steel Ingot", "tier": 3, "description": "High quality steel"},
	"enchanted_leather": {"name": "Enchanted Leather", "tier": 3, "description": "Magically treated leather"},
	"mana_crystal": {"name": "Mana Crystal", "tier": 3, "description": "Pure crystallized mana"},
	"essence_power": {"name": "Essence of Power", "tier": 3, "description": "Concentrated magical essence"},

	# Epic materials (rare boss drops)
	"keysteel": {"name": "Keysteel", "tier": 4, "description": "Legendary typing metal"},
	"dragon_leather": {"name": "Dragon Leather", "tier": 4, "description": "Hide of a dragon"},
	"word_crystal": {"name": "Word Crystal", "tier": 4, "description": "Crystallized language"}
}

# Crafting recipes
const RECIPES: Dictionary = {
	# === CONSUMABLES ===
	"health_potion": {
		"name": "Health Potion",
		"category": "consumable",
		"ingredients": [
			{"item": "herb_common", "qty": 3}
		],
		"gold_cost": 10,
		"output_item": "potion_health",
		"output_qty": 1,
		"unlock": {"type": "default"}
	},
	"health_potion_large": {
		"name": "Large Health Potion",
		"category": "consumable",
		"ingredients": [
			{"item": "herb_common", "qty": 2},
			{"item": "herb_rare", "qty": 1}
		],
		"gold_cost": 25,
		"output_item": "potion_health_large",
		"output_qty": 1,
		"unlock": {"type": "level", "value": 5}
	},
	"damage_scroll": {
		"name": "Scroll of Power",
		"category": "consumable",
		"ingredients": [
			{"item": "crystal_shard", "qty": 2},
			{"item": "herb_common", "qty": 1}
		],
		"gold_cost": 15,
		"output_item": "scroll_damage",
		"output_qty": 1,
		"unlock": {"type": "default"}
	},
	"speed_elixir": {
		"name": "Speed Elixir",
		"category": "consumable",
		"ingredients": [
			{"item": "herb_rare", "qty": 2},
			{"item": "crystal_shard", "qty": 1}
		],
		"gold_cost": 30,
		"output_item": "elixir_speed",
		"output_qty": 1,
		"unlock": {"type": "level", "value": 8}
	},
	"combo_potion": {
		"name": "Combo Potion",
		"category": "consumable",
		"ingredients": [
			{"item": "crystal_cluster", "qty": 1},
			{"item": "herb_rare", "qty": 1}
		],
		"gold_cost": 40,
		"output_item": "potion_combo",
		"output_qty": 1,
		"unlock": {"type": "level", "value": 10}
	},
	"gold_elixir": {
		"name": "Elixir of Fortune",
		"category": "consumable",
		"ingredients": [
			{"item": "herb_rare", "qty": 3},
			{"item": "crystal_cluster", "qty": 1}
		],
		"gold_cost": 50,
		"output_item": "elixir_gold",
		"output_qty": 1,
		"unlock": {"type": "level", "value": 12}
	},

	# === BASIC EQUIPMENT (Tier 1) ===
	"helm_basic": {
		"name": "Leather Cap",
		"category": "equipment",
		"ingredients": [
			{"item": "leather_scraps", "qty": 4},
			{"item": "scrap_metal", "qty": 1}
		],
		"gold_cost": 30,
		"output_item": "helm_leather",
		"output_qty": 1,
		"unlock": {"type": "default"}
	},
	"armor_basic": {
		"name": "Leather Vest",
		"category": "equipment",
		"ingredients": [
			{"item": "leather_scraps", "qty": 6},
			{"item": "scrap_metal", "qty": 2}
		],
		"gold_cost": 50,
		"output_item": "armor_leather",
		"output_qty": 1,
		"unlock": {"type": "default"}
	},
	"gloves_basic": {
		"name": "Leather Gloves",
		"category": "equipment",
		"ingredients": [
			{"item": "leather_scraps", "qty": 3}
		],
		"gold_cost": 20,
		"output_item": "gloves_leather",
		"output_qty": 1,
		"unlock": {"type": "default"}
	},
	"ring_basic": {
		"name": "Simple Ring",
		"category": "equipment",
		"ingredients": [
			{"item": "scrap_metal", "qty": 3},
			{"item": "crystal_shard", "qty": 1}
		],
		"gold_cost": 25,
		"output_item": "ring_simple",
		"output_qty": 1,
		"unlock": {"type": "default"}
	},

	# === STANDARD EQUIPMENT (Tier 2) ===
	"helm_iron": {
		"name": "Iron Helm",
		"category": "equipment",
		"ingredients": [
			{"item": "iron_ingot", "qty": 3},
			{"item": "leather_scraps", "qty": 2}
		],
		"gold_cost": 80,
		"output_item": "helm_iron",
		"output_qty": 1,
		"unlock": {"type": "level", "value": 10}
	},
	"armor_iron": {
		"name": "Iron Chestplate",
		"category": "equipment",
		"ingredients": [
			{"item": "iron_ingot", "qty": 5},
			{"item": "quality_leather", "qty": 2}
		],
		"gold_cost": 120,
		"output_item": "armor_iron",
		"output_qty": 1,
		"unlock": {"type": "level", "value": 10}
	},
	"gloves_typing": {
		"name": "Typist's Gloves",
		"category": "equipment",
		"ingredients": [
			{"item": "quality_leather", "qty": 3},
			{"item": "crystal_cluster", "qty": 1}
		],
		"gold_cost": 100,
		"output_item": "gloves_typing",
		"output_qty": 1,
		"unlock": {"type": "level", "value": 12}
	},
	"amulet_accuracy": {
		"name": "Accuracy Amulet",
		"category": "equipment",
		"ingredients": [
			{"item": "crystal_cluster", "qty": 2},
			{"item": "iron_ingot", "qty": 1}
		],
		"gold_cost": 90,
		"output_item": "amulet_accuracy",
		"output_qty": 1,
		"unlock": {"type": "level", "value": 10}
	},

	# === ADVANCED EQUIPMENT (Tier 3) ===
	"helm_steel": {
		"name": "Steel Helm",
		"category": "equipment",
		"ingredients": [
			{"item": "steel_ingot", "qty": 3},
			{"item": "enchanted_leather", "qty": 1}
		],
		"gold_cost": 200,
		"output_item": "helm_steel",
		"output_qty": 1,
		"unlock": {"type": "level", "value": 18}
	},
	"armor_steel": {
		"name": "Steel Chestplate",
		"category": "equipment",
		"ingredients": [
			{"item": "steel_ingot", "qty": 5},
			{"item": "enchanted_leather", "qty": 2}
		],
		"gold_cost": 300,
		"output_item": "armor_steel",
		"output_qty": 1,
		"unlock": {"type": "level", "value": 18}
	},
	"ring_power": {
		"name": "Ring of Power",
		"category": "equipment",
		"ingredients": [
			{"item": "mana_crystal", "qty": 1},
			{"item": "steel_ingot", "qty": 2},
			{"item": "essence_power", "qty": 1}
		],
		"gold_cost": 250,
		"output_item": "ring_power",
		"output_qty": 1,
		"unlock": {"type": "level", "value": 20}
	},
	"amulet_combo": {
		"name": "Combo Master Amulet",
		"category": "equipment",
		"ingredients": [
			{"item": "mana_crystal", "qty": 2},
			{"item": "essence_power", "qty": 1}
		],
		"gold_cost": 280,
		"output_item": "amulet_combo",
		"output_qty": 1,
		"unlock": {"type": "level", "value": 20}
	},

	# === LEGENDARY EQUIPMENT (Tier 4) ===
	"helm_legendary": {
		"name": "Crown of Words",
		"category": "equipment",
		"ingredients": [
			{"item": "keysteel", "qty": 3},
			{"item": "word_crystal", "qty": 2},
			{"item": "mana_crystal", "qty": 2}
		],
		"gold_cost": 800,
		"output_item": "helm_legendary",
		"output_qty": 1,
		"unlock": {"type": "level", "value": 30}
	},
	"armor_legendary": {
		"name": "Wordweave Mantle",
		"category": "equipment",
		"ingredients": [
			{"item": "dragon_leather", "qty": 3},
			{"item": "word_crystal", "qty": 3},
			{"item": "keysteel", "qty": 2}
		],
		"gold_cost": 1000,
		"output_item": "armor_legendary",
		"output_qty": 1,
		"unlock": {"type": "level", "value": 30}
	},

	# === MATERIAL UPGRADES ===
	"upgrade_iron": {
		"name": "Refine Iron",
		"category": "material",
		"ingredients": [
			{"item": "scrap_metal", "qty": 5}
		],
		"gold_cost": 20,
		"output_item": "iron_ingot",
		"output_qty": 1,
		"unlock": {"type": "level", "value": 5}
	},
	"upgrade_steel": {
		"name": "Forge Steel",
		"category": "material",
		"ingredients": [
			{"item": "iron_ingot", "qty": 3}
		],
		"gold_cost": 50,
		"output_item": "steel_ingot",
		"output_qty": 1,
		"unlock": {"type": "level", "value": 15}
	},
	"upgrade_crystal": {
		"name": "Fuse Crystals",
		"category": "material",
		"ingredients": [
			{"item": "crystal_shard", "qty": 5}
		],
		"gold_cost": 25,
		"output_item": "crystal_cluster",
		"output_qty": 1,
		"unlock": {"type": "level", "value": 8}
	},
	"upgrade_mana_crystal": {
		"name": "Concentrate Mana",
		"category": "material",
		"ingredients": [
			{"item": "crystal_cluster", "qty": 3}
		],
		"gold_cost": 75,
		"output_item": "mana_crystal",
		"output_qty": 1,
		"unlock": {"type": "level", "value": 18}
	}
}


## Get player's materials from profile
static func get_materials(profile: Dictionary) -> Dictionary:
	return TypingProfile.get_profile_value(profile, "crafting_materials", {})


## Set player's materials in profile
static func set_materials(profile: Dictionary, materials: Dictionary) -> void:
	TypingProfile.set_profile_value(profile, "crafting_materials", materials)


## Get count of a specific material
static func get_material_count(profile: Dictionary, material_id: String) -> int:
	var materials: Dictionary = get_materials(profile)
	return int(materials.get(material_id, 0))


## Add materials to player's inventory
static func add_material(profile: Dictionary, material_id: String, quantity: int = 1) -> void:
	var materials: Dictionary = get_materials(profile)
	materials[material_id] = int(materials.get(material_id, 0)) + quantity
	set_materials(profile, materials)


## Remove materials from player's inventory
static func remove_material(profile: Dictionary, material_id: String, quantity: int = 1) -> bool:
	var materials: Dictionary = get_materials(profile)
	var current: int = int(materials.get(material_id, 0))

	if current < quantity:
		return false

	materials[material_id] = current - quantity
	if materials[material_id] <= 0:
		materials.erase(material_id)

	set_materials(profile, materials)
	return true


## Check if player has required materials for a recipe
static func can_craft(profile: Dictionary, recipe_id: String, gold: int) -> Dictionary:
	var recipe: Dictionary = RECIPES.get(recipe_id, {})
	if recipe.is_empty():
		return {"can_craft": false, "reason": "Recipe not found"}

	# Check unlock requirements
	var unlock: Dictionary = recipe.get("unlock", {"type": "default"})
	var unlock_type: String = str(unlock.get("type", "default"))

	if unlock_type == "level":
		var req_level: int = int(unlock.get("value", 1))
		var player_level: int = int(TypingProfile.get_profile_value(profile, "player_level", 1))
		if player_level < req_level:
			return {"can_craft": false, "reason": "Requires level %d" % req_level}

	# Check gold
	var gold_cost: int = int(recipe.get("gold_cost", 0))
	if gold < gold_cost:
		return {"can_craft": false, "reason": "Not enough gold (need %d)" % gold_cost}

	# Check materials
	var ingredients: Array = recipe.get("ingredients", [])
	var materials: Dictionary = get_materials(profile)
	var missing: Array[String] = []

	for ingredient in ingredients:
		var item_id: String = str(ingredient.get("item", ""))
		var qty_needed: int = int(ingredient.get("qty", 1))
		var qty_have: int = int(materials.get(item_id, 0))

		if qty_have < qty_needed:
			var material_name: String = str(MATERIALS.get(item_id, {}).get("name", item_id))
			missing.append("%s (%d/%d)" % [material_name, qty_have, qty_needed])

	if not missing.is_empty():
		return {"can_craft": false, "reason": "Missing: " + ", ".join(missing)}

	return {"can_craft": true, "reason": ""}


## Craft an item
static func craft(profile: Dictionary, recipe_id: String, gold: int) -> Dictionary:
	var check: Dictionary = can_craft(profile, recipe_id, gold)
	if not bool(check.get("can_craft", false)):
		return {"success": false, "error": str(check.get("reason", "Cannot craft"))}

	var recipe: Dictionary = RECIPES[recipe_id]

	# Remove materials
	var ingredients: Array = recipe.get("ingredients", [])
	for ingredient in ingredients:
		var item_id: String = str(ingredient.get("item", ""))
		var qty: int = int(ingredient.get("qty", 1))
		remove_material(profile, item_id, qty)

	# Add output item to inventory
	var output_item: String = str(recipe.get("output_item", ""))
	var output_qty: int = int(recipe.get("output_qty", 1))

	for i in range(output_qty):
		TypingProfile.add_to_inventory(profile, output_item)

	# Return gold cost for caller to deduct
	return {
		"success": true,
		"gold_cost": int(recipe.get("gold_cost", 0)),
		"output_item": output_item,
		"output_qty": output_qty,
		"recipe_name": str(recipe.get("name", recipe_id))
	}


## Get unlocked recipes for player
static func get_unlocked_recipes(profile: Dictionary) -> Array[String]:
	var player_level: int = int(TypingProfile.get_profile_value(profile, "player_level", 1))
	var unlocked: Array[String] = []

	for recipe_id in RECIPES.keys():
		var recipe: Dictionary = RECIPES[recipe_id]
		var unlock: Dictionary = recipe.get("unlock", {"type": "default"})
		var unlock_type: String = str(unlock.get("type", "default"))

		var is_unlocked: bool = false
		match unlock_type:
			"default":
				is_unlocked = true
			"level":
				is_unlocked = player_level >= int(unlock.get("value", 1))

		if is_unlocked:
			unlocked.append(recipe_id)

	return unlocked


## Get recipes by category
static func get_recipes_by_category(profile: Dictionary, category: String) -> Array[String]:
	var unlocked: Array[String] = get_unlocked_recipes(profile)
	var filtered: Array[String] = []

	for recipe_id in unlocked:
		var recipe: Dictionary = RECIPES.get(recipe_id, {})
		if str(recipe.get("category", "")) == category:
			filtered.append(recipe_id)

	return filtered


## Format recipe for display
static func format_recipe(profile: Dictionary, recipe_id: String, gold: int) -> String:
	var recipe: Dictionary = RECIPES.get(recipe_id, {})
	if recipe.is_empty():
		return "Unknown recipe"

	var lines: Array[String] = []
	var name: String = str(recipe.get("name", recipe_id))
	var category: String = str(recipe.get("category", "misc"))
	var gold_cost: int = int(recipe.get("gold_cost", 0))

	lines.append("[color=yellow]%s[/color] [%s]" % [name, category])

	# Ingredients
	lines.append("[color=cyan]Ingredients:[/color]")
	var ingredients: Array = recipe.get("ingredients", [])
	var materials: Dictionary = get_materials(profile)

	for ingredient in ingredients:
		var item_id: String = str(ingredient.get("item", ""))
		var qty_needed: int = int(ingredient.get("qty", 1))
		var qty_have: int = int(materials.get(item_id, 0))
		var material_name: String = str(MATERIALS.get(item_id, {}).get("name", item_id))

		var color: String = "lime" if qty_have >= qty_needed else "red"
		lines.append("  [color=%s]%s: %d/%d[/color]" % [color, material_name, qty_have, qty_needed])

	# Gold cost
	var gold_color: String = "lime" if gold >= gold_cost else "red"
	lines.append("[color=%s]Gold: %d[/color]" % [gold_color, gold_cost])

	# Output
	var output_item: String = str(recipe.get("output_item", ""))
	var output_qty: int = int(recipe.get("output_qty", 1))
	lines.append("[color=orange]Creates: %s x%d[/color]" % [output_item, output_qty])

	return "\n".join(lines)


## Format materials list for display
static func format_materials(profile: Dictionary) -> String:
	var materials: Dictionary = get_materials(profile)
	if materials.is_empty():
		return "[color=gray]No crafting materials[/color]"

	var lines: Array[String] = []
	lines.append("[color=yellow]CRAFTING MATERIALS[/color]")
	lines.append("")

	# Group by tier
	var by_tier: Dictionary = {}
	for mat_id in materials.keys():
		var mat_info: Dictionary = MATERIALS.get(mat_id, {"tier": 1})
		var tier: int = int(mat_info.get("tier", 1))
		if not by_tier.has(tier):
			by_tier[tier] = []
		by_tier[tier].append(mat_id)

	var tier_names: Dictionary = {1: "Common", 2: "Uncommon", 3: "Rare", 4: "Epic"}
	var tier_colors: Dictionary = {1: "white", 2: "green", 3: "cyan", 4: "magenta"}

	for tier in [1, 2, 3, 4]:
		if by_tier.has(tier):
			var tier_name: String = tier_names.get(tier, "Unknown")
			var tier_color: String = tier_colors.get(tier, "white")
			lines.append("[color=%s]%s:[/color]" % [tier_color, tier_name])

			for mat_id in by_tier[tier]:
				var mat_info: Dictionary = MATERIALS.get(mat_id, {})
				var mat_name: String = str(mat_info.get("name", mat_id))
				var qty: int = int(materials[mat_id])
				lines.append("  %s: %d" % [mat_name, qty])

	return "\n".join(lines)


## Format recipe list for display
static func format_recipe_list(profile: Dictionary, category: String = "") -> String:
	var lines: Array[String] = []
	lines.append("[color=yellow]CRAFTING RECIPES[/color]")
	lines.append("")

	var categories: Array[String] = ["consumable", "equipment", "material"]
	if not category.is_empty():
		categories = [category]

	for cat in categories:
		var recipes: Array[String] = get_recipes_by_category(profile, cat)
		if recipes.is_empty():
			continue

		var cat_name: String = cat.capitalize() + "s"
		lines.append("[color=orange]%s:[/color]" % cat_name)

		for recipe_id in recipes:
			var recipe: Dictionary = RECIPES.get(recipe_id, {})
			var name: String = str(recipe.get("name", recipe_id))
			var gold: int = int(recipe.get("gold_cost", 0))
			lines.append("  [color=cyan]%s[/color] - %s (%dg)" % [recipe_id, name, gold])

		lines.append("")

	lines.append("[color=gray]Use 'craft <recipe_id>' to craft[/color]")
	lines.append("[color=gray]Use 'recipe <recipe_id>' for details[/color]")

	return "\n".join(lines)


## Roll material drop from enemy
static func roll_material_drop(day: int, is_boss: bool, is_elite: bool, rng_seed: int) -> String:
	var drop_chance: float = 0.15 + float(day) * 0.01  # 15% base + 1% per day
	if is_boss:
		drop_chance = 0.8  # Bosses almost always drop
	elif is_elite:
		drop_chance = 0.4  # Elites have higher chance

	var roll: float = _seeded_random(rng_seed)
	if roll > drop_chance:
		return ""  # No drop

	# Determine tier based on day and enemy type
	var max_tier: int = 1
	if day >= 5:
		max_tier = 2
	if day >= 12:
		max_tier = 3
	if day >= 20:
		max_tier = 4

	if is_boss:
		max_tier = min(4, max_tier + 1)
	elif is_elite:
		max_tier = min(4, max_tier)

	# Roll for tier (higher tiers are rarer)
	var tier_roll: float = _seeded_random(rng_seed + 1)
	var tier: int = 1
	if tier_roll > 0.9 and max_tier >= 4:
		tier = 4
	elif tier_roll > 0.7 and max_tier >= 3:
		tier = 3
	elif tier_roll > 0.4 and max_tier >= 2:
		tier = 2

	# Get materials of that tier
	var tier_materials: Array[String] = []
	for mat_id in MATERIALS.keys():
		var mat_info: Dictionary = MATERIALS[mat_id]
		if int(mat_info.get("tier", 1)) == tier:
			tier_materials.append(mat_id)

	if tier_materials.is_empty():
		return ""

	# Pick random material from tier
	var mat_roll: float = _seeded_random(rng_seed + 2)
	var mat_index: int = int(mat_roll * float(tier_materials.size())) % tier_materials.size()
	return tier_materials[mat_index]


## Deterministic random
static func _seeded_random(seed_val: int) -> float:
	var a: int = 1103515245
	var c: int = 12345
	var m: int = 2147483648
	var value: int = (a * abs(seed_val) + c) % m
	return float(value) / float(m)
