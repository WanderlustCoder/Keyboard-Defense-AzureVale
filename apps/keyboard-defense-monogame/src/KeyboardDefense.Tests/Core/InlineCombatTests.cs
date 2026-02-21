using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;

namespace KeyboardDefense.Tests.Core;

public class InlineCombatCoreTests
{
    [Fact]
    public void Constants_MatchExpectedValues()
    {
        Assert.Equal(2, InlineCombat.EncounterTriggerRadius);
        Assert.Equal(0.3f, InlineCombat.EnemyApproachSpeed, 3);
    }

    [Fact]
    public void AssignWords_AssignsNonEmptyWordToEveryEnemy()
    {
        var state = CreateEncounterState();
        var enemies = new List<Dictionary<string, object>>
        {
            CreateEnemy(1, kind: "scout"),
            CreateEnemy(2, kind: "raider"),
            CreateEnemy(3, kind: "armored"),
        };

        InlineCombat.AssignWords(state, enemies);

        foreach (var enemy in enemies)
        {
            string word = enemy.GetValueOrDefault("word")?.ToString() ?? "";
            Assert.False(string.IsNullOrWhiteSpace(word));
        }
    }

    [Fact]
    public void AssignWords_AssignsUniqueWordsAcrossEncounter()
    {
        var state = CreateEncounterState();
        var enemies = new List<Dictionary<string, object>>
        {
            CreateEnemy(1),
            CreateEnemy(2),
            CreateEnemy(3),
            CreateEnemy(4),
        };

        InlineCombat.AssignWords(state, enemies);

        var words = enemies.Select(e => e["word"]?.ToString() ?? "").ToList();
        Assert.Equal(words.Count, words.Distinct(StringComparer.OrdinalIgnoreCase).Count());
    }

    [Fact]
    public void AssignWords_DifferentEnemiesReceiveDifferentWords()
    {
        var state = CreateEncounterState();
        var enemies = new List<Dictionary<string, object>>
        {
            CreateEnemy(10, kind: "scout"),
            CreateEnemy(11, kind: "scout"),
        };

        InlineCombat.AssignWords(state, enemies);

        string first = enemies[0]["word"]?.ToString() ?? "";
        string second = enemies[1]["word"]?.ToString() ?? "";
        Assert.NotEqual(first, second);
    }

    [Fact]
    public void ProcessTyping_NotInEncounterMode_ReturnsEmptyEvents()
    {
        var state = CreateEncounterState();
        state.ActivityMode = "exploration";
        state.EncounterEnemies.Add(CreateEnemy(1, word: "mist", hp: 10));

        int hpBefore = Convert.ToInt32(state.EncounterEnemies[0]["hp"]);
        var events = InlineCombat.ProcessTyping(state, "mist");

        Assert.Empty(events);
        Assert.Equal(hpBefore, Convert.ToInt32(state.EncounterEnemies[0]["hp"]));
    }

    [Fact]
    public void ProcessTyping_EmptyInput_ReturnsEmptyEvents()
    {
        var state = CreateEncounterState();
        state.EncounterEnemies.Add(CreateEnemy(1, word: "mist", hp: 10));

        var events = InlineCombat.ProcessTyping(state, "   ");

        Assert.Empty(events);
        Assert.Equal(10, Convert.ToInt32(state.EncounterEnemies[0]["hp"]));
    }

    [Fact]
    public void ProcessTyping_WrongWord_ReturnsMissAndDoesNotDamageEnemy()
    {
        var state = CreateEncounterState();
        state.EncounterEnemies.Add(CreateEnemy(1, word: "mist", hp: 8));

        var events = InlineCombat.ProcessTyping(state, "wrong");

        Assert.Single(events);
        Assert.Contains("Miss", events[0], StringComparison.OrdinalIgnoreCase);
        Assert.Equal(8, Convert.ToInt32(state.EncounterEnemies[0]["hp"]));
    }

    [Fact]
    public void ProcessTyping_WrongWord_IncrementsBattleErrorsMetric()
    {
        var state = CreateEncounterState();
        state.EncounterEnemies.Add(CreateEnemy(1, word: "mist", hp: 8));

        InlineCombat.ProcessTyping(state, "wrong");

        Assert.Equal(1, Convert.ToInt32(state.TypingMetrics["battle_errors"]));
    }

    [Fact]
    public void ProcessTyping_CorrectWord_DealsDamageAndReturnsEvents()
    {
        var state = CreateEncounterState();
        state.EncounterEnemies.Add(CreateEnemy(1, word: "mist", hp: 50));

        var events = InlineCombat.ProcessTyping(state, "mist");

        Assert.NotEmpty(events);
        Assert.True(Convert.ToInt32(state.EncounterEnemies[0]["hp"]) < 50);
    }

    [Fact]
    public void ProcessTyping_CorrectWord_IncrementsComboAndWordsTypedMetric()
    {
        var state = CreateEncounterState();
        state.EncounterEnemies.Add(CreateEnemy(1, word: "mist", hp: 50));

        InlineCombat.ProcessTyping(state, "mist");

        Assert.Equal(1, TypingMetrics.GetComboCount(state));
        Assert.Equal(1, Convert.ToInt32(state.TypingMetrics["battle_words_typed"]));
    }

