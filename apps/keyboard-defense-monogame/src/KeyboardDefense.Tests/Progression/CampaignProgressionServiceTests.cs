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

        var firstOutcome = CampaignProgressionService.ApplySingleWaveOutcome(
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

        var secondOutcome = CampaignProgressionService.ApplySingleWaveOutcome(
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

        Assert.True(firstOutcome.IsCampaignRun);
        Assert.True(firstOutcome.IsVictory);
        Assert.False(firstOutcome.NodeAlreadyCompleted);
        Assert.True(firstOutcome.NodeCompletedThisRun);
        Assert.True(firstOutcome.RewardAwarded);
        Assert.Equal(25, firstOutcome.RewardGold);

        Assert.True(secondOutcome.IsCampaignRun);
        Assert.True(secondOutcome.IsVictory);
        Assert.True(secondOutcome.NodeAlreadyCompleted);
        Assert.False(secondOutcome.NodeCompletedThisRun);
        Assert.False(secondOutcome.RewardAwarded);
        Assert.Equal(25, secondOutcome.RewardGold);

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

        var outcome = CampaignProgressionService.ApplySingleWaveOutcome(
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

        Assert.True(outcome.IsCampaignRun);
        Assert.False(outcome.IsVictory);
        Assert.False(outcome.NodeAlreadyCompleted);
        Assert.False(outcome.NodeCompletedThisRun);
        Assert.False(outcome.RewardAwarded);
        Assert.Equal(30, outcome.RewardGold);

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

        var outcome = CampaignProgressionService.ApplySingleWaveOutcome(
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

        Assert.Equal(CampaignProgressionService.CampaignOutcome.None, outcome);

        Assert.False(progression.IsNodeCompleted("ember_bridge"));
        Assert.Equal(0, progression.Gold);
        Assert.Equal(0, progression.TotalGamesPlayed);
        Assert.Equal(0, progression.TotalVictories);
    }

    [Fact]
    public void BuildSummaryDisplay_UsesRewardMessage_OnFirstVictoryClear()
    {
        var outcome = new CampaignProgressionService.CampaignOutcome(
            IsCampaignRun: true,
            IsVictory: true,
            NodeAlreadyCompleted: false,
            NodeCompletedThisRun: true,
            RewardAwarded: true,
            RewardGold: 35);

        var display = CampaignProgressionService.BuildSummaryDisplay(outcome);

        Assert.Equal("Node cleared: +35 gold awarded.", display.Text);
        Assert.Equal(CampaignProgressionService.CampaignOutcomeTone.Reward, display.Tone);
    }

    [Fact]
    public void BuildSummaryDisplay_UsesAlreadyClearedMessage_OnRepeatVictory()
    {
        var outcome = new CampaignProgressionService.CampaignOutcome(
            IsCampaignRun: true,
            IsVictory: true,
            NodeAlreadyCompleted: true,
            NodeCompletedThisRun: false,
            RewardAwarded: false,
            RewardGold: 35);

        var display = CampaignProgressionService.BuildSummaryDisplay(outcome);

        Assert.Equal("Node already cleared. No additional node reward.", display.Text);
        Assert.Equal(CampaignProgressionService.CampaignOutcomeTone.Neutral, display.Tone);
    }

    [Fact]
    public void BuildSummaryDisplay_UsesDefeatRewardPrompt_WhenRewardExists()
    {
        var outcome = new CampaignProgressionService.CampaignOutcome(
            IsCampaignRun: true,
            IsVictory: false,
            NodeAlreadyCompleted: false,
            NodeCompletedThisRun: false,
            RewardAwarded: false,
            RewardGold: 18);

        var display = CampaignProgressionService.BuildSummaryDisplay(outcome);

        Assert.Equal("Node not cleared. Win to earn +18 gold.", display.Text);
        Assert.Equal(CampaignProgressionService.CampaignOutcomeTone.Warning, display.Tone);
    }

    [Fact]
    public void BuildSummaryDisplay_UsesEmptyNeutral_WhenNotCampaignRun()
    {
        var display = CampaignProgressionService.BuildSummaryDisplay(
            CampaignProgressionService.CampaignOutcome.None);

        Assert.Equal(string.Empty, display.Text);
        Assert.Equal(CampaignProgressionService.CampaignOutcomeTone.Neutral, display.Tone);
    }

    [Fact]
    public void ApplySingleWaveOutcome_UsingBattleToSummaryHandoff_Victory_CompletesNodeAndRewards()
    {
        using var appDataScope = new TempAppDataScope();
        var progression = new ProgressionState();
        var handoff = CampaignProgressionService.CampaignSummaryHandoff.Create(
            returnToCampaignMapOnSummary: true,
            campaignNodeId: "the-nexus",
            campaignNodeRewardGold: 40);

        var outcome = CampaignProgressionService.ApplySingleWaveOutcome(
            progression,
            handoff,
            isVictory: true,
            day: 5,
            enemiesDefeated: 21,
            wordsTyped: 42,
            wordsPerMinute: 51.3,
            accuracyRate: 0.96);
        var display = CampaignProgressionService.BuildSummaryDisplay(outcome);

        Assert.True(outcome.NodeCompletedThisRun);
        Assert.True(outcome.RewardAwarded);
        Assert.Equal(40, progression.Gold);
        Assert.True(progression.IsNodeCompleted("the-nexus"));
        Assert.Equal("Node cleared: +40 gold awarded.", display.Text);
        Assert.Equal(CampaignProgressionService.CampaignOutcomeTone.Reward, display.Tone);
    }

    [Fact]
    public void ApplySingleWaveOutcome_UsingBattleToSummaryHandoff_Defeat_ShowsRetryPromptWithoutReward()
    {
        using var appDataScope = new TempAppDataScope();
        var progression = new ProgressionState();
        var handoff = CampaignProgressionService.CampaignSummaryHandoff.Create(
            returnToCampaignMapOnSummary: true,
            campaignNodeId: "citadel-rise",
            campaignNodeRewardGold: 30);

        var outcome = CampaignProgressionService.ApplySingleWaveOutcome(
            progression,
            handoff,
            isVictory: false,
            day: 4,
            enemiesDefeated: 12,
            wordsTyped: 27,
            wordsPerMinute: 38.0,
            accuracyRate: 0.84);
        var display = CampaignProgressionService.BuildSummaryDisplay(outcome);

        Assert.False(outcome.NodeCompletedThisRun);
        Assert.False(outcome.RewardAwarded);
        Assert.False(progression.IsNodeCompleted("citadel-rise"));
        Assert.Equal(0, progression.Gold);
        Assert.Equal("Node not cleared. Win to earn +30 gold.", display.Text);
        Assert.Equal(CampaignProgressionService.CampaignOutcomeTone.Warning, display.Tone);
    }

    [Fact]
    public void CampaignSummaryHandoff_Create_NormalizesNodeAndReward()
    {
        var handoff = CampaignProgressionService.CampaignSummaryHandoff.Create(
            returnToCampaignMapOnSummary: true,
            campaignNodeId: "  ember-bridge  ",
            campaignNodeRewardGold: -5);

        Assert.True(handoff.ReturnToCampaignMapOnSummary);
        Assert.Equal("ember-bridge", handoff.CampaignNodeId);
        Assert.Equal(0, handoff.CampaignNodeRewardGold);
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
