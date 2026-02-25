using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class IntentApplierNightActionsTests
{
    [Fact]
    public void Wait_DuringDay_RejectsAction()
    {
        var state = DefaultState.Create();
        state.Phase = "day";

        var (newState, events, result) = Apply(state, "wait");

        Assert.Equal("day", newState.Phase);
        Assert.Contains("Wait is only available at night.", events);
        Assert.False(result.ContainsKey("request"));
    }

    [Fact]
    public void DefendInput_DuringDay_RejectsAction()
    {
        var state = DefaultState.Create();
        state.Phase = "day";

        var (newState, events, result) = Apply(state, "defend_input", new()
        {
            ["text"] = "alpha",
        });

        Assert.Equal("day", newState.Phase);
        Assert.Contains("No threats to defend right now.", events);
        Assert.False(result.ContainsKey("request"));
    }

    [Fact]
    public void DefendInput_WithEmptyText_RequestsEnemyWord()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        int hpBefore = state.Hp;

        var (newState, events, result) = Apply(state, "defend_input", new()
        {
            ["text"] = "   ",
        });

        Assert.Equal(hpBefore, newState.Hp);
        Assert.Contains("Type an enemy word to defend.", events);
        Assert.False(result.ContainsKey("request"));
    }

    [Fact]
    public void DefendInput_PrefersExactMatchOverPrefixMatches()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();
        state.Enemies.Add(Enemy(word: "alpha", hp: 8, gold: 2, dist: 6));
        state.Enemies.Add(Enemy(word: "al", hp: 1, gold: 3, dist: 6));
        int goldBefore = state.Gold;

        var (newState, events, _) = Apply(state, "defend_input", new()
        {
            ["text"] = "al",
        });

        Assert.Single(newState.Enemies);
        Assert.Equal("alpha", newState.Enemies[0]["word"]?.ToString());
        Assert.Equal(goldBefore + 3, newState.Gold);
        Assert.Contains(events, e => e.Contains("Typed 'al'", StringComparison.Ordinal));
    }

    [Fact]
    public void DefendInput_UsesPrefixFallbackWhenExactMatchMissing()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();
        state.Enemies.Add(Enemy(word: "alpha", hp: 1, gold: 4, dist: 6));
        state.Enemies.Add(Enemy(word: "bravo", hp: 9, gold: 2, dist: 6));
        int goldBefore = state.Gold;

        var (newState, events, _) = Apply(state, "defend_input", new()
        {
            ["text"] = "alp",
        });

        Assert.Single(newState.Enemies);
        Assert.Equal("bravo", newState.Enemies[0]["word"]?.ToString());
        Assert.Equal(goldBefore + 4, newState.Gold);
        Assert.Contains(events, e => e.Contains("Typed 'alp'", StringComparison.Ordinal));
    }

    [Fact]
    public void DefendInput_MissAgainstExistingEnemies_AppliesHpPenalty()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();
        state.Enemies.Add(Enemy(word: "alpha", hp: 4, gold: 1, dist: 6));
        int hpBefore = state.Hp;

        var (newState, events, _) = Apply(state, "defend_input", new()
        {
            ["text"] = "wrong",
        });

        Assert.Equal(hpBefore - 1, newState.Hp);
        Assert.Contains("Miss. No matching enemy word.", events);
    }

    [Fact]
    public void DefendInput_MissInPracticeMode_DoesNotApplyHpPenalty()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.PracticeMode = true;
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();
        state.Enemies.Add(Enemy(word: "alpha", hp: 4, gold: 1, dist: 6));
        int hpBefore = state.Hp;

        var (newState, events, _) = Apply(state, "defend_input", new()
        {
            ["text"] = "wrong",
        });

        Assert.Equal(hpBefore, newState.Hp);
        Assert.Contains("Miss. (practice mode - no damage)", events);
    }

    [Fact]
    public void DefendInput_WhenNoEnemies_PromptsAndAdvancesWithoutMissPenalty()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.NightSpawnRemaining = 0;
        state.NightWaveTotal = 4;
        state.NightPrompt = "word";
        state.Threat = 2;
        state.Enemies.Clear();
        int hpBefore = state.Hp;

        var (newState, events, result) = Apply(state, "defend_input", new()
        {
            ["text"] = "alpha",
        });
        var request = RequireRequest(result);

        Assert.Equal(hpBefore, newState.Hp);
        Assert.Equal("day", newState.Phase);
        Assert.Contains("No enemies yet; wait or defend after spawn.", events);
        Assert.Contains("Waited.", events);
        Assert.Equal("autosave", request["kind"]?.ToString());
        Assert.Equal("dawn", request["reason"]?.ToString());
    }

    [Fact]
    public void Wait_SpawnsEnemy_DecrementsSpawnRemaining_AndAvoidsExistingWord()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.NightSpawnRemaining = 1;
        state.Enemies.Clear();
        state.Enemies.Add(Enemy(word: "mist", hp: 6, gold: 1, dist: 6));

        var (newState, events, result) = Apply(state, "wait");

        Assert.Equal("night", newState.Phase);
        Assert.Equal(0, newState.NightSpawnRemaining);
        Assert.Equal(2, newState.Enemies.Count);
        Assert.False(string.Equals("mist", newState.Enemies[1]["word"]?.ToString(), StringComparison.OrdinalIgnoreCase));
        Assert.Contains(events, e => e.StartsWith("Enemy spawned: '", StringComparison.Ordinal));
        Assert.False(result.ContainsKey("request"));
    }

    [Fact]
    public void Wait_AutoTowerDamagesFirstEnemyOnly()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();
        state.Enemies.Add(Enemy(word: "first", hp: 5, gold: 2, dist: 6));
        state.Enemies.Add(Enemy(word: "second", hp: 5, gold: 2, dist: 6));
        int towerIndex = SimMap.Idx(state.BasePos.X - 1, state.BasePos.Y, state.MapW);
        state.Structures[towerIndex] = "auto_sentry";

        var (newState, _, _) = Apply(state, "wait");

        var first = newState.Enemies.Single(e => string.Equals(e["word"]?.ToString(), "first", StringComparison.Ordinal));
        var second = newState.Enemies.Single(e => string.Equals(e["word"]?.ToString(), "second", StringComparison.Ordinal));
        Assert.Equal(4, Convert.ToInt32(first.GetValueOrDefault("hp", 0)));
        Assert.Equal(5, Convert.ToInt32(second.GetValueOrDefault("hp", 0)));
    }

    [Fact]
    public void Wait_AutoTowerKill_RemovesEnemyAndAwardsGold()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();
        state.Enemies.Add(Enemy(word: "first", hp: 1, gold: 4, dist: 6));
        state.Enemies.Add(Enemy(word: "second", hp: 5, gold: 2, dist: 6));
        int towerIndex = SimMap.Idx(state.BasePos.X - 1, state.BasePos.Y, state.MapW);
        state.Structures[towerIndex] = "auto_sentry";
        int goldBefore = state.Gold;
        int defeatedBefore = state.EnemiesDefeated;

        var (newState, events, result) = Apply(state, "wait");

        Assert.DoesNotContain(newState.Enemies, e => string.Equals(e["word"]?.ToString(), "first", StringComparison.Ordinal));
        Assert.Contains(newState.Enemies, e => string.Equals(e["word"]?.ToString(), "second", StringComparison.Ordinal));
        Assert.Equal(goldBefore + 4, newState.Gold);
        Assert.Equal(defeatedBefore + 1, newState.EnemiesDefeated);
        Assert.Contains("Auto-tower defeats enemy! +4 gold.", events);
        Assert.False(result.ContainsKey("request"));
    }

    [Fact]
    public void Wait_EnemyReachesBase_DealsDamageAndIsRemoved()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();
        state.Enemies.Add(Enemy(word: "raider", hp: 3, gold: 2, dist: 1, damage: 3));
        int hpBefore = state.Hp;

        var (newState, events, _) = Apply(state, "wait");

        Assert.Equal(hpBefore - 3, newState.Hp);
        Assert.Empty(newState.Enemies);
        Assert.Contains("Enemy reached the base! -3 HP.", events);
    }

    [Fact]
    public void Wait_HpDropsToZero_TriggersGameOverBeforeDawn()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.Hp = 1;
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();
        state.Enemies.Add(Enemy(word: "raider", hp: 3, gold: 2, dist: 1, damage: 1));

        var (newState, events, result) = Apply(state, "wait");

        Assert.Equal("game_over", newState.Phase);
        Assert.Contains("Game Over.", events);
        Assert.DoesNotContain("Dawn breaks.", events);
        Assert.False(result.ContainsKey("request"));
    }

    [Fact]
    public void Wait_WhenNightIsCleared_TransitionsToDayAndResetsNightState()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.Ap = 0;
        state.Threat = 3;
        state.NightSpawnRemaining = 0;
        state.NightWaveTotal = 6;
        state.NightPrompt = "pending";
        state.Enemies.Clear();

        var (newState, events, result) = Apply(state, "wait");
        var request = RequireRequest(result);

        Assert.Equal("day", newState.Phase);
        Assert.Equal(newState.ApMax, newState.Ap);
        Assert.Equal(2, newState.Threat);
        Assert.Equal("", newState.NightPrompt);
        Assert.Equal(0, newState.NightWaveTotal);
        Assert.Contains("Dawn breaks.", events);
        Assert.Equal("autosave", request["kind"]?.ToString());
        Assert.Equal("dawn", request["reason"]?.ToString());
    }

    [Fact]
    public void Wait_Day21ClearedNight_TransitionsToVictoryAndEmitsSummary()
    {
        var state = DefaultState.Create();
        state.Day = 21;
        state.Phase = "night";
        state.Ap = 0;
        state.Threat = 2;
        state.Gold = 123;
        state.NightSpawnRemaining = 0;
        state.NightWaveTotal = 8;
        state.Enemies.Clear();

        var (newState, events, result) = Apply(state, "wait");
        var request = RequireRequest(result);

        Assert.Equal("victory", newState.Phase);
        Assert.Equal(newState.ApMax, newState.Ap);
        Assert.Equal(1, newState.Threat);
        Assert.Contains("VICTORY! The kingdom is saved!", events);
        Assert.Contains("You survived 21 days and defeated all bosses.", events);
        Assert.Contains("Final gold: 123", events);
        Assert.DoesNotContain("Dawn breaks.", events);
        Assert.Equal("autosave", request["kind"]?.ToString());
        Assert.Equal("dawn", request["reason"]?.ToString());
    }

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

    private static Dictionary<string, object> RequireRequest(Dictionary<string, object> result)
    {
        Assert.True(result.TryGetValue("request", out object? requestObj));
        return Assert.IsType<Dictionary<string, object>>(requestObj);
    }
}
