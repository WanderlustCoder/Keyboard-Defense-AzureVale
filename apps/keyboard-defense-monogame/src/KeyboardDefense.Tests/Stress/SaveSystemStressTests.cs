using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace KeyboardDefense.Tests.Stress;

public sealed class SaveSystemStressTests : IDisposable
{
    private static readonly HashSet<string> SetLikeArrayPaths = new(StringComparer.Ordinal)
    {
        "/discovered",
        "/completed_quests",
        "/bosses_defeated",
        "/milestones",
        "/unlocked_skills",
        "/completed_daily_challenges",
    };

    private readonly string _tempDirectory;

    public SaveSystemStressTests()
    {
        _tempDirectory = Path.Combine(
            Path.GetTempPath(),
            $"keyboard-defense-save-system-stress-{Guid.NewGuid():N}");
        Directory.CreateDirectory(_tempDirectory);
    }

    [Fact]
    public void RapidSaveLoadCycle_100Iterations_PreservesAllData()
    {
        var baseline = CreateStressState("rapid_cycle", enemyCount: 96, extraBuildingCount: 140);
        string baselineSnapshot = BuildCanonicalSnapshot(baseline);
        string savePath = GetSavePath("rapid_cycle.json");

        var current = baseline;
        for (int i = 0; i < 100; i++)
        {
            Assert.True(SaveManager.SaveToFile(current, savePath), $"Save failed at iteration {i + 1}.");

            var (ok, loaded, error) = SaveManager.LoadFromFile(savePath);
            Assert.True(ok, $"Load failed at iteration {i + 1}: {error}");
            Assert.NotNull(loaded);

            string loadedSnapshot = BuildCanonicalSnapshot(loaded!);
            Assert.Equal(baselineSnapshot, loadedSnapshot);
            current = loaded!;
        }
    }

    [Fact]
    public void LargeGameState_ThousandEnemiesFiveHundredBuildings_SerializesUnderOneSecond()
    {
        var state = CreateLargeState();

        // Warm up to avoid one-time JIT cost skewing the timing assertion.
        _ = SaveManager.StateToJson(new GameState());

        var stopwatch = Stopwatch.StartNew();
        string json = SaveManager.StateToJson(state);
        stopwatch.Stop();

        Assert.False(string.IsNullOrWhiteSpace(json));
        Assert.True(
            stopwatch.Elapsed < TimeSpan.FromSeconds(1),
            $"Serialization took {stopwatch.Elapsed.TotalMilliseconds:F2}ms, expected under 1000ms.");
    }

    [Fact]
    public void LargeGameState_ThousandEnemiesFiveHundredBuildings_RoundTripPreservesCountsAndCaps()
    {
        var state = CreateLargeState();
        string savePath = GetSavePath("large_state_round_trip.json");

        Assert.True(SaveManager.SaveToFile(state, savePath));

        var (ok, loaded, error) = SaveManager.LoadFromFile(savePath);
        Assert.True(ok, error);
        Assert.NotNull(loaded);

        Assert.Equal(1000, loaded!.Enemies.Count);
        Assert.Equal(500, loaded.Buildings.Count);
        Assert.Equal(int.MaxValue, loaded.Resources["wood"]);
        Assert.Equal(int.MaxValue, loaded.Resources["stone"]);
        Assert.Equal(int.MaxValue, loaded.Resources["food"]);
        Assert.Equal(BuildCanonicalSnapshot(state), BuildCanonicalSnapshot(loaded));
    }

