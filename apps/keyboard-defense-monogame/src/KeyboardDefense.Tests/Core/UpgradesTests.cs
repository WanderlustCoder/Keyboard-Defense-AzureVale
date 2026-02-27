using System;
using System.Collections.Generic;
using System.Reflection;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

[CollectionDefinition("UpgradesSerial", DisableParallelization = true)]
public sealed class UpgradesSerialCollection
{
}

[Collection("UpgradesSerial")]
public class UpgradesTests
{
    private static readonly FieldInfo KingdomUpgradesField =
        typeof(Upgrades).GetField("_kingdomUpgrades", BindingFlags.NonPublic | BindingFlags.Static)
        ?? throw new InvalidOperationException("Could not access Upgrades kingdom cache.");

    private static readonly FieldInfo UnitUpgradesField =
        typeof(Upgrades).GetField("_unitUpgrades", BindingFlags.NonPublic | BindingFlags.Static)
        ?? throw new InvalidOperationException("Could not access Upgrades unit cache.");

    [Fact]
    public void GetKingdomUpgrade_ReturnsUpgradeById()
    {
        WithUpgrades(
            kingdom: new()
            {
                Upgrade("k-one", 10),
                Upgrade("k-two", 25)
            },
            unit: new(),
            action: () =>
            {
                var upgrade = Upgrades.GetKingdomUpgrade("k-two");

                Assert.NotNull(upgrade);
                Assert.Equal("k-two", upgrade!.GetValueOrDefault("id"));
            });
    }

    [Fact]
    public void GetUnitUpgrade_ReturnsNullWhenIdDoesNotExist()
    {
        WithUpgrades(
            kingdom: new(),
            unit: new()
            {
                Upgrade("u-one", 15)
            },
            action: () =>
            {
                var upgrade = Upgrades.GetUnitUpgrade("missing");
                Assert.Null(upgrade);
            });
    }

    [Fact]
    public void CanPurchase_ReturnsUnknownUpgradeForMissingId()
    {
        WithUpgrades(
            kingdom: new(),
            unit: new(),
            action: () =>
            {
                var state = new GameState { Gold = 100 };

                var result = Upgrades.CanPurchase(state, "unknown", "kingdom");

                Assert.False(Convert.ToBoolean(result["ok"]));
                Assert.Equal("Unknown upgrade.", result["error"]);
            });
    }

    [Fact]
    public void CanPurchase_FailsWhenAlreadyPurchased()
    {
        WithUpgrades(
            kingdom: new()
            {
                Upgrade("k-owned", 10)
            },
            unit: new(),
            action: () =>
            {
                var state = new GameState { Gold = 100 };
                state.PurchasedKingdomUpgrades.Add("k-owned");

                var result = Upgrades.CanPurchase(state, "k-owned", "kingdom");

                Assert.False(Convert.ToBoolean(result["ok"]));
                Assert.Equal("Already purchased.", result["error"]);
            });
    }

    [Fact]
    public void CanPurchase_FailsWhenGoldIsInsufficient()
    {
        WithUpgrades(
            kingdom: new()
            {
                Upgrade("k-costly", 40)
            },
            unit: new(),
            action: () =>
            {
                var state = new GameState { Gold = 39 };

                var result = Upgrades.CanPurchase(state, "k-costly", "kingdom");

                Assert.False(Convert.ToBoolean(result["ok"]));
                Assert.Equal("Need 40 gold (have 39).", result["error"]);
            });
    }

    [Fact]
    public void CanPurchase_FailsWhenPrerequisiteIsMissing()
    {
        WithUpgrades(
            kingdom: new()
            {
                Upgrade("k-tier-one", 10),
                Upgrade("k-tier-two", 30, requires: "k-tier-one")
            },
            unit: new(),
            action: () =>
            {
                var state = new GameState { Gold = 100 };

                var result = Upgrades.CanPurchase(state, "k-tier-two", "kingdom");

                Assert.False(Convert.ToBoolean(result["ok"]));
                Assert.Equal("Requires k-tier-one first.", result["error"]);
            });
    }

