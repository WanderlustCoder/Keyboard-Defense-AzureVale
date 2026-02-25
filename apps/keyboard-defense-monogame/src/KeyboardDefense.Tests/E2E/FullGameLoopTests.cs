using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.E2E;

public class FullGameLoopTests
{
    [Fact]
    public void DefaultState_InitializesForGameLoop()
    {
        var state = DefaultState.Create("full_loop_default", placeStartingTowers: true);

        Assert.Equal("day", state.Phase);
        Assert.Equal("exploration", state.ActivityMode);
        Assert.Equal(state.BasePos, state.PlayerPos);
        Assert.True(state.Ap > 0);
        Assert.True(state.RoamingEnemies.Count > 0);
    }

    [Fact]
    public void WorldTick_MultipleTicks_AdvanceTimeOfDay()
    {
        var state = DefaultState.Create("full_loop_ticks", placeStartingTowers: true);
        float initialTime = state.TimeOfDay;

        var result = WorldTick.Tick(state, 6.0);

        Assert.True(Convert.ToBoolean(result["changed"]));
        Assert.InRange(state.TimeOfDay, initialTime + 0.119f, initialTime + 0.121f);
        Assert.InRange(state.WorldTickAccum, 0f, 0.999f);
    }

    [Fact]
    public void IntentApplier_MovePlayer_UpdatesPlayerAndCursor()
    {
        var state = DefaultState.Create("full_loop_move", placeStartingTowers: true);
        var (dx, dy, target) = FindPassableNeighborStep(state);

        var result = IntentApplier.Apply(state, SimIntents.Make("move_player", new()
        {
            ["dx"] = dx,
            ["dy"] = dy,
        }));
        var moved = (GameState)result["state"];

        Assert.Equal(target, moved.PlayerPos);
        Assert.Equal(target, moved.CursorPos);
    }

    [Fact]
    public void WorldTick_NearbyEnemy_TriggersEncounterMode()
    {
        var state = DefaultState.Create("full_loop_encounter_trigger", placeStartingTowers: true);
        state.ActivityMode = "exploration";
        state.RoamingEnemies.Clear();
        AddRoamingEnemy(state, state.PlayerPos, hp: 1);

        state.WorldTickAccum = 1.0f;
        var tickResult = WorldTick.Tick(state, 0);
        var tickEvents = tickResult.GetValueOrDefault("events") as List<string> ?? new();

        Assert.Equal("encounter", state.ActivityMode);
        Assert.NotEmpty(state.EncounterEnemies);
        Assert.Contains(tickEvents, e => e.Contains("Encounter!", StringComparison.OrdinalIgnoreCase));
        Assert.False(string.IsNullOrWhiteSpace(state.EncounterEnemies[0].GetValueOrDefault("word")?.ToString()));
    }

    [Fact]
    public void EncounterCombat_TypingWord_ResolvesEncounterAndAwardsGold()
    {
        var state = DefaultState.Create("full_loop_encounter_resolve", placeStartingTowers: true);
        int goldBefore = state.Gold;

        state.ActivityMode = "encounter";
        state.EncounterEnemies.Clear();
        state.EncounterEnemies.Add(new Dictionary<string, object>
        {
            ["id"] = state.EnemyNextId++,
            ["kind"] = "scout",
            ["word"] = "oak",
            ["hp"] = 1,
            ["tier"] = 0,
            ["pos"] = state.PlayerPos,
        });

        var events = InlineCombat.ProcessTyping(state, "oak");

        Assert.Contains(events, e => e.Contains("Defeated", StringComparison.OrdinalIgnoreCase));
        Assert.Equal("exploration", state.ActivityMode);
        Assert.Empty(state.EncounterEnemies);
        Assert.Equal(1, state.EnemiesDefeated);
        Assert.True(state.Gold > goldBefore);
    }

    [Fact]
    public void DayNightCycle_EndDayAndResolveNight_ReturnsToDay()
    {
        var sim = new GameSimulator("full_loop_day_night");
        int apMax = sim.State.ApMax;

        sim.EndDay();
        Assert.Equal("night", sim.State.Phase);
        Assert.True(sim.State.NightWaveTotal > 0);

        RunNightWithGuaranteedKills(sim, maxSteps: 250);

        Assert.Equal("day", sim.State.Phase);
        Assert.Equal(apMax, sim.State.Ap);
        Assert.Equal(0, sim.State.NightWaveTotal);
        Assert.True(sim.State.Hp > 0);
    }

    [Fact]
    public void Resources_AccumulateAcrossDayNightCycles()
    {
        var sim = new GameSimulator("full_loop_resources");
        int woodBefore = sim.State.Resources.GetValueOrDefault("wood", 0);
        int stoneBefore = sim.State.Resources.GetValueOrDefault("stone", 0);
        int goldBefore = sim.State.Gold;

        for (int cycle = 0; cycle < 2; cycle++)
        {
            sim.Apply(SimIntents.Make("gather", new() { ["resource"] = "wood", ["amount"] = 4 }));
            sim.Apply(SimIntents.Make("gather", new() { ["resource"] = "stone", ["amount"] = 2 }));
            sim.EndDay();
            RunNightWithGuaranteedKills(sim, maxSteps: 250);
        }

        Assert.True(sim.State.Resources.GetValueOrDefault("wood", 0) >= woodBefore + 8);
        Assert.True(sim.State.Resources.GetValueOrDefault("stone", 0) >= stoneBefore + 4);
        Assert.True(sim.State.Gold >= goldBefore);
    }

