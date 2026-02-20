using System;
using System.Collections.Generic;

namespace KeyboardDefense.Core.Typing;

/// <summary>
/// Combo tier system with bonuses and visual feedback.
/// Ported from sim/combo.gd.
/// </summary>
public static class ComboSystem
{
    public static readonly ComboTier[] Tiers = new[]
    {
        new ComboTier(0, "Default", 0, 0),
        new ComboTier(3, "Warming Up", 5, 5),
        new ComboTier(5, "On Fire", 10, 10),
        new ComboTier(10, "Blazing", 20, 15),
        new ComboTier(20, "Inferno", 35, 25),
        new ComboTier(50, "Unstoppable", 50, 40),
        new ComboTier(100, "LEGENDARY", 75, 60),
        new ComboTier(200, "GODLIKE", 100, 80),
    };

    public static int GetTierIndex(int combo)
    {
        for (int i = Tiers.Length - 1; i >= 0; i--)
        {
            if (combo >= Tiers[i].Threshold)
                return i;
        }
        return 0;
    }

    public static ComboTier GetTier(int combo) => Tiers[GetTierIndex(combo)];

    public static int GetDamageBonusPercent(int combo) => GetTier(combo).DamageBonusPercent;
    public static int GetGoldBonusPercent(int combo) => GetTier(combo).GoldBonusPercent;

    public static int ApplyDamageBonus(int baseDamage, int combo)
    {
        int bonus = GetDamageBonusPercent(combo);
        return baseDamage + (baseDamage * bonus / 100);
    }

    public static int ApplyGoldBonus(int baseGold, int combo)
    {
        int bonus = GetGoldBonusPercent(combo);
        return baseGold + (baseGold * bonus / 100);
    }

    public static bool IsTierMilestone(int oldCombo, int newCombo)
        => GetTierIndex(oldCombo) != GetTierIndex(newCombo);

    public static string GetTierAnnouncement(int combo)
    {
        var tier = GetTier(combo);
        return tier.Threshold > 0 ? $"{tier.Name}! x{combo}" : "";
    }

    public static string FormatComboDisplay(int combo)
    {
        if (combo <= 0) return "";
        var tier = GetTier(combo);
        return $"{tier.Name} x{combo}";
    }
}

public readonly struct ComboTier
{
    public int Threshold { get; }
    public string Name { get; }
    public int DamageBonusPercent { get; }
    public int GoldBonusPercent { get; }

    public ComboTier(int threshold, string name, int damageBonus, int goldBonus)
    {
        Threshold = threshold;
        Name = name;
        DamageBonusPercent = damageBonus;
        GoldBonusPercent = goldBonus;
    }
}
