# Save System Architecture

**Created:** 2026-01-08

Complete specification for game save/load system, data persistence, and cloud sync.

---

## System Overview

### Save Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   SAVE SYSTEM LAYERS                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              APPLICATION LAYER                       │   │
│  │  Save/Load requests, auto-save triggers             │   │
│  └──────────────────────┬──────────────────────────────┘   │
│                         │                                   │
│  ┌──────────────────────▼──────────────────────────────┐   │
│  │              SERIALIZATION LAYER                     │   │
│  │  Object → Dictionary → JSON conversion              │   │
│  └──────────────────────┬──────────────────────────────┘   │
│                         │                                   │
│  ┌──────────────────────▼──────────────────────────────┐   │
│  │              ENCRYPTION LAYER (Optional)             │   │
│  │  AES encryption for save data                       │   │
│  └──────────────────────┬──────────────────────────────┘   │
│                         │                                   │
│  ┌──────────────────────▼──────────────────────────────┐   │
│  │              STORAGE LAYER                           │   │
│  │  Local files, cloud sync                            │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Save Data Structure

### Root Save Object

```json
{
  "save_version": "1.0.0",
  "game_version": "1.0.0",
  "created_at": "2026-01-08T12:00:00Z",
  "modified_at": "2026-01-08T15:30:00Z",
  "playtime_seconds": 12345,
  "checksum": "abc123...",

  "player": { },
  "progress": { },
  "world": { },
  "inventory": { },
  "settings": { },
  "statistics": { },
  "achievements": { }
}
```

### Player Data

```json
{
  "player": {
    "name": "TypeMaster",
    "level": 25,
    "xp": 15000,
    "xp_to_next": 4472,
    "prestige_level": 1,
    "prestige_points": 5,

    "stats": {
      "precision": 8,
      "velocity": 6,
      "fortitude": 4,
      "fortune": 2,
      "wisdom": 5,
      "unallocated": 3
    },

    "skills": {
      "speed": {
        "swift_start": 2,
        "momentum": 3,
        "burst_typing": 1,
        "chain_killer": 0,
        "overdrive": 0,
        "speed_demon": 0
      },
      "accuracy": { },
      "defense": { },
      "towers": { },
      "utility": { },
      "mastery": { }
    },

    "prestige_upgrades": {
      "prestige_xp": 2,
      "prestige_gold": 1,
      "prestige_start": 0
    },

    "equipped": {
      "headgear": "helm_speed",
      "armor": "armor_scribe",
      "gloves": "gloves_precision",
      "boots": "boots_swamp",
      "amulet": null,
      "ring": null,
      "belt": "belt_fortune",
      "cape": null
    },

    "active_keyboard_skin": "skin_forest",
    "active_title": "Grove Protector"
  }
}
```

### Progress Data

```json
{
  "progress": {
    "current_day": 15,
    "current_region": "evergrove",
    "current_zone": "whisper_grove",

    "story": {
      "current_quest": "mq_06_sunlit_path",
      "completed_quests": ["mq_01", "mq_02", "mq_03", "mq_04", "mq_05"],
      "quest_states": {
        "mq_06_sunlit_path": {
          "objectives": {
            "obj_01": true,
            "obj_02": false,
            "obj_03": false
          }
        }
      }
    },

    "side_quests": {
      "active": ["sq_treasure_hunt", "rc_ev_02"],
      "completed": ["rc_ev_01"],
      "states": {
        "sq_treasure_hunt": {
          "pois_found": 2,
          "pois_required": 3
        }
      }
    },

    "lessons": {
      "home_row_1": {
        "completed": true,
        "stars": 5,
        "best_accuracy": 0.98,
        "best_wpm": 52,
        "attempts": 12
      },
      "home_row_2": {
        "completed": true,
        "stars": 4,
        "best_accuracy": 0.95,
        "best_wpm": 48,
        "attempts": 8
      }
    },

    "mastery_badges": ["home_row_master"],

    "bosses_defeated": ["boss_grove_guardian"],

    "reputation": {
      "evergrove": 650,
      "sunfields": 200,
      "stonepass": 50,
      "mistfen": 0,
      "citadel": 100
    }
  }
}
```

### World Data

