using System;
using System.Collections.Generic;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Progression;

/// <summary>
/// Victory and game-over condition checking.
/// Ported from sim/victory.gd.
/// </summary>
public static class Victory
{
    public static string CheckVictory(GameState state)
    {
        // Game over if HP reaches 0
        if (state.Hp <= 0) return "defeat";

        // Check for campaign victory conditions
        if (state.Day >= 30 && state.CompletedQuests.Count >= 5)
            return "victory";

        // Check for boss victory
        if (state.BossesDefeated.Count >= 4)
            return "victory";

        return "none";
    }

    public static Dictionary<string, object> GetVictoryReport(GameState state)
    {
        string result = CheckVictory(state);
        var report = new Dictionary<string, object>
        {
            ["result"] = result,
            ["day"] = state.Day,
            ["gold_earned"] = state.Gold,
            ["quests_completed"] = state.CompletedQuests.Count,
            ["bosses_defeated"] = state.BossesDefeated.Count,
            ["tiles_discovered"] = state.Discovered.Count,
            ["total_tiles"] = state.MapW * state.MapH,
        };

        if (result == "victory")
        {
            int score = CalculateScore(state);
            report["score"] = score;
            report["grade"] = GetGrade(score);
        }
        else if (result == "defeat")
        {
            report["survived_days"] = state.Day;
        }

        return report;
    }

    public static int CalculateScore(GameState state)
    {
        int score = 0;
        score += state.Day * 100;
        score += state.Gold * 2;
        score += state.CompletedQuests.Count * 500;
        score += state.BossesDefeated.Count * 1000;
        score += state.Discovered.Count * 10;
        score += state.Structures.Count * 50;
        return score;
    }

    public static string GetGrade(int score)
    {
        if (score >= 20000) return "S";
        if (score >= 15000) return "A";
        if (score >= 10000) return "B";
        if (score >= 5000) return "C";
        return "D";
    }
}
