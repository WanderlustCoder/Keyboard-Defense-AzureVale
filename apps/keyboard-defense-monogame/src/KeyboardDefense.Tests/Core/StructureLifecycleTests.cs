using System;
using System.Collections.Generic;
using System.IO;
using KeyboardDefense.Core.Balance;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

[Collection("StaticData")]
public class StructureLifecycleTests
{
    [Fact]
    public void PlaceStructure_AppearsInStateStructures()
    {
        LoadBuildingsData();
        var state = DefaultState.Create("structure_lifecycle_place");
        var pos = PrepareTile(state, 1, 0, SimMap.TerrainPlains);
        int index = pos.ToIndex(state.MapW);
        SeedResourcesForCost(state, "tower", padding: 5);

        var (newState, events) = Apply(state, "build", new()
        {
            ["building"] = "tower",
            ["x"] = pos.X,
            ["y"] = pos.Y
        });

        Assert.True(newState.Structures.ContainsKey(index));
        Assert.Equal("tower", newState.Structures[index]);
        Assert.Contains($"Built tower at ({pos.X},{pos.Y}).", events);
    }

    [Fact]
    public void PlacedStructure_HasCorrectPositionTypeAndInitialHpProxy()
    {
        LoadBuildingsData();
        var state = DefaultState.Create("structure_lifecycle_shape");
        var pos = PrepareTile(state, 2, 0, SimMap.TerrainPlains);
        int expectedIndex = pos.ToIndex(state.MapW);
        SeedResourcesForCost(state, "tower", padding: 5);

        var (newState, _) = Apply(state, "build", new()
        {
            ["building"] = "tower",
            ["x"] = pos.X,
            ["y"] = pos.Y
        });

        var placed = Assert.Single(newState.Structures);
        Assert.Equal(expectedIndex, placed.Key);
        Assert.Equal(pos, GridPoint.FromIndex(placed.Key, newState.MapW));
        Assert.Equal("tower", placed.Value);
        Assert.Equal(1, newState.StructureLevels[placed.Key]);
    }

    [Fact]
    public void UpgradeStructure_IncreasesLevelAndImprovesDerivedDamageStat()
    {
        var state = DefaultState.Create("structure_lifecycle_upgrade");
        var pos = PrepareTile(state, 1, 0, SimMap.TerrainPlains);
        int index = pos.ToIndex(state.MapW);
        state.Structures[index] = "tower";
        state.StructureLevels[index] = 1;
        state.Gold = 20;
        state.Ap = 3;

        int damageBefore = SimBalance.CalculateTowerDamage(baseDamage: 10, level: state.StructureLevels[index]);

        var (newState, events) = Apply(state, "upgrade", new()
        {
            ["x"] = pos.X,
            ["y"] = pos.Y
        });

        int levelAfter = newState.StructureLevels[index];
        int damageAfter = SimBalance.CalculateTowerDamage(baseDamage: 10, level: levelAfter);

        Assert.Equal(2, levelAfter);
        Assert.True(damageAfter > damageBefore);
        Assert.Equal(15, newState.Gold);
        Assert.Contains("Upgraded tower to level 2 for 5 gold.", events);
    }

    [Fact]
    public void DamagedStructure_ReducesHpProxyLevel()
    {
        var state = DefaultState.Create("structure_lifecycle_damage");
        var pos = PrepareTile(state, 1, 0, SimMap.TerrainPlains);
        int index = pos.ToIndex(state.MapW);
        state.Structures[index] = "tower";
        state.StructureLevels[index] = 3;
        state.Gold = 10;
        state.Ap = 3;

        var (_, failedUpgradeEvents) = Apply(state, "upgrade", new()
        {
            ["x"] = pos.X,
            ["y"] = pos.Y
        });
        Assert.Contains("Need 15 gold to upgrade (have 10).", failedUpgradeEvents);

        state.StructureLevels[index] = 2;

        var (newState, successEvents) = Apply(state, "upgrade", new()
        {
            ["x"] = pos.X,
            ["y"] = pos.Y
        });

        Assert.Equal(3, newState.StructureLevels[index]);
        Assert.Equal(0, newState.Gold);
        Assert.Contains("Upgraded tower to level 3 for 10 gold.", successEvents);
    }

    [Fact]
    public void DestroyedStructure_WhenHpProxyIsZero_IsRemovedFromStructures()
    {
        var state = DefaultState.Create("structure_lifecycle_destroy");
        var pos = PrepareTile(state, 1, 0, SimMap.TerrainPlains);
        int index = pos.ToIndex(state.MapW);
        state.Structures[index] = "tower";
        state.StructureLevels[index] = 0;
        state.Buildings["tower"] = 1;

        var (newState, events) = Apply(state, "demolish", new()
        {
            ["x"] = pos.X,
            ["y"] = pos.Y
        });

        Assert.False(newState.Structures.ContainsKey(index));
        Assert.False(newState.StructureLevels.ContainsKey(index));
        Assert.Equal(0, newState.Buildings.GetValueOrDefault("tower", 0));
        Assert.Contains($"Demolished tower at ({pos.X},{pos.Y}).", events);
    }

