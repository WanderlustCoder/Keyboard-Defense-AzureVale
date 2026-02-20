using System.Collections.Generic;

namespace KeyboardDefense.Core.Combat;

/// <summary>
/// Status effect definitions and registry.
/// Ported from sim/status_effects.gd.
/// </summary>
public static class StatusEffects
{
    public const string CategoryDebuff = "debuff";
    public const string CategoryBuff = "buff";

    public static readonly Dictionary<string, StatusEffectDef> Effects = new()
    {
        ["slow"] = new() { Name = "Slowed", Category = CategoryDebuff, Duration = 3.0f, SpeedMod = -0.3f, MaxStacks = 3 },
        ["frozen"] = new() { Name = "Frozen", Category = CategoryDebuff, Duration = 1.5f, Immobilized = true },
        ["rooted"] = new() { Name = "Rooted", Category = CategoryDebuff, Duration = 2.0f, Immobilized = true },
        ["burning"] = new() { Name = "Burning", Category = CategoryDebuff, Duration = 5.0f, DotDamage = 3, MaxStacks = 5 },
        ["poisoned"] = new() { Name = "Poisoned", Category = CategoryDebuff, Duration = 8.0f, DotDamage = 2, MaxStacks = 10 },
        ["bleeding"] = new() { Name = "Bleeding", Category = CategoryDebuff, Duration = 6.0f, DotDamage = 4, MaxStacks = 3 },
        ["corrupting"] = new() { Name = "Corrupting", Category = CategoryDebuff, Duration = 10.0f, DotDamage = 5 },
        ["armor_broken"] = new() { Name = "Armor Broken", Category = CategoryDebuff, Duration = 8.0f, ArmorMod = -0.5f },
        ["exposed"] = new() { Name = "Exposed", Category = CategoryDebuff, Duration = 5.0f, DamageTakenMod = 0.25f },
    };

    public static StatusEffectDef? GetEffect(string id) => Effects.GetValueOrDefault(id);
    public static string GetEffectName(string id) => Effects.GetValueOrDefault(id)?.Name ?? id;
}

public class StatusEffectDef
{
    public string Name { get; set; } = "";
    public string Category { get; set; } = "debuff";
    public float Duration { get; set; }
    public float SpeedMod { get; set; }
    public float ArmorMod { get; set; }
    public float DamageTakenMod { get; set; }
    public int DotDamage { get; set; }
    public int MaxStacks { get; set; } = 1;
    public bool Immobilized { get; set; }
}
