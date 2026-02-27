using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Combat;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Tests for EnemyTypes — registry completeness, tier/category queries,
/// ability checks, and EnemyTypeDef record validation.
/// </summary>
public class EnemyTypesExtendedTests
{
    // =========================================================================
    // Registry — completeness
    // =========================================================================

    [Fact]
    public void Registry_HasElevenEntries()
    {
        Assert.Equal(11, EnemyTypes.Registry.Count);
    }

    [Theory]
    [InlineData("raider")]
    [InlineData("scout")]
    [InlineData("swarm")]
    [InlineData("armored")]
    [InlineData("berserker")]
    [InlineData("phantom")]
    [InlineData("healer")]
    [InlineData("tank")]
    [InlineData("champion")]
    [InlineData("elite")]
    [InlineData("warlord")]
    public void Registry_ContainsExpectedKind(string kind)
    {
        Assert.True(EnemyTypes.Registry.ContainsKey(kind));
    }

    // =========================================================================
    // Registry — stat validation
    // =========================================================================

    [Theory]
    [InlineData("raider", "Raider", EnemyTypes.Tier.Minion, EnemyTypes.Category.Basic, 20, 0, 40, 1, 5)]
    [InlineData("scout", "Scout", EnemyTypes.Tier.Minion, EnemyTypes.Category.Fast, 12, 0, 70, 1, 3)]
    [InlineData("swarm", "Swarm", EnemyTypes.Tier.Minion, EnemyTypes.Category.Basic, 8, 0, 50, 1, 2)]
    [InlineData("armored", "Armored", EnemyTypes.Tier.Standard, EnemyTypes.Category.Armored, 40, 5, 30, 2, 8)]
    [InlineData("berserker", "Berserker", EnemyTypes.Tier.Standard, EnemyTypes.Category.Basic, 30, 0, 55, 3, 7)]
    [InlineData("phantom", "Phantom", EnemyTypes.Tier.Standard, EnemyTypes.Category.Magic, 25, 0, 45, 2, 6)]
    [InlineData("healer", "Healer", EnemyTypes.Tier.Standard, EnemyTypes.Category.Support, 20, 0, 35, 1, 6)]
    [InlineData("tank", "Tank", EnemyTypes.Tier.Elite, EnemyTypes.Category.Armored, 80, 10, 20, 3, 12)]
    [InlineData("champion", "Champion", EnemyTypes.Tier.Elite, EnemyTypes.Category.Basic, 60, 5, 40, 4, 15)]
    [InlineData("elite", "Elite", EnemyTypes.Tier.Elite, EnemyTypes.Category.Magic, 50, 3, 50, 3, 12)]
    [InlineData("warlord", "Warlord", EnemyTypes.Tier.Boss, EnemyTypes.Category.Siege, 200, 15, 25, 5, 30)]
    public void Registry_AllStats_MatchExpected(
        string kind, string name, EnemyTypes.Tier tier, EnemyTypes.Category category,
        int hp, int armor, int speed, int damage, int gold)
    {
        var def = EnemyTypes.Registry[kind];
        Assert.Equal(name, def.Name);
        Assert.Equal(tier, def.Tier);
        Assert.Equal(category, def.Category);
        Assert.Equal(hp, def.Hp);
        Assert.Equal(armor, def.Armor);
        Assert.Equal(speed, def.Speed);
        Assert.Equal(damage, def.Damage);
        Assert.Equal(gold, def.Gold);
    }

    [Fact]
    public void Registry_AllEntries_HavePositiveHp()
    {
        foreach (var (kind, def) in EnemyTypes.Registry)
        {
            Assert.True(def.Hp > 0, $"'{kind}' has non-positive HP: {def.Hp}");
        }
    }

    [Fact]
    public void Registry_AllEntries_HaveNonNegativeArmor()
    {
        foreach (var (kind, def) in EnemyTypes.Registry)
        {
            Assert.True(def.Armor >= 0, $"'{kind}' has negative armor: {def.Armor}");
        }
    }

    [Fact]
    public void Registry_AllEntries_HavePositiveGold()
    {
        foreach (var (kind, def) in EnemyTypes.Registry)
        {
            Assert.True(def.Gold > 0, $"'{kind}' has non-positive gold: {def.Gold}");
        }
    }

    [Fact]
    public void Registry_AllEntries_HaveNonNullAbilities()
    {
        foreach (var (kind, def) in EnemyTypes.Registry)
        {
            Assert.NotNull(def.Abilities);
        }
    }

    // =========================================================================
    // Get — lookup
    // =========================================================================

