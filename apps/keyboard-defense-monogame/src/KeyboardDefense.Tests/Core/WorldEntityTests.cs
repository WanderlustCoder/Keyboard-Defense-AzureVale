using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class WorldEntityTests
{
    private static GameState CreateWorldState(string seed = "entity_test")
    {
        return DefaultState.Create(seed);
    }

    /// <summary>Creates a minimal state suitable for GetEntitiesNear tests (no full terrain).</summary>
    private static GameState CreateMinimalState()
    {
        var state = new GameState();
        state.MapW = 64;
        state.MapH = 64;
        // Fill terrain to correct size so any incidental terrain checks work
        for (int i = 0; i < state.MapW * state.MapH; i++)
            state.Terrain.Add(SimMap.TerrainPlains);
        return state;
    }

    // --- PopulateWorld ---

    [Fact]
    public void PopulateWorld_CreatesResourceNodes()
    {
        var state = CreateWorldState();
        Assert.True(state.ResourceNodes.Count > 0, "PopulateWorld should create resource nodes");
    }

    [Fact]
    public void PopulateWorld_CreatesRoamingEnemies()
    {
        var state = CreateWorldState();
        Assert.True(state.RoamingEnemies.Count > 0, "PopulateWorld should create roaming enemies");
    }

    [Fact]
    public void PopulateWorld_CreatesNpcs()
    {
        var state = CreateWorldState();
        Assert.True(state.Npcs.Count > 0, "PopulateWorld should create NPCs");
    }

    [Fact]
    public void PopulateWorld_RoamingEnemiesRespectMaxLimit()
    {
        var state = CreateWorldState();
        Assert.True(state.RoamingEnemies.Count <= WorldTick.MaxRoamingEnemies,
            $"RoamingEnemies ({state.RoamingEnemies.Count}) should not exceed max ({WorldTick.MaxRoamingEnemies})");
    }

    [Fact]
    public void PopulateWorld_ResourceNodesOnPassableTerrain()
    {
        var state = CreateWorldState();
        foreach (var (idx, node) in state.ResourceNodes)
        {
            if (node.GetValueOrDefault("pos") is GridPoint pos)
            {
                Assert.True(SimMap.InBounds(pos.X, pos.Y, state.MapW, state.MapH),
                    $"Resource node at ({pos.X},{pos.Y}) should be in bounds");
            }
        }
    }

    [Fact]
    public void PopulateWorld_EnemiesHaveRequiredFields()
    {
        var state = CreateWorldState();
        foreach (var enemy in state.RoamingEnemies)
        {
            Assert.True(enemy.ContainsKey("id"), "Enemy must have id");
            Assert.True(enemy.ContainsKey("kind"), "Enemy must have kind");
            Assert.True(enemy.ContainsKey("pos"), "Enemy must have pos");
            Assert.True(enemy.ContainsKey("hp"), "Enemy must have hp");
            Assert.True(enemy.ContainsKey("tier"), "Enemy must have tier");
            Assert.True(enemy.ContainsKey("patrol_origin"), "Enemy must have patrol_origin");
        }
    }

    [Fact]
    public void PopulateWorld_NpcsHaveRequiredFields()
    {
        var state = CreateWorldState();
        foreach (var npc in state.Npcs)
        {
            Assert.True(npc.ContainsKey("type"), "NPC must have type");
            Assert.True(npc.ContainsKey("pos"), "NPC must have pos");
            Assert.True(npc.ContainsKey("name"), "NPC must have name");
        }
    }

    [Fact]
    public void PopulateWorld_HasCoreAndOutpostNpcs()
    {
        var state = CreateWorldState();
        // Core NPCs (no "zone" key) should be in Safe Zone
        var coreNpcs = state.Npcs.Where(n => !n.ContainsKey("zone")).ToList();
        foreach (var npc in coreNpcs)
        {
            if (npc.GetValueOrDefault("pos") is GridPoint pos)
            {
                string zone = SimMap.GetZoneAt(state, pos);
                Assert.Equal(SimMap.ZoneSafe, zone);
            }
        }
        // Outpost NPCs (with "zone" key) exist in outer zones
        var outpostNpcs = state.Npcs.Where(n => n.ContainsKey("zone")).ToList();
        Assert.True(outpostNpcs.Count > 0, "Should have outpost NPCs in outer zones");
        // Total NPC count is substantial
        Assert.True(state.Npcs.Count >= 5, $"Expected >= 5 NPCs, got {state.Npcs.Count}");
    }

    [Fact]
    public void PopulateWorld_EnemiesNotInSafeZone()
    {
        var state = CreateWorldState();
        foreach (var enemy in state.RoamingEnemies)
        {
            if (enemy.GetValueOrDefault("pos") is GridPoint pos)
            {
                string zone = SimMap.GetZoneAt(state, pos);
                Assert.NotEqual(SimMap.ZoneSafe, zone);
            }
        }
    }

    [Fact]
    public void PopulateWorld_EnemyTiersScaleWithZone()
    {
        var state = CreateWorldState();
        foreach (var enemy in state.RoamingEnemies)
        {
            int tier = Convert.ToInt32(enemy.GetValueOrDefault("tier", 0));
            string zone = enemy.GetValueOrDefault("zone")?.ToString() ?? "";

            switch (zone)
            {
                case "frontier":
                    Assert.True(tier <= 1, $"Frontier enemy tier {tier} should be <= 1");
                    break;
                case "wilderness":
                    Assert.True(tier <= 3, $"Wilderness enemy tier {tier} should be <= 3");
                    break;
                case "depths":
                    Assert.True(tier <= 4, $"Depths enemy tier {tier} should be <= 4");
                    break;
            }
        }
    }

    // --- TickEntityMovement ---

    [Fact]
    public void TickEntityMovement_EnemiesStayInBounds()
    {
        var state = CreateWorldState();

        // Tick many times to exercise movement
        for (int i = 0; i < 100; i++)
            WorldEntities.TickEntityMovement(state);

        foreach (var enemy in state.RoamingEnemies)
        {
            if (enemy.GetValueOrDefault("pos") is GridPoint pos)
            {
                Assert.True(SimMap.InBounds(pos.X, pos.Y, state.MapW, state.MapH),
                    $"Enemy at ({pos.X},{pos.Y}) should be in bounds after movement");
            }
        }
    }

    [Fact]
    public void TickEntityMovement_EnemiesStayWithinPatrolRange()
    {
        var state = CreateWorldState();

        for (int i = 0; i < 200; i++)
            WorldEntities.TickEntityMovement(state);

        foreach (var enemy in state.RoamingEnemies)
        {
            if (enemy.GetValueOrDefault("pos") is GridPoint pos &&
                enemy.GetValueOrDefault("patrol_origin") is GridPoint origin)
            {
                int dist = origin.ManhattanDistance(pos);
                Assert.True(dist <= 8,
                    $"Enemy at ({pos.X},{pos.Y}) is {dist} tiles from patrol origin ({origin.X},{origin.Y}), max is 8");
            }
        }
    }

    [Fact]
    public void TickEntityMovement_DoesNotMoveOntoBase()
    {
        var state = CreateWorldState();

        // Place an enemy adjacent to the base
        state.RoamingEnemies.Clear();
        var adjacentPos = new GridPoint(state.BasePos.X + 1, state.BasePos.Y);
        int adjIdx = SimMap.Idx(adjacentPos.X, adjacentPos.Y, state.MapW);
        state.Terrain[adjIdx] = SimMap.TerrainPlains;

        state.RoamingEnemies.Add(new Dictionary<string, object>
        {
            ["id"] = state.EnemyNextId++,
            ["kind"] = "raider",
            ["pos"] = adjacentPos,
            ["hp"] = 5,
            ["tier"] = 0,
            ["patrol_origin"] = adjacentPos,
        });

        for (int i = 0; i < 200; i++)
            WorldEntities.TickEntityMovement(state);

        foreach (var enemy in state.RoamingEnemies)
        {
            if (enemy.GetValueOrDefault("pos") is GridPoint pos)
            {
                Assert.NotEqual(state.BasePos, pos);
            }
        }
    }

    // --- GetEntitiesNear ---

    [Fact]
    public void GetEntitiesNear_FindsEnemiesWithinRadius()
    {
        var state = CreateMinimalState();
        var center = new GridPoint(32, 32);

        state.RoamingEnemies.Add(new Dictionary<string, object>
        {
            ["id"] = 1,
            ["kind"] = "scout",
            ["pos"] = new GridPoint(33, 32), // distance 1
            ["hp"] = 3,
            ["tier"] = 0,
        });
        state.RoamingEnemies.Add(new Dictionary<string, object>
        {
            ["id"] = 2,
            ["kind"] = "raider",
            ["pos"] = new GridPoint(40, 40), // distance 16 - out of range
            ["hp"] = 5,
            ["tier"] = 1,
        });

        var results = WorldEntities.GetEntitiesNear(state, center, 3);
        Assert.Single(results);
        Assert.Equal("enemy", results[0]["entity_type"]?.ToString());
    }

    [Fact]
    public void GetEntitiesNear_FindsNpcsWithinRadius()
    {
        var state = CreateMinimalState();
        var center = new GridPoint(32, 32);

        state.Npcs.Add(new Dictionary<string, object>
        {
            ["type"] = "trainer",
            ["pos"] = new GridPoint(33, 32), // distance 1
            ["name"] = "Master Galen",
        });

        var results = WorldEntities.GetEntitiesNear(state, center, 2);
        Assert.Single(results);
        Assert.Equal("npc", results[0]["entity_type"]?.ToString());
    }

    [Fact]
    public void GetEntitiesNear_FindsResourceNodesWithinRadius()
    {
        var state = CreateMinimalState();
        var nodePos = new GridPoint(31, 32);
        int nodeIdx = SimMap.Idx(nodePos.X, nodePos.Y, state.MapW);

        state.ResourceNodes[nodeIdx] = new Dictionary<string, object>
        {
            ["type"] = "wood_grove",
            ["pos"] = nodePos,
        };

        var results = WorldEntities.GetEntitiesNear(state, new GridPoint(32, 32), 2);
        Assert.Single(results);
        Assert.Equal("resource", results[0]["entity_type"]?.ToString());
    }

    [Fact]
    public void GetEntitiesNear_ExcludesEntitiesOutsideRadius()
    {
        var state = CreateMinimalState();

        state.RoamingEnemies.Add(new Dictionary<string, object>
        {
            ["id"] = 1,
            ["kind"] = "scout",
            ["pos"] = new GridPoint(50, 50), // far away
            ["hp"] = 3,
        });

        var results = WorldEntities.GetEntitiesNear(state, new GridPoint(10, 10), 5);
        Assert.Empty(results);
    }

    [Fact]
    public void GetEntitiesNear_ReturnsMixedEntityTypes()
    {
        var state = CreateMinimalState();
        var center = new GridPoint(32, 32);

        state.RoamingEnemies.Add(new Dictionary<string, object>
        {
            ["id"] = 1,
            ["kind"] = "scout",
            ["pos"] = new GridPoint(33, 32),
            ["hp"] = 3,
        });

        state.Npcs.Add(new Dictionary<string, object>
        {
            ["type"] = "merchant",
            ["pos"] = new GridPoint(31, 32),
            ["name"] = "Merchant Adira",
        });

        var nodePos = new GridPoint(32, 33);
        int idx = SimMap.Idx(nodePos.X, nodePos.Y, state.MapW);
        state.ResourceNodes[idx] = new Dictionary<string, object>
        {
            ["type"] = "stone_quarry",
            ["pos"] = nodePos,
        };

        var results = WorldEntities.GetEntitiesNear(state, center, 3);
        Assert.Equal(3, results.Count);

        var types = results.Select(r => r["entity_type"]?.ToString()).OrderBy(t => t).ToList();
        Assert.Contains("enemy", types);
        Assert.Contains("npc", types);
        Assert.Contains("resource", types);
    }

    // --- Desert/Snow terrain biome tests ---

    [Fact]
    public void PopulateWorld_DesertTerrainGeneratedInSouthEast()
    {
        var state = CreateWorldState();
        var bp = state.BasePos;

        // Check tiles far south-east of the base (dist > 18, x > bp.X+4, y > bp.Y+4)
        var desertTiles = new List<string>();
        for (int y = bp.Y + 10; y < state.MapH; y++)
        {
            for (int x = bp.X + 10; x < state.MapW; x++)
            {
                double dist = Math.Sqrt(Math.Pow(x - bp.X, 2) + Math.Pow(y - bp.Y, 2));
                if (dist > 18)
                {
                    string terrain = SimMap.GetTerrain(state, new GridPoint(x, y));
                    desertTiles.Add(terrain);
                }
            }
        }

        Assert.True(desertTiles.Count > 0, "Should have tiles in the far south-east region");
        Assert.Contains(SimMap.Desert, desertTiles);
    }

    [Fact]
    public void PopulateWorld_SnowTerrainGeneratedInNorthWest()
    {
        var state = CreateWorldState();
        var bp = state.BasePos;

        // Check tiles far north-west of the base (dist > 18, x < bp.X-4, y < bp.Y-4)
        var snowTiles = new List<string>();
        for (int y = 0; y < bp.Y - 4; y++)
        {
            for (int x = 0; x < bp.X - 4; x++)
            {
                double dist = Math.Sqrt(Math.Pow(x - bp.X, 2) + Math.Pow(y - bp.Y, 2));
                if (dist > 18)
                {
                    string terrain = SimMap.GetTerrain(state, new GridPoint(x, y));
                    snowTiles.Add(terrain);
                }
            }
        }

        Assert.True(snowTiles.Count > 0, "Should have tiles in the far north-west region");
        Assert.Contains(SimMap.Snow, snowTiles);
    }

    // --- Advanced resource node tests ---

    [Fact]
    public void PopulateWorld_ResourceNodesIncludeAdvancedTypes()
    {
        var state = CreateWorldState();
        var advancedTypes = new HashSet<string> { "herb_patch", "iron_deposit", "pine_forest", "crystal_cave" };

        var resourceTypes = state.ResourceNodes.Values
            .Select(n => n.GetValueOrDefault("type")?.ToString() ?? "")
            .ToList();

        bool hasAdvanced = resourceTypes.Any(t => advancedTypes.Contains(t));
        Assert.True(hasAdvanced,
            $"Expected at least one advanced resource type among: {string.Join(", ", advancedTypes)}. " +
            $"Got: {string.Join(", ", resourceTypes.Distinct())}");
    }

    [Fact]
    public void PopulateWorld_DepthsZoneHasResourceNodes()
    {
        var state = CreateWorldState();

        var depthsNodes = state.ResourceNodes.Values
            .Where(n => n.GetValueOrDefault("zone")?.ToString() == SimMap.ZoneDepths)
            .ToList();

        Assert.True(depthsNodes.Count > 0,
            "Depths zone should have resource nodes");
    }

    // --- Outpost NPC tests ---

    [Fact]
    public void PopulateWorld_OutpostNpcsHaveZoneKey()
    {
        var state = CreateWorldState();

        var outpostNpcs = state.Npcs.Where(n => n.ContainsKey("zone")).ToList();
        Assert.True(outpostNpcs.Count > 0, "Should have at least one outpost NPC");

        foreach (var npc in outpostNpcs)
        {
            Assert.True(npc.ContainsKey("zone"),
                $"Outpost NPC '{npc.GetValueOrDefault("name")}' must have 'zone' key");
            Assert.True(npc.ContainsKey("facing"),
                $"Outpost NPC '{npc.GetValueOrDefault("name")}' must have 'facing' key");

            string zone = npc["zone"]?.ToString() ?? "";
            Assert.True(zone == SimMap.ZoneFrontier || zone == SimMap.ZoneWilderness || zone == SimMap.ZoneDepths,
                $"Outpost NPC zone '{zone}' must be frontier, wilderness, or depths");
        }
    }

    // --- POI tests ---

    [Fact]
    public void PopulateWorld_PoisSpreadAcrossAllZones()
    {
        var state = CreateWorldState();

        var poiZones = state.ActivePois.Values
            .Where(p => p.ContainsKey("zone"))
            .Select(p => p["zone"]?.ToString() ?? "")
            .Distinct()
            .ToList();

        Assert.Contains(SimMap.ZoneSafe, poiZones);
        Assert.Contains(SimMap.ZoneFrontier, poiZones);
        Assert.Contains(SimMap.ZoneWilderness, poiZones);
        Assert.Contains(SimMap.ZoneDepths, poiZones);
    }

    [Fact]
    public void PopulateWorld_MorePoisThanBefore()
    {
        var state = CreateWorldState();

        Assert.True(state.ActivePois.Count >= 12,
            $"Expected at least 12 POIs (12 guaranteed + random bonus), got {state.ActivePois.Count}");
    }
}
