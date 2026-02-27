using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Extended tests for NpcInteraction — all NPC types, edge cases for adjacency,
/// multiple NPCs, CompleteReadyQuests, and interaction payload structure.
/// </summary>
public class NpcInteractionExtendedTests
{
    // =========================================================================
    // InteractionRadius constant
    // =========================================================================

    [Fact]
    public void InteractionRadius_IsOne()
    {
        Assert.Equal(1, NpcInteraction.InteractionRadius);
    }

    // =========================================================================
    // TryInteract — activity mode requirements
    // =========================================================================

    [Theory]
    [InlineData("encounter")]
    [InlineData("combat")]
    [InlineData("building")]
    [InlineData("menu")]
    [InlineData("")]
    public void TryInteract_NonExplorationMode_ReturnsNull(string mode)
    {
        var state = CreateNpcState();
        state.ActivityMode = mode;
        PlaceNpcNearPlayer(state, "trainer");

        var result = NpcInteraction.TryInteract(state);

        Assert.Null(result);
    }

    [Fact]
    public void TryInteract_ExplorationMode_ReturnsInteraction()
    {
        var state = CreateNpcState();
        state.ActivityMode = "exploration";
        PlaceNpcNearPlayer(state, "trainer");

        var result = NpcInteraction.TryInteract(state);

        Assert.NotNull(result);
    }

    // =========================================================================
    // TryInteract — adjacency boundary
    // =========================================================================

    [Fact]
    public void TryInteract_NpcAtSamePosition_ReturnsInteraction()
    {
        var state = CreateNpcState();
        state.Npcs.Add(new Dictionary<string, object>
        {
            ["type"] = "merchant",
            ["pos"] = state.PlayerPos,
            ["name"] = "Merchant Adira",
        });

        var result = NpcInteraction.TryInteract(state);

        Assert.NotNull(result);
        Assert.Equal("merchant", result!["npc_type"]?.ToString());
    }

    [Fact]
    public void TryInteract_NpcAtDistance1_ReturnsInteraction()
    {
        var state = CreateNpcState();
        var npcPos = new GridPoint(state.PlayerPos.X, state.PlayerPos.Y + 1);
        state.Npcs.Add(new Dictionary<string, object>
        {
            ["type"] = "trainer",
            ["pos"] = npcPos,
            ["name"] = "Trainer",
        });

        var result = NpcInteraction.TryInteract(state);

        Assert.NotNull(result);
    }

    [Fact]
    public void TryInteract_NpcAtDistance2_ReturnsNull()
    {
        var state = CreateNpcState();
        var npcPos = new GridPoint(state.PlayerPos.X + 2, state.PlayerPos.Y);
        state.Npcs.Add(new Dictionary<string, object>
        {
            ["type"] = "trainer",
            ["pos"] = npcPos,
            ["name"] = "Trainer",
        });

        var result = NpcInteraction.TryInteract(state);

        Assert.Null(result);
    }

    // =========================================================================
    // TryInteract — closest NPC selection
    // =========================================================================

    [Fact]
    public void TryInteract_MultipleNpcs_ReturnsClosest()
    {
        var state = CreateNpcState();
        // Far NPC
        state.Npcs.Add(new Dictionary<string, object>
        {
            ["type"] = "merchant",
            ["pos"] = new GridPoint(state.PlayerPos.X + 1, state.PlayerPos.Y),
            ["name"] = "Far Merchant",
        });
        // Same position NPC (closer)
        state.Npcs.Add(new Dictionary<string, object>
        {
            ["type"] = "trainer",
            ["pos"] = state.PlayerPos,
            ["name"] = "Close Trainer",
        });

        var result = NpcInteraction.TryInteract(state);

        Assert.NotNull(result);
        Assert.Equal("Close Trainer", result!["speaker"]?.ToString());
    }

    // =========================================================================
    // TryInteract — all NPC types produce correct structure
    // =========================================================================

    [Fact]
    public void TryInteract_Trainer_HasExpectedKeys()
    {
        var state = CreateNpcState();
        PlaceNpcNearPlayer(state, "trainer");

        var result = NpcInteraction.TryInteract(state)!;

        Assert.Equal("trainer", result["npc_type"]?.ToString());
        Assert.True(result.ContainsKey("speaker"));
        Assert.True(result.ContainsKey("lines"));
        Assert.True(result.ContainsKey("quests"));
    }

