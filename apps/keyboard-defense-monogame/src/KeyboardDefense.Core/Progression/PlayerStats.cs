using System;
using System.Collections.Generic;

namespace KeyboardDefense.Core.Progression;

/// <summary>
/// Comprehensive player statistics tracking.
/// Ported from sim/player_stats.gd.
/// </summary>
public class PlayerStats
{
    // Combat
    public int Kills { get; set; }
    public int BossKills { get; set; }
    public long DamageDealt { get; set; }
    public long DamageTaken { get; set; }
    public int Deaths { get; set; }

    // Typing
    public int WordsTyped { get; set; }
    public long CharsTyped { get; set; }
    public int Typos { get; set; }
    public int PerfectWords { get; set; }

    // Economy
    public int GoldEarned { get; set; }
    public int GoldSpent { get; set; }

    // Progression
    public int DaysSurvived { get; set; }
    public int WavesCompleted { get; set; }
    public int QuestsCompleted { get; set; }

    // Records
    public int HighestCombo { get; set; }
    public int HighestDay { get; set; }
    public double HighestAccuracy { get; set; }
    public double HighestWpm { get; set; }

    public double GetAccuracy() => WordsTyped > 0 ? (double)PerfectWords / WordsTyped : 0;
    public double GetKdRatio() => Deaths > 0 ? (double)Kills / Deaths : Kills;

    public void RecordKill(bool isBoss = false)
    {
        Kills++;
        if (isBoss) BossKills++;
    }

    public void RecordWord(bool perfect, int charCount)
    {
        WordsTyped++;
        CharsTyped += charCount;
        if (perfect) PerfectWords++;
        else Typos++;
    }

    public void RecordCombo(int combo) => HighestCombo = Math.Max(HighestCombo, combo);
    public void RecordDay(int day) => HighestDay = Math.Max(HighestDay, day);
    public void RecordAccuracy(double accuracy) => HighestAccuracy = Math.Max(HighestAccuracy, accuracy);
    public void RecordWpm(double wpm) => HighestWpm = Math.Max(HighestWpm, wpm);

    public Dictionary<string, object> GetReport()
    {
        return new()
        {
            ["kills"] = Kills,
            ["boss_kills"] = BossKills,
            ["words_typed"] = WordsTyped,
            ["accuracy"] = $"{GetAccuracy():P1}",
            ["highest_combo"] = HighestCombo,
            ["highest_day"] = HighestDay,
            ["highest_wpm"] = $"{HighestWpm:F1}",
            ["gold_earned"] = GoldEarned,
            ["waves_completed"] = WavesCompleted,
        };
    }
}
