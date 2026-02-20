namespace KeyboardDefense.Game.Screens;

public static class CampaignMapInputPolicy
{
    public static bool ResolveMouseInspectMode(
        bool currentMouseInspectMode,
        bool mouseMoved,
        bool clickStartedOnHoveredNode,
        bool keyboardNavigationRequested)
    {
        if (mouseMoved || clickStartedOnHoveredNode)
            return true;
        if (keyboardNavigationRequested)
            return false;
        return currentMouseInspectMode;
    }

    public static bool IsTraversalModeToggleRequested(bool f6Pressed, bool mPressed)
    {
        return f6Pressed || mPressed;
    }

    public static int? ResolveCycleDelta(
        bool tabPressed,
        bool shiftDown,
        bool qPressed,
        bool ePressed)
    {
        if (qPressed && !ePressed)
            return -1;
        if (ePressed && !qPressed)
            return 1;
        if (tabPressed)
            return shiftDown ? -1 : 1;
        return null;
    }
}
