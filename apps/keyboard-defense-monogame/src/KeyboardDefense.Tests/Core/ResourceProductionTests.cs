using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using KeyboardDefense.Core.Balance;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Economy;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

[Collection("StaticData")]
public class ResourceProductionTests
{
    [Fact]
    public void AdvanceDay_ProductionBuildingsAddResourcesEachDayTick()
    {
        var state = CreateState("resource_day_tick");
        AddStructure(state, 1, 0, "farm");
        AddStructure(state, 2, 0, "lumber");
        AddStructure(state, 3, 0, "quarry");

        int foodBefore = state.Resources.GetValueOrDefault("food", 0);
        int woodBefore = state.Resources.GetValueOrDefault("wood", 0);
        int stoneBefore = state.Resources.GetValueOrDefault("stone", 0);

        SimTick.AdvanceDay(state);

        Assert.Equal(foodBefore + 2, state.Resources["food"]);
        Assert.Equal(woodBefore + 2, state.Resources["wood"]);
        Assert.Equal(stoneBefore + 2, state.Resources["stone"]);
    }

    [Fact]
    public void BuildingsData_DailyProductionRateMatchesLoadedBuildingDefinitions()
    {
        LoadBuildingsData();
        var state = CreateState("resource_definition_rates");
        state.Buildings.Clear();
        state.Buildings["farm"] = 2;
        state.Buildings["lumber"] = 1;
        state.Buildings["quarry"] = 1;

        var farmDef = Assert.IsType<BuildingDef>(BuildingsData.GetBuilding("farm"));
        var lumberDef = Assert.IsType<BuildingDef>(BuildingsData.GetBuilding("lumber"));
        var quarryDef = Assert.IsType<BuildingDef>(BuildingsData.GetBuilding("quarry"));

        var production = BuildingsData.DailyProduction(state);

        Assert.Equal(farmDef.Production["food"] * 2, production["food"]);
        Assert.Equal(lumberDef.Production["wood"], production["wood"]);
        Assert.Equal(quarryDef.Production["stone"], production["stone"]);
    }

    [Fact]
    public void AdvanceDay_MultipleBuildingsOfSameTypeStackProduction()
    {
        var state = CreateState("resource_stack_same_type");
        AddStructure(state, 1, 0, "farm");
        AddStructure(state, 2, 0, "farm");
        AddStructure(state, 3, 0, "farm");
        int foodBefore = state.Resources.GetValueOrDefault("food", 0);

        SimTick.AdvanceDay(state);

        Assert.Equal(foodBefore + 6, state.Resources["food"]);
    }

    [Fact]
    public void AdvanceDay_DamagedBuildingRemovalReducesProduction()
    {
        var state = CreateState("resource_damage_reduces_output");
        int healthyIndex = AddStructure(state, 1, 0, "lumber");
        int damagedIndex = AddStructure(state, 2, 0, "lumber");

        int beforeFirstTick = state.Resources.GetValueOrDefault("wood", 0);
        SimTick.AdvanceDay(state);
        int firstTickGain = state.Resources.GetValueOrDefault("wood", 0) - beforeFirstTick;

        // Current pipeline uses active structures as producers; a damaged structure
        // is treated as unavailable for production.
        state.StructureLevels[damagedIndex] = 0;
        state.Structures.Remove(damagedIndex);
        int beforeSecondTick = state.Resources.GetValueOrDefault("wood", 0);
        SimTick.AdvanceDay(state);
        int secondTickGain = state.Resources.GetValueOrDefault("wood", 0) - beforeSecondTick;

        Assert.True(state.Structures.ContainsKey(healthyIndex));
        Assert.Equal(4, firstTickGain);
        Assert.Equal(2, secondTickGain);
        Assert.True(secondTickGain < firstTickGain);
    }

    [Fact]
    public void WorkerAssignmentsIncreaseEffectiveProductionMultiplier()
    {
        var state = CreateState("resource_workers_bonus");
        state.WorkerCount = 3;
        int farmIndex = AddStructure(state, 1, 0, "farm");
        const double baseFarmOutputPerTick = 2.0;

        Assert.True(Workers.AssignWorker(state, farmIndex));
        Assert.True(Workers.AssignWorker(state, farmIndex));

        double boostedOutput = baseFarmOutputPerTick * Workers.WorkerBonus(state, farmIndex);

        Assert.Equal(3.0, boostedOutput);
        Assert.True(boostedOutput > baseFarmOutputPerTick);
    }