```json
{
  "world": {
    "discovered_regions": ["evergrove", "sunfields"],
    "discovered_zones": {
      "evergrove": ["forest_entrance", "whisper_grove", "ancient_oak"],
      "sunfields": ["plains_gate"]
    },

    "poi_states": {
      "evergrove_wagon_01": {
        "discovered": true,
        "visited": true,
        "completed": true,
        "last_event": "wagon_supplies",
        "respawn_day": null
      },
      "evergrove_shrine_01": {
        "discovered": true,
        "visited": true,
        "completed": false,
        "last_event": "spirit_blessing",
        "respawn_day": 18
      }
    },

    "npc_relationships": {
      "npc_lyra": {
        "affinity": 4,
        "dialogue_seen": ["greeting_first", "lesson_intro_home_row"]
      },
      "npc_thorne": {
        "affinity": 3,
        "quests_completed": 2
      }
    },

    "unlocked_fast_travel": ["castle_keystonia", "evergrove_entrance"],

    "current_weather": "clear",
    "weather_change_day": 16,

    "current_time": 14.5,

    "seasonal_event": null
  }
}
```

### Inventory Data

```json
{
  "inventory": {
    "gold": 1234,
    "word_tokens": 50,

    "equipment": [
      {"id": "helm_speed", "slot": "headgear", "equipped": true},
      {"id": "armor_scribe", "slot": "armor", "equipped": true},
      {"id": "boots_basic", "slot": "boots", "equipped": false},
      {"id": "gloves_swift", "slot": "gloves", "equipped": false}
    ],

    "consumables": [
      {"id": "potion_health_small", "count": 5},
      {"id": "potion_speed", "count": 2},
      {"id": "scroll_reveal", "count": 1}
    ],

    "materials": [
      {"id": "herbs", "count": 15},
      {"id": "crystal_shard", "count": 3},
      {"id": "cloth", "count": 8}
    ],

    "quest_items": [
      {"id": "grove_seal", "count": 1},
      {"id": "ancient_key_fragment", "count": 2}
    ],

    "keyboard_skins_unlocked": ["skin_default", "skin_forest"],
    "titles_unlocked": ["novice_typist", "defender", "grove_protector"],

    "capacity": {
      "equipment": 24,
      "consumables": 30,
      "materials": 40
    }
  }
}
```

### Statistics Data

```json
{
  "statistics": {
    "typing": {
      "total_words_typed": 15234,
      "total_characters_typed": 89421,
      "total_mistakes": 892,
      "overall_accuracy": 0.943,
      "best_wpm_ever": 67,
      "average_wpm": 42,
      "total_typing_time_seconds": 28800,
      "longest_combo": 87,
      "perfect_words": 12456
    },

    "combat": {
      "enemies_defeated": 5234,
      "enemies_by_tier": {
        "T1": 3500,
        "T2": 1200,
        "T3": 400,
        "T4": 100,
        "T5": 34
      },
      "bosses_defeated": 5,
      "waves_completed": 423,
      "perfect_waves": 89,
      "castle_hp_lost": 2340,
      "deaths": 12
    },

    "exploration": {
      "pois_discovered": 45,
      "pois_completed": 38,
      "zones_explored": 12,
      "distance_traveled": 15000
    },

    "economy": {
      "gold_earned": 45000,
      "gold_spent": 38000,
      "items_bought": 234,
      "items_sold": 156,
      "items_crafted": 45
    },

    "lessons": {
      "lessons_completed": 18,
      "lessons_mastered": 8,
      "total_stars": 72,
      "lesson_attempts": 156
    },

    "time": {
      "play_sessions": 45,
      "total_playtime_seconds": 86400,
      "longest_session_seconds": 7200,
      "days_played": 23
    }
  }
}
```

### Achievements Data

```json
{
  "achievements": {
    "unlocked": [
      {
        "id": "first_blood",
        "unlocked_at": "2026-01-01T10:30:00Z"
      },
      {
        "id": "century",
        "unlocked_at": "2026-01-03T14:20:00Z"
      }
    ],

    "progress": {
      "thousand": {
        "current": 523,
        "target": 1000
      },
      "speed_50": {
        "current": 47,
        "target": 50
      }
    },

    "hidden_discovered": ["secret_shrine"]
  }
}
```

### Settings Data

```json
{
  "settings": {
    "audio": {
      "master_volume": 0.8,
      "music_volume": 0.65,
      "sfx_volume": 1.0,
      "ui_volume": 0.4,
      "typing_volume": 0.75,
      "mute_unfocused": true
    },

    "display": {
      "fullscreen": true,
      "resolution": "1920x1080",
      "vsync": true,
      "ui_scale": 100,
      "show_fps": false
    },

    "accessibility": {
      "high_contrast": false,
      "large_text": false,
      "color_blind_mode": "none",
      "reduce_motion": false,
      "screen_shake": true
    },

    "gameplay": {
      "auto_target": true,
      "show_keyboard": true,
      "show_finger_hints": true,
      "pause_on_focus_loss": true,
      "confirm_quit": true
    },

    "keyboard": {
      "layout": "qwerty",
      "custom_bindings": {}
    }
  }
}
```

