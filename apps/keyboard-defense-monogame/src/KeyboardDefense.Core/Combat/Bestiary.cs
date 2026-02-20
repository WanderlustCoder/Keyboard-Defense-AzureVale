using System;
using System.Collections.Generic;
using System.Linq;

namespace KeyboardDefense.Core.Combat;

/// <summary>
/// Bestiary tracking and enemy information system.
/// Ported from sim/bestiary.gd.
/// </summary>
public static class Bestiary
{
    public static void RecordEncounter(Dictionary<string, object> bestiaryData, string enemyKind)
    {
        if (!bestiaryData.TryGetValue(enemyKind, out var existing) || existing is not Dictionary<string, object> entry)
        {
            entry = new Dictionary<string, object>
            {
                ["kind"] = enemyKind,
                ["encounters"] = 0,
                ["defeats"] = 0,
                ["first_seen"] = DateTime.UtcNow.Ticks
            };
            bestiaryData[enemyKind] = entry;
        }
        entry["encounters"] = Convert.ToInt32(entry.GetValueOrDefault("encounters", 0)) + 1;
    }

    public static void RecordDefeat(Dictionary<string, object> bestiaryData, string enemyKind)
    {
        if (bestiaryData.TryGetValue(enemyKind, out var existing) && existing is Dictionary<string, object> entry)
        {
            entry["defeats"] = Convert.ToInt32(entry.GetValueOrDefault("defeats", 0)) + 1;
        }
    }

    public static Dictionary<string, object> GetSummary(Dictionary<string, object> bestiaryData)
    {
        int total = EnemyTypes.Registry.Count;
        int encountered = bestiaryData.Count;
        double completion = total > 0 ? (double)encountered / total : 0;

        return new Dictionary<string, object>
        {
            ["total_types"] = total,
            ["encountered"] = encountered,
            ["completion"] = completion,
        };
    }

    public static Dictionary<string, object>? GetEnemyInfo(string kind)
    {
        var def = EnemyTypes.Get(kind);
        if (def == null) return null;

        return new Dictionary<string, object>
        {
            ["name"] = def.Name,
            ["tier"] = (int)def.Tier,
            ["category"] = def.Category.ToString(),
            ["hp"] = def.Hp,
            ["armor"] = def.Armor,
            ["speed"] = def.Speed,
            ["damage"] = def.Damage,
            ["gold"] = def.Gold,
            ["abilities"] = def.Abilities.ToList(),
        };
    }

    public static List<string> GetUnencountered(Dictionary<string, object> bestiaryData)
    {
        return EnemyTypes.Registry.Keys
            .Where(kind => !bestiaryData.ContainsKey(kind))
            .ToList();
    }

    public static string FormatEntry(string kind, Dictionary<string, object>? encounterData)
    {
        var def = EnemyTypes.Get(kind);
        if (def == null) return $"Unknown: {kind}";

        string line = $"{def.Name} (T{(int)def.Tier} {def.Category})";
        line += $" HP:{def.Hp} Armor:{def.Armor} Spd:{def.Speed} Dmg:{def.Damage}";

        if (encounterData is Dictionary<string, object> entry)
        {
            int encounters = Convert.ToInt32(entry.GetValueOrDefault("encounters", 0));
            int defeats = Convert.ToInt32(entry.GetValueOrDefault("defeats", 0));
            line += $" | Seen:{encounters} Defeated:{defeats}";
        }
        else
        {
            line += " | Not yet encountered";
        }

        return line;
    }
}
