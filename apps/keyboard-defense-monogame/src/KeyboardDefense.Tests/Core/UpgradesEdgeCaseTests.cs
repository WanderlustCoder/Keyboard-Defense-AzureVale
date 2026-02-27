using System;
using System.Collections.Generic;
using System.Reflection;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

[Collection("UpgradesSerial")]
public class UpgradesEdgeCaseTests
{
    private static readonly FieldInfo KingdomUpgradesField =
        typeof(Upgrades).GetField("_kingdomUpgrades", BindingFlags.NonPublic | BindingFlags.Static)
        ?? throw new InvalidOperationException("Could not access Upgrades kingdom cache.");

    private static readonly FieldInfo UnitUpgradesField =
        typeof(Upgrades).GetField("_unitUpgrades", BindingFlags.NonPublic | BindingFlags.Static)
        ?? throw new InvalidOperationException("Could not access Upgrades unit cache.");

    [Fact]
    public void Purchase_MaxLevelAttemptsAfterInitialPurchase_DoNotChargeAgain()
    {
        WithUpgrades(
            kingdom: new()
            {
                Upgrade("k-cap", 25)
            },
            unit: new(),
            action: () =>
            {
                var state = new GameState { Gold = 100 };

                var first = Upgrades.Purchase(state, "k-cap", "kingdom");
                var second = Upgrades.Purchase(state, "k-cap", "kingdom");
                var third = Upgrades.Purchase(state, "k-cap", "kingdom");

                Assert.True(IsOk(first));
                Assert.False(IsOk(second));
                Assert.False(IsOk(third));
                Assert.Equal("Already purchased.", second["error"]);
                Assert.Equal("Already purchased.", third["error"]);
                Assert.Equal(75, state.Gold);
                Assert.Single(state.PurchasedKingdomUpgrades);
                Assert.Equal("k-cap", state.PurchasedKingdomUpgrades[0]);
            });
    }

    [Fact]
    public void Purchase_PrerequisiteChain_CannotSkipIntermediateUpgrade()
    {
        WithUpgrades(
            kingdom: new()
            {
                Upgrade("k-a", 10),
                Upgrade("k-b", 20, requires: "k-a"),
                Upgrade("k-c", 40, requires: "k-b")
            },
            unit: new(),
            action: () =>
            {
                var state = new GameState { Gold = 200 };
                state.PurchasedKingdomUpgrades.Add("k-a");

                var result = Upgrades.CanPurchase(state, "k-c", "kingdom");

                Assert.False(IsOk(result));
                Assert.Equal("Requires k-b first.", result["error"]);
            });
    }

    [Fact]
    public void Purchase_PrerequisiteChain_AllowsSequentialUnlockAndPurchase()
    {
        WithUpgrades(
            kingdom: new()
            {
                Upgrade("k-a", 10),
                Upgrade("k-b", 20, requires: "k-a"),
                Upgrade("k-c", 40, requires: "k-b")
            },
            unit: new(),
            action: () =>
            {
                var state = new GameState { Gold = 70 };

                var first = Upgrades.Purchase(state, "k-a", "kingdom");
                var second = Upgrades.Purchase(state, "k-b", "kingdom");
                var third = Upgrades.Purchase(state, "k-c", "kingdom");

                Assert.True(IsOk(first));
                Assert.True(IsOk(second));
                Assert.True(IsOk(third));
                Assert.Equal(0, state.Gold);
                Assert.Equal(new[] { "k-a", "k-b", "k-c" }, state.PurchasedKingdomUpgrades);
            });
    }

    [Fact]
    public void Purchase_UpgradeCostScalingAcrossTiers_UsesConfiguredCostsWithoutHiddenMultiplier()
    {
        WithUpgrades(
            kingdom: new()
            {
                Upgrade("k-tier-1", 7),
                Upgrade("k-tier-2", 19),
                Upgrade("k-tier-3", 41)
            },
            unit: new(),
            action: () =>
            {
                var state = new GameState { Gold = 100 };

                Assert.True(IsOk(Upgrades.Purchase(state, "k-tier-1", "kingdom")));
                Assert.Equal(93, state.Gold);

                Assert.True(IsOk(Upgrades.Purchase(state, "k-tier-2", "kingdom")));
                Assert.Equal(74, state.Gold);

                Assert.True(IsOk(Upgrades.Purchase(state, "k-tier-3", "kingdom")));
                Assert.Equal(33, state.Gold);
            });
    }

