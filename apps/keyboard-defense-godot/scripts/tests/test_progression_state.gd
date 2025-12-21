extends RefCounted

const TestHelper = preload("res://scripts/tests/test_helper.gd")
const ProgressionState = preload("res://scripts/ProgressionState.gd")

func run() -> Dictionary:
	var helper = TestHelper.new()
	var state = ProgressionState.new()
	state.persistence_enabled = false
	state._load_static_data()
	state.gold = 50
	var upgrades: Array = state.get_kingdom_upgrades()
	helper.assert_true(upgrades.size() > 0, "kingdom upgrades load")
	if upgrades.size() == 0:
		return helper.summary()
	var upgrade: Dictionary = upgrades[0]
	var upgrade_id := str(upgrade.get("id", ""))
	var cost := int(upgrade.get("cost", 0))
	var success = state.apply_upgrade(upgrade_id)
	helper.assert_true(success, "upgrade can be purchased")
	helper.assert_eq(state.gold, 50 - cost, "gold decreases after purchase")
	helper.assert_true(state.is_upgrade_owned(upgrade_id), "upgrade recorded as owned")
	var effects: Dictionary = upgrade.get("effects", {})
	for key in effects.keys():
		if key == "castle_health_bonus":
			var expected = int(effects[key])
			helper.assert_eq(int(state.modifiers.get(key, 0)), expected, "castle health bonus applied")
		else:
			var expected_float = 1.0 + float(effects[key])
			helper.assert_true(abs(float(state.modifiers.get(key, 0.0)) - expected_float) < 0.001, "modifier applied")

	var summary := helper.summary()
	state.free()
	return summary
