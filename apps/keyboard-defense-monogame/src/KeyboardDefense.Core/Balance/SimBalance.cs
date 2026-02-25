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

    /// <summary>
    /// First day when exploration rewards may be redirected toward stone catch-up.
    /// </summary>
    public const int MidgameStoneCatchupDay = 4;

    /// <summary>
    /// Minimum stone stockpile that disables forced stone catch-up rewards.
    /// </summary>
    public const int MidgameStoneCatchupMin = 10;

    /// <summary>
    /// First day when the low-food midgame bonus can be granted.
    /// </summary>
    public const int MidgameFoodBonusDay = 4;

    /// <summary>
    /// Food stockpile threshold above which the midgame food bonus is not applied.
    /// </summary>
    public const int MidgameFoodBonusThreshold = 12;

    /// <summary>
    /// Flat food amount granted when the midgame low-food bonus condition is met.
    /// </summary>
    public const int MidgameFoodBonusAmount = 2;

    /// <summary>
    /// Resource soft caps applied from day 5 through day 6.
    /// </summary>
    public static readonly Dictionary<string, int> MidgameCapsDay5 = new()
    {
        ["wood"] = 40, ["stone"] = 20, ["food"] = 25
    };
    /// <summary>
    /// Resource soft caps applied from day 7 onward in midgame pacing.
    /// </summary>
    public static readonly Dictionary<string, int> MidgameCapsDay7 = new()
    {
        ["wood"] = 50, ["stone"] = 35, ["food"] = 35
    };
    /// <summary>
    /// Late-game reference caps used for balancing and tuning.
    /// </summary>
    public static readonly Dictionary<string, int> EndgameCaps = new()
    {
        ["wood"] = 100, ["stone"] = 75, ["food"] = 50, ["gold"] = 1000
    };
    /// <summary>
    /// Baseline resources granted at the start of a run.
    /// </summary>
    public static readonly Dictionary<string, int> StartingResources = new()
    {
        ["wood"] = 10, ["stone"] = 5, ["food"] = 5, ["gold"] = 0
    };

    /// <summary>
    /// Gold cost to hire one worker.
    /// </summary>
    public const int WorkerHireCost = 10;

    /// <summary>
    /// Base worker capacity before housing-based expansion.
    /// </summary>
    public const int MaxWorkersBase = 5;

    /// <summary>
    /// Additional worker capacity contributed by each house.
    /// </summary>
    public const int MaxWorkersPerHouse = 2;

    // =========================================================================
    // COMBAT CONSTANTS
    // =========================================================================

    /// <summary>
    /// Base enemy health before day and threat scaling.
    /// </summary>
    public const int EnemyHpBase = 2;

    /// <summary>
    /// Day-scaling divisor used in enemy health growth.
    /// </summary>
    public const int EnemyHpDayDivisor = 3;

    /// <summary>
    /// Threat-scaling divisor used in enemy health growth.
    /// </summary>
    public const int EnemyHpThreatDivisor = 4;

    /// <summary>
    /// Base boss health before day and threat scaling.
    /// </summary>
    public const int BossHpBase = 10;

    /// <summary>
    /// Day-scaling divisor used in boss health growth.
    /// </summary>
    public const int BossHpDayDivisor = 2;

    /// <summary>
    /// Threat-scaling divisor used in boss health growth.
    /// </summary>
    public const int BossHpThreatDivisor = 3;

    /// <summary>
    /// Base enemy count per wave before scaling factors.
    /// </summary>
    public const int WaveEnemyBaseCount = 3;

    /// <summary>
    /// Additional enemies added per day to wave size.
    /// </summary>
    public const int WaveEnemyPerDay = 1;

    /// <summary>
    /// Additional enemies added per threat point to wave size.
    /// </summary>
    public const double WaveEnemyPerThreat = 0.5;

    /// <summary>
    /// Maximum allowed threat value.
    /// </summary>
    public const int ThreatMax = 10;

    /// <summary>
    /// Threat level at which wave assault behaviors are enabled.
    /// </summary>
    public const int ThreatWaveThreshold = 5;

    /// <summary>
    /// Baseline typing damage value used by combat calculations.
    /// </summary>
    public const int TypingBaseDamage = 1;

    /// <summary>
    /// Words-per-minute threshold that grants bonus typing damage.
    /// </summary>
    public const int TypingWpmBonusThreshold = 60;

    /// <summary>
    /// Damage bonus granted when the WPM threshold is reached.
    /// </summary>
    public const int TypingWpmBonusDamage = 1;

    /// <summary>
    /// Accuracy threshold that grants bonus typing damage.
    /// </summary>
    public const double TypingAccuracyBonusThreshold = 0.95;

    /// <summary>
    /// Damage bonus granted when the accuracy threshold is reached.
    /// </summary>
    public const int TypingAccuracyBonusDamage = 1;

    /// <summary>
    /// Multiplier step applied per 10 combo points in typing damage calculations.
    /// </summary>
    public const double TypingComboBonusMultiplier = 0.1;

    // =========================================================================
    // TOWER CONSTANTS
    // =========================================================================

    /// <summary>
    /// Per-level multiplicative damage scaling for tower upgrades.
    /// </summary>
    public const double TowerUpgradeDamageMult = 1.25;

    /// <summary>
    /// Per-level multiplicative cost scaling for tower upgrades.
    /// </summary>
    public const double TowerUpgradeCostMult = 1.5;

    /// <summary>
    /// Maximum supported tower level.
    /// </summary>
    public const int TowerMaxLevel = 5;

    /// <summary>
    /// Minimum placement distance from the base for tower construction.
    /// </summary>
    public const int TowerMinDistanceFromBase = 2;

    /// <summary>
    /// Maximum number of legendary towers that can exist simultaneously.
    /// </summary>
    public const int TowerMaxLegendaryCount = 1;

    /// <summary>
    /// Hard upper bound for tracked resource values.
    /// </summary>
    public const int ResourceCap = 999;

    // =========================================================================
    // PROGRESSION MILESTONES
    // =========================================================================

    /// <summary>
    /// Day-based progression targets used to evaluate campaign pacing.
    /// </summary>
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

    /// <summary>
    /// Gold total required to satisfy the economic victory condition.
    /// </summary>
    public const int VictoryGoldTarget = 10000;

    /// <summary>
    /// Wave count required to satisfy the survival victory condition.
    /// </summary>
    public const int VictorySurvivalWaves = 50;

    // =========================================================================
    // BALANCE CALCULATION HELPERS
    // =========================================================================

    /// <summary>
    /// Redirects exploration rewards to stone during midgame when the stone stockpile is below catch-up thresholds.
    /// </summary>
    public static string MaybeOverrideExploreReward(GameState state, string rewardResource)
    {
        if (state.Day < MidgameStoneCatchupDay)
            return rewardResource;
        if (state.Resources.GetValueOrDefault("stone", 0) >= MidgameStoneCatchupMin)
            return rewardResource;
        return "stone";
    }

    /// <summary>
    /// Returns bonus food for low-food states during configured midgame days.
    /// </summary>
    public static int MidgameFoodBonus(GameState state)
    {
        if (state.Day < MidgameFoodBonusDay)
            return 0;
        if (state.Resources.GetValueOrDefault("food", 0) >= MidgameFoodBonusThreshold)
            return 0;
        return MidgameFoodBonusAmount;
    }

    /// <summary>
    /// Returns active resource caps for a specific day.
    /// </summary>
    public static Dictionary<string, int> CapsForDay(int day)
    {
        if (day >= 7) return MidgameCapsDay7;
        if (day >= 5) return MidgameCapsDay5;
        return new Dictionary<string, int>();
    }

    /// <summary>
    /// Applies active day caps to state resources and returns the trimmed overflow by resource.
    /// </summary>
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

    /// <summary>
    /// Calculates enemy hit points using base plus day and threat scaling divisors.
    /// </summary>
    public static int CalculateEnemyHp(int day, int threat)
    {
        return EnemyHpBase + (day / EnemyHpDayDivisor) + (threat / EnemyHpThreatDivisor);
    }

    /// <summary>
    /// Calculates boss hit points using base plus day and threat scaling, with an optional additive bonus.
    /// </summary>
    public static int CalculateBossHp(int day, int threat, int hpBonus = 0)
    {
        return BossHpBase + (day / BossHpDayDivisor) + (threat / BossHpThreatDivisor) + hpBonus;
    }

    /// <summary>
    /// Calculates wave size from base count with day and threat growth, clamped to at least one enemy.
    /// </summary>
    public static int CalculateWaveSize(int day, int threat)
    {
        int count = WaveEnemyBaseCount + (day * WaveEnemyPerDay) + (int)(threat * WaveEnemyPerThreat);
        return Math.Max(1, count);
    }

    /// <summary>
    /// Calculates typing damage by combining WPM and accuracy bonuses with combo-based multiplicative scaling.
    /// </summary>
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

    /// <summary>
    /// Calculates tower upgrade resource costs using exponential level scaling.
    /// </summary>
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

    /// <summary>
    /// Calculates tower damage at a target level using multiplicative upgrade scaling.
    /// </summary>
    public static int CalculateTowerDamage(int baseDamage, int level)
    {
        double multiplier = Math.Pow(TowerUpgradeDamageMult, level - 1);
        return (int)(baseDamage * multiplier);
    }

    /// <summary>
    /// Compares current progression stats against the configured milestone for a day and reports deficits.
    /// </summary>
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

    /// <summary>
    /// Returns linear difficulty scaling factor by day for downstream systems.
    /// </summary>
    public static double GetDifficultyFactor(int day)
    {
        return 1.0 + (day - 1) / 10.0;
    }

    /// <summary>
    /// Calculates day-scaled gold rewards using fixed linear growth.
    /// </summary>
    public static int CalculateGoldReward(int baseGold, int day)
    {
        double scaling = 1.0 + (day * 0.05);
        return (int)(baseGold * scaling);
    }
}
