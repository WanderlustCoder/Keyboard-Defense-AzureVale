using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class TargetingTests
{
    private static Dictionary<string, object> Enemy(
        int id,
        int x,
        int y,
        int hp = 10,
        int speed = 1,
        bool alive = true)
    {
        return new Dictionary<string, object>
        {
            ["id"] = id,
            ["x"] = x,
            ["y"] = y,
            ["hp"] = hp,
            ["speed"] = speed,
            ["alive"] = alive,
        };
    }

    private static Dictionary<string, object> Tower(int x, int y, string targetMode = "nearest")
    {
        return new Dictionary<string, object>
        {
            ["x"] = x,
            ["y"] = y,
            ["target_mode"] = targetMode,
        };
    }

    private static int Id(Dictionary<string, object>? entity)
    {
        Assert.NotNull(entity);
        return Convert.ToInt32(entity!["id"]);
    }

    private static List<int> Ids(IEnumerable<Dictionary<string, object>> entities)
        => entities.Select(Id).ToList();

    [Fact]
    public void FindNearest_ReturnsClosestEnemyByManhattanDistance()
    {
        var tower = Tower(0, 0);
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 6, 0),
            Enemy(2, 1, 2),
            Enemy(3, 3, 3),
        };

        var target = Targeting.FindNearest(tower, enemies);

        Assert.Equal(2, Id(target));
    }

    [Fact]
    public void FindStrongest_ReturnsEnemyWithHighestHp()
    {
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 0, 0, hp: 12),
            Enemy(2, 0, 0, hp: 30),
            Enemy(3, 0, 0, hp: 20),
        };

        var target = Targeting.FindStrongest(enemies);

        Assert.Equal(2, Id(target));
    }

    [Fact]
    public void FindWeakest_ReturnsEnemyWithLowestHp()
    {
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 0, 0, hp: 12),
            Enemy(2, 0, 0, hp: 4),
            Enemy(3, 0, 0, hp: 20),
        };

        var target = Targeting.FindWeakest(enemies);

        Assert.Equal(2, Id(target));
    }

    [Fact]
    public void FindFastest_ReturnsEnemyWithHighestSpeed()
    {
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 0, 0, speed: 2),
            Enemy(2, 0, 0, speed: 7),
            Enemy(3, 0, 0, speed: 5),
        };

        var target = Targeting.FindFastest(enemies);

        Assert.Equal(2, Id(target));
    }

    [Fact]
    public void FindFirst_ReturnsFirstEnemyInList()
    {
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(10, 0, 0),
            Enemy(20, 0, 0),
            Enemy(30, 0, 0),
        };

        var target = Targeting.FindFirst(enemies);

        Assert.Equal(10, Id(target));
    }

    [Fact]
    public void FindLast_ReturnsLastEnemyInList()
    {
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(10, 0, 0),
            Enemy(20, 0, 0),
            Enemy(30, 0, 0),
        };

        var target = Targeting.FindLast(enemies);

        Assert.Equal(30, Id(target));
    }

    [Fact]
    public void FindTarget_WithNearestMode_ReturnsNearestAliveEnemy()
    {
        var state = DefaultState.Create();
        var tower = Tower(0, 0, "nearest");
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 1, 0, alive: false),
            Enemy(2, 4, 4),
            Enemy(3, 2, 0),
        };

        var target = Targeting.FindTarget(state, tower, enemies);

        Assert.Equal(3, Id(target));
    }

    [Fact]
    public void FindTarget_WithStrongestMode_ReturnsStrongestAliveEnemy()
    {
        var state = DefaultState.Create();
        var tower = Tower(0, 0, "strongest");
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 1, 1, hp: 99, alive: false),
            Enemy(2, 2, 2, hp: 20),
            Enemy(3, 3, 3, hp: 40),
        };

        var target = Targeting.FindTarget(state, tower, enemies);

        Assert.Equal(3, Id(target));
    }

    [Fact]
    public void FindTarget_WithWeakestMode_ReturnsWeakestAliveEnemy()
    {
        var state = DefaultState.Create();
        var tower = Tower(0, 0, "weakest");
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 1, 1, hp: 1, alive: false),
            Enemy(2, 2, 2, hp: 15),
            Enemy(3, 3, 3, hp: 9),
        };

        var target = Targeting.FindTarget(state, tower, enemies);

        Assert.Equal(3, Id(target));
    }

    [Fact]
    public void FindTarget_WithFastestMode_ReturnsFastestAliveEnemy()
    {
        var state = DefaultState.Create();
        var tower = Tower(0, 0, "fastest");
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 1, 1, speed: 99, alive: false),
            Enemy(2, 2, 2, speed: 3),
            Enemy(3, 3, 3, speed: 7),
        };

        var target = Targeting.FindTarget(state, tower, enemies);

        Assert.Equal(3, Id(target));
    }

    [Fact]
    public void FindTarget_WithFirstMode_ReturnsFirstAliveEnemy()
    {
        var state = DefaultState.Create();
        var tower = Tower(0, 0, "first");
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 0, 0, alive: false),
            Enemy(2, 0, 0),
            Enemy(3, 0, 0),
        };

        var target = Targeting.FindTarget(state, tower, enemies);

        Assert.Equal(2, Id(target));
    }

    [Fact]
    public void FindTarget_WithLastMode_ReturnsLastAliveEnemy()
    {
        var state = DefaultState.Create();
        var tower = Tower(0, 0, "last");
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 0, 0),
            Enemy(2, 0, 0),
            Enemy(3, 0, 0, alive: false),
        };

        var target = Targeting.FindTarget(state, tower, enemies);

        Assert.Equal(2, Id(target));
    }

    [Fact]
    public void FindTarget_WithUnknownMode_FallsBackToNearest()
    {
        var state = DefaultState.Create();
        var tower = Tower(0, 0, "not_a_mode");
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 9, 9),
            Enemy(2, 1, 1),
        };

        var target = Targeting.FindTarget(state, tower, enemies);

        Assert.Equal(2, Id(target));
    }

    [Fact]
    public void FindTarget_WithEmptyEnemyList_ReturnsNull()
    {
        var state = DefaultState.Create();
        var tower = Tower(0, 0);

        var target = Targeting.FindTarget(state, tower, new List<Dictionary<string, object>>());

        Assert.Null(target);
    }

    [Fact]
    public void FindTarget_WithOnlyDeadEnemies_ReturnsNull()
    {
        var state = DefaultState.Create();
        var tower = Tower(0, 0);
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 0, 0, alive: false),
            Enemy(2, 1, 0, alive: false),
        };

        var target = Targeting.FindTarget(state, tower, enemies);

        Assert.Null(target);
    }

    [Fact]
    public void FindTarget_ExcludesDeadEnemiesFromSelection()
    {
        var state = DefaultState.Create();
        var tower = Tower(0, 0, "strongest");
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 0, 0, hp: 500, alive: false),
            Enemy(2, 0, 0, hp: 30),
            Enemy(3, 0, 0, hp: 40),
        };

        var target = Targeting.FindTarget(state, tower, enemies);

        Assert.Equal(3, Id(target));
    }

    [Fact]
    public void FindMultiTargets_ReturnsRequestedNearestAliveEnemiesInDistanceOrder()
    {
        var state = DefaultState.Create();
        var tower = Tower(0, 0);
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 3, 0),
            Enemy(2, 1, 0),
            Enemy(3, 0, 1, alive: false),
            Enemy(4, 2, 0),
        };

        var targets = Targeting.FindMultiTargets(state, tower, enemies, 2);

        Assert.Equal(new[] { 2, 4 }, Ids(targets));
    }

    [Fact]
    public void FindMultiTargets_WhenCountExceedsAlive_ReturnsAllAliveEnemies()
    {
        var state = DefaultState.Create();
        var tower = Tower(0, 0);
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 1, 0),
            Enemy(2, 2, 0),
            Enemy(3, 0, 0, alive: false),
        };

        var targets = Targeting.FindMultiTargets(state, tower, enemies, 10);

        Assert.Equal(new[] { 1, 2 }, Ids(targets));
    }

    [Fact]
    public void FindMultiTargets_WithNoAliveEnemies_ReturnsEmpty()
    {
        var state = DefaultState.Create();
        var tower = Tower(0, 0);
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 1, 0, alive: false),
            Enemy(2, 2, 0, alive: false),
        };

        var targets = Targeting.FindMultiTargets(state, tower, enemies, 3);

        Assert.Empty(targets);
    }

    [Fact]
    public void FindAoeTargets_ReturnsOnlyAliveEnemiesWithinRadius()
    {
        var center = new Dictionary<string, object>
        {
            ["x"] = 5,
            ["y"] = 5,
        };
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 5, 7),
            Enemy(2, 6, 5),
            Enemy(3, 8, 5),
            Enemy(4, 5, 6, alive: false),
        };

        var targets = Targeting.FindAoeTargets(center, enemies, 2);

        Assert.Equal(new[] { 1, 2 }, Ids(targets));
    }

    [Fact]
    public void FindChainTargets_BuildsNearestUnusedChainAndStopsAtMaxJumps()
    {
        var first = Enemy(1, 0, 0);
        var enemies = new List<Dictionary<string, object>>
        {
            first,
            Enemy(2, 1, 0),
            Enemy(3, 3, 0),
            Enemy(4, 4, 0),
            Enemy(5, 6, 0),
        };

        var chain = Targeting.FindChainTargets(first, enemies, maxJumps: 2, jumpRange: 2);

        Assert.Equal(new[] { 1, 2, 3 }, Ids(chain));
    }

    [Fact]
    public void FindChainTargets_StopsWhenNoAliveEnemyWithinJumpRange()
    {
        var first = Enemy(1, 0, 0);
        var enemies = new List<Dictionary<string, object>>
        {
            first,
            Enemy(2, 1, 0, alive: false),
            Enemy(3, 10, 0),
        };

        var chain = Targeting.FindChainTargets(first, enemies, maxJumps: 5, jumpRange: 2);

        Assert.Equal(new[] { 1 }, Ids(chain));
    }

    [Fact]
    public void ManhattanDistance_ReturnsExpectedValueForDifferentPoints()
    {
        var a = new Dictionary<string, object>
        {
            ["x"] = -2,
            ["y"] = 5,
        };
        var b = new Dictionary<string, object>
        {
            ["x"] = 3,
            ["y"] = 1,
        };

        Assert.Equal(9, Targeting.ManhattanDistance(a, b));
        Assert.Equal(9, Targeting.ManhattanDistance(b, a));
    }

    [Fact]
    public void ManhattanDistance_ForSamePoint_ReturnsZero()
    {
        var point = new Dictionary<string, object>
        {
            ["x"] = 12,
            ["y"] = -7,
        };

        Assert.Equal(0, Targeting.ManhattanDistance(point, point));
    }
}
