using System.Collections.Generic;
using KeyboardDefense.Core.Progression;

namespace KeyboardDefense.Tests.Core;

public class PlayerStatsCoreTests
{
    [Fact]
    public void Constructor_DefaultValues_AreZero()
    {
        var stats = new PlayerStats();

        Assert.Equal(0, stats.Kills);
        Assert.Equal(0, stats.BossKills);
        Assert.Equal(0L, stats.DamageDealt);
        Assert.Equal(0L, stats.DamageTaken);
        Assert.Equal(0, stats.Deaths);
        Assert.Equal(0, stats.WordsTyped);
        Assert.Equal(0L, stats.CharsTyped);
        Assert.Equal(0, stats.Typos);
        Assert.Equal(0, stats.PerfectWords);
        Assert.Equal(0, stats.GoldEarned);
        Assert.Equal(0, stats.GoldSpent);
        Assert.Equal(0, stats.DaysSurvived);
        Assert.Equal(0, stats.WavesCompleted);
        Assert.Equal(0, stats.QuestsCompleted);
        Assert.Equal(0, stats.HighestCombo);
        Assert.Equal(0, stats.HighestDay);
        Assert.Equal(0.0, stats.HighestAccuracy);
        Assert.Equal(0.0, stats.HighestWpm);
    }

    [Fact]
    public void GetAccuracy_NoWordsTyped_ReturnsZero()
    {
        var stats = new PlayerStats();

        Assert.Equal(0.0, stats.GetAccuracy());
    }

    [Fact]
    public void GetAccuracy_WithPerfectAndImperfectWords_ReturnsRatio()
    {
        var stats = new PlayerStats
        {
            WordsTyped = 4,
            PerfectWords = 3,
        };

        Assert.Equal(0.75, stats.GetAccuracy());
    }

    [Fact]
    public void GetKdRatio_NoDeaths_ReturnsKillsAsDouble()
    {
        var stats = new PlayerStats
        {
            Kills = 7,
        };

        Assert.Equal(7.0, stats.GetKdRatio());
    }

    [Fact]
    public void GetKdRatio_WithDeaths_ReturnsKillDeathRatio()
    {
        var stats = new PlayerStats
        {
            Kills = 9,
            Deaths = 4,
        };

        Assert.Equal(2.25, stats.GetKdRatio());
    }

    [Fact]
    public void RecordKill_DefaultCall_IncrementsKillsOnly()
    {
        var stats = new PlayerStats();

        stats.RecordKill();

        Assert.Equal(1, stats.Kills);
        Assert.Equal(0, stats.BossKills);
    }

    [Fact]
    public void RecordKill_BossCall_IncrementsKillsAndBossKills()
    {
        var stats = new PlayerStats();

        stats.RecordKill(isBoss: true);

        Assert.Equal(1, stats.Kills);
        Assert.Equal(1, stats.BossKills);
    }

    [Fact]
    public void RecordKill_MultipleCalls_AccumulateValues()
    {
        var stats = new PlayerStats();

        stats.RecordKill();
        stats.RecordKill(isBoss: true);
        stats.RecordKill(isBoss: true);

        Assert.Equal(3, stats.Kills);
        Assert.Equal(2, stats.BossKills);
    }

    [Fact]
    public void RecordWord_PerfectWord_IncrementsWordsCharsAndPerfectWords()
    {
        var stats = new PlayerStats();

        stats.RecordWord(perfect: true, charCount: 5);

        Assert.Equal(1, stats.WordsTyped);
        Assert.Equal(5L, stats.CharsTyped);
        Assert.Equal(1, stats.PerfectWords);
        Assert.Equal(0, stats.Typos);
    }

    [Fact]
    public void RecordWord_ImperfectWord_IncrementsWordsCharsAndTypos()
    {
        var stats = new PlayerStats();

        stats.RecordWord(perfect: false, charCount: 6);

        Assert.Equal(1, stats.WordsTyped);
        Assert.Equal(6L, stats.CharsTyped);
        Assert.Equal(0, stats.PerfectWords);
        Assert.Equal(1, stats.Typos);
    }

    [Fact]
    public void RecordWord_MultipleCalls_AccumulateAcrossBuckets()
    {
        var stats = new PlayerStats();

        stats.RecordWord(perfect: true, charCount: 4);
        stats.RecordWord(perfect: false, charCount: 6);
        stats.RecordWord(perfect: false, charCount: 3);

        Assert.Equal(3, stats.WordsTyped);
        Assert.Equal(13L, stats.CharsTyped);
        Assert.Equal(1, stats.PerfectWords);
        Assert.Equal(2, stats.Typos);
    }

    [Fact]
    public void RecordCombo_FirstValue_SetsHighestCombo()
    {
        var stats = new PlayerStats();

        stats.RecordCombo(7);

        Assert.Equal(7, stats.HighestCombo);
    }

    [Fact]
    public void RecordCombo_LowerValue_DoesNotReduceHighestCombo()
    {
        var stats = new PlayerStats();
        stats.RecordCombo(12);

        stats.RecordCombo(9);

        Assert.Equal(12, stats.HighestCombo);
    }

    [Fact]
    public void RecordDay_MultipleValues_TracksMaximum()
    {
        var stats = new PlayerStats();

        stats.RecordDay(3);
        stats.RecordDay(8);
        stats.RecordDay(5);

        Assert.Equal(8, stats.HighestDay);
    }

