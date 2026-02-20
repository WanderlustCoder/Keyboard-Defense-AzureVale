using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Data;

namespace KeyboardDefense.Tests.Core;

public class SkillsTests
{
    [Fact]
    public void Registry_HasEntries()
    {
        Assert.NotEmpty(Skills.Registry);
    }

    [Fact]
    public void GetSkill_KnownSkill_ReturnsDef()
    {
        var skill = Skills.GetSkill("quick_fingers");
        Assert.NotNull(skill);
        Assert.Equal("Quick Fingers", skill!.Name);
    }

    [Fact]
    public void CanUnlock_WithEnoughPoints_ReturnsTrue()
    {
        var state = new GameState();
        state.SkillPoints = 10;
        var available = Skills.GetAvailableSkills(state);
        if (available.Count > 0)
            Assert.True(Skills.CanUnlock(state, available[0]));
    }

    [Fact]
    public void UnlockSkill_AddsToUnlocked()
    {
        var state = new GameState();
        state.SkillPoints = 10;
        var available = Skills.GetAvailableSkills(state);
        if (available.Count > 0)
        {
            var result = Skills.UnlockSkill(state, available[0]);
            Assert.Contains(available[0], state.UnlockedSkills);
        }
    }

    [Fact]
    public void UnlockSkill_AlreadyUnlocked_Fails()
    {
        var state = new GameState();
        state.SkillPoints = 20;
        var available = Skills.GetAvailableSkills(state);
        if (available.Count > 0)
        {
            Skills.UnlockSkill(state, available[0]);
            var result = Skills.UnlockSkill(state, available[0]);
            // Should return ok=false for already unlocked skill
            Assert.False((bool)result["ok"]);
        }
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