---

## Save File Management

### File Structure

```
user://saves/
├── profile_1/
│   ├── save_auto.json
│   ├── save_slot_1.json
│   ├── save_slot_2.json
│   ├── save_slot_3.json
│   └── backup/
│       ├── save_auto_20260108_120000.json
│       └── save_auto_20260107_180000.json
├── profile_2/
│   └── ...
├── settings.json (global)
└── cloud_sync_state.json
```

### Save Slots

| Slot | Type | Description |
|------|------|-------------|
| Auto | Automatic | Saves on events |
| Slot 1-3 | Manual | Player-triggered |
| Quick | Manual | F5 shortcut |
| Backup | Automatic | Rolling backups |

### Auto-Save Triggers

```json
{
  "auto_save_triggers": [
    "wave_complete",
    "quest_complete",
    "lesson_complete",
    "boss_defeated",
    "level_up",
    "item_obtained_rare",
    "zone_entered",
    "shop_transaction",
    "periodic_5_minutes"
  ]
}
```

---

## Save/Load API

### Core Functions

```gdscript
# save_manager.gd

class_name SaveManager
extends Node

signal save_started
signal save_completed(success: bool)
signal load_started
signal load_completed(success: bool)
signal save_corrupted(slot: String)

const SAVE_VERSION := "1.0.0"
const SAVE_DIR := "user://saves/"
const MAX_BACKUPS := 5

var current_profile: String = "profile_1"
var auto_save_enabled: bool = true
var encryption_enabled: bool = true

# Save game state to specified slot
func save_game(slot: String = "auto") -> bool:
    emit_signal("save_started")

    var save_data := _collect_save_data()
    save_data["checksum"] = _calculate_checksum(save_data)

    var json_string := JSON.stringify(save_data, "\t")

    if encryption_enabled:
        json_string = _encrypt(json_string)

    var path := _get_save_path(slot)
    var success := _write_file(path, json_string)

    if success and slot == "auto":
        _rotate_backups()

    emit_signal("save_completed", success)
    return success

# Load game state from specified slot
func load_game(slot: String = "auto") -> bool:
    emit_signal("load_started")

    var path := _get_save_path(slot)
    var json_string := _read_file(path)

    if json_string.is_empty():
        emit_signal("load_completed", false)
        return false

    if encryption_enabled:
        json_string = _decrypt(json_string)

    var save_data = JSON.parse_string(json_string)

    if not _validate_save(save_data):
        emit_signal("save_corrupted", slot)
        return _attempt_backup_recovery(slot)

    _apply_save_data(save_data)

    emit_signal("load_completed", true)
    return true

# Delete a save slot
func delete_save(slot: String) -> bool:
    var path := _get_save_path(slot)
    return DirAccess.remove_absolute(path) == OK

# Get metadata for all save slots
func get_save_slots() -> Array[Dictionary]:
    var slots: Array[Dictionary] = []

    for slot in ["auto", "slot_1", "slot_2", "slot_3"]:
        var path := _get_save_path(slot)
        if FileAccess.file_exists(path):
            var meta := _read_save_metadata(path)
            meta["slot"] = slot
            slots.append(meta)

    return slots
```

### Data Collection

```gdscript
func _collect_save_data() -> Dictionary:
    return {
        "save_version": SAVE_VERSION,
        "game_version": ProjectSettings.get_setting("application/config/version"),
        "created_at": _get_existing_created_at(),
        "modified_at": Time.get_datetime_string_from_system(true),
        "playtime_seconds": GameState.total_playtime,

        "player": _collect_player_data(),
        "progress": _collect_progress_data(),
        "world": _collect_world_data(),
        "inventory": _collect_inventory_data(),
        "settings": _collect_settings_data(),
        "statistics": _collect_statistics_data(),
        "achievements": _collect_achievements_data()
    }

func _collect_player_data() -> Dictionary:
    var player := GameState.player
    return {
        "name": player.name,
        "level": player.level,
        "xp": player.xp,
        "xp_to_next": player.xp_to_next_level(),
        "prestige_level": player.prestige_level,
        "prestige_points": player.prestige_points,
        "stats": player.stats.duplicate(),
        "skills": player.skills.duplicate(true),
        "prestige_upgrades": player.prestige_upgrades.duplicate(),
        "equipped": player.equipped.duplicate(),
        "active_keyboard_skin": player.keyboard_skin,
        "active_title": player.title
    }
```

