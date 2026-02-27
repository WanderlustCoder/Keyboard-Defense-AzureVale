using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core;
using KeyboardDefense.Core.Balance;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Extended tests for WorldTick — wave assault lifecycle, reward calculations,
/// encounter transitions, threat mechanics, and constants.
/// </summary>
public class WorldTickExtendedTests
{
    // =========================================================================
    // Constants
    // =========================================================================

    [Fact]
    public void Constants_HaveExpectedValues()
    {
        Assert.Equal(1.0, WorldTick.WorldTickInterval);
        Assert.Equal(0.02, WorldTick.TimeAdvanceRate);
        Assert.Equal(0.8, WorldTick.WaveAssaultThreshold);
        Assert.Equal(30.0, WorldTick.WaveCooldownDuration);
        Assert.Equal(8, WorldTick.MaxRoamingEnemies);
    }

    [Fact]
    public void RewardConstants_ArePositive()
    {
        Assert.True(WorldTick.WaveBaseGold > 0);
        Assert.True(WorldTick.WavePerEnemyGold > 0);
        Assert.True(WorldTick.WaveBaseWood > 0);
        Assert.True(WorldTick.WaveBaseStone > 0);
        Assert.True(WorldTick.WaveBaseFood > 0);
    }

    // =========================================================================
    // Wave assault lifecycle — full cycle
    // =========================================================================

    [Fact]
    public void WaveAssault_FullLifecycle_TriggerSpawnCompleteReward()
    {
        var state = CreateState("lifecycle");
        state.ThreatLevel = 0.9f;
        state.WaveCooldown = 0;
        state.Gold = 50;
        int initialDay = state.Day;

        // Step 1: Trigger wave assault
        var result1 = WorldTick.Tick(state, WorldTick.WorldTickInterval);
        Assert.Equal("wave_assault", state.ActivityMode);
        Assert.Equal("night", state.Phase);

        // Step 2: Spawn and clear all enemies
        int safety = 0;
        while (state.ActivityMode == "wave_assault" && safety < 100)
        {
            WorldTick.Tick(state, WorldTick.WorldTickInterval);
            // Kill all enemies each tick
            state.Enemies.Clear();
            safety++;
        }

        // Step 3: Verify completion
        Assert.Equal("exploration", state.ActivityMode);
        Assert.Equal("day", state.Phase);
        Assert.Equal(initialDay + 1, state.Day);
        Assert.True(state.Gold > 50, "Should have earned gold reward");
        Assert.True(state.WaveCooldown > 0, "Should have set wave cooldown");
        Assert.Equal(1, state.WavesSurvived);
    }

    // =========================================================================
    // Wave rewards
    // =========================================================================

    [Fact]
    public void WaveRewards_GoldRespectsGoldCap()
    {
        var state = CreateState("gold-cap-wave");
        state.Gold = SimBalance.GoldCap - 1;
        state.ActivityMode = "wave_assault";
        state.Phase = "night";
        state.NightWaveTotal = 10;
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();

        WorldTick.Tick(state, WorldTick.WorldTickInterval);

        Assert.True(state.Gold <= SimBalance.GoldCap);
    }

    [Fact]
    public void WaveRewards_IncludeAllResourceTypes()
    {
        var state = CreateState("all-resources");
        state.ActivityMode = "wave_assault";
        state.Phase = "night";
        state.NightWaveTotal = 6;
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();
        state.Resources["wood"] = 0;
        state.Resources["stone"] = 0;
        state.Resources["food"] = 0;
        int goldBefore = state.Gold;

        WorldTick.Tick(state, WorldTick.WorldTickInterval);

        Assert.True(state.Gold > goldBefore, "Gold should increase");
        Assert.True(state.Resources["wood"] > 0, "Wood should increase");
        Assert.True(state.Resources["stone"] > 0, "Stone should increase");
        Assert.True(state.Resources["food"] > 0, "Food should increase");
    }

    [Fact]
    public void WaveRewards_LargerWaveGivesMoreGold()
    {
        // Small wave
        var small = CreateState("small-wave");
        small.ActivityMode = "wave_assault";
        small.Phase = "night";
        small.NightWaveTotal = 3;
        small.NightSpawnRemaining = 0;
        small.Enemies.Clear();
        small.Gold = 0;

        // Large wave
        var large = CreateState("large-wave");
        large.ActivityMode = "wave_assault";
        large.Phase = "night";
        large.NightWaveTotal = 12;
        large.NightSpawnRemaining = 0;
        large.Enemies.Clear();
        large.Gold = 0;

        WorldTick.Tick(small, WorldTick.WorldTickInterval);
        WorldTick.Tick(large, WorldTick.WorldTickInterval);

        Assert.True(large.Gold > small.Gold,
            $"Large wave gold ({large.Gold}) should exceed small wave ({small.Gold})");
    }

    // =========================================================================
    // Wave assault completion resets
    // =========================================================================

