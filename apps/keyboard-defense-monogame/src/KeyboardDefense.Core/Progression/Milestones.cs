using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Progression;

/// <summary>
/// Milestone tracking for achievements and progression.
/// Ported from sim/milestones.gd.
/// </summary>
public static class Milestones
{
    public static readonly Dictionary<string, MilestoneDef> Registry = new()
    {
        ["first_blood"] = new("First Blood", "Defeat your first enemy.", "combat"),
        ["combo_5"] = new("Getting Warmed Up", "Reach a 5-hit combo.", "typing"),
        ["combo_20"] = new("Combo King", "Reach a 20-hit combo.", "typing"),
        ["combo_50"] = new("Unstoppable", "Reach a 50-hit combo.", "typing"),
        ["day_7"] = new("Survivor", "Survive 7 days.", "survival"),
        ["day_14"] = new("Veteran", "Survive 14 days.", "survival"),
        ["day_30"] = new("Legend", "Survive 30 days.", "survival"),
        ["explore_25"] = new("Cartographer", "Discover 25% of the map.", "exploration"),
        ["explore_50"] = new("Explorer", "Discover 50% of the map.", "exploration"),
        ["explore_100"] = new("Completionist", "Discover the entire map.", "exploration"),
        ["build_10"] = new("Architect", "Build 10 structures.", "economy"),
        ["gold_100"] = new("Wealthy", "Accumulate 100 gold.", "economy"),
        ["perfect_night"] = new("Flawless", "Complete a night with 100% accuracy.", "typing"),
        ["all_bosses"] = new("Champion", "Defeat all bosses.", "combat"),
    };

    public static MilestoneDef? GetMilestone(string id) => Registry.GetValueOrDefault(id);

    public static List<string> CheckNewMilestones(GameState state)
    {
        var newMilestones = new List<string>();

        foreach (var (id, def) in Registry)
        {
            if (state.Milestones.Contains(id)) continue;
            if (IsMilestoneEarned(state, id))
            {
                state.Milestones.Add(id);
                newMilestones.Add(id);
            }
        }

        return newMilestones;
    }

    private static bool IsMilestoneEarned(GameState state, string id) => id switch
    {
        "first_blood" => state.EnemiesDefeated > 0,
        "combo_5" => state.MaxComboEver >= 5,
        "combo_20" => state.MaxComboEver >= 20,
        "combo_50" => state.MaxComboEver >= 50,
        "day_7" => state.Day >= 7,
        "day_14" => state.Day >= 14,
        "day_30" => state.Day >= 30,
        "explore_25" => GetExplorationPercent(state) >= 0.25,
        "explore_50" => GetExplorationPercent(state) >= 0.50,
        "explore_100" => GetExplorationPercent(state) >= 1.0,
        "build_10" => state.Structures.Count >= 10,
        "gold_100" => state.Gold >= 100,
        "all_bosses" => state.BossesDefeated.Count >= 4,
        _ => false,
    };

    private static double GetExplorationPercent(GameState state)
    {
        int total = state.MapW * state.MapH;
        return total > 0 ? (double)state.Discovered.Count / total : 0;
    }
}

public record MilestoneDef(string Name, string Description, string Category);
