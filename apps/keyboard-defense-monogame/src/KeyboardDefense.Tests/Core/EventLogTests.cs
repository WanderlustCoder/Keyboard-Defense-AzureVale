using System;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;
using KeyboardDefense.Game.Rendering;

namespace KeyboardDefense.Tests.Core;

public class EventLogTests
{
    [Fact]
    public void BuildPlacementEvent_CreatesLogEntry()
    {
        var state = CreateState();
        var buildPos = new GridPoint(state.BasePos.X + 1, state.BasePos.Y);
        int buildIndex = state.Index(buildPos.X, buildPos.Y);
        state.Discovered.Add(buildIndex);
        state.Terrain[buildIndex] = SimMap.TerrainPlains;
        state.Structures.Remove(buildIndex);

        foreach (string key in GameState.ResourceKeys)
            state.Resources[key] = 999;

        var result = IntentApplier.Apply(state, SimIntents.Make("build", new()
        {
            ["building"] = "tower",
            ["x"] = buildPos.X,
            ["y"] = buildPos.Y
        }));

        var events = GetEvents(result);
        Assert.Contains(events, e => e.Contains($"Built tower at ({buildPos.X},{buildPos.Y}).", StringComparison.Ordinal));
    }

    [Fact]
    public void EnemyKilledEvent_CreatesLogEntry()
    {
        var state = CreateState();
        state.Phase = "night";
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();
        state.Enemies.Add(new Dictionary<string, object>
        {
            ["id"] = 1,
            ["kind"] = "scout",
            ["word"] = "alpha",
            ["hp"] = 1,
            ["damage"] = 1,
            ["dist"] = 10,
            ["gold"] = 3,
        });

        var result = IntentApplier.Apply(state, SimIntents.Make("defend_input", new()
        {
            ["text"] = "alpha"
        }));

        var events = GetEvents(result);
        Assert.Contains(events, e => e.Contains("Enemy defeated!", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public void QuestCompletedEvent_CreatesLogEntry()
    {
        var state = CreateState();
        state.Day = 0;
        state.Discovered.Clear();
        state.Discovered.Add(state.Index(state.BasePos.X, state.BasePos.Y));

        var towerPos = new GridPoint(state.BasePos.X + 1, state.BasePos.Y);
        int towerIndex = state.Index(towerPos.X, towerPos.Y);
        state.Structures[towerIndex] = "tower";

        var events = NpcInteraction.CompleteReadyQuests(state);
        Assert.Contains(events, e => e.Contains("Quest complete: First Defense!", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public void DayAdvanceEvent_IncludesDayNumberTimestamp()
    {
        var state = CreateState();
        state.Day = 6;

        var result = SimTick.AdvanceDay(state);
        var events = GetEvents(result);

        Assert.Equal(7, state.Day);
        Assert.Contains($"Day advanced to {state.Day}.", events);
    }

    [Fact]
    public void EventLogOverlay_DropsOldestEntries_WhenMaxCapacityExceeded()
    {
        var state = CreateState();
        var overlay = new EventLogOverlay();

        for (int i = 1; i <= 20; i++)
            overlay.Append($"Day {state.Day}: event {i}");

        var messages = GetOverlayMessages(overlay);
        Assert.Equal(15, messages.Count);
        Assert.Equal("Day 1: event 6", messages[0]);
        Assert.Equal("Day 1: event 20", messages[^1]);
    }

    [Fact]
    public void WaveAssaultNightEnd_EmitsCombatSummaryLogEntry()
    {
        var state = CreateState();
        int dayBefore = state.Day;
        state.ActivityMode = "wave_assault";
        state.Phase = "night";
        state.NightWaveTotal = 5;
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();

        var result = WorldTick.Tick(state, WorldTick.WorldTickInterval);
        var events = GetEvents(result);

        Assert.Contains(events, e => e.Contains("Wave repelled!", StringComparison.OrdinalIgnoreCase));
        Assert.Equal("day", state.Phase);
        Assert.Equal("exploration", state.ActivityMode);
        Assert.Equal(dayBefore + 1, state.Day);
    }

    [Fact]
    public void GatherAction_LogsResourceChangeEvent()
    {
        var state = CreateState();
        state.Resources["wood"] = 0;
        state.Ap = state.ApMax;

        var result = IntentApplier.Apply(state, SimIntents.Make("gather", new()
        {
            ["resource"] = "wood",
            ["amount"] = 4
        }));

        var events = GetEvents(result);
        var newState = GetState(result);
        Assert.Contains("Gathered 4 wood.", events);
        Assert.Equal(4, newState.Resources["wood"]);
    }

    [Fact]
    public void EndIntent_LogsDayToNightPhaseTransition()
    {
        var state = CreateState();
        state.Phase = "day";

        var result = IntentApplier.Apply(state, SimIntents.Make("end"));
        var events = GetEvents(result);
        var newState = GetState(result);

        Assert.Contains(events, e => e.StartsWith("Night falls. Enemy wave:", StringComparison.Ordinal));
        Assert.Equal("night", newState.Phase);
    }

    [Fact]
    public void NightCompletion_LogsNightToDayPhaseTransition()
    {
        var state = CreateState();
        state.Phase = "night";
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();

        var result = IntentApplier.Apply(state, SimIntents.Make("wait"));
        var events = GetEvents(result);
        var newState = GetState(result);

        Assert.Contains("Dawn breaks.", events);
        Assert.Equal("day", newState.Phase);
    }

    private static GameState CreateState()
        => DefaultState.Create($"event_log_tests_{Guid.NewGuid():N}", placeStartingTowers: false, useWorldSpec: false);

    private static GameState GetState(Dictionary<string, object> result)
        => Assert.IsType<GameState>(result["state"]);

    private static List<string> GetEvents(Dictionary<string, object> result)
        => Assert.IsType<List<string>>(result["events"]);

    private static List<string> GetOverlayMessages(EventLogOverlay overlay)
    {
        var entriesField = typeof(EventLogOverlay).GetField("_entries", BindingFlags.Instance | BindingFlags.NonPublic);
        Assert.NotNull(entriesField);

        var entries = Assert.IsAssignableFrom<IList>(entriesField!.GetValue(overlay));
        var messages = new List<string>(entries.Count);

        foreach (var entry in entries)
        {
            Assert.NotNull(entry);
            var messageProperty = entry!.GetType().GetProperty("Message", BindingFlags.Instance | BindingFlags.Public);
            Assert.NotNull(messageProperty);
            string? message = messageProperty!.GetValue(entry)?.ToString();
            Assert.False(string.IsNullOrEmpty(message));
            messages.Add(message!);
        }

        return messages;
    }
}
