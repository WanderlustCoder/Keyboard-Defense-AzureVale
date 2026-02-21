using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Data;

namespace KeyboardDefense.Tests.Core;

public class SkillsCoreTests
{
    [Fact]
    public void Registry_HasSevenEntries()
    {
        Assert.Equal(7, Skills.Registry.Count);
    }

    [Fact]
    public void Registry_HasExpectedCategoryAndTierForEachSkill()
    {
        var expected = new Dictionary<string, (string Category, int Tier)>
        {
            ["quick_fingers"] = ("combat", 1),
            ["iron_walls"] = ("defense", 1),
            ["efficient_harvest"] = ("economy", 1),
            ["critical_strike"] = ("combat", 2),
            ["fortified_walls"] = ("defense", 2),
            ["trade_mastery"] = ("economy", 2),
            ["word_mastery"] = ("combat", 3),
        };

        foreach (var (skillId, expectedValues) in expected)
        {
            Assert.True(Skills.Registry.TryGetValue(skillId, out var skill), $"Missing skill id '{skillId}' in registry.");
            Assert.Equal(expectedValues.Category, skill!.Category);
            Assert.Equal(expectedValues.Tier, skill.Tier);
        }
    }

    [Fact]
    public void Registry_HasExpectedPrerequisitesForEachSkill()
    {
        var expectedPrerequisites = new Dictionary<string, string?>
        {
            ["quick_fingers"] = null,
            ["iron_walls"] = null,
            ["efficient_harvest"] = null,
            ["critical_strike"] = "quick_fingers",
            ["fortified_walls"] = "iron_walls",
            ["trade_mastery"] = "efficient_harvest",
            ["word_mastery"] = "critical_strike",
        };

        foreach (var (skillId, prerequisite) in expectedPrerequisites)
        {
            var skill = Assert.IsType<SkillDef>(Skills.GetSkill(skillId));
            Assert.Equal(prerequisite, skill.Prerequisite);
        }
    }

    [Fact]
    public void GetSkill_KnownId_ReturnsDefinition()
    {
        var skill = Skills.GetSkill("critical_strike");

        Assert.NotNull(skill);
        Assert.Equal("Critical Strike", skill!.Name);
        Assert.Equal("combat", skill.Category);
        Assert.Equal(2, skill.Tier);
        Assert.Equal("quick_fingers", skill.Prerequisite);
        Assert.Equal(0.05, skill.Bonuses["crit_chance"], 3);
        Assert.Equal(2.0, skill.Bonuses["crit_mult"], 3);
    }

    [Fact]
    public void GetSkill_UnknownId_ReturnsNull()
    {
        Assert.Null(Skills.GetSkill("not_a_real_skill"));
    }

    [Fact]
    public void CanUnlock_MissingSkill_ReturnsFalse()
    {
        var state = CreateState(skillPoints: 10);

        Assert.False(Skills.CanUnlock(state, "missing_skill"));
    }

    [Fact]
    public void CanUnlock_AlreadyUnlocked_ReturnsFalse()
    {
        var state = CreateState(skillPoints: 10);
        state.UnlockedSkills.Add("quick_fingers");

        Assert.False(Skills.CanUnlock(state, "quick_fingers"));
    }

    [Fact]
    public void CanUnlock_PrerequisiteNotMet_ReturnsFalse()
    {
        var state = CreateState(skillPoints: 3);

        Assert.False(Skills.CanUnlock(state, "critical_strike"));
    }

    [Fact]
    public void CanUnlock_NotEnoughSkillPoints_ReturnsFalse()
    {
        var state = CreateState(skillPoints: 1);
        state.UnlockedSkills.Add("quick_fingers");

        Assert.False(Skills.CanUnlock(state, "critical_strike"));
    }

    [Fact]
    public void CanUnlock_ValidTierOneSkill_ReturnsTrue()
    {
        var state = CreateState(skillPoints: 1);

        Assert.True(Skills.CanUnlock(state, "quick_fingers"));
    }

    [Fact]
    public void CanUnlock_ValidTierTwoSkillWithPrerequisite_ReturnsTrue()
    {
        var state = CreateState(skillPoints: 2);
        state.UnlockedSkills.Add("quick_fingers");

        Assert.True(Skills.CanUnlock(state, "critical_strike"));
    }

