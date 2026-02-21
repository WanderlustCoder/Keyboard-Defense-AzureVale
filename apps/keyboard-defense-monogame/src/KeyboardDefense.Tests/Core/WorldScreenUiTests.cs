using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Tests for core systems that the WorldScreen UI depends on:
/// InlineCombat edge cases, WorldQuests.GetProgress, ResourceChallenge,
/// NpcInteraction, and InlineCombat.TickEnemyApproach edge cases.
/// </summary>
public class WorldScreenUiTests
{
    // ─────────────────────────────────────────────────
    // InlineCombat.UpdatePartialProgress edge cases
    // ─────────────────────────────────────────────────

    [Fact]
    public void UpdatePartialProgress_EnemyWithEmptyWord_NeverMarkedAsTarget()
    {
        var state = CreateEncounterState();
        state.EncounterEnemies.Add(CreateEnemy(1, word: ""));
        state.EncounterEnemies.Add(CreateEnemy(2, word: "castle"));

        InlineCombat.UpdatePartialProgress(state, "cas");

        // Enemy with empty word should not be targeted
        Assert.Equal(0, Convert.ToInt32(state.EncounterEnemies[0]["typed_chars"]));
        Assert.True(state.EncounterEnemies[0]["is_target"] is false);
        // Normal enemy should still match
        Assert.Equal(3, Convert.ToInt32(state.EncounterEnemies[1]["typed_chars"]));
        Assert.True(state.EncounterEnemies[1]["is_target"] is true);
    }

    [Fact]
    public void UpdatePartialProgress_EnemyWithEmptyWord_EmptyInputDoesNotTarget()
    {
        var state = CreateEncounterState();
        state.EncounterEnemies.Add(CreateEnemy(1, word: ""));

        // Empty string starts with empty string in some languages, but the code
        // guards with !string.IsNullOrEmpty(typed), so empty input should not target anything
        InlineCombat.UpdatePartialProgress(state, "");

        Assert.Equal(0, Convert.ToInt32(state.EncounterEnemies[0]["typed_chars"]));
        Assert.True(state.EncounterEnemies[0]["is_target"] is false);
    }

    [Fact]
    public void UpdatePartialProgress_InputLongerThanAnyWord_NoEnemyTargeted()
    {
        var state = CreateEncounterState();
        state.EncounterEnemies.Add(CreateEnemy(1, word: "hi"));
        state.EncounterEnemies.Add(CreateEnemy(2, word: "go"));

        // Input is longer than any word and does not prefix-match
        InlineCombat.UpdatePartialProgress(state, "hijklmnop");

        Assert.Equal(0, Convert.ToInt32(state.EncounterEnemies[0]["typed_chars"]));
        Assert.True(state.EncounterEnemies[0]["is_target"] is false);
        Assert.Equal(0, Convert.ToInt32(state.EncounterEnemies[1]["typed_chars"]));
        Assert.True(state.EncounterEnemies[1]["is_target"] is false);
    }

    [Fact]
    public void UpdatePartialProgress_InputLongerThanWord_ButPrefixMatches_StillNotTargeted()
    {
        // "hi".StartsWith("hijklmnop") is false, so even though "hijklmnop" starts with "hi",
        // the code checks word.StartsWith(typed), not typed.StartsWith(word).
        var state = CreateEncounterState();
        state.EncounterEnemies.Add(CreateEnemy(1, word: "hi"));

        InlineCombat.UpdatePartialProgress(state, "hijklmnop");

        // The word "hi" does NOT start with "hijklmnop", so no match
        Assert.Equal(0, Convert.ToInt32(state.EncounterEnemies[0]["typed_chars"]));
        Assert.True(state.EncounterEnemies[0]["is_target"] is false);
    }

    // ─────────────────────────────────────────────────
    // WorldQuests.GetProgress
    // ─────────────────────────────────────────────────

    [Fact]
    public void GetProgress_KnownQuest_ReturnsNonZeroTarget()
    {
        var state = DefaultState.Create();

        var (current, target) = WorldQuests.GetProgress(state, "first_tower");

        Assert.True(target > 0, "Known quest should have a non-zero target");
        Assert.Equal(1, target); // first_tower requires building 1 tower
    }

