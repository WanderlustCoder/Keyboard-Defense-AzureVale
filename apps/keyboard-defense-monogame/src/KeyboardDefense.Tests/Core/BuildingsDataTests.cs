using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

[Collection("StaticData")]
public class BuildingsDataTests
{
    [Fact]
    public void LoadData_LoadsAllBuildingDefinitionsFromJson()
    {
        var expectedBuildings = LoadExpectedBuildingsAndEnsureLoaded();

        Assert.NotEmpty(expectedBuildings);
        int loadedCount = expectedBuildings.Keys.Count(id => BuildingsData.GetBuilding(id) != null);
        Assert.Equal(expectedBuildings.Count, loadedCount);
    }

    [Fact]
    public void GetBuilding_KnownIds_UseExpectedDisplayNames()
    {
        var expectedBuildings = LoadExpectedBuildingsAndEnsureLoaded();

        foreach (var (id, node) in expectedBuildings)
        {
            var def = BuildingsData.GetBuilding(id);
            Assert.NotNull(def);

            string expectedName =
                node.TryGetProperty("label", out JsonElement label) ? label.GetString() ?? id :
                node.TryGetProperty("name", out JsonElement name) ? name.GetString() ?? id :
                id;
            Assert.Equal(expectedName, def!.Name);
        }
    }

    [Fact]
    public void CostFor_ReturnsExpectedCost_ForKnownAndUnknownBuilding()
    {
        LoadExpectedBuildingsAndEnsureLoaded();

        var towerCost = BuildingsData.CostFor("tower");
        Assert.Equal(2, towerCost.Count);
        Assert.Equal(4, towerCost["wood"]);
        Assert.Equal(8, towerCost["stone"]);

        var unknownCost = BuildingsData.CostFor("unknown_building");
        Assert.NotNull(unknownCost);
        Assert.Empty(unknownCost);
    }

    [Fact]
    public void CostValidation_AllBuildingCosts_AreGreaterThanZero()
    {
        var expectedBuildings = LoadExpectedBuildingsAndEnsureLoaded();

        foreach (string id in expectedBuildings.Keys)
        {
            var cost = BuildingsData.CostFor(id);
            Assert.NotEmpty(cost);
            foreach (var (resource, amount) in cost)
            {
                Assert.True(amount > 0, $"Building '{id}' has non-positive cost for '{resource}': {amount}");
            }
        }
    }

    [Fact]
    public void CategoryFiltering_BuildingCountsPerCategory_MatchJson()
    {
        var expectedBuildings = LoadExpectedBuildingsAndEnsureLoaded();

        var expectedCounts = expectedBuildings
            .GroupBy(kvp => kvp.Value.GetProperty("category").GetString() ?? string.Empty)
            .ToDictionary(g => g.Key, g => g.Count(), StringComparer.Ordinal);

        var actualCounts = expectedBuildings.Keys
            .Select(id => BuildingsData.GetBuilding(id))
            .Where(def => def != null)
            .Select(def => def!)
            .GroupBy(def => def.Category)
            .ToDictionary(g => g.Key, g => g.Count(), StringComparer.Ordinal);

        Assert.Equal(expectedCounts.Count, actualCounts.Count);
        foreach (var (category, expectedCount) in expectedCounts)
        {
            Assert.True(actualCounts.ContainsKey(category), $"Missing category '{category}' in loaded data.");
            Assert.Equal(expectedCount, actualCounts[category]);
        }
    }

    [Fact]
    public void CategoryFiltering_ProductionBuildings_MatchExpectedIds()
    {
        var expectedBuildings = LoadExpectedBuildingsAndEnsureLoaded();

        var expectedProduction = expectedBuildings
            .Where(kvp => string.Equals(
                kvp.Value.GetProperty("category").GetString(),
                "production",
                StringComparison.Ordinal))
            .Select(kvp => kvp.Key)
            .OrderBy(id => id)
            .ToArray();

        var actualProduction = expectedBuildings.Keys
            .Select(id => BuildingsData.GetBuilding(id))
            .Where(def => def != null && def.Category == "production")
            .Select(def => def!.Id)
            .OrderBy(id => id)
            .ToArray();

        Assert.Equal(expectedProduction, actualProduction);
    }

    [Fact]
    public void DailyProduction_AggregatesByBuildingCount()
    {
        LoadExpectedBuildingsAndEnsureLoaded();

        var state = new GameState();
        state.Buildings.Clear();
        state.Buildings["farm"] = 2;
        state.Buildings["lumber"] = 1;
        state.Buildings["market"] = 3;

        var output = BuildingsData.DailyProduction(state);

        Assert.Equal(6, output["food"]);   // 2 farms * 3 food
        Assert.Equal(3, output["wood"]);   // 1 lumber * 3 wood
        Assert.Equal(0, output["stone"]);
        Assert.True(output.ContainsKey("gold"));
        Assert.Equal(15, output["gold"]);  // 3 markets * 5 gold
    }

