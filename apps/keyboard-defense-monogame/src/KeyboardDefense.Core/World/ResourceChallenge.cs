using System;
using System.Collections.Generic;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;

namespace KeyboardDefense.Core.World;

/// <summary>
/// Typing challenge system for harvesting resource nodes.
/// Player walks to a node, presses E/Enter, types the challenge word,
/// and performance determines harvest multiplier (0.5x-2.0x).
/// </summary>
public static class ResourceChallenge
{
    public const int InteractionRadius = 1;
    public const float NodeCooldownTicks = 10f;

    /// <summary>
    /// Start a resource harvest challenge at the player's location.
    /// Returns challenge word and node info, or null if no valid node nearby.
    /// </summary>
    public static Dictionary<string, object>? StartChallenge(GameState state)
    {
        if (state.ActivityMode != "exploration") return null;

        // Find the nearest resource node within interaction radius
        var playerPos = state.PlayerPos;
        int bestIdx = -1;
        int bestDist = int.MaxValue;

        foreach (var (idx, node) in state.ResourceNodes)
        {
            if (node.GetValueOrDefault("pos") is not GridPoint nPos) continue;

            // Check cooldown
            float cooldown = Convert.ToSingle(node.GetValueOrDefault("cooldown", 0f));
            if (cooldown > 0) continue;

            int dist = playerPos.ManhattanDistance(nPos);
            if (dist <= InteractionRadius && dist < bestDist)
            {
                bestDist = dist;
                bestIdx = idx;
            }
        }

        if (bestIdx < 0) return null;

        var targetNode = state.ResourceNodes[bestIdx];
        string nodeType = targetNode.GetValueOrDefault("type")?.ToString() ?? "wood_grove";
        var def = ResourceNodes.GetNodeType(nodeType);
        if (def == null) return null;

        // Generate challenge word scaled to node quality
        string word = GenerateChallengeWord(state, nodeType, bestIdx);

        // Switch to harvest challenge mode
        state.ActivityMode = "harvest_challenge";
        state.PendingEvent = new Dictionary<string, object>
        {
            ["type"] = "harvest_challenge",
            ["node_index"] = bestIdx,
            ["word"] = word,
            ["node_type"] = nodeType,
        };

        return new Dictionary<string, object>
        {
            ["ok"] = true,
            ["word"] = word,
            ["node_name"] = def.Name,
            ["resource"] = def.Resource,
            ["node_index"] = bestIdx,
        };
    }

    /// <summary>
    /// Process typed input for the active harvest challenge.
    /// Returns events describing the result.
    /// </summary>
    public static List<string> ProcessChallengeInput(GameState state, string input)
    {
        var events = new List<string>();
        if (state.ActivityMode != "harvest_challenge") return events;
        if (state.PendingEvent.GetValueOrDefault("type")?.ToString() != "harvest_challenge") return events;

        string typed = input.Trim().ToLowerInvariant();
        if (string.IsNullOrEmpty(typed)) return events;

        string challengeWord = (state.PendingEvent.GetValueOrDefault("word")?.ToString() ?? "").ToLowerInvariant();
        int nodeIndex = Convert.ToInt32(state.PendingEvent.GetValueOrDefault("node_index", -1));

        if (nodeIndex < 0 || !state.ResourceNodes.ContainsKey(nodeIndex))
        {
            EndChallenge(state);
            events.Add("The resource node has vanished!");
            return events;
        }

        // Calculate performance score based on accuracy
        double score = CalculateScore(typed, challengeWord);

        // Harvest with performance multiplier
        var result = ResourceNodes.HarvestNode(state, nodeIndex, score);

        if (Convert.ToBoolean(result.GetValueOrDefault("ok", false)))
        {
            string message = result.GetValueOrDefault("message")?.ToString() ?? "Harvested!";
            double multiplier = Convert.ToDouble(result.GetValueOrDefault("multiplier", 1.0));

            if (multiplier >= 1.8)
                events.Add($"PERFECT! {message}");
            else if (multiplier >= 1.2)
                events.Add($"Good harvest! {message}");
            else
                events.Add(message);

            // Put node on cooldown
            if (state.ResourceNodes.TryGetValue(nodeIndex, out var node))
                node["cooldown"] = NodeCooldownTicks;

            // Track typing
            TypingMetrics.RecordWordCompleted(state);
        }
        else
        {
            events.Add(result.GetValueOrDefault("error")?.ToString() ?? "Harvest failed.");
        }

        EndChallenge(state);
        return events;
    }

    /// <summary>Cancel the active challenge and return to exploration.</summary>
    public static void CancelChallenge(GameState state)
    {
        if (state.ActivityMode == "harvest_challenge")
            EndChallenge(state);
    }

    /// <summary>Tick resource node cooldowns each world tick.</summary>
    public static void TickCooldowns(GameState state, float delta)
    {
        foreach (var (_, node) in state.ResourceNodes)
        {
            float cooldown = Convert.ToSingle(node.GetValueOrDefault("cooldown", 0f));
            if (cooldown > 0)
                node["cooldown"] = Math.Max(0f, cooldown - delta);
        }
    }

    private static void EndChallenge(GameState state)
    {
        state.ActivityMode = "exploration";
        state.PendingEvent.Clear();
    }

    private static double CalculateScore(string typed, string expected)
    {
        if (typed == expected) return 100.0;

        // Partial credit based on edit distance
        int distance = LevenshteinDistance(typed, expected);
        int maxLen = Math.Max(typed.Length, expected.Length);
        if (maxLen == 0) return 0;

        double accuracy = 1.0 - (double)distance / maxLen;
        return Math.Max(0, accuracy * 100.0);
    }

    private static int LevenshteinDistance(string a, string b)
    {
        int m = a.Length, n = b.Length;
        var d = new int[m + 1, n + 1];
        for (int i = 0; i <= m; i++) d[i, 0] = i;
        for (int j = 0; j <= n; j++) d[0, j] = j;
        for (int i = 1; i <= m; i++)
        {
            for (int j = 1; j <= n; j++)
            {
                int cost = a[i - 1] == b[j - 1] ? 0 : 1;
                d[i, j] = Math.Min(Math.Min(d[i - 1, j] + 1, d[i, j - 1] + 1), d[i - 1, j - 1] + cost);
            }
        }
        return d[m, n];
    }

    private static string GenerateChallengeWord(GameState state, string nodeType, int nodeIndex)
    {
        var usedWords = new HashSet<string>();
        return WordPool.WordForEnemy(
            state.RngSeed, state.Day, nodeType, nodeIndex, usedWords, state.LessonId);
    }
}
