using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Stress;

public class CombatStressTests
{
    private const int WaveCompletionGuardTicks = 2000;

    [Fact]
    public void WaveSim_OneHundredConsecutiveWaves_CompletesWithoutInfiniteLoop()
    {
        var state = DefaultState.Create("stress_100_waves", placeStartingTowers: true);
        state.Hp = 5000;

        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 24,
            SpawnIntervalSeconds = 0.1f,
            EnemyStepIntervalSeconds = 0.1f,
            EnemyStepDistance = 1,
            EnemyContactDamage = 1,
            TypedHitDamage = 4,
            TypedMissDamage = 0,
            TowerTickDamage = 100,
        };

        for (int wave = 0; wave < 100; wave++)
        {
            var events = new List<string>();
            VerticalSliceWaveSim.StartSingleWave(state, config, events);

            int ticks = RunWaveToCompletion(state, config, maxTicks: WaveCompletionGuardTicks, deltaSeconds: 0.1f);
            Assert.True(ticks > 0);
            Assert.NotEqual("night", state.Phase);

            if (state.Phase == "game_over")
            {
                state.Hp = 5000;
                state.Phase = "day";
            }
        }
    }

    [Fact]
    public void TowerCombat_WithMoreThanFiftyEnemies_HandlesSimultaneousTargets()
    {
        var state = new GameState();
        var towers = new List<Dictionary<string, object>>
        {
            Tower(name: "Single", category: "single", damage: 12, x: 0, y: 0),
            Tower(name: "Volley", category: "multi", damage: 8, x: 1, y: 0, multiCount: 12),
            Tower(name: "Blast", category: "aoe", damage: 10, x: 0, y: 0, aoeRadius: 3),
            Tower(name: "Chain", category: "chain", damage: 9, x: 0, y: 0, chainJumps: 8, chainRange: 2),
        };
        var enemies = CreateTowerCombatEnemies(count: 64, hp: 120);

        var events = TowerCombat.ProcessTowerAttacks(state, towers, enemies);

        Assert.NotEmpty(events);
        int damaged = enemies.Count(e => Convert.ToInt32(e["hp"]) < 120);
        Assert.True(
            damaged >= 16,
            $"Expected broad damage distribution with 64 enemies, but only {damaged} enemies took damage.");
    }

    [Fact]
    public void AutoTowerCombat_MaxTowerCount_TargetingRemainsStable()
    {
        const int mapSize = 16;
        var state = new GameState
        {
            MapW = mapSize,
            MapH = mapSize,
            Structures = new Dictionary<int, string>(),
            Enemies = new List<Dictionary<string, object>>(),
            TowerCooldowns = new Dictionary<int, int>(),
        };

        for (int y = 0; y < mapSize; y++)
        {
            for (int x = 0; x < mapSize; x++)
            {
                int index = new GridPoint(x, y).ToIndex(mapSize);
                state.Structures[index] = AutoTowerTypes.Flame;
            }
        }

        state.Enemies.AddRange(CreateAutoEnemiesGrid(mapSize, spacing: 2, hp: 1000));

        var eventCounts = new List<int>();
        var stopwatch = Stopwatch.StartNew();

        for (int iteration = 0; iteration < 8; iteration++)
        {
            state.TowerCooldowns.Clear();
            var tickEvents = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.016);
            eventCounts.Add(tickEvents.Count);
        }

        stopwatch.Stop();

        Assert.Equal(mapSize * mapSize, eventCounts[0]);
        Assert.All(eventCounts, count => Assert.Equal(eventCounts[0], count));
        Assert.True(
            stopwatch.ElapsedMilliseconds < 1000,
            $"Max tower targeting regression detected: {stopwatch.ElapsedMilliseconds}ms.");
    }

    [Fact]
    public void WaveSim_ExtremeDifficultySettings_CompletesWithinSafetyLimit()
    {
        var state = DefaultState.Create("stress_extreme", placeStartingTowers: true);
        state.Hp = 10000;

        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 128,
            SpawnIntervalSeconds = 0.1f,
            EnemyStepIntervalSeconds = 0.1f,
            EnemyStepDistance = 3,
            EnemyContactDamage = 15,
            TypedHitDamage = 50,
            TypedMissDamage = 10,
            TowerTickDamage = 80,
        };

        var events = new List<string>();
        VerticalSliceWaveSim.StartSingleWave(state, config, events);

        int ticks = RunWaveToCompletion(state, config, maxTicks: 6000, deltaSeconds: 0.5f);
        Assert.True(ticks > 0);

        string result = state.TypingMetrics.GetValueOrDefault("vs_result")?.ToString() ?? string.Empty;
        Assert.True(result is "victory" or "defeat", $"Unexpected result marker: '{result}'.");
    }

    [Fact]
    public void WaveSim_CollectionsRemainBoundedAcrossLongCombatSequence()
    {
        var state = DefaultState.Create("stress_memory_bounds", placeStartingTowers: true);
        state.Hp = 50000;
        int baselineStructureCount = state.Structures.Count;

        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 32,
            SpawnIntervalSeconds = 0.1f,
            EnemyStepIntervalSeconds = 0.1f,
            EnemyStepDistance = 1,
            EnemyContactDamage = 1,
            TypedHitDamage = 3,
            TypedMissDamage = 0,
            TowerTickDamage = 120,
        };

        for (int i = 0; i < 60; i++)
        {
            var events = new List<string>();
            VerticalSliceWaveSim.StartSingleWave(state, config, events);
            RunWaveToCompletion(state, config, maxTicks: WaveCompletionGuardTicks, deltaSeconds: 0.1f);
            Assert.Equal("day", state.Phase);
        }

        Assert.Empty(state.Enemies);
        Assert.Equal(baselineStructureCount, state.Structures.Count);
        Assert.True(state.TypingMetrics.Count <= 40, $"Typing metric keys grew unexpectedly: {state.TypingMetrics.Count}");
        Assert.True(state.TowerCooldowns.Count <= state.Structures.Count);
    }

    [Fact]
    public void WaveSim_RapidConsecutiveEncounters_ResetAndResolve()
    {
        var state = DefaultState.Create("stress_rapid_encounters", placeStartingTowers: false);
        state.Hp = 2000;

        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 1,
            SpawnIntervalSeconds = 1f,
            EnemyStepIntervalSeconds = 5f,
            EnemyStepDistance = 1,
            EnemyContactDamage = 1,
            TypedHitDamage = 2,
            TypedMissDamage = 0,
            TowerTickDamage = 0,
        };

        for (int encounter = 0; encounter < 200; encounter++)
        {
            var events = new List<string>();
            VerticalSliceWaveSim.StartSingleWave(state, config, events);

            state.Enemies.Clear();
            state.NightSpawnRemaining = 0;
            state.NightWaveTotal = 1;
            state.Enemies.Add(new Dictionary<string, object>
            {
                ["id"] = encounter + 1,
                ["kind"] = "scout",
                ["word"] = "a",
                ["hp"] = 1,
                ["dist"] = 8,
                ["gold"] = 1,
                ["damage"] = 1,
            });

            events.Clear();
            VerticalSliceWaveSim.Step(state, config, 0f, "a", events);

            Assert.Equal("day", state.Phase);
            Assert.Equal(0, state.NightSpawnRemaining);
            Assert.Empty(state.Enemies);
        }
    }

    [Fact]
    public void WaveSim_OneHundredTicks_RunUnderOneSecond()
    {
        var state = DefaultState.Create("stress_100_ticks", placeStartingTowers: true);
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 100,
            SpawnIntervalSeconds = 1000f,
            EnemyStepIntervalSeconds = 1000f,
            EnemyStepDistance = 1,
            EnemyContactDamage = 1,
            TypedHitDamage = 2,
            TypedMissDamage = 1,
            TowerTickDamage = 1,
        };
        var events = new List<string>();

        VerticalSliceWaveSim.StartSingleWave(state, config, events);

        var stopwatch = Stopwatch.StartNew();
        for (int i = 0; i < 100; i++)
        {
            events.Clear();
            VerticalSliceWaveSim.Step(state, config, deltaSeconds: 0.01f, typedInput: null, events);
        }
        stopwatch.Stop();

        Assert.True(
            stopwatch.ElapsedMilliseconds < 1000,
            $"100 wave ticks exceeded budget: {stopwatch.ElapsedMilliseconds}ms.");
    }

    private static int RunWaveToCompletion(
        GameState state,
        VerticalSliceWaveConfig config,
        int maxTicks,
        float deltaSeconds)
    {
        var events = new List<string>();
        int ticks = 0;

        while (state.Phase == "night" && ticks < maxTicks)
        {
            events.Clear();
            VerticalSliceWaveSim.Step(state, config, deltaSeconds, typedInput: null, events);
            ticks++;
        }

        Assert.NotEqual("night", state.Phase);
        return ticks;
    }

    private static List<Dictionary<string, object>> CreateTowerCombatEnemies(int count, int hp)
    {
        var enemies = new List<Dictionary<string, object>>(count);
        int side = (int)Math.Ceiling(Math.Sqrt(count));

        for (int i = 0; i < count; i++)
        {
            int x = i % side;
            int y = i / side;
            enemies.Add(new Dictionary<string, object>
            {
                ["id"] = i + 1,
                ["x"] = x,
                ["y"] = y,
                ["hp"] = hp,
                ["armor"] = 0,
                ["alive"] = true,
                ["word"] = $"enemy{i + 1}",
                ["affix"] = "",
                ["effects"] = new List<Dictionary<string, object>>(),
            });
        }

        return enemies;
    }

    private static List<Dictionary<string, object>> CreateAutoEnemiesGrid(int mapSize, int spacing, int hp)
    {
        var enemies = new List<Dictionary<string, object>>();
        int id = 1;

        for (int y = 0; y < mapSize; y += spacing)
        {
            for (int x = 0; x < mapSize; x += spacing)
            {
                enemies.Add(new Dictionary<string, object>
                {
                    ["id"] = id++,
                    ["pos"] = new GridPoint(x, y),
                    ["hp"] = hp,
                    ["max_hp"] = hp,
                    ["speed"] = 1.0,
                    ["damage"] = 1,
                    ["kind"] = "raider",
                });
            }
        }

        return enemies;
    }

    private static Dictionary<string, object> Tower(
        string name,
        string category,
        int damage,
        int x,
        int y,
        string targetMode = "nearest",
        string damageType = "physical",
        int multiCount = 2,
        int aoeRadius = 2,
        int chainJumps = 3,
        int chainRange = 3)
    {
        return new Dictionary<string, object>
        {
            ["name"] = name,
            ["category"] = category,
            ["x"] = x,
            ["y"] = y,
            ["damage"] = damage,
            ["target_mode"] = targetMode,
            ["damage_type"] = damageType,
            ["multi_count"] = multiCount,
            ["aoe_radius"] = aoeRadius,
            ["chain_jumps"] = chainJumps,
            ["chain_range"] = chainRange,
        };
    }
}
