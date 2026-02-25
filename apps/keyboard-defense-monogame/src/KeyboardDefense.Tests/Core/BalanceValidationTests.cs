using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using KeyboardDefense.Core.Balance;
using KeyboardDefense.Core.Combat;

namespace KeyboardDefense.Tests.Core;

public class BalanceValidationTests
{
    private static readonly HashSet<string> AllowedNegativeEffectKeys = new(StringComparer.Ordinal)
    {
        "threat_rate_multiplier",
    };

    private static readonly Dictionary<string, int> ConservativeDailyIncome = new(StringComparer.Ordinal)
    {
        ["wood"] = 20,
        ["stone"] = 12,
        ["food"] = 8,
        ["gold"] = 12,
    };

    [Fact]
    public void TowerDpsScalesProportionallyWithCost_OffensiveTowersHaveStrongPositiveCorrelation()
    {
        List<TowerBalanceRow> offensiveTowers = ReadTowerRows()
            .Where(t => !string.Equals(t.TargetType, "none", StringComparison.OrdinalIgnoreCase))
            .Where(t => t.Damage > 0 && t.AttackSpeed > 0)
            .ToList();

        Assert.True(offensiveTowers.Count >= 10, "Expected at least 10 offensive towers for correlation check.");

        var costs = offensiveTowers.Select(t => (double)t.Cost).ToArray();
        var dps = offensiveTowers.Select(t => t.Dps).ToArray();
        double correlation = ComputePearsonCorrelation(costs, dps);

        Assert.True(
            correlation >= 0.75,
            $"Expected strong positive DPS/cost correlation; got {correlation:F3}.");
    }

    [Fact]
    public void TowerRange_IsFiniteAndPositive_ForCombatTowersInTowersJson()
    {
        var combatTowers = ReadTowerRows()
            .Where(t => !string.Equals(t.TargetType, "none", StringComparison.OrdinalIgnoreCase))
            .ToList();

        Assert.NotEmpty(combatTowers);

        foreach (TowerBalanceRow tower in combatTowers)
        {
            Assert.False(double.IsNaN(tower.Range) || double.IsInfinity(tower.Range), $"Tower '{tower.Id}' has non-finite range.");
            Assert.True(tower.Range > 0, $"Tower '{tower.Id}' has non-positive range: {tower.Range}.");
            Assert.True(tower.Range <= 100, $"Tower '{tower.Id}' range '{tower.Range}' looks effectively unbounded.");
        }
    }

    [Fact]
    public void TowerCooldown_IsPositive_ForCombatTowersInTowersJson()
    {
        var combatTowers = ReadTowerRows()
            .Where(t => !string.Equals(t.TargetType, "none", StringComparison.OrdinalIgnoreCase))
            .ToList();

        Assert.NotEmpty(combatTowers);

        foreach (TowerBalanceRow tower in combatTowers)
        {
            Assert.True(tower.AttackSpeed > 0, $"Tower '{tower.Id}' has zero/negative attack speed: {tower.AttackSpeed}.");
        }
    }

    [Fact]
    public void TowerTypeRegistry_CombatDefinitionsHaveFiniteRangeAndPositiveCooldown()
    {
        var combatTowerDefs = TowerTypes.TowerStats
            .Where(kvp => kvp.Value.Target != TargetType.None)
            .ToList();

        Assert.NotEmpty(combatTowerDefs);

        foreach (var (id, def) in combatTowerDefs)
        {
            Assert.True(def.Range > 0 && def.Range <= 100, $"TowerTypes '{id}' has invalid range: {def.Range}.");
            Assert.True(def.Cooldown > 0f, $"TowerTypes '{id}' has zero/negative cooldown: {def.Cooldown}.");
        }
    }

    [Fact]
    public void EnemyHpScalesReasonablyAcrossTiers_AverageHpIsMonotonic()
    {
        var tiers = EnemyTypes.Registry.Values
            .GroupBy(e => (int)e.Tier)
            .OrderBy(g => g.Key)
            .Select(g => new
            {
                Tier = g.Key,
                AverageHp = g.Average(x => x.Hp),
            })
            .ToList();

        Assert.True(tiers.Count >= 4, "Expected at least four enemy tiers.");

        for (int i = 1; i < tiers.Count; i++)
        {
            Assert.True(
                tiers[i].AverageHp > tiers[i - 1].AverageHp,
                $"Tier {tiers[i].Tier} average HP ({tiers[i].AverageHp:F2}) should be greater than tier {tiers[i - 1].Tier} ({tiers[i - 1].AverageHp:F2}).");
        }
    }

