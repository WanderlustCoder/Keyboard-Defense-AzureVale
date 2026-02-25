using System.Collections.Generic;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;
using KeyboardDefense.Game.Rendering;
using Microsoft.Xna.Framework;

namespace KeyboardDefense.Tests.Core;

public class MinimapDataTests
{
    private static readonly Color PlainsColor = new(90, 130, 65);
    private static readonly Color ForestColor = new(45, 90, 40);
    private static readonly Color MountainColor = new(130, 110, 90);
    private static readonly Color WaterColor = new(50, 90, 150);
    private static readonly Color FogColor = new(25, 25, 35);

    [Fact]
    public void GenerateData_TerrainColorMappingMatchesTerrainTypes()
    {
        var state = CreateState("minimap_terrain_colors");
        var basePos = state.BasePos;

        var terrainSamples = new (GridPoint Pos, string Terrain, Color Expected)[]
        {
            (basePos, SimMap.TerrainPlains, PlainsColor),
            (new GridPoint(basePos.X + 1, basePos.Y), SimMap.TerrainForest, ForestColor),
            (new GridPoint(basePos.X - 1, basePos.Y), SimMap.TerrainMountain, MountainColor),
            (new GridPoint(basePos.X, basePos.Y + 1), SimMap.TerrainWater, WaterColor),
        };

        foreach (var sample in terrainSamples)
        {
            int idx = SimMap.Idx(sample.Pos.X, sample.Pos.Y, state.MapW);
            state.Discovered.Add(idx);
            state.Terrain[idx] = sample.Terrain;
        }

        var data = MinimapRenderer.GenerateData(state);

        foreach (var sample in terrainSamples)
            Assert.Equal(sample.Expected, data.GetTileColorAt(sample.Pos.X, sample.Pos.Y));
    }

    [Fact]
    public void GenerateData_DiscoveredTilesShowTerrain_UndiscoveredShowFog()
    {
        var state = CreateState("minimap_discovery_fog");
        var discoveredPos = new GridPoint(state.BasePos.X + 1, state.BasePos.Y);
        var undiscoveredPos = FindUndiscoveredTile(state);

        int discoveredIndex = SimMap.Idx(discoveredPos.X, discoveredPos.Y, state.MapW);
        int undiscoveredIndex = SimMap.Idx(undiscoveredPos.X, undiscoveredPos.Y, state.MapW);
        state.Discovered.Add(discoveredIndex);
        state.Discovered.Remove(undiscoveredIndex);
        state.Terrain[discoveredIndex] = SimMap.TerrainForest;
        state.Terrain[undiscoveredIndex] = SimMap.TerrainMountain;

        var data = MinimapRenderer.GenerateData(state);

        Assert.Equal(ForestColor, data.GetTileColorAt(discoveredPos.X, discoveredPos.Y));
        Assert.Equal(FogColor, data.GetTileColorAt(undiscoveredPos.X, undiscoveredPos.Y));
    }

    [Fact]
    public void GenerateData_BasePositionIsMarked()
    {
        var state = CreateState("minimap_base_marker");
        var data = MinimapRenderer.GenerateData(state);

        Assert.Equal(state.BasePos, data.BasePosition);
    }

    [Fact]
    public void GenerateData_EnemyPositionsAppearDuringNight()
    {
        var state = CreateState("minimap_enemy_night");
        state.Phase = "night";
        var enemyPos = new GridPoint(state.BasePos.X + 2, state.BasePos.Y);

        state.Enemies.Clear();
        state.Enemies.Add(new Dictionary<string, object>
        {
            ["id"] = 101,
            ["x"] = enemyPos.X,
            ["y"] = enemyPos.Y,
        });

        var data = MinimapRenderer.GenerateData(state);
        int enemyIndex = SimMap.Idx(enemyPos.X, enemyPos.Y, state.MapW);

        Assert.Contains(enemyIndex, data.EnemyTiles);
    }

