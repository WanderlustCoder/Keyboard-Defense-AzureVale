using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Extended tests for VerticalSliceWaveSim — spawn mechanics, tower attacks,
/// enemy advancement, score computation, target selection, and practice mode.
/// </summary>
public class VerticalSliceWaveSimExtendedTests
{
    // =========================================================================
    // StartSingleWave
    // =========================================================================

    [Fact]
    public void StartSingleWave_ClearsExistingEnemies()
    {
        var state = CreateState("clear-enemies");
        state.Enemies.Add(MakeEnemy(1, "leftover", hp: 5));
        var config = DefaultConfig();
        var events = new List<string>();

        VerticalSliceWaveSim.StartSingleWave(state, config, events);

        Assert.Empty(state.Enemies);
    }

    [Fact]
    public void StartSingleWave_SetsApToZero()
    {
        var state = CreateState("ap-zero");
        state.Ap = 5;
        var events = new List<string>();

        VerticalSliceWaveSim.StartSingleWave(state, DefaultConfig(), events);

        Assert.Equal(0, state.Ap);
    }

    [Fact]
    public void StartSingleWave_RecordsStartHpInMetrics()
    {
        var state = CreateState("start-hp");
        state.Hp = 15;
        var events = new List<string>();

        VerticalSliceWaveSim.StartSingleWave(state, DefaultConfig(), events);

        Assert.Equal(15, MetricInt(state, "vs_start_hp"));
    }

    [Fact]
    public void StartSingleWave_ClearsResultMetric()
    {
        var state = CreateState("clear-result");
        state.TypingMetrics["vs_result"] = "victory";
        var events = new List<string>();

        VerticalSliceWaveSim.StartSingleWave(state, DefaultConfig(), events);

        Assert.Equal("", MetricString(state, "vs_result"));
    }

    // =========================================================================
    // Enemy spawning
    // =========================================================================

