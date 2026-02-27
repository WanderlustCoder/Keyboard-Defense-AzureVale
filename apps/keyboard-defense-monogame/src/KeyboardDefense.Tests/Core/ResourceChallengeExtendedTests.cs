using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Extended tests for ResourceChallenge — constants, ProcessChallengeInput edge cases,
/// cooldown tick interactions, CancelChallenge idempotency, multiple nodes,
/// and scoring edge cases.
/// </summary>
public class ResourceChallengeExtendedTests
{
    // =========================================================================
    // Constants
    // =========================================================================

    [Fact]
    public void InteractionRadius_IsOne()
    {
        Assert.Equal(1, ResourceChallenge.InteractionRadius);
    }

    [Fact]
    public void NodeCooldownTicks_IsTen()
    {
        Assert.Equal(10f, ResourceChallenge.NodeCooldownTicks);
    }

    // =========================================================================
    // StartChallenge — multiple nodes, picks closest
    // =========================================================================

    [Fact]
    public void StartChallenge_MultipleNodes_PicksClosest()
    {
        var state = CreateHarvestState();
        // Node at same position as player (distance 0)
        PlaceNode(state, state.PlayerPos, "wood_grove", 0f);
        // Node at distance 1
        var farPos = new GridPoint(state.PlayerPos.X + 1, state.PlayerPos.Y);
        PlaceNode(state, farPos, "stone_quarry", 0f);

        var result = ResourceChallenge.StartChallenge(state);

        Assert.NotNull(result);
        // Should pick the one at distance 0
        int nodeIdx = Convert.ToInt32(result!["node_index"]);
        Assert.Equal(SimMap.Idx(state.PlayerPos.X, state.PlayerPos.Y, state.MapW), nodeIdx);
    }

    [Fact]
    public void StartChallenge_ClosestNodeOnCooldown_PicksNextClosest()
    {
        var state = CreateHarvestState();
        // Closest node on cooldown
        PlaceNode(state, state.PlayerPos, "wood_grove", 5f);
        // Next closest available
        var nextPos = new GridPoint(state.PlayerPos.X + 1, state.PlayerPos.Y);
        PlaceNode(state, nextPos, "stone_quarry", 0f);

        var result = ResourceChallenge.StartChallenge(state);

        Assert.NotNull(result);
        int nodeIdx = Convert.ToInt32(result!["node_index"]);
        Assert.Equal(SimMap.Idx(nextPos.X, nextPos.Y, state.MapW), nodeIdx);
    }

    [Fact]
    public void StartChallenge_AllNodesOnCooldown_ReturnsNull()
    {
        var state = CreateHarvestState();
        PlaceNode(state, state.PlayerPos, "wood_grove", 5f);

        var result = ResourceChallenge.StartChallenge(state);

        Assert.Null(result);
        Assert.Equal("exploration", state.ActivityMode);
    }

    [Fact]
    public void StartChallenge_SetsActivityModeToHarvestChallenge()
    {
        var state = CreateHarvestState();
        PlaceNode(state, state.PlayerPos, "wood_grove", 0f);

        ResourceChallenge.StartChallenge(state);

        Assert.Equal("harvest_challenge", state.ActivityMode);
    }

    [Fact]
    public void StartChallenge_SetsPendingEvent()
    {
        var state = CreateHarvestState();
        PlaceNode(state, state.PlayerPos, "wood_grove", 0f);

        ResourceChallenge.StartChallenge(state);

        Assert.Equal("harvest_challenge", state.PendingEvent["type"]?.ToString());
        Assert.True(state.PendingEvent.ContainsKey("word"));
        Assert.True(state.PendingEvent.ContainsKey("node_index"));
        Assert.True(state.PendingEvent.ContainsKey("node_type"));
    }

    // =========================================================================
    // ProcessChallengeInput — edge cases
    // =========================================================================

    [Fact]
    public void ProcessChallengeInput_NotInHarvestMode_ReturnsEmpty()
    {
        var state = CreateHarvestState();
        state.ActivityMode = "exploration";

        var events = ResourceChallenge.ProcessChallengeInput(state, "test");

        Assert.Empty(events);
    }

