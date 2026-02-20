using System;
using System.Collections.Generic;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Economy;

/// <summary>
/// Worker assignment and production bonuses.
/// Ported from sim/workers.gd.
/// </summary>
public static class Workers
{
    public const double BaseWorkerBonus = 0.25;

    public static int WorkersAt(GameState state, int structureIndex)
    {
        return state.WorkerAssignments.GetValueOrDefault(structureIndex, 0);
    }

    public static bool AssignWorker(GameState state, int structureIndex)
    {
        if (!state.Structures.ContainsKey(structureIndex)) return false;
        int totalAssigned = 0;
        foreach (var count in state.WorkerAssignments.Values)
            totalAssigned += count;
        if (totalAssigned >= state.WorkerCount) return false;

        state.WorkerAssignments[structureIndex] =
            state.WorkerAssignments.GetValueOrDefault(structureIndex, 0) + 1;
        return true;
    }

    public static bool UnassignWorker(GameState state, int structureIndex)
    {
        int current = WorkersAt(state, structureIndex);
        if (current <= 0) return false;
        state.WorkerAssignments[structureIndex] = current - 1;
        if (state.WorkerAssignments[structureIndex] == 0)
            state.WorkerAssignments.Remove(structureIndex);
        return true;
    }

    public static double WorkerBonus(GameState state, int structureIndex)
    {
        int workers = WorkersAt(state, structureIndex);
        if (workers <= 0) return 1.0;
        return 1.0 + workers * BaseWorkerBonus;
    }

    public static int GetAvailableWorkers(GameState state)
    {
        int totalAssigned = 0;
        foreach (var count in state.WorkerAssignments.Values)
            totalAssigned += count;
        return Math.Max(0, state.WorkerCount - totalAssigned);
    }
}