    [Fact]
    public void GenerateData_EnemyPositionsAreHiddenDuringDay()
    {
        var state = CreateState("minimap_enemy_day");
        state.Phase = "day";
        var enemyPos = new GridPoint(state.BasePos.X + 2, state.BasePos.Y);

        state.Enemies.Clear();
        state.Enemies.Add(new Dictionary<string, object>
        {
            ["id"] = 202,
            ["x"] = enemyPos.X,
            ["y"] = enemyPos.Y,
        });

        var data = MinimapRenderer.GenerateData(state);
        int enemyIndex = SimMap.Idx(enemyPos.X, enemyPos.Y, state.MapW);

        Assert.DoesNotContain(enemyIndex, data.EnemyTiles);
    }

    [Fact]
    public void GenerateData_BuildingPositionsAppearOnMinimap()
    {
        var state = CreateState("minimap_buildings");
        var buildingPos = new GridPoint(state.BasePos.X + 1, state.BasePos.Y + 1);
        int buildingIndex = SimMap.Idx(buildingPos.X, buildingPos.Y, state.MapW);

        state.Structures[buildingIndex] = "tower";

        var data = MinimapRenderer.GenerateData(state);

        Assert.Contains(buildingIndex, data.StructureTiles);
    }

    [Fact]
    public void GenerateData_NpcPositionsAppearOnMinimap()
    {
        var state = CreateState("minimap_npcs");
        var npcPos = new GridPoint(state.BasePos.X + 1, state.BasePos.Y);
        int npcIndex = SimMap.Idx(npcPos.X, npcPos.Y, state.MapW);
        state.Discovered.Add(npcIndex);

        state.Npcs.Add(new Dictionary<string, object>
        {
            ["id"] = "npc_test",
            ["type"] = "merchant",
            ["name"] = "Mira",
            ["pos"] = npcPos,
        });

        var data = MinimapRenderer.GenerateData(state);

        Assert.Contains(npcIndex, data.NpcTiles);
    }

    [Fact]
    public void GenerateData_RoamingEnemiesRequireDiscoveryAtNight()
    {
        var state = CreateState("minimap_roaming_discovery");
        state.Phase = "night";

        var discoveredEnemyPos = new GridPoint(state.BasePos.X + 2, state.BasePos.Y);
        var undiscoveredEnemyPos = FindUndiscoveredTile(state);
        int discoveredIndex = SimMap.Idx(discoveredEnemyPos.X, discoveredEnemyPos.Y, state.MapW);
        int undiscoveredIndex = SimMap.Idx(undiscoveredEnemyPos.X, undiscoveredEnemyPos.Y, state.MapW);

        state.Discovered.Add(discoveredIndex);
        state.Discovered.Remove(undiscoveredIndex);

        state.RoamingEnemies.Clear();
        state.RoamingEnemies.Add(new Dictionary<string, object> { ["pos"] = discoveredEnemyPos });
        state.RoamingEnemies.Add(new Dictionary<string, object> { ["pos"] = undiscoveredEnemyPos });

        var data = MinimapRenderer.GenerateData(state);

        Assert.Contains(discoveredIndex, data.EnemyTiles);
        Assert.DoesNotContain(undiscoveredIndex, data.EnemyTiles);
    }

    [Fact]
    public void GenerateData_UpdatesAfterExploration()
    {
        var state = CreateState("minimap_exploration_update");
        var targetPos = FindUndiscoveredTile(state);
        int targetIndex = SimMap.Idx(targetPos.X, targetPos.Y, state.MapW);
        state.Terrain[targetIndex] = SimMap.TerrainMountain;

        var before = MinimapRenderer.GenerateData(state);
        Assert.Equal(FogColor, before.GetTileColorAt(targetPos.X, targetPos.Y));

        state.Discovered.Add(targetIndex);

        var after = MinimapRenderer.GenerateData(state);
        Assert.Equal(MountainColor, after.GetTileColorAt(targetPos.X, targetPos.Y));
    }

    private static GameState CreateState(string seed)
        => DefaultState.Create(seed, placeStartingTowers: false, useWorldSpec: false);

    private static GridPoint FindUndiscoveredTile(GameState state)
    {
        for (int y = 0; y < state.MapH; y++)
        {
            for (int x = 0; x < state.MapW; x++)
            {
                int index = SimMap.Idx(x, y, state.MapW);
                if (!state.Discovered.Contains(index))
                    return new GridPoint(x, y);
            }
        }

        throw new InvalidOperationException("No undiscovered tile was found for this test state.");
    }
}
