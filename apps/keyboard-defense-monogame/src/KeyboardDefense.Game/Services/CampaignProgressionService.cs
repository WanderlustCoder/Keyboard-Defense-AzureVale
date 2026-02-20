using System;

namespace KeyboardDefense.Game.Services;

/// <summary>
/// Applies campaign progression updates for vertical-slice single-wave outcomes.
/// </summary>
public static class CampaignProgressionService
{
    public readonly record struct CampaignOutcome(
        bool IsCampaignRun,
        bool IsVictory,
        bool NodeAlreadyCompleted,
        bool NodeCompletedThisRun,
        bool RewardAwarded,
        int RewardGold)
    {
        public static CampaignOutcome None => new(
            IsCampaignRun: false,
            IsVictory: false,
            NodeAlreadyCompleted: false,
            NodeCompletedThisRun: false,
            RewardAwarded: false,
            RewardGold: 0);
    }

    public static CampaignOutcome ApplySingleWaveOutcome(
        ProgressionState progressionState,
        bool returnToCampaignMapOnSummary,
        bool isVictory,
        string campaignNodeId,
        int campaignNodeRewardGold,
        int day,
        int enemiesDefeated,
        int wordsTyped,
        double wordsPerMinute,
        double accuracyRate)
    {
        if (!returnToCampaignMapOnSummary || string.IsNullOrWhiteSpace(campaignNodeId))
            return CampaignOutcome.None;

        int rewardGold = Math.Max(0, campaignNodeRewardGold);
        bool alreadyCompleted = progressionState.IsNodeCompleted(campaignNodeId);

        progressionState.RecordGameEnd(
            victory: isVictory,
            day: day,
            enemiesDefeated: enemiesDefeated,
            wordsTyped: wordsTyped,
            wpm: wordsPerMinute,
            accuracy: accuracyRate);

        bool nodeCompletedThisRun = false;
        bool rewardAwarded = false;
        if (isVictory)
        {
            nodeCompletedThisRun = !alreadyCompleted;
            progressionState.CompleteNode(campaignNodeId, rewardGold);
            rewardAwarded = nodeCompletedThisRun && rewardGold > 0;
        }

        return new CampaignOutcome(
            IsCampaignRun: true,
            IsVictory: isVictory,
            NodeAlreadyCompleted: alreadyCompleted,
            NodeCompletedThisRun: nodeCompletedThisRun,
            RewardAwarded: rewardAwarded,
            RewardGold: rewardGold);
    }
}
