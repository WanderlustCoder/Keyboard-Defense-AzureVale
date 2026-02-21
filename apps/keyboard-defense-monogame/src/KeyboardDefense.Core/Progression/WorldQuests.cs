using System;
using System.Collections.Generic;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Progression;

/// <summary>
/// Dynamic quest generation for the open world.
/// Generates quests based on world state and progress,
/// tracks completion conditions, and awards rewards.
/// </summary>
public static class WorldQuests
{
    /// <summary>
    /// Generate available quests based on current world state.
    /// Returns quest IDs that haven't been completed yet.
    /// </summary>
    public static List<string> GetAvailableQuests(GameState state)
    {
        var available = new List<string>();

        foreach (var (questId, _) in Quests.Registry)
        {
            if (state.CompletedQuests.Contains(questId)) continue;
            if (IsPreconditionMet(state, questId))
                available.Add(questId);
        }

        return available;
    }

    /// <summary>
    /// Check if quest preconditions are met (day requirement, previous quest completion, etc.)
    /// </summary>
    public static bool IsPreconditionMet(GameState state, string questId)
    {
        return questId switch
        {
            "first_tower" => true, // always available
            "first_night" => state.Day >= 1,
            "explorer" => true,
            "word_smith" => true,
            "combo_master" => state.EnemiesDefeated >= 5,
            "kingdom_builder" => state.CompletedQuests.Contains("first_tower"),
            "boss_slayer" => state.Day >= 3,
            "supply_run" => state.Day >= 2,
            "stone_collector" => state.Day >= 3,
            "feast_preparation" => state.Day >= 4,
            "defender_of_the_realm" => state.EnemiesDefeated >= 10,
            _ => true,
        };
    }

    /// <summary>
    /// Get progress toward a quest as (current, target).
    /// </summary>
    public static (int Current, int Target) GetProgress(GameState state, string questId)
    {
        var def = Quests.GetQuest(questId);
        if (def == null) return (0, 0);

        var condition = def.Condition;
        int current = condition.Type switch
        {
            "build" => CountStructures(state, condition.Target),
            "survive_night" => state.Day,
            "discover" => state.Discovered.Count,
            "type_words" => GetWordsTyped(state),
            "combo" => state.MaxComboEver,
            "defeat_boss" => condition.Target != null
                ? (state.BossesDefeated.Contains(condition.Target) ? 1 : 0)
                : state.BossesDefeated.Count,
            "defeat_enemies" => state.EnemiesDefeated,
            "survive_waves" => state.WavesSurvived,
            _ => 0,
        };

        return (Math.Min(current, condition.Value), condition.Value);
    }

    /// <summary>
    /// Check all active quests and auto-complete any that are finished.
    /// Returns events for completed quests.
    /// </summary>
    public static List<string> CheckCompletions(GameState state)
    {
        var events = new List<string>();
        var active = Quests.GetActiveQuests(state);

        foreach (var questId in active)
        {
            var (current, target) = GetProgress(state, questId);
            if (target <= 0 || current < target) continue;

            var result = Quests.CompleteQuest(state, questId);
            if (Convert.ToBoolean(result.GetValueOrDefault("ok", false)))
            {
                var def = Quests.GetQuest(questId);
                string message = result.GetValueOrDefault("message")?.ToString()
                    ?? $"Quest complete: {def?.Name ?? questId}!";
                events.Add(message);
            }
        }

        return events;
    }

    private static int CountStructures(GameState state, string? type)
    {
        if (string.IsNullOrEmpty(type))
            return state.Structures.Count;

        int count = 0;
        foreach (var (_, structType) in state.Structures)
        {
            if (structType == type)
                count++;
        }
        return count;
    }

    private static int GetWordsTyped(GameState state)
    {
        if (state.TypingMetrics.TryGetValue("battle_words_typed", out var val))
            return Convert.ToInt32(val);
        return 0;
    }
}
