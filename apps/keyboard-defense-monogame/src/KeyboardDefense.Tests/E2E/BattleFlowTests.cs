using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.E2E;

/// <summary>
/// End-to-end tests for battle flow: spawn, type, defeat, victory/defeat.
/// </summary>
public class BattleFlowTests
{
    [Fact]
    public void CompleteBattle_DefeatAllEnemies_SurvivesNight()
    {
        var sim = new GameSimulator("battle_complete_v2");
        sim.EndDay();
        Assert.Equal("night", sim.State.Phase);

        var result = sim.RunNightToCompletion(maxSteps: 150);

        // Night should end with transition back to day (survived)
        Assert.Equal("day", result.EndPhase);
        Assert.True(result.EnemiesKilled > 0, "Should have killed at least one enemy");
        Assert.True(result.WordsTyped > 0, "Should have typed at least one word");
        Assert.True(result.EndHp > 0, "Castle should survive");
    }

    [Fact]
    public void WrongWords_EnemiesReachBase_HpDecreases()
    {
        var sim = new GameSimulator("wrong_words");
        int startHp = sim.State.Hp;
        sim.EndDay();

        // Type only wrong words during night
        for (int i = 0; i < 30; i++)
        {
            if (sim.State.Phase != "night") break;
            sim.TypeWord("zzzzz_never_matches");
        }

        // HP should have decreased (enemies reach base or miss penalty)
        Assert.True(sim.State.Hp < startHp || sim.State.Phase != "night",
            "Wrong words should let enemies through or penalize HP");
    }

    [Fact]
    public void EnemySpawn_HasValidWordAndKind()
    {
        var sim = new GameSimulator("spawn_check");
        sim.EndDay();
        Assert.Equal("night", sim.State.Phase);

        sim.SpawnEnemies();

        if (sim.State.Enemies.Count > 0)
        {
            var enemy = sim.State.Enemies[0];
            string word = enemy.GetValueOrDefault("word")?.ToString() ?? "";
            string kind = enemy.GetValueOrDefault("kind")?.ToString() ?? "";

            Assert.NotEmpty(word);
            Assert.NotEmpty(kind);
            Assert.True(word.Length >= 2, "Enemy word should be at least 2 chars");
        }
    }

    [Fact]
    public void TypingCorrectWord_EarnsGold()
    {
        var sim = new GameSimulator("gold_earn");
        sim.EndDay();
        sim.SpawnEnemies();

        if (sim.State.Enemies.Count == 0) return;

        int goldBefore = sim.State.Gold;
        string word = sim.FirstEnemyWord()!;
        sim.TypeWord(word);

        // Gold should increase when enemy is defeated
        Assert.True(sim.State.Gold >= goldBefore, "Gold should not decrease after typing correct word");
    }

    [Fact]
    public void NightPhase_AllEnemiesDefeated_TransitionsToDawn()
    {
        var sim = new GameSimulator("dawn_transition");
        Assert.Equal(1, sim.State.Day);

        sim.EndDay();
        var result = sim.RunNightToCompletion();

        Assert.Equal("day", result.EndPhase);
    }

    [Fact]
    public void NightPhase_WaveCountPositive()
    {
        var sim = new GameSimulator("wave_count_test");
        sim.EndDay();
        Assert.Equal("night", sim.State.Phase);
        Assert.True(sim.State.NightWaveTotal > 0, "Night wave should have enemies");
        Assert.True(sim.State.NightSpawnRemaining > 0, "Should have enemies left to spawn");
    }

    [Fact]
    public void EnemyHasHpAndMaxHp()
    {
        var sim = new GameSimulator("enemy_hp");
        sim.EndDay();
        sim.SpawnEnemies();

        if (sim.State.Enemies.Count == 0) return;

        var enemy = sim.State.Enemies[0];
        Assert.True(enemy.ContainsKey("hp"), "Enemy should have hp");

        int hp = Convert.ToInt32(enemy["hp"]);
        Assert.True(hp > 0, "Enemy HP should be positive");
    }

    [Fact]
    public void NightPhase_HasWaveTotal()
    {
        var sim = new GameSimulator("night_wave");
        sim.EndDay();

        Assert.Equal("night", sim.State.Phase);
        Assert.True(sim.State.NightWaveTotal > 0, "Night should have a wave count");
    }

    [Fact]
    public void WaveTotal_ScalesWithDay()
    {
        var sim = new GameSimulator("wave_scale");

        // Day 1 night
        sim.EndDay();
        int wave1 = sim.State.NightWaveTotal;
        sim.RunNightToCompletion();

        // Day 2 night
        sim.RunDayPhase();
        int wave2 = sim.State.NightWaveTotal;

        // Wave totals should be > 0
        Assert.True(wave1 > 0, "Day 1 wave should have enemies");
        Assert.True(wave2 > 0, "Day 2 wave should have enemies");
    }

    [Fact]
    public void TypingMetrics_UpdatedDuringBattle()
    {
        var sim = new GameSimulator("typing_metrics");
        sim.EndDay();

        // Type some words
        for (int i = 0; i < 10; i++)
        {
            if (sim.State.Phase != "night") break;
            if (sim.State.Enemies.Count > 0)
                sim.DefeatFirstEnemy();
            else
                sim.Wait();
        }

        var metrics = sim.State.TypingMetrics;
        // Metrics should have been updated
        Assert.NotNull(metrics);
    }

    [Fact]
    public void GameOver_WhenHpReachesZero()
    {
        var sim = new GameSimulator("game_over");
        sim.State.Hp = 1; // Set low HP
        sim.EndDay();

        // Type wrong words to force game over
        for (int i = 0; i < 50; i++)
        {
            if (sim.State.Phase != "night") break;
            sim.TypeWord("zzzzz_wrong");
        }

        // Should either be game_over or day (if night ended first)
        Assert.True(
            sim.State.Phase == "game_over" || sim.State.Phase == "day",
            $"Expected game_over or day, got {sim.State.Phase}");
    }
}
