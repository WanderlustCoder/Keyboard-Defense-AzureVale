using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Extended tests for Quests — registry completeness invariants, category distribution,
/// QuestDef/QuestCondition record validation, reward structure checks,
/// GetActiveQuests edge cases, and CompleteQuest idempotency.
/// </summary>
public class QuestsExtendedTests
{
    // =========================================================================
    // Registry — completeness
    // =========================================================================

    [Fact]
    public void Registry_HasTwentyEntries()
    {
        Assert.Equal(20, Quests.Registry.Count);
    }

    [Theory]
    [InlineData("first_tower")]
    [InlineData("first_night")]
    [InlineData("explorer")]
    [InlineData("word_smith")]
    [InlineData("combo_master")]
    [InlineData("kingdom_builder")]
    [InlineData("boss_slayer")]
    [InlineData("supply_run")]
    [InlineData("stone_collector")]
    [InlineData("feast_preparation")]
    [InlineData("defender_of_the_realm")]
    [InlineData("wave_defender")]
    [InlineData("speed_demon")]
    [InlineData("perfect_accuracy")]
    [InlineData("grove_champion")]
    [InlineData("mountain_conqueror")]
    [InlineData("night_owl")]
    [InlineData("architect")]
    [InlineData("cartographer")]
    [InlineData("wave_master")]
    public void Registry_ContainsExpectedQuestId(string questId)
    {
        Assert.True(Quests.Registry.ContainsKey(questId));
    }

    // =========================================================================
    // Registry — field validation invariants
    // =========================================================================

    [Fact]
    public void Registry_AllQuests_HaveNonEmptyNames()
    {
        foreach (var (id, quest) in Quests.Registry)
        {
            Assert.False(string.IsNullOrWhiteSpace(quest.Name),
                $"Quest '{id}' has empty name.");
        }
    }

    [Fact]
    public void Registry_AllQuests_HaveNonEmptyDescriptions()
    {
        foreach (var (id, quest) in Quests.Registry)
        {
            Assert.False(string.IsNullOrWhiteSpace(quest.Description),
                $"Quest '{id}' has empty description.");
        }
    }

    [Fact]
    public void Registry_AllQuests_HaveNonEmptyCategory()
    {
        foreach (var (id, quest) in Quests.Registry)
        {
            Assert.False(string.IsNullOrWhiteSpace(quest.Category),
                $"Quest '{id}' has empty category.");
        }
    }

    [Fact]
    public void Registry_AllQuests_HavePositiveConditionValue()
    {
        foreach (var (id, quest) in Quests.Registry)
        {
            Assert.True(quest.Condition.Value > 0,
                $"Quest '{id}' has non-positive condition value: {quest.Condition.Value}");
        }
    }

    [Fact]
    public void Registry_AllQuests_HaveAtLeastOneReward()
    {
        foreach (var (id, quest) in Quests.Registry)
        {
            Assert.True(quest.Rewards.Count > 0,
                $"Quest '{id}' has no rewards.");
        }
    }

    [Fact]
    public void Registry_AllQuests_HavePositiveRewardValues()
    {
        foreach (var (id, quest) in Quests.Registry)
        {
            foreach (var (rewardKey, rewardVal) in quest.Rewards)
            {
                Assert.True(rewardVal > 0,
                    $"Quest '{id}' has non-positive reward '{rewardKey}': {rewardVal}");
            }
        }
    }

    // =========================================================================
    // Category distribution
    // =========================================================================

    [Theory]
    [InlineData("tutorial", 2)]
    [InlineData("exploration", 2)]
    [InlineData("typing", 4)]
    [InlineData("economy", 5)]
    [InlineData("combat", 7)]
    public void Registry_CategoryDistribution_MatchesExpected(string category, int expectedCount)
    {
        int count = Quests.Registry.Values.Count(q => q.Category == category);
        Assert.Equal(expectedCount, count);
    }

    [Fact]
    public void Registry_AllCategoriesSumToTotalCount()
    {
        var categories = Quests.Registry.Values
            .GroupBy(q => q.Category)
            .Sum(g => g.Count());
        Assert.Equal(Quests.Registry.Count, categories);
    }

    // =========================================================================
    // Condition type distribution
    // =========================================================================

    [Fact]
    public void Registry_AllConditionTypes_AreSupportedFactoryTypes()
    {
        var supportedTypes = new HashSet<string>
        {
            "build", "survive_night", "discover", "type_words",
            "combo", "defeat_boss", "defeat_enemies", "survive_waves",
        };

        foreach (var (id, quest) in Quests.Registry)
        {
            Assert.Contains(quest.Condition.Type, supportedTypes);
        }
    }

