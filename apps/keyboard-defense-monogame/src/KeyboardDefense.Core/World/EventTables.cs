using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.World;

/// <summary>
/// Event table loading and weighted selection.
/// Ported from sim/event_tables.gd.
/// </summary>
public static class EventTables
{
    private static Dictionary<string, List<Dictionary<string, object>>>? _tables;

    public static void LoadTables(Dictionary<string, List<Dictionary<string, object>>> tables)
    {
        _tables = tables;
    }

    public static Dictionary<string, object>? SelectEvent(GameState state, string tableId)
    {
        if (_tables == null || !_tables.TryGetValue(tableId, out var entries))
            return null;

        var eligible = entries.Where(e => CheckConditions(state, e)).ToList();
        if (eligible.Count == 0) return null;

        // Weighted random selection
        double totalWeight = eligible.Sum(e => Convert.ToDouble(e.GetValueOrDefault("weight", 1.0)));
        double roll = SimRng.RollDouble(state) * totalWeight;
        double cumulative = 0;

        foreach (var entry in eligible)
        {
            cumulative += Convert.ToDouble(entry.GetValueOrDefault("weight", 1.0));
            if (roll <= cumulative) return entry;
        }

        return eligible.Last();
    }

    public static bool CheckConditions(GameState state, Dictionary<string, object> entry)
    {
        if (entry.GetValueOrDefault("conditions") is not Dictionary<string, object> conditions)
            return true;

        if (conditions.TryGetValue("min_day", out var minDay) && state.Day < Convert.ToInt32(minDay))
            return false;
        if (conditions.TryGetValue("max_day", out var maxDay) && state.Day > Convert.ToInt32(maxDay))
            return false;

        if (conditions.TryGetValue("requires_flag", out var flag))
        {
            string flagStr = flag?.ToString() ?? "";
            if (!state.EventFlags.ContainsKey(flagStr)) return false;
        }

        string eventId = entry.GetValueOrDefault("event_id", "").ToString() ?? "";
        if (state.EventCooldowns.TryGetValue(eventId, out int cooldownDay) && state.Day < cooldownDay)
            return false;

        return true;
    }

    public static void SetCooldown(GameState state, string eventId, int cooldownDays)
    {
        state.EventCooldowns[eventId] = state.Day + cooldownDays;
    }
}
