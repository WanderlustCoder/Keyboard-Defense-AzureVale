using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class ResearchDataTests
{
    [Fact]
    public void ResearchJson_LoadsAndContainsResearchEntries()
    {
        using JsonDocument json = LoadResearchJson();
        JsonElement root = json.RootElement;

        Assert.True(root.TryGetProperty("categories", out JsonElement categories));
        Assert.Equal(JsonValueKind.Object, categories.ValueKind);
        Assert.True(categories.EnumerateObject().Any(), "Expected at least one research category.");

        Assert.True(root.TryGetProperty("research", out JsonElement research));
        Assert.Equal(JsonValueKind.Array, research.ValueKind);
        Assert.True(research.GetArrayLength() > 0, "Expected at least one research entry.");
    }

    [Fact]
    public void Registry_HasExpectedResearchCount()
    {
        Assert.Equal(8, ResearchData.Registry.Count);
    }

    [Fact]
    public void Registry_PrerequisitesReferenceExistingResearch()
    {
        foreach (var (id, def) in ResearchData.Registry)
        {
            if (string.IsNullOrWhiteSpace(def.Prerequisite))
            {
                continue;
            }

            Assert.True(
                ResearchData.Registry.ContainsKey(def.Prerequisite),
                $"Research '{id}' references missing prerequisite '{def.Prerequisite}'.");
        }
    }

    [Fact]
    public void Registry_PrerequisiteChains_AreAcyclic()
    {
        var visiting = new HashSet<string>();
        var visited = new HashSet<string>();

        bool HasCycle(string id)
        {
            if (visited.Contains(id))
            {
                return false;
            }

            if (!visiting.Add(id))
            {
                return true;
            }

            string? prerequisite = ResearchData.Registry[id].Prerequisite;
            if (!string.IsNullOrWhiteSpace(prerequisite)
                && ResearchData.Registry.ContainsKey(prerequisite)
                && HasCycle(prerequisite))
            {
                return true;
            }

            visiting.Remove(id);
            visited.Add(id);
            return false;
        }

        foreach (string id in ResearchData.Registry.Keys)
        {
            Assert.False(HasCycle(id), $"Cycle detected in ResearchData registry starting at '{id}'.");
        }
    }

    [Fact]
    public void Registry_CostsAndEffects_AreValid()
    {
        foreach (var (id, def) in ResearchData.Registry)
        {
            Assert.False(string.IsNullOrWhiteSpace(def.Name), $"Research '{id}' is missing a name.");
            Assert.False(string.IsNullOrWhiteSpace(def.Category), $"Research '{id}' is missing a category.");
            Assert.True(def.GoldCost > 0, $"Research '{id}' has invalid gold cost '{def.GoldCost}'.");
            Assert.True(def.WavesRequired > 0, $"Research '{id}' has invalid waves required '{def.WavesRequired}'.");
            Assert.NotEmpty(def.Effects);

            foreach (var (effectName, effectValue) in def.Effects)
            {
                Assert.False(string.IsNullOrWhiteSpace(effectName), $"Research '{id}' has an empty effect key.");
                Assert.True(double.IsFinite(effectValue), $"Research '{id}' has non-finite effect value for '{effectName}'.");
            }
        }
    }

    [Fact]
    public void ResearchJson_DescriptionsCostsAndEffects_AreValid()
    {
        using JsonDocument json = LoadResearchJson();
        JsonElement research = json.RootElement.GetProperty("research");

        foreach (JsonElement entry in research.EnumerateArray())
        {
            string id = entry.GetProperty("id").GetString() ?? "";

            string description = entry.GetProperty("description").GetString() ?? "";
            Assert.False(string.IsNullOrWhiteSpace(description), $"Research '{id}' has an empty description.");

            int gold = entry.GetProperty("cost").GetProperty("gold").GetInt32();
            Assert.True(gold > 0, $"Research '{id}' has invalid gold cost '{gold}'.");

            int wavesToComplete = entry.GetProperty("waves_to_complete").GetInt32();
            Assert.True(wavesToComplete > 0, $"Research '{id}' has invalid waves_to_complete '{wavesToComplete}'.");

            JsonElement effects = entry.GetProperty("effects");
            Assert.Equal(JsonValueKind.Object, effects.ValueKind);

            int effectCount = 0;
            foreach (JsonProperty effect in effects.EnumerateObject())
            {
                effectCount++;
                Assert.False(string.IsNullOrWhiteSpace(effect.Name), $"Research '{id}' has an effect with an empty key.");
                Assert.NotEqual(JsonValueKind.Null, effect.Value.ValueKind);
                Assert.NotEqual(JsonValueKind.Undefined, effect.Value.ValueKind);
            }

            Assert.True(effectCount > 0, $"Research '{id}' should define at least one effect.");
        }
    }

    [Fact]
    public void ResearchJson_PrerequisiteChains_AreAcyclic()
    {
        using JsonDocument json = LoadResearchJson();
        JsonElement research = json.RootElement.GetProperty("research");

        var dependencies = new Dictionary<string, List<string>>();
        foreach (JsonElement entry in research.EnumerateArray())
        {
            string id = entry.GetProperty("id").GetString() ?? "";
            Assert.False(string.IsNullOrWhiteSpace(id), "Each research entry must define a non-empty id.");
            Assert.False(dependencies.ContainsKey(id), $"Duplicate research id '{id}' found in research.json.");

            var requires = new List<string>();
            foreach (JsonElement prereq in entry.GetProperty("requires").EnumerateArray())
            {
                string prereqId = prereq.GetString() ?? "";
                Assert.False(string.IsNullOrWhiteSpace(prereqId), $"Research '{id}' has an empty prerequisite id.");
                requires.Add(prereqId);
            }

            dependencies[id] = requires;
        }

        foreach (var (id, requires) in dependencies)
        {
            foreach (string prereq in requires)
            {
                Assert.True(dependencies.ContainsKey(prereq), $"Research '{id}' requires unknown research '{prereq}'.");
            }
        }

        var visiting = new HashSet<string>();
        var visited = new HashSet<string>();

        bool HasCycle(string id)
        {
            if (visited.Contains(id))
            {
                return false;
            }

            if (!visiting.Add(id))
            {
                return true;
            }

            foreach (string prereq in dependencies[id])
            {
                if (HasCycle(prereq))
                {
                    return true;
                }
            }

            visiting.Remove(id);
            visited.Add(id);
            return false;
        }

        foreach (string id in dependencies.Keys)
        {
            Assert.False(HasCycle(id), $"Cycle detected in research.json prerequisite graph starting at '{id}'.");
        }
    }

    [Fact]
    public void StartAndAdvanceResearch_HappyPath_CompletesResearch()
    {
        const string researchId = "improved_walls";
        var def = Assert.IsType<ResearchDef>(ResearchData.GetResearch(researchId));

        var state = new GameState
        {
            Gold = def.GoldCost + 25,
        };

        bool started = ResearchData.StartResearch(state, researchId);

        Assert.True(started);
        Assert.Equal(researchId, state.ActiveResearch);
        Assert.Equal(0, state.ResearchProgress);
        Assert.Equal(25, state.Gold);

        for (int i = 0; i < def.WavesRequired - 1; i++)
        {
            bool completedEarly = ResearchData.AdvanceResearch(state);
            Assert.False(completedEarly);
        }

        bool completed = ResearchData.AdvanceResearch(state);

        Assert.True(completed);
        Assert.Equal("", state.ActiveResearch);
        Assert.Equal(0, state.ResearchProgress);
        Assert.Contains(researchId, state.CompletedResearch);
    }

    private static JsonDocument LoadResearchJson()
    {
        string dataDirectory = FindDataDirectory();
        string researchPath = Path.Combine(dataDirectory, "research.json");
        return JsonDocument.Parse(File.ReadAllText(researchPath));
    }

    private static string FindDataDirectory()
    {
        string dir = AppDomain.CurrentDomain.BaseDirectory;
        for (int i = 0; i < 10; i++)
        {
            string candidate = Path.Combine(dir, "data");
            if (Directory.Exists(candidate) && File.Exists(Path.Combine(candidate, "research.json")))
            {
                return candidate;
            }

            string parent = Path.GetDirectoryName(dir) ?? dir;
            if (parent == dir)
            {
                break;
            }

            dir = parent;
        }

        throw new DirectoryNotFoundException("Could not locate data/research.json from the test output directory.");
    }
}
