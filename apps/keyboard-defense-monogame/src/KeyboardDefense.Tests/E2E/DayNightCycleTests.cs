using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.E2E;

public class DayNightCycleTests
{
    [Fact]
    public void DayPhase_ExploreBuildTrade_AreAvailableAndManageAp()
    {
        var state = DefaultState.Create("e2e_day_actions");
        Assert.Equal("day", state.Phase);
        Assert.Equal(state.ApMax, state.Ap);

        int discoveredBefore = state.Discovered.Count;
        int apBeforeExplore = state.Ap;
        var (afterExplore, exploreEvents) = Apply(state, "explore");

        Assert.Equal("day", afterExplore.Phase);
        Assert.Equal(apBeforeExplore - 1, afterExplore.Ap);
        Assert.True(afterExplore.Discovered.Count >= discoveredBefore);
        Assert.Contains(exploreEvents, e => e.Contains("Discovered tile", StringComparison.OrdinalIgnoreCase));

        var buildPos = PrepareBuildableTile(afterExplore);
        int buildIdx = SimMap.Idx(buildPos.X, buildPos.Y, afterExplore.MapW);
        afterExplore.Resources["wood"] = 200;
        afterExplore.Resources["stone"] = 200;
        int apBeforeBuild = afterExplore.Ap;
        var (afterBuild, buildEvents) = Apply(afterExplore, "build", new()
        {
            ["building"] = "tower",
            ["x"] = buildPos.X,
            ["y"] = buildPos.Y,
        });

        Assert.Equal(apBeforeBuild - 1, afterBuild.Ap);
        Assert.Equal("tower", afterBuild.Structures[buildIdx]);
        Assert.Contains(buildEvents, e => e.Contains("Built tower", StringComparison.OrdinalIgnoreCase));

        afterBuild.Resources["wood"] = 40;
        afterBuild.Resources["stone"] = 0;
        int apBeforeTrade = afterBuild.Ap;
        var (afterTrade, tradeEvents) = Apply(afterBuild, "trade_execute", new()
        {
            ["from_resource"] = "wood",
            ["to_resource"] = "stone",
            ["amount"] = 10,
        });

        Assert.Equal(apBeforeTrade, afterTrade.Ap);
        Assert.Equal(30, afterTrade.Resources["wood"]);
        Assert.True(afterTrade.Resources["stone"] > 0);
        Assert.Contains(tradeEvents, e => e.Contains("Traded 10 wood", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public void EndDay_TransitionsToNightAndQueuesWave()
    {
        var state = DefaultState.Create("e2e_day_to_night");
        state.Threat = 4;

        var (nightState, events) = Apply(state, "end");

        Assert.Equal("night", nightState.Phase);
        Assert.Equal(0, nightState.Ap);
        Assert.True(nightState.NightWaveTotal > 0);
        Assert.True(nightState.NightSpawnRemaining > 0);
        Assert.Contains(events, e => e.Contains("Night falls", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public void NightTransition_FirstWaitSpawnsEnemyAndBeginsCombat()
    {
        var state = DefaultState.Create("e2e_night_spawn");
        var (nightState, _) = Apply(state, "end");
        int spawnBefore = nightState.NightSpawnRemaining;

        var (afterWait, events) = Apply(nightState, "wait");

        Assert.Equal("night", afterWait.Phase);
        Assert.NotEmpty(afterWait.Enemies);
        Assert.True(afterWait.NightSpawnRemaining < spawnBefore);
        int enemyDist = Convert.ToInt32(afterWait.Enemies[0].GetValueOrDefault("dist", 10));
        Assert.Equal(9, enemyDist);
        Assert.Contains(events, e => e.Contains("Enemy spawned", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public void NightCombat_TypingEnemyWord_ResolvesCombatAndAwardsGold()
    {
        var state = DefaultState.Create("e2e_night_defend");
        var (nightState, _) = Apply(state, "end");
        var (spawnedState, _) = Apply(nightState, "wait");

        Assert.NotEmpty(spawnedState.Enemies);
        string word = spawnedState.Enemies[0].GetValueOrDefault("word")?.ToString() ?? "";
        Assert.False(string.IsNullOrWhiteSpace(word));

        spawnedState.Enemies[0]["hp"] = 1;
        int defeatedBefore = spawnedState.EnemiesDefeated;
        int goldBefore = spawnedState.Gold;

        var (afterDefend, events) = Apply(spawnedState, "defend_input", new() { ["text"] = word });

        Assert.Contains(events, e => e.Contains("Typed", StringComparison.OrdinalIgnoreCase));
        Assert.True(afterDefend.EnemiesDefeated > defeatedBefore);
        Assert.True(afterDefend.Gold > goldBefore);
    }

    [Fact]
    public void NightPhase_AutoTowerFiresAndCanFinishNight()
    {
        var state = DefaultState.Create("e2e_tower_fire", placeStartingTowers: true);
        state.Phase = "night";
        state.NightWaveTotal = 1;
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();
        state.Enemies.Add(new Dictionary<string, object>
        {
            ["kind"] = "scout",
            ["word"] = "ash",
            ["hp"] = 1,
            ["gold"] = 4,
            ["damage"] = 1,
            ["dist"] = 10,
        });

        int goldBefore = state.Gold;
        var (afterWait, events) = Apply(state, "wait");

        Assert.Contains(events, e => e.Contains("Auto-tower defeats enemy", StringComparison.OrdinalIgnoreCase));
        Assert.True(afterWait.Gold >= goldBefore + 4);
        Assert.Equal("day", afterWait.Phase);
    }

    [Fact]
    public void NightPhase_EnemyAtBaseDealsDamageBeforeDawn()
    {
        var state = DefaultState.Create("e2e_enemy_base_hit");
        state.Phase = "night";
        state.NightWaveTotal = 1;
        state.NightSpawnRemaining = 0;
        state.Hp = 10;
        state.Enemies.Clear();
        state.Enemies.Add(new Dictionary<string, object>
        {
            ["kind"] = "raider",
            ["word"] = "oak",
            ["hp"] = 2,
            ["gold"] = 1,
            ["damage"] = 2,
            ["dist"] = 1,
        });

        var (afterWait, events) = Apply(state, "wait");

        Assert.Equal(8, afterWait.Hp);
        Assert.Empty(afterWait.Enemies);
        Assert.Equal("day", afterWait.Phase);
        Assert.Contains(events, e => e.Contains("Enemy reached the base", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public void NightEnd_WaveAssaultCompletion_IncrementsDayAndAwardsResources()
    {
        var state = DefaultState.Create("e2e_wave_complete");
        state.ActivityMode = "wave_assault";
        state.Phase = "night";
        state.NightWaveTotal = 6;
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();
        state.Ap = 0;

        int dayBefore = state.Day;
        int wavesBefore = state.WavesSurvived;
        int goldBefore = state.Gold;
        int woodBefore = state.Resources.GetValueOrDefault("wood", 0);
        int stoneBefore = state.Resources.GetValueOrDefault("stone", 0);
        int foodBefore = state.Resources.GetValueOrDefault("food", 0);

        var tickResult = WorldTick.Tick(state, WorldTick.WorldTickInterval);
        var events = Assert.IsType<List<string>>(tickResult["events"]);

        Assert.Equal("exploration", state.ActivityMode);
        Assert.Equal("day", state.Phase);
        Assert.Equal(dayBefore + 1, state.Day);
        Assert.Equal(wavesBefore + 1, state.WavesSurvived);
        Assert.Equal(state.ApMax, state.Ap);
        Assert.True(state.Gold > goldBefore);
        Assert.True(state.Resources["wood"] > woodBefore);
        Assert.True(state.Resources["stone"] > stoneBefore);
        Assert.True(state.Resources["food"] > foodBefore);
        Assert.Contains(events, e => e.Contains("Wave repelled", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public void MultiDayProgression_FiveFullWaveCycles_AdvanceDayAndAccumulateRewards()
    {
        var state = DefaultState.Create("e2e_five_cycles");
        int dayStart = state.Day;
        int goldStart = state.Gold;
        int woodStart = state.Resources.GetValueOrDefault("wood", 0);
        int stoneStart = state.Resources.GetValueOrDefault("stone", 0);
        int foodStart = state.Resources.GetValueOrDefault("food", 0);

        for (int i = 0; i < 5; i++)
        {
            state.ActivityMode = "wave_assault";
            state.Phase = "night";
            state.NightWaveTotal = 4 + i;
            state.NightSpawnRemaining = 0;
            state.Enemies.Clear();
            state.Ap = 0;

            WorldTick.Tick(state, WorldTick.WorldTickInterval);
            Assert.Equal("day", state.Phase);
            Assert.Equal("exploration", state.ActivityMode);
        }

        Assert.Equal(dayStart + 5, state.Day);
        Assert.Equal(5, state.WavesSurvived);
        Assert.True(state.Gold > goldStart);
        Assert.True(state.Resources["wood"] > woodStart);
        Assert.True(state.Resources["stone"] > stoneStart);
        Assert.True(state.Resources["food"] > foodStart);
    }

    [Fact]
    public void ApManagement_ConsumesDuringDay_BlocksAtZero_AndRefillsAtDawn()
    {
        var state = DefaultState.Create("e2e_ap_management");
        int apMax = state.ApMax;

        for (int i = 0; i < apMax; i++)
        {
            (state, _) = Apply(state, "gather", new()
            {
                ["resource"] = "wood",
                ["amount"] = 1,
            });
        }

        Assert.Equal(0, state.Ap);

        var (blockedExploreState, blockedEvents) = Apply(state, "explore");
        Assert.Equal(0, blockedExploreState.Ap);
        Assert.Contains(blockedEvents, e => e.Contains("No action points remaining", StringComparison.OrdinalIgnoreCase));

        var (nightState, _) = Apply(blockedExploreState, "end");
        Assert.Equal("night", nightState.Phase);
        Assert.Equal(0, nightState.Ap);

        nightState.NightWaveTotal = 0;
        nightState.NightSpawnRemaining = 0;
        nightState.Enemies.Clear();
        var (dawnState, dawnEvents) = Apply(nightState, "wait");

        Assert.Equal("day", dawnState.Phase);
        Assert.Equal(apMax, dawnState.Ap);
        Assert.Contains(dawnEvents, e => e.Contains("Dawn breaks", StringComparison.OrdinalIgnoreCase));
    }

    private static (GameState State, List<string> Events) Apply(
        GameState state,
        string kind,
        Dictionary<string, object>? data = null)
    {
        var result = IntentApplier.Apply(state, SimIntents.Make(kind, data));
        var newState = Assert.IsType<GameState>(result["state"]);
        var events = Assert.IsType<List<string>>(result["events"]);
        return (newState, events);
    }

    private static GridPoint PrepareBuildableTile(GameState state)
    {
        var pos = new GridPoint(state.BasePos.X + 2, state.BasePos.Y);
        Assert.True(SimMap.InBounds(pos.X, pos.Y, state.MapW, state.MapH));
        int idx = SimMap.Idx(pos.X, pos.Y, state.MapW);
        state.Discovered.Add(idx);
        state.Terrain[idx] = SimMap.TerrainPlains;
        state.Structures.Remove(idx);
        state.StructureLevels.Remove(idx);
        return pos;
    }
}
