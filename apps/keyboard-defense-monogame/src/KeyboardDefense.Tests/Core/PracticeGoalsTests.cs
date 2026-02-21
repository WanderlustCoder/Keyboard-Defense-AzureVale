using KeyboardDefense.Core.Typing;

namespace KeyboardDefense.Tests.Core;

public class PracticeGoalsCoreTests
{
    [Fact]
    public void Goals_HasFourEntries()
    {
        Assert.Equal(4, PracticeGoals.Goals.Count);
    }

    [Fact]
    public void Goals_ContainsExpectedGoalKeys()
    {
        Assert.Contains("balanced", PracticeGoals.Goals.Keys);
        Assert.Contains("accuracy", PracticeGoals.Goals.Keys);
        Assert.Contains("backspace", PracticeGoals.Goals.Keys);
        Assert.Contains("speed", PracticeGoals.Goals.Keys);
    }

    [Fact]
    public void NormalizeGoal_Balanced_ReturnsBalanced()
    {
        Assert.Equal("balanced", PracticeGoals.NormalizeGoal("balanced"));
    }

    [Fact]
    public void NormalizeGoal_Accuracy_ReturnsAccuracy()
    {
        Assert.Equal("accuracy", PracticeGoals.NormalizeGoal("accuracy"));
    }

    [Fact]
    public void NormalizeGoal_Backspace_ReturnsBackspace()
    {
        Assert.Equal("backspace", PracticeGoals.NormalizeGoal("backspace"));
    }

    [Fact]
    public void NormalizeGoal_Speed_ReturnsSpeed()
    {
        Assert.Equal("speed", PracticeGoals.NormalizeGoal("speed"));
    }

    [Fact]
    public void NormalizeGoal_TrimsWhitespaceAndLowercases()
    {
        Assert.Equal("backspace", PracticeGoals.NormalizeGoal("  BACKSPACE  "));
    }

    [Fact]
    public void NormalizeGoal_Null_ReturnsBalanced()
    {
        Assert.Equal("balanced", PracticeGoals.NormalizeGoal(null!));
    }

    [Fact]
    public void NormalizeGoal_UnknownGoal_ReturnsBalanced()
    {
        Assert.Equal("balanced", PracticeGoals.NormalizeGoal("unknown-goal"));
    }

    [Fact]
    public void Thresholds_Balanced_ReturnExpectedValues()
    {
        var thresholds = PracticeGoals.Thresholds("balanced");
        AssertThresholds(thresholds, 0.55, 0.78, 0.20, 0.30);
    }

    [Fact]
    public void Thresholds_Accuracy_ReturnExpectedValues()
    {
        var thresholds = PracticeGoals.Thresholds("accuracy");
        AssertThresholds(thresholds, 0.45, 0.85, 0.25, 0.35);
    }

    [Fact]
    public void Thresholds_Backspace_ReturnExpectedValues()
    {
        var thresholds = PracticeGoals.Thresholds("backspace");
        AssertThresholds(thresholds, 0.50, 0.75, 0.12, 0.30);
    }

    [Fact]
    public void Thresholds_Speed_ReturnExpectedValues()
    {
        var thresholds = PracticeGoals.Thresholds("speed");
        AssertThresholds(thresholds, 0.70, 0.75, 0.25, 0.25);
    }

    [Fact]
    public void GoalLabel_KnownGoals_ReturnExpectedLabels()
    {
        Assert.Equal("Balanced", PracticeGoals.GoalLabel("balanced"));
        Assert.Equal("Accuracy Focus", PracticeGoals.GoalLabel("accuracy"));
        Assert.Equal("Clean Keystrokes", PracticeGoals.GoalLabel("backspace"));
        Assert.Equal("Speed Focus", PracticeGoals.GoalLabel("speed"));
    }

    [Fact]
    public void GoalLabel_UnknownGoal_ReturnsBalanced()
    {
        Assert.Equal("Balanced", PracticeGoals.GoalLabel("unknown-goal"));
    }

    [Fact]
    public void GoalDescription_KnownGoals_ReturnExpectedDescriptions()
    {
        Assert.Equal("A well-rounded target for all typing metrics.", PracticeGoals.GoalDescription("balanced"));
        Assert.Equal("Prioritize accuracy over speed.", PracticeGoals.GoalDescription("accuracy"));
        Assert.Equal("Minimize use of backspace key.", PracticeGoals.GoalDescription("backspace"));
        Assert.Equal("Prioritize speed and throughput.", PracticeGoals.GoalDescription("speed"));
    }

    [Fact]
    public void GoalDescription_UnknownGoal_ReturnsEmptyString()
    {
        Assert.Equal(string.Empty, PracticeGoals.GoalDescription("unknown-goal"));
    }

    [Fact]
    public void GoalThresholds_Struct_ExposesConfiguredProperties()
    {
        var thresholds = new GoalThresholds(0.61, 0.83, 0.14, 0.27);

        Assert.Equal(0.61, thresholds.MinHitRate, 10);
        Assert.Equal(0.83, thresholds.MinAccuracy, 10);
        Assert.Equal(0.14, thresholds.MaxBackspaceRate, 10);
        Assert.Equal(0.27, thresholds.MaxIncompleteRate, 10);
    }

    private static void AssertThresholds(
        GoalThresholds thresholds,
        double minHitRate,
        double minAccuracy,
        double maxBackspaceRate,
        double maxIncompleteRate)
    {
        Assert.Equal(minHitRate, thresholds.MinHitRate, 10);
        Assert.Equal(minAccuracy, thresholds.MinAccuracy, 10);
        Assert.Equal(maxBackspaceRate, thresholds.MaxBackspaceRate, 10);
        Assert.Equal(maxIncompleteRate, thresholds.MaxIncompleteRate, 10);
    }
}
