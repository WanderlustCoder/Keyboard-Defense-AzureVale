using System;
using System.Collections.Generic;
using System.IO;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class WorldSpecLoaderExtendedTests
{
    [Fact]
    public void PopulateFromSpec_ProjectWorldSpec_LoadsWithExpectedDimensionsAndTerrainCount()
    {
        string specPath = ResolveWorldSpecPath();
        var state = new GameState();

        bool loaded = WorldSpecLoader.PopulateFromSpec(state, specPath);

        Assert.True(loaded);
        Assert.Equal(192, state.MapW);
        Assert.Equal(108, state.MapH);
        Assert.Equal(state.MapW * state.MapH, state.Terrain.Count);
    }

    [Fact]
    public void GetPoiPositions_WithValidTargets_ParsesCoordinates()
    {
        const string json = """
{
  "poi": {
    "targets": {
      "shrine": { "x": 3, "y": 5 },
      "camp": { "x": 9, "y": 1 },
      "mine": { "x": 4, "y": 8 }
    }
  }
}
""";

        RunWithTemporarySpec(json, specPath =>
        {
            Dictionary<string, GridPoint> pois = WorldSpecLoader.GetPoiPositions(specPath);

            Assert.Equal(3, pois.Count);
            Assert.Equal(new GridPoint(3, 5), pois["shrine"]);
            Assert.Equal(new GridPoint(9, 1), pois["camp"]);
            Assert.Equal(new GridPoint(4, 8), pois["mine"]);
        });
    }

    [Fact]
    public void PopulateFromSpec_CoastBands_StackIntoPlainsBeachAndWater()
    {
        const string json = """
{
  "world": { "width": 6, "height": 1 },
  "coast": {
    "bands": {
      "meadow_to_beach": 1,
      "beach_to_shallow": 0,
      "shallow_to_deep": 1
    },
    "control_points": [
      { "y": 0, "x": 3 },
      { "y": 1, "x": 3 }
    ]
  },
  "biomes": {},
  "poi": { "targets": {} },
  "roads": { "corridors": [] }
}
""";

        RunWithTemporarySpec(json, specPath =>
        {
            var state = new GameState();
            Assert.True(WorldSpecLoader.PopulateFromSpec(state, specPath));

            Assert.Equal(SimMap.Plains, TerrainAt(state, 0, 0));
            Assert.Equal(SimMap.Plains, TerrainAt(state, 1, 0));
            Assert.Equal(SimMap.Desert, TerrainAt(state, 2, 0));
            Assert.Equal(SimMap.Water, TerrainAt(state, 3, 0));
            Assert.Equal(SimMap.Water, TerrainAt(state, 4, 0));
            Assert.Equal(SimMap.Water, TerrainAt(state, 5, 0));
        });
    }

    [Fact]
    public void PopulateFromSpec_BiomeParsing_AppliesSwampAndMountainToMeadow()
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
      "outer": [ { "x": 2.0, "y": 2.0, "r": 2.2 } ],
      "core": [],
      "cut": []
    },
    "mountain": {
      "outer": [ { "x": 5.0, "y": 5.0, "r": 1.8 } ],
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

            Assert.Equal(SimMap.Forest, TerrainAt(state, 2, 2));
            Assert.Equal(SimMap.Mountain, TerrainAt(state, 5, 5));
            Assert.Equal(SimMap.Plains, TerrainAt(state, 7, 0));
        });
    }

    [Fact]
    public void PopulateFromSpec_PoiRoadCorridor_ConnectsEndpoints()
    {
        const string json = """
{
  "world": { "width": 9, "height": 5 },
  "coast": {
    "bands": {
      "meadow_to_beach": 0,
      "beach_to_shallow": 0,
      "shallow_to_deep": 0
    },
    "control_points": [
      { "y": 0, "x": 100 },
      { "y": 5, "x": 100 }
    ]
  },
  "biomes": {},
  "poi": {
    "targets": {
      "a": { "x": 1, "y": 2 },
      "b": { "x": 4, "y": 2 },
      "c": { "x": 7, "y": 2 }
    }
  },
  "roads": {
    "corridors": [
      { "radius": 0.75, "points": [ "a", "b", "c" ] }
    ]
  }
}
""";

        RunWithTemporarySpec(json, specPath =>
        {
            var state = new GameState();
            Assert.True(WorldSpecLoader.PopulateFromSpec(state, specPath));

            var pois = WorldSpecLoader.GetPoiPositions(specPath);
            GridPoint start = pois["a"];
            GridPoint end = pois["c"];

            Assert.Equal(SimMap.Road, TerrainAt(state, start.X, start.Y));
            Assert.Equal(SimMap.Road, TerrainAt(state, end.X, end.Y));
            Assert.True(HasRoadPath(state, start, end));
        });
    }

    [Fact]
    public void PopulateFromSpec_TerrainLayerStacking_MountainOverridesRoadAndRoadOverridesSwamp()
    {
        const string json = """
{
  "world": { "width": 9, "height": 5 },
  "coast": {
    "bands": {
      "meadow_to_beach": 0,
      "beach_to_shallow": 0,
      "shallow_to_deep": 0
    },
    "control_points": [
      { "y": 0, "x": 100 },
      { "y": 5, "x": 100 }
    ]
  },
  "biomes": {
    "swamp": {
      "outer": [ { "x": 4.0, "y": 2.0, "r": 3.0 } ],
      "core": [],
      "cut": []
    },
    "mountain": {
      "outer": [ { "x": 4.0, "y": 2.0, "r": 0.75 } ],
      "core": [],
      "cut": []
    }
  },
  "poi": {
    "targets": {
      "a": { "x": 1, "y": 2 },
      "b": { "x": 7, "y": 2 }
    }
  },
  "roads": {
    "corridors": [
      { "radius": 0.9, "points": [ "a", "b" ] }
    ]
  }
}
""";

        RunWithTemporarySpec(json, specPath =>
        {
            var state = new GameState();
            Assert.True(WorldSpecLoader.PopulateFromSpec(state, specPath));

            Assert.Equal(SimMap.Mountain, TerrainAt(state, 4, 2));
            Assert.Equal(SimMap.Road, TerrainAt(state, 2, 2));
            Assert.Equal(SimMap.Forest, TerrainAt(state, 4, 0));
        });
    }

    [Fact]
    public void PopulateFromSpec_InvalidRoadReferences_AreIgnoredGracefully()
    {
        const string json = """
{
  "world": { "width": 6, "height": 3 },
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
      "a": { "x": 1, "y": 1 }
    }
  },
  "roads": {
    "corridors": [
      { "radius": 0.8, "points": [ "missing", "also_missing" ] },
      { "radius": 0.8, "points": [ "a" ] }
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
    public void PopulateFromSpec_EmptyOptionalSections_DefaultToPlains()
    {
        const string json = """
{
  "world": { "width": 5, "height": 4 },
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
  }
}
""";

        RunWithTemporarySpec(json, specPath =>
        {
            var state = new GameState();
            Assert.True(WorldSpecLoader.PopulateFromSpec(state, specPath));

            Assert.Equal(5, state.MapW);
            Assert.Equal(4, state.MapH);
            Assert.Equal(20, state.Terrain.Count);
            Assert.All(state.Terrain, terrain => Assert.Equal(SimMap.Plains, terrain));
        });
    }

    [Fact]
    public void GetPoiPositions_EmptySpec_ReturnsEmptyDictionary()
    {
        const string json = "{}";

        RunWithTemporarySpec(json, specPath =>
        {
            Dictionary<string, GridPoint> pois = WorldSpecLoader.GetPoiPositions(specPath);

            Assert.NotNull(pois);
            Assert.Empty(pois);
        });
    }

    private static bool HasRoadPath(GameState state, GridPoint start, GridPoint end)
    {
        if (TerrainAt(state, start.X, start.Y) != SimMap.Road ||
            TerrainAt(state, end.X, end.Y) != SimMap.Road)
        {
            return false;
        }

        var queue = new Queue<GridPoint>();
        var visited = new HashSet<GridPoint> { start };
        queue.Enqueue(start);

        while (queue.Count > 0)
        {
            GridPoint current = queue.Dequeue();
            if (current == end)
            {
                return true;
            }

            foreach (GridPoint next in SimMap.Neighbors4(current, state.MapW, state.MapH))
            {
                if (visited.Contains(next) || TerrainAt(state, next.X, next.Y) != SimMap.Road)
                {
                    continue;
                }

                visited.Add(next);
                queue.Enqueue(next);
            }
        }

        return false;
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
        string tempDir = Path.Combine(Path.GetTempPath(), "keyboard-defense-world-spec-extended-tests-" + Guid.NewGuid().ToString("N"));
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
