class_name SimSkills
extends RefCounted
## Player skill tree system - passive and active abilities

# Skill tree IDs
const TREE_SPEED := "speed"
const TREE_ACCURACY := "accuracy"
const TREE_DEFENSE := "defense"

# Skill data structure
const SKILL_TREES: Dictionary = {
	"speed": {
		"name": "Way of the Swift",
		"description": "Master the art of rapid typing",
		"icon": "lightning",
		"skills": {
			"swift_start": {
				"name": "Quick Start",
				"tier": 1,
				"cost": 1,
				"max_ranks": 3,
				"effect": "+2 WPM per rank",
				"effect_type": "wpm_bonus",
				"effect_value": 2,
				"prerequisites": []
			},
			"momentum": {
				"name": "Momentum",
				"tier": 1,
				"cost": 1,
				"max_ranks": 3,
				"effect": "Combo grants +1% damage per rank",
				"effect_type": "combo_damage_bonus",
				"effect_value": 0.01,
				"prerequisites": []
			},
			"burst_typing": {
				"name": "Burst Typing",
				"tier": 2,
				"cost": 2,
				"max_ranks": 2,
				"effect": "First 3 words deal +20% damage per rank",
				"effect_type": "burst_damage",
				"effect_value": 0.2,
				"prerequisites": ["swift_start"]
			},
			"chain_killer": {
				"name": "Chain Killer",
				"tier": 2,
				"cost": 2,
				"max_ranks": 2,
				"effect": "+10% damage for kills within 2s per rank",
				"effect_type": "chain_damage",
				"effect_value": 0.1,
				"prerequisites": ["momentum"]
			},
			"overdrive": {
				"name": "Overdrive",
				"tier": 3,
				"cost": 3,
				"max_ranks": 1,
				"effect": "Active: +50% damage for 10s, 60s cooldown",
				"effect_type": "active_damage_boost",
				"effect_value": 0.5,
				"duration": 10.0,
				"cooldown": 60.0,
				"prerequisites": ["burst_typing", "chain_killer"]
			},
			"speed_demon": {
				"name": "Speed Demon",
				"tier": 4,
				"cost": 5,
				"max_ranks": 1,
				"effect": "Passive: +15% damage, -5% accuracy tolerance",
				"effect_type": "speed_demon",
				"effect_value": 0.15,
				"prerequisites": ["overdrive"]
			}
		}
	},
	"accuracy": {
		"name": "Way of Precision",
		"description": "Master the art of perfect typing",
		"icon": "crosshair",
		"skills": {
			"steady_hands": {
				"name": "Steady Hands",
				"tier": 1,
				"cost": 1,
				"max_ranks": 3,
				"effect": "+5% crit chance per rank",
				"effect_type": "crit_chance",
				"effect_value": 0.05,
				"prerequisites": []
			},
			"focus": {
				"name": "Focus",
				"tier": 1,
				"cost": 1,
				"max_ranks": 3,
				"effect": "Mistake penalty reduced 10% per rank",
				"effect_type": "mistake_reduction",
				"effect_value": 0.1,
				"prerequisites": []
			},
			"critical_strike": {
				"name": "Critical Strike",
				"tier": 2,
				"cost": 2,
				"max_ranks": 2,
				"effect": "Crit damage +50% per rank",
				"effect_type": "crit_damage",
				"effect_value": 0.5,
				"prerequisites": ["steady_hands"]
			},
			"recovery": {
				"name": "Quick Recovery",
				"tier": 2,
				"cost": 2,
				"max_ranks": 2,
				"effect": "Mistakes don't break combo (once per 8s, -2s per rank)",
				"effect_type": "combo_protection",
				"effect_value": 2.0,
				"base_cooldown": 8.0,
				"prerequisites": ["focus"]
			},
			"perfect_form": {
				"name": "Perfect Form",
				"tier": 3,
				"cost": 3,
				"max_ranks": 1,
				"effect": "Active: 100% crit chance for 8s, 90s cooldown",
				"effect_type": "active_crit",
				"effect_value": 1.0,
				"duration": 8.0,
				"cooldown": 90.0,
				"prerequisites": ["critical_strike", "recovery"]
			},
			"precision_master": {
				"name": "Precision Master",
				"tier": 4,
				"cost": 5,
				"max_ranks": 1,
				"effect": "Passive: Perfect combos (10+) deal +50% damage",
				"effect_type": "perfect_combo_damage",
				"effect_value": 0.5,
				"prerequisites": ["perfect_form"]
			}
		}
	},
	"defense": {
		"name": "Way of the Guardian",
		"description": "Master the art of survival",
		"icon": "shield",
		"skills": {
			"fortify": {
				"name": "Fortify",
				"tier": 1,
				"cost": 1,
				"max_ranks": 3,
				"effect": "Castle takes 5% less damage per rank",
				"effect_type": "damage_reduction",
				"effect_value": 0.05,
				"prerequisites": []
			},
			"regeneration": {
				"name": "Regeneration",
				"tier": 1,
				"cost": 1,
				"max_ranks": 3,
				"effect": "Castle heals 1 HP per wave per rank",
				"effect_type": "wave_heal",
				"effect_value": 1,
				"prerequisites": []
			},
			"thick_walls": {
				"name": "Thick Walls",
				"tier": 2,
				"cost": 2,
				"max_ranks": 2,
				"effect": "+10% gold from kills per rank",
				"effect_type": "gold_bonus",
				"effect_value": 0.1,
				"prerequisites": ["fortify"]
			},
			"slowing_aura": {
				"name": "Slowing Aura",
				"tier": 2,
				"cost": 2,
				"max_ranks": 2,
				"effect": "Enemies near castle slowed 10% per rank",
				"effect_type": "castle_slow_aura",
				"effect_value": 0.1,
				"prerequisites": ["regeneration"]
			},
			"last_stand": {
				"name": "Last Stand",
				"tier": 3,
				"cost": 3,
				"max_ranks": 1,
				"effect": "Active: Block all damage for 5s, 120s cooldown",
				"effect_type": "active_shield",
				"effect_value": 1.0,
				"duration": 5.0,
				"cooldown": 120.0,
				"prerequisites": ["thick_walls", "slowing_aura"]
			},
			"guardian_spirit": {
				"name": "Guardian Spirit",
				"tier": 4,
				"cost": 5,
				"max_ranks": 1,
				"effect": "Passive: Survive one lethal hit per battle (1 HP)",
				"effect_type": "death_prevention",
				"effect_value": 1,
				"prerequisites": ["last_stand"]
			}
		}
	}
}


