using System;
using System.Collections.Generic;
using System.IO;
using KeyboardDefense.Core.State;
using Newtonsoft.Json;

namespace KeyboardDefense.Core.Data;

/// <summary>
/// Handles serialization/deserialization of GameState to/from JSON.
/// Ported from sim/save.gd (SimSave class).
/// </summary>
public static class SaveManager
{
    public const int SaveVersion = 1;

    public static string StateToJson(GameState state)
    {
        var dict = StateToDict(state);
        return JsonConvert.SerializeObject(dict, Formatting.Indented);
    }

    public static (bool Ok, GameState? State, string? Error) StateFromJson(string json)
    {
        try
        {
            var dict = JsonConvert.DeserializeObject<Dictionary<string, object>>(json);
            if (dict == null)
                return (false, null, "Failed to parse JSON.");
            return StateFromDict(dict);
        }
        catch (Exception ex)
        {
            return (false, null, $"JSON parse error: {ex.Message}");
        }
    }

    public static Dictionary<string, object> StateToDict(GameState state)
    {
        var discoveredList = new List<int>(state.Discovered);

        return new Dictionary<string, object>
        {
            // Core
            ["version"] = SaveVersion,
            ["day"] = state.Day,
            ["phase"] = state.Phase,
            ["ap_max"] = state.ApMax,
            ["ap"] = state.Ap,
            ["hp"] = state.Hp,
            ["threat"] = state.Threat,
            ["resources"] = new Dictionary<string, int>(state.Resources),
            ["buildings"] = new Dictionary<string, int>(state.Buildings),
            ["map_w"] = state.MapW,
            ["map_h"] = state.MapH,
            ["base_pos"] = PointToDict(state.BasePos),
            ["cursor_pos"] = PointToDict(state.CursorPos),
            ["player_pos"] = PointToDict(state.PlayerPos),
            ["player_facing"] = state.PlayerFacing,
            ["terrain"] = new List<string>(state.Terrain),
            ["structures"] = SerializeIntKeyDict(state.Structures),
            ["structure_levels"] = SerializeIntIntDict(state.StructureLevels),
            ["discovered"] = discoveredList,
            ["night_prompt"] = state.NightPrompt,
            ["night_spawn_remaining"] = state.NightSpawnRemaining,
            ["night_wave_total"] = state.NightWaveTotal,
            ["enemies"] = state.Enemies,
            ["enemy_next_id"] = state.EnemyNextId,
            ["last_path_open"] = state.LastPathOpen,
            ["rng_seed"] = state.RngSeed,
            ["rng_state"] = state.RngState,
            ["lesson_id"] = state.LessonId,

            // Event system
            ["active_pois"] = state.ActivePois,
            ["event_cooldowns"] = new Dictionary<string, int>(state.EventCooldowns),
            ["event_flags"] = state.EventFlags,
            ["pending_event"] = state.PendingEvent,
            ["active_buffs"] = state.ActiveBuffs,

            // Upgrades
            ["gold"] = state.Gold,
            ["purchased_kingdom_upgrades"] = new List<string>(state.PurchasedKingdomUpgrades),
            ["purchased_unit_upgrades"] = new List<string>(state.PurchasedUnitUpgrades),

            // Progression
            ["completed_quests"] = new List<string>(state.CompletedQuests),
            ["bosses_defeated"] = new List<string>(state.BossesDefeated),
            ["milestones"] = new List<string>(state.Milestones),
            ["unlocked_skills"] = new List<string>(state.UnlockedSkills),
            ["skill_points"] = state.SkillPoints,
            ["enemies_defeated"] = state.EnemiesDefeated,
            ["max_combo_ever"] = state.MaxComboEver,
            ["waves_survived"] = state.WavesSurvived,
            ["active_title"] = state.ActiveTitle,

            // Inventory & equipment
            ["inventory"] = new Dictionary<string, int>(state.Inventory),
            ["equipped_items"] = new Dictionary<string, string>(state.EquippedItems),

            // Workers
            ["workers"] = SerializeIntIntDict(state.Workers),
            ["worker_assignments"] = SerializeIntIntDict(state.WorkerAssignments),
            ["worker_count"] = state.WorkerCount,
            ["total_workers"] = state.TotalWorkers,
            ["max_workers"] = state.MaxWorkers,
            ["worker_upkeep"] = state.WorkerUpkeep,

            // Citizens
            ["citizens"] = state.Citizens,

            // Research
            ["active_research"] = state.ActiveResearch,
            ["research_progress"] = state.ResearchProgress,
            ["completed_research"] = new List<string>(state.CompletedResearch),

            // Trade
            ["trade_rates"] = new Dictionary<string, double>(state.TradeRates),
            ["last_trade_day"] = state.LastTradeDay,

            // Faction/Diplomacy
            ["faction_relations"] = new Dictionary<string, int>(state.FactionRelations),
            ["faction_agreements"] = SerializeFactionAgreements(state.FactionAgreements),
            ["pending_diplomacy"] = state.PendingDiplomacy,

            // Accessibility
            ["speed_multiplier"] = state.SpeedMultiplier,
            ["practice_mode"] = state.PracticeMode,

            // Open-world
            ["time_of_day"] = state.TimeOfDay,
            ["activity_mode"] = state.ActivityMode,
            ["threat_level"] = state.ThreatLevel,
            ["wave_cooldown"] = state.WaveCooldown,
            ["world_tick_accum"] = state.WorldTickAccum,
            ["threat_decay_accum"] = state.ThreatDecayAccum,
            ["roaming_enemies"] = state.RoamingEnemies,
            ["roaming_resources"] = state.RoamingResources,
            ["npcs"] = state.Npcs,
            ["encounter_enemies"] = state.EncounterEnemies,

            // Expeditions
            ["active_expeditions"] = state.ActiveExpeditions,
            ["expedition_next_id"] = state.ExpeditionNextId,
            ["expedition_history"] = state.ExpeditionHistory,

            // Resource nodes
            ["resource_nodes"] = SerializeIntDictDict(state.ResourceNodes),
            ["harvested_nodes"] = new Dictionary<string, int>(state.HarvestedNodes),

            // Loot
            ["loot_pending"] = state.LootPending,
            ["last_loot_quality"] = state.LastLootQuality,
            ["perfect_kills"] = state.PerfectKills,

            // Towers
            ["tower_states"] = SerializeIntDictDict(state.TowerStates),
            ["active_synergies"] = state.ActiveSynergies,
            ["summoned_units"] = state.SummonedUnits,
            ["summoned_next_id"] = state.SummonedNextId,
            ["active_traps"] = state.ActiveTraps,
            ["tower_charge"] = SerializeIntIntDict(state.TowerCharge),
            ["tower_cooldowns"] = SerializeIntIntDict(state.TowerCooldowns),
            ["tower_summon_ids"] = SerializeIntListIntDict(state.TowerSummonIds),
            ["auto_tower"] = SerializeAutoTower(state.AutoTower),
            ["targeting_mode"] = state.TargetingMode,

            // Typing
            ["typing_metrics"] = state.TypingMetrics,
            ["arrow_rain_timer"] = state.ArrowRainTimer,

            // Hero
            ["hero_id"] = state.HeroId,
            ["hero_ability_cooldown"] = state.HeroAbilityCooldown,
            ["hero_active_effects"] = state.HeroActiveEffects,

            // Titles
            ["equipped_title"] = state.EquippedTitle,
            ["unlocked_titles"] = new List<string>(state.UnlockedTitles),
            ["unlocked_badges"] = new List<string>(state.UnlockedBadges),

            // Daily challenges
            ["completed_daily_challenges"] = new List<string>(state.CompletedDailyChallenges),
            ["daily_challenge_date"] = state.DailyChallengeDate,
            ["perfect_nights_today"] = state.PerfectNightsToday,
            ["no_damage_nights_today"] = state.NoDamageNightsToday,
            ["fastest_night_seconds"] = state.FastestNightSeconds,

            // Victory
            ["victory_achieved"] = new List<string>(state.VictoryAchieved),
            ["victory_checked"] = state.VictoryChecked,
            ["peak_gold"] = state.PeakGold,
            ["story_completed"] = state.StoryCompleted,
            ["current_act"] = state.CurrentAct,
        };
    }