    [Fact]
    public void Step_SpawnsEnemiesOnSchedule()
    {
        var state = CreateState("spawn-schedule");
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 3,
            SpawnIntervalSeconds = 0.5f,
            EnemyStepIntervalSeconds = 100f, // don't trigger advance
            TowerTickDamage = 0,
        };
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());

        // First step spawns enemies (timer starts at 0)
        var events = new List<string>();
        VerticalSliceWaveSim.Step(state, config, 1.5f, null, events);

        Assert.True(state.Enemies.Count > 0, "Should have spawned enemies");
        Assert.True(state.NightSpawnRemaining < 3, "Spawn remaining should decrease");
    }

    [Fact]
    public void Step_SpawnedEnemiesHaveUniqueWords()
    {
        var state = CreateState("unique-spawn-words");
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 5,
            SpawnIntervalSeconds = 0.1f,
            EnemyStepIntervalSeconds = 100f,
            TowerTickDamage = 0,
        };
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());

        VerticalSliceWaveSim.Step(state, config, 5f, null, new List<string>());

        var words = state.Enemies
            .Select(e => e.GetValueOrDefault("word")?.ToString() ?? "")
            .Where(w => !string.IsNullOrEmpty(w))
            .ToList();
        Assert.Equal(words.Count, words.Distinct().Count());
    }

    [Fact]
    public void Step_DoesNotSpawnWhenRemainingIsZero()
    {
        var state = CreateState("no-spawn-zero");
        var config = DefaultConfig();
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        state.NightSpawnRemaining = 0;
        state.Enemies.Add(MakeEnemy(1, "blocker", dist: 99));

        int before = state.Enemies.Count;
        VerticalSliceWaveSim.Step(state, config, 2f, null, new List<string>());

        Assert.True(state.Enemies.Count <= before, "Should not spawn new enemies");
    }

    // =========================================================================
    // Tower attacks
    // =========================================================================

    [Fact]
    public void TowerAttack_AutoTowerDealsTickDamage()
    {
        var state = CreateState("tower-damage");
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 0,
            EnemyStepIntervalSeconds = 0.5f,
            TowerTickDamage = 2,
            EnemyStepDistance = 0,
            EnemyContactDamage = 0,
        };
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        state.NightSpawnRemaining = 0;

        // Place auto tower (key is tile index)
        state.Structures[5 * state.MapW + 5] = "auto_turret";
        state.Enemies.Add(MakeEnemy(1, "target", hp: 10, dist: 20));

        var events = new List<string>();
        VerticalSliceWaveSim.Step(state, config, 1f, null, events);

        // Tower should have damaged the enemy
        int hp = Convert.ToInt32(state.Enemies[0]["hp"]);
        Assert.True(hp < 10, $"Tower should deal damage, hp={hp}");
    }

    [Fact]
    public void TowerAttack_KillsEnemyAndAwardsGold()
    {
        var state = CreateState("tower-kill");
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 0,
            EnemyStepIntervalSeconds = 0.5f,
            TowerTickDamage = 10,
            EnemyStepDistance = 0,
            EnemyContactDamage = 0,
        };
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        state.NightSpawnRemaining = 0;

        state.Structures[5 * state.MapW + 5] = "auto_turret";
        state.Enemies.Add(MakeEnemy(1, "doomed", hp: 3, dist: 20, gold: 5));
        int goldBefore = state.Gold;

        var events = new List<string>();
        VerticalSliceWaveSim.Step(state, config, 1f, null, events);

        Assert.Empty(state.Enemies);
        Assert.Equal(goldBefore + 5, state.Gold);
        Assert.Contains(events, e => e.Contains("Auto-tower", StringComparison.Ordinal));
    }

    [Fact]
    public void TowerAttack_ZeroDamage_DoesNothing()
    {
        var state = CreateState("tower-zero-dmg");
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 0,
            EnemyStepIntervalSeconds = 0.5f,
            TowerTickDamage = 0,
            EnemyStepDistance = 0,
            EnemyContactDamage = 0,
        };
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        state.NightSpawnRemaining = 0;

        state.Structures[5 * state.MapW + 5] = "auto_turret";
        state.Enemies.Add(MakeEnemy(1, "safe", hp: 5, dist: 20));

        VerticalSliceWaveSim.Step(state, config, 1f, null, new List<string>());

        Assert.Equal(5, Convert.ToInt32(state.Enemies[0]["hp"]));
    }

    [Fact]
    public void TowerAttack_NonAutoStructure_DoesNotAttack()
    {
        var state = CreateState("non-auto-tower");
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 0,
            EnemyStepIntervalSeconds = 0.5f,
            TowerTickDamage = 5,
            EnemyStepDistance = 0,
            EnemyContactDamage = 0,
        };
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        state.NightSpawnRemaining = 0;

        state.Structures[5 * state.MapW + 5] = "wall";
        state.Enemies.Add(MakeEnemy(1, "safe", hp: 5, dist: 20));

        VerticalSliceWaveSim.Step(state, config, 1f, null, new List<string>());

        Assert.Equal(5, Convert.ToInt32(state.Enemies[0]["hp"]));
    }

    // =========================================================================
    // Enemy advancement
    // =========================================================================

    [Fact]
    public void EnemyAdvance_ReducesDistByStepDistance()
    {
        var state = CreateState("advance-dist");
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 0,
            EnemyStepIntervalSeconds = 0.5f,
            EnemyStepDistance = 2,
            TowerTickDamage = 0,
            EnemyContactDamage = 1,
        };
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        state.NightSpawnRemaining = 0;
        state.Enemies.Add(MakeEnemy(1, "marcher", hp: 5, dist: 10));

        VerticalSliceWaveSim.Step(state, config, 1f, null, new List<string>());

        int dist = Convert.ToInt32(state.Enemies[0]["dist"]);
        Assert.True(dist < 10, $"Distance should decrease, got {dist}");
    }

    [Fact]
    public void EnemyAdvance_ReachesBase_DamagesPlayerAndRemovesEnemy()
    {
        var state = CreateState("advance-base");
        state.Hp = 10;
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 0,
            EnemyStepIntervalSeconds = 0.5f,
            EnemyStepDistance = 5,
            TowerTickDamage = 0,
            EnemyContactDamage = 2,
        };
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        state.NightSpawnRemaining = 0;
        state.Enemies.Add(MakeEnemy(1, "rusher", hp: 5, dist: 1));

        var events = new List<string>();
        VerticalSliceWaveSim.Step(state, config, 1f, null, events);

        Assert.Empty(state.Enemies);
        Assert.True(state.Hp < 10, "Player should take contact damage");
        Assert.Contains(events, e => e.Contains("reached the base", StringComparison.Ordinal));
    }

    [Fact]
    public void EnemyAdvance_AtBase_CausesGameOverIfHpDepleted()
    {
        var state = CreateState("advance-gameover");
        state.Hp = 1;
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 0,
            EnemyStepIntervalSeconds = 0.5f,
            EnemyStepDistance = 10,
            TowerTickDamage = 0,
            EnemyContactDamage = 5,
        };
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        state.NightSpawnRemaining = 0;
        state.Enemies.Add(MakeEnemy(1, "fatal", hp: 5, dist: 1));

        var events = new List<string>();
        VerticalSliceWaveSim.Step(state, config, 1f, null, events);

        Assert.Equal("game_over", state.Phase);
        Assert.Equal("defeat", MetricString(state, "vs_result"));
    }

    // =========================================================================
    // Typing resolution
    // =========================================================================

    [Fact]
    public void Typing_CorrectPrefix_SetsNightPromptToRemainder()
    {
        var state = CreateState("typing-prefix");
        var config = QuietConfig();
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        state.NightSpawnRemaining = 0;
        state.Enemies.Add(MakeEnemy(1, "hello", hp: 5, dist: 10));

        VerticalSliceWaveSim.Step(state, config, 0f, "he", new List<string>());

        Assert.Equal("llo", state.NightPrompt);
    }

    [Fact]
    public void Typing_CompleteWord_KillsEnemyWhenHpDepleted()
    {
        var state = CreateState("typing-kill");
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 0,
            EnemyStepIntervalSeconds = 100f,
            TowerTickDamage = 0,
            TypedHitDamage = 10,
        };
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        state.NightSpawnRemaining = 0;
        state.Enemies.Add(MakeEnemy(1, "hi", hp: 1, dist: 10, gold: 3));
        int goldBefore = state.Gold;

        var events = new List<string>();
        VerticalSliceWaveSim.Step(state, config, 0f, "hi", events);

        Assert.Empty(state.Enemies);
        Assert.Equal(goldBefore + 3, state.Gold);
        Assert.Equal(1, state.EnemiesDefeated);
        Assert.Contains(events, e => e.Contains("Enemy defeated!", StringComparison.Ordinal));
    }

    [Fact]
    public void Typing_CompleteWord_EnemySurvivesWithRemainingHp()
    {
        var state = CreateState("typing-survive");
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 0,
            EnemyStepIntervalSeconds = 100f,
            TowerTickDamage = 0,
            TypedHitDamage = 1,
        };
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        state.NightSpawnRemaining = 0;
        state.Enemies.Add(MakeEnemy(1, "go", hp: 5, dist: 10));

        var events = new List<string>();
        VerticalSliceWaveSim.Step(state, config, 0f, "go", events);

        Assert.Single(state.Enemies);
        Assert.Equal(4, Convert.ToInt32(state.Enemies[0]["hp"]));
        Assert.Contains(events, e => e.Contains("survives", StringComparison.Ordinal));
    }

    [Fact]
    public void Typing_Miss_IncrementsMissCount()
    {
        var state = CreateState("typing-miss-count");
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 0,
            EnemyStepIntervalSeconds = 100f,
            TowerTickDamage = 0,
            TypedMissDamage = 0,
        };
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        state.NightSpawnRemaining = 0;
        state.Enemies.Add(MakeEnemy(1, "apple", hp: 5, dist: 10));

        VerticalSliceWaveSim.Step(state, config, 0f, "zzz", new List<string>());

        Assert.Equal(1, MetricInt(state, "vs_miss_count"));
    }

    [Fact]
    public void Typing_MissInPracticeMode_DoesNotDamagePlayer()
    {
        var state = CreateState("practice-miss");
        state.PracticeMode = true;
        state.Hp = 10;
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 0,
            EnemyStepIntervalSeconds = 100f,
            TowerTickDamage = 0,
            TypedMissDamage = 3,
        };
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        state.NightSpawnRemaining = 0;

        VerticalSliceWaveSim.Step(state, config, 0f, "badword", new List<string>());

        Assert.Equal(10, state.Hp);
    }

    [Fact]
    public void Typing_MissWithDamage_ReducesPlayerHp()
    {
        var state = CreateState("miss-damage");
        state.Hp = 10;
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 0,
            EnemyStepIntervalSeconds = 100f,
            TowerTickDamage = 0,
            TypedMissDamage = 2,
        };
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        state.NightSpawnRemaining = 0;

        VerticalSliceWaveSim.Step(state, config, 0f, "garbage", new List<string>());

        Assert.Equal(8, state.Hp);
    }

    // =========================================================================
    // Target selection
    // =========================================================================

    [Fact]
    public void TargetSelection_PrefersCloserEnemy()
    {
        var state = CreateState("target-closer");
        var config = QuietConfig();
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        state.NightSpawnRemaining = 0;

        state.Enemies.Add(MakeEnemy(1, "far", hp: 5, dist: 20));
        state.Enemies.Add(MakeEnemy(2, "fast", hp: 5, dist: 3));

        var events = new List<string>();
        VerticalSliceWaveSim.Step(state, config, 0f, "f", events);

        // Should target "fast" (dist=3) over "far" (dist=20)
        // The night prompt should show remainder of "fast"
        Assert.Equal("ast", state.NightPrompt);
    }

    [Fact]
    public void TargetSelection_SameDistance_PrefersShortestWord()
    {
        var state = CreateState("target-shortest");
        var config = QuietConfig();
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        state.NightSpawnRemaining = 0;

        state.Enemies.Add(MakeEnemy(1, "apple", hp: 5, dist: 5));
        state.Enemies.Add(MakeEnemy(2, "ape", hp: 5, dist: 5));

        var events = new List<string>();
        VerticalSliceWaveSim.Step(state, config, 0f, "a", events);

        // Should target "ape" (shorter) at same distance
        Assert.Equal("pe", state.NightPrompt);
    }

    // =========================================================================
    // Score computation
    // =========================================================================

    [Fact]
    public void Victory_GivesScoreBonus()
    {
        var state = CreateState("victory-bonus");
        var config = DefaultConfig();
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        state.NightSpawnRemaining = 0;
        state.NightWaveTotal = 0;
        state.Enemies.Clear();

        VerticalSliceWaveSim.Step(state, config, 0f, null, new List<string>());

        int score = MetricInt(state, "vs_score");
        Assert.True(score >= 500, $"Victory should give 500+ bonus, got {score}");
    }

    [Fact]
    public void Defeat_DoesNotGetVictoryBonus()
    {
        var state = CreateState("defeat-no-bonus");
        state.Hp = 1;
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 0,
            EnemyStepIntervalSeconds = 100f,
            TowerTickDamage = 0,
            TypedMissDamage = 5,
        };
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        state.NightSpawnRemaining = 0;

        VerticalSliceWaveSim.Step(state, config, 0f, "miss", new List<string>());

        Assert.Equal("defeat", MetricString(state, "vs_result"));
        // With no enemies defeated or words typed, score comes only from hp remaining
        int score = MetricInt(state, "vs_score");
        Assert.True(score < 500, $"Defeat should not have victory bonus, got {score}");
    }

    [Fact]
    public void Score_NeverGoesNegative()
    {
        var state = CreateState("score-nonneg");
        state.Hp = 1;
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 0,
            EnemyStepIntervalSeconds = 100f,
            TowerTickDamage = 0,
            TypedMissDamage = 1,
        };
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        state.NightSpawnRemaining = 0;

        // Cause many misses for score penalties
        for (int i = 0; i < 20; i++)
            VerticalSliceWaveSim.Step(state, config, 0f, "zzz", new List<string>());

        int score = MetricInt(state, "vs_score");
        Assert.True(score >= 0, $"Score should be non-negative, got {score}");
    }

    // =========================================================================
    // Summary payload
    // =========================================================================

    [Fact]
    public void VictorySummary_ContainsAllExpectedFields()
    {
        var state = CreateState("summary-fields");
        var config = DefaultConfig();
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        state.NightSpawnRemaining = 0;
        state.NightWaveTotal = 3;
        state.Enemies.Clear();

        VerticalSliceWaveSim.Step(state, config, 0f, null, new List<string>());

        var payload = state.TypingMetrics["vs_summary_payload"] as Dictionary<string, object>;
        Assert.NotNull(payload);
        Assert.Equal("victory", payload!["result"]);
        Assert.True(payload.ContainsKey("score"));
        Assert.True(payload.ContainsKey("elapsed_seconds"));
        Assert.True(payload.ContainsKey("enemies_defeated"));
        Assert.True(payload.ContainsKey("words_typed"));
        Assert.True(payload.ContainsKey("misses"));
        Assert.True(payload.ContainsKey("damage_taken"));
        Assert.True(payload.ContainsKey("hp_remaining"));
        Assert.True(payload.ContainsKey("wave_total"));
        Assert.True(payload.ContainsKey("gold"));
    }

    [Fact]
    public void FinalizeResult_OnlyRunsOnce()
    {
        var state = CreateState("finalize-once");
        var config = DefaultConfig();
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        state.NightSpawnRemaining = 0;
        state.NightWaveTotal = 0;
        state.Enemies.Clear();

        var events1 = new List<string>();
        VerticalSliceWaveSim.Step(state, config, 0f, null, events1);
        int firstScore = MetricInt(state, "vs_score");

        // Step again — should not overwrite result
        state.Phase = "night"; // hack to re-enter step
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();
        var events2 = new List<string>();
        VerticalSliceWaveSim.Step(state, config, 0f, null, events2);

        Assert.Equal(firstScore, MetricInt(state, "vs_score"));
    }

    // =========================================================================
    // Step does nothing when not in night phase
    // =========================================================================

    [Fact]
    public void Step_DayPhase_DoesNothing()
    {
        var state = CreateState("day-noop");
        state.Phase = "day";
        var config = DefaultConfig();
        var events = new List<string>();

        VerticalSliceWaveSim.Step(state, config, 1f, "test", events);

        Assert.Empty(events);
        Assert.Equal("day", state.Phase);
    }

    // =========================================================================
    // Battle chars/words tracking
    // =========================================================================

    [Fact]
    public void Typing_TracksCharsTyped()
    {
        var state = CreateState("chars-typed");
        var config = QuietConfig();
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        state.NightSpawnRemaining = 0;
        state.Enemies.Add(MakeEnemy(1, "cat", hp: 10, dist: 20));

        VerticalSliceWaveSim.Step(state, config, 0f, "ca", new List<string>());

        Assert.Equal(2, MetricInt(state, "battle_chars_typed"));
    }

    [Fact]
    public void Typing_TracksWordsTyped()
    {
        var state = CreateState("words-typed");
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 0,
            EnemyStepIntervalSeconds = 100f,
            TowerTickDamage = 0,
            TypedHitDamage = 100,
        };
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        state.NightSpawnRemaining = 0;
        state.Enemies.Add(MakeEnemy(1, "hi", hp: 1, dist: 10));

        VerticalSliceWaveSim.Step(state, config, 0f, "hi", new List<string>());

        Assert.Equal(1, MetricInt(state, "battle_words_typed"));
    }

    // =========================================================================
    // Gold capping
    // =========================================================================

    [Fact]
    public void TypingKill_GoldCappedAtSimBalance()
    {
        var state = CreateState("gold-cap");
        state.Gold = KeyboardDefense.Core.Balance.SimBalance.GoldCap - 1;
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 0,
            EnemyStepIntervalSeconds = 100f,
            TowerTickDamage = 0,
            TypedHitDamage = 100,
        };
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        state.NightSpawnRemaining = 0;
        state.Enemies.Add(MakeEnemy(1, "go", hp: 1, dist: 10, gold: 100));

        VerticalSliceWaveSim.Step(state, config, 0f, "go", new List<string>());

        Assert.True(state.Gold <= KeyboardDefense.Core.Balance.SimBalance.GoldCap);
    }

    // =========================================================================
    // Full wave lifecycle
    // =========================================================================

    [Fact]
    public void FullWave_TypeAllWords_Achieves_Victory()
    {
        var state = CreateState("full-wave-victory");
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 2,
            SpawnIntervalSeconds = 0.1f,
            EnemyStepIntervalSeconds = 100f,
            TowerTickDamage = 0,
            TypedHitDamage = 100,
            TypedMissDamage = 0,
        };
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());

        // Spawn all enemies
        VerticalSliceWaveSim.Step(state, config, 5f, null, new List<string>());
        Assert.Equal(0, state.NightSpawnRemaining);

        // Type each enemy's word
        int safety = 0;
        while (state.Enemies.Count > 0 && safety < 50)
        {
            string word = state.Enemies[0].GetValueOrDefault("word")?.ToString() ?? "";
            if (!string.IsNullOrEmpty(word))
                VerticalSliceWaveSim.Step(state, config, 0f, word, new List<string>());
            safety++;
        }

        Assert.Equal("day", state.Phase);
        Assert.Equal("victory", MetricString(state, "vs_result"));
    }

    // =========================================================================
    // WaveConfig defaults
    // =========================================================================

    [Fact]
    public void WaveConfig_DefaultValues()
    {
        var config = new VerticalSliceWaveConfig();
        Assert.Equal(6, config.SpawnTotal);
        Assert.Equal(1.0f, config.SpawnIntervalSeconds);
        Assert.Equal(1.0f, config.EnemyStepIntervalSeconds);
        Assert.Equal(1, config.EnemyStepDistance);
        Assert.Equal(1, config.EnemyContactDamage);
        Assert.Equal(2, config.TypedHitDamage);
        Assert.Equal(1, config.TypedMissDamage);
        Assert.Equal(1, config.TowerTickDamage);
    }

    // =========================================================================
    // Helpers
    // =========================================================================

    private static GameState CreateState(string seed)
    {
        var state = DefaultState.Create(seed, placeStartingTowers: false);
        state.Hp = 10;
        state.ApMax = 5;
        state.Ap = 3;
        state.PracticeMode = false;
        return state;
    }

    private static VerticalSliceWaveConfig DefaultConfig() => new()
    {
        SpawnTotal = 3,
        SpawnIntervalSeconds = 1.0f,
        EnemyStepIntervalSeconds = 1.0f,
        TowerTickDamage = 0,
    };

    /// <summary>Config that suppresses spawning and advancement for typing-focused tests.</summary>
    private static VerticalSliceWaveConfig QuietConfig() => new()
    {
        SpawnTotal = 0,
        EnemyStepIntervalSeconds = 100f,
        TowerTickDamage = 0,
        TypedHitDamage = 2,
        TypedMissDamage = 0,
    };

    private static Dictionary<string, object> MakeEnemy(
        int id, string word, int hp = 5, int dist = 10, int gold = 1, int damage = 1)
    {
        return new Dictionary<string, object>
        {
            ["id"] = id,
            ["kind"] = "scout",
            ["word"] = word,
            ["hp"] = hp,
            ["dist"] = dist,
            ["gold"] = gold,
            ["damage"] = damage,
            ["alive"] = true,
        };
    }

    private static int MetricInt(GameState state, string key)
    {
        if (!state.TypingMetrics.TryGetValue(key, out object? value) || value == null)
            return 0;
        if (value is int i) return i;
        return int.TryParse(value.ToString(), out int parsed) ? parsed : 0;
    }

    private static string MetricString(GameState state, string key)
    {
        if (!state.TypingMetrics.TryGetValue(key, out object? value) || value == null)
            return "";
        return value.ToString() ?? "";
    }
}