### Data Application

```gdscript
func _apply_save_data(data: Dictionary) -> void:
    # Version migration if needed
    data = _migrate_save_version(data)

    _apply_player_data(data.get("player", {}))
    _apply_progress_data(data.get("progress", {}))
    _apply_world_data(data.get("world", {}))
    _apply_inventory_data(data.get("inventory", {}))
    _apply_settings_data(data.get("settings", {}))
    _apply_statistics_data(data.get("statistics", {}))
    _apply_achievements_data(data.get("achievements", {}))

    GameState.total_playtime = data.get("playtime_seconds", 0)

func _apply_player_data(data: Dictionary) -> void:
    if data.is_empty():
        return

    var player := GameState.player
    player.name = data.get("name", "Player")
    player.level = data.get("level", 1)
    player.xp = data.get("xp", 0)
    player.prestige_level = data.get("prestige_level", 0)
    player.prestige_points = data.get("prestige_points", 0)

    player.stats = data.get("stats", _default_stats())
    player.skills = data.get("skills", _default_skills())
    player.prestige_upgrades = data.get("prestige_upgrades", {})
    player.equipped = data.get("equipped", {})
    player.keyboard_skin = data.get("active_keyboard_skin", "skin_default")
    player.title = data.get("active_title", "novice_typist")

    player.recalculate_stats()
```

---

## Version Migration

### Migration System

```gdscript
func _migrate_save_version(data: Dictionary) -> Dictionary:
    var version := data.get("save_version", "0.0.0")

    # Apply migrations in order
    if _version_less_than(version, "1.0.0"):
        data = _migrate_to_1_0_0(data)

    if _version_less_than(version, "1.1.0"):
        data = _migrate_to_1_1_0(data)

    # Update version after migration
    data["save_version"] = SAVE_VERSION

    return data

func _migrate_to_1_0_0(data: Dictionary) -> Dictionary:
    # Example migration: Add new field with default
    if not data.has("statistics"):
        data["statistics"] = _default_statistics()

    # Example migration: Rename field
    if data.has("player") and data["player"].has("gold"):
        if not data.has("inventory"):
            data["inventory"] = {}
        data["inventory"]["gold"] = data["player"]["gold"]
        data["player"].erase("gold")

    return data
```

### Version Compatibility

| Save Version | Game Versions | Notes |
|--------------|---------------|-------|
| 1.0.0 | 1.0.0 - 1.0.x | Initial release |
| 1.1.0 | 1.1.0 - 1.1.x | Added prestige system |
| 1.2.0 | 1.2.0+ | Added cloud sync |

---

## Validation & Security

### Checksum Validation

```gdscript
func _calculate_checksum(data: Dictionary) -> String:
    var data_copy := data.duplicate(true)
    data_copy.erase("checksum")

    var json := JSON.stringify(data_copy)
    var ctx := HashingContext.new()
    ctx.start(HashingContext.HASH_SHA256)
    ctx.update(json.to_utf8_buffer())

    return ctx.finish().hex_encode()

func _validate_checksum(data: Dictionary) -> bool:
    var stored := data.get("checksum", "")
    var calculated := _calculate_checksum(data)
    return stored == calculated
```

### Encryption

```gdscript
const ENCRYPTION_KEY := "your-secret-key-here"

func _encrypt(text: String) -> String:
    var aes := AESContext.new()
    aes.start(AESContext.MODE_CBC_ENCRYPT, ENCRYPTION_KEY.to_utf8_buffer())

    var data := text.to_utf8_buffer()
    var encrypted := aes.update(data)
    encrypted.append_array(aes.finish())

    return Marshalls.raw_to_base64(encrypted)

func _decrypt(text: String) -> String:
    var aes := AESContext.new()
    aes.start(AESContext.MODE_CBC_DECRYPT, ENCRYPTION_KEY.to_utf8_buffer())

    var encrypted := Marshalls.base64_to_raw(text)
    var decrypted := aes.update(encrypted)
    decrypted.append_array(aes.finish())

    return decrypted.get_string_from_utf8()
```

### Data Validation

