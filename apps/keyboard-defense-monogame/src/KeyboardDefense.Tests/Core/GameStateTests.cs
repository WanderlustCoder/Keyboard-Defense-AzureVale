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
// SimRngTests moved to dedicated SimRngTests.cs

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
// SaveManagerTests moved to dedicated SaveManagerTests.cs
