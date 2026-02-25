using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Balance;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class WaveCompositionExtendedTests
{
    [Fact]
    public void ComposeWave_NightCompositionUsesMultipleEnemyKindsAcrossWaves()
    {
        var state = DefaultState.Create("wave-composition-variety");
        state.Day = 10;

        const int totalWaves = 5;
        var uniqueKinds = new HashSet<string>(StringComparer.Ordinal);

        for (int waveIndex = 0; waveIndex < totalWaves; waveIndex++)
        {
            WaveSpec spec = WaveComposer.ComposeWave(state, waveIndex, totalWaves);
            foreach (string enemyKind in spec.Enemies)
                uniqueKinds.Add(enemyKind);
        }

        Assert.True(
            uniqueKinds.Count >= 4,
            $"Expected >= 4 unique enemy kinds across the night, got {uniqueKinds.Count}.");
    }

    [Theory]
    [InlineData(7)]
    [InlineData(14)]
    [InlineData(21)]
    [InlineData(28)]
    public void ComposeWave_FinalWaveOnMilestoneDay_UsesBossAssaultAndBossFlag(int day)
    {
        var state = DefaultState.Create($"wave-composition-milestone-{day}");
        state.Day = day;

        WaveSpec spec = WaveComposer.ComposeWave(state, waveIndex: 3, totalWaves: 4);

        Assert.Equal("boss_assault", spec.Theme);
        Assert.True(spec.HasBoss);
    }

    [Theory]
    [InlineData(6)]
    [InlineData(8)]
    [InlineData(13)]
    [InlineData(15)]
    public void ComposeWave_FinalWaveOffMilestoneDay_DoesNotUseBossAssault(int day)
    {
        var state = DefaultState.Create($"wave-composition-non-milestone-{day}");
        state.Day = day;

        WaveSpec spec = WaveComposer.ComposeWave(state, waveIndex: 3, totalWaves: 4);

        Assert.NotEqual("boss_assault", spec.Theme);
        Assert.False(spec.HasBoss);
    }

    [Fact]
    public void DifficultyCurve_TotalEnemiesAcrossNight_IncreasesWithDay()
    {
        const int totalWaves = 4;

        int day2Total = CalculateNightEnemyCount(day: 2, totalWaves);
        int day8Total = CalculateNightEnemyCount(day: 8, totalWaves);
        int day16Total = CalculateNightEnemyCount(day: 16, totalWaves);

        Assert.True(day2Total < day8Total, $"Expected day 8 total > day 2 total, got {day8Total} vs {day2Total}.");
        Assert.True(day8Total < day16Total, $"Expected day 16 total > day 8 total, got {day16Total} vs {day8Total}.");
    }

    [Fact]
    public void DifficultyCurve_EnemyCountIsNonDecreasingAcrossWaveIndices()
    {
        const int day = 12;
        const int totalWaves = 6;
        var counts = new List<int>(totalWaves);

        for (int waveIndex = 0; waveIndex < totalWaves; waveIndex++)
            counts.Add(WaveComposer.CalculateEnemyCount(day, waveIndex, totalWaves));

        for (int i = 1; i < counts.Count; i++)
            Assert.True(counts[i] >= counts[i - 1], $"Wave {i} count {counts[i]} was less than wave {i - 1} count {counts[i - 1]}.");

        Assert.True(counts[^1] > counts[0], $"Expected last wave count > first wave count, got {counts[^1]} vs {counts[0]}.");
    }

    [Fact]
    public void ComposeWave_EnemyHpTotalMatchesBaseAndPerKindBonuses()
    {
        var state = DefaultState.Create("wave-composition-hp-total-match");
        state.Day = 11;
        state.Threat = 4;

        WaveSpec spec = WaveComposer.ComposeWave(state, waveIndex: 2, totalWaves: 5);
        int baseHp = SimBalance.CalculateEnemyHp(state.Day, state.Threat);
        int expectedTotal = 0;

        foreach (string enemyKind in spec.Enemies)
        {
            int hpBonus = Enemies.EnemyKinds.GetValueOrDefault(enemyKind)?.HpBonus ?? 0;
            expectedTotal += baseHp + hpBonus;
        }

        int actualTotal = CalculateWaveHpTotal(state.Day, state.Threat, spec.Enemies);
        Assert.Equal(expectedTotal, actualTotal);
    }

    [Fact]
    public void ComposeWave_EnemyHpTotalIncreasesByDayForSameSeedAndWave()
    {
        var earlyState = DefaultState.Create("wave-composition-hp-scaling");
        earlyState.Day = 4;
        earlyState.Threat = 2;

        var lateState = DefaultState.Create("wave-composition-hp-scaling");
        lateState.Day = 18;
        lateState.Threat = 2;

        WaveSpec earlySpec = WaveComposer.ComposeWave(earlyState, waveIndex: 1, totalWaves: 4);
        WaveSpec lateSpec = WaveComposer.ComposeWave(lateState, waveIndex: 1, totalWaves: 4);

        int earlyHpTotal = CalculateWaveHpTotal(earlyState.Day, earlyState.Threat, earlySpec.Enemies);
        int lateHpTotal = CalculateWaveHpTotal(lateState.Day, lateState.Threat, lateSpec.Enemies);

        Assert.True(
            lateHpTotal > earlyHpTotal,
            $"Expected later-day wave HP total > early-day total, got {lateHpTotal} vs {earlyHpTotal}.");
    }

    [Fact]
    public void WaveTimingAndSpacing_SpawnCadenceAndEnemyAdvanceUseIndependentTimers()
    {
        var state = DefaultState.Create("wave-composition-timing-spacing");
        state.Hp = 50;

        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 3,
            SpawnIntervalSeconds = 0.5f,
            EnemyStepIntervalSeconds = 2.0f,
            EnemyStepDistance = 2,
            EnemyContactDamage = 1,
            TypedHitDamage = 2,
            TypedMissDamage = 0,
            TowerTickDamage = 0,
        };

        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());

        for (int i = 0; i < 3; i++)
            VerticalSliceWaveSim.Step(state, config, deltaSeconds: 0.5f, typedInput: null, new List<string>());

        Assert.Equal(3, state.Enemies.Count);
        Assert.Equal(0, state.NightSpawnRemaining);
        Assert.Equal(50, state.Hp);
        foreach (var enemy in state.Enemies)
            Assert.False(enemy.ContainsKey("dist"), "Enemy should not advance before enemy step timer elapses.");

        VerticalSliceWaveSim.Step(state, config, deltaSeconds: 0.5f, typedInput: null, new List<string>());

        Assert.Equal(3, state.Enemies.Count);
        Assert.Equal(50, state.Hp);
        foreach (var enemy in state.Enemies)
        {
            int dist = Convert.ToInt32(enemy.GetValueOrDefault("dist", -1));
            Assert.Equal(8, dist);
        }
    }

    [Fact]
    public void ProgressiveEnemyVariety_LaterWaveContainsEarlierKinds_ForSameSeed()
    {
        const int day = 10;
        const int totalWaves = 5;

        for (int i = 0; i < 32; i++)
        {
            string seed = $"wave-composition-progressive-{i}";

            var earlyState = DefaultState.Create(seed);
            earlyState.Day = day;
            WaveSpec earlyWave = WaveComposer.ComposeWave(earlyState, waveIndex: 0, totalWaves);

            var lateState = DefaultState.Create(seed);
            lateState.Day = day;
            WaveSpec lateWave = WaveComposer.ComposeWave(lateState, waveIndex: totalWaves - 1, totalWaves);

            var earlyKinds = new HashSet<string>(earlyWave.Enemies, StringComparer.Ordinal);
            var lateKinds = new HashSet<string>(lateWave.Enemies, StringComparer.Ordinal);

            Assert.True(
                earlyKinds.IsSubsetOf(lateKinds),
                $"Seed '{seed}' had early kinds [{string.Join(",", earlyKinds)}] not included in later kinds [{string.Join(",", lateKinds)}].");
        }
    }

    private static int CalculateNightEnemyCount(int day, int totalWaves)
    {
        int total = 0;
        for (int waveIndex = 0; waveIndex < totalWaves; waveIndex++)
            total += WaveComposer.CalculateEnemyCount(day, waveIndex, totalWaves);
        return total;
    }

    private static int CalculateWaveHpTotal(int day, int threat, IReadOnlyList<string> enemyKinds)
    {
        var state = DefaultState.Create($"wave-composition-hp-{day}-{threat}-{enemyKinds.Count}");
        state.Day = day;
        state.Threat = threat;

        int hpTotal = 0;
        foreach (string enemyKind in enemyKinds)
        {
            var enemy = Enemies.MakeEnemy(state, enemyKind, new GridPoint(0, 0), "test", day);
            hpTotal += Convert.ToInt32(enemy.GetValueOrDefault("hp", 0));
        }

        return hpTotal;
    }
}