    public static (bool Ok, GameState? State, string? Error) StateFromDict(Dictionary<string, object> data)
    {
        int version = GetInt(data, "version", 1);
        if (version > SaveVersion)
            return (false, null, $"Save version {version} is newer than supported {SaveVersion}.");

        var state = new GameState
        {
            // Core
            Version = version,
            Day = GetInt(data, "day", 1),
            Phase = GetString(data, "phase", "day"),
            ApMax = GetInt(data, "ap_max", 3),
            Ap = GetInt(data, "ap", 3),
            Hp = GetInt(data, "hp", 10),
            Threat = GetInt(data, "threat", 0),
            MapW = GetInt(data, "map_w", 64),
            MapH = GetInt(data, "map_h", 64),
            NightPrompt = GetString(data, "night_prompt", ""),
            NightSpawnRemaining = GetInt(data, "night_spawn_remaining", 0),
            NightWaveTotal = GetInt(data, "night_wave_total", 0),
            EnemyNextId = GetInt(data, "enemy_next_id", 1),
            LastPathOpen = GetBool(data, "last_path_open", true),
            RngSeed = GetString(data, "rng_seed", "default"),
            RngState = GetLong(data, "rng_state", 0),
            LessonId = GetString(data, "lesson_id", "full_alpha"),

            // Upgrades
            Gold = GetInt(data, "gold", 0),
            ArrowRainTimer = GetFloat(data, "arrow_rain_timer", 0.0f),

            // Progression
            SkillPoints = GetInt(data, "skill_points", 0),
            EnemiesDefeated = GetInt(data, "enemies_defeated", 0),
            MaxComboEver = GetInt(data, "max_combo_ever", 0),
            WavesSurvived = GetInt(data, "waves_survived", 0),
            ActiveTitle = GetString(data, "active_title", ""),

            // Workers
            WorkerCount = GetInt(data, "worker_count", 3),
            TotalWorkers = GetInt(data, "total_workers", 3),
            MaxWorkers = GetInt(data, "max_workers", 10),
            WorkerUpkeep = GetInt(data, "worker_upkeep", 1),

            // Research
            ActiveResearch = GetString(data, "active_research", ""),
            ResearchProgress = GetInt(data, "research_progress", 0),

            // Trade
            LastTradeDay = GetInt(data, "last_trade_day", 0),

            // Accessibility
            SpeedMultiplier = GetFloat(data, "speed_multiplier", 1.0f),
            PracticeMode = GetBool(data, "practice_mode", false),

            // Open-world
            TimeOfDay = GetFloat(data, "time_of_day", 0.25f),
            ActivityMode = GetString(data, "activity_mode", "exploration"),
            ThreatLevel = GetFloat(data, "threat_level", 0f),
            WaveCooldown = GetFloat(data, "wave_cooldown", 0f),
            WorldTickAccum = GetFloat(data, "world_tick_accum", 0f),
            ThreatDecayAccum = GetFloat(data, "threat_decay_accum", 0f),

            // Expeditions
            ExpeditionNextId = GetInt(data, "expedition_next_id", 1),

            // Loot
            LastLootQuality = GetFloat(data, "last_loot_quality", 1.0f),
            PerfectKills = GetInt(data, "perfect_kills", 0),

            // Towers
            SummonedNextId = GetInt(data, "summoned_next_id", 1),
            TargetingMode = GetString(data, "targeting_mode", "nearest"),

            // Hero
            HeroId = GetString(data, "hero_id", ""),
            HeroAbilityCooldown = GetFloat(data, "hero_ability_cooldown", 0f),

            // Titles
            EquippedTitle = GetString(data, "equipped_title", ""),

            // Daily challenges
            DailyChallengeDate = GetString(data, "daily_challenge_date", ""),
            PerfectNightsToday = GetInt(data, "perfect_nights_today", 0),
            NoDamageNightsToday = GetInt(data, "no_damage_nights_today", 0),
            FastestNightSeconds = GetInt(data, "fastest_night_seconds", 0),

            // Victory
            VictoryChecked = GetBool(data, "victory_checked", false),
            PeakGold = GetInt(data, "peak_gold", 0),
            StoryCompleted = GetBool(data, "story_completed", false),
            CurrentAct = GetInt(data, "current_act", 1),
        };

        // Points
        state.BasePos = PointFromDict(data, "base_pos", new GridPoint(state.MapW / 2, state.MapH / 2));
        state.CursorPos = PointFromDict(data, "cursor_pos", state.BasePos);
        state.PlayerPos = PointFromDict(data, "player_pos", state.BasePos);
        state.PlayerFacing = GetString(data, "player_facing", "down");

        // Core collections
        state.Resources = DeserializeStringIntDict(data, "resources");
        state.Buildings = DeserializeStringIntDict(data, "buildings");
        state.Terrain = DeserializeStringList(data, "terrain");
        state.Structures = DeserializeIntStringDict(data, "structures");
        state.StructureLevels = DeserializeIntIntDict(data, "structure_levels");
        state.Discovered = DeserializeIntHashSet(data, "discovered");
        state.Enemies = DeserializeEnemyList(data, "enemies");
        state.PurchasedKingdomUpgrades = DeserializeStringList(data, "purchased_kingdom_upgrades");
        state.PurchasedUnitUpgrades = DeserializeStringList(data, "purchased_unit_upgrades");

        // Event system
        state.ActivePois = DeserializeStringDictDict(data, "active_pois");
        state.EventCooldowns = DeserializeStringIntDict(data, "event_cooldowns");
        state.EventFlags = DeserializeDictStringObject(data, "event_flags");
        state.PendingEvent = DeserializeDictStringObject(data, "pending_event");
        state.ActiveBuffs = DeserializeEnemyList(data, "active_buffs");

        // Progression
        state.CompletedQuests = DeserializeStringHashSet(data, "completed_quests");
        state.BossesDefeated = DeserializeStringHashSet(data, "bosses_defeated");
        state.Milestones = DeserializeStringHashSet(data, "milestones");
        state.UnlockedSkills = DeserializeStringHashSet(data, "unlocked_skills");

        // Inventory
        state.Inventory = DeserializeStringIntDict(data, "inventory");
        state.EquippedItems = DeserializeStringStringDict(data, "equipped_items");

        // Workers
        state.Workers = DeserializeIntIntDict(data, "workers");
        state.WorkerAssignments = DeserializeIntIntDict(data, "worker_assignments");

        // Research
        state.CompletedResearch = DeserializeStringList(data, "completed_research");

        // Trade
        state.TradeRates = DeserializeStringDoubleDict(data, "trade_rates");

        // Faction
        state.FactionRelations = DeserializeStringIntDict(data, "faction_relations");
        state.FactionAgreements = DeserializeFactionAgreements(data, "faction_agreements");
        state.PendingDiplomacy = DeserializeStringDictDict(data, "pending_diplomacy");

        // Citizens
        state.Citizens = DeserializeEnemyList(data, "citizens");

        // Open-world entities
        state.RoamingEnemies = DeserializeEnemyList(data, "roaming_enemies");
        state.RoamingResources = DeserializeEnemyList(data, "roaming_resources");
        state.Npcs = DeserializeEnemyList(data, "npcs");
        state.EncounterEnemies = DeserializeEnemyList(data, "encounter_enemies");

        // Expeditions
        state.ActiveExpeditions = DeserializeEnemyList(data, "active_expeditions");
        state.ExpeditionHistory = DeserializeEnemyList(data, "expedition_history");

        // Resource nodes
        state.ResourceNodes = DeserializeIntDictDict(data, "resource_nodes");
        state.HarvestedNodes = DeserializeStringIntDict(data, "harvested_nodes");

        // Loot
        state.LootPending = DeserializeEnemyList(data, "loot_pending");

        // Towers
        state.TowerStates = DeserializeIntDictDict(data, "tower_states");
        state.ActiveSynergies = DeserializeEnemyList(data, "active_synergies");
        state.SummonedUnits = DeserializeEnemyList(data, "summoned_units");
        state.ActiveTraps = DeserializeEnemyList(data, "active_traps");
        state.TowerCharge = DeserializeIntIntDict(data, "tower_charge");
        state.TowerCooldowns = DeserializeIntIntDict(data, "tower_cooldowns");
        state.TowerSummonIds = DeserializeIntListIntDict(data, "tower_summon_ids");
        state.AutoTower = DeserializeAutoTower(data, "auto_tower");

        // Typing
        state.TypingMetrics = DeserializeDictStringObject(data, "typing_metrics");
        if (state.TypingMetrics.Count == 0)
        {
            // Initialize defaults if not present in save
            state.TypingMetrics = new Dictionary<string, object>
            {
                ["battle_chars_typed"] = 0,
                ["battle_words_typed"] = 0,
                ["battle_start_msec"] = 0L,
                ["battle_errors"] = 0,
                ["rolling_window_chars"] = new List<object>(),
                ["unique_letters_window"] = new Dictionary<string, object>(),
                ["perfect_word_streak"] = 0,
                ["current_word_errors"] = 0
            };
        }

        // Hero
        state.HeroActiveEffects = DeserializeEnemyList(data, "hero_active_effects");

        // Titles
        state.UnlockedTitles = DeserializeStringList(data, "unlocked_titles");
        state.UnlockedBadges = DeserializeStringList(data, "unlocked_badges");

        // Daily challenges
        state.CompletedDailyChallenges = DeserializeStringHashSet(data, "completed_daily_challenges");

        // Victory
        state.VictoryAchieved = DeserializeStringList(data, "victory_achieved");

        return (true, state, null);
    }

