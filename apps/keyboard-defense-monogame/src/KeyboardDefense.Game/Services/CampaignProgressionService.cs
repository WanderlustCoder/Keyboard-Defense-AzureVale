using System;

namespace KeyboardDefense.Game.Services;

/// <summary>
/// Applies campaign progression updates for vertical-slice single-wave outcomes.
/// </summary>
public static class CampaignProgressionService
{
    public static void ApplySingleWaveOutcome(
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
            return;

        progressionState.RecordGameEnd(
            victory: isVictory,
            day: day,
            enemiesDefeated: enemiesDefeated,
            wordsTyped: wordsTyped,
            wpm: wordsPerMinute,
            accuracy: accuracyRate);

        if (isVictory)
            progressionState.CompleteNode(campaignNodeId, Math.Max(0, campaignNodeRewardGold));
    }
}
