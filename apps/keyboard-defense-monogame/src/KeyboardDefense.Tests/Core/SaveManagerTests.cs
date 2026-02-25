using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;
using Newtonsoft.Json;

namespace KeyboardDefense.Tests.Core;

public class SaveManagerTests
{
    private static readonly HashSet<string> ExpectedStateKeys = new(StringComparer.Ordinal)
    {
        "version",
        "day",
        "phase",
        "ap_max",
        "ap",
        "hp",
        "threat",
        "resources",
        "buildings",
        "map_w",
        "map_h",
        "base_pos",
        "cursor_pos",
        "player_pos",
        "player_facing",
        "terrain",
        "structures",
        "structure_levels",
        "discovered",
        "night_prompt",
        "night_spawn_remaining",
        "night_wave_total",
        "enemies",
        "enemy_next_id",
        "last_path_open",
        "rng_seed",
        "rng_state",
        "lesson_id",
        "active_pois",
        "event_cooldowns",
        "event_flags",
        "pending_event",
        "active_buffs",
        "gold",
        "purchased_kingdom_upgrades",
        "purchased_unit_upgrades",
        "completed_quests",
        "bosses_defeated",
        "milestones",
        "unlocked_skills",
        "skill_points",
        "enemies_defeated",
        "max_combo_ever",
        "waves_survived",
        "active_title",
        "inventory",
        "equipped_items",
        "workers",
        "worker_assignments",
        "worker_count",
        "total_workers",
        "max_workers",
        "worker_upkeep",
        "citizens",
        "active_research",
        "research_progress",
        "completed_research",
        "trade_rates",
        "last_trade_day",
        "faction_relations",
        "faction_agreements",
        "pending_diplomacy",
        "speed_multiplier",
        "practice_mode",
        "time_of_day",
        "activity_mode",
        "threat_level",
        "wave_cooldown",
        "world_tick_accum",
        "threat_decay_accum",
        "roaming_enemies",
        "roaming_resources",
        "npcs",
        "encounter_enemies",
        "active_expeditions",
        "expedition_next_id",
        "expedition_history",
        "resource_nodes",
        "harvested_nodes",
        "loot_pending",
        "last_loot_quality",
        "perfect_kills",
        "tower_states",
        "active_synergies",
        "summoned_units",
        "summoned_next_id",
        "active_traps",
        "tower_charge",
        "tower_cooldowns",
        "tower_summon_ids",
        "auto_tower",
        "targeting_mode",
        "typing_metrics",
        "arrow_rain_timer",
        "hero_id",
        "hero_ability_cooldown",
        "hero_active_effects",
        "equipped_title",
        "unlocked_titles",
        "unlocked_badges",
        "completed_daily_challenges",
        "daily_challenge_date",
        "perfect_nights_today",
        "no_damage_nights_today",
        "fastest_night_seconds",
        "victory_achieved",
        "victory_checked",
        "peak_gold",
        "story_completed",
        "current_act",
    };

    [Fact]
    public void StateToDict_ContainsAllExpectedKeysAndSaveVersion()
    {
        var state = new GameState();

        var dict = SaveManager.StateToDict(state);

        Assert.Equal(ExpectedStateKeys.Count, dict.Count);
        Assert.Empty(ExpectedStateKeys.Except(dict.Keys));
        Assert.Empty(dict.Keys.Except(ExpectedStateKeys));
        Assert.Equal(SaveManager.SaveVersion, Convert.ToInt32(dict["version"]));
    }

    [Fact]
    public void StateToDict_IntIndexedCollectionsUseStringKeys()
    {
        var state = new GameState();
        state.Structures[4] = "tower";
        state.StructureLevels[4] = 3;
        state.Workers[7] = 2;
        state.TowerCharge[4] = 1;
        state.TowerCooldowns[4] = 5;
        state.TowerSummonIds[4] = new List<int> { 9, 10 };

        var dict = SaveManager.StateToDict(state);

        var structures = Assert.IsType<Dictionary<string, string>>(dict["structures"]);
        var structureLevels = Assert.IsType<Dictionary<string, int>>(dict["structure_levels"]);
        var workers = Assert.IsType<Dictionary<string, int>>(dict["workers"]);
        var towerCharge = Assert.IsType<Dictionary<string, int>>(dict["tower_charge"]);
        var towerCooldowns = Assert.IsType<Dictionary<string, int>>(dict["tower_cooldowns"]);
        var towerSummonIds = Assert.IsType<Dictionary<string, List<int>>>(dict["tower_summon_ids"]);

        Assert.Equal("tower", structures["4"]);
        Assert.Equal(3, structureLevels["4"]);
        Assert.Equal(2, workers["7"]);
        Assert.Equal(1, towerCharge["4"]);
        Assert.Equal(5, towerCooldowns["4"]);
        Assert.Equal(new List<int> { 9, 10 }, towerSummonIds["4"]);
    }

