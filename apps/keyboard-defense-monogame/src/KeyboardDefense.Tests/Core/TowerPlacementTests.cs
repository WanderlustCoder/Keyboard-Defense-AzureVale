using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class TowerPlacementTests
{
    [Fact]
    public void BuildTower_OnValidTerrain_PlacesTower()
    {
        LoadBuildingsData();
        var state = DefaultState.Create();
        var pos = PrepareBuildableTile(state, dx: 1, dy: 0);
        int index = pos.ToIndex(state.MapW);
        var cost = BuildingsData.CostFor("tower");
        Assert.NotEmpty(cost);
        SeedResourcesForCost(state, cost, padding: 5);

        int apBefore = state.Ap;

        var (newState, events) = ApplyBuild(state, pos);

        Assert.Equal(apBefore - 1, newState.Ap);
        Assert.Equal("tower", newState.Structures[index]);
        Assert.Equal(1, newState.StructureLevels[index]);
        Assert.Contains($"Built tower at ({pos.X},{pos.Y}).", events);
    }

    [Fact]
    public void BuildTower_OnOccupiedTile_Fails()
    {
        LoadBuildingsData();
        var state = DefaultState.Create();
        var pos = PrepareBuildableTile(state, dx: 1, dy: 0);
        int index = pos.ToIndex(state.MapW);
        state.Structures[index] = "wall";
        state.StructureLevels[index] = 1;

        var cost = BuildingsData.CostFor("tower");
        SeedResourcesForCost(state, cost, padding: 5);
        int apBefore = state.Ap;
        int towerCountBefore = state.Buildings.GetValueOrDefault("tower", 0);
        var resourcesBefore = new Dictionary<string, int>(state.Resources);

        var (newState, events) = ApplyBuild(state, pos);

        Assert.Equal(apBefore, newState.Ap);
        Assert.Equal("wall", newState.Structures[index]);
        Assert.Equal(1, newState.StructureLevels[index]);
        Assert.Equal(towerCountBefore, newState.Buildings.GetValueOrDefault("tower", 0));
        Assert.Equal(resourcesBefore, newState.Resources);
        Assert.Contains("That tile is already occupied.", events);
    }

    [Fact]
    public void BuildTower_DeductsConfiguredResourceCost()
    {
        LoadBuildingsData();
        var state = DefaultState.Create();
        var pos = PrepareBuildableTile(state, dx: 2, dy: 0);
        var cost = BuildingsData.CostFor("tower");
        Assert.NotEmpty(cost);
        SeedResourcesForCost(state, cost, padding: 10);
        var resourcesBefore = new Dictionary<string, int>(state.Resources);

        var (newState, _) = ApplyBuild(state, pos);

        foreach (string resource in GameState.ResourceKeys)
        {
            int expected = resourcesBefore[resource] - cost.GetValueOrDefault(resource, 0);
            Assert.Equal(expected, newState.Resources[resource]);
        }
    }

    [Fact]
    public void AutoTargeting_RangeCalculation_UsesInclusiveManhattanDistance()
    {
        var state = DefaultState.Create();
        int towerIndex = state.BasePos.ToIndex(state.MapW);
        var inRange = new GridPoint(state.BasePos.X + 3, state.BasePos.Y);
        var outOfRange = new GridPoint(state.BasePos.X + 4, state.BasePos.Y);
        state.Enemies.Add(Enemy(1, inRange));
        state.Enemies.Add(Enemy(2, outOfRange));

        var targets = AutoTargeting.PickTargets(
            state,
            towerIndex,
            AutoTowerTypes.AutoTargetMode.Nearest,
            range: 3,
            count: 4);

        var target = Assert.Single(targets);
        Assert.Equal(1, EnemyId(target));
    }

    [Fact]
    public void AutoTargeting_PriorityNearest_SelectsClosestEnemy()
    {
        var state = DefaultState.Create();
        int towerIndex = state.BasePos.ToIndex(state.MapW);
        state.Enemies.Add(Enemy(10, new GridPoint(state.BasePos.X + 3, state.BasePos.Y), hp: 100));
        state.Enemies.Add(Enemy(11, new GridPoint(state.BasePos.X + 1, state.BasePos.Y), hp: 1));

        var targets = AutoTargeting.PickTargets(
            state,
            towerIndex,
            AutoTowerTypes.AutoTargetMode.Nearest,
            range: 5);

        var target = Assert.Single(targets);
        Assert.Equal(11, EnemyId(target));
    }

    [Fact]
    public void AutoTargeting_PriorityWeakest_SelectsLowestHpEnemy()
    {
        var state = DefaultState.Create();
        int towerIndex = state.BasePos.ToIndex(state.MapW);
        state.Enemies.Add(Enemy(20, new GridPoint(state.BasePos.X + 1, state.BasePos.Y), hp: 18, maxHp: 18));
        state.Enemies.Add(Enemy(21, new GridPoint(state.BasePos.X + 2, state.BasePos.Y), hp: 4, maxHp: 20));
        state.Enemies.Add(Enemy(22, new GridPoint(state.BasePos.X + 3, state.BasePos.Y), hp: 9, maxHp: 9));

        var targets = AutoTargeting.PickTargets(
            state,
            towerIndex,
            AutoTowerTypes.AutoTargetMode.LowestHp,
            range: 6);

        var target = Assert.Single(targets);
        Assert.Equal(21, EnemyId(target));
    }

    [Fact]
    public void AutoTargeting_PriorityStrongest_SelectsHighestHpEnemy()
    {
        var state = DefaultState.Create();
        int towerIndex = state.BasePos.ToIndex(state.MapW);
        state.Enemies.Add(Enemy(30, new GridPoint(state.BasePos.X + 1, state.BasePos.Y), hp: 12, maxHp: 20));
        state.Enemies.Add(Enemy(31, new GridPoint(state.BasePos.X + 2, state.BasePos.Y), hp: 35, maxHp: 35));
        state.Enemies.Add(Enemy(32, new GridPoint(state.BasePos.X + 3, state.BasePos.Y), hp: 25, maxHp: 25));

        var targets = AutoTargeting.PickTargets(
            state,
            towerIndex,
            AutoTowerTypes.AutoTargetMode.HighestHp,
            range: 6);

        var target = Assert.Single(targets);
        Assert.Equal(31, EnemyId(target));
    }

    [Fact]
    public void AutoTargeting_EnemyOutsideRange_ReturnsNoTargets()
    {
        var state = DefaultState.Create();
        int towerIndex = state.BasePos.ToIndex(state.MapW);
        state.Enemies.Add(Enemy(40, new GridPoint(state.BasePos.X + 7, state.BasePos.Y)));

        var targets = AutoTargeting.PickTargets(
            state,
            towerIndex,
            AutoTowerTypes.AutoTargetMode.Nearest,
            range: 3);

        Assert.Empty(targets);
    }

    [Fact]
    public void AutoTowerCombat_MultipleTowersCanTargetSameEnemy()
    {
        var state = DefaultState.Create();
        int leftTowerIndex = new GridPoint(state.BasePos.X - 1, state.BasePos.Y).ToIndex(state.MapW);
        int rightTowerIndex = new GridPoint(state.BasePos.X + 1, state.BasePos.Y).ToIndex(state.MapW);

        state.Structures[leftTowerIndex] = AutoTowerTypes.Sentry;
        state.Structures[rightTowerIndex] = AutoTowerTypes.Sentry;

        state.Enemies.Add(Enemy(50, new GridPoint(state.BasePos.X, state.BasePos.Y + 2), hp: 30, maxHp: 30));

        var events = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.016);

        Assert.Equal(2, events.Count);
        Assert.Equal(2, events.Count(e => Convert.ToInt32(e["target_id"]) == 50));
        Assert.Equal(20, Convert.ToInt32(state.Enemies.Single()["hp"]));
    }

    private static (GameState State, List<string> Events) ApplyBuild(GameState state, GridPoint pos)
    {
        var result = IntentApplier.Apply(state, SimIntents.Make("build", new Dictionary<string, object>
        {
            ["building"] = "tower",
            ["x"] = pos.X,
            ["y"] = pos.Y
        }));

        var newState = Assert.IsType<GameState>(result["state"]);
        var events = Assert.IsType<List<string>>(result["events"]);
        return (newState, events);
    }

    private static GridPoint PrepareBuildableTile(GameState state, int dx, int dy)
    {
        var pos = new GridPoint(state.BasePos.X + dx, state.BasePos.Y + dy);
        Assert.True(SimMap.InBounds(pos.X, pos.Y, state.MapW, state.MapH));
        int index = pos.ToIndex(state.MapW);
        state.Discovered.Add(index);
        state.Terrain[index] = SimMap.TerrainPlains;
        state.Structures.Remove(index);
        state.StructureLevels.Remove(index);
        return pos;
    }

    private static void SeedResourcesForCost(GameState state, Dictionary<string, int> cost, int padding)
    {
        foreach (string resource in GameState.ResourceKeys)
            state.Resources[resource] = cost.GetValueOrDefault(resource, 0) + padding;
    }

    private static int EnemyId(Dictionary<string, object> enemy)
        => Convert.ToInt32(enemy.GetValueOrDefault("id", -1));

    private static Dictionary<string, object> Enemy(
        int id,
        GridPoint pos,
        int hp = 10,
        int maxHp = 10,
        double speed = 1.0,
        int damage = 1)
    {
        return new Dictionary<string, object>
        {
            ["id"] = id,
            ["pos"] = pos,
            ["hp"] = hp,
            ["max_hp"] = maxHp,
            ["speed"] = speed,
            ["damage"] = damage,
        };
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