    [Fact]
    public void ProcessTyping_LethalDamage_RemovesEnemyIncrementsDefeatedAndAwardsGold()
    {
        var state = CreateEncounterState();
        state.EncounterEnemies.Add(CreateEnemy(1, word: "mist", hp: 1, tier: 2));
        int goldBefore = state.Gold;

        var events = InlineCombat.ProcessTyping(state, "mist");

        Assert.Empty(state.EncounterEnemies);
        Assert.Equal(1, state.EnemiesDefeated);
        Assert.Equal(goldBefore + 7, state.Gold);
        Assert.Contains(events, e => e.Contains("Defeated", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public void ProcessTyping_LastEnemyKilled_EndsEncounter()
    {
        var state = CreateEncounterState();
        state.EncounterEnemies.Add(CreateEnemy(1, word: "mist", hp: 1));

        var events = InlineCombat.ProcessTyping(state, "mist");

        Assert.Equal("exploration", state.ActivityMode);
        Assert.Empty(state.EncounterEnemies);
        Assert.Contains(events, e => e.Contains("Encounter cleared", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public void ProcessTyping_MatchingIsCaseInsensitive()
    {
        var state = CreateEncounterState();
        state.EncounterEnemies.Add(CreateEnemy(1, word: "scout", hp: 1));

        var events = InlineCombat.ProcessTyping(state, "SCOUT");

        Assert.Empty(state.EncounterEnemies);
        Assert.Contains(events, e => e.Contains("Defeated", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public void TickEnemyApproach_NotInEncounterMode_ReturnsEmptyEvents()
    {
        var state = CreateEncounterState();
        state.ActivityMode = "exploration";
        state.EncounterEnemies.Add(CreateEnemy(1, approachProgress: 0.4f));

        var events = InlineCombat.TickEnemyApproach(state, 1.0f);

        Assert.Empty(events);
        Assert.Equal(0.4f, Convert.ToSingle(state.EncounterEnemies[0]["approach_progress"]), 3);
    }

    [Fact]
    public void TickEnemyApproach_AdvancesApproachProgressBySpeedTimesDelta()
    {
        var state = CreateEncounterState();
        state.EncounterEnemies.Add(CreateEnemy(1, approachProgress: 0.1f));

        InlineCombat.TickEnemyApproach(state, 2.0f);

        float approach = Convert.ToSingle(state.EncounterEnemies[0]["approach_progress"]);
        Assert.Equal(0.7f, approach, 3);
    }

    [Fact]
    public void TickEnemyApproach_EnemyReachesPlayer_DamagesPlayerAndRemovesEnemy()
    {
        var state = CreateEncounterState();
        state.Hp = 10;
        state.EncounterEnemies.Add(CreateEnemy(1, tier: 0, approachProgress: 0.95f));
        state.EncounterEnemies.Add(CreateEnemy(2, tier: 0, approachProgress: 0.0f));

        var events = InlineCombat.TickEnemyApproach(state, 1.0f);

        Assert.Equal(9, state.Hp);
        Assert.Single(state.EncounterEnemies);
        Assert.Equal(2, Convert.ToInt32(state.EncounterEnemies[0]["id"]));
        Assert.Contains(events, e => e.Contains("strikes you", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public void TickEnemyApproach_HighTierEnemyDealsOnePlusTierDamage()
    {
        var state = CreateEncounterState();
        state.Hp = 10;
        state.EncounterEnemies.Add(CreateEnemy(1, tier: 3, approachProgress: 0.99f));

        InlineCombat.TickEnemyApproach(state, 1.0f);

        Assert.Equal(6, state.Hp);
    }

    [Fact]
    public void TickEnemyApproach_HpReachesZero_SetsPhaseToGameOver()
    {
        var state = CreateEncounterState();
        state.Hp = 1;
        state.EncounterEnemies.Add(CreateEnemy(1, tier: 0, approachProgress: 0.99f));

        var events = InlineCombat.TickEnemyApproach(state, 1.0f);

        Assert.Equal("game_over", state.Phase);
        Assert.Equal("encounter", state.ActivityMode);
        Assert.Contains(events, e => e.Contains("defeated", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public void TickEnemyApproach_WhenAllEnemiesAreGone_EncounterEnds()
    {
        var state = CreateEncounterState();
        state.Hp = 10;
        state.EncounterEnemies.Add(CreateEnemy(1, tier: 0, approachProgress: 0.99f));

        var events = InlineCombat.TickEnemyApproach(state, 1.0f);

        Assert.Equal("exploration", state.ActivityMode);
        Assert.Empty(state.EncounterEnemies);
        Assert.Contains(events, e => e.Contains("Encounter cleared", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public void EndEncounter_SetsExplorationModeAndClearsEncounterEnemies()
    {
        var state = CreateEncounterState();
        state.EncounterEnemies.Add(CreateEnemy(1));
        state.EncounterEnemies.Add(CreateEnemy(2));

        InlineCombat.EndEncounter(state);

        Assert.Equal("exploration", state.ActivityMode);
        Assert.Empty(state.EncounterEnemies);
    }

    [Fact]
    public void EndEncounter_ResetsCombo()
    {
        var state = CreateEncounterState();
        TypingMetrics.IncrementCombo(state);
        TypingMetrics.IncrementCombo(state);
        Assert.Equal(2, TypingMetrics.GetComboCount(state));

        InlineCombat.EndEncounter(state);

        Assert.Equal(0, TypingMetrics.GetComboCount(state));
    }

    private static GameState CreateEncounterState()
    {
        var state = DefaultState.Create();
        state.ActivityMode = "encounter";
        TypingMetrics.InitBattleMetrics(state);
        return state;
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