    [Fact]
    public void StateToJson_IncludesIndentedVersionField()
    {
        var json = SaveManager.StateToJson(new GameState());

        Assert.Contains("\"version\": 1", json);
        Assert.Contains(Environment.NewLine, json);
    }

    [Fact]
    public void StateFromJson_InvalidJson_ReturnsError()
    {
        var (ok, state, error) = SaveManager.StateFromJson("{ broken");

        Assert.False(ok);
        Assert.Null(state);
        Assert.NotNull(error);
        Assert.Contains("JSON parse error", error!, StringComparison.Ordinal);
    }

    [Fact]
    public void StateFromJson_NullJson_ReturnsError()
    {
        var (ok, state, error) = SaveManager.StateFromJson(null!);

        Assert.False(ok);
        Assert.Null(state);
        Assert.NotNull(error);
        Assert.Contains("JSON parse error", error!, StringComparison.Ordinal);
    }

    [Fact]
    public void StateFromJson_ArrayRoot_ReturnsError()
    {
        var (ok, state, error) = SaveManager.StateFromJson("[]");

        Assert.False(ok);
        Assert.Null(state);
        Assert.NotNull(error);
    }

    [Fact]
    public void StateFromJson_NewerVersion_ReturnsError()
    {
        var json = $"{{\"version\":{SaveManager.SaveVersion + 1}}}";

        var (ok, state, error) = SaveManager.StateFromJson(json);

        Assert.False(ok);
        Assert.Null(state);
        Assert.NotNull(error);
        Assert.Contains("newer", error!, StringComparison.Ordinal);
    }

    [Fact]
    public void StateFromDict_FutureVersion_ReturnsError()
    {
        var data = new Dictionary<string, object>
        {
            ["version"] = SaveManager.SaveVersion + 99,
        };

        var (ok, state, error) = SaveManager.StateFromDict(data);

        Assert.False(ok);
        Assert.Null(state);
        Assert.NotNull(error);
        Assert.Contains("newer", error!, StringComparison.Ordinal);
    }

    [Fact]
    public void StateFromDict_EmptyDictionary_UsesFallbackDefaults()
    {
        var (ok, state, error) = SaveManager.StateFromDict(new Dictionary<string, object>());

        Assert.True(ok, error);
        Assert.NotNull(state);

        Assert.Equal(1, state!.Version);
        Assert.Equal(1, state.Day);
        Assert.Equal("day", state.Phase);
        Assert.Equal(3, state.ApMax);
        Assert.Equal(3, state.Ap);
        Assert.Equal(10, state.Hp);
        Assert.Equal(0, state.Threat);
        Assert.Equal(64, state.MapW);
        Assert.Equal(64, state.MapH);
        Assert.Equal(new GridPoint(32, 32), state.BasePos);
        Assert.Equal(state.BasePos, state.CursorPos);
        Assert.Equal(state.BasePos, state.PlayerPos);
        Assert.Equal("down", state.PlayerFacing);
        Assert.True(state.LastPathOpen);
        Assert.Equal("default", state.RngSeed);
        Assert.Equal(0L, state.RngState);
        Assert.Equal("full_alpha", state.LessonId);
        Assert.Equal(3, state.WorkerCount);
        Assert.Equal(3, state.TotalWorkers);
        Assert.Equal(10, state.MaxWorkers);
        Assert.Equal(1, state.WorkerUpkeep);
        Assert.Equal("exploration", state.ActivityMode);
        Assert.Equal("nearest", state.TargetingMode);
        Assert.Empty(state.Resources);
        Assert.Empty(state.Buildings);
        Assert.Empty(state.Terrain);
        Assert.Equal("balanced", state.AutoTower.BuildPriority);
        Assert.True(state.AutoTower.AutoRepair);
        AssertTypingMetricDefaults(state.TypingMetrics);
    }

