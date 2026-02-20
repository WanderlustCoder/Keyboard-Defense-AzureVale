using System;
using System.Collections.Generic;
using System.IO;
using KeyboardDefense.Core.State;
using Newtonsoft.Json;

namespace KeyboardDefense.Core.Data;

/// <summary>
/// Handles serialization/deserialization of GameState to/from JSON.
/// Ported from sim/save.gd (SimSave class).
/// </summary>
public static class SaveManager
{
    public const int SaveVersion = 1;

    public static string StateToJson(GameState state)
    {
        var dict = StateToDict(state);
        return JsonConvert.SerializeObject(dict, Formatting.Indented);
    }

    public static (bool Ok, GameState? State, string? Error) StateFromJson(string json)
    {
        try
        {
            var dict = JsonConvert.DeserializeObject<Dictionary<string, object>>(json);
            if (dict == null)
                return (false, null, "Failed to parse JSON.");
            return StateFromDict(dict);
        }
        catch (Exception ex)
        {
            return (false, null, $"JSON parse error: {ex.Message}");
        }
    }

    public static Dictionary<string, object> StateToDict(GameState state)
    {
        var discoveredList = new List<int>(state.Discovered);

        return new Dictionary<string, object>
        {
            ["version"] = SaveVersion,
            ["day"] = state.Day,
            ["phase"] = state.Phase,
            ["ap_max"] = state.ApMax,
            ["ap"] = state.Ap,
            ["hp"] = state.Hp,
            ["threat"] = state.Threat,
            ["resources"] = new Dictionary<string, int>(state.Resources),
            ["buildings"] = new Dictionary<string, int>(state.Buildings),
            ["map_w"] = state.MapW,
            ["map_h"] = state.MapH,
            ["base_pos"] = PointToDict(state.BasePos),
            ["cursor_pos"] = PointToDict(state.CursorPos),
            ["terrain"] = new List<string>(state.Terrain),
            ["structures"] = SerializeIntKeyDict(state.Structures),
            ["structure_levels"] = SerializeIntIntDict(state.StructureLevels),
            ["discovered"] = discoveredList,
            ["night_prompt"] = state.NightPrompt,
            ["night_spawn_remaining"] = state.NightSpawnRemaining,
            ["night_wave_total"] = state.NightWaveTotal,
            ["enemies"] = state.Enemies,
            ["enemy_next_id"] = state.EnemyNextId,
            ["last_path_open"] = state.LastPathOpen,
            ["rng_seed"] = state.RngSeed,
            ["rng_state"] = state.RngState,
            ["lesson_id"] = state.LessonId,
            ["gold"] = state.Gold,
            ["purchased_kingdom_upgrades"] = new List<string>(state.PurchasedKingdomUpgrades),
            ["purchased_unit_upgrades"] = new List<string>(state.PurchasedUnitUpgrades),
            ["typing_metrics"] = state.TypingMetrics,
            ["arrow_rain_timer"] = state.ArrowRainTimer,
        };
    }