    [Fact]
    public void EnemyHpScalesReasonablyAcrossTiers_HigherTierMinimumStaysAboveLowerTierMaximumBand()
    {
        var tiers = EnemyTypes.Registry.Values
            .GroupBy(e => (int)e.Tier)
            .OrderBy(g => g.Key)
            .Select(g => new
            {
                Tier = g.Key,
                MinHp = g.Min(x => x.Hp),
                MaxHp = g.Max(x => x.Hp),
            })
            .ToList();

        Assert.True(tiers.Count >= 4, "Expected at least four enemy tiers.");

        for (int i = 1; i < tiers.Count; i++)
        {
            double lowerTierMaxBand = tiers[i - 1].MaxHp * 0.75;
            Assert.True(
                tiers[i].MinHp >= lowerTierMaxBand,
                $"Tier {tiers[i].Tier} min HP ({tiers[i].MinHp}) is too low vs tier {tiers[i - 1].Tier} max HP ({tiers[i - 1].MaxHp}).");
        }
    }

    [Fact]
    public void TowerUpgradeCosts_IncreasePerLevel()
    {
        using JsonDocument doc = LoadDataDocument("tower_upgrades.json");
        JsonElement upgrades = doc.RootElement.GetProperty("upgrades");

        foreach (JsonProperty upgrade in upgrades.EnumerateObject())
        {
            JsonElement levels = upgrade.Value.GetProperty("levels");
            List<(int Level, int Cost)> levelCosts = ReadLevelCosts(levels);
            Assert.True(levelCosts.Count >= 2, $"Tower upgrade '{upgrade.Name}' should define at least two paid levels.");

            for (int i = 1; i < levelCosts.Count; i++)
            {
                Assert.True(
                    levelCosts[i].Cost > levelCosts[i - 1].Cost,
                    $"Tower upgrade '{upgrade.Name}' has non-increasing costs: L{levelCosts[i - 1].Level}={levelCosts[i - 1].Cost}, L{levelCosts[i].Level}={levelCosts[i].Cost}.");
            }
        }
    }

    [Fact]
    public void TowerTier3ChoiceCosts_AreAtLeastLevel3PathCost()
    {
        using JsonDocument doc = LoadDataDocument("tower_upgrades.json");
        JsonElement upgrades = doc.RootElement.GetProperty("upgrades");

        foreach (JsonProperty upgrade in upgrades.EnumerateObject())
        {
            JsonElement levels = upgrade.Value.GetProperty("levels");
            List<(int Level, int Cost)> levelCosts = ReadLevelCosts(levels);
            int? level3Cost = levelCosts.FirstOrDefault(c => c.Level == 3).Cost;
            if (level3Cost is null or 0)
            {
                continue;
            }

            if (!upgrade.Value.TryGetProperty("tier3_choices", out JsonElement choices) ||
                choices.ValueKind != JsonValueKind.Object)
            {
                continue;
            }

            foreach (JsonProperty choice in choices.EnumerateObject())
            {
                if (!choice.Value.TryGetProperty("cost", out JsonElement costNode) ||
                    costNode.ValueKind != JsonValueKind.Object)
                {
                    continue;
                }

                int choiceCost = SumNumericObject(costNode);
                Assert.True(
                    choiceCost >= level3Cost.Value,
                    $"Tower '{upgrade.Name}' tier-3 choice '{choice.Name}' costs {choiceCost}, below level-3 path cost {level3Cost.Value}.");
            }
        }
    }

    [Fact]
    public void BuildingUpgradeCosts_IncreasePerLevel()
    {
        using JsonDocument doc = LoadDataDocument("building_upgrades.json");
        JsonElement upgrades = doc.RootElement.GetProperty("upgrades");

        foreach (JsonProperty upgrade in upgrades.EnumerateObject())
        {
            JsonElement levels = upgrade.Value.GetProperty("levels");
            List<(int Level, int Cost)> levelCosts = ReadLevelCosts(levels);
            Assert.True(levelCosts.Count >= 2, $"Building upgrade '{upgrade.Name}' should define at least two paid levels.");

            for (int i = 1; i < levelCosts.Count; i++)
            {
                Assert.True(
                    levelCosts[i].Cost > levelCosts[i - 1].Cost,
                    $"Building upgrade '{upgrade.Name}' has non-increasing costs: L{levelCosts[i - 1].Level}={levelCosts[i - 1].Cost}, L{levelCosts[i].Level}={levelCosts[i].Cost}.");
            }
        }
    }

