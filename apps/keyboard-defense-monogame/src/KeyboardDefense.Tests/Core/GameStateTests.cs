using KeyboardDefense.Core.State;
using KeyboardDefense.Core;
using KeyboardDefense.Core.Balance;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.Data;

namespace KeyboardDefense.Tests.Core;

public class GameStateTests
{
    [Fact]
    public void GameState_DefaultInit_HasCorrectDefaults()
    {
        var state = new GameState();

        Assert.Equal(1, state.Day);
        Assert.Equal("day", state.Phase);
        Assert.Equal(3, state.Ap);
        Assert.Equal(10, state.Hp);
        Assert.Equal(0, state.Threat);
        Assert.Equal(32, state.MapW);
        Assert.Equal(32, state.MapH);
        Assert.Equal(new GridPoint(16, 16), state.BasePos);
        Assert.Equal(state.BasePos, state.CursorPos);
        Assert.Equal("full_alpha", state.LessonId);
        Assert.Equal(1, state.EnemyNextId);
    }

    [Fact]
    public void GameState_Resources_InitializedToZero()
    {
        var state = new GameState();

        foreach (var key in GameState.ResourceKeys)
        {
            Assert.Equal(0, state.Resources[key]);
        }
    }

    [Fact]
    public void GameState_Buildings_InitializedToZero()
    {
        var state = new GameState();

        foreach (var key in GameState.BuildingKeys)
        {
            Assert.Equal(0, state.Buildings[key]);
        }
    }

    [Fact]
    public void GameState_Terrain_CorrectSize()
    {
        var state = new GameState();
        Assert.Equal(state.MapW * state.MapH, state.Terrain.Count);
    }

    [Fact]
    public void GameState_BasePos_IsDiscovered()
    {
        var state = new GameState();
        int baseIndex = state.Index(state.BasePos.X, state.BasePos.Y);
        Assert.Contains(baseIndex, state.Discovered);
    }

    [Fact]
    public void GameState_Index_CalculatesCorrectly()
    {
        var state = new GameState();
        Assert.Equal(0, state.Index(0, 0));
        Assert.Equal(state.MapW, state.Index(0, 1)); // Second row
        Assert.Equal(1, state.Index(1, 0)); // Second column
        Assert.Equal(state.MapW + 5, state.Index(5, 1));
    }
}

public class GridPointTests
{
    [Fact]
    public void GridPoint_Equality()
    {
        var a = new GridPoint(3, 5);
        var b = new GridPoint(3, 5);
        var c = new GridPoint(4, 5);

        Assert.Equal(a, b);
        Assert.NotEqual(a, c);
        Assert.True(a == b);
        Assert.True(a != c);
    }

    [Fact]
    public void GridPoint_Arithmetic()
    {
        var a = new GridPoint(3, 5);
        var b = new GridPoint(1, 2);

        Assert.Equal(new GridPoint(4, 7), a + b);
        Assert.Equal(new GridPoint(2, 3), a - b);
        Assert.Equal(new GridPoint(6, 10), a * 2);
    }

    [Fact]
    public void GridPoint_ManhattanDistance()
    {
        var a = new GridPoint(0, 0);
        var b = new GridPoint(3, 4);
        Assert.Equal(7, a.ManhattanDistance(b));
    }
}

public class SimRngTests
{
    [Fact]
    public void SimRng_SeedDeterminism()
    {
        var state1 = new GameState();
        var state2 = new GameState();

        SimRng.SeedState(state1, "test_seed");
        SimRng.SeedState(state2, "test_seed");

        var results1 = new int[10];
        var results2 = new int[10];

        for (int i = 0; i < 10; i++)
        {
            results1[i] = SimRng.RollRange(state1, 0, 100);
            results2[i] = SimRng.RollRange(state2, 0, 100);
        }

        Assert.Equal(results1, results2);
    }

    [Fact]
    public void SimRng_DifferentSeeds_DifferentResults()
    {
        var state1 = new GameState();
        var state2 = new GameState();

        SimRng.SeedState(state1, "seed_a");
        SimRng.SeedState(state2, "seed_b");

        int val1 = SimRng.RollRange(state1, 0, 1000000);
        int val2 = SimRng.RollRange(state2, 0, 1000000);

        Assert.NotEqual(val1, val2);
    }

    [Fact]
    public void SimRng_RollRange_WithinBounds()
    {
        var state = new GameState();
        SimRng.SeedState(state, "bounds_test");

        for (int i = 0; i < 100; i++)
        {
            int val = SimRng.RollRange(state, 5, 15);
            Assert.InRange(val, 5, 15);
        }
    }

