using System;

namespace KeyboardDefense.Game.Services;

/// <summary>
/// Applies campaign progression updates for vertical-slice single-wave outcomes.
/// </summary>
public static class CampaignProgressionService
{
    public readonly record struct CampaignSummaryHandoff(
        bool ReturnToCampaignMapOnSummary,
        string CampaignNodeId,
        int CampaignNodeRewardGold)
    {
        public static CampaignSummaryHandoff None => new(
            ReturnToCampaignMapOnSummary: false,
            CampaignNodeId: string.Empty,
            CampaignNodeRewardGold: 0);

        public static CampaignSummaryHandoff Create(
            bool returnToCampaignMapOnSummary,
            string? campaignNodeId,
            int campaignNodeRewardGold)
        {
            return new CampaignSummaryHandoff(
                ReturnToCampaignMapOnSummary: returnToCampaignMapOnSummary,
                CampaignNodeId: (campaignNodeId ?? string.Empty).Trim(),
                CampaignNodeRewardGold: Math.Max(0, campaignNodeRewardGold));
        }
    }

    public enum CampaignOutcomeTone
    {
        Neutral,
        Success,
        Reward,
        Warning,
    }

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

    public readonly record struct CampaignOutcomeDisplay(string Text, CampaignOutcomeTone Tone);

    public static CampaignOutcome ApplySingleWaveOutcome(
        ProgressionState progressionState,
        CampaignSummaryHandoff handoff,
        bool isVictory,
        int day,
        int enemiesDefeated,
        int wordsTyped,
        double wordsPerMinute,
        double accuracyRate)
    {
        return ApplySingleWaveOutcome(
            progressionState,
            handoff.ReturnToCampaignMapOnSummary,
            isVictory,
            handoff.CampaignNodeId,
            handoff.CampaignNodeRewardGold,
            day,
            enemiesDefeated,
            wordsTyped,
            wordsPerMinute,
            accuracyRate);
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

    public static CampaignOutcomeDisplay BuildSummaryDisplay(CampaignOutcome outcome)
    {
        if (!outcome.IsCampaignRun)
            return new CampaignOutcomeDisplay(string.Empty, CampaignOutcomeTone.Neutral);

        if (outcome.IsVictory)
        {
            if (outcome.RewardAwarded)
            {
                return new CampaignOutcomeDisplay(
                    $"Node cleared: +{outcome.RewardGold} gold awarded.",
                    CampaignOutcomeTone.Reward);
            }

            if (outcome.NodeCompletedThisRun)
                return new CampaignOutcomeDisplay("Node cleared.", CampaignOutcomeTone.Success);

            return new CampaignOutcomeDisplay(
                "Node already cleared. No additional node reward.",
                CampaignOutcomeTone.Neutral);
        }

        if (outcome.RewardGold > 0)
        {
            return new CampaignOutcomeDisplay(
                $"Node not cleared. Win to earn +{outcome.RewardGold} gold.",
                CampaignOutcomeTone.Warning);
        }

        return new CampaignOutcomeDisplay(
            "Node not cleared. Win to mark this node complete.",
            CampaignOutcomeTone.Warning);
    }
}
