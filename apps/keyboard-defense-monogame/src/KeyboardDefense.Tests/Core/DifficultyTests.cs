using System.Collections.Generic;
using KeyboardDefense.Core.Combat;

namespace KeyboardDefense.Tests.Core;

public class DifficultyCoreTests
{
    [Fact]
    public void DefaultMode_IsAdventure()
    {
        Assert.Equal("adventure", Difficulty.DefaultMode);
    }

    [Fact]
    public void Modes_ContainsExpectedFiveIds()
    {
        Assert.Equal(5, Difficulty.Modes.Count);
        Assert.Contains("story", Difficulty.Modes.Keys);
        Assert.Contains("adventure", Difficulty.Modes.Keys);
        Assert.Contains("champion", Difficulty.Modes.Keys);
        Assert.Contains("nightmare", Difficulty.Modes.Keys);
        Assert.Contains("zen", Difficulty.Modes.Keys);
    }

    [Fact]
    public void StoryMode_HasExpectedValues()
    {
        var story = Difficulty.Modes["story"];
        Assert.Equal(0.6, story.EnemyHealth);
        Assert.Equal(0.5, story.EnemyDamage);
        Assert.False(story.EnemiesDisabled);
    }

    [Fact]
    public void ZenMode_HasExpectedValues()
    {
        var zen = Difficulty.Modes["zen"];
        Assert.Equal(0.0, zen.EnemyHealth);
        Assert.True(zen.EnemiesDisabled);
    }

    [Fact]
    public void ChampionMode_HasExpectedUnlockRequirement()
    {
        var champion = Difficulty.Modes["champion"];
        Assert.Equal("complete_act_3", champion.UnlockRequirement);
    }

    [Fact]
    public void NightmareMode_HasExpectedUnlockRequirement()
    {
        var nightmare = Difficulty.Modes["nightmare"];
        Assert.Equal("complete_champion", nightmare.UnlockRequirement);
    }

    [Fact]
    public void GetMode_KnownMode_ReturnsMode()
    {
        var mode = Difficulty.GetMode("story");
        Assert.Equal("Story Mode", mode.Name);
    }

    [Fact]
    public void GetMode_UnknownMode_ReturnsAdventure()
    {
        var mode = Difficulty.GetMode("unknown_mode");
        Assert.Equal("Adventure Mode", mode.Name);
        Assert.Equal(1.0, mode.EnemyHealth);
    }

    [Fact]
    public void GetModeName_KnownMode_ReturnsDisplayName()
    {
        Assert.Equal("Nightmare Mode", Difficulty.GetModeName("nightmare"));
    }

    [Fact]
    public void GetModeName_UnknownMode_ReturnsDefaultDisplayName()
    {
        Assert.Equal("Adventure Mode", Difficulty.GetModeName("not_real"));
    }

    [Fact]
    public void GetAllModeIds_ReturnsAllFiveModes()
    {
        var modeIds = Difficulty.GetAllModeIds();
        Assert.Equal(5, modeIds.Count);
        Assert.Contains("story", modeIds);
        Assert.Contains("adventure", modeIds);
        Assert.Contains("champion", modeIds);
        Assert.Contains("nightmare", modeIds);
        Assert.Contains("zen", modeIds);
    }

    [Fact]
    public void GetUnlockedModes_NoBadges_ReturnsAlwaysUnlockedModes()
    {
        var unlocked = Difficulty.GetUnlockedModes(new HashSet<string>());
        Assert.Equal(new[] { "story", "adventure", "zen" }, unlocked);
    }

    [Fact]
    public void GetUnlockedModes_FullAlphabetBadge_UnlocksChampion()
    {
        var unlocked = Difficulty.GetUnlockedModes(new HashSet<string> { "full_alphabet_badge" });
        Assert.Equal(new[] { "story", "adventure", "zen", "champion" }, unlocked);
    }

    [Fact]
    public void GetUnlockedModes_ChampionComplete_UnlocksNightmare()
    {
        var unlocked = Difficulty.GetUnlockedModes(new HashSet<string> { "champion_complete" });
        Assert.Equal(new[] { "story", "adventure", "zen", "nightmare" }, unlocked);
    }

    [Fact]
    public void GetUnlockedModes_BothBadges_UnlocksChampionAndNightmare()
    {
        var unlocked = Difficulty.GetUnlockedModes(new HashSet<string> { "full_alphabet_badge", "champion_complete" });
        Assert.Equal(new[] { "story", "adventure", "zen", "champion", "nightmare" }, unlocked);
    }

    [Fact]
    public void ApplyHealthModifier_AppliesStoryAdventureNightmareAndZenClamp()
    {
        const int baseHp = 10;
        Assert.Equal(6, Difficulty.ApplyHealthModifier(baseHp, "story"));
        Assert.Equal(10, Difficulty.ApplyHealthModifier(baseHp, "adventure"));
        Assert.Equal(20, Difficulty.ApplyHealthModifier(baseHp, "nightmare"));
        Assert.Equal(1, Difficulty.ApplyHealthModifier(baseHp, "zen"));
    }

    [Fact]
    public void ApplyDamageModifier_AppliesStoryAdventureNightmareAndZenClamp()
    {
        const int baseDamage = 10;
        Assert.Equal(5, Difficulty.ApplyDamageModifier(baseDamage, "story"));
        Assert.Equal(10, Difficulty.ApplyDamageModifier(baseDamage, "adventure"));
        Assert.Equal(20, Difficulty.ApplyDamageModifier(baseDamage, "nightmare"));
        Assert.Equal(1, Difficulty.ApplyDamageModifier(baseDamage, "zen"));
    }

    [Fact]
    public void ApplySpeedModifier_AppliesStoryAdventureNightmareAndZenClamp()
    {
        const double baseSpeed = 1.0;
        Assert.Equal(0.8, Difficulty.ApplySpeedModifier(baseSpeed, "story"), 10);
        Assert.Equal(1.0, Difficulty.ApplySpeedModifier(baseSpeed, "adventure"), 10);
        Assert.Equal(1.4, Difficulty.ApplySpeedModifier(baseSpeed, "nightmare"), 10);
        Assert.Equal(0.1, Difficulty.ApplySpeedModifier(baseSpeed, "zen"), 10);
    }

    [Fact]
    public void ApplyWaveSizeModifier_AppliesStoryAdventureNightmareAndZenClamp()
    {
        const int baseSize = 10;
        Assert.Equal(7, Difficulty.ApplyWaveSizeModifier(baseSize, "story"));
        Assert.Equal(10, Difficulty.ApplyWaveSizeModifier(baseSize, "adventure"));
        Assert.Equal(15, Difficulty.ApplyWaveSizeModifier(baseSize, "nightmare"));
        Assert.Equal(1, Difficulty.ApplyWaveSizeModifier(baseSize, "zen"));
    }

    [Fact]
    public void ApplyGoldModifier_AppliesStoryAdventureNightmareAndZenClamp()
    {
        const int baseGold = 20;
        Assert.Equal(20, Difficulty.ApplyGoldModifier(baseGold, "story"));
        Assert.Equal(20, Difficulty.ApplyGoldModifier(baseGold, "adventure"));
        Assert.Equal(35, Difficulty.ApplyGoldModifier(baseGold, "nightmare"));
        Assert.Equal(5, Difficulty.ApplyGoldModifier(baseGold, "zen"));
        Assert.Equal(1, Difficulty.ApplyGoldModifier(3, "zen"));
    }
}