    [Fact]
    public void TotalDefense_SumsDefenseForPlacedStructures()
    {
        LoadExpectedBuildingsAndEnsureLoaded();

        var state = new GameState();
        state.Structures.Clear();
        state.Structures[0] = "wall";      // 1
        state.Structures[1] = "tower";     // 2
        state.Structures[2] = "garrison";  // 3
        state.Structures[3] = "farm";      // 0

        int totalDefense = BuildingsData.TotalDefense(state);
        Assert.Equal(6, totalDefense);
    }

    [Fact]
    public void UpgradePath_RequirementsReferenceExistingBuildings_AndNoCycles()
    {
        var expectedBuildings = LoadExpectedBuildingsAndEnsureLoaded();
        var allIds = expectedBuildings.Keys.ToHashSet(StringComparer.Ordinal);

        var requiresByBuilding = new Dictionary<string, string[]>(StringComparer.Ordinal);
        foreach (var (id, node) in expectedBuildings)
        {
            string[] requires = GetRequires(node).ToArray();
            requiresByBuilding[id] = requires;

            foreach (string requiredId in requires)
            {
                Assert.Contains(requiredId, allIds);
                Assert.NotEqual(id, requiredId);
            }
        }

        var visiting = new HashSet<string>(StringComparer.Ordinal);
        var visited = new HashSet<string>(StringComparer.Ordinal);

        bool HasCycle(string id)
        {
            if (visited.Contains(id)) return false;
            if (!visiting.Add(id)) return true;

            foreach (string required in requiresByBuilding[id])
            {
                if (HasCycle(required)) return true;
            }

            visiting.Remove(id);
            visited.Add(id);
            return false;
        }

        foreach (string id in requiresByBuilding.Keys)
        {
            Assert.False(HasCycle(id), $"Cycle detected in building upgrade requirements for '{id}'.");
        }
    }

    [Fact]
    public void UpgradePath_RequiredBuildings_AreNotHigherTierThanDependentBuilding()
    {
        var expectedBuildings = LoadExpectedBuildingsAndEnsureLoaded();

        foreach (var (id, node) in expectedBuildings)
        {
            var building = BuildingsData.GetBuilding(id);
            Assert.NotNull(building);

            foreach (string requiredId in GetRequires(node))
            {
                var required = BuildingsData.GetBuilding(requiredId);
                Assert.NotNull(required);
                Assert.True(
                    required!.Tier <= building!.Tier,
                    $"Building '{id}' (tier {building!.Tier}) cannot require higher tier '{requiredId}' (tier {required!.Tier}).");
            }
        }
    }

    private static Dictionary<string, JsonElement> LoadExpectedBuildingsAndEnsureLoaded()
    {
        string dataDir = ResolveDataDirectory();
        BuildingsData.LoadData(dataDir);
        return ReadExpectedBuildings(dataDir);
    }

    private static Dictionary<string, JsonElement> ReadExpectedBuildings(string dataDir)
    {
        string path = Path.Combine(dataDir, "buildings.json");
        using var document = JsonDocument.Parse(File.ReadAllText(path));
        var buildings = document.RootElement.GetProperty("buildings");

        var output = new Dictionary<string, JsonElement>(StringComparer.Ordinal);
        foreach (var prop in buildings.EnumerateObject())
        {
            output[prop.Name] = prop.Value.Clone();
        }

        return output;
    }

    private static IEnumerable<string> GetRequires(JsonElement buildingNode)
    {
        if (!buildingNode.TryGetProperty("requires", out JsonElement requires) ||
            requires.ValueKind != JsonValueKind.Array)
        {
            yield break;
        }

        foreach (JsonElement required in requires.EnumerateArray())
        {
            string? id = required.GetString();
            if (!string.IsNullOrWhiteSpace(id))
            {
                yield return id;
            }
        }
    }

    private static string ResolveDataDirectory()
    {
        string? dir = AppDomain.CurrentDomain.BaseDirectory;
        for (int i = 0; i < 10 && !string.IsNullOrEmpty(dir); i++)
        {
            string candidate = Path.Combine(dir, "data");
            if (File.Exists(Path.Combine(candidate, "buildings.json")))
            {
                return candidate;
            }

            string? parent = Path.GetDirectoryName(dir);
            if (parent == dir) break;
            dir = parent;
        }

        throw new DirectoryNotFoundException("Could not locate data/buildings.json from test base directory.");
    }
}
