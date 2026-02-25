using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Progression;

namespace KeyboardDefense.Tests.Core;

public class HeroTypesTests
{
    [Fact]
    public void HeroesRegistry_HasExpectedHeroIdsAndCount()
    {
        var expectedIds = new HashSet<string>(StringComparer.Ordinal)
        {
            "commander",
            "scholar",
            "ranger",
            "merchant",
            "warrior",
        };

        Assert.Equal(expectedIds.Count, HeroTypes.Heroes.Count);
        foreach (var id in expectedIds)
            Assert.Contains(id, HeroTypes.Heroes.Keys);
    }

    [Fact]
    public void GetHero_KnownHeroId_ReturnsExpectedDefinition()
    {
        var hero = HeroTypes.GetHero("scholar");

        Assert.NotNull(hero);
        Assert.Equal("Scholar", hero!.Name);
        Assert.Equal("Improves typing accuracy bonuses.", hero.Description);
        Assert.Equal(2, hero.Bonuses.Count);
        Assert.Equal(1.2, hero.Bonuses["accuracy_bonus"], 3);
        Assert.Equal(1.1, hero.Bonuses["xp_mult"], 3);
    }

    [Fact]
    public void IsValidHero_KnownAndUnknownIds_ReturnsExpectedResult()
    {
        Assert.True(HeroTypes.IsValidHero("commander"));
        Assert.True(HeroTypes.IsValidHero("warrior"));
        Assert.False(HeroTypes.IsValidHero("paladin"));
    }

    [Fact]
    public void GetHeroBonus_KnownHeroAndBonus_ReturnsStoredValue()
    {
        var bonus = HeroTypes.GetHeroBonus("merchant", "gold_mult", 0.0);

        Assert.Equal(1.2, bonus, 3);
    }

    [Fact]
    public void GetHeroBonus_InvalidHeroOrMissingBonus_ReturnsDefaultValue()
    {
        Assert.Equal(1.5, HeroTypes.GetHeroBonus("missing_hero", "gold_mult", 1.5), 3);
        Assert.Equal(2.5, HeroTypes.GetHeroBonus(null, "xp_mult", 2.5), 3);
        Assert.Equal(3.5, HeroTypes.GetHeroBonus("commander", "unknown_bonus", 3.5), 3);
    }

    [Fact]
    public void FormatHeroInfo_KnownHero_FormatsNameDescriptionAndBonusKeys()
    {
        var info = HeroTypes.FormatHeroInfo("warrior");

        Assert.StartsWith("Warrior\nDirect combat bonuses.\nBonuses: ", info, StringComparison.Ordinal);
        Assert.Contains("damage mult: x1.30", info, StringComparison.Ordinal);
        Assert.Contains("crit chance: +0.1", info, StringComparison.Ordinal);
        Assert.DoesNotContain("damage_mult", info, StringComparison.Ordinal);
        Assert.DoesNotContain("crit_chance", info, StringComparison.Ordinal);
    }

    [Fact]
    public void FormatHeroInfo_UnknownHero_ReturnsUnknownMessage()
    {
        Assert.Equal("Unknown hero.", HeroTypes.FormatHeroInfo("not_real"));
    }

    [Fact]
    public void HeroesRegistry_AllEntriesHaveNameDescriptionAndPositiveBonuses()
    {
        foreach (var (heroId, heroDef) in HeroTypes.Heroes)
        {
            Assert.False(string.IsNullOrWhiteSpace(heroId));
            Assert.False(string.IsNullOrWhiteSpace(heroDef.Name));
            Assert.False(string.IsNullOrWhiteSpace(heroDef.Description));
            Assert.NotEmpty(heroDef.Bonuses);

            foreach (var (bonusKey, bonusValue) in heroDef.Bonuses)
            {
                Assert.False(string.IsNullOrWhiteSpace(bonusKey));
                Assert.True(bonusValue > 0, $"Hero '{heroId}' bonus '{bonusKey}' should be positive.");
            }
        }
    }
}
