using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Extended tests for IntentApplier night actions — Restart/New session actions,
/// multi-enemy kill sequences, tower attack edge cases, enemy move edge cases,
/// boss spawn on milestone days, victory conditions, and spawn word uniqueness.
/// </summary>
public class IntentApplierNightActionsExtendedTests
{
    // =========================================================================
    // Restart — session action
    // =========================================================================

    [Fact]
    public void Restart_DuringDayPhase_Rejected()
    {
        var state = DefaultState.Create();
        state.Phase = "day";

        var (newState, events, _) = Apply(state, "restart");

        Assert.Equal("day", newState.Phase);
        Assert.Contains("Restart is only available after game over or victory.", events);
    }

    [Fact]
    public void Restart_DuringNightPhase_Rejected()
    {
        var state = DefaultState.Create();
        state.Phase = "night";

        var (newState, events, _) = Apply(state, "restart");

        Assert.Equal("night", newState.Phase);
        Assert.Contains("Restart is only available after game over or victory.", events);
    }

    [Fact]
    public void Restart_DuringGameOver_CreatesFreshState()
    {
        var state = DefaultState.Create("test_seed");
        state.Phase = "game_over";
        state.Gold = 999;
        state.Day = 15;

        var (newState, events, _) = Apply(state, "restart");

        Assert.Equal("day", newState.Phase);
        Assert.Equal(1, newState.Day);
        Assert.Contains(events, e => e.Contains("Restarted run"));
        Assert.Contains(events, e => e.Contains("test_seed"));
    }

    [Fact]
    public void Restart_DuringVictory_CreatesFreshStateWithDifferentMessage()
    {
        var state = DefaultState.Create("victory_seed");
        state.Phase = "victory";
        state.Day = 21;

        var (newState, events, _) = Apply(state, "restart");

        Assert.Equal("day", newState.Phase);
        Assert.Equal(1, newState.Day);
        Assert.Contains(events, e => e.Contains("new challenge"));
    }

    [Fact]
    public void Restart_PreservesLessonId()
    {
        var state = DefaultState.Create();
        state.Phase = "game_over";
        state.LessonId = "custom_lesson";

        var (newState, _, _) = Apply(state, "restart");

        Assert.Equal("custom_lesson", newState.LessonId);
    }

    // =========================================================================
    // New — session action
    // =========================================================================

    [Fact]
    public void New_CreatesFreshState()
    {
        var state = DefaultState.Create("new_seed");
        state.Phase = "day";
        state.Gold = 500;
        state.Day = 10;

        var (newState, events, _) = Apply(state, "new");

        Assert.Equal("day", newState.Phase);
        Assert.Equal(1, newState.Day);
        Assert.Contains(events, e => e.Contains("New run started"));
    }

    [Fact]
    public void New_PreservesLessonId()
    {
        var state = DefaultState.Create();
        state.LessonId = "home_row";

        var (newState, _, _) = Apply(state, "new");

        Assert.Equal("home_row", newState.LessonId);
    }

    // =========================================================================
    // DefendInput — multi-enemy scenarios
    // =========================================================================

    [Fact]
    public void DefendInput_KillsEnemy_AwardsGoldAndIncrementsDefeated()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();
        state.Enemies.Add(Enemy(word: "kill", hp: 1, gold: 7, dist: 10));
        int goldBefore = state.Gold;
        int defeatedBefore = state.EnemiesDefeated;

        var (newState, events, _) = Apply(state, "defend_input", new()
        {
            ["text"] = "kill",
        });

