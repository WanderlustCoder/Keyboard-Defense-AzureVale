using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Combat;

namespace KeyboardDefense.Tests.Core;

public class BestiaryCoreTests
{
    [Fact]
    public void RecordEncounter_NewKind_CreatesEntryWithEncounterOneAndDefaults()
    {
        var bestiaryData = new Dictionary<string, object>();
        long before = DateTime.UtcNow.Ticks;

        Bestiary.RecordEncounter(bestiaryData, "raider");

        long after = DateTime.UtcNow.Ticks;
        var entry = Assert.IsType<Dictionary<string, object>>(bestiaryData["raider"]);
        long firstSeen = Convert.ToInt64(entry["first_seen"]);

        Assert.Equal("raider", entry["kind"]);
        Assert.Equal(1, Convert.ToInt32(entry["encounters"]));
        Assert.Equal(0, Convert.ToInt32(entry["defeats"]));
        Assert.InRange(firstSeen, before, after);
    }

    [Fact]
    public void RecordEncounter_ExistingKind_IncrementsEncounters()
    {
        var entry = new Dictionary<string, object>
        {
            ["kind"] = "raider",
            ["encounters"] = 3,
            ["defeats"] = 2,
            ["first_seen"] = 12345L,
        };

        var bestiaryData = new Dictionary<string, object>
        {
            ["raider"] = entry,
        };

        Bestiary.RecordEncounter(bestiaryData, "raider");

        Assert.Equal(4, Convert.ToInt32(entry["encounters"]));
        Assert.Equal(2, Convert.ToInt32(entry["defeats"]));
        Assert.Equal(12345L, Convert.ToInt64(entry["first_seen"]));
    }

    [Fact]
    public void RecordEncounter_ExistingNonDictionaryEntry_ReplacesWithValidEntry()
    {
        var bestiaryData = new Dictionary<string, object>
        {
            ["raider"] = "invalid",
        };

        Bestiary.RecordEncounter(bestiaryData, "raider");

        var entry = Assert.IsType<Dictionary<string, object>>(bestiaryData["raider"]);
        Assert.Equal("raider", entry["kind"]);
        Assert.Equal(1, Convert.ToInt32(entry["encounters"]));
        Assert.Equal(0, Convert.ToInt32(entry["defeats"]));
    }

    [Fact]
    public void RecordDefeat_ExistingKind_IncrementsDefeats()
    {
        var entry = new Dictionary<string, object>
        {
            ["kind"] = "tank",
            ["encounters"] = 2,
            ["defeats"] = 1,
        };

        var bestiaryData = new Dictionary<string, object>
        {
            ["tank"] = entry,
        };

        Bestiary.RecordDefeat(bestiaryData, "tank");

        Assert.Equal(2, Convert.ToInt32(entry["defeats"]));
        Assert.Equal(2, Convert.ToInt32(entry["encounters"]));
    }

    [Fact]
    public void RecordDefeat_NonExistingKind_DoesNothing()
    {
        var bestiaryData = CreateBestiaryDataFromKinds("raider");

        Bestiary.RecordDefeat(bestiaryData, "tank");

        Assert.Single(bestiaryData);
        Assert.False(bestiaryData.ContainsKey("tank"));
    }

    [Fact]
    public void RecordDefeat_ExistingNonDictionaryEntry_DoesNothing()
    {
        var bestiaryData = new Dictionary<string, object>
        {
            ["tank"] = "invalid",
        };

        Bestiary.RecordDefeat(bestiaryData, "tank");

        Assert.Equal("invalid", bestiaryData["tank"]);
    }

    [Fact]
    public void GetSummary_EmptyData_ReturnsZeroEncounteredAndCompletion()
    {
        var summary = Bestiary.GetSummary(new Dictionary<string, object>());

        Assert.Equal(EnemyTypes.Registry.Count, Convert.ToInt32(summary["total_types"]));
        Assert.Equal(0, Convert.ToInt32(summary["encountered"]));
        Assert.Equal(0.0, Convert.ToDouble(summary["completion"]));
    }

    [Fact]
    public void GetSummary_WithEntries_ReturnsExpectedCounts()
    {
        var bestiaryData = CreateBestiaryDataFromKinds("raider", "tank", "warlord");

        var summary = Bestiary.GetSummary(bestiaryData);
        double expectedCompletion = 3d / EnemyTypes.Registry.Count;

        Assert.Equal(EnemyTypes.Registry.Count, Convert.ToInt32(summary["total_types"]));
        Assert.Equal(3, Convert.ToInt32(summary["encountered"]));
        Assert.Equal(expectedCompletion, Convert.ToDouble(summary["completion"]), 10);
    }

