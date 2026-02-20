using System;
using System.Collections.Generic;

namespace KeyboardDefense.Game.Screens;

public static class CampaignMapOnboardingPolicy
{
    public const string CampaignMapOnboardingDoneFlag = "campaign_map_onboarding_done";

    public static bool ShouldShow(ISet<string> completedAchievements)
    {
        return !completedAchievements.Contains(CampaignMapOnboardingDoneFlag);
    }

    public static int AdvanceStep(int currentStep, int totalSteps)
    {
        if (totalSteps <= 0)
            return 0;
        return Math.Min(currentStep + 1, totalSteps);
    }

    public static bool IsComplete(int currentStep, int totalSteps)
    {
        return totalSteps <= 0 || currentStep >= totalSteps;
    }
}
