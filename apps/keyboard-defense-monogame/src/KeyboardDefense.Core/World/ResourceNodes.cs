using System;
using System.Collections.Generic;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.World;

/// <summary>
/// Resource harvesting POIs with typing challenges.
/// Ported from sim/resource_nodes.gd.
/// </summary>
public static class ResourceNodes
{
    public static readonly Dictionary<string, ResourceNodeDef> NodeTypes = new()
    {
        ["wood_grove"] = new("Timber Grove", "wood", 5, 10),
        ["stone_quarry"] = new("Stone Quarry", "stone", 4, 8),
        ["food_garden"] = new("Wild Garden", "food", 6, 12),
        ["gold_vein"] = new("Gold Vein", "gold", 2, 5),
    };

    public static ResourceNodeDef? GetNodeType(string nodeId) => NodeTypes.GetValueOrDefault(nodeId);

    public static Dictionary<string, object> HarvestNode(GameState state, int nodeIndex, double performanceScore)
    {
        if (!state.ResourceNodes.TryGetValue(nodeIndex, out var node))
            return new() { ["ok"] = false, ["error"] = "No resource node at location." };

        string nodeType = node.GetValueOrDefault("type", "").ToString() ?? "";
        var def = GetNodeType(nodeType);
        if (def == null)
            return new() { ["ok"] = false, ["error"] = "Unknown node type." };

        // Performance multiplier (0.5x to 2.0x based on typing challenge performance)
        double multiplier = CalculatePerformanceMultiplier(performanceScore);
        int yield = (int)(def.BaseYield * multiplier);
        yield = Math.Max(1, yield);

        state.Resources[def.Resource] = state.Resources.GetValueOrDefault(def.Resource, 0) + yield;

        // Track harvested
        state.HarvestedNodes[nodeIndex.ToString()] = state.Day;

        return new()
        {
            ["ok"] = true,
            ["resource"] = def.Resource,
            ["amount"] = yield,
            ["multiplier"] = multiplier,
            ["message"] = $"Harvested {yield} {def.Resource} from {def.Name}!"
        };
    }

    public static double CalculatePerformanceMultiplier(double score)
    {
        // score is 0-100
        double normalized = Math.Clamp(score / 100.0, 0, 1);
        return 0.5 + normalized * 1.5; // 0.5x to 2.0x
    }
}

public record ResourceNodeDef(string Name, string Resource, int BaseYield, int MaxYield);
