using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.World;

/// <summary>
/// NPC interaction system: detect adjacent NPCs, trigger dialogue,
/// offer quests, and process quest completion.
/// </summary>
public static class NpcInteraction
{
    public const int InteractionRadius = 1;

    /// <summary>
    /// Try to interact with an NPC adjacent to the player.
    /// Returns interaction info or null if no NPC nearby.
    /// </summary>
    public static Dictionary<string, object>? TryInteract(GameState state)
    {
        if (state.ActivityMode != "exploration") return null;

        var playerPos = state.PlayerPos;
        Dictionary<string, object>? closestNpc = null;
        int closestDist = int.MaxValue;

        foreach (var npc in state.Npcs)
        {
            if (npc.GetValueOrDefault("pos") is not GridPoint npcPos) continue;
            int dist = playerPos.ManhattanDistance(npcPos);
            if (dist <= InteractionRadius && dist < closestDist)
            {
                closestDist = dist;
                closestNpc = npc;
            }
        }

        if (closestNpc == null) return null;

        string npcType = closestNpc.GetValueOrDefault("type")?.ToString() ?? "unknown";
        string npcName = closestNpc.GetValueOrDefault("name")?.ToString() ?? "Stranger";

        return npcType switch
        {
            "trainer" => BuildTrainerInteraction(state, npcName),
            "merchant" => BuildMerchantInteraction(state, npcName),
            "quest_giver" => BuildQuestGiverInteraction(state, npcName),
            _ => new Dictionary<string, object>
            {
                ["speaker"] = npcName,
                ["lines"] = new List<string> { "..." },
            },
        };
    }

    private static Dictionary<string, object> BuildTrainerInteraction(GameState state, string name)
    {
        var lines = new List<string>();
        lines.Add($"{name}: Welcome, defender! I can help you improve your typing skills.");

        var recommendedLessons = Data.LessonsData.LessonIds();
        if (recommendedLessons.Count > 0)
        {
            string current = Data.LessonsData.LessonLabel(state.LessonId);
            lines.Add($"Current lesson: {current}");
            lines.Add("Visit the library to practice your lessons.");
        }

        // Offer quests
        var availableQuests = GetAvailableQuestsForNpc(state, "trainer");
        if (availableQuests.Count > 0)
        {
            lines.Add($"I have {availableQuests.Count} task{(availableQuests.Count == 1 ? "" : "s")} for you:");
            foreach (var q in availableQuests)
            {
                var def = Quests.GetQuest(q);
                if (def != null)
                    lines.Add($"  - {def.Name}: {def.Description}");
            }
        }

        return new Dictionary<string, object>
        {
            ["speaker"] = name,
            ["npc_type"] = "trainer",
            ["lines"] = lines,
            ["quests"] = availableQuests,
        };
    }

    private static Dictionary<string, object> BuildMerchantInteraction(GameState state, string name)
    {
        var lines = new List<string>
        {
            $"{name}: Greetings, traveler! Looking to trade?",
            $"You have {state.Gold} gold.",
        };

        var resources = state.Resources;
        if (resources.Count > 0)
        {
            lines.Add("Your resources:");
            foreach (var (key, amount) in resources)
            {
                if (amount > 0)
                    lines.Add($"  {key}: {amount}");
            }
        }

        return new Dictionary<string, object>
        {
            ["speaker"] = name,
            ["npc_type"] = "merchant",
            ["lines"] = lines,
        };
    }

    private static Dictionary<string, object> BuildQuestGiverInteraction(GameState state, string name)
    {
        var lines = new List<string>();
        lines.Add($"{name}: The kingdom needs your help, defender!");

        var availableQuests = GetAvailableQuestsForNpc(state, "quest_giver");

        if (availableQuests.Count > 0)
        {
            lines.Add("Available quests:");
            foreach (var q in availableQuests)
            {
                var def = Quests.GetQuest(q);
                if (def != null)
                    lines.Add($"  - {def.Name}: {def.Description}");
            }
        }
        else
        {
            lines.Add("You've completed all available tasks. Well done!");
        }

        // Check for completable quests
        var completable = GetCompletableQuests(state);
        if (completable.Count > 0)
        {
            lines.Add("Ready to turn in:");
            foreach (var q in completable)
            {
                var def = Quests.GetQuest(q);
                if (def != null)
                    lines.Add($"  - {def.Name} (COMPLETE!)");
            }
        }

        return new Dictionary<string, object>
        {
            ["speaker"] = name,
            ["npc_type"] = "quest_giver",
            ["lines"] = lines,
            ["quests"] = availableQuests,
            ["completable"] = completable,
        };
    }

    /// <summary>
    /// Complete all completable quests and return events.
    /// </summary>
    public static List<string> CompleteReadyQuests(GameState state)
    {
        var events = new List<string>();
        var completable = GetCompletableQuests(state);

        foreach (var questId in completable)
        {
            var result = Quests.CompleteQuest(state, questId);
            if (Convert.ToBoolean(result.GetValueOrDefault("ok", false)))
            {
                var def = Quests.GetQuest(questId);
                string name = def?.Name ?? questId;
                events.Add($"Quest complete: {name}!");

                // Announce rewards
                if (def?.Rewards != null)
                {
                    foreach (var (resource, amount) in def.Rewards)
                        events.Add($"  +{amount} {resource}");
                }
            }
        }

        return events;
    }

    private static List<string> GetAvailableQuestsForNpc(GameState state, string npcType)
    {
        var active = Quests.GetActiveQuests(state);
        var result = new List<string>();

        foreach (var questId in active)
        {
            var def = Quests.GetQuest(questId);
            if (def == null) continue;

            // Route quests to appropriate NPCs
            bool matches = npcType switch
            {
                "trainer" => def.Category is "typing" or "combat" or "tutorial",
                "quest_giver" => def.Category is "exploration" or "building" or "boss" or "economy" or "tutorial",
                "merchant" => def.Category is "economy",
                _ => false,
            };

            if (matches)
                result.Add(questId);
        }

        return result;
    }

    private static List<string> GetCompletableQuests(GameState state)
    {
        var active = Quests.GetActiveQuests(state);
        var completable = new List<string>();

        foreach (var questId in active)
        {
            var (current, target) = WorldQuests.GetProgress(state, questId);
            if (target > 0 && current >= target)
                completable.Add(questId);
        }

        return completable;
    }
}