    [Theory]
    [InlineData("unit_upgrades.json")]
    [InlineData("kingdom_upgrades.json")]
    public void TieredUpgradeCosts_IncreaseAcrossTiers(string fileName)
    {
        List<TieredUpgradeRow> upgrades = ReadTieredUpgrades(fileName);

        var tierBands = upgrades
            .GroupBy(u => u.Tier)
            .OrderBy(g => g.Key)
            .Select(g => new
            {
                Tier = g.Key,
                MinCost = g.Min(x => x.Cost),
                MaxCost = g.Max(x => x.Cost),
            })
            .ToList();

        Assert.True(tierBands.Count >= 3, $"Expected at least 3 tiers in '{fileName}'.");

        for (int i = 1; i < tierBands.Count; i++)
        {
            Assert.True(
                tierBands[i].MinCost > tierBands[i - 1].MaxCost,
                $"'{fileName}' tier {tierBands[i].Tier} min cost ({tierBands[i].MinCost}) should exceed tier {tierBands[i - 1].Tier} max cost ({tierBands[i - 1].MaxCost}).");
        }
    }

    [Theory]
    [InlineData("tower_upgrades.json")]
    [InlineData("building_upgrades.json")]
    public void StructuredUpgradeData_DoesNotContainNegativeNumbers(string fileName)
    {
        using JsonDocument doc = LoadDataDocument(fileName);
        JsonElement upgrades = doc.RootElement.GetProperty("upgrades");

        foreach (JsonProperty upgrade in upgrades.EnumerateObject())
        {
            foreach ((string path, double value) in EnumerateNumericLeaves(upgrade.Value, upgrade.Name))
            {
                Assert.True(
                    value >= 0,
                    $"{fileName}:{path} has negative value {value}.");
            }
        }
    }

    [Theory]
    [InlineData("unit_upgrades.json")]
    [InlineData("kingdom_upgrades.json")]
    public void UpgradeEffects_DoNotApplyNegativeStats_ExceptAllowedReductions(string fileName)
    {
        List<TieredUpgradeRow> upgrades = ReadTieredUpgrades(fileName);

        foreach (TieredUpgradeRow upgrade in upgrades)
        {
            foreach (var (effectKey, effectValue) in upgrade.Effects)
            {
                Assert.False(
                    double.IsNaN(effectValue) || double.IsInfinity(effectValue),
                    $"Upgrade '{upgrade.Id}' effect '{effectKey}' is non-finite: {effectValue}.");

                if (AllowedNegativeEffectKeys.Contains(effectKey))
                {
                    Assert.InRange(effectValue, -1.0, 0.0);
                }
                else
                {
                    Assert.True(
                        effectValue >= 0,
                        $"Upgrade '{upgrade.Id}' effect '{effectKey}' is negative: {effectValue}.");
                }
            }
        }
    }

    [Fact]
    public void ScenarioDifficulty_IncreasesMonotonicallyAcrossTagBands()
    {
        List<ScenarioBalanceRow> scenarios = ReadScenarioRows();

        List<int> earlyDays = scenarios
            .Where(s => s.Tags.Contains("early") && s.ExpectedDay.HasValue)
            .Select(s => s.ExpectedDay!.Value)
            .ToList();
        List<int> midDays = scenarios
            .Where(s => s.Tags.Contains("mid") && s.ExpectedDay.HasValue)
            .Select(s => s.ExpectedDay!.Value)
            .ToList();
        List<int> longDays = scenarios
            .Where(s => s.Tags.Contains("long") && s.ExpectedDay.HasValue)
            .Select(s => s.ExpectedDay!.Value)
            .ToList();

        Assert.NotEmpty(earlyDays);
        Assert.NotEmpty(midDays);
        Assert.NotEmpty(longDays);

        Assert.True(earlyDays.Max() < midDays.Min(), "Expected 'mid' scenarios to be strictly later than all 'early' scenarios.");
        Assert.True(midDays.Min() <= longDays.Min(), "Expected 'long' scenarios to be at least as late as the start of 'mid' scenarios.");
        Assert.True(longDays.Min() >= 7, "Expected 'long' scenarios to target late-game days.");
    }

