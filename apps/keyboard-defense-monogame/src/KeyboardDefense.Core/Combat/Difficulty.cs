using System;
using System.Collections.Generic;
using System.Linq;

namespace KeyboardDefense.Core.Combat;

/// <summary>
/// Difficulty mode definitions and modifier calculations.
/// Ported from sim/difficulty.gd.
/// </summary>
public static class Difficulty
{
    public const string DefaultMode = "adventure";

    public static readonly Dictionary<string, DifficultyMode> Modes = new()
    {
        ["story"] = new("Story Mode", "Experience the tale of Keystonia at your own pace.",
            0.6, 0.5, 0.8, 0.7, 1.5, 0.5, 1.0, 2, 3.0, false),
        ["adventure"] = new("Adventure Mode", "The intended experience. Balanced challenge that rewards skill.",
            1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1, 1.5, false),
        ["champion"] = new("Champion Mode", "For experienced defenders. Enemies hit harder, margins are thin.",
            1.4, 1.5, 1.2, 1.3, 0.8, 1.5, 1.3, 0, 1.0, false, "complete_act_3"),
        ["nightmare"] = new("Nightmare Mode", "The ultimate test. Only the fastest survive.",
            2.0, 2.0, 1.4, 1.5, 0.6, 2.0, 1.75, 0, 0.5, false, "complete_champion"),
        ["zen"] = new("Zen Mode", "No pressure. Pure typing practice with no enemies.",
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 99, 10.0, true),
    };

    public static DifficultyMode GetMode(string modeId) => Modes.GetValueOrDefault(modeId, Modes[DefaultMode]);
    public static string GetModeName(string modeId) => GetMode(modeId).Name;
    public static List<string> GetAllModeIds() => Modes.Keys.ToList();

    public static List<string> GetUnlockedModes(HashSet<string> badges)
    {
        var unlocked = new List<string> { "story", "adventure", "zen" };
        if (badges.Contains("full_alphabet_badge")) unlocked.Add("champion");
        if (badges.Contains("champion_complete")) unlocked.Add("nightmare");
        return unlocked;
    }

    public static int ApplyHealthModifier(int baseHp, string modeId)
        => Math.Max(1, (int)(baseHp * GetMode(modeId).EnemyHealth));

    public static int ApplyDamageModifier(int baseDamage, string modeId)
        => Math.Max(1, (int)(baseDamage * GetMode(modeId).EnemyDamage));

    public static double ApplySpeedModifier(double baseSpeed, string modeId)
        => Math.Max(0.1, baseSpeed * GetMode(modeId).EnemySpeed);

    public static int ApplyWaveSizeModifier(int baseSize, string modeId)
        => Math.Max(1, (int)(baseSize * GetMode(modeId).WaveSize));

    public static int ApplyGoldModifier(int baseGold, string modeId)
        => Math.Max(1, (int)(baseGold * GetMode(modeId).GoldEarned));
}

public record DifficultyMode(
    string Name, string Description,
    double EnemyHealth, double EnemyDamage, double EnemySpeed,
    double WaveSize, double WaveDelay, double ErrorPenalty,
    double GoldEarned, int TypoForgiveness, double WordPreviewTime,
    bool EnemiesDisabled, string? UnlockRequirement = null);
