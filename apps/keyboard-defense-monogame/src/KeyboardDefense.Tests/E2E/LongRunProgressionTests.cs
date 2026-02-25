using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.E2E;

public class LongRunProgressionTests
{
    private const int FiftyDaySpan = 50;
    private const int TenMegabytes = 10 * 1024 * 1024;
    private const string StarterResearch = "improved_walls";
    private static readonly object BuildingsDataLoadLock = new();
    private static bool _buildingsDataLoaded;

    [Fact]
    public void FiftyDayRun_DayCounter_IncreasesMonotonically()
    {
        var run = SimulateCampaign(
            daysToAdvance: FiftyDaySpan,
            seed: "longrun_day_counter",
            planTowers: false,
            planResearch: false);

        Assert.Equal(FiftyDaySpan + 1, run.DayHistory.Count);
        Assert.True(IsStrictlyIncreasing(run.DayHistory));
        Assert.Equal(1 + FiftyDaySpan, run.State.Day);
    }

    [Fact]
    public void BasicStrategy_PlayerSurvivesAtLeastTenDays()
    {
        var run = SimulateCampaign(
            daysToAdvance: 10,
            seed: "longrun_survival_10_days",
            planTowers: true,
            planResearch: false);

        Assert.True(run.State.Hp > 0);
        Assert.True(run.State.Day >= 11);
        Assert.Equal("day", run.State.Phase);
        Assert.Equal("exploration", run.State.ActivityMode);
    }

    [Fact]
    public void ResourceIncome_ScalesWithBuildingCount()
    {
        var oneSetState = DefaultState.Create("longrun_income_single");
        var threeSetState = DefaultState.Create("longrun_income_triple");

        AddProductionBuildings(oneSetState, farms: 1, lumbers: 1, quarries: 1, startIndex: 40);
        AddProductionBuildings(threeSetState, farms: 3, lumbers: 3, quarries: 3, startIndex: 80);

        var oneSetBefore = SnapshotResources(oneSetState);
        var threeSetBefore = SnapshotResources(threeSetState);

        SimTick.AdvanceDay(oneSetState);
        SimTick.AdvanceDay(threeSetState);

        int oneWood = ResourceDelta(oneSetBefore, oneSetState.Resources, "wood");
        int oneStone = ResourceDelta(oneSetBefore, oneSetState.Resources, "stone");
        int oneFood = ResourceDelta(oneSetBefore, oneSetState.Resources, "food");

        int threeWood = ResourceDelta(threeSetBefore, threeSetState.Resources, "wood");
        int threeStone = ResourceDelta(threeSetBefore, threeSetState.Resources, "stone");
        int threeFood = ResourceDelta(threeSetBefore, threeSetState.Resources, "food");

        Assert.Equal(2, oneWood);
        Assert.Equal(2, oneStone);
        Assert.Equal(2, oneFood);
        Assert.Equal(6, threeWood);
        Assert.Equal(6, threeStone);
        Assert.Equal(6, threeFood);
        Assert.True(threeWood > oneWood);
        Assert.True(threeStone > oneStone);
        Assert.True(threeFood > oneFood);
    }

    [Fact]
    public void FiftyDayRun_EnemyDifficultyIncreases_ButRemainsBeatable()
    {
        var run = SimulateCampaign(
            daysToAdvance: FiftyDaySpan,
            seed: "longrun_enemy_scaling",
            planTowers: true,
            planResearch: false);

        Assert.Equal(FiftyDaySpan, run.DifficultySamples.Count);
        var first = run.DifficultySamples[0];
        var last = run.DifficultySamples[^1];

        Assert.True(last.MaxHp > first.MaxHp,
            $"Expected enemy HP to increase by day {last.Day}. Got day {first.Day}:{first.MaxHp} vs day {last.Day}:{last.MaxHp}.");
        Assert.True(last.MaxDamage >= first.MaxDamage,
            $"Expected enemy damage to be non-decreasing by day {last.Day}. Got day {first.Day}:{first.MaxDamage} vs day {last.Day}:{last.MaxDamage}.");
        Assert.Equal(1 + FiftyDaySpan, run.State.Day);
        Assert.True(run.State.Hp > 0);
    }

    [Fact]
    public void CombatGold_AccumulatesAcrossRun()
    {
        var run = SimulateCampaign(
            daysToAdvance: 20,
            seed: "longrun_gold_gain",
            planTowers: false,
            planResearch: false);

        Assert.True(run.State.EnemiesDefeated > 0);
        Assert.True(IsNonDecreasing(run.GoldHistory));
        Assert.True(run.GoldHistory[^1] > run.GoldHistory[0]);
    }

