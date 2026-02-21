using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Combat;

namespace KeyboardDefense.Tests.Core;

public class AutoTowerTypesCoreTests
{
    [Fact]
    public void Towers_HasThirteenEntries()
    {
        Assert.Equal(13, AutoTowerTypes.Towers.Count);
    }

    [Fact]
    public void UpgradePaths_HasSevenEntries()
    {
        Assert.Equal(7, AutoTowerTypes.UpgradePaths.Count);
    }

    [Fact]
    public void TowerConstants_MatchExpectedValues()
    {
        var expected = new Dictionary<string, string>(StringComparer.Ordinal)
        {
            [nameof(AutoTowerTypes.Sentry)] = "auto_sentry",
            [nameof(AutoTowerTypes.Spark)] = "auto_spark",
            [nameof(AutoTowerTypes.Thorns)] = "auto_thorns",
            [nameof(AutoTowerTypes.Ballista)] = "auto_ballista",
            [nameof(AutoTowerTypes.Tesla)] = "auto_tesla",
            [nameof(AutoTowerTypes.Bramble)] = "auto_bramble",
            [nameof(AutoTowerTypes.Flame)] = "auto_flame",
            [nameof(AutoTowerTypes.Cannon)] = "auto_cannon",
            [nameof(AutoTowerTypes.Storm)] = "auto_storm",
            [nameof(AutoTowerTypes.Fortress)] = "auto_fortress",
            [nameof(AutoTowerTypes.Inferno)] = "auto_inferno",
            [nameof(AutoTowerTypes.Arcane)] = "auto_arcane",
            [nameof(AutoTowerTypes.Doom)] = "auto_doom",
        };

        var actual = new Dictionary<string, string>(StringComparer.Ordinal)
        {
            [nameof(AutoTowerTypes.Sentry)] = AutoTowerTypes.Sentry,
            [nameof(AutoTowerTypes.Spark)] = AutoTowerTypes.Spark,
            [nameof(AutoTowerTypes.Thorns)] = AutoTowerTypes.Thorns,
            [nameof(AutoTowerTypes.Ballista)] = AutoTowerTypes.Ballista,
            [nameof(AutoTowerTypes.Tesla)] = AutoTowerTypes.Tesla,
            [nameof(AutoTowerTypes.Bramble)] = AutoTowerTypes.Bramble,
            [nameof(AutoTowerTypes.Flame)] = AutoTowerTypes.Flame,
            [nameof(AutoTowerTypes.Cannon)] = AutoTowerTypes.Cannon,
            [nameof(AutoTowerTypes.Storm)] = AutoTowerTypes.Storm,
            [nameof(AutoTowerTypes.Fortress)] = AutoTowerTypes.Fortress,
            [nameof(AutoTowerTypes.Inferno)] = AutoTowerTypes.Inferno,
            [nameof(AutoTowerTypes.Arcane)] = AutoTowerTypes.Arcane,
            [nameof(AutoTowerTypes.Doom)] = AutoTowerTypes.Doom,
        };

        Assert.Equal(expected.Count, actual.Count);
        foreach (var (key, expectedValue) in expected)
        {
            Assert.True(actual.TryGetValue(key, out var actualValue));
            Assert.Equal(expectedValue, actualValue);
        }
    }

    [Fact]
    public void GetTower_KnownId_ReturnsExpectedDefinition()
    {
        var sentry = AutoTowerTypes.GetTower(AutoTowerTypes.Sentry);

        Assert.NotNull(sentry);
        Assert.Equal("Sentry Turret", sentry!.Name);
        Assert.Equal(AutoTowerTypes.AutoTier.Tier1, sentry.Tier);
        Assert.Equal(5, sentry.Damage);
        Assert.Equal(0.8, sentry.AttackSpeed, 5);
        Assert.Equal(3, sentry.Range);
        Assert.Equal(AutoTowerTypes.AutoTargetMode.Nearest, sentry.Targeting);
        Assert.Equal(AutoTowerTypes.AutoDamageType.Physical, sentry.DmgType);
        Assert.Equal(3, sentry.Cost.Count);
        Assert.Equal(80, sentry.Cost["gold"]);
        Assert.Equal(6, sentry.Cost["wood"]);
        Assert.Equal(10, sentry.Cost["stone"]);
        Assert.False(sentry.IsLegendary);
    }

    [Fact]
    public void GetTower_UnknownId_ReturnsNull()
    {
        Assert.Null(AutoTowerTypes.GetTower("auto_missing"));
    }

    [Fact]
    public void GetTowerName_KnownId_ReturnsDisplayName()
    {
        Assert.Equal("Sentry Turret", AutoTowerTypes.GetTowerName(AutoTowerTypes.Sentry));
    }

