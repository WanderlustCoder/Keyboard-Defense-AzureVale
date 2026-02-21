using System;
using System.Collections.Generic;
using KeyboardDefense.Core;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class AffixesCoreTests
{
    [Fact]
    public void Registry_HasEightEntries()
    {
        Assert.Equal(8, Affixes.Registry.Count);
    }

    [Fact]
    public void Registry_HasExpectedTierBonusesAndSpecialsForAllAffixes()
    {
        var expected = new Dictionary<string, AffixDef>
        {
            ["swift"] = new("Swift", 1, 0, 0, 20, 0, null),
            ["armored"] = new("Armored", 1, 0, 5, 0, 0, null),
            ["resilient"] = new("Resilient", 1, 20, 0, 0, 0, null),
            ["shielded"] = new("Shielded", 2, 0, 0, 0, 0, "first_hit_immune"),
            ["splitting"] = new("Splitting", 2, -10, 0, 0, 0, "split_on_death"),
            ["regenerating"] = new("Regenerating", 2, 0, 0, 0, 0, "regen"),
            ["enraged"] = new("Enraged", 3, 0, 0, 10, 50, null),
            ["vampiric"] = new("Vampiric", 3, 0, 0, 0, 0, "lifesteal"),
        };

        foreach (var (id, expectedDef) in expected)
        {
            Assert.True(Affixes.Registry.TryGetValue(id, out var actual), $"Missing affix id '{id}' in registry.");
            Assert.Equal(expectedDef.Name, actual!.Name);
            Assert.Equal(expectedDef.Tier, actual.Tier);
            Assert.Equal(expectedDef.HpBonus, actual.HpBonus);
            Assert.Equal(expectedDef.ArmorBonus, actual.ArmorBonus);
            Assert.Equal(expectedDef.SpeedBonus, actual.SpeedBonus);
            Assert.Equal(expectedDef.DamageBonus, actual.DamageBonus);
            Assert.Equal(expectedDef.Special, actual.Special);
        }
    }

    [Fact]
    public void ApplyAffix_Swift_IncreasesSpeedByTwenty()
    {
        var enemy = CreateEnemy(speed: 1);

        Affixes.ApplyAffix(enemy, "swift");

        Assert.Equal("swift", enemy["affix"]);
        Assert.Equal(21, enemy["speed"]);
        Assert.Equal(1, enemy["damage"]);
    }

    [Fact]
    public void ApplyAffix_Armored_IncreasesArmorByFive()
    {
        var enemy = CreateEnemy(armor: 2);

        Affixes.ApplyAffix(enemy, "armored");

        Assert.Equal("armored", enemy["affix"]);
        Assert.Equal(7, enemy["armor"]);
        Assert.Equal(1, enemy["speed"]);
    }

    [Fact]
    public void ApplyAffix_Resilient_IncreasesHpAndMaxHpByTwentyPercent()
    {
        var enemy = CreateEnemy(hp: 125, maxHp: 200);

        Affixes.ApplyAffix(enemy, "resilient");

        Assert.Equal("resilient", enemy["affix"]);
        Assert.Equal(150, enemy["hp"]);
        Assert.Equal(225, enemy["max_hp"]);
    }

    [Fact]
    public void ApplyAffix_Shielded_SetsFirstHitImmuneFlag()
    {
        var enemy = CreateEnemy();

        Affixes.ApplyAffix(enemy, "shielded");

        Assert.Equal("shielded", enemy["affix"]);
        Assert.True(enemy.ContainsKey("affix_first_hit_immune"));
        Assert.Equal(true, enemy["affix_first_hit_immune"]);
    }

    [Fact]
    public void ApplyAffix_Splitting_DecreasesHpAndMaxHpByTenPercentAndSetsSplitFlag()
    {
        var enemy = CreateEnemy(hp: 100, maxHp: 90);

        Affixes.ApplyAffix(enemy, "splitting");

        Assert.Equal("splitting", enemy["affix"]);
        Assert.Equal(90, enemy["hp"]);
        Assert.Equal(80, enemy["max_hp"]);
        Assert.True(enemy.ContainsKey("affix_split_on_death"));
        Assert.Equal(true, enemy["affix_split_on_death"]);
    }

    [Fact]
    public void ApplyAffix_Enraged_IncreasesSpeedAndDamage()
    {
        var enemy = CreateEnemy(speed: 3, damage: 8);

        Affixes.ApplyAffix(enemy, "enraged");

        Assert.Equal("enraged", enemy["affix"]);
        Assert.Equal(13, enemy["speed"]);
        Assert.Equal(58, enemy["damage"]);
    }

    [Fact]
    public void ApplyAffix_SetsAffixIdOnEnemy()
    {
        var enemy = CreateEnemy();

        Affixes.ApplyAffix(enemy, "vampiric");

        Assert.Equal("vampiric", enemy["affix"]);
    }

    [Fact]
    public void ApplyAffix_UnknownId_DoesNotChangeEnemy()
    {
        var enemy = CreateEnemy(hp: 100, maxHp: 100, armor: 5, speed: 4, damage: 9, affix: "");
        var snapshot = new Dictionary<string, object>(enemy);

        Affixes.ApplyAffix(enemy, "not_real");

        Assert.Equal(snapshot.Count, enemy.Count);
        foreach (var (key, value) in snapshot)
        {
            Assert.True(enemy.ContainsKey(key));
            Assert.Equal(value, enemy[key]);
        }
    }

    [Fact]
    public void GetAvailableAffixes_DayOne_ReturnsOnlyTierOneAffixes()
    {
        var available = Affixes.GetAvailableAffixes(1);

        var expected = new HashSet<string> { "swift", "armored", "resilient" };
        Assert.True(new HashSet<string>(available).SetEquals(expected));
    }

    [Fact]
    public void GetAvailableAffixes_DayFour_ReturnsTierOneAndTierTwoAffixes()
    {
        var available = Affixes.GetAvailableAffixes(4);

        var expected = new HashSet<string> { "swift", "armored", "resilient", "shielded", "splitting", "regenerating" };
        Assert.True(new HashSet<string>(available).SetEquals(expected));
    }

    [Fact]
    public void GetAvailableAffixes_DaySeven_ReturnsAllAffixes()
    {
        var available = Affixes.GetAvailableAffixes(7);

        var expected = new HashSet<string> { "swift", "armored", "resilient", "shielded", "splitting", "regenerating", "enraged", "vampiric" };
        Assert.True(new HashSet<string>(available).SetEquals(expected));
    }

    [Fact]
    public void GetAvailableAffixes_DayTen_ReturnsAllAffixes()
    {
        var available = Affixes.GetAvailableAffixes(10);

        var expected = new HashSet<string> { "swift", "armored", "resilient", "shielded", "splitting", "regenerating", "enraged", "vampiric" };
        Assert.True(new HashSet<string>(available).SetEquals(expected));
    }

    [Fact]
    public void RollAffix_ChanceRollAboveThirty_ReturnsNull()
    {
        long rngState = FindRngStateForFirstRoll(roll => roll > 30);
        var state = new GameState { RngState = rngState };

        var result = Affixes.RollAffix(state, 7);

        Assert.Null(result);
    }

    [Fact]
    public void RollAffix_ChanceRollThirtyOrLower_ReturnsAvailableAffix()
    {
        long rngState = FindRngStateForFirstRoll(roll => roll <= 30);
        var state = new GameState { RngState = rngState };
        var available = Affixes.GetAvailableAffixes(7);

        var result = Affixes.RollAffix(state, 7);

        Assert.NotNull(result);
        Assert.Contains(result!, available);
    }

    [Fact]
    public void RollAffix_DayOne_ReturnsOnlyTierOneAffixWhenItRolls()
    {
        long rngState = FindRngStateForFirstRoll(roll => roll <= 30);
        var state = new GameState { RngState = rngState };
        var tierOne = new HashSet<string> { "swift", "armored", "resilient" };

        var result = Affixes.RollAffix(state, 1);

        Assert.NotNull(result);
        Assert.Contains(result!, tierOne);
    }

    [Fact]
    public void RollAffix_DayFour_DoesNotReturnTierThreeAffixWhenItRolls()
    {
        long rngState = FindRngStateForFirstRoll(roll => roll <= 30);
        var state = new GameState { RngState = rngState };
        var tierThree = new HashSet<string> { "enraged", "vampiric" };

        var result = Affixes.RollAffix(state, 4);

        Assert.NotNull(result);
        Assert.DoesNotContain(result!, tierThree);
    }

    private static Dictionary<string, object> CreateEnemy(
        int hp = 100,
        int maxHp = 100,
        int armor = 0,
        int speed = 1,
        int damage = 1,
        string affix = "")
    {
        return new Dictionary<string, object>
        {
            ["hp"] = hp,
            ["max_hp"] = maxHp,
            ["armor"] = armor,
            ["speed"] = speed,
            ["damage"] = damage,
            ["affix"] = affix,
        };
    }

    private static long FindRngStateForFirstRoll(Func<int, bool> predicate)
    {
        var probe = new GameState();
        for (long candidate = 0; candidate < 200_000; candidate++)
        {
            probe.RngState = candidate;
            int roll = SimRng.RollRange(probe, 1, 100);
            if (predicate(roll))
                return candidate;
        }

        throw new InvalidOperationException("Unable to find an RNG state matching the requested first roll predicate.");
    }
}