    [Fact]
    public void ProcessChallengeInput_EmptyInput_ReturnsEmpty()
    {
        var state = CreateHarvestState();
        PlaceNode(state, state.PlayerPos, "wood_grove", 0f);
        ResourceChallenge.StartChallenge(state);

        var events = ResourceChallenge.ProcessChallengeInput(state, "");

        Assert.Empty(events);
        // Still in harvest mode since no input processed
        Assert.Equal("harvest_challenge", state.ActivityMode);
    }

    [Fact]
    public void ProcessChallengeInput_WhitespaceOnly_ReturnsEmpty()
    {
        var state = CreateHarvestState();
        PlaceNode(state, state.PlayerPos, "wood_grove", 0f);
        ResourceChallenge.StartChallenge(state);

        var events = ResourceChallenge.ProcessChallengeInput(state, "   ");

        Assert.Empty(events);
    }

    [Fact]
    public void ProcessChallengeInput_ExactMatch_ReturnsEvent()
    {
        var state = CreateHarvestState();
        PlaceNode(state, state.PlayerPos, "wood_grove", 0f);
        var challenge = ResourceChallenge.StartChallenge(state)!;
        string word = challenge["word"].ToString()!;

        var events = ResourceChallenge.ProcessChallengeInput(state, word);

        Assert.NotEmpty(events);
        Assert.Equal("exploration", state.ActivityMode);
    }

    [Fact]
    public void ProcessChallengeInput_CaseInsensitive()
    {
        var state = CreateHarvestState();
        PlaceNode(state, state.PlayerPos, "wood_grove", 0f);
        var challenge = ResourceChallenge.StartChallenge(state)!;
        string word = challenge["word"].ToString()!;

        var events = ResourceChallenge.ProcessChallengeInput(state, word.ToUpperInvariant());

        Assert.NotEmpty(events);
    }

    [Fact]
    public void ProcessChallengeInput_NodeRemoved_ReturnsVanishedMessage()
    {
        var state = CreateHarvestState();
        PlaceNode(state, state.PlayerPos, "wood_grove", 0f);
        ResourceChallenge.StartChallenge(state);

        // Remove the node while challenge is active
        state.ResourceNodes.Clear();

        var events = ResourceChallenge.ProcessChallengeInput(state, "anything");

        Assert.NotEmpty(events);
        Assert.Contains(events, e => e.Contains("vanished"));
        Assert.Equal("exploration", state.ActivityMode);
    }

    [Fact]
    public void ProcessChallengeInput_SetsNodeCooldownAfterHarvest()
    {
        var state = CreateHarvestState();
        int nodeIdx = PlaceNode(state, state.PlayerPos, "wood_grove", 0f);
        var challenge = ResourceChallenge.StartChallenge(state)!;
        string word = challenge["word"].ToString()!;

        ResourceChallenge.ProcessChallengeInput(state, word);

        float cooldown = Convert.ToSingle(state.ResourceNodes[nodeIdx].GetValueOrDefault("cooldown", 0f));
        Assert.Equal(ResourceChallenge.NodeCooldownTicks, cooldown);
    }

    // =========================================================================
    // CancelChallenge — edge cases
    // =========================================================================

    [Fact]
    public void CancelChallenge_NotInHarvestMode_DoesNothing()
    {
        var state = CreateHarvestState();
        state.ActivityMode = "exploration";

        ResourceChallenge.CancelChallenge(state);

        Assert.Equal("exploration", state.ActivityMode);
    }

    [Fact]
    public void CancelChallenge_InHarvestMode_ReturnsToExploration()
    {
        var state = CreateHarvestState();
        PlaceNode(state, state.PlayerPos, "wood_grove", 0f);
        ResourceChallenge.StartChallenge(state);

        ResourceChallenge.CancelChallenge(state);

        Assert.Equal("exploration", state.ActivityMode);
    }

    [Fact]
    public void CancelChallenge_CalledTwice_NoCrash()
    {
        var state = CreateHarvestState();
        PlaceNode(state, state.PlayerPos, "wood_grove", 0f);
        ResourceChallenge.StartChallenge(state);

        ResourceChallenge.CancelChallenge(state);
        ResourceChallenge.CancelChallenge(state);

        Assert.Equal("exploration", state.ActivityMode);
    }

    // =========================================================================
    // TickCooldowns — edge cases
    // =========================================================================

