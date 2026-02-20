using System.Collections.Generic;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;

namespace KeyboardDefense.Tests.Progression;

public class VictoryScreenTests
{
    [Fact]
    public void CheckVictory_Defeat_WhenHpZero()
    {
        var state = DefaultState.Create("test", true);
        state.Hp = 0;
        Assert.Equal("defeat", Victory.CheckVictory(state));
    }

    [Fact]
    public void CheckVictory_None_WhenAlive()
    {
        var state = DefaultState.Create("test", true);
        state.Hp = 20;
        Assert.Equal("none", Victory.CheckVictory(state));
    }

    [Fact]
    public void CheckVictory_Victory_WhenBossesDefeated()
    {
        var state = DefaultState.Create("test", true);
        state.BossesDefeated.UnionWith(new[] { "boss1", "boss2", "boss3", "boss4" });
        Assert.Equal("victory", Victory.CheckVictory(state));
    }

    [Fact]
    public void CheckVictory_Victory_WhenDayAndQuests()
    {
        var state = DefaultState.Create("test", true);
        state.Day = 30;
        state.CompletedQuests.UnionWith(new[] { "q1", "q2", "q3", "q4", "q5" });
        Assert.Equal("victory", Victory.CheckVictory(state));
    }

    [Fact]
    public void CalculateScore_IncreasesWithFactors()
    {
        var state = DefaultState.Create("test", true);
        int baseScore = Victory.CalculateScore(state);

        // Adding a day increases score
        state.Day += 1;
        int afterDay = Victory.CalculateScore(state);
        Assert.True(afterDay > baseScore);

        // Adding gold increases score
        state.Gold += 50;
        int afterGold = Victory.CalculateScore(state);
        Assert.True(afterGold > afterDay);

        // Completing a quest increases score
        state.CompletedQuests.Add("q1");
        int afterQuest = Victory.CalculateScore(state);
        Assert.True(afterQuest > afterGold);

        // Defeating a boss increases score
        state.BossesDefeated.Add("boss1");
        int afterBoss = Victory.CalculateScore(state);
        Assert.True(afterBoss > afterQuest);
    }

    [Fact]
    public void GetGrade_ReturnsCorrectGrades()
    {
        Assert.Equal("S", Victory.GetGrade(20000));
        Assert.Equal("S", Victory.GetGrade(25000));
        Assert.Equal("A", Victory.GetGrade(15000));
        Assert.Equal("B", Victory.GetGrade(10000));
        Assert.Equal("C", Victory.GetGrade(5000));
        Assert.Equal("D", Victory.GetGrade(1000));
    }

    [Fact]
    public void GetVictoryReport_IncludesScore_OnVictory()
    {
        var state = DefaultState.Create("test", true);
        state.BossesDefeated.UnionWith(new[] { "b1", "b2", "b3", "b4" });
        state.Day = 15;

        var report = Victory.GetVictoryReport(state);
        Assert.Equal("victory", report["result"]);
        Assert.True(report.ContainsKey("score"));
        Assert.True(report.ContainsKey("grade"));
    }

    [Fact]
    public void GetVictoryReport_IncludesSurvivedDays_OnDefeat()
    {
        var state = DefaultState.Create("test", true);
        state.Hp = 0;
        state.Day = 7;

        var report = Victory.GetVictoryReport(state);
        Assert.Equal("defeat", report["result"]);
        Assert.Equal(7, report["survived_days"]);
    }

    [Fact]
    public void Milestones_CheckNewMilestones_DetectsFirstBlood()
    {
        var state = DefaultState.Create("test", true);
        state.EnemiesDefeated = 1;

        var newMilestones = Milestones.CheckNewMilestones(state);
        Assert.Contains("first_blood", newMilestones);
        Assert.Contains("first_blood", state.Milestones);
    }

    [Fact]
    public void Milestones_DoesNotDuplicate()
    {
        var state = DefaultState.Create("test", true);
        state.EnemiesDefeated = 1;

        Milestones.CheckNewMilestones(state);
        var second = Milestones.CheckNewMilestones(state);
        Assert.DoesNotContain("first_blood", second);
    }

    [Fact]
    public void Milestones_DetectsCombo()
    {
        var state = DefaultState.Create("test", true);
        state.MaxComboEver = 5;

        var newMilestones = Milestones.CheckNewMilestones(state);
        Assert.Contains("combo_5", newMilestones);
    }

    [Fact]
    public void Milestones_DetectsDay7()
    {
        var state = DefaultState.Create("test", true);
        state.Day = 7;

        var newMilestones = Milestones.CheckNewMilestones(state);
        Assert.Contains("day_7", newMilestones);
    }

    [Fact]
    public void Milestones_DetectsGold100()
    {
        var state = DefaultState.Create("test", true);
        state.Gold = 100;

        var newMilestones = Milestones.CheckNewMilestones(state);
        Assert.Contains("gold_100", newMilestones);
    }

    [Fact]
    public void Milestones_GetMilestone_ReturnsDef()
    {
        var def = Milestones.GetMilestone("first_blood");
        Assert.NotNull(def);
        Assert.Equal("First Blood", def!.Name);
        Assert.Equal("combat", def.Category);
    }

    [Fact]
    public void Milestones_GetMilestone_ReturnsNull_ForUnknown()
    {
        var def = Milestones.GetMilestone("nonexistent");
        Assert.Null(def);
    }

    [Fact]
    public void Milestones_AllBosses()
    {
        var state = DefaultState.Create("test", true);
        state.BossesDefeated.UnionWith(new[] { "b1", "b2", "b3", "b4" });

        var newMilestones = Milestones.CheckNewMilestones(state);
        Assert.Contains("all_bosses", newMilestones);
    }

    [Fact]
    public void TypingMetrics_GetWpm_ReturnsZero_WhenNoInput()
    {
        var state = DefaultState.Create("test", true);
        TypingMetrics.InitBattleMetrics(state);
        double wpm = TypingMetrics.GetWpm(state);
        Assert.Equal(0, wpm);
    }

    [Fact]
    public void TypingMetrics_GetAccuracy_PerfectByDefault()
    {
        var state = DefaultState.Create("test", true);
        TypingMetrics.InitBattleMetrics(state);
        double acc = TypingMetrics.GetAccuracy(state);
        Assert.Equal(1.0, acc);
    }

    [Fact]
    public void TypingMetrics_RecordError_ReducesAccuracy()
    {
        var state = DefaultState.Create("test", true);
        TypingMetrics.InitBattleMetrics(state);
        TypingMetrics.RecordCharTyped(state, 'a');
        TypingMetrics.RecordCharTyped(state, 'b');
        TypingMetrics.RecordError(state);

        double acc = TypingMetrics.GetAccuracy(state);
        Assert.True(acc < 1.0);
    }

    [Fact]
    public void TypingMetrics_ComboMultiplier_ScalesWithCombo()
    {
        Assert.Equal(1.0, TypingMetrics.GetComboMultiplier(0));
        Assert.Equal(1.0, TypingMetrics.GetComboMultiplier(2));
        Assert.Equal(1.1, TypingMetrics.GetComboMultiplier(3));
        Assert.Equal(1.25, TypingMetrics.GetComboMultiplier(5));
        Assert.Equal(2.5, TypingMetrics.GetComboMultiplier(50));
    }
}
