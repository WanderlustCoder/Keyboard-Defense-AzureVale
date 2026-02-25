using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class DefaultStateInitializationTests
{
    [Fact]
    public void Create_InitialValues_AreValid()
    {
        var state = DefaultState.Create(useWorldSpec: false);

        Assert.Equal(1, state.Day);
        Assert.Equal("day", state.Phase);
        Assert.True(state.Hp > 0, "Starting health should be positive.");
        Assert.True(state.Gold > 0, "Starting resources should include positive gold.");
        Assert.Equal(LessonsData.DefaultLessonId(), state.LessonId);
    }

    [Fact]
    public void Create_StartPosition_IsCenteredAndSynced()
    {
        var state = DefaultState.Create(useWorldSpec: false);
        var expectedBase = new GridPoint(state.MapW / 2, state.MapH / 2);

        Assert.Equal(expectedBase, state.BasePos);
        Assert.Equal(state.BasePos, state.PlayerPos);
        Assert.Equal(state.BasePos, state.CursorPos);
    }

    [Fact]
    public void Create_Inventory_StartsEmpty()
    {
        var state = DefaultState.Create(useWorldSpec: false);

        Assert.Empty(state.Inventory);
        Assert.Empty(state.EquippedItems);
    }

    [Fact]
    public void Create_ResourceAndBuildingTables_AreInitialized()
    {
        var state = DefaultState.Create(useWorldSpec: false);

        foreach (var resourceKey in GameState.ResourceKeys)
        {
            Assert.True(state.Resources.ContainsKey(resourceKey), $"Missing resource key '{resourceKey}'.");
            Assert.True(state.Resources[resourceKey] >= 0, $"Resource '{resourceKey}' should be non-negative.");
        }

        foreach (var buildingKey in GameState.BuildingKeys)
        {
            Assert.True(state.Buildings.ContainsKey(buildingKey), $"Missing building key '{buildingKey}'.");
            Assert.True(state.Buildings[buildingKey] >= 0, $"Building '{buildingKey}' should be non-negative.");
        }
    }

    [Fact]
    public void Create_GeneratesTerrain_AndForcesBaseTileToPlains()
    {
        var state = DefaultState.Create(useWorldSpec: false);

        Assert.Equal(state.MapW * state.MapH, state.Terrain.Count);
        Assert.DoesNotContain(state.Terrain, string.IsNullOrEmpty);

        int baseIndex = SimMap.Idx(state.BasePos.X, state.BasePos.Y, state.MapW);
        Assert.Equal(SimMap.TerrainPlains, state.Terrain[baseIndex]);
    }

    [Fact]
    public void Create_DiscoversExpectedStartingAreaAroundBase()
    {
        var state = DefaultState.Create(useWorldSpec: false);

        Assert.Equal(121, state.Discovered.Count);

        var corners = new[]
        {
            new GridPoint(state.BasePos.X - 5, state.BasePos.Y - 5),
            new GridPoint(state.BasePos.X + 5, state.BasePos.Y - 5),
            new GridPoint(state.BasePos.X - 5, state.BasePos.Y + 5),
            new GridPoint(state.BasePos.X + 5, state.BasePos.Y + 5),
        };

        foreach (var point in corners)
        {
            int index = SimMap.Idx(point.X, point.Y, state.MapW);
            Assert.Contains(index, state.Discovered);
        }
    }

    [Fact]
    public void Create_PopulatesInitialWorldEntities()
    {
        var state = DefaultState.Create(useWorldSpec: false);

        Assert.True(state.ResourceNodes.Count > 0, "Expected at least one resource node.");
        Assert.True(state.RoamingEnemies.Count > 0, "Expected at least one roaming enemy.");
        Assert.True(state.Npcs.Count > 0, "Expected at least one NPC.");
        Assert.True(state.ActivePois.Count > 0, "Expected at least one POI.");
    }

    [Fact]
    public void Create_DoesNotPlaceStartingTowers_WhenDisabled()
    {
        var state = DefaultState.Create(placeStartingTowers: false, useWorldSpec: false);

        Assert.Empty(state.Structures);
    }

    [Fact]
    public void Create_PlacesStartingTowers_WhenEnabled()
    {
        var state = DefaultState.Create(placeStartingTowers: true, useWorldSpec: false);

        int leftIndex = SimMap.Idx(state.BasePos.X - 1, state.BasePos.Y, state.MapW);
        int rightIndex = SimMap.Idx(state.BasePos.X + 1, state.BasePos.Y, state.MapW);

        Assert.True(state.Structures.TryGetValue(leftIndex, out var leftType));
        Assert.True(state.Structures.TryGetValue(rightIndex, out var rightType));
        Assert.Equal("auto_sentry", leftType);
        Assert.Equal("auto_spark", rightType);
        Assert.NotEqual(SimMap.TerrainWater, state.Terrain[leftIndex]);
        Assert.NotEqual(SimMap.TerrainWater, state.Terrain[rightIndex]);
    }

    [Fact]
    public void Create_WithSameSeed_IsDeterministicForCoreLayout()
    {
        var first = DefaultState.Create("default_state_seed", placeStartingTowers: true, useWorldSpec: false);
        var second = DefaultState.Create("default_state_seed", placeStartingTowers: true, useWorldSpec: false);

        Assert.Equal(first.RngSeed, second.RngSeed);
        Assert.Equal(first.BasePos, second.BasePos);
        Assert.Equal(first.Terrain, second.Terrain);
        Assert.True(first.Discovered.SetEquals(second.Discovered));
        Assert.Equal(first.Structures.Count, second.Structures.Count);
        foreach (var (index, structure) in first.Structures)
        {
            Assert.True(second.Structures.TryGetValue(index, out var otherStructure));
            Assert.Equal(structure, otherStructure);
        }
    }
}
