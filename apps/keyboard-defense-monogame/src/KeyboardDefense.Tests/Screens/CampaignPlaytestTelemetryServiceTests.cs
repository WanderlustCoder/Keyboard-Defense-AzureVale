using System.Collections.Generic;
using KeyboardDefense.Game.Services;

namespace KeyboardDefense.Tests.Screens;

public class CampaignPlaytestTelemetryServiceTests
{
    [Fact]
    public void RecordEvents_IncrementExpectedCounters()
    {
        var before = CampaignPlaytestTelemetryService.GetSnapshot();

        CampaignPlaytestTelemetryService.RecordMapEntered();
        CampaignPlaytestTelemetryService.RecordOnboardingShown();
        CampaignPlaytestTelemetryService.RecordOnboardingCompleted();
        CampaignPlaytestTelemetryService.RecordTraversalModeToggled("Linear");
        CampaignPlaytestTelemetryService.RecordTraversalModeToggled("Spatial");
        CampaignPlaytestTelemetryService.RecordLaunchPromptShown("ember-bridge");
        CampaignPlaytestTelemetryService.RecordLaunchConfirmed("ember-bridge", "keyboard_confirm");
        CampaignPlaytestTelemetryService.RecordLaunchConfirmed("ember-bridge", "mouse_click");
        CampaignPlaytestTelemetryService.RecordReturnContextShown(
            "ember-bridge",
            CampaignProgressionService.CampaignOutcomeTone.Reward);

        var after = CampaignPlaytestTelemetryService.GetSnapshot();

        Assert.True(after.MapVisits >= before.MapVisits + 1);
        Assert.True(after.OnboardingShownCount >= before.OnboardingShownCount + 1);
        Assert.True(after.OnboardingCompletedCount >= before.OnboardingCompletedCount + 1);
        Assert.True(after.LaunchPromptCount >= before.LaunchPromptCount + 1);
        Assert.True(after.LaunchConfirmedCount >= before.LaunchConfirmedCount + 2);
        Assert.True(after.ReturnContextShownCount >= before.ReturnContextShownCount + 1);

        Assert.True(
            Count(after.TraversalModeToggleCount, "Linear") >=
            Count(before.TraversalModeToggleCount, "Linear") + 1);
        Assert.True(
            Count(after.TraversalModeToggleCount, "Spatial") >=
            Count(before.TraversalModeToggleCount, "Spatial") + 1);
        Assert.True(
            Count(after.LaunchPromptByNode, "ember-bridge") >=
            Count(before.LaunchPromptByNode, "ember-bridge") + 1);
        Assert.True(
            Count(after.LaunchConfirmedByInputMode, "keyboard_confirm") >=
            Count(before.LaunchConfirmedByInputMode, "keyboard_confirm") + 1);
        Assert.True(
            Count(after.LaunchConfirmedByInputMode, "mouse_click") >=
            Count(before.LaunchConfirmedByInputMode, "mouse_click") + 1);
        Assert.True(
            Count(after.ReturnContextToneCount, CampaignProgressionService.CampaignOutcomeTone.Reward.ToString()) >=
            Count(before.ReturnContextToneCount, CampaignProgressionService.CampaignOutcomeTone.Reward.ToString()) + 1);

        Assert.False(string.IsNullOrWhiteSpace(after.LastUpdatedUtc));
    }

    private static int Count(Dictionary<string, int> map, string key)
    {
        return map.TryGetValue(key, out int count) ? count : 0;
    }
}
