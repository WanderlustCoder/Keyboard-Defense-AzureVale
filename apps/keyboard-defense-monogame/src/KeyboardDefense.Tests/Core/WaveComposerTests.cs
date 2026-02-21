using System.Collections.Generic;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class WaveComposerCoreTests
{
    [Fact]
    public void WaveThemes_HasExpectedTenThemesInOrder()
    {
        string[] expected =
        {
            "standard", "swarm", "elite", "speedy", "tanky",
            "magic", "undead", "burning", "frozen", "boss_assault"
        };

        Assert.Equal(10, WaveComposer.WaveThemes.Length);
        Assert.Equal(expected, WaveComposer.WaveThemes);
    }

    [Fact]
    public void ThemeKinds_HasEntryForEveryWaveTheme()
    {
        foreach (string theme in WaveComposer.WaveThemes)
        {
            Assert.True(
                WaveComposer.ThemeKinds.ContainsKey(theme),
                $"ThemeKinds is missing key '{theme}'.");
            Assert.NotEmpty(WaveComposer.ThemeKinds[theme]);
        }
    }

    [Fact]
    public void ThemeKinds_HasNoUnexpectedThemeEntries()
    {
        var knownThemes = new HashSet<string>(WaveComposer.WaveThemes);
        Assert.Equal(WaveComposer.WaveThemes.Length, WaveComposer.ThemeKinds.Count);

        foreach (string theme in WaveComposer.ThemeKinds.Keys)
            Assert.Contains(theme, knownThemes);
    }

    [Fact]
    public void ThemeKinds_StandardThemeMatchesExpectedKinds()
    {
        Assert.Equal(
            new[] { "raider", "scout", "armored" },
            WaveComposer.ThemeKinds["standard"]);
    }

    [Fact]
    public void ThemeKinds_BossAssaultThemeMatchesExpectedKinds()
    {
        Assert.Equal(
            new[] { "raider", "armored", "champion" },
            WaveComposer.ThemeKinds["boss_assault"]);
    }

    [Fact]
    public void CalculateEnemyCount_DayZero_FirstWave_ReturnsBaseCount()
    {
        int count = WaveComposer.CalculateEnemyCount(day: 0, waveIndex: 0, totalWaves: 3);
        Assert.Equal(2, count);
    }

    [Fact]
    public void CalculateEnemyCount_DayScaling_UsesIntegerDivision()
    {
        int dayOne = WaveComposer.CalculateEnemyCount(day: 1, waveIndex: 0, totalWaves: 3);
        int dayTwo = WaveComposer.CalculateEnemyCount(day: 2, waveIndex: 0, totalWaves: 3);

        Assert.Equal(2, dayOne);
        Assert.Equal(3, dayTwo);
    }

    [Fact]
    public void CalculateEnemyCount_WaveScaling_AppliesMultiplier()
    {
        int count = WaveComposer.CalculateEnemyCount(day: 10, waveIndex: 2, totalWaves: 4);
        Assert.Equal(10, count); // (2 + 10/2) * (1 + 2/4) => 7 * 1.5 => 10.5 => 10
    }

    [Fact]
    public void CalculateEnemyCount_WaveIndexEqualToTotalWaves_DoublesBaseCount()
    {
        int count = WaveComposer.CalculateEnemyCount(day: 6, waveIndex: 3, totalWaves: 3);
        Assert.Equal(10, count); // base 5, multiplier 2.0
    }

    [Fact]
    public void CalculateEnemyCount_ClampsToAtLeastOne()
    {
        int count = WaveComposer.CalculateEnemyCount(day: -100, waveIndex: 0, totalWaves: 1);
        Assert.Equal(1, count);
    }

    [Fact]
    public void SelectTheme_FinalWaveOnDaySeven_ReturnsBossAssault()
    {
        var state = DefaultState.Create();
        state.Day = 7;

        string theme = WaveComposer.SelectTheme(state, waveIndex: 2, totalWaves: 3);

        Assert.Equal("boss_assault", theme);
    }

    [Fact]
    public void SelectTheme_FinalWaveOnNonBossDay_ExcludesBossAssault()
    {
        var state = DefaultState.Create();
        state.Day = 8;

        string theme = WaveComposer.SelectTheme(state, waveIndex: 2, totalWaves: 3);

        Assert.NotEqual("boss_assault", theme);
        Assert.Contains(theme, WaveComposer.WaveThemes);
    }

    [Fact]
    public void SelectTheme_NonFinalWaveOnBossDay_DoesNotForceBossAssault()
    {
        var state = DefaultState.Create();
        state.Day = 14;

        string theme = WaveComposer.SelectTheme(state, waveIndex: 1, totalWaves: 3);

        Assert.NotEqual("boss_assault", theme);
    }

    [Fact]
    public void ComposeWave_ReturnsSpecMetadataAndCalculatedEnemyCount()
    {
        var state = DefaultState.Create();
        state.Day = 5;

        WaveSpec spec = WaveComposer.ComposeWave(state, waveIndex: 1, totalWaves: 4);
        int expectedCount = WaveComposer.CalculateEnemyCount(state.Day, waveIndex: 1, totalWaves: 4);

        Assert.Equal(1, spec.WaveIndex);
        Assert.Equal(4, spec.TotalWaves);
        Assert.Equal(expectedCount, spec.Enemies.Count);
        Assert.Contains(spec.Theme, WaveComposer.WaveThemes);
    }

    [Fact]
    public void ComposeWave_EnemiesComeFromSelectedThemePool()
    {
        var state = DefaultState.Create();
        state.Day = 4;

        WaveSpec spec = WaveComposer.ComposeWave(state, waveIndex: 0, totalWaves: 3);
        string[] validKinds = WaveComposer.ThemeKinds[spec.Theme];

        Assert.NotEmpty(spec.Enemies);
        foreach (string enemyKind in spec.Enemies)
            Assert.Contains(enemyKind, validKinds);
    }

    [Fact]
    public void ComposeWave_FinalWaveOnBossDay_SetsBossThemeAndFlag()
    {
        var state = DefaultState.Create();
        state.Day = 7;

        WaveSpec spec = WaveComposer.ComposeWave(state, waveIndex: 2, totalWaves: 3);

        Assert.Equal("boss_assault", spec.Theme);
        Assert.True(spec.HasBoss);
        foreach (string enemyKind in spec.Enemies)
            Assert.Contains(enemyKind, WaveComposer.ThemeKinds["boss_assault"]);
    }

    [Fact]
    public void ComposeWave_FinalWaveOnNonBossDay_DoesNotSetBossFlag()
    {
        var state = DefaultState.Create();
        state.Day = 8;

        WaveSpec spec = WaveComposer.ComposeWave(state, waveIndex: 2, totalWaves: 3);

        Assert.NotEqual("boss_assault", spec.Theme);
        Assert.False(spec.HasBoss);
    }

    [Fact]
    public void GetThemeDisplayName_MapsAllThemesAndPassesThroughUnknown()
    {
        var expectedDisplayNames = new Dictionary<string, string>
        {
            ["standard"] = "Standard",
            ["swarm"] = "Swarm",
            ["elite"] = "Elite",
            ["speedy"] = "Speedy",
            ["tanky"] = "Tanky",
            ["magic"] = "Magic",
            ["undead"] = "Undead",
            ["burning"] = "Burning",
            ["frozen"] = "Frozen",
            ["boss_assault"] = "Boss Assault",
        };

        foreach (var entry in expectedDisplayNames)
            Assert.Equal(entry.Value, WaveComposer.GetThemeDisplayName(entry.Key));

        Assert.Equal("unknown_theme", WaveComposer.GetThemeDisplayName("unknown_theme"));
    }
}