    [Fact]
    public void StateFromDict_InvalidScalarTypes_UseFallbacks()
    {
        var data = new Dictionary<string, object>
        {
            ["version"] = 1,
            ["day"] = "nope",
            ["ap_max"] = "x",
            ["ap"] = "y",
            ["hp"] = "z",
            ["map_w"] = "wide",
            ["map_h"] = "tall",
            ["last_path_open"] = "not_bool",
            ["rng_state"] = "invalid_long",
            ["speed_multiplier"] = "invalid_float",
            ["practice_mode"] = "invalid_bool",
            ["wave_cooldown"] = "bad",
        };

        var (ok, state, error) = SaveManager.StateFromDict(data);

        Assert.True(ok, error);
        Assert.NotNull(state);
        Assert.Equal(1, state!.Day);
        Assert.Equal(3, state.ApMax);
        Assert.Equal(3, state.Ap);
        Assert.Equal(10, state.Hp);
        Assert.Equal(64, state.MapW);
        Assert.Equal(64, state.MapH);
        Assert.True(state.LastPathOpen);
        Assert.Equal(0L, state.RngState);
        Assert.Equal(1.0f, state.SpeedMultiplier);
        Assert.False(state.PracticeMode);
        Assert.Equal(0f, state.WaveCooldown);
    }

    [Fact]
    public void StateFromDict_NullValues_DoNotThrow_AndCoerceDefaults()
    {
        var data = new Dictionary<string, object>
        {
            ["version"] = 1,
            ["day"] = null!,
            ["resources"] = null!,
            ["typing_metrics"] = null!,
        };

        var (ok, state, error) = SaveManager.StateFromDict(data);

        Assert.True(ok, error);
        Assert.NotNull(state);
        Assert.Equal(0, state!.Day);
        Assert.Empty(state.Resources);
        AssertTypingMetricDefaults(state.TypingMetrics);
    }

    [Fact]
    public void StateFromDict_MissingTypingMetrics_InitializesDefaults()
    {
        var data = new Dictionary<string, object> { ["version"] = 1 };

        var (ok, state, error) = SaveManager.StateFromDict(data);

        Assert.True(ok, error);
        Assert.NotNull(state);
        AssertTypingMetricDefaults(state!.TypingMetrics);
    }

    [Fact]
    public void StateFromDict_EmptyTypingMetrics_InitializesDefaults()
    {
        var data = new Dictionary<string, object>
        {
            ["version"] = 1,
            ["typing_metrics"] = new Dictionary<string, object>(),
        };

        var (ok, state, error) = SaveManager.StateFromDict(data);

        Assert.True(ok, error);
        Assert.NotNull(state);
        AssertTypingMetricDefaults(state!.TypingMetrics);
    }

    [Fact]
    public void StateFromDict_JTokenCollections_DeserializesComplexCollections()
    {
        var json = """
            {
              "version": 1,
              "structures": { "10": "tower" },
              "structure_levels": { "10": 3 },
              "resource_nodes": {
                "99": { "kind": "iron", "amount": 7, "active": true }
              },
              "tower_summon_ids": { "10": [3, 4, 5] },
              "faction_agreements": {
                "trade": ["guild_a"],
                "non_aggression": [],
                "alliance": [],
                "war": ["guild_b"]
              },
              "auto_tower": {
                "auto_build": true,
                "build_priority": "offense",
                "auto_upgrade": true,
                "auto_repair": false,
                "resource_reserve_percent": 50
              }
            }
            """;

        var data = ParseDict(json);
        var (ok, state, error) = SaveManager.StateFromDict(data);

        Assert.True(ok, error);
        Assert.NotNull(state);
        Assert.Equal("tower", state!.Structures[10]);
        Assert.Equal(3, state.StructureLevels[10]);
        Assert.Equal("iron", state.ResourceNodes[99]["kind"]);
        Assert.Equal(7, Convert.ToInt32(state.ResourceNodes[99]["amount"]));
        Assert.Equal(new List<int> { 3, 4, 5 }, state.TowerSummonIds[10]);
        Assert.Contains("guild_a", state.FactionAgreements["trade"]);
        Assert.Contains("guild_b", state.FactionAgreements["war"]);
        Assert.True(state.AutoTower.AutoBuild);
        Assert.Equal("offense", state.AutoTower.BuildPriority);
        Assert.True(state.AutoTower.AutoUpgrade);
        Assert.False(state.AutoTower.AutoRepair);
        Assert.Equal(50, state.AutoTower.ResourceReservePercent);
    }