    [Fact]
    public async Task ConcurrentSaveAttempts_SingleSharedSlot_DoesNotCorruptData()
    {
        const int writerCount = 20;
        string savePath = GetSavePath("shared_slot.json");

        var states = Enumerable.Range(0, writerCount)
            .Select(i =>
            {
                var state = CreateStressState($"shared_{i}", enemyCount: 24, extraBuildingCount: 40);
                state.Day = 500 + i;
                state.Gold = 50_000 + i;
                state.RngSeed = $"shared_writer_seed_{i}";
                return state;
            })
            .ToArray();

        var gate = new ManualResetEventSlim(initialState: false);
        Task<(GameState State, bool Saved)>[] tasks = states.Select(state => Task.Run(() =>
        {
            gate.Wait();
            bool saved = SaveManager.SaveToFile(state, savePath);
            return (state, saved);
        })).ToArray();

        gate.Set();
        var results = await Task.WhenAll(tasks);

        var successfulStates = results.Where(r => r.Saved).Select(r => r.State).ToArray();
        Assert.NotEmpty(successfulStates);

        var (ok, loaded, error) = SaveManager.LoadFromFile(savePath);
        Assert.True(ok, error);
        Assert.NotNull(loaded);

        string loadedSnapshot = BuildCanonicalSnapshot(loaded!);
        Assert.Contains(successfulStates, state => BuildCanonicalSnapshot(state) == loadedSnapshot);
    }

    [Fact]
    public async Task ConcurrentSaveAttempts_MultipleFiles_EachFileRemainsReadable()
    {
        const int saveCount = 24;
        var jobs = Enumerable.Range(0, saveCount)
            .Select(i => new
            {
                State = CreateStressState($"parallel_{i}", enemyCount: 20, extraBuildingCount: 30),
                Path = GetSavePath($"parallel_{i:D2}.json"),
            })
            .ToArray();

        await Task.WhenAll(jobs.Select(job => Task.Run(() =>
        {
            Assert.True(SaveManager.SaveToFile(job.State, job.Path));
        })));

        foreach (var job in jobs)
        {
            var (ok, loaded, error) = SaveManager.LoadFromFile(job.Path);
            Assert.True(ok, error);
            Assert.NotNull(loaded);
            Assert.Equal(BuildCanonicalSnapshot(job.State), BuildCanonicalSnapshot(loaded!));
        }
    }

    [Fact]
    public void LoadFromFile_CorruptedJson_ReturnsMeaningfulParseError()
    {
        string savePath = GetSavePath("corrupted_payload.json");
        File.WriteAllText(savePath, "{\"version\":1,\"day\":9,\"phase\":\"night\"");

        var (ok, state, error) = SaveManager.LoadFromFile(savePath);

        Assert.False(ok);
        Assert.Null(state);
        Assert.False(string.IsNullOrWhiteSpace(error));
        Assert.Contains("JSON parse error", error!, StringComparison.Ordinal);
        Assert.True(
            error!.Contains("Unexpected", StringComparison.OrdinalIgnoreCase) ||
            error.Contains("line", StringComparison.OrdinalIgnoreCase),
            $"Expected parser details in error, got: {error}");
    }

    [Fact]
    public void StateFromJson_CorruptedJson_ReturnsMeaningfulParseError()
    {
        const string corrupted = "not-json\u0001\u0002";

        var (ok, state, error) = SaveManager.StateFromJson(corrupted);

        Assert.False(ok);
        Assert.Null(state);
        Assert.False(string.IsNullOrWhiteSpace(error));
        Assert.Contains("JSON parse error", error!, StringComparison.Ordinal);
        Assert.True(
            error!.Contains("line", StringComparison.OrdinalIgnoreCase) ||
            error.Contains("position", StringComparison.OrdinalIgnoreCase),
            $"Expected line/position context in error, got: {error}");
    }

