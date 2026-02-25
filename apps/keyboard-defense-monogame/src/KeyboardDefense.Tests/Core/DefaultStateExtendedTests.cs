using System.Reflection;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class DefaultStateExtendedTests
{
    private static readonly HashSet<string> ValidTerrainTypes = new(StringComparer.Ordinal)
    {
        SimMap.TerrainPlains,
        SimMap.TerrainForest,
        SimMap.TerrainMountain,
        SimMap.TerrainWater,
        SimMap.TerrainDesert,
        SimMap.TerrainSnow,
        SimMap.TerrainRoad,
    };

    private static GameState CreateState(string seed) =>
        DefaultState.Create(seed, placeStartingTowers: false, useWorldSpec: false);

    [Fact]
    public void Create_DifferentSeeds_ProduceDifferentTerrain()
    {
        var first = CreateState("default-state-extended-seed-a");
        var second = CreateState("default-state-extended-seed-b");

        Assert.False(first.Terrain.SequenceEqual(second.Terrain),
            "Expected different seeds to produce different terrain layouts.");
    }

    [Fact]
    public void Create_SameSeed_ProducesIdenticalDeterministicState()
    {
        const string seed = "default-state-extended-deterministic";
        var first = CreateState(seed);
        var second = CreateState(seed);

        Assert.Equal(first.Terrain, second.Terrain);
        Assert.True(first.Discovered.SetEquals(second.Discovered));
        Assert.Equal(ProjectResourceNodes(first), ProjectResourceNodes(second));
        Assert.Equal(ProjectNpcs(first), ProjectNpcs(second));
        Assert.Equal(ProjectRoamingEnemies(first), ProjectRoamingEnemies(second));
        Assert.Equal(ProjectPois(first), ProjectPois(second));
        Assert.Equal(first.EnemyNextId, second.EnemyNextId);
        Assert.Equal(first.Gold, second.Gold);
        Assert.Equal(first.LessonId, second.LessonId);
    }

    [Fact]
    public void Create_AllReferenceTypeProperties_AreInitialized()
    {
        var state = CreateState("default-state-extended-init-check");
        var properties = typeof(GameState)
            .GetProperties(BindingFlags.Instance | BindingFlags.Public)
            .Where(property => !property.PropertyType.IsValueType);

        foreach (var property in properties)
        {
            object? value = property.GetValue(state);
            Assert.True(value is not null, $"Property '{property.Name}' was not initialized.");
        }
    }

    [Fact]
    public void Create_MapDimensionsAndCorePositions_AreWithinBounds()
    {
        var state = CreateState("default-state-extended-map-bounds");

        Assert.True(state.MapW > 0);
        Assert.True(state.MapH > 0);
        Assert.Equal(state.MapW * state.MapH, state.Terrain.Count);
        Assert.True(SimMap.InBounds(state.BasePos.X, state.BasePos.Y, state.MapW, state.MapH));
        Assert.True(SimMap.InBounds(state.PlayerPos.X, state.PlayerPos.Y, state.MapW, state.MapH));
        Assert.True(SimMap.InBounds(state.CursorPos.X, state.CursorPos.Y, state.MapW, state.MapH));
    }

    [Fact]
    public void Create_DiscoveredSet_ContainsBasePosition()
    {
        var state = CreateState("default-state-extended-discovered-base");
        int baseIndex = SimMap.Idx(state.BasePos.X, state.BasePos.Y, state.MapW);

        Assert.Contains(baseIndex, state.Discovered);
    }

    [Fact]
    public void Create_DiscoveredSet_ContainsOnlyInBoundsTileIndexes()
    {
        var state = CreateState("default-state-extended-discovered-bounds");
        int maxIndex = state.MapW * state.MapH - 1;

        Assert.NotEmpty(state.Discovered);
        Assert.All(state.Discovered, index => Assert.InRange(index, 0, maxIndex));
    }

    [Fact]
    public void Create_ResourceDictionaries_ContainExpectedKeys()
    {
        var state = CreateState("default-state-extended-resource-keys");

        var expectedResourceKeys = GameState.ResourceKeys.OrderBy(key => key).ToArray();
        var actualResourceKeys = state.Resources.Keys.OrderBy(key => key).ToArray();
        Assert.Equal(expectedResourceKeys, actualResourceKeys);

        var expectedBuildingKeys = GameState.BuildingKeys.OrderBy(key => key).ToArray();
        var actualBuildingKeys = state.Buildings.Keys.OrderBy(key => key).ToArray();
        Assert.Equal(expectedBuildingKeys, actualBuildingKeys);
    }

    [Fact]
    public void Create_Terrain_ContainsOnlyValidTypes()
    {
        var state = CreateState("default-state-extended-terrain-types");

        Assert.All(state.Terrain, terrain =>
            Assert.True(ValidTerrainTypes.Contains(terrain), $"Unexpected terrain type '{terrain}'."));
    }

    [Fact]
    public void Create_NpcSpawns_AreInBoundsAndOnPassableTerrain()
    {
        var state = CreateState("default-state-extended-npc-spawns");

        Assert.NotEmpty(state.Npcs);
        foreach (var npc in state.Npcs)
        {
            Assert.True(npc.ContainsKey("pos"), "NPC entry is missing 'pos'.");
            var pos = Assert.IsType<GridPoint>(npc["pos"]);

            Assert.True(SimMap.InBounds(pos.X, pos.Y, state.MapW, state.MapH));
            Assert.True(SimMap.IsPassable(state, pos));

            int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
            Assert.NotEqual(SimMap.TerrainWater, state.Terrain[index]);
        }
    }

    [Fact]
    public void Create_RoamingEnemySpawns_AreInBoundsAndOnPassableTerrain()
    {
        var state = CreateState("default-state-extended-enemy-spawns");

        Assert.NotEmpty(state.RoamingEnemies);
        foreach (var enemy in state.RoamingEnemies)
        {
            Assert.True(enemy.ContainsKey("pos"), "Enemy entry is missing 'pos'.");
            var pos = Assert.IsType<GridPoint>(enemy["pos"]);

            Assert.True(SimMap.InBounds(pos.X, pos.Y, state.MapW, state.MapH));
            Assert.True(SimMap.IsPassable(state, pos));
            Assert.NotEqual(state.BasePos, pos);
        }
    }

    [Fact]
    public void Create_ResourceNodes_AreIndexedCorrectlyAndOnValidTerrain()
    {
        var state = CreateState("default-state-extended-resource-nodes");

        Assert.NotEmpty(state.ResourceNodes);
        foreach (var (index, node) in state.ResourceNodes)
        {
            Assert.True(node.ContainsKey("pos"), "Resource node is missing 'pos'.");
            var pos = Assert.IsType<GridPoint>(node["pos"]);

            Assert.Equal(index, SimMap.Idx(pos.X, pos.Y, state.MapW));
            Assert.True(SimMap.InBounds(pos.X, pos.Y, state.MapW, state.MapH));
            Assert.True(SimMap.IsPassable(state, pos));
            Assert.NotEqual(SimMap.TerrainWater, state.Terrain[index]);
        }
    }

    private static string[] ProjectResourceNodes(GameState state)
    {
        return state.ResourceNodes
            .OrderBy(entry => entry.Key)
            .Select(entry =>
            {
                var node = entry.Value;
                var pos = Assert.IsType<GridPoint>(node["pos"]);
                string type = node.GetValueOrDefault("type", "").ToString() ?? "";
                string zone = node.GetValueOrDefault("zone", "").ToString() ?? "";
                int cooldown = Convert.ToInt32(node.GetValueOrDefault("cooldown", 0));
                return $"{entry.Key}|{type}|{zone}|{cooldown}|{pos.X}|{pos.Y}";
            })
            .ToArray();
    }

    private static string[] ProjectNpcs(GameState state)
    {
        return state.Npcs
            .Select(npc =>
            {
                var pos = Assert.IsType<GridPoint>(npc["pos"]);
                string type = npc.GetValueOrDefault("type", "").ToString() ?? "";
                string name = npc.GetValueOrDefault("name", "").ToString() ?? "";
                string zone = npc.GetValueOrDefault("zone", "").ToString() ?? "";
                return $"{type}|{name}|{zone}|{pos.X}|{pos.Y}";
            })
            .OrderBy(value => value, StringComparer.Ordinal)
            .ToArray();
    }

    private static string[] ProjectRoamingEnemies(GameState state)
    {
        return state.RoamingEnemies
            .Select(enemy =>
            {
                var pos = Assert.IsType<GridPoint>(enemy["pos"]);
                int id = Convert.ToInt32(enemy.GetValueOrDefault("id", 0));
                string kind = enemy.GetValueOrDefault("kind", "").ToString() ?? "";
                int tier = Convert.ToInt32(enemy.GetValueOrDefault("tier", 0));
                int hp = Convert.ToInt32(enemy.GetValueOrDefault("hp", 0));
                string zone = enemy.GetValueOrDefault("zone", "").ToString() ?? "";
                return $"{id}|{kind}|{tier}|{hp}|{zone}|{pos.X}|{pos.Y}";
            })
            .OrderBy(value => value, StringComparer.Ordinal)
            .ToArray();
    }

    private static string[] ProjectPois(GameState state)
    {
        return state.ActivePois
            .OrderBy(entry => entry.Key, StringComparer.Ordinal)
            .Select(entry =>
            {
                var poi = entry.Value;
                var pos = Assert.IsType<GridPoint>(poi["pos"]);
                string eventId = poi.GetValueOrDefault("event_id", "").ToString() ?? "";
                return $"{entry.Key}|{eventId}|{pos.X}|{pos.Y}";
            })
            .ToArray();
    }
}
