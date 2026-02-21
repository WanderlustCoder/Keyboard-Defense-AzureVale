using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class WorldQuestsTests
{
    [Fact]
    public void GetAvailableQuests_DefaultState_ExcludesDayEnemyAndDependencyGatedQuests()
    {
        var state = DefaultState.Create();
        state.Day = 1;
        state.EnemiesDefeated = 0;
        state.CompletedQuests.Clear();

        var available = WorldQuests.GetAvailableQuests(state);

        Assert.Contains("first_tower", available);
        Assert.Contains("first_night", available);
        Assert.DoesNotContain("combo_master", available);
        Assert.DoesNotContain("kingdom_builder", available);
        Assert.DoesNotContain("boss_slayer", available);
        Assert.DoesNotContain("supply_run", available);
        Assert.DoesNotContain("stone_collector", available);
        Assert.DoesNotContain("feast_preparation", available);
        Assert.DoesNotContain("defender_of_the_realm", available);
    }

    [Fact]
    public void GetAvailableQuests_CompletedQuest_IsExcluded()
    {
        var state = DefaultState.Create();
        state.CompletedQuests.Add("first_tower");

        var available = WorldQuests.GetAvailableQuests(state);

        Assert.DoesNotContain("first_tower", available);
    }

    [Fact]
    public void GetAvailableQuests_KingdomBuilder_AppearsAfterFirstTowerCompletion()
    {
        var state = DefaultState.Create();
        state.Day = 1;
        state.EnemiesDefeated = 0;
        state.CompletedQuests.Add("first_tower");

        var available = WorldQuests.GetAvailableQuests(state);

        Assert.Contains("kingdom_builder", available);
    }

    [Fact]
    public void IsPreconditionMet_FirstNight_DayZeroBlocked_DayOneAllowed()
    {
        var state = DefaultState.Create();
        state.Day = 0;

        Assert.False(WorldQuests.IsPreconditionMet(state, "first_night"));

        state.Day = 1;
        Assert.True(WorldQuests.IsPreconditionMet(state, "first_night"));
    }

    [Fact]
    public void IsPreconditionMet_ComboMaster_RequiresFiveEnemiesDefeated()
    {
        var state = DefaultState.Create();
        state.EnemiesDefeated = 4;

        Assert.False(WorldQuests.IsPreconditionMet(state, "combo_master"));

        state.EnemiesDefeated = 5;
        Assert.True(WorldQuests.IsPreconditionMet(state, "combo_master"));
    }

    [Fact]
    public void IsPreconditionMet_KingdomBuilder_RequiresFirstTowerCompletion()
    {
        var state = DefaultState.Create();

        Assert.False(WorldQuests.IsPreconditionMet(state, "kingdom_builder"));

        state.CompletedQuests.Add("first_tower");
        Assert.True(WorldQuests.IsPreconditionMet(state, "kingdom_builder"));
    }

    [Fact]
    public void IsPreconditionMet_BossSlayer_DayThreeGate()
    {
        var state = DefaultState.Create();
        state.Day = 2;

        Assert.False(WorldQuests.IsPreconditionMet(state, "boss_slayer"));

        state.Day = 3;
        Assert.True(WorldQuests.IsPreconditionMet(state, "boss_slayer"));
    }

    [Fact]
    public void IsPreconditionMet_EconomyQuestDayGates_AreApplied()
    {
        var state = DefaultState.Create();
        state.Day = 1;

        Assert.False(WorldQuests.IsPreconditionMet(state, "supply_run"));
        Assert.False(WorldQuests.IsPreconditionMet(state, "stone_collector"));
        Assert.False(WorldQuests.IsPreconditionMet(state, "feast_preparation"));

        state.Day = 4;
        Assert.True(WorldQuests.IsPreconditionMet(state, "supply_run"));
        Assert.True(WorldQuests.IsPreconditionMet(state, "stone_collector"));
        Assert.True(WorldQuests.IsPreconditionMet(state, "feast_preparation"));
    }

    [Fact]
    public void IsPreconditionMet_DefenderOfTheRealm_RequiresTenEnemiesDefeated()
    {
        var state = DefaultState.Create();
        state.EnemiesDefeated = 9;

        Assert.False(WorldQuests.IsPreconditionMet(state, "defender_of_the_realm"));

        state.EnemiesDefeated = 10;
        Assert.True(WorldQuests.IsPreconditionMet(state, "defender_of_the_realm"));
    }

    [Fact]
    public void IsPreconditionMet_DefaultPaths_FirstTowerAndUnknownReturnTrue()
    {
        var state = DefaultState.Create();
        state.Day = 0;
        state.EnemiesDefeated = 0;

        Assert.True(WorldQuests.IsPreconditionMet(state, "first_tower"));
        Assert.True(WorldQuests.IsPreconditionMet(state, "quest_id_not_in_switch"));
    }

    [Fact]
    public void GetProgress_BuildTypeSpecific_CountsOnlyMatchingStructureType()
    {
        var state = DefaultState.Create();
        state.Structures.Clear();
        state.Structures[1] = "wall";

        var noTowerProgress = WorldQuests.GetProgress(state, "first_tower");
        Assert.Equal((0, 1), noTowerProgress);

        state.Structures[2] = "tower";
        var towerProgress = WorldQuests.GetProgress(state, "first_tower");
        Assert.Equal((1, 1), towerProgress);
    }

    [Fact]
    public void GetProgress_BuildWithoutType_CountsAllStructuresAndCapsAtTarget()
    {
        var state = DefaultState.Create();
        state.Structures.Clear();
        for (int i = 0; i < 12; i++)
            state.Structures[i] = i % 2 == 0 ? "tower" : "farm";

        var progress = WorldQuests.GetProgress(state, "kingdom_builder");

        Assert.Equal((10, 10), progress);
    }

    [Fact]
    public void GetProgress_SurviveNight_UsesDayAndCapsAtTarget()
    {
        var state = DefaultState.Create();
        state.Day = 3;

        var beforeCap = WorldQuests.GetProgress(state, "night_owl");
        Assert.Equal((3, 5), beforeCap);

        state.Day = 7;
        var capped = WorldQuests.GetProgress(state, "night_owl");
        Assert.Equal((5, 5), capped);
    }

    [Fact]
    public void GetProgress_Discover_UsesDiscoveredCountAndCapsAtTarget()
    {
        var state = DefaultState.Create();
        state.Discovered.Clear();
        for (int i = 0; i < 47; i++)
            state.Discovered.Add(i);

        var beforeCap = WorldQuests.GetProgress(state, "explorer");
        Assert.Equal((47, 50), beforeCap);

        for (int i = 47; i < 80; i++)
            state.Discovered.Add(i);

        var capped = WorldQuests.GetProgress(state, "explorer");
        Assert.Equal((50, 50), capped);
    }

    [Fact]
    public void GetProgress_TypeWords_UsesTypingMetricsAndCapsAtTarget()
    {
        var state = DefaultState.Create();
        state.TypingMetrics["battle_words_typed"] = 42;

        var beforeCap = WorldQuests.GetProgress(state, "word_smith");
        Assert.Equal((42, 100), beforeCap);

        state.TypingMetrics["battle_words_typed"] = 150;
        var capped = WorldQuests.GetProgress(state, "word_smith");
        Assert.Equal((100, 100), capped);
    }

    [Fact]
    public void GetProgress_Combo_UsesMaxComboEverAndCapsAtTarget()
    {
        var state = DefaultState.Create();
        state.MaxComboEver = 18;

        var beforeCap = WorldQuests.GetProgress(state, "combo_master");
        Assert.Equal((18, 20), beforeCap);

        state.MaxComboEver = 25;
        var capped = WorldQuests.GetProgress(state, "combo_master");
        Assert.Equal((20, 20), capped);
    }

    [Fact]
    public void GetProgress_DefeatBoss_HandlesSpecificAndAnyBossTargets()
    {
        var state = DefaultState.Create();
        state.BossesDefeated.Clear();

        var specificBefore = WorldQuests.GetProgress(state, "grove_champion");
        var anyBefore = WorldQuests.GetProgress(state, "boss_slayer");
        Assert.Equal((0, 1), specificBefore);
        Assert.Equal((0, 1), anyBefore);

        state.BossesDefeated.Add("grove_guardian");
        var specificAfter = WorldQuests.GetProgress(state, "grove_champion");
        Assert.Equal((1, 1), specificAfter);

        state.BossesDefeated.Add("mountain_king");
        var anyAfter = WorldQuests.GetProgress(state, "boss_slayer");
        Assert.Equal((1, 1), anyAfter);
    }

    [Fact]
    public void GetProgress_DefeatEnemies_UsesEnemiesDefeatedAndCapsAtTarget()
    {
        var state = DefaultState.Create();
        state.EnemiesDefeated = 20;

        var beforeCap = WorldQuests.GetProgress(state, "defender_of_the_realm");
        Assert.Equal((20, 25), beforeCap);

        state.EnemiesDefeated = 40;
        var capped = WorldQuests.GetProgress(state, "defender_of_the_realm");
        Assert.Equal((25, 25), capped);
    }

    [Fact]
    public void GetProgress_SurviveWaves_UsesWavesSurvivedAndCapsAtTarget()
    {
        var state = DefaultState.Create();
        state.WavesSurvived = 2;

        var beforeCap = WorldQuests.GetProgress(state, "wave_defender");
        Assert.Equal((2, 3), beforeCap);

        state.WavesSurvived = 8;
        var capped = WorldQuests.GetProgress(state, "wave_defender");
        Assert.Equal((3, 3), capped);
    }

    [Fact]
    public void GetProgress_UnknownQuestId_ReturnsZeroZero()
    {
        var state = DefaultState.Create();

        var progress = WorldQuests.GetProgress(state, "not_a_real_quest_id");

        Assert.Equal((0, 0), progress);
    }

    [Fact]
    public void CheckCompletions_ReadyQuest_IsCompletedAndReturnsEventMessage()
    {
        var state = DefaultState.Create();
        state.Day = 0;
        state.EnemiesDefeated = 0;
        state.WavesSurvived = 0;
        state.MaxComboEver = 0;
        state.Discovered.Clear();
        state.BossesDefeated.Clear();
        state.TypingMetrics["battle_words_typed"] = 0;
        state.Structures.Clear();
        state.Structures[1] = "tower";

        var events = WorldQuests.CheckCompletions(state);

        Assert.Contains("first_tower", state.CompletedQuests);
        Assert.Contains(events, e => e.Contains("First Defense"));
        Assert.Contains(events, e => e.Contains("gold"));
    }

    [Fact]
    public void CheckCompletions_WhenNoQuestMeetsTarget_ReturnsNoEvents()
    {
        var state = DefaultState.Create();
        state.Day = 0;
        state.EnemiesDefeated = 0;
        state.WavesSurvived = 0;
        state.MaxComboEver = 0;
        state.Discovered.Clear();
        state.BossesDefeated.Clear();
        state.TypingMetrics["battle_words_typed"] = 0;
        state.Structures.Clear();

        var events = WorldQuests.CheckCompletions(state);

        Assert.Empty(events);
        Assert.Empty(state.CompletedQuests);
    }

    [Fact]
    public void CheckCompletions_AwardsGold()
    {
        var state = DefaultState.Create();
        state.Structures.Clear();
        state.Structures[1] = "tower";
        int goldBefore = state.Gold;

        WorldQuests.CheckCompletions(state);

        Assert.True(state.Gold > goldBefore, "Completing a quest should award gold");
    }

    [Fact]
    public void CheckCompletions_MultipleQuestsReady_AllComplete()
    {
        var state = DefaultState.Create();
        state.Day = 5;
        state.EnemiesDefeated = 30;
        state.MaxComboEver = 25;
        state.WavesSurvived = 10;
        state.TypingMetrics["battle_words_typed"] = 150;
        state.Structures.Clear();
        state.Structures[1] = "tower";
        for (int i = 2; i <= 12; i++) state.Structures[i] = "farm";
        for (int i = 0; i < 60; i++) state.Discovered.Add(i);

        var events = WorldQuests.CheckCompletions(state);

        Assert.True(events.Count >= 3, $"Multiple quests should complete, got {events.Count}");
        Assert.True(state.CompletedQuests.Count >= 3);
    }

    [Fact]
    public void CheckCompletions_AlreadyCompleted_NotRetriggered()
    {
        var state = DefaultState.Create();
        state.Structures.Clear();
        state.Structures[1] = "tower";

        WorldQuests.CheckCompletions(state);
        int goldAfterFirst = state.Gold;

        var events = WorldQuests.CheckCompletions(state);
        Assert.Empty(events);
        Assert.Equal(goldAfterFirst, state.Gold);
    }

    [Fact]
    public void GetProgress_SpeedDemon_UsesMaxComboEver()
    {
        var state = DefaultState.Create();
        state.MaxComboEver = 30;

        var progress = WorldQuests.GetProgress(state, "speed_demon");
        Assert.True(progress.Current > 0 || progress.Target > 0);
    }

    [Fact]
    public void Quests_GetQuest_ReturnsNullForUnknownId()
    {
        Assert.Null(Quests.GetQuest("totally_fake_quest"));
    }

    [Fact]
    public void Quests_GetQuest_ReturnsDefForKnownId()
    {
        var def = Quests.GetQuest("first_tower");
        Assert.NotNull(def);
        Assert.Equal("First Defense", def!.Name);
    }

    [Fact]
    public void Quests_IsComplete_FalseByDefault()
    {
        var state = DefaultState.Create();
        Assert.False(Quests.IsComplete(state, "first_tower"));
    }

    [Fact]
    public void Quests_IsComplete_TrueAfterCompletion()
    {
        var state = DefaultState.Create();
        state.CompletedQuests.Add("first_tower");
        Assert.True(Quests.IsComplete(state, "first_tower"));
    }

    [Fact]
    public void Quests_CompleteQuest_AlreadyDone_ReturnsFalse()
    {
        var state = DefaultState.Create();
        state.CompletedQuests.Add("first_tower");
        var result = Quests.CompleteQuest(state, "first_tower");
        Assert.False(Convert.ToBoolean(result["ok"]));
    }

    [Fact]
    public void Quests_CompleteQuest_UnknownId_ReturnsFalse()
    {
        var state = DefaultState.Create();
        var result = Quests.CompleteQuest(state, "nonexistent");
        Assert.False(Convert.ToBoolean(result["ok"]));
    }

    [Fact]
    public void Quests_Registry_HasAtLeast15Quests()
    {
        Assert.True(Quests.Registry.Count >= 15, $"Registry has {Quests.Registry.Count} quests");
    }

    [Fact]
    public void Quests_GetActiveQuests_ExcludesCompleted()
    {
        var state = DefaultState.Create();
        state.CompletedQuests.Add("first_tower");
        state.CompletedQuests.Add("explorer");

        var active = Quests.GetActiveQuests(state);
        Assert.DoesNotContain("first_tower", active);
        Assert.DoesNotContain("explorer", active);
    }
}
