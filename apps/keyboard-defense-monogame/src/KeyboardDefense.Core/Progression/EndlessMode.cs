using System;
using System.Collections.Generic;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Progression;

/// <summary>
/// Infinite scaling challenge mode.
/// Ported from sim/endless_mode.gd.
/// </summary>
public static class EndlessMode
{
    public const int UnlockDay = 15;
    public const int UnlockWaves = 45;
    public const double HpScalePerDay = 0.08;
    public const double SpeedScalePerDay = 0.02;
    public const double CountScalePerDay = 0.05;
    public const double DamageScalePerDay = 0.04;

    public static bool IsUnlocked(GameState state) => state.Day >= UnlockDay;

    public static double GetHpScale(int endlessDay) => 1.0 + endlessDay * HpScalePerDay;
    public static double GetSpeedScale(int endlessDay) => 1.0 + endlessDay * SpeedScalePerDay;
    public static double GetCountScale(int endlessDay) => 1.0 + endlessDay * CountScalePerDay;
    public static double GetDamageScale(int endlessDay) => 1.0 + endlessDay * DamageScalePerDay;

    public static readonly Dictionary<int, EndlessMilestone> Milestones = new()
    {
        [5] = new("Enduring", 500, "Survived 5 endless days"),
        [10] = new("Relentless", 1000, "Survived 10 endless days"),
        [15] = new("Unstoppable", 2000, "Survived 15 endless days"),
        [20] = new("Legendary", 5000, "Survived 20 endless days"),
        [30] = new("Mythic", 10000, "Survived 30 endless days"),
    };

    public static EndlessMilestone? CheckMilestone(int endlessDay)
        => Milestones.GetValueOrDefault(endlessDay);

    public static int CalculateWaveSize(int endlessDay, int baseThreat)
    {
        int baseSize = 3 + endlessDay;
        return (int)(baseSize * GetCountScale(endlessDay)) + baseThreat / 2;
    }

    public static int CalculateEnemyHp(int endlessDay, int baseHp)
        => (int)(baseHp * GetHpScale(endlessDay));
}

public record EndlessMilestone(string Name, int GoldReward, string Description);
