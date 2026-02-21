using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class VictoryCoreTests
{
    [Fact]
    public void CheckVictory_DayThirtyWithoutQuestsOrBosses_ReturnsNone()
    {
        var state = CreateState();
        state.Day = 30;

        var result = Victory.CheckVictory(state);

        Assert.Equal("none", result);
    }

    [Fact]
    public void CheckVictory_DayThirtyWithFourQuestsWithoutBosses_ReturnsNone()
    {
        var state = CreateState();
        state.Day = 30;
        AddQuests(state, 4);

        var result = Victory.CheckVictory(state);

        Assert.Equal("none", result);
    }

    [Fact]
    public void CheckVictory_DayThirtyWithFiveQuests_ReturnsVictory()
    {
        var state = CreateState();
        state.Day = 30;
        AddQuests(state, 5);

        var result = Victory.CheckVictory(state);

        Assert.Equal("victory", result);
    }

    [Fact]
    public void CheckVictory_FourBossesDefeatedOnEarlyDay_ReturnsVictory()
    {
        var state = CreateState();
        state.Day = 1;
        AddBosses(state, 4);

        var result = Victory.CheckVictory(state);

        Assert.Equal("victory", result);
    }

    [Fact]
    public void CheckVictory_BelowAllThresholds_ReturnsNone()
    {
        var state = CreateState();
        state.Day = 29;
        AddQuests(state, 4);
        AddBosses(state, 3);

        var result = Victory.CheckVictory(state);

        Assert.Equal("none", result);
    }

    [Fact]
    public void CheckVictory_HpZero_ReturnsDefeat()
    {
        var state = CreateState();
        state.Hp = 0;

        var result = Victory.CheckVictory(state);

        Assert.Equal("defeat", result);
    }

    [Fact]
    public void CheckVictory_HpNegative_ReturnsDefeat()
    {
        var state = CreateState();
        state.Hp = -1;

        var result = Victory.CheckVictory(state);

        Assert.Equal("defeat", result);
    }

    [Fact]
    public void CheckVictory_HpPositive_DoesNotReturnDefeat()
    {
        var state = CreateState();
        state.Hp = 1;

        var result = Victory.CheckVictory(state);

        Assert.NotEqual("defeat", result);
    }

    [Fact]
    public void CalculateScore_UsesAllComponents()
    {
        var state = CreateState();
        state.Day = 12;
        state.Gold = 345;
        AddQuests(state, 3);
        AddBosses(state, 2);
        state.Discovered.UnionWith(new[] { 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26 });
        state.Structures[0] = "wall";
        state.Structures[1] = "tower";
        state.Structures[2] = "farm";
        state.Structures[3] = "market";

        var score = Victory.CalculateScore(state);

        Assert.Equal(5760, score);
    }

    [Fact]
    public void CalculateScore_WithZeroedState_ReturnsZero()
    {
        var state = CreateState();

        var score = Victory.CalculateScore(state);

        Assert.Equal(0, score);
    }

    [Fact]
    public void CalculateScore_IncreasesWithEachComponent()
    {
        var baseline = Victory.CalculateScore(CreateState());

        var withDay = ScoreWith(state => state.Day = 1);
        var withGold = ScoreWith(state => state.Gold = 1);
        var withQuest = ScoreWith(state => state.CompletedQuests.Add("quest_1"));
        var withBoss = ScoreWith(state => state.BossesDefeated.Add("boss_1"));
        var withDiscovered = ScoreWith(state => state.Discovered.Add(1));
        var withStructure = ScoreWith(state => state.Structures[1] = "tower");

        Assert.True(withDay > baseline);
        Assert.True(withGold > baseline);
        Assert.True(withQuest > baseline);
        Assert.True(withBoss > baseline);
        Assert.True(withDiscovered > baseline);
        Assert.True(withStructure > baseline);
    }

    [Fact]
    public void GetGrade_At10000_ReturnsB()
    {
        Assert.Equal("B", Victory.GetGrade(10000));
    }

    [Fact]
    public void GetGrade_At9999_ReturnsC()
    {
        Assert.Equal("C", Victory.GetGrade(9999));
    }

    [Fact]
    public void GetGrade_At7000_ReturnsC()
    {
        Assert.Equal("C", Victory.GetGrade(7000));
    }

    [Fact]
    public void GetGrade_At6999_ReturnsC()
    {
        Assert.Equal("C", Victory.GetGrade(6999));
    }

    [Fact]
    public void GetGrade_At4000_ReturnsD()
    {
        Assert.Equal("D", Victory.GetGrade(4000));
    }

    [Fact]
    public void GetGrade_At3999_ReturnsD()
    {
        Assert.Equal("D", Victory.GetGrade(3999));
    }

    [Fact]
    public void GetGrade_At2000_ReturnsD()
    {
        Assert.Equal("D", Victory.GetGrade(2000));
    }

    [Fact]
    public void GetGrade_At1999_ReturnsD()
    {
        Assert.Equal("D", Victory.GetGrade(1999));
    }

    [Fact]
    public void GetGrade_At0_ReturnsD()
    {
        Assert.Equal("D", Victory.GetGrade(0));
    }

    private static GameState CreateState()
    {
        var state = DefaultState.Create();
        state.Hp = 10;
        state.Day = 0;
        state.Gold = 0;
        state.CompletedQuests.Clear();
        state.BossesDefeated.Clear();
        state.Discovered.Clear();
        state.Structures.Clear();
        return state;
    }

    private static int ScoreWith(Action<GameState> mutator)
    {
        var state = CreateState();
        mutator(state);
        return Victory.CalculateScore(state);
    }

    private static void AddQuests(GameState state, int count)
    {
        for (int i = 0; i < count; i++)
            state.CompletedQuests.Add($"quest_{i}");
    }

    private static void AddBosses(GameState state, int count)
    {
        for (int i = 0; i < count; i++)
            state.BossesDefeated.Add($"boss_{i}");
    }
}
