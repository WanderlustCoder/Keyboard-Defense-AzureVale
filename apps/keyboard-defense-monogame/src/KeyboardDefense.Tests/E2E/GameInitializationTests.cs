using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Economy;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;
using KeyboardDefense.Game.Services;
using Newtonsoft.Json.Linq;

namespace KeyboardDefense.Tests.E2E;

[Collection("StaticData")]
public class GameInitializationTests
{
    private static readonly object DataLoadLock = new();
    private static bool _dataLoaded;

    private static readonly HashSet<string> ValidTerrainTypes = new(StringComparer.Ordinal)
    {
        SimMap.TerrainPlains,
        SimMap.TerrainForest,
        SimMap.TerrainMountain,
        SimMap.TerrainWater,
        SimMap.TerrainDesert,
        SimMap.TerrainSnow,
        SimMap.TerrainRoad,
    };

    private static readonly string[] TowerBuildTypes =
    {
        "tower",
        "auto_sentry",
        "auto_spark",
        "auto_thorns",
        "auto_ballista",
        "auto_tesla",
        "auto_bramble",
        "auto_flame",
        "auto_cannon",
        "auto_storm",
        "auto_fortress",
        "auto_inferno",
        "auto_arcane",
        "auto_doom",
    };

    [Fact]
    public void InitializationPipeline_LoadsAllRuntimeDataFilesWithoutErrors()
    {
        EnsureDataLoaded();
        string dataDir = ResolveDataDirectory();

        string[] requiredFiles =
        {
            "buildings.json",
            "lessons.json",
            "factions.json",
            "vertical_slice_wave.json",
            "vertical_slice_wave_profiles.json",
            "story.json",
            "world_spec.json",
            "events/event_tables.json",
            "pois/pois.json",
            "translations/en.json",
        };

        foreach (string relativePath in requiredFiles)
        {
            string fullPath = Path.Combine(dataDir, relativePath);
            Assert.True(File.Exists(fullPath), $"Required data file not found: {fullPath}");
            AssertJsonIsParseable(fullPath);
        }

        Assert.NotNull(BuildingsData.GetBuilding("tower"));
        Assert.True(LessonsData.IsValid(LessonsData.DefaultLessonId()));
        Assert.NotEmpty(LessonsData.LessonIds());
        Assert.NotEmpty(FactionsData.GetFactionIds());
        Assert.NotNull(Poi.GetPoiDef("poi_evergrove_wagon"));
        Assert.True(Locale.HasTranslation("ui.save"));
        Assert.True(StoryManager.Instance.IsLoaded);
        Assert.NotEmpty(StoryManager.Instance.GetActs());
        Assert.NotNull(EventTables.SelectEvent(DefaultState.Create("init_event_table_seed"), "evergrove_default"));
        Assert.NotNull(VerticalSliceWaveData.GetProfile("vertical_slice_default"));
        Assert.NotEmpty(Items.Equipment);
        Assert.NotEmpty(Items.Consumables);
    }

    [Fact]
    public void DefaultState_HasValidTerrainForAllPositions()
    {
        var state = CreateInitializedState("terrain_validity_seed");

        Assert.Equal(state.MapW * state.MapH, state.Terrain.Count);

        for (int y = 0; y < state.MapH; y++)
        {
            for (int x = 0; x < state.MapW; x++)
            {
                int index = SimMap.Idx(x, y, state.MapW);
                string terrain = state.Terrain[index];
                Assert.False(string.IsNullOrWhiteSpace(terrain), $"Terrain missing at ({x},{y}).");
                Assert.Contains(terrain, ValidTerrainTypes);
            }
        }
    }

    [Fact]
    public void DefaultState_PlayerStartsWithExpectedResourcesForFirstBuild()
    {
        var state = CreateInitializedState("starting_resources_seed");

        Assert.Equal(1, state.Day);
        Assert.Equal("day", state.Phase);
        Assert.Equal(10, state.Gold);
        Assert.Equal(state.ApMax, state.Ap);

        foreach (string resourceKey in GameState.ResourceKeys)
            Assert.True(state.Resources.ContainsKey(resourceKey), $"Missing resource key '{resourceKey}'.");

        Assert.Equal(0, state.Resources["wood"]);
        Assert.Equal(0, state.Resources["stone"]);
        Assert.Equal(0, state.Resources["food"]);
    }

