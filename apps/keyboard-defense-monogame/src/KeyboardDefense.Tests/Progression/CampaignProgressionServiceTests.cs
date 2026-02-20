using System;
using System.IO;
using KeyboardDefense.Game.Services;

namespace KeyboardDefense.Tests.Progression;

public class CampaignProgressionServiceTests
{
    [Fact]
    public void ApplySingleWaveOutcome_Victory_CompletesNodeAndAwardsGoldOnce()
    {
        using var appDataScope = new TempAppDataScope();
        var progression = new ProgressionState();

        CampaignProgressionService.ApplySingleWaveOutcome(
            progression,
            returnToCampaignMapOnSummary: true,
            isVictory: true,
            campaignNodeId: "forest_gate",
            campaignNodeRewardGold: 25,
            day: 3,
            enemiesDefeated: 12,
            wordsTyped: 30,
            wordsPerMinute: 42.5,
            accuracyRate: 0.91);

        CampaignProgressionService.ApplySingleWaveOutcome(
            progression,
            returnToCampaignMapOnSummary: true,
            isVictory: true,
            campaignNodeId: "forest_gate",
            campaignNodeRewardGold: 25,
            day: 4,
            enemiesDefeated: 16,
            wordsTyped: 34,
            wordsPerMinute: 44.0,
            accuracyRate: 0.93);

        Assert.True(progression.IsNodeCompleted("forest_gate"));
        Assert.Equal(25, progression.Gold);
        Assert.Equal(2, progression.TotalGamesPlayed);
        Assert.Equal(2, progression.TotalVictories);
    }

    [Fact]
    public void ApplySingleWaveOutcome_Defeat_RecordsRunWithoutNodeCompletion()
    {
        using var appDataScope = new TempAppDataScope();
        var progression = new ProgressionState();

        CampaignProgressionService.ApplySingleWaveOutcome(
            progression,
            returnToCampaignMapOnSummary: true,
            isVictory: false,
            campaignNodeId: "whisper_grove",
            campaignNodeRewardGold: 30,
            day: 2,
            enemiesDefeated: 5,
            wordsTyped: 14,
            wordsPerMinute: 28.0,
            accuracyRate: 0.82);

        Assert.False(progression.IsNodeCompleted("whisper_grove"));
        Assert.Equal(0, progression.Gold);
        Assert.Equal(1, progression.TotalGamesPlayed);
        Assert.Equal(0, progression.TotalVictories);
    }

    [Fact]
    public void ApplySingleWaveOutcome_NonCampaignSummary_DoesNothing()
    {
        using var appDataScope = new TempAppDataScope();
        var progression = new ProgressionState();

        CampaignProgressionService.ApplySingleWaveOutcome(
            progression,
            returnToCampaignMapOnSummary: false,
            isVictory: true,
            campaignNodeId: "ember_bridge",
            campaignNodeRewardGold: 20,
            day: 1,
            enemiesDefeated: 8,
            wordsTyped: 20,
            wordsPerMinute: 35.0,
            accuracyRate: 0.88);

        Assert.False(progression.IsNodeCompleted("ember_bridge"));
        Assert.Equal(0, progression.Gold);
        Assert.Equal(0, progression.TotalGamesPlayed);
        Assert.Equal(0, progression.TotalVictories);
    }

    private sealed class TempAppDataScope : IDisposable
    {
        private readonly string? _originalAppData;
        private readonly string _tempAppDataPath;

        public TempAppDataScope()
        {
            _originalAppData = Environment.GetEnvironmentVariable("APPDATA");
            _tempAppDataPath = Path.Combine(
                Path.GetTempPath(),
                "KeyboardDefenseTests",
                Guid.NewGuid().ToString("N"));

            Directory.CreateDirectory(_tempAppDataPath);
            Environment.SetEnvironmentVariable("APPDATA", _tempAppDataPath);
        }

        public void Dispose()
        {
            Environment.SetEnvironmentVariable("APPDATA", _originalAppData);

            try
            {
                if (Directory.Exists(_tempAppDataPath))
                    Directory.Delete(_tempAppDataPath, recursive: true);
            }
            catch
            {
                // Cleanup best-effort only.
            }
        }
    }
}