    [Fact]
    public void GetTowerName_UnknownId_ReturnsOriginalId()
    {
        Assert.Equal("auto_missing", AutoTowerTypes.GetTowerName("auto_missing"));
    }

    [Fact]
    public void IsValidTower_KnownId_ReturnsTrue()
    {
        Assert.True(AutoTowerTypes.IsValidTower(AutoTowerTypes.Tesla));
    }

    [Fact]
    public void IsValidTower_UnknownId_ReturnsFalse()
    {
        Assert.False(AutoTowerTypes.IsValidTower("auto_missing"));
    }

    [Fact]
    public void IsLegendary_ArcaneAndDoomAreLegendary_SentryIsNot()
    {
        Assert.True(AutoTowerTypes.IsLegendary(AutoTowerTypes.Arcane));
        Assert.True(AutoTowerTypes.IsLegendary(AutoTowerTypes.Doom));
        Assert.False(AutoTowerTypes.IsLegendary(AutoTowerTypes.Sentry));
    }

    [Fact]
    public void GetUpgradeOptions_Sentry_ReturnsBallista()
    {
        var options = AutoTowerTypes.GetUpgradeOptions(AutoTowerTypes.Sentry);

        Assert.Equal(new[] { AutoTowerTypes.Ballista }, options);
    }

    [Fact]
    public void GetUpgradeOptions_Arcane_ReturnsEmpty()
    {
        var options = AutoTowerTypes.GetUpgradeOptions(AutoTowerTypes.Arcane);

        Assert.NotNull(options);
        Assert.Empty(options);
    }

    [Fact]
    public void CanUpgradeTo_SentryToBallista_ReturnsTrue()
    {
        Assert.True(AutoTowerTypes.CanUpgradeTo(AutoTowerTypes.Sentry, AutoTowerTypes.Ballista));
    }

    [Fact]
    public void CanUpgradeTo_SentryToTesla_ReturnsFalse()
    {
        Assert.False(AutoTowerTypes.CanUpgradeTo(AutoTowerTypes.Sentry, AutoTowerTypes.Tesla));
    }

    [Fact]
    public void GetDps_Sentry_ReturnsExpectedValue()
    {
        Assert.Equal(4.0, AutoTowerTypes.GetDps(AutoTowerTypes.Sentry), 5);
    }

    [Fact]
    public void GetDps_Thorns_ReturnsZero()
    {
        Assert.Equal(0.0, AutoTowerTypes.GetDps(AutoTowerTypes.Thorns), 5);
    }

    [Fact]
    public void GetTowersByTier_Tier1_ReturnsExpectedEntries()
    {
        var tier1 = AutoTowerTypes.GetTowersByTier(AutoTowerTypes.AutoTier.Tier1);
        var expected = new HashSet<string> { AutoTowerTypes.Sentry, AutoTowerTypes.Spark, AutoTowerTypes.Thorns };

        Assert.Equal(3, tier1.Count);
        Assert.True(expected.SetEquals(tier1));
    }

    [Fact]
    public void GetTowersByTier_Tier4_ReturnsExpectedEntries()
    {
        var tier4 = AutoTowerTypes.GetTowersByTier(AutoTowerTypes.AutoTier.Tier4);
        var expected = new HashSet<string> { AutoTowerTypes.Arcane, AutoTowerTypes.Doom };

        Assert.Equal(2, tier4.Count);
        Assert.True(expected.SetEquals(tier4));
    }

    [Fact]
    public void GetTowersByTier_EachTier_HasExpectedCount()
    {
        var expectedCounts = new Dictionary<AutoTowerTypes.AutoTier, int>
        {
            [AutoTowerTypes.AutoTier.Tier1] = 3,
            [AutoTowerTypes.AutoTier.Tier2] = 4,
            [AutoTowerTypes.AutoTier.Tier3] = 4,
            [AutoTowerTypes.AutoTier.Tier4] = 2,
        };

        foreach (var (tier, count) in expectedCounts)
            Assert.Equal(count, AutoTowerTypes.GetTowersByTier(tier).Count);
    }

    [Fact]
    public void UpgradePaths_FromAndToIds_AreRegisteredTowerIds()
    {
        foreach (var (fromTower, upgradeTargets) in AutoTowerTypes.UpgradePaths)
        {
            Assert.True(AutoTowerTypes.IsValidTower(fromTower));
            Assert.NotEmpty(upgradeTargets);
            foreach (var target in upgradeTargets)
                Assert.True(AutoTowerTypes.IsValidTower(target));
        }
    }
}
