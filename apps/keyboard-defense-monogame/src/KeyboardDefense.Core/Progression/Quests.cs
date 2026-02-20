using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Progression;

/// <summary>
/// Quest tracking and completion system.
/// Ported from sim/quests.gd.
/// </summary>
public static class Quests
{
    public static readonly Dictionary<string, QuestDef> Registry = new()
    {
        ["first_tower"] = new("First Defense", "Build your first tower.",
            "tutorial", QuestCondition.BuildStructure("tower", 1),
            new() { ["gold"] = 10 }),
        ["first_night"] = new("Survive the Night", "Survive your first night battle.",
            "tutorial", QuestCondition.SurviveNight(1),
            new() { ["gold"] = 15 }),
        ["explorer"] = new("Explorer", "Discover 50 map tiles.",
            "exploration", QuestCondition.DiscoverTiles(50),
            new() { ["gold"] = 25 }),
        ["word_smith"] = new("Word Smith", "Type 100 words correctly.",
            "typing", QuestCondition.TypeWords(100),
            new() { ["gold"] = 20, ["skill_point"] = 1 }),
        ["combo_master"] = new("Combo Master", "Reach a 20-hit combo.",
            "typing", QuestCondition.ReachCombo(20),
            new() { ["gold"] = 30 }),
        ["kingdom_builder"] = new("Kingdom Builder", "Build 10 structures.",
            "economy", QuestCondition.BuildStructure(null, 10),
            new() { ["gold"] = 40, ["skill_point"] = 1 }),
        ["boss_slayer"] = new("Boss Slayer", "Defeat any boss.",
            "combat", QuestCondition.DefeatBoss(null),
            new() { ["gold"] = 50, ["skill_point"] = 2 }),
    };

    public static QuestDef? GetQuest(string questId) => Registry.GetValueOrDefault(questId);

    public static bool IsComplete(GameState state, string questId)
        => state.CompletedQuests.Contains(questId);

    public static List<string> GetActiveQuests(GameState state)
    {
        return Registry.Keys
            .Where(id => !state.CompletedQuests.Contains(id))
            .ToList();
    }

    public static Dictionary<string, object> CompleteQuest(GameState state, string questId)
    {
        if (!Registry.TryGetValue(questId, out var quest))
            return new() { ["ok"] = false, ["error"] = "Unknown quest." };
        if (state.CompletedQuests.Contains(questId))
            return new() { ["ok"] = false, ["error"] = "Already completed." };

        state.CompletedQuests.Add(questId);

        // Apply rewards
        var rewards = new List<string>();
        if (quest.Rewards.TryGetValue("gold", out int gold))
        {
            state.Gold += gold;
            rewards.Add($"+{gold} gold");
        }
        if (quest.Rewards.TryGetValue("skill_point", out int sp))
        {
            state.SkillPoints += sp;
            rewards.Add($"+{sp} skill point(s)");
        }

        return new()
        {
            ["ok"] = true,
            ["message"] = $"Quest complete: {quest.Name}! Rewards: {string.Join(", ", rewards)}"
        };
    }
}

public record QuestDef(string Name, string Description, string Category,
    QuestCondition Condition, Dictionary<string, int> Rewards);

public record QuestCondition(string Type, string? Target, int Value)
{
    public static QuestCondition BuildStructure(string? type, int count) => new("build", type, count);
    public static QuestCondition SurviveNight(int count) => new("survive_night", null, count);
    public static QuestCondition DiscoverTiles(int count) => new("discover", null, count);
    public static QuestCondition TypeWords(int count) => new("type_words", null, count);
    public static QuestCondition ReachCombo(int combo) => new("combo", null, combo);
    public static QuestCondition DefeatBoss(string? bossId) => new("defeat_boss", bossId, 1);
}