    [Fact]
    public void GetSummary_AllTypesEncountered_ReturnsCompletionOne()
    {
        var bestiaryData = CreateBestiaryDataFromKinds(EnemyTypes.Registry.Keys.ToArray());

        var summary = Bestiary.GetSummary(bestiaryData);

        Assert.Equal(EnemyTypes.Registry.Count, Convert.ToInt32(summary["encountered"]));
        Assert.Equal(1.0, Convert.ToDouble(summary["completion"]));
    }

    [Fact]
    public void GetEnemyInfo_KnownKind_ReturnsExpectedKeys()
    {
        var info = Bestiary.GetEnemyInfo("armored");

        Assert.NotNull(info);
        Assert.Equal(
            new[] { "name", "tier", "category", "hp", "armor", "speed", "damage", "gold", "abilities" },
            info!.Keys);
    }

    [Fact]
    public void GetEnemyInfo_KnownKind_MapsDefinitionValues()
    {
        var def = EnemyTypes.Get("armored")!;
        var info = Bestiary.GetEnemyInfo("armored");

        Assert.NotNull(info);
        Assert.Equal(def.Name, info!["name"]);
        Assert.Equal((int)def.Tier, Convert.ToInt32(info["tier"]));
        Assert.Equal(def.Category.ToString(), info["category"]);
        Assert.Equal(def.Hp, Convert.ToInt32(info["hp"]));
        Assert.Equal(def.Armor, Convert.ToInt32(info["armor"]));
        Assert.Equal(def.Speed, Convert.ToInt32(info["speed"]));
        Assert.Equal(def.Damage, Convert.ToInt32(info["damage"]));
        Assert.Equal(def.Gold, Convert.ToInt32(info["gold"]));

        var abilities = Assert.IsType<List<string>>(info["abilities"]);
        Assert.Equal(def.Abilities, abilities);
    }

    [Fact]
    public void GetEnemyInfo_UnknownKind_ReturnsNull()
    {
        Assert.Null(Bestiary.GetEnemyInfo("unknown_enemy_kind"));
    }

    [Fact]
    public void GetUnencountered_EmptyData_ReturnsAllRegistryKinds()
    {
        var unencountered = Bestiary.GetUnencountered(new Dictionary<string, object>());

        Assert.Equal(EnemyTypes.Registry.Keys, unencountered);
    }

    [Fact]
    public void GetUnencountered_WithEncounteredKinds_ReturnsOnlyRemainingKinds()
    {
        var bestiaryData = CreateBestiaryDataFromKinds("raider", "tank");

        var unencountered = Bestiary.GetUnencountered(bestiaryData);
        var expected = EnemyTypes.Registry.Keys.Except(new[] { "raider", "tank" }).ToList();

        Assert.Equal(expected, unencountered);
    }

    [Fact]
    public void GetUnencountered_AllEncountered_ReturnsEmpty()
    {
        var bestiaryData = CreateBestiaryDataFromKinds(EnemyTypes.Registry.Keys.ToArray());

        var unencountered = Bestiary.GetUnencountered(bestiaryData);

        Assert.Empty(unencountered);
    }

    [Fact]
    public void FormatEntry_KnownKindWithEncounterData_IncludesStatsAndProgress()
    {
        var def = EnemyTypes.Get("raider")!;
        var encounterData = new Dictionary<string, object>
        {
            ["encounters"] = 7,
            ["defeats"] = 4,
        };

        var text = Bestiary.FormatEntry("raider", encounterData);

        Assert.StartsWith($"{def.Name} (T{(int)def.Tier} {def.Category})", text);
        Assert.Contains($"HP:{def.Hp}", text);
        Assert.Contains($"Armor:{def.Armor}", text);
        Assert.Contains($"Spd:{def.Speed}", text);
        Assert.Contains($"Dmg:{def.Damage}", text);
        Assert.Contains("Seen:7", text);
        Assert.Contains("Defeated:4", text);
    }

    [Fact]
    public void FormatEntry_KnownKindWithoutEncounterData_ReturnsNotYetEncountered()
    {
        var text = Bestiary.FormatEntry("raider", null);

        Assert.Contains("Raider", text);
        Assert.EndsWith(" | Not yet encountered", text);
    }

    [Fact]
    public void FormatEntry_UnknownKind_ReturnsUnknownLabel()
    {
        Assert.Equal("Unknown: mystery", Bestiary.FormatEntry("mystery", null));
    }

    private static Dictionary<string, object> CreateBestiaryDataFromKinds(params string[] kinds)
    {
        var data = new Dictionary<string, object>();
        foreach (var kind in kinds)
        {
            data[kind] = new Dictionary<string, object>
            {
                ["kind"] = kind,
                ["encounters"] = 1,
                ["defeats"] = 0,
                ["first_seen"] = DateTime.UtcNow.Ticks,
            };
        }

        return data;
    }
}
