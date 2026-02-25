using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;
using Newtonsoft.Json;

namespace KeyboardDefense.Tests.Core;

public class WorldSpecLoaderTests
{
    [Fact]
    public void PopulateFromSpec_MissingFile_ReturnsFalseAndDoesNotMutateState()
    {
        var state = new GameState
        {
            MapW = 7,
            MapH = 5,
        };
        state.Terrain.Clear();
        state.Terrain.AddRange(new[] { "sentinel-a", "sentinel-b" });

        bool loaded = WorldSpecLoader.PopulateFromSpec(state, Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString("N") + ".json"));

        Assert.False(loaded);
        Assert.Equal(7, state.MapW);
        Assert.Equal(5, state.MapH);
        Assert.Equal(new[] { "sentinel-a", "sentinel-b" }, state.Terrain);
    }

    [Fact]
    public void GetPoiPositions_MissingFile_ReturnsEmptyDictionary()
    {
        var pois = WorldSpecLoader.GetPoiPositions(Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString("N") + ".json"));

        Assert.NotNull(pois);
        Assert.Empty(pois);
    }

    [Fact]
    public void GetPoiPositions_ProjectSpec_ReturnsExpectedTargetsAndCoordinates()
    {
        string specPath = ResolveWorldSpecPath();

        Dictionary<string, GridPoint> pois = WorldSpecLoader.GetPoiPositions(specPath);

        Assert.Equal(7, pois.Count);
        Assert.Equal(new GridPoint(56, 83), pois["shrine"]);
        Assert.Equal(new GridPoint(113, 24), pois["mine"]);
        Assert.Equal(new GridPoint(117, 51), pois["shore"]);
        Assert.True(new[] { "shrine", "camp", "outpost", "ruins", "watchtower", "mine", "shore" }
            .All(pois.ContainsKey));
    }

    [Fact]
    public void PopulateFromSpec_ProjectSpec_SetsDimensionsAndTerrainGrid()
    {
        string specPath = ResolveWorldSpecPath();
        var state = new GameState();

        bool loaded = WorldSpecLoader.PopulateFromSpec(state, specPath);

        Assert.True(loaded);
        Assert.Equal(192, state.MapW);
        Assert.Equal(108, state.MapH);
        Assert.Equal(state.MapW * state.MapH, state.Terrain.Count);
        Assert.DoesNotContain(state.Terrain, t => string.IsNullOrWhiteSpace(t));
    }

    [Fact]
    public void PopulateFromSpec_ProjectSpec_ContainsExpectedTerrainFamilies()
    {
        string specPath = ResolveWorldSpecPath();
        var state = new GameState();
        Assert.True(WorldSpecLoader.PopulateFromSpec(state, specPath));

        Assert.Contains(SimMap.Water, state.Terrain);
        Assert.Contains(SimMap.Desert, state.Terrain);
        Assert.Contains(SimMap.Plains, state.Terrain);
        Assert.Contains(SimMap.Forest, state.Terrain);
        Assert.Contains(SimMap.Mountain, state.Terrain);
        Assert.Contains(SimMap.Road, state.Terrain);

        var known = new HashSet<string>(StringComparer.Ordinal)
        {
            SimMap.Water,
            SimMap.Desert,
            SimMap.Plains,
            SimMap.Forest,
            SimMap.Mountain,
            SimMap.Road,
            SimMap.Snow,
        };

        Assert.All(state.Terrain, terrain => Assert.Contains(terrain, known));
    }

    [Fact]
    public void PopulateFromSpec_InvalidJson_ThrowsJsonReaderException()
    {
        RunWithTemporarySpec("{ \"world\": {", specPath =>
        {
            var state = new GameState();
            Assert.Throws<JsonReaderException>(() => WorldSpecLoader.PopulateFromSpec(state, specPath));
        });
    }

    [Fact]
    public void PopulateFromSpec_MissingRequiredWorldFields_Throws()
    {
        const string json = """
{
  "coast": {
    "bands": {
      "meadow_to_beach": 0,
      "beach_to_shallow": 0,
      "shallow_to_deep": 0
    },
    "control_points": [ { "y": 0, "x": 10 } ]
  }
}
""";

        RunWithTemporarySpec(json, specPath =>
        {
            var state = new GameState();
            Assert.ThrowsAny<Exception>(() => WorldSpecLoader.PopulateFromSpec(state, specPath));
        });
    }

    [Fact]
    public void PopulateFromSpec_BiomeCut_RemovesPaintedSwampArea()
    {
        const string json = """
{
  "world": { "width": 8, "height": 8 },
  "coast": {
    "bands": {
      "meadow_to_beach": 0,
      "beach_to_shallow": 0,
      "shallow_to_deep": 0
    },
    "control_points": [
      { "y": 0, "x": 100 },
      { "y": 8, "x": 100 }
    ]
  },
  "biomes": {
    "swamp": {
      "outer": [ { "x": 3.5, "y": 3.5, "r": 3.0 } ],
      "core": [],
      "cut": [ { "x": 3.5, "y": 3.5, "r": 1.1 } ]
    }
  },
  "poi": { "targets": {} },
  "roads": { "corridors": [] }
}
""";

        RunWithTemporarySpec(json, specPath =>
        {
            var state = new GameState();
            Assert.True(WorldSpecLoader.PopulateFromSpec(state, specPath));

            Assert.Equal(SimMap.Plains, TerrainAt(state, 3, 3));
            Assert.Equal(SimMap.Forest, TerrainAt(state, 1, 3));
        });
    }

    [Fact]
    public void PopulateFromSpec_BiomePainting_SkipsWaterVertices()
    {
        const string json = """
{
  "world": { "width": 6, "height": 4 },
  "coast": {
    "bands": {
      "meadow_to_beach": 0,
      "beach_to_shallow": 0,
      "shallow_to_deep": 0
    },
    "control_points": [
      { "y": 0, "x": 2 },
      { "y": 4, "x": 2 }
    ]
  },
  "biomes": {
    "swamp": {
      "outer": [ { "x": 5.0, "y": 2.0, "r": 2.0 } ],
      "core": [],
      "cut": []
    }
  },
  "poi": { "targets": {} },
  "roads": { "corridors": [] }
}
""";

        RunWithTemporarySpec(json, specPath =>
        {
            var state = new GameState();
            Assert.True(WorldSpecLoader.PopulateFromSpec(state, specPath));

            Assert.DoesNotContain(SimMap.Forest, state.Terrain);
            Assert.Contains(SimMap.Water, state.Terrain);
            Assert.Equal(SimMap.Plains, TerrainAt(state, 0, 1));
        });
    }

    [Fact]
    public void PopulateFromSpec_RoadsRequireAtLeastTwoValidPoiPoints()
    {
        const string json = """
{
  "world": { "width": 7, "height": 3 },
  "coast": {
    "bands": {
      "meadow_to_beach": 0,
      "beach_to_shallow": 0,
      "shallow_to_deep": 0
    },
    "control_points": [
      { "y": 0, "x": 100 },
      { "y": 3, "x": 100 }
    ]
  },
  "biomes": {},
  "poi": {
    "targets": {
      "a": { "x": 1, "y": 1 },
      "b": { "x": 5, "y": 1 }
    }
  },
  "roads": {
    "corridors": [
      { "radius": 0.8, "points": [ "a" ] },
      { "radius": 0.8, "points": [ "missing", "also_missing" ] },
      { "radius": 0.8, "points": [ "a", "missing" ] }
    ]
  }
}
""";

        RunWithTemporarySpec(json, specPath =>
        {
            var state = new GameState();
            Assert.True(WorldSpecLoader.PopulateFromSpec(state, specPath));

            Assert.DoesNotContain(SimMap.Road, state.Terrain);
            Assert.All(state.Terrain, terrain => Assert.Equal(SimMap.Plains, terrain));
        });
    }

    [Fact]
    public void PopulateFromSpec_RegionBoundaryPainting_ClampsOutOfBoundsBiomeCircles()
    {
        const string json = """
{
  "world": { "width": 4, "height": 4 },
  "coast": {
    "bands": {
      "meadow_to_beach": 0,
      "beach_to_shallow": 0,
      "shallow_to_deep": 0
    },
    "control_points": [
      { "y": 0, "x": 100 },
      { "y": 4, "x": 100 }
    ]
  },
  "biomes": {
    "mountain": {
      "outer": [ { "x": -1.0, "y": -1.0, "r": 3.0 } ],
      "core": [],
      "cut": []
    }
  },
  "poi": { "targets": {} },
  "roads": { "corridors": [] }
}
""";

        RunWithTemporarySpec(json, specPath =>
        {
            var state = new GameState();
            Assert.True(WorldSpecLoader.PopulateFromSpec(state, specPath));

            Assert.Equal(SimMap.Mountain, TerrainAt(state, 0, 0));
            Assert.Equal(SimMap.Plains, TerrainAt(state, 3, 3));
        });
    }

    [Fact]
    public void PopulateFromSpec_RoadsDoNotOverrideMountainTiles()
    {
        const string json = """
{
  "world": { "width": 8, "height": 4 },
  "coast": {
    "bands": {
      "meadow_to_beach": 0,
      "beach_to_shallow": 0,
      "shallow_to_deep": 0
    },
    "control_points": [
      { "y": 0, "x": 100 },
      { "y": 4, "x": 100 }
    ]
  },
  "biomes": {
    "mountain": {
      "outer": [ { "x": 3.0, "y": 1.5, "r": 1.4 } ],
      "core": [],
      "cut": []
    }
  },
  "poi": {
    "targets": {
      "a": { "x": 1, "y": 1 },
      "b": { "x": 5, "y": 1 }
    }
  },
  "roads": {
    "corridors": [
      { "radius": 0.65, "points": [ "a", "b" ] }
    ]
  }
}
""";

        RunWithTemporarySpec(json, specPath =>
        {
            var state = new GameState();
            Assert.True(WorldSpecLoader.PopulateFromSpec(state, specPath));

            Assert.Equal(SimMap.Road, TerrainAt(state, 5, 1));
            Assert.Equal(SimMap.Mountain, TerrainAt(state, 3, 1));
        });
    }

    private static string TerrainAt(GameState state, int x, int y)
    {
        return state.Terrain[y * state.MapW + x];
    }

    private static string ResolveWorldSpecPath()
    {
        string? dir = AppDomain.CurrentDomain.BaseDirectory;
        for (int i = 0; i < 12 && !string.IsNullOrWhiteSpace(dir); i++)
        {
            string candidate = Path.Combine(dir, "data", "world_spec.json");
            if (File.Exists(candidate))
            {
                return candidate;
            }

            dir = Directory.GetParent(dir)?.FullName;
        }

        throw new DirectoryNotFoundException("Unable to locate data/world_spec.json from test base directory.");
    }

    private static void RunWithTemporarySpec(string json, Action<string> assertions)
    {
        string tempDir = Path.Combine(Path.GetTempPath(), "keyboard-defense-world-spec-tests-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(tempDir);
        string specPath = Path.Combine(tempDir, "world_spec.json");

        try
        {
            File.WriteAllText(specPath, json);
            assertions(specPath);
        }
        finally
        {
            if (Directory.Exists(tempDir))
            {
                Directory.Delete(tempDir, recursive: true);
            }
        }
    }
}
