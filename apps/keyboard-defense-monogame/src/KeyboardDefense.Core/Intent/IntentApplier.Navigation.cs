using System;
using System.Collections.Generic;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Core.Intent;

public static partial class IntentApplier
{
    private static void ApplyCursor(GameState state, Dictionary<string, object> intent, List<string> events)
    {
        int x = Convert.ToInt32(intent.GetValueOrDefault("x", 0));
        int y = Convert.ToInt32(intent.GetValueOrDefault("y", 0));
        if (!SimMap.InBounds(x, y, state.MapW, state.MapH))
        {
            events.Add("Cursor position out of bounds.");
            return;
        }
        state.CursorPos = new GridPoint(x, y);
        events.Add($"Cursor moved to ({x},{y}).");
    }

    private static void ApplyCursorMove(GameState state, Dictionary<string, object> intent, List<string> events)
    {
        int dx = Convert.ToInt32(intent.GetValueOrDefault("dx", 0));
        int dy = Convert.ToInt32(intent.GetValueOrDefault("dy", 0));
        int steps = Convert.ToInt32(intent.GetValueOrDefault("steps", 1));
        int newX = state.CursorPos.X + dx * steps;
        int newY = state.CursorPos.Y + dy * steps;
        newX = Math.Clamp(newX, 0, state.MapW - 1);
        newY = Math.Clamp(newY, 0, state.MapH - 1);
        state.CursorPos = new GridPoint(newX, newY);
        events.Add($"Cursor at ({newX},{newY}).");
    }

    private static void ApplyInspect(GameState state, Dictionary<string, object> intent, List<string> events)
    {
        var pos = IntentPosition(state, intent);
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        if (!state.Discovered.Contains(index))
        {
            events.Add($"Tile ({pos.X},{pos.Y}) is not discovered.");
            return;
        }
        string terrain = SimMap.GetTerrain(state, pos);
        string structure = state.Structures.GetValueOrDefault(index, "none");
        int level = state.StructureLevels.GetValueOrDefault(index, 0);
        events.Add($"Tile ({pos.X},{pos.Y}): {terrain}");
        if (structure != "none")
            events.Add($"  Structure: {structure} (level {level})");
    }

    private static void ApplyInspectTile(GameState state, List<string> events)
    {
        var pos = state.CursorPos;
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        if (!state.Discovered.Contains(index))
        {
            events.Add($"Tile ({pos.X},{pos.Y}) is undiscovered.");
            return;
        }
        string terrain = SimMap.GetTerrain(state, pos);
        events.Add($"You see: {terrain} at ({pos.X},{pos.Y}).");
        if (state.Structures.TryGetValue(index, out string? structure))
            events.Add($"  Structure: {structure}");
    }

    private static void ApplyMap(GameState state, List<string> events)
    {
        int discovered = state.Discovered.Count;
        int total = state.MapW * state.MapH;
        int structures = state.Structures.Count;
        events.Add($"Map: {state.MapW}x{state.MapH} ({discovered}/{total} tiles discovered)");
        events.Add($"  Structures: {structures} | Base: ({state.BasePos.X},{state.BasePos.Y})");
        events.Add($"  Cursor: ({state.CursorPos.X},{state.CursorPos.Y})");
    }

    private static void ApplyZoneShow(GameState state, List<string> events)
    {
        events.Add("Zone view: showing map regions.");
    }

    private static void ApplyZoneSummary(GameState state, List<string> events)
    {
        events.Add($"Zone summary: {state.Discovered.Count} tiles discovered across the kingdom.");
    }

    private static void ApplyMovePlayer(GameState state, Dictionary<string, object> intent, List<string> events)
    {
        int dx = Convert.ToInt32(intent.GetValueOrDefault("dx", 0));
        int dy = Convert.ToInt32(intent.GetValueOrDefault("dy", 0));
        int newX = state.PlayerPos.X + dx;
        int newY = state.PlayerPos.Y + dy;

        // Update facing regardless of passability
        if (dx < 0) state.PlayerFacing = "left";
        else if (dx > 0) state.PlayerFacing = "right";
        else if (dy < 0) state.PlayerFacing = "up";
        else if (dy > 0) state.PlayerFacing = "down";

        // Validate bounds
        if (!SimMap.InBounds(newX, newY, state.MapW, state.MapH))
        {
            events.Add("You can't go that way.");
            return;
        }

        // Validate passability
        var newPos = new GridPoint(newX, newY);
        if (!SimMap.IsPassable(state, newPos))
        {
            string terrain = SimMap.GetTerrain(state, newPos);
            events.Add($"Blocked by {terrain}.");
            return;
        }

        // Move player
        state.PlayerPos = newPos;
        state.CursorPos = newPos; // Keep cursor synced with player

        // Discover tiles in radius around player
        const int discoverRadius = 3;
        for (int ry = -discoverRadius; ry <= discoverRadius; ry++)
        {
            for (int rx = -discoverRadius; rx <= discoverRadius; rx++)
            {
                int tx = newX + rx;
                int ty = newY + ry;
                if (SimMap.InBounds(tx, ty, state.MapW, state.MapH))
                {
                    int idx = SimMap.Idx(tx, ty, state.MapW);
                    if (!state.Discovered.Contains(idx))
                    {
                        state.Discovered.Add(idx);
                        SimMap.EnsureTileGenerated(state, new GridPoint(tx, ty));
                    }
                }
            }
        }
    }
}
