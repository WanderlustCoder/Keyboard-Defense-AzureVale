using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.World;

/// <summary>
/// Populates and manages world entities: resource nodes, roaming enemies, NPCs, POIs.
/// </summary>
public static class WorldEntities
{
    private static readonly string[] ResourceNodeTypes = { "wood_grove", "stone_quarry", "food_garden", "gold_vein" };
    private static readonly string[] EnemyKindsByTier = { "scout", "raider", "armored", "berserker", "elite" };
    private static readonly string[] NpcTypes = { "trainer", "merchant", "quest_giver" };

    /// <summary>Seeds the world with resource nodes, roaming enemies, and NPCs.</summary>
    public static void PopulateWorld(GameState state)
    {
        PopulateResourceNodes(state);
        PopulateRoamingEnemies(state);
        PopulateNpcs(state);
    }

    private static void PopulateResourceNodes(GameState state)
    {
        // Place 4-8 resource nodes per zone in discovered-accessible areas
        string[] zones = { SimMap.ZoneSafe, SimMap.ZoneFrontier, SimMap.ZoneWilderness };
        foreach (string zone in zones)
        {
            int count = SimRng.RollRange(state, 4, 8);
            for (int i = 0; i < count; i++)
            {
                var pos = FindValidPositionInZone(state, zone, 50);
                if (pos == null) continue;

                int idx = SimMap.Idx(pos.Value.X, pos.Value.Y, state.MapW);
                if (state.ResourceNodes.ContainsKey(idx)) continue;

                string nodeType = ResourceNodeTypes[SimRng.RollRange(state, 0, ResourceNodeTypes.Length - 1)];
                state.ResourceNodes[idx] = new Dictionary<string, object>
                {
                    ["type"] = nodeType,
                    ["pos"] = pos.Value,
                    ["zone"] = zone,
                    ["cooldown"] = 0,
                };
            }
        }
    }

    private static void PopulateRoamingEnemies(GameState state)
    {
        // Scale enemy count and tier to zone danger
        var zoneConfigs = new[]
        {
            (Zone: SimMap.ZoneFrontier, MinCount: 2, MaxCount: 4, MaxTier: 1),
            (Zone: SimMap.ZoneWilderness, MinCount: 3, MaxCount: 6, MaxTier: 3),
            (Zone: SimMap.ZoneDepths, MinCount: 2, MaxCount: 4, MaxTier: 4),
        };

        foreach (var config in zoneConfigs)
        {
            int count = SimRng.RollRange(state, config.MinCount, config.MaxCount);
            for (int i = 0; i < count; i++)
            {
                if (state.RoamingEnemies.Count >= WorldTick.MaxRoamingEnemies) break;

                var pos = FindValidPositionInZone(state, config.Zone, 50);
                if (pos == null) continue;

                int tier = SimRng.RollRange(state, 0, Math.Min(config.MaxTier, EnemyKindsByTier.Length - 1));
                string kind = EnemyKindsByTier[tier];

                state.RoamingEnemies.Add(new Dictionary<string, object>
                {
                    ["id"] = state.EnemyNextId++,
                    ["kind"] = kind,
                    ["pos"] = pos.Value,
                    ["hp"] = 3 + tier * 2,
                    ["tier"] = tier,
                    ["zone"] = config.Zone,
                    ["patrol_origin"] = pos.Value,
                });
            }
        }
    }

    private static void PopulateNpcs(GameState state)
    {
        // Place NPCs near the safe zone (close to castle)
        foreach (string npcType in NpcTypes)
        {
            var pos = FindValidPositionInZone(state, SimMap.ZoneSafe, 30);
            if (pos == null) continue;

            state.Npcs.Add(new Dictionary<string, object>
            {
                ["type"] = npcType,
                ["pos"] = pos.Value,
                ["name"] = GetNpcName(npcType),
                ["quest_available"] = true,
            });
        }
    }

    /// <summary>Move roaming enemies around their patrol area each world tick.</summary>
    public static void TickEntityMovement(GameState state)
    {
        foreach (var enemy in state.RoamingEnemies)
        {
            if (enemy.GetValueOrDefault("pos") is not GridPoint pos) continue;

            // 30% chance to move each tick
            if (SimRng.RollRange(state, 1, 100) > 30) continue;

            // Pick random direction
            int dir = SimRng.RollRange(state, 0, 3);
            var delta = dir switch
            {
                0 => new GridPoint(1, 0),
                1 => new GridPoint(-1, 0),
                2 => new GridPoint(0, 1),
                _ => new GridPoint(0, -1),
            };

            var newPos = pos + delta;

            // Stay in bounds and on passable terrain
            if (!SimMap.InBounds(newPos.X, newPos.Y, state.MapW, state.MapH)) continue;
            if (!SimMap.IsPassable(state, newPos)) continue;

            // Don't move onto the castle
            if (newPos == state.BasePos) continue;

            // Stay within patrol range (8 tiles from origin)
            if (enemy.GetValueOrDefault("patrol_origin") is GridPoint origin)
            {
                if (origin.ManhattanDistance(newPos) > 8) continue;
            }

            enemy["pos"] = newPos;
        }
    }

    /// <summary>Get all entities (enemies + NPCs + resource nodes) near a position.</summary>
    public static List<Dictionary<string, object>> GetEntitiesNear(GameState state, GridPoint pos, int radius)
    {
        var results = new List<Dictionary<string, object>>();

        foreach (var enemy in state.RoamingEnemies)
        {
            if (enemy.GetValueOrDefault("pos") is GridPoint ePos && ePos.ManhattanDistance(pos) <= radius)
            {
                var entry = new Dictionary<string, object>(enemy) { ["entity_type"] = "enemy" };
                results.Add(entry);
            }
        }

        foreach (var npc in state.Npcs)
        {
            if (npc.GetValueOrDefault("pos") is GridPoint nPos && nPos.ManhattanDistance(pos) <= radius)
            {
                var entry = new Dictionary<string, object>(npc) { ["entity_type"] = "npc" };
                results.Add(entry);
            }
        }

        foreach (var (idx, node) in state.ResourceNodes)
        {
            if (node.GetValueOrDefault("pos") is GridPoint rPos && rPos.ManhattanDistance(pos) <= radius)
            {
                var entry = new Dictionary<string, object>(node) { ["entity_type"] = "resource", ["index"] = idx };
                results.Add(entry);
            }
        }

        return results;
    }

    private static GridPoint? FindValidPositionInZone(GameState state, string targetZone, int maxAttempts)
    {
        for (int attempt = 0; attempt < maxAttempts; attempt++)
        {
            int x = SimRng.RollRange(state, 1, state.MapW - 2);
            int y = SimRng.RollRange(state, 1, state.MapH - 2);
            var pos = new GridPoint(x, y);

            string zone = SimMap.GetZoneAt(state, pos);
            if (zone != targetZone) continue;

            SimMap.EnsureTileGenerated(state, pos);
            if (!SimMap.IsPassable(state, pos)) continue;
            if (pos == state.BasePos) continue;

            return pos;
        }
        return null;
    }

    private static string GetNpcName(string npcType) => npcType switch
    {
        "trainer" => "Master Galen",
        "merchant" => "Merchant Adira",
        "quest_giver" => "Quartermaster Torin",
        _ => npcType,
    };
}
