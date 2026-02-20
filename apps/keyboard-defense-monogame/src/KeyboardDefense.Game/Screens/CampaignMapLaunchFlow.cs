using System;

namespace KeyboardDefense.Game.Screens;

public sealed class CampaignMapLaunchFlow
{
    public const float DefaultConfirmWindowSeconds = 1.8f;

    private readonly float _confirmWindowSeconds;

    public CampaignMapLaunchFlow(float confirmWindowSeconds = DefaultConfirmWindowSeconds)
    {
        _confirmWindowSeconds = Math.Max(0.2f, confirmWindowSeconds);
    }

    public string? PendingNodeId { get; private set; }
    public float PendingSecondsRemaining { get; private set; }

    public bool RequestLaunch(string nodeId)
    {
        if (string.IsNullOrWhiteSpace(nodeId))
            return false;

        if (string.Equals(PendingNodeId, nodeId, StringComparison.Ordinal) &&
            PendingSecondsRemaining > 0f)
        {
            Clear();
            return true;
        }

        PendingNodeId = nodeId;
        PendingSecondsRemaining = _confirmWindowSeconds;
        return false;
    }

    public void Update(float deltaSeconds)
    {
        if (PendingSecondsRemaining <= 0f)
            return;

        PendingSecondsRemaining = Math.Max(0f, PendingSecondsRemaining - Math.Max(0f, deltaSeconds));
        if (PendingSecondsRemaining <= 0f)
            Clear();
    }

    public void HandleFocusChanged(string? focusedNodeId)
    {
        if (PendingNodeId == null)
            return;
        if (!string.Equals(PendingNodeId, focusedNodeId, StringComparison.Ordinal))
            Clear();
    }

    public void Clear()
    {
        PendingNodeId = null;
        PendingSecondsRemaining = 0f;
    }
}
