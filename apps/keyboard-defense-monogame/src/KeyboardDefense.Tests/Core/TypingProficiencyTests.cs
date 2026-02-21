using KeyboardDefense.Core.Typing;
using static KeyboardDefense.Core.Typing.TypingProficiency;

namespace KeyboardDefense.Tests.Core;

public class TypingProficiencyTests
{
    [Theory]
    [InlineData(20, 0.90, ProficiencyTier.Novice)]
    [InlineData(45, 0.80, ProficiencyTier.Adept)]
    [InlineData(65, 0.85, ProficiencyTier.Expert)]
    [InlineData(85, 0.88, ProficiencyTier.Master)]
    [InlineData(90, 0.96, ProficiencyTier.Grandmaster)]
    public void GetTier_ReturnsCorrectTier(double wpm, double accuracy, ProficiencyTier expected)
    {
        var tier = TypingProficiency.GetTier(wpm, accuracy);
        Assert.Equal(expected, tier);
    }

    [Fact]
    public void GetTier_LowAccuracy_CapsAtNovice()
    {
        // Even fast typing with poor accuracy stays Novice
        var tier = TypingProficiency.GetTier(100, 0.50);
        Assert.Equal(ProficiencyTier.Novice, tier);
    }

    [Fact]
    public void GetDamageMultiplier_IncreasesWithTier()
    {
        double novice = GetDamageMultiplier(ProficiencyTier.Novice);
        double adept = GetDamageMultiplier(ProficiencyTier.Adept);
        double expert = GetDamageMultiplier(ProficiencyTier.Expert);
        double master = GetDamageMultiplier(ProficiencyTier.Master);
        double gm = GetDamageMultiplier(ProficiencyTier.Grandmaster);

        Assert.True(novice < adept);
        Assert.True(adept < expert);
        Assert.True(expert < master);
        Assert.True(master < gm);
    }

    [Fact]
    public void GetResourceMultiplier_IncreasesWithTier()
    {
        double novice = GetResourceMultiplier(ProficiencyTier.Novice);
        double gm = GetResourceMultiplier(ProficiencyTier.Grandmaster);

        Assert.True(gm > novice);
        Assert.Equal(1.0, novice);
    }

    [Fact]
    public void GetDiscoveryRadiusBonus_IncreasesWithTier()
    {
        int novice = GetDiscoveryRadiusBonus(ProficiencyTier.Novice);
        int gm = GetDiscoveryRadiusBonus(ProficiencyTier.Grandmaster);

        Assert.Equal(0, novice);
        Assert.True(gm > 0);
    }

    [Fact]
    public void GetGoldMultiplier_IncreasesWithTier()
    {
        double novice = GetGoldMultiplier(ProficiencyTier.Novice);
        double gm = GetGoldMultiplier(ProficiencyTier.Grandmaster);

        Assert.Equal(1.0, novice);
        Assert.True(gm > 1.0);
    }

    [Fact]
    public void GetTierName_ReturnsNonEmpty()
    {
        foreach (ProficiencyTier tier in Enum.GetValues<ProficiencyTier>())
        {
            string name = GetTierName(tier);
            Assert.False(string.IsNullOrEmpty(name));
        }
    }

    [Fact]
    public void GetScore_PerfectTypist_HighScore()
    {
        double score = TypingProficiency.GetScore(100, 1.0);
        Assert.True(score >= 95.0);
    }

    [Fact]
    public void GetScore_ZeroStats_LowScore()
    {
        double score = TypingProficiency.GetScore(0, 0);
        Assert.Equal(0.0, score);
    }

    [Fact]
    public void GetScore_ClampsInputs()
    {
        // Negative values clamp to 0
        double score = TypingProficiency.GetScore(-10, -0.5);
        Assert.True(score >= 0);
    }
}