        Assert.Empty(newState.Enemies);
        Assert.True(newState.Gold > goldBefore);
        Assert.Equal(defeatedBefore + 1, newState.EnemiesDefeated);
        Assert.Contains(events, e => e.Contains("defeated"));
    }

    [Fact]
    public void DefendInput_DamagesButDoesNotKill_KeepsEnemyAlive()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();
        state.Enemies.Add(Enemy(word: "tank", hp: 999, gold: 1, dist: 10));
        int goldBefore = state.Gold;

        var (newState, events, _) = Apply(state, "defend_input", new()
        {
            ["text"] = "tank",
        });

        Assert.Single(newState.Enemies);
        Assert.Equal(goldBefore, newState.Gold); // No gold for non-kill
        Assert.Contains(events, e => e.Contains("Enemy HP:"));
    }

    [Fact]
    public void DefendInput_MultipleEnemies_OnlyHitsMatchingWord()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();
        state.Enemies.Add(Enemy(word: "alpha", hp: 999, gold: 1, dist: 10));
        state.Enemies.Add(Enemy(word: "beta", hp: 1, gold: 5, dist: 10));
        state.Enemies.Add(Enemy(word: "gamma", hp: 999, gold: 1, dist: 10));

        var (newState, events, _) = Apply(state, "defend_input", new()
        {
            ["text"] = "beta",
        });

        // beta should be killed, alpha and gamma remain
        Assert.Equal(2, newState.Enemies.Count);
        Assert.Contains(newState.Enemies, e => e["word"]?.ToString() == "alpha");
        Assert.Contains(newState.Enemies, e => e["word"]?.ToString() == "gamma");
        Assert.DoesNotContain(newState.Enemies, e => e["word"]?.ToString() == "beta");
    }

    // =========================================================================
    // Wait — spawn and move interactions
    // =========================================================================

    [Fact]
    public void Wait_MultipleSpawns_UniqueWords()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.NightSpawnRemaining = 5;
        state.Enemies.Clear();

        // Do multiple waits to spawn enemies
        for (int i = 0; i < 3; i++)
        {
            Apply(state, "wait");
        }

        var words = state.Enemies
            .Select(e => e.GetValueOrDefault("word")?.ToString() ?? "")
            .Where(w => !string.IsNullOrEmpty(w))
            .ToList();

        // All words should be unique
        Assert.Equal(words.Count, words.Distinct().Count());
    }

    [Fact]
    public void Wait_NoSpawnsRemaining_NoNewEnemyAdded()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();
        state.Enemies.Add(Enemy(word: "existing", hp: 5, gold: 1, dist: 10));

        var (newState, events, _) = Apply(state, "wait");

        // Enemy count might decrease (if it reaches base) but shouldn't increase from spawn
        Assert.DoesNotContain(events, e => e.StartsWith("Enemy spawned:", StringComparison.Ordinal));
    }

    // =========================================================================
    // Tower attacks — edge cases
    // =========================================================================

    [Fact]
    public void Wait_MultipleAutoTowers_AllAttackFirstEnemy()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();
        state.Enemies.Add(Enemy(word: "target", hp: 10, gold: 3, dist: 10));

        // Place 2 auto-sentries
        int idx1 = SimMap.Idx(state.BasePos.X - 1, state.BasePos.Y, state.MapW);
        int idx2 = SimMap.Idx(state.BasePos.X + 1, state.BasePos.Y, state.MapW);
        state.Structures[idx1] = "auto_sentry";
        state.Structures[idx2] = "auto_sentry";

        var (newState, _, _) = Apply(state, "wait");

        // Each tower deals 1 damage, so HP should decrease by 2
        if (newState.Enemies.Count > 0)
        {
            int hp = Convert.ToInt32(newState.Enemies[0].GetValueOrDefault("hp", 0));
            Assert.Equal(8, hp);
        }
    }

    [Fact]
    public void Wait_NoAutoTowers_NoTowerDamage()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();
        state.Enemies.Add(Enemy(word: "safe", hp: 5, gold: 1, dist: 10));

        // Clear all auto structures
        var autoKeys = state.Structures.Where(kv => kv.Value.StartsWith("auto_")).Select(kv => kv.Key).ToList();
        foreach (var key in autoKeys) state.Structures.Remove(key);

        var (newState, events, _) = Apply(state, "wait");

        Assert.DoesNotContain(events, e => e.Contains("Auto-tower"));
    }

    [Fact]
    public void Wait_AutoTower_NoEnemies_NoCrash()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();

        int idx = SimMap.Idx(state.BasePos.X - 1, state.BasePos.Y, state.MapW);
        state.Structures[idx] = "auto_sentry";

        var (_, events, _) = Apply(state, "wait");

        Assert.DoesNotContain(events, e => e.Contains("Auto-tower"));
    }

    // =========================================================================
    // Enemy movement — multiple enemies reaching base
    // =========================================================================

    [Fact]
    public void Wait_MultipleEnemiesReachBase_AllDealDamage()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.NightSpawnRemaining = 0;
        state.Hp = 20;
        state.Enemies.Clear();
        state.Enemies.Add(Enemy(word: "a", hp: 5, gold: 1, dist: 1, damage: 2));
        state.Enemies.Add(Enemy(word: "b", hp: 5, gold: 1, dist: 1, damage: 3));
        // Clear auto-towers to avoid interference
        var autoKeys = state.Structures.Where(kv => kv.Value.StartsWith("auto_")).Select(kv => kv.Key).ToList();
        foreach (var key in autoKeys) state.Structures.Remove(key);

        var (newState, events, _) = Apply(state, "wait");

        Assert.Equal(15, newState.Hp); // 20 - 2 - 3
        Assert.Empty(newState.Enemies);
        Assert.Equal(2, events.Count(e => e.Contains("Enemy reached the base!")));
    }

    [Fact]
    public void Wait_EnemyMovesCloser_DistanceDecreases()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();
        state.Enemies.Add(Enemy(word: "far", hp: 5, gold: 1, dist: 5));
        // Clear auto-towers
        var autoKeys = state.Structures.Where(kv => kv.Value.StartsWith("auto_")).Select(kv => kv.Key).ToList();
        foreach (var key in autoKeys) state.Structures.Remove(key);

        var (newState, _, _) = Apply(state, "wait");

        Assert.Single(newState.Enemies);
        Assert.Equal(4, Convert.ToInt32(newState.Enemies[0]["dist"]));
    }

    // =========================================================================
    // Game over / Victory triggers
    // =========================================================================

    [Fact]
    public void Wait_GameOver_DoesNotTransitionToDawn()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.Hp = 2;
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();
        state.Enemies.Add(Enemy(word: "fatal", hp: 5, gold: 1, dist: 1, damage: 5));
        // Clear auto-towers
        var autoKeys = state.Structures.Where(kv => kv.Value.StartsWith("auto_")).Select(kv => kv.Key).ToList();
        foreach (var key in autoKeys) state.Structures.Remove(key);

        var (newState, events, _) = Apply(state, "wait");

        Assert.Equal("game_over", newState.Phase);
        Assert.Contains("Game Over.", events);
        Assert.DoesNotContain("Dawn breaks.", events);
        Assert.DoesNotContain("VICTORY", events);
    }

    [Fact]
    public void Wait_Day21_NoEnemies_NoSpawns_TriggersVictory()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.Day = 21;
        state.Threat = 1;
        state.NightSpawnRemaining = 0;
        state.NightWaveTotal = 1;
        state.Enemies.Clear();

        var (newState, events, _) = Apply(state, "wait");

        Assert.Equal("victory", newState.Phase);
        Assert.Contains("VICTORY! The kingdom is saved!", events);
        Assert.Contains(events, e => e.Contains("survived 21 days"));
    }

    [Fact]
    public void Wait_Day22_AlsoTriggersVictory()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.Day = 22;
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();

        var (newState, _, _) = Apply(state, "wait");

        Assert.Equal("victory", newState.Phase);
    }

    [Fact]
    public void Wait_Day20_NightCleared_TransitionsToDayNotVictory()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.Day = 20;
        state.NightSpawnRemaining = 0;
        state.NightWaveTotal = 1;
        state.Enemies.Clear();

        var (newState, events, _) = Apply(state, "wait");

        Assert.Equal("day", newState.Phase);
        Assert.Contains("Dawn breaks.", events);
        Assert.DoesNotContain("VICTORY", events);
    }

    // =========================================================================
    // Dawn — state reset
    // =========================================================================

    [Fact]
    public void Wait_Dawn_RestoresApToMax()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.Ap = 0;
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();

        var (newState, _, _) = Apply(state, "wait");

        Assert.Equal(newState.ApMax, newState.Ap);
    }

    [Fact]
    public void Wait_Dawn_DecrementsThreat()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.Threat = 5;
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();

        var (newState, _, _) = Apply(state, "wait");

        Assert.Equal(4, newState.Threat);
    }

    [Fact]
    public void Wait_Dawn_ThreatDoesNotGoBelowZero()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.Threat = 0;
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();

        var (newState, _, _) = Apply(state, "wait");

        Assert.Equal(0, newState.Threat);
    }

    [Fact]
    public void Wait_Dawn_ClearsNightPromptAndWaveTotal()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.NightPrompt = "some_prompt";
        state.NightWaveTotal = 10;
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();

        var (newState, _, _) = Apply(state, "wait");

        Assert.Equal("", newState.NightPrompt);
        Assert.Equal(0, newState.NightWaveTotal);
    }

    // =========================================================================
    // DefendInput — miss penalty
    // =========================================================================

    [Fact]
    public void DefendInput_MissMultipleTimes_AccumulatesDamage()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();
        state.Enemies.Add(Enemy(word: "alpha", hp: 999, gold: 1, dist: 10));
        int hpBefore = state.Hp;
        // Clear auto-towers
        var autoKeys = state.Structures.Where(kv => kv.Value.StartsWith("auto_")).Select(kv => kv.Key).ToList();
        foreach (var key in autoKeys) state.Structures.Remove(key);

        var (state2, _, _) = Apply(state, "defend_input", new() { ["text"] = "wrong1" });
        var (state3, _, _) = Apply(state2, "defend_input", new() { ["text"] = "wrong2" });

        Assert.Equal(hpBefore - 2, state3.Hp);
    }

    // =========================================================================
    // Wait — autosave request on dawn
    // =========================================================================

    [Fact]
    public void Wait_Dawn_ReturnsAutosaveRequest()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();

        var (_, _, result) = Apply(state, "wait");

        Assert.True(result.TryGetValue("request", out var requestObj));
        var request = Assert.IsType<Dictionary<string, object>>(requestObj);
        Assert.Equal("autosave", request["kind"]?.ToString());
        Assert.Equal("dawn", request["reason"]?.ToString());
    }

    // =========================================================================
    // Helpers
    // =========================================================================

    private static Dictionary<string, object> Enemy(
        string word,
        int hp,
        int gold,
        int dist,
        int damage = 1,
        string kind = "raider")
    {
        return new Dictionary<string, object>
        {
            ["word"] = word,
            ["hp"] = hp,
            ["gold"] = gold,
            ["dist"] = dist,
            ["damage"] = damage,
            ["kind"] = kind,
        };
    }

    private static (GameState State, List<string> Events, Dictionary<string, object> Result) Apply(
        GameState state,
        string kind,
        Dictionary<string, object>? payload = null)
    {
        var result = IntentApplier.Apply(state, SimIntents.Make(kind, payload));
        var newState = Assert.IsType<GameState>(result["state"]);
        var events = Assert.IsType<List<string>>(result["events"]);
        return (newState, events, result);
    }
}