    [Fact]
    public void DefaultState_TypingLessonsAreAvailableFromDayOne()
    {
        var state = CreateInitializedState("lesson_availability_seed");

        Assert.Equal(1, state.Day);
        Assert.NotEmpty(LessonsData.LessonIds());
        Assert.True(LessonsData.IsValid(state.LessonId));

        var lesson = LessonsData.GetLesson(state.LessonId);
        Assert.NotNull(lesson);
        Assert.False(string.IsNullOrWhiteSpace(lesson!.Name));
        Assert.False(string.IsNullOrWhiteSpace(lesson.Mode));
    }

    [Fact]
    public void DefaultState_HasAtLeastOneAffordableBuildableTowerTypeAtStart()
    {
        var state = CreateInitializedState("affordable_tower_seed");

        string? affordableTower = TowerBuildTypes.FirstOrDefault(
            towerId => BuildingsData.IsValid(towerId) && CanAfford(state, BuildingsData.CostFor(towerId)));

        Assert.False(string.IsNullOrWhiteSpace(affordableTower));

        GridPoint? buildablePos = FindBuildableDiscoveredTile(state);
        Assert.True(buildablePos.HasValue, "Expected at least one buildable discovered tile at initialization.");

        var intent = new Dictionary<string, object>
        {
            ["kind"] = "build",
            ["building"] = affordableTower!,
            ["x"] = buildablePos.Value.X,
            ["y"] = buildablePos.Value.Y,
        };

        var result = IntentApplier.Apply(state, intent);
        var nextState = Assert.IsType<GameState>(result["state"]);

        int buildIndex = SimMap.Idx(buildablePos.Value.X, buildablePos.Value.Y, state.MapW);
        Assert.True(nextState.Structures.TryGetValue(buildIndex, out string? builtType));
        Assert.Equal(affordableTower, builtType);
    }

    [Fact]
    public void DefaultState_MapHasReachablePoisFromBase()
    {
        var state = CreateInitializedState("reachable_pois_seed");
        Assert.NotEmpty(state.ActivePois);

        int[] distances = SimMap.ComputeDistToBase(state);
        int reachablePoiCount = 0;

        foreach (var (poiId, poiState) in state.ActivePois)
        {
            Assert.True(poiState.TryGetValue("pos", out object? rawPos), $"POI '{poiId}' missing position.");
            var pos = Assert.IsType<GridPoint>(rawPos);
            Assert.True(SimMap.InBounds(pos.X, pos.Y, state.MapW, state.MapH), $"POI '{poiId}' is out of bounds.");

            int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
            if (distances[index] >= 0)
                reachablePoiCount++;
        }

        Assert.True(
            reachablePoiCount > 0,
            $"Expected at least one reachable POI, but none were reachable out of {state.ActivePois.Count}.");
    }

    [Fact]
    public void DefaultState_NpcPositionsAreOnValidPassableTerrain()
    {
        var state = CreateInitializedState("npc_validity_seed");
        Assert.NotEmpty(state.Npcs);

        foreach (var npc in state.Npcs)
        {
            Assert.True(npc.TryGetValue("pos", out object? rawPos), "NPC is missing 'pos'.");
            var pos = Assert.IsType<GridPoint>(rawPos);

            Assert.True(SimMap.InBounds(pos.X, pos.Y, state.MapW, state.MapH));

            string terrain = SimMap.GetTerrain(state, pos);
            Assert.Contains(terrain, ValidTerrainTypes);
            Assert.True(SimMap.IsPassable(state, pos), $"NPC tile at ({pos.X},{pos.Y}) should be passable.");
        }
    }