    [Fact]
    public void GetProgress_UnknownQuest_ReturnsZeroZero()
    {
        var state = DefaultState.Create();

        var (current, target) = WorldQuests.GetProgress(state, "completely_made_up_quest_xyz");

        Assert.Equal(0, current);
        Assert.Equal(0, target);
    }

    [Fact]
    public void GetProgress_CompletedQuest_StillReturnsValidProgress()
    {
        var state = DefaultState.Create();
        // Complete the first_tower quest properly
        state.Structures[1] = "tower";
        state.CompletedQuests.Add("first_tower");

        // GetProgress should still work even on completed quests
        // (it reads game state, not completion status)
        var (current, target) = WorldQuests.GetProgress(state, "first_tower");

        Assert.True(target > 0, "Completed quest should still report valid target");
        Assert.True(current > 0, "With a tower built, current should be > 0");
        Assert.Equal(target, current); // Should show as fully completed
    }

    [Fact]
    public void GetProgress_MultipleQuestTypes_AllReturnPositiveTargets()
    {
        var state = DefaultState.Create();
        string[] knownQuests = { "first_tower", "explorer", "word_smith", "combo_master",
                                 "boss_slayer", "defender_of_the_realm", "wave_defender" };

        foreach (var questId in knownQuests)
        {
            var (_, target) = WorldQuests.GetProgress(state, questId);
            Assert.True(target > 0, $"Quest '{questId}' should have target > 0 but got {target}");
        }
    }

    // ─────────────────────────────────────────────────
    // ResourceChallenge
    // ─────────────────────────────────────────────────

    [Fact]
    public void StartChallenge_NotInExplorationMode_ReturnsNull()
    {
        var state = CreateHarvestState();
        PlaceNodeNearPlayer(state);

        state.ActivityMode = "encounter";
        var result = ResourceChallenge.StartChallenge(state);
        Assert.Null(result);

        state.ActivityMode = "harvest_challenge";
        result = ResourceChallenge.StartChallenge(state);
        Assert.Null(result);
    }

    [Fact]
    public void StartChallenge_NoResourceNodesExist_ReturnsNull()
    {
        var state = CreateHarvestState();
        state.ResourceNodes.Clear();

        var result = ResourceChallenge.StartChallenge(state);

        Assert.Null(result);
        Assert.Equal("exploration", state.ActivityMode);
    }

    [Fact]
    public void StartChallenge_ResourceNodesTooFarAway_ReturnsNull()
    {
        var state = CreateHarvestState();
        // Place node far from player (beyond InteractionRadius of 1)
        var farPos = new GridPoint(state.PlayerPos.X + 10, state.PlayerPos.Y + 10);
        int farIdx = SimMap.Idx(farPos.X, farPos.Y, state.MapW);
        state.ResourceNodes[farIdx] = new Dictionary<string, object>
        {
            ["type"] = "wood_grove",
            ["pos"] = farPos,
            ["cooldown"] = 0f,
        };

        var result = ResourceChallenge.StartChallenge(state);

        Assert.Null(result);
        Assert.Equal("exploration", state.ActivityMode);
    }

    [Fact]
    public void CancelChallenge_ResetsActivityModeToExploration()
    {
        var state = CreateHarvestState();
        PlaceNodeNearPlayer(state);

        ResourceChallenge.StartChallenge(state);
        Assert.Equal("harvest_challenge", state.ActivityMode);

        ResourceChallenge.CancelChallenge(state);

        Assert.Equal("exploration", state.ActivityMode);
    }

    [Fact]
    public void CancelChallenge_WhenNotInHarvestMode_DoesNothing()
    {
        var state = CreateHarvestState();
        state.ActivityMode = "encounter";

        ResourceChallenge.CancelChallenge(state);

        Assert.Equal("encounter", state.ActivityMode);
    }