    [Fact]
    public void LoadFromFile_MissingFields_LoadsWithDefaults()
    {
        string savePath = GetSavePath("missing_fields.json");
        File.WriteAllText(savePath, "{\"version\":1,\"day\":13,\"phase\":\"night\"}");

        var (ok, state, error) = SaveManager.LoadFromFile(savePath);

        Assert.True(ok, error);
        Assert.NotNull(state);

        Assert.Equal(13, state!.Day);
        Assert.Equal("night", state.Phase);
        Assert.Equal(64, state.MapW);
        Assert.Equal(64, state.MapH);
        Assert.Equal(new GridPoint(32, 32), state.BasePos);
        Assert.Equal(state.BasePos, state.CursorPos);
        Assert.Equal(state.BasePos, state.PlayerPos);
        Assert.Equal("default", state.RngSeed);
        Assert.Equal("exploration", state.ActivityMode);
        Assert.Equal("nearest", state.TargetingMode);
        Assert.Equal("balanced", state.AutoTower.BuildPriority);
        Assert.True(state.AutoTower.AutoRepair);
        Assert.Empty(state.Resources);
        Assert.Empty(state.Buildings);
        Assert.Empty(state.Enemies);
        Assert.NotEmpty(state.TypingMetrics);
    }

    [Fact]
    public void RoundTrip_ExtremelyLongStringValues_ArePreservedExactly()
    {
        string veryLong = new string('x', 200_000);
        var state = CreateStressState("long_strings", enemyCount: 3, extraBuildingCount: 5);

        state.NightPrompt = veryLong;
        state.RngSeed = $"{veryLong}_seed";
        state.HeroId = $"{veryLong}_hero";
        state.EquippedTitle = $"{veryLong}_title";
        state.EquippedItems["weapon"] = $"{veryLong}_weapon";
        state.PendingEvent["lore_blob"] = veryLong;
        state.Enemies[0]["word"] = veryLong;

        string savePath = GetSavePath("long_strings.json");
        Assert.True(SaveManager.SaveToFile(state, savePath));

        var (ok, loaded, error) = SaveManager.LoadFromFile(savePath);
        Assert.True(ok, error);
        Assert.NotNull(loaded);

        Assert.Equal(state.NightPrompt, loaded!.NightPrompt);
        Assert.Equal(state.RngSeed, loaded.RngSeed);
        Assert.Equal(state.HeroId, loaded.HeroId);
        Assert.Equal(state.EquippedTitle, loaded.EquippedTitle);
        Assert.Equal(state.EquippedItems["weapon"], loaded.EquippedItems["weapon"]);
        Assert.Equal(state.PendingEvent["lore_blob"]?.ToString(), loaded.PendingEvent["lore_blob"]?.ToString());
        Assert.Equal(state.Enemies[0]["word"]?.ToString(), loaded.Enemies[0]["word"]?.ToString());
        Assert.Equal(BuildCanonicalSnapshot(state), BuildCanonicalSnapshot(loaded));
    }

    public void Dispose()
    {
        if (!Directory.Exists(_tempDirectory))
            return;

        try
        {
            Directory.Delete(_tempDirectory, recursive: true);
        }
        catch (IOException)
        {
            // Best-effort cleanup for temp files.
        }
        catch (UnauthorizedAccessException)
        {
            // Best-effort cleanup for temp files.
        }
    }

    private string GetSavePath(string fileName)
        => Path.Combine(_tempDirectory, fileName);

    private static GameState CreateLargeState()
    {
        var state = CreateStressState("large", enemyCount: 1000, extraBuildingCount: 500);

        state.Resources["wood"] = int.MaxValue;
        state.Resources["stone"] = int.MaxValue;
        state.Resources["food"] = int.MaxValue;

        state.Buildings.Clear();
        for (int i = 0; i < 500; i++)
            state.Buildings[$"mega_building_{i:D3}"] = int.MaxValue - i;

        return state;
    }