    public static bool SaveToFile(GameState state, string path)
    {
        try
        {
            string json = StateToJson(state);
            File.WriteAllText(path, json);
            return true;
        }
        catch
        {
            return false;
        }
    }

    public static (bool Ok, GameState? State, string? Error) LoadFromFile(string path)
    {
        try
        {
            if (!File.Exists(path))
                return (false, null, "Save file not found.");
            string json = File.ReadAllText(path);
            return StateFromJson(json);
        }
        catch (Exception ex)
        {
            return (false, null, $"Load error: {ex.Message}");
        }
    }

    // ── Point helpers ──

    private static Dictionary<string, object> PointToDict(GridPoint p)
        => new() { ["x"] = p.X, ["y"] = p.Y };

    private static GridPoint PointFromDict(Dictionary<string, object> data, string key, GridPoint fallback)
    {
        if (!data.ContainsKey(key)) return fallback;
        try
        {
            var raw = data[key];
            if (raw is Newtonsoft.Json.Linq.JObject jObj)
            {
                return new GridPoint(
                    jObj.Value<int>("x"),
                    jObj.Value<int>("y")
                );
            }
            if (raw is Dictionary<string, object> dict)
            {
                return new GridPoint(
                    Convert.ToInt32(dict.GetValueOrDefault("x", fallback.X)),
                    Convert.ToInt32(dict.GetValueOrDefault("y", fallback.Y))
                );
            }
        }
        catch { }
        return fallback;
    }