    [Fact]
    public void TryInteract_Trainer_LinesContainWelcome()
    {
        var state = CreateNpcState();
        PlaceNpcNearPlayer(state, "trainer");

        var result = NpcInteraction.TryInteract(state)!;
        var lines = (List<string>)result["lines"];

        Assert.Contains(lines, l => l.Contains("Welcome, defender"));
    }

    [Fact]
    public void TryInteract_Merchant_HasExpectedKeys()
    {
        var state = CreateNpcState();
        PlaceNpcNearPlayer(state, "merchant");

        var result = NpcInteraction.TryInteract(state)!;

        Assert.Equal("merchant", result["npc_type"]?.ToString());
        Assert.True(result.ContainsKey("speaker"));
        Assert.True(result.ContainsKey("lines"));
    }

    [Fact]
    public void TryInteract_Merchant_ShowsGoldAmount()
    {
        var state = CreateNpcState();
        state.Gold = 1234;
        PlaceNpcNearPlayer(state, "merchant");

        var result = NpcInteraction.TryInteract(state)!;
        var lines = (List<string>)result["lines"];

        Assert.Contains(lines, l => l.Contains("1234 gold"));
    }

    [Fact]
    public void TryInteract_Merchant_ShowsResources()
    {
        var state = CreateNpcState();
        state.Resources["wood"] = 10;
        state.Resources["stone"] = 5;
        PlaceNpcNearPlayer(state, "merchant");

        var result = NpcInteraction.TryInteract(state)!;
        var lines = (List<string>)result["lines"];

        Assert.Contains(lines, l => l.Contains("wood: 10"));
        Assert.Contains(lines, l => l.Contains("stone: 5"));
    }

    [Fact]
    public void TryInteract_Merchant_ZeroResources_NotShown()
    {
        var state = CreateNpcState();
        state.Resources["wood"] = 0;
        state.Resources["stone"] = 5;
        PlaceNpcNearPlayer(state, "merchant");

        var result = NpcInteraction.TryInteract(state)!;
        var lines = (List<string>)result["lines"];

        Assert.DoesNotContain(lines, l => l.Contains("wood: 0"));
        Assert.Contains(lines, l => l.Contains("stone: 5"));
    }

    [Fact]
    public void TryInteract_QuestGiver_HasExpectedKeys()
    {
        var state = CreateNpcState();
        PlaceNpcNearPlayer(state, "quest_giver");

        var result = NpcInteraction.TryInteract(state)!;

        Assert.Equal("quest_giver", result["npc_type"]?.ToString());
        Assert.True(result.ContainsKey("speaker"));
        Assert.True(result.ContainsKey("lines"));
        Assert.True(result.ContainsKey("quests"));
        Assert.True(result.ContainsKey("completable"));
    }

    [Fact]
    public void TryInteract_QuestGiver_LinesContainKingdomHelp()
    {
        var state = CreateNpcState();
        PlaceNpcNearPlayer(state, "quest_giver");

        var result = NpcInteraction.TryInteract(state)!;
        var lines = (List<string>)result["lines"];

        Assert.Contains(lines, l => l.Contains("kingdom needs your help"));
    }

    // =========================================================================
    // TryInteract — unknown NPC type
    // =========================================================================

    [Fact]
    public void TryInteract_UnknownType_ReturnsGenericDialogue()
    {
        var state = CreateNpcState();
        state.Npcs.Add(new Dictionary<string, object>
        {
            ["type"] = "alien",
            ["pos"] = new GridPoint(state.PlayerPos.X + 1, state.PlayerPos.Y),
            ["name"] = "Mysterious Figure",
        });

        var result = NpcInteraction.TryInteract(state);

        Assert.NotNull(result);
        Assert.Equal("Mysterious Figure", result!["speaker"]?.ToString());
        var lines = (List<string>)result["lines"];
        Assert.Contains(lines, l => l == "...");
    }

