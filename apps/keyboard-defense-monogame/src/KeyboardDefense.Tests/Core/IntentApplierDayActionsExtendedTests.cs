using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Extended tests for IntentApplier day actions — Gather edge cases, Build validation
/// (base tile, occupied, mountain, resource cost), Demolish/Upgrade edge cases,
/// Explore when all discovered, End with boss spawns, IsBossDay/GetBossForDay,
/// and multi-action AP tracking.
/// </summary>
public class IntentApplierDayActionsExtendedTests
{
    // =========================================================================
    // Gather — edge cases
    // =========================================================================

    [Fact]
    public void Gather_DuringNight_Rejected()
    {
        var state = CreateState();
        state.Phase = "night";

        var (newState, events, _) = Apply(state, "gather", new()
        {
            ["resource"] = "wood",
            ["amount"] = 5,
        });

        Assert.Contains(events, e => e.Contains("only available during the day")
                                     || e.Contains("Day action"));
    }

    [Fact]
    public void Gather_ValidResource_IncreasesResourceAndConsumesAp()
    {
        var state = CreateState();
        state.Ap = 3;
        state.Resources["wood"] = 5;

        var (newState, events, _) = Apply(state, "gather", new()
        {
            ["resource"] = "wood",
            ["amount"] = 3,
        });

        Assert.Equal(8, newState.Resources["wood"]);
        Assert.Equal(2, newState.Ap);
        Assert.Contains(events, e => e.Contains("Gathered 3 wood"));
    }

    [Fact]
    public void Gather_InvalidResource_DoesNotChangeState()
    {
        var state = CreateState();
        state.Ap = 3;

        var (newState, events, _) = Apply(state, "gather", new()
        {
            ["resource"] = "mithril",
            ["amount"] = 5,
        });

        Assert.Contains("Invalid gather request.", events);
    }

    [Fact]
    public void Gather_ZeroAmount_ReturnsInvalidRequest()
    {
        var state = CreateState();
        state.Ap = 3;

        var (_, events, _) = Apply(state, "gather", new()
        {
            ["resource"] = "wood",
            ["amount"] = 0,
        });

        Assert.Contains("Invalid gather request.", events);
    }

    [Fact]
    public void Gather_NoAp_ReturnsNoApMessage()
    {
        var state = CreateState();
        state.Ap = 0;

        var (_, events, _) = Apply(state, "gather", new()
        {
            ["resource"] = "wood",
            ["amount"] = 3,
        });

        Assert.Contains("No action points remaining. Type 'end' to start the night.", events);
    }

    // =========================================================================
    // Build — extended validation
    // =========================================================================

    [Fact]
    public void Build_OnBaseTile_RejectedWithoutConsumingAp()
    {
        LoadBuildingsData();
        var state = CreateState();
        state.Ap = 3;
        int apBefore = state.Ap;

        var (newState, events, _) = Apply(state, "build", new()
        {
            ["building"] = "tower",
            ["x"] = state.BasePos.X,
            ["y"] = state.BasePos.Y,
        });

        Assert.Equal(apBefore, newState.Ap);
        Assert.Contains("Cannot build on the base tile.", events);
    }

    [Fact]
    public void Build_OnOccupiedTile_RejectedWithoutConsumingAp()
    {
        LoadBuildingsData();
        var state = CreateState();
        var pos = PrepareBuildableTile(state, 1, 0);
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        state.Structures[index] = "wall";
        int apBefore = state.Ap;

        var (newState, events, _) = Apply(state, "build", new()
        {
            ["building"] = "tower",
            ["x"] = pos.X,
            ["y"] = pos.Y,
        });

        Assert.Equal(apBefore, newState.Ap);
        Assert.Contains("That tile is already occupied.", events);
    }