    [Fact]
    public void UnlockSkill_ValidUnlock_DeductsPointsAndAddsSkillAndReturnsSuccess()
    {
        var state = CreateState(skillPoints: 3);

        var result = Skills.UnlockSkill(state, "quick_fingers");

        Assert.True((bool)result["ok"]);
        Assert.Equal("Unlocked Quick Fingers!", result["message"]);
        Assert.Equal(2, state.SkillPoints);
        Assert.Contains("quick_fingers", state.UnlockedSkills);
    }

    [Fact]
    public void UnlockSkill_InvalidUnlock_ReturnsErrorAndLeavesStateUnchanged()
    {
        var state = CreateState(skillPoints: 0);

        var result = Skills.UnlockSkill(state, "quick_fingers");

        Assert.False((bool)result["ok"]);
        Assert.Equal("Cannot unlock skill.", result["error"]);
        Assert.Equal(0, state.SkillPoints);
        Assert.Empty(state.UnlockedSkills);
    }

    [Fact]
    public void GetBonusValue_NoUnlockedSkills_ReturnsDefaultValue()
    {
        var state = CreateState();

        var result = Skills.GetBonusValue(state, "damage_mult", 1.0);

        Assert.Equal(1.0, result, 3);
    }

    [Fact]
    public void GetBonusValue_MultiplierKey_MultipliesDefaultValue()
    {
        var state = CreateState();
        state.UnlockedSkills.Add("quick_fingers");

        var result = Skills.GetBonusValue(state, "damage_mult", 1.0);

        Assert.Equal(1.1, result, 3);
    }

    [Fact]
    public void GetBonusValue_AdditiveKey_AddsToDefaultValue()
    {
        var state = CreateState();
        state.UnlockedSkills.Add("critical_strike");

        var result = Skills.GetBonusValue(state, "crit_chance", 0.10);

        Assert.Equal(0.15, result, 3);
    }

    [Fact]
    public void GetBonusValue_MultipleSkillsWithSameMultiplierKey_StackMultiplicatively()
    {
        var state = CreateState();
        const string skillA = "__test_damage_mult_a";
        const string skillB = "__test_damage_mult_b";
        Skills.Registry[skillA] = new SkillDef("Test A", "Multiplier test skill A.", "combat", 1, new() { ["damage_mult"] = 1.1 }, null);
        Skills.Registry[skillB] = new SkillDef("Test B", "Multiplier test skill B.", "combat", 1, new() { ["damage_mult"] = 1.2 }, null);

        try
        {
            state.UnlockedSkills.Add(skillA);
            state.UnlockedSkills.Add(skillB);

            var result = Skills.GetBonusValue(state, "damage_mult", 1.0);

            Assert.Equal(1.32, result, 3);
        }
        finally
        {
            Skills.Registry.Remove(skillA);
            Skills.Registry.Remove(skillB);
        }
    }

    [Fact]
    public void GetAvailableSkills_NoSkillPoints_ReturnsEmpty()
    {
        var state = CreateState(skillPoints: 0);

        var available = Skills.GetAvailableSkills(state);

        Assert.Empty(available);
    }

    [Fact]
    public void GetAvailableSkills_OnlyReturnsUnlockableSkillsForCurrentState()
    {
        var state = CreateState(skillPoints: 2);
        state.UnlockedSkills.Add("quick_fingers");

        var available = Skills.GetAvailableSkills(state);

        Assert.Contains("critical_strike", available);
        Assert.Contains("iron_walls", available);
        Assert.Contains("efficient_harvest", available);
        Assert.DoesNotContain("quick_fingers", available);
        Assert.DoesNotContain("fortified_walls", available);
        Assert.DoesNotContain("trade_mastery", available);
        Assert.DoesNotContain("word_mastery", available);
    }

    [Fact]
    public void PrerequisiteChain_CannotUnlockTierTwoUntilTierOneThenCanUnlock()
    {
        var state = CreateState(skillPoints: 3);

        Assert.False(Skills.CanUnlock(state, "critical_strike"));
        var unlockTierOne = Skills.UnlockSkill(state, "quick_fingers");
        Assert.True((bool)unlockTierOne["ok"]);
        Assert.True(Skills.CanUnlock(state, "critical_strike"));
    }

    private static GameState CreateState(int skillPoints = 0)
    {
        var state = DefaultState.Create(Guid.NewGuid().ToString("N"));
        state.UnlockedSkills.Clear();
        state.SkillPoints = skillPoints;
        return state;
    }
}

public class QuestsTests
{
    [Fact]
    public void Registry_HasEntries()
    {
        Assert.NotEmpty(Quests.Registry);
    }

