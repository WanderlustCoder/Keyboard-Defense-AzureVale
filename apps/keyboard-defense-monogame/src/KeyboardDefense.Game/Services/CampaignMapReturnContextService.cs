using System;

namespace KeyboardDefense.Game.Services;

public static class CampaignMapReturnContextService
{
    public readonly record struct ReturnContext(
        string NodeId,
        string Message,
        CampaignProgressionService.CampaignOutcomeTone Tone);

    private static ReturnContext? _pending;

    public static void SetFromSummaryOutcome(
        string? nodeId,
        string? nodeName,
        CampaignProgressionService.CampaignOutcome outcome)
    {
        if (!outcome.IsCampaignRun)
            return;

        var display = CampaignProgressionService.BuildSummaryDisplay(outcome);
        string id = (nodeId ?? string.Empty).Trim();
        string label = string.IsNullOrWhiteSpace(nodeName) ? id : nodeName.Trim();
        string prefix = string.IsNullOrWhiteSpace(label) ? "Campaign update" : label;
        string text = string.IsNullOrWhiteSpace(display.Text)
            ? $"{prefix}: summary updated."
            : $"{prefix}: {display.Text}";

        _pending = new ReturnContext(id, text, display.Tone);
    }

    public static ReturnContext? Consume()
    {
        var current = _pending;
        _pending = null;
        return current;
    }

    public static void Clear()
    {
        _pending = null;
    }
}
