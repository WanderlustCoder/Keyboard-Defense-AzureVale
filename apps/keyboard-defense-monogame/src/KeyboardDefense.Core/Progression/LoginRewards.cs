using System;
using System.Collections.Generic;

namespace KeyboardDefense.Core.Progression;

/// <summary>
/// Login streak reward system.
/// Ported from sim/login_rewards.gd.
/// </summary>
public static class LoginRewards
{
    public static readonly Dictionary<int, LoginRewardDef> Rewards = new()
    {
        [1] = new("Welcome Back", 10, null),
        [2] = new("Returning Hero", 15, "power_boost"),
        [3] = new("Dedicated", 20, "accuracy_boost"),
        [5] = new("Committed", 30, "xp_boost"),
        [7] = new("Weekly Warrior", 50, "combo_boost"),
        [14] = new("Fortnight Fighter", 75, "gold_rush"),
        [30] = new("Monthly Master", 100, "mega_boost"),
    };

    public static LoginRewardDef GetReward(int streakDays)
    {
        LoginRewardDef? best = null;
        foreach (var (day, reward) in Rewards)
        {
            if (streakDays >= day)
                best = reward;
        }
        return best ?? new("Login Bonus", 5, null);
    }

    public static Dictionary<string, object> ClaimReward(int streakDays)
    {
        var reward = GetReward(streakDays);
        return new()
        {
            ["gold"] = reward.GoldReward,
            ["bonus_item"] = reward.BonusItem ?? "",
            ["message"] = $"{reward.Name}: +{reward.GoldReward} gold" +
                (reward.BonusItem != null ? $" + {reward.BonusItem}" : "")
        };
    }
}

public record LoginRewardDef(string Name, int GoldReward, string? BonusItem);
