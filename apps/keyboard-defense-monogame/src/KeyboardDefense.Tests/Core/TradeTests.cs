using System.Collections.Generic;
using KeyboardDefense.Core.Economy;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class TradeTests
{
    [Fact]
    public void GetExchangeRate_KnownPairWithoutState_ReturnsBaseRate()
    {
        double rate = Trade.GetExchangeRate("wood", "food");

        Assert.Equal(1.5, rate);
    }

    [Fact]
    public void GetExchangeRate_KnownPairWithoutMarket_ReturnsBaseRate()
    {
        var state = CreateState(wood: 5, stone: 1, food: 0);

        double rate = Trade.GetExchangeRate("wood", "stone", state);

        Assert.Equal(1.0, rate);
    }

    [Fact]
    public void GetExchangeRate_MarketPresent_AppliesBonus()
    {
        var state = CreateState(wood: 5, stone: 0, food: 0, withMarket: true);

        double rate = Trade.GetExchangeRate("wood", "stone", state);

        Assert.Equal(1.15, rate, 6);
    }

    [Fact]
    public void GetExchangeRate_UnknownPair_ReturnsZero()
    {
        Assert.Equal(0, Trade.GetExchangeRate("wood", "gold"));
        Assert.Equal(0, Trade.GetExchangeRate("gold", "wood"));
    }

    [Fact]
    public void ExecuteTrade_ValidTrade_UpdatesResourcesAndReturnsPayload()
    {
        var state = CreateState(wood: 10, stone: 1, food: 0);

        var result = Trade.ExecuteTrade(state, "wood", "stone", 4);

        Assert.True((bool)result["success"]);
        Assert.Equal("wood", result["from"]);
        Assert.Equal("stone", result["to"]);
        Assert.Equal(4, result["spent"]);
        Assert.Equal(4, result["received"]);
        Assert.Equal(1.0, (double)result["rate"]);
        Assert.Equal("Traded 4 wood for 4 stone.", result["message"]);
        Assert.Equal(6, state.Resources["wood"]);
        Assert.Equal(5, state.Resources["stone"]);
    }

    [Fact]
    public void ExecuteTrade_FractionalRate_FloorsReceivedAmount()
    {
        var state = CreateState(wood: 0, stone: 0, food: 6);

        var result = Trade.ExecuteTrade(state, "food", "wood", 3);

        Assert.True((bool)result["success"]);
        Assert.Equal(2, result["received"]);
        Assert.Equal(3, state.Resources["food"]);
        Assert.Equal(2, state.Resources["wood"]);
    }

    [Fact]
    public void ExecuteTrade_WhenRateTimesAmountIsBelowOne_StillReceivesOne()
    {
        var state = CreateState(wood: 0, stone: 0, food: 1);

        var result = Trade.ExecuteTrade(state, "food", "wood", 1);

        Assert.True((bool)result["success"]);
        Assert.Equal(1, result["received"]);
        Assert.Equal(0, state.Resources["food"]);
        Assert.Equal(1, state.Resources["wood"]);
    }

    [Fact]
    public void ExecuteTrade_MarketBonusChangesReceivedAmount()
    {
        var state = CreateState(wood: 10, stone: 0, food: 0, withMarket: true);

        var result = Trade.ExecuteTrade(state, "wood", "stone", 10);

        Assert.True((bool)result["success"]);
        Assert.Equal(11, result["received"]);
        Assert.Equal(0, state.Resources["wood"]);
        Assert.Equal(11, state.Resources["stone"]);
        Assert.Equal(1.15, (double)result["rate"], 6);
    }

    [Fact]
    public void ExecuteTrade_SameResource_ReturnsErrorAndDoesNotMutateResources()
    {
        var state = CreateState(wood: 9, stone: 2, food: 1);

        var result = Trade.ExecuteTrade(state, "wood", "wood", 3);

        Assert.False((bool)result["success"]);
        Assert.Equal("Cannot trade a resource for itself.", result["error"]);
        Assert.Equal(9, state.Resources["wood"]);
        Assert.Equal(2, state.Resources["stone"]);
        Assert.Equal(1, state.Resources["food"]);
    }

    [Fact]
    public void ExecuteTrade_InvalidAmountRouteAndBalance_ReturnErrorsAndDoNotMutate()
    {
        var invalidAmountState = CreateState(wood: 9, stone: 2, food: 1);
        var negativeAmountState = CreateState(wood: 9, stone: 2, food: 1);
        var noRouteState = CreateState(wood: 9, stone: 2, food: 1);
        var insufficientState = CreateState(wood: 2, stone: 5, food: 1);

        var zeroAmount = Trade.ExecuteTrade(invalidAmountState, "wood", "stone", 0);
        var negativeAmount = Trade.ExecuteTrade(negativeAmountState, "wood", "stone", -2);
        var noRoute = Trade.ExecuteTrade(noRouteState, "wood", "gold", 2);
        var insufficient = Trade.ExecuteTrade(insufficientState, "wood", "stone", 3);

        Assert.False((bool)zeroAmount["success"]);
        Assert.Equal("Amount must be positive.", zeroAmount["error"]);
        Assert.Equal(9, invalidAmountState.Resources["wood"]);
        Assert.Equal(2, invalidAmountState.Resources["stone"]);

        Assert.False((bool)negativeAmount["success"]);
        Assert.Equal("Amount must be positive.", negativeAmount["error"]);
        Assert.Equal(9, negativeAmountState.Resources["wood"]);
        Assert.Equal(2, negativeAmountState.Resources["stone"]);

        Assert.False((bool)noRoute["success"]);
        Assert.Equal("No trade route from wood to gold.", noRoute["error"]);
        Assert.Equal(9, noRouteState.Resources["wood"]);
        Assert.Equal(2, noRouteState.Resources["stone"]);
        Assert.False(noRouteState.Resources.ContainsKey("gold"));

        Assert.False((bool)insufficient["success"]);
        Assert.Equal("Not enough wood (have 2, need 3).", insufficient["error"]);
        Assert.Equal(2, insufficientState.Resources["wood"]);
        Assert.Equal(5, insufficientState.Resources["stone"]);
    }

    private static GameState CreateState(int wood, int stone, int food, bool withMarket = false)
    {
        var state = new GameState();
        state.Resources["wood"] = wood;
        state.Resources["stone"] = stone;
        state.Resources["food"] = food;

        if (withMarket)
            state.Structures[1] = "market";

        return state;
    }
}
