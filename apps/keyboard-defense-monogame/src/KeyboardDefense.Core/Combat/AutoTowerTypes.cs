using System.Collections.Generic;
using System.Linq;

namespace KeyboardDefense.Core.Combat;

/// <summary>
/// Auto-defense tower definitions and upgrade paths.
/// Ported from sim/auto_tower_types.gd.
/// </summary>
public static class AutoTowerTypes
{
    public enum AutoTier { Tier1 = 1, Tier2 = 2, Tier3 = 3, Tier4 = 4 }
    public enum AutoTargetMode { Nearest, HighestHp, LowestHp, Fastest, Cluster, Chain, Zone, Contact, Smart }
    public enum AutoDamageType { Physical, Lightning, Fire, Nature, Siege }

    public const string Sentry = "auto_sentry";
    public const string Spark = "auto_spark";
    public const string Thorns = "auto_thorns";
    public const string Ballista = "auto_ballista";
    public const string Tesla = "auto_tesla";
    public const string Bramble = "auto_bramble";
    public const string Flame = "auto_flame";
    public const string Cannon = "auto_cannon";
    public const string Storm = "auto_storm";
    public const string Fortress = "auto_fortress";
    public const string Inferno = "auto_inferno";
    public const string Arcane = "auto_arcane";
    public const string Doom = "auto_doom";

    public static readonly Dictionary<string, AutoTowerDef> Towers = new()
    {
        [Sentry] = new("Sentry Turret", AutoTier.Tier1, 5, 0.8, 3, AutoTargetMode.Nearest, AutoDamageType.Physical,
            new() { ["gold"] = 80, ["wood"] = 6, ["stone"] = 10 }),
        [Spark] = new("Spark Coil", AutoTier.Tier1, 3, 0.67, 2, AutoTargetMode.Zone, AutoDamageType.Lightning,
            new() { ["gold"] = 100, ["wood"] = 4, ["stone"] = 8 }),
        [Thorns] = new("Thorn Barrier", AutoTier.Tier1, 8, 0.0, 1, AutoTargetMode.Contact, AutoDamageType.Nature,
            new() { ["gold"] = 60, ["wood"] = 8 }),
        [Ballista] = new("Ballista Emplacement", AutoTier.Tier2, 25, 0.3, 6, AutoTargetMode.HighestHp, AutoDamageType.Siege,
            new() { ["gold"] = 230, ["wood"] = 10, ["stone"] = 15 }),
        [Tesla] = new("Tesla Array", AutoTier.Tier2, 8, 1.0, 4, AutoTargetMode.Chain, AutoDamageType.Lightning,
            new() { ["gold"] = 280, ["wood"] = 6, ["stone"] = 12 }),
        [Bramble] = new("Bramble Maze", AutoTier.Tier2, 4, 2.0, 3, AutoTargetMode.Zone, AutoDamageType.Nature,
            new() { ["gold"] = 180, ["wood"] = 15, ["stone"] = 5 }),
        [Flame] = new("Flame Jet", AutoTier.Tier2, 6, 2.0, 3, AutoTargetMode.Nearest, AutoDamageType.Fire,
            new() { ["gold"] = 250, ["wood"] = 8, ["stone"] = 10 }),
        [Cannon] = new("Siege Cannon", AutoTier.Tier3, 50, 0.2, 8, AutoTargetMode.Cluster, AutoDamageType.Siege,
            new() { ["gold"] = 530, ["wood"] = 15, ["stone"] = 30 }),
        [Storm] = new("Storm Spire", AutoTier.Tier3, 15, 0.5, 6, AutoTargetMode.Cluster, AutoDamageType.Lightning,
            new() { ["gold"] = 630, ["wood"] = 8, ["stone"] = 20 }),
        [Fortress] = new("Living Fortress", AutoTier.Tier3, 20, 0.8, 2, AutoTargetMode.Zone, AutoDamageType.Nature,
            new() { ["gold"] = 520, ["wood"] = 30, ["stone"] = 10 }),
        [Inferno] = new("Inferno Engine", AutoTier.Tier3, 10, 3.0, 4, AutoTargetMode.Nearest, AutoDamageType.Fire,
            new() { ["gold"] = 580, ["wood"] = 12, ["stone"] = 15 }),
        [Arcane] = new("Arcane Sentinel", AutoTier.Tier4, 35, 1.2, 5, AutoTargetMode.Smart, AutoDamageType.Physical,
            new() { ["gold"] = 1200, ["wood"] = 20, ["stone"] = 30 }, isLegendary: true),
        [Doom] = new("Doom Fortress", AutoTier.Tier4, 80, 0.15, 7, AutoTargetMode.Cluster, AutoDamageType.Siege,
            new() { ["gold"] = 2000, ["wood"] = 50, ["stone"] = 80 }, isLegendary: true),
    };

    public static readonly Dictionary<string, string[]> UpgradePaths = new()
    {
        [Sentry] = new[] { Ballista },
        [Spark] = new[] { Tesla },
        [Thorns] = new[] { Bramble },
        [Flame] = new[] { Inferno },
        [Ballista] = new[] { Cannon },
        [Tesla] = new[] { Storm },
        [Bramble] = new[] { Fortress },
    };

    public static AutoTowerDef? GetTower(string id) => Towers.GetValueOrDefault(id);
    public static string GetTowerName(string id) => Towers.GetValueOrDefault(id)?.Name ?? id;
    public static bool IsValidTower(string id) => Towers.ContainsKey(id);
    public static bool IsLegendary(string id) => Towers.GetValueOrDefault(id)?.IsLegendary ?? false;

    public static string[] GetUpgradeOptions(string id) => UpgradePaths.GetValueOrDefault(id, System.Array.Empty<string>());
    public static bool CanUpgradeTo(string fromId, string toId) => GetUpgradeOptions(fromId).Contains(toId);

    public static double GetDps(string id)
    {
        var tower = GetTower(id);
        if (tower == null || tower.AttackSpeed <= 0) return 0;
        return tower.Damage * tower.AttackSpeed;
    }

    public static List<string> GetTowersByTier(AutoTier tier)
        => Towers.Where(kv => kv.Value.Tier == tier).Select(kv => kv.Key).ToList();
}

public record AutoTowerDef(
    string Name, AutoTowerTypes.AutoTier Tier, int Damage, double AttackSpeed, int Range,
    AutoTowerTypes.AutoTargetMode Targeting, AutoTowerTypes.AutoDamageType DmgType,
    Dictionary<string, int> Cost, bool isLegendary = false)
{
    public bool IsLegendary => isLegendary;
}