    [Fact]
    public void StateToJson_And_StateFromJson_RoundTrip_PreservesComprehensiveState()
    {
        var state = CreatePopulatedState();

        var json = SaveManager.StateToJson(state);
        var (ok, loaded, error) = SaveManager.StateFromJson(json);

        Assert.True(ok, error);
        Assert.NotNull(loaded);

        Assert.Equal(state.Day, loaded!.Day);
        Assert.Equal(state.Phase, loaded.Phase);
        Assert.Equal(state.ApMax, loaded.ApMax);
        Assert.Equal(state.Ap, loaded.Ap);
        Assert.Equal(state.Hp, loaded.Hp);
        Assert.Equal(state.Threat, loaded.Threat);
        Assert.Equal(state.Resources["wood"], loaded.Resources["wood"]);
        Assert.Equal(state.Buildings["tower"], loaded.Buildings["tower"]);
        Assert.Equal(state.MapW, loaded.MapW);
        Assert.Equal(state.MapH, loaded.MapH);
        Assert.Equal(state.BasePos, loaded.BasePos);
        Assert.Equal(state.CursorPos, loaded.CursorPos);
        Assert.Equal(state.PlayerPos, loaded.PlayerPos);
        Assert.Equal(state.PlayerFacing, loaded.PlayerFacing);
        Assert.Equal(state.Terrain, loaded.Terrain);
        Assert.Equal(state.Structures[3], loaded.Structures[3]);
        Assert.Equal(state.StructureLevels[3], loaded.StructureLevels[3]);
        Assert.Contains(17, loaded.Discovered);
        Assert.Equal(state.NightPrompt, loaded.NightPrompt);
        Assert.Equal(state.NightSpawnRemaining, loaded.NightSpawnRemaining);
        Assert.Equal(state.NightWaveTotal, loaded.NightWaveTotal);
        Assert.Single(loaded.Enemies);
        Assert.Equal("raider", loaded.Enemies[0]["kind"]);
        Assert.Equal(state.EnemyNextId, loaded.EnemyNextId);
        Assert.Equal(state.LastPathOpen, loaded.LastPathOpen);
        Assert.Equal(state.RngSeed, loaded.RngSeed);
        Assert.Equal(state.RngState, loaded.RngState);
        Assert.Equal(state.LessonId, loaded.LessonId);
        Assert.Equal(2, Convert.ToInt32(loaded.ActivePois["ancient_ruins"]["tier"]));
        Assert.Equal(3, loaded.EventCooldowns["merchant"]);
        Assert.True(Convert.ToBoolean(loaded.EventFlags["wave_defender_done"]));
        Assert.Equal("raid", loaded.PendingEvent["kind"]);
        Assert.Single(loaded.ActiveBuffs);
        Assert.Equal("shield", loaded.ActiveBuffs[0]["type"]);
        Assert.Equal(state.Gold, loaded.Gold);
        Assert.Equal(state.PurchasedKingdomUpgrades, loaded.PurchasedKingdomUpgrades);
        Assert.Equal(state.PurchasedUnitUpgrades, loaded.PurchasedUnitUpgrades);
        Assert.True(loaded.CompletedQuests.SetEquals(state.CompletedQuests));
        Assert.True(loaded.BossesDefeated.SetEquals(state.BossesDefeated));
        Assert.True(loaded.Milestones.SetEquals(state.Milestones));
        Assert.True(loaded.UnlockedSkills.SetEquals(state.UnlockedSkills));
        Assert.Equal(state.SkillPoints, loaded.SkillPoints);
        Assert.Equal(state.EnemiesDefeated, loaded.EnemiesDefeated);
        Assert.Equal(state.MaxComboEver, loaded.MaxComboEver);
        Assert.Equal(state.WavesSurvived, loaded.WavesSurvived);
        Assert.Equal(state.ActiveTitle, loaded.ActiveTitle);
        Assert.Equal(state.Inventory["potion"], loaded.Inventory["potion"]);
        Assert.Equal(state.EquippedItems["weapon"], loaded.EquippedItems["weapon"]);
        Assert.Equal(state.Workers[1], loaded.Workers[1]);
        Assert.Equal(state.WorkerAssignments[1], loaded.WorkerAssignments[1]);
        Assert.Equal(state.WorkerCount, loaded.WorkerCount);
        Assert.Equal(state.TotalWorkers, loaded.TotalWorkers);
        Assert.Equal(state.MaxWorkers, loaded.MaxWorkers);
        Assert.Equal(state.WorkerUpkeep, loaded.WorkerUpkeep);
        Assert.Single(loaded.Citizens);
        Assert.Equal("Ada", loaded.Citizens[0]["name"]);
        Assert.Equal(state.ActiveResearch, loaded.ActiveResearch);
        Assert.Equal(state.ResearchProgress, loaded.ResearchProgress);
        Assert.Equal(state.CompletedResearch, loaded.CompletedResearch);
        Assert.Equal(state.TradeRates["wood_to_stone"], loaded.TradeRates["wood_to_stone"], 3);
        Assert.Equal(state.LastTradeDay, loaded.LastTradeDay);
        Assert.Equal(state.FactionRelations["guild"], loaded.FactionRelations["guild"]);
        Assert.Contains("guild", loaded.FactionAgreements["trade"]);
        Assert.Equal("offer_alliance", loaded.PendingDiplomacy["guild"]["proposal"]);
        Assert.Equal(state.SpeedMultiplier, loaded.SpeedMultiplier, 3);
        Assert.Equal(state.PracticeMode, loaded.PracticeMode);
        Assert.Equal(state.TimeOfDay, loaded.TimeOfDay, 3);
        Assert.Equal(state.ActivityMode, loaded.ActivityMode);
        Assert.Equal(state.ThreatLevel, loaded.ThreatLevel, 3);
        Assert.Equal(state.WaveCooldown, loaded.WaveCooldown, 3);
        Assert.Equal(state.WorldTickAccum, loaded.WorldTickAccum, 3);
        Assert.Equal(state.ThreatDecayAccum, loaded.ThreatDecayAccum, 3);
        Assert.Single(loaded.RoamingEnemies);
        Assert.Single(loaded.RoamingResources);
        Assert.Single(loaded.Npcs);
        Assert.Single(loaded.EncounterEnemies);
        Assert.Single(loaded.ActiveExpeditions);
        Assert.Equal(state.ExpeditionNextId, loaded.ExpeditionNextId);
        Assert.Single(loaded.ExpeditionHistory);
        Assert.Equal("ore", loaded.ResourceNodes[42]["kind"]);
        Assert.Equal(5, loaded.HarvestedNodes["ore_node"]);
        Assert.Single(loaded.LootPending);
        Assert.Equal(state.LastLootQuality, loaded.LastLootQuality, 3);
        Assert.Equal(state.PerfectKills, loaded.PerfectKills);
        Assert.Equal("arrow", loaded.TowerStates[3]["kind"]);
        Assert.Single(loaded.ActiveSynergies);
        Assert.Single(loaded.SummonedUnits);
        Assert.Equal(state.SummonedNextId, loaded.SummonedNextId);
        Assert.Single(loaded.ActiveTraps);
        Assert.Equal(state.TowerCharge[3], loaded.TowerCharge[3]);
        Assert.Equal(state.TowerCooldowns[3], loaded.TowerCooldowns[3]);
        Assert.Equal(state.TowerSummonIds[3], loaded.TowerSummonIds[3]);
        Assert.True(loaded.AutoTower.AutoBuild);
        Assert.Equal(state.AutoTower.BuildPriority, loaded.AutoTower.BuildPriority);
        Assert.True(loaded.AutoTower.AutoUpgrade);
        Assert.False(loaded.AutoTower.AutoRepair);
        Assert.Equal(state.AutoTower.ResourceReservePercent, loaded.AutoTower.ResourceReservePercent);
        Assert.Equal(state.TargetingMode, loaded.TargetingMode);
        Assert.Equal(1024, Convert.ToInt32(loaded.TypingMetrics["battle_chars_typed"]));
        Assert.Equal(9876543210L, Convert.ToInt64(loaded.TypingMetrics["battle_start_msec"]));
        Assert.Equal(state.ArrowRainTimer, loaded.ArrowRainTimer, 3);
        Assert.Equal(state.HeroId, loaded.HeroId);
        Assert.Equal(state.HeroAbilityCooldown, loaded.HeroAbilityCooldown, 3);
        Assert.Single(loaded.HeroActiveEffects);
        Assert.Equal(state.EquippedTitle, loaded.EquippedTitle);
        Assert.Equal(state.UnlockedTitles, loaded.UnlockedTitles);
        Assert.Equal(state.UnlockedBadges, loaded.UnlockedBadges);
        Assert.True(loaded.CompletedDailyChallenges.SetEquals(state.CompletedDailyChallenges));
        Assert.Equal(state.DailyChallengeDate, loaded.DailyChallengeDate);
        Assert.Equal(state.PerfectNightsToday, loaded.PerfectNightsToday);
        Assert.Equal(state.NoDamageNightsToday, loaded.NoDamageNightsToday);
        Assert.Equal(state.FastestNightSeconds, loaded.FastestNightSeconds);
        Assert.Equal(state.VictoryAchieved, loaded.VictoryAchieved);
        Assert.Equal(state.VictoryChecked, loaded.VictoryChecked);
        Assert.Equal(state.PeakGold, loaded.PeakGold);
        Assert.Equal(state.StoryCompleted, loaded.StoryCompleted);
        Assert.Equal(state.CurrentAct, loaded.CurrentAct);
    }

