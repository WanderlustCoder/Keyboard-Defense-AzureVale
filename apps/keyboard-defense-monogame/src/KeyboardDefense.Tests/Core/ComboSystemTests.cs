using KeyboardDefense.Core.Typing;

namespace KeyboardDefense.Tests.Core;

public class ComboSystemTests
{
    [Fact]
    public void Tiers_HasEightEntries()
    {
        Assert.Equal(8, ComboSystem.Tiers.Length);
    }

    [Fact]
    public void Tiers_HaveExpectedThresholds()
    {
        int[] expectedThresholds = [0, 3, 5, 10, 20, 50, 100, 200];

        for (int i = 0; i < expectedThresholds.Length; i++)
        {
            Assert.Equal(expectedThresholds[i], ComboSystem.Tiers[i].Threshold);
        }
    }

    [Fact]
    public void GetTierIndex_ZeroCombo_ReturnsDefaultTier()
    {
        Assert.Equal(0, ComboSystem.GetTierIndex(0));
    }

    [Fact]
    public void GetTierIndex_AtWarmingUpThreshold_ReturnsTierOne()
    {
        Assert.Equal(1, ComboSystem.GetTierIndex(3));
    }

    [Fact]
    public void GetTierIndex_AtOnFireThreshold_ReturnsTierTwo()
    {
        Assert.Equal(2, ComboSystem.GetTierIndex(5));
    }

    [Fact]
    public void GetTierIndex_AtBlazingThreshold_ReturnsTierThree()
    {
        Assert.Equal(3, ComboSystem.GetTierIndex(10));
    }

    [Fact]
    public void GetTierIndex_AtInfernoThreshold_ReturnsTierFour()
    {
        Assert.Equal(4, ComboSystem.GetTierIndex(20));
    }

    [Fact]
    public void GetTierIndex_AtUnstoppableThreshold_ReturnsTierFive()
    {
        Assert.Equal(5, ComboSystem.GetTierIndex(50));
    }

    [Fact]
    public void GetTierIndex_AtLegendaryThreshold_ReturnsTierSix()
    {
        Assert.Equal(6, ComboSystem.GetTierIndex(100));
    }

    [Fact]
    public void GetTierIndex_AtGodlikeThreshold_ReturnsTierSeven()
    {
        Assert.Equal(7, ComboSystem.GetTierIndex(200));
    }

    [Fact]
    public void GetTierIndex_BetweenThresholds_ReturnsCurrentTier()
    {
        Assert.Equal(1, ComboSystem.GetTierIndex(4));
        Assert.Equal(2, ComboSystem.GetTierIndex(9));
        Assert.Equal(3, ComboSystem.GetTierIndex(19));
        Assert.Equal(4, ComboSystem.GetTierIndex(49));
        Assert.Equal(5, ComboSystem.GetTierIndex(99));
        Assert.Equal(6, ComboSystem.GetTierIndex(199));
    }

    [Fact]
    public void GetDamageBonusPercent_AtTierThresholds_ReturnsExpectedBonuses()
    {
        Assert.Equal(0, ComboSystem.GetDamageBonusPercent(0));
        Assert.Equal(5, ComboSystem.GetDamageBonusPercent(3));
        Assert.Equal(10, ComboSystem.GetDamageBonusPercent(5));
        Assert.Equal(20, ComboSystem.GetDamageBonusPercent(10));
        Assert.Equal(35, ComboSystem.GetDamageBonusPercent(20));
        Assert.Equal(50, ComboSystem.GetDamageBonusPercent(50));
        Assert.Equal(75, ComboSystem.GetDamageBonusPercent(100));
        Assert.Equal(100, ComboSystem.GetDamageBonusPercent(200));
    }

    [Fact]
    public void GetGoldBonusPercent_AtTierThresholds_ReturnsExpectedBonuses()
    {
        Assert.Equal(0, ComboSystem.GetGoldBonusPercent(0));
        Assert.Equal(5, ComboSystem.GetGoldBonusPercent(3));
        Assert.Equal(10, ComboSystem.GetGoldBonusPercent(5));
        Assert.Equal(15, ComboSystem.GetGoldBonusPercent(10));
        Assert.Equal(25, ComboSystem.GetGoldBonusPercent(20));
        Assert.Equal(40, ComboSystem.GetGoldBonusPercent(50));
        Assert.Equal(60, ComboSystem.GetGoldBonusPercent(100));
        Assert.Equal(80, ComboSystem.GetGoldBonusPercent(200));
    }

    [Fact]
    public void ApplyDamageBonus_UsesExpectedCalculations()
    {
        Assert.Equal(100, ComboSystem.ApplyDamageBonus(100, 0));
        Assert.Equal(120, ComboSystem.ApplyDamageBonus(100, 10));
        Assert.Equal(200, ComboSystem.ApplyDamageBonus(100, 200));
    }

    [Fact]
    public void ApplyGoldBonus_UsesExpectedCalculations()
    {
        Assert.Equal(100, ComboSystem.ApplyGoldBonus(100, 0));
        Assert.Equal(115, ComboSystem.ApplyGoldBonus(100, 10));
        Assert.Equal(180, ComboSystem.ApplyGoldBonus(100, 200));
    }

    [Fact]
    public void IsTierMilestone_WithinSameTier_ReturnsFalse()
    {
        Assert.False(ComboSystem.IsTierMilestone(3, 4));
    }

    [Fact]
    public void IsTierMilestone_CrossingTierBoundary_ReturnsTrue()
    {
        Assert.True(ComboSystem.IsTierMilestone(4, 5));
    }

    [Fact]
    public void GetTierAnnouncement_DefaultTier_ReturnsEmpty()
    {
        Assert.Equal(string.Empty, ComboSystem.GetTierAnnouncement(0));
    }

    [Fact]
    public void GetTierAnnouncement_NonDefaultTier_ReturnsFormattedText()
    {
        Assert.Equal("Blazing! x10", ComboSystem.GetTierAnnouncement(10));
    }

    [Fact]
    public void FormatComboDisplay_ZeroOrNegativeCombo_ReturnsEmpty()
    {
        Assert.Equal(string.Empty, ComboSystem.FormatComboDisplay(0));
        Assert.Equal(string.Empty, ComboSystem.FormatComboDisplay(-1));
    }

    [Fact]
    public void FormatComboDisplay_PositiveCombo_ReturnsFormattedText()
    {
        Assert.Equal("Warming Up x3", ComboSystem.FormatComboDisplay(3));
    }
}
