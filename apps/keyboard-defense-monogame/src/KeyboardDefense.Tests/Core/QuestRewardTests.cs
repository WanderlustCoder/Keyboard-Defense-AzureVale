using System.Collections.Generic;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class QuestRewardTests
{
    private static GameState CreateQuestState()
    {
        var state = new GameState
        {
            MapW = 16, MapH = 16,
            Hp = 20, Phase = "day",
            ActivityMode = "exploration",
            RngSeed = "quest_test",
            LessonId = "full_alpha",
            Day = 1,
        };
        state.BasePos = new GridPoint(8, 8);
        state.PlayerPos = state.BasePos;
        for (int i = 0; i < state.MapW * state.MapH; i++)
            state.Terrain.Add("plains");
        TypingMetrics.InitBattleMetrics(state);
        return state;
    }

    [Fact]
    public void CompleteQuest_AwardsGold()
    {
        var state = CreateQuestState();
        int goldBefore = state.Gold;
        var result = Quests.CompleteQuest(state, "first_tower");
        Assert.True((bool)result["ok"]);
        Assert.True(state.Gold > goldBefore);
    }

    [Fact]
    public void CompleteQuest_AwardsSkillPoints()
    {
        var state = CreateQuestState();
        int spBefore = state.SkillPoints;
        var result = Quests.CompleteQuest(state, "word_smith");
        Assert.True((bool)result["ok"]);
        Assert.True(state.SkillPoints > spBefore);
    }

    [Fact]
    public void CompleteQuest_AwardsResources()
    {
        var state = CreateQuestState();
        int woodBefore = state.Resources.GetValueOrDefault("wood", 0);
        var result = Quests.CompleteQuest(state, "supply_run");
        Assert.True((bool)result["ok"]);
        Assert.True(state.Resources.GetValueOrDefault("wood", 0) > woodBefore);
    }

    [Fact]
    public void CompleteQuest_AwardsMultipleResourceTypes()
    {
        var state = CreateQuestState();
        int goldBefore = state.Gold;
        int woodBefore = state.Resources.GetValueOrDefault("wood", 0);
        int stoneBefore = state.Resources.GetValueOrDefault("stone", 0);
        int spBefore = state.SkillPoints;

        var result = Quests.CompleteQuest(state, "defender_of_the_realm");
        Assert.True((bool)result["ok"]);
        Assert.True(state.Gold > goldBefore);
        Assert.True(state.Resources.GetValueOrDefault("wood", 0) > woodBefore);
        Assert.True(state.Resources.GetValueOrDefault("stone", 0) > stoneBefore);
        Assert.True(state.SkillPoints > spBefore);
    }

    [Fact]
    public void CompleteQuest_DuplicateCompletion_Fails()
    {
        var state = CreateQuestState();
        Quests.CompleteQuest(state, "first_tower");
        var result = Quests.CompleteQuest(state, "first_tower");
        Assert.False((bool)result["ok"]);
    }

    [Fact]
    public void CompleteQuest_MessageIncludesRewards()
    {
        var state = CreateQuestState();
        var result = Quests.CompleteQuest(state, "first_tower");
        string msg = result["message"].ToString()!;
        Assert.Contains("gold", msg);
    }

    [Fact]
    public void CheckCompletions_IncludesRewardMessage()
    {
        var state = CreateQuestState();
        // Satisfy first_tower quest: build a tower
        int idx = SimMap.Idx(10, 8, state.MapW);
        state.Structures[idx] = "tower";

        var events = WorldQuests.CheckCompletions(state);
        Assert.NotEmpty(events);
        // Should contain reward info from Quests.CompleteQuest
        Assert.Contains(events, e => e.Contains("gold"));
    }

    [Fact]
    public void NpcRouting_QuestGiver_IncludesEconomyQuests()
    {
        var state = CreateQuestState();
        state.Day = 5; // ensure economy quests are unlocked

        // Place quest giver NPC adjacent to player
        state.Npcs.Add(new Dictionary<string, object>
        {
            ["type"] = "quest_giver",
            ["pos"] = new GridPoint(state.PlayerPos.X + 1, state.PlayerPos.Y),
            ["name"] = "Elder",
        });

        var result = NpcInteraction.TryInteract(state);
        Assert.NotNull(result);
        string lines = string.Join("\n", (List<string>)result!["lines"]);
        // Should mention economy quests like Supply Run
        Assert.Contains("Supply Run", lines);
    }

    [Fact]
    public void NpcRouting_Trainer_IncludesTutorialQuests()
    {
        var state = CreateQuestState();

        state.Npcs.Add(new Dictionary<string, object>
        {
            ["type"] = "trainer",
            ["pos"] = new GridPoint(state.PlayerPos.X + 1, state.PlayerPos.Y),
            ["name"] = "Sensei",
        });

        var result = NpcInteraction.TryInteract(state);
        Assert.NotNull(result);
        // Trainer should show tutorial quests (first_tower, first_night)
        var quests = result!.GetValueOrDefault("quests") as List<string>;
        Assert.NotNull(quests);
        Assert.Contains("first_tower", quests!);
    }

    [Fact]
    public void NewQuests_ExistInRegistry()
    {
        Assert.NotNull(Quests.GetQuest("supply_run"));
        Assert.NotNull(Quests.GetQuest("stone_collector"));
        Assert.NotNull(Quests.GetQuest("feast_preparation"));
        Assert.NotNull(Quests.GetQuest("defender_of_the_realm"));
    }

    [Fact]
    public void NewQuests_HaveResourceRewards()
    {
        var supplyRun = Quests.GetQuest("supply_run")!;
        Assert.True(supplyRun.Rewards.ContainsKey("wood"));

        var stoneCollector = Quests.GetQuest("stone_collector")!;
        Assert.True(stoneCollector.Rewards.ContainsKey("stone"));

        var feast = Quests.GetQuest("feast_preparation")!;
        Assert.True(feast.Rewards.ContainsKey("food"));
    }

    [Fact]
    public void Preconditions_NewQuests_DayGated()
    {
        var state = CreateQuestState();
        state.Day = 1;
        Assert.False(WorldQuests.IsPreconditionMet(state, "supply_run")); // requires day >= 2
        Assert.False(WorldQuests.IsPreconditionMet(state, "stone_collector")); // requires day >= 3

        state.Day = 5;
        Assert.True(WorldQuests.IsPreconditionMet(state, "supply_run"));
        Assert.True(WorldQuests.IsPreconditionMet(state, "stone_collector"));
        Assert.True(WorldQuests.IsPreconditionMet(state, "feast_preparation"));
    }
}
