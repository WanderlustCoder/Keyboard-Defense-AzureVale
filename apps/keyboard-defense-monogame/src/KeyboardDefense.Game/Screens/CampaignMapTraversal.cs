using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;

namespace KeyboardDefense.Game.Screens;

public static class CampaignMapTraversal
{
    public static string? FindDirectionalCandidate(
        string currentNodeId,
        IReadOnlyDictionary<string, Vector2> nodePositions,
        IReadOnlyList<string> keyboardNodeOrder,
        int dirX,
        int dirY,
        float rowSpacing,
        float columnSpacing)
    {
        if (!nodePositions.TryGetValue(currentNodeId, out Vector2 currentPos))
            return null;

        string? bestId = null;
        float bestScore = float.MaxValue;
        foreach (string candidateId in keyboardNodeOrder)
        {
            if (candidateId == currentNodeId || !nodePositions.TryGetValue(candidateId, out Vector2 candidatePos))
                continue;

            float dx = candidatePos.X - currentPos.X;
            float dy = candidatePos.Y - currentPos.Y;
            float primary;
            float secondary;
            float laneThreshold;

            if (dirX != 0)
            {
                primary = dirX > 0 ? dx : -dx;
                secondary = MathF.Abs(dy);
                laneThreshold = rowSpacing * 0.65f;
            }
            else
            {
                primary = dirY > 0 ? dy : -dy;
                secondary = MathF.Abs(dx);
                laneThreshold = columnSpacing * 0.6f;
            }

            if (primary <= 0f)
                continue;

            float lanePenalty = secondary <= laneThreshold
                ? secondary * 0.35f
                : laneThreshold * 0.35f + (secondary - laneThreshold) * 6f;
            float score = primary + lanePenalty;
            if (score < bestScore)
            {
                bestScore = score;
                bestId = candidateId;
            }
        }

        return bestId;
    }

    public static Vector2 EnsureFocusedNodeVisible(
        Vector2 scrollOffset,
        Rectangle nodeRect,
        int viewportWidth,
        int viewportHeight,
        int topBound = 96,
        int margin = 24)
    {
        int leftBound = margin;
        int rightBound = viewportWidth - margin;
        int upperBound = topBound;
        int lowerBound = viewportHeight - margin;

        var shifted = new Rectangle(
            nodeRect.X + (int)scrollOffset.X,
            nodeRect.Y + (int)scrollOffset.Y,
            nodeRect.Width,
            nodeRect.Height);

        if (shifted.Left < leftBound)
            scrollOffset.X += leftBound - shifted.Left;
        if (shifted.Right > rightBound)
            scrollOffset.X -= shifted.Right - rightBound;
        if (shifted.Top < upperBound)
            scrollOffset.Y += upperBound - shifted.Top;
        if (shifted.Bottom > lowerBound)
            scrollOffset.Y -= shifted.Bottom - lowerBound;

        return scrollOffset;
    }

    public static Vector2 ClampScrollOffset(
        Vector2 scrollOffset,
        int viewportWidth,
        int viewportHeight,
        int graphWidth,
        int graphHeight)
    {
        float minX = -(graphWidth - viewportWidth + 40f);
        float minY = -(graphHeight - viewportHeight + 40f);
        if (minX > 40f)
            minX = 40f;
        if (minY > 40f)
            minY = 40f;

        return new Vector2(
            MathHelper.Clamp(scrollOffset.X, minX, 40f),
            MathHelper.Clamp(scrollOffset.Y, minY, 40f));
    }
}