    [Fact]
    public void Build_OnMountain_RejectedWithoutConsumingAp()
    {
        LoadBuildingsData();
        var state = CreateState();
        var pos = PrepareBuildableTile(state, 1, 0);
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        state.Terrain[index] = SimMap.TerrainMountain;
        int apBefore = state.Ap;

        var (newState, events, _) = Apply(state, "build", new()
        {
            ["building"] = "tower",
            ["x"] = pos.X,
            ["y"] = pos.Y,
        });

        Assert.Equal(apBefore, newState.Ap);
        Assert.Contains("Cannot build on mountain.", events);
    }

    [Fact]
    public void Build_UnknownBuildingType_Rejected()
    {
        LoadBuildingsData();
        var state = CreateState();
        int apBefore = state.Ap;

        var (newState, events, _) = Apply(state, "build", new()
        {
            ["building"] = "laser_cannon",
            ["x"] = 0,
            ["y"] = 0,
        });

        Assert.Contains(events, e => e.Contains("Unknown build type"));
        Assert.Equal(apBefore, newState.Ap);
    }

    [Fact]
    public void Build_OutOfBounds_Rejected()
    {
        LoadBuildingsData();
        var state = CreateState();
        int apBefore = state.Ap;

        var (newState, events, _) = Apply(state, "build", new()
        {
            ["building"] = "tower",
            ["x"] = -1,
            ["y"] = -1,
        });

        Assert.Contains("Build location out of bounds.", events);
        Assert.Equal(apBefore, newState.Ap);
    }

    [Fact]
    public void Build_NotEnoughResources_Rejected()
    {
        LoadBuildingsData();
        var state = CreateState();
        var pos = PrepareBuildableTile(state, 1, 0);
        state.Resources["wood"] = 0;
        state.Resources["stone"] = 0;
        int apBefore = state.Ap;

        var (newState, events, _) = Apply(state, "build", new()
        {
            ["building"] = "tower",
            ["x"] = pos.X,
            ["y"] = pos.Y,
        });

        Assert.Contains(events, e => e.Contains("Not enough resources"));
        Assert.Equal(apBefore, newState.Ap);
    }

    [Fact]
    public void Build_Success_IncrementsBuildings()
    {
        LoadBuildingsData();
        var state = CreateState();
        var pos = PrepareBuildableTile(state, 1, 0);
        state.Resources["wood"] = 200;
        state.Resources["stone"] = 200;
        int countBefore = state.Buildings.GetValueOrDefault("tower", 0);

        var (newState, _, _) = Apply(state, "build", new()
        {
            ["building"] = "tower",
            ["x"] = pos.X,
            ["y"] = pos.Y,
        });

        Assert.Equal(countBefore + 1, newState.Buildings.GetValueOrDefault("tower", 0));
    }

    [Fact]
    public void Build_Success_SetsStructureLevel1()
    {
        LoadBuildingsData();
        var state = CreateState();
        var pos = PrepareBuildableTile(state, 1, 0);
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        state.Resources["wood"] = 200;
        state.Resources["stone"] = 200;

        var (newState, _, _) = Apply(state, "build", new()
        {
            ["building"] = "tower",
            ["x"] = pos.X,
            ["y"] = pos.Y,
        });

        Assert.Equal(1, newState.StructureLevels[index]);
    }

    // =========================================================================
    // Demolish — extended edge cases
    // =========================================================================

    [Fact]
    public void Demolish_ValidStructure_RemovesAndDecrementsBuildingCount()
    {
        var state = CreateState();
        var pos = PrepareBuildableTile(state, 1, 0);
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        state.Structures[index] = "tower";
        state.StructureLevels[index] = 2;
        state.Buildings["tower"] = 3;

        var (newState, events, _) = Apply(state, "demolish", new()
        {
            ["x"] = pos.X,
            ["y"] = pos.Y,
        });

        Assert.False(newState.Structures.ContainsKey(index));
        Assert.False(newState.StructureLevels.ContainsKey(index));
        Assert.Equal(2, newState.Buildings["tower"]);
        Assert.Contains(events, e => e.Contains("Demolished tower"));
    }

