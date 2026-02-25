using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text.Json;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Economy;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Game.Input;

namespace KeyboardDefense.Tests.Core;

[Collection("StaticData")]
public class DataConsistencyTests
{
    private static readonly Lazy<DataSnapshot> Snapshot = new(CreateSnapshot);

    private static readonly IReadOnlyDictionary<string, string> ShiftedKeyMap = new Dictionary<string, string>(StringComparer.Ordinal)
    {
        ["`"] = "~",
        ["1"] = "!",
        ["2"] = "@",
        ["3"] = "#",
        ["4"] = "$",
        ["5"] = "%",
        ["6"] = "^",
        ["7"] = "&",
        ["8"] = "*",
        ["9"] = "(",
        ["0"] = ")",
        ["-"] = "_",
        ["="] = "+",
        ["["] = "{",
        ["]"] = "}",
        ["\\"] = "|",
        [";"] = ":",
        ["'"] = "\"",
        [","] = "<",
        ["."] = ">",
        ["/"] = "?",
    };

    [Fact]
    public void DataFiles_AllJsonFiles_ParseSuccessfully()
    {
        DataSnapshot snapshot = Snapshot.Value;
        Assert.True(snapshot.Roots.Count >= 30, $"Expected at least 30 JSON files under data/, found {snapshot.Roots.Count}.");

        foreach (var (relativePath, root) in snapshot.Roots)
        {
            Assert.True(
                root.ValueKind is JsonValueKind.Object or JsonValueKind.Array,
                $"{relativePath} root must be an object or array, but was {root.ValueKind}.");
        }
    }

    [Fact]
    public void Scenarios_EnemyReferencesResolveToEnemyTypeRegistry()
    {
        JsonElement scenariosRoot = Snapshot.Value.GetRootByFileName("scenarios.json");
        HashSet<string> referencedKinds = CollectScenarioEnemyKindReferences(scenariosRoot);
        HashSet<string> knownKinds = EnemyTypes.Registry.Keys.ToHashSet(StringComparer.Ordinal);

        Assert.NotEmpty(knownKinds);

        foreach (string referencedKind in referencedKinds)
        {
            Assert.Contains(
                referencedKind,
                knownKinds);
        }

        int enemyMetricCount = CountEnemyMetricEntriesInScenarios(scenariosRoot);
        Assert.True(
            referencedKinds.Count > 0 || enemyMetricCount > 0,
            "scenarios.json should reference enemy types explicitly or include enemy metrics in expectations.");
    }

    [Fact]
    public void Scenarios_EnemyReferencesResolveToEnemyFactoryData()
    {
        JsonElement scenariosRoot = Snapshot.Value.GetRootByFileName("scenarios.json");
        HashSet<string> referencedKinds = CollectScenarioEnemyKindReferences(scenariosRoot);
        HashSet<string> knownKinds = Enemies.EnemyKinds.Keys
            .Concat(Enemies.BossKinds.Keys)
            .ToHashSet(StringComparer.Ordinal);

        Assert.NotEmpty(knownKinds);

        foreach (string referencedKind in referencedKinds)
        {
            Assert.Contains(
                referencedKind,
                knownKinds);
        }
    }

    [Fact]
    public void Buildings_TowerTypeReferencesHaveMatchingDefinitions()
    {
        JsonElement buildingsRoot = Snapshot.Value.GetRootByFileName("buildings.json");
        JsonElement buildingsNode = GetRequiredProperty(buildingsRoot, "buildings", JsonValueKind.Object, "buildings.json");

        JsonElement towersRoot = Snapshot.Value.GetRootByFileName("towers.json");
        JsonElement towersNode = GetRequiredProperty(towersRoot, "towers", JsonValueKind.Object, "towers.json");

        HashSet<string> towerJsonIds = towersNode.EnumerateObject().Select(prop => prop.Name).ToHashSet(StringComparer.Ordinal);
        HashSet<string> runtimeTowerIds = TowerTypes.TowerStats.Keys.ToHashSet(StringComparer.Ordinal);
        HashSet<string> explicitTowerRefs = CollectTowerTypeReferencesFromBuildings(buildingsNode);

        foreach (string towerRef in explicitTowerRefs)
        {
            Assert.Contains(
                towerRef,
                towerJsonIds);

            if (!towerRef.StartsWith("tower_", StringComparison.Ordinal))
            {
                continue;
            }

            string runtimeId = NormalizeTowerRuntimeId(towerRef);
            Assert.Contains(
                runtimeId,
                runtimeTowerIds);
        }

        bool hasCombatStats = buildingsNode.EnumerateObject()
            .Any(prop => prop.Value.TryGetProperty("combat_stats", out JsonElement statsNode) && statsNode.ValueKind == JsonValueKind.Object);

        Assert.True(
            explicitTowerRefs.Count > 0 || hasCombatStats,
            "buildings.json should contain explicit tower type references or tower-style combat stats.");
    }

