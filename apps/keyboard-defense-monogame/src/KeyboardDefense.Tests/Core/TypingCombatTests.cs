using System;
using System.Collections.Generic;
using System.Diagnostics;
using KeyboardDefense.Core.Balance;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;

namespace KeyboardDefense.Tests.Core;

public class TypingCombatTests
{
    [Fact]
    public void CorrectKeystrokes_IncreaseWpmMeasurement()
    {
        var state = DefaultState.Create();
        TypingMetrics.InitBattleMetrics(state);
        SetBattleStartSecondsAgo(state, 60);

        double baselineWpm = TypingMetrics.GetCurrentWpm(state);

        for (int i = 0; i < 300; i++)
            TypingMetrics.RecordCharTyped(state, 'a');

        double wpmAfterTyping = TypingMetrics.GetCurrentWpm(state);

        Assert.Equal(0, baselineWpm);
        Assert.True(wpmAfterTyping > baselineWpm);
        Assert.InRange(wpmAfterTyping, 58.0, 62.0);
    }

    [Fact]
    public void HigherWpm_ProducesMoreDamage_PerSimBalance()
    {
        var lowWpmState = CreateEncounterState();
        ConfigureTypingSnapshot(lowWpmState, charsTyped: 150, errors: 45, combo: 0, secondsAgo: 60); // ~30 WPM, 70% acc
        int lowDamage = DealSingleTypedHit(lowWpmState, "mist", enemyHp: 50);

        var highWpmState = CreateEncounterState();
        ConfigureTypingSnapshot(highWpmState, charsTyped: 350, errors: 105, combo: 0, secondsAgo: 60); // ~70 WPM, 70% acc
        int highDamage = DealSingleTypedHit(highWpmState, "mist", enemyHp: 50);

        int expectedLow = SimBalance.CalculateTypingDamage(
            SimBalance.TypingBaseDamage,
            TypingMetrics.GetCurrentWpm(lowWpmState),
            TypingMetrics.GetAccuracy(lowWpmState),
            0);
        int expectedHigh = SimBalance.CalculateTypingDamage(
            SimBalance.TypingBaseDamage,
            TypingMetrics.GetCurrentWpm(highWpmState),
            TypingMetrics.GetAccuracy(highWpmState),
            0);

        Assert.Equal(expectedLow, lowDamage);
        Assert.Equal(expectedHigh, highDamage);
        Assert.True(highDamage > lowDamage);
    }

    [Fact]
    public void AccuracyTracking_AffectsDamageMultiplier()
    {
        var lowAccuracyState = CreateEncounterState();
        ConfigureTypingSnapshot(lowAccuracyState, charsTyped: 150, errors: 45, combo: 0, secondsAgo: 60); // ~30 WPM, 70% acc
        int lowAccuracyDamage = DealSingleTypedHit(lowAccuracyState, "mist", enemyHp: 50);

        var highAccuracyState = CreateEncounterState();
        ConfigureTypingSnapshot(highAccuracyState, charsTyped: 150, errors: 6, combo: 0, secondsAgo: 60); // ~30 WPM, 96% acc
        int highAccuracyDamage = DealSingleTypedHit(highAccuracyState, "mist", enemyHp: 50);

        int expectedLow = SimBalance.CalculateTypingDamage(
            SimBalance.TypingBaseDamage,
            TypingMetrics.GetCurrentWpm(lowAccuracyState),
            TypingMetrics.GetAccuracy(lowAccuracyState),
            0);
        int expectedHigh = SimBalance.CalculateTypingDamage(
            SimBalance.TypingBaseDamage,
            TypingMetrics.GetCurrentWpm(highAccuracyState),
            TypingMetrics.GetAccuracy(highAccuracyState),
            0);

        Assert.Equal(expectedLow, lowAccuracyDamage);
        Assert.Equal(expectedHigh, highAccuracyDamage);
        Assert.True(highAccuracyDamage > lowAccuracyDamage);
    }

