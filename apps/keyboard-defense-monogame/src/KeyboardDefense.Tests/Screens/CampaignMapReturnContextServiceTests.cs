using KeyboardDefense.Game.Services;

namespace KeyboardDefense.Tests.Screens;

public class CampaignMapReturnContextServiceTests
{
    [Fact]
    public void SetFromSummaryOutcome_RewardOutcome_StoresToneAndMessage()
    {
        CampaignMapReturnContextService.Clear();
        var outcome = new CampaignProgressionService.CampaignOutcome(
            IsCampaignRun: true,
            IsVictory: true,
            NodeAlreadyCompleted: false,
            NodeCompletedThisRun: true,
            RewardAwarded: true,
            RewardGold: 30);

        CampaignMapReturnContextService.SetFromSummaryOutcome("ember-bridge", "Ember Bridge", outcome);
        var context = CampaignMapReturnContextService.Consume();

        Assert.True(context.HasValue);
        Assert.Equal("ember-bridge", context.Value.NodeId);
        Assert.Equal(CampaignProgressionService.CampaignOutcomeTone.Reward, context.Value.Tone);
        Assert.Contains("Ember Bridge", context.Value.Message);
        Assert.Contains("+30 gold awarded", context.Value.Message);
    }

    [Fact]
    public void SetFromSummaryOutcome_WarningOutcome_StoresWarningTone()
    {
        CampaignMapReturnContextService.Clear();
        var outcome = new CampaignProgressionService.CampaignOutcome(
            IsCampaignRun: true,
            IsVictory: false,
            NodeAlreadyCompleted: false,
            NodeCompletedThisRun: false,
            RewardAwarded: false,
            RewardGold: 40);

        CampaignMapReturnContextService.SetFromSummaryOutcome("whisper-grove", "Whisper Grove", outcome);
        var context = CampaignMapReturnContextService.Consume();

        Assert.True(context.HasValue);
        Assert.Equal(CampaignProgressionService.CampaignOutcomeTone.Warning, context.Value.Tone);
        Assert.Contains("Whisper Grove", context.Value.Message);
        Assert.Contains("Win to earn +40 gold", context.Value.Message);
    }

    [Fact]
    public void SetFromSummaryOutcome_NonCampaignOutcome_DoesNotStoreContext()
    {
        CampaignMapReturnContextService.Clear();
        CampaignMapReturnContextService.SetFromSummaryOutcome(
            "ember-bridge",
            "Ember Bridge",
            CampaignProgressionService.CampaignOutcome.None);

        Assert.Null(CampaignMapReturnContextService.Consume());
    }

    [Fact]
    public void Consume_ClearsPendingContext()
    {
        CampaignMapReturnContextService.Clear();
        var outcome = new CampaignProgressionService.CampaignOutcome(
            IsCampaignRun: true,
            IsVictory: true,
            NodeAlreadyCompleted: true,
            NodeCompletedThisRun: false,
            RewardAwarded: false,
            RewardGold: 0);

        CampaignMapReturnContextService.SetFromSummaryOutcome("a", "A", outcome);
        Assert.True(CampaignMapReturnContextService.Consume().HasValue);
        Assert.Null(CampaignMapReturnContextService.Consume());
    }
}
