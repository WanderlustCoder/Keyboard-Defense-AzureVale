using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Combat;

/// <summary>
/// Target selection algorithms for typing towers.
/// Ported from sim/targeting.gd.
/// </summary>
public static class Targeting
{
    public static Dictionary<string, object>? FindTarget(
        GameState state,
        Dictionary<string, object> tower,
        List<Dictionary<string, object>> enemies)
    {
        if (enemies.Count == 0) return null;

        var alive = enemies.Where(e => e.GetValueOrDefault("alive") is true).ToList();
        if (alive.Count == 0) return null;

        string mode = tower.GetValueOrDefault("target_mode")?.ToString() ?? "nearest";
        return mode switch
        {
            "nearest" => FindNearest(tower, alive),
            "strongest" => FindStrongest(alive),
            "weakest" => FindWeakest(alive),
            "fastest" => FindFastest(alive),
            "first" => FindFirst(alive),
            "last" => FindLast(alive),
            _ => FindNearest(tower, alive),
        };
    }

    public static List<Dictionary<string, object>> FindMultiTargets(
        GameState state,
        Dictionary<string, object> tower,
        List<Dictionary<string, object>> enemies,
        int count)
    {
        var alive = enemies.Where(e => e.GetValueOrDefault("alive") is true).ToList();
        if (alive.Count == 0) return new();

        var sorted = SortByDistance(tower, alive);
        return sorted.Take(count).ToList();
    }

    public static List<Dictionary<string, object>> FindAoeTargets(
        Dictionary<string, object> center,
        List<Dictionary<string, object>> enemies,
        int radius)
    {
        var results = new List<Dictionary<string, object>>();
        var cx = Convert.ToInt32(center.GetValueOrDefault("x", 0));
        var cy = Convert.ToInt32(center.GetValueOrDefault("y", 0));

        foreach (var enemy in enemies)
        {
            if (enemy.GetValueOrDefault("alive") is not true) continue;
            var ex = Convert.ToInt32(enemy.GetValueOrDefault("x", 0));
            var ey = Convert.ToInt32(enemy.GetValueOrDefault("y", 0));
            var dist = Math.Abs(cx - ex) + Math.Abs(cy - ey);
            if (dist <= radius) results.Add(enemy);
        }
        return results;
    }

    public static List<Dictionary<string, object>> FindChainTargets(
        Dictionary<string, object> first,
        List<Dictionary<string, object>> enemies,
        int maxJumps,
        int jumpRange)
    {
        var chain = new List<Dictionary<string, object>> { first };
        var used = new HashSet<int> { Convert.ToInt32(first.GetValueOrDefault("id", -1)) };
        var current = first;

        for (int i = 0; i < maxJumps; i++)
        {
            Dictionary<string, object>? nearest = null;
            int bestDist = int.MaxValue;

            foreach (var enemy in enemies)
            {
                if (enemy.GetValueOrDefault("alive") is not true) continue;
                int id = Convert.ToInt32(enemy.GetValueOrDefault("id", -1));
                if (used.Contains(id)) continue;

                int dist = ManhattanDistance(current, enemy);
                if (dist <= jumpRange && dist < bestDist)
                {
                    bestDist = dist;
                    nearest = enemy;
                }
            }

            if (nearest == null) break;
            chain.Add(nearest);
            used.Add(Convert.ToInt32(nearest.GetValueOrDefault("id", -1)));
            current = nearest;
        }
        return chain;
    }

    public static Dictionary<string, object>? FindNearest(
        Dictionary<string, object> tower,
        List<Dictionary<string, object>> enemies)
    {
        Dictionary<string, object>? best = null;
        int bestDist = int.MaxValue;
        foreach (var e in enemies)
        {
            int dist = ManhattanDistance(tower, e);
            if (dist < bestDist)
            {
                bestDist = dist;
                best = e;
            }
        }
        return best;
    }

    public static Dictionary<string, object>? FindStrongest(List<Dictionary<string, object>> enemies)
    {
        Dictionary<string, object>? best = null;
        int bestHp = -1;
        foreach (var e in enemies)
        {
            int hp = Convert.ToInt32(e.GetValueOrDefault("hp", 0));
            if (hp > bestHp) { bestHp = hp; best = e; }
        }
        return best;
    }

    public static Dictionary<string, object>? FindWeakest(List<Dictionary<string, object>> enemies)
    {
        Dictionary<string, object>? best = null;
        int bestHp = int.MaxValue;
        foreach (var e in enemies)
        {
            int hp = Convert.ToInt32(e.GetValueOrDefault("hp", 0));
            if (hp < bestHp) { bestHp = hp; best = e; }
        }
        return best;
    }

    public static Dictionary<string, object>? FindFastest(List<Dictionary<string, object>> enemies)
    {
        Dictionary<string, object>? best = null;
        int bestSpeed = -1;
        foreach (var e in enemies)
        {
            int speed = Convert.ToInt32(e.GetValueOrDefault("speed", 0));
            if (speed > bestSpeed) { bestSpeed = speed; best = e; }
        }
        return best;
    }

    public static Dictionary<string, object>? FindFirst(List<Dictionary<string, object>> enemies)
        => enemies.Count > 0 ? enemies[0] : null;

    public static Dictionary<string, object>? FindLast(List<Dictionary<string, object>> enemies)
        => enemies.Count > 0 ? enemies[^1] : null;

    public static int ManhattanDistance(Dictionary<string, object> a, Dictionary<string, object> b)
    {
        int ax = Convert.ToInt32(a.GetValueOrDefault("x", 0));
        int ay = Convert.ToInt32(a.GetValueOrDefault("y", 0));
        int bx = Convert.ToInt32(b.GetValueOrDefault("x", 0));
        int by = Convert.ToInt32(b.GetValueOrDefault("y", 0));
        return Math.Abs(ax - bx) + Math.Abs(ay - by);
    }

    private static List<Dictionary<string, object>> SortByDistance(
        Dictionary<string, object> origin,
        List<Dictionary<string, object>> enemies)
    {
        return enemies.OrderBy(e => ManhattanDistance(origin, e)).ToList();
    }
}
