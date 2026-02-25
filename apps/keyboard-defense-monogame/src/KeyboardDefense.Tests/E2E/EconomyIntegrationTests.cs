using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Economy;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.E2E;

[CollectionDefinition("EconomyIntegrationSerial", DisableParallelization = true)]
public sealed class EconomyIntegrationSerialCollection
{
}

[Collection("EconomyIntegrationSerial")]
public class EconomyIntegrationTests
{
    private static readonly FieldInfo BuildingsCacheField =
        typeof(BuildingsData).GetField("_cache", BindingFlags.NonPublic | BindingFlags.Static)
        ?? throw new InvalidOperationException("Could not access BuildingsData cache.");

    [Fact]
    public void ResourceGeneration_OverMultipleTicks_AccumulatesProduction()
    {
        var state = DefaultState.Create("econ_multi_tick_generation");
        state.Structures[0] = "farm";
        state.Structures[1] = "lumber";
        state.Structures[2] = "quarry";

        int startFood = state.Resources.GetValueOrDefault("food", 0);
        int startWood = state.Resources.GetValueOrDefault("wood", 0);
        int startStone = state.Resources.GetValueOrDefault("stone", 0);

        SimTick.AdvanceDay(state);
        SimTick.AdvanceDay(state);

        Assert.Equal(3, state.Day);
        Assert.Equal(startFood + 4, state.Resources.GetValueOrDefault("food", 0));
        Assert.Equal(startWood + 4, state.Resources.GetValueOrDefault("wood", 0));
        Assert.Equal(startStone + 4, state.Resources.GetValueOrDefault("stone", 0));
    }

