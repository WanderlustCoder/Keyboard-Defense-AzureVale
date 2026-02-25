using System;
using System.Collections.Generic;
using System.Diagnostics;
using KeyboardDefense.Core.Balance;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;

namespace KeyboardDefense.Tests.Core;

public sealed class ProficiencyTests : IDisposable
{
    public ProficiencyTests()
    {
        TypingProfile.Instance.Reset();
    }

    public void Dispose()
    {
        TypingProfile.Instance.Reset();
    }

    [Theory]
    [InlineData(39.9, 0.99, TypingProficiency.ProficiencyTier.Novice)]
    [InlineData(40.0, 0.75, TypingProficiency.ProficiencyTier.Adept)]
    [InlineData(59.9, 0.99, TypingProficiency.ProficiencyTier.Adept)]
    [InlineData(60.0, 0.80, TypingProficiency.ProficiencyTier.Expert)]
    [InlineData(79.9, 0.99, TypingProficiency.ProficiencyTier.Expert)]
    [InlineData(80.0, 0.85, TypingProficiency.ProficiencyTier.Master)]
    [InlineData(80.0, 0.95, TypingProficiency.ProficiencyTier.Grandmaster)]
    [InlineData(120.0, 0.94, TypingProficiency.ProficiencyTier.Master)]
    public void GetTier_RespectsLevelThresholds(double wpm, double accuracy, TypingProficiency.ProficiencyTier expected)
    {
        var tier = TypingProficiency.GetTier(wpm, accuracy);
        Assert.Equal(expected, tier);
    }

    [Fact]
    public void GetTier_HighWpmWithLowAccuracy_DoesNotLevelUp()
    {
        var tier = TypingProficiency.GetTier(120.0, 0.74);
        Assert.Equal(TypingProficiency.ProficiencyTier.Novice, tier);
    }

    [Fact]
    public void RecordSession_GainsProfileProgressLikeXp()
    {
        var profile = TypingProfile.Instance;

        profile.RecordSession(65.0, 0.90, wordsTyped: 30, errors: 3, durationSec: 45.0);
        profile.RecordSession(70.0, 0.92, wordsTyped: 25, errors: 2, durationSec: 30.0);

        Assert.Equal(2, profile.Sessions.Count);
        Assert.Equal(55, profile.TotalWordsTyped);
        Assert.Equal(75.0, profile.TotalPlayTimeSeconds, 6);
    }

    [Fact]
    public void GetTier_FromProfile_ReachesGrandmasterWithHighRecentPerformance()
    {
        var profile = TypingProfile.Instance;
        SeedAccuracy(profile, correct: 100, errors: 0);

        for (int i = 0; i < 5; i++)
            profile.RecordSession(90.0, 0.99, wordsTyped: 40, errors: 0, durationSec: 30.0);

        Assert.Equal(TypingProficiency.ProficiencyTier.Grandmaster, TypingProficiency.GetTier());
    }

    [Fact]
    public void GetTier_FromProfile_DropsWhenRecentSessionsDecline()
    {
        var profile = TypingProfile.Instance;
        SeedAccuracy(profile, correct: 100, errors: 0);

        for (int i = 0; i < 5; i++)
            profile.RecordSession(90.0, 0.99, wordsTyped: 40, errors: 0, durationSec: 30.0);

        Assert.Equal(TypingProficiency.ProficiencyTier.Grandmaster, TypingProficiency.GetTier());

        for (int i = 0; i < 5; i++)
            profile.RecordSession(30.0, 0.99, wordsTyped: 20, errors: 0, durationSec: 30.0);

        Assert.Equal(TypingProficiency.ProficiencyTier.Novice, TypingProficiency.GetTier());
    }

    [Theory]
    [InlineData(120.0, 0.70, TypingProficiency.ProficiencyTier.Novice)]   // high WPM, low accuracy
    [InlineData(120.0, 0.74, TypingProficiency.ProficiencyTier.Novice)]   // just below Adept threshold
    [InlineData(120.0, 0.80, TypingProficiency.ProficiencyTier.Expert)]   // meets Expert but not Master
    [InlineData(120.0, 0.84, TypingProficiency.ProficiencyTier.Expert)]   // just below Master threshold
    public void GetTier_LowAccuracy_PreventsPromotion(double wpm, double accuracy, TypingProficiency.ProficiencyTier expected)
    {
        Assert.Equal(expected, TypingProficiency.GetTier(wpm, accuracy));
    }

