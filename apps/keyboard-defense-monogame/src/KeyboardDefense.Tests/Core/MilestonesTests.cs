using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class MilestonesCoreTests
{
    [Fact]
    public void Registry_HasFourteenEntries()
    {
        Assert.Equal(14, Milestones.Registry.Count);
    }

    [Fact]
    public void GetMilestone_KnownId_ReturnsDefinition()
    {
        var def = Milestones.GetMilestone("first_blood");

        Assert.NotNull(def);
        Assert.Equal("First Blood", def!.Name);
        Assert.Equal("Defeat your first enemy.", def.Description);
        Assert.Equal("combat", def.Category);
    }

    [Fact]
    public void GetMilestone_UnknownId_ReturnsNull()
    {
        var def = Milestones.GetMilestone("not_a_real_milestone");

        Assert.Null(def);
    }

    [Fact]
    public void Registry_ContainsAllExpectedCategories()
    {
        var categories = new HashSet<string>(StringComparer.Ordinal);
        foreach (var def in Milestones.Registry.Values)
            categories.Add(def.Category);

        Assert.Equal(5, categories.Count);
        Assert.Contains("combat", categories);
        Assert.Contains("typing", categories);
        Assert.Contains("survival", categories);
        Assert.Contains("exploration", categories);
        Assert.Contains("economy", categories);
    }

    [Fact]
    public void CheckNewMilestones_BaselineState_EarnsNothing()
    {
        var state = CreateBaselineState();

        var earned = Milestones.CheckNewMilestones(state);

        Assert.Empty(earned);
        Assert.Empty(state.Milestones);
    }

    [Fact]
    public void CheckNewMilestones_FirstBloodCondition_EarnsMilestone()
    {
        var state = CreateBaselineState();
        state.EnemiesDefeated = 1;

        var earned = Milestones.CheckNewMilestones(state);

        Assert.Contains("first_blood", earned);
        Assert.Contains("first_blood", state.Milestones);
    }

    [Fact]
    public void CheckNewMilestones_Combo5Boundary_EarnsOnlyCombo5()
    {
        var state = CreateBaselineState();
        state.MaxComboEver = 5;

        var earned = Milestones.CheckNewMilestones(state);

        Assert.Contains("combo_5", earned);
        Assert.DoesNotContain("combo_20", earned);
        Assert.DoesNotContain("combo_50", earned);
    }

    [Fact]
    public void CheckNewMilestones_Combo20Boundary_EarnsCombo5AndCombo20()
    {
        var state = CreateBaselineState();
        state.MaxComboEver = 20;

        var earned = Milestones.CheckNewMilestones(state);

        Assert.Contains("combo_5", earned);
        Assert.Contains("combo_20", earned);
        Assert.DoesNotContain("combo_50", earned);
    }

    [Fact]
    public void CheckNewMilestones_Combo50Boundary_EarnsAllComboMilestones()
    {
        var state = CreateBaselineState();
        state.MaxComboEver = 50;

        var earned = Milestones.CheckNewMilestones(state);

        Assert.Contains("combo_5", earned);
        Assert.Contains("combo_20", earned);
        Assert.Contains("combo_50", earned);
    }

    [Fact]
    public void CheckNewMilestones_Day7Boundary_EarnsOnlyDay7()
    {
        var state = CreateBaselineState();
        state.Day = 7;

        var earned = Milestones.CheckNewMilestones(state);

        Assert.Contains("day_7", earned);
        Assert.DoesNotContain("day_14", earned);
        Assert.DoesNotContain("day_30", earned);
    }

    [Fact]
    public void CheckNewMilestones_Day14Boundary_EarnsDay7AndDay14()
    {
        var state = CreateBaselineState();
        state.Day = 14;

        var earned = Milestones.CheckNewMilestones(state);

        Assert.Contains("day_7", earned);
        Assert.Contains("day_14", earned);
        Assert.DoesNotContain("day_30", earned);
    }

    [Fact]
    public void CheckNewMilestones_Day30Boundary_EarnsAllDayMilestones()
    {
        var state = CreateBaselineState();
        state.Day = 30;

        var earned = Milestones.CheckNewMilestones(state);

        Assert.Contains("day_7", earned);
        Assert.Contains("day_14", earned);
        Assert.Contains("day_30", earned);
    }

    [Fact]
    public void CheckNewMilestones_Gold100Boundary_EarnsGoldMilestone()
    {
        var state = CreateBaselineState();
        state.Gold = 100;

        var earned = Milestones.CheckNewMilestones(state);

        Assert.Contains("gold_100", earned);
        Assert.Contains("gold_100", state.Milestones);
    }

    [Fact]
    public void CheckNewMilestones_Build10Boundary_EarnsBuildMilestone()
    {
        var state = CreateBaselineState();
        for (int i = 0; i < 10; i++)
            state.Structures[i] = "tower";

        var earned = Milestones.CheckNewMilestones(state);

        Assert.Contains("build_10", earned);
        Assert.Contains("build_10", state.Milestones);
    }

    [Fact]
    public void CheckNewMilestones_AlreadyEarnedMilestone_IsNotReAdded()
    {
        var state = CreateBaselineState();
        state.EnemiesDefeated = 1;
        state.Milestones.Add("first_blood");

        var earned = Milestones.CheckNewMilestones(state);

        Assert.DoesNotContain("first_blood", earned);
        Assert.Single(state.Milestones);
        Assert.Contains("first_blood", state.Milestones);
    }

    [Fact]
    public void CheckNewMilestones_MultipleEligibleMilestones_AreReturnedInSingleCall()
    {
        var state = CreateBaselineState();
        state.EnemiesDefeated = 1;
        state.MaxComboEver = 20;
        state.Day = 14;
        state.Gold = 100;
        for (int i = 0; i < 10; i++)
            state.Structures[i] = "tower";
        state.BossesDefeated.UnionWith(new[] { "b1", "b2", "b3", "b4" });
        ConfigureExploration(state, mapW: 4, mapH: 4, discoveredCount: 3);

        var earned = Milestones.CheckNewMilestones(state);
        var earnedSet = new HashSet<string>(earned, StringComparer.Ordinal);

        Assert.Equal(8, earnedSet.Count);
        Assert.Contains("first_blood", earnedSet);
        Assert.Contains("combo_5", earnedSet);
        Assert.Contains("combo_20", earnedSet);
        Assert.Contains("day_7", earnedSet);
        Assert.Contains("day_14", earnedSet);
        Assert.Contains("build_10", earnedSet);
        Assert.Contains("gold_100", earnedSet);
        Assert.Contains("all_bosses", earnedSet);
    }

    [Fact]
    public void CheckNewMilestones_Explore25Boundary_EarnsOnlyExplore25()
    {
        var state = CreateBaselineState();
        ConfigureExploration(state, mapW: 4, mapH: 4, discoveredCount: 4);

        var earned = Milestones.CheckNewMilestones(state);

        Assert.Contains("explore_25", earned);
        Assert.DoesNotContain("explore_50", earned);
        Assert.DoesNotContain("explore_100", earned);
    }

    [Fact]
    public void CheckNewMilestones_Explore50Boundary_EarnsExplore25AndExplore50()
    {
        var state = CreateBaselineState();
        ConfigureExploration(state, mapW: 4, mapH: 4, discoveredCount: 8);

        var earned = Milestones.CheckNewMilestones(state);

        Assert.Contains("explore_25", earned);
        Assert.Contains("explore_50", earned);
        Assert.DoesNotContain("explore_100", earned);
    }

    [Fact]
    public void CheckNewMilestones_Explore100Boundary_EarnsAllExplorationMilestones()
    {
        var state = CreateBaselineState();
        ConfigureExploration(state, mapW: 4, mapH: 4, discoveredCount: 16);

        var earned = Milestones.CheckNewMilestones(state);

        Assert.Contains("explore_25", earned);
        Assert.Contains("explore_50", earned);
        Assert.Contains("explore_100", earned);
    }

    [Fact]
    public void CheckNewMilestones_ExploreWithZeroMapSize_EarnsNoExplorationMilestones()
    {
        var state = CreateBaselineState();
        ConfigureExploration(state, mapW: 0, mapH: 0, discoveredCount: 100);

        var earned = Milestones.CheckNewMilestones(state);

        Assert.DoesNotContain("explore_25", earned);
        Assert.DoesNotContain("explore_50", earned);
        Assert.DoesNotContain("explore_100", earned);
    }

    [Fact]
    public void CheckNewMilestones_AllBosses_RequiresFourDistinctBosses()
    {
        var state = CreateBaselineState();
        state.BossesDefeated.UnionWith(new[] { "b1", "b2", "b3" });

        var before = Milestones.CheckNewMilestones(state);
        Assert.DoesNotContain("all_bosses", before);

        state.BossesDefeated.Add("b4");
        var after = Milestones.CheckNewMilestones(state);
        Assert.Contains("all_bosses", after);
    }

    [Fact]
    public void CheckNewMilestones_PerfectNight_NeverEarns()
    {
        var state = CreateBaselineState();
        state.EnemiesDefeated = 999;
        state.MaxComboEver = 999;
        state.Day = 999;
        state.Gold = 999;
        for (int i = 0; i < 20; i++)
            state.Structures[i] = "tower";
        state.BossesDefeated.UnionWith(new[] { "b1", "b2", "b3", "b4" });
        ConfigureExploration(state, mapW: 4, mapH: 4, discoveredCount: 16);

        var earned = Milestones.CheckNewMilestones(state);

        Assert.DoesNotContain("perfect_night", earned);
        Assert.DoesNotContain("perfect_night", state.Milestones);
    }

    private static GameState CreateBaselineState()
    {
        var state = DefaultState.Create();
        state.EnemiesDefeated = 0;
        state.MaxComboEver = 0;
        state.Day = 1;
        state.Gold = 0;
        state.Structures.Clear();
        state.BossesDefeated.Clear();
        state.Milestones.Clear();
        state.Discovered.Clear();
        return state;
    }

    private static void ConfigureExploration(GameState state, int mapW, int mapH, int discoveredCount)
    {
        state.MapW = mapW;
        state.MapH = mapH;
        state.Discovered.Clear();
        for (int i = 0; i < discoveredCount; i++)
            state.Discovered.Add(i);
    }
}