    [Fact]
    public void RecordAccuracy_MultipleValues_TracksMaximum()
    {
        var stats = new PlayerStats();

        stats.RecordAccuracy(0.75);
        stats.RecordAccuracy(0.90);
        stats.RecordAccuracy(0.80);

        Assert.Equal(0.90, stats.HighestAccuracy);
    }

    [Fact]
    public void RecordWpm_MultipleValues_TracksMaximum()
    {
        var stats = new PlayerStats();

        stats.RecordWpm(42.4);
        stats.RecordWpm(60.2);
        stats.RecordWpm(58.8);

        Assert.Equal(60.2, stats.HighestWpm);
    }

    [Fact]
    public void GetReport_ContainsAllExpectedKeys()
    {
        var stats = new PlayerStats();

        Dictionary<string, object> report = stats.GetReport();
        var expectedKeys = new HashSet<string>
        {
            "kills",
            "boss_kills",
            "words_typed",
            "accuracy",
            "highest_combo",
            "highest_day",
            "highest_wpm",
            "gold_earned",
            "waves_completed",
        };

        Assert.Equal(expectedKeys.Count, report.Count);
        foreach (var key in expectedKeys)
        {
            Assert.True(report.ContainsKey(key), $"Missing expected key '{key}'.");
        }
    }

    [Fact]
    public void GetReport_ValuesMatchPropertiesAndFormatting()
    {
        var stats = new PlayerStats
        {
            Kills = 5,
            BossKills = 2,
            WordsTyped = 4,
            PerfectWords = 3,
            HighestCombo = 17,
            HighestDay = 9,
            HighestWpm = 72.345,
            GoldEarned = 120,
            WavesCompleted = 11,
        };

        Dictionary<string, object> report = stats.GetReport();

        Assert.Equal(stats.Kills, report["kills"]);
        Assert.Equal(stats.BossKills, report["boss_kills"]);
        Assert.Equal(stats.WordsTyped, report["words_typed"]);
        Assert.Equal($"{stats.GetAccuracy():P1}", report["accuracy"]);
        Assert.Equal(stats.HighestCombo, report["highest_combo"]);
        Assert.Equal(stats.HighestDay, report["highest_day"]);
        Assert.Equal($"{stats.HighestWpm:F1}", report["highest_wpm"]);
        Assert.Equal(stats.GoldEarned, report["gold_earned"]);
        Assert.Equal(stats.WavesCompleted, report["waves_completed"]);
    }

    [Fact]
    public void GetReport_MultipleCalls_ReturnIndependentSnapshots()
    {
        var stats = new PlayerStats();

        Dictionary<string, object> first = stats.GetReport();
        stats.RecordKill();
        Dictionary<string, object> second = stats.GetReport();

        Assert.NotSame(first, second);
        Assert.Equal(0, first["kills"]);
        Assert.Equal(1, second["kills"]);
    }

    [Fact]
    public void CombinedUsageScenario_TracksStatsAndReportConsistently()
    {
        var stats = new PlayerStats();

        stats.RecordKill();
        stats.RecordKill(isBoss: true);
        stats.RecordWord(perfect: true, charCount: 5);
        stats.RecordWord(perfect: false, charCount: 4);
        stats.RecordCombo(8);
        stats.RecordCombo(6);
        stats.RecordDay(2);
        stats.RecordDay(3);
        stats.RecordAccuracy(0.60);
        stats.RecordAccuracy(0.55);
        stats.RecordWpm(44.4);
        stats.RecordWpm(50.4);
        stats.DamageDealt += 250;
        stats.DamageTaken += 100;
        stats.GoldEarned += 30;
        stats.GoldSpent += 10;
        stats.DaysSurvived += 1;
        stats.WavesCompleted += 2;
        stats.QuestsCompleted += 1;

        var report = stats.GetReport();

        Assert.Equal(2, stats.Kills);
        Assert.Equal(1, stats.BossKills);
        Assert.Equal(2, stats.WordsTyped);
        Assert.Equal(9L, stats.CharsTyped);
        Assert.Equal(1, stats.PerfectWords);
        Assert.Equal(1, stats.Typos);
        Assert.Equal(8, stats.HighestCombo);
        Assert.Equal(3, stats.HighestDay);
        Assert.Equal(0.60, stats.HighestAccuracy);
        Assert.Equal(50.4, stats.HighestWpm);
        Assert.Equal(250L, stats.DamageDealt);
        Assert.Equal(100L, stats.DamageTaken);
        Assert.Equal(30, stats.GoldEarned);
        Assert.Equal(10, stats.GoldSpent);
        Assert.Equal(1, stats.DaysSurvived);
        Assert.Equal(2, stats.WavesCompleted);
        Assert.Equal(1, stats.QuestsCompleted);
        Assert.Equal(2, report["kills"]);
        Assert.Equal(1, report["boss_kills"]);
        Assert.Equal(2, report["words_typed"]);
        Assert.Equal($"{stats.GetAccuracy():P1}", report["accuracy"]);
        Assert.Equal(8, report["highest_combo"]);
        Assert.Equal(3, report["highest_day"]);
        Assert.Equal($"{stats.HighestWpm:F1}", report["highest_wpm"]);
        Assert.Equal(30, report["gold_earned"]);
        Assert.Equal(2, report["waves_completed"]);
    }
}