    [Fact]
    public void Get_KnownKind_ReturnsDef()
    {
        var def = EnemyTypes.Get("raider");
        Assert.NotNull(def);
        Assert.Equal("Raider", def!.Name);
    }

    [Fact]
    public void Get_UnknownKind_ReturnsNull()
    {
        Assert.Null(EnemyTypes.Get("nonexistent"));
    }

    [Fact]
    public void Get_EmptyString_ReturnsNull()
    {
        Assert.Null(EnemyTypes.Get(""));
    }

    // =========================================================================
    // GetByTier — tier queries
    // =========================================================================

    [Fact]
    public void GetByTier_Minion_ReturnsThreeEntries()
    {
        var minions = EnemyTypes.GetByTier(EnemyTypes.Tier.Minion);
        Assert.Equal(3, minions.Count);
        Assert.Contains("raider", minions);
        Assert.Contains("scout", minions);
        Assert.Contains("swarm", minions);
    }

    [Fact]
    public void GetByTier_Standard_ReturnsFourEntries()
    {
        var standard = EnemyTypes.GetByTier(EnemyTypes.Tier.Standard);
        Assert.Equal(4, standard.Count);
        Assert.Contains("armored", standard);
        Assert.Contains("berserker", standard);
        Assert.Contains("phantom", standard);
        Assert.Contains("healer", standard);
    }

    [Fact]
    public void GetByTier_Elite_ReturnsThreeEntries()
    {
        var elites = EnemyTypes.GetByTier(EnemyTypes.Tier.Elite);
        Assert.Equal(3, elites.Count);
        Assert.Contains("tank", elites);
        Assert.Contains("champion", elites);
        Assert.Contains("elite", elites);
    }

    [Fact]
    public void GetByTier_Boss_ReturnsOneEntry()
    {
        var bosses = EnemyTypes.GetByTier(EnemyTypes.Tier.Boss);
        Assert.Single(bosses);
        Assert.Contains("warlord", bosses);
    }

    [Fact]
    public void GetByTier_AllTiersCoverAllEntries()
    {
        var all = new List<string>();
        foreach (EnemyTypes.Tier tier in Enum.GetValues<EnemyTypes.Tier>())
            all.AddRange(EnemyTypes.GetByTier(tier));

        Assert.Equal(EnemyTypes.Registry.Count, all.Count);
    }

    // =========================================================================
    // GetByCategory — category queries
    // =========================================================================

    [Fact]
    public void GetByCategory_Basic_ReturnsExpected()
    {
        var basic = EnemyTypes.GetByCategory(EnemyTypes.Category.Basic);
        Assert.Contains("raider", basic);
        Assert.Contains("swarm", basic);
        Assert.Contains("berserker", basic);
        Assert.Contains("champion", basic);
        Assert.Equal(4, basic.Count);
    }

    [Fact]
    public void GetByCategory_Fast_ReturnsOnlyScout()
    {
        var fast = EnemyTypes.GetByCategory(EnemyTypes.Category.Fast);
        Assert.Single(fast);
        Assert.Contains("scout", fast);
    }

    [Fact]
    public void GetByCategory_Armored_ReturnsTwoEntries()
    {
        var armored = EnemyTypes.GetByCategory(EnemyTypes.Category.Armored);
        Assert.Equal(2, armored.Count);
        Assert.Contains("armored", armored);
        Assert.Contains("tank", armored);
    }

    [Fact]
    public void GetByCategory_Magic_ReturnsTwoEntries()
    {
        var magic = EnemyTypes.GetByCategory(EnemyTypes.Category.Magic);
        Assert.Equal(2, magic.Count);
        Assert.Contains("phantom", magic);
        Assert.Contains("elite", magic);
    }

    [Fact]
    public void GetByCategory_Support_ReturnsOnlyHealer()
    {
        var support = EnemyTypes.GetByCategory(EnemyTypes.Category.Support);
        Assert.Single(support);
        Assert.Contains("healer", support);
    }

    [Fact]
    public void GetByCategory_Siege_ReturnsOnlyWarlord()
    {
        var siege = EnemyTypes.GetByCategory(EnemyTypes.Category.Siege);
        Assert.Single(siege);
        Assert.Contains("warlord", siege);
    }

    [Fact]
    public void GetByCategory_AllCategoriesCoverAllEntries()
    {
        var all = new List<string>();
        foreach (EnemyTypes.Category cat in Enum.GetValues<EnemyTypes.Category>())
            all.AddRange(EnemyTypes.GetByCategory(cat));

        Assert.Equal(EnemyTypes.Registry.Count, all.Count);
    }

