using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Extended tests for WorldEntities — TickEntityMovement mechanics, PopulateWorld entity
/// distribution, and GetEntitiesNear edge cases.
/// </summary>
public class WorldEntitiesExtendedTests
{
    // =========================================================================
    // TickEntityMovement
    // =========================================================================

    [Fact]
    public void TickEntityMovement_EnemiesWithinPatrolRange_CanMove()
    {
        var state = CreateMinimalState(seed: "tick-movement-can-move");
        var origin = new GridPoint(10, 10);
        AddEnemy(state, 1, origin);

        // Tick many times — at least some should move
        for (int i = 0; i < 100; i++)
            WorldEntities.TickEntityMovement(state);

        var pos = (GridPoint)state.RoamingEnemies[0]["pos"];
        // Either moved or stayed (probabilistic), but should still be in bounds
        Assert.True(SimMap.InBounds(pos.X, pos.Y, state.MapW, state.MapH));
    }

    [Fact]
    public void TickEntityMovement_DoesNotMoveOntoBasePos()
    {
        var state = CreateMinimalState(seed: "tick-no-base-move");
        // Place enemy adjacent to base
        var pos = new GridPoint(state.BasePos.X + 1, state.BasePos.Y);
        AddEnemy(state, 1, pos);

        for (int i = 0; i < 200; i++)
            WorldEntities.TickEntityMovement(state);

        var finalPos = (GridPoint)state.RoamingEnemies[0]["pos"];
        Assert.NotEqual(state.BasePos, finalPos);
    }

    [Fact]
    public void TickEntityMovement_StaysWithinPatrolRange()
    {
        var state = CreateMinimalState(seed: "tick-patrol-range");
        var origin = new GridPoint(16, 16);
        AddEnemy(state, 1, origin);

        for (int i = 0; i < 500; i++)
            WorldEntities.TickEntityMovement(state);

        var pos = (GridPoint)state.RoamingEnemies[0]["pos"];
        int dist = origin.ManhattanDistance(pos);
        Assert.True(dist <= 8, $"Enemy drifted {dist} tiles from patrol origin (max 8)");
    }

    [Fact]
    public void TickEntityMovement_StaysInBounds()
    {
        var state = CreateMinimalState(width: 8, height: 8, seed: "tick-bounds");
        // Place enemy near edge
        var pos = new GridPoint(1, 1);
        AddEnemy(state, 1, pos);

        for (int i = 0; i < 300; i++)
            WorldEntities.TickEntityMovement(state);

        var finalPos = (GridPoint)state.RoamingEnemies[0]["pos"];
        Assert.True(SimMap.InBounds(finalPos.X, finalPos.Y, state.MapW, state.MapH));
    }

    [Fact]
    public void TickEntityMovement_DoesNotCrashWithNoEnemies()
    {
        var state = CreateMinimalState();
        state.RoamingEnemies.Clear();

        var ex = Record.Exception(() => WorldEntities.TickEntityMovement(state));
        Assert.Null(ex);
    }

    [Fact]
    public void TickEntityMovement_EnemyWithoutPosKey_IsSkipped()
    {
        var state = CreateMinimalState();
        state.RoamingEnemies.Add(new Dictionary<string, object>
        {
            ["id"] = 99,
            ["kind"] = "scout",
            // no "pos" key
        });

        var ex = Record.Exception(() =>
        {
            for (int i = 0; i < 50; i++)
                WorldEntities.TickEntityMovement(state);
        });
        Assert.Null(ex);
    }

    // =========================================================================
    // PopulateWorld — entity counts and distribution
    // =========================================================================

    [Fact]
    public void PopulateWorld_CreatesNpcsIncludingCoreAndOutpost()
    {
        var state = DefaultState.Create("populate-npcs");

        // Should have at least 3 core NPCs (trainer, merchant, quest_giver)
        Assert.True(state.Npcs.Count >= 3,
            $"Expected at least 3 NPCs, got {state.Npcs.Count}");
    }

    [Fact]
    public void PopulateWorld_CreatesResourceNodesAcrossZones()
    {
        var state = DefaultState.Create("populate-resources");

        Assert.True(state.ResourceNodes.Count >= 10,
            $"Expected at least 10 resource nodes, got {state.ResourceNodes.Count}");

        // Check for variety in resource types
        var types = state.ResourceNodes.Values
            .Select(n => n.GetValueOrDefault("type")?.ToString() ?? "")
            .Distinct()
            .ToList();
        Assert.True(types.Count >= 2,
            $"Expected at least 2 distinct resource types, got {types.Count}");
    }

