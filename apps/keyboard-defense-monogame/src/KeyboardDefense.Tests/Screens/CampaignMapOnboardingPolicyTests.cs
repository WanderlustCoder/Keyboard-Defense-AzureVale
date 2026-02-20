using System.Collections.Generic;
using KeyboardDefense.Game.Screens;

namespace KeyboardDefense.Tests.Screens;

public class CampaignMapOnboardingPolicyTests
{
    [Fact]
    public void ShouldShow_ReturnsTrue_WhenCompletionFlagMissing()
    {
        var completed = new HashSet<string> { "battle_tutorial_done" };
        bool shouldShow = CampaignMapOnboardingPolicy.ShouldShow(completed);
        Assert.True(shouldShow);
    }

    [Fact]
    public void ShouldShow_ReturnsFalse_WhenCompletionFlagPresent()
    {
        var completed = new HashSet<string> { CampaignMapOnboardingPolicy.CampaignMapOnboardingDoneFlag };
        bool shouldShow = CampaignMapOnboardingPolicy.ShouldShow(completed);
        Assert.False(shouldShow);
    }

    [Theory]
    [InlineData(0, 3, 1)]
    [InlineData(1, 3, 2)]
    [InlineData(2, 3, 3)]
    [InlineData(3, 3, 3)]
    [InlineData(0, 0, 0)]
    public void AdvanceStep_ClampsToCompletionBoundary(int currentStep, int totalSteps, int expected)
    {
        int next = CampaignMapOnboardingPolicy.AdvanceStep(currentStep, totalSteps);
        Assert.Equal(expected, next);
    }

    [Theory]
    [InlineData(0, 3, false)]
    [InlineData(2, 3, false)]
    [InlineData(3, 3, true)]
    [InlineData(1, 0, true)]
    public void IsComplete_UsesStepBoundary(int step, int totalSteps, bool expected)
    {
        bool complete = CampaignMapOnboardingPolicy.IsComplete(step, totalSteps);
        Assert.Equal(expected, complete);
    }
}