    [Fact]
    public void WorldTick_TimeOfDay_WrapsAcrossFullCycle()
    {
        var state = DefaultState.Create("full_loop_time_wrap", placeStartingTowers: true);
        state.TimeOfDay = 0.95f;

        WorldTick.Tick(state, 3.0);

        Assert.InRange(state.TimeOfDay, 0.009f, 0.011f);
    }

    [Fact]
    public void SaveLoad_MidGameRoundTrip_PreservesState()
    {
        var sim = new GameSimulator("full_loop_save_load");
        var (dx, dy, target) = FindPassableNeighborStep(sim.State);

        sim.Apply(SimIntents.Make("move_player", new()
        {
            ["dx"] = dx,
            ["dy"] = dy,
        }));
        sim.Apply(SimIntents.Make("gather", new() { ["resource"] = "wood", ["amount"] = 5 }));
        sim.EndDay();
        sim.Wait();
        WorldTick.Tick(sim.State, 4.0);

        string json = SaveManager.StateToJson(sim.State);
        var (ok, loaded, error) = SaveManager.StateFromJson(json);

        Assert.True(ok, error ?? "Save/load round-trip failed");
        Assert.NotNull(loaded);
        Assert.Equal(sim.State.Day, loaded!.Day);
        Assert.Equal(sim.State.Phase, loaded.Phase);
        Assert.Equal(sim.State.Hp, loaded.Hp);
        Assert.Equal(sim.State.Gold, loaded.Gold);
        Assert.Equal(sim.State.PlayerPos, loaded.PlayerPos);
        Assert.Equal(target, loaded.PlayerPos);
        Assert.Equal(sim.State.CursorPos, loaded.CursorPos);
        Assert.Equal(sim.State.Resources.GetValueOrDefault("wood", 0), loaded.Resources.GetValueOrDefault("wood", 0));
        Assert.Equal(sim.State.NightSpawnRemaining, loaded.NightSpawnRemaining);
        Assert.Equal(sim.State.Enemies.Count, loaded.Enemies.Count);
        Assert.Equal(sim.State.TimeOfDay, loaded.TimeOfDay, 0.001f);
    }

    [Fact]
    public void FullLoop_MovementEncounterNightAndSaveLoad_RemainsConsistent()
    {
        var sim = new GameSimulator("full_loop_integration");
        int startingGold = sim.State.Gold;

        var (dx, dy, _) = FindPassableNeighborStep(sim.State);
        sim.Apply(SimIntents.Make("move_player", new()
        {
            ["dx"] = dx,
            ["dy"] = dy,
        }));

        sim.State.RoamingEnemies.Clear();
        AddRoamingEnemy(sim.State, sim.State.PlayerPos, hp: 1);
        sim.State.WorldTickAccum = 1.0f;
        WorldTick.Tick(sim.State, 0);
        Assert.Equal("encounter", sim.State.ActivityMode);

        string encounterWord = sim.State.EncounterEnemies[0].GetValueOrDefault("word")?.ToString() ?? "";
        Assert.False(string.IsNullOrWhiteSpace(encounterWord));
        InlineCombat.ProcessTyping(sim.State, encounterWord);
        Assert.Equal("exploration", sim.State.ActivityMode);

        sim.Apply(SimIntents.Make("gather", new() { ["resource"] = "wood", ["amount"] = 3 }));
        sim.EndDay();
        RunNightWithGuaranteedKills(sim, maxSteps: 250);

        string json = SaveManager.StateToJson(sim.State);
        var (ok, loaded, error) = SaveManager.StateFromJson(json);

        Assert.True(ok, error ?? "Save/load round-trip failed");
        Assert.NotNull(loaded);
        Assert.Equal("day", loaded!.Phase);
        Assert.True(loaded.EnemiesDefeated >= 1);
        Assert.True(loaded.Gold >= startingGold);
        Assert.True(sim.AllEvents.Count > 0);
    }

    private static void AddRoamingEnemy(GameState state, GridPoint position, int hp)
    {
        state.RoamingEnemies.Add(new Dictionary<string, object>
        {
            ["id"] = state.EnemyNextId++,
            ["kind"] = "scout",
            ["pos"] = position,
            ["hp"] = hp,
            ["tier"] = 0,
            ["damage"] = 1,
            ["speed"] = 1,
            ["zone"] = SimMap.ZoneSafe,
            ["patrol_origin"] = position,
        });
    }

    private static (int Dx, int Dy, GridPoint Target) FindPassableNeighborStep(GameState state)
    {
        var steps = new (int dx, int dy)[]
        {
            (1, 0),
            (-1, 0),
            (0, 1),
            (0, -1),
        };

        foreach (var step in steps)
        {
            var next = new GridPoint(state.PlayerPos.X + step.dx, state.PlayerPos.Y + step.dy);
            if (!SimMap.InBounds(next.X, next.Y, state.MapW, state.MapH))
                continue;
            if (SimMap.IsPassable(state, next))
                return (step.dx, step.dy, next);
        }

        throw new InvalidOperationException("No passable adjacent tile found for movement test.");
    }

    private static void RunNightWithGuaranteedKills(GameSimulator sim, int maxSteps)
    {
        for (int step = 0; step < maxSteps; step++)
        {
            if (sim.State.Phase != "night")
                return;

            if (sim.State.Enemies.Count == 0)
            {
                sim.Wait();
                continue;
            }

            sim.State.Enemies[0]["hp"] = 1;
            string? word = sim.FirstEnemyWord();
            if (string.IsNullOrWhiteSpace(word))
            {
                sim.Wait();
                continue;
            }

            sim.TypeWord(word);
        }

        Assert.True(sim.State.Phase != "night", "Night did not resolve within the allotted simulation steps.");
    }
}