    [Fact]
    public void Demolish_NoStructure_ReturnsError()
    {
        var state = CreateState();
        var pos = PrepareBuildableTile(state, 1, 0);
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        state.Structures.Remove(index);

        var (_, events, _) = Apply(state, "demolish", new()
        {
            ["x"] = pos.X,
            ["y"] = pos.Y,
        });

        Assert.Contains("No structure at that location.", events);
    }

    [Fact]
    public void Demolish_LastBuildingOfType_RemovesBuildingKey()
    {
        var state = CreateState();
        var pos = PrepareBuildableTile(state, 1, 0);
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        state.Structures[index] = "wall";
        state.Buildings["wall"] = 1;

        var (newState, _, _) = Apply(state, "demolish", new()
        {
            ["x"] = pos.X,
            ["y"] = pos.Y,
        });

        Assert.False(newState.Buildings.ContainsKey("wall"));
    }

    [Fact]
    public void Demolish_DuringNight_Rejected()
    {
        var state = CreateState();
        state.Phase = "night";

        var (_, events, _) = Apply(state, "demolish", new()
        {
            ["x"] = 0,
            ["y"] = 0,
        });

        Assert.Contains(events, e => e.Contains("only available during the day")
                                     || e.Contains("Day action"));
    }

    // =========================================================================
    // Upgrade — edge cases
    // =========================================================================

    [Fact]
    public void Upgrade_ValidStructure_IncrementsLevelAndChargesGold()
    {
        var state = CreateState();
        var pos = PrepareBuildableTile(state, 1, 0);
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        state.Structures[index] = "tower";
        state.StructureLevels[index] = 1;
        state.Gold = 100;

        var (newState, events, _) = Apply(state, "upgrade", new()
        {
            ["x"] = pos.X,
            ["y"] = pos.Y,
        });

        Assert.Equal(2, newState.StructureLevels[index]);
        Assert.Equal(95, newState.Gold); // Level 1 upgrade costs 1*5 = 5
        Assert.Contains(events, e => e.Contains("Upgraded") && e.Contains("level 2"));
    }

    [Fact]
    public void Upgrade_NoStructure_ReturnsError()
    {
        var state = CreateState();
        var pos = PrepareBuildableTile(state, 1, 0);
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        state.Structures.Remove(index);

        var (_, events, _) = Apply(state, "upgrade", new()
        {
            ["x"] = pos.X,
            ["y"] = pos.Y,
        });

        Assert.Contains("No structure at that location to upgrade.", events);
    }

    [Fact]
    public void Upgrade_NotEnoughGold_ReturnsError()
    {
        var state = CreateState();
        var pos = PrepareBuildableTile(state, 1, 0);
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        state.Structures[index] = "tower";
        state.StructureLevels[index] = 10;
        state.Gold = 1; // Level 10 costs 50

        var (_, events, _) = Apply(state, "upgrade", new()
        {
            ["x"] = pos.X,
            ["y"] = pos.Y,
        });

        Assert.Contains(events, e => e.Contains("Need") && e.Contains("gold"));
    }

    [Fact]
    public void Upgrade_CostScalesWithLevel()
    {
        var state = CreateState();
        var pos = PrepareBuildableTile(state, 1, 0);
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        state.Structures[index] = "tower";
        state.StructureLevels[index] = 3;
        state.Gold = 100;

        var (newState, _, _) = Apply(state, "upgrade", new()
        {
            ["x"] = pos.X,
            ["y"] = pos.Y,
        });

        Assert.Equal(85, newState.Gold); // Level 3 costs 3*5 = 15
        Assert.Equal(4, newState.StructureLevels[index]);
    }

    // =========================================================================
    // Explore — edge cases
    // =========================================================================

    [Fact]
    public void Explore_DuringNight_Rejected()
    {
        var state = CreateState();
        state.Phase = "night";

        var (_, events, _) = Apply(state, "explore");

        Assert.Contains(events, e => e.Contains("only available during the day")
                                     || e.Contains("Day action"));
    }

