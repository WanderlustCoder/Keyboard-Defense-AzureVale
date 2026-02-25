using System;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class QuestsDeepTests
{
    [Fact]
    public void QuestChain_FirstTowerCompletionUnlocksAndThenCompletesKingdomBuilder()
    {
        var state = CreateCleanQuestState(day: 0);
        state.Structures[10] = "tower";

        var firstEvents = WorldQuests.CheckCompletions(state);

        Assert.Contains("first_tower", state.CompletedQuests);
        Assert.Contains(firstEvents, e => e.Contains("First Defense", StringComparison.Ordinal));
        Assert.Contains("kingdom_builder", WorldQuests.GetAvailableQuests(state));

        for (int i = 0; i < 9; i++)
            state.Structures[100 + i] = "farm";

        Assert.Equal((10, 10), WorldQuests.GetProgress(state, "kingdom_builder"));

        var secondEvents = WorldQuests.CheckCompletions(state);

        Assert.Contains("kingdom_builder", state.CompletedQuests);
        Assert.Contains(secondEvents, e => e.Contains("Kingdom Builder", StringComparison.Ordinal));
    }

    [Fact]
    public void QuestChain_EconomyQuestDayGatesUnlockInOrderAcrossDays()
    {
        var state = CreateCleanQuestState(day: 1);

        var dayOne = WorldQuests.GetAvailableQuests(state);
        Assert.DoesNotContain("supply_run", dayOne);
        Assert.DoesNotContain("stone_collector", dayOne);
        Assert.DoesNotContain("feast_preparation", dayOne);

        state.Day = 2;
        var dayTwo = WorldQuests.GetAvailableQuests(state);
        Assert.Contains("supply_run", dayTwo);
        Assert.DoesNotContain("stone_collector", dayTwo);
        Assert.DoesNotContain("feast_preparation", dayTwo);

        state.Day = 3;
        var dayThree = WorldQuests.GetAvailableQuests(state);
        Assert.Contains("supply_run", dayThree);
        Assert.Contains("stone_collector", dayThree);
        Assert.DoesNotContain("feast_preparation", dayThree);

        state.Day = 4;
        var dayFour = WorldQuests.GetAvailableQuests(state);
        Assert.Contains("supply_run", dayFour);
        Assert.Contains("stone_collector", dayFour);
        Assert.Contains("feast_preparation", dayFour);
    }

    [Fact]
    public void SimultaneousTypeWordQuests_CompleteAtTheirOwnThresholdsAcrossChecks()
    {
        var state = CreateCleanQuestState(day: 4);
        state.CompletedQuests.Add("first_night");

        state.TypingMetrics["battle_words_typed"] = 19;
        var belowThresholdEvents = WorldQuests.CheckCompletions(state);
        Assert.Empty(belowThresholdEvents);

        state.TypingMetrics["battle_words_typed"] = 20;
        var atTwentyEvents = WorldQuests.CheckCompletions(state);
        Assert.Contains("supply_run", state.CompletedQuests);
        Assert.Contains(atTwentyEvents, e => e.Contains("Supply Run", StringComparison.Ordinal));

        state.TypingMetrics["battle_words_typed"] = 30;
        var atThirtyEvents = WorldQuests.CheckCompletions(state);
        Assert.Contains("stone_collector", state.CompletedQuests);
        Assert.Contains(atThirtyEvents, e => e.Contains("Stone Collector", StringComparison.Ordinal));

        state.TypingMetrics["battle_words_typed"] = 40;
        var atFortyEvents = WorldQuests.CheckCompletions(state);
        Assert.Contains("feast_preparation", state.CompletedQuests);
        Assert.Contains(atFortyEvents, e => e.Contains("Feast Preparation", StringComparison.Ordinal));

        state.TypingMetrics["battle_words_typed"] = 50;
        var atFiftyEvents = WorldQuests.CheckCompletions(state);
        Assert.Contains("speed_demon", state.CompletedQuests);
        Assert.Contains(atFiftyEvents, e => e.Contains("Speed Demon", StringComparison.Ordinal));
        Assert.DoesNotContain("word_smith", state.CompletedQuests);
    }

    [Fact]
    public void SimultaneousActiveQuests_DifferentActionTypesCompleteInSingleSweep()
    {
        var state = CreateCleanQuestState(day: 4);
        state.CompletedQuests.Add("first_night");
        state.Structures[1] = "tower";
        state.TypingMetrics["battle_words_typed"] = 40;
        state.MaxComboEver = 20;
        state.EnemiesDefeated = 25;
        state.WavesSurvived = 3;

        var events = WorldQuests.CheckCompletions(state);
        var expectedQuestIds = new[]
        {
            "first_tower",
            "combo_master",
            "perfect_accuracy",
            "defender_of_the_realm",
            "wave_defender",
            "supply_run",
            "stone_collector",
            "feast_preparation",
        };

        foreach (var questId in expectedQuestIds)
            Assert.Contains(questId, state.CompletedQuests);

        Assert.Equal(expectedQuestIds.Length, events.Count);
    }

    [Fact]
    public void GetProgress_MixedActionSnapshotReportsExpectedValuesForAllConditionTypes()
    {
        var state = CreateCleanQuestState(day: 6);
        for (int i = 0; i < 12; i++)
            state.Structures[i] = i == 0 ? "tower" : "farm";
        for (int i = 0; i < 160; i++)
            state.Discovered.Add(i);
        state.TypingMetrics["battle_words_typed"] = 120;
        state.MaxComboEver = 25;
        state.BossesDefeated.Add("grove_guardian");
        state.EnemiesDefeated = 40;
        state.WavesSurvived = 11;

        Assert.Equal((1, 1), WorldQuests.GetProgress(state, "first_tower"));
        Assert.Equal((10, 10), WorldQuests.GetProgress(state, "kingdom_builder"));
        Assert.Equal((12, 15), WorldQuests.GetProgress(state, "architect"));
        Assert.Equal((5, 5), WorldQuests.GetProgress(state, "night_owl"));
        Assert.Equal((50, 50), WorldQuests.GetProgress(state, "explorer"));
        Assert.Equal((150, 150), WorldQuests.GetProgress(state, "cartographer"));
        Assert.Equal((100, 100), WorldQuests.GetProgress(state, "word_smith"));
        Assert.Equal((50, 50), WorldQuests.GetProgress(state, "speed_demon"));
        Assert.Equal((20, 20), WorldQuests.GetProgress(state, "combo_master"));
        Assert.Equal((10, 10), WorldQuests.GetProgress(state, "perfect_accuracy"));
        Assert.Equal((1, 1), WorldQuests.GetProgress(state, "grove_champion"));
        Assert.Equal((0, 1), WorldQuests.GetProgress(state, "mountain_conqueror"));
        Assert.Equal((1, 1), WorldQuests.GetProgress(state, "boss_slayer"));
        Assert.Equal((25, 25), WorldQuests.GetProgress(state, "defender_of_the_realm"));
        Assert.Equal((3, 3), WorldQuests.GetProgress(state, "wave_defender"));
        Assert.Equal((10, 10), WorldQuests.GetProgress(state, "wave_master"));
    }

    [Fact]
    public void RewardStacking_DirectQuestCompletionsAccumulateExactTotalsAcrossCurrencies()
    {
        var state = CreateCleanQuestState(day: 0);
        var questIds = new[] { "word_smith", "defender_of_the_realm", "wave_defender" };

        int expectedGold = 0;
        int expectedSkillPoints = 0;
        int expectedWood = 0;
        int expectedStone = 0;
        int expectedFood = 0;

        foreach (var questId in questIds)
        {
            var quest = Quest(questId);
            var result = Quests.CompleteQuest(state, questId);
            Assert.True((bool)result["ok"]);

            expectedGold += quest.Rewards.GetValueOrDefault("gold", 0);
            expectedSkillPoints += quest.Rewards.GetValueOrDefault("skill_point", 0);
            expectedWood += quest.Rewards.GetValueOrDefault("wood", 0);
            expectedStone += quest.Rewards.GetValueOrDefault("stone", 0);
            expectedFood += quest.Rewards.GetValueOrDefault("food", 0);
        }

        Assert.Equal(expectedGold, state.Gold);
        Assert.Equal(expectedSkillPoints, state.SkillPoints);
        Assert.Equal(expectedWood, state.Resources.GetValueOrDefault("wood", 0));
        Assert.Equal(expectedStone, state.Resources.GetValueOrDefault("stone", 0));
        Assert.Equal(expectedFood, state.Resources.GetValueOrDefault("food", 0));
        Assert.Equal(questIds.Length, state.CompletedQuests.Count);
    }

    [Fact]
    public void RewardStacking_CheckCompletionsMatchesDirectCompletionForSameQuestSet()
    {
        var directState = CreateCleanQuestState(day: 4);
        var worldState = CreateCleanQuestState(day: 4);
        worldState.CompletedQuests.Add("first_night");
        worldState.TypingMetrics["battle_words_typed"] = 40;
        var questIds = new[] { "supply_run", "stone_collector", "feast_preparation" };

        foreach (var questId in questIds)
        {
            var result = Quests.CompleteQuest(directState, questId);
            Assert.True((bool)result["ok"]);
        }

        var events = WorldQuests.CheckCompletions(worldState);

        Assert.Equal(questIds.Length, events.Count);
        Assert.Equal(directState.Gold, worldState.Gold);
        Assert.Equal(directState.SkillPoints, worldState.SkillPoints);
        Assert.Equal(directState.Resources.GetValueOrDefault("wood", 0), worldState.Resources.GetValueOrDefault("wood", 0));
        Assert.Equal(directState.Resources.GetValueOrDefault("stone", 0), worldState.Resources.GetValueOrDefault("stone", 0));
        Assert.Equal(directState.Resources.GetValueOrDefault("food", 0), worldState.Resources.GetValueOrDefault("food", 0));
    }

    [Fact]
    public void GetActiveQuests_MultipleCompletionsReduceActiveCountByExactNumber()
    {
        var state = CreateCleanQuestState(day: 0);
        var completedInTest = new[] { "first_tower", "word_smith", "supply_run" };
        int activeBefore = Quests.GetActiveQuests(state).Count;

        foreach (var questId in completedInTest)
        {
            var result = Quests.CompleteQuest(state, questId);
            Assert.True((bool)result["ok"]);
        }

        var activeAfter = Quests.GetActiveQuests(state);

        Assert.Equal(activeBefore - completedInTest.Length, activeAfter.Count);
        foreach (var questId in completedInTest)
            Assert.DoesNotContain(questId, activeAfter);
    }

    [Fact]
    public void AbandonAndReaccept_SimulatedByCompletionReset_QuestBecomesAvailableAgain()
    {
        var state = CreateCleanQuestState(day: 2);

        Assert.Contains("supply_run", WorldQuests.GetAvailableQuests(state));
        Assert.True((bool)Quests.CompleteQuest(state, "supply_run")["ok"]);
        Assert.DoesNotContain("supply_run", WorldQuests.GetAvailableQuests(state));

        state.CompletedQuests.Remove("supply_run");

        Assert.Contains("supply_run", WorldQuests.GetAvailableQuests(state));
    }

    [Fact]
    public void AbandonAndReaccept_RecompletionAfterReset_AppliesRewardsAgain()
    {
        var state = CreateCleanQuestState(day: 2);
        var quest = Quest("supply_run");

        Assert.True((bool)Quests.CompleteQuest(state, "supply_run")["ok"]);
        state.CompletedQuests.Remove("supply_run");
        Assert.True((bool)Quests.CompleteQuest(state, "supply_run")["ok"]);

        Assert.Equal(quest.Rewards["gold"] * 2, state.Gold);
        Assert.Equal(quest.Rewards["wood"] * 2, state.Resources.GetValueOrDefault("wood", 0));
        Assert.Single(state.CompletedQuests);
    }

    [Fact]
    public void AbandonAndReaccept_ProgressCarriesAcrossReset_AllowsImmediateRecompletion()
    {
        var state = CreateCleanQuestState(day: 4);
        state.CompletedQuests.Add("first_night");
        state.TypingMetrics["battle_words_typed"] = 40;
        var feast = Quest("feast_preparation");

        WorldQuests.CheckCompletions(state);
        Assert.Contains("feast_preparation", state.CompletedQuests);

        int goldBeforeSecondCompletion = state.Gold;
        int foodBeforeSecondCompletion = state.Resources.GetValueOrDefault("food", 0);
        state.CompletedQuests.Remove("feast_preparation");

        var secondEvents = WorldQuests.CheckCompletions(state);

        Assert.Single(secondEvents);
        Assert.Contains("Feast Preparation", secondEvents[0], StringComparison.Ordinal);
        Assert.Contains("feast_preparation", state.CompletedQuests);
        Assert.Equal(goldBeforeSecondCompletion + feast.Rewards["gold"], state.Gold);
        Assert.Equal(foodBeforeSecondCompletion + feast.Rewards["food"], state.Resources.GetValueOrDefault("food", 0));
    }

    [Fact]
    public void QuestChain_BossQuestBranchesCompleteInExpectedOrderByDefeatedBoss()
    {
        var state = CreateCleanQuestState(day: 3);
        state.CompletedQuests.Add("first_night");
        state.BossesDefeated.Add("grove_guardian");

        var firstBossEvents = WorldQuests.CheckCompletions(state);

        Assert.Contains("boss_slayer", state.CompletedQuests);
        Assert.Contains("grove_champion", state.CompletedQuests);
        Assert.DoesNotContain("mountain_conqueror", state.CompletedQuests);
        Assert.Contains(firstBossEvents, e => e.Contains("Boss Slayer", StringComparison.Ordinal));
        Assert.Contains(firstBossEvents, e => e.Contains("Grove Champion", StringComparison.Ordinal));

        state.BossesDefeated.Add("mountain_king");
        var secondBossEvents = WorldQuests.CheckCompletions(state);

        Assert.Single(secondBossEvents);
        Assert.Contains("mountain_conqueror", state.CompletedQuests);
        Assert.Contains("Mountain Conqueror", secondBossEvents[0], StringComparison.Ordinal);
    }

    private static GameState CreateCleanQuestState(int day)
    {
        var state = DefaultState.Create($"quests_deep_{Guid.NewGuid():N}");
        state.Day = day;
        state.Gold = 0;
        state.SkillPoints = 0;
        state.CompletedQuests.Clear();
        state.BossesDefeated.Clear();
        state.Structures.Clear();
        state.Discovered.Clear();
        state.EnemiesDefeated = 0;
        state.MaxComboEver = 0;
        state.WavesSurvived = 0;
        state.Resources["wood"] = 0;
        state.Resources["stone"] = 0;
        state.Resources["food"] = 0;
        state.TypingMetrics["battle_words_typed"] = 0;
        return state;
    }

    private static QuestDef Quest(string questId)
    {
        return Assert.IsType<QuestDef>(Quests.GetQuest(questId));
    }
}
