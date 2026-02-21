using System;

namespace KeyboardDefense.Core.Typing;

/// <summary>
/// Calculates typing proficiency level from TypingProfile and maps it
/// to gameplay bonuses: resource multiplier, combat damage, discovery radius.
/// </summary>
public static class TypingProficiency
{
    public const double NoviceWpmThreshold = 25.0;
    public const double AdeptWpmThreshold = 40.0;
    public const double ExpertWpmThreshold = 60.0;
    public const double MasterWpmThreshold = 80.0;

    public const double MinAccuracyForBonus = 0.70;

    public enum ProficiencyTier
    {
        Novice = 0,
        Adept = 1,
        Expert = 2,
        Master = 3,
        Grandmaster = 4,
    }

    /// <summary>Calculate proficiency tier from current typing stats.</summary>
    public static ProficiencyTier GetTier()
    {
        double wpm = TypingProfile.Instance.GetAverageWpm(5);
        double accuracy = TypingProfile.Instance.GetOverallAccuracy();

        if (wpm >= MasterWpmThreshold && accuracy >= 0.95)
            return ProficiencyTier.Grandmaster;
        if (wpm >= MasterWpmThreshold && accuracy >= 0.85)
            return ProficiencyTier.Master;
        if (wpm >= ExpertWpmThreshold && accuracy >= 0.80)
            return ProficiencyTier.Expert;
        if (wpm >= AdeptWpmThreshold && accuracy >= 0.75)
            return ProficiencyTier.Adept;

        return ProficiencyTier.Novice;
    }

    /// <summary>Calculate proficiency tier from explicit WPM/accuracy values (for testing).</summary>
    public static ProficiencyTier GetTier(double wpm, double accuracy)
    {
        if (wpm >= MasterWpmThreshold && accuracy >= 0.95)
            return ProficiencyTier.Grandmaster;
        if (wpm >= MasterWpmThreshold && accuracy >= 0.85)
            return ProficiencyTier.Master;
        if (wpm >= ExpertWpmThreshold && accuracy >= 0.80)
            return ProficiencyTier.Expert;
        if (wpm >= AdeptWpmThreshold && accuracy >= 0.75)
            return ProficiencyTier.Adept;

        return ProficiencyTier.Novice;
    }

    /// <summary>Combat damage multiplier based on proficiency.</summary>
    public static double GetDamageMultiplier(ProficiencyTier tier) => tier switch
    {
        ProficiencyTier.Novice => 1.0,
        ProficiencyTier.Adept => 1.15,
        ProficiencyTier.Expert => 1.35,
        ProficiencyTier.Master => 1.6,
        ProficiencyTier.Grandmaster => 2.0,
        _ => 1.0,
    };

    /// <summary>Resource harvest multiplier based on proficiency.</summary>
    public static double GetResourceMultiplier(ProficiencyTier tier) => tier switch
    {
        ProficiencyTier.Novice => 1.0,
        ProficiencyTier.Adept => 1.1,
        ProficiencyTier.Expert => 1.25,
        ProficiencyTier.Master => 1.5,
        ProficiencyTier.Grandmaster => 1.75,
        _ => 1.0,
    };

    /// <summary>Discovery radius bonus tiles based on proficiency.</summary>
    public static int GetDiscoveryRadiusBonus(ProficiencyTier tier) => tier switch
    {
        ProficiencyTier.Novice => 0,
        ProficiencyTier.Adept => 1,
        ProficiencyTier.Expert => 2,
        ProficiencyTier.Master => 3,
        ProficiencyTier.Grandmaster => 4,
        _ => 0,
    };

    /// <summary>Gold bonus percentage based on proficiency.</summary>
    public static double GetGoldMultiplier(ProficiencyTier tier) => tier switch
    {
        ProficiencyTier.Novice => 1.0,
        ProficiencyTier.Adept => 1.1,
        ProficiencyTier.Expert => 1.2,
        ProficiencyTier.Master => 1.4,
        ProficiencyTier.Grandmaster => 1.6,
        _ => 1.0,
    };

    /// <summary>Human-readable tier name.</summary>
    public static string GetTierName(ProficiencyTier tier) => tier switch
    {
        ProficiencyTier.Novice => "Novice Typist",
        ProficiencyTier.Adept => "Adept Typist",
        ProficiencyTier.Expert => "Expert Typist",
        ProficiencyTier.Master => "Master Typist",
        ProficiencyTier.Grandmaster => "Grandmaster Typist",
        _ => "Unknown",
    };

    /// <summary>Proficiency score (0-100) combining WPM and accuracy.</summary>
    public static double GetScore(double wpm, double accuracy)
    {
        double wpmScore = Math.Clamp(wpm / 100.0, 0, 1) * 60.0;
        double accScore = Math.Clamp(accuracy, 0, 1) * 40.0;
        return wpmScore + accScore;
    }
}
