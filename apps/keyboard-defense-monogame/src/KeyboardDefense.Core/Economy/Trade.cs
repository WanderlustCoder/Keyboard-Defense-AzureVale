using System;
using System.Collections.Generic;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Economy;

/// <summary>
/// Resource trading system with exchange rates.
/// Ported from sim/trade.gd.
/// </summary>
public static class Trade
{
    /// <summary>
    /// Base exchange rates for one unit of source resource converted into target resource.
    /// Current routes are: wood to stone (1.0), wood to food (1.5), stone to wood (1.0),
    /// stone to food (1.5), food to wood (0.67), and food to stone (0.67).
    /// </summary>
    public static readonly Dictionary<string, Dictionary<string, double>> BaseRates = new()
    {
        ["wood"] = new() { ["stone"] = 1.0, ["food"] = 1.5 },
        ["stone"] = new() { ["wood"] = 1.0, ["food"] = 1.5 },
        ["food"] = new() { ["wood"] = 0.67, ["stone"] = 0.67 },
    };

    /// <summary>
    /// Gets the exchange rate between two resources, including the market building bonus when available.
    /// </summary>
    /// <param name="from">The resource being spent.</param>
    /// <param name="to">The resource being received.</param>
    /// <param name="state">The game state used to evaluate market bonus eligibility.</param>
    /// <returns>
    /// The effective exchange rate for the route, or <c>0</c> when no route exists.
    /// A market increases the base rate by 15%.
    /// </returns>
    public static double GetExchangeRate(string from, string to, GameState? state = null)
    {
        if (!BaseRates.TryGetValue(from, out var rates)) return 0;
        if (!rates.TryGetValue(to, out double rate)) return 0;

        // Market bonus if player has market building
        if (state != null && HasMarket(state))
            rate *= 1.15;

        return rate;
    }

    /// <summary>
    /// Executes a trade by spending one resource and adding the converted amount of another resource.
    /// </summary>
    /// <param name="state">The game state containing resources and structures.</param>
    /// <param name="from">The resource type to spend.</param>
    /// <param name="to">The resource type to receive.</param>
    /// <param name="amount">The amount of source resource to spend.</param>
    /// <returns>
    /// A result dictionary with <c>success</c> and either trade details
    /// (<c>spent</c>, <c>received</c>, <c>rate</c>) or an <c>error</c> message.
    /// </returns>
    public static Dictionary<string, object> ExecuteTrade(GameState state, string from, string to, int amount)
    {
        if (from == to)
            return Error("Cannot trade a resource for itself.");
        if (amount <= 0)
            return Error("Amount must be positive.");

        double rate = GetExchangeRate(from, to, state);
        if (rate <= 0)
            return Error($"No trade route from {from} to {to}.");

        int currentFrom = state.Resources.GetValueOrDefault(from, 0);
        if (currentFrom < amount)
            return Error($"Not enough {from} (have {currentFrom}, need {amount}).");

        int received = Math.Max(1, (int)(amount * rate));

        state.Resources[from] = currentFrom - amount;
        state.Resources[to] = state.Resources.GetValueOrDefault(to, 0) + received;

        return new Dictionary<string, object>
        {
            ["success"] = true,
            ["from"] = from,
            ["to"] = to,
            ["spent"] = amount,
            ["received"] = received,
            ["rate"] = rate,
            ["message"] = $"Traded {amount} {from} for {received} {to}."
        };
    }

    private static bool HasMarket(GameState state)
    {
        foreach (var (_, building) in state.Structures)
            if (building == "market") return true;
        return false;
    }

    private static Dictionary<string, object> Error(string message) => new()
    {
        ["success"] = false,
        ["error"] = message
    };
}