## Get all skill trees
static func get_all_trees() -> Array[String]:
	var trees: Array[String] = []
	for key in SKILL_TREES.keys():
		trees.append(str(key))
	return trees


## Get tree data
static func get_tree(tree_id: String) -> Dictionary:
	return SKILL_TREES.get(tree_id, {})


## Get tree name
static func get_tree_name(tree_id: String) -> String:
	var tree: Dictionary = get_tree(tree_id)
	return str(tree.get("name", tree_id.capitalize()))


## Get all skills in a tree
static func get_tree_skills(tree_id: String) -> Dictionary:
	var tree: Dictionary = get_tree(tree_id)
	return tree.get("skills", {})


## Get specific skill data
static func get_skill(tree_id: String, skill_id: String) -> Dictionary:
	var skills: Dictionary = get_tree_skills(tree_id)
	return skills.get(skill_id, {})


## Get skill name
static func get_skill_name(tree_id: String, skill_id: String) -> String:
	var skill: Dictionary = get_skill(tree_id, skill_id)
	return str(skill.get("name", skill_id.capitalize()))


## Get skill cost
static func get_skill_cost(tree_id: String, skill_id: String) -> int:
	var skill: Dictionary = get_skill(tree_id, skill_id)
	return int(skill.get("cost", 1))


## Get skill max ranks
static func get_skill_max_ranks(tree_id: String, skill_id: String) -> int:
	var skill: Dictionary = get_skill(tree_id, skill_id)
	return int(skill.get("max_ranks", 1))


## Get skill prerequisites
static func get_skill_prerequisites(tree_id: String, skill_id: String) -> Array[String]:
	var skill: Dictionary = get_skill(tree_id, skill_id)
	var prereqs: Array[String] = []
	for p in skill.get("prerequisites", []):
		prereqs.append(str(p))
	return prereqs


