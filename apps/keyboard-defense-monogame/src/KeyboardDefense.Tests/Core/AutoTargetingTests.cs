using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class AutoTargetingTests
{
    [Fact]
    public void PickTargets_WhenNoEnemiesAreInRange_ReturnsEmpty()
    {
        var state = CreateState();
        int towerIndex = Index(state, 0, 0);
        state.Enemies.Add(Enemy(1, new GridPoint(6, 6)));
        state.Enemies.Add(new Dictionary<string, object>
        {
            ["id"] = 2,
            ["hp"] = 15,
            ["max_hp"] = 15,
        });

        var targets = AutoTargeting.PickTargets(state, towerIndex, AutoTowerTypes.AutoTargetMode.Nearest, range: 2);

        Assert.Empty(targets);
    }

    [Fact]
    public void PickTargets_Nearest_ReturnsClosestEnemiesByDistance()
    {
        var state = CreateState();
        int towerIndex = Index(state, 2, 2);
        state.Enemies.Add(Enemy(1, new GridPoint(5, 2)));
        state.Enemies.Add(Enemy(2, new GridPoint(1, 2)));
        state.Enemies.Add(Enemy(3, new GridPoint(2, 4)));
        state.Enemies.Add(Enemy(4, new GridPoint(9, 9)));

        var targets = AutoTargeting.PickTargets(
            state,
            towerIndex,
            AutoTowerTypes.AutoTargetMode.Nearest,
            range: 3,
            count: 2);

        Assert.Equal(new[] { 2, 3 }, Ids(targets));
    }

    [Fact]
    public void PickTargets_HighestHp_ReturnsEnemiesWithHighestHpFirst()
    {
        var state = CreateState();
        int towerIndex = Index(state, 0, 0);
        state.Enemies.Add(Enemy(1, new GridPoint(1, 0), hp: 12, maxHp: 20));
        state.Enemies.Add(Enemy(2, new GridPoint(2, 0), hp: 40, maxHp: 40));
        state.Enemies.Add(Enemy(3, new GridPoint(3, 0), hp: 25, maxHp: 25));

        var targets = AutoTargeting.PickTargets(
            state,
            towerIndex,
            AutoTowerTypes.AutoTargetMode.HighestHp,
            range: 5,
            count: 2);

        Assert.Equal(new[] { 2, 3 }, Ids(targets));
    }

    [Fact]
    public void PickTargets_LowestHp_ReturnsEnemiesWithLowestHpFirst()
    {
        var state = CreateState();
        int towerIndex = Index(state, 0, 0);
        state.Enemies.Add(Enemy(1, new GridPoint(1, 0), hp: 12, maxHp: 12));
        state.Enemies.Add(Enemy(2, new GridPoint(2, 0), hp: 4, maxHp: 20));
        state.Enemies.Add(Enemy(3, new GridPoint(3, 0), hp: 9, maxHp: 9));

        var targets = AutoTargeting.PickTargets(
            state,
            towerIndex,
            AutoTowerTypes.AutoTargetMode.LowestHp,
            range: 5,
            count: 2);

        Assert.Equal(new[] { 2, 3 }, Ids(targets));
    }

    [Fact]
    public void PickTargets_Fastest_ReturnsEnemiesWithHighestSpeedFirst()
    {
        var state = CreateState();
        int towerIndex = Index(state, 0, 0);
        state.Enemies.Add(Enemy(1, new GridPoint(1, 0), speed: 1.5));
        state.Enemies.Add(Enemy(2, new GridPoint(2, 0), speed: 3.0));
        state.Enemies.Add(Enemy(3, new GridPoint(3, 0), speed: 4.5));

        var targets = AutoTargeting.PickTargets(
            state,
            towerIndex,
            AutoTowerTypes.AutoTargetMode.Fastest,
            range: 5,
            count: 2);

        Assert.Equal(new[] { 3, 2 }, Ids(targets));
    }

    [Fact]
    public void PickTargets_Cluster_PrioritizesEnemyWithMostNearbyNeighbors()
    {
        var state = CreateState();
        int towerIndex = Index(state, 0, 0);
        state.Enemies.Add(Enemy(1, new GridPoint(5, 5)));
        state.Enemies.Add(Enemy(2, new GridPoint(5, 7)));
        state.Enemies.Add(Enemy(3, new GridPoint(7, 5)));
        state.Enemies.Add(Enemy(4, new GridPoint(3, 5)));
        state.Enemies.Add(Enemy(5, new GridPoint(12, 12)));

        var targets = AutoTargeting.PickTargets(
            state,
            towerIndex,
            AutoTowerTypes.AutoTargetMode.Cluster,
            range: 30,
            count: 1);

        var target = Assert.Single(targets);
        Assert.Equal(1, Id(target));
    }

    [Fact]
    public void PickTargets_Chain_StartsFromNearestThenChainsByNearestRemaining()
    {
        var state = CreateState();
        int towerIndex = Index(state, 0, 0);
        state.Enemies.Add(Enemy(1, new GridPoint(1, 0)));
        state.Enemies.Add(Enemy(2, new GridPoint(4, 0)));
        state.Enemies.Add(Enemy(3, new GridPoint(2, 0)));
        state.Enemies.Add(Enemy(4, new GridPoint(6, 0)));

        var targets = AutoTargeting.PickTargets(
            state,
            towerIndex,
            AutoTowerTypes.AutoTargetMode.Chain,
            range: 10,
            count: 3);

        Assert.Equal(new[] { 1, 3, 2 }, Ids(targets));
    }

    [Fact]
    public void PickTargets_Zone_ReturnsAllInRangeTargetsRegardlessOfCount()
    {
        var state = CreateState();
        int towerIndex = Index(state, 0, 0);
        state.Enemies.Add(Enemy(1, new GridPoint(1, 0)));
        state.Enemies.Add(Enemy(2, new GridPoint(0, 2)));
        state.Enemies.Add(Enemy(3, new GridPoint(3, 0)));
        state.Enemies.Add(Enemy(4, new GridPoint(4, 0)));

        var targets = AutoTargeting.PickTargets(
            state,
            towerIndex,
            AutoTowerTypes.AutoTargetMode.Zone,
            range: 3,
            count: 1);

        Assert.Equal(new[] { 1, 2, 3 }, Ids(targets));
    }

    [Fact]
    public void PickTargets_Contact_ReturnsOnlyAdjacentEnemies()
    {
        var state = CreateState();
        int towerIndex = Index(state, 2, 2);
        state.Enemies.Add(Enemy(1, new GridPoint(2, 3)));
        state.Enemies.Add(Enemy(2, new GridPoint(1, 2)));
        state.Enemies.Add(Enemy(3, new GridPoint(2, 4)));

        var targets = AutoTargeting.PickTargets(
            state,
            towerIndex,
            AutoTowerTypes.AutoTargetMode.Contact,
            range: 5,
            count: 3);

        Assert.Equal(new[] { 1, 2 }, Ids(targets));
    }

    [Fact]
    public void PickTargets_Smart_UsesWeightedScoringIncludingKindBonuses()
    {
        var state = CreateState();
        int towerIndex = Index(state, 0, 0);
        state.Enemies.Add(Enemy(1, new GridPoint(1, 0), hp: 20, maxHp: 100, speed: 1.0, damage: 2));
        state.Enemies.Add(Enemy(2, new GridPoint(5, 0), hp: 80, maxHp: 100, speed: 2.0, damage: 3, kind: "boss_beast"));
        state.Enemies.Add(Enemy(3, new GridPoint(2, 0), hp: 70, maxHp: 100, speed: 2.0, damage: 2, kind: "elite_raider"));

        var targets = AutoTargeting.PickTargets(
            state,
            towerIndex,
            AutoTowerTypes.AutoTargetMode.Smart,
            range: 6,
            count: 2);

        Assert.Equal(new[] { 2, 3 }, Ids(targets));
    }

    [Fact]
    public void PickTargets_UnknownMode_FallsBackToNearest()
    {
        var state = CreateState();
        int towerIndex = Index(state, 0, 0);
        state.Enemies.Add(Enemy(1, new GridPoint(3, 0)));
        state.Enemies.Add(Enemy(2, new GridPoint(1, 0)));

        var targets = AutoTargeting.PickTargets(
            state,
            towerIndex,
            (AutoTowerTypes.AutoTargetMode)999,
            range: 5,
            count: 1);

        var target = Assert.Single(targets);
        Assert.Equal(2, Id(target));
    }

    private static GameState CreateState(int mapWidth = 16)
    {
        return new GameState
        {
            MapW = mapWidth,
            Enemies = new List<Dictionary<string, object>>(),
        };
    }

    private static int Index(GameState state, int x, int y) => new GridPoint(x, y).ToIndex(state.MapW);

    private static int Id(Dictionary<string, object>? enemy)
    {
        Assert.NotNull(enemy);
        return Convert.ToInt32(enemy!["id"]);
    }

    private static int[] Ids(IEnumerable<Dictionary<string, object>> enemies)
        => enemies.Select(Id).ToArray();

    private static Dictionary<string, object> Enemy(
        int id,
        GridPoint pos,
        int hp = 10,
        int maxHp = 10,
        double speed = 1.0,
        int damage = 1,
        string kind = "")
    {
        return new Dictionary<string, object>
        {
            ["id"] = id,
            ["pos"] = pos,
            ["hp"] = hp,
            ["max_hp"] = maxHp,
            ["speed"] = speed,
            ["damage"] = damage,
            ["kind"] = kind,
        };
    }
}