    [Fact]
    public void Explore_IncreasesDiscoveredCount()
    {
        var state = CreateState();
        state.Ap = 3;
        int discoveredBefore = state.Discovered.Count;

        var (newState, _, _) = Apply(state, "explore");

        Assert.Equal(discoveredBefore + 1, newState.Discovered.Count);
    }

    [Fact]
    public void Explore_IncreasesThreatByOne()
    {
        var state = CreateState();
        state.Ap = 3;
        int threatBefore = state.Threat;

        var (newState, _, _) = Apply(state, "explore");

        Assert.Equal(threatBefore + 1, newState.Threat);
    }

    [Fact]
    public void Explore_AllTilesDiscovered_ReturnsNoTilesMessage()
    {
        var state = CreateState();
        state.Ap = 3;
        // Discover all tiles
        for (int i = 0; i < state.MapW * state.MapH; i++)
            state.Discovered.Add(i);

        var (_, events, _) = Apply(state, "explore");

        Assert.Contains("No new tiles to discover.", events);
    }

    // =========================================================================
    // End (day→night transition) — boss spawns
    // =========================================================================

    [Theory]
    [InlineData(7, "forest_guardian")]
    [InlineData(14, "stone_golem")]
    [InlineData(21, "sunlord")]
    public void End_BossDay_SpawnsBossEnemy(int day, string expectedBossKind)
    {
        var state = CreateState();
        state.Day = day;

        var (newState, events, _) = Apply(state, "end");

        Assert.Equal("night", newState.Phase);
        Assert.Contains(events, e => e.Contains("BOSS ENCOUNTER"));
        // Boss should be in enemies list
        Assert.Contains(newState.Enemies, e =>
            e.GetValueOrDefault("kind")?.ToString() == expectedBossKind ||
            (Convert.ToBoolean(e.GetValueOrDefault("is_boss", false))));
    }

    [Theory]
    [InlineData(1)]
    [InlineData(5)]
    [InlineData(10)]
    [InlineData(20)]
    public void End_NonBossDay_NoBossSpawn(int day)
    {
        var state = CreateState();
        state.Day = day;

        var (newState, events, _) = Apply(state, "end");

        Assert.Equal("night", newState.Phase);
        Assert.DoesNotContain(events, e => e.Contains("BOSS ENCOUNTER"));
    }

    [Fact]
    public void End_SetsNightPhaseAndClearsAp()
    {
        var state = CreateState();
        state.Ap = 5;

        var (newState, _, _) = Apply(state, "end");

        Assert.Equal("night", newState.Phase);
        Assert.Equal(0, newState.Ap);
    }

    [Fact]
    public void End_SetsNightWaveTotalToSpawnRemaining()
    {
        var state = CreateState();

        var (newState, _, _) = Apply(state, "end");

        Assert.True(newState.NightWaveTotal >= 1);
        Assert.Equal(newState.NightWaveTotal, newState.NightSpawnRemaining);
    }

    [Fact]
    public void End_ClearsExistingEnemies()
    {
        var state = CreateState();
        state.Enemies.Add(new Dictionary<string, object>
        {
            ["word"] = "leftover",
            ["hp"] = 5,
            ["kind"] = "raider",
        });

        var (newState, _, _) = Apply(state, "end");

        // Enemies cleared before night spawn; only boss enemies (if any) would remain
        Assert.DoesNotContain(newState.Enemies, e =>
            e.GetValueOrDefault("word")?.ToString() == "leftover");
    }

    [Fact]
    public void End_ReturnsAutosaveRequest()
    {
        var state = CreateState();

        var (_, _, result) = Apply(state, "end");

        Assert.True(result.TryGetValue("request", out var requestObj));
        var request = Assert.IsType<Dictionary<string, object>>(requestObj);
        Assert.Equal("autosave", request["kind"]?.ToString());
        Assert.Equal("night", request["reason"]?.ToString());
    }

    // =========================================================================
    // AP tracking across multiple actions
    // =========================================================================