    [Fact]
    public void Buildings_InternalBuildingReferencesResolveToKnownBuildingIds()
    {
        JsonElement buildingsRoot = Snapshot.Value.GetRootByFileName("buildings.json");
        JsonElement buildingsNode = GetRequiredProperty(buildingsRoot, "buildings", JsonValueKind.Object, "buildings.json");

        HashSet<string> buildingIds = buildingsNode.EnumerateObject().Select(prop => prop.Name).ToHashSet(StringComparer.Ordinal);
        Assert.NotEmpty(buildingIds);

        int referenceCount = 0;
        foreach (JsonProperty building in buildingsNode.EnumerateObject())
        {
            foreach (string referencedId in CollectBuildingIdReferences(building.Value))
            {
                referenceCount++;
                Assert.Contains(
                    referencedId,
                    buildingIds);
            }
        }

        Assert.True(referenceCount > 0, "Expected at least one building-to-building reference in buildings.json.");
    }

    [Fact]
    public void QuestRewardItems_ExistInItemsDefinitions()
    {
        JsonElement buildingsRoot = Snapshot.Value.GetRootByFileName("buildings.json");
        JsonElement resourcesNode = GetRequiredProperty(buildingsRoot, "resources", JsonValueKind.Object, "buildings.json");
        HashSet<string> resourceKeys = resourcesNode.EnumerateObject().Select(prop => prop.Name).ToHashSet(StringComparer.Ordinal);

        HashSet<string> nonItemRewardKeys = new(resourceKeys, StringComparer.Ordinal)
        {
            "gold",
            "skill_point",
        };

        HashSet<string> itemIds = Items.Equipment.Keys
            .Concat(Items.Consumables.Keys)
            .ToHashSet(StringComparer.Ordinal);

        Assert.NotEmpty(Quests.Registry);
        Assert.NotEmpty(itemIds);

        foreach (var (questId, questDef) in Quests.Registry)
        {
            foreach (var (rewardKey, rewardAmount) in questDef.Rewards)
            {
                Assert.True(rewardAmount > 0, $"Quest '{questId}' reward '{rewardKey}' must be positive.");

                if (nonItemRewardKeys.Contains(rewardKey))
                {
                    continue;
                }

                Assert.Contains(
                    rewardKey,
                    itemIds);
            }
        }
    }

    [Fact]
    public void ResearchJson_PrerequisitesReferenceValidResearchIds()
    {
        JsonElement researchRoot = Snapshot.Value.GetRootByFileName("research.json");
        JsonElement researchNode = GetRequiredProperty(researchRoot, "research", JsonValueKind.Array, "research.json");

        HashSet<string> ids = researchNode.EnumerateArray()
            .Select(entry => GetRequiredString(entry, "id", "research.json"))
            .ToHashSet(StringComparer.Ordinal);

        Assert.NotEmpty(ids);

        foreach (JsonElement entry in researchNode.EnumerateArray())
        {
            string id = GetRequiredString(entry, "id", "research.json");
            JsonElement requiresNode = GetRequiredProperty(entry, "requires", JsonValueKind.Array, $"research.json:{id}");

            foreach (JsonElement prerequisite in requiresNode.EnumerateArray())
            {
                string prerequisiteId = ReadStringValue(prerequisite, $"research.json:{id}.requires[]");
                Assert.Contains(
                    prerequisiteId,
                    ids);
            }
        }
    }

    [Fact]
    public void ResearchRegistry_PrerequisitesReferenceValidResearchIds()
    {
        Assert.NotEmpty(ResearchData.Registry);

        foreach (var (id, def) in ResearchData.Registry)
        {
            if (string.IsNullOrWhiteSpace(def.Prerequisite))
            {
                continue;
            }

            Assert.True(
                ResearchData.Registry.ContainsKey(def.Prerequisite),
                $"ResearchData.Registry entry '{id}' references missing prerequisite '{def.Prerequisite}'.");
        }
    }

    [Fact]
    public void Lessons_CharacterSetsAreSubsetOfKeyboardLayout()
    {
        JsonElement lessonsRoot = Snapshot.Value.GetRootByFileName("lessons.json");
        JsonElement lessonsNode = GetRequiredProperty(lessonsRoot, "lessons", JsonValueKind.Array, "lessons.json");
        HashSet<string> supportedChars = BuildSupportedKeyboardCharset();

        int checkedLessonCount = 0;
        foreach (JsonElement lesson in lessonsNode.EnumerateArray())
        {
            string mode = TryGetString(lesson, "mode") ?? "charset";
            if (!string.Equals(mode, "charset", StringComparison.Ordinal))
            {
                continue;
            }

            string lessonId = TryGetString(lesson, "id") ?? "<unknown-lesson>";
            string charset = TryGetString(lesson, "charset") ?? string.Empty;

            checkedLessonCount++;
            foreach (char c in charset)
            {
                string value = c.ToString();
                Assert.Contains(
                    value,
                    supportedChars);
            }
        }

        Assert.True(checkedLessonCount > 0, "Expected at least one charset lesson in lessons.json.");
    }

