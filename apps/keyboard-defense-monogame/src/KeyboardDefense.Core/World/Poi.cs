using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.World;

/// <summary>
/// Point-of-Interest system for world exploration.
/// Ported from sim/poi.gd.
/// </summary>
public static class Poi
{
    private static Dictionary<string, Dictionary<string, object>>? _poiDefs;

    public static void LoadPois(Dictionary<string, Dictionary<string, object>> pois)
    {
        _poiDefs = pois;
    }

    public static Dictionary<string, object>? GetPoiDef(string poiId)
    {
        if (_poiDefs == null) return null;
        return _poiDefs.GetValueOrDefault(poiId);
    }

    public static bool HasActivePoi(GameState state, string poiId)
        => state.ActivePois.ContainsKey(poiId);

    public static Dictionary<string, object> InteractWithPoi(GameState state, string poiId)
    {
        if (!state.ActivePois.TryGetValue(poiId, out var poiState))
            return new() { ["ok"] = false, ["error"] = "POI not found." };

        string eventId = poiState.GetValueOrDefault("event_id", "").ToString() ?? "";
        if (string.IsNullOrEmpty(eventId))
            return new() { ["ok"] = false, ["error"] = "POI has no event." };

        var eventData = GetPoiDef(poiId);
        if (eventData == null)
            return new() { ["ok"] = false, ["error"] = "Unknown POI type." };

        return Events.TriggerEvent(state, eventId, eventData);
    }

    public static void SpawnPoi(GameState state, string poiId, GridPoint pos, Dictionary<string, object>? data = null)
    {
        var poiState = new Dictionary<string, object>
        {
            ["pos"] = pos,
            ["discovered_day"] = state.Day,
        };
        if (data != null)
        {
            foreach (var (key, value) in data)
                poiState[key] = value;
        }
        state.ActivePois[poiId] = poiState;
    }

    public static void RemovePoi(GameState state, string poiId)
    {
        state.ActivePois.Remove(poiId);
    }

    public static List<string> GetActivePoiIds(GameState state) => state.ActivePois.Keys.ToList();
}