    [Fact]
    public void MultipleActions_ConsumeApCorrectly()
    {
        var state = CreateState();
        state.Ap = 3;

        var (state2, _, _) = Apply(state, "explore");
        Assert.Equal(2, state2.Ap);

        var (state3, _, _) = Apply(state2, "explore");
        Assert.Equal(1, state3.Ap);
    }

    [Fact]
    public void MultipleActions_NoAp_AllRejected()
    {
        var state = CreateState();
        state.Ap = 0;
        int discoveredBefore = state.Discovered.Count;

        var (state2, _, _) = Apply(state, "explore");
        var (state3, _, _) = Apply(state2, "explore");

        Assert.Equal(discoveredBefore, state3.Discovered.Count);
    }

    // =========================================================================
    // MovePlayer — extended
    // =========================================================================

    [Fact]
    public void MovePlayer_ValidDirection_AutoDiscoversTargetTile()
    {
        var state = CreateState();
        state.PlayerPos = state.BasePos;
        state.CursorPos = state.BasePos;
        var target = new GridPoint(state.BasePos.X + 1, state.BasePos.Y);
        int targetIndex = SimMap.Idx(target.X, target.Y, state.MapW);
        state.Structures.Remove(targetIndex);
        state.Terrain[targetIndex] = SimMap.TerrainPlains;
        state.Discovered.Remove(targetIndex);

        var (newState, _, _) = Apply(state, "move_player", new()
        {
            ["dx"] = 1,
            ["dy"] = 0,
        });

        Assert.Contains(targetIndex, newState.Discovered);
    }

    [Fact]
    public void MovePlayer_UpdatesFacingDirection()
    {
        var state = CreateState();
        state.PlayerPos = new GridPoint(state.MapW / 2, state.MapH / 2);
        state.CursorPos = state.PlayerPos;
        // Ensure target tile is passable
        var target = new GridPoint(state.PlayerPos.X, state.PlayerPos.Y + 1);
        int targetIndex = SimMap.Idx(target.X, target.Y, state.MapW);
        state.Structures.Remove(targetIndex);
        state.Terrain[targetIndex] = SimMap.TerrainPlains;

        var (newState, _, _) = Apply(state, "move_player", new()
        {
            ["dx"] = 0,
            ["dy"] = 1,
        });

        Assert.Equal("down", newState.PlayerFacing);
    }

    // =========================================================================
    // Helpers
    // =========================================================================

    private static GameState CreateState() => DefaultState.Create();

    private static (GameState State, List<string> Events, Dictionary<string, object> Result) Apply(
        GameState state,
        string kind,
        Dictionary<string, object>? data = null)
    {
        var result = IntentApplier.Apply(state, SimIntents.Make(kind, data));
        var newState = Assert.IsType<GameState>(result["state"]);
        var events = Assert.IsType<List<string>>(result["events"]);
        return (newState, events, result);
    }

    private static GridPoint PrepareBuildableTile(GameState state, int dx, int dy)
    {
        var pos = new GridPoint(state.BasePos.X + dx, state.BasePos.Y + dy);
        Assert.True(SimMap.InBounds(pos.X, pos.Y, state.MapW, state.MapH));
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        state.Discovered.Add(index);
        state.Terrain[index] = SimMap.TerrainPlains;
        state.Structures.Remove(index);
        state.StructureLevels.Remove(index);
        return pos;
    }

    private static void LoadBuildingsData()
    {
        BuildingsData.LoadData(ResolveDataDirectory());
    }

    private static string ResolveDataDirectory()
    {
        string? dir = AppContext.BaseDirectory;
        for (int i = 0; i < 10 && !string.IsNullOrEmpty(dir); i++)
        {
            string candidate = Path.Combine(dir, "data");
            if (File.Exists(Path.Combine(candidate, "buildings.json")))
                return candidate;

            string? parent = Path.GetDirectoryName(dir);
            if (parent == dir)
                break;
            dir = parent;
        }

        throw new DirectoryNotFoundException("Could not locate data/buildings.json from test base directory.");
    }
}
