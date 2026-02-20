using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.World;

/// <summary>
/// Worker expedition system for resource gathering.
/// Ported from sim/expeditions.gd.
/// </summary>
public static class Expeditions
{
    public static readonly Dictionary<string, ExpeditionDef> Types = new()
    {
        ["forest"] = new("Forest Expedition", "wood", 8, 3, 0.1),
        ["mine"] = new("Mining Expedition", "stone", 6, 4, 0.15),
        ["forage"] = new("Foraging Trip", "food", 10, 2, 0.05),
        ["treasure"] = new("Treasure Hunt", "gold", 3, 5, 0.25),
    };

    public static Dictionary<string, object> StartExpedition(GameState state, string type, int workerCount)
    {
        if (!Types.TryGetValue(type, out var def))
            return new() { ["ok"] = false, ["error"] = "Unknown expedition type." };
        if (workerCount <= 0)
            return new() { ["ok"] = false, ["error"] = "Need at least 1 worker." };

        int id = state.ExpeditionNextId++;
        var expedition = new Dictionary<string, object>
        {
            ["id"] = id,
            ["type"] = type,
            ["workers"] = workerCount,
            ["phase"] = "traveling",
            ["progress"] = 0,
            ["duration"] = def.Duration,
            ["started_day"] = state.Day,
        };
        state.ActiveExpeditions.Add(expedition);
        return new() { ["ok"] = true, ["expedition_id"] = id, ["message"] = $"Started {def.Name} with {workerCount} workers." };
    }

    public static List<Dictionary<string, object>> TickExpeditions(GameState state)
    {
        var completedEvents = new List<Dictionary<string, object>>();

        for (int i = state.ActiveExpeditions.Count - 1; i >= 0; i--)
        {
            var exp = state.ActiveExpeditions[i];
            int progress = Convert.ToInt32(exp.GetValueOrDefault("progress", 0)) + 1;
            int duration = Convert.ToInt32(exp.GetValueOrDefault("duration", 3));
            exp["progress"] = progress;

            if (progress >= duration)
            {
                string type = exp.GetValueOrDefault("type", "").ToString() ?? "";
                int workers = Convert.ToInt32(exp.GetValueOrDefault("workers", 1));
                var def = Types.GetValueOrDefault(type);
                if (def != null)
                {
                    int yield = def.BaseYield * workers;
                    state.Resources[def.Resource] = state.Resources.GetValueOrDefault(def.Resource, 0) + yield;
                    completedEvents.Add(new() { ["type"] = "expedition_complete", ["resource"] = def.Resource, ["amount"] = yield });
                }
                state.ActiveExpeditions.RemoveAt(i);
            }
        }
        return completedEvents;
    }

    public static int GetActiveExpeditionCount(GameState state) => state.ActiveExpeditions.Count;
}

public record ExpeditionDef(string Name, string Resource, int BaseYield, int Duration, double RiskChance);