    // ── Serialization helpers ──

    private static Dictionary<string, string> SerializeIntKeyDict(Dictionary<int, string> dict)
    {
        var result = new Dictionary<string, string>();
        foreach (var (key, value) in dict)
            result[key.ToString()] = value;
        return result;
    }

    private static Dictionary<string, int> SerializeIntIntDict(Dictionary<int, int> dict)
    {
        var result = new Dictionary<string, int>();
        foreach (var (key, value) in dict)
            result[key.ToString()] = value;
        return result;
    }

    private static Dictionary<string, Dictionary<string, object>> SerializeIntDictDict(
        Dictionary<int, Dictionary<string, object>> dict)
    {
        var result = new Dictionary<string, Dictionary<string, object>>();
        foreach (var (key, value) in dict)
            result[key.ToString()] = value;
        return result;
    }

    private static Dictionary<string, List<int>> SerializeIntListIntDict(Dictionary<int, List<int>> dict)
    {
        var result = new Dictionary<string, List<int>>();
        foreach (var (key, value) in dict)
            result[key.ToString()] = value;
        return result;
    }

    private static Dictionary<string, object> SerializeFactionAgreements(
        Dictionary<string, List<string>> agreements)
    {
        var result = new Dictionary<string, object>();
        foreach (var (key, list) in agreements)
            result[key] = new List<string>(list);
        return result;
    }