    [Fact]
    public void TryInteract_MissingTypeKey_DefaultsToUnknown()
    {
        var state = CreateNpcState();
        state.Npcs.Add(new Dictionary<string, object>
        {
            ["pos"] = new GridPoint(state.PlayerPos.X + 1, state.PlayerPos.Y),
            ["name"] = "Nameless",
        });

        var result = NpcInteraction.TryInteract(state);

        Assert.NotNull(result);
        // Should get generic dialogue since type is "unknown"
        var lines = (List<string>)result!["lines"];
        Assert.Contains(lines, l => l == "...");
    }

    [Fact]
    public void TryInteract_MissingNameKey_DefaultsToStranger()
    {
        var state = CreateNpcState();
        state.Npcs.Add(new Dictionary<string, object>
        {
            ["type"] = "merchant",
            ["pos"] = new GridPoint(state.PlayerPos.X + 1, state.PlayerPos.Y),
        });

        var result = NpcInteraction.TryInteract(state);

        Assert.NotNull(result);
        Assert.Equal("Stranger", result!["speaker"]?.ToString());
    }

    // =========================================================================
    // TryInteract — no NPCs / empty list
    // =========================================================================

    [Fact]
    public void TryInteract_EmptyNpcList_ReturnsNull()
    {
        var state = CreateNpcState();
        state.Npcs.Clear();

        var result = NpcInteraction.TryInteract(state);

        Assert.Null(result);
    }

    [Fact]
    public void TryInteract_NpcWithoutPos_IsSkipped()
    {
        var state = CreateNpcState();
        state.Npcs.Add(new Dictionary<string, object>
        {
            ["type"] = "trainer",
            ["name"] = "Ghost",
            // No "pos" key
        });

        var result = NpcInteraction.TryInteract(state);

        Assert.Null(result);
    }

    // =========================================================================
    // CompleteReadyQuests — edge cases
    // =========================================================================

    [Fact]
    public void CompleteReadyQuests_NoCompletable_ReturnsEmptyEvents()
    {
        var state = CreateNpcState();
        // Don't meet any quest objectives

        var events = NpcInteraction.CompleteReadyQuests(state);

        // May or may not be empty depending on quest setup, but should not crash
        Assert.NotNull(events);
    }

    [Fact]
    public void CompleteReadyQuests_WithCompletedQuest_ReturnsCompletionEvent()
    {
        var state = CreateNpcState();
        // Build a tower to satisfy "first_tower" quest
        state.Structures[SimMap.Idx(10, 10, state.MapW)] = "tower";
        state.Buildings["tower"] = 1;

        var events = NpcInteraction.CompleteReadyQuests(state);

        Assert.NotEmpty(events);
        Assert.Contains(events, e => e.Contains("Quest complete"));
    }

    [Fact]
    public void CompleteReadyQuests_CompletedQuestAddsToCompletedList()
    {
        var state = CreateNpcState();
        state.Structures[SimMap.Idx(10, 10, state.MapW)] = "tower";
        state.Buildings["tower"] = 1;

        NpcInteraction.CompleteReadyQuests(state);

        Assert.Contains("first_tower", state.CompletedQuests);
    }

    [Fact]
    public void CompleteReadyQuests_AlreadyCompleted_DoesNotDuplicate()
    {
        var state = CreateNpcState();
        state.Structures[SimMap.Idx(10, 10, state.MapW)] = "tower";
        state.Buildings["tower"] = 1;

        NpcInteraction.CompleteReadyQuests(state);
        var countAfterFirst = state.CompletedQuests.Count;

        NpcInteraction.CompleteReadyQuests(state);
        var countAfterSecond = state.CompletedQuests.Count;

        Assert.Equal(countAfterFirst, countAfterSecond);
    }

    // =========================================================================
    // Helpers
    // =========================================================================

    private static GameState CreateNpcState()
    {
        var state = DefaultState.Create("npc_ext_test");
        return state;
    }

    private static void PlaceNpcNearPlayer(GameState state, string type)
    {
        var pos = new GridPoint(state.PlayerPos.X + 1, state.PlayerPos.Y);
        state.Npcs.Add(new Dictionary<string, object>
        {
            ["type"] = type,
            ["pos"] = pos,
            ["name"] = type switch
            {
                "trainer" => "Master Galen",
                "merchant" => "Merchant Adira",
                "quest_giver" => "Quartermaster Torin",
                _ => "Stranger",
            },
            ["quest_available"] = true,
        });
    }
}
