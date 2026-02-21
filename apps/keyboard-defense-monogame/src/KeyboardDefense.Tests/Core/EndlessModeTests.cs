using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class EndlessModeCoreTests
{
    [Fact]
    public void UnlockDayConstant_IsFifteen()
    {
        Assert.Equal(15, EndlessMode.UnlockDay);
    }

    [Fact]
    public void UnlockWavesConstant_IsFortyFive()
    {
        Assert.Equal(45, EndlessMode.UnlockWaves);
    }

    [Fact]
    public void HpScalePerDayConstant_IsExpectedValue()
    {
        Assert.Equal(0.08, EndlessMode.HpScalePerDay);
    }

    [Fact]
    public void SpeedScalePerDayConstant_IsExpectedValue()
    {
        Assert.Equal(0.02, EndlessMode.SpeedScalePerDay);
    }

    [Fact]
    public void CountScalePerDayConstant_IsExpectedValue()
    {
        Assert.Equal(0.05, EndlessMode.CountScalePerDay);
    }

    [Fact]
    public void DamageScalePerDayConstant_IsExpectedValue()
    {
        Assert.Equal(0.04, EndlessMode.DamageScalePerDay);
    }

    [Fact]
    public void IsUnlocked_DayFourteen_ReturnsFalse()
    {
        var state = new GameState { Day = 14 };

        Assert.False(EndlessMode.IsUnlocked(state));
    }

    [Fact]
    public void IsUnlocked_DayFifteen_ReturnsTrue()
    {
        var state = new GameState { Day = 15 };

        Assert.True(EndlessMode.IsUnlocked(state));
    }

    [Fact]
    public void IsUnlocked_DayOneHundred_ReturnsTrue()
    {
        var state = new GameState { Day = 100 };

        Assert.True(EndlessMode.IsUnlocked(state));
    }

    [Fact]
    public void ScaleMethods_DayZero_ReturnOne()
    {
        Assert.Equal(1.0, EndlessMode.GetHpScale(0), 10);
        Assert.Equal(1.0, EndlessMode.GetSpeedScale(0), 10);
        Assert.Equal(1.0, EndlessMode.GetCountScale(0), 10);
        Assert.Equal(1.0, EndlessMode.GetDamageScale(0), 10);
    }

    [Fact]
    public void ScaleMethods_DayTen_ReturnExpectedValues()
    {
        Assert.Equal(1.8, EndlessMode.GetHpScale(10), 10);
        Assert.Equal(1.2, EndlessMode.GetSpeedScale(10), 10);
        Assert.Equal(1.5, EndlessMode.GetCountScale(10), 10);
        Assert.Equal(1.4, EndlessMode.GetDamageScale(10), 10);
    }

    [Fact]
    public void Milestones_HasFiveEntries()
    {
        Assert.Equal(5, EndlessMode.Milestones.Count);
    }

    [Fact]
    public void CheckMilestone_DayFive_ReturnsExpectedMilestone()
    {
        var milestone = EndlessMode.CheckMilestone(5);

        Assert.NotNull(milestone);
        Assert.Equal("Enduring", milestone!.Name);
        Assert.Equal(500, milestone.GoldReward);
        Assert.Equal("Survived 5 endless days", milestone.Description);
    }

    [Fact]
    public void CheckMilestone_DayTen_ReturnsExpectedMilestone()
    {
        var milestone = EndlessMode.CheckMilestone(10);

        Assert.NotNull(milestone);
        Assert.Equal("Relentless", milestone!.Name);
        Assert.Equal(1000, milestone.GoldReward);
        Assert.Equal("Survived 10 endless days", milestone.Description);
    }

    [Fact]
    public void CheckMilestone_DayFifteen_ReturnsExpectedMilestone()
    {
        var milestone = EndlessMode.CheckMilestone(15);

        Assert.NotNull(milestone);
        Assert.Equal("Unstoppable", milestone!.Name);
        Assert.Equal(2000, milestone.GoldReward);
        Assert.Equal("Survived 15 endless days", milestone.Description);
    }

    [Fact]
    public void CheckMilestone_DayTwenty_ReturnsExpectedMilestone()
    {
        var milestone = EndlessMode.CheckMilestone(20);

        Assert.NotNull(milestone);
        Assert.Equal("Legendary", milestone!.Name);
        Assert.Equal(5000, milestone.GoldReward);
        Assert.Equal("Survived 20 endless days", milestone.Description);
    }

    [Fact]
    public void CheckMilestone_DayThirty_ReturnsExpectedMilestone()
    {
        var milestone = EndlessMode.CheckMilestone(30);

        Assert.NotNull(milestone);
        Assert.Equal("Mythic", milestone!.Name);
        Assert.Equal(10000, milestone.GoldReward);
        Assert.Equal("Survived 30 endless days", milestone.Description);
    }

    [Fact]
    public void CheckMilestone_NonMilestoneDay_ReturnsNull()
    {
        Assert.Null(EndlessMode.CheckMilestone(6));
    }

    [Fact]
    public void CalculateWaveSize_DayZero_ReturnsExpectedValue()
    {
        var waveSize = EndlessMode.CalculateWaveSize(0, 10);

        Assert.Equal(8, waveSize);
    }

    [Fact]
    public void CalculateWaveSize_DayTen_ReturnsExpectedValue()
    {
        var waveSize = EndlessMode.CalculateWaveSize(10, 10);

        Assert.Equal(24, waveSize);
    }

    [Fact]
    public void CalculateEnemyHp_DayZero_ReturnsBaseHp()
    {
        var enemyHp = EndlessMode.CalculateEnemyHp(0, 75);

        Assert.Equal(75, enemyHp);
    }

    [Fact]
    public void CalculateEnemyHp_DayTen_ReturnsScaledHp()
    {
        var enemyHp = EndlessMode.CalculateEnemyHp(10, 75);

        Assert.Equal(135, enemyHp);
    }
}