    private static Dictionary<string, object> SerializeAutoTower(AutoTowerSettings settings)
    {
        return new Dictionary<string, object>
        {
            ["auto_build"] = settings.AutoBuild,
            ["build_priority"] = settings.BuildPriority,
            ["auto_upgrade"] = settings.AutoUpgrade,
            ["auto_repair"] = settings.AutoRepair,
            ["resource_reserve_percent"] = settings.ResourceReservePercent,
        };
    }

    // ── Deserialization helpers ──

    private static Dictionary<string, int> DeserializeStringIntDict(Dictionary<string, object> data, string key)
    {
        var result = new Dictionary<string, int>();
        if (!data.TryGetValue(key, out var raw)) return result;
        if (raw is Newtonsoft.Json.Linq.JObject jObj)
        {
            foreach (var prop in jObj.Properties())
                result[prop.Name] = prop.Value.ToObject<int>();
        }
        else if (raw is Dictionary<string, object> dict)
        {
            foreach (var (k, v) in dict)
                result[k] = Convert.ToInt32(v);
        }
        else if (raw is Dictionary<string, int> typed)
        {
            foreach (var (k, v) in typed) result[k] = v;
        }
        return result;
    }

    private static Dictionary<string, string> DeserializeStringStringDict(Dictionary<string, object> data, string key)
    {
        var result = new Dictionary<string, string>();
        if (!data.TryGetValue(key, out var raw)) return result;
        if (raw is Newtonsoft.Json.Linq.JObject jObj)
        {
            foreach (var prop in jObj.Properties())
                result[prop.Name] = prop.Value.ToObject<string>() ?? "";
        }
        else if (raw is Dictionary<string, object> dict)
        {
            foreach (var (k, v) in dict)
                result[k] = v?.ToString() ?? "";
        }
        else if (raw is Dictionary<string, string> typed)
        {
            foreach (var (k, v) in typed) result[k] = v;
        }
        return result;
    }