    [Fact]
    public void SaveToFile_And_LoadFromFile_RoundTrip()
    {
        var state = CreatePopulatedState();
        var path = NewTempFilePath();

        try
        {
            Assert.True(SaveManager.SaveToFile(state, path));

            var (ok, loaded, error) = SaveManager.LoadFromFile(path);
            Assert.True(ok, error);
            Assert.NotNull(loaded);
            Assert.Equal(state.Day, loaded!.Day);
            Assert.Equal(state.Gold, loaded.Gold);
            Assert.Equal(state.HeroId, loaded.HeroId);
            Assert.Equal(state.CurrentAct, loaded.CurrentAct);
        }
        finally
        {
            if (File.Exists(path))
            {
                File.Delete(path);
            }
        }
    }

    [Fact]
    public void SaveToFile_DirectoryPath_ReturnsFalse()
    {
        var success = SaveManager.SaveToFile(new GameState(), Path.GetTempPath());
        Assert.False(success);
    }

    [Fact]
    public void LoadFromFile_MissingFile_ReturnsNotFoundError()
    {
        var path = NewTempFilePath();
        if (File.Exists(path))
        {
            File.Delete(path);
        }

        var (ok, state, error) = SaveManager.LoadFromFile(path);

        Assert.False(ok);
        Assert.Null(state);
        Assert.Equal("Save file not found.", error);
    }