    [Fact]
    public void SimRng_Choose_ReturnsFromList()
    {
        var state = new GameState();
        SimRng.SeedState(state, "choose_test");

        var items = new List<string> { "a", "b", "c" };
        for (int i = 0; i < 20; i++)
        {
            var result = SimRng.Choose(state, items);
            Assert.NotNull(result);
            Assert.Contains(result, items);
        }
    }

    [Fact]
    public void SimRng_Choose_EmptyList_ReturnsNull()
    {
        var state = new GameState();
        SimRng.SeedState(state, "empty");

        var result = SimRng.Choose(state, new List<string>());
        Assert.Null(result);
    }
}

public class SimBalanceTests
{
    [Fact]
    public void CalculateEnemyHp_ScalesWithDay()
    {
        int hp1 = SimBalance.CalculateEnemyHp(1, 0);
        int hp10 = SimBalance.CalculateEnemyHp(10, 0);
        Assert.True(hp10 > hp1);
    }

    [Fact]
    public void CalculateWaveSize_AtLeastOne()
    {
        int size = SimBalance.CalculateWaveSize(0, 0);
        Assert.True(size >= 1);
    }

    [Fact]
    public void CalculateTypingDamage_BaseDamage()
    {
        int damage = SimBalance.CalculateTypingDamage(1, 30, 0.5, 0);
        Assert.Equal(1, damage);
    }

    [Fact]
    public void CalculateTypingDamage_WpmBonus()
    {
        int damage = SimBalance.CalculateTypingDamage(1, 60, 0.5, 0);
        Assert.True(damage > 1);
    }

    [Fact]
    public void CalculateTypingDamage_AccuracyBonus()
    {
        int damage = SimBalance.CalculateTypingDamage(1, 30, 0.95, 0);
        Assert.True(damage > 1);
    }

    [Fact]
    public void CalculateTowerDamage_ScalesWithLevel()
    {
        int dmg1 = SimBalance.CalculateTowerDamage(10, 1);
        int dmg5 = SimBalance.CalculateTowerDamage(10, 5);
        Assert.True(dmg5 > dmg1);
    }

    [Fact]
    public void GetDifficultyFactor_Day1_IsOne()
    {
        Assert.Equal(1.0, SimBalance.GetDifficultyFactor(1));
    }

    [Fact]
    public void CheckMilestone_Day1_OnTrack()
    {
        var (onTrack, issues) = SimBalance.CheckMilestone(1, 1, 0, 0);
        Assert.True(onTrack);
        Assert.Empty(issues);
    }

    [Fact]
    public void CheckMilestone_Day1_Behind()
    {
        var (onTrack, issues) = SimBalance.CheckMilestone(1, 0, 0, 0);
        Assert.False(onTrack);
        Assert.NotEmpty(issues);
    }
}

public class SimIntentsTests
{
    [Fact]
    public void Make_CreatesIntentWithKind()
    {
        var intent = SimIntents.Make("build");
        Assert.Equal("build", intent["kind"]);
    }

    [Fact]
    public void Make_MergesData()
    {
        var intent = SimIntents.Make("build", new Dictionary<string, object>
        {
            ["type"] = "tower",
            ["x"] = 5,
            ["y"] = 10,
        });

        Assert.Equal("build", intent["kind"]);
        Assert.Equal("tower", intent["type"]);
        Assert.Equal(5, intent["x"]);
        Assert.Equal(10, intent["y"]);
    }

    [Fact]
    public void HelpLines_ReturnsContent()
    {
        var lines = SimIntents.HelpLines();
        Assert.NotEmpty(lines);
        Assert.Contains(lines, l => l.Contains("help"));
    }
}

public class SaveManagerTests
{
    [Fact]
    public void RoundTrip_PreservesState()
    {
        var state = new GameState();
        state.Day = 5;
        state.Phase = "night";
        state.Hp = 7;
        state.Gold = 250;
        state.Resources["wood"] = 30;
        state.Resources["stone"] = 15;

        string json = SaveManager.StateToJson(state);
        var (ok, loaded, error) = SaveManager.StateFromJson(json);

        Assert.True(ok);
        Assert.NotNull(loaded);
        Assert.Null(error);
        Assert.Equal(5, loaded!.Day);
        Assert.Equal("night", loaded.Phase);
        Assert.Equal(7, loaded.Hp);
        Assert.Equal(250, loaded.Gold);
    }

    [Fact]
    public void StateFromJson_InvalidJson_ReturnsError()
    {
        var (ok, state, error) = SaveManager.StateFromJson("not valid json");
        Assert.False(ok);
        Assert.Null(state);
        Assert.NotNull(error);
    }
}