    [Fact]
    public void AdvanceDay_ResourceCapsAreRespectedAfterProduction()
    {
        var state = CreateState("resource_caps");
        AddStructure(state, 1, 0, "lumber");
        state.Resources["wood"] = SimBalance.ResourceCap - 1;

        var result = SimTick.AdvanceDay(state);
        var events = Assert.IsType<List<string>>(result["events"]);

        Assert.Equal(SimBalance.ResourceCap, state.Resources["wood"]);
        Assert.Contains(events, e => e.Contains("Storage limits:", StringComparison.Ordinal));
        Assert.Contains(events, e => e.Contains("wood 1", StringComparison.Ordinal));
    }

    [Fact]
    public void WorldTick_DuringNightWaveAssault_DoesNotRunDayProduction()
    {
        var state = CreateState("resource_night_pause");
        AddStructure(state, 1, 0, "farm");
        AddStructure(state, 2, 0, "lumber");
        AddStructure(state, 3, 0, "quarry");
        var before = SnapshotCoreResources(state);

        state.ActivityMode = "wave_assault";
        state.Phase = "night";
        state.NightWaveTotal = 3;
        state.NightSpawnRemaining = 1;
        state.Enemies.Clear();

        WorldTick.Tick(state, WorldTick.WorldTickInterval);

        Assert.Equal("night", state.Phase);
        Assert.Equal("wave_assault", state.ActivityMode);
        foreach (var key in GameState.ResourceKeys)
            Assert.Equal(before[key], state.Resources.GetValueOrDefault(key, 0));
    }

    [Fact]
    public void AdvanceDay_ProductionMutatesOnlyGameStateResourceKeys()
    {
        var state = CreateState("resource_key_alignment");
        AddStructure(state, 1, 0, "farm");
        AddStructure(state, 2, 0, "market");
        var before = new Dictionary<string, int>(state.Resources, StringComparer.Ordinal);

        SimTick.AdvanceDay(state);

        var changedKeys = state.Resources
            .Where(kvp => kvp.Value != before.GetValueOrDefault(kvp.Key, 0))
            .Select(kvp => kvp.Key)
            .ToArray();

        Assert.NotEmpty(changedKeys);
        Assert.All(changedKeys, key => Assert.Contains(key, GameState.ResourceKeys));
        Assert.DoesNotContain("gold", changedKeys);
    }

    [Fact]
    public void BuildingsData_CoreProductionResourcesMatchGameStateResourceKeys()
    {
        LoadBuildingsData();
        var state = CreateState("resource_key_catalog_match");
        state.Buildings.Clear();
        state.Buildings["farm"] = 1;
        state.Buildings["lumber"] = 1;
        state.Buildings["quarry"] = 1;

        var output = BuildingsData.DailyProduction(state);
        var producedKeys = output
            .Where(kvp => kvp.Value > 0)
            .Select(kvp => kvp.Key)
            .OrderBy(key => key, StringComparer.Ordinal)
            .ToArray();
        var expected = GameState.ResourceKeys
            .OrderBy(key => key, StringComparer.Ordinal)
            .ToArray();

        Assert.Equal(expected, producedKeys);
    }

    private static GameState CreateState(string seed)
    {
        var state = DefaultState.Create(seed);
        state.Structures.Clear();
        state.StructureLevels.Clear();
        state.WorkerAssignments.Clear();
        foreach (var key in GameState.ResourceKeys)
            state.Resources[key] = 0;
        return state;
    }

    private static int AddStructure(GameState state, int xOffset, int yOffset, string buildingType)
    {
        int x = state.BasePos.X + xOffset;
        int y = state.BasePos.Y + yOffset;
        Assert.InRange(x, 0, state.MapW - 1);
        Assert.InRange(y, 0, state.MapH - 1);
        int index = state.Index(x, y);
        state.Structures[index] = buildingType;
        state.StructureLevels[index] = 1;
        return index;
    }

    private static Dictionary<string, int> SnapshotCoreResources(GameState state)
    {
        var snapshot = new Dictionary<string, int>(StringComparer.Ordinal);
        foreach (var key in GameState.ResourceKeys)
            snapshot[key] = state.Resources.GetValueOrDefault(key, 0);
        return snapshot;
    }

    private static void LoadBuildingsData()
    {
        BuildingsData.LoadData(ResolveDataDirectory());
    }

    private static string ResolveDataDirectory()
    {
        string? dir = AppContext.BaseDirectory;
        for (int i = 0; i < 10 && !string.IsNullOrEmpty(dir); i++)
        {
            string candidate = Path.Combine(dir, "data");
            if (File.Exists(Path.Combine(candidate, "buildings.json")))
                return candidate;

            string? parent = Path.GetDirectoryName(dir);
            if (parent == dir)
                break;
            dir = parent;
        }

        throw new DirectoryNotFoundException("Could not locate data/buildings.json from test base directory.");
    }
}
