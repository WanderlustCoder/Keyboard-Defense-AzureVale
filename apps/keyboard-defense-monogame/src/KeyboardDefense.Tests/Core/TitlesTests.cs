using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class TitlesCoreTests
{
    [Fact]
    public void Registry_HasTenEntries()
    {
        Assert.Equal(10, Titles.Registry.Count);
    }

    [Fact]
    public void Registry_ContainsExpectedTitleIds()
    {
        var expectedIds = new HashSet<string>(StringComparer.Ordinal)
        {
            "novice",
            "defender",
            "veteran",
            "legend",
            "wordsmith",
            "speedster",
            "perfectionist",
            "explorer",
            "champion",
            "architect",
        };

        Assert.Equal(expectedIds.Count, Titles.Registry.Count);
        foreach (var id in expectedIds)
            Assert.Contains(id, Titles.Registry.Keys);
    }

    [Fact]
    public void GetTitle_Novice_ReturnsExpectedDefinition()
    {
        var title = Titles.GetTitle("novice");

        Assert.NotNull(title);
        Assert.Equal("Novice", title!.Name);
        Assert.Equal("Starting title.", title.Description);
        Assert.Null(title.RequiredMilestone);
    }

    [Fact]
    public void GetTitle_Defender_ReturnsExpectedDefinition()
    {
        var title = Titles.GetTitle("defender");

        Assert.NotNull(title);
        Assert.Equal("Defender", title!.Name);
        Assert.Equal("Survived 7 days.", title.Description);
        Assert.Equal("day_7", title.RequiredMilestone);
    }

    [Fact]
    public void GetTitle_UnknownId_ReturnsNull()
    {
        var title = Titles.GetTitle("not_a_real_title");

        Assert.Null(title);
    }

    [Fact]
    public void IsValidTitle_KnownTitles_ReturnsTrue()
    {
        Assert.True(Titles.IsValidTitle("novice"));
        Assert.True(Titles.IsValidTitle("champion"));
    }

    [Fact]
    public void IsValidTitle_UnknownTitle_ReturnsFalse()
    {
        Assert.False(Titles.IsValidTitle("missing_title"));
    }

    [Fact]
    public void IsTitleUnlocked_Novice_AlwaysUnlockedWithoutMilestone()
    {
        var state = CreateState();

        Assert.True(Titles.IsTitleUnlocked(state, "novice"));
    }

    [Fact]
    public void IsTitleUnlocked_Defender_WithoutDay7Milestone_ReturnsFalse()
    {
        var state = CreateState();

        Assert.False(Titles.IsTitleUnlocked(state, "defender"));
    }

    [Fact]
    public void IsTitleUnlocked_Defender_WithDay7Milestone_ReturnsTrue()
    {
        var state = CreateState();
        state.Milestones.Add("day_7");

        Assert.True(Titles.IsTitleUnlocked(state, "defender"));
    }

    [Fact]
    public void IsTitleUnlocked_UnknownTitle_ReturnsFalse()
    {
        var state = CreateState();
        state.Milestones.Add("day_7");

        Assert.False(Titles.IsTitleUnlocked(state, "does_not_exist"));
    }

    [Fact]
    public void GetUnlockedTitles_FreshState_ReturnsOnlyNovice()
    {
        var state = CreateState();

        var unlocked = Titles.GetUnlockedTitles(state);

        Assert.Single(unlocked);
        Assert.Equal("novice", unlocked[0]);
    }

    [Fact]
    public void GetUnlockedTitles_WithMilestones_IncludesOnlyMatchingTitles()
    {
        var state = CreateState();
        state.Milestones.UnionWith(new[] { "day_7", "wpm_80", "explore_50" });

        var unlocked = Titles.GetUnlockedTitles(state);

        Assert.Equal(4, unlocked.Count);
        Assert.Contains("novice", unlocked);
        Assert.Contains("defender", unlocked);
        Assert.Contains("speedster", unlocked);
        Assert.Contains("explorer", unlocked);
        Assert.DoesNotContain("veteran", unlocked);
        Assert.DoesNotContain("legend", unlocked);
        Assert.DoesNotContain("wordsmith", unlocked);
    }

    [Fact]
    public void GetUnlockedTitles_AllMilestonesPresent_ReturnsAllTitles()
    {
        var state = CreateState();
        state.Milestones.UnionWith(new[]
        {
            "day_7",
            "day_14",
            "day_30",
            "type_500",
            "wpm_80",
            "perfect_night",
            "explore_50",
            "all_bosses",
            "build_15",
        });

        var unlocked = Titles.GetUnlockedTitles(state);

        Assert.Equal(Titles.Registry.Count, unlocked.Count);
        foreach (var titleId in Titles.Registry.Keys)
            Assert.Contains(titleId, unlocked);
    }

    [Fact]
    public void EquipTitle_UnlockedTitle_ReturnsTrueAndSetsActiveTitle()
    {
        var state = CreateState();
        state.Milestones.Add("day_7");

        var equipped = Titles.EquipTitle(state, "defender");

        Assert.True(equipped);
        Assert.Equal("defender", state.ActiveTitle);
    }

    [Fact]
    public void EquipTitle_LockedTitle_ReturnsFalseAndDoesNotChangeActiveTitle()
    {
        var state = CreateState();
        state.ActiveTitle = "novice";

        var equipped = Titles.EquipTitle(state, "legend");

        Assert.False(equipped);
        Assert.Equal("novice", state.ActiveTitle);
    }

    [Fact]
    public void GetDisplayTitle_EmptyActiveTitle_ReturnsNovice()
    {
        var state = CreateState();
        state.ActiveTitle = string.Empty;

        var display = Titles.GetDisplayTitle(state);

        Assert.Equal("Novice", display);
    }

    [Fact]
    public void GetDisplayTitle_ValidActiveTitle_ReturnsTitleName()
    {
        var state = CreateState();
        state.ActiveTitle = "champion";

        var display = Titles.GetDisplayTitle(state);

        Assert.Equal("Champion", display);
    }

    [Fact]
    public void GetDisplayTitle_InvalidActiveTitle_ReturnsNovice()
    {
        var state = CreateState();
        state.ActiveTitle = "unknown_title";

        var display = Titles.GetDisplayTitle(state);

        Assert.Equal("Novice", display);
    }

    private static GameState CreateState()
    {
        var state = DefaultState.Create("titles_test_seed");
        state.Milestones.Clear();
        state.ActiveTitle = string.Empty;
        return state;
    }
}