    [Fact]
    public void GetQuest_KnownQuest_ReturnsDef()
    {
        var quest = Quests.GetQuest("first_tower");
        Assert.NotNull(quest);
        Assert.Equal("First Defense", quest!.Name);
    }

    [Fact]
    public void IsComplete_InitialState_ReturnsFalse()
    {
        var state = new GameState();
        Assert.False(Quests.IsComplete(state, "first_tower"));
    }

    [Fact]
    public void GetActiveQuests_InitialState_ReturnsQuests()
    {
        var state = new GameState();
        var active = Quests.GetActiveQuests(state);
        Assert.NotEmpty(active);
    }
}

public class TutorialDataTests
{
    [Fact]
    public void BattleSteps_HasSevenSteps()
    {
        Assert.Equal(7, TutorialData.BattleSteps.Count);
    }

    [Fact]
    public void BattleSteps_FirstStep_HasNoTrigger()
    {
        var first = TutorialData.BattleSteps[0];
        Assert.Null(first.Trigger);
        Assert.Equal("Welcome", first.Title);
        Assert.Equal("Elder Lyra", first.Speaker);
    }

    [Fact]
    public void BattleSteps_TypingTarget_HasTrigger()
    {
        var step = TutorialData.BattleSteps[1];
        Assert.Equal("first_word_typed", step.Trigger);
    }

    [Fact]
    public void BattleSteps_AllHaveSpeaker()
    {
        foreach (var step in TutorialData.BattleSteps)
        {
            Assert.False(string.IsNullOrEmpty(step.Speaker));
            Assert.False(string.IsNullOrEmpty(step.Line1));
        }
    }

    [Fact]
    public void OnboardingSteps_HasSixSteps()
    {
        Assert.Equal(6, TutorialData.OnboardingSteps.Count);
    }

    [Fact]
    public void OnboardingSteps_AllHaveCompletionFlags()
    {
        foreach (var step in TutorialData.OnboardingSteps)
        {
            Assert.NotEmpty(step.CompletionFlags);
            Assert.False(string.IsNullOrEmpty(step.Id));
            Assert.False(string.IsNullOrEmpty(step.Title));
        }
    }

    [Fact]
    public void OnboardingSteps_WelcomeStep_RequiresUsedHelp()
    {
        var welcome = TutorialData.OnboardingSteps[0];
        Assert.Equal("welcome_focus", welcome.Id);
        Assert.Contains("used_help", welcome.CompletionFlags);
    }

    [Fact]
    public void OnboardingSteps_LastStep_RequiresAcknowledge()
    {
        var last = TutorialData.OnboardingSteps[^1];
        Assert.Equal("wrap_up", last.Id);
        Assert.Contains("acknowledged", last.CompletionFlags);
    }
}

public class GameSpeedTests
{
    [Fact]
    public void SpeedMultiplier_DefaultIsOne()
    {
        var state = new GameState();
        Assert.Equal(1.0f, state.SpeedMultiplier);
    }

    [Fact]
    public void SpeedMultiplier_CanBeSet()
    {
        var state = new GameState();
        state.SpeedMultiplier = 1.5f;
        Assert.Equal(1.5f, state.SpeedMultiplier);
    }
}

public class ResearchTests
{
    [Fact]
    public void Registry_HasEntries()
    {
        Assert.NotEmpty(ResearchData.Registry);
    }

    [Fact]
    public void GetResearch_KnownId_ReturnsDef()
    {
        var research = ResearchData.GetResearch("improved_walls");
        Assert.NotNull(research);
        Assert.Equal("Improved Walls", research!.Name);
    }

    [Fact]
    public void StartResearch_EmptyState_Succeeds()
    {
        var state = new GameState();
        state.Gold = 1000;
        bool started = ResearchData.StartResearch(state, "improved_walls");
        Assert.True(started);
        Assert.Equal("improved_walls", state.ActiveResearch);
    }

    [Fact]
    public void StartResearch_AlreadyResearching_Fails()
    {
        var state = new GameState();
        state.Gold = 1000;
        state.ActiveResearch = "something_else";
        bool started = ResearchData.StartResearch(state, "improved_walls");
        Assert.False(started);
    }

    [Fact]
    public void GetAvailableResearch_InitialState_ReturnsOptions()
    {
        var state = new GameState();
        var available = ResearchData.GetAvailableResearch(state);
        Assert.NotEmpty(available);
    }
}
