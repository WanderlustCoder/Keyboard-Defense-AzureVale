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
    /// <summary>
    /// Quest catalog keyed by stable quest identifier.
    /// </summary>
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
        ["supply_run"] = new("Supply Run", "Gather 20 wood from resource nodes.",
            "economy", QuestCondition.TypeWords(20),
            new() { ["wood"] = 15, ["gold"] = 10 }),
        ["stone_collector"] = new("Stone Collector", "Gather 15 stone from resource nodes.",
            "economy", QuestCondition.TypeWords(30),
            new() { ["stone"] = 10, ["gold"] = 10 }),
        ["feast_preparation"] = new("Feast Preparation", "Gather 10 food for the kingdom.",
            "economy", QuestCondition.TypeWords(40),
            new() { ["food"] = 10, ["gold"] = 15 }),
        ["defender_of_the_realm"] = new("Defender of the Realm", "Defeat 25 enemies.",
            "combat", QuestCondition.DefeatEnemies(25),
            new() { ["gold"] = 60, ["skill_point"] = 2, ["wood"] = 20, ["stone"] = 10 }),
        ["wave_defender"] = new("Wave Defender", "Survive 3 wave assaults.",
            "combat", QuestCondition.SurviveWaves(3),
            new() { ["gold"] = 50, ["wood"] = 15, ["stone"] = 15, ["food"] = 10 }),
        ["speed_demon"] = new("Speed Demon", "Reach 80 WPM in combat.",
            "typing", QuestCondition.TypeWords(50),
            new() { ["gold"] = 35, ["skill_point"] = 1 }),
        ["perfect_accuracy"] = new("Perfect Accuracy", "Complete an encounter with 100% accuracy.",
            "typing", QuestCondition.ReachCombo(10),
            new() { ["gold"] = 40, ["skill_point"] = 2 }),
        ["grove_champion"] = new("Grove Champion", "Defeat the Grove Guardian.",
            "combat", QuestCondition.DefeatBoss("grove_guardian"),
            new() { ["gold"] = 100, ["skill_point"] = 3, ["wood"] = 30 }),
        ["mountain_conqueror"] = new("Mountain Conqueror", "Defeat the Mountain King.",
            "combat", QuestCondition.DefeatBoss("mountain_king"),
            new() { ["gold"] = 150, ["skill_point"] = 3, ["stone"] = 30 }),
        ["night_owl"] = new("Night Owl", "Survive 5 nights.",
            "combat", QuestCondition.SurviveNight(5),
            new() { ["gold"] = 75, ["skill_point"] = 2 }),
        ["architect"] = new("Architect", "Build 5 different building types.",
            "economy", QuestCondition.BuildStructure(null, 15),
            new() { ["gold"] = 60, ["wood"] = 20, ["stone"] = 20 }),
        ["cartographer"] = new("Cartographer", "Discover 150 map tiles.",
            "exploration", QuestCondition.DiscoverTiles(150),
            new() { ["gold"] = 50, ["skill_point"] = 2 }),
        ["wave_master"] = new("Wave Master", "Survive 10 wave assaults.",
            "combat", QuestCondition.SurviveWaves(10),
            new() { ["gold"] = 100, ["skill_point"] = 3, ["wood"] = 25, ["stone"] = 25, ["food"] = 15 }),
    };

    /// <summary>
    /// Returns the quest definition for a quest id, or null when the id is not registered.
    /// </summary>
    public static QuestDef? GetQuest(string questId) => Registry.GetValueOrDefault(questId);

    /// <summary>
    /// Returns true when the specified quest id has already been completed in the current run.
    /// </summary>
    public static bool IsComplete(GameState state, string questId)
        => state.CompletedQuests.Contains(questId);

    /// <summary>
    /// Returns all quest ids that are still active because they are not yet completed.
    /// </summary>
    public static List<string> GetActiveQuests(GameState state)
    {
        return Registry.Keys
            .Where(id => !state.CompletedQuests.Contains(id))
            .ToList();
    }

    /// <summary>
    /// Completes a quest lifecycle step by validating the quest, marking completion, and granting rewards.
    /// </summary>
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
            state.Gold = Math.Min(state.Gold + gold, Balance.SimBalance.GoldCap);
            rewards.Add($"+{gold} gold");
        }
        if (quest.Rewards.TryGetValue("skill_point", out int sp))
        {
            state.SkillPoints += sp;
            rewards.Add($"+{sp} skill point(s)");
        }

        // Resource rewards
        foreach (var (resource, amount) in quest.Rewards)
        {
            if (resource is "gold" or "skill_point") continue; // already handled
            int current = state.Resources.GetValueOrDefault(resource, 0);
            state.Resources[resource] = current + amount;
            rewards.Add($"+{amount} {resource}");
        }

        return new()
        {
            ["ok"] = true,
            ["message"] = $"Quest complete: {quest.Name}! Rewards: {string.Join(", ", rewards)}"
        };
    }
}

/// <summary>
/// Immutable quest definition containing identity, completion condition, and reward payload.
/// </summary>
public record QuestDef(string Name, string Description, string Category,
    QuestCondition Condition, Dictionary<string, int> Rewards);

/// <summary>
/// Immutable quest condition descriptor used by the quest evaluation pipeline.
/// </summary>
public record QuestCondition(string Type, string? Target, int Value)
{
    /// <summary>
    /// Creates a build-condition quest requirement for a structure type and count target.
    /// </summary>
    public static QuestCondition BuildStructure(string? type, int count) => new("build", type, count);

    /// <summary>
    /// Creates a survive-night quest requirement for the required number of nights.
    /// </summary>
    public static QuestCondition SurviveNight(int count) => new("survive_night", null, count);

    /// <summary>
    /// Creates an exploration quest requirement for discovered tile count.
    /// </summary>
    public static QuestCondition DiscoverTiles(int count) => new("discover", null, count);

    /// <summary>
    /// Creates a typing quest requirement for successfully typed word count.
    /// </summary>
    public static QuestCondition TypeWords(int count) => new("type_words", null, count);

    /// <summary>
    /// Creates a combo quest requirement for reaching a combo threshold.
    /// </summary>
    public static QuestCondition ReachCombo(int combo) => new("combo", null, combo);

    /// <summary>
    /// Creates a boss quest requirement for defeating a specific boss or any boss.
    /// </summary>
    public static QuestCondition DefeatBoss(string? bossId) => new("defeat_boss", bossId, 1);

    /// <summary>
    /// Creates a combat quest requirement for defeating a total number of enemies.
    /// </summary>
    public static QuestCondition DefeatEnemies(int count) => new("defeat_enemies", null, count);

    /// <summary>
    /// Creates a wave quest requirement for surviving a number of assault waves.
    /// </summary>
    public static QuestCondition SurviveWaves(int count) => new("survive_waves", null, count);
}