    [Fact]
    public void TickCooldowns_DecrementsMultipleNodeCooldowns()
    {
        var state = CreateHarvestState();
        var pos1 = new GridPoint(state.PlayerPos.X + 2, state.PlayerPos.Y);
        var pos2 = new GridPoint(state.PlayerPos.X + 3, state.PlayerPos.Y);
        int idx1 = SimMap.Idx(pos1.X, pos1.Y, state.MapW);
        int idx2 = SimMap.Idx(pos2.X, pos2.Y, state.MapW);

        state.ResourceNodes[idx1] = new Dictionary<string, object>
        {
            ["type"] = "wood_grove", ["pos"] = pos1, ["cooldown"] = 8f,
        };
        state.ResourceNodes[idx2] = new Dictionary<string, object>
        {
            ["type"] = "stone_outcrop", ["pos"] = pos2, ["cooldown"] = 3f,
        };

        ResourceChallenge.TickCooldowns(state, 2f);

        float cd1 = Convert.ToSingle(state.ResourceNodes[idx1]["cooldown"]);
        float cd2 = Convert.ToSingle(state.ResourceNodes[idx2]["cooldown"]);
        Assert.Equal(6f, cd1, 0.01);
        Assert.Equal(1f, cd2, 0.01);
    }

    [Fact]
    public void TickCooldowns_NodeWithZeroCooldown_StaysAtZero()
    {
        var state = CreateHarvestState();
        var pos = state.PlayerPos;
        int idx = SimMap.Idx(pos.X, pos.Y, state.MapW);
        state.ResourceNodes[idx] = new Dictionary<string, object>
        {
            ["type"] = "wood_grove", ["pos"] = pos, ["cooldown"] = 0f,
        };

        ResourceChallenge.TickCooldowns(state, 5f);

        float cd = Convert.ToSingle(state.ResourceNodes[idx]["cooldown"]);
        Assert.Equal(0f, cd);
    }

    [Fact]
    public void TickCooldowns_LargeDelta_ClampsToZero()
    {
        var state = CreateHarvestState();
        var pos = state.PlayerPos;
        int idx = SimMap.Idx(pos.X, pos.Y, state.MapW);
        state.ResourceNodes[idx] = new Dictionary<string, object>
        {
            ["type"] = "wood_grove", ["pos"] = pos, ["cooldown"] = 2f,
        };

        ResourceChallenge.TickCooldowns(state, 100f);

        float cd = Convert.ToSingle(state.ResourceNodes[idx]["cooldown"]);
        Assert.Equal(0f, cd);
    }

    // ─────────────────────────────────────────────────
    // NpcInteraction
    // ─────────────────────────────────────────────────

    [Fact]
    public void TryInteract_NotInExplorationMode_ReturnsNull()
    {
        var state = CreateNpcState();
        PlaceNpcNearPlayer(state, "trainer");

        state.ActivityMode = "encounter";
        var result = NpcInteraction.TryInteract(state);
        Assert.Null(result);

        state.ActivityMode = "harvest_challenge";
        result = NpcInteraction.TryInteract(state);
        Assert.Null(result);
    }

    [Fact]
    public void TryInteract_NoNpcsInState_ReturnsNull()
    {
        var state = CreateNpcState();
        state.Npcs.Clear();

        var result = NpcInteraction.TryInteract(state);

        Assert.Null(result);
    }

    [Fact]
    public void TryInteract_SelectsClosestNpcWhenMultipleNearby()
    {
        var state = CreateNpcState();
        state.Npcs.Clear();

        // Place two NPCs near the player: one adjacent (distance 1), one at same position (distance 0)
        var farPos = new GridPoint(state.PlayerPos.X + 1, state.PlayerPos.Y);
        state.Npcs.Add(new Dictionary<string, object>
        {
            ["type"] = "merchant",
            ["pos"] = farPos,
            ["name"] = "Far Merchant",
        });

        var closePos = state.PlayerPos; // distance 0
        state.Npcs.Add(new Dictionary<string, object>
        {
            ["type"] = "trainer",
            ["pos"] = closePos,
            ["name"] = "Close Trainer",
        });

        var result = NpcInteraction.TryInteract(state);

        Assert.NotNull(result);
        Assert.Equal("Close Trainer", result!["speaker"]?.ToString());
    }