    [Theory]
    [InlineData(25, 7, 10.0, TypingProficiency.ProficiencyTier.Novice)]
    [InlineData(75, 2, 10.0, TypingProficiency.ProficiencyTier.Grandmaster)]
    public void ProcessTyping_AppliesProficiencyDamageMultiplier(
        int charsTyped,
        int errors,
        double elapsedSeconds,
        TypingProficiency.ProficiencyTier expectedTier)
    {
        const int startingHp = 50;
        var state = CreateEncounterState(enemyHp: startingHp, enemyTier: 0);
        SetBattleMetrics(state, charsTyped, errors, elapsedSeconds);

        double wpm = TypingMetrics.GetCurrentWpm(state);
        double accuracy = TypingMetrics.GetAccuracy(state);
        var tier = TypingProficiency.GetTier(wpm, accuracy);
        Assert.Equal(expectedTier, tier);

        int baseDamage = SimBalance.CalculateTypingDamage(1, wpm, accuracy, combo: 0);
        int expectedDamage = Math.Max(1, (int)(baseDamage * TypingProficiency.GetDamageMultiplier(tier)));

        InlineCombat.ProcessTyping(state, "test");

        int hpAfter = Convert.ToInt32(state.EncounterEnemies[0]["hp"]);
        Assert.Equal(expectedDamage, startingHp - hpAfter);
    }

    [Theory]
    [InlineData(25, 7, 10.0, TypingProficiency.ProficiencyTier.Novice)]
    [InlineData(75, 2, 10.0, TypingProficiency.ProficiencyTier.Grandmaster)]
    public void ProcessTyping_AppliesProficiencyGoldMultiplier(
        int charsTyped,
        int errors,
        double elapsedSeconds,
        TypingProficiency.ProficiencyTier expectedTier)
    {
        const int enemyTier = 2;
        var state = CreateEncounterState(enemyHp: 1, enemyTier: enemyTier);
        SetBattleMetrics(state, charsTyped, errors, elapsedSeconds);

        double wpm = TypingMetrics.GetCurrentWpm(state);
        double accuracy = TypingMetrics.GetAccuracy(state);
        var tier = TypingProficiency.GetTier(wpm, accuracy);
        Assert.Equal(expectedTier, tier);

        int expectedGold = (int)((3 + enemyTier * 2) * TypingProficiency.GetGoldMultiplier(tier));

        int goldBefore = state.Gold;
        InlineCombat.ProcessTyping(state, "test");

        Assert.Equal(expectedGold, state.Gold - goldBefore);
    }

    [Fact]
    public void GetScore_UsesWeightedClampedInputs()
    {
        Assert.Equal(50.0, TypingProficiency.GetScore(50.0, 0.5), 6);
        Assert.Equal(100.0, TypingProficiency.GetScore(200.0, 1.2), 6);
        Assert.Equal(0.0, TypingProficiency.GetScore(-10.0, -0.1), 6);
    }

    private static void SeedAccuracy(TypingProfile profile, int correct, int errors)
    {
        for (int i = 0; i < correct; i++)
            profile.RecordCorrectChar('a');

        for (int i = 0; i < errors; i++)
            profile.RecordError('a', 's');
    }

    private static GameState CreateEncounterState(int enemyHp, int enemyTier)
    {
        var state = new GameState
        {
            Hp = 20,
            Phase = "day",
            ActivityMode = "encounter",
            RngSeed = "proficiency_tests",
            LessonId = "full_alpha",
        };

        TypingMetrics.InitBattleMetrics(state);
        state.EncounterEnemies.Add(new Dictionary<string, object>
        {
            ["id"] = 1,
            ["kind"] = "raider",
            ["hp"] = enemyHp,
            ["tier"] = enemyTier,
            ["word"] = "test",
            ["pos"] = new GridPoint(state.PlayerPos.X + 1, state.PlayerPos.Y),
            ["approach_progress"] = 0f,
        });

        return state;
    }

    private static void SetBattleMetrics(GameState state, int charsTyped, int errors, double elapsedSeconds)
    {
        state.TypingMetrics["battle_chars_typed"] = charsTyped;
        state.TypingMetrics["battle_errors"] = errors;
        state.TypingMetrics["battle_words_typed"] = Math.Max(1, charsTyped / 5);
        state.TypingMetrics["perfect_word_streak"] = 0;
        state.TypingMetrics["battle_start_msec"] =
            Stopwatch.GetTimestamp() - (long)(elapsedSeconds * Stopwatch.Frequency);
    }
}
