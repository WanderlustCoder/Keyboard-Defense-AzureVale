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
    public static readonly Dictionary<string, Dictionary<string, double>> BaseRates = new()
    {
        ["wood"] = new() { ["stone"] = 1.0, ["food"] = 1.5 },
        ["stone"] = new() { ["wood"] = 1.0, ["food"] = 1.5 },
        ["food"] = new() { ["wood"] = 0.67, ["stone"] = 0.67 },
    };

    public static double GetExchangeRate(string from, string to, GameState? state = null)
    {
        if (!BaseRates.TryGetValue(from, out var rates)) return 0;
        if (!rates.TryGetValue(to, out double rate)) return 0;

        // Market bonus if player has market building
        if (state != null && HasMarket(state))
            rate *= 1.15;

        return rate;
    }

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
