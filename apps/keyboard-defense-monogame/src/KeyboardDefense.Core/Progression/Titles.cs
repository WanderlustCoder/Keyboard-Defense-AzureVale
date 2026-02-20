using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Progression;

/// <summary>
/// Title system for player display names.
/// Ported from sim/titles.gd.
/// </summary>
public static class Titles
{
    public static readonly Dictionary<string, TitleDef> Registry = new()
    {
        ["novice"] = new("Novice", "Starting title.", null),
        ["defender"] = new("Defender", "Survived 7 days.", "day_7"),
        ["veteran"] = new("Veteran", "Survived 14 days.", "day_14"),
        ["legend"] = new("Legend", "Survived 30 days.", "day_30"),
        ["wordsmith"] = new("Wordsmith", "Typed 500 words correctly.", "type_500"),
        ["speedster"] = new("Speedster", "Achieved 80+ WPM.", "wpm_80"),
        ["perfectionist"] = new("Perfectionist", "100% accuracy in a night.", "perfect_night"),
        ["explorer"] = new("Explorer", "Discovered 50% of the map.", "explore_50"),
        ["champion"] = new("Champion", "Defeated all bosses.", "all_bosses"),
        ["architect"] = new("Architect", "Built 15 structures.", "build_15"),
    };

    public static TitleDef? GetTitle(string titleId) => Registry.GetValueOrDefault(titleId);

    public static bool IsValidTitle(string titleId) => Registry.ContainsKey(titleId);

    public static List<string> GetUnlockedTitles(GameState state)
    {
        return Registry.Keys
            .Where(id => IsTitleUnlocked(state, id))
            .ToList();
    }

    public static bool IsTitleUnlocked(GameState state, string titleId)
    {
        if (!Registry.TryGetValue(titleId, out var title)) return false;
        if (title.RequiredMilestone == null) return true; // Default title
        return state.Milestones.Contains(title.RequiredMilestone);
    }

    public static bool EquipTitle(GameState state, string titleId)
    {
        if (!IsTitleUnlocked(state, titleId)) return false;
        state.ActiveTitle = titleId;
        return true;
    }

    public static string GetDisplayTitle(GameState state)
    {
        if (string.IsNullOrEmpty(state.ActiveTitle)) return "Novice";
        return Registry.GetValueOrDefault(state.ActiveTitle)?.Name ?? "Novice";
    }
}

public record TitleDef(string Name, string Description, string? RequiredMilestone);
