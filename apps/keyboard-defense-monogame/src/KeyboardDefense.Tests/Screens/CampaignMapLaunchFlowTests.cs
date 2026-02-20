using KeyboardDefense.Game.Screens;

namespace KeyboardDefense.Tests.Screens;

public class CampaignMapLaunchFlowTests
{
    [Fact]
    public void RequestLaunch_RequiresSecondConfirmWithinWindow()
    {
        var flow = new CampaignMapLaunchFlow(confirmWindowSeconds: 2f);

        bool first = flow.RequestLaunch("ember-bridge");
        bool second = flow.RequestLaunch("ember-bridge");

        Assert.False(first);
        Assert.True(second);
        Assert.Null(flow.PendingNodeId);
    }

    [Fact]
    public void RequestLaunch_ExpiresAfterTimeout()
    {
        var flow = new CampaignMapLaunchFlow(confirmWindowSeconds: 1f);

        bool first = flow.RequestLaunch("ember-bridge");
        flow.Update(1.25f);
        bool second = flow.RequestLaunch("ember-bridge");

        Assert.False(first);
        Assert.False(second);
        Assert.Equal("ember-bridge", flow.PendingNodeId);
    }

    [Fact]
    public void HandleFocusChanged_ClearsPendingWhenNodeChanges()
    {
        var flow = new CampaignMapLaunchFlow(confirmWindowSeconds: 2f);
        flow.RequestLaunch("ember-bridge");

        flow.HandleFocusChanged("whisper-grove");

        Assert.Null(flow.PendingNodeId);
        Assert.Equal(0f, flow.PendingSecondsRemaining);
    }
}