```gdscript
func _validate_save(data: Dictionary) -> bool:
    # Check required fields
    var required := ["save_version", "player", "progress", "world"]
    for field in required:
        if not data.has(field):
            push_error("Missing required field: " + field)
            return false

    # Validate checksum
    if not _validate_checksum(data):
        push_error("Checksum validation failed")
        return false

    # Validate version compatibility
    if not _is_version_compatible(data.get("save_version", "")):
        push_error("Incompatible save version")
        return false

    # Validate data ranges
    if not _validate_data_ranges(data):
        push_error("Data range validation failed")
        return false

    return true

func _validate_data_ranges(data: Dictionary) -> bool:
    var player := data.get("player", {})

    # Level must be positive
    if player.get("level", 1) < 1:
        return false

    # XP cannot be negative
    if player.get("xp", 0) < 0:
        return false

    # Stats must be non-negative
    var stats := player.get("stats", {})
    for stat in stats.values():
        if stat < 0:
            return false

    return true
```

---

## Backup & Recovery

### Backup Rotation

```gdscript
func _rotate_backups() -> void:
    var backup_dir := SAVE_DIR + current_profile + "/backup/"
    DirAccess.make_dir_recursive_absolute(backup_dir)

    # Create new backup
    var timestamp := Time.get_datetime_string_from_system().replace(":", "")
    var backup_name := "save_auto_" + timestamp + ".json"
    var source := _get_save_path("auto")
    var dest := backup_dir + backup_name

    DirAccess.copy_absolute(source, dest)

    # Remove old backups
    var backups := _get_sorted_backups()
    while backups.size() > MAX_BACKUPS:
        DirAccess.remove_absolute(backups.pop_front())

func _get_sorted_backups() -> Array[String]:
    var backup_dir := SAVE_DIR + current_profile + "/backup/"
    var dir := DirAccess.open(backup_dir)
    var backups: Array[String] = []

    dir.list_dir_begin()
    var file := dir.get_next()
    while file != "":
        if file.ends_with(".json"):
            backups.append(backup_dir + file)
        file = dir.get_next()
    dir.list_dir_end()

    backups.sort()
    return backups
```

### Recovery System

```gdscript
func _attempt_backup_recovery(slot: String) -> bool:
    var backups := _get_sorted_backups()
    backups.reverse()  # Newest first

    for backup_path in backups:
        push_warning("Attempting recovery from: " + backup_path)

        var json_string := _read_file(backup_path)
        if encryption_enabled:
            json_string = _decrypt(json_string)

        var save_data = JSON.parse_string(json_string)

        if _validate_save(save_data):
            _apply_save_data(save_data)
            push_warning("Recovery successful from: " + backup_path)

            # Copy recovered save to main slot
            save_game(slot)

            emit_signal("load_completed", true)
            return true

    push_error("All backup recovery attempts failed")
    emit_signal("load_completed", false)
    return false
```

---

## Cloud Sync

### Cloud Sync Architecture

```json
{
  "cloud_sync": {
    "provider": "steam_cloud",
    "sync_interval": 300,
    "conflict_resolution": "newest_wins",
    "sync_on_events": ["save_completed", "game_quit"],
    "files_to_sync": ["save_auto.json", "settings.json"]
  }
}
```

### Conflict Resolution

```gdscript
enum ConflictResolution {
    NEWEST_WINS,
    LOCAL_WINS,
    CLOUD_WINS,
    ASK_USER
}

func _resolve_sync_conflict(local: Dictionary, cloud: Dictionary) -> Dictionary:
    match Settings.cloud_conflict_resolution:
        ConflictResolution.NEWEST_WINS:
            var local_time := Time.get_unix_time_from_datetime_string(local["modified_at"])
            var cloud_time := Time.get_unix_time_from_datetime_string(cloud["modified_at"])
            return cloud if cloud_time > local_time else local

        ConflictResolution.LOCAL_WINS:
            return local

        ConflictResolution.CLOUD_WINS:
            return cloud

        ConflictResolution.ASK_USER:
            return await _show_conflict_dialog(local, cloud)

    return local
```

---

## Implementation Checklist

- [ ] Create SaveManager singleton
- [ ] Implement save data collection
- [ ] Implement save data application
- [ ] Add JSON serialization
- [ ] Implement encryption (optional)
- [ ] Add checksum validation
- [ ] Create backup rotation system
- [ ] Implement recovery from backups
- [ ] Add version migration system
- [ ] Create save slot UI
- [ ] Implement auto-save triggers
- [ ] Add cloud sync integration
- [ ] Create conflict resolution UI
- [ ] Test save/load across versions
- [ ] Add save file error handling

---

## References

- `game/main.gd` - Game state management
- `game/typing_profile.gd` - Player data
- `scripts/GameController.gd` - Game flow
- Godot FileAccess documentation
- Godot JSON documentation
