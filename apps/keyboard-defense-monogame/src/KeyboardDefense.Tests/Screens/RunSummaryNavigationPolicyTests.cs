using KeyboardDefense.Game.Screens;
using KeyboardDefense.Game.Services;

namespace KeyboardDefense.Tests.Screens;

public class RunSummaryNavigationPolicyTests
{
    [Theory]
    [InlineData(true, true)]
    [InlineData(false, false)]
    public void ShouldReturnToCampaignMap_MatchesConfiguredFlag(bool configured, bool expected)
    {
        Assert.Equal(expected, RunSummaryNavigationPolicy.ShouldReturnToCampaignMap(configured));
    }

    [Fact]
    public void PublishReturnContextIfNeeded_PublishesWhenReturningToCampaignMap()
    {
        CampaignMapReturnContextService.Clear();
        var outcome = new CampaignProgressionService.CampaignOutcome(
            IsCampaignRun: true,
            IsVictory: true,
            NodeAlreadyCompleted: false,
            NodeCompletedThisRun: true,
            RewardAwarded: true,
            RewardGold: 55);

        RunSummaryNavigationPolicy.PublishReturnContextIfNeeded(
            returnToCampaignMapOnSummary: true,
            campaignNodeId: "ember-bridge",
            nodeName: "Ember Bridge",
            outcome: outcome);

        var context = CampaignMapReturnContextService.Consume();
        Assert.True(context.HasValue);
        Assert.Equal("ember-bridge", context.Value.NodeId);
        Assert.Contains("Ember Bridge", context.Value.Message);
    }

    [Fact]
    public void PublishReturnContextIfNeeded_DoesNotPublishWhenReturningToMainMenu()
    {
        CampaignMapReturnContextService.Clear();
        var outcome = new CampaignProgressionService.CampaignOutcome(
            IsCampaignRun: true,
            IsVictory: true,
            NodeAlreadyCompleted: false,
            NodeCompletedThisRun: true,
            RewardAwarded: true,
            RewardGold: 55);

        RunSummaryNavigationPolicy.PublishReturnContextIfNeeded(
            returnToCampaignMapOnSummary: false,
            campaignNodeId: "ember-bridge",
            nodeName: "Ember Bridge",
            outcome: outcome);

        Assert.Null(CampaignMapReturnContextService.Consume());
    }
}