    public static (bool Ok, GameState? State, string? Error) StateFromDict(Dictionary<string, object> data)
    {
        int version = GetInt(data, "version", 1);
        if (version > SaveVersion)
            return (false, null, $"Save version {version} is newer than supported {SaveVersion}.");

        var state = new GameState
        {
            Version = version,
            Day = GetInt(data, "day", 1),
            Phase = GetString(data, "phase", "day"),
            ApMax = GetInt(data, "ap_max", 3),
            Ap = GetInt(data, "ap", 3),
            Hp = GetInt(data, "hp", 10),
            Threat = GetInt(data, "threat", 0),
            MapW = GetInt(data, "map_w", 64),
            MapH = GetInt(data, "map_h", 64),
            NightPrompt = GetString(data, "night_prompt", ""),
            NightSpawnRemaining = GetInt(data, "night_spawn_remaining", 0),
            NightWaveTotal = GetInt(data, "night_wave_total", 0),
            EnemyNextId = GetInt(data, "enemy_next_id", 1),
            LastPathOpen = GetBool(data, "last_path_open", true),
            RngSeed = GetString(data, "rng_seed", "default"),
            RngState = GetLong(data, "rng_state", 0),
            LessonId = GetString(data, "lesson_id", "full_alpha"),
            Gold = GetInt(data, "gold", 0),
            ArrowRainTimer = GetFloat(data, "arrow_rain_timer", 0.0f),
        };

        state.BasePos = PointFromDict(data, "base_pos", new GridPoint(state.MapW / 2, state.MapH / 2));
        state.CursorPos = PointFromDict(data, "cursor_pos", state.BasePos);

        // Restore collections
        state.Resources = DeserializeStringIntDict(data, "resources");
        state.Buildings = DeserializeStringIntDict(data, "buildings");
        state.Terrain = DeserializeStringList(data, "terrain");
        state.Structures = DeserializeIntStringDict(data, "structures");
        state.StructureLevels = DeserializeIntIntDict(data, "structure_levels");
        state.Discovered = DeserializeIntHashSet(data, "discovered");
        state.Enemies = DeserializeEnemyList(data, "enemies");
        state.PurchasedKingdomUpgrades = DeserializeStringList(data, "purchased_kingdom_upgrades");
        state.PurchasedUnitUpgrades = DeserializeStringList(data, "purchased_unit_upgrades");

        return (true, state, null);
    }

    public static bool SaveToFile(GameState state, string path)
    {
        try
        {
            string json = StateToJson(state);
            File.WriteAllText(path, json);
            return true;
        }
        catch
        {
            return false;
        }
    }

    public static (bool Ok, GameState? State, string? Error) LoadFromFile(string path)
    {
        try
        {
            if (!File.Exists(path))
                return (false, null, "Save file not found.");
            string json = File.ReadAllText(path);
            return StateFromJson(json);
        }
        catch (Exception ex)
        {
            return (false, null, $"Load error: {ex.Message}");
        }
    }

    // Helpers
    private static Dictionary<string, object> PointToDict(GridPoint p)
        => new() { ["x"] = p.X, ["y"] = p.Y };

    private static GridPoint PointFromDict(Dictionary<string, object> data, string key, GridPoint fallback)
    {
        if (!data.ContainsKey(key)) return fallback;
        try
        {
            var raw = data[key];
            if (raw is Newtonsoft.Json.Linq.JObject jObj)
            {
                return new GridPoint(
                    jObj.Value<int>("x"),
                    jObj.Value<int>("y")
                );
            }
            if (raw is Dictionary<string, object> dict)
            {
                return new GridPoint(
                    Convert.ToInt32(dict.GetValueOrDefault("x", fallback.X)),
                    Convert.ToInt32(dict.GetValueOrDefault("y", fallback.Y))
                );
            }
        }
        catch { }
        return fallback;
    }

    private static Dictionary<string, string> SerializeIntKeyDict(Dictionary<int, string> dict)
    {
        var result = new Dictionary<string, string>();
        foreach (var (key, value) in dict)
            result[key.ToString()] = value;
        return result;
    }

    private static Dictionary<string, int> SerializeIntIntDict(Dictionary<int, int> dict)
    {
        var result = new Dictionary<string, int>();
        foreach (var (key, value) in dict)
            result[key.ToString()] = value;
        return result;
    }

    private static Dictionary<string, int> DeserializeStringIntDict(Dictionary<string, object> data, string key)
    {
        var result = new Dictionary<string, int>();
        if (!data.TryGetValue(key, out var raw)) return result;
        if (raw is Newtonsoft.Json.Linq.JObject jObj)
        {
            foreach (var prop in jObj.Properties())
                result[prop.Name] = prop.Value.ToObject<int>();
        }
        else if (raw is Dictionary<string, object> dict)
        {
            foreach (var (k, v) in dict)
                result[k] = Convert.ToInt32(v);
        }
        return result;
    }

    private static List<string> DeserializeStringList(Dictionary<string, object> data, string key)
    {
        var result = new List<string>();
        if (!data.TryGetValue(key, out var raw)) return result;
        if (raw is Newtonsoft.Json.Linq.JArray jArr)
        {
            foreach (var item in jArr)
                result.Add(item.ToObject<string>() ?? "");
        }
        else if (raw is List<string> list)
        {
            result.AddRange(list);
        }
        return result;
    }

