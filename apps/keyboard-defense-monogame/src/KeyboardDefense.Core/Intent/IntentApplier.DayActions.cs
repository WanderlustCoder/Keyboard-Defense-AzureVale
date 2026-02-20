using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Balance;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Core.Intent;

public static partial class IntentApplier
{
    private static void ApplyGather(GameState state, Dictionary<string, object> intent, List<string> events)
    {
        if (!RequireDay(state, events)) return;
        if (!ConsumeAp(state, events)) return;
        string resource = intent.GetValueOrDefault("resource")?.ToString() ?? "";
        int baseAmount = Convert.ToInt32(intent.GetValueOrDefault("amount", 0));
        if (!state.Resources.ContainsKey(resource) || baseAmount <= 0)
        {
            events.Add("Invalid gather request.");
            return;
        }
        int amount = baseAmount;
        state.Resources[resource] = state.Resources.GetValueOrDefault(resource, 0) + amount;
        events.Add($"Gathered {amount} {resource}.");
        events.Add(FormatStatus(state));
    }

    private static void ApplyBuild(GameState state, Dictionary<string, object> intent, List<string> events)
    {
        if (!RequireDay(state, events)) return;
        string buildingType = intent.GetValueOrDefault("building")?.ToString() ?? "";
        if (!BuildingsData.IsValid(buildingType))
        {
            events.Add($"Unknown build type: {buildingType}");
            return;
        }
        var pos = IntentPosition(state, intent);
        if (!SimMap.InBounds(pos.X, pos.Y, state.MapW, state.MapH))
        {
            events.Add("Build location out of bounds.");
            return;
        }
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        if (!state.Discovered.Contains(index))
        {
            events.Add("That tile is not discovered yet.");
            return;
        }
        if (pos.X == state.BasePos.X && pos.Y == state.BasePos.Y)
        {
            events.Add("Cannot build on the base tile.");
            return;
        }
        if (state.Structures.ContainsKey(index))
        {
            events.Add("That tile is already occupied.");
            return;
        }
        if (SimMap.GetTerrain(state, pos) == SimMap.TerrainWater)
        {
            events.Add("Cannot build on water.");
            return;
        }
        var cost = BuildingsData.CostFor(buildingType);
        if (!HasResources(state, cost))
        {
            events.Add($"Not enough resources to build {buildingType}.");
            return;
        }
        if (!ConsumeAp(state, events)) return;
        ApplyCost(state, cost);
        state.Structures[index] = buildingType;
        state.StructureLevels[index] = 1;
        state.Buildings[buildingType] = state.Buildings.GetValueOrDefault(buildingType, 0) + 1;
        events.Add($"Built {buildingType} at ({pos.X},{pos.Y}).");
        events.Add(FormatStatus(state));
    }

    private static void ApplyExplore(GameState state, List<string> events)
    {
        if (!RequireDay(state, events)) return;
        if (!ConsumeAp(state, events)) return;
        int tileIndex = PickExploreTile(state);
        if (tileIndex < 0)
        {
            events.Add("No new tiles to discover.");
            return;
        }
        state.Discovered.Add(tileIndex);
        var pos = GridPoint.FromIndex(tileIndex, state.MapW);
        SimMap.EnsureTileGenerated(state, pos);
        string terrain = SimMap.GetTerrain(state, pos);
        state.Threat += 1;
        events.Add($"Discovered tile ({pos.X},{pos.Y}): {terrain}.");
        events.Add(FormatStatus(state));
    }

    private static bool ApplyEnd(GameState state, List<string> events)
    {
        if (!RequireDay(state, events)) return false;
        state.Phase = "night";
        state.Ap = 0;
        int defense = BuildingsData.TotalDefense(state);
        int waveTotal = SimBalance.CalculateWaveSize(state.Day, state.Threat);
        state.NightWaveTotal = waveTotal;
        state.NightSpawnRemaining = waveTotal;
        state.Enemies.Clear();
        state.NightPrompt = "";
        state.LastPathOpen = SimMap.PathOpenToBase(state);
        if (!state.LastPathOpen)
            state.NightWaveTotal = Math.Max(1, state.NightWaveTotal - 2);

        // Boss spawn on milestone days
        if (IsBossDay(state.Day))
        {
            string bossKind = GetBossForDay(state.Day);
            var bossPos = SimMap.GetSpawnPos(state);
            string bossWord = WordPool.WordForEnemy(state.RngSeed, state.Day, bossKind, state.EnemyNextId, new HashSet<string>(), state.LessonId);
            var boss = Enemies.MakeBoss(state, bossKind, bossPos, bossWord, state.Day);
            state.Enemies.Add(boss);
            events.Add($"BOSS ENCOUNTER: {bossKind.Replace("_", " ")} appears!");
        }

        events.Add($"Night falls. Enemy wave: {state.NightWaveTotal}.");
        if (!state.LastPathOpen)
            events.Add("Walls slow the enemy. Night shortened.");
        return true;
    }

    private static void ApplyDemolish(GameState state, Dictionary<string, object> intent, List<string> events)
    {
        if (!RequireDay(state, events)) return;
        var pos = IntentPosition(state, intent);
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        if (!state.Structures.ContainsKey(index))
        {
            events.Add("No structure at that location.");
            return;
        }
        string structureType = state.Structures[index];
        state.Structures.Remove(index);
        state.StructureLevels.Remove(index);
        if (state.Buildings.ContainsKey(structureType))
        {
            state.Buildings[structureType] = Math.Max(0, state.Buildings[structureType] - 1);
            if (state.Buildings[structureType] == 0)
                state.Buildings.Remove(structureType);
        }
        events.Add($"Demolished {structureType} at ({pos.X},{pos.Y}).");
    }

    private static void ApplyUpgradeStructure(GameState state, Dictionary<string, object> intent, List<string> events)
    {
        if (!RequireDay(state, events)) return;
        var pos = IntentPosition(state, intent);
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        if (!state.Structures.ContainsKey(index))
        {
            events.Add("No structure at that location to upgrade.");
            return;
        }
        int currentLevel = state.StructureLevels.GetValueOrDefault(index, 1);
        int upgradeCost = currentLevel * 5;
        if (state.Gold < upgradeCost)
        {
            events.Add($"Need {upgradeCost} gold to upgrade (have {state.Gold}).");
            return;
        }
        if (!ConsumeAp(state, events)) return;
        state.Gold -= upgradeCost;
        state.StructureLevels[index] = currentLevel + 1;
        events.Add($"Upgraded {state.Structures[index]} to level {currentLevel + 1} for {upgradeCost} gold.");
    }

    // --- Boss helpers ---
    private static bool IsBossDay(int day) => day == 7 || day == 14 || day == 21;

    private static string GetBossForDay(int day) => day switch
    {
        7 => "forest_guardian",
        14 => "stone_golem",
        21 => "sunlord",
        _ => "forest_guardian",
    };

    // --- Exploration helper ---
    private static int PickExploreTile(GameState state)
    {
        // Find undiscovered tile adjacent to discovered tiles
        var candidates = new List<int>();
        int[] offsets = { -1, 1, -state.MapW, state.MapW };
        foreach (int discovered in state.Discovered)
        {
            foreach (int offset in offsets)
            {
                int neighbor = discovered + offset;
                if (neighbor >= 0 && neighbor < state.MapW * state.MapH && !state.Discovered.Contains(neighbor))
                    candidates.Add(neighbor);
            }
        }
        if (candidates.Count == 0) return -1;
        return candidates[SimRng.RollRange(state, 0, candidates.Count - 1)];
    }
}
