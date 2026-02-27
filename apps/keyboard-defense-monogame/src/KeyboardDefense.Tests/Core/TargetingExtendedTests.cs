using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Extended tests for Targeting — FindNearest with dead enemies, FindTarget mode
/// dispatch edge cases, FindChainTargets boundary, FindAoeTargets boundary,
/// ManhattanDistance with negative coordinates, and multi-target ordering.
/// </summary>
public class TargetingExtendedTests
{
    // =========================================================================
    // FindNearest — dead enemy filtering
    // =========================================================================

    [Fact]
    public void FindNearest_SkipsDeadEnemies_ByHp()
    {
        var tower = Tower(0, 0);
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 1, 0, hp: 0),  // dead by hp
            Enemy(2, 5, 0, hp: 10), // alive
        };

        var target = Targeting.FindNearest(tower, enemies);

        Assert.NotNull(target);
        Assert.Equal(2, Convert.ToInt32(target!["id"]));
    }

    [Fact]
    public void FindNearest_AllDead_ReturnsNull()
    {
        var tower = Tower(0, 0);
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 1, 0, hp: 0),
            Enemy(2, 2, 0, hp: -5),
        };

        var target = Targeting.FindNearest(tower, enemies);

        Assert.Null(target);
    }

    [Fact]
    public void FindNearest_EmptyList_ReturnsNull()
    {
        var tower = Tower(0, 0);
        var target = Targeting.FindNearest(tower, new List<Dictionary<string, object>>());
        Assert.Null(target);
    }

    [Fact]
    public void FindNearest_SingleEnemy_ReturnsThatEnemy()
    {
        var tower = Tower(0, 0);
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 100, 100, hp: 5),
        };

        var target = Targeting.FindNearest(tower, enemies);

        Assert.NotNull(target);
        Assert.Equal(1, Convert.ToInt32(target!["id"]));
    }

    [Fact]
    public void FindNearest_TiedDistance_ReturnsFirstInList()
    {
        var tower = Tower(5, 5);
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 6, 5, hp: 10), // dist = 1
            Enemy(2, 5, 6, hp: 10), // dist = 1
            Enemy(3, 4, 5, hp: 10), // dist = 1
        };

        var target = Targeting.FindNearest(tower, enemies);

        Assert.NotNull(target);
        Assert.Equal(1, Convert.ToInt32(target!["id"]));
    }

    // =========================================================================
    // FindStrongest/FindWeakest — edge cases
    // =========================================================================

    [Fact]
    public void FindStrongest_SingleEnemy_ReturnsThatEnemy()
    {
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 0, 0, hp: 1),
        };

        var target = Targeting.FindStrongest(enemies);

        Assert.Equal(1, Convert.ToInt32(target!["id"]));
    }

    [Fact]
    public void FindStrongest_TiedHp_ReturnsFirstInList()
    {
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 0, 0, hp: 20),
            Enemy(2, 0, 0, hp: 20),
        };

        var target = Targeting.FindStrongest(enemies);

        Assert.Equal(1, Convert.ToInt32(target!["id"]));
    }

    [Fact]
    public void FindWeakest_SingleEnemy_ReturnsThatEnemy()
    {
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 0, 0, hp: 99),
        };

        var target = Targeting.FindWeakest(enemies);

        Assert.Equal(1, Convert.ToInt32(target!["id"]));
    }

    [Fact]
    public void FindWeakest_TiedHp_ReturnsFirstInList()
    {
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 0, 0, hp: 5),
            Enemy(2, 0, 0, hp: 5),
        };

        var target = Targeting.FindWeakest(enemies);

        Assert.Equal(1, Convert.ToInt32(target!["id"]));
    }

    // =========================================================================
    // FindFastest — edge cases
    // =========================================================================

    [Fact]
    public void FindFastest_TiedSpeed_ReturnsFirstInList()
    {
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 0, 0, hp: 10, speed: 5),
            Enemy(2, 0, 0, hp: 10, speed: 5),
        };

        var target = Targeting.FindFastest(enemies);

        Assert.Equal(1, Convert.ToInt32(target!["id"]));
    }

    [Fact]
    public void FindFastest_ZeroSpeed_StillReturns()
    {
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 0, 0, hp: 10, speed: 0),
        };

        var target = Targeting.FindFastest(enemies);

        Assert.NotNull(target);
    }

    // =========================================================================
    // FindFirst / FindLast — edge cases
    // =========================================================================

    [Fact]
    public void FindFirst_EmptyList_ReturnsNull()
    {
        Assert.Null(Targeting.FindFirst(new List<Dictionary<string, object>>()));
    }

    [Fact]
    public void FindLast_EmptyList_ReturnsNull()
    {
        Assert.Null(Targeting.FindLast(new List<Dictionary<string, object>>()));
    }

    [Fact]
    public void FindFirst_SingleEnemy_ReturnsSame()
    {
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(42, 0, 0),
        };

        var first = Targeting.FindFirst(enemies);
        var last = Targeting.FindLast(enemies);

        Assert.Equal(42, Convert.ToInt32(first!["id"]));
        Assert.Equal(42, Convert.ToInt32(last!["id"]));
    }

    // =========================================================================
    // FindTarget — mode dispatch
    // =========================================================================

    [Fact]
    public void FindTarget_NullTargetMode_DefaultsToNearest()
    {
        var state = DefaultState.Create();
        var tower = new Dictionary<string, object>
        {
            ["pos_x"] = 0,
            ["pos_y"] = 0,
            // No "target_mode" key
        };
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 10, 0, alive: true),
            Enemy(2, 1, 0, alive: true),
        };

        var target = Targeting.FindTarget(state, tower, enemies);

        Assert.Equal(2, Convert.ToInt32(target!["id"]));
    }

    // =========================================================================
    // FindMultiTargets — edge cases
    // =========================================================================

    [Fact]
    public void FindMultiTargets_CountZero_ReturnsEmpty()
    {
        var state = DefaultState.Create();
        var tower = Tower(0, 0);
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 1, 0),
            Enemy(2, 2, 0),
        };

        var targets = Targeting.FindMultiTargets(state, tower, enemies, 0);

        Assert.Empty(targets);
    }

    [Fact]
    public void FindMultiTargets_OrderedByDistance()
    {
        var state = DefaultState.Create();
        var tower = Tower(0, 0);
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 10, 0),
            Enemy(2, 3, 0),
            Enemy(3, 1, 0),
        };

        var targets = Targeting.FindMultiTargets(state, tower, enemies, 3);

        Assert.Equal(3, Convert.ToInt32(targets[0]["id"])); // closest first
        Assert.Equal(2, Convert.ToInt32(targets[1]["id"]));
        Assert.Equal(1, Convert.ToInt32(targets[2]["id"]));
    }

    // =========================================================================
    // FindAoeTargets — boundary cases
    // =========================================================================

    [Fact]
    public void FindAoeTargets_ExactlyAtRadius_Included()
    {
        var center = new Dictionary<string, object>
        {
            ["pos_x"] = 5,
            ["pos_y"] = 5,
        };
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 8, 5, alive: true), // dist = 3
        };

        var targets = Targeting.FindAoeTargets(center, enemies, 3);

        Assert.Single(targets);
    }

    [Fact]
    public void FindAoeTargets_JustBeyondRadius_Excluded()
    {
        var center = new Dictionary<string, object>
        {
            ["pos_x"] = 5,
            ["pos_y"] = 5,
        };
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 9, 5, alive: true), // dist = 4
        };

        var targets = Targeting.FindAoeTargets(center, enemies, 3);

        Assert.Empty(targets);
    }

    [Fact]
    public void FindAoeTargets_RadiusZero_OnlySamePosition()
    {
        var center = new Dictionary<string, object>
        {
            ["pos_x"] = 5,
            ["pos_y"] = 5,
        };
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 5, 5, alive: true), // same position
            Enemy(2, 6, 5, alive: true), // dist = 1
        };

        var targets = Targeting.FindAoeTargets(center, enemies, 0);

        Assert.Single(targets);
        Assert.Equal(1, Convert.ToInt32(targets[0]["id"]));
    }

    [Fact]
    public void FindAoeTargets_SkipsDeadEnemies()
    {
        var center = new Dictionary<string, object>
        {
            ["pos_x"] = 5,
            ["pos_y"] = 5,
        };
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, 5, 5, alive: false),
            Enemy(2, 6, 5, alive: true),
        };

        var targets = Targeting.FindAoeTargets(center, enemies, 2);

        Assert.Single(targets);
        Assert.Equal(2, Convert.ToInt32(targets[0]["id"]));
    }

    [Fact]
    public void FindAoeTargets_EmptyEnemies_ReturnsEmpty()
    {
        var center = new Dictionary<string, object>
        {
            ["pos_x"] = 5,
            ["pos_y"] = 5,
        };

        var targets = Targeting.FindAoeTargets(
            center, new List<Dictionary<string, object>>(), 10);

        Assert.Empty(targets);
    }

    // =========================================================================
    // FindChainTargets — boundary cases
    // =========================================================================

    [Fact]
    public void FindChainTargets_ZeroMaxJumps_ReturnsOnlyFirst()
    {
        var first = Enemy(1, 0, 0);
        var enemies = new List<Dictionary<string, object>>
        {
            first,
            Enemy(2, 1, 0),
        };

        var chain = Targeting.FindChainTargets(first, enemies, maxJumps: 0, jumpRange: 10);

        Assert.Single(chain);
        Assert.Equal(1, Convert.ToInt32(chain[0]["id"]));
    }

    [Fact]
    public void FindChainTargets_ZeroJumpRange_ReturnsOnlyFirst()
    {
        var first = Enemy(1, 0, 0);
        var enemies = new List<Dictionary<string, object>>
        {
            first,
            Enemy(2, 1, 0),
        };

        var chain = Targeting.FindChainTargets(first, enemies, maxJumps: 5, jumpRange: 0);

        // jumpRange=0 means only enemies at distance 0 (same pos) would chain
        // but same enemy can't be reused, so only first
        Assert.Single(chain);
    }

    [Fact]
    public void FindChainTargets_LargeJumpRange_ChainsThroughAll()
    {
        var first = Enemy(1, 0, 0);
        var enemies = new List<Dictionary<string, object>>
        {
            first,
            Enemy(2, 10, 0),
            Enemy(3, 20, 0),
            Enemy(4, 30, 0),
        };

        var chain = Targeting.FindChainTargets(first, enemies, maxJumps: 10, jumpRange: 100);

        Assert.Equal(4, chain.Count);
    }

    [Fact]
    public void FindChainTargets_SkipsDeadInChain()
    {
        var first = Enemy(1, 0, 0);
        var enemies = new List<Dictionary<string, object>>
        {
            first,
            Enemy(2, 1, 0, alive: false), // dead, skip
            Enemy(3, 2, 0),
        };

        var chain = Targeting.FindChainTargets(first, enemies, maxJumps: 5, jumpRange: 5);

        // Should jump from 1 directly to 3, skipping dead 2
        Assert.Equal(2, chain.Count);
        Assert.Equal(1, Convert.ToInt32(chain[0]["id"]));
        Assert.Equal(3, Convert.ToInt32(chain[1]["id"]));
    }

    [Fact]
    public void FindChainTargets_DoesNotReuseEnemy()
    {
        var first = Enemy(1, 0, 0);
        var enemies = new List<Dictionary<string, object>>
        {
            first,
            Enemy(2, 1, 0),
        };

        var chain = Targeting.FindChainTargets(first, enemies, maxJumps: 10, jumpRange: 10);

        // Even with many jumps, only 2 enemies available
        Assert.Equal(2, chain.Count);
    }

    // =========================================================================
    // ManhattanDistance — edge cases
    // =========================================================================

    [Fact]
    public void ManhattanDistance_BothNegative_ReturnsCorrect()
    {
        var a = new Dictionary<string, object> { ["pos_x"] = -5, ["pos_y"] = -3 };
        var b = new Dictionary<string, object> { ["pos_x"] = -1, ["pos_y"] = -8 };

        Assert.Equal(9, Targeting.ManhattanDistance(a, b)); // |(-5)-(-1)| + |(-3)-(-8)| = 4+5
    }

    [Fact]
    public void ManhattanDistance_LargeCoordinates_ReturnsCorrect()
    {
        var a = new Dictionary<string, object> { ["pos_x"] = 1000, ["pos_y"] = 2000 };
        var b = new Dictionary<string, object> { ["pos_x"] = 0, ["pos_y"] = 0 };

        Assert.Equal(3000, Targeting.ManhattanDistance(a, b));
    }

    [Fact]
    public void ManhattanDistance_IsSymmetric()
    {
        var a = new Dictionary<string, object> { ["pos_x"] = 3, ["pos_y"] = 7 };
        var b = new Dictionary<string, object> { ["pos_x"] = 10, ["pos_y"] = 2 };

        Assert.Equal(
            Targeting.ManhattanDistance(a, b),
            Targeting.ManhattanDistance(b, a));
    }

    [Fact]
    public void ManhattanDistance_MissingKeys_DefaultsToZero()
    {
        var a = new Dictionary<string, object>(); // no pos_x or pos_y
        var b = new Dictionary<string, object> { ["pos_x"] = 5, ["pos_y"] = 3 };

        Assert.Equal(8, Targeting.ManhattanDistance(a, b)); // |0-5| + |0-3|
    }

    // =========================================================================
    // Helpers
    // =========================================================================

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
            ["pos_x"] = x,
            ["pos_y"] = y,
            ["hp"] = hp,
            ["speed"] = speed,
            ["alive"] = alive,
        };
    }

    private static Dictionary<string, object> Tower(int x, int y, string targetMode = "nearest")
    {
        return new Dictionary<string, object>
        {
            ["pos_x"] = x,
            ["pos_y"] = y,
            ["target_mode"] = targetMode,
        };
    }
}
