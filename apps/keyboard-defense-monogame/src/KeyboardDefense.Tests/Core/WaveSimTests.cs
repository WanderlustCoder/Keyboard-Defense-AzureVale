using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class WaveSimTests
{
    private const string ResultKey = "vs_result";
    private const string DamageTakenKey = "vs_damage_taken";
    private const string ScoreKey = "vs_score";
    private const string ElapsedSecondsKey = "vs_elapsed_seconds";
    private const string SummaryPayloadKey = "vs_summary_payload";

    [Fact]
    public void Simulation_RunToCompletionWithAutoTowers_EndsWithVictory()
    {
        var state = DefaultState.Create("wave_sim_victory", placeStartingTowers: true);
        state.Hp = 40;
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 6,
            SpawnIntervalSeconds = 0.2f,
            EnemyStepIntervalSeconds = 0.2f,
            EnemyStepDistance = 1,
            EnemyContactDamage = 1,
            TypedHitDamage = 2,
            TypedMissDamage = 1,
            TowerTickDamage = 8,
        };

        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        int steps = RunNightToCompletion(state, config, deltaSeconds: 0.2f, maxSteps: 600);

        Assert.Equal("day", state.Phase);
        Assert.Equal("victory", MetricString(state, ResultKey));
        Assert.Equal(0, state.NightSpawnRemaining);
        Assert.Empty(state.Enemies);
        Assert.InRange(steps, 1, 599);
        Assert.True(state.TypingMetrics.ContainsKey(SummaryPayloadKey));
    }

    [Fact]
    public void Simulation_RunToCompletionWithoutDefense_CanEndInDefeat()
    {
        var state = DefaultState.Create("wave_sim_defeat", placeStartingTowers: false);
        state.Hp = 1;
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 1,
            SpawnIntervalSeconds = 5.0f,
            EnemyStepIntervalSeconds = 0.1f,
            EnemyStepDistance = 20,
            EnemyContactDamage = 2,
            TypedHitDamage = 2,
            TypedMissDamage = 0,
            TowerTickDamage = 0,
        };

        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        int steps = RunNightToCompletion(state, config, deltaSeconds: 0.1f, maxSteps: 30);

        Assert.Equal("game_over", state.Phase);
        Assert.Equal("defeat", MetricString(state, ResultKey));
        Assert.InRange(steps, 1, 29);
        Assert.True(MetricInt(state, DamageTakenKey) >= 1);
    }

    [Fact]
    public void Spawning_LargeDeltaSpawnsUpToWaveTotal()
    {
        var state = DefaultState.Create("wave_sim_spawn_total", placeStartingTowers: false);
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 3,
            SpawnIntervalSeconds = 0.5f,
            EnemyStepIntervalSeconds = 30f,
            EnemyStepDistance = 1,
            EnemyContactDamage = 1,
            TypedHitDamage = 2,
            TypedMissDamage = 1,
            TowerTickDamage = 0,
        };
        var events = new List<string>();

        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        VerticalSliceWaveSim.Step(state, config, deltaSeconds: 1.5f, typedInput: null, events);

        Assert.Equal(3, state.Enemies.Count);
        Assert.Equal(0, state.NightSpawnRemaining);
        Assert.Equal(3, CountMatchingEvents(events, "Enemy spawned:"));
    }

    [Fact]
    public void Spawning_RespectsSpawnIntervalAcrossSteps()
    {
        var state = DefaultState.Create("wave_sim_spawn_interval", placeStartingTowers: false);
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 2,
            SpawnIntervalSeconds = 1f,
            EnemyStepIntervalSeconds = 30f,
            EnemyStepDistance = 1,
            EnemyContactDamage = 1,
            TypedHitDamage = 2,
            TypedMissDamage = 1,
            TowerTickDamage = 0,
        };
        var events = new List<string>();

        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());

        VerticalSliceWaveSim.Step(state, config, deltaSeconds: 0.25f, typedInput: null, events);
        Assert.Single(state.Enemies);
        Assert.Equal(1, state.NightSpawnRemaining);

        events.Clear();
        VerticalSliceWaveSim.Step(state, config, deltaSeconds: 0.5f, typedInput: null, events);
        Assert.Single(state.Enemies);
        Assert.Equal(1, state.NightSpawnRemaining);
        Assert.Equal(0, CountMatchingEvents(events, "Enemy spawned:"));

        events.Clear();
        VerticalSliceWaveSim.Step(state, config, deltaSeconds: 0.5f, typedInput: null, events);
        Assert.Equal(2, state.Enemies.Count);
        Assert.Equal(0, state.NightSpawnRemaining);
        Assert.Equal(1, CountMatchingEvents(events, "Enemy spawned:"));
    }

    [Fact]
    public void TowerDamage_AppliesConfiguredTickDamageToEnemy()
    {
        var state = DefaultState.Create("wave_sim_tower_damage", placeStartingTowers: false);
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 0,
            SpawnIntervalSeconds = 1f,
            EnemyStepIntervalSeconds = 1f,
            EnemyStepDistance = 0,
            EnemyContactDamage = 1,
            TypedHitDamage = 2,
            TypedMissDamage = 1,
            TowerTickDamage = 3,
        };
        var events = new List<string>();

        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        state.Structures.Clear();
        state.Structures[SimMap.Idx(state.BasePos.X, state.BasePos.Y, state.MapW)] = "auto_sentry";
        state.NightSpawnRemaining = 0;
        state.NightWaveTotal = 1;
        state.Enemies.Clear();
        state.Enemies.Add(CreateEnemy(id: 11, hp: 7, dist: 9, gold: 2));

        VerticalSliceWaveSim.Step(state, config, deltaSeconds: 1f, typedInput: null, events);

        int hp = Convert.ToInt32(state.Enemies[0].GetValueOrDefault("hp", 0));
        Assert.Equal(4, hp);
        Assert.Equal(10, state.Hp);
        Assert.Equal(0, CountMatchingEvents(events, "Auto-tower defeats enemy!"));
    }

    [Fact]
    public void TowerDamage_KillAwardsGoldAndDefeatCount()
    {
        var state = DefaultState.Create("wave_sim_tower_kill", placeStartingTowers: false);
        int startGold = state.Gold;
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 0,
            SpawnIntervalSeconds = 1f,
            EnemyStepIntervalSeconds = 1f,
            EnemyStepDistance = 0,
            EnemyContactDamage = 1,
            TypedHitDamage = 2,
            TypedMissDamage = 1,
            TowerTickDamage = 5,
        };
        var events = new List<string>();

        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        state.Structures.Clear();
        state.Structures[SimMap.Idx(state.BasePos.X, state.BasePos.Y, state.MapW)] = "auto_sentry";
        state.NightSpawnRemaining = 0;
        state.NightWaveTotal = 1;
        state.Enemies.Clear();
        state.EnemiesDefeated = 0;
        state.Enemies.Add(CreateEnemy(id: 12, hp: 3, dist: 9, gold: 7));

        VerticalSliceWaveSim.Step(state, config, deltaSeconds: 1f, typedInput: null, events);

        Assert.Empty(state.Enemies);
        Assert.Equal(startGold + 7, state.Gold);
        Assert.Equal(1, state.EnemiesDefeated);
        Assert.Equal(1, CountMatchingEvents(events, "Auto-tower defeats enemy!"));
    }

    [Fact]
    public void DifficultyScaling_HigherDayAndThreatIncreaseEnemyHp()
    {
        var lowState = DefaultState.Create("wave_sim_scaling", placeStartingTowers: false);
        lowState.Day = 1;
        lowState.Threat = 0;

        var highState = DefaultState.Create("wave_sim_scaling", placeStartingTowers: false);
        highState.Day = 12;
        highState.Threat = 8;

        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 1,
            SpawnIntervalSeconds = 1f,
            EnemyStepIntervalSeconds = 30f,
            EnemyStepDistance = 1,
            EnemyContactDamage = 1,
            TypedHitDamage = 2,
            TypedMissDamage = 1,
            TowerTickDamage = 0,
        };

        VerticalSliceWaveSim.StartSingleWave(lowState, config, new List<string>());
        VerticalSliceWaveSim.Step(lowState, config, deltaSeconds: 0f, typedInput: null, new List<string>());

        VerticalSliceWaveSim.StartSingleWave(highState, config, new List<string>());
        VerticalSliceWaveSim.Step(highState, config, deltaSeconds: 0f, typedInput: null, new List<string>());

        string lowKind = lowState.Enemies[0].GetValueOrDefault("kind")?.ToString() ?? "";
        string highKind = highState.Enemies[0].GetValueOrDefault("kind")?.ToString() ?? "";
        int lowHp = Convert.ToInt32(lowState.Enemies[0].GetValueOrDefault("hp", 0));
        int highHp = Convert.ToInt32(highState.Enemies[0].GetValueOrDefault("hp", 0));

        Assert.Equal(lowKind, highKind);
        Assert.Equal(6, highHp - lowHp);
    }

    [Fact]
    public void DifficultyScaling_HarderWaveConfigCausesMoreDamageTaken()
    {
        var easyState = DefaultState.Create("wave_sim_pressure", placeStartingTowers: false);
        easyState.Hp = 200;
        var hardState = DefaultState.Create("wave_sim_pressure", placeStartingTowers: false);
        hardState.Hp = 200;

        var easy = new VerticalSliceWaveConfig
        {
            SpawnTotal = 4,
            SpawnIntervalSeconds = 2f,
            EnemyStepIntervalSeconds = 1f,
            EnemyStepDistance = 1,
            EnemyContactDamage = 1,
            TypedHitDamage = 2,
            TypedMissDamage = 0,
            TowerTickDamage = 0,
        };
        var hard = new VerticalSliceWaveConfig
        {
            SpawnTotal = 8,
            SpawnIntervalSeconds = 1f,
            EnemyStepIntervalSeconds = 1f,
            EnemyStepDistance = 2,
            EnemyContactDamage = 2,
            TypedHitDamage = 2,
            TypedMissDamage = 0,
            TowerTickDamage = 0,
        };

        VerticalSliceWaveSim.StartSingleWave(easyState, easy, new List<string>());
        RunNightToCompletion(easyState, easy, deltaSeconds: 1f, maxSteps: 300);

        VerticalSliceWaveSim.StartSingleWave(hardState, hard, new List<string>());
        RunNightToCompletion(hardState, hard, deltaSeconds: 1f, maxSteps: 300);

        Assert.Equal("victory", MetricString(easyState, ResultKey));
        Assert.Equal("victory", MetricString(hardState, ResultKey));
        Assert.True(
            MetricInt(hardState, DamageTakenKey) > MetricInt(easyState, DamageTakenKey),
            $"Expected harder config to deal more damage. easy={MetricInt(easyState, DamageTakenKey)} hard={MetricInt(hardState, DamageTakenKey)}");
    }

    [Fact]
    public void Determinism_SameSeedAndConfig_ProducesSameOutcome()
    {
        var first = DefaultState.Create("wave_sim_deterministic", placeStartingTowers: false);
        var second = DefaultState.Create("wave_sim_deterministic", placeStartingTowers: false);
        first.Hp = 300;
        second.Hp = 300;

        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 7,
            SpawnIntervalSeconds = 0.7f,
            EnemyStepIntervalSeconds = 0.5f,
            EnemyStepDistance = 2,
            EnemyContactDamage = 1,
            TypedHitDamage = 2,
            TypedMissDamage = 0,
            TowerTickDamage = 0,
        };

        var firstSnapshots = new List<string>();
        var secondSnapshots = new List<string>();

        VerticalSliceWaveSim.StartSingleWave(first, config, new List<string>());
        RunNightToCompletion(first, config, deltaSeconds: 0.5f, maxSteps: 400, snapshots: firstSnapshots);

        VerticalSliceWaveSim.StartSingleWave(second, config, new List<string>());
        RunNightToCompletion(second, config, deltaSeconds: 0.5f, maxSteps: 400, snapshots: secondSnapshots);

        Assert.Equal(firstSnapshots, secondSnapshots);
        Assert.Equal(first.Phase, second.Phase);
        Assert.Equal(first.Hp, second.Hp);
        Assert.Equal(first.Gold, second.Gold);
        Assert.Equal(first.EnemiesDefeated, second.EnemiesDefeated);
        Assert.Equal(MetricString(first, ResultKey), MetricString(second, ResultKey));
        Assert.Equal(MetricInt(first, DamageTakenKey), MetricInt(second, DamageTakenKey));
        Assert.Equal(MetricInt(first, ScoreKey), MetricInt(second, ScoreKey));
        Assert.Equal(MetricInt(first, ElapsedSecondsKey), MetricInt(second, ElapsedSecondsKey));
    }

    private static int RunNightToCompletion(
        GameState state,
        VerticalSliceWaveConfig config,
        float deltaSeconds,
        int maxSteps,
        List<string>? snapshots = null)
    {
        var events = new List<string>();
        int steps = 0;

        while (state.Phase == "night" && steps < maxSteps)
        {
            events.Clear();
            VerticalSliceWaveSim.Step(state, config, deltaSeconds, typedInput: null, events);
            snapshots?.Add(
                $"{state.Phase}|{state.NightSpawnRemaining}|{state.Enemies.Count}|{state.Hp}|{state.RngState}");
            steps++;
        }

        Assert.NotEqual("night", state.Phase);
        return steps;
    }

    private static int MetricInt(GameState state, string key, int fallback = 0)
    {
        if (!state.TypingMetrics.TryGetValue(key, out object? value) || value == null)
            return fallback;

        if (value is int intValue)
            return intValue;

        return int.TryParse(value.ToString(), out int parsed) ? parsed : fallback;
    }

    private static string MetricString(GameState state, string key, string fallback = "")
    {
        if (!state.TypingMetrics.TryGetValue(key, out object? value) || value == null)
            return fallback;

        return value.ToString() ?? fallback;
    }

    private static int CountMatchingEvents(List<string> events, string prefix)
    {
        int count = 0;
        foreach (string e in events)
        {
            if (e.StartsWith(prefix, StringComparison.Ordinal))
                count++;
        }
        return count;
    }

    private static Dictionary<string, object> CreateEnemy(int id, int hp, int dist, int gold)
    {
        return new Dictionary<string, object>
        {
            ["id"] = id,
            ["kind"] = "raider",
            ["word"] = "candle",
            ["hp"] = hp,
            ["dist"] = dist,
            ["gold"] = gold,
        };
    }
}