    [Fact]
    public void Registry_HasQuestsForAllConditionTypes()
    {
        var typesUsed = Quests.Registry.Values
            .Select(q => q.Condition.Type)
            .Distinct()
            .ToHashSet();

        Assert.Contains("build", typesUsed);
        Assert.Contains("survive_night", typesUsed);
        Assert.Contains("discover", typesUsed);
        Assert.Contains("type_words", typesUsed);
        Assert.Contains("combo", typesUsed);
        Assert.Contains("defeat_boss", typesUsed);
        Assert.Contains("defeat_enemies", typesUsed);
        Assert.Contains("survive_waves", typesUsed);
    }

    // =========================================================================
    // QuestCondition — factory method validation
    // =========================================================================

    [Fact]
    public void QuestCondition_BuildStructure_WithType_SetsTarget()
    {
        var cond = QuestCondition.BuildStructure("wall", 5);
        Assert.Equal("build", cond.Type);
        Assert.Equal("wall", cond.Target);
        Assert.Equal(5, cond.Value);
    }

    [Fact]
    public void QuestCondition_BuildStructure_NullType_SetsNullTarget()
    {
        var cond = QuestCondition.BuildStructure(null, 10);
        Assert.Equal("build", cond.Type);
        Assert.Null(cond.Target);
        Assert.Equal(10, cond.Value);
    }

    [Fact]
    public void QuestCondition_SurviveNight_SetsCorrectFields()
    {
        var cond = QuestCondition.SurviveNight(7);
        Assert.Equal("survive_night", cond.Type);
        Assert.Null(cond.Target);
        Assert.Equal(7, cond.Value);
    }

    [Fact]
    public void QuestCondition_DiscoverTiles_SetsCorrectFields()
    {
        var cond = QuestCondition.DiscoverTiles(100);
        Assert.Equal("discover", cond.Type);
        Assert.Null(cond.Target);
        Assert.Equal(100, cond.Value);
    }

    [Fact]
    public void QuestCondition_TypeWords_SetsCorrectFields()
    {
        var cond = QuestCondition.TypeWords(50);
        Assert.Equal("type_words", cond.Type);
        Assert.Null(cond.Target);
        Assert.Equal(50, cond.Value);
    }

    [Fact]
    public void QuestCondition_ReachCombo_SetsCorrectFields()
    {
        var cond = QuestCondition.ReachCombo(15);
        Assert.Equal("combo", cond.Type);
        Assert.Null(cond.Target);
        Assert.Equal(15, cond.Value);
    }

    [Fact]
    public void QuestCondition_DefeatBoss_WithTarget_SetsTarget()
    {
        var cond = QuestCondition.DefeatBoss("dragon_lord");
        Assert.Equal("defeat_boss", cond.Type);
        Assert.Equal("dragon_lord", cond.Target);
        Assert.Equal(1, cond.Value);
    }

    [Fact]
    public void QuestCondition_DefeatBoss_NullTarget_AnyBoss()
    {
        var cond = QuestCondition.DefeatBoss(null);
        Assert.Equal("defeat_boss", cond.Type);
        Assert.Null(cond.Target);
        Assert.Equal(1, cond.Value);
    }

    [Fact]
    public void QuestCondition_DefeatEnemies_SetsCorrectFields()
    {
        var cond = QuestCondition.DefeatEnemies(50);
        Assert.Equal("defeat_enemies", cond.Type);
        Assert.Null(cond.Target);
        Assert.Equal(50, cond.Value);
    }

    [Fact]
    public void QuestCondition_SurviveWaves_SetsCorrectFields()
    {
        var cond = QuestCondition.SurviveWaves(8);
        Assert.Equal("survive_waves", cond.Type);
        Assert.Null(cond.Target);
        Assert.Equal(8, cond.Value);
    }

    // =========================================================================
    // QuestCondition — record equality
    // =========================================================================

    [Fact]
    public void QuestCondition_RecordEquality_SameValues_AreEqual()
    {
        var a = new QuestCondition("build", "tower", 1);
        var b = new QuestCondition("build", "tower", 1);
        Assert.Equal(a, b);
    }

    [Fact]
    public void QuestCondition_RecordEquality_DifferentValues_AreNotEqual()
    {
        var a = new QuestCondition("build", "tower", 1);
        var b = new QuestCondition("build", "wall", 1);
        Assert.NotEqual(a, b);
    }

    // =========================================================================
    // QuestDef — record validation
    // =========================================================================

    [Fact]
    public void QuestDef_RecordFields_AccessibleCorrectly()
    {
        var rewards = new Dictionary<string, int> { ["gold"] = 50, ["wood"] = 10 };
        var condition = QuestCondition.BuildStructure("tower", 3);
        var def = new QuestDef("Test Quest", "A test.", "testing", condition, rewards);

        Assert.Equal("Test Quest", def.Name);
        Assert.Equal("A test.", def.Description);
        Assert.Equal("testing", def.Category);
        Assert.Equal(condition, def.Condition);
        Assert.Equal(50, def.Rewards["gold"]);
        Assert.Equal(10, def.Rewards["wood"]);
    }