    // =========================================================================
    // HasAbility — ability checks
    // =========================================================================

    [Theory]
    [InlineData("armored", "fortified", true)]
    [InlineData("berserker", "enrage", true)]
    [InlineData("phantom", "ghostly", true)]
    [InlineData("healer", "heal_aura", true)]
    [InlineData("tank", "fortified", true)]
    [InlineData("tank", "taunt", true)]
    [InlineData("champion", "enrage", true)]
    [InlineData("champion", "rally", true)]
    [InlineData("elite", "ghostly", true)]
    [InlineData("elite", "spell_shield", true)]
    [InlineData("warlord", "fortified", true)]
    [InlineData("warlord", "rally", true)]
    [InlineData("warlord", "enrage", true)]
    public void HasAbility_KnownAbilities_ReturnsExpected(string kind, string ability, bool expected)
    {
        Assert.Equal(expected, EnemyTypes.HasAbility(kind, ability));
    }

    [Fact]
    public void HasAbility_MinionsHaveNoAbilities()
    {
        foreach (var kind in EnemyTypes.GetByTier(EnemyTypes.Tier.Minion))
        {
            var def = EnemyTypes.Get(kind);
            Assert.NotNull(def);
            Assert.Empty(def!.Abilities);
        }
    }

    [Fact]
    public void HasAbility_UnknownKind_ReturnsFalse()
    {
        Assert.False(EnemyTypes.HasAbility("nonexistent", "fortified"));
    }

    [Fact]
    public void HasAbility_UnknownAbility_ReturnsFalse()
    {
        Assert.False(EnemyTypes.HasAbility("tank", "flying"));
    }

    // =========================================================================
    // Tier/Category enum values
    // =========================================================================

    [Theory]
    [InlineData(EnemyTypes.Tier.Minion, 1)]
    [InlineData(EnemyTypes.Tier.Standard, 2)]
    [InlineData(EnemyTypes.Tier.Elite, 3)]
    [InlineData(EnemyTypes.Tier.Boss, 4)]
    public void Tier_HasExpectedIntValue(EnemyTypes.Tier tier, int expected)
    {
        Assert.Equal(expected, (int)tier);
    }

    // =========================================================================
    // EnemyTypeDef record
    // =========================================================================

    [Fact]
    public void EnemyTypeDef_IsRecord_WithExpectedFields()
    {
        var def = new EnemyTypeDef("Test", EnemyTypes.Tier.Elite, EnemyTypes.Category.Magic,
            100, 5, 50, 3, 10, new[] { "fly", "heal" });

        Assert.Equal("Test", def.Name);
        Assert.Equal(EnemyTypes.Tier.Elite, def.Tier);
        Assert.Equal(EnemyTypes.Category.Magic, def.Category);
        Assert.Equal(100, def.Hp);
        Assert.Equal(5, def.Armor);
        Assert.Equal(50, def.Speed);
        Assert.Equal(3, def.Damage);
        Assert.Equal(10, def.Gold);
        Assert.Equal(new[] { "fly", "heal" }, def.Abilities);
    }

    // =========================================================================
    // Tier progression — higher tier enemies are stronger
    // =========================================================================

    [Fact]
    public void HigherTier_HasHigherAverageHp()
    {
        double AvgHp(EnemyTypes.Tier tier) => EnemyTypes.GetByTier(tier)
            .Select(k => EnemyTypes.Get(k)!.Hp)
            .Average();

        Assert.True(AvgHp(EnemyTypes.Tier.Minion) < AvgHp(EnemyTypes.Tier.Standard));
        Assert.True(AvgHp(EnemyTypes.Tier.Standard) < AvgHp(EnemyTypes.Tier.Elite));
        Assert.True(AvgHp(EnemyTypes.Tier.Elite) < AvgHp(EnemyTypes.Tier.Boss));
    }

    [Fact]
    public void HigherTier_HasHigherAverageGold()
    {
        double AvgGold(EnemyTypes.Tier tier) => EnemyTypes.GetByTier(tier)
            .Select(k => EnemyTypes.Get(k)!.Gold)
            .Average();

        Assert.True(AvgGold(EnemyTypes.Tier.Minion) < AvgGold(EnemyTypes.Tier.Standard));
        Assert.True(AvgGold(EnemyTypes.Tier.Standard) < AvgGold(EnemyTypes.Tier.Elite));
        Assert.True(AvgGold(EnemyTypes.Tier.Elite) < AvgGold(EnemyTypes.Tier.Boss));
    }
}
