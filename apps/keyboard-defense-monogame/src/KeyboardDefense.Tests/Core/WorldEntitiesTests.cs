using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class WorldEntitiesTests
{
    private static GameState CreatePopulatedState(string seed = "world-entities-tests")
    {
        return DefaultState.Create(seed);
    }

    private static GameState CreateMinimalState(int width = 32, int height = 32, string seed = "world-entities-minimal")
    {
        var state = new GameState
        {
            MapW = width,
            MapH = height,
        };

        state.BasePos = new GridPoint(width / 2, height / 2);
        state.PlayerPos = state.BasePos;
        state.CursorPos = state.BasePos;

        state.Terrain.Clear();
        for (int i = 0; i < width * height; i++)
            state.Terrain.Add(SimMap.TerrainPlains);

        state.Structures.Clear();
        state.RoamingEnemies.Clear();
        state.Npcs.Clear();
        state.ResourceNodes.Clear();
        SimRng.SeedState(state, seed);
        return state;
    }

    private static Dictionary<string, object> AddEnemy(GameState state, int id, GridPoint pos, string kind = "scout", int tier = 0)
    {
        var enemy = new Dictionary<string, object>
        {
            ["id"] = id,
            ["kind"] = kind,
            ["pos"] = pos,
            ["hp"] = 3 + (tier * 2),
            ["tier"] = tier,
            ["patrol_origin"] = pos,
        };

        state.RoamingEnemies.Add(enemy);
        return enemy;
    }

    private static Dictionary<string, object> AddNpc(GameState state, string type, GridPoint pos, string name)
    {
        var npc = new Dictionary<string, object>
        {
            ["type"] = type,
            ["pos"] = pos,
            ["name"] = name,
            ["quest_available"] = true,
            ["facing"] = "south",
        };

        state.Npcs.Add(npc);
        return npc;
    }

    private static int AddResourceNode(GameState state, GridPoint pos, string type = "wood_grove")
    {
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        state.ResourceNodes[index] = new Dictionary<string, object>
        {
            ["type"] = type,
            ["pos"] = pos,
            ["zone"] = SimMap.GetZoneAt(state, pos),
            ["cooldown"] = 0,
        };

        return index;
    }

    [Fact]
    public void PopulateWorld_CreatesEnemiesNpcsAndResourceNodes()
    {
        var state = CreatePopulatedState("world-entities-create");

        Assert.NotEmpty(state.RoamingEnemies);
        Assert.NotEmpty(state.Npcs);
        Assert.NotEmpty(state.ResourceNodes);
    }

    [Fact]
    public void PopulateWorld_CreatesEnemiesWithUniquePositiveIds()
    {
        var state = CreatePopulatedState("world-entities-enemy-ids");
        var ids = state.RoamingEnemies
            .Select(enemy => Convert.ToInt32(enemy.GetValueOrDefault("id", 0)))
            .ToList();

        Assert.NotEmpty(ids);
        Assert.Equal(ids.Count, ids.Distinct().Count());
        Assert.All(ids, id => Assert.True(id > 0));
    }

    [Fact]
    public void PopulateWorld_IndexesResourceNodesByTheirPosition()
    {
        var state = CreatePopulatedState("world-entities-resource-index");

        Assert.NotEmpty(state.ResourceNodes);

        foreach (var (index, node) in state.ResourceNodes)
        {
            var pos = Assert.IsType<GridPoint>(node["pos"]);
            Assert.Equal(index, SimMap.Idx(pos.X, pos.Y, state.MapW));
        }
    }

    [Fact]
    public void PopulateWorld_CreatesEntitiesWithRequiredFields()
    {
        var state = CreatePopulatedState("world-entities-required-fields");

        Assert.All(state.RoamingEnemies, enemy =>
        {
            Assert.True(enemy.ContainsKey("id"));
            Assert.True(enemy.ContainsKey("kind"));
            Assert.True(enemy.ContainsKey("pos"));
            Assert.True(enemy.ContainsKey("hp"));
            Assert.True(enemy.ContainsKey("tier"));
            Assert.True(enemy.ContainsKey("patrol_origin"));
        });

        Assert.All(state.Npcs, npc =>
        {
            Assert.True(npc.ContainsKey("type"));
            Assert.True(npc.ContainsKey("pos"));
            Assert.True(npc.ContainsKey("name"));
            Assert.True(npc.ContainsKey("quest_available"));
            Assert.True(npc.ContainsKey("facing"));
        });

        Assert.All(state.ResourceNodes.Values, node =>
        {
            Assert.True(node.ContainsKey("type"));
            Assert.True(node.ContainsKey("pos"));
            Assert.True(node.ContainsKey("zone"));
            Assert.True(node.ContainsKey("cooldown"));
        });
    }

    [Fact]
    public void GetEntitiesNear_ReturnsEnemyWithIdForLookup()
    {
        var state = CreateMinimalState();
        var center = new GridPoint(16, 16);

        AddEnemy(state, id: 42, pos: center, kind: "raider", tier: 1);

        var results = WorldEntities.GetEntitiesNear(state, center, radius: 0);
        var enemy = Assert.Single(results, entity => entity["entity_type"]?.ToString() == "enemy");

        Assert.Equal(42, Convert.ToInt32(enemy["id"]));
        Assert.Equal(center, Assert.IsType<GridPoint>(enemy["pos"]));
    }

    [Fact]
    public void GetEntitiesNear_CanLookupSpecificEnemyWhenMultipleIdsAreInRange()
    {
        var state = CreateMinimalState();
        var center = new GridPoint(10, 10);

        AddEnemy(state, id: 1001, pos: new GridPoint(10, 10), kind: "scout");
        AddEnemy(state, id: 1002, pos: new GridPoint(11, 10), kind: "armored", tier: 2);

        var results = WorldEntities.GetEntitiesNear(state, center, radius: 2);
        var byId = Assert.Single(results, entity =>
            entity["entity_type"]?.ToString() == "enemy" &&
            Convert.ToInt32(entity["id"]) == 1002);

        Assert.Equal("armored", byId["kind"]?.ToString());
        Assert.Equal(new GridPoint(11, 10), Assert.IsType<GridPoint>(byId["pos"]));
    }

    [Fact]
    public void GetEntitiesNear_RadiusZeroReturnsOnlyEntitiesOnExactTile()
    {
        var state = CreateMinimalState();
        var center = new GridPoint(12, 12);

        AddEnemy(state, id: 1, pos: center);
        AddNpc(state, "merchant", new GridPoint(13, 12), "Merchant Adira");
        AddResourceNode(state, new GridPoint(12, 13), "stone_quarry");

        var results = WorldEntities.GetEntitiesNear(state, center, radius: 0);

        Assert.Single(results);
        Assert.Equal("enemy", results[0]["entity_type"]?.ToString());
    }

    [Fact]
    public void GetEntitiesNear_UsesManhattanDistanceAndIncludesBoundary()
    {
        var state = CreateMinimalState();
        var center = new GridPoint(8, 8);

        AddEnemy(state, id: 11, pos: new GridPoint(10, 8));
        AddNpc(state, "trainer", new GridPoint(8, 10), "Master Galen");
        AddResourceNode(state, new GridPoint(7, 7), "food_garden");

        var results = WorldEntities.GetEntitiesNear(state, center, radius: 2);

        Assert.Equal(3, results.Count);
    }

    [Fact]
    public void GetEntitiesNear_ExcludesEntitiesOutsideRadius()
    {
        var state = CreateMinimalState();
        var center = new GridPoint(8, 8);

        AddEnemy(state, id: 20, pos: new GridPoint(11, 8));
        AddNpc(state, "quest_giver", new GridPoint(8, 12), "Quartermaster Torin");
        AddResourceNode(state, new GridPoint(4, 8), "gold_vein");

        var results = WorldEntities.GetEntitiesNear(state, center, radius: 2);

        Assert.Empty(results);
    }

    [Fact]
    public void GetEntitiesNear_RemovedEnemyIsNoLongerReturned()
    {
        var state = CreateMinimalState();
        var center = new GridPoint(14, 14);

        AddEnemy(state, id: 99, pos: center);
        Assert.Contains(WorldEntities.GetEntitiesNear(state, center, radius: 1), entity =>
            entity["entity_type"]?.ToString() == "enemy" && Convert.ToInt32(entity["id"]) == 99);

        state.RoamingEnemies.RemoveAll(enemy => Convert.ToInt32(enemy.GetValueOrDefault("id", -1)) == 99);

        Assert.DoesNotContain(WorldEntities.GetEntitiesNear(state, center, radius: 1), entity =>
            entity["entity_type"]?.ToString() == "enemy" && Convert.ToInt32(entity["id"]) == 99);
    }

    [Fact]
    public void GetEntitiesNear_RemovedNpcIsNoLongerReturned()
    {
        var state = CreateMinimalState();
        var center = new GridPoint(15, 15);

        AddNpc(state, "trainer", center, "Master Galen");
        Assert.Contains(WorldEntities.GetEntitiesNear(state, center, radius: 1), entity =>
            entity["entity_type"]?.ToString() == "npc" && entity["name"]?.ToString() == "Master Galen");

        state.Npcs.RemoveAll(npc => npc.GetValueOrDefault("name")?.ToString() == "Master Galen");

        Assert.DoesNotContain(WorldEntities.GetEntitiesNear(state, center, radius: 1), entity =>
            entity["entity_type"]?.ToString() == "npc" && entity["name"]?.ToString() == "Master Galen");
    }

    [Fact]
    public void GetEntitiesNear_RemovedResourceNodeIsNoLongerReturned()
    {
        var state = CreateMinimalState();
        var center = new GridPoint(9, 9);
        int index = AddResourceNode(state, center, "iron_deposit");

        Assert.Contains(WorldEntities.GetEntitiesNear(state, center, radius: 1), entity =>
            entity["entity_type"]?.ToString() == "resource" && Convert.ToInt32(entity["index"]) == index);

        state.ResourceNodes.Remove(index);

        Assert.DoesNotContain(WorldEntities.GetEntitiesNear(state, center, radius: 1), entity =>
            entity["entity_type"]?.ToString() == "resource" && Convert.ToInt32(entity["index"]) == index);
    }

    [Fact]
    public void GetEntitiesNear_AssignsExpectedEntityTypeMarkers()
    {
        var state = CreateMinimalState();
        var center = new GridPoint(20, 20);

        AddEnemy(state, id: 501, pos: new GridPoint(20, 20));
        AddNpc(state, "merchant", new GridPoint(21, 20), "Merchant Adira");
        int resourceIndex = AddResourceNode(state, new GridPoint(20, 21), "wood_grove");

        var results = WorldEntities.GetEntitiesNear(state, center, radius: 2);
        var types = results.Select(entity => entity["entity_type"]?.ToString()).OrderBy(type => type).ToList();

        Assert.Equal(new[] { "enemy", "npc", "resource" }, types);

        var resource = Assert.Single(results, entity => entity["entity_type"]?.ToString() == "resource");
        Assert.Equal(resourceIndex, Convert.ToInt32(resource["index"]));
    }

    [Fact]
    public void GetEntitiesNear_TypeFilteringReturnsExpectedCounts()
    {
        var state = CreateMinimalState();
        var center = new GridPoint(6, 6);

        AddEnemy(state, id: 1, pos: new GridPoint(6, 6));
        AddEnemy(state, id: 2, pos: new GridPoint(7, 6));
        AddNpc(state, "quest_giver", new GridPoint(6, 7), "Quartermaster Torin");
        AddResourceNode(state, new GridPoint(5, 6), "crystal_cave");
        AddResourceNode(state, new GridPoint(6, 5), "pine_forest");

        var results = WorldEntities.GetEntitiesNear(state, center, radius: 2);
        int enemyCount = results.Count(entity => entity["entity_type"]?.ToString() == "enemy");
        int npcCount = results.Count(entity => entity["entity_type"]?.ToString() == "npc");
        int resourceCount = results.Count(entity => entity["entity_type"]?.ToString() == "resource");

        Assert.Equal(2, enemyCount);
        Assert.Equal(1, npcCount);
        Assert.Equal(2, resourceCount);
    }
}
