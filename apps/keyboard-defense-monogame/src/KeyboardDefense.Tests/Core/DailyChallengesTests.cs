using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class DailyChallengesCoreTests
{
    [Fact]
    public void Templates_HasTwelveEntries()
    {
        Assert.Equal(12, DailyChallenges.Templates.Count);
    }

    [Fact]
    public void ChallengePool_HasTwentyEntries()
    {
        Assert.Equal(20, DailyChallenges.ChallengePool.Length);
    }

    [Fact]
    public void GetChallengeForDay_WrapsAroundTemplateCount()
    {
        int templateCount = DailyChallenges.Templates.Count;

        string dayTwo = DailyChallenges.GetChallengeForDay(2);
        string wrapped = DailyChallenges.GetChallengeForDay(2 + templateCount);

        Assert.Equal(dayTwo, wrapped);
    }

    [Fact]
    public void GetChallenge_KnownId_ReturnsDefinition()
    {
        var def = Assert.IsType<DailyChallengeDef>(DailyChallenges.GetChallenge("speed_demon"));

        Assert.Equal("Speed Demon", def.Name);
        Assert.Equal("typing", def.Category);
    }

    [Fact]
    public void GetChallenge_UnknownId_ReturnsNull()
    {
        Assert.Null(DailyChallenges.GetChallenge("missing_id"));
    }

    [Fact]
    public void CalculateStreakBonus_ZeroDays_ReturnsZero()
    {
        Assert.Equal(0, DailyChallenges.CalculateStreakBonus(0));
    }

    [Fact]
    public void CalculateStreakBonus_OneDay_ReturnsOne()
    {
        Assert.Equal(1, DailyChallenges.CalculateStreakBonus(1));
    }

    [Fact]
    public void CalculateStreakBonus_ThreeDays_ReturnsTwo()
    {
        Assert.Equal(2, DailyChallenges.CalculateStreakBonus(3));
    }

    [Fact]
    public void CalculateStreakBonus_SevenDays_ReturnsThree()
    {
        Assert.Equal(3, DailyChallenges.CalculateStreakBonus(7));
    }

    [Fact]
    public void GetChallengesForDate_ReturnsExactlyThreeChallenges()
    {
        var challenges = DailyChallenges.GetChallengesForDate(new DateTime(2026, 6, 12, 0, 0, 0, DateTimeKind.Utc), highestDayReached: 8);

        Assert.Equal(3, challenges.Count);
    }

    [Fact]
    public void GetChallengesForDate_SameDateAndTier_IsDeterministic()
    {
        var date = new DateTime(2026, 6, 12, 0, 0, 0, DateTimeKind.Utc);

        var first = DailyChallenges.GetChallengesForDate(date, highestDayReached: 8);
        var second = DailyChallenges.GetChallengesForDate(date, highestDayReached: 8);

        Assert.Equal(first.Select(c => c.Id), second.Select(c => c.Id));
        Assert.Equal(first.Select(c => c.Reward), second.Select(c => c.Reward));
    }

    [Fact]
    public void GetChallengesForDate_PrefersDistinctTypes()
    {
        var challenges = DailyChallenges.GetChallengesForDate(new DateTime(2026, 7, 20, 0, 0, 0, DateTimeKind.Utc), highestDayReached: 15);

        Assert.Equal(3, challenges.Count);
        Assert.Equal(3, challenges.Select(c => c.Type).Distinct().Count());
    }

    [Fact]
    public void GetChallengesForDate_ScalesRewardsWithTier()
    {
        var date = new DateTime(2026, 8, 21, 0, 0, 0, DateTimeKind.Utc);

        var earlyTier = DailyChallenges.GetChallengesForDate(date, highestDayReached: 1);
        var endgameTier = DailyChallenges.GetChallengesForDate(date, highestDayReached: 20);

        foreach (var challenge in earlyTier)
        {
            int baseReward = DailyChallenges.ChallengePool.Single(c => c.Id == challenge.Id).Reward;
            Assert.Equal(baseReward, challenge.Reward);
        }

        foreach (var challenge in endgameTier)
        {
            int baseReward = DailyChallenges.ChallengePool.Single(c => c.Id == challenge.Id).Reward;
            Assert.Equal((int)(baseReward * 1.75f), challenge.Reward);
        }
    }

    [Fact]
    public void FilterByTier_TierZero_OnlyIncludesRewardsUpToThirty()
    {
        var filtered = InvokeFilterByTier(0);

        Assert.NotEmpty(filtered);
        Assert.All(filtered, c => Assert.True(c.Reward <= 30, $"Challenge '{c.Id}' exceeded tier-0 cap."));
    }

    [Fact]
    public void FilterByTier_TierOne_OnlyIncludesRewardsUpToFifty()
    {
        var filtered = InvokeFilterByTier(1);

        Assert.NotEmpty(filtered);
        Assert.All(filtered, c => Assert.True(c.Reward <= 50, $"Challenge '{c.Id}' exceeded tier-1 cap."));
    }

    [Fact]
    public void FilterByTier_TierTwo_OnlyIncludesRewardsUpToSeventy()
    {
        var filtered = InvokeFilterByTier(2);

        Assert.NotEmpty(filtered);
        Assert.All(filtered, c => Assert.True(c.Reward <= 70, $"Challenge '{c.Id}' exceeded tier-2 cap."));
    }

    [Fact]
    public void FilterByTier_TierThree_IncludesEntirePool()
    {
        var filtered = InvokeFilterByTier(3);

        Assert.Equal(DailyChallenges.ChallengePool.Length, filtered.Count);
    }

    [Fact]
    public void GetProgress_DefeatEnemies_UsesEnemiesDefeated()
    {
        var state = CreateState();
        state.EnemiesDefeated = 17;

        var challenge = new ChallengeDef("test_defeat", "Test", "Test", ChallengeType.DefeatEnemies, 30, 20);

        var (current, target) = DailyChallenges.GetProgress(state, challenge);

        Assert.Equal(17, current);
        Assert.Equal(30, target);
    }

    [Fact]
    public void GetProgress_ComboStreak_UsesMaxComboEver()
    {
        var state = CreateState();
        state.MaxComboEver = 14;

        var challenge = new ChallengeDef("test_combo", "Test", "Test", ChallengeType.ComboStreak, 20, 20);

        var (current, target) = DailyChallenges.GetProgress(state, challenge);

        Assert.Equal(14, current);
        Assert.Equal(20, target);
    }

    [Fact]
    public void GetProgress_SurviveDays_UsesCurrentDay()
    {
        var state = CreateState();
        state.Day = 6;

        var challenge = new ChallengeDef("test_survive", "Test", "Test", ChallengeType.SurviveDays, 10, 20);

        var (current, target) = DailyChallenges.GetProgress(state, challenge);

        Assert.Equal(6, current);
        Assert.Equal(10, target);
    }

    [Fact]
    public void CompleteChallenge_AvailableChallenge_AwardsGoldAndMarksCompleted()
    {
        var state = CreateState();
        state.Day = 12;

        var challenge = DailyChallenges.GetTodaysChallenges(state.Day)[0];
        int goldBefore = state.Gold;

        var result = DailyChallenges.CompleteChallenge(state, challenge.Id);

        Assert.True((bool)result["ok"]);
        Assert.Equal(goldBefore + challenge.Reward, state.Gold);
        Assert.Contains(challenge.Id, state.CompletedDailyChallenges);
    }

    [Fact]
    public void CompleteChallenge_AlreadyCompleted_ReturnsError()
    {
        var state = CreateState();
        state.Day = 12;

        var challenge = DailyChallenges.GetTodaysChallenges(state.Day)[0];

        DailyChallenges.CompleteChallenge(state, challenge.Id);
        int goldAfterFirstCompletion = state.Gold;

        var secondResult = DailyChallenges.CompleteChallenge(state, challenge.Id);

        Assert.False((bool)secondResult["ok"]);
        Assert.Equal("Already completed.", secondResult["error"]);
        Assert.Equal(goldAfterFirstCompletion, state.Gold);
    }

    [Fact]
    public void CompleteChallenge_ChallengeNotAvailableToday_ReturnsError()
    {
        var state = CreateState();
        state.Day = 12;

        var todayIds = DailyChallenges.GetTodaysChallenges(state.Day).Select(c => c.Id).ToHashSet();
        string unavailableId = DailyChallenges.ChallengePool.Select(c => c.Id).First(id => !todayIds.Contains(id));

        var result = DailyChallenges.CompleteChallenge(state, unavailableId);

        Assert.False((bool)result["ok"]);
        Assert.Equal("Challenge not available today.", result["error"]);
        Assert.DoesNotContain(unavailableId, state.CompletedDailyChallenges);
    }

    private static List<ChallengeDef> InvokeFilterByTier(int tier)
    {
        var method = typeof(DailyChallenges).GetMethod("FilterByTier", BindingFlags.NonPublic | BindingFlags.Static);
        Assert.NotNull(method);

        var result = method!.Invoke(null, new object[] { tier });
        return Assert.IsType<List<ChallengeDef>>(result);
    }

    private static GameState CreateState()
    {
        var state = DefaultState.Create(Guid.NewGuid().ToString("N"));
        state.CompletedDailyChallenges.Clear();
        state.TypingMetrics["battle_words_typed"] = 0;
        return state;
    }
}
