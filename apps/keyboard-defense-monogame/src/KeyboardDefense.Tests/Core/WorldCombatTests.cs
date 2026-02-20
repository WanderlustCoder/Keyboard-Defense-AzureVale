using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class BuffsTests
{
    [Fact]
    public void AddBuff_AppearsInActiveBuffs()
    {
        var state = new GameState();
        Buffs.AddBuff(state, "test_buff", 3);
        Assert.True(Buffs.HasBuff(state, "test_buff"));
    }

    [Fact]
    public void AddBuff_SetsRemainingDays()
    {
        var state = new GameState();
        Buffs.AddBuff(state, "test_buff", 5);
        Assert.Equal(5, Buffs.GetBuffRemainingDays(state, "test_buff"));
    }

    [Fact]
    public void AddBuff_DuplicateId_ReplacesExisting()
    {
        var state = new GameState();
        Buffs.AddBuff(state, "test_buff", 3);
        Buffs.AddBuff(state, "test_buff", 7);

        Assert.Single(state.ActiveBuffs.FindAll(
            b => b.GetValueOrDefault("buff_id")?.ToString() == "test_buff"));
        Assert.Equal(7, Buffs.GetBuffRemainingDays(state, "test_buff"));
    }

    [Fact]
    public void HasBuff_Nonexistent_ReturnsFalse()
    {
        var state = new GameState();
        Assert.False(Buffs.HasBuff(state, "nonexistent"));
    }

    [Fact]
    public void GetBuffRemainingDays_Nonexistent_ReturnsZero()
    {
        var state = new GameState();
        Assert.Equal(0, Buffs.GetBuffRemainingDays(state, "nonexistent"));
    }

    [Fact]
    public void ExpireBuffs_DecrementsAndRemoves()
    {
        var state = new GameState();
        Buffs.AddBuff(state, "short_buff", 1);
        Buffs.AddBuff(state, "long_buff", 5);

        var expired = Buffs.ExpireBuffs(state);

        Assert.Contains("short_buff", expired);
        Assert.DoesNotContain("long_buff", expired);
        Assert.False(Buffs.HasBuff(state, "short_buff"));
        Assert.True(Buffs.HasBuff(state, "long_buff"));
        Assert.Equal(4, Buffs.GetBuffRemainingDays(state, "long_buff"));
    }

    [Fact]
    public void AddBuff_WithEffects_ReturnsMultiplier()
    {
        var state = new GameState();
        Buffs.AddBuff(state, "damage_buff", 3, new() { ["damage_multiplier"] = 1.5 });

        double dmgMult = Buffs.GetDamageMultiplier(state);
        Assert.Equal(1.5, dmgMult);
    }

    [Fact]
    public void GetMultiplier_NoBuffs_ReturnsZero()
    {
        var state = new GameState();
        Assert.Equal(0.0, Buffs.GetDamageMultiplier(state));
        Assert.Equal(0.0, Buffs.GetResourceMultiplier(state));
    }

    [Fact]
    public void ApplyDawnEffects_ApBonus_IncrementsAp()
    {
        var state = new GameState();
        state.Ap = 1;
        state.ApMax = 10;
        Buffs.AddBuff(state, "energized", 3, new() { ["ap_bonus"] = 2.0 });

        var messages = Buffs.ApplyDawnEffects(state);

        Assert.Equal(3, state.Ap);
        Assert.Contains(messages, m => m.Contains("AP"));
    }

    [Fact]
    public void ApplyDawnEffects_HpRegen_HealsWhenLow()
    {
        var state = new GameState();
        state.Hp = 5;
        Buffs.AddBuff(state, "regen", 3, new() { ["hp_regen"] = 2.0 });

        Buffs.ApplyDawnEffects(state);

        Assert.Equal(7, state.Hp);
    }

    [Fact]
    public void ApplyDawnEffects_HpRegen_CapsAtMax()
    {
        var state = new GameState();
        state.Hp = 9;
        Buffs.AddBuff(state, "regen", 3, new() { ["hp_regen"] = 5.0 });

        Buffs.ApplyDawnEffects(state);

        Assert.Equal(10, state.Hp); // Capped at 10
    }
}

public class WaveComposerTests
{
    [Fact]
    public void WaveThemes_NotEmpty()
    {
        Assert.NotEmpty(WaveComposer.WaveThemes);
    }

    [Fact]
    public void ThemeKinds_AllThemesHaveKinds()
    {
        foreach (string theme in WaveComposer.WaveThemes)
        {
            Assert.True(WaveComposer.ThemeKinds.ContainsKey(theme),
                $"Theme '{theme}' missing from ThemeKinds");
            Assert.NotEmpty(WaveComposer.ThemeKinds[theme]);
        }
    }

    [Fact]
    public void ComposeWave_ReturnsValidSpec()
    {
        var state = DefaultState.Create("wave_test", true);
        var spec = WaveComposer.ComposeWave(state, 0, 3);

        Assert.NotNull(spec);
        Assert.NotEmpty(spec.Theme);
        Assert.NotEmpty(spec.Enemies);
        Assert.Equal(0, spec.WaveIndex);
        Assert.Equal(3, spec.TotalWaves);
    }

