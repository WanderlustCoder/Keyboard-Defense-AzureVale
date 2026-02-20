using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class DailyChallengesTests
{
    // ---------- Legacy template tests ----------

    [Fact]
    public void GetChallengeForDay_SameDay_ReturnsSameChallenge()
    {
        string first = DailyChallenges.GetChallengeForDay(5);
        string second = DailyChallenges.GetChallengeForDay(5);
        Assert.Equal(first, second);
    }

    [Fact]
    public void GetChallengeForDay_DifferentDays_ProduceDifferentChallenges()
    {
        // Days 0 and 1 map to different template indices
        string day0 = DailyChallenges.GetChallengeForDay(0);
        string day1 = DailyChallenges.GetChallengeForDay(1);
        Assert.NotEqual(day0, day1);
    }

    [Fact]
    public void GetChallengeForDay_CyclesThroughAllTemplates()
    {
        int templateCount = DailyChallenges.Templates.Count;
        var seen = new HashSet<string>();

        for (int day = 0; day < templateCount; day++)
            seen.Add(DailyChallenges.GetChallengeForDay(day));

        Assert.Equal(templateCount, seen.Count);
    }

    [Fact]
    public void GetChallengeForDay_WrapsAroundAfterAllTemplates()
    {
        int templateCount = DailyChallenges.Templates.Count;
        string day0 = DailyChallenges.GetChallengeForDay(0);
        string wrapped = DailyChallenges.GetChallengeForDay(templateCount);
        Assert.Equal(day0, wrapped);
    }

    [Fact]
    public void Templates_ContainsTwelveEntries()
    {
        Assert.Equal(12, DailyChallenges.Templates.Count);
    }

    [Fact]
    public void Templates_AllHavePositiveTokenReward()
    {
        foreach (var kvp in DailyChallenges.Templates)
        {
            Assert.True(kvp.Value.TokenReward > 0,
                $"Template '{kvp.Key}' should have positive token reward");
        }
    }

    [Fact]
    public void Templates_AllHaveNonEmptyNameAndDescription()
    {
        foreach (var kvp in DailyChallenges.Templates)
        {
            Assert.False(string.IsNullOrWhiteSpace(kvp.Value.Name),
                $"Template '{kvp.Key}' should have a name");
            Assert.False(string.IsNullOrWhiteSpace(kvp.Value.Description),
                $"Template '{kvp.Key}' should have a description");
        }
    }

    [Fact]
    public void Templates_AllHaveCategory()
    {
        foreach (var kvp in DailyChallenges.Templates)
        {
            Assert.False(string.IsNullOrWhiteSpace(kvp.Value.Category),
                $"Template '{kvp.Key}' should have a category");
        }
    }

    [Fact]
    public void GetChallenge_ValidId_ReturnsDef()
    {
        var def = DailyChallenges.GetChallenge("speed_demon");
        Assert.NotNull(def);
        Assert.Equal("Speed Demon", def!.Name);
        Assert.Equal(3, def.TokenReward);
    }

    [Fact]
    public void GetChallenge_InvalidId_ReturnsNull()
    {
        Assert.Null(DailyChallenges.GetChallenge("nonexistent"));
    }

    [Fact]
    public void GetChallengeForDay_ReturnsValidTemplateKey()
    {
        for (int day = 0; day < 30; day++)
        {
            string key = DailyChallenges.GetChallengeForDay(day);
            Assert.True(DailyChallenges.Templates.ContainsKey(key),
                $"Day {day} returned unknown key '{key}'");
        }
    }

    // ---------- Streak bonus tests ----------

    [Fact]
    public void CalculateStreakBonus_ZeroDays_ReturnsZero()
    {
        Assert.Equal(0, DailyChallenges.CalculateStreakBonus(0));
    }

    [Fact]
    public void CalculateStreakBonus_OneDayStreak_ReturnsOne()
    {
        Assert.Equal(1, DailyChallenges.CalculateStreakBonus(1));
    }

    [Fact]
    public void CalculateStreakBonus_ThreeDayStreak_ReturnsTwo()
    {
        Assert.Equal(2, DailyChallenges.CalculateStreakBonus(3));
    }

    [Fact]
    public void CalculateStreakBonus_SevenDayStreak_ReturnsThree()
    {
        Assert.Equal(3, DailyChallenges.CalculateStreakBonus(7));
    }

    [Fact]
    public void CalculateStreakBonus_LargeStreak_CapsAtThree()
    {
        Assert.Equal(3, DailyChallenges.CalculateStreakBonus(100));
    }

    [Fact]
    public void CalculateStreakBonus_TwoDayStreak_ReturnsOne()
    {
        Assert.Equal(1, DailyChallenges.CalculateStreakBonus(2));
    }

    [Fact]
    public void CalculateStreakBonus_SixDayStreak_ReturnsTwo()
    {
        Assert.Equal(2, DailyChallenges.CalculateStreakBonus(6));
    }

    // ---------- New typed challenge pool: deterministic generation ----------

    [Fact]
    public void GetChallengesForDate_SameDate_ReturnsSameChallenges()
    {
        var date = new DateTime(2026, 6, 15);
        var first = DailyChallenges.GetChallengesForDate(date, 1);
        var second = DailyChallenges.GetChallengesForDate(date, 1);

        Assert.Equal(first.Count, second.Count);
        for (int i = 0; i < first.Count; i++)
            Assert.Equal(first[i].Id, second[i].Id);
    }

    [Fact]
    public void GetChallengesForDate_DifferentDates_ProduceDifferentChallenges()
    {
        var day1 = DailyChallenges.GetChallengesForDate(new DateTime(2026, 1, 1), 1);
        var day2 = DailyChallenges.GetChallengesForDate(new DateTime(2026, 1, 2), 1);

        // At least one challenge ID should differ between days
        var ids1 = day1.Select(c => c.Id).ToHashSet();
        var ids2 = day2.Select(c => c.Id).ToHashSet();
        Assert.False(ids1.SetEquals(ids2), "Different days should produce different challenge sets");
    }

    [Fact]
    public void GetChallengesForDate_ReturnsThreeChallenges()
    {
        var challenges = DailyChallenges.GetChallengesForDate(new DateTime(2026, 3, 10), 1);
        Assert.Equal(3, challenges.Count);
    }

    [Fact]
    public void GetChallengesForDate_AllHaveValidIds()
    {
        var challenges = DailyChallenges.GetChallengesForDate(new DateTime(2026, 7, 4), 5);
        foreach (var c in challenges)
        {
            Assert.False(string.IsNullOrWhiteSpace(c.Id));
            Assert.False(string.IsNullOrWhiteSpace(c.Name));
        }
    }

    [Fact]
    public void GetChallengesForDate_AllHavePositiveRewards()
    {
        var challenges = DailyChallenges.GetChallengesForDate(new DateTime(2026, 5, 20), 10);
        foreach (var c in challenges)
            Assert.True(c.Reward > 0, $"Challenge '{c.Id}' should have positive reward");
    }

    // ---------- Progress tracking ----------

    [Fact]
    public void GetProgress_DefeatEnemies_TracksEnemiesDefeated()
    {
        var state = new GameState();
        state.EnemiesDefeated = 7;

        var challenge = new ChallengeDef("test_defeat", "Test", "Defeat enemies",
            ChallengeType.DefeatEnemies, 10, 15);

        var (current, target) = DailyChallenges.GetProgress(state, challenge);
        Assert.Equal(7, current);
        Assert.Equal(10, target);
    }

    [Fact]
    public void GetProgress_DefeatEnemies_CapsAtTarget()
    {
        var state = new GameState();
        state.EnemiesDefeated = 50;

        var challenge = new ChallengeDef("test_defeat", "Test", "Defeat enemies",
            ChallengeType.DefeatEnemies, 10, 15);

        var (current, target) = DailyChallenges.GetProgress(state, challenge);
        Assert.Equal(10, current); // capped at target
        Assert.Equal(10, target);
    }

    [Fact]
    public void GetProgress_TypeWords_TracksWordsTyped()
    {
        var state = new GameState();
        state.TypingMetrics["battle_words_typed"] = 35;

        var challenge = new ChallengeDef("test_type", "Test", "Type words",
            ChallengeType.TypeWords, 50, 25);

        var (current, target) = DailyChallenges.GetProgress(state, challenge);
        Assert.Equal(35, current);
        Assert.Equal(50, target);
    }

    [Fact]
    public void GetProgress_ComboStreak_TracksMaxCombo()
    {
        var state = new GameState();
        state.MaxComboEver = 12;

        var challenge = new ChallengeDef("test_combo", "Test", "Combo streak",
            ChallengeType.ComboStreak, 10, 30);

        var (current, _) = DailyChallenges.GetProgress(state, challenge);
        Assert.Equal(10, current); // capped at target
    }

    [Fact]
    public void GetProgress_SurviveDays_TracksDay()
    {
        var state = new GameState(); // Day defaults to 1
        state.Day = 4;

        var challenge = new ChallengeDef("test_survive", "Test", "Survive days",
            ChallengeType.SurviveDays, 5, 20);

        var (current, target) = DailyChallenges.GetProgress(state, challenge);
        Assert.Equal(4, current);
        Assert.Equal(5, target);
    }

    [Fact]
    public void GetProgress_PerfectAccuracy_TracksPerfectNights()
    {
        var state = new GameState();
        state.PerfectNightsToday = 1;

        var challenge = new ChallengeDef("test_perfect", "Test", "Perfect accuracy",
            ChallengeType.PerfectAccuracy, 2, 75);

        var (current, target) = DailyChallenges.GetProgress(state, challenge);
        Assert.Equal(1, current);
        Assert.Equal(2, target);
    }

    [Fact]
    public void GetProgress_NoDamage_TracksNoDamageNights()
    {
        var state = new GameState();
        state.NoDamageNightsToday = 2;

        var challenge = new ChallengeDef("test_nodmg", "Test", "No damage",
            ChallengeType.NoDamage, 2, 65);

        var (current, target) = DailyChallenges.GetProgress(state, challenge);
        Assert.Equal(2, current);
        Assert.Equal(2, target);
    }

    // ---------- Challenge completion ----------

    [Fact]
    public void CompleteChallenge_AwardsGold()
    {
        var state = new GameState();
        state.Day = 1;
        var today = DailyChallenges.GetTodaysChallenges(state.Day);
        var challenge = today[0];

        int goldBefore = state.Gold;
        var result = DailyChallenges.CompleteChallenge(state, challenge.Id);

        Assert.True((bool)result["ok"]);
        Assert.Equal(goldBefore + challenge.Reward, state.Gold);
        Assert.Contains(challenge.Id, state.CompletedDailyChallenges);
    }

    [Fact]
    public void CompleteChallenge_AlreadyCompleted_ReturnsFalse()
    {
        var state = new GameState();
        state.Day = 1;
        var today = DailyChallenges.GetTodaysChallenges(state.Day);
        var challenge = today[0];

        DailyChallenges.CompleteChallenge(state, challenge.Id);
        var result = DailyChallenges.CompleteChallenge(state, challenge.Id);

        Assert.False((bool)result["ok"]);
    }

    [Fact]
    public void CompleteChallenge_UnavailableChallenge_ReturnsFalse()
    {
        var state = new GameState();
        var result = DailyChallenges.CompleteChallenge(state, "completely_fake_id");
        Assert.False((bool)result["ok"]);
    }

    // ---------- ChallengePool coverage ----------

    [Fact]
    public void ChallengePool_HasExpectedEntries()
    {
        Assert.Equal(20, DailyChallenges.ChallengePool.Length);
    }

    [Fact]
    public void ChallengePool_AllIdsAreUnique()
    {
        var ids = DailyChallenges.ChallengePool.Select(c => c.Id).ToList();
        Assert.Equal(ids.Count, ids.Distinct().Count());
    }

    [Fact]
    public void ChallengePool_AllHavePositiveTargets()
    {
        foreach (var c in DailyChallenges.ChallengePool)
            Assert.True(c.Target > 0, $"Challenge '{c.Id}' should have a positive target");
    }
}
