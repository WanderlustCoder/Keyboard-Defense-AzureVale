using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Data;

namespace KeyboardDefense.Tests.Core;

public class TutorialDataTests
{
    [Fact]
    public void BattleSteps_LoadsSevenSteps()
    {
        Assert.Equal(7, TutorialData.BattleSteps.Count);
    }

    [Fact]
    public void BattleSteps_FollowsExpectedNarrativeOrder()
    {
        var titles = TutorialData.BattleSteps.Select(step => step.Title).ToArray();

        Assert.Equal(
            new[]
            {
                "Welcome",
                "Typing Target",
                "Threat Meter",
                "Castle Health",
                "Combos & Buffs",
                "Victory Hint",
                "Tutorial Complete",
            },
            titles);
    }

    [Fact]
    public void BattleSteps_AllTextFieldsArePopulated()
    {
        foreach (var step in TutorialData.BattleSteps)
        {
            Assert.False(string.IsNullOrWhiteSpace(step.Title));
            Assert.False(string.IsNullOrWhiteSpace(step.Speaker));
            Assert.False(string.IsNullOrWhiteSpace(step.Line1));
            Assert.False(string.IsNullOrWhiteSpace(step.Line2));
        }
    }

    [Fact]
    public void BattleSteps_TriggersFollowExpectedProgressionAndFormat()
    {
        var triggers = TutorialData.BattleSteps.Select(step => step.Trigger).ToArray();

        Assert.Equal(
            new string?[]
            {
                null,
                "first_word_typed",
                "threat_shown",
                "castle_damaged",
                "combo_achieved",
                "near_victory",
                null,
            },
            triggers);

        var nonNullTriggers = triggers.Where(trigger => trigger is not null).Select(trigger => trigger!).ToList();
        Assert.Equal(nonNullTriggers.Count, nonNullTriggers.Distinct().Count());

        foreach (var trigger in nonNullTriggers)
            AssertSnakeCaseIdentifier(trigger);
    }

    [Fact]
    public void OnboardingSteps_LoadsSixSteps()
    {
        Assert.Equal(6, TutorialData.OnboardingSteps.Count);
    }

    [Fact]
    public void OnboardingSteps_FollowsExpectedStepOrder()
    {
        var ids = TutorialData.OnboardingSteps.Select(step => step.Id).ToArray();

        Assert.Equal(
            new[]
            {
                "welcome_focus",
                "day_actions",
                "end_day",
                "night_typing",
                "reach_dawn",
                "wrap_up",
            },
            ids);
    }

    [Fact]
    public void OnboardingSteps_AllTextAndCompletionFlagsArePopulated()
    {
        foreach (var step in TutorialData.OnboardingSteps)
        {
            Assert.False(string.IsNullOrWhiteSpace(step.Id));
            Assert.False(string.IsNullOrWhiteSpace(step.Title));
            Assert.False(string.IsNullOrWhiteSpace(step.Description));
            Assert.False(string.IsNullOrWhiteSpace(step.Hint));
            Assert.NotEmpty(step.CompletionFlags);
            Assert.All(step.CompletionFlags, flag => Assert.False(string.IsNullOrWhiteSpace(flag)));
        }
    }

    [Fact]
    public void OnboardingSteps_CompletionCriteriaMatchExpectedFlagsAndFormat()
    {
        var expectedFlagsById = new Dictionary<string, string[]>
        {
            ["welcome_focus"] = new[] { "used_help" },
            ["day_actions"] = new[] { "did_gather", "did_build" },
            ["end_day"] = new[] { "entered_night" },
            ["night_typing"] = new[] { "hit_enemy" },
            ["reach_dawn"] = new[] { "reached_dawn" },
            ["wrap_up"] = new[] { "acknowledged" },
        };

        var allFlags = new List<string>();
        foreach (var step in TutorialData.OnboardingSteps)
        {
            Assert.True(expectedFlagsById.TryGetValue(step.Id, out var expectedFlags), $"Unexpected onboarding step id '{step.Id}'.");
            Assert.Equal(expectedFlags!, step.CompletionFlags);

            foreach (var flag in step.CompletionFlags)
            {
                AssertSnakeCaseIdentifier(flag);
                allFlags.Add(flag);
            }
        }

        Assert.Equal(allFlags.Count, allFlags.Distinct().Count());
    }

    private static void AssertSnakeCaseIdentifier(string value)
    {
        Assert.False(string.IsNullOrWhiteSpace(value));
        var segments = ParseSnakeCaseIdentifier(value);
        Assert.NotEmpty(segments);
        Assert.Equal(value, string.Join('_', segments));

        foreach (var segment in segments)
            foreach (char c in segment)
                Assert.True(char.IsLower(c) || char.IsDigit(c), $"Unexpected character '{c}' in segment '{segment}' from identifier '{value}'.");
    }

    private static string[] ParseSnakeCaseIdentifier(string value)
    {
        Assert.False(value.StartsWith('_'));
        Assert.False(value.EndsWith('_'));
        Assert.DoesNotContain("__", value);
        return value.Split('_');
    }
}
