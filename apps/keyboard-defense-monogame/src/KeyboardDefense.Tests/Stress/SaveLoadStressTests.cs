using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Stress;

public sealed class SaveLoadStressTests : IDisposable
{
    private readonly string _tempDirectory;

    public SaveLoadStressTests()
    {
        _tempDirectory = Path.Combine(
            Path.GetTempPath(),
            $"keyboard-defense-save-stress-{Guid.NewGuid():N}");
        Directory.CreateDirectory(_tempDirectory);
    }

    [Fact]
    public void SaveLoad_100RoundTrips_PreservesStateFidelity()
    {
        var baseline = CreateStressState("roundtrip");
        var current = baseline;
        string savePath = GetSavePath("roundtrip_100.json");

        for (int i = 0; i < 100; i++)
        {
            Assert.True(SaveManager.SaveToFile(current, savePath));

            var (ok, loaded, error) = SaveManager.LoadFromFile(savePath);
            Assert.True(ok, $"Round-trip {i + 1} failed: {error}");
            Assert.NotNull(loaded);

            AssertStateFidelity(baseline, loaded!);
            current = loaded!;
        }
    }

    [Fact]
    public void SaveLoad_MaxInventoryManyQuestsManyUpgrades_RoundTripsWithoutDataLoss()
    {
        var state = CreateStressState("max_payload");
        AddLargeProgressionPayload(
            state,
            inventoryCount: 3000,
            questCount: 2000,
            upgradeCount: 1500);

        string savePath = GetSavePath("max_payload.json");
        Assert.True(SaveManager.SaveToFile(state, savePath));

        var (ok, loaded, error) = SaveManager.LoadFromFile(savePath);
        Assert.True(ok, error);
        Assert.NotNull(loaded);

        Assert.Equal(state.Inventory.Count, loaded!.Inventory.Count);
        Assert.Equal(state.CompletedQuests.Count, loaded.CompletedQuests.Count);
        Assert.Equal(state.PurchasedKingdomUpgrades.Count, loaded.PurchasedKingdomUpgrades.Count);
        Assert.Equal(state.PurchasedUnitUpgrades.Count, loaded.PurchasedUnitUpgrades.Count);
        AssertStateFidelity(state, loaded);
    }

    [Fact]
    public void SaveLoad_HeavyState_FileSizeStaysUnderOneMegabyte()
    {
        var state = CreateStressState("size_budget", enemyCount: 250);
        AddLargeProgressionPayload(
            state,
            inventoryCount: 2500,
            questCount: 1500,
            upgradeCount: 1200);

        string savePath = GetSavePath("size_budget.json");
        Assert.True(SaveManager.SaveToFile(state, savePath));

        var fileInfo = new FileInfo(savePath);
        Assert.True(fileInfo.Exists);
        Assert.True(fileInfo.Length < 1_000_000, $"Save file too large: {fileInfo.Length} bytes");
    }

    [Fact]
    public void SaveLoad_CorruptedSaveData_ReturnsErrorAndDoesNotCrash()
    {
        var corruptedPayloads = new[]
        {
            ("truncated.json", "{\"version\":1,\"day\":5,\"phase\":\"night\""),
            ("garbage.json", "not-json\x01\x02\x03"),
        };

        foreach (var (fileName, payload) in corruptedPayloads)
        {
            string savePath = GetSavePath(fileName);
            File.WriteAllText(savePath, payload);

            var (ok, state, error) = SaveManager.LoadFromFile(savePath);
            Assert.False(ok);
            Assert.Null(state);
            Assert.False(string.IsNullOrWhiteSpace(error));
        }
    }

    [Fact]
    public async Task SaveLoad_ConcurrentSaveRequests_PreservePerFileIntegrity()
    {
        const int saveCount = 24;
        var jobs = Enumerable.Range(0, saveCount)
            .Select(i => new
            {
                State = CreateStressState($"concurrent_{i}", enemyCount: 20),
                Path = GetSavePath($"concurrent_{i:D2}.json"),
            })
            .ToArray();

        await Task.WhenAll(jobs.Select(job => Task.Run(() =>
        {
            Assert.True(SaveManager.SaveToFile(job.State, job.Path));

            var (ok, loaded, error) = SaveManager.LoadFromFile(job.Path);
            Assert.True(ok, error);
            Assert.NotNull(loaded);
            AssertStateFidelity(job.State, loaded!);
        })));
    }