    [Fact]
    public void ComposeWave_EnemiesAreFromTheme()
    {
        var state = DefaultState.Create("theme_check", true);
        var spec = WaveComposer.ComposeWave(state, 0, 3);

        var validKinds = WaveComposer.ThemeKinds[spec.Theme];
        foreach (string kind in spec.Enemies)
        {
            Assert.Contains(kind, validKinds);
        }
    }

    [Fact]
    public void CalculateEnemyCount_ScalesWithDay()
    {
        int day1 = WaveComposer.CalculateEnemyCount(1, 0, 3);
        int day10 = WaveComposer.CalculateEnemyCount(10, 0, 3);
        Assert.True(day10 > day1);
    }

    [Fact]
    public void CalculateEnemyCount_AlwaysAtLeastOne()
    {
        int count = WaveComposer.CalculateEnemyCount(1, 0, 1);
        Assert.True(count >= 1);
    }

    [Fact]
    public void SelectTheme_Day7LastWave_ReturnsBossAssault()
    {
        var state = DefaultState.Create("boss_test", true);
        state.Day = 7;
        string theme = WaveComposer.SelectTheme(state, 2, 3); // Last wave
        Assert.Equal("boss_assault", theme);
    }

    [Fact]
    public void GetThemeDisplayName_ReturnsReadableName()
    {
        Assert.Equal("Standard", WaveComposer.GetThemeDisplayName("standard"));
        Assert.Equal("Boss Assault", WaveComposer.GetThemeDisplayName("boss_assault"));
    }

    [Fact]
    public void GetThemeDisplayName_UnknownTheme_ReturnsRaw()
    {
        Assert.Equal("custom_theme", WaveComposer.GetThemeDisplayName("custom_theme"));
    }
}

public class DifficultyTests
{
    [Fact]
    public void Modes_ContainsAllExpected()
    {
        Assert.True(Difficulty.Modes.ContainsKey("story"));
        Assert.True(Difficulty.Modes.ContainsKey("adventure"));
        Assert.True(Difficulty.Modes.ContainsKey("champion"));
        Assert.True(Difficulty.Modes.ContainsKey("nightmare"));
        Assert.True(Difficulty.Modes.ContainsKey("zen"));
    }

    [Fact]
    public void GetMode_Default_ReturnsAdventure()
    {
        var mode = Difficulty.GetMode(Difficulty.DefaultMode);
        Assert.Equal("Adventure Mode", mode.Name);
    }

    [Fact]
    public void GetMode_Unknown_FallsBackToDefault()
    {
        var mode = Difficulty.GetMode("nonexistent");
        Assert.Equal("Adventure Mode", mode.Name);
    }

    [Fact]
    public void ApplyHealthModifier_StoryMode_Reduces()
    {
        int hp = Difficulty.ApplyHealthModifier(100, "story");
        Assert.True(hp < 100);
    }

    [Fact]
    public void ApplyHealthModifier_Nightmare_Increases()
    {
        int hp = Difficulty.ApplyHealthModifier(100, "nightmare");
        Assert.True(hp > 100);
    }

    [Fact]
    public void ApplyHealthModifier_AlwaysAtLeastOne()
    {
        int hp = Difficulty.ApplyHealthModifier(1, "zen");
        Assert.True(hp >= 1);
    }

    [Fact]
    public void ApplyDamageModifier_AdventureMode_NoChange()
    {
        // Adventure mode has 1.0 damage multiplier
        int dmg = Difficulty.ApplyDamageModifier(10, "adventure");
        Assert.Equal(10, dmg);
    }

    [Fact]
    public void ApplyWaveSizeModifier_StorySmaller_NightmareLarger()
    {
        int story = Difficulty.ApplyWaveSizeModifier(10, "story");
        int nightmare = Difficulty.ApplyWaveSizeModifier(10, "nightmare");
        Assert.True(nightmare > story);
    }

    [Fact]
    public void GetUnlockedModes_NoProgress_HasBaseThree()
    {
        var unlocked = Difficulty.GetUnlockedModes(new HashSet<string>());
        Assert.Contains("story", unlocked);
        Assert.Contains("adventure", unlocked);
        Assert.Contains("zen", unlocked);
        Assert.DoesNotContain("champion", unlocked);
    }

    [Fact]
    public void GetUnlockedModes_WithBadge_UnlocksChampion()
    {
        var badges = new HashSet<string> { "full_alphabet_badge" };
        var unlocked = Difficulty.GetUnlockedModes(badges);
        Assert.Contains("champion", unlocked);
    }

    [Fact]
    public void GetAllModeIds_ReturnsAllFive()
    {
        var ids = Difficulty.GetAllModeIds();
        Assert.Equal(5, ids.Count);
    }
}

public class VictoryTests
{
    [Fact]
    public void CheckVictory_FullHp_ReturnsNone()
    {
        var state = new GameState();
        state.Hp = 10;
        Assert.Equal("none", Victory.CheckVictory(state));
    }

