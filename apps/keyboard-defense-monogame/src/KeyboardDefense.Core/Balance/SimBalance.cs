using System;
using System.Collections.Generic;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Balance;

/// <summary>
/// Centralized balance constants and formulas for Keyboard Defense.
/// Ported from sim/balance.gd (SimBalance class).
/// </summary>
public static class SimBalance
{
    // =========================================================================
    // ECONOMY CONSTANTS
    // =========================================================================

    public const int MidgameStoneCatchupDay = 4;
    public const int MidgameStoneCatchupMin = 10;
    public const int MidgameFoodBonusDay = 4;
    public const int MidgameFoodBonusThreshold = 12;
    public const int MidgameFoodBonusAmount = 2;

    public static readonly Dictionary<string, int> MidgameCapsDay5 = new()
    {
        ["wood"] = 40, ["stone"] = 20, ["food"] = 25
    };
    public static readonly Dictionary<string, int> MidgameCapsDay7 = new()
    {
        ["wood"] = 50, ["stone"] = 35, ["food"] = 35
    };
    public static readonly Dictionary<string, int> EndgameCaps = new()
    {
        ["wood"] = 100, ["stone"] = 75, ["food"] = 50, ["gold"] = 1000
    };
    public static readonly Dictionary<string, int> StartingResources = new()
    {
        ["wood"] = 10, ["stone"] = 5, ["food"] = 5, ["gold"] = 0
    };

    public const int WorkerHireCost = 10;
    public const int MaxWorkersBase = 5;
    public const int MaxWorkersPerHouse = 2;

    // =========================================================================
    // COMBAT CONSTANTS
    // =========================================================================

    public const int EnemyHpBase = 2;
    public const int EnemyHpDayDivisor = 3;
    public const int EnemyHpThreatDivisor = 4;

    public const int BossHpBase = 10;
    public const int BossHpDayDivisor = 2;
    public const int BossHpThreatDivisor = 3;

    public const int WaveEnemyBaseCount = 3;
    public const int WaveEnemyPerDay = 1;
    public const double WaveEnemyPerThreat = 0.5;

    public const int ThreatMax = 10;
    public const int ThreatWaveThreshold = 5;

    public const int TypingBaseDamage = 1;
    public const int TypingWpmBonusThreshold = 60;
    public const int TypingWpmBonusDamage = 1;
    public const double TypingAccuracyBonusThreshold = 0.95;
    public const int TypingAccuracyBonusDamage = 1;
    public const double TypingComboBonusMultiplier = 0.1;

    // =========================================================================
    // TOWER CONSTANTS
    // =========================================================================

    public const double TowerUpgradeDamageMult = 1.25;
    public const double TowerUpgradeCostMult = 1.5;
    public const int TowerMaxLevel = 5;
    public const int TowerMinDistanceFromBase = 2;
    public const int TowerMaxLegendaryCount = 1;
    public const int ResourceCap = 999;

    // =========================================================================
    // PROGRESSION MILESTONES
    // =========================================================================

    public static readonly Dictionary<int, (int Buildings, int Towers, int Gold)> ProgressionMilestones = new()
    {
        [1] = (1, 0, 0),
        [3] = (3, 1, 20),
        [5] = (5, 2, 50),
        [7] = (7, 3, 100),
        [10] = (10, 5, 200),
        [15] = (15, 7, 400),
        [20] = (20, 10, 750),
    };

    public const int VictoryGoldTarget = 10000;
    public const int VictorySurvivalWaves = 50;

    // =========================================================================
    // BALANCE CALCULATION HELPERS
    // =========================================================================

    public static string MaybeOverrideExploreReward(GameState state, string rewardResource)
    {
        if (state.Day < MidgameStoneCatchupDay)
            return rewardResource;
        if (state.Resources.GetValueOrDefault("stone", 0) >= MidgameStoneCatchupMin)
            return rewardResource;
        return "stone";
    }

    public static int MidgameFoodBonus(GameState state)
    {
        if (state.Day < MidgameFoodBonusDay)
            return 0;
        if (state.Resources.GetValueOrDefault("food", 0) >= MidgameFoodBonusThreshold)
            return 0;
        return MidgameFoodBonusAmount;
    }

    public static Dictionary<string, int> CapsForDay(int day)
    {
        if (day >= 7) return MidgameCapsDay7;
        if (day >= 5) return MidgameCapsDay5;
        return new Dictionary<string, int>();
    }

    public static Dictionary<string, int> ApplyResourceCaps(GameState state)
    {
        var caps = CapsForDay(state.Day);
        var trimmed = new Dictionary<string, int>();
        foreach (var (key, cap) in caps)
        {
            int value = state.Resources.GetValueOrDefault(key, 0);
            if (value > cap)
            {
                int delta = value - cap;
                state.Resources[key] = cap;
                trimmed[key] = delta;
            }
        }
        return trimmed;
    }

    public static int CalculateEnemyHp(int day, int threat)
    {
        return EnemyHpBase + (day / EnemyHpDayDivisor) + (threat / EnemyHpThreatDivisor);
    }

    public static int CalculateBossHp(int day, int threat, int hpBonus = 0)
    {
        return BossHpBase + (day / BossHpDayDivisor) + (threat / BossHpThreatDivisor) + hpBonus;
    }

    public static int CalculateWaveSize(int day, int threat)
    {
        int count = WaveEnemyBaseCount + (day * WaveEnemyPerDay) + (int)(threat * WaveEnemyPerThreat);
        return Math.Max(1, count);
    }

    public static int CalculateTypingDamage(int baseDamage, double wpm, double accuracy, int combo)
    {
        int damage = baseDamage;

        if (wpm >= TypingWpmBonusThreshold)
            damage += TypingWpmBonusDamage;

        if (accuracy >= TypingAccuracyBonusThreshold)
            damage += TypingAccuracyBonusDamage;

        double comboBonus = 1.0 + ((combo / 10) * TypingComboBonusMultiplier);
        damage = (int)(damage * comboBonus);

        return Math.Max(1, damage);
    }

    public static Dictionary<string, int> CalculateUpgradeCost(Dictionary<string, int> baseCost, int currentLevel)
    {
        double multiplier = Math.Pow(TowerUpgradeCostMult, currentLevel);
        var result = new Dictionary<string, int>();
        foreach (var (resource, cost) in baseCost)
        {
            result[resource] = (int)(cost * multiplier);
        }
        return result;
    }

    public static int CalculateTowerDamage(int baseDamage, int level)
    {
        double multiplier = Math.Pow(TowerUpgradeDamageMult, level - 1);
        return (int)(baseDamage * multiplier);
    }

    public static (bool OnTrack, List<string> Issues) CheckMilestone(int day, int buildings, int towers, int gold)
    {
        if (!ProgressionMilestones.TryGetValue(day, out var milestone))
            return (true, new List<string>());

        var issues = new List<string>();
        if (buildings < milestone.Buildings)
            issues.Add($"Buildings behind ({buildings}/{milestone.Buildings})");
        if (towers < milestone.Towers)
            issues.Add($"Towers behind ({towers}/{milestone.Towers})");
        if (gold < milestone.Gold)
            issues.Add($"Gold behind ({gold}/{milestone.Gold})");

        return (issues.Count == 0, issues);
    }

    public static double GetDifficultyFactor(int day)
    {
        return 1.0 + (day - 1) / 10.0;
    }

    public static int CalculateGoldReward(int baseGold, int day)
    {
        double scaling = 1.0 + (day * 0.05);
        return (int)(baseGold * scaling);
    }
}