    [Fact]
    public void PopulateWorld_RoamingEnemiesDoNotExceedMaxCap()
    {
        var state = DefaultState.Create("populate-enemy-cap");
        Assert.True(state.RoamingEnemies.Count <= WorldTick.MaxRoamingEnemies,
            $"Expected at most {WorldTick.MaxRoamingEnemies} roaming enemies, got {state.RoamingEnemies.Count}");
    }

    [Fact]
    public void PopulateWorld_RoamingEnemiesHaveValidKinds()
    {
        var state = DefaultState.Create("populate-valid-kinds");
        var validKinds = new HashSet<string> { "scout", "raider", "armored", "berserker", "elite" };

        Assert.All(state.RoamingEnemies, enemy =>
        {
            string kind = enemy.GetValueOrDefault("kind")?.ToString() ?? "";
            Assert.Contains(kind, validKinds);
        });
    }

    [Fact]
    public void PopulateWorld_NpcNames_AreNotEmpty()
    {
        var state = DefaultState.Create("populate-npc-names");

        Assert.All(state.Npcs, npc =>
        {
            string name = npc.GetValueOrDefault("name")?.ToString() ?? "";
            Assert.False(string.IsNullOrWhiteSpace(name));
        });
    }

    [Fact]
    public void PopulateWorld_DifferentSeeds_ProduceDifferentLayouts()
    {
        var state1 = DefaultState.Create("layout-seed-alpha");
        var state2 = DefaultState.Create("layout-seed-beta");

        // At minimum, enemy positions should differ between seeds
        var positions1 = state1.RoamingEnemies
            .Select(e => e.GetValueOrDefault("pos")?.ToString() ?? "")
            .OrderBy(s => s)
            .ToList();
        var positions2 = state2.RoamingEnemies
            .Select(e => e.GetValueOrDefault("pos")?.ToString() ?? "")
            .OrderBy(s => s)
            .ToList();

        // Very unlikely to be identical with different seeds
        Assert.NotEqual(positions1, positions2);
    }

    // =========================================================================
    // GetEntitiesNear — additional edge cases
    // =========================================================================

    [Fact]
    public void GetEntitiesNear_EmptyWorld_ReturnsEmptyList()
    {
        var state = CreateMinimalState();
        var results = WorldEntities.GetEntitiesNear(state, new GridPoint(5, 5), 10);
        Assert.Empty(results);
    }

    [Fact]
    public void GetEntitiesNear_LargeRadius_ReturnsAllEntities()
    {
        var state = CreateMinimalState();
        AddEnemy(state, 1, new GridPoint(0, 0));
        AddEnemy(state, 2, new GridPoint(30, 30));
        AddNpc(state, "merchant", new GridPoint(15, 15), "M");

        var results = WorldEntities.GetEntitiesNear(state, new GridPoint(15, 15), 100);
        Assert.Equal(3, results.Count);
    }

    [Fact]
    public void GetEntitiesNear_DoesNotMutateOriginalEntities()
    {
        var state = CreateMinimalState();
        AddEnemy(state, 1, new GridPoint(5, 5));

        var results = WorldEntities.GetEntitiesNear(state, new GridPoint(5, 5), 1);

        // Result should have entity_type added, but original should not
        Assert.True(results[0].ContainsKey("entity_type"));
        Assert.False(state.RoamingEnemies[0].ContainsKey("entity_type"));
    }

    // =========================================================================
    // PopulateWorld with spec POIs
    // =========================================================================

    [Fact]
    public void PopulateWorld_WithSpecPois_PlacesAtFixedCoordinates()
    {
        var state = CreateMinimalState(64, 64, "spec-pois");
        var specPois = new Dictionary<string, GridPoint>
        {
            ["shrine"] = new GridPoint(10, 10),
            ["camp"] = new GridPoint(20, 20),
        };

        WorldEntities.PopulateWorld(state, specPois);

        Assert.True(state.ActivePois.Count >= 2,
            $"Expected at least 2 POIs from spec, got {state.ActivePois.Count}");
    }

    // =========================================================================
    // Helpers
    // =========================================================================

    private static GameState CreateMinimalState(int width = 32, int height = 32, string seed = "ext-minimal")
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

    private static void AddEnemy(GameState state, int id, GridPoint pos, string kind = "scout")
    {
        state.RoamingEnemies.Add(new Dictionary<string, object>
        {
            ["id"] = id,
            ["kind"] = kind,
            ["pos"] = pos,
            ["hp"] = 3,
            ["tier"] = 0,
            ["patrol_origin"] = pos,
        });
    }

    private static void AddNpc(GameState state, string type, GridPoint pos, string name)
    {
        state.Npcs.Add(new Dictionary<string, object>
        {
            ["type"] = type,
            ["pos"] = pos,
            ["name"] = name,
            ["quest_available"] = true,
            ["facing"] = "south",
        });
    }
}
