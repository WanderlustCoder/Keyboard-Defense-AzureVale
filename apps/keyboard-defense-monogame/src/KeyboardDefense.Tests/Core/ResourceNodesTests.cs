using System;
using System.Collections.Generic;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class ResourceNodesCoreTests
{
    [Fact]
    public void NodeTypes_HasFourEntries()
    {
        Assert.Equal(4, ResourceNodes.NodeTypes.Count);
    }

    [Fact]
    public void NodeTypes_ContainsExpectedDefinitions()
    {
        var expected = ExpectedDefinitions();

        foreach (var (nodeId, expectedDef) in expected)
        {
            Assert.True(ResourceNodes.NodeTypes.ContainsKey(nodeId));
            Assert.Equal(expectedDef, ResourceNodes.NodeTypes[nodeId]);
        }
    }

    [Fact]
    public void GetNodeType_KnownIds_ReturnExpectedDefinitions()
    {
        var expected = ExpectedDefinitions();

        foreach (var (nodeId, expectedDef) in expected)
        {
            Assert.Equal(expectedDef, ResourceNodes.GetNodeType(nodeId));
        }
    }

    [Fact]
    public void GetNodeType_UnknownId_ReturnsNull()
    {
        Assert.Null(ResourceNodes.GetNodeType("unknown_node_type"));
    }

    [Fact]
    public void CalculatePerformanceMultiplier_ScoreZero_ReturnsPointFive()
    {
        double multiplier = ResourceNodes.CalculatePerformanceMultiplier(0);
        Assert.Equal(0.5, multiplier, 6);
    }

    [Fact]
    public void CalculatePerformanceMultiplier_ScoreFifty_ReturnsOnePointTwoFive()
    {
        double multiplier = ResourceNodes.CalculatePerformanceMultiplier(50);
        Assert.Equal(1.25, multiplier, 6);
    }

    [Fact]
    public void CalculatePerformanceMultiplier_ScoreOneHundred_ReturnsTwo()
    {
        double multiplier = ResourceNodes.CalculatePerformanceMultiplier(100);
        Assert.Equal(2.0, multiplier, 6);
    }

    [Fact]
    public void CalculatePerformanceMultiplier_ScoreBelowZero_ClampsToPointFive()
    {
        double multiplier = ResourceNodes.CalculatePerformanceMultiplier(-50);
        Assert.Equal(0.5, multiplier, 6);
    }

    [Fact]
    public void CalculatePerformanceMultiplier_ScoreAboveOneHundred_ClampsToTwo()
    {
        double multiplier = ResourceNodes.CalculatePerformanceMultiplier(200);
        Assert.Equal(2.0, multiplier, 6);
    }

    [Fact]
    public void HarvestNode_NoNodeAtIndex_ReturnsFailure()
    {
        var state = CreateIsolatedState();
        state.Resources["wood"] = 3;

        var result = ResourceNodes.HarvestNode(state, 42, 100);

        Assert.False((bool)result["ok"]);
        Assert.Equal("No resource node at location.", result["error"]);
        Assert.Equal(3, state.Resources["wood"]);
        Assert.Empty(state.HarvestedNodes);
    }

    [Fact]
    public void HarvestNode_UnknownNodeType_ReturnsFailure()
    {
        var state = CreateIsolatedState();
        AddNode(state, 42, "not_real");

        var result = ResourceNodes.HarvestNode(state, 42, 100);

        Assert.False((bool)result["ok"]);
        Assert.Equal("Unknown node type.", result["error"]);
        Assert.Equal(0, state.Resources["wood"]);
        Assert.Empty(state.HarvestedNodes);
    }

    [Fact]
    public void HarvestNode_WoodGroveScore100_ReturnsYieldTenAndWoodResource()
    {
        var state = CreateIsolatedState();
        AddNode(state, 42, "wood_grove");

        var result = ResourceNodes.HarvestNode(state, 42, 100);

        Assert.True((bool)result["ok"]);
        Assert.Equal("wood", result["resource"]);
        Assert.Equal(10, result["amount"]);
        Assert.Equal(10, state.Resources["wood"]);
    }

    [Fact]
    public void HarvestNode_StoneQuarryScore50_ReturnsYieldFive()
    {
        var state = CreateIsolatedState();
        AddNode(state, 42, "stone_quarry");

        var result = ResourceNodes.HarvestNode(state, 42, 50);

        Assert.True((bool)result["ok"]);
        Assert.Equal("stone", result["resource"]);
        Assert.Equal(5, result["amount"]);
        Assert.Equal(5, state.Resources["stone"]);
    }

    [Fact]
    public void HarvestNode_AddsYieldToExistingResourceCount()
    {
        var state = CreateIsolatedState();
        AddNode(state, 42, "wood_grove");
        state.Resources["wood"] = 7;

        var result = ResourceNodes.HarvestNode(state, 42, 100);

        Assert.True((bool)result["ok"]);
        Assert.Equal(17, state.Resources["wood"]);
    }

    [Fact]
    public void HarvestNode_RecordsHarvestedNodeDay()
    {
        var state = CreateIsolatedState();
        state.Day = 9;
        AddNode(state, 42, "food_garden");

        var result = ResourceNodes.HarvestNode(state, 42, 100);

        Assert.True((bool)result["ok"]);
        Assert.Equal(9, state.HarvestedNodes["42"]);
    }

    [Fact]
    public void HarvestNode_ScoreZero_WoodGroveFloorsToTwo()
    {
        var state = CreateIsolatedState();
        AddNode(state, 42, "wood_grove");

        var result = ResourceNodes.HarvestNode(state, 42, 0);

        Assert.True((bool)result["ok"]);
        Assert.Equal(2, result["amount"]);
        Assert.Equal(2, state.Resources["wood"]);
    }

    [Fact]
    public void HarvestNode_ScoreZero_GoldVeinYieldsOneMinimum()
    {
        var state = CreateIsolatedState();
        AddNode(state, 42, "gold_vein");

        var result = ResourceNodes.HarvestNode(state, 42, 0);

        Assert.True((bool)result["ok"]);
        Assert.Equal("gold", result["resource"]);
        Assert.Equal(1, result["amount"]);
        Assert.Equal(1, state.Resources["gold"]);
    }

    [Fact]
    public void HarvestNode_SuccessResult_IncludesMultiplierAndMessage()
    {
        var state = CreateIsolatedState();
        AddNode(state, 42, "wood_grove");

        var result = ResourceNodes.HarvestNode(state, 42, 100);

        Assert.True((bool)result["ok"]);
        Assert.Equal(2.0, (double)result["multiplier"], 6);
        Assert.Equal("Harvested 10 wood from Timber Grove!", result["message"]);
    }

    private static GameState CreateIsolatedState()
    {
        var state = DefaultState.Create(seed: "resource_nodes_tests");
        state.ResourceNodes.Clear();
        state.HarvestedNodes.Clear();
        state.Resources["wood"] = 0;
        state.Resources["stone"] = 0;
        state.Resources["food"] = 0;
        state.Resources.Remove("gold");
        return state;
    }

    private static void AddNode(GameState state, int nodeIndex, string nodeType)
    {
        state.ResourceNodes[nodeIndex] = new Dictionary<string, object>
        {
            ["type"] = nodeType
        };
    }

    private static Dictionary<string, ResourceNodeDef> ExpectedDefinitions() =>
        new()
        {
            ["wood_grove"] = new("Timber Grove", "wood", 5, 10),
            ["stone_quarry"] = new("Stone Quarry", "stone", 4, 8),
            ["food_garden"] = new("Wild Garden", "food", 6, 12),
            ["gold_vein"] = new("Gold Vein", "gold", 2, 5),
        };
}
