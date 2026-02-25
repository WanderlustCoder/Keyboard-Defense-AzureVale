using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Combat;

namespace KeyboardDefense.Tests.Core;

public class CombatTypesTests
{
    [Fact]
    public void TowerTypes_RegistryContainsExpectedTowerIds()
    {
        var expectedIds = new HashSet<string>(StringComparer.Ordinal)
        {
            TowerTypes.Arrow,
            TowerTypes.Magic,
            TowerTypes.Frost,
            TowerTypes.Cannon,
            TowerTypes.Multi,
            TowerTypes.Arcane,
            TowerTypes.Holy,
            TowerTypes.Siege,
            TowerTypes.PoisonTower,
            TowerTypes.Tesla,
            TowerTypes.Summoner,
            TowerTypes.Support,
            TowerTypes.Trap,
            TowerTypes.Wordsmith,
            TowerTypes.Shrine,
            TowerTypes.Purifier,
        };

        Assert.Equal(expectedIds.Count, TowerTypes.TowerStats.Count);
        Assert.True(expectedIds.SetEquals(TowerTypes.TowerStats.Keys));
    }

    [Fact]
    public void TowerTypes_GetTowerData_KnownType_ReturnsExpectedDefinition()
    {
        var def = TowerTypes.GetTowerData(TowerTypes.Purifier);

        Assert.NotNull(def);
        Assert.Equal("Purifier", def!.Name);
        Assert.Equal(TowerCategory.Legendary, def.Category);
        Assert.Equal(12, def.Damage);
        Assert.Equal(4, def.Range);
        Assert.Equal(2.0f, def.Cooldown, 5);
        Assert.Equal(DamageType.Pure, def.DmgType);
        Assert.Equal(TargetType.Aoe, def.Target);
        Assert.Equal(2, def.AoeRadius);
        Assert.True(def.IsLegendary);
    }

    [Fact]
    public void TowerTypes_UnknownType_ReturnsNullAndFallbackDefaults()
    {
        const string UnknownType = "unknown_tower";

        Assert.False(TowerTypes.IsValidTowerType(UnknownType));
        Assert.Null(TowerTypes.GetTowerData(UnknownType));
        Assert.Equal(UnknownType, TowerTypes.GetTowerName(UnknownType));
        Assert.False(TowerTypes.IsLegendary(UnknownType));
        Assert.Equal(TowerCategory.Basic, TowerTypes.GetCategory(UnknownType));
    }

    [Fact]
    public void TowerTypes_AllDefinitions_HaveValidStatsAndConsistentSpecialFields()
    {
        foreach (var (id, def) in TowerTypes.TowerStats)
        {
            Assert.False(string.IsNullOrWhiteSpace(id));
            Assert.False(string.IsNullOrWhiteSpace(def.Name));
            Assert.True(def.Range > 0, $"Tower '{id}' has invalid range: {def.Range}.");
            Assert.True(def.Cooldown >= 0f, $"Tower '{id}' has invalid cooldown: {def.Cooldown}.");
            Assert.True(def.Damage >= 0, $"Tower '{id}' has invalid damage: {def.Damage}.");
            Assert.True(def.TargetCount >= 1, $"Tower '{id}' has invalid target count: {def.TargetCount}.");
            Assert.True(def.AoeRadius >= 1, $"Tower '{id}' has invalid aoe radius: {def.AoeRadius}.");
            Assert.True(def.ChainCount >= 1, $"Tower '{id}' has invalid chain count: {def.ChainCount}.");
            Assert.True(Enum.IsDefined(def.Category), $"Tower '{id}' has unknown category: {def.Category}.");
            Assert.True(Enum.IsDefined(def.DmgType), $"Tower '{id}' has unknown damage type: {def.DmgType}.");
            Assert.True(Enum.IsDefined(def.Target), $"Tower '{id}' has unknown target type: {def.Target}.");

            if (def.Target != TargetType.None)
                Assert.True(def.Cooldown > 0f, $"Tower '{id}' attacks but has non-positive cooldown.");

            if (def.Target == TargetType.Multi)
                Assert.True(def.TargetCount > 1, $"Tower '{id}' is multi-target but target count is not > 1.");

            if (def.Target == TargetType.Chain)
                Assert.True(def.ChainCount > 1, $"Tower '{id}' is chain-target but chain count is not > 1.");

            if (def.IsLegendary)
                Assert.Equal(TowerCategory.Legendary, def.Category);
        }
    }

    [Fact]
    public void TowerTypes_FilterByCategory_ReturnsExpectedTypeSets()
    {
        var basic = TowerTypes.TowerStats.Where(kv => kv.Value.Category == TowerCategory.Basic).Select(kv => kv.Key);
        var advanced = TowerTypes.TowerStats.Where(kv => kv.Value.Category == TowerCategory.Advanced).Select(kv => kv.Key);
        var specialist = TowerTypes.TowerStats.Where(kv => kv.Value.Category == TowerCategory.Specialist).Select(kv => kv.Key);
        var legendary = TowerTypes.TowerStats.Where(kv => kv.Value.Category == TowerCategory.Legendary).Select(kv => kv.Key);

        Assert.True(new HashSet<string>(StringComparer.Ordinal)
        {
            TowerTypes.Arrow,
            TowerTypes.Magic,
            TowerTypes.Frost,
            TowerTypes.Cannon,
        }.SetEquals(basic));

        Assert.True(new HashSet<string>(StringComparer.Ordinal)
        {
            TowerTypes.Multi,
            TowerTypes.Arcane,
            TowerTypes.Holy,
            TowerTypes.Siege,
        }.SetEquals(advanced));

        Assert.True(new HashSet<string>(StringComparer.Ordinal)
        {
            TowerTypes.PoisonTower,
            TowerTypes.Tesla,
            TowerTypes.Summoner,
            TowerTypes.Support,
            TowerTypes.Trap,
        }.SetEquals(specialist));

        Assert.True(new HashSet<string>(StringComparer.Ordinal)
        {
            TowerTypes.Wordsmith,
            TowerTypes.Shrine,
            TowerTypes.Purifier,
        }.SetEquals(legendary));
    }