    [Fact]
    public void Research_CompletesWithinTwentyDays()
    {
        var run = SimulateCampaign(
            daysToAdvance: 20,
            seed: "longrun_research_20_days",
            planTowers: false,
            planResearch: true);

        Assert.Contains(StarterResearch, run.State.CompletedResearch);
        Assert.NotNull(run.ResearchCompletedDay);
        int elapsedDays = run.ResearchCompletedDay!.Value - 1;
        Assert.InRange(elapsedDays, 1, 20);
    }

    [Fact]
    public void TowerPlan_BuildsAtLeastThreeTowersByDayTen()
    {
        var run = SimulateCampaign(
            daysToAdvance: 10,
            seed: "longrun_three_towers",
            planTowers: true,
            planResearch: false);

        Assert.True(run.State.Day >= 11);
        Assert.True(CountBuiltTowers(run.State) >= 3,
            $"Expected at least 3 towers by day 10, found {CountBuiltTowers(run.State)}.");
    }

    [Fact]
    public void FiftyDayRun_SerializedStateRemainsUnderTenMegabytes()
    {
        var run = SimulateCampaign(
            daysToAdvance: FiftyDaySpan,
            seed: "longrun_serialized_size",
            planTowers: true,
            planResearch: true);

        string json = SaveManager.StateToJson(run.State);
        int byteCount = Encoding.UTF8.GetByteCount(json);

        Assert.True(byteCount < TenMegabytes,
            $"Serialized state exceeded 10MB: {byteCount} bytes.");
    }

    private static CampaignRun SimulateCampaign(int daysToAdvance, string seed, bool planTowers, bool planResearch)
    {
        EnsureBuildingsDataLoaded();
        var state = DefaultState.Create(seed);
        var run = new CampaignRun(state);
        var towerPlan = GetTowerBuildPlan(state);
        int towerPlanCursor = 0;
        int targetDay = state.Day + daysToAdvance;

        while (state.Day < targetDay)
        {
            if (planTowers && state.Day <= 10 && CountBuiltTowers(state) < 3 && towerPlanCursor < towerPlan.Count)
            {
                state = GatherAndBuildTower(state, towerPlan[towerPlanCursor]);
                towerPlanCursor++;
            }

            if (planResearch)
                TryStartResearch(state, StarterResearch);

            state.ActivityMode = "exploration";
            state.Phase = "day";
            state.RoamingEnemies.Clear();
            state.EncounterEnemies.Clear();
            state.ThreatLevel = 1.0f;
            state.WaveCooldown = 0f;

            WorldTick.Tick(state, WorldTick.WorldTickInterval);
            Assert.Equal("wave_assault", state.ActivityMode);

            bool sampledThisDay = false;
            int sampleDay = state.Day;
            int dayMaxHp = 0;
            int dayMaxDamage = 0;
            int tickGuard = 0;

            while (state.ActivityMode == "wave_assault")
            {
                tickGuard++;
                Assert.True(tickGuard < 2048, $"Wave resolution exceeded safety limit on day {sampleDay}.");

                WorldTick.Tick(state, WorldTick.WorldTickInterval);
                if (state.Enemies.Count == 0)
                    continue;

                sampledThisDay = true;
                dayMaxHp = Math.Max(dayMaxHp, state.Enemies.Max(enemy => Convert.ToInt32(enemy.GetValueOrDefault("hp", 0))));
                dayMaxDamage = Math.Max(dayMaxDamage, state.Enemies.Max(enemy => Convert.ToInt32(enemy.GetValueOrDefault("damage", 1))));
                DefeatActiveWaveEnemies(state);
            }

            Assert.True(sampledThisDay, $"Expected at least one enemy spawn on day {sampleDay}.");
            run.DifficultySamples.Add(new DifficultySample(sampleDay, dayMaxHp, dayMaxDamage));
            run.WaveSizeHistory.Add(state.NightWaveTotal);

            if (planResearch && state.ActiveResearch == StarterResearch)
            {
                bool completed = ResearchData.AdvanceResearch(state);
                if (completed && run.ResearchCompletedDay is null)
                    run.ResearchCompletedDay = state.Day;
            }

            run.RecordDay(state);
        }

        return run;
    }

    private static GameState GatherAndBuildTower(GameState state, GridPoint position)
    {
        PrepareBuildableTile(state, position);
        var cost = BuildingsData.CostFor("tower");

        foreach (var (resource, amount) in cost)
        {
            if (string.Equals(resource, "gold", StringComparison.Ordinal))
            {
                int missingGold = amount - state.Gold;
                if (missingGold > 0)
                    state.Gold += missingGold;
                continue;
            }

            int current = state.Resources.GetValueOrDefault(resource, 0);
            int missing = amount - current;
            if (missing <= 0)
                continue;

            state = ApplyIntent(state, "gather", new()
            {
                ["resource"] = resource,
                ["amount"] = missing,
            });
        }

        state = ApplyIntent(state, "build", new()
        {
            ["building"] = "tower",
            ["x"] = position.X,
            ["y"] = position.Y,
        });

        int index = SimMap.Idx(position.X, position.Y, state.MapW);
        Assert.Equal("tower", state.Structures.GetValueOrDefault(index));
        return state;
    }