    [Fact]
    public void TypingStreaks_BoostDamage()
    {
        var noStreakState = CreateEncounterState();
        ConfigureTypingSnapshot(noStreakState, charsTyped: 350, errors: 105, combo: 0, secondsAgo: 60); // ~70 WPM, 70% acc
        int noStreakDamage = DealSingleTypedHit(noStreakState, "mist", enemyHp: 50);

        var streakState = CreateEncounterState();
        ConfigureTypingSnapshot(streakState, charsTyped: 350, errors: 105, combo: 50, secondsAgo: 60); // combo bonus kicks in
        int streakDamage = DealSingleTypedHit(streakState, "mist", enemyHp: 50);

        int expectedNoStreak = SimBalance.CalculateTypingDamage(
            SimBalance.TypingBaseDamage,
            TypingMetrics.GetCurrentWpm(noStreakState),
            TypingMetrics.GetAccuracy(noStreakState),
            0);
        int expectedStreak = SimBalance.CalculateTypingDamage(
            SimBalance.TypingBaseDamage,
            TypingMetrics.GetCurrentWpm(streakState),
            TypingMetrics.GetAccuracy(streakState),
            50);

        Assert.Equal(expectedNoStreak, noStreakDamage);
        Assert.Equal(expectedStreak, streakDamage);
        Assert.True(streakDamage > noStreakDamage);
    }

    [Fact]
    public void TypingErrors_ReduceAccuracy_AndDamage()
    {
        var cleanState = CreateEncounterState();
        ConfigureTypingSnapshot(cleanState, charsTyped: 20, errors: 0, combo: 0, secondsAgo: 60);
        int cleanDamage = DealSingleTypedHit(cleanState, "mist", enemyHp: 50);
        double cleanAccuracy = TypingMetrics.GetAccuracy(cleanState);

        var errorState = CreateEncounterState();
        ConfigureTypingSnapshot(errorState, charsTyped: 20, errors: 0, combo: 0, secondsAgo: 60);
        errorState.EncounterEnemies.Add(CreateEncounterEnemy(id: 99, word: "mist", hp: 50));

        InlineCombat.ProcessTyping(errorState, "wrong");
        InlineCombat.ProcessTyping(errorState, "wrong");
        double accuracyAfterErrors = TypingMetrics.GetAccuracy(errorState);

        int hpBeforeHit = Convert.ToInt32(errorState.EncounterEnemies[0]["hp"]);
        InlineCombat.ProcessTyping(errorState, "mist");
        int hpAfterHit = Convert.ToInt32(errorState.EncounterEnemies[0]["hp"]);
        int errorDamage = hpBeforeHit - hpAfterHit;

        Assert.Equal(1.0, cleanAccuracy, 3);
        Assert.Equal(0.9, accuracyAfterErrors, 3);
        Assert.True(errorDamage < cleanDamage);
    }

    [Fact]
    public void WpmMeasurementWindow_TracksRollingChars_ForLastNSeconds()
    {
        var state = DefaultState.Create();
        TypingMetrics.InitBattleMetrics(state);

        TypingMetrics.RecordCharTyped(state, 'a');
        TypingMetrics.RecordCharTyped(state, 'b');

        Assert.Equal(10000, TypingMetrics.WpmWindowMs);

        var window = Assert.IsType<List<object>>(state.TypingMetrics["rolling_window_chars"]);
        Assert.Equal(2, window.Count);

        var first = Assert.IsType<Dictionary<string, object>>(window[0]);
        var second = Assert.IsType<Dictionary<string, object>>(window[1]);

        Assert.Equal("a", first["char"]?.ToString()?.ToLowerInvariant());
        Assert.Equal("b", second["char"]?.ToString()?.ToLowerInvariant());

        long firstTime = Convert.ToInt64(first["time"]);
        long secondTime = Convert.ToInt64(second["time"]);
        Assert.True(secondTime >= firstTime);

        double secondAgeMs = (Stopwatch.GetTimestamp() - secondTime) * 1000.0 / Stopwatch.Frequency;
        Assert.InRange(secondAgeMs, 0, TypingMetrics.WpmWindowMs);
    }

    [Fact]
    public void CombatTypingFeedback_EmitsHitAndMissIndicators()
    {
        var state = DefaultState.Create();
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 0,
            SpawnIntervalSeconds = 99f,
            EnemyStepIntervalSeconds = 99f,
            TypedHitDamage = 2,
            TypedMissDamage = 0,
            TowerTickDamage = 0,
        };

        var events = new List<string>();
        VerticalSliceWaveSim.StartSingleWave(state, config, events);
        events.Clear();

        state.Enemies.Clear();
        state.Enemies.Add(new Dictionary<string, object>
        {
            ["id"] = 1,
            ["kind"] = "scout",
            ["word"] = "mist",
            ["hp"] = 5,
            ["gold"] = 1,
            ["dist"] = 6,
            ["damage"] = 1,
        });

