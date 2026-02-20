using System.Collections.Generic;

namespace KeyboardDefense.Core.Combat;

public enum TowerCategory { Basic = 0, Advanced = 1, Specialist = 2, Legendary = 3 }
public enum DamageType { Physical = 0, Magical, Holy, Lightning, Poison, Cold, Fire, Siege, Nature, Pure }
public enum TargetType { Single = 0, Multi, Aoe, Chain, Adaptive, None }

/// <summary>
/// Tower type definitions and registry.
/// Ported from sim/tower_types.gd.
/// </summary>
public static class TowerTypes
{
    public const string Arrow = "arrow";
    public const string Magic = "magic";
    public const string Frost = "frost";
    public const string Cannon = "cannon";
    public const string Multi = "multi";
    public const string Arcane = "arcane";
    public const string Holy = "holy";
    public const string Siege = "siege";
    public const string PoisonTower = "poison";
    public const string Tesla = "tesla";
    public const string Summoner = "summoner";
    public const string Support = "support";
    public const string Trap = "trap";
    public const string Wordsmith = "wordsmith";
    public const string Shrine = "shrine";
    public const string Purifier = "purifier";

    public static readonly Dictionary<string, TowerDef> TowerStats = new()
    {
        [Arrow] = new() { Name = "Arrow Tower", Category = TowerCategory.Basic, Damage = 3, Range = 3, Cooldown = 1.0f, DmgType = DamageType.Physical, Target = TargetType.Single },
        [Magic] = new() { Name = "Magic Tower", Category = TowerCategory.Basic, Damage = 4, Range = 3, Cooldown = 1.2f, DmgType = DamageType.Magical, Target = TargetType.Single },
        [Frost] = new() { Name = "Frost Tower", Category = TowerCategory.Basic, Damage = 2, Range = 3, Cooldown = 1.5f, DmgType = DamageType.Cold, Target = TargetType.Single },
        [Cannon] = new() { Name = "Cannon Tower", Category = TowerCategory.Basic, Damage = 6, Range = 4, Cooldown = 2.0f, DmgType = DamageType.Siege, Target = TargetType.Aoe },
        [Multi] = new() { Name = "Multi-Shot Tower", Category = TowerCategory.Advanced, Damage = 2, Range = 3, Cooldown = 0.8f, DmgType = DamageType.Physical, Target = TargetType.Multi, TargetCount = 3 },
        [Arcane] = new() { Name = "Arcane Spire", Category = TowerCategory.Advanced, Damage = 5, Range = 4, Cooldown = 1.5f, DmgType = DamageType.Magical, Target = TargetType.Adaptive },
        [Holy] = new() { Name = "Holy Beacon", Category = TowerCategory.Advanced, Damage = 4, Range = 3, Cooldown = 1.3f, DmgType = DamageType.Holy, Target = TargetType.Single },
        [Siege] = new() { Name = "Siege Engine", Category = TowerCategory.Advanced, Damage = 10, Range = 5, Cooldown = 3.0f, DmgType = DamageType.Siege, Target = TargetType.Aoe, AoeRadius = 2 },
        [PoisonTower] = new() { Name = "Poison Tower", Category = TowerCategory.Specialist, Damage = 1, Range = 3, Cooldown = 1.0f, DmgType = DamageType.Poison, Target = TargetType.Single },
        [Tesla] = new() { Name = "Tesla Coil", Category = TowerCategory.Specialist, Damage = 3, Range = 3, Cooldown = 1.2f, DmgType = DamageType.Lightning, Target = TargetType.Chain, ChainCount = 3 },
        [Summoner] = new() { Name = "Summoner Tower", Category = TowerCategory.Specialist, Damage = 0, Range = 4, Cooldown = 5.0f, DmgType = DamageType.Physical, Target = TargetType.None },
        [Support] = new() { Name = "Support Tower", Category = TowerCategory.Specialist, Damage = 0, Range = 3, Cooldown = 0f, DmgType = DamageType.Physical, Target = TargetType.None },
        [Trap] = new() { Name = "Trap Tower", Category = TowerCategory.Specialist, Damage = 0, Range = 2, Cooldown = 4.0f, DmgType = DamageType.Physical, Target = TargetType.None },
        [Wordsmith] = new() { Name = "Wordsmith Tower", Category = TowerCategory.Legendary, Damage = 8, Range = 5, Cooldown = 1.0f, DmgType = DamageType.Pure, Target = TargetType.Single, IsLegendary = true },
        [Shrine] = new() { Name = "Shrine of Words", Category = TowerCategory.Legendary, Damage = 0, Range = 6, Cooldown = 0f, DmgType = DamageType.Holy, Target = TargetType.None, IsLegendary = true },
        [Purifier] = new() { Name = "Purifier", Category = TowerCategory.Legendary, Damage = 12, Range = 4, Cooldown = 2.0f, DmgType = DamageType.Pure, Target = TargetType.Aoe, AoeRadius = 2, IsLegendary = true },
    };

    public static bool IsValidTowerType(string type) => TowerStats.ContainsKey(type);
    public static TowerDef? GetTowerData(string type) => TowerStats.GetValueOrDefault(type);
    public static string GetTowerName(string type) => TowerStats.GetValueOrDefault(type)?.Name ?? type;
    public static bool IsLegendary(string type) => TowerStats.GetValueOrDefault(type)?.IsLegendary ?? false;

    public static TowerCategory GetCategory(string type)
        => TowerStats.GetValueOrDefault(type)?.Category ?? TowerCategory.Basic;
}

public class TowerDef
{
    public string Name { get; set; } = "";
    public TowerCategory Category { get; set; }
    public int Damage { get; set; }
    public int Range { get; set; }
    public float Cooldown { get; set; }
    public DamageType DmgType { get; set; }
    public TargetType Target { get; set; }
    public int TargetCount { get; set; } = 1;
    public int AoeRadius { get; set; } = 1;
    public int ChainCount { get; set; } = 1;
    public bool IsLegendary { get; set; }
}
