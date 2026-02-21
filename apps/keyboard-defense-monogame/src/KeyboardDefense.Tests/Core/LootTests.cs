using System;
using System.Collections.Generic;
using KeyboardDefense.Core;
using KeyboardDefense.Core.Economy;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class LootTests
{
    private static readonly Dictionary<int, long> DropRollStateCache = new();

    [Fact]
    public void GetQualityTier_AtZero_ReturnsPoor()
    {
        Assert.Equal("poor", Loot.GetQualityTier(0.0));
    }

    [Fact]
    public void GetQualityTier_AtPointFortyNine_ReturnsPoor()
    {
        Assert.Equal("poor", Loot.GetQualityTier(0.49));
    }

    [Fact]
    public void GetQualityTier_AtPointFifty_ReturnsNormal()
    {
        Assert.Equal("normal", Loot.GetQualityTier(0.5));
    }

    [Fact]
    public void GetQualityTier_AtPointSeventyFour_ReturnsNormal()
    {
        Assert.Equal("normal", Loot.GetQualityTier(0.74));
    }

    [Fact]
    public void GetQualityTier_AtPointSeventyFive_ReturnsGood()
    {
        Assert.Equal("good", Loot.GetQualityTier(0.75));
    }

    [Fact]
    public void GetQualityTier_AtPointEightyNine_ReturnsGood()
    {
        Assert.Equal("good", Loot.GetQualityTier(0.89));
    }

    [Fact]
    public void GetQualityTier_AtPointNinety_ReturnsGreat()
    {
        Assert.Equal("great", Loot.GetQualityTier(0.9));
    }

    [Fact]
    public void GetQualityTier_AtPointNinetyNine_ReturnsGreat()
    {
        Assert.Equal("great", Loot.GetQualityTier(0.99));
    }

    [Fact]
    public void GetQualityTier_AtOne_ReturnsPerfect()
    {
        Assert.Equal("perfect", Loot.GetQualityTier(1.0));
    }

    [Fact]
    public void GetQualityMultiplier_KnownQualities_ReturnExpectedValues()
    {
        Assert.Equal(2.0, Loot.GetQualityMultiplier("perfect"));
        Assert.Equal(1.5, Loot.GetQualityMultiplier("great"));
        Assert.Equal(1.2, Loot.GetQualityMultiplier("good"));
        Assert.Equal(1.0, Loot.GetQualityMultiplier("normal"));
        Assert.Equal(0.5, Loot.GetQualityMultiplier("poor"));
    }

    [Fact]
    public void GetQualityMultiplier_UnknownQuality_ReturnsDefault()
    {
        Assert.Equal(1.0, Loot.GetQualityMultiplier("legendary"));
    }

    [Fact]
    public void GenerateLoot_PerfectQuality_UsesExpectedGoldForKnownEnemyKinds()
    {
        var expectedBaseGold = new Dictionary<string, int>
        {
            ["scout"] = 3,
            ["raider"] = 5,
            ["armored"] = 8,
            ["berserker"] = 7,
            ["phantom"] = 6,
            ["healer"] = 6,
            ["tank"] = 12,
            ["champion"] = 15,
            ["elite"] = 12,
            ["warlord"] = 30,
        };

        foreach (var (enemyKind, baseGold) in expectedBaseGold)
        {
            var state = DefaultState.Create();
            var loot = Loot.GenerateLoot(state, enemyKind, 1.0);

            Assert.Equal("perfect", Assert.IsType<string>(loot["quality"]));
            Assert.Equal(2.0, Convert.ToDouble(loot["multiplier"]));
            Assert.Equal(baseGold * 2, Convert.ToInt32(loot["gold"]));
        }
    }

    [Fact]
    public void GenerateLoot_UnknownEnemyKind_UsesDefaultGoldAndGreatMultiplier()
    {
        var state = DefaultState.Create();

        var loot = Loot.GenerateLoot(state, "unknown_kind", 0.9);

        Assert.Equal("great", Assert.IsType<string>(loot["quality"]));
        Assert.Equal(1.5, Convert.ToDouble(loot["multiplier"]));
        Assert.Equal(7, Convert.ToInt32(loot["gold"])); // floor(5 * 1.5)
    }

    [Fact]
    public void GenerateLoot_PoorQuality_AppliesFloorAndMinimumGold()
    {
        var state = DefaultState.Create();

        var loot = Loot.GenerateLoot(state, "scout", 0.0);

        Assert.Equal("poor", Assert.IsType<string>(loot["quality"]));
        Assert.Equal(0.5, Convert.ToDouble(loot["multiplier"]));
        Assert.Equal(1, Convert.ToInt32(loot["gold"])); // max(1, floor(3 * 0.5))
    }

    [Fact]
    public void GenerateLoot_PerfectQuality_UsesFiftyPercentDropChanceAndArmoredPool()
    {
        var dropState = DefaultState.Create();
        dropState.RngState = GetRngStateForDropRoll(50);
        var droppedLoot = Loot.GenerateLoot(dropState, "armored", 1.0);

        Assert.True(droppedLoot.ContainsKey("material"));
        var droppedMaterial = Assert.IsType<string>(droppedLoot["material"]);
        Assert.Contains(droppedMaterial, new[] { "iron_ore", "coal" });
        Assert.Equal(1, Convert.ToInt32(droppedLoot["material_count"]));

        var noDropState = DefaultState.Create();
        noDropState.RngState = GetRngStateForDropRoll(51);
        var noDropLoot = Loot.GenerateLoot(noDropState, "armored", 1.0);

        Assert.False(noDropLoot.ContainsKey("material"));
        Assert.False(noDropLoot.ContainsKey("material_count"));
    }

    [Fact]
    public void GenerateLoot_GreatQuality_UsesThirtyPercentDropChanceAndPhantomPool()
    {
        var dropState = DefaultState.Create();
        dropState.RngState = GetRngStateForDropRoll(30);
        var droppedLoot = Loot.GenerateLoot(dropState, "phantom", 0.9);

        Assert.True(droppedLoot.ContainsKey("material"));
        var droppedMaterial = Assert.IsType<string>(droppedLoot["material"]);
        Assert.Contains(droppedMaterial, new[] { "crystal", "fire_essence" });
        Assert.Equal(1, Convert.ToInt32(droppedLoot["material_count"]));

        var noDropState = DefaultState.Create();
        noDropState.RngState = GetRngStateForDropRoll(31);
        var noDropLoot = Loot.GenerateLoot(noDropState, "phantom", 0.9);

        Assert.False(noDropLoot.ContainsKey("material"));
        Assert.False(noDropLoot.ContainsKey("material_count"));
    }

    [Fact]
    public void GenerateLoot_NormalQuality_UsesFifteenPercentDropChanceAndHealerPool()
    {
        var dropState = DefaultState.Create();
        dropState.RngState = GetRngStateForDropRoll(15);
        var droppedLoot = Loot.GenerateLoot(dropState, "healer", 0.5);

        Assert.True(droppedLoot.ContainsKey("material"));
        var droppedMaterial = Assert.IsType<string>(droppedLoot["material"]);
        Assert.Contains(droppedMaterial, new[] { "herb", "water" });
        Assert.Equal(1, Convert.ToInt32(droppedLoot["material_count"]));

        var noDropState = DefaultState.Create();
        noDropState.RngState = GetRngStateForDropRoll(16);
        var noDropLoot = Loot.GenerateLoot(noDropState, "healer", 0.5);

        Assert.False(noDropLoot.ContainsKey("material"));
        Assert.False(noDropLoot.ContainsKey("material_count"));
    }

    [Fact]
    public void CollectLoot_AddsGold_WhenNoMaterialExists()
    {
        var state = DefaultState.Create();
        int initialGold = state.Gold;
        int initialInventoryEntries = state.Inventory.Count;

        var loot = new Dictionary<string, object>
        {
            ["gold"] = 7,
            ["quality"] = "normal",
            ["multiplier"] = 1.0,
        };

        Loot.CollectLoot(state, loot);

        Assert.Equal(initialGold + 7, state.Gold);
        Assert.Equal(initialInventoryEntries, state.Inventory.Count);
    }

    [Fact]
    public void CollectLoot_AddsMaterialWithExplicitCount()
    {
        var state = DefaultState.Create();
        state.Inventory.Clear();
        int initialGold = state.Gold;

        var loot = new Dictionary<string, object>
        {
            ["gold"] = 3,
            ["material"] = "iron_ore",
            ["material_count"] = 4,
        };

        Loot.CollectLoot(state, loot);

        Assert.Equal(initialGold + 3, state.Gold);
        Assert.Equal(4, state.Inventory["iron_ore"]);
    }

    [Fact]
    public void CollectLoot_StacksExistingMaterialAndDefaultsCountToOne()
    {
        var state = DefaultState.Create();
        state.Inventory.Clear();
        state.Inventory["herb"] = 2;
        int initialGold = state.Gold;

        var loot = new Dictionary<string, object>
        {
            ["gold"] = 1,
            ["material"] = "herb",
        };

        Loot.CollectLoot(state, loot);

        Assert.Equal(initialGold + 1, state.Gold);
        Assert.Equal(3, state.Inventory["herb"]);
    }

    private static long GetRngStateForDropRoll(int targetRoll)
    {
        if (DropRollStateCache.TryGetValue(targetRoll, out var cached))
            return cached;

        var probe = DefaultState.Create();
        for (long candidate = 0; candidate < 2_000_000; candidate++)
        {
            probe.RngState = candidate;
            if (SimRng.RollRange(probe, 1, 100) == targetRoll)
            {
                DropRollStateCache[targetRoll] = candidate;
                return candidate;
            }
        }

        throw new InvalidOperationException($"Unable to find RNG state for drop roll {targetRoll}.");
    }
}
