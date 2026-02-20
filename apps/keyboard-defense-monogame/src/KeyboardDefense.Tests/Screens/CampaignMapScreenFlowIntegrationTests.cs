using System.Collections.Generic;
using KeyboardDefense.Game.Screens;
using KeyboardDefense.Game.Services;

namespace KeyboardDefense.Tests.Screens;

public class CampaignMapScreenFlowIntegrationTests
{
    [Fact]
    public void KeyboardInspectionAndLaunchFlow_RequiresConfirmAndPreservesKeyboardMode()
    {
        var flow = new CampaignMapLaunchFlow(confirmWindowSeconds: 2f);

        int? cycleDelta = CampaignMapInputPolicy.ResolveCycleDelta(
            tabPressed: true,
            shiftDown: false,
            qPressed: false,
            ePressed: false);
        bool mouseMode = CampaignMapInputPolicy.ResolveMouseInspectMode(
            currentMouseInspectMode: true,
            mouseMoved: false,
            clickStartedOnHoveredNode: false,
            keyboardNavigationRequested: true);

        bool firstLaunch = flow.RequestLaunch("ember-bridge");
        flow.Update(0.5f);
        bool secondLaunch = flow.RequestLaunch("ember-bridge");

        Assert.Equal(1, cycleDelta);
        Assert.False(mouseMode);
        Assert.False(firstLaunch);
        Assert.True(secondLaunch);
    }

    [Fact]
    public void SummaryReturnContextAndOnboardingFlow_WorkTogether()
    {
        CampaignMapReturnContextService.Clear();

        var outcome = new CampaignProgressionService.CampaignOutcome(
            IsCampaignRun: true,
            IsVictory: true,
            NodeAlreadyCompleted: false,
            NodeCompletedThisRun: true,
            RewardAwarded: true,
            RewardGold: 45);
        CampaignMapReturnContextService.SetFromSummaryOutcome(
            "ember-bridge",
            "Ember Bridge",
            outcome);
        var context = CampaignMapReturnContextService.Consume();

        var completedAchievements = new HashSet<string>();
        bool onboardingVisible = CampaignMapOnboardingPolicy.ShouldShow(completedAchievements);
        completedAchievements.Add(CampaignMapOnboardingPolicy.CampaignMapOnboardingDoneFlag);
        bool onboardingAfterDone = CampaignMapOnboardingPolicy.ShouldShow(completedAchievements);

        Assert.True(context.HasValue);
        Assert.Equal("ember-bridge", context.Value.NodeId);
        Assert.Contains("Ember Bridge", context.Value.Message);
        Assert.True(onboardingVisible);
        Assert.False(onboardingAfterDone);
    }
}
