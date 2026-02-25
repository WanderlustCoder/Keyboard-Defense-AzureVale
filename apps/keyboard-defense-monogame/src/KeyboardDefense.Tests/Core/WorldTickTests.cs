using System;
using System.Collections.Generic;
using KeyboardDefense.Core;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class WorldTickTests
{
    [Fact]
    public void Tick_BelowInterval_DoesNotProcessSimulationStep()
    {
        var state = CreateState();
        float initialTime = state.TimeOfDay;

        var result = WorldTick.Tick(state, 0.4);

        Assert.False((bool)result["changed"]);
        Assert.Empty(GetEvents(result));
        AssertInRange(state.WorldTickAccum, 0.399f, 0.401f);
        AssertInRange(state.TimeOfDay, initialTime - 0.0001f, initialTime + 0.0001f);
    }

    [Fact]
    public void Tick_WhenAccumCrossesInterval_ProcessesOneStepAndPreservesRemainder()
    {
        var state = CreateState();
        state.WorldTickAccum = 0.25f;
        state.TimeOfDay = 0.30f;

        var result = WorldTick.Tick(state, 1.0);

        Assert.True((bool)result["changed"]);
        Assert.Empty(GetEvents(result));
        AssertInRange(state.WorldTickAccum, 0.249f, 0.251f);
        AssertInRange(state.TimeOfDay, 0.319f, 0.321f);
    }

    [Fact]
    public void Tick_MultipleIntervals_ProcessesEachTickAndLeavesRemainder()
    {
        var state = CreateState();
        state.ActivityMode = "idle";
        state.TimeOfDay = 0.10f;

        var result = WorldTick.Tick(state, 3.2);

        Assert.True((bool)result["changed"]);
        Assert.Empty(GetEvents(result));
        AssertInRange(state.WorldTickAccum, 0.199f, 0.201f);
        AssertInRange(state.TimeOfDay, 0.159f, 0.161f);
    }

    [Fact]
    public void Tick_TimeOfDayWrapsWhenPassingOne()
    {
        var state = CreateState();
        state.ActivityMode = "idle";
        state.TimeOfDay = 0.99f;

        WorldTick.Tick(state, WorldTick.WorldTickInterval);

        AssertInRange(state.TimeOfDay, 0.009f, 0.011f);
    }

    [Fact]
    public void Tick_WaveCooldownDecaysAndClampsToZero()
    {
        var state = CreateState();
        state.WaveCooldown = 0.2f;

        var result = WorldTick.Tick(state, 0.5);

        Assert.False((bool)result["changed"]);
        Assert.Equal(0f, state.WaveCooldown);
        AssertInRange(state.WorldTickAccum, 0.499f, 0.501f);
    }

    [Fact]
    public void Tick_ExplorationWithoutNearbyEnemies_DecaysThreatLevel()
    {
        var state = CreateState();
        state.ThreatLevel = 0.50f;

        WorldTick.Tick(state, WorldTick.WorldTickInterval);

        AssertInRange(state.ThreatLevel, 0.489f, 0.491f);
    }

    [Fact]
    public void Tick_ExplorationWithNearbyEnemy_IncreasesThreatLevel()
    {
        var state = CreateState();
        state.PlayerPos = new GridPoint(0, 0);
        state.ThreatLevel = 0.20f;
        state.RoamingEnemies.Add(new Dictionary<string, object>
        {
            ["id"] = 101,
            ["kind"] = "scout",
            ["pos"] = state.BasePos,
            ["hp"] = 3,
            ["tier"] = 0,
            ["patrol_origin"] = state.BasePos
        });

        WorldTick.Tick(state, WorldTick.WorldTickInterval);

        Assert.True(state.ThreatLevel > 0.20f, $"Expected threat increase, got {state.ThreatLevel}");
    }

    [Fact]
    public void Tick_ExplorationWithNearbyHostiles_StartsEncounterAndMovesEnemies()
    {
        var state = CreateState();
        state.RoamingEnemies.Add(new Dictionary<string, object>
        {
            ["id"] = 1,
            ["kind"] = "scout",
            ["pos"] = state.PlayerPos,
            ["hp"] = 3,
            ["damage"] = 1,
            ["speed"] = 1,
            ["tier"] = 0
        });
        state.RoamingEnemies.Add(new Dictionary<string, object>
        {
            ["id"] = 2,
            ["kind"] = "raider",
            ["pos"] = new GridPoint(state.PlayerPos.X + 1, state.PlayerPos.Y),
            ["hp"] = 4,
            ["damage"] = 2,
            ["speed"] = 1,
            ["tier"] = 1
        });

        var result = WorldTick.Tick(state, WorldTick.WorldTickInterval);
        var events = GetEvents(result);

        Assert.Equal("encounter", state.ActivityMode);
        Assert.Equal(2, state.EncounterEnemies.Count);
        Assert.Empty(state.RoamingEnemies);
        Assert.Contains(events, e => e.StartsWith("Encounter!", StringComparison.Ordinal));
        Assert.All(state.EncounterEnemies, enemy =>
        {
            Assert.True(enemy.ContainsKey("word"));
            Assert.False(string.IsNullOrWhiteSpace(enemy["word"]?.ToString()));
            Assert.Equal(Convert.ToInt32(enemy["hp"]), Convert.ToInt32(enemy["max_hp"]));
        });
    }

    [Fact]
    public void Tick_EncounterMode_AdvancesApproachAndAppliesEnemyHit()
    {
        var state = CreateState();
        state.ActivityMode = "encounter";
        state.Hp = 10;
        state.EncounterEnemies.Add(new Dictionary<string, object>
        {
            ["id"] = 10,
            ["kind"] = "scout",
            ["pos"] = state.PlayerPos,
            ["tier"] = 2,
            ["approach_progress"] = 0.8f
        });

        var result = WorldTick.Tick(state, WorldTick.WorldTickInterval);
        var events = GetEvents(result);

        Assert.Equal(7, state.Hp);
        Assert.Equal("exploration", state.ActivityMode);
        Assert.Empty(state.EncounterEnemies);
        Assert.Contains(events, e => e.Contains("strikes you for 3 damage", StringComparison.Ordinal));
    }

    [Fact]
    public void Tick_HighThreatWithoutCooldown_StartsWaveAssault()
    {
        var state = CreateState();
        state.Day = 4;
        state.ThreatLevel = 0.85f;
        state.WaveCooldown = 0;

        var result = WorldTick.Tick(state, WorldTick.WorldTickInterval);
        var events = GetEvents(result);

        Assert.Equal("wave_assault", state.ActivityMode);
        Assert.Equal("night", state.Phase);
        Assert.True(state.NightWaveTotal > 0);
        Assert.Equal(state.NightWaveTotal, state.NightSpawnRemaining);
        AssertInRange(state.ThreatLevel, 0.299f, 0.301f);
        Assert.Contains(events, e => e.Contains("WAVE ASSAULT", StringComparison.Ordinal));
    }

    [Fact]
    public void Tick_HighThreatDuringCooldown_DoesNotStartWaveAssault()
    {
        var state = CreateState();
        state.ThreatLevel = 0.90f;
        state.WaveCooldown = 5f;

        var result = WorldTick.Tick(state, WorldTick.WorldTickInterval);
        var events = GetEvents(result);

        Assert.Equal("exploration", state.ActivityMode);
        Assert.DoesNotContain(events, e => e.Contains("WAVE ASSAULT", StringComparison.Ordinal));
        AssertInRange(state.WaveCooldown, 3.999f, 4.001f);
    }

    [Fact]
    public void Tick_WaveAssault_SpawnsEnemyAndConsumesRemainingCount()
    {
        var state = CreateState();
        state.ActivityMode = "wave_assault";
        state.Day = 5;
        state.NightWaveTotal = 5;
        state.NightSpawnRemaining = 3;
        state.Enemies.Clear();

        WorldTick.Tick(state, WorldTick.WorldTickInterval);

        Assert.Single(state.Enemies);
        Assert.Equal(2, state.NightSpawnRemaining);
        var enemy = state.Enemies[0];
        Assert.True(enemy.ContainsKey("id"));
        Assert.True(enemy.ContainsKey("kind"));
        Assert.True(enemy.ContainsKey("word"));
        Assert.True(enemy.ContainsKey("pos"));
        Assert.True(enemy.ContainsKey("hp"));
        Assert.True(enemy.ContainsKey("max_hp"));
        Assert.True(enemy.ContainsKey("damage"));
        Assert.True(enemy.ContainsKey("speed"));
        Assert.Equal(10, Convert.ToInt32(enemy["dist"]));
    }

    [Fact]
    public void Tick_WaveAssault_RespectsConcurrentEnemyCap()
    {
        var state = CreateState();
        state.ActivityMode = "wave_assault";
        state.NightWaveTotal = 4;
        state.NightSpawnRemaining = 2;

        for (int i = 0; i < 4; i++)
        {
            state.Enemies.Add(new Dictionary<string, object>
            {
                ["id"] = i + 1,
                ["kind"] = "scout",
                ["word"] = $"word{i}",
                ["hp"] = 2,
                ["max_hp"] = 2,
                ["damage"] = 1,
                ["speed"] = 1,
                ["dist"] = 10
            });
        }

        WorldTick.Tick(state, WorldTick.WorldTickInterval);

        Assert.Equal(4, state.Enemies.Count);
        Assert.Equal(2, state.NightSpawnRemaining);
    }

    [Fact]
    public void Tick_WaveAssaultCompleted_ResetsModeAndAwardsProgression()
    {
        var state = CreateState();
        state.ActivityMode = "wave_assault";
        state.Phase = "night";
        state.Day = 2;
        state.ApMax = 6;
        state.Ap = 1;
        state.NightWaveTotal = 6;
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();
        int goldBefore = state.Gold;
        int woodBefore = state.Resources.GetValueOrDefault("wood", 0);
        int stoneBefore = state.Resources.GetValueOrDefault("stone", 0);
        int foodBefore = state.Resources.GetValueOrDefault("food", 0);

        var result = WorldTick.Tick(state, WorldTick.WorldTickInterval);
        var events = GetEvents(result);

        Assert.Equal("exploration", state.ActivityMode);
        Assert.Equal("day", state.Phase);
        Assert.Equal(state.ApMax, state.Ap);
        Assert.Equal((float)WorldTick.WaveCooldownDuration, state.WaveCooldown);
        Assert.Equal(3, state.Day);
        Assert.Equal(1, state.WavesSurvived);
        Assert.True(state.Gold > goldBefore);
        Assert.True(state.Resources.GetValueOrDefault("wood", 0) > woodBefore);
        Assert.True(state.Resources.GetValueOrDefault("stone", 0) > stoneBefore);
        Assert.True(state.Resources.GetValueOrDefault("food", 0) > foodBefore);
        Assert.Contains(events, e => e.Contains("Wave repelled!", StringComparison.Ordinal));
    }

    [Fact]
    public void Tick_WaveAssaultUsesDifficultyModeFromEventFlags()
    {
        var storyState = CreateState("world_tick_story");
        storyState.Day = 6;
        storyState.ThreatLevel = 0.95f;
        storyState.EventFlags["difficulty_mode"] = "story";

        var championState = CreateState("world_tick_champion");
        championState.Day = 6;
        championState.ThreatLevel = 0.95f;
        championState.EventFlags["difficulty_mode"] = "champion";

        WorldTick.Tick(storyState, WorldTick.WorldTickInterval);
        WorldTick.Tick(championState, WorldTick.WorldTickInterval);

        Assert.Equal("wave_assault", storyState.ActivityMode);
        Assert.Equal("wave_assault", championState.ActivityMode);
        Assert.True(championState.NightWaveTotal > storyState.NightWaveTotal,
            $"Expected champion wave size > story wave size, got {championState.NightWaveTotal} vs {storyState.NightWaveTotal}");
    }

    private static GameState CreateState(string seed = "world_tick_tests")
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
        => Assert.IsType<List<string>>(tickResult["events"]);

    private static void AssertInRange(float value, float min, float max)
        => Assert.True(value >= min && value <= max, $"Expected {value} to be in range [{min}, {max}]");
}