    [Fact]
    public void TradeExecution_ThroughIntent_UpdatesResourceBalances()
    {
        var state = DefaultState.Create("econ_trade_intent");
        state.Resources["wood"] = 30;
        state.Resources["stone"] = 1;

        state = ApplyIntent(state, "trade_execute", new()
        {
            ["from_resource"] = "wood",
            ["to_resource"] = "stone",
            ["amount"] = 10
        }, out var events);

        Assert.Equal(20, state.Resources.GetValueOrDefault("wood", 0));
        Assert.Equal(11, state.Resources.GetValueOrDefault("stone", 0));
        Assert.Contains(events, e => e.Contains("Traded 10 wood for 10 stone", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public void TradeExecution_WithMarketStructure_AppliesRateBonus()
    {
        var state = DefaultState.Create("econ_trade_market_bonus");
        state.Structures[7] = "market";
        state.Resources["wood"] = 20;
        state.Resources["stone"] = 0;

        state = ApplyIntent(state, "trade_execute", new()
        {
            ["from_resource"] = "wood",
            ["to_resource"] = "stone",
            ["amount"] = 10
        }, out _);

        Assert.Equal(10, state.Resources.GetValueOrDefault("wood", 0));
        Assert.Equal(11, state.Resources.GetValueOrDefault("stone", 0));
    }

    [Fact]
    public void TradeExecution_WhenSourceIsInsufficient_DoesNotMutateResources()
    {
        var state = DefaultState.Create("econ_trade_insufficient_balance");
        state.Resources["wood"] = 5;
        state.Resources["stone"] = 3;

        state = ApplyIntent(state, "trade_execute", new()
        {
            ["from_resource"] = "wood",
            ["to_resource"] = "stone",
            ["amount"] = 10
        }, out var events);

        Assert.Equal(5, state.Resources.GetValueOrDefault("wood", 0));
        Assert.Equal(3, state.Resources.GetValueOrDefault("stone", 0));
        Assert.Contains(events, e => e.Contains("Not enough wood", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public void Crafting_ConsumesInputMaterials_AndProducesItem()
    {
        var state = DefaultState.Create("econ_crafting_single_recipe");
        state.Inventory["iron_ore"] = 4;

        var result = Crafting.Craft(state, "iron_ingot");

        Assert.True((bool)result["success"]);
        Assert.Equal(2, Convert.ToInt32(state.Inventory.GetValueOrDefault("iron_ore", 0)));
        Assert.Equal(1, Convert.ToInt32(state.Inventory.GetValueOrDefault("iron_ingot", 0)));
    }

    [Fact]
    public void Crafting_ChainRecipe_ConsumesIntermediatesAndOutputsFinalItem()
    {
        var state = DefaultState.Create("econ_crafting_chain");
        state.Inventory["iron_ore"] = 8;
        state.Inventory["coal"] = 2;

        Crafting.Craft(state, "iron_ingot");
        Crafting.Craft(state, "iron_ingot");
        var steelResult = Crafting.Craft(state, "steel_ingot");

        Assert.True((bool)steelResult["success"]);
        Assert.Equal(4, Convert.ToInt32(state.Inventory.GetValueOrDefault("iron_ore", 0)));
        Assert.Equal(0, Convert.ToInt32(state.Inventory.GetValueOrDefault("iron_ingot", 0)));
        Assert.Equal(1, Convert.ToInt32(state.Inventory.GetValueOrDefault("coal", 0)));
        Assert.Equal(1, Convert.ToInt32(state.Inventory.GetValueOrDefault("steel_ingot", 0)));
    }

    [Fact]
    public void ResourceDepletion_ThenRecoveryViaDailyIncome_EnablesSecondTowerBuild()
    {
        WithLoadedBuildingsData(() =>
        {
            var state = DefaultState.Create("econ_deplete_recover");
            var towerCost = BuildingsData.CostFor("tower");
            int towerWood = towerCost.GetValueOrDefault("wood", 0);
            int towerStone = towerCost.GetValueOrDefault("stone", 0);

            state.Resources["wood"] = towerWood;
            state.Resources["stone"] = towerStone;

            var firstTile = PrepareBuildTile(state, 2, 0);
            var secondTile = PrepareBuildTile(state, 3, 0);

            state = BuildTower(state, firstTile, out _);

            Assert.Equal(0, state.Resources.GetValueOrDefault("wood", 0));
            Assert.Equal(0, state.Resources.GetValueOrDefault("stone", 0));

            state = BuildTower(state, secondTile, out var failedBuildEvents);
            Assert.Contains(failedBuildEvents, e => e.Contains("Not enough resources", StringComparison.OrdinalIgnoreCase));

            state.Structures[100] = "lumber";
            state.Structures[101] = "quarry";

            int daysToRecover = Math.Max(
                (int)Math.Ceiling(towerWood / 2.0),
                (int)Math.Ceiling(towerStone / 2.0));

            for (int i = 0; i < daysToRecover; i++)
                SimTick.AdvanceDay(state);

            state = BuildTower(state, secondTile, out _);
            int secondIndex = SimMap.Idx(secondTile.X, secondTile.Y, state.MapW);

            Assert.True(state.Structures.TryGetValue(secondIndex, out var builtType) && builtType == "tower");
        });
    }

    [Fact]
    public void TradeRecovery_ConvertsWoodIntoStone_ForTowerBuildReadiness()
    {
        WithLoadedBuildingsData(() =>
        {
            var state = DefaultState.Create("econ_trade_recovery");
            var towerCost = BuildingsData.CostFor("tower");
            int towerWood = towerCost.GetValueOrDefault("wood", 0);
            int towerStone = towerCost.GetValueOrDefault("stone", 0);

            double rate = Trade.GetExchangeRate("wood", "stone", state);
            int tradeAmount = AmountNeededForMinimumReceive(towerStone, rate);

            state.Resources["wood"] = towerWood + tradeAmount;
            state.Resources["stone"] = 0;

            var buildTile = PrepareBuildTile(state, 2, 1);

            state = BuildTower(state, buildTile, out var failEvents);
            Assert.Contains(failEvents, e => e.Contains("Not enough resources", StringComparison.OrdinalIgnoreCase));

            state = ApplyIntent(state, "trade_execute", new()
            {
                ["from_resource"] = "wood",
                ["to_resource"] = "stone",
                ["amount"] = tradeAmount
            }, out _);

            state = BuildTower(state, buildTile, out _);
            int buildIndex = SimMap.Idx(buildTile.X, buildTile.Y, state.MapW);

            Assert.True(state.Structures.TryGetValue(buildIndex, out var builtType) && builtType == "tower");
            Assert.True(state.Resources.GetValueOrDefault("wood", 0) >= 0);
            Assert.True(state.Resources.GetValueOrDefault("stone", 0) >= 0);
        });
    }

    [Fact]
    public void EconomyBalance_IncomeCanSustainRepeatedTowerConstruction()
    {
        WithLoadedBuildingsData(() =>
        {
            var state = DefaultState.Create("econ_balance_sustain");
            var towerCost = BuildingsData.CostFor("tower");
            int towerWood = towerCost.GetValueOrDefault("wood", 0);
            int towerStone = towerCost.GetValueOrDefault("stone", 0);

            int lumberCount = (int)Math.Ceiling(towerWood / 2.0);
            int quarryCount = (int)Math.Ceiling(towerStone / 2.0);
            for (int i = 0; i < lumberCount; i++)
                state.Structures[300 + i] = "lumber";
            for (int i = 0; i < quarryCount; i++)
                state.Structures[400 + i] = "quarry";

            state.Resources["wood"] = 0;
            state.Resources["stone"] = 0;

            var buildTiles = new[]
            {
                PrepareBuildTile(state, 2, 0),
                PrepareBuildTile(state, 3, 0),
                PrepareBuildTile(state, 4, 0),
            };

            foreach (var tile in buildTiles)
            {
                SimTick.AdvanceDay(state);
                state = BuildTower(state, tile, out var buildEvents);
                Assert.DoesNotContain(buildEvents, e => e.Contains("Not enough resources", StringComparison.OrdinalIgnoreCase));
            }

            int towersBuilt = state.Structures.Values.Count(v => v == "tower");
            Assert.Equal(buildTiles.Length, towersBuilt);
        });
    }

    [Fact]
    public void ResourceRecovery_MidgameFoodBonusProvidesSupplyWhenDepleted()
    {
        var state = DefaultState.Create("econ_midgame_food_bonus");
        state.Day = 4;
        state.Resources["food"] = 0;

        var result = SimTick.AdvanceDay(state);
        var events = result.GetValueOrDefault("events") as List<string> ?? new();

        Assert.Equal(2, state.Resources.GetValueOrDefault("food", 0));
        Assert.Contains(events, e => e.Contains("Midgame supply", StringComparison.OrdinalIgnoreCase));
    }

    private static GameState BuildTower(GameState state, GridPoint position, out List<string> events)
    {
        return ApplyIntent(state, "build", new()
        {
            ["building"] = "tower",
            ["x"] = position.X,
            ["y"] = position.Y
        }, out events);
    }

    private static GameState ApplyIntent(
        GameState state,
        string kind,
        Dictionary<string, object>? payload,
        out List<string> events)
    {
        var result = IntentApplier.Apply(state, SimIntents.Make(kind, payload));
        events = result.GetValueOrDefault("events") as List<string> ?? new();
        return Assert.IsType<GameState>(result["state"]);
    }

    private static GridPoint PrepareBuildTile(GameState state, int dx, int dy)
    {
        var position = new GridPoint(state.BasePos.X + dx, state.BasePos.Y + dy);
        Assert.True(SimMap.InBounds(position.X, position.Y, state.MapW, state.MapH));
        int index = SimMap.Idx(position.X, position.Y, state.MapW);
        state.Discovered.Add(index);
        state.Terrain[index] = SimMap.TerrainPlains;
        state.Structures.Remove(index);
        return position;
    }

    private static int AmountNeededForMinimumReceive(int minimumReceive, double rate)
    {
        if (minimumReceive <= 0)
            return 0;
        if (rate <= 0)
            throw new ArgumentOutOfRangeException(nameof(rate), "Exchange rate must be positive.");

        int amount = 1;
        while (Math.Max(1, (int)(amount * rate)) < minimumReceive)
            amount++;
        return amount;
    }

    private static void WithLoadedBuildingsData(Action action)
    {
        object? originalCache = BuildingsCacheField.GetValue(null);
        try
        {
            BuildingsData.LoadData(FindDataDirectory());
            action();
        }
        finally
        {
            BuildingsCacheField.SetValue(null, originalCache);
        }
    }

    private static string FindDataDirectory()
    {
        string dir = AppContext.BaseDirectory;
        for (int i = 0; i < 10; i++)
        {
            string candidate = Path.Combine(dir, "data");
            if (File.Exists(Path.Combine(candidate, "buildings.json")))
                return candidate;

            string parent = Path.GetDirectoryName(dir) ?? dir;
            if (parent == dir)
                break;
            dir = parent;
        }

        throw new DirectoryNotFoundException("Could not find data directory with buildings.json.");
    }
}