    [Fact]
    public void LoadFromFile_InvalidJson_ReturnsParseError()
    {
        var path = NewTempFilePath();

        try
        {
            File.WriteAllText(path, "{ invalid");
            var (ok, state, error) = SaveManager.LoadFromFile(path);

            Assert.False(ok);
            Assert.Null(state);
            Assert.NotNull(error);
            Assert.Contains("JSON parse error", error!, StringComparison.Ordinal);
        }
        finally
        {
            if (File.Exists(path))
            {
                File.Delete(path);
            }
        }
    }

    private static Dictionary<string, object> ParseDict(string json)
    {
        return JsonConvert.DeserializeObject<Dictionary<string, object>>(json)
            ?? throw new InvalidOperationException("Failed to deserialize test json to dictionary.");
    }

    private static string NewTempFilePath()
    {
        return Path.Combine(Path.GetTempPath(), $"keyboard-defense-save-{Guid.NewGuid():N}.json");
    }

    private static void AssertTypingMetricDefaults(Dictionary<string, object> typingMetrics)
    {
        Assert.Equal(0, Convert.ToInt32(typingMetrics["battle_chars_typed"]));
        Assert.Equal(0, Convert.ToInt32(typingMetrics["battle_words_typed"]));
        Assert.Equal(0L, Convert.ToInt64(typingMetrics["battle_start_msec"]));
        Assert.Equal(0, Convert.ToInt32(typingMetrics["battle_errors"]));
        Assert.Equal(0, Convert.ToInt32(typingMetrics["perfect_word_streak"]));
        Assert.Equal(0, Convert.ToInt32(typingMetrics["current_word_errors"]));
        Assert.Empty(Assert.IsType<List<object>>(typingMetrics["rolling_window_chars"]));
        Assert.Empty(Assert.IsAssignableFrom<Dictionary<string, object>>(typingMetrics["unique_letters_window"]));
    }

