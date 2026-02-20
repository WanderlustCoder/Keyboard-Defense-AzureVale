using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Combat;

/// <summary>
/// Summoned unit management for Summoner towers.
/// Ported from sim/summoned_units.gd.
/// </summary>
public static class SummonedUnits
{
    public const int MaxSummonsPerTower = 3;
    public const int BaseUnitHp = 15;
    public const int BaseUnitDamage = 4;
    public const double BaseUnitSpeed = 1.0;

    public static Dictionary<string, object> CreateUnit(GameState state, int towerIndex, int level)
    {
        int id = state.SummonedNextId++;
        return new Dictionary<string, object>
        {
            ["id"] = id,
            ["tower_index"] = towerIndex,
            ["hp"] = BaseUnitHp + level * 5,
            ["max_hp"] = BaseUnitHp + level * 5,
            ["damage"] = BaseUnitDamage + level * 2,
            ["speed"] = BaseUnitSpeed,
            ["pos"] = GridPoint.FromIndex(towerIndex, state.MapW),
            ["target_id"] = -1,
        };
    }

    public static bool CanSummon(GameState state, int towerIndex)
    {
        var summonIds = state.TowerSummonIds.GetValueOrDefault(towerIndex);
        if (summonIds == null) return true;
        int activeSummons = summonIds.Count(sid =>
            state.SummonedUnits.Any(u => Convert.ToInt32(u.GetValueOrDefault("id", -1)) == sid));
        return activeSummons < MaxSummonsPerTower;
    }

    public static Dictionary<string, object>? SpawnUnit(GameState state, int towerIndex, int level)
    {
        if (!CanSummon(state, towerIndex)) return null;
        var unit = CreateUnit(state, towerIndex, level);
        state.SummonedUnits.Add(unit);
        int unitId = Convert.ToInt32(unit["id"]);
        if (!state.TowerSummonIds.ContainsKey(towerIndex))
            state.TowerSummonIds[towerIndex] = new List<int>();
        state.TowerSummonIds[towerIndex].Add(unitId);
        return unit;
    }

    public static void RemoveDeadUnits(GameState state)
    {
        state.SummonedUnits.RemoveAll(u => Convert.ToInt32(u.GetValueOrDefault("hp", 0)) <= 0);
    }
}