    [Fact]
    public void ScenarioNightWaveExpectations_ArePresentAndPositive()
    {
        List<ScenarioBalanceRow> nightScenarios = ReadScenarioRows()
            .Where(s => string.Equals(s.ExpectedPhase, "night", StringComparison.OrdinalIgnoreCase))
            .ToList();

        Assert.NotEmpty(nightScenarios);

        foreach (ScenarioBalanceRow scenario in nightScenarios)
        {
            int? expectedWaveCount = scenario.NightWaveEq ?? scenario.NightWaveMin ?? scenario.NightWaveMax;
            Assert.True(expectedWaveCount.HasValue, $"Night scenario '{scenario.Id}' is missing night_wave_total expectation.");
            Assert.True(expectedWaveCount.Value > 0, $"Night scenario '{scenario.Id}' has non-positive wave expectation: {expectedWaveCount.Value}.");
        }
    }

    [Fact]
    public void NonMonumentBuildingCosts_AreAffordableFromStartingResourcesWithinReasonablePlayTime()
    {
        const int reasonableDayBudget = 3;

        List<BuildingBalanceRow> candidateBuildings = ReadBuildingRows()
            .Where(b => !string.Equals(b.Category, "monument", StringComparison.OrdinalIgnoreCase))
            .ToList();

        Assert.NotEmpty(candidateBuildings);

        foreach (BuildingBalanceRow building in candidateBuildings)
        {
            int requiredDays = 0;

            foreach (var (resource, cost) in building.Costs)
            {
                int starting = SimBalance.StartingResources.GetValueOrDefault(resource, 0);
                int deficit = Math.Max(0, cost - starting);
                if (deficit == 0)
                {
                    continue;
                }

                Assert.True(
                    ConservativeDailyIncome.TryGetValue(resource, out int dailyIncome) && dailyIncome > 0,
                    $"No conservative daily income configured for resource '{resource}' (building '{building.Id}').");

                int daysForResource = (int)Math.Ceiling(deficit / (double)dailyIncome);
                requiredDays = Math.Max(requiredDays, daysForResource);
            }

            Assert.True(
                requiredDays <= reasonableDayBudget,
                $"Building '{building.Id}' requires ~{requiredDays} days under conservative income, exceeding budget {reasonableDayBudget}.");
        }
    }

    private static List<TowerBalanceRow> ReadTowerRows()
    {
        using JsonDocument doc = LoadDataDocument("towers.json");
        JsonElement towers = doc.RootElement.GetProperty("towers");
        var rows = new List<TowerBalanceRow>();

        foreach (JsonProperty tower in towers.EnumerateObject())
        {
            JsonElement node = tower.Value;
            JsonElement baseCost = node.GetProperty("base_cost");
            JsonElement baseStats = node.GetProperty("base_stats");

            double damage = GetDouble(baseStats, "damage", 0);
            double attackSpeed = GetDouble(baseStats, "attack_speed", 0);
            double shotsPerAttack = GetDouble(baseStats, "shots_per_attack", 1);

            rows.Add(new TowerBalanceRow(
                Id: tower.Name,
                Cost: SumNumericObject(baseCost),
                Damage: damage,
                AttackSpeed: attackSpeed,
                ShotsPerAttack: shotsPerAttack,
                Range: GetDouble(baseStats, "range", 0),
                TargetType: GetString(baseStats, "target_type", "none")));
        }

        return rows;
    }

    private static List<BuildingBalanceRow> ReadBuildingRows()
    {
        using JsonDocument doc = LoadDataDocument("buildings.json");
        JsonElement buildings = doc.RootElement.GetProperty("buildings");
        var rows = new List<BuildingBalanceRow>();

        foreach (JsonProperty building in buildings.EnumerateObject())
        {
            var costs = new Dictionary<string, int>(StringComparer.Ordinal);
            if (building.Value.TryGetProperty("cost", out JsonElement costNode) &&
                costNode.ValueKind == JsonValueKind.Object)
            {
                foreach (JsonProperty resource in costNode.EnumerateObject())
                {
                    costs[resource.Name] = ReadInt(resource.Value);
                }
            }

            rows.Add(new BuildingBalanceRow(
                Id: building.Name,
                Category: GetString(building.Value, "category", string.Empty),
                Costs: costs));
        }

        return rows;
    }

