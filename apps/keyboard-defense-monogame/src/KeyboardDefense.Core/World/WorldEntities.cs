using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Core.World;

/// <summary>
/// Populates and manages world entities: resource nodes, roaming enemies, NPCs, POIs.
/// </summary>
public static class WorldEntities
{
    private static readonly string[] ResourceNodeTypes = { "wood_grove", "stone_quarry", "food_garden", "gold_vein" };
    private static readonly string[] AdvancedResourceTypes = { "herb_patch", "iron_deposit", "pine_forest", "crystal_cave" };
    private static readonly string[] EnemyKindsByTier = { "scout", "raider", "armored", "berserker", "elite" };
    private static readonly string[] NpcTypes = { "trainer", "merchant", "quest_giver" };

    /// <summary>Seeds the world with resource nodes, roaming enemies, and NPCs.</summary>
    public static void PopulateWorld(GameState state, Dictionary<string, GridPoint>? specPois = null)
    {
        PopulateResourceNodes(state);
        PopulateRoamingEnemies(state);
        PopulateNpcs(state);
        PopulatePois(state, specPois);
    }

    private static void PopulateResourceNodes(GameState state)
    {
        // Place resource nodes per zone — more nodes and variety in outer zones
        var zoneConfigs = new[]
        {
            (Zone: SimMap.ZoneSafe, Min: 5, Max: 8, UseAdvanced: false),
            (Zone: SimMap.ZoneFrontier, Min: 6, Max: 10, UseAdvanced: true),
            (Zone: SimMap.ZoneWilderness, Min: 6, Max: 10, UseAdvanced: true),
            (Zone: SimMap.ZoneDepths, Min: 3, Max: 5, UseAdvanced: true),
        };

        foreach (var config in zoneConfigs)
        {
            int count = SimRng.RollRange(state, config.Min, config.Max);
            for (int i = 0; i < count; i++)
            {
                var pos = FindValidPositionInZone(state, config.Zone, 50);
                if (pos == null) continue;

                int idx = SimMap.Idx(pos.Value.X, pos.Value.Y, state.MapW);
                if (state.ResourceNodes.ContainsKey(idx)) continue;

                // Mix in advanced resource types for outer zones
                string nodeType;
                if (config.UseAdvanced && SimRng.RollRange(state, 1, 100) <= 35)
                    nodeType = AdvancedResourceTypes[SimRng.RollRange(state, 0, AdvancedResourceTypes.Length - 1)];
                else
                    nodeType = ResourceNodeTypes[SimRng.RollRange(state, 0, ResourceNodeTypes.Length - 1)];

                state.ResourceNodes[idx] = new Dictionary<string, object>
                {
                    ["type"] = nodeType,
                    ["pos"] = pos.Value,
                    ["zone"] = config.Zone,
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
        // Core NPCs near the castle (Safe Zone)
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
                ["facing"] = "south",
            });
        }

        // Outpost NPCs in outer zones for exploration reward
        var outpostNpcs = new[]
        {
            (Type: "merchant", Zone: SimMap.ZoneFrontier, Name: "Wandering Eli"),
            (Type: "trainer", Zone: SimMap.ZoneFrontier, Name: "Battlemaster Kira"),
            (Type: "quest_giver", Zone: SimMap.ZoneWilderness, Name: "Ranger Selene"),
            (Type: "merchant", Zone: SimMap.ZoneWilderness, Name: "Relic Dealer Voss"),
            (Type: "trainer", Zone: SimMap.ZoneDepths, Name: "Sage Ophira"),
            (Type: "quest_giver", Zone: SimMap.ZoneDepths, Name: "The Cartographer"),
        };

        foreach (var npcDef in outpostNpcs)
        {
            var pos = FindValidPositionInZone(state, npcDef.Zone, 40);
            if (pos == null) continue;

            state.Npcs.Add(new Dictionary<string, object>
            {
                ["type"] = npcDef.Type,
                ["pos"] = pos.Value,
                ["name"] = npcDef.Name,
                ["quest_available"] = true,
                ["facing"] = "south",
                ["zone"] = npcDef.Zone,
            });
        }
    }