## Check if skill is active (has cooldown)
static func is_active_skill(tree_id: String, skill_id: String) -> bool:
	var skill: Dictionary = get_skill(tree_id, skill_id)
	return skill.has("cooldown")


## Check if player can learn skill (prerequisites met)
static func can_learn_skill(tree_id: String, skill_id: String, learned_skills: Dictionary) -> bool:
	var prereqs: Array[String] = get_skill_prerequisites(tree_id, skill_id)
	for prereq_id in prereqs:
		var key: String = "%s:%s" % [tree_id, prereq_id]
		if not learned_skills.has(key) or int(learned_skills.get(key, 0)) <= 0:
			return false
	return true


## Get player's rank in a skill
static func get_skill_rank(tree_id: String, skill_id: String, learned_skills: Dictionary) -> int:
	var key: String = "%s:%s" % [tree_id, skill_id]
	return int(learned_skills.get(key, 0))


## Learn/upgrade a skill (returns new learned_skills dict)
static func learn_skill(tree_id: String, skill_id: String, learned_skills: Dictionary) -> Dictionary:
	var result: Dictionary = learned_skills.duplicate()
	var key: String = "%s:%s" % [tree_id, skill_id]
	var current_rank: int = int(result.get(key, 0))
	var max_ranks: int = get_skill_max_ranks(tree_id, skill_id)

	if current_rank < max_ranks:
		result[key] = current_rank + 1

	return result


## Calculate total skill points spent
static func get_total_points_spent(learned_skills: Dictionary) -> int:
	var total: int = 0
	for key in learned_skills.keys():
		var parts: PackedStringArray = str(key).split(":")
		if parts.size() == 2:
			var tree_id: String = parts[0]
			var skill_id: String = parts[1]
			var ranks: int = int(learned_skills.get(key, 0))
			var cost_per_rank: int = get_skill_cost(tree_id, skill_id)
			total += ranks * cost_per_rank
	return total


## Calculate skill effect value (multiplied by ranks)
static func get_effect_value(tree_id: String, skill_id: String, learned_skills: Dictionary) -> float:
	var skill: Dictionary = get_skill(tree_id, skill_id)
	var ranks: int = get_skill_rank(tree_id, skill_id, learned_skills)
	if ranks <= 0:
		return 0.0
	var base_value: float = float(skill.get("effect_value", 0))
	return base_value * float(ranks)


## Get total bonus from a specific effect type across all skills
static func get_total_effect(effect_type: String, learned_skills: Dictionary) -> float:
	var total: float = 0.0
	for tree_id in SKILL_TREES.keys():
		var skills: Dictionary = get_tree_skills(str(tree_id))
		for skill_id in skills.keys():
			var skill: Dictionary = skills[skill_id]
			if str(skill.get("effect_type", "")) == effect_type:
				var ranks: int = get_skill_rank(str(tree_id), str(skill_id), learned_skills)
				if ranks > 0:
					total += float(skill.get("effect_value", 0)) * float(ranks)
	return total


## Get WPM bonus from skills
static func get_wpm_bonus(learned_skills: Dictionary) -> int:
	return int(get_total_effect("wpm_bonus", learned_skills))


## Get crit chance bonus from skills
static func get_crit_chance_bonus(learned_skills: Dictionary) -> float:
	return get_total_effect("crit_chance", learned_skills)


## Get crit damage bonus from skills
static func get_crit_damage_bonus(learned_skills: Dictionary) -> float:
	return get_total_effect("crit_damage", learned_skills)


## Get damage reduction from skills
static func get_damage_reduction(learned_skills: Dictionary) -> float:
	return get_total_effect("damage_reduction", learned_skills)


## Get gold bonus from skills
static func get_gold_bonus(learned_skills: Dictionary) -> float:
	return get_total_effect("gold_bonus", learned_skills)


## Get wave heal from skills
static func get_wave_heal(learned_skills: Dictionary) -> int:
	return int(get_total_effect("wave_heal", learned_skills))