    private static Dictionary<string, double> DeserializeStringDoubleDict(Dictionary<string, object> data, string key)
    {
        var result = new Dictionary<string, double>();
        if (!data.TryGetValue(key, out var raw)) return result;
        if (raw is Newtonsoft.Json.Linq.JObject jObj)
        {
            foreach (var prop in jObj.Properties())
                result[prop.Name] = prop.Value.ToObject<double>();
        }
        else if (raw is Dictionary<string, object> dict)
        {
            foreach (var (k, v) in dict)
                result[k] = Convert.ToDouble(v);
        }
        else if (raw is Dictionary<string, double> typed)
        {
            foreach (var (k, v) in typed) result[k] = v;
        }
        return result;
    }

    private static List<string> DeserializeStringList(Dictionary<string, object> data, string key)
    {
        var result = new List<string>();
        if (!data.TryGetValue(key, out var raw)) return result;
        if (raw is Newtonsoft.Json.Linq.JArray jArr)
        {
            foreach (var item in jArr)
                result.Add(item.ToObject<string>() ?? "");
        }
        else if (raw is List<string> list)
        {
            result.AddRange(list);
        }
        return result;
    }

    private static Dictionary<int, string> DeserializeIntStringDict(Dictionary<string, object> data, string key)
    {
        var result = new Dictionary<int, string>();
        if (!data.TryGetValue(key, out var raw)) return result;
        if (raw is Newtonsoft.Json.Linq.JObject jObj)
        {
            foreach (var prop in jObj.Properties())
                if (int.TryParse(prop.Name, out int idx))
                    result[idx] = prop.Value.ToObject<string>() ?? "";
        }
        else if (raw is Dictionary<string, string> dict)
        {
            foreach (var (k, v) in dict)
                if (int.TryParse(k, out int idx))
                    result[idx] = v;
        }
        return result;
    }

    private static Dictionary<int, int> DeserializeIntIntDict(Dictionary<string, object> data, string key)
    {
        var result = new Dictionary<int, int>();
        if (!data.TryGetValue(key, out var raw)) return result;
        if (raw is Newtonsoft.Json.Linq.JObject jObj)
        {
            foreach (var prop in jObj.Properties())
                if (int.TryParse(prop.Name, out int idx))
                    result[idx] = prop.Value.ToObject<int>();
        }
        else if (raw is Dictionary<string, int> dict)
        {
            foreach (var (k, v) in dict)
                if (int.TryParse(k, out int idx))
                    result[idx] = v;
        }
        return result;
    }

    private static Dictionary<int, Dictionary<string, object>> DeserializeIntDictDict(
        Dictionary<string, object> data, string key)
    {
        var result = new Dictionary<int, Dictionary<string, object>>();
        if (!data.TryGetValue(key, out var raw)) return result;
        if (raw is Newtonsoft.Json.Linq.JObject jObj)
        {
            foreach (var prop in jObj.Properties())
            {
                if (!int.TryParse(prop.Name, out int idx)) continue;
                if (prop.Value is Newtonsoft.Json.Linq.JObject inner)
                {
                    var dict = new Dictionary<string, object>();
                    foreach (var p in inner.Properties())
                        dict[p.Name] = p.Value.Type switch
                        {
                            Newtonsoft.Json.Linq.JTokenType.Integer => p.Value.ToObject<int>(),
                            Newtonsoft.Json.Linq.JTokenType.Float => p.Value.ToObject<double>(),
                            Newtonsoft.Json.Linq.JTokenType.String => (object)p.Value.ToObject<string>()!,
                            Newtonsoft.Json.Linq.JTokenType.Boolean => p.Value.ToObject<bool>(),
                            _ => p.Value.ToString(),
                        };
                    result[idx] = dict;
                }
            }
        }
        return result;
    }