    [Fact]
    public async Task SaveLoad_ConcurrentOverwritesSingleSlot_FinalSaveRemainsReadable()
    {
        const int writerCount = 16;
        string savePath = GetSavePath("shared_slot.json");
        var states = Enumerable.Range(0, writerCount)
            .Select(i =>
            {
                var state = CreateStressState($"shared_{i}", enemyCount: 10);
                state.Day = 100 + i;
                state.Gold = 5000 + i;
                state.RngSeed = $"shared_seed_{i}";
                return state;
            })
            .ToArray();

        bool[] saveResults = await Task.WhenAll(states.Select(state =>
            Task.Run(() => SaveManager.SaveToFile(state, savePath))));

        Assert.Contains(true, saveResults);

        var (ok, loaded, error) = SaveManager.LoadFromFile(savePath);
        Assert.True(ok, error);
        Assert.NotNull(loaded);

        var matchingState = states.FirstOrDefault(s =>
            string.Equals(s.RngSeed, loaded!.RngSeed, StringComparison.Ordinal));
        Assert.NotNull(matchingState);
        AssertStateFidelity(matchingState!, loaded!);
    }

    [Fact]
    public void SaveLoad_DuringCombatState_PreservesCombatProgress()
    {
        var state = CreateStressState("combat", enemyCount: 40);
        state.Phase = "night";
        state.ActivityMode = "combat";
        state.NightPrompt = "onslaught";
        state.NightSpawnRemaining = 12;
        state.NightWaveTotal = 52;
        state.TypingMetrics["battle_chars_typed"] = 1532;
        state.TypingMetrics["battle_words_typed"] = 227;
        state.TypingMetrics["battle_errors"] = 14;
        state.TypingMetrics["battle_start_msec"] = 123456789L;

        string savePath = GetSavePath("combat_state.json");
        Assert.True(SaveManager.SaveToFile(state, savePath));

        var (ok, loaded, error) = SaveManager.LoadFromFile(savePath);
        Assert.True(ok, error);
        Assert.NotNull(loaded);

        Assert.Equal("night", loaded!.Phase);
        Assert.Equal("combat", loaded.ActivityMode);
        Assert.Equal(40, loaded.Enemies.Count);
        Assert.Equal(1532, Convert.ToInt32(loaded.TypingMetrics["battle_chars_typed"]));
        Assert.Equal(227, Convert.ToInt32(loaded.TypingMetrics["battle_words_typed"]));
        AssertStateFidelity(state, loaded);
    }