    [Fact]
    public void CanPurchase_SucceedsWhenGoldAndPrerequisiteRequirementsAreMet()
    {
        WithUpgrades(
            kingdom: new()
            {
                Upgrade("k-tier-one", 10),
                Upgrade("k-tier-two", 30, requires: "k-tier-one")
            },
            unit: new(),
            action: () =>
            {
                var state = new GameState { Gold = 30 };
                state.PurchasedKingdomUpgrades.Add("k-tier-one");

                var result = Upgrades.CanPurchase(state, "k-tier-two", "kingdom");

                Assert.True(Convert.ToBoolean(result["ok"]));
            });
    }

    [Fact]
    public void Purchase_DeductsGoldAddsKingdomUpgradeAndReturnsNamedMessage()
    {
        WithUpgrades(
            kingdom: new()
            {
                Upgrade("k-fortress", 30, name: "Fortress Upgrade")
            },
            unit: new(),
            action: () =>
            {
                var state = new GameState { Gold = 80 };

                var result = Upgrades.Purchase(state, "k-fortress", "kingdom");

                Assert.True(Convert.ToBoolean(result["ok"]));
                Assert.Equal(50, state.Gold);
                Assert.Contains("k-fortress", state.PurchasedKingdomUpgrades);
                Assert.Equal("Purchased Fortress Upgrade for 30 gold.", result["message"]);
            });
    }

    [Fact]
    public void Purchase_ParsesStringGoldCostAndFallsBackToIdWhenNameMissing()
    {
        WithUpgrades(
            kingdom: new(),
            unit: new()
            {
                Upgrade("u-rangers", "12")
            },
            action: () =>
            {
                var state = new GameState { Gold = 20 };

                var result = Upgrades.Purchase(state, "u-rangers", "unit");

                Assert.True(Convert.ToBoolean(result["ok"]));
                Assert.Equal(8, state.Gold);
                Assert.Contains("u-rangers", state.PurchasedUnitUpgrades);
                Assert.Equal("Purchased u-rangers for 12 gold.", result["message"]);
            });
    }

    [Fact]
    public void Purchase_AddsOnlyToUnitListWhenCategoryIsUnit()
    {
        WithUpgrades(
            kingdom: new(),
            unit: new()
            {
                Upgrade("u-guard", 9)
            },
            action: () =>
            {
                var state = new GameState { Gold = 15 };

                var result = Upgrades.Purchase(state, "u-guard", "unit");

                Assert.True(Convert.ToBoolean(result["ok"]));
                Assert.Contains("u-guard", state.PurchasedUnitUpgrades);
                Assert.DoesNotContain("u-guard", state.PurchasedKingdomUpgrades);
            });
    }

    [Fact]
    public void Purchase_RejectsSecondPurchaseAsSingleLevelMaxEnforcement()
    {
        WithUpgrades(
            kingdom: new()
            {
                Upgrade("k-single-level", 18)
            },
            unit: new(),
            action: () =>
            {
                var state = new GameState { Gold = 100 };

                var first = Upgrades.Purchase(state, "k-single-level", "kingdom");
                var second = Upgrades.Purchase(state, "k-single-level", "kingdom");

                Assert.True(Convert.ToBoolean(first["ok"]));
                Assert.False(Convert.ToBoolean(second["ok"]));
                Assert.Equal("Already purchased.", second["error"]);
                Assert.Equal(82, state.Gold);
                Assert.Single(state.PurchasedKingdomUpgrades);
            });
    }

    private static Dictionary<string, object> Upgrade(
        string id,
        object goldCost,
        string? requires = null,
        string? name = null)
    {
        var upgrade = new Dictionary<string, object>
        {
            ["id"] = id,
            ["gold_cost"] = goldCost
        };

        if (!string.IsNullOrWhiteSpace(requires))
            upgrade["requires"] = requires;

        if (!string.IsNullOrWhiteSpace(name))
            upgrade["name"] = name;

        return upgrade;
    }

    private static void WithUpgrades(
        List<Dictionary<string, object>> kingdom,
        List<Dictionary<string, object>> unit,
        Action action)
    {
        object? originalKingdom = KingdomUpgradesField.GetValue(null);
        object? originalUnit = UnitUpgradesField.GetValue(null);

        try
        {
            KingdomUpgradesField.SetValue(null, kingdom);
            UnitUpgradesField.SetValue(null, unit);
            action();
        }
        finally
        {
            KingdomUpgradesField.SetValue(null, originalKingdom);
            UnitUpgradesField.SetValue(null, originalUnit);
        }
    }
}
