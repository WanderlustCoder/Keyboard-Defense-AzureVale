using KeyboardDefense.Game.Services;

namespace KeyboardDefense.Game.Screens;

public static class RunSummaryNavigationPolicy
{
    public static bool ShouldReturnToCampaignMap(bool returnToCampaignMapOnSummary)
    {
        return returnToCampaignMapOnSummary;
    }

    public static void PublishReturnContextIfNeeded(
        bool returnToCampaignMapOnSummary,
        string campaignNodeId,
        string nodeName,
        CampaignProgressionService.CampaignOutcome outcome)
    {
        if (!ShouldReturnToCampaignMap(returnToCampaignMapOnSummary))
            return;

        CampaignMapReturnContextService.SetFromSummaryOutcome(
            campaignNodeId,
            nodeName,
            outcome);
    }
}
