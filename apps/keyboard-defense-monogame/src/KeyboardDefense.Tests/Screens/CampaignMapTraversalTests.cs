using System.Collections.Generic;
using KeyboardDefense.Game.Screens;
using Microsoft.Xna.Framework;

namespace KeyboardDefense.Tests.Screens;

public class CampaignMapTraversalTests
{
    [Fact]
    public void FindDirectionalCandidate_PrefersClosestCandidateInRequestedDirection()
    {
        var positions = new Dictionary<string, Vector2>
        {
            ["center"] = new(100, 100),
            ["right-near"] = new(300, 100),
            ["right-far-lane"] = new(260, 260),
            ["left-near"] = new(20, 100),
        };
        var order = new List<string> { "center", "right-near", "right-far-lane", "left-near" };

        string? nextRight = CampaignMapTraversal.FindDirectionalCandidate(
            "center", positions, order, 1, 0, 95f, 280f);
        string? nextLeft = CampaignMapTraversal.FindDirectionalCandidate(
            "center", positions, order, -1, 0, 95f, 280f);

        Assert.Equal("right-near", nextRight);
        Assert.Equal("left-near", nextLeft);
    }

    [Fact]
    public void FindDirectionalCandidate_ReturnsNull_WhenNoCandidateInDirection()
    {
        var positions = new Dictionary<string, Vector2>
        {
            ["center"] = new(200, 200),
            ["down"] = new(200, 320),
        };
        var order = new List<string> { "center", "down" };

        string? nextUp = CampaignMapTraversal.FindDirectionalCandidate(
            "center", positions, order, 0, -1, 95f, 280f);

        Assert.Null(nextUp);
    }

    [Fact]
    public void EnsureFocusedNodeVisible_AdjustsScrollOffsetToRevealNode()
    {
        Vector2 adjusted = CampaignMapTraversal.EnsureFocusedNodeVisible(
            Vector2.Zero,
            new Rectangle(900, 580, 220, 70),
            viewportWidth: 800,
            viewportHeight: 600,
            topBound: 96,
            margin: 24);

        Assert.Equal(-344f, adjusted.X);
        Assert.Equal(-74f, adjusted.Y);
    }

    [Fact]
    public void ClampScrollOffset_ClampsToGraphBounds()
    {
        Vector2 clamped = CampaignMapTraversal.ClampScrollOffset(
            new Vector2(-1000f, -1000f),
            viewportWidth: 800,
            viewportHeight: 600,
            graphWidth: 1200,
            graphHeight: 900);

        Assert.Equal(-440f, clamped.X);
        Assert.Equal(-340f, clamped.Y);
    }

    [Fact]
    public void ClampScrollOffset_WhenGraphIsSmaller_UsesStaticUpperRange()
    {
        Vector2 clamped = CampaignMapTraversal.ClampScrollOffset(
            new Vector2(-200f, -200f),
            viewportWidth: 800,
            viewportHeight: 600,
            graphWidth: 500,
            graphHeight: 450);

        Assert.Equal(40f, clamped.X);
        Assert.Equal(40f, clamped.Y);
    }
}
