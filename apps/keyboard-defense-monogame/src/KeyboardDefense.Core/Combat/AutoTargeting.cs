using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Combat;

/// <summary>
/// Targeting algorithms for auto-defense towers.
/// Ported from sim/auto_targeting.gd.
/// </summary>
public static class AutoTargeting
{
    public static List<Dictionary<string, object>> PickTargets(
        GameState state, int towerIndex, AutoTowerTypes.AutoTargetMode mode, int range, int count = 1)
    {
        var enemies = GetEnemiesInRange(state, towerIndex, range);
        if (enemies.Count == 0) return new();

        return mode switch
        {
            AutoTowerTypes.AutoTargetMode.Nearest => PickNearest(state, towerIndex, enemies, count),
            AutoTowerTypes.AutoTargetMode.HighestHp => PickHighestHp(enemies, count),
            AutoTowerTypes.AutoTargetMode.LowestHp => PickLowestHp(enemies, count),
            AutoTowerTypes.AutoTargetMode.Fastest => PickFastest(enemies, count),
            AutoTowerTypes.AutoTargetMode.Cluster => PickCluster(enemies, count),
            AutoTowerTypes.AutoTargetMode.Chain => PickChain(state, towerIndex, enemies, count),
            AutoTowerTypes.AutoTargetMode.Zone => enemies,
            AutoTowerTypes.AutoTargetMode.Contact => PickContact(state, towerIndex, enemies),
            AutoTowerTypes.AutoTargetMode.Smart => PickSmart(state, towerIndex, enemies, count),
            _ => PickNearest(state, towerIndex, enemies, count),
        };
    }

    private static List<Dictionary<string, object>> GetEnemiesInRange(GameState state, int towerIndex, int range)
    {
        var towerPos = GridPoint.FromIndex(towerIndex, state.MapW);
        return state.Enemies.Where(e =>
        {
            if (e.GetValueOrDefault("pos") is not GridPoint pos) return false;
            return towerPos.ManhattanDistance(pos) <= range;
        }).ToList();
    }

    private static List<Dictionary<string, object>> PickNearest(
        GameState state, int towerIndex, List<Dictionary<string, object>> enemies, int count)
    {
        var towerPos = GridPoint.FromIndex(towerIndex, state.MapW);
        return enemies
            .OrderBy(e => e.GetValueOrDefault("pos") is GridPoint p ? towerPos.ManhattanDistance(p) : int.MaxValue)
            .Take(count).ToList();
    }

    private static List<Dictionary<string, object>> PickHighestHp(
        List<Dictionary<string, object>> enemies, int count)
    {
        return enemies.OrderByDescending(e => Convert.ToInt32(e.GetValueOrDefault("hp", 0)))
            .Take(count).ToList();
    }

    private static List<Dictionary<string, object>> PickLowestHp(
        List<Dictionary<string, object>> enemies, int count)
    {
        return enemies.OrderBy(e => Convert.ToInt32(e.GetValueOrDefault("hp", 0)))
            .Take(count).ToList();
    }

    private static List<Dictionary<string, object>> PickFastest(
        List<Dictionary<string, object>> enemies, int count)
    {
        return enemies.OrderByDescending(e => Convert.ToDouble(e.GetValueOrDefault("speed", 0)))
            .Take(count).ToList();
    }

    private static List<Dictionary<string, object>> PickCluster(
        List<Dictionary<string, object>> enemies, int count)
    {
        // Find enemy with most neighbors
        return enemies
            .OrderByDescending(e =>
            {
                if (e.GetValueOrDefault("pos") is not GridPoint pos) return 0;
                return enemies.Count(other =>
                {
                    if (other.GetValueOrDefault("pos") is not GridPoint otherPos) return false;
                    return pos.ManhattanDistance(otherPos) <= 2;
                });
            })
            .Take(count).ToList();
    }

    private static List<Dictionary<string, object>> PickChain(
        GameState state, int towerIndex, List<Dictionary<string, object>> enemies, int chainCount)
    {
        var primary = PickNearest(state, towerIndex, enemies, 1);
        if (primary.Count == 0) return new();

        var result = new List<Dictionary<string, object>>(primary);
        var remaining = enemies.Except(result).ToList();

        for (int i = 1; i < chainCount && remaining.Count > 0; i++)
        {
            var lastPos = result.Last().GetValueOrDefault("pos") as GridPoint? ?? GridPoint.Zero;
            var next = remaining.OrderBy(e =>
                e.GetValueOrDefault("pos") is GridPoint p ? lastPos.ManhattanDistance(p) : int.MaxValue).First();
            result.Add(next);
            remaining.Remove(next);
        }
        return result;
    }

    private static List<Dictionary<string, object>> PickContact(
        GameState state, int towerIndex, List<Dictionary<string, object>> enemies)
    {
        var towerPos = GridPoint.FromIndex(towerIndex, state.MapW);
        return enemies.Where(e =>
        {
            if (e.GetValueOrDefault("pos") is not GridPoint pos) return false;
            return towerPos.ManhattanDistance(pos) <= 1;
        }).ToList();
    }

    private static List<Dictionary<string, object>> PickSmart(
        GameState state, int towerIndex, List<Dictionary<string, object>> enemies, int count)
    {
        var towerPos = GridPoint.FromIndex(towerIndex, state.MapW);
        return enemies.OrderByDescending(e =>
        {
            double score = 0;
            int hp = Convert.ToInt32(e.GetValueOrDefault("hp", 1));
            int maxHp = Convert.ToInt32(e.GetValueOrDefault("max_hp", 1));
            double speed = Convert.ToDouble(e.GetValueOrDefault("speed", 1));
            int damage = Convert.ToInt32(e.GetValueOrDefault("damage", 1));

            // Prioritize low HP% (finish off)
            double hpPct = maxHp > 0 ? (double)hp / maxHp : 1.0;
            score += (1.0 - hpPct) * 30;

            // Prioritize high damage enemies
            score += damage * 5;

            // Prioritize fast enemies
            score += speed * 2;

            // Prioritize closer enemies
            if (e.GetValueOrDefault("pos") is GridPoint pos)
            {
                int dist = towerPos.ManhattanDistance(pos);
                score += Math.Max(0, 10 - dist) * 3;
            }

            // Bonus for bosses/elites
            string kind = e.GetValueOrDefault("kind")?.ToString() ?? "";
            if (kind.Contains("boss")) score += 50;
            if (kind.Contains("elite")) score += 25;

            return score;
        }).Take(count).ToList();
    }
}
