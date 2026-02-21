using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class QuestSystemTests
{
    [Fact]
    public void Registry_HasAtLeastTwelveEntries()
    {
        Assert.True(Quests.Registry.Count >= 12);
    }

    [Fact]
    public void GetQuest_KnownQuestIds_ReturnExpectedDefinitions()
    {
        var firstTower = Quests.GetQuest("first_tower");
        var bossSlayer = Quests.GetQuest("boss_slayer");
        var waveDefender = Quests.GetQuest("wave_defender");

        Assert.NotNull(firstTower);
        Assert.Equal("First Defense", firstTower!.Name);
        Assert.Equal("tutorial", firstTower.Category);

        Assert.NotNull(bossSlayer);
        Assert.Equal("Boss Slayer", bossSlayer!.Name);
        Assert.Equal("defeat_boss", bossSlayer.Condition.Type);

        Assert.NotNull(waveDefender);
        Assert.Equal("Wave Defender", waveDefender!.Name);
        Assert.Equal("survive_waves", waveDefender.Condition.Type);
    }

    [Fact]
    public void GetQuest_UnknownId_ReturnsNull()
    {
        var quest = Quests.GetQuest("unknown_quest_id");
        Assert.Null(quest);
    }

    [Fact]
    public void IsComplete_DefaultState_ReturnsFalse()
    {
        var state = DefaultState.Create();
        Assert.False(Quests.IsComplete(state, "first_tower"));
    }

    [Fact]
    public void IsComplete_AfterCompleteQuest_ReturnsTrue()
    {
        var state = DefaultState.Create();

        Quests.CompleteQuest(state, "first_tower");

        Assert.True(Quests.IsComplete(state, "first_tower"));
    }

    [Fact]
    public void GetActiveQuests_DefaultState_MatchesRegistryKeys()
    {
        var state = DefaultState.Create();

        var active = Quests.GetActiveQuests(state);

        Assert.Equal(Quests.Registry.Count, active.Count);
        Assert.Equal(
            Quests.Registry.Keys.OrderBy(id => id),
            active.OrderBy(id => id));
    }

    [Fact]
    public void GetActiveQuests_AfterCompletion_ExcludesCompletedQuestAndCountDecrements()
    {
        var state = DefaultState.Create();
        var before = Quests.GetActiveQuests(state);

        Quests.CompleteQuest(state, "first_tower");

        var after = Quests.GetActiveQuests(state);
        Assert.Equal(before.Count - 1, after.Count);
        Assert.DoesNotContain("first_tower", after);
    }

    [Fact]
    public void CompleteQuest_GoldReward_AppliesExactAmount()
    {
        var state = DefaultState.Create();
        var quest = Quests.GetQuest("first_tower")!;
        int goldBefore = state.Gold;

        var result = Quests.CompleteQuest(state, "first_tower");

        Assert.True((bool)result["ok"]);
        Assert.Equal(goldBefore + quest.Rewards["gold"], state.Gold);
    }

    [Fact]
    public void CompleteQuest_SkillPointReward_AppliesExactAmount()
    {
        var state = DefaultState.Create();
        var quest = Quests.GetQuest("word_smith")!;
        int spBefore = state.SkillPoints;

        var result = Quests.CompleteQuest(state, "word_smith");

        Assert.True((bool)result["ok"]);
        Assert.Equal(spBefore + quest.Rewards["skill_point"], state.SkillPoints);
    }

    [Fact]
    public void CompleteQuest_ResourceRewards_AppliesWoodStoneFoodExactAmounts()
    {
        var state = DefaultState.Create();
        var woodQuest = Quests.GetQuest("supply_run")!;
        var stoneQuest = Quests.GetQuest("stone_collector")!;
        var foodQuest = Quests.GetQuest("feast_preparation")!;

        int woodBefore = state.Resources.GetValueOrDefault("wood", 0);
        var woodResult = Quests.CompleteQuest(state, "supply_run");
        Assert.True((bool)woodResult["ok"]);
        Assert.Equal(woodBefore + woodQuest.Rewards["wood"], state.Resources["wood"]);

        int stoneBefore = state.Resources.GetValueOrDefault("stone", 0);
        var stoneResult = Quests.CompleteQuest(state, "stone_collector");
        Assert.True((bool)stoneResult["ok"]);
        Assert.Equal(stoneBefore + stoneQuest.Rewards["stone"], state.Resources["stone"]);

        int foodBefore = state.Resources.GetValueOrDefault("food", 0);
        var foodResult = Quests.CompleteQuest(state, "feast_preparation");
        Assert.True((bool)foodResult["ok"]);
        Assert.Equal(foodBefore + foodQuest.Rewards["food"], state.Resources["food"]);
    }

    [Fact]
    public void CompleteQuest_DuplicateCompletion_ReturnsAlreadyCompletedError()
    {
        var state = DefaultState.Create();
        var quest = Quests.GetQuest("first_tower")!;
        int startingGold = state.Gold;

        var firstResult = Quests.CompleteQuest(state, "first_tower");
        int goldAfterFirst = state.Gold;
        var secondResult = Quests.CompleteQuest(state, "first_tower");

        Assert.True((bool)firstResult["ok"]);
        Assert.False((bool)secondResult["ok"]);
        Assert.Equal("Already completed.", secondResult["error"]);
        Assert.Equal(goldAfterFirst, state.Gold);
        Assert.Equal(1, state.CompletedQuests.Count(id => id == "first_tower"));
        Assert.Equal(startingGold + quest.Rewards["gold"], state.Gold);
    }

    [Fact]
    public void CompleteQuest_UnknownId_ReturnsUnknownQuestError()
    {
        var state = DefaultState.Create();

        var result = Quests.CompleteQuest(state, "not_a_real_quest");

        Assert.False((bool)result["ok"]);
        Assert.Equal("Unknown quest.", result["error"]);
        Assert.Empty(state.CompletedQuests);
    }

    [Fact]
    public void CompleteQuest_SuccessResult_ContainsQuestNameAndRewardsMessage()
    {
        var state = DefaultState.Create();

        var result = Quests.CompleteQuest(state, "word_smith");

        Assert.True((bool)result["ok"]);
        Assert.True(result.ContainsKey("message"));

        var message = Assert.IsType<string>(result["message"]);
        Assert.Contains("Quest complete: Word Smith!", message);
        Assert.Contains("gold", message);
        Assert.Contains("skill point", message);
    }

    [Fact]
    public void QuestCategories_AreNonEmptyAndFromKnownSet()
    {
        var validCategories = new HashSet<string>
        {
            "tutorial",
            "exploration",
            "typing",
            "economy",
            "combat",
        };

        foreach (var (_, quest) in Quests.Registry)
        {
            Assert.False(string.IsNullOrWhiteSpace(quest.Category));
            Assert.Contains(quest.Category, validCategories);
        }
    }

    [Fact]
    public void QuestCondition_BuildStructureFactory_ProducesExpectedValues()
    {
        var condition = QuestCondition.BuildStructure("tower", 3);

        Assert.Equal("build", condition.Type);
        Assert.Equal("tower", condition.Target);
        Assert.Equal(3, condition.Value);
    }

    [Fact]
    public void QuestCondition_SurviveNightAndDiscoverTilesFactories_ProduceExpectedValues()
    {
        var surviveNight = QuestCondition.SurviveNight(2);
        var discoverTiles = QuestCondition.DiscoverTiles(75);

        Assert.Equal("survive_night", surviveNight.Type);
        Assert.Null(surviveNight.Target);
        Assert.Equal(2, surviveNight.Value);

        Assert.Equal("discover", discoverTiles.Type);
        Assert.Null(discoverTiles.Target);
        Assert.Equal(75, discoverTiles.Value);
    }

    [Fact]
    public void QuestCondition_TypeWordsAndReachComboFactories_ProduceExpectedValues()
    {
        var typeWords = QuestCondition.TypeWords(120);
        var reachCombo = QuestCondition.ReachCombo(25);

        Assert.Equal("type_words", typeWords.Type);
        Assert.Null(typeWords.Target);
        Assert.Equal(120, typeWords.Value);

        Assert.Equal("combo", reachCombo.Type);
        Assert.Null(reachCombo.Target);
        Assert.Equal(25, reachCombo.Value);
    }

    [Fact]
    public void QuestCondition_DefeatBossFactory_ProducesExpectedValues()
    {
        var defeatAnyBoss = QuestCondition.DefeatBoss(null);
        var defeatSpecificBoss = QuestCondition.DefeatBoss("grove_guardian");

        Assert.Equal("defeat_boss", defeatAnyBoss.Type);
        Assert.Null(defeatAnyBoss.Target);
        Assert.Equal(1, defeatAnyBoss.Value);

        Assert.Equal("defeat_boss", defeatSpecificBoss.Type);
        Assert.Equal("grove_guardian", defeatSpecificBoss.Target);
        Assert.Equal(1, defeatSpecificBoss.Value);
    }

    [Fact]
    public void QuestCondition_DefeatEnemiesAndSurviveWavesFactories_ProduceExpectedValues()
    {
        var defeatEnemies = QuestCondition.DefeatEnemies(25);
        var surviveWaves = QuestCondition.SurviveWaves(10);

        Assert.Equal("defeat_enemies", defeatEnemies.Type);
        Assert.Null(defeatEnemies.Target);
        Assert.Equal(25, defeatEnemies.Value);

        Assert.Equal("survive_waves", surviveWaves.Type);
        Assert.Null(surviveWaves.Target);
        Assert.Equal(10, surviveWaves.Value);
    }

    [Fact]
    public void Registry_AllRewardValues_ArePositive()
    {
        foreach (var (questId, quest) in Quests.Registry)
        {
            Assert.NotEmpty(quest.Rewards);
            foreach (var (rewardType, amount) in quest.Rewards)
            {
                Assert.False(string.IsNullOrWhiteSpace(rewardType));
                Assert.True(amount > 0, $"Quest '{questId}' has non-positive reward value for '{rewardType}'.");
            }
        }
    }
}
