extends Node

var next_battle_node_id: String = ""
var last_battle_summary: Dictionary = {}

const SCENE_MENU := "res://scenes/MainMenu.tscn"
const SCENE_MAP := "res://scenes/CampaignMap.tscn"
const SCENE_BATTLE := "res://scenes/Battlefield.tscn"
const SCENE_KINGDOM := "res://scenes/KingdomHub.tscn"
const SCENE_SETTINGS := "res://scenes/SettingsMenu.tscn"

func go_to_menu() -> void:
	get_tree().change_scene_to_file(SCENE_MENU)

func go_to_map() -> void:
	get_tree().change_scene_to_file(SCENE_MAP)

func go_to_battle(node_id: String) -> void:
	next_battle_node_id = node_id
	last_battle_summary = {}
	get_tree().change_scene_to_file(SCENE_BATTLE)

func go_to_kingdom() -> void:
	get_tree().change_scene_to_file(SCENE_KINGDOM)

func go_to_settings() -> void:
	get_tree().change_scene_to_file(SCENE_SETTINGS)
