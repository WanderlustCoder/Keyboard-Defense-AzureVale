using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using KeyboardDefense.Core.State;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace KeyboardDefense.Core.Progression;

/// <summary>
/// Kingdom and unit upgrade system.
/// Ported from sim/upgrades.gd.
/// </summary>
public static class Upgrades
{
    private static List<Dictionary<string, object>>? _kingdomUpgrades;
    private static List<Dictionary<string, object>>? _unitUpgrades;

    public static List<Dictionary<string, object>> GetKingdomUpgrades()
    {
        if (_kingdomUpgrades == null)
            _kingdomUpgrades = LoadUpgrades("data/kingdom_upgrades.json");
        return _kingdomUpgrades;
    }

    public static List<Dictionary<string, object>> GetUnitUpgrades()
    {
        if (_unitUpgrades == null)
            _unitUpgrades = LoadUpgrades("data/unit_upgrades.json");
        return _unitUpgrades;
    }

    public static Dictionary<string, object>? GetKingdomUpgrade(string id)
        => GetKingdomUpgrades().FirstOrDefault(u => u.GetValueOrDefault("id")?.ToString() == id);

    public static Dictionary<string, object>? GetUnitUpgrade(string id)
        => GetUnitUpgrades().FirstOrDefault(u => u.GetValueOrDefault("id")?.ToString() == id);

    public static Dictionary<string, object> CanPurchase(GameState state, string upgradeId, string category)
    {
        var upgrade = category == "kingdom" ? GetKingdomUpgrade(upgradeId) : GetUnitUpgrade(upgradeId);
        if (upgrade == null)
            return new() { ["ok"] = false, ["error"] = "Unknown upgrade." };

        var purchased = category == "kingdom" ? state.PurchasedKingdomUpgrades : state.PurchasedUnitUpgrades;
        if (purchased.Contains(upgradeId))
            return new() { ["ok"] = false, ["error"] = "Already purchased." };

        int cost = Convert.ToInt32(upgrade.GetValueOrDefault("gold_cost", 0));
        if (state.Gold < cost)
            return new() { ["ok"] = false, ["error"] = $"Need {cost} gold (have {state.Gold})." };

        // Check prerequisites
        if (upgrade.GetValueOrDefault("requires") is string req && !string.IsNullOrEmpty(req))
        {
            if (!purchased.Contains(req))
                return new() { ["ok"] = false, ["error"] = $"Requires {req} first." };
        }

        return new() { ["ok"] = true };
    }

    public static Dictionary<string, object> Purchase(GameState state, string upgradeId, string category)
    {
        var check = CanPurchase(state, upgradeId, category);
        if (check.GetValueOrDefault("ok") is not true) return check;

        var upgrade = category == "kingdom" ? GetKingdomUpgrade(upgradeId) : GetUnitUpgrade(upgradeId);
        if (upgrade == null) return new() { ["ok"] = false, ["error"] = "Unknown upgrade." };

        int cost = Convert.ToInt32(upgrade.GetValueOrDefault("gold_cost", 0));
        state.Gold -= cost;

        var purchased = category == "kingdom" ? state.PurchasedKingdomUpgrades : state.PurchasedUnitUpgrades;
        purchased.Add(upgradeId);

        string name = upgrade.GetValueOrDefault("name")?.ToString() ?? upgradeId;
        return new()
        {
            ["ok"] = true,
            ["message"] = $"Purchased {name} for {cost} gold."
        };
    }

    private static List<Dictionary<string, object>> LoadUpgrades(string path)
    {
        try
        {
            if (!File.Exists(path)) return new();
            string json = File.ReadAllText(path);
            var data = JsonConvert.DeserializeObject<JObject>(json);
            var arr = data?["upgrades"]?.ToObject<List<Dictionary<string, object>>>();
            return arr ?? new();
        }
        catch
        {
            return new();
        }
    }
}