    [Fact]
    public void TryInteract_ResultContainsSpeakerAndLines()
    {
        var state = CreateNpcState();
        PlaceNpcNearPlayer(state, "trainer");

        var result = NpcInteraction.TryInteract(state);

        Assert.NotNull(result);
        Assert.True(result!.ContainsKey("speaker"), "Result should have 'speaker' key");
        Assert.True(result.ContainsKey("lines"), "Result should have 'lines' key");
        Assert.False(string.IsNullOrEmpty(result["speaker"]?.ToString()));
        var lines = result["lines"] as List<string>;
        Assert.NotNull(lines);
        Assert.NotEmpty(lines!);
    }

    [Fact]
    public void TryInteract_MerchantResult_ContainsSpeakerAndLines()
    {
        var state = CreateNpcState();
        PlaceNpcNearPlayer(state, "merchant");

        var result = NpcInteraction.TryInteract(state);

        Assert.NotNull(result);
        Assert.True(result!.ContainsKey("speaker"));
        Assert.True(result.ContainsKey("lines"));
        Assert.Equal("merchant", result["npc_type"]?.ToString());
    }

    [Fact]
    public void TryInteract_QuestGiverResult_ContainsSpeakerAndLines()
    {
        var state = CreateNpcState();
        PlaceNpcNearPlayer(state, "quest_giver");

        var result = NpcInteraction.TryInteract(state);

        Assert.NotNull(result);
        Assert.True(result!.ContainsKey("speaker"));
        Assert.True(result.ContainsKey("lines"));
        Assert.Equal("quest_giver", result["npc_type"]?.ToString());
    }

    [Fact]
    public void TryInteract_UnknownNpcType_ReturnsSpeakerAndEllipsisLine()
    {
        var state = CreateNpcState();
        state.Npcs.Clear();
        state.Npcs.Add(new Dictionary<string, object>
        {
            ["type"] = "mysterious_stranger",
            ["pos"] = new GridPoint(state.PlayerPos.X + 1, state.PlayerPos.Y),
            ["name"] = "Shadow",
        });

        var result = NpcInteraction.TryInteract(state);

        Assert.NotNull(result);
        Assert.Equal("Shadow", result!["speaker"]?.ToString());
        var lines = result["lines"] as List<string>;
        Assert.NotNull(lines);
        Assert.Contains("...", lines!);
    }

    [Fact]
    public void CompleteReadyQuests_NoQuestsCompletable_ReturnsEmptyList()
    {
        var state = CreateNpcState();
        // Clear all progress so nothing is completable
        state.Structures.Clear();
        state.EnemiesDefeated = 0;
        state.MaxComboEver = 0;
        state.WavesSurvived = 0;
        state.BossesDefeated.Clear();
        state.Discovered.Clear();
        state.TypingMetrics["battle_words_typed"] = 0;
        state.Day = 0;

        var events = NpcInteraction.CompleteReadyQuests(state);

        Assert.Empty(events);
    }