    private static GameState CreateStressState(string id, int enemyCount, int extraBuildingCount)
    {
        var state = DefaultState.Create($"save_system_{id}", placeStartingTowers: true);

        state.Day = 42;
        state.Phase = "night";
        state.ApMax = 9;
        state.Ap = 6;
        state.Hp = 27;
        state.Threat = 14;
        state.Gold = 12_345;
        state.NightPrompt = "defend the gate";
        state.NightSpawnRemaining = enemyCount;
        state.NightWaveTotal = enemyCount + 4;
        state.EnemyNextId = 10_000;
        state.LastPathOpen = false;
        state.RngSeed = $"seed_{id}";
        state.RngState = 9_876_543_210;
        state.LessonId = "advanced_alpha";
        state.SkillPoints = 17;
        state.EnemiesDefeated = 1_234;
        state.MaxComboEver = 88;
        state.WavesSurvived = 63;
        state.ActiveTitle = "Archivist";

        state.WorkerCount = 15;
        state.TotalWorkers = 18;
        state.MaxWorkers = 30;
        state.WorkerUpkeep = 4;
        state.ActiveResearch = "forged_walls";
        state.ResearchProgress = 92;
        state.LastTradeDay = 41;

        state.SpeedMultiplier = 1.25f;
        state.PracticeMode = false;
        state.TimeOfDay = 0.82f;
        state.ActivityMode = "combat";
        state.ThreatLevel = 0.73f;
        state.WaveCooldown = 1.5f;
        state.WorldTickAccum = 3.25f;
        state.ThreatDecayAccum = 0.42f;

        state.ExpeditionNextId = 4;
        state.LastLootQuality = 1.7f;
        state.PerfectKills = 32;
        state.SummonedNextId = 500;
        state.TargetingMode = "weakest";

        state.HeroId = "warden";
        state.HeroAbilityCooldown = 6.2f;
        state.EquippedTitle = "Guardian";

        state.DailyChallengeDate = "2026-02-25";
        state.PerfectNightsToday = 2;
        state.NoDamageNightsToday = 1;
        state.FastestNightSeconds = 45;

        state.VictoryChecked = true;
        state.PeakGold = 99_999;
        state.StoryCompleted = false;
        state.CurrentAct = 3;

        state.Resources["wood"] = 8_000;
        state.Resources["stone"] = 6_000;
        state.Resources["food"] = 7_500;
        state.Resources["iron"] = 900;
        state.Resources["mana"] = 1_200;

        state.Buildings["tower"] = 25;
        state.Buildings["wall"] = 40;
        state.Buildings["market"] = 7;
        for (int i = 0; i < extraBuildingCount; i++)
            state.Buildings[$"building_{i:D3}"] = i + 1;

        state.Structures.Clear();
        state.StructureLevels.Clear();
        for (int i = 0; i < 120; i++)
        {
            state.Structures[1000 + i] = i % 2 == 0 ? "tower" : "wall";
            state.StructureLevels[1000 + i] = 1 + (i % 5);
        }

        state.Discovered = new HashSet<int> { 1, 17, 23, 88, 144 };

        state.EventCooldowns["merchant"] = 3;
        state.EventCooldowns["raid"] = 6;
        state.EventFlags["boss_warning"] = true;
        state.EventFlags["storm_active"] = false;
        state.ActivePois = new Dictionary<string, Dictionary<string, object>>
        {
            ["outpost"] = new()
            {
                ["zone"] = "frontier",
                ["discovered_day"] = 1,
                ["x"] = 12,
                ["y"] = 7,
                ["event_id"] = "poi_outpost",
            },
            ["shrine"] = new()
            {
                ["zone"] = "safe",
                ["discovered_day"] = 1,
                ["x"] = 8,
                ["y"] = 14,
                ["event_id"] = "poi_shrine",
            },
        };
        state.PendingEvent["kind"] = "raid";
        state.PendingEvent["difficulty"] = 8;
        state.ActiveBuffs.Add(new Dictionary<string, object>
        {
            ["type"] = "shield",
            ["duration"] = 5,
            ["stacks"] = 2,
        });

        state.PurchasedKingdomUpgrades = Enumerable.Range(0, 60)
            .Select(i => $"kingdom_upgrade_{i:D3}")
            .ToList();
        state.PurchasedUnitUpgrades = Enumerable.Range(0, 60)
            .Select(i => $"unit_upgrade_{i:D3}")
            .ToList();

        state.CompletedQuests = Enumerable.Range(0, 70)
            .Select(i => $"quest_{i:D3}")
            .ToHashSet(StringComparer.Ordinal);
        state.BossesDefeated = Enumerable.Range(0, 20)
            .Select(i => $"boss_{i:D3}")
            .ToHashSet(StringComparer.Ordinal);
        state.Milestones = Enumerable.Range(0, 40)
            .Select(i => $"milestone_{i:D3}")
            .ToHashSet(StringComparer.Ordinal);
        state.UnlockedSkills = Enumerable.Range(0, 35)
            .Select(i => $"skill_{i:D3}")
            .ToHashSet(StringComparer.Ordinal);
        state.CompletedDailyChallenges = Enumerable.Range(0, 10)
            .Select(i => $"daily_{i:D3}")
            .ToHashSet(StringComparer.Ordinal);

        state.Inventory.Clear();
        for (int i = 0; i < 200; i++)
            state.Inventory[$"item_{i:D4}"] = 5000 - i;

        state.EquippedItems["weapon"] = "blade_of_letters";
        state.EquippedItems["armor"] = "iron_ink_mail";
        state.EquippedItems["trinket"] = "glyph_stone";

        state.Workers.Clear();
        state.WorkerAssignments.Clear();
        for (int i = 0; i < 20; i++)
        {
            state.Workers[i] = i % 3;
            state.WorkerAssignments[i] = (i + 1) % 5;
        }

        state.Citizens.Add(new Dictionary<string, object> { ["name"] = "Ada", ["role"] = "smith" });
        state.Citizens.Add(new Dictionary<string, object> { ["name"] = "Lin", ["role"] = "scout" });

        state.CompletedResearch = Enumerable.Range(0, 25)
            .Select(i => $"research_{i:D3}")
            .ToList();
        state.TradeRates["wood_to_stone"] = 2.1;
        state.TradeRates["stone_to_gold"] = 0.9;
        state.FactionRelations["guild"] = 50;
        state.FactionRelations["nomads"] = -15;
        state.FactionAgreements["trade"].Add("guild");
        state.FactionAgreements["non_aggression"].Add("nomads");
        state.PendingDiplomacy["guild"] = new Dictionary<string, object>
        {
            ["proposal"] = "offer_alliance",
            ["ttl"] = 2,
        };

        state.Enemies.Clear();
        state.RoamingEnemies.Clear();
        for (int i = 0; i < enemyCount; i++)
        {
            state.Enemies.Add(new Dictionary<string, object>
            {
                ["id"] = 2000 + i,
                ["kind"] = "raider",
                ["hp"] = 10 + (i % 7),
                ["elite"] = (i % 11) == 0,
                ["word"] = $"enemy_word_{i:D4}",
            });

            state.RoamingEnemies.Add(new Dictionary<string, object>
            {
                ["kind"] = "wolf",
                ["x"] = i % 40,
                ["y"] = (i * 2) % 40,
            });
        }

        state.RoamingResources = new List<Dictionary<string, object>>
        {
            new() { ["kind"] = "herb", ["x"] = 5, ["y"] = 9 },
            new() { ["kind"] = "ore", ["x"] = 6, ["y"] = 3 },
        };
        state.Npcs = new List<Dictionary<string, object>>
        {
            new() { ["id"] = "merchant", ["x"] = 7, ["y"] = 7 },
            new() { ["id"] = "smith", ["x"] = 8, ["y"] = 4 },
        };
        state.EncounterEnemies = new List<Dictionary<string, object>>
        {
            new() { ["kind"] = "bandit", ["count"] = 4 },
        };

        state.ActiveExpeditions = new List<Dictionary<string, object>>
        {
            new() { ["id"] = 1, ["status"] = "active" },
        };
        state.ExpeditionHistory = new List<Dictionary<string, object>>
        {
            new() { ["id"] = 0, ["status"] = "completed" },
        };

        state.ResourceNodes.Clear();
        state.HarvestedNodes.Clear();
        for (int i = 0; i < 80; i++)
        {
            state.ResourceNodes[3000 + i] = new Dictionary<string, object>
            {
                ["kind"] = "ore",
                ["amount"] = 4 + (i % 3),
                ["active"] = (i % 2) == 0,
            };
            state.HarvestedNodes[$"node_{i:D3}"] = i;
        }

        state.LootPending = new List<Dictionary<string, object>>
        {
            new() { ["item"] = "ruby", ["qty"] = 1 },
            new() { ["item"] = "iron", ["qty"] = 3 },
        };

        state.TowerStates.Clear();
        state.TowerCharge.Clear();
        state.TowerCooldowns.Clear();
        state.TowerSummonIds.Clear();
        for (int i = 0; i < 36; i++)
        {
            int towerId = 400 + i;
            state.TowerStates[towerId] = new Dictionary<string, object>
            {
                ["kind"] = "arrow",
                ["level"] = 1 + (i % 4),
            };
            state.TowerCharge[towerId] = i % 5;
            state.TowerCooldowns[towerId] = i % 3;
            state.TowerSummonIds[towerId] = new List<int> { 9000 + i, 9100 + i };
        }

        state.ActiveSynergies = new List<Dictionary<string, object>>
        {
            new() { ["name"] = "crossfire", ["active"] = true },
        };
        state.SummonedUnits = new List<Dictionary<string, object>>
        {
            new() { ["id"] = 7001, ["kind"] = "golem" },
        };
        state.ActiveTraps = new List<Dictionary<string, object>>
        {
            new() { ["type"] = "spike", ["charges"] = 3 },
        };

        state.AutoTower.AutoBuild = true;
        state.AutoTower.AutoUpgrade = true;
        state.AutoTower.AutoRepair = true;
        state.AutoTower.BuildPriority = "offense";
        state.AutoTower.ResourceReservePercent = 30;

        state.TypingMetrics = new Dictionary<string, object>
        {
            ["battle_chars_typed"] = 4096,
            ["battle_words_typed"] = 512,
            ["battle_start_msec"] = 9_876_543_210L,
            ["battle_errors"] = 21,
            ["rolling_window_chars"] = new List<object> { 30, 31, 32, 33 },
            ["unique_letters_window"] = new Dictionary<string, object> { ["a"] = 4, ["s"] = 3 },
            ["perfect_word_streak"] = 17,
            ["current_word_errors"] = 2,
        };

        state.HeroActiveEffects = new List<Dictionary<string, object>>
        {
            new() { ["name"] = "focus", ["duration"] = 4 },
        };
        state.UnlockedTitles = new List<string> { "Guardian", "Strategist" };
        state.UnlockedBadges = new List<string> { "first_blood", "perfect_night" };
        state.VictoryAchieved = new List<string> { "story_clear" };

        return state;
    }