    private static void PopulatePois(GameState state, Dictionary<string, GridPoint>? specPois = null)
    {
        // When spec POIs are available, place them at fixed coordinates
        if (specPois != null && specPois.Count > 0)
        {
            // Map spec POI names to game POI types
            var specToPoiType = new Dictionary<string, string>
            {
                ["shrine"] = "shrine",
                ["camp"] = "campsite",
                ["outpost"] = "watchtower",
                ["ruins"] = "forge",
                ["watchtower"] = "watchtower",
                ["mine"] = "mine",
                ["shore"] = "bridge",
            };

            foreach (var (specName, pos) in specPois)
            {
                if (!SimMap.InBounds(pos.X, pos.Y, state.MapW, state.MapH)) continue;
                string poiId = specToPoiType.GetValueOrDefault(specName, specName);
                string zone = SimMap.GetZoneAt(state, pos);
                Poi.SpawnPoi(state, poiId, pos, new Dictionary<string, object>
                {
                    ["zone"] = zone,
                    ["event_id"] = $"poi_{poiId}",
                    ["spec_name"] = specName,
                });
            }
            return;
        }

        // Guaranteed POI landmarks per zone
        var guaranteedPois = new[]
        {
            // Safe Zone — peaceful landmarks
            (Id: "shrine", Zone: SimMap.ZoneSafe),
            (Id: "well", Zone: SimMap.ZoneSafe),
            (Id: "signpost", Zone: SimMap.ZoneSafe),

            // Frontier — outpost landmarks
            (Id: "watchtower", Zone: SimMap.ZoneFrontier),
            (Id: "campfire", Zone: SimMap.ZoneFrontier),
            (Id: "bridge", Zone: SimMap.ZoneFrontier),
            (Id: "training_dummy", Zone: SimMap.ZoneFrontier),

            // Wilderness — exploration landmarks
            (Id: "campsite", Zone: SimMap.ZoneWilderness),
            (Id: "mine", Zone: SimMap.ZoneWilderness),
            (Id: "market", Zone: SimMap.ZoneWilderness),

            // Depths — dangerous landmarks
            (Id: "forge", Zone: SimMap.ZoneDepths),
            (Id: "arena", Zone: SimMap.ZoneDepths),
        };

        foreach (var placement in guaranteedPois)
        {
            var pos = FindValidPositionInZone(state, placement.Zone, 40);
            if (pos == null) continue;

            Poi.SpawnPoi(state, placement.Id, pos.Value, new Dictionary<string, object>
            {
                ["zone"] = placement.Zone,
                ["event_id"] = $"poi_{placement.Id}",
            });
        }

        // Random bonus POIs per zone (2-3 extra per zone for variety)
        string[][] zoneBonusPois =
        {
            new[] { "well", "signpost" },                           // Safe
            new[] { "campfire", "signpost", "bridge" },             // Frontier
            new[] { "campsite", "campfire", "mine", "market" },     // Wilderness
            new[] { "campfire", "mine", "forge" },                  // Depths
        };
        string[] zones = { SimMap.ZoneSafe, SimMap.ZoneFrontier, SimMap.ZoneWilderness, SimMap.ZoneDepths };

        for (int z = 0; z < zones.Length; z++)
        {
            int bonusCount = SimRng.RollRange(state, 2, 3);
            for (int i = 0; i < bonusCount; i++)
            {
                var pos = FindValidPositionInZone(state, zones[z], 40);
                if (pos == null) continue;

                string poiId = zoneBonusPois[z][SimRng.RollRange(state, 0, zoneBonusPois[z].Length - 1)];
                string uniqueId = $"{poiId}_{z}_{i}";

                Poi.SpawnPoi(state, uniqueId, pos.Value, new Dictionary<string, object>
                {
                    ["zone"] = zones[z],
                    ["event_id"] = $"poi_{poiId}",
                    ["display_name"] = poiId.Replace('_', ' '),
                });
            }
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