    [Fact]
    public void TickCooldowns_MultipleNodes_DecrementsAll()
    {
        var state = CreateHarvestState();
        PlaceNode(state, state.PlayerPos, "wood_grove", 5f);
        var otherPos = new GridPoint(state.PlayerPos.X + 2, state.PlayerPos.Y);
        PlaceNode(state, otherPos, "stone_quarry", 8f);

        ResourceChallenge.TickCooldowns(state, 3f);

        foreach (var (_, node) in state.ResourceNodes)
        {
            float cd = Convert.ToSingle(node.GetValueOrDefault("cooldown", 0f));
            Assert.True(cd >= 0);
        }
    }

    [Fact]
    public void TickCooldowns_ZeroDelta_NoCooldownChange()
    {
        var state = CreateHarvestState();
        PlaceNode(state, state.PlayerPos, "wood_grove", 5f);
        int nodeIdx = SimMap.Idx(state.PlayerPos.X, state.PlayerPos.Y, state.MapW);

        ResourceChallenge.TickCooldowns(state, 0f);

        float cd = Convert.ToSingle(state.ResourceNodes[nodeIdx]["cooldown"]);
        Assert.Equal(5f, cd, 0.01);
    }

    [Fact]
    public void TickCooldowns_NoCooldownNodes_NoCrash()
    {
        var state = CreateHarvestState();
        // Node without cooldown key
        var nodePos = state.PlayerPos;
        int nodeIdx = SimMap.Idx(nodePos.X, nodePos.Y, state.MapW);
        state.ResourceNodes[nodeIdx] = new Dictionary<string, object>
        {
            ["type"] = "wood_grove",
            ["pos"] = nodePos,
        };

        ResourceChallenge.TickCooldowns(state, 2f);

        // Should not crash
    }

    [Fact]
    public void TickCooldowns_EmptyNodes_NoCrash()
    {
        var state = CreateHarvestState();
        state.ResourceNodes.Clear();

        ResourceChallenge.TickCooldowns(state, 5f);
    }

    [Fact]
    public void TickCooldowns_LargeDelta_ClampsToZero()
    {
        var state = CreateHarvestState();
        int nodeIdx = PlaceNode(state, state.PlayerPos, "wood_grove", 3f);

        ResourceChallenge.TickCooldowns(state, 100f);

        float cd = Convert.ToSingle(state.ResourceNodes[nodeIdx]["cooldown"]);
        Assert.Equal(0f, cd);
    }

    // =========================================================================
    // StartChallenge → ProcessChallengeInput → StartChallenge cycle
    // =========================================================================

    [Fact]
    public void FullCycle_ChallengeAndCooldownAndRechallenge()
    {
        var state = CreateHarvestState();
        int nodeIdx = PlaceNode(state, state.PlayerPos, "wood_grove", 0f);

        // Start and complete challenge
        var challenge1 = ResourceChallenge.StartChallenge(state);
        Assert.NotNull(challenge1);
        string word1 = challenge1!["word"].ToString()!;
        ResourceChallenge.ProcessChallengeInput(state, word1);

        // Node should be on cooldown now
        float cd = Convert.ToSingle(state.ResourceNodes[nodeIdx]["cooldown"]);
        Assert.True(cd > 0);

        // Can't start another challenge on same node
        var challenge2 = ResourceChallenge.StartChallenge(state);
        Assert.Null(challenge2);

        // Tick cooldown to zero
        ResourceChallenge.TickCooldowns(state, cd);

        // Now can start again
        var challenge3 = ResourceChallenge.StartChallenge(state);
        Assert.NotNull(challenge3);
    }

    // =========================================================================
    // Helpers
    // =========================================================================

    private static GameState CreateHarvestState()
    {
        var state = DefaultState.Create("harvest_ext_test");
        TypingMetrics.InitBattleMetrics(state);
        return state;
    }

    private static int PlaceNode(GameState state, GridPoint pos, string nodeType, float cooldown)
    {
        int nodeIdx = SimMap.Idx(pos.X, pos.Y, state.MapW);
        state.ResourceNodes[nodeIdx] = new Dictionary<string, object>
        {
            ["type"] = nodeType,
            ["pos"] = pos,
            ["zone"] = "safe",
            ["cooldown"] = cooldown,
        };
        return nodeIdx;
    }
}
