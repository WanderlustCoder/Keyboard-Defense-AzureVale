extends RefCounted

const TestHelper = preload("res://scripts/tests/test_helper.gd")

const SCENES := [
	"res://scenes/MainMenu.tscn",
	"res://scenes/CampaignMap.tscn",
	"res://scenes/Battlefield.tscn",
	"res://scenes/KingdomHub.tscn"
]

func run() -> Dictionary:
	var helper = TestHelper.new()
	for path in SCENES:
		var packed = load(path)
		helper.assert_true(packed != null, "scene loads: %s" % path)
		if packed == null:
			continue
		var instance = packed.instantiate()
		helper.assert_true(instance != null, "scene instantiates: %s" % path)
		if instance:
			instance.free()
	return helper.summary()
