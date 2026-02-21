using System.Collections.Generic;
using KeyboardDefense.Core.Progression;

namespace KeyboardDefense.Tests.Core;

public class LoginRewardsCoreTests
{
    [Fact]
    public void RewardsDictionary_HasSevenEntries()
    {
        Assert.Equal(7, LoginRewards.Rewards.Count);
    }

    [Fact]
    public void RewardsDictionary_ContainsExpectedMilestoneDays()
    {
        var expectedDays = new HashSet<int> { 1, 2, 3, 5, 7, 14, 30 };

        Assert.True(expectedDays.SetEquals(LoginRewards.Rewards.Keys));
    }

    [Fact]
    public void GetReward_StreakZero_ReturnsFallbackReward()
    {
        var reward = LoginRewards.GetReward(0);

        AssertReward(reward, "Login Bonus", 5, null);
    }

    [Fact]
    public void GetReward_NegativeStreak_ReturnsFallbackReward()
    {
        var reward = LoginRewards.GetReward(-3);

        AssertReward(reward, "Login Bonus", 5, null);
    }

    [Fact]
    public void GetReward_StreakOne_ReturnsWelcomeBack()
    {
        var reward = LoginRewards.GetReward(1);

        AssertReward(reward, "Welcome Back", 10, null);
    }

    [Fact]
    public void GetReward_StreakTwo_ReturnsReturningHero()
    {
        var reward = LoginRewards.GetReward(2);

        AssertReward(reward, "Returning Hero", 15, "power_boost");
    }

    [Fact]
    public void GetReward_StreakThree_ReturnsDedicated()
    {
        var reward = LoginRewards.GetReward(3);

        AssertReward(reward, "Dedicated", 20, "accuracy_boost");
    }

    [Fact]
    public void GetReward_StreakFour_ReturnsDayThreeReward()
    {
        var reward = LoginRewards.GetReward(4);

        AssertReward(reward, "Dedicated", 20, "accuracy_boost");
    }

    [Fact]
    public void GetReward_StreakSix_ReturnsDayFiveReward()
    {
        var reward = LoginRewards.GetReward(6);

        AssertReward(reward, "Committed", 30, "xp_boost");
    }

    [Fact]
    public void GetReward_StreakSeven_ReturnsWeeklyWarrior()
    {
        var reward = LoginRewards.GetReward(7);

        AssertReward(reward, "Weekly Warrior", 50, "combo_boost");
    }

    [Fact]
    public void GetReward_StreakFourteen_ReturnsFortnightFighter()
    {
        var reward = LoginRewards.GetReward(14);

        AssertReward(reward, "Fortnight Fighter", 75, "gold_rush");
    }

    [Fact]
    public void GetReward_StreakThirtyOrHigher_ReturnsMonthlyMaster()
    {
        var atThirty = LoginRewards.GetReward(30);
        var aboveThirty = LoginRewards.GetReward(45);

        AssertReward(atThirty, "Monthly Master", 100, "mega_boost");
        AssertReward(aboveThirty, "Monthly Master", 100, "mega_boost");
    }

    [Fact]
    public void ClaimReward_GoldMatchesGetRewardForRepresentativeStreaks()
    {
        foreach (var streakDays in new[] { 0, 1, 2, 4, 7, 14, 30, 99 })
        {
            var expected = LoginRewards.GetReward(streakDays);
            var claim = LoginRewards.ClaimReward(streakDays);

            Assert.Equal(expected.GoldReward, Assert.IsType<int>(claim["gold"]));
        }
    }

    [Fact]
    public void ClaimReward_NoBonusReward_UsesEmptyBonusItemString()
    {
        var fallbackClaim = LoginRewards.ClaimReward(0);
        var dayOneClaim = LoginRewards.ClaimReward(1);

        Assert.Equal(string.Empty, Assert.IsType<string>(fallbackClaim["bonus_item"]));
        Assert.Equal(string.Empty, Assert.IsType<string>(dayOneClaim["bonus_item"]));
    }

    [Fact]
    public void ClaimReward_RewardWithBonus_SetsBonusItemValue()
    {
        var claim = LoginRewards.ClaimReward(2);

        Assert.Equal("power_boost", Assert.IsType<string>(claim["bonus_item"]));
    }

    [Fact]
    public void ClaimReward_MessageIncludesRewardNameAndGold()
    {
        var claim = LoginRewards.ClaimReward(1);
        var message = Assert.IsType<string>(claim["message"]);

        Assert.Contains("Welcome Back", message);
        Assert.Contains("+10 gold", message);
    }

    [Fact]
    public void ClaimReward_MessageIncludesBonusWhenPresent()
    {
        var claim = LoginRewards.ClaimReward(7);
        var message = Assert.IsType<string>(claim["message"]);

        Assert.Contains("Weekly Warrior", message);
        Assert.Contains("+50 gold", message);
        Assert.Contains("combo_boost", message);
    }

    [Fact]
    public void ClaimReward_ReturnsGoldBonusItemAndMessageKeys()
    {
        var claim = LoginRewards.ClaimReward(5);

        Assert.True(claim.ContainsKey("gold"));
        Assert.True(claim.ContainsKey("bonus_item"));
        Assert.True(claim.ContainsKey("message"));
        Assert.Equal(3, claim.Count);
    }

    [Fact]
    public void LoginRewardDef_Constructor_SetsAllProperties()
    {
        var def = new LoginRewardDef("Test Reward", 42, "test_item");

        Assert.Equal("Test Reward", def.Name);
        Assert.Equal(42, def.GoldReward);
        Assert.Equal("test_item", def.BonusItem);
    }

    [Fact]
    public void LoginRewardDef_WithSameValues_AreEqual()
    {
        var first = new LoginRewardDef("Echo", 12, null);
        var second = new LoginRewardDef("Echo", 12, null);

        Assert.Equal(first, second);
    }

    private static void AssertReward(LoginRewardDef reward, string name, int gold, string? bonusItem)
    {
        Assert.Equal(name, reward.Name);
        Assert.Equal(gold, reward.GoldReward);
        Assert.Equal(bonusItem, reward.BonusItem);
    }
}