    [Fact]
    public void TowerTypes_GetCategory_MatchesRegistryDefinitionForEveryType()
    {
        foreach (var (id, def) in TowerTypes.TowerStats)
            Assert.Equal(def.Category, TowerTypes.GetCategory(id));
    }

    [Fact]
    public void EnemyTypes_RegistryContainsExpectedKinds()
    {
        var expectedKinds = new HashSet<string>(StringComparer.Ordinal)
        {
            "raider",
            "scout",
            "swarm",
            "armored",
            "berserker",
            "phantom",
            "healer",
            "tank",
            "champion",
            "elite",
            "warlord",
        };

        Assert.Equal(expectedKinds.Count, EnemyTypes.Registry.Count);
        Assert.True(expectedKinds.SetEquals(EnemyTypes.Registry.Keys));
    }

    [Fact]
    public void EnemyTypes_Get_KnownType_ReturnsExpectedDefinition()
    {
        var def = EnemyTypes.Get("tank");

        Assert.NotNull(def);
        Assert.Equal("Tank", def!.Name);
        Assert.Equal(EnemyTypes.Tier.Elite, def.Tier);
        Assert.Equal(EnemyTypes.Category.Armored, def.Category);
        Assert.Equal(80, def.Hp);
        Assert.Equal(10, def.Armor);
        Assert.Equal(20, def.Speed);
        Assert.Equal(3, def.Damage);
        Assert.Equal(12, def.Gold);
        Assert.Contains("fortified", def.Abilities);
        Assert.Contains("taunt", def.Abilities);
    }

    [Fact]
    public void EnemyTypes_UnknownType_ReturnsNullAndHasAbilityFalse()
    {
        Assert.Null(EnemyTypes.Get("unknown_enemy"));
        Assert.False(EnemyTypes.HasAbility("unknown_enemy", "fortified"));
    }

    [Fact]
    public void EnemyTypes_AllDefinitions_HaveValidStatsAndAbilityIds()
    {
        foreach (var (kind, def) in EnemyTypes.Registry)
        {
            Assert.False(string.IsNullOrWhiteSpace(kind));
            Assert.False(string.IsNullOrWhiteSpace(def.Name));
            Assert.True(def.Hp > 0, $"Enemy '{kind}' has invalid hp: {def.Hp}.");
            Assert.True(def.Armor >= 0, $"Enemy '{kind}' has invalid armor: {def.Armor}.");
            Assert.True(def.Speed > 0, $"Enemy '{kind}' has invalid speed: {def.Speed}.");
            Assert.True(def.Damage > 0, $"Enemy '{kind}' has invalid damage: {def.Damage}.");
            Assert.True(def.Gold > 0, $"Enemy '{kind}' has invalid gold: {def.Gold}.");
            Assert.True(Enum.IsDefined(def.Tier), $"Enemy '{kind}' has unknown tier: {def.Tier}.");
            Assert.True(Enum.IsDefined(def.Category), $"Enemy '{kind}' has unknown category: {def.Category}.");
            Assert.NotNull(def.Abilities);
            Assert.Equal(def.Abilities.Length, def.Abilities.Distinct(StringComparer.Ordinal).Count());

            foreach (var ability in def.Abilities)
            {
                Assert.False(string.IsNullOrWhiteSpace(ability), $"Enemy '{kind}' has empty ability id.");
                Assert.True(EnemyTypes.HasAbility(kind, ability), $"Enemy '{kind}' is missing ability '{ability}'.");
            }
        }
    }

    [Fact]
    public void EnemyTypes_FilteringByCategoryAndTier_PartitionsRegistryWithoutDuplicates()
    {
        var byCategory = Enum.GetValues<EnemyTypes.Category>()
            .SelectMany(EnemyTypes.GetByCategory)
            .ToList();

        var byTier = Enum.GetValues<EnemyTypes.Tier>()
            .SelectMany(EnemyTypes.GetByTier)
            .ToList();

        Assert.Equal(byCategory.Count, byCategory.Distinct(StringComparer.Ordinal).Count());
        Assert.Equal(byTier.Count, byTier.Distinct(StringComparer.Ordinal).Count());
        Assert.True(new HashSet<string>(EnemyTypes.Registry.Keys, StringComparer.Ordinal).SetEquals(byCategory));
        Assert.True(new HashSet<string>(EnemyTypes.Registry.Keys, StringComparer.Ordinal).SetEquals(byTier));

        foreach (var category in Enum.GetValues<EnemyTypes.Category>())
        {
            var kinds = EnemyTypes.GetByCategory(category);
            foreach (var kind in kinds)
                Assert.Equal(category, EnemyTypes.Get(kind)!.Category);
        }
    }
}