    private static List<ScenarioBalanceRow> ReadScenarioRows()
    {
        using JsonDocument doc = LoadDataDocument("scenarios.json");
        JsonElement scenarios = doc.RootElement.GetProperty("scenarios");
        var rows = new List<ScenarioBalanceRow>();

        foreach (JsonElement scenario in scenarios.EnumerateArray())
        {
            string id = GetString(scenario, "id", string.Empty);
            var tags = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            if (scenario.TryGetProperty("tags", out JsonElement tagsNode) &&
                tagsNode.ValueKind == JsonValueKind.Array)
            {
                foreach (JsonElement tag in tagsNode.EnumerateArray())
                {
                    string value = tag.GetString() ?? string.Empty;
                    if (!string.IsNullOrWhiteSpace(value))
                    {
                        tags.Add(value);
                    }
                }
            }

            rows.Add(new ScenarioBalanceRow(
                Id: id,
                Tags: tags,
                ExpectedDay: TryReadNestedInt(scenario, "expect_baseline", "day", "eq"),
                ExpectedPhase: TryReadNestedString(scenario, "expect_baseline", "phase", "eq"),
                NightWaveEq: TryReadNestedInt(scenario, "expect_baseline", "night_wave_total", "eq"),
                NightWaveMin: TryReadNestedInt(scenario, "expect_baseline", "night_wave_total", "min"),
                NightWaveMax: TryReadNestedInt(scenario, "expect_baseline", "night_wave_total", "max")));
        }

        return rows;
    }

    private static List<TieredUpgradeRow> ReadTieredUpgrades(string fileName)
    {
        using JsonDocument doc = LoadDataDocument(fileName);
        JsonElement upgrades = doc.RootElement.GetProperty("upgrades");
        var rows = new List<TieredUpgradeRow>();

        foreach (JsonElement upgrade in upgrades.EnumerateArray())
        {
            string id = GetString(upgrade, "id", string.Empty);
            int tier = ReadInt(upgrade.GetProperty("tier"));
            int cost = ReadInt(upgrade.GetProperty("cost"));

            var effects = new Dictionary<string, double>(StringComparer.Ordinal);
            if (upgrade.TryGetProperty("effects", out JsonElement effectsNode) &&
                effectsNode.ValueKind == JsonValueKind.Object)
            {
                foreach (JsonProperty effect in effectsNode.EnumerateObject())
                {
                    effects[effect.Name] = ReadDouble(effect.Value);
                }
            }

            rows.Add(new TieredUpgradeRow(id, tier, cost, effects));
        }

        return rows;
    }

    private static List<(int Level, int Cost)> ReadLevelCosts(JsonElement levelsNode)
    {
        var rows = new List<(int Level, int Cost)>();

        foreach (JsonProperty level in levelsNode.EnumerateObject())
        {
            if (!int.TryParse(level.Name, out int levelNumber))
            {
                continue;
            }

            if (!level.Value.TryGetProperty("cost", out JsonElement costNode) ||
                costNode.ValueKind != JsonValueKind.Object)
            {
                continue;
            }

            int cost = SumNumericObject(costNode);
            rows.Add((levelNumber, cost));
        }

        return rows.OrderBy(r => r.Level).ToList();
    }

    private static IEnumerable<(string Path, double Value)> EnumerateNumericLeaves(JsonElement node, string path)
    {
        switch (node.ValueKind)
        {
            case JsonValueKind.Object:
                foreach (JsonProperty prop in node.EnumerateObject())
                {
                    string childPath = string.IsNullOrEmpty(path) ? prop.Name : $"{path}.{prop.Name}";
                    foreach (var item in EnumerateNumericLeaves(prop.Value, childPath))
                    {
                        yield return item;
                    }
                }
                break;

            case JsonValueKind.Array:
                int index = 0;
                foreach (JsonElement item in node.EnumerateArray())
                {
                    string childPath = $"{path}[{index}]";
                    foreach (var pair in EnumerateNumericLeaves(item, childPath))
                    {
                        yield return pair;
                    }
                    index++;
                }
                break;

            case JsonValueKind.Number:
                yield return (path, ReadDouble(node));
                break;
        }
    }

    private static int SumNumericObject(JsonElement objectNode)
    {
        int sum = 0;
        foreach (JsonProperty prop in objectNode.EnumerateObject())
        {
            sum += ReadInt(prop.Value);
        }
        return sum;
    }

    private static double ComputePearsonCorrelation(IReadOnlyList<double> x, IReadOnlyList<double> y)
    {
        if (x.Count != y.Count)
        {
            throw new ArgumentException("Correlation vectors must have equal length.");
        }

        if (x.Count < 2)
        {
            return 0;
        }

        double meanX = x.Average();
        double meanY = y.Average();

        double covariance = 0;
        double varianceX = 0;
        double varianceY = 0;

        for (int i = 0; i < x.Count; i++)
        {
            double dx = x[i] - meanX;
            double dy = y[i] - meanY;
            covariance += dx * dy;
            varianceX += dx * dx;
            varianceY += dy * dy;
        }

        if (varianceX <= 0 || varianceY <= 0)
        {
            return 0;
        }

        return covariance / Math.Sqrt(varianceX * varianceY);
    }