    [Fact]
    public void CanPurchase_FailsWhenGoldIsOneBelowRequiredCost()
    {
        WithUpgrades(
            kingdom: new()
            {
                Upgrade("k-expensive", 50)
            },
            unit: new(),
            action: () =>
            {
                var state = new GameState { Gold = 49 };

                var result = Upgrades.CanPurchase(state, "k-expensive", "kingdom");

                Assert.False(IsOk(result));
                Assert.Equal("Need 50 gold (have 49).", result["error"]);
            });
    }

    [Fact]
    public void Purchase_FirstUpgradeCanBlockSecondUpgradeDueToRemainingGold()
    {
        WithUpgrades(
            kingdom: new()
            {
                Upgrade("k-cheap", 15),
                Upgrade("k-follow-up", 20)
            },
            unit: new(),
            action: () =>
            {
                var state = new GameState { Gold = 34 };

                var first = Upgrades.Purchase(state, "k-cheap", "kingdom");
                var second = Upgrades.Purchase(state, "k-follow-up", "kingdom");

                Assert.True(IsOk(first));
                Assert.False(IsOk(second));
                Assert.Equal("Need 20 gold (have 19).", second["error"]);
                Assert.Equal(19, state.Gold);
                Assert.Single(state.PurchasedKingdomUpgrades);
                Assert.Equal("k-cheap", state.PurchasedKingdomUpgrades[0]);
            });
    }

    [Fact]
    public void Purchase_SameUpgradeIdCanBeBoughtOncePerCategory()
    {
        WithUpgrades(
            kingdom: new()
            {
                Upgrade("shared-upgrade", 10)
            },
            unit: new()
            {
                Upgrade("shared-upgrade", 12)
            },
            action: () =>
            {
                var state = new GameState { Gold = 30 };

                var kingdomResult = Upgrades.Purchase(state, "shared-upgrade", "kingdom");
                var unitResult = Upgrades.Purchase(state, "shared-upgrade", "unit");

                Assert.True(IsOk(kingdomResult));
                Assert.True(IsOk(unitResult));
                Assert.Equal(8, state.Gold);
                Assert.Contains("shared-upgrade", state.PurchasedKingdomUpgrades);
                Assert.Contains("shared-upgrade", state.PurchasedUnitUpgrades);
            });
    }

    [Fact]
    public void CanPurchase_PrerequisiteMustExistInSameCategoryPurchasedList()
    {
        WithUpgrades(
            kingdom: new()
            {
                Upgrade("shared-base", 5)
            },
            unit: new()
            {
                Upgrade("shared-base", 5),
                Upgrade("unit-elite", 25, requires: "shared-base")
            },
            action: () =>
            {
                var state = new GameState { Gold = 100 };
                state.PurchasedKingdomUpgrades.Add("shared-base");

                var result = Upgrades.CanPurchase(state, "unit-elite", "unit");

                Assert.False(IsOk(result));
                Assert.Equal("Requires shared-base first.", result["error"]);
            });
    }

    [Fact]
    public void Purchase_NewGameStateScopeActsAsUpgradeResetForFreshRun()
    {
        WithUpgrades(
            kingdom: new()
            {
                Upgrade("k-run-scope", 20)
            },
            unit: new(),
            action: () =>
            {
                var firstRun = new GameState { Gold = 20 };
                var firstRunPurchase = Upgrades.Purchase(firstRun, "k-run-scope", "kingdom");
                var firstRunRetry = Upgrades.Purchase(firstRun, "k-run-scope", "kingdom");

                var secondRun = new GameState { Gold = 20 };
                var secondRunPurchase = Upgrades.Purchase(secondRun, "k-run-scope", "kingdom");

                Assert.True(IsOk(firstRunPurchase));
                Assert.False(IsOk(firstRunRetry));
                Assert.True(IsOk(secondRunPurchase));
                Assert.Single(firstRun.PurchasedKingdomUpgrades);
                Assert.Single(secondRun.PurchasedKingdomUpgrades);
                Assert.Equal(0, secondRun.Gold);
            });
    }

    private static Dictionary<string, object> Upgrade(string id, object goldCost, string? requires = null)
    {
        var upgrade = new Dictionary<string, object>
        {
            ["id"] = id,
            ["gold_cost"] = goldCost
        };

        if (!string.IsNullOrWhiteSpace(requires))
            upgrade["requires"] = requires;

        return upgrade;
    }

    private static bool IsOk(Dictionary<string, object> result)
        => Convert.ToBoolean(result.GetValueOrDefault("ok", false));

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