        VerticalSliceWaveSim.Step(state, config, 0.1f, "mi", events);
        VerticalSliceWaveSim.Step(state, config, 0.1f, "zz", events);

        Assert.Contains(events, e => e.StartsWith("typing_hit:", StringComparison.Ordinal));
        Assert.Contains(events, e => e.StartsWith("typing_miss:", StringComparison.Ordinal));
    }

    [Fact]
    public void TypingDuringNightPhase_DealsDamageToTargetedEnemy()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();
        state.Enemies.Add(CreateNightEnemy("bravo", hp: 10, dist: 6, gold: 1));
        state.Enemies.Add(CreateNightEnemy("alpha", hp: 10, dist: 6, gold: 1));

        var result = IntentApplier.Apply(state, SimIntents.Make("defend_input", new Dictionary<string, object>
        {
            ["text"] = "alpha",
        }));

        var newState = Assert.IsType<GameState>(result["state"]);
        var events = Assert.IsType<List<string>>(result["events"]);

        var alpha = FindEnemyByWord(newState.Enemies, "alpha");
        var bravo = FindEnemyByWord(newState.Enemies, "bravo");

        Assert.NotNull(alpha);
        Assert.NotNull(bravo);
        Assert.Equal(7, Convert.ToInt32(alpha!["hp"])); // 3 typing damage from night defend flow
        Assert.Equal(10, Convert.ToInt32(bravo!["hp"]));
        Assert.Equal(5, Convert.ToInt32(alpha["dist"]));
        Assert.Equal(5, Convert.ToInt32(bravo["dist"]));
        Assert.Contains(events, e => e.Contains("Typed 'alpha' — 3 damage.", StringComparison.Ordinal));
    }

    private static GameState CreateEncounterState()
    {
        var state = DefaultState.Create();
        state.ActivityMode = "encounter";
        TypingMetrics.InitBattleMetrics(state);
        return state;
    }

    private static void ConfigureTypingSnapshot(
        GameState state,
        int charsTyped,
        int errors,
        int combo,
        double secondsAgo)
    {
        state.TypingMetrics["battle_chars_typed"] = charsTyped;
        state.TypingMetrics["battle_errors"] = errors;
        state.TypingMetrics["perfect_word_streak"] = combo;
        SetBattleStartSecondsAgo(state, secondsAgo);
    }

    private static void SetBattleStartSecondsAgo(GameState state, double secondsAgo)
    {
        long elapsedTicks = (long)(secondsAgo * Stopwatch.Frequency);
        state.TypingMetrics["battle_start_msec"] = Stopwatch.GetTimestamp() - elapsedTicks;
    }

    private static int DealSingleTypedHit(GameState state, string word, int enemyHp)
    {
        state.EncounterEnemies.Clear();
        state.EncounterEnemies.Add(CreateEncounterEnemy(id: 1, word: word, hp: enemyHp));

        var events = InlineCombat.ProcessTyping(state, word);
        Assert.NotEmpty(events);

        int hpAfter = Convert.ToInt32(state.EncounterEnemies[0]["hp"]);
        return enemyHp - hpAfter;
    }

    private static Dictionary<string, object> CreateEncounterEnemy(int id, string word, int hp)
    {
        return new Dictionary<string, object>
        {
            ["id"] = id,
            ["kind"] = "scout",
            ["word"] = word,
            ["hp"] = hp,
            ["tier"] = 0,
            ["pos"] = new GridPoint(5, 5),
            ["approach_progress"] = 0f,
        };
    }

    private static Dictionary<string, object> CreateNightEnemy(string word, int hp, int dist, int gold)
    {
        return new Dictionary<string, object>
        {
            ["word"] = word,
            ["hp"] = hp,
            ["dist"] = dist,
            ["gold"] = gold,
            ["damage"] = 1,
            ["kind"] = "raider",
        };
    }

    private static Dictionary<string, object>? FindEnemyByWord(List<Dictionary<string, object>> enemies, string word)
    {
        foreach (var enemy in enemies)
        {
            string enemyWord = enemy.GetValueOrDefault("word")?.ToString() ?? "";
            if (string.Equals(enemyWord, word, StringComparison.OrdinalIgnoreCase))
                return enemy;
        }
        return null;
    }
}