    private static GameState CreatePopulatedState()
    {
        var state = new GameState
        {
            Day = 42,
            Phase = "night",
            ApMax = 7,
            Ap = 4,
            Hp = 18,
            Threat = 9,
            MapW = 12,
            MapH = 10,
            BasePos = new GridPoint(2, 3),
            CursorPos = new GridPoint(4, 5),
            PlayerPos = new GridPoint(6, 7),
            PlayerFacing = "left",
            NightPrompt = "defend",
            NightSpawnRemaining = 5,
            NightWaveTotal = 13,
            EnemyNextId = 99,
            LastPathOpen = false,
            RngSeed = "seed-123",
            RngState = 123456789L,
            LessonId = "lesson_x",
            Gold = 321,
            SkillPoints = 8,
            EnemiesDefeated = 77,
            MaxComboEver = 12,
            WavesSurvived = 19,
            ActiveTitle = "Champion",
            WorkerCount = 5,
            TotalWorkers = 9,
            MaxWorkers = 20,
            WorkerUpkeep = 2,
            ActiveResearch = "advanced_tools",
            ResearchProgress = 44,
            LastTradeDay = 41,
            SpeedMultiplier = 1.75f,
            PracticeMode = true,
            TimeOfDay = 0.9f,
            ActivityMode = "combat",
            ThreatLevel = 0.42f,
            WaveCooldown = 2.5f,
            WorldTickAccum = 1.2f,
            ThreatDecayAccum = 0.35f,
            ExpeditionNextId = 6,
            LastLootQuality = 1.8f,
            PerfectKills = 11,
            SummonedNextId = 55,
            TargetingMode = "strongest",
            ArrowRainTimer = 3.25f,
            HeroId = "ranger",
            HeroAbilityCooldown = 1.25f,
            EquippedTitle = "Defender",
            DailyChallengeDate = "2026-02-25",
            PerfectNightsToday = 2,
            NoDamageNightsToday = 1,
            FastestNightSeconds = 37,
            VictoryChecked = true,
            PeakGold = 500,
            StoryCompleted = true,
            CurrentAct = 4,
        };

        state.Resources = new Dictionary<string, int> { ["wood"] = 25, ["stone"] = 19, ["food"] = 12 };
        state.Buildings = new Dictionary<string, int> { ["tower"] = 2, ["farm"] = 1 };
        state.Terrain = new List<string> { "plains", "road", "forest" };
        state.Structures = new Dictionary<int, string> { [3] = "tower" };
        state.StructureLevels = new Dictionary<int, int> { [3] = 2 };
        state.Discovered = new HashSet<int> { 1, 17, 33 };
        state.Enemies = new List<Dictionary<string, object>>
        {
            new() { ["id"] = 1, ["kind"] = "raider", ["hp"] = 9, ["elite"] = true },
        };
        state.ActivePois = new Dictionary<string, Dictionary<string, object>>
        {
            ["ancient_ruins"] = new() { ["tier"] = 2, ["active"] = true },
        };
        state.EventCooldowns = new Dictionary<string, int> { ["merchant"] = 3 };
        state.EventFlags = new Dictionary<string, object> { ["wave_defender_done"] = true };
        state.PendingEvent = new Dictionary<string, object> { ["kind"] = "raid", ["difficulty"] = 4 };
        state.ActiveBuffs = new List<Dictionary<string, object>>
        {
            new() { ["type"] = "shield", ["duration"] = 5 },
        };
        state.PurchasedKingdomUpgrades = new List<string> { "double_harvest" };
        state.PurchasedUnitUpgrades = new List<string> { "quick_reload" };
        state.CompletedQuests = new HashSet<string> { "wave_defender" };
        state.BossesDefeated = new HashSet<string> { "alpha_wyrm" };
        state.Milestones = new HashSet<string> { "day_30" };
        state.UnlockedSkills = new HashSet<string> { "focus_fire" };
        state.Inventory = new Dictionary<string, int> { ["potion"] = 4 };
        state.EquippedItems = new Dictionary<string, string> { ["weapon"] = "oak_staff" };
        state.Workers = new Dictionary<int, int> { [1] = 1 };
        state.WorkerAssignments = new Dictionary<int, int> { [1] = 3 };
        state.Citizens = new List<Dictionary<string, object>>
        {
            new() { ["name"] = "Ada", ["profession"] = "smith" },
        };
        state.CompletedResearch = new List<string> { "basic_tools", "alchemy_1" };
        state.TradeRates = new Dictionary<string, double> { ["wood_to_stone"] = 2.25 };
        state.FactionRelations = new Dictionary<string, int> { ["guild"] = 55 };
        state.FactionAgreements = new Dictionary<string, List<string>>
        {
            ["trade"] = new List<string> { "guild" },
            ["non_aggression"] = new List<string>(),
            ["alliance"] = new List<string>(),
            ["war"] = new List<string>(),
        };
        state.PendingDiplomacy = new Dictionary<string, Dictionary<string, object>>
        {
            ["guild"] = new() { ["proposal"] = "offer_alliance", ["ttl"] = 2 },
        };
        state.RoamingEnemies = new List<Dictionary<string, object>>
        {
            new() { ["kind"] = "wolf", ["x"] = 5, ["y"] = 2 },
        };
        state.RoamingResources = new List<Dictionary<string, object>>
        {
            new() { ["kind"] = "herb", ["x"] = 7, ["y"] = 6 },
        };
        state.Npcs = new List<Dictionary<string, object>>
        {
            new() { ["id"] = "merchant_npc", ["x"] = 8, ["y"] = 8 },
        };
        state.EncounterEnemies = new List<Dictionary<string, object>>
        {
            new() { ["kind"] = "bandit", ["count"] = 2 },
        };
        state.ActiveExpeditions = new List<Dictionary<string, object>>
        {
            new() { ["id"] = 5, ["status"] = "active" },
        };
        state.ExpeditionHistory = new List<Dictionary<string, object>>
        {
            new() { ["id"] = 2, ["status"] = "completed" },
        };
        state.ResourceNodes = new Dictionary<int, Dictionary<string, object>>
        {
            [42] = new() { ["kind"] = "ore", ["amount"] = 7, ["active"] = true },
        };
        state.HarvestedNodes = new Dictionary<string, int> { ["ore_node"] = 5 };
        state.LootPending = new List<Dictionary<string, object>>
        {
            new() { ["item"] = "ruby", ["qty"] = 1 },
        };
        state.TowerStates = new Dictionary<int, Dictionary<string, object>>
        {
            [3] = new() { ["kind"] = "arrow", ["level"] = 2 },
        };
        state.ActiveSynergies = new List<Dictionary<string, object>>
        {
            new() { ["name"] = "crossfire", ["active"] = true },
        };
        state.SummonedUnits = new List<Dictionary<string, object>>
        {
            new() { ["id"] = 10, ["kind"] = "golem" },
        };
        state.ActiveTraps = new List<Dictionary<string, object>>
        {
            new() { ["type"] = "spike", ["charges"] = 2 },
        };
        state.TowerCharge = new Dictionary<int, int> { [3] = 4 };
        state.TowerCooldowns = new Dictionary<int, int> { [3] = 1 };
        state.TowerSummonIds = new Dictionary<int, List<int>> { [3] = new List<int> { 10, 11 } };
        state.AutoTower = new AutoTowerSettings
        {
            AutoBuild = true,
            BuildPriority = "offense",
            AutoUpgrade = true,
            AutoRepair = false,
            ResourceReservePercent = 50,
        };
        state.TypingMetrics = new Dictionary<string, object>
        {
            ["battle_chars_typed"] = 1024,
            ["battle_words_typed"] = 128,
            ["battle_start_msec"] = 9876543210L,
            ["battle_errors"] = 7,
            ["rolling_window_chars"] = new List<object> { 22, 23, 24 },
            ["unique_letters_window"] = new Dictionary<string, object> { ["a"] = 3, ["s"] = 2 },
            ["perfect_word_streak"] = 14,
            ["current_word_errors"] = 1,
        };
        state.HeroActiveEffects = new List<Dictionary<string, object>>
        {
            new() { ["name"] = "focus", ["duration"] = 2.5f },
        };
        state.UnlockedTitles = new List<string> { "Defender", "Commander" };
        state.UnlockedBadges = new List<string> { "first_blood" };
        state.CompletedDailyChallenges = new HashSet<string> { "no_miss_night" };
        state.VictoryAchieved = new List<string> { "story_clear" };

        return state;
    }
}