    [Fact]
    public void WaveComplete_ClearsTradeHistoryAndDailyChallenges()
    {
        var state = CreateState("wave-clear-trade");
        state.ActivityMode = "wave_assault";
        state.Phase = "night";
        state.NightWaveTotal = 1;
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();
        state.TradeHistory.Add("wood:stone");
        state.CompletedDailyChallenges.Add("test_challenge");

        WorldTick.Tick(state, WorldTick.WorldTickInterval);

        Assert.Empty(state.TradeHistory);
        Assert.Empty(state.CompletedDailyChallenges);
    }

    [Fact]
    public void WaveComplete_RestoresApToMax()
    {
        var state = CreateState("wave-restore-ap");
        state.ActivityMode = "wave_assault";
        state.Phase = "night";
        state.NightWaveTotal = 1;
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();
        state.ApMax = 7;
        state.Ap = 0;

        WorldTick.Tick(state, WorldTick.WorldTickInterval);

        Assert.Equal(7, state.Ap);
    }

    // =========================================================================
    // Wave spawning mechanics
    // =========================================================================

    [Fact]
    public void WaveSpawn_AssignsUniqueWordsToEnemies()
    {
        var state = CreateState("unique-words");
        state.ActivityMode = "wave_assault";
        state.Day = 5;
        state.NightWaveTotal = 5;
        state.NightSpawnRemaining = 5;
        state.Enemies.Clear();

        // Spawn multiple enemies
        for (int i = 0; i < 5; i++)
            WorldTick.Tick(state, WorldTick.WorldTickInterval);

        var words = state.Enemies
            .Select(e => e.GetValueOrDefault("word")?.ToString() ?? "")
            .Where(w => !string.IsNullOrEmpty(w))
            .ToList();

        Assert.Equal(words.Count, words.Distinct().Count());
    }

    [Fact]
    public void WaveSpawn_DoesNotSpawnWhenRemainingIsZero()
    {
        var state = CreateState("no-spawn-zero");
        state.ActivityMode = "wave_assault";
        state.NightWaveTotal = 3;
        state.NightSpawnRemaining = 0;
        state.Enemies.Add(new Dictionary<string, object> { ["id"] = 1 }); // prevent completion

        WorldTick.Tick(state, WorldTick.WorldTickInterval);

        Assert.Single(state.Enemies); // no new enemies added
    }

    [Fact]
    public void WaveSpawn_IncreasesEnemyNextId()
    {
        var state = CreateState("spawn-id");
        state.ActivityMode = "wave_assault";
        state.Day = 3;
        state.NightWaveTotal = 5;
        state.NightSpawnRemaining = 3;
        state.Enemies.Clear();
        int idBefore = state.EnemyNextId;

        WorldTick.Tick(state, WorldTick.WorldTickInterval);

        Assert.True(state.EnemyNextId > idBefore);
    }

    // =========================================================================
    // Encounter mechanics
    // =========================================================================

    [Fact]
    public void Encounter_OnlyTriggeredByEnemyTypeEntities()
    {
        var state = CreateState("encounter-enemy-only");
        // Add NPC near player — should NOT trigger encounter
        state.Npcs.Add(new Dictionary<string, object>
        {
            ["type"] = "merchant",
            ["pos"] = state.PlayerPos,
            ["name"] = "Merchant",
            ["entity_type"] = "npc",
        });

        var result = WorldTick.Tick(state, WorldTick.WorldTickInterval);
        Assert.Equal("exploration", state.ActivityMode);
    }

    [Fact]
    public void Encounter_TransfersEnemyFromRoamingToEncounter()
    {
        var state = CreateState("encounter-transfer");
        state.RoamingEnemies.Add(new Dictionary<string, object>
        {
            ["id"] = 42,
            ["kind"] = "scout",
            ["pos"] = state.PlayerPos,
            ["hp"] = 5,
            ["damage"] = 1,
            ["speed"] = 1,
            ["tier"] = 0,
        });

        WorldTick.Tick(state, WorldTick.WorldTickInterval);

        Assert.Equal("encounter", state.ActivityMode);
        Assert.Empty(state.RoamingEnemies);
        Assert.Single(state.EncounterEnemies);
        Assert.Equal(42, Convert.ToInt32(state.EncounterEnemies[0]["id"]));
    }

    // =========================================================================
    // Threat level mechanics
    // =========================================================================

    [Fact]
    public void ThreatLevel_ClampsToZeroOnDecay()
    {
        var state = CreateState("threat-clamp-zero");
        state.ThreatLevel = 0.005f; // very low

        WorldTick.Tick(state, WorldTick.WorldTickInterval);

        Assert.True(state.ThreatLevel >= 0, "Threat should not go negative");
    }

    [Fact]
    public void ThreatLevel_ClampsToOneOnGrowth()
    {
        var state = CreateState("threat-clamp-one");
        state.ThreatLevel = 0.95f;

        // Many nearby enemies
        for (int i = 0; i < 10; i++)
        {
            state.RoamingEnemies.Add(new Dictionary<string, object>
            {
                ["id"] = i + 1,
                ["kind"] = "scout",
                ["pos"] = state.BasePos,
                ["hp"] = 3,
                ["tier"] = 0,
                ["patrol_origin"] = state.BasePos,
            });
        }

        // Tick without triggering wave (set cooldown to block)
        state.WaveCooldown = 999f;
        WorldTick.Tick(state, WorldTick.WorldTickInterval);

        Assert.True(state.ThreatLevel <= 1.0f, "Threat should not exceed 1.0");
    }

