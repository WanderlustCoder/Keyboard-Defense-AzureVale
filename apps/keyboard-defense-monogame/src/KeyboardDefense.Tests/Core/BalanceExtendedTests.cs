using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using KeyboardDefense.Core.Balance;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class BalanceExtendedTests
{
    private const int MaxValidationDay = 100;
    private const int ScreenEnemyCapacity = 100;
    private const double MeaningfulTypingDamageRatio = 0.05;

    [Fact]
    public void EnemyHpScaling_IsMonotonicByDay_AtZeroThreat()
    {
        int previous = SimBalance.CalculateEnemyHp(day: 1, threat: 0);

        for (int day = 2; day <= MaxValidationDay; day++)
        {
            int current = SimBalance.CalculateEnemyHp(day, threat: 0);
            Assert.True(
                current >= previous,
                $"Enemy HP decreased at day {day}: previous={previous}, current={current}.");
            previous = current;
        }
    }

    [Fact]
    public void EnemyHpScaling_IsMonotonicByDay_AtMaxThreat()
    {
        int threat = SimBalance.ThreatMax;
        int previous = SimBalance.CalculateEnemyHp(day: 1, threat);

        for (int day = 2; day <= MaxValidationDay; day++)
        {
            int current = SimBalance.CalculateEnemyHp(day, threat);
            Assert.True(
                current >= previous,
                $"Enemy HP decreased at day {day} (threat {threat}): previous={previous}, current={current}.");
            previous = current;
        }
    }

    [Fact]
    public void EnemyHpScaling_IncreasesAtLeastOncePerDivisorWindow()
    {
        int threat = SimBalance.ThreatMax;
        int jump = SimBalance.EnemyHpDayDivisor;

        for (int day = 1; day <= MaxValidationDay - jump; day++)
        {
            int baseline = SimBalance.CalculateEnemyHp(day, threat);
            int afterWindow = SimBalance.CalculateEnemyHp(day + jump, threat);

            Assert.True(
                afterWindow >= baseline + 1,
                $"Enemy HP should increase by at least 1 over {jump} days; day {day}={baseline}, day {day + jump}={afterWindow}.");
        }
    }

    [Fact]
    public void MaxLevelTowerDamage_CanOneShotDayOneEnemy_ForAllOffensiveTowerTypes()
    {
        int dayOneEnemyHp = SimBalance.CalculateEnemyHp(day: 1, threat: 0);
        var offensiveTowers = TowerTypes.TowerStats
            .Where(kvp => kvp.Value.Damage > 0 && kvp.Value.Target != TargetType.None)
            .ToList();

        Assert.NotEmpty(offensiveTowers);

        foreach (var (towerId, tower) in offensiveTowers)
        {
            int maxLevelDamage = SimBalance.CalculateTowerDamage(tower.Damage, SimBalance.TowerMaxLevel);
            Assert.True(
                maxLevelDamage >= dayOneEnemyHp,
                $"Tower '{towerId}' max-level damage {maxLevelDamage} should one-shot day-1 enemy HP {dayOneEnemyHp}.");
        }
    }

    [Fact]
    public void MaxLevelTowerDamage_WithBaseDamageOne_CanStillOneShotDayOneEnemy()
    {
        int dayOneEnemyHp = SimBalance.CalculateEnemyHp(day: 1, threat: 0);
        int maxLevelDamage = SimBalance.CalculateTowerDamage(baseDamage: 1, SimBalance.TowerMaxLevel);

        Assert.True(
            maxLevelDamage >= dayOneEnemyHp,
            $"Base damage 1 at max level should one-shot day-1 enemy HP {dayOneEnemyHp}, but got {maxLevelDamage}.");
    }

    [Fact]
    public void PlayerCanAffordAtLeastOneTowerByDayThree_WithSingleQuarryRamp()
    {
        Dictionary<string, int> quarryCost = ReadBuildingCost("quarry");
        Dictionary<string, int> towerCost = ReadBuildingCost("tower");

        var state = CreateStateWithStartingResources();
        Assert.True(CanAfford(state, quarryCost), "Starting resources should afford one quarry.");

        Spend(state, quarryCost);
        state.Structures[0] = "quarry";

        SimTick.AdvanceDay(state); // day 2
        SimTick.AdvanceDay(state); // day 3

        Assert.Equal(3, state.Day);
        Assert.True(
            CanAfford(state, towerCost),
            $"Expected tower affordability by day 3. Wallet vs cost: {FormatWalletVsCost(state, towerCost)}.");
    }

    [Fact]
    public void WaveSize_RemainsUnderScreenCapacity_ThroughVictorySurvivalSpan()
    {
        int threat = SimBalance.ThreatMax;

        for (int day = 1; day <= SimBalance.VictorySurvivalWaves; day++)
        {
            int waveSize = SimBalance.CalculateWaveSize(day, threat);
            Assert.True(
                waveSize < ScreenEnemyCapacity,
                $"Day {day} wave size {waveSize} exceeds screen capacity limit {ScreenEnemyCapacity}.");
        }
    }

    [Fact]
    public void BuildingIncome_CoversBasicTowerMaintenance()
    {
        // There is no tower-specific upkeep formula yet; worker upkeep is the current maintenance baseline.
        var state = new GameState();
        state.Structures[0] = "farm";
        state.Structures[1] = "tower";

        int foodBefore = state.Resources.GetValueOrDefault("food", 0);
        int basicTowerMaintenance = state.WorkerUpkeep;

        SimTick.AdvanceDay(state);

        int foodProduced = state.Resources.GetValueOrDefault("food", 0) - foodBefore;
        Assert.True(
            foodProduced >= basicTowerMaintenance,
            $"Farm income ({foodProduced}) should cover basic maintenance ({basicTowerMaintenance}).");
    }

    [Fact]
    public void DifficultyFactor_DayFiftyIsWithinTenTimesDayOne()
    {
        double dayOne = SimBalance.GetDifficultyFactor(1);
        double dayFifty = SimBalance.GetDifficultyFactor(50);

        Assert.True(dayOne > 0, $"Day 1 difficulty must be positive, got {dayOne}.");
        Assert.True(
            dayFifty / dayOne <= 10.0,
            $"Day 50 difficulty {dayFifty:F3} should be <= 10x day 1 ({dayOne:F3}).");
    }

    [Fact]
    public void DifficultyFactor_IsMonotonicFromDayOneToHundred()
    {
        double previous = SimBalance.GetDifficultyFactor(1);

        for (int day = 2; day <= MaxValidationDay; day++)
        {
            double current = SimBalance.GetDifficultyFactor(day);
            Assert.True(double.IsFinite(current), $"Day {day} difficulty is not finite: {current}.");
            Assert.True(
                current >= previous,
                $"Difficulty decreased at day {day}: previous={previous:F4}, current={current:F4}.");
            previous = current;
        }
    }

    [Fact]
    public void TypingDamage_At120Wpm95Accuracy_IsMeaningfulAcrossDays()
    {
        int typingDamage = SimBalance.CalculateTypingDamage(
            baseDamage: SimBalance.TypingBaseDamage,
            wpm: 120,
            accuracy: 0.95,
            combo: 0);

        Assert.True(typingDamage > 0, $"Typing damage should be positive, got {typingDamage}.");

        for (int day = 1; day <= MaxValidationDay; day++)
        {
            int enemyHp = SimBalance.CalculateEnemyHp(day, SimBalance.ThreatMax);
            double ratio = typingDamage / (double)enemyHp;
            Assert.True(
                ratio >= MeaningfulTypingDamageRatio,
                $"Day {day}: typing damage ratio too low ({ratio:P2}); damage={typingDamage}, enemyHp={enemyHp}.");
        }
    }

    [Fact]
    public void BalanceCalcs_NoNegativeOrNonFiniteValues_ForDaysOneToHundred()
    {
        for (int day = 1; day <= MaxValidationDay; day++)
        {
            double difficulty = SimBalance.GetDifficultyFactor(day);
            Assert.True(double.IsFinite(difficulty), $"Difficulty should be finite at day {day}.");
            Assert.True(difficulty > 0, $"Difficulty should be positive at day {day}, got {difficulty}.");

            int goldReward = SimBalance.CalculateGoldReward(baseGold: 1, day);
            Assert.True(goldReward >= 0, $"Gold reward should be non-negative at day {day}, got {goldReward}.");

            for (int threat = 0; threat <= SimBalance.ThreatMax; threat++)
            {
                int enemyHp = SimBalance.CalculateEnemyHp(day, threat);
                int bossHp = SimBalance.CalculateBossHp(day, threat);
                int waveSize = SimBalance.CalculateWaveSize(day, threat);
                int typingDamage = SimBalance.CalculateTypingDamage(
                    baseDamage: SimBalance.TypingBaseDamage,
                    wpm: 120,
                    accuracy: 0.95,
                    combo: day + threat);

                Assert.True(enemyHp > 0, $"Enemy HP must be positive at day={day}, threat={threat}, got {enemyHp}.");
                Assert.True(bossHp > 0, $"Boss HP must be positive at day={day}, threat={threat}, got {bossHp}.");
                Assert.True(waveSize >= 1, $"Wave size must be >= 1 at day={day}, threat={threat}, got {waveSize}.");
                Assert.True(typingDamage >= 1, $"Typing damage must be >= 1 at day={day}, threat={threat}, got {typingDamage}.");
            }
        }
    }

    [Fact]
    public void UpgradeCostAndTowerDamage_ArePositiveAndMonotonicAcrossLevels()
    {
        Dictionary<string, int> towerBaseCost = ReadBuildingCost("tower");

        int previousUpgradeTotal = -1;
        for (int level = 0; level <= SimBalance.TowerMaxLevel; level++)
        {
            Dictionary<string, int> upgradedCost = SimBalance.CalculateUpgradeCost(towerBaseCost, level);
            int currentTotal = upgradedCost.Values.Sum();

            Assert.True(currentTotal > 0, $"Upgrade total should be positive at level {level}, got {currentTotal}.");
            if (previousUpgradeTotal >= 0)
            {
                Assert.True(
                    currentTotal >= previousUpgradeTotal,
                    $"Upgrade cost should be monotonic: level {level - 1}={previousUpgradeTotal}, level {level}={currentTotal}.");
            }

            previousUpgradeTotal = currentTotal;
        }

        int baseDamage = TowerTypes.TowerStats[TowerTypes.Arrow].Damage;
        int previousDamage = SimBalance.CalculateTowerDamage(baseDamage, level: 1);

        for (int level = 2; level <= SimBalance.TowerMaxLevel; level++)
        {
            int currentDamage = SimBalance.CalculateTowerDamage(baseDamage, level);
            Assert.True(
                currentDamage >= previousDamage,
                $"Tower damage should be monotonic: level {level - 1}={previousDamage}, level {level}={currentDamage}.");
            previousDamage = currentDamage;
        }
    }

    private static GameState CreateStateWithStartingResources()
    {
        var state = new GameState();

        foreach (var (resource, amount) in SimBalance.StartingResources)
        {
            if (string.Equals(resource, "gold", StringComparison.Ordinal))
            {
                state.Gold = amount;
            }
            else
            {
                state.Resources[resource] = amount;
            }
        }

        return state;
    }

    private static bool CanAfford(GameState state, IReadOnlyDictionary<string, int> cost)
    {
        foreach (var (resource, amount) in cost)
        {
            if (GetResourceAmount(state, resource) < amount)
            {
                return false;
            }
        }

        return true;
    }

    private static void Spend(GameState state, IReadOnlyDictionary<string, int> cost)
    {
        foreach (var (resource, amount) in cost)
        {
            int remaining = GetResourceAmount(state, resource) - amount;
            SetResourceAmount(state, resource, remaining);
        }
    }

    private static int GetResourceAmount(GameState state, string resource)
    {
        if (string.Equals(resource, "gold", StringComparison.Ordinal))
        {
            return state.Gold;
        }

        return state.Resources.GetValueOrDefault(resource, 0);
    }

    private static void SetResourceAmount(GameState state, string resource, int amount)
    {
        if (string.Equals(resource, "gold", StringComparison.Ordinal))
        {
            state.Gold = amount;
            return;
        }

        state.Resources[resource] = amount;
    }

    private static string FormatWalletVsCost(GameState state, IReadOnlyDictionary<string, int> cost)
    {
        return string.Join(", ", cost.Select(c => $"{c.Key}:{GetResourceAmount(state, c.Key)}/{c.Value}"));
    }

    private static Dictionary<string, int> ReadBuildingCost(string buildingId)
    {
        using JsonDocument doc = LoadDataDocument("buildings.json");
        JsonElement buildings = doc.RootElement.GetProperty("buildings");
        JsonElement building = buildings.GetProperty(buildingId);
        JsonElement costNode = building.GetProperty("cost");

        var costs = new Dictionary<string, int>(StringComparer.Ordinal);
        foreach (JsonProperty property in costNode.EnumerateObject())
        {
            costs[property.Name] = ReadInt(property.Value);
        }

        return costs;
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
            if (File.Exists(Path.Combine(candidate, "buildings.json")))
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

        throw new DirectoryNotFoundException("Could not locate data/buildings.json from test base directory.");
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
}