    private static Dictionary<string, Dictionary<string, object>> DeserializeStringDictDict(
        Dictionary<string, object> data, string key)
    {
        var result = new Dictionary<string, Dictionary<string, object>>();
        if (!data.TryGetValue(key, out var raw)) return result;
        if (raw is Newtonsoft.Json.Linq.JObject jObj)
        {
            foreach (var prop in jObj.Properties())
            {
                if (prop.Value is Newtonsoft.Json.Linq.JObject inner)
                {
                    var dict = new Dictionary<string, object>();
                    foreach (var p in inner.Properties())
                        dict[p.Name] = p.Value.Type switch
                        {
                            Newtonsoft.Json.Linq.JTokenType.Integer => p.Value.ToObject<int>(),
                            Newtonsoft.Json.Linq.JTokenType.Float => p.Value.ToObject<double>(),
                            Newtonsoft.Json.Linq.JTokenType.String => (object)p.Value.ToObject<string>()!,
                            Newtonsoft.Json.Linq.JTokenType.Boolean => p.Value.ToObject<bool>(),
                            _ => p.Value.ToString(),
                        };
                    result[prop.Name] = dict;
                }
            }
        }
        else if (raw is Dictionary<string, Dictionary<string, object>> typed)
        {
            foreach (var (k, v) in typed) result[k] = v;
        }
        return result;
    }

    private static Dictionary<string, object> DeserializeDictStringObject(
        Dictionary<string, object> data, string key)
    {
        var result = new Dictionary<string, object>();
        if (!data.TryGetValue(key, out var raw)) return result;
        if (raw is Newtonsoft.Json.Linq.JObject jObj)
        {
            foreach (var prop in jObj.Properties())
                result[prop.Name] = DeserializeJToken(prop.Value);
            return result;
        }
        if (raw is Dictionary<string, object> dict)
        {
            foreach (var (k, v) in dict) result[k] = v;
        }
        return result;
    }

    private static Dictionary<string, object> DeserializeJObjectToDict(Newtonsoft.Json.Linq.JObject jObj)
    {
        var dict = new Dictionary<string, object>();
        foreach (var prop in jObj.Properties())
            dict[prop.Name] = DeserializeJToken(prop.Value);
        return dict;
    }

    private static object DeserializeJToken(Newtonsoft.Json.Linq.JToken token)
    {
        return token.Type switch
        {
            Newtonsoft.Json.Linq.JTokenType.Integer =>
                token.ToObject<long>() is long l && l >= int.MinValue && l <= int.MaxValue
                    ? (object)(int)l : l,
            Newtonsoft.Json.Linq.JTokenType.Float => token.ToObject<double>(),
            Newtonsoft.Json.Linq.JTokenType.String => (object)token.ToObject<string>()!,
            Newtonsoft.Json.Linq.JTokenType.Boolean => token.ToObject<bool>(),
            Newtonsoft.Json.Linq.JTokenType.Array => token.ToObject<List<object>>()!,
            Newtonsoft.Json.Linq.JTokenType.Object =>
                (object)DeserializeJObjectToDict((Newtonsoft.Json.Linq.JObject)token),
            _ => token.ToString(),
        };
    }

    private static Dictionary<int, List<int>> DeserializeIntListIntDict(
        Dictionary<string, object> data, string key)
    {
        var result = new Dictionary<int, List<int>>();
        if (!data.TryGetValue(key, out var raw)) return result;
        if (raw is Newtonsoft.Json.Linq.JObject jObj)
        {
            foreach (var prop in jObj.Properties())
            {
                if (!int.TryParse(prop.Name, out int idx)) continue;
                if (prop.Value is Newtonsoft.Json.Linq.JArray arr)
                {
                    var list = new List<int>();
                    foreach (var item in arr)
                        list.Add(item.ToObject<int>());
                    result[idx] = list;
                }
            }
        }
        return result;
    }

    private static Dictionary<string, List<string>> DeserializeFactionAgreements(
        Dictionary<string, object> data, string key)
    {
        var result = new Dictionary<string, List<string>>
        {
            ["trade"] = new(), ["non_aggression"] = new(), ["alliance"] = new(), ["war"] = new()
        };
        if (!data.TryGetValue(key, out var raw)) return result;
        if (raw is Newtonsoft.Json.Linq.JObject jObj)
        {
            foreach (var prop in jObj.Properties())
            {
                var list = new List<string>();
                if (prop.Value is Newtonsoft.Json.Linq.JArray arr)
                {
                    foreach (var item in arr)
                    {
                        string? s = item.ToObject<string>();
                        if (s != null) list.Add(s);
                    }
                }
                result[prop.Name] = list;
            }
        }
        return result;
    }