    [Fact]
    public void ThreatLevel_DistantEnemies_DoNotContribute()
    {
        var state = CreateState("threat-distant");
        state.ThreatLevel = 0.5f;

        // Enemy far from base
        state.RoamingEnemies.Add(new Dictionary<string, object>
        {
            ["id"] = 1,
            ["kind"] = "scout",
            ["pos"] = new GridPoint(0, 0), // far corner
            ["hp"] = 3,
            ["tier"] = 0,
            ["patrol_origin"] = new GridPoint(0, 0),
        });

        WorldTick.Tick(state, WorldTick.WorldTickInterval);

        // With no nearby enemies, threat should decay
        Assert.True(state.ThreatLevel < 0.5f);
    }

    // =========================================================================
    // Time-of-day
    // =========================================================================

    [Fact]
    public void TimeOfDay_AdvancesByRatePerTick()
    {
        var state = CreateState("time-advance");
        state.ActivityMode = "idle"; // no special processing
        state.TimeOfDay = 0.5f;

        WorldTick.Tick(state, WorldTick.WorldTickInterval);

        float expected = 0.5f + (float)WorldTick.TimeAdvanceRate;
        Assert.InRange(state.TimeOfDay, expected - 0.001f, expected + 0.001f);
    }

    [Fact]
    public void TimeOfDay_NeverExceedsOne()
    {
        var state = CreateState("time-wrap");
        state.ActivityMode = "idle";
        state.TimeOfDay = 0.1f;

        // Tick many times
        for (int i = 0; i < 100; i++)
            WorldTick.Tick(state, WorldTick.WorldTickInterval);

        Assert.True(state.TimeOfDay >= 0f && state.TimeOfDay < 1.0f,
            $"TimeOfDay should wrap, got {state.TimeOfDay}");
    }

    // =========================================================================
    // Wave cooldown
    // =========================================================================

    [Fact]
    public void WaveCooldown_DecaysByDeltaEachTick()
    {
        var state = CreateState("cooldown-decay");
        state.WaveCooldown = 10f;

        WorldTick.Tick(state, 3.0);

        Assert.InRange(state.WaveCooldown, 6.9f, 7.1f);
    }

    [Fact]
    public void WaveCooldown_NeverGoesNegative()
    {
        var state = CreateState("cooldown-clamp");
        state.WaveCooldown = 0.5f;

        WorldTick.Tick(state, 5.0);

        Assert.Equal(0f, state.WaveCooldown);
    }

    // =========================================================================
    // Delta accumulation
    // =========================================================================

    [Fact]
    public void Tick_SmallDeltas_AccumulateCorrectly()
    {
        var state = CreateState("small-deltas");
        state.ActivityMode = "idle";

        // Many small ticks that don't cross interval
        for (int i = 0; i < 9; i++)
            WorldTick.Tick(state, 0.1);

        // Accumulated 0.9, below 1.0 interval
        Assert.InRange(state.WorldTickAccum, 0.89f, 0.91f);
        Assert.InRange(state.TimeOfDay, 0.249f, 0.251f); // unchanged

        // One more that crosses threshold
        WorldTick.Tick(state, 0.2);

        // Should have processed one tick, remainder ~0.1
        Assert.InRange(state.WorldTickAccum, 0.09f, 0.11f);
        float expectedTime = 0.25f + (float)WorldTick.TimeAdvanceRate;
        Assert.InRange(state.TimeOfDay, expectedTime - 0.001f, expectedTime + 0.001f);
    }

    // =========================================================================
    // Helpers
    // =========================================================================

    private static GameState CreateState(string seed = "world_tick_ext")
    {
        var state = new GameState
        {
            Day = 3,
            MapW = 16,
            MapH = 16,
            BasePos = new GridPoint(8, 8),
            PlayerPos = new GridPoint(8, 8),
            CursorPos = new GridPoint(8, 8),
            Phase = "day",
            ActivityMode = "exploration",
            ApMax = 5,
            Ap = 3,
            Hp = 10,
            LessonId = "full_alpha",
        };
        state.Terrain.Clear();
        for (int i = 0; i < state.MapW * state.MapH; i++)
            state.Terrain.Add(SimMap.TerrainPlains);
        state.RoamingEnemies.Clear();
        state.EncounterEnemies.Clear();
        state.Enemies.Clear();
        state.Npcs.Clear();
        state.ResourceNodes.Clear();
        state.ThreatLevel = 0f;
        state.WaveCooldown = 0f;
        state.WorldTickAccum = 0f;
        state.TimeOfDay = 0.25f;
        SimRng.SeedState(state, seed);
        return state;
    }

    private static List<string> GetEvents(Dictionary<string, object> tickResult)
        => (List<string>)tickResult["events"];
}