    [Fact]
    public void Buildings_ProvideDefenseBonusToBase()
    {
        LoadBuildingsData();
        var state = DefaultState.Create("structure_lifecycle_defense");
        state.Day = 4;
        state.Threat = 5;
        AddStructure(state, 1, 0, "wall");
        AddStructure(state, 2, 0, "tower");

        int defense = BuildingsData.TotalDefense(state);
        int waveWithoutDefense = SimTick.ComputeNightWaveTotal(state, defense: 0);
        int waveWithDefense = SimTick.ComputeNightWaveTotal(state, defense);

        Assert.True(defense > 0);
        Assert.True(waveWithDefense < waveWithoutDefense);
    }

    [Fact]
    public void Buildings_ProduceResourcesPerDayTick()
    {
        var state = DefaultState.Create("structure_lifecycle_production");
        state.Structures.Clear();
        state.StructureLevels.Clear();
        foreach (string key in GameState.ResourceKeys)
            state.Resources[key] = 0;

        AddStructure(state, 1, 0, "farm");
        AddStructure(state, 2, 0, "lumber");
        AddStructure(state, 3, 0, "quarry");

        SimTick.AdvanceDay(state);

        Assert.Equal(2, state.Resources["food"]);
        Assert.Equal(2, state.Resources["wood"]);
        Assert.Equal(2, state.Resources["stone"]);
    }

    [Fact]
    public void CannotBuildOnWaterTerrain()
    {
        LoadBuildingsData();
        var state = DefaultState.Create("structure_lifecycle_water");
        var pos = PrepareTile(state, 1, 0, SimMap.TerrainWater);
        int index = pos.ToIndex(state.MapW);
        SeedResourcesForCost(state, "tower", padding: 5);
        int apBefore = state.Ap;

        var (newState, events) = Apply(state, "build", new()
        {
            ["building"] = "tower",
            ["x"] = pos.X,
            ["y"] = pos.Y
        });

        Assert.False(newState.Structures.ContainsKey(index));
        Assert.Equal(apBefore, newState.Ap);
        Assert.Contains("Cannot build on water.", events);
    }

    [Fact]
    public void CannotBuildOnMountainTerrain()
    {
        LoadBuildingsData();
        var state = DefaultState.Create("structure_lifecycle_mountain");
        var pos = PrepareTile(state, 1, 0, SimMap.TerrainMountain);
        int index = pos.ToIndex(state.MapW);
        SeedResourcesForCost(state, "tower", padding: 5);
        int apBefore = state.Ap;

        var (newState, events) = Apply(state, "build", new()
        {
            ["building"] = "tower",
            ["x"] = pos.X,
            ["y"] = pos.Y
        });

        Assert.False(newState.Structures.ContainsKey(index));
        Assert.Equal(apBefore, newState.Ap);
        Assert.Contains("Cannot build on mountain.", events);
    }

    [Fact]
    public void BuildingCost_IsDeductedFromResources()
    {
        LoadBuildingsData();
        var state = DefaultState.Create("structure_lifecycle_cost");
        var pos = PrepareTile(state, 1, 0, SimMap.TerrainPlains);
        var cost = BuildingsData.CostFor("tower");
        Assert.NotEmpty(cost);
        SeedResourcesForCost(state, "tower", padding: 10);
        var before = new Dictionary<string, int>(state.Resources);

        var (newState, _) = Apply(state, "build", new()
        {
            ["building"] = "tower",
            ["x"] = pos.X,
            ["y"] = pos.Y
        });

        foreach (string resource in GameState.ResourceKeys)
        {
            int expected = before[resource] - cost.GetValueOrDefault(resource, 0);
            Assert.Equal(expected, newState.Resources[resource]);
        }
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

    private static GridPoint PrepareTile(GameState state, int dx, int dy, string terrain)
    {
        var pos = new GridPoint(state.BasePos.X + dx, state.BasePos.Y + dy);
        Assert.True(SimMap.InBounds(pos.X, pos.Y, state.MapW, state.MapH));
        int index = pos.ToIndex(state.MapW);
        state.Discovered.Add(index);
        state.Terrain[index] = terrain;
        state.Structures.Remove(index);
        state.StructureLevels.Remove(index);
        return pos;
    }

    private static int AddStructure(GameState state, int dx, int dy, string buildingType)
    {
        var pos = PrepareTile(state, dx, dy, SimMap.TerrainPlains);
        int index = pos.ToIndex(state.MapW);
        state.Structures[index] = buildingType;
        state.StructureLevels[index] = 1;
        state.Buildings[buildingType] = state.Buildings.GetValueOrDefault(buildingType, 0) + 1;
        return index;
    }

    private static void SeedResourcesForCost(GameState state, string buildingType, int padding)
    {
        var cost = BuildingsData.CostFor(buildingType);
        Assert.NotEmpty(cost);
        foreach (string resource in GameState.ResourceKeys)
            state.Resources[resource] = cost.GetValueOrDefault(resource, 0) + padding;
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