    [Fact]
    public void CompleteReadyQuests_WithCompletableQuest_CompletesAndReturnsEvents()
    {
        var state = CreateNpcState();
        state.Structures.Clear();
        state.Structures[1] = "tower"; // Satisfies "first_tower" quest

        var events = NpcInteraction.CompleteReadyQuests(state);

        Assert.Contains("first_tower", state.CompletedQuests);
        Assert.NotEmpty(events);
        Assert.Contains(events, e => e.Contains("Quest complete", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public void CompleteReadyQuests_AlreadyCompleted_DoesNotDuplicate()
    {
        var state = CreateNpcState();
        state.Structures.Clear();
        state.Structures[1] = "tower";
        state.CompletedQuests.Add("first_tower");

        // Zero out all progress so no other quests complete either
        state.EnemiesDefeated = 0;
        state.MaxComboEver = 0;
        state.WavesSurvived = 0;
        state.BossesDefeated.Clear();
        state.Discovered.Clear();
        state.TypingMetrics["battle_words_typed"] = 0;
        state.Day = 0;

        int goldBefore = state.Gold;
        var events = NpcInteraction.CompleteReadyQuests(state);

        // first_tower should not generate reward events again
        bool hasFirstTowerEvent = false;
        foreach (var e in events)
        {
            if (e.Contains("First Defense", StringComparison.OrdinalIgnoreCase))
                hasFirstTowerEvent = true;
        }
        Assert.False(hasFirstTowerEvent, "Already-completed quest should not be completed again");
        Assert.Equal(goldBefore, state.Gold);
    }

    // ─────────────────────────────────────────────────
    // InlineCombat.TickEnemyApproach edge cases
    // ─────────────────────────────────────────────────

    [Fact]
    public void TickEnemyApproach_NotInEncounterMode_ReturnsEmpty()
    {
        var state = CreateEncounterState();
        state.ActivityMode = "exploration";
        state.EncounterEnemies.Add(CreateEnemy(1, approachProgress: 0.5f));

        var events = InlineCombat.TickEnemyApproach(state, 1.0f);

        Assert.Empty(events);
        // Approach progress should NOT have changed
        Assert.Equal(0.5f, Convert.ToSingle(state.EncounterEnemies[0]["approach_progress"]), 3);
    }

    [Fact]
    public void TickEnemyApproach_NotInEncounterMode_HarvestChallenge_ReturnsEmpty()
    {
        var state = CreateEncounterState();
        state.ActivityMode = "harvest_challenge";
        state.EncounterEnemies.Add(CreateEnemy(1, approachProgress: 0.2f));

        var events = InlineCombat.TickEnemyApproach(state, 1.0f);

        Assert.Empty(events);
    }

    [Fact]
    public void TickEnemyApproach_ApproachAccumulatesOverMultipleTicks()
    {
        var state = CreateEncounterState();
        state.EncounterEnemies.Add(CreateEnemy(1, approachProgress: 0.0f));

        // Tick 1: delta = 0.5s -> approach += 0.3 * 0.5 = 0.15
        InlineCombat.TickEnemyApproach(state, 0.5f);
        float after1 = Convert.ToSingle(state.EncounterEnemies[0]["approach_progress"]);
        Assert.Equal(0.15f, after1, 3);

        // Tick 2: delta = 1.0s -> approach += 0.3 * 1.0 = 0.3 -> total 0.45
        InlineCombat.TickEnemyApproach(state, 1.0f);
        float after2 = Convert.ToSingle(state.EncounterEnemies[0]["approach_progress"]);
        Assert.Equal(0.45f, after2, 3);

        // Tick 3: delta = 0.5s -> approach += 0.3 * 0.5 = 0.15 -> total 0.60
        InlineCombat.TickEnemyApproach(state, 0.5f);
        float after3 = Convert.ToSingle(state.EncounterEnemies[0]["approach_progress"]);
        Assert.Equal(0.60f, after3, 3);
    }

    [Fact]
    public void TickEnemyApproach_ZeroDelta_DoesNotAdvance()
    {
        var state = CreateEncounterState();
        state.EncounterEnemies.Add(CreateEnemy(1, approachProgress: 0.5f));

        InlineCombat.TickEnemyApproach(state, 0.0f);

        float approach = Convert.ToSingle(state.EncounterEnemies[0]["approach_progress"]);
        Assert.Equal(0.5f, approach, 3);
    }

    [Fact]
    public void TickEnemyApproach_MultipleEnemiesApproachIndependently()
    {
        var state = CreateEncounterState();
        state.Hp = 20;
        state.EncounterEnemies.Add(CreateEnemy(1, approachProgress: 0.0f));
        state.EncounterEnemies.Add(CreateEnemy(2, approachProgress: 0.5f));

        InlineCombat.TickEnemyApproach(state, 1.0f);

        // Enemy 1: 0.0 + 0.3 * 1.0 = 0.3
        float ap1 = Convert.ToSingle(state.EncounterEnemies[0]["approach_progress"]);
        Assert.Equal(0.3f, ap1, 3);

        // Enemy 2: 0.5 + 0.3 * 1.0 = 0.8
        float ap2 = Convert.ToSingle(state.EncounterEnemies[1]["approach_progress"]);
        Assert.Equal(0.8f, ap2, 3);
    }

    [Fact]
    public void TickEnemyApproach_EnemyWithoutPos_IsSkippedSafely()
    {
        var state = CreateEncounterState();
        state.Hp = 10;
        // Create enemy without "pos" key
        var enemyNoPos = new Dictionary<string, object>
        {
            ["kind"] = "ghost",
            ["id"] = 1,
            ["word"] = "phantom",
            ["hp"] = 3,
            ["tier"] = 0,
            ["approach_progress"] = 0.5f,
        };
        state.EncounterEnemies.Add(enemyNoPos);

        // Should not throw and should return empty events
        var events = InlineCombat.TickEnemyApproach(state, 1.0f);

        // Enemy without pos is skipped by the "is not GridPoint" check
        // so approach_progress should not change and no damage occurs
        Assert.Equal(10, state.Hp);
    }

    // ─────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────

    private static GameState CreateEncounterState()
    {
        var state = DefaultState.Create();
        state.ActivityMode = "encounter";
        TypingMetrics.InitBattleMetrics(state);
        return state;
    }

    private static GameState CreateHarvestState()
    {
        var state = DefaultState.Create("harvest_ui_test");
        TypingMetrics.InitBattleMetrics(state);
        return state;
    }

    private static GameState CreateNpcState()
    {
        var state = DefaultState.Create("npc_ui_test");
        return state;
    }

    private static void PlaceNodeNearPlayer(GameState state)
    {
        var nodePos = state.PlayerPos;
        int nodeIdx = SimMap.Idx(nodePos.X, nodePos.Y, state.MapW);
        state.ResourceNodes[nodeIdx] = new Dictionary<string, object>
        {
            ["type"] = "wood_grove",
            ["pos"] = nodePos,
            ["zone"] = "safe",
            ["cooldown"] = 0f,
        };
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

    // ─────────────────────────────────────────────────
    // DailyChallenges integration (wired to WorldScreen)
    // ─────────────────────────────────────────────────

    [Fact]
    public void CheckProgress_DefeatEnemies_ReturnsCompletedWhenThresholdMet()
    {
        var state = new GameState { Day = 1, EnemiesDefeated = 0 };
        var challenges = DailyChallenges.GetTodaysChallenges(1);
        var defeatChallenge = challenges.Find(c => c.Type == ChallengeType.DefeatEnemies);
        if (defeatChallenge == null) return; // not in today's pool

        state.EnemiesDefeated = defeatChallenge.Target;
        var completed = DailyChallenges.CheckProgress(state);
        Assert.Contains(defeatChallenge.Id, completed);
    }

    [Fact]
    public void CompleteChallenge_AwardsGold()
    {
        var state = new GameState { Day = 1, Gold = 100 };
        var challenges = DailyChallenges.GetTodaysChallenges(1);
        var challenge = challenges[0];

        // Set up progress to complete
        SetupChallengeProgress(state, challenge);

        int goldBefore = state.Gold;
        var result = DailyChallenges.CompleteChallenge(state, challenge.Id);
        Assert.True(result["ok"] is true);
        Assert.True(state.Gold > goldBefore, "Gold should increase after challenge completion");
        Assert.Contains(challenge.Id, state.CompletedDailyChallenges);
    }

    [Fact]
    public void CompleteChallenge_AlreadyCompleted_ReturnsFalse()
    {
        var state = new GameState { Day = 1 };
        var challenges = DailyChallenges.GetTodaysChallenges(1);
        var challenge = challenges[0];
        state.CompletedDailyChallenges.Add(challenge.Id);

        var result = DailyChallenges.CompleteChallenge(state, challenge.Id);
        Assert.True(result["ok"] is false);
    }

    [Fact]
    public void CheckProgress_AlreadyCompleted_NotReturnedAgain()
    {
        var state = new GameState { Day = 1, EnemiesDefeated = 999, MaxComboEver = 999 };
        state.TypingMetrics["battle_words_typed"] = 999;
        state.PerfectNightsToday = 99;
        state.NoDamageNightsToday = 99;
        state.FastestNightSeconds = 10;

        var challenges = DailyChallenges.GetTodaysChallenges(1);

        // Complete all first
        foreach (var c in challenges)
            state.CompletedDailyChallenges.Add(c.Id);

        var completed = DailyChallenges.CheckProgress(state);
        Assert.Empty(completed);
    }

    [Fact]
    public void GetProgress_ComboStreak_ReturnsMaxCombo()
    {
        var state = new GameState { MaxComboEver = 12 };
        var challenges = DailyChallenges.GetTodaysChallenges(1);
        var comboChallenge = challenges.Find(c => c.Type == ChallengeType.ComboStreak);
        if (comboChallenge == null) return;

        var (current, target) = DailyChallenges.GetProgress(state, comboChallenge);
        Assert.Equal(Math.Min(12, target), current);
    }

    [Fact]
    public void GetProgress_SurviveDays_ReturnsDayCount()
    {
        var state = new GameState { Day = 7 };
        var challenges = DailyChallenges.GetTodaysChallenges(1);
        var surviveChallenge = challenges.Find(c => c.Type == ChallengeType.SurviveDays);
        if (surviveChallenge == null) return;

        var (current, target) = DailyChallenges.GetProgress(state, surviveChallenge);
        Assert.Equal(Math.Min(7, target), current);
    }

    [Fact]
    public void GetTodaysChallenges_Returns3Challenges()
    {
        var challenges = DailyChallenges.GetTodaysChallenges(1);
        Assert.Equal(3, challenges.Count);
    }

    [Fact]
    public void GetTodaysChallenges_DeterministicForSameDay()
    {
        var a = DailyChallenges.GetTodaysChallenges(1);
        var b = DailyChallenges.GetTodaysChallenges(1);
        Assert.Equal(a[0].Id, b[0].Id);
        Assert.Equal(a[1].Id, b[1].Id);
        Assert.Equal(a[2].Id, b[2].Id);
    }

    [Fact]
    public void GetTodaysChallenges_ScalesRewardsWithTier()
    {
        var earlyGame = DailyChallenges.GetChallengesForDate(DateTime.UtcNow, 1);
        var lateGame = DailyChallenges.GetChallengesForDate(DateTime.UtcNow, 20);

        // Late-game rewards should be at least as high (tier multiplier)
        int earlyTotal = earlyGame[0].Reward + earlyGame[1].Reward + earlyGame[2].Reward;
        int lateTotal = lateGame[0].Reward + lateGame[1].Reward + lateGame[2].Reward;
        Assert.True(lateTotal >= earlyTotal, "Late-game rewards should scale with tier");
    }

    [Fact]
    public void TimeUntilRefresh_ReturnsPositiveTimeSpan()
    {
        var remaining = DailyChallenges.TimeUntilRefresh();
        Assert.True(remaining.TotalSeconds > 0, "Time until refresh should be positive");
        Assert.True(remaining.TotalHours <= 24, "Time until refresh should be <= 24 hours");
    }

    private static void SetupChallengeProgress(GameState state, ChallengeDef challenge)
    {
        switch (challenge.Type)
        {
            case ChallengeType.DefeatEnemies:
                state.EnemiesDefeated = challenge.Target;
                break;
            case ChallengeType.TypeWords:
                state.TypingMetrics["battle_words_typed"] = challenge.Target;
                break;
            case ChallengeType.PerfectAccuracy:
                state.PerfectNightsToday = challenge.Target;
                break;
            case ChallengeType.ComboStreak:
                state.MaxComboEver = challenge.Target;
                break;
            case ChallengeType.SurviveDays:
                state.Day = challenge.Target;
                break;
            case ChallengeType.SpeedRun:
                state.FastestNightSeconds = challenge.Target - 1; // Under target = complete
                break;
            case ChallengeType.NoDamage:
                state.NoDamageNightsToday = challenge.Target;
                break;
        }
    }

    private static Dictionary<string, object> CreateEnemy(
        int id,
        string kind = "scout",
        string word = "mist",
        int hp = 5,
        int tier = 0,
        GridPoint? pos = null,
        float approachProgress = 0f)
    {
        return new Dictionary<string, object>
        {
            ["kind"] = kind,
            ["id"] = id,
            ["word"] = word,
            ["hp"] = hp,
            ["tier"] = tier,
            ["pos"] = pos ?? new GridPoint(5, 5),
            ["approach_progress"] = approachProgress,
        };
    }
}
