using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class NpcInteractionTests
{
    private static GameState CreateNpcState()
    {
        var state = DefaultState.Create("npc_test");
        return state;
    }

    private static void PlaceNpcNearPlayer(GameState state, string type = "trainer")
    {
        var pos = new GridPoint(state.PlayerPos.X + 1, state.PlayerPos.Y);
        state.Npcs.Add(new Dictionary<string, object>
        {
            ["type"] = type,
            ["pos"] = pos,
            ["name"] = type == "trainer" ? "Master Galen" :
                       type == "merchant" ? "Merchant Adira" : "Quartermaster Torin",
            ["quest_available"] = true,
        });
    }

    [Fact]
    public void TryInteract_NpcAdjacent_ReturnsInteraction()
    {
        var state = CreateNpcState();
        PlaceNpcNearPlayer(state, "trainer");

        var result = NpcInteraction.TryInteract(state);

        Assert.NotNull(result);
        Assert.Equal("trainer", result!["npc_type"]?.ToString());
        Assert.Equal("Master Galen", result["speaker"]?.ToString());
    }

    [Fact]
    public void TryInteract_NoNpcNearby_ReturnsNull()
    {
        var state = CreateNpcState();
        state.Npcs.Clear();

        var result = NpcInteraction.TryInteract(state);

        Assert.Null(result);
    }

    [Fact]
    public void TryInteract_NotInExploration_ReturnsNull()
    {
        var state = CreateNpcState();
        state.ActivityMode = "encounter";
        PlaceNpcNearPlayer(state);

        var result = NpcInteraction.TryInteract(state);

        Assert.Null(result);
    }

    [Fact]
    public void TryInteract_NpcTooFar_ReturnsNull()
    {
        var state = CreateNpcState();
        // Place NPC far away
        state.Npcs.Add(new Dictionary<string, object>
        {
            ["type"] = "trainer",
            ["pos"] = new GridPoint(state.PlayerPos.X + 10, state.PlayerPos.Y),
            ["name"] = "Master Galen",
        });

        var result = NpcInteraction.TryInteract(state);

        Assert.Null(result);
    }

    [Fact]
    public void TryInteract_Trainer_HasDialogueLines()
    {
        var state = CreateNpcState();
        PlaceNpcNearPlayer(state, "trainer");

        var result = NpcInteraction.TryInteract(state)!;
        var lines = result["lines"] as List<string>;

        Assert.NotNull(lines);
        Assert.NotEmpty(lines!);
    }

    [Fact]
    public void TryInteract_Merchant_ShowsGold()
    {
        var state = CreateNpcState();
        state.Gold = 42;
        PlaceNpcNearPlayer(state, "merchant");

        var result = NpcInteraction.TryInteract(state)!;
        var lines = result["lines"] as List<string>;

        Assert.NotNull(lines);
        Assert.Contains(lines!, l => l.Contains("42 gold"));
    }

    [Fact]
    public void TryInteract_QuestGiver_ListsQuests()
    {
        var state = CreateNpcState();
        PlaceNpcNearPlayer(state, "quest_giver");

        var result = NpcInteraction.TryInteract(state)!;

        Assert.Equal("quest_giver", result["npc_type"]?.ToString());
        Assert.True(result.ContainsKey("quests"));
    }

    [Fact]
    public void CompleteReadyQuests_CompletesEligible()
    {
        var state = CreateNpcState();
        // Build a tower to satisfy "first_tower" quest
        state.Structures[SimMap.Idx(10, 10, state.MapW)] = "tower";
        state.Buildings["tower"] = 1;

        var events = NpcInteraction.CompleteReadyQuests(state);

        // first_tower should be completed
        Assert.Contains(state.CompletedQuests, q => q == "first_tower");
        Assert.NotEmpty(events);
    }
}