    private static AutoTowerSettings DeserializeAutoTower(Dictionary<string, object> data, string key)
    {
        var settings = new AutoTowerSettings();
        if (!data.TryGetValue(key, out var raw)) return settings;
        if (raw is Newtonsoft.Json.Linq.JObject jObj)
        {
            settings.AutoBuild = jObj.Value<bool>("auto_build");
            settings.BuildPriority = jObj.Value<string>("build_priority") ?? "balanced";
            settings.AutoUpgrade = jObj.Value<bool>("auto_upgrade");
            settings.AutoRepair = jObj.Value<bool>("auto_repair");
            settings.ResourceReservePercent = jObj.Value<int>("resource_reserve_percent");
        }
        else if (raw is Dictionary<string, object> dict)
        {
            settings.AutoBuild = Convert.ToBoolean(dict.GetValueOrDefault("auto_build", false));
            settings.BuildPriority = dict.GetValueOrDefault("build_priority")?.ToString() ?? "balanced";
            settings.AutoUpgrade = Convert.ToBoolean(dict.GetValueOrDefault("auto_upgrade", false));
            settings.AutoRepair = Convert.ToBoolean(dict.GetValueOrDefault("auto_repair", true));
            settings.ResourceReservePercent = Convert.ToInt32(dict.GetValueOrDefault("resource_reserve_percent", 0));
        }
        return settings;
    }

    private static HashSet<int> DeserializeIntHashSet(Dictionary<string, object> data, string key)
    {
        var result = new HashSet<int>();
        if (!data.TryGetValue(key, out var raw)) return result;
        if (raw is Newtonsoft.Json.Linq.JArray jArr)
        {
            foreach (var item in jArr)
                result.Add(item.ToObject<int>());
        }
        return result;
    }

    private static List<Dictionary<string, object>> DeserializeEnemyList(Dictionary<string, object> data, string key)
    {
        var result = new List<Dictionary<string, object>>();
        if (!data.TryGetValue(key, out var raw)) return result;
        if (raw is Newtonsoft.Json.Linq.JArray jArr)
        {
            foreach (var item in jArr)
            {
                if (item is Newtonsoft.Json.Linq.JObject jEnemy)
                {
                    var enemy = new Dictionary<string, object>();
                    foreach (var prop in jEnemy.Properties())
                        enemy[prop.Name] = prop.Value.Type switch
                        {
                            Newtonsoft.Json.Linq.JTokenType.Integer => prop.Value.ToObject<int>(),
                            Newtonsoft.Json.Linq.JTokenType.Float => prop.Value.ToObject<double>(),
                            Newtonsoft.Json.Linq.JTokenType.String => (object)prop.Value.ToObject<string>()!,
                            Newtonsoft.Json.Linq.JTokenType.Boolean => prop.Value.ToObject<bool>(),
                            _ => prop.Value.ToString(),
                        };
                    result.Add(enemy);
                }
            }
        }
        return result;
    }

    private static HashSet<string> DeserializeStringHashSet(Dictionary<string, object> data, string key)
    {
        var result = new HashSet<string>();
        if (!data.TryGetValue(key, out var raw)) return result;
        if (raw is Newtonsoft.Json.Linq.JArray jArr)
        {
            foreach (var item in jArr)
            {
                string? s = item.ToObject<string>();
                if (s != null) result.Add(s);
            }
        }
        else if (raw is List<string> list)
        {
            foreach (var s in list) result.Add(s);
        }
        return result;
    }

    // ── Scalar helpers ──

    private static int GetInt(Dictionary<string, object> data, string key, int fallback)
    {
        if (data.TryGetValue(key, out var val))
        {
            try { return Convert.ToInt32(val); }
            catch { return fallback; }
        }
        return fallback;
    }

    private static long GetLong(Dictionary<string, object> data, string key, long fallback)
    {
        if (data.TryGetValue(key, out var val))
        {
            try { return Convert.ToInt64(val); }
            catch { return fallback; }
        }
        return fallback;
    }

    private static float GetFloat(Dictionary<string, object> data, string key, float fallback)
    {
        if (data.TryGetValue(key, out var val))
        {
            try { return Convert.ToSingle(val); }
            catch { return fallback; }
        }
        return fallback;
    }

    private static string GetString(Dictionary<string, object> data, string key, string fallback)
    {
        if (data.TryGetValue(key, out var val))
            return val?.ToString() ?? fallback;
        return fallback;
    }

    private static bool GetBool(Dictionary<string, object> data, string key, bool fallback)
    {
        if (data.TryGetValue(key, out var val))
        {
            try { return Convert.ToBoolean(val); }
            catch { return fallback; }
        }
        return fallback;
    }
}
