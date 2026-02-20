using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class TargetingModeTests
{
    private static Dictionary<string, object> MakeEnemy(int id, int x, int y, int hp, int speed = 1)
    {
        return new Dictionary<string, object>
        {
            ["id"] = id,
            ["x"] = x,
            ["y"] = y,
            ["hp"] = hp,
            ["max_hp"] = hp,
            ["speed"] = speed,
            ["alive"] = true,
        };
    }

    private static Dictionary<string, object> MakeTower(int x, int y, string targetMode = "nearest")
    {
        return new Dictionary<string, object>
        {
            ["x"] = x,
            ["y"] = y,
            ["target_mode"] = targetMode,
        };
    }

    // --- Default targeting mode ---

    [Fact]
    public void FindTarget_DefaultMode_IsNearest()
    {
        var state = new GameState();
        // Tower with no explicit target_mode falls back to "nearest"
        var tower = new Dictionary<string, object> { ["x"] = 0, ["y"] = 0 };
        var enemies = new List<Dictionary<string, object>>
        {
            MakeEnemy(1, 5, 5, 10),
            MakeEnemy(2, 1, 1, 10),
        };

        var target = Targeting.FindTarget(state, tower, enemies);
        Assert.NotNull(target);
        Assert.Equal(2, target!["id"]); // (1,1) is nearest to (0,0)
    }

    // --- Nearest mode ---

    [Fact]
    public void FindTarget_NearestMode_ReturnsClosestEnemy()
    {
        var state = new GameState();
        var tower = MakeTower(0, 0, "nearest");
        var enemies = new List<Dictionary<string, object>>
        {
            MakeEnemy(1, 10, 10, 5),
            MakeEnemy(2, 2, 3, 5),
            MakeEnemy(3, 8, 0, 5),
        };

        var target = Targeting.FindTarget(state, tower, enemies);
        Assert.NotNull(target);
        Assert.Equal(2, target!["id"]); // distance 5
    }

    // --- Strongest mode ---

    [Fact]
    public void FindTarget_StrongestMode_ReturnsHighestHp()
    {
        var state = new GameState();
        var tower = MakeTower(0, 0, "strongest");
        var enemies = new List<Dictionary<string, object>>
        {
            MakeEnemy(1, 1, 1, 5),
            MakeEnemy(2, 2, 2, 50),
            MakeEnemy(3, 3, 3, 20),
        };

        var target = Targeting.FindTarget(state, tower, enemies);
        Assert.NotNull(target);
        Assert.Equal(2, target!["id"]);
    }

    // --- Weakest mode ---

    [Fact]
    public void FindTarget_WeakestMode_ReturnsLowestHp()
    {
        var state = new GameState();
        var tower = MakeTower(0, 0, "weakest");
        var enemies = new List<Dictionary<string, object>>
        {
            MakeEnemy(1, 1, 1, 20),
            MakeEnemy(2, 2, 2, 3),
            MakeEnemy(3, 3, 3, 50),
        };

        var target = Targeting.FindTarget(state, tower, enemies);
        Assert.NotNull(target);
        Assert.Equal(2, target!["id"]);
    }

    // --- Fastest mode ---

    [Fact]
    public void FindTarget_FastestMode_ReturnsFastestEnemy()
    {
        var state = new GameState();
        var tower = MakeTower(0, 0, "fastest");
        var enemies = new List<Dictionary<string, object>>
        {
            MakeEnemy(1, 1, 1, 10, speed: 2),
            MakeEnemy(2, 2, 2, 10, speed: 8),
            MakeEnemy(3, 3, 3, 10, speed: 5),
        };

        var target = Targeting.FindTarget(state, tower, enemies);
        Assert.NotNull(target);
        Assert.Equal(2, target!["id"]);
    }

    // --- First / Last modes ---

    [Fact]
    public void FindTarget_FirstMode_ReturnsFirstInList()
    {
        var state = new GameState();
        var tower = MakeTower(0, 0, "first");
        var enemies = new List<Dictionary<string, object>>
        {
            MakeEnemy(10, 5, 5, 10),
            MakeEnemy(20, 1, 1, 10),
            MakeEnemy(30, 9, 9, 10),
        };

        var target = Targeting.FindTarget(state, tower, enemies);
        Assert.NotNull(target);
        Assert.Equal(10, target!["id"]);
    }

    [Fact]
    public void FindTarget_LastMode_ReturnsLastInList()
    {
        var state = new GameState();
        var tower = MakeTower(0, 0, "last");
        var enemies = new List<Dictionary<string, object>>
        {
            MakeEnemy(10, 5, 5, 10),
            MakeEnemy(20, 1, 1, 10),
            MakeEnemy(30, 9, 9, 10),
        };

        var target = Targeting.FindTarget(state, tower, enemies);
        Assert.NotNull(target);
        Assert.Equal(30, target!["id"]);
    }

    // --- Invalid mode defaults to nearest ---

    [Fact]
    public void FindTarget_InvalidMode_FallsBackToNearest()
    {
        var state = new GameState();
        var tower = MakeTower(0, 0, "bogus_mode");
        var enemies = new List<Dictionary<string, object>>
        {
            MakeEnemy(1, 10, 10, 10),
            MakeEnemy(2, 1, 0, 10),
        };

        var target = Targeting.FindTarget(state, tower, enemies);
        Assert.NotNull(target);
        Assert.Equal(2, target!["id"]); // nearest to (0,0)
    }

    // --- No enemies ---

    [Fact]
    public void FindTarget_NoEnemies_ReturnsNull()
    {
        var state = new GameState();
        var tower = MakeTower(0, 0);
        var enemies = new List<Dictionary<string, object>>();

        Assert.Null(Targeting.FindTarget(state, tower, enemies));
    }

    // --- Dead enemies filtered ---

    [Fact]
    public void FindTarget_SkipsDeadEnemies()
    {
        var state = new GameState();
        var tower = MakeTower(0, 0, "nearest");
        var enemies = new List<Dictionary<string, object>>
        {
            new()
            {
                ["id"] = 1, ["x"] = 1, ["y"] = 0, ["hp"] = 0,
                ["alive"] = false, ["speed"] = 1,
            },
            MakeEnemy(2, 5, 5, 10),
        };

        var target = Targeting.FindTarget(state, tower, enemies);
        Assert.NotNull(target);
        Assert.Equal(2, target!["id"]);
    }

    [Fact]
    public void FindTarget_AllDead_ReturnsNull()
    {
        var state = new GameState();
        var tower = MakeTower(0, 0);
        var enemies = new List<Dictionary<string, object>>
        {
            new()
            {
                ["id"] = 1, ["x"] = 1, ["y"] = 0, ["hp"] = 0,
                ["alive"] = false, ["speed"] = 1,
            },
        };

        Assert.Null(Targeting.FindTarget(state, tower, enemies));
    }

    // --- Multi-target selection ---

    [Fact]
    public void FindMultiTargets_ReturnsRequestedCount()
    {
        var state = new GameState();
        var tower = MakeTower(0, 0);
        var enemies = new List<Dictionary<string, object>>
        {
            MakeEnemy(1, 1, 1, 10),
            MakeEnemy(2, 2, 2, 10),
            MakeEnemy(3, 3, 3, 10),
        };

        var targets = Targeting.FindMultiTargets(state, tower, enemies, 2);
        Assert.Equal(2, targets.Count);
    }

    [Fact]
    public void FindMultiTargets_LessThanRequested_ReturnsAll()
    {
        var state = new GameState();
        var tower = MakeTower(0, 0);
        var enemies = new List<Dictionary<string, object>>
        {
            MakeEnemy(1, 1, 1, 10),
        };

        var targets = Targeting.FindMultiTargets(state, tower, enemies, 5);
        Assert.Single(targets);
    }

    // --- AoE targets ---

    [Fact]
    public void FindAoeTargets_ReturnsEnemiesWithinRadius()
    {
        var center = new Dictionary<string, object> { ["x"] = 5, ["y"] = 5 };
        var enemies = new List<Dictionary<string, object>>
        {
            MakeEnemy(1, 5, 6, 10),   // distance 1, in range
            MakeEnemy(2, 5, 5, 10),   // distance 0, in range
            MakeEnemy(3, 20, 20, 10), // distance 30, out of range
        };

        var targets = Targeting.FindAoeTargets(center, enemies, 3);
        Assert.Equal(2, targets.Count);
    }

    [Fact]
    public void FindAoeTargets_ExcludesDeadEnemies()
    {
        var center = new Dictionary<string, object> { ["x"] = 0, ["y"] = 0 };
        var enemies = new List<Dictionary<string, object>>
        {
            MakeEnemy(1, 1, 0, 10),
            new()
            {
                ["id"] = 2, ["x"] = 0, ["y"] = 1, ["hp"] = 0,
                ["alive"] = false, ["speed"] = 1,
            },
        };

        var targets = Targeting.FindAoeTargets(center, enemies, 5);
        Assert.Single(targets);
        Assert.Equal(1, targets[0]["id"]);
    }

    // --- Chain targets ---

    [Fact]
    public void FindChainTargets_ChainsToNearbyEnemies()
    {
        var first = MakeEnemy(1, 0, 0, 10);
        var enemies = new List<Dictionary<string, object>>
        {
            first,
            MakeEnemy(2, 1, 0, 10),
            MakeEnemy(3, 2, 0, 10),
            MakeEnemy(4, 100, 100, 10), // too far to chain
        };

        var chain = Targeting.FindChainTargets(first, enemies, 3, 3);
        Assert.Equal(3, chain.Count);
        Assert.Equal(1, chain[0]["id"]);
        Assert.Equal(2, chain[1]["id"]);
        Assert.Equal(3, chain[2]["id"]);
    }

    [Fact]
    public void FindChainTargets_StopsWhenNoEnemiesInRange()
    {
        var first = MakeEnemy(1, 0, 0, 10);
        var enemies = new List<Dictionary<string, object>>
        {
            first,
            MakeEnemy(2, 100, 100, 10), // too far
        };

        var chain = Targeting.FindChainTargets(first, enemies, 5, 2);
        Assert.Single(chain); // only the initial target
    }

    // --- Manhattan distance ---

    [Fact]
    public void ManhattanDistance_CalculatesCorrectly()
    {
        var a = new Dictionary<string, object> { ["x"] = 0, ["y"] = 0 };
        var b = new Dictionary<string, object> { ["x"] = 3, ["y"] = 4 };
        Assert.Equal(7, Targeting.ManhattanDistance(a, b));
    }

    [Fact]
    public void ManhattanDistance_SamePoint_ReturnsZero()
    {
        var a = new Dictionary<string, object> { ["x"] = 5, ["y"] = 5 };
        Assert.Equal(0, Targeting.ManhattanDistance(a, a));
    }

    // --- All valid targeting mode strings ---

    [Theory]
    [InlineData("nearest")]
    [InlineData("strongest")]
    [InlineData("weakest")]
    [InlineData("fastest")]
    [InlineData("first")]
    [InlineData("last")]
    public void FindTarget_AllValidModes_ReturnNonNull(string mode)
    {
        var state = new GameState();
        var tower = MakeTower(5, 5, mode);
        var enemies = new List<Dictionary<string, object>>
        {
            MakeEnemy(1, 1, 1, 10, speed: 5),
            MakeEnemy(2, 3, 3, 20, speed: 2),
            MakeEnemy(3, 8, 8, 5, speed: 10),
        };

        var target = Targeting.FindTarget(state, tower, enemies);
        Assert.NotNull(target);
    }

    // --- AutoTargetMode enum ---

    [Fact]
    public void AutoTargetMode_HasExpectedValues()
    {
        var modes = Enum.GetValues<AutoTowerTypes.AutoTargetMode>();
        Assert.Equal(9, modes.Length);
        Assert.Contains(AutoTowerTypes.AutoTargetMode.Nearest, modes);
        Assert.Contains(AutoTowerTypes.AutoTargetMode.HighestHp, modes);
        Assert.Contains(AutoTowerTypes.AutoTargetMode.LowestHp, modes);
        Assert.Contains(AutoTowerTypes.AutoTargetMode.Fastest, modes);
        Assert.Contains(AutoTowerTypes.AutoTargetMode.Cluster, modes);
        Assert.Contains(AutoTowerTypes.AutoTargetMode.Chain, modes);
        Assert.Contains(AutoTowerTypes.AutoTargetMode.Zone, modes);
        Assert.Contains(AutoTowerTypes.AutoTargetMode.Contact, modes);
        Assert.Contains(AutoTowerTypes.AutoTargetMode.Smart, modes);
    }

    [Fact]
    public void AutoTargetMode_ParsesFromString()
    {
        Assert.True(Enum.TryParse<AutoTowerTypes.AutoTargetMode>("Nearest", out var mode));
        Assert.Equal(AutoTowerTypes.AutoTargetMode.Nearest, mode);
    }

    [Fact]
    public void AutoTargetMode_InvalidString_FailsParse()
    {
        Assert.False(Enum.TryParse<AutoTowerTypes.AutoTargetMode>("BogusMode", out _));
    }

    // --- Setting targeting mode persists in tower dict ---

    [Fact]
    public void TowerTargetMode_SetMode_PersistsInState()
    {
        var tower = MakeTower(0, 0, "nearest");
        Assert.Equal("nearest", tower["target_mode"]);

        tower["target_mode"] = "strongest";
        Assert.Equal("strongest", tower["target_mode"]);

        // Verify the new mode is used by FindTarget
        var state = new GameState();
        var enemies = new List<Dictionary<string, object>>
        {
            MakeEnemy(1, 1, 1, 5),
            MakeEnemy(2, 10, 10, 100),
        };

        var target = Targeting.FindTarget(state, tower, enemies);
        Assert.NotNull(target);
        Assert.Equal(2, target!["id"]); // strongest has 100 hp
    }

    [Fact]
    public void TowerTargetMode_MissingKey_DefaultsToNearest()
    {
        var tower = new Dictionary<string, object> { ["x"] = 0, ["y"] = 0 };
        // No "target_mode" key at all
        Assert.False(tower.ContainsKey("target_mode"));

        var state = new GameState();
        var enemies = new List<Dictionary<string, object>>
        {
            MakeEnemy(1, 10, 10, 100), // far, strong
            MakeEnemy(2, 1, 0, 5),     // near, weak
        };

        var target = Targeting.FindTarget(state, tower, enemies);
        Assert.NotNull(target);
        Assert.Equal(2, target!["id"]); // nearest wins as default
    }
}