    [Fact]
    public void DefaultState_SaveLoadRoundTrip_PreservesInitialState()
    {
        var state = CreateInitializedState("save_roundtrip_seed");

        string json = SaveManager.StateToJson(state);
        var (ok, loaded, error) = SaveManager.StateFromJson(json);

        Assert.True(ok, error ?? "Save/load round-trip failed.");
        Assert.NotNull(loaded);

        Assert.Equal(state.Day, loaded!.Day);
        Assert.Equal(state.Phase, loaded.Phase);
        Assert.Equal(state.ApMax, loaded.ApMax);
        Assert.Equal(state.Ap, loaded.Ap);
        Assert.Equal(state.Hp, loaded.Hp);
        Assert.Equal(state.Threat, loaded.Threat);
        Assert.Equal(state.Gold, loaded.Gold);
        Assert.Equal(state.MapW, loaded.MapW);
        Assert.Equal(state.MapH, loaded.MapH);
        Assert.Equal(state.BasePos, loaded.BasePos);
        Assert.Equal(state.PlayerPos, loaded.PlayerPos);
        Assert.Equal(state.CursorPos, loaded.CursorPos);
        Assert.Equal(state.LessonId, loaded.LessonId);
        Assert.Equal(state.Terrain, loaded.Terrain);
        Assert.True(state.Discovered.SetEquals(loaded.Discovered));

        foreach (string resourceKey in GameState.ResourceKeys)
            Assert.Equal(state.Resources.GetValueOrDefault(resourceKey, 0), loaded.Resources.GetValueOrDefault(resourceKey, 0));

        Assert.Equal(state.Structures.Count, loaded.Structures.Count);
        foreach (var (index, structureType) in state.Structures)
        {
            Assert.True(loaded.Structures.TryGetValue(index, out string? loadedType));
            Assert.Equal(structureType, loadedType);
        }

        Assert.Equal(state.ActivePois.Count, loaded.ActivePois.Count);
        Assert.Equal(state.Npcs.Count, loaded.Npcs.Count);
        Assert.Equal(state.RoamingEnemies.Count, loaded.RoamingEnemies.Count);
        Assert.Equal(state.ResourceNodes.Count, loaded.ResourceNodes.Count);
    }

    [Fact]
    public void DefaultState_HasOpenPathFromMapEdgeToBase()
    {
        var state = CreateInitializedState("path_open_seed");
        Assert.True(SimMap.PathOpenToBase(state), "Expected at least one edge tile to reach the base.");
    }

    private static GameState CreateInitializedState(string seed)
    {
        EnsureDataLoaded();
        return DefaultState.Create(seed);
    }

    private static void EnsureDataLoaded()
    {
        lock (DataLoadLock)
        {
            if (_dataLoaded)
                return;

            DataLoader.LoadAll();
            _dataLoaded = true;
        }
    }

    private static string ResolveDataDirectory()
    {
        if (!string.IsNullOrWhiteSpace(DataLoader.DataDirectory) &&
            File.Exists(Path.Combine(DataLoader.DataDirectory, "buildings.json")))
        {
            return DataLoader.DataDirectory;
        }

        string? dir = AppContext.BaseDirectory;
        for (int i = 0; i < 10 && !string.IsNullOrWhiteSpace(dir); i++)
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

    private static void AssertJsonIsParseable(string path)
    {
        string json = File.ReadAllText(path);
        _ = JToken.Parse(json);
    }

    private static bool CanAfford(GameState state, IReadOnlyDictionary<string, int> cost)
    {
        foreach (var (resource, amount) in cost)
        {
            int available = resource.Equals("gold", StringComparison.Ordinal)
                ? state.Gold
                : state.Resources.GetValueOrDefault(resource, 0);

            if (available < amount)
                return false;
        }
        return true;
    }

    private static GridPoint? FindBuildableDiscoveredTile(GameState state)
    {
        foreach (int index in state.Discovered.OrderBy(v => v))
        {
            var pos = SimMap.PosFromIndex(index, state.MapW);
            if (SimMap.IsBuildable(state, pos))
                return pos;
        }

        return null;
    }
}
