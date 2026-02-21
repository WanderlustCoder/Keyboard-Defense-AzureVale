using System;
using System.Collections.Generic;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class PoiCoreTests
{
    [Fact]
    public void LoadPois_GetPoiDef_ReturnsDefinitionForKnownId()
    {
        var defs = new Dictionary<string, Dictionary<string, object>>
        {
            ["watchtower"] = new()
            {
                ["title"] = "Old Watchtower",
                ["description"] = "Scouts once stood guard."
            }
        };

        Poi.LoadPois(defs);

        var def = Poi.GetPoiDef("watchtower");

        Assert.NotNull(def);
        Assert.Equal("Old Watchtower", def["title"]);
        Assert.Equal("Scouts once stood guard.", def["description"]);
    }

    [Fact]
    public void GetPoiDef_UnknownId_ReturnsNull()
    {
        Poi.LoadPois(new Dictionary<string, Dictionary<string, object>>
        {
            ["shrine"] = new()
        });

        var def = Poi.GetPoiDef("unknown_poi");

        Assert.Null(def);
    }

    [Fact]
    public void LoadPois_ReplacesPreviousDefinitions()
    {
        Poi.LoadPois(new Dictionary<string, Dictionary<string, object>>
        {
            ["old_poi"] = new() { ["title"] = "Old" }
        });

        Poi.LoadPois(new Dictionary<string, Dictionary<string, object>>
        {
            ["new_poi"] = new() { ["title"] = "New" }
        });

        Assert.Null(Poi.GetPoiDef("old_poi"));
        Assert.NotNull(Poi.GetPoiDef("new_poi"));
    }

    [Fact]
    public void SpawnPoi_AddsPoiWithExpectedPositionAndDiscoveredDay()
    {
        var state = CreateState();
        state.Day = 7;
        var pos = new GridPoint(10, 12);

        Poi.SpawnPoi(state, "watchtower", pos);

        Assert.True(state.ActivePois.ContainsKey("watchtower"));
        var poi = state.ActivePois["watchtower"];
        Assert.Equal(pos, (GridPoint)poi["pos"]);
        Assert.Equal(7, Convert.ToInt32(poi["discovered_day"]));
    }

    [Fact]
    public void SpawnPoi_MergesProvidedDataIntoPoiState()
    {
        var state = CreateState();

        Poi.SpawnPoi(state, "shrine", new GridPoint(5, 6), new Dictionary<string, object>
        {
            ["zone"] = "safe",
            ["event_id"] = "poi_shrine",
            ["rarity"] = "rare"
        });

        var poi = state.ActivePois["shrine"];
        Assert.Equal("safe", poi["zone"]);
        Assert.Equal("poi_shrine", poi["event_id"]);
        Assert.Equal("rare", poi["rarity"]);
        Assert.Equal(new GridPoint(5, 6), (GridPoint)poi["pos"]);
    }

    [Fact]
    public void SpawnPoi_ProvidedDataCanOverrideDefaultFields()
    {
        var state = CreateState();
        state.Day = 4;

        Poi.SpawnPoi(state, "mine", new GridPoint(1, 1), new Dictionary<string, object>
        {
            ["pos"] = new GridPoint(9, 9),
            ["discovered_day"] = 42
        });

        var poi = state.ActivePois["mine"];
        Assert.Equal(new GridPoint(9, 9), (GridPoint)poi["pos"]);
        Assert.Equal(42, Convert.ToInt32(poi["discovered_day"]));
    }

    [Fact]
    public void SpawnPoi_MultiplePoisAccumulate()
    {
        var state = CreateState();

        Poi.SpawnPoi(state, "watchtower", new GridPoint(2, 2));
        Poi.SpawnPoi(state, "shrine", new GridPoint(3, 4));

        Assert.Equal(2, state.ActivePois.Count);
        Assert.True(state.ActivePois.ContainsKey("watchtower"));
        Assert.True(state.ActivePois.ContainsKey("shrine"));
    }

    [Fact]
    public void SpawnPoi_SamePoiIdOverwritesExistingEntry()
    {
        var state = CreateState();
        state.Day = 3;
        Poi.SpawnPoi(state, "campfire", new GridPoint(1, 2));

        state.Day = 9;
        Poi.SpawnPoi(state, "campfire", new GridPoint(7, 8), new Dictionary<string, object> { ["zone"] = "frontier" });

        Assert.Single(state.ActivePois);
        var poi = state.ActivePois["campfire"];
        Assert.Equal(new GridPoint(7, 8), (GridPoint)poi["pos"]);
        Assert.Equal(9, Convert.ToInt32(poi["discovered_day"]));
        Assert.Equal("frontier", poi["zone"]);
    }

    [Fact]
    public void HasActivePoi_WhenPresent_ReturnsTrue()
    {
        var state = CreateState();
        Poi.SpawnPoi(state, "watchtower", new GridPoint(4, 4));

        Assert.True(Poi.HasActivePoi(state, "watchtower"));
    }

    [Fact]
    public void HasActivePoi_WhenAbsent_ReturnsFalse()
    {
        var state = CreateState();

        Assert.False(Poi.HasActivePoi(state, "watchtower"));
    }

    [Fact]
    public void RemovePoi_RemovesCorrectPoiById()
    {
        var state = CreateState();
        Poi.SpawnPoi(state, "watchtower", new GridPoint(4, 5));

        Poi.RemovePoi(state, "watchtower");

        Assert.False(state.ActivePois.ContainsKey("watchtower"));
        Assert.Empty(state.ActivePois);
    }

    [Fact]
    public void RemovePoi_OnNonExistentId_DoesNothing()
    {
        var state = CreateState();
        Poi.SpawnPoi(state, "watchtower", new GridPoint(4, 5));

        Poi.RemovePoi(state, "missing");

        Assert.Single(state.ActivePois);
        Assert.True(state.ActivePois.ContainsKey("watchtower"));
    }

    [Fact]
    public void RemovePoi_WithMultiplePois_RemovesOnlyTarget()
    {
        var state = CreateState();
        Poi.SpawnPoi(state, "watchtower", new GridPoint(2, 2));
        Poi.SpawnPoi(state, "mine", new GridPoint(3, 3));
        Poi.SpawnPoi(state, "shrine", new GridPoint(4, 4));

        Poi.RemovePoi(state, "mine");

        Assert.Equal(2, state.ActivePois.Count);
        Assert.True(state.ActivePois.ContainsKey("watchtower"));
        Assert.False(state.ActivePois.ContainsKey("mine"));
        Assert.True(state.ActivePois.ContainsKey("shrine"));
    }

    [Fact]
    public void InteractWithPoi_OnNonExistentPoi_ReturnsNotFound()
    {
        var state = CreateState();

        var result = Poi.InteractWithPoi(state, "missing");

        Assert.False(Convert.ToBoolean(result["ok"]));
        Assert.Equal("POI not found.", result["error"]);
    }

    [Fact]
    public void InteractWithPoi_WithoutEventId_ReturnsError()
    {
        var state = CreateState();
        Poi.SpawnPoi(state, "watchtower", new GridPoint(5, 5));

        var result = Poi.InteractWithPoi(state, "watchtower");

        Assert.False(Convert.ToBoolean(result["ok"]));
        Assert.Equal("POI has no event.", result["error"]);
        Assert.Empty(state.PendingEvent);
    }

    [Fact]
    public void InteractWithPoi_UnknownPoiDefinition_ReturnsError()
    {
        var state = CreateState();
        Poi.LoadPois(new Dictionary<string, Dictionary<string, object>>());
        Poi.SpawnPoi(state, "watchtower", new GridPoint(5, 5), new Dictionary<string, object> { ["event_id"] = "poi_watchtower" });

        var result = Poi.InteractWithPoi(state, "watchtower");

        Assert.False(Convert.ToBoolean(result["ok"]));
        Assert.Equal("Unknown POI type.", result["error"]);
        Assert.Empty(state.PendingEvent);
    }

    [Fact]
    public void InteractWithPoi_ValidPoi_TriggersEventAndSetsPendingEvent()
    {
        var state = CreateState();
        Poi.LoadPois(new Dictionary<string, Dictionary<string, object>>
        {
            ["shrine"] = new()
            {
                ["title"] = "Ancient Shrine",
                ["description"] = "Read the carvings.",
                ["choices"] = new List<object>
                {
                    new Dictionary<string, object> { ["text"] = "Pray", ["effects"] = new List<object>() }
                }
            }
        });

        Poi.SpawnPoi(state, "shrine", new GridPoint(8, 9), new Dictionary<string, object> { ["event_id"] = "poi_shrine" });

        var result = Poi.InteractWithPoi(state, "shrine");

        Assert.True(Convert.ToBoolean(result["ok"]));
        Assert.Equal("Event triggered: Ancient Shrine", result["message"]);
        Assert.Equal("poi_shrine", state.PendingEvent["event_id"]);
        Assert.Equal("Ancient Shrine", state.PendingEvent["title"]);
        Assert.Equal("Read the carvings.", state.PendingEvent["description"]);
        var choices = Assert.IsType<List<object>>(state.PendingEvent["choices"]);
        Assert.Single(choices);
    }

    [Fact]
    public void GetActivePoiIds_ReturnsEmptyWhenNoPois()
    {
        var state = CreateState();

        var ids = Poi.GetActivePoiIds(state);

        Assert.Empty(ids);
    }

    [Fact]
    public void GetActivePoiIds_ReturnsAllActivePoiIds()
    {
        var state = CreateState();
        Poi.SpawnPoi(state, "watchtower", new GridPoint(1, 1));
        Poi.SpawnPoi(state, "shrine", new GridPoint(2, 2));

        var ids = Poi.GetActivePoiIds(state);

        Assert.Equal(2, ids.Count);
        Assert.Contains("watchtower", ids);
        Assert.Contains("shrine", ids);
    }

    private static GameState CreateState()
    {
        var state = DefaultState.Create("poi_core_tests");
        state.ActivePois.Clear();
        state.PendingEvent.Clear();
        return state;
    }
}
