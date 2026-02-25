using System;
using System.IO;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Core.State;

/// <summary>
/// Creates default initial game state.
/// Ported from sim/default_state.gd.
/// </summary>
public static class DefaultState
{
    /// <summary>
    /// Creates a freshly initialized game state and populates world data for a new run.
    /// State creation transitions from constructor defaults into either spec-driven or procedural world setup.
    /// </summary>
    /// <param name="seed">Random seed string used to initialize deterministic state.</param>
    /// <param name="placeStartingTowers">If set, places starter auto-towers around the base.</param>
    /// <param name="useWorldSpec">If set, attempts to load and apply the world specification file.</param>
    /// <returns>A fully initialized <see cref="GameState"/>.</returns>
    public static GameState Create(string seed = "default", bool placeStartingTowers = false, bool useWorldSpec = false)
    {
        var state = new GameState();
        SimRng.SeedState(state, seed);
        state.LessonId = LessonsData.DefaultLessonId();

        // Reset biome generator for new seed
        SimMap.ResetBiomeGenerator();

        // Try spec-driven world when explicitly requested
        string? specPath = useWorldSpec ? FindSpecPath() : null;
        bool specLoaded = specPath != null && WorldSpecLoader.PopulateFromSpec(state, specPath);

        if (specLoaded)
        {
            // Place base inland on meadow terrain
            state.BasePos = new GridPoint(60, 54);
            state.PlayerPos = state.BasePos;
            state.CursorPos = state.BasePos;

            // Larger discover radius for bigger map
            DiscoverStartingArea(state, 12);
        }
        else
        {
            // Fallback: procedural terrain on default 32x32 grid
            SimMap.GenerateTerrain(state);
            DiscoverStartingArea(state, 5);
        }

        // Ensure castle is on plains
        int baseIndex = SimMap.Idx(state.BasePos.X, state.BasePos.Y, state.MapW);
        state.Terrain[baseIndex] = SimMap.TerrainPlains;

        // Starting resources
        state.Gold = 10;

        // Populate world with resource nodes, roaming enemies, NPCs
        if (specLoaded)
        {
            var pois = WorldSpecLoader.GetPoiPositions(specPath!);
            WorldEntities.PopulateWorld(state, pois);
        }
        else
        {
            WorldEntities.PopulateWorld(state);
        }

        // Optionally place starting auto-towers near base
        if (placeStartingTowers)
            PlaceStartingTowers(state);

        return state;
    }

    /// <summary>
    /// Locates the world specification file from runtime data output.
    /// </summary>
    /// <returns>The full path when found; otherwise <see langword="null"/>.</returns>
    private static string? FindSpecPath()
    {
        // Check data/ directory (copied to output by build)
        string dataPath = Path.Combine(AppContext.BaseDirectory, "data", "world_spec.json");
        if (File.Exists(dataPath)) return dataPath;
        return null;
    }

    /// <summary>
    /// Marks and generates tiles in the initial discovery radius around the base.
    /// </summary>
    /// <param name="state">The game state to mutate.</param>
    /// <param name="radius">The discovery radius in tiles.</param>
    private static void DiscoverStartingArea(GameState state, int radius)
    {
        for (int dy = -radius; dy <= radius; dy++)
        {
            for (int dx = -radius; dx <= radius; dx++)
            {
                var pos = new GridPoint(state.BasePos.X + dx, state.BasePos.Y + dy);
                if (SimMap.InBounds(pos.X, pos.Y, state.MapW, state.MapH))
                {
                    int idx = SimMap.Idx(pos.X, pos.Y, state.MapW);
                    state.Discovered.Add(idx);
                    SimMap.EnsureTileGenerated(state, pos);
                }
            }
        }
    }

    /// <summary>
    /// Places predefined starter tower structures adjacent to the base position.
    /// </summary>
    /// <param name="state">The game state to mutate.</param>
    private static void PlaceStartingTowers(GameState state)
    {
        var basePos = state.BasePos;
        var towerPositions = new GridPoint[]
        {
            new(basePos.X - 1, basePos.Y),
            new(basePos.X + 1, basePos.Y),
        };
        var towerTypes = new[] { "auto_sentry", "auto_spark" };

        for (int i = 0; i < towerPositions.Length; i++)
        {
            var pos = towerPositions[i];
            if (!SimMap.InBounds(pos.X, pos.Y, state.MapW, state.MapH))
                continue;
            int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
            if (state.Terrain[index] == SimMap.TerrainWater)
                state.Terrain[index] = SimMap.TerrainPlains;
            state.Structures[index] = towerTypes[i];
        }
    }
}