    private static string BuildCanonicalSnapshot(GameState state)
    {
        JToken raw = JToken.FromObject(SaveManager.StateToDict(state));
        JToken normalized = NormalizeToken(raw, path: string.Empty);
        return normalized.ToString(Formatting.None);
    }

    private static JToken NormalizeToken(JToken token, string path)
    {
        return token.Type switch
        {
            JTokenType.Object => NormalizeObject((JObject)token, path),
            JTokenType.Array => NormalizeArray((JArray)token, path),
            _ => token.DeepClone(),
        };
    }

    private static JObject NormalizeObject(JObject obj, string path)
    {
        var normalized = new JObject();
        foreach (var prop in obj.Properties().OrderBy(p => p.Name, StringComparer.Ordinal))
        {
            string childPath = $"{path}/{prop.Name}";
            normalized.Add(prop.Name, NormalizeToken(prop.Value, childPath));
        }

        return normalized;
    }

    private static JArray NormalizeArray(JArray arr, string path)
    {
        var items = arr
            .Select(item => NormalizeToken(item, path))
            .ToList();

        if (SetLikeArrayPaths.Contains(path))
        {
            items = items
                .OrderBy(item => item.ToString(Formatting.None), StringComparer.Ordinal)
                .ToList();
        }

        return new JArray(items);
    }
}