## Get combo damage bonus (per combo count)
static func get_combo_damage_bonus(learned_skills: Dictionary, combo: int) -> float:
	var per_combo: float = get_total_effect("combo_damage_bonus", learned_skills)
	return per_combo * float(combo)


## Check if player has perfect combo damage bonus active
static func has_perfect_combo_bonus(learned_skills: Dictionary, combo: int) -> bool:
	var bonus: float = get_total_effect("perfect_combo_damage", learned_skills)
	return bonus > 0 and combo >= 10


## Get perfect combo damage bonus
static func get_perfect_combo_damage(learned_skills: Dictionary) -> float:
	return get_total_effect("perfect_combo_damage", learned_skills)


## Check if player has death prevention skill
static func has_death_prevention(learned_skills: Dictionary) -> bool:
	return get_total_effect("death_prevention", learned_skills) > 0


## Get mistake reduction percentage
static func get_mistake_reduction(learned_skills: Dictionary) -> float:
	return get_total_effect("mistake_reduction", learned_skills)


## Get burst damage bonus (for first N words)
static func get_burst_damage_bonus(learned_skills: Dictionary, words_typed_this_wave: int) -> float:
	if words_typed_this_wave > 3:
		return 0.0
	return get_total_effect("burst_damage", learned_skills)


## Get chain damage bonus (for kills within time window)
static func get_chain_damage_bonus(learned_skills: Dictionary) -> float:
	return get_total_effect("chain_damage", learned_skills)


## Get castle slow aura percentage
static func get_castle_slow_aura(learned_skills: Dictionary) -> float:
	return get_total_effect("castle_slow_aura", learned_skills)


## Get combo protection cooldown (0 if not learned)
static func get_combo_protection_cooldown(learned_skills: Dictionary) -> float:
	var base_cooldown: float = 8.0
	var reduction: float = get_total_effect("combo_protection", learned_skills)
	if reduction <= 0:
		return 0.0  # Not learned
	return max(2.0, base_cooldown - reduction)


## Get active skill info if learned
static func get_active_skill_info(tree_id: String, skill_id: String, learned_skills: Dictionary) -> Dictionary:
	var ranks: int = get_skill_rank(tree_id, skill_id, learned_skills)
	if ranks <= 0:
		return {}

	var skill: Dictionary = get_skill(tree_id, skill_id)
	if not skill.has("cooldown"):
		return {}

	return {
		"name": str(skill.get("name", "")),
		"effect_type": str(skill.get("effect_type", "")),
		"effect_value": float(skill.get("effect_value", 0)),
		"duration": float(skill.get("duration", 0)),
		"cooldown": float(skill.get("cooldown", 0))
	}


## Get all learned active skills
static func get_learned_active_skills(learned_skills: Dictionary) -> Array[Dictionary]:
	var actives: Array[Dictionary] = []
	for tree_id in SKILL_TREES.keys():
		var skills: Dictionary = get_tree_skills(str(tree_id))
		for skill_id in skills.keys():
			var info: Dictionary = get_active_skill_info(str(tree_id), str(skill_id), learned_skills)
			if not info.is_empty():
				info["tree_id"] = str(tree_id)
				info["skill_id"] = str(skill_id)
				actives.append(info)
	return actives


## Format skill for display
static func format_skill_display(tree_id: String, skill_id: String, learned_skills: Dictionary) -> String:
	var skill: Dictionary = get_skill(tree_id, skill_id)
	var name: String = str(skill.get("name", skill_id))
	var ranks: int = get_skill_rank(tree_id, skill_id, learned_skills)
	var max_ranks: int = int(skill.get("max_ranks", 1))
	var effect: String = str(skill.get("effect", ""))

	if ranks > 0:
		return "[color=lime]%s[/color] (%d/%d) - %s" % [name, ranks, max_ranks, effect]
	else:
		return "[color=gray]%s[/color] (0/%d) - %s" % [name, max_ranks, effect]


## Serialize learned skills for save
static func serialize(learned_skills: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in learned_skills.keys():
		result[str(key)] = int(learned_skills.get(key, 0))
	return result


## Deserialize learned skills from save
static func deserialize(data: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in data.keys():
		result[str(key)] = int(data.get(key, 0))
	return result