    [Fact]
    public void CheckVictory_ZeroHp_ReturnsDefeat()
    {
        var state = new GameState();
        state.Hp = 0;
        Assert.Equal("defeat", Victory.CheckVictory(state));
    }

    [Fact]
    public void CheckVictory_NegativeHp_ReturnsDefeat()
    {
        var state = new GameState();
        state.Hp = -5;
        Assert.Equal("defeat", Victory.CheckVictory(state));
    }

    [Fact]
    public void CheckVictory_Day30With5Quests_ReturnsVictory()
    {
        var state = new GameState();
        state.Hp = 10;
        state.Day = 30;
        for (int i = 0; i < 5; i++)
            state.CompletedQuests.Add($"quest_{i}");

        Assert.Equal("victory", Victory.CheckVictory(state));
    }

    [Fact]
    public void CheckVictory_4BossesDefeated_ReturnsVictory()
    {
        var state = new GameState();
        state.Hp = 10;
        for (int i = 0; i < 4; i++)
            state.BossesDefeated.Add($"boss_{i}");

        Assert.Equal("victory", Victory.CheckVictory(state));
    }

    [Fact]
    public void CalculateScore_IncludesDayGoldQuestsBosses()
    {
        var state = new GameState();
        state.Day = 10;
        state.Gold = 100;
        state.CompletedQuests.Add("test");
        state.BossesDefeated.Add("boss");

        int score = Victory.CalculateScore(state);
        Assert.True(score > 0);
        // Day=10*100=1000, Gold=100*2=200, Quests=1*500=500, Bosses=1*1000=1000
        Assert.True(score >= 2700);
    }

    [Fact]
    public void GetGrade_HighScore_ReturnsS()
    {
        Assert.Equal("S", Victory.GetGrade(20000));
        Assert.Equal("S", Victory.GetGrade(25000));
    }

    [Fact]
    public void GetGrade_LowScore_ReturnsD()
    {
        Assert.Equal("D", Victory.GetGrade(100));
        Assert.Equal("D", Victory.GetGrade(0));
    }

    [Fact]
    public void GetGrade_AllTiers()
    {
        Assert.Equal("D", Victory.GetGrade(4999));
        Assert.Equal("C", Victory.GetGrade(5000));
        Assert.Equal("B", Victory.GetGrade(10000));
        Assert.Equal("A", Victory.GetGrade(15000));
        Assert.Equal("S", Victory.GetGrade(20000));
    }

    [Fact]
    public void GetVictoryReport_Defeat_HasSurvivedDays()
    {
        var state = new GameState();
        state.Hp = 0;
        state.Day = 7;

        var report = Victory.GetVictoryReport(state);
        Assert.Equal("defeat", report["result"]);
        Assert.Equal(7, report["survived_days"]);
    }

    [Fact]
    public void GetVictoryReport_Victory_HasScoreAndGrade()
    {
        var state = new GameState();
        state.Hp = 10;
        state.Day = 30;
        state.Gold = 500;
        for (int i = 0; i < 5; i++)
            state.CompletedQuests.Add($"quest_{i}");

        var report = Victory.GetVictoryReport(state);
        Assert.Equal("victory", report["result"]);
        Assert.True(report.ContainsKey("score"));
        Assert.True(report.ContainsKey("grade"));
    }
}

public class SimTickTests
{
    [Fact]
    public void AdvanceDay_IncrementsDayCounter()
    {
        var state = DefaultState.Create("tick_test", true);
        int originalDay = state.Day;

        SimTick.AdvanceDay(state);

        Assert.Equal(originalDay + 1, state.Day);
    }

    [Fact]
    public void AdvanceDay_ReturnsEvents()
    {
        var state = DefaultState.Create("tick_test", true);
        var result = SimTick.AdvanceDay(state);

        Assert.True(result.ContainsKey("events"));
        var events = result["events"] as List<string>;
        Assert.NotNull(events);
        Assert.NotEmpty(events!);
    }

    [Fact]
    public void AdvanceDay_WithFarm_ProducesFood()
    {
        var state = DefaultState.Create("farm_test", true);
        state.Structures[0] = "farm";
        int foodBefore = state.Resources.GetValueOrDefault("food", 0);

        SimTick.AdvanceDay(state);

        Assert.True(state.Resources.GetValueOrDefault("food", 0) > foodBefore);
    }

    [Fact]
    public void ComputeNightWaveTotal_AlwaysAtLeastOne()
    {
        var state = DefaultState.Create("wave_total_test", true);
        int total = SimTick.ComputeNightWaveTotal(state, 100);
        Assert.True(total >= 1);
    }

    [Fact]
    public void ComputeNightWaveTotal_HighDefense_ReducesWaves()
    {
        var state = DefaultState.Create("defense_test", true);
        int lowDef = SimTick.ComputeNightWaveTotal(state, 0);
        int highDef = SimTick.ComputeNightWaveTotal(state, 10);
        Assert.True(highDef <= lowDef);
    }

    [Fact]
    public void BuildNightPrompt_ReturnsNonEmpty()
    {
        var state = DefaultState.Create("prompt_test", true);
        string prompt = SimTick.BuildNightPrompt(state);
        Assert.NotEmpty(prompt);
    }
}
