using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class QuestsSystemTests
{
    [Fact]
    public void GetQuest_KnownQuest_ReturnsExpectedDefinition()
    {
        var quest = Assert.IsType<QuestDef>(Quests.GetQuest("first_tower"));

        Assert.Equal("First Defense", quest.Name);
        Assert.Equal("Build your first tower.", quest.Description);
        Assert.Equal("tutorial", quest.Category);
        Assert.Equal(new QuestCondition("build", "tower", 1), quest.Condition);
        Assert.Equal(10, quest.Rewards["gold"]);
    }

    [Fact]
    public void GetQuest_UnknownQuest_ReturnsNull()
    {
        Assert.Null(Quests.GetQuest("quest_that_does_not_exist"));
    }

    [Fact]
    public void GetActiveQuests_DefaultState_ContainsAllRegisteredQuests()
    {
        var state = DefaultState.Create();

        var active = Quests.GetActiveQuests(state);

        Assert.Equal(Quests.Registry.Count, active.Count);
        foreach (var questId in Quests.Registry.Keys)
            Assert.Contains(questId, active);
    }

    [Fact]
    public void CompleteQuest_Success_TransitionsQuestFromActiveToCompleted()
    {
        var state = DefaultState.Create();
        Assert.Contains("first_tower", Quests.GetActiveQuests(state));

        var result = Quests.CompleteQuest(state, "first_tower");
        var message = Assert.IsType<string>(result["message"]);

        Assert.True(Convert.ToBoolean(result["ok"]));
        Assert.Contains("first_tower", state.CompletedQuests);
        Assert.DoesNotContain("first_tower", Quests.GetActiveQuests(state));
        Assert.Contains("Quest complete: First Defense!", message);
    }

    [Fact]
    public void IsComplete_ReflectsQuestCompletionState()
    {
        var state = DefaultState.Create();

        Assert.False(Quests.IsComplete(state, "first_tower"));

        state.CompletedQuests.Add("first_tower");

        Assert.True(Quests.IsComplete(state, "first_tower"));
    }

    [Fact]
    public void CompleteQuest_UnknownQuest_ReturnsErrorAndDoesNotMutateState()
    {
        var state = DefaultState.Create();
        int goldBefore = state.Gold;
        int skillPointsBefore = state.SkillPoints;
        int completedBefore = state.CompletedQuests.Count;
        var resourcesBefore = SnapshotResources(state);

        var result = Quests.CompleteQuest(state, "unknown_quest");

        Assert.False(Convert.ToBoolean(result["ok"]));
        Assert.Equal("Unknown quest.", result["error"]);
        Assert.Equal(goldBefore, state.Gold);
        Assert.Equal(skillPointsBefore, state.SkillPoints);
        Assert.Equal(completedBefore, state.CompletedQuests.Count);

        foreach (var (resource, amount) in resourcesBefore)
            Assert.Equal(amount, state.Resources.GetValueOrDefault(resource, 0));
    }

    [Fact]
    public void CompleteQuest_AlreadyCompletedQuest_ReturnsErrorAndDoesNotPayTwice()
    {
        var state = DefaultState.Create();

        var first = Quests.CompleteQuest(state, "first_tower");
        Assert.True(Convert.ToBoolean(first["ok"]));

        int goldAfterFirst = state.Gold;
        int completedAfterFirst = state.CompletedQuests.Count;

        var second = Quests.CompleteQuest(state, "first_tower");

        Assert.False(Convert.ToBoolean(second["ok"]));
        Assert.Equal("Already completed.", second["error"]);
        Assert.Equal(goldAfterFirst, state.Gold);
        Assert.Equal(completedAfterFirst, state.CompletedQuests.Count);
    }

    [Fact]
    public void CompleteQuest_GoldRewardQuest_AppliesGoldOnly()
    {
        var state = DefaultState.Create();
        var quest = Assert.IsType<QuestDef>(Quests.GetQuest("first_tower"));
        int goldBefore = state.Gold;
        int skillPointsBefore = state.SkillPoints;

        var result = Quests.CompleteQuest(state, "first_tower");
        var message = Assert.IsType<string>(result["message"]);

        Assert.True(Convert.ToBoolean(result["ok"]));
        Assert.Equal(goldBefore + quest.Rewards["gold"], state.Gold);
        Assert.Equal(skillPointsBefore, state.SkillPoints);
        Assert.Contains($"+{quest.Rewards["gold"]} gold", message);
    }

    [Fact]
    public void CompleteQuest_GoldAndSkillRewardQuest_AppliesBothRewards()
    {
        var state = DefaultState.Create();
        var quest = Assert.IsType<QuestDef>(Quests.GetQuest("word_smith"));
        int goldBefore = state.Gold;
        int skillPointsBefore = state.SkillPoints;

        var result = Quests.CompleteQuest(state, "word_smith");
        var message = Assert.IsType<string>(result["message"]);

        Assert.True(Convert.ToBoolean(result["ok"]));
        Assert.Equal(goldBefore + quest.Rewards["gold"], state.Gold);
        Assert.Equal(skillPointsBefore + quest.Rewards["skill_point"], state.SkillPoints);
        Assert.Contains($"+{quest.Rewards["gold"]} gold", message);
        Assert.Contains($"+{quest.Rewards["skill_point"]} skill point(s)", message);
    }

    [Fact]
    public void CompleteQuest_ResourceRewardQuest_AccumulatesResourceAndGoldRewards()
    {
        var state = DefaultState.Create();
        var quest = Assert.IsType<QuestDef>(Quests.GetQuest("wave_defender"));

        state.Resources["wood"] = 4;
        state.Resources["stone"] = 7;
        state.Resources["food"] = 2;

        int goldBefore = state.Gold;
        int woodBefore = state.Resources["wood"];
        int stoneBefore = state.Resources["stone"];
        int foodBefore = state.Resources["food"];

        var result = Quests.CompleteQuest(state, "wave_defender");
        var message = Assert.IsType<string>(result["message"]);

        Assert.True(Convert.ToBoolean(result["ok"]));
        Assert.Equal(goldBefore + quest.Rewards["gold"], state.Gold);
        Assert.Equal(woodBefore + quest.Rewards["wood"], state.Resources["wood"]);
        Assert.Equal(stoneBefore + quest.Rewards["stone"], state.Resources["stone"]);
        Assert.Equal(foodBefore + quest.Rewards["food"], state.Resources["food"]);
        Assert.Contains($"+{quest.Rewards["wood"]} wood", message);
        Assert.Contains($"+{quest.Rewards["stone"]} stone", message);
        Assert.Contains($"+{quest.Rewards["food"]} food", message);
    }

    [Fact]
    public void QuestConditions_RegistryAndFactoryMethods_AreConsistent()
    {
        var supportedTypes = new HashSet<string>
        {
            "build",
            "survive_night",
            "discover",
            "type_words",
            "combo",
            "defeat_boss",
            "defeat_enemies",
            "survive_waves",
        };

        foreach (var (questId, quest) in Quests.Registry)
        {
            Assert.Contains(quest.Condition.Type, supportedTypes);
            Assert.True(quest.Condition.Value > 0, $"Quest '{questId}' has non-positive condition target.");
        }

        Assert.Equal(new QuestCondition("build", "tower", 2), QuestCondition.BuildStructure("tower", 2));
        Assert.Equal(new QuestCondition("survive_night", null, 3), QuestCondition.SurviveNight(3));
        Assert.Equal(new QuestCondition("discover", null, 20), QuestCondition.DiscoverTiles(20));
        Assert.Equal(new QuestCondition("type_words", null, 40), QuestCondition.TypeWords(40));
        Assert.Equal(new QuestCondition("combo", null, 15), QuestCondition.ReachCombo(15));
        Assert.Equal(new QuestCondition("defeat_boss", "mountain_king", 1), QuestCondition.DefeatBoss("mountain_king"));
        Assert.Equal(new QuestCondition("defeat_enemies", null, 12), QuestCondition.DefeatEnemies(12));
        Assert.Equal(new QuestCondition("survive_waves", null, 5), QuestCondition.SurviveWaves(5));
    }

    private static Dictionary<string, int> SnapshotResources(GameState state)
    {
        var snapshot = new Dictionary<string, int>();
        foreach (var resource in GameState.ResourceKeys)
            snapshot[resource] = state.Resources.GetValueOrDefault(resource, 0);

        return snapshot;
    }
}