    private static void TryStartResearch(GameState state, string researchId)
    {
        if (state.CompletedResearch.Contains(researchId))
            return;
        if (!string.IsNullOrEmpty(state.ActiveResearch))
            return;
        ResearchData.StartResearch(state, researchId);
    }

    private static void DefeatActiveWaveEnemies(GameState state)
    {
        foreach (var enemy in state.Enemies)
        {
            state.Gold += Convert.ToInt32(enemy.GetValueOrDefault("gold", 1));
            state.EnemiesDefeated++;
        }
        state.Enemies.Clear();
    }

    private static GameState ApplyIntent(GameState state, string kind, Dictionary<string, object>? data = null)
    {
        var result = IntentApplier.Apply(state, SimIntents.Make(kind, data));
        return Assert.IsType<GameState>(result["state"]);
    }

    private static List<GridPoint> GetTowerBuildPlan(GameState state)
    {
        var plan = new List<GridPoint>
        {
            new(state.BasePos.X + 2, state.BasePos.Y),
            new(state.BasePos.X - 2, state.BasePos.Y),
            new(state.BasePos.X, state.BasePos.Y + 2),
            new(state.BasePos.X, state.BasePos.Y - 2),
            new(state.BasePos.X + 3, state.BasePos.Y + 1),
        };

        return plan.Where(pos => SimMap.InBounds(pos.X, pos.Y, state.MapW, state.MapH)).ToList();
    }

    private static void PrepareBuildableTile(GameState state, GridPoint position)
    {
        int index = SimMap.Idx(position.X, position.Y, state.MapW);
        state.Discovered.Add(index);
        state.Terrain[index] = SimMap.TerrainPlains;
        state.Structures.Remove(index);
        state.StructureLevels.Remove(index);
    }

    private static int CountBuiltTowers(GameState state)
        => state.Structures.Values.Count(structure => string.Equals(structure, "tower", StringComparison.Ordinal));

    private static void AddProductionBuildings(GameState state, int farms, int lumbers, int quarries, int startIndex)
    {
        int index = startIndex;
        for (int i = 0; i < farms; i++)
            state.Structures[index++] = "farm";
        for (int i = 0; i < lumbers; i++)
            state.Structures[index++] = "lumber";
        for (int i = 0; i < quarries; i++)
            state.Structures[index++] = "quarry";
    }

    private static Dictionary<string, int> SnapshotResources(GameState state)
        => new(state.Resources);

    private static int ResourceDelta(Dictionary<string, int> before, Dictionary<string, int> after, string key)
        => after.GetValueOrDefault(key, 0) - before.GetValueOrDefault(key, 0);

    private static bool IsStrictlyIncreasing(IReadOnlyList<int> values)
    {
        for (int i = 1; i < values.Count; i++)
        {
            if (values[i] <= values[i - 1])
                return false;
        }
        return true;
    }

    private static bool IsNonDecreasing(IReadOnlyList<int> values)
    {
        for (int i = 1; i < values.Count; i++)
        {
            if (values[i] < values[i - 1])
                return false;
        }
        return true;
    }

    private static void EnsureBuildingsDataLoaded()
    {
        if (_buildingsDataLoaded)
            return;

        lock (BuildingsDataLoadLock)
        {
            if (_buildingsDataLoaded)
                return;

            BuildingsData.LoadData(ResolveDataDirectory());
            _buildingsDataLoaded = true;
        }
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

        string currentDirCandidate = Path.Combine(Directory.GetCurrentDirectory(), "data");
        if (File.Exists(Path.Combine(currentDirCandidate, "buildings.json")))
            return currentDirCandidate;

        throw new DirectoryNotFoundException("Could not locate data/buildings.json for long-run progression tests.");
    }

    private sealed class CampaignRun
    {
        public CampaignRun(GameState state)
        {
            State = state;
            DayHistory.Add(state.Day);
            GoldHistory.Add(state.Gold);
        }

        public GameState State { get; private set; }
        public List<int> DayHistory { get; } = new();
        public List<int> GoldHistory { get; } = new();
        public List<int> WaveSizeHistory { get; } = new();
        public List<DifficultySample> DifficultySamples { get; } = new();
        public int? ResearchCompletedDay { get; set; }

        public void RecordDay(GameState state)
        {
            State = state;
            DayHistory.Add(state.Day);
            GoldHistory.Add(state.Gold);
        }
    }

    private readonly record struct DifficultySample(int Day, int MaxHp, int MaxDamage);
}