    private static int? TryReadNestedInt(JsonElement root, params string[] path)
    {
        JsonElement? current = root;
        foreach (string segment in path)
        {
            if (current is null ||
                current.Value.ValueKind != JsonValueKind.Object ||
                !current.Value.TryGetProperty(segment, out JsonElement next))
            {
                return null;
            }

            current = next;
        }

        return current.Value.ValueKind switch
        {
            JsonValueKind.Number => ReadInt(current.Value),
            JsonValueKind.String when int.TryParse(current.Value.GetString(), out int value) => value,
            _ => null,
        };
    }

    private static string? TryReadNestedString(JsonElement root, params string[] path)
    {
        JsonElement? current = root;
        foreach (string segment in path)
        {
            if (current is null ||
                current.Value.ValueKind != JsonValueKind.Object ||
                !current.Value.TryGetProperty(segment, out JsonElement next))
            {
                return null;
            }

            current = next;
        }

        return current.Value.ValueKind == JsonValueKind.String ? current.Value.GetString() : null;
    }

    private static double GetDouble(JsonElement node, string propertyName, double fallback)
    {
        if (!node.TryGetProperty(propertyName, out JsonElement value))
        {
            return fallback;
        }

        return ReadDouble(value);
    }

    private static string GetString(JsonElement node, string propertyName, string fallback)
    {
        if (!node.TryGetProperty(propertyName, out JsonElement value) ||
            value.ValueKind != JsonValueKind.String)
        {
            return fallback;
        }

        return value.GetString() ?? fallback;
    }

    private static int ReadInt(JsonElement value)
    {
        if (value.ValueKind == JsonValueKind.Number && value.TryGetInt32(out int intValue))
        {
            return intValue;
        }

        if (value.ValueKind == JsonValueKind.Number)
        {
            return Convert.ToInt32(value.GetDouble());
        }

        if (value.ValueKind == JsonValueKind.String &&
            int.TryParse(value.GetString(), out int parsed))
        {
            return parsed;
        }

        throw new InvalidDataException($"Expected integer-compatible JSON value but found '{value.ValueKind}'.");
    }

    private static double ReadDouble(JsonElement value)
    {
        if (value.ValueKind == JsonValueKind.Number)
        {
            return value.GetDouble();
        }

        if (value.ValueKind == JsonValueKind.String &&
            double.TryParse(value.GetString(), out double parsed))
        {
            return parsed;
        }

        throw new InvalidDataException($"Expected numeric JSON value but found '{value.ValueKind}'.");
    }

    private static JsonDocument LoadDataDocument(string fileName)
    {
        string dataDir = ResolveDataDirectory();
        string path = Path.Combine(dataDir, fileName);
        if (!File.Exists(path))
        {
            throw new FileNotFoundException($"Could not locate data file '{fileName}' at '{path}'.");
        }

        return JsonDocument.Parse(File.ReadAllText(path));
    }

    private static string ResolveDataDirectory()
    {
        string? dir = AppDomain.CurrentDomain.BaseDirectory;
        for (int i = 0; i < 10 && !string.IsNullOrEmpty(dir); i++)
        {
            string candidate = Path.Combine(dir, "data");
            if (File.Exists(Path.Combine(candidate, "towers.json")))
            {
                return candidate;
            }

            string? parent = Path.GetDirectoryName(dir);
            if (parent == dir)
            {
                break;
            }

            dir = parent;
        }

        throw new DirectoryNotFoundException("Could not locate data/towers.json from test base directory.");
    }

    private readonly record struct TowerBalanceRow(
        string Id,
        int Cost,
        double Damage,
        double AttackSpeed,
        double ShotsPerAttack,
        double Range,
        string TargetType)
    {
        public double Dps => Damage * AttackSpeed * ShotsPerAttack;
    }

    private readonly record struct BuildingBalanceRow(
        string Id,
        string Category,
        Dictionary<string, int> Costs);

    private readonly record struct TieredUpgradeRow(
        string Id,
        int Tier,
        int Cost,
        Dictionary<string, double> Effects);

    private readonly record struct ScenarioBalanceRow(
        string Id,
        HashSet<string> Tags,
        int? ExpectedDay,
        string? ExpectedPhase,
        int? NightWaveEq,
        int? NightWaveMin,
        int? NightWaveMax);
}
