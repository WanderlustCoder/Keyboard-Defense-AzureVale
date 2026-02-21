using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class InlineCombatTests
{
    private static GameState CreateCombatState()
    {
        var state = DefaultState.Create("combat_test");
        state.ActivityMode = "encounter";
        TypingMetrics.InitBattleMetrics(state);
        return state;
    }

    private static Dictionary<string, object> MakeEnemy(int id, string kind = "raider", int hp = 3, int tier = 0)
    {
        return new Dictionary<string, object>
        {
            ["id"] = id,
            ["kind"] = kind,
            ["hp"] = hp,
            ["tier"] = tier,
            ["word"] = "test",
            ["pos"] = new GridPoint(32, 30),
            ["approach_progress"] = 0f,
        };
    }

    // --- AssignWords ---

    [Fact]
    public void AssignWords_SetsWordOnEachEnemy()
    {
        var state = CreateCombatState();
        var enemies = new List<Dictionary<string, object>>
        {
            MakeEnemy(1),
            MakeEnemy(2),
            MakeEnemy(3),
        };

        InlineCombat.AssignWords(state, enemies);

        foreach (var enemy in enemies)
        {
            string word = enemy.GetValueOrDefault("word")?.ToString() ?? "";
            Assert.False(string.IsNullOrEmpty(word), "Each enemy should have a word assigned");
        }
    }

    [Fact]
    public void AssignWords_NoDuplicateWords()
    {
        var state = CreateCombatState();
        var enemies = new List<Dictionary<string, object>>
        {
            MakeEnemy(1),
            MakeEnemy(2),
            MakeEnemy(3),
        };

        InlineCombat.AssignWords(state, enemies);

        var words = enemies.Select(e => e["word"]?.ToString()).ToList();
        Assert.Equal(words.Count, words.Distinct().Count());
    }

    // --- ProcessTyping ---

    [Fact]
    public void ProcessTyping_CorrectWord_DamagesEnemy()
    {
        var state = CreateCombatState();
        var enemy = MakeEnemy(1, hp: 10);
        enemy["word"] = "hello";
        state.EncounterEnemies.Add(enemy);

        var events = InlineCombat.ProcessTyping(state, "hello");

        int hp = Convert.ToInt32(enemy["hp"]);
        Assert.True(hp < 10, "Enemy HP should decrease after correct word");
        Assert.NotEmpty(events);
    }

    [Fact]
    public void ProcessTyping_CorrectWord_KillsEnemy()
    {
        var state = CreateCombatState();
        var enemy = MakeEnemy(1, hp: 1);
        enemy["word"] = "die";
        state.EncounterEnemies.Add(enemy);

        var events = InlineCombat.ProcessTyping(state, "die");

        Assert.Empty(state.EncounterEnemies);
        Assert.True(events.Any(e => e.Contains("Defeated")));
    }

    [Fact]
    public void ProcessTyping_WrongWord_ReturnsMissEvent()
    {
        var state = CreateCombatState();
        var enemy = MakeEnemy(1);
        enemy["word"] = "hello";
        state.EncounterEnemies.Add(enemy);

        var events = InlineCombat.ProcessTyping(state, "wrong");

        Assert.True(events.Any(e => e.Contains("Miss")));
        Assert.Single(state.EncounterEnemies); // enemy still alive
    }

    [Fact]
    public void ProcessTyping_CaseInsensitive()
    {
        var state = CreateCombatState();
        var enemy = MakeEnemy(1, hp: 1);
        enemy["word"] = "Hello";
        state.EncounterEnemies.Add(enemy);

        var events = InlineCombat.ProcessTyping(state, "HELLO");

        Assert.Empty(state.EncounterEnemies);
    }

    [Fact]
    public void ProcessTyping_AwardsGold()
    {
        var state = CreateCombatState();
        int goldBefore = state.Gold;
        var enemy = MakeEnemy(1, hp: 1, tier: 0);
        enemy["word"] = "gold";
        state.EncounterEnemies.Add(enemy);

        InlineCombat.ProcessTyping(state, "gold");

        Assert.True(state.Gold > goldBefore, "Killing an enemy should award gold");
    }

    [Fact]
    public void ProcessTyping_IncrementsCombo()
    {
        var state = CreateCombatState();
        // Use high HP so enemy survives (EndEncounter resets combo on last kill)
        var enemy1 = MakeEnemy(1, hp: 1);
        enemy1["word"] = "first";
        var enemy2 = MakeEnemy(2, hp: 100);
        enemy2["word"] = "second";
        state.EncounterEnemies.Add(enemy1);
        state.EncounterEnemies.Add(enemy2);

        int comboBefore = TypingMetrics.GetComboCount(state);
        InlineCombat.ProcessTyping(state, "first");

        Assert.True(TypingMetrics.GetComboCount(state) > comboBefore);
    }

    [Fact]
    public void ProcessTyping_IncrementsEnemiesDefeated()
    {
        var state = CreateCombatState();
        int defeatedBefore = state.EnemiesDefeated;
        var enemy = MakeEnemy(1, hp: 1);
        enemy["word"] = "count";
        state.EncounterEnemies.Add(enemy);

        InlineCombat.ProcessTyping(state, "count");

        Assert.Equal(defeatedBefore + 1, state.EnemiesDefeated);
    }

    [Fact]
    public void ProcessTyping_EmptyInput_NoEffect()
    {
        var state = CreateCombatState();
        var enemy = MakeEnemy(1);
        enemy["word"] = "hello";
        state.EncounterEnemies.Add(enemy);

        var events = InlineCombat.ProcessTyping(state, "  ");

        Assert.Empty(events);
        Assert.Single(state.EncounterEnemies);
    }

    [Fact]
    public void ProcessTyping_NotInEncounterMode_NoEffect()
    {
        var state = CreateCombatState();
        state.ActivityMode = "exploration";
        var enemy = MakeEnemy(1);
        enemy["word"] = "hello";
        state.EncounterEnemies.Add(enemy);

        var events = InlineCombat.ProcessTyping(state, "hello");

        Assert.Empty(events);
    }

    [Fact]
    public void ProcessTyping_LastEnemyKilled_EndsEncounter()
    {
        var state = CreateCombatState();
        var enemy = MakeEnemy(1, hp: 1);
        enemy["word"] = "last";
        state.EncounterEnemies.Add(enemy);

        var events = InlineCombat.ProcessTyping(state, "last");

        Assert.Equal("exploration", state.ActivityMode);
        Assert.True(events.Any(e => e.Contains("cleared")));
    }

    // --- TickEnemyApproach ---

    [Fact]
    public void TickEnemyApproach_AdvancesEnemies()
    {
        var state = CreateCombatState();
        var enemy = MakeEnemy(1);
        enemy["approach_progress"] = 0f;
        state.EncounterEnemies.Add(enemy);

        InlineCombat.TickEnemyApproach(state, 1.0f);

        float progress = Convert.ToSingle(enemy["approach_progress"]);
        Assert.True(progress > 0f, "Enemy approach progress should advance");
    }

    [Fact]
    public void TickEnemyApproach_EnemyReachesPlayer_DealsDamage()
    {
        var state = CreateCombatState();
        int hpBefore = state.Hp;
        var enemy = MakeEnemy(1, tier: 0);
        enemy["approach_progress"] = 0.99f; // almost there
        state.EncounterEnemies.Add(enemy);

        // Tick enough to push past 1.0
        InlineCombat.TickEnemyApproach(state, 1.0f);

        Assert.True(state.Hp < hpBefore, "Player should take damage when enemy reaches them");
    }

    [Fact]
    public void TickEnemyApproach_EnemyReachesPlayer_RemovedFromEncounter()
    {
        var state = CreateCombatState();
        var enemy = MakeEnemy(1);
        enemy["approach_progress"] = 0.99f;
        state.EncounterEnemies.Add(enemy);

        InlineCombat.TickEnemyApproach(state, 1.0f);

        Assert.Empty(state.EncounterEnemies);
    }

    [Fact]
    public void TickEnemyApproach_HigherTier_MoreDamage()
    {
        var stateT0 = CreateCombatState();
        stateT0.Hp = 100;
        var enemyT0 = MakeEnemy(1, tier: 0);
        enemyT0["approach_progress"] = 0.99f;
        stateT0.EncounterEnemies.Add(enemyT0);
        InlineCombat.TickEnemyApproach(stateT0, 1.0f);
        int damageT0 = 100 - stateT0.Hp;

        var stateT2 = CreateCombatState();
        stateT2.Hp = 100;
        var enemyT2 = MakeEnemy(2, tier: 2);
        enemyT2["approach_progress"] = 0.99f;
        stateT2.EncounterEnemies.Add(enemyT2);
        InlineCombat.TickEnemyApproach(stateT2, 1.0f);
        int damageT2 = 100 - stateT2.Hp;

        Assert.True(damageT2 > damageT0, $"Tier 2 damage ({damageT2}) should exceed tier 0 ({damageT0})");
    }

    [Fact]
    public void TickEnemyApproach_KillsPlayer_SetsGameOver()
    {
        var state = CreateCombatState();
        state.Hp = 1;
        var enemy = MakeEnemy(1, tier: 0);
        enemy["approach_progress"] = 0.99f;
        state.EncounterEnemies.Add(enemy);

        var events = InlineCombat.TickEnemyApproach(state, 1.0f);

        Assert.Equal("game_over", state.Phase);
        Assert.True(events.Any(e => e.Contains("defeated")));
    }

    [Fact]
    public void TickEnemyApproach_NotInEncounter_NoEffect()
    {
        var state = CreateCombatState();
        state.ActivityMode = "exploration";
        var enemy = MakeEnemy(1);
        enemy["approach_progress"] = 0.5f;
        state.EncounterEnemies.Add(enemy);

        var events = InlineCombat.TickEnemyApproach(state, 1.0f);

        Assert.Empty(events);
    }

    [Fact]
    public void TickEnemyApproach_AllEnemiesGone_EndsEncounter()
    {
        var state = CreateCombatState();
        state.Hp = 100;
        var enemy = MakeEnemy(1);
        enemy["approach_progress"] = 0.99f;
        state.EncounterEnemies.Add(enemy);

        var events = InlineCombat.TickEnemyApproach(state, 1.0f);

        Assert.Equal("exploration", state.ActivityMode);
        Assert.True(events.Any(e => e.Contains("cleared")));
    }

    // --- EndEncounter ---

    [Fact]
    public void EndEncounter_ReturnsToExploration()
    {
        var state = CreateCombatState();
        state.EncounterEnemies.Add(MakeEnemy(1));

        InlineCombat.EndEncounter(state);

        Assert.Equal("exploration", state.ActivityMode);
        Assert.Empty(state.EncounterEnemies);
    }

    [Fact]
    public void EndEncounter_ResetsCombo()
    {
        var state = CreateCombatState();
        TypingMetrics.IncrementCombo(state);
        TypingMetrics.IncrementCombo(state);
        Assert.True(TypingMetrics.GetComboCount(state) > 0);

        InlineCombat.EndEncounter(state);

        Assert.Equal(0, TypingMetrics.GetComboCount(state));
    }
}