    private static Dictionary<int, string> DeserializeIntStringDict(Dictionary<string, object> data, string key)
    {
        var result = new Dictionary<int, string>();
        if (!data.TryGetValue(key, out var raw)) return result;
        if (raw is Newtonsoft.Json.Linq.JObject jObj)
        {
            foreach (var prop in jObj.Properties())
                if (int.TryParse(prop.Name, out int idx))
                    result[idx] = prop.Value.ToObject<string>() ?? "";
        }
        else if (raw is Dictionary<string, string> dict)
        {
            foreach (var (k, v) in dict)
                if (int.TryParse(k, out int idx))
                    result[idx] = v;
        }
        return result;
    }

    private static Dictionary<int, int> DeserializeIntIntDict(Dictionary<string, object> data, string key)
    {
        var result = new Dictionary<int, int>();
        if (!data.TryGetValue(key, out var raw)) return result;
        if (raw is Newtonsoft.Json.Linq.JObject jObj)
        {
            foreach (var prop in jObj.Properties())
                if (int.TryParse(prop.Name, out int idx))
                    result[idx] = prop.Value.ToObject<int>();
        }
        else if (raw is Dictionary<string, int> dict)
        {
            foreach (var (k, v) in dict)
                if (int.TryParse(k, out int idx))
                    result[idx] = v;
        }
        return result;
    }

    private static HashSet<int> DeserializeIntHashSet(Dictionary<string, object> data, string key)
    {
        var result = new HashSet<int>();
        if (!data.TryGetValue(key, out var raw)) return result;
        if (raw is Newtonsoft.Json.Linq.JArray jArr)
        {
            foreach (var item in jArr)
                result.Add(item.ToObject<int>());
        }
        return result;
    }

    private static List<Dictionary<string, object>> DeserializeEnemyList(Dictionary<string, object> data, string key)
    {
        var result = new List<Dictionary<string, object>>();
        if (!data.TryGetValue(key, out var raw)) return result;
        if (raw is Newtonsoft.Json.Linq.JArray jArr)
        {
            foreach (var item in jArr)
            {
                if (item is Newtonsoft.Json.Linq.JObject jEnemy)
                {
                    var enemy = new Dictionary<string, object>();
                    foreach (var prop in jEnemy.Properties())
                        enemy[prop.Name] = prop.Value.Type switch
                        {
                            Newtonsoft.Json.Linq.JTokenType.Integer => prop.Value.ToObject<int>(),
                            Newtonsoft.Json.Linq.JTokenType.Float => prop.Value.ToObject<double>(),
                            Newtonsoft.Json.Linq.JTokenType.String => (object)prop.Value.ToObject<string>()!,
                            Newtonsoft.Json.Linq.JTokenType.Boolean => prop.Value.ToObject<bool>(),
                            _ => prop.Value.ToString(),
                        };
                    result.Add(enemy);
                }
            }
        }
        return result;
    }

    private static int GetInt(Dictionary<string, object> data, string key, int fallback)
    {
        if (data.TryGetValue(key, out var val))
        {
            try { return Convert.ToInt32(val); }
            catch { return fallback; }
        }
        return fallback;
    }

    private static long GetLong(Dictionary<string, object> data, string key, long fallback)
    {
        if (data.TryGetValue(key, out var val))
        {
            try { return Convert.ToInt64(val); }
            catch { return fallback; }
        }
        return fallback;
    }

    private static float GetFloat(Dictionary<string, object> data, string key, float fallback)
    {
        if (data.TryGetValue(key, out var val))
        {
            try { return Convert.ToSingle(val); }
            catch { return fallback; }
        }
        return fallback;
    }

    private static string GetString(Dictionary<string, object> data, string key, string fallback)
    {
        if (data.TryGetValue(key, out var val))
            return val?.ToString() ?? fallback;
        return fallback;
    }

    private static bool GetBool(Dictionary<string, object> data, string key, bool fallback)
    {
        if (data.TryGetValue(key, out var val))
        {
            try { return Convert.ToBoolean(val); }
            catch { return fallback; }
        }
        return fallback;
    }
}
