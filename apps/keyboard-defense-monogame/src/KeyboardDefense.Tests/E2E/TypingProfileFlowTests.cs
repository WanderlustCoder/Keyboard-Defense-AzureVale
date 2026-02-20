using KeyboardDefense.Core.Typing;

namespace KeyboardDefense.Tests.E2E;

/// <summary>
/// End-to-end tests for typing profile: recording, weak keys, adaptive difficulty.
/// </summary>
public class TypingProfileFlowTests
{
    [Fact]
    public void RecordCorrectChars_UpdatesStats()
    {
        var profile = new TypingProfile();
        profile.RecordCorrectChar('a');
        profile.RecordCorrectChar('b');
        profile.RecordCorrectChar('c');

        Assert.Equal(3, profile.TotalCharsTyped);
        Assert.True(profile.KeyStats.ContainsKey('a'));
        Assert.Equal(1, profile.KeyStats['a'].Correct);
    }

    [Fact]
    public void RecordErrors_TracksPerKey()
    {
        var profile = new TypingProfile();

        // Type 'a' correctly 8 times, error 2 times
        for (int i = 0; i < 8; i++) profile.RecordCorrectChar('a');
        profile.RecordError('a', 's');
        profile.RecordError('a', 'd');

        // RecordError increments TotalErrors and KeyStats[].Total but NOT TotalCharsTyped
        Assert.Equal(8, profile.TotalCharsTyped);
        Assert.Equal(2, profile.TotalErrors);
        Assert.Equal(8, profile.KeyStats['a'].Correct);
        Assert.Equal(10, profile.KeyStats['a'].Total);
    }

    [Fact]
    public void WeakKeys_IdentifiedByLowAccuracy()
    {
        var profile = new TypingProfile();

        // 'q' has poor accuracy (3/12 = 25%)
        for (int i = 0; i < 3; i++) profile.RecordCorrectChar('q');
        for (int i = 0; i < 9; i++) profile.RecordError('q', 'w');

        // 'a' has good accuracy (11/12 = 92%)
        for (int i = 0; i < 11; i++) profile.RecordCorrectChar('a');
        profile.RecordError('a', 's');

        var weakKeys = profile.GetWeakKeys();
        Assert.Contains('q', weakKeys);
        Assert.DoesNotContain('a', weakKeys);
    }

    [Fact]
    public void StrongKeys_IdentifiedByHighAccuracy()
    {
        var profile = new TypingProfile();

        // Perfect accuracy on 'a' with enough samples
        for (int i = 0; i < 15; i++) profile.RecordCorrectChar('a');

        var strongKeys = profile.GetStrongKeys();
        Assert.Contains('a', strongKeys);
    }

    [Fact]
    public void SessionSummary_RecordedAndCapped()
    {
        var profile = new TypingProfile();

        // Record many sessions
        for (int i = 0; i < 25; i++)
        {
            profile.RecordSession(
                wpm: 40 + i,
                accuracy: 0.85 + i * 0.005,
                wordsTyped: 20,
                errors: 1,
                durationSec: 60.0);
        }

        Assert.True(profile.Sessions.Count <= TypingProfile.MaxSessionHistory,
            "Sessions should be capped");
    }

    [Fact]
    public void AverageWpm_CalculatedFromSessions()
    {
        var profile = new TypingProfile();
        profile.RecordSession(wpm: 40, accuracy: 0.9, wordsTyped: 10, errors: 1, durationSec: 60.0);
        profile.RecordSession(wpm: 60, accuracy: 0.95, wordsTyped: 15, errors: 1, durationSec: 60.0);

        double avg = profile.GetAverageWpm();
        Assert.True(avg >= 40 && avg <= 60,
            $"Average WPM should be between 40-60, got {avg}");
    }

    [Fact]
    public void ComboSystem_TierProgression()
    {
        // No combo
        Assert.Equal(0, ComboSystem.GetTierIndex(0));

        // Warming Up (3+)
        Assert.True(ComboSystem.GetTierIndex(3) >= 1);

        // On Fire (5+)
        Assert.True(ComboSystem.GetTierIndex(5) >= 2);

        // Blazing (10+)
        Assert.True(ComboSystem.GetTierIndex(10) >= 3);
    }

    [Fact]
    public void ComboSystem_DamageBonusIncreases()
    {
        int bonus0 = ComboSystem.GetDamageBonusPercent(0);
        int bonus5 = ComboSystem.GetDamageBonusPercent(5);
        int bonus20 = ComboSystem.GetDamageBonusPercent(20);

        Assert.True(bonus5 > bonus0, "Combo 5 should have higher damage bonus than 0");
        Assert.True(bonus20 > bonus5, "Combo 20 should have higher damage bonus than 5");
    }

    [Fact]
    public void ComboSystem_ApplyDamageBonus()
    {
        int base5 = ComboSystem.ApplyDamageBonus(10, 5);
        int base0 = ComboSystem.ApplyDamageBonus(10, 0);

        Assert.True(base5 > base0, "Combo should increase damage");
    }

    [Fact]
    public void ComboSystem_GoldBonusIncreases()
    {
        int gold0 = ComboSystem.ApplyGoldBonus(10, 0);
        int gold10 = ComboSystem.ApplyGoldBonus(10, 10);

        Assert.True(gold10 >= gold0, "Combo should not decrease gold");
    }

    [Fact]
    public void ComboSystem_TierMilestoneDetected()
    {
        Assert.True(ComboSystem.IsTierMilestone(2, 3), "Crossing from 2 to 3 should be milestone");
        Assert.False(ComboSystem.IsTierMilestone(1, 2), "1 to 2 is same tier");
    }

    [Fact]
    public void BattleTyping_TracksMetricsThroughCampaign()
    {
        var sim = new GameSimulator("typing_track");
        sim.RunCampaign(2);

        // After 2 days of combat, events should have been generated
        Assert.True(sim.AllEvents.Count > 0, "Campaign should generate events");
        Assert.True(sim.TotalSteps > 0, "Campaign should take steps");
    }
}