    [Fact]
    public void SaveLoad_MultipleSlotsStress_RemainIndependent()
    {
        const int slotCount = 20;
        var slots = Enumerable.Range(1, slotCount)
            .Select(i => new
            {
                State = CreateStressState($"slot_{i}", enemyCount: 8),
                Path = GetSavePath($"slot_{i:D2}.json"),
            })
            .ToArray();

        for (int i = 0; i < slots.Length; i++)
        {
            slots[i].State.Day = i + 1;
            slots[i].State.Gold = 1000 + i * 100;
            slots[i].State.RngSeed = $"slot_seed_{i + 1}";
            Assert.True(SaveManager.SaveToFile(slots[i].State, slots[i].Path));
        }

        foreach (var slot in slots)
        {
            var (ok, loaded, error) = SaveManager.LoadFromFile(slot.Path);
            Assert.True(ok, error);
            Assert.NotNull(loaded);
            AssertStateFidelity(slot.State, loaded!);
        }
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
            // Temp cleanup should not fail tests.
        }
        catch (UnauthorizedAccessException)
        {
            // Temp cleanup should not fail tests.
        }
    }

    private string GetSavePath(string fileName)
        => Path.Combine(_tempDirectory, fileName);

    private static void AssertStateFidelity(GameState expected, GameState actual)
    {
        Assert.Equal(expected.Day, actual.Day);
        Assert.Equal(expected.Phase, actual.Phase);
        Assert.Equal(expected.ApMax, actual.ApMax);
        Assert.Equal(expected.Ap, actual.Ap);
        Assert.Equal(expected.Hp, actual.Hp);
        Assert.Equal(expected.Threat, actual.Threat);
        Assert.Equal(expected.Gold, actual.Gold);
        Assert.Equal(expected.MapW, actual.MapW);
        Assert.Equal(expected.MapH, actual.MapH);
        Assert.Equal(expected.BasePos, actual.BasePos);
        Assert.Equal(expected.CursorPos, actual.CursorPos);
        Assert.Equal(expected.PlayerPos, actual.PlayerPos);
        Assert.Equal(expected.PlayerFacing, actual.PlayerFacing);
        Assert.Equal(expected.NightPrompt, actual.NightPrompt);
        Assert.Equal(expected.NightSpawnRemaining, actual.NightSpawnRemaining);
        Assert.Equal(expected.NightWaveTotal, actual.NightWaveTotal);
        Assert.Equal(expected.EnemyNextId, actual.EnemyNextId);
        Assert.Equal(expected.RngSeed, actual.RngSeed);
        Assert.Equal(expected.RngState, actual.RngState);
        Assert.Equal(expected.LessonId, actual.LessonId);
        Assert.Equal(expected.ActivityMode, actual.ActivityMode);
        Assert.Equal(expected.TargetingMode, actual.TargetingMode);
        Assert.Equal(expected.HeroId, actual.HeroId);
        Assert.Equal(expected.EquippedTitle, actual.EquippedTitle);
        Assert.Equal(expected.CurrentAct, actual.CurrentAct);

        Assert.Equal(expected.SpeedMultiplier, actual.SpeedMultiplier, 3);
        Assert.Equal(expected.TimeOfDay, actual.TimeOfDay, 3);
        Assert.Equal(expected.ThreatLevel, actual.ThreatLevel, 3);
        Assert.Equal(expected.WaveCooldown, actual.WaveCooldown, 3);
        Assert.Equal(expected.WorldTickAccum, actual.WorldTickAccum, 3);
        Assert.Equal(expected.ThreatDecayAccum, actual.ThreatDecayAccum, 3);
        Assert.Equal(expected.LastLootQuality, actual.LastLootQuality, 3);
        Assert.Equal(expected.ArrowRainTimer, actual.ArrowRainTimer, 3);
        Assert.Equal(expected.HeroAbilityCooldown, actual.HeroAbilityCooldown, 3);

        AssertStringIntDictionaryEqual(expected.Resources, actual.Resources);
        AssertStringIntDictionaryEqual(expected.Buildings, actual.Buildings);
        AssertStringIntDictionaryEqual(expected.Inventory, actual.Inventory);
        AssertStringStringDictionaryEqual(expected.EquippedItems, actual.EquippedItems);
        AssertIntStringDictionaryEqual(expected.Structures, actual.Structures);
        AssertIntIntDictionaryEqual(expected.StructureLevels, actual.StructureLevels);
        AssertIntIntDictionaryEqual(expected.Workers, actual.Workers);
        AssertIntIntDictionaryEqual(expected.WorkerAssignments, actual.WorkerAssignments);
        AssertIntIntDictionaryEqual(expected.TowerCharge, actual.TowerCharge);
        AssertIntIntDictionaryEqual(expected.TowerCooldowns, actual.TowerCooldowns);
        AssertIntListDictionaryEqual(expected.TowerSummonIds, actual.TowerSummonIds);

        Assert.Equal(expected.PurchasedKingdomUpgrades, actual.PurchasedKingdomUpgrades);
        Assert.Equal(expected.PurchasedUnitUpgrades, actual.PurchasedUnitUpgrades);
        Assert.Equal(expected.CompletedResearch, actual.CompletedResearch);
        Assert.Equal(expected.UnlockedTitles, actual.UnlockedTitles);
        Assert.Equal(expected.UnlockedBadges, actual.UnlockedBadges);
        Assert.Equal(expected.VictoryAchieved, actual.VictoryAchieved);

        Assert.True(actual.Discovered.SetEquals(expected.Discovered));
        Assert.True(actual.CompletedQuests.SetEquals(expected.CompletedQuests));
        Assert.True(actual.BossesDefeated.SetEquals(expected.BossesDefeated));
        Assert.True(actual.Milestones.SetEquals(expected.Milestones));
        Assert.True(actual.UnlockedSkills.SetEquals(expected.UnlockedSkills));
        Assert.True(actual.CompletedDailyChallenges.SetEquals(expected.CompletedDailyChallenges));

        Assert.Equal(expected.Enemies.Count, actual.Enemies.Count);
        if (expected.Enemies.Count > 0)
        {
            Assert.Equal(expected.Enemies[0]["word"]?.ToString(), actual.Enemies[0]["word"]?.ToString());
            Assert.Equal(expected.Enemies[^1]["word"]?.ToString(), actual.Enemies[^1]["word"]?.ToString());
        }

        Assert.Equal(expected.ResourceNodes.Count, actual.ResourceNodes.Count);
        Assert.Equal(expected.HarvestedNodes.Count, actual.HarvestedNodes.Count);
        Assert.Equal(expected.TowerStates.Count, actual.TowerStates.Count);
        Assert.Equal(expected.ActiveSynergies.Count, actual.ActiveSynergies.Count);
        Assert.Equal(expected.SummonedUnits.Count, actual.SummonedUnits.Count);
        Assert.Equal(expected.ActiveTraps.Count, actual.ActiveTraps.Count);
        Assert.Equal(expected.ActiveExpeditions.Count, actual.ActiveExpeditions.Count);
        Assert.Equal(expected.ExpeditionHistory.Count, actual.ExpeditionHistory.Count);
        Assert.Equal(expected.RoamingEnemies.Count, actual.RoamingEnemies.Count);
        Assert.Equal(expected.RoamingResources.Count, actual.RoamingResources.Count);
        Assert.Equal(expected.Npcs.Count, actual.Npcs.Count);
        Assert.Equal(expected.EncounterEnemies.Count, actual.EncounterEnemies.Count);
        Assert.Equal(expected.Citizens.Count, actual.Citizens.Count);

        foreach (var (key, value) in expected.TradeRates)
        {
            Assert.True(actual.TradeRates.TryGetValue(key, out double actualValue));
            Assert.Equal(value, actualValue, 3);
        }

        foreach (var (key, value) in expected.FactionRelations)
        {
            Assert.True(actual.FactionRelations.TryGetValue(key, out int actualValue));
            Assert.Equal(value, actualValue);
        }

        foreach (var (key, expectedEntries) in expected.FactionAgreements)
        {
            Assert.True(actual.FactionAgreements.TryGetValue(key, out var actualEntries));
            Assert.True(actualEntries!.OrderBy(v => v).SequenceEqual(expectedEntries.OrderBy(v => v)));
        }

        Assert.Equal(
            Convert.ToInt32(expected.TypingMetrics["battle_chars_typed"]),
            Convert.ToInt32(actual.TypingMetrics["battle_chars_typed"]));
        Assert.Equal(
            Convert.ToInt32(expected.TypingMetrics["battle_words_typed"]),
            Convert.ToInt32(actual.TypingMetrics["battle_words_typed"]));
        Assert.Equal(
            Convert.ToInt32(expected.TypingMetrics["battle_errors"]),
            Convert.ToInt32(actual.TypingMetrics["battle_errors"]));
        Assert.Equal(
            Convert.ToInt64(expected.TypingMetrics["battle_start_msec"]),
            Convert.ToInt64(actual.TypingMetrics["battle_start_msec"]));
    }

    private static void AssertStringIntDictionaryEqual(
        Dictionary<string, int> expected,
        Dictionary<string, int> actual)
    {
        Assert.Equal(expected.Count, actual.Count);
        foreach (var (key, expectedValue) in expected)
        {
            Assert.True(actual.TryGetValue(key, out int actualValue));
            Assert.Equal(expectedValue, actualValue);
        }
    }

    private static void AssertStringStringDictionaryEqual(
        Dictionary<string, string> expected,
        Dictionary<string, string> actual)
    {
        Assert.Equal(expected.Count, actual.Count);
        foreach (var (key, expectedValue) in expected)
        {
            Assert.True(actual.TryGetValue(key, out string? actualValue));
            Assert.Equal(expectedValue, actualValue);
        }
    }

    private static void AssertIntStringDictionaryEqual(
        Dictionary<int, string> expected,
        Dictionary<int, string> actual)
    {
        Assert.Equal(expected.Count, actual.Count);
        foreach (var (key, expectedValue) in expected)
        {
            Assert.True(actual.TryGetValue(key, out string? actualValue));
            Assert.Equal(expectedValue, actualValue);
        }
    }

    private static void AssertIntIntDictionaryEqual(
        Dictionary<int, int> expected,
        Dictionary<int, int> actual)
    {
        Assert.Equal(expected.Count, actual.Count);
        foreach (var (key, expectedValue) in expected)
        {
            Assert.True(actual.TryGetValue(key, out int actualValue));
            Assert.Equal(expectedValue, actualValue);
        }
    }

    private static void AssertIntListDictionaryEqual(
        Dictionary<int, List<int>> expected,
        Dictionary<int, List<int>> actual)
    {
        Assert.Equal(expected.Count, actual.Count);
        foreach (var (key, expectedList) in expected)
        {
            Assert.True(actual.TryGetValue(key, out var actualList));
            Assert.Equal(expectedList, actualList);
        }
    }

    private static GameState CreateStressState(
        string id,
        int enemyCount = 16)
    {
        var state = DefaultState.Create($"stress_{id}", placeStartingTowers: true);
        state.Day = 30;
        state.Phase = "night";
        state.ApMax = 9;
        state.Ap = 6;
        state.Hp = 23;
        state.Threat = 11;
        state.Gold = 5555;
        state.NightPrompt = "fortify";
        state.NightSpawnRemaining = enemyCount;
        state.NightWaveTotal = enemyCount + 5;
        state.EnemyNextId = 1000;
        state.RngSeed = $"seed_{id}";
        state.RngState = 1234567890L;
        state.LessonId = "advanced_home_row";
        state.SkillPoints = 14;
        state.EnemiesDefeated = 900;
        state.MaxComboEver = 77;
        state.WavesSurvived = 41;
        state.ActiveTitle = "Storm Warden";
        state.WorkerCount = 12;
        state.TotalWorkers = 14;
        state.MaxWorkers = 20;
        state.WorkerUpkeep = 3;
        state.ActiveResearch = "arcane_machinery";
        state.ResearchProgress = 83;
        state.LastTradeDay = 29;
        state.SpeedMultiplier = 1.1f;
        state.PracticeMode = false;
        state.TimeOfDay = 0.8f;
        state.ActivityMode = "combat";
        state.ThreatLevel = 0.76f;
        state.WaveCooldown = 2.25f;
        state.WorldTickAccum = 4.5f;
        state.ThreatDecayAccum = 0.6f;
        state.ExpeditionNextId = 9;
        state.LastLootQuality = 1.8f;
        state.PerfectKills = 27;
        state.SummonedNextId = 70;
        state.TargetingMode = "weakest";
        state.ArrowRainTimer = 1.75f;
        state.HeroId = "sentinel";
        state.HeroAbilityCooldown = 9.5f;
        state.EquippedTitle = "Keeper";
        state.DailyChallengeDate = "2026-02-25";
        state.PerfectNightsToday = 3;
        state.NoDamageNightsToday = 2;
        state.FastestNightSeconds = 49;
        state.VictoryChecked = true;
        state.PeakGold = 7777;
        state.StoryCompleted = false;
        state.CurrentAct = 3;

        state.Resources["wood"] = 777;
        state.Resources["stone"] = 444;
        state.Resources["food"] = 321;
        state.Buildings["tower"] = 12;
        state.Buildings["wall"] = 6;
        state.Buildings["market"] = 2;

        state.EventCooldowns["merchant"] = 2;
        state.EventCooldowns["raid"] = 4;
        state.EventFlags["raid_ready"] = true;
        state.EventFlags["bonus_night"] = false;
        state.PendingEvent["kind"] = "raid";
        state.PendingEvent["difficulty"] = 6;
        state.ActiveBuffs.Add(new Dictionary<string, object>
        {
            ["type"] = "shield",
            ["duration"] = 5,
            ["stacks"] = 2,
        });

        state.Inventory["health_potion"] = 25;
        state.Inventory["mana_potion"] = 13;
        state.EquippedItems["weapon"] = "blade_of_words";
        state.EquippedItems["armor"] = "scribe_mail";
        state.EquippedItems["trinket"] = "glyph_ring";

        for (int i = 0; i < 12; i++)
        {
            state.Workers[i] = i % 3;
            state.WorkerAssignments[i] = (i + 1) % 5;
        }

        state.Citizens.Add(new Dictionary<string, object>
        {
            ["name"] = "Ada",
            ["role"] = "smith",
        });
        state.Citizens.Add(new Dictionary<string, object>
        {
            ["name"] = "Lin",
            ["role"] = "scout",
        });

        state.CompletedResearch.Add("basic_tools");
        state.CompletedResearch.Add("reinforced_walls");
        state.TradeRates["wood_to_stone"] = 2.25;
        state.TradeRates["stone_to_gold"] = 0.91;
        state.FactionRelations["guild"] = 45;
        state.FactionRelations["nomads"] = -10;
        state.FactionAgreements["trade"].Add("guild");
        state.FactionAgreements["non_aggression"].Add("nomads");
        state.PendingDiplomacy["guild"] = new Dictionary<string, object>
        {
            ["proposal"] = "offer_alliance",
            ["ttl"] = 2,
        };

        for (int i = 0; i < enemyCount; i++)
        {
            state.Enemies.Add(new Dictionary<string, object>
            {
                ["id"] = 100 + i,
                ["kind"] = "raider",
                ["hp"] = 8 + (i % 5),
                ["word"] = $"word_{i}",
            });

            state.RoamingEnemies.Add(new Dictionary<string, object>
            {
                ["kind"] = "wolf",
                ["x"] = i % 10,
                ["y"] = (i * 2) % 10,
            });
        }

        state.RoamingResources.Add(new Dictionary<string, object>
        {
            ["kind"] = "herb",
            ["x"] = 7,
            ["y"] = 6,
        });
        state.Npcs.Add(new Dictionary<string, object>
        {
            ["id"] = "merchant",
            ["x"] = 9,
            ["y"] = 8,
        });
        state.EncounterEnemies.Add(new Dictionary<string, object>
        {
            ["kind"] = "bandit",
            ["count"] = 3,
        });

        state.ActiveExpeditions.Add(new Dictionary<string, object>
        {
            ["id"] = 1,
            ["status"] = "active",
        });
        state.ExpeditionHistory.Add(new Dictionary<string, object>
        {
            ["id"] = 0,
            ["status"] = "completed",
        });

        for (int i = 0; i < 64; i++)
        {
            int key = 1000 + i;
            state.ResourceNodes[key] = new Dictionary<string, object>
            {
                ["kind"] = "ore",
                ["amount"] = 5 + (i % 4),
                ["active"] = (i % 2) == 0,
            };
            state.HarvestedNodes[$"node_{i}"] = i;
        }

        for (int i = 0; i < 24; i++)
        {
            int towerId = 200 + i;
            state.TowerStates[towerId] = new Dictionary<string, object>
            {
                ["kind"] = "arrow",
                ["level"] = 1 + (i % 4),
            };
            state.TowerCharge[towerId] = i % 5;
            state.TowerCooldowns[towerId] = i % 3;
            state.TowerSummonIds[towerId] = new List<int> { 3000 + i, 4000 + i };
        }

        state.ActiveSynergies.Add(new Dictionary<string, object> { ["name"] = "crossfire" });
        state.SummonedUnits.Add(new Dictionary<string, object> { ["id"] = 9001, ["kind"] = "golem" });
        state.ActiveTraps.Add(new Dictionary<string, object> { ["type"] = "spike", ["charges"] = 3 });
        state.AutoTower.AutoBuild = true;
        state.AutoTower.AutoUpgrade = true;
        state.AutoTower.AutoRepair = true;
        state.AutoTower.BuildPriority = "offense";
        state.AutoTower.ResourceReservePercent = 20;

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
        state.HeroActiveEffects.Add(new Dictionary<string, object>
        {
            ["name"] = "focus",
            ["duration"] = 3,
        });
        state.UnlockedTitles.Add("Keeper");
        state.UnlockedBadges.Add("first_blood");
        state.CompletedDailyChallenges.Add("no_miss_night");
        state.VictoryAchieved.Add("story_clear");

        AddLargeProgressionPayload(
            state,
            inventoryCount: 128,
            questCount: 120,
            upgradeCount: 100);

        return state;
    }

    private static void AddLargeProgressionPayload(
        GameState state,
        int inventoryCount,
        int questCount,
        int upgradeCount)
    {
        for (int i = 0; i < inventoryCount; i++)
            state.Inventory[$"item_{i:D4}"] = int.MaxValue - i;

        for (int i = 0; i < questCount; i++)
        {
            state.CompletedQuests.Add($"quest_{i:D4}");
            state.BossesDefeated.Add($"boss_{i:D4}");
            state.Milestones.Add($"milestone_{i:D4}");
            state.UnlockedSkills.Add($"skill_{i:D4}");
            state.CompletedDailyChallenges.Add($"daily_{i:D4}");
        }

        state.PurchasedKingdomUpgrades.Clear();
        state.PurchasedUnitUpgrades.Clear();
        for (int i = 0; i < upgradeCount; i++)
        {
            state.PurchasedKingdomUpgrades.Add($"kingdom_upgrade_{i:D4}");
            state.PurchasedUnitUpgrades.Add($"unit_upgrade_{i:D4}");
        }
    }
}