    // =========================================================================
    // GetQuest — edge cases
    // =========================================================================

    [Fact]
    public void GetQuest_AllRegisteredIds_ReturnNonNull()
    {
        foreach (var id in Quests.Registry.Keys)
        {
            Assert.NotNull(Quests.GetQuest(id));
        }
    }

    [Fact]
    public void GetQuest_EmptyString_ReturnsNull()
    {
        Assert.Null(Quests.GetQuest(""));
    }

    // =========================================================================
    // GetActiveQuests — edge cases
    // =========================================================================

    [Fact]
    public void GetActiveQuests_AllCompleted_ReturnsEmpty()
    {
        var state = DefaultState.Create();
        foreach (var id in Quests.Registry.Keys)
            state.CompletedQuests.Add(id);

        var active = Quests.GetActiveQuests(state);

        Assert.Empty(active);
    }

    [Fact]
    public void GetActiveQuests_CountDecreasesByOnePerCompletion()
    {
        var state = DefaultState.Create();
        int totalBefore = Quests.GetActiveQuests(state).Count;
        Assert.Equal(Quests.Registry.Count, totalBefore);

        Quests.CompleteQuest(state, "first_tower");

        Assert.Equal(totalBefore - 1, Quests.GetActiveQuests(state).Count);
    }

    // =========================================================================
    // CompleteQuest — specific quest reward spot-checks
    // =========================================================================

    [Theory]
    [InlineData("first_tower", "gold", 10)]
    [InlineData("first_night", "gold", 15)]
    [InlineData("explorer", "gold", 25)]
    [InlineData("combo_master", "gold", 30)]
    [InlineData("boss_slayer", "gold", 50)]
    [InlineData("grove_champion", "gold", 100)]
    [InlineData("mountain_conqueror", "gold", 150)]
    public void CompleteQuest_SpecificQuest_GrantsExpectedGold(string questId, string rewardKey, int expectedAmount)
    {
        var state = DefaultState.Create();
        state.Gold = 0;
        var quest = Quests.GetQuest(questId)!;
        Assert.Equal(expectedAmount, quest.Rewards[rewardKey]);

        Quests.CompleteQuest(state, questId);

        Assert.Equal(expectedAmount, state.Gold);
    }

    [Fact]
    public void CompleteQuest_WaveMaster_GrantsAllResourceTypes()
    {
        var state = DefaultState.Create();
        state.Gold = 0;
        state.SkillPoints = 0;
        state.Resources["wood"] = 0;
        state.Resources["stone"] = 0;
        state.Resources["food"] = 0;

        Quests.CompleteQuest(state, "wave_master");

        Assert.Equal(100, state.Gold);
        Assert.Equal(3, state.SkillPoints);
        Assert.Equal(25, state.Resources["wood"]);
        Assert.Equal(25, state.Resources["stone"]);
        Assert.Equal(15, state.Resources["food"]);
    }

    // =========================================================================
    // CompleteQuest — message format
    // =========================================================================

    [Fact]
    public void CompleteQuest_MessageContainsQuestName()
    {
        var state = DefaultState.Create();
        var result = Quests.CompleteQuest(state, "explorer");
        var message = result["message"]?.ToString() ?? "";

        Assert.Contains("Explorer", message);
        Assert.Contains("Quest complete:", message);
    }

    [Fact]
    public void CompleteQuest_MessageContainsAllRewardTypes()
    {
        var state = DefaultState.Create();
        state.Resources["wood"] = 0;
        state.Resources["stone"] = 0;
        state.Resources["food"] = 0;

        var result = Quests.CompleteQuest(state, "wave_master");
        var message = result["message"]?.ToString() ?? "";

        Assert.Contains("gold", message);
        Assert.Contains("skill point", message);
        Assert.Contains("wood", message);
        Assert.Contains("stone", message);
        Assert.Contains("food", message);
    }

    // =========================================================================
    // IsComplete — edge cases
    // =========================================================================

    [Fact]
    public void IsComplete_NonExistentQuestId_ReturnsFalse()
    {
        var state = DefaultState.Create();
        Assert.False(Quests.IsComplete(state, "nonexistent_quest_id"));
    }

    [Fact]
    public void IsComplete_AfterCompletion_ReturnsTrue()
    {
        var state = DefaultState.Create();
        Quests.CompleteQuest(state, "first_tower");
        Assert.True(Quests.IsComplete(state, "first_tower"));
    }

    [Fact]
    public void IsComplete_AfterManualRemoval_ReturnsFalse()
    {
        var state = DefaultState.Create();
        Quests.CompleteQuest(state, "first_tower");
        state.CompletedQuests.Remove("first_tower");
        Assert.False(Quests.IsComplete(state, "first_tower"));
    }
}
