using KeyboardDefense.Game.Screens;

namespace KeyboardDefense.Tests.Screens;

public class CampaignMapInputPolicyTests
{
    [Fact]
    public void ResolveMouseInspectMode_MouseMoved_SwitchesToMouse()
    {
        bool isMouseMode = CampaignMapInputPolicy.ResolveMouseInspectMode(
            currentMouseInspectMode: false,
            mouseMoved: true,
            clickStartedOnHoveredNode: false,
            keyboardNavigationRequested: false);

        Assert.True(isMouseMode);
    }

    [Fact]
    public void ResolveMouseInspectMode_KeyboardNavigation_StaysKeyboardWhenMouseIdle()
    {
        bool isMouseMode = CampaignMapInputPolicy.ResolveMouseInspectMode(
            currentMouseInspectMode: true,
            mouseMoved: false,
            clickStartedOnHoveredNode: false,
            keyboardNavigationRequested: true);

        Assert.False(isMouseMode);
    }

    [Fact]
    public void ResolveMouseInspectMode_ClickOnHoveredNode_SwitchesToMouse()
    {
        bool isMouseMode = CampaignMapInputPolicy.ResolveMouseInspectMode(
            currentMouseInspectMode: false,
            mouseMoved: false,
            clickStartedOnHoveredNode: true,
            keyboardNavigationRequested: true);

        Assert.True(isMouseMode);
    }

    [Theory]
    [InlineData(true, false, true)]
    [InlineData(false, true, true)]
    [InlineData(true, true, true)]
    [InlineData(false, false, false)]
    public void IsTraversalModeToggleRequested_HandlesPrimaryAndFallbackKeys(
        bool f6Pressed,
        bool mPressed,
        bool expected)
    {
        bool requested = CampaignMapInputPolicy.IsTraversalModeToggleRequested(f6Pressed, mPressed);
        Assert.Equal(expected, requested);
    }

    [Fact]
    public void ResolveCycleDelta_UsesCompactBindingsBeforeTabFallback()
    {
        int? qDelta = CampaignMapInputPolicy.ResolveCycleDelta(
            tabPressed: true,
            shiftDown: false,
            qPressed: true,
            ePressed: false);
        int? eDelta = CampaignMapInputPolicy.ResolveCycleDelta(
            tabPressed: true,
            shiftDown: true,
            qPressed: false,
            ePressed: true);

        Assert.Equal(-1, qDelta);
        Assert.Equal(1, eDelta);
    }

    [Fact]
    public void ResolveCycleDelta_UsesTabShiftFallback()
    {
        int? forward = CampaignMapInputPolicy.ResolveCycleDelta(
            tabPressed: true,
            shiftDown: false,
            qPressed: false,
            ePressed: false);
        int? reverse = CampaignMapInputPolicy.ResolveCycleDelta(
            tabPressed: true,
            shiftDown: true,
            qPressed: false,
            ePressed: false);
        int? none = CampaignMapInputPolicy.ResolveCycleDelta(
            tabPressed: false,
            shiftDown: false,
            qPressed: false,
            ePressed: false);

        Assert.Equal(1, forward);
        Assert.Equal(-1, reverse);
        Assert.Null(none);
    }
}