    [Fact]
    public void NpcFactionIds_MatchFactionsDefinitions()
    {
        JsonElement factionsRoot = Snapshot.Value.GetRootByFileName("factions.json");
        JsonElement factionsNode = GetRequiredProperty(factionsRoot, "factions", JsonValueKind.Object, "factions.json");
        HashSet<string> knownFactionIds = factionsNode.EnumerateObject().Select(prop => prop.Name).ToHashSet(StringComparer.Ordinal);

        Assert.NotEmpty(knownFactionIds);

        HashSet<string> referencedFactionIds = new(StringComparer.Ordinal);
        foreach (var (relativePath, root) in Snapshot.Value.Roots)
        {
            if (relativePath.EndsWith("/factions.json", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(relativePath, "factions.json", StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            CollectNpcFactionIds(root, inNpcContext: false, referencedFactionIds);
        }

        foreach (string referencedFactionId in referencedFactionIds)
        {
            Assert.Contains(
                referencedFactionId,
                knownFactionIds);
        }
    }

    [Fact]
    public void Buildings_CostAndProductionResourceKeysUseValidResources()
    {
        JsonElement buildingsRoot = Snapshot.Value.GetRootByFileName("buildings.json");
        JsonElement resourcesNode = GetRequiredProperty(buildingsRoot, "resources", JsonValueKind.Object, "buildings.json");
        JsonElement buildingsNode = GetRequiredProperty(buildingsRoot, "buildings", JsonValueKind.Object, "buildings.json");

        HashSet<string> validResourceKeys = resourcesNode.EnumerateObject().Select(prop => prop.Name).ToHashSet(StringComparer.Ordinal);
        Assert.NotEmpty(validResourceKeys);

        foreach (JsonProperty building in buildingsNode.EnumerateObject())
        {
            string context = $"buildings.json:{building.Name}";
            JsonElement costNode = GetRequiredProperty(building.Value, "cost", JsonValueKind.Object, context);
            ValidateResourceMapKeys(costNode, validResourceKeys, $"{context}.cost");

            if (building.Value.TryGetProperty("production", out JsonElement productionNode))
            {
                Assert.Equal(JsonValueKind.Object, productionNode.ValueKind);
                ValidateResourceMapKeys(productionNode, validResourceKeys, $"{context}.production");
            }
        }
    }

    [Fact]
    public void BuildingUpgrades_ReferenceKnownBuildings_AndUseValidResourceKeys()
    {
        JsonElement buildingsRoot = Snapshot.Value.GetRootByFileName("buildings.json");
        JsonElement buildingUpgradesRoot = Snapshot.Value.GetRootByFileName("building_upgrades.json");

        JsonElement buildingsNode = GetRequiredProperty(buildingsRoot, "buildings", JsonValueKind.Object, "buildings.json");
        JsonElement resourcesNode = GetRequiredProperty(buildingsRoot, "resources", JsonValueKind.Object, "buildings.json");
        JsonElement upgradesNode = GetRequiredProperty(buildingUpgradesRoot, "upgrades", JsonValueKind.Object, "building_upgrades.json");

        HashSet<string> buildingIds = buildingsNode.EnumerateObject().Select(prop => prop.Name).ToHashSet(StringComparer.Ordinal);
        HashSet<string> validResourceKeys = resourcesNode.EnumerateObject().Select(prop => prop.Name).ToHashSet(StringComparer.Ordinal);

        Assert.NotEmpty(buildingIds);
        Assert.NotEmpty(validResourceKeys);

        foreach (JsonProperty upgradeEntry in upgradesNode.EnumerateObject())
        {
            string buildingId = upgradeEntry.Name;
            Assert.Contains(
                buildingId,
                buildingIds);

            string context = $"building_upgrades.json:{buildingId}";
            JsonElement levelsNode = GetRequiredProperty(upgradeEntry.Value, "levels", JsonValueKind.Object, context);

            foreach (JsonProperty levelEntry in levelsNode.EnumerateObject())
            {
                string levelContext = $"{context}.levels[{levelEntry.Name}]";
                if (levelEntry.Value.TryGetProperty("cost", out JsonElement costNode))
                {
                    Assert.Equal(JsonValueKind.Object, costNode.ValueKind);
                    ValidateResourceMapKeys(costNode, validResourceKeys, $"{levelContext}.cost");
                }

                if (levelEntry.Value.TryGetProperty("production", out JsonElement productionNode))
                {
                    Assert.Equal(JsonValueKind.Object, productionNode.ValueKind);
                    ValidateResourceMapKeys(productionNode, validResourceKeys, $"{levelContext}.production");
                }
            }
        }
    }

    [Fact]
    public void DrillTemplates_NoOrphanEntriesRelativeToMapNodes()
    {
        JsonElement drillsRoot = Snapshot.Value.GetRootByFileName("drills.json");
        JsonElement mapRoot = Snapshot.Value.GetRootByFileName("map.json");

        JsonElement templatesNode = GetRequiredProperty(drillsRoot, "templates", JsonValueKind.Array, "drills.json");
        JsonElement mapNodes = GetRequiredProperty(mapRoot, "nodes", JsonValueKind.Array, "map.json");

        HashSet<string> drillTemplateIds = templatesNode.EnumerateArray()
            .Select(node => GetRequiredString(node, "id", "drills.json.templates[]"))
            .ToHashSet(StringComparer.Ordinal);

        HashSet<string> mapTemplateRefs = mapNodes.EnumerateArray()
            .Select(node => GetRequiredString(node, "drill_template", "map.json.nodes[]"))
            .ToHashSet(StringComparer.Ordinal);

        Assert.NotEmpty(drillTemplateIds);
        Assert.NotEmpty(mapTemplateRefs);

        foreach (string templateRef in mapTemplateRefs)
        {
            Assert.Contains(
                templateRef,
                drillTemplateIds);
        }

        List<string> orphanTemplates = drillTemplateIds
            .Where(id => !mapTemplateRefs.Contains(id))
            .OrderBy(id => id, StringComparer.Ordinal)
            .ToList();

        Assert.Empty(orphanTemplates);
    }

    [Fact]
    public void Lessons_NoOrphanEntriesAcrossContentReferences()
    {
        JsonElement lessonsRoot = Snapshot.Value.GetRootByFileName("lessons.json");
        JsonElement mapRoot = Snapshot.Value.GetRootByFileName("map.json");
        JsonElement storyRoot = Snapshot.Value.GetRootByFileName("story.json");

        JsonElement lessonsNode = GetRequiredProperty(lessonsRoot, "lessons", JsonValueKind.Array, "lessons.json");
        HashSet<string> lessonIds = lessonsNode.EnumerateArray()
            .Select(node => GetRequiredString(node, "id", "lessons.json.lessons[]"))
            .ToHashSet(StringComparer.Ordinal);

        HashSet<string> referencedLessonIds = new(StringComparer.Ordinal);

        string defaultLesson = GetRequiredString(lessonsRoot, "default_lesson", "lessons.json");
        referencedLessonIds.Add(defaultLesson);

        JsonElement graduationPaths = GetRequiredProperty(lessonsRoot, "graduation_paths", JsonValueKind.Object, "lessons.json");
        foreach (JsonProperty pathEntry in graduationPaths.EnumerateObject())
        {
            JsonElement stagesNode = GetRequiredProperty(pathEntry.Value, "stages", JsonValueKind.Array, $"lessons.json.graduation_paths.{pathEntry.Name}");
            foreach (JsonElement stage in stagesNode.EnumerateArray())
            {
                JsonElement stageLessons = GetRequiredProperty(stage, "lessons", JsonValueKind.Array, $"lessons.json.graduation_paths.{pathEntry.Name}.stages[]");
                foreach (JsonElement lessonRef in stageLessons.EnumerateArray())
                {
                    referencedLessonIds.Add(ReadStringValue(lessonRef, "lessons.json graduation path lesson reference"));
                }
            }
        }

        JsonElement mapNodes = GetRequiredProperty(mapRoot, "nodes", JsonValueKind.Array, "map.json");
        foreach (JsonElement mapNode in mapNodes.EnumerateArray())
        {
            referencedLessonIds.Add(GetRequiredString(mapNode, "lesson_id", "map.json.nodes[]"));
        }

        JsonElement actsNode = GetRequiredProperty(storyRoot, "acts", JsonValueKind.Array, "story.json");
        foreach (JsonElement act in actsNode.EnumerateArray())
        {
            JsonElement actLessons = GetRequiredProperty(act, "lessons", JsonValueKind.Array, "story.json.acts[]");
            foreach (JsonElement lessonRef in actLessons.EnumerateArray())
            {
                referencedLessonIds.Add(ReadStringValue(lessonRef, "story.json acts lesson reference"));
            }
        }

        JsonElement introductionsNode = GetRequiredProperty(storyRoot, "lesson_introductions", JsonValueKind.Object, "story.json");
        foreach (JsonProperty introduction in introductionsNode.EnumerateObject())
        {
            referencedLessonIds.Add(introduction.Name);
        }

        foreach (string reference in referencedLessonIds)
        {
            Assert.Contains(
                reference,
                lessonIds);
        }

        List<string> orphanLessons = lessonIds
            .Where(id => !referencedLessonIds.Contains(id))
            .OrderBy(id => id, StringComparer.Ordinal)
            .ToList();

        Assert.Empty(orphanLessons);
    }

    [Fact]
    public void MapNodes_NoOrphanEntriesInDependencyGraph()
    {
        JsonElement mapRoot = Snapshot.Value.GetRootByFileName("map.json");
        JsonElement nodes = GetRequiredProperty(mapRoot, "nodes", JsonValueKind.Array, "map.json");

        var requiresByNodeId = new Dictionary<string, List<string>>(StringComparer.Ordinal);
        foreach (JsonElement node in nodes.EnumerateArray())
        {
            string id = GetRequiredString(node, "id", "map.json.nodes[]");
            JsonElement requiresNode = GetRequiredProperty(node, "requires", JsonValueKind.Array, $"map.json:{id}");

            requiresByNodeId[id] = requiresNode.EnumerateArray()
                .Select(item => ReadStringValue(item, $"map.json:{id}.requires[]"))
                .ToList();
        }

        Assert.NotEmpty(requiresByNodeId);

        foreach (var (id, requires) in requiresByNodeId)
        {
            foreach (string requiredNodeId in requires)
            {
                Assert.True(
                    requiresByNodeId.ContainsKey(requiredNodeId),
                    $"Map node '{id}' requires unknown node '{requiredNodeId}'.");
            }
        }

        var dependentsByNodeId = requiresByNodeId.Keys.ToDictionary(
            key => key,
            _ => new List<string>(),
            StringComparer.Ordinal);

        foreach (var (id, requires) in requiresByNodeId)
        {
            foreach (string requiredNodeId in requires)
            {
                dependentsByNodeId[requiredNodeId].Add(id);
            }
        }

        List<string> roots = requiresByNodeId
            .Where(pair => pair.Value.Count == 0)
            .Select(pair => pair.Key)
            .ToList();

        Assert.NotEmpty(roots);

        HashSet<string> reachable = new(StringComparer.Ordinal);
        Queue<string> queue = new();
        foreach (string rootId in roots)
        {
            if (reachable.Add(rootId))
            {
                queue.Enqueue(rootId);
            }
        }

        while (queue.Count > 0)
        {
            string current = queue.Dequeue();
            foreach (string dependent in dependentsByNodeId[current])
            {
                if (reachable.Add(dependent))
                {
                    queue.Enqueue(dependent);
                }
            }
        }

        List<string> unreachableNodes = requiresByNodeId.Keys
            .Where(id => !reachable.Contains(id))
            .OrderBy(id => id, StringComparer.Ordinal)
            .ToList();

        Assert.Empty(unreachableNodes);
    }

    private static void ValidateResourceMapKeys(JsonElement resourceMap, HashSet<string> validKeys, string context)
    {
        foreach (JsonProperty entry in resourceMap.EnumerateObject())
        {
            Assert.Contains(
                entry.Name,
                validKeys);
            Assert.True(
                entry.Value.ValueKind == JsonValueKind.Number,
                $"{context}.{entry.Name} must be numeric.");
        }
    }

    private static HashSet<string> CollectScenarioEnemyKindReferences(JsonElement scenariosRoot)
    {
        JsonElement scenariosNode = GetRequiredProperty(scenariosRoot, "scenarios", JsonValueKind.Array, "scenarios.json");
        HashSet<string> kinds = new(StringComparer.Ordinal);

        foreach (JsonElement scenario in scenariosNode.EnumerateArray())
        {
            foreach (string expectationName in new[] { "expect_baseline", "expect_target" })
            {
                if (!scenario.TryGetProperty(expectationName, out JsonElement expectationNode) ||
                    expectationNode.ValueKind != JsonValueKind.Object)
                {
                    continue;
                }

                foreach (JsonProperty metric in expectationNode.EnumerateObject())
                {
                    if (metric.Name.StartsWith("enemies_by_type.", StringComparison.OrdinalIgnoreCase))
                    {
                        string kind = NormalizeToken(metric.Name["enemies_by_type.".Length..]);
                        if (!string.IsNullOrWhiteSpace(kind))
                        {
                            kinds.Add(kind);
                        }
                    }

                    if (metric.Name.StartsWith("enemies_by_kind.", StringComparison.OrdinalIgnoreCase))
                    {
                        string kind = NormalizeToken(metric.Name["enemies_by_kind.".Length..]);
                        if (!string.IsNullOrWhiteSpace(kind))
                        {
                            kinds.Add(kind);
                        }
                    }

                    if (metric.Name.Contains("enemy_kind", StringComparison.OrdinalIgnoreCase) &&
                        metric.Value.ValueKind == JsonValueKind.Object &&
                        metric.Value.TryGetProperty("eq", out JsonElement eqValue) &&
                        eqValue.ValueKind == JsonValueKind.String)
                    {
                        string kind = NormalizeToken(eqValue.GetString() ?? string.Empty);
                        if (!string.IsNullOrWhiteSpace(kind))
                        {
                            kinds.Add(kind);
                        }
                    }
                }
            }

            if (!scenario.TryGetProperty("script", out JsonElement scriptNode) || scriptNode.ValueKind != JsonValueKind.Array)
            {
                continue;
            }

            foreach (JsonElement commandNode in scriptNode.EnumerateArray())
            {
                if (commandNode.ValueKind != JsonValueKind.String)
                {
                    continue;
                }

                string command = commandNode.GetString() ?? string.Empty;
                string[] tokens = command.Split(' ', StringSplitOptions.RemoveEmptyEntries);
                if (tokens.Length < 2)
                {
                    continue;
                }

                if (tokens[0].Equals("spawn", StringComparison.OrdinalIgnoreCase) ||
                    tokens[0].Equals("spawn_enemy", StringComparison.OrdinalIgnoreCase) ||
                    tokens[0].Equals("enemy", StringComparison.OrdinalIgnoreCase))
                {
                    string kind = NormalizeToken(tokens[1]);
                    if (!string.IsNullOrWhiteSpace(kind))
                    {
                        kinds.Add(kind);
                    }
                }
            }
        }

        return kinds;
    }

    private static int CountEnemyMetricEntriesInScenarios(JsonElement scenariosRoot)
    {
        JsonElement scenariosNode = GetRequiredProperty(scenariosRoot, "scenarios", JsonValueKind.Array, "scenarios.json");
        int count = 0;

        foreach (JsonElement scenario in scenariosNode.EnumerateArray())
        {
            foreach (string expectationName in new[] { "expect_baseline", "expect_target" })
            {
                if (!scenario.TryGetProperty(expectationName, out JsonElement expectationNode) ||
                    expectationNode.ValueKind != JsonValueKind.Object)
                {
                    continue;
                }

                count += expectationNode.EnumerateObject()
                    .Count(metric =>
                        metric.Name.Contains("enemy", StringComparison.OrdinalIgnoreCase) ||
                        metric.Name.Contains("enemies", StringComparison.OrdinalIgnoreCase));
            }
        }

        return count;
    }

    private static HashSet<string> CollectTowerTypeReferencesFromBuildings(JsonElement buildingsNode)
    {
        HashSet<string> towerReferences = new(StringComparer.Ordinal);
        foreach (JsonProperty building in buildingsNode.EnumerateObject())
        {
            CollectTowerTypeReferencesFromNode(building.Value, parentPropertyName: null, towerReferences);
        }

        return towerReferences;
    }

    private static void CollectTowerTypeReferencesFromNode(JsonElement node, string? parentPropertyName, HashSet<string> output)
    {
        switch (node.ValueKind)
        {
            case JsonValueKind.Object:
                foreach (JsonProperty property in node.EnumerateObject())
                {
                    CollectTowerTypeReferencesFromNode(property.Value, property.Name, output);
                }

                break;

            case JsonValueKind.Array:
                foreach (JsonElement item in node.EnumerateArray())
                {
                    CollectTowerTypeReferencesFromNode(item, parentPropertyName, output);
                }

                break;

            case JsonValueKind.String:
                string value = node.GetString() ?? string.Empty;
                if (string.IsNullOrWhiteSpace(value))
                {
                    return;
                }

                if (value.StartsWith("tower_", StringComparison.Ordinal) || IsExplicitTowerReferenceProperty(parentPropertyName))
                {
                    output.Add(value);
                }

                break;
        }
    }

    private static bool IsExplicitTowerReferenceProperty(string? propertyName)
    {
        if (string.IsNullOrWhiteSpace(propertyName))
        {
            return false;
        }

        return propertyName.Equals("tower_type", StringComparison.OrdinalIgnoreCase)
            || propertyName.Equals("tower_types", StringComparison.OrdinalIgnoreCase)
            || propertyName.Equals("tower_id", StringComparison.OrdinalIgnoreCase)
            || propertyName.Equals("tower_ids", StringComparison.OrdinalIgnoreCase)
            || propertyName.Equals("tower_ref", StringComparison.OrdinalIgnoreCase)
            || propertyName.Equals("tower_refs", StringComparison.OrdinalIgnoreCase)
            || propertyName.Equals("unlocks_tower", StringComparison.OrdinalIgnoreCase)
            || propertyName.Equals("unlock_tower", StringComparison.OrdinalIgnoreCase)
            || propertyName.Equals("unlock_towers", StringComparison.OrdinalIgnoreCase);
    }

    private static string NormalizeTowerRuntimeId(string towerJsonId)
    {
        if (towerJsonId.StartsWith("tower_legendary_", StringComparison.Ordinal))
        {
            return towerJsonId["tower_legendary_".Length..];
        }

        if (towerJsonId.StartsWith("tower_", StringComparison.Ordinal))
        {
            return towerJsonId["tower_".Length..];
        }

        return towerJsonId;
    }

    private static IEnumerable<string> CollectBuildingIdReferences(JsonElement buildingNode)
    {
        if (buildingNode.TryGetProperty("requires", out JsonElement requiresNode) &&
            requiresNode.ValueKind == JsonValueKind.Array)
        {
            foreach (JsonElement item in requiresNode.EnumerateArray())
            {
                if (item.ValueKind == JsonValueKind.String && !string.IsNullOrWhiteSpace(item.GetString()))
                {
                    yield return item.GetString()!;
                }
            }
        }

        if (buildingNode.TryGetProperty("unlocks", out JsonElement unlocksNode) &&
            unlocksNode.ValueKind == JsonValueKind.Array)
        {
            foreach (JsonElement item in unlocksNode.EnumerateArray())
            {
                if (item.ValueKind == JsonValueKind.String && !string.IsNullOrWhiteSpace(item.GetString()))
                {
                    yield return item.GetString()!;
                }
            }
        }

        if (buildingNode.TryGetProperty("adjacency_bonus", out JsonElement adjacencyNode) &&
            adjacencyNode.ValueKind == JsonValueKind.Object &&
            adjacencyNode.TryGetProperty("building", out JsonElement buildingRefsNode) &&
            buildingRefsNode.ValueKind == JsonValueKind.Object)
        {
            foreach (JsonProperty reference in buildingRefsNode.EnumerateObject())
            {
                if (!string.Equals(reference.Name, "*", StringComparison.Ordinal))
                {
                    yield return reference.Name;
                }
            }
        }
    }

    private static void CollectNpcFactionIds(JsonElement node, bool inNpcContext, HashSet<string> output)
    {
        switch (node.ValueKind)
        {
            case JsonValueKind.Array:
                foreach (JsonElement item in node.EnumerateArray())
                {
                    CollectNpcFactionIds(item, inNpcContext, output);
                }

                return;

            case JsonValueKind.Object:
                bool localNpcContext = inNpcContext || NodeLooksLikeNpc(node);
                foreach (JsonProperty property in node.EnumerateObject())
                {
                    if (localNpcContext && IsFactionIdProperty(property.Name))
                    {
                        AddFactionIds(property.Value, output);
                    }

                    bool childNpcContext = localNpcContext || property.Name.Contains("npc", StringComparison.OrdinalIgnoreCase);
                    CollectNpcFactionIds(property.Value, childNpcContext, output);
                }

                return;
        }
    }

    private static bool NodeLooksLikeNpc(JsonElement node)
    {
        if (node.TryGetProperty("type", out JsonElement typeNode) &&
            typeNode.ValueKind == JsonValueKind.String &&
            (typeNode.GetString() ?? string.Empty).Contains("npc", StringComparison.OrdinalIgnoreCase))
        {
            return true;
        }

        if (node.TryGetProperty("npc_type", out JsonElement npcTypeNode) && npcTypeNode.ValueKind == JsonValueKind.String)
        {
            return true;
        }

        return node.TryGetProperty("npcs", out _);
    }

    private static bool IsFactionIdProperty(string propertyName)
    {
        return propertyName.Equals("faction_id", StringComparison.OrdinalIgnoreCase)
            || propertyName.Equals("faction", StringComparison.OrdinalIgnoreCase)
            || propertyName.Equals("factionid", StringComparison.OrdinalIgnoreCase)
            || propertyName.Equals("npc_faction_id", StringComparison.OrdinalIgnoreCase)
            || propertyName.Equals("faction_ids", StringComparison.OrdinalIgnoreCase)
            || propertyName.Equals("factions", StringComparison.OrdinalIgnoreCase);
    }

    private static void AddFactionIds(JsonElement node, HashSet<string> output)
    {
        if (node.ValueKind == JsonValueKind.String)
        {
            string value = node.GetString() ?? string.Empty;
            if (!string.IsNullOrWhiteSpace(value))
            {
                output.Add(value);
            }

            return;
        }

        if (node.ValueKind == JsonValueKind.Array)
        {
            foreach (JsonElement item in node.EnumerateArray())
            {
                if (item.ValueKind == JsonValueKind.String)
                {
                    string value = item.GetString() ?? string.Empty;
                    if (!string.IsNullOrWhiteSpace(value))
                    {
                        output.Add(value);
                    }
                }
            }
        }
    }

    private static HashSet<string> BuildSupportedKeyboardCharset()
    {
        FieldInfo? rowsField = typeof(KeyboardDisplay).GetField("Rows", BindingFlags.NonPublic | BindingFlags.Static);
        Assert.NotNull(rowsField);

        string[][]? rows = rowsField!.GetValue(null) as string[][];
        Assert.NotNull(rows);

        HashSet<string> charset = new(StringComparer.Ordinal);
        foreach (string[] row in rows!)
        {
            foreach (string key in row)
            {
                if (string.IsNullOrEmpty(key))
                {
                    continue;
                }

                if (key.Length == 1)
                {
                    charset.Add(key);
                    if (char.IsLetter(key[0]))
                    {
                        charset.Add(char.ToUpperInvariant(key[0]).ToString());
                    }
                }

                if (ShiftedKeyMap.TryGetValue(key, out string? shifted))
                {
                    charset.Add(shifted);
                }
            }
        }

        return charset;
    }

    private static JsonElement GetRequiredProperty(JsonElement node, string propertyName, JsonValueKind expectedKind, string context)
    {
        Assert.Equal(JsonValueKind.Object, node.ValueKind);
        Assert.True(node.TryGetProperty(propertyName, out JsonElement value), $"{context} missing required property '{propertyName}'.");
        Assert.Equal(expectedKind, value.ValueKind);
        return value;
    }

    private static string GetRequiredString(JsonElement node, string propertyName, string context)
    {
        JsonElement value = GetRequiredProperty(node, propertyName, JsonValueKind.String, context);
        string? result = value.GetString();
        Assert.False(string.IsNullOrWhiteSpace(result), $"{context}.{propertyName} must be a non-empty string.");
        return result!;
    }

    private static string? TryGetString(JsonElement node, string propertyName)
    {
        if (!node.TryGetProperty(propertyName, out JsonElement value) || value.ValueKind != JsonValueKind.String)
        {
            return null;
        }

        return value.GetString();
    }

    private static string ReadStringValue(JsonElement node, string context)
    {
        Assert.Equal(JsonValueKind.String, node.ValueKind);
        string? value = node.GetString();
        Assert.False(string.IsNullOrWhiteSpace(value), $"{context} must contain a non-empty string value.");
        return value!;
    }

    private static string NormalizeToken(string value)
        => value.Trim().Trim(',', '.', ';', ':', '[', ']', '(', ')', '"', '\'').ToLowerInvariant();

    private static DataSnapshot CreateSnapshot()
    {
        string dataDirectory = ResolveDataDirectory();
        var roots = new Dictionary<string, JsonElement>(StringComparer.OrdinalIgnoreCase);

        foreach (string path in Directory.EnumerateFiles(dataDirectory, "*.json", SearchOption.AllDirectories))
        {
            string relativePath = NormalizePath(Path.GetRelativePath(dataDirectory, path));
            try
            {
                using JsonDocument document = JsonDocument.Parse(File.ReadAllText(path));
                roots[relativePath] = document.RootElement.Clone();
            }
            catch (Exception ex)
            {
                throw new InvalidDataException($"Failed to parse JSON file '{relativePath}'.", ex);
            }
        }

        return new DataSnapshot(dataDirectory, roots);
    }

    private static string ResolveDataDirectory()
    {
        string? dir = AppDomain.CurrentDomain.BaseDirectory;
        for (int i = 0; i < 12 && !string.IsNullOrWhiteSpace(dir); i++)
        {
            string candidate = Path.Combine(dir, "data");
            if (Directory.Exists(candidate) && File.Exists(Path.Combine(candidate, "scenarios.json")))
            {
                return candidate;
            }

            string? parent = Path.GetDirectoryName(dir);
            if (string.Equals(parent, dir, StringComparison.Ordinal))
            {
                break;
            }

            dir = parent;
        }

        throw new DirectoryNotFoundException("Unable to locate data directory from test output.");
    }

    private static string NormalizePath(string path) => path.Replace('\\', '/');

    private sealed class DataSnapshot
    {
        public DataSnapshot(string dataDirectory, IReadOnlyDictionary<string, JsonElement> roots)
        {
            DataDirectory = dataDirectory;
            Roots = roots;
        }

        public string DataDirectory { get; }

        public IReadOnlyDictionary<string, JsonElement> Roots { get; }

        public JsonElement GetRootByFileName(string fileName)
        {
            var matches = Roots
                .Where(pair => string.Equals(Path.GetFileName(pair.Key), fileName, StringComparison.OrdinalIgnoreCase))
                .Select(pair => pair.Value)
                .ToList();

            Assert.NotEmpty(matches);
            Assert.True(matches.Count == 1, $"Expected a single JSON file named '{fileName}', but found {matches.Count}.");
            return matches[0];
        }
    }
}
