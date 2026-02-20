using System;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Core.Progression;

namespace KeyboardDefense.Core.Combat;

/// <summary>
/// Tower damage bonuses based on typing performance.
/// Ported from sim/typing_tower_bonuses.gd.
/// </summary>
public static class TypingTowerBonuses
{
    public const double WordsmithWpmScale = 100.0;
    public const double WordsmithAccuracyPower = 2.0;
    public const double ArcaneMaxAccuracyBonus = 1.5;
    public const double LetterSpiritPerLetter = 0.05;
    public const double LetterSpiritMaxBonus = 1.30;
    public const double MinAccuracyForBonus = 0.5;

    public static double GetTowerDamageMultiplier(GameState state, string towerId)
    {
        double multiplier = 1.0;
        int comboCount = TypingMetrics.GetComboCount(state);
        double comboMult = TypingMetrics.GetComboMultiplier(comboCount);
        multiplier *= comboMult;

        multiplier *= towerId switch
        {
            TowerTypes.Wordsmith => GetWordsmithBonus(state),
            TowerTypes.Arcane => GetArcaneBonus(state),
            TowerTypes.Shrine => GetLetterShrineBonus(state),
            TowerTypes.Arrow or TowerTypes.Multi => GetAccuracyBonus(state, 0.2),
            TowerTypes.Magic => GetAccuracyBonus(state, 0.3),
            TowerTypes.Frost => GetAccuracyBonus(state, 0.25),
            TowerTypes.Holy or TowerTypes.Purifier => GetPerfectStreakBonus(state),
            TowerTypes.Tesla => GetChainDamageBonus(state),
            TowerTypes.Siege => GetSustainedBonus(state),
            _ => 1.0
        };

        return multiplier;
    }

    public static int GetChainBonus(GameState state, string towerId)
    {
        if (towerId != TowerTypes.Tesla) return 0;
        int combo = TypingMetrics.GetComboCount(state);
        if (combo >= 50) return 3;
        if (combo >= 20) return 2;
        if (combo >= 10) return 1;
        return 0;
    }

    public static double GetAttackSpeedMultiplier(GameState state, string towerId)
    {
        double wpm = TypingMetrics.GetWpm(state);
        double speedMult = 1.0 + (wpm / 200.0);
        return Math.Clamp(speedMult, 1.0, 2.0);
    }

    private static double GetWordsmithBonus(GameState state)
    {
        double wpm = TypingMetrics.GetWpm(state);
        double accuracy = TypingMetrics.GetAccuracy(state);
        if (accuracy < MinAccuracyForBonus) return 1.0;
        double wpmBonus = 1.0 + (wpm / WordsmithWpmScale);
        double accuracyMult = Math.Pow(accuracy, WordsmithAccuracyPower);
        return wpmBonus * accuracyMult;
    }

    private static double GetArcaneBonus(GameState state)
    {
        double accuracy = TypingMetrics.GetAccuracy(state);
        if (accuracy < MinAccuracyForBonus) return 1.0;
        return 1.0 + (accuracy - MinAccuracyForBonus) * (ArcaneMaxAccuracyBonus - 1.0) / (1.0 - MinAccuracyForBonus);
    }

    private static double GetLetterShrineBonus(GameState state)
    {
        int uniqueCount = TypingMetrics.GetUniqueLetterCount(state);
        double bonus = 1.0 + (uniqueCount * LetterSpiritPerLetter);
        return Math.Min(bonus, 1.0 + LetterSpiritMaxBonus);
    }

    private static double GetAccuracyBonus(GameState state, double maxBonus)
    {
        double accuracy = TypingMetrics.GetAccuracy(state);
        if (accuracy < MinAccuracyForBonus) return 1.0;
        return 1.0 + (accuracy - MinAccuracyForBonus) * maxBonus / (1.0 - MinAccuracyForBonus);
    }

    private static double GetPerfectStreakBonus(GameState state)
    {
        int streak = TypingMetrics.GetPerfectStreak(state);
        return 1.0 + Math.Min(streak * 0.1, 0.5);
    }

    private static double GetChainDamageBonus(GameState state)
    {
        int combo = TypingMetrics.GetComboCount(state);
        return 1.0 + Math.Min(combo * 0.02, 0.5);
    }

    private static double GetSustainedBonus(GameState state)
    {
        int chars = TypingMetrics.GetCharsTyped(state);
        double duration = TypingMetrics.GetBattleDuration(state);
        if (duration < 5.0) return 1.0;
        double charsPerSec = chars / duration;
        return 1.0 + Math.Min(charsPerSec * 0.05, 0.5);
    }

    public static string GetLetterShrineMode(GameState state)
    {
        int uniqueCount = TypingMetrics.GetUniqueLetterCount(state);
        int combo = TypingMetrics.GetComboCount(state);
        if (uniqueCount >= 20) return "epsilon";
        if (combo >= 30) return "omega";
        return "alpha";
    }
}
