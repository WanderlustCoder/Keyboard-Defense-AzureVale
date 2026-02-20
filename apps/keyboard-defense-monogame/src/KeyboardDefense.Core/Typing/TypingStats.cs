using System;
using System.Collections.Generic;

namespace KeyboardDefense.Core.Typing;

/// <summary>
/// Night typing stats tracking with combo, accuracy, hit rate.
/// Ported from sim/typing_stats.gd.
/// </summary>
public class TypingStats
{
    public int NightDay { get; set; }
    public int WaveTotal { get; set; }
    public int NightSteps { get; set; }
    public int EnterPresses { get; set; }
    public int IncompleteEnters { get; set; }
    public int CommandEnters { get; set; }
    public int DefendAttempts { get; set; }
    public int WaitSteps { get; set; }
    public int Hits { get; set; }
    public int Misses { get; set; }
    public int TypedChars { get; set; }
    public int DeletedChars { get; set; }
    public double SumAccuracy { get; set; }
    public int AccuracyAttempts { get; set; }
    public int SumEditDistance { get; set; }
    public int EditDistanceAttempts { get; set; }
    public long StartMsec { get; set; } = -1;
    public int CurrentCombo { get; set; }
    public int MaxCombo { get; set; }
    public int[] ComboThresholds { get; } = { 3, 5, 10, 20, 50 };

    public void StartNight(int day, int waveTotal, long nowMsec = -1)
    {
        NightDay = day;
        WaveTotal = waveTotal;
        NightSteps = 0;
        EnterPresses = 0;
        IncompleteEnters = 0;
        CommandEnters = 0;
        DefendAttempts = 0;
        WaitSteps = 0;
        Hits = 0;
        Misses = 0;
        TypedChars = 0;
        DeletedChars = 0;
        SumAccuracy = 0;
        AccuracyAttempts = 0;
        SumEditDistance = 0;
        EditDistanceAttempts = 0;
        StartMsec = nowMsec;
        CurrentCombo = 0;
        MaxCombo = 0;
    }

    public void OnTextChanged(string prevText, string newText)
    {
        int prevLen = prevText.Length;
        int newLen = newText.Length;
        if (newLen > prevLen) TypedChars += newLen - prevLen;
        else if (newLen < prevLen) DeletedChars += prevLen - newLen;
    }

    public void OnEnterPressed() => EnterPresses++;

    public void RecordIncompleteEnter(string reason) => IncompleteEnters++;

    public void RecordCommandEnter(string kind, bool advancesStep)
    {
        CommandEnters++;
        if (advancesStep) NightSteps++;
        if (kind == "wait") WaitSteps++;
    }

    public void RecordDefendAttempt(string typedRaw, List<Dictionary<string, object>> enemies)
    {
        DefendAttempts++;
        NightSteps++;

        string typed = TypingFeedback.NormalizeInput(typedRaw);
        bool hit = false;

        foreach (var enemy in enemies)
        {
            string word = TypingFeedback.NormalizeInput(enemy.GetValueOrDefault("word")?.ToString() ?? "");
            if (word != "" && typed == word) { hit = true; break; }
        }

        if (hit) { Hits++; CurrentCombo++; if (CurrentCombo > MaxCombo) MaxCombo = CurrentCombo; }
        else { Misses++; CurrentCombo = 0; }

        if (enemies.Count == 0) return;

        int bestDist = int.MaxValue;
        int bestLen = 0;
        foreach (var enemy in enemies)
        {
            string word = TypingFeedback.NormalizeInput(enemy.GetValueOrDefault("word")?.ToString() ?? "");
            if (word == "") continue;
            int dist = TypingFeedback.EditDistance(typed, word);
            if (dist < bestDist) { bestDist = dist; bestLen = word.Length; }
        }

        if (bestDist != int.MaxValue)
        {
            SumEditDistance += bestDist;
            EditDistanceAttempts++;
            int maxLen = Math.Max(Math.Max(bestLen, typed.Length), 1);
            double acc = Math.Clamp(1.0 - (double)bestDist / maxLen, 0, 1);
            SumAccuracy += acc;
            AccuracyAttempts++;
        }
    }

    public Dictionary<string, object> ToReportDict()
    {
        double attemptDiv = Math.Max(DefendAttempts, 1);
        double backspaceDiv = Math.Max(TypedChars + DeletedChars, 1);
        double accuracyDiv = Math.Max(AccuracyAttempts, 1);
        double editDiv = Math.Max(EditDistanceAttempts, 1);

        return new Dictionary<string, object>
        {
            ["night_day"] = NightDay,
            ["wave_total"] = WaveTotal,
            ["night_steps"] = NightSteps,
            ["enter_presses"] = EnterPresses,
            ["incomplete_enters"] = IncompleteEnters,
            ["command_enters"] = CommandEnters,
            ["defend_attempts"] = DefendAttempts,
            ["wait_steps"] = WaitSteps,
            ["hits"] = Hits,
            ["misses"] = Misses,
            ["typed_chars"] = TypedChars,
            ["deleted_chars"] = DeletedChars,
            ["current_combo"] = CurrentCombo,
            ["max_combo"] = MaxCombo,
            ["hit_rate"] = Hits / attemptDiv,
            ["backspace_rate"] = DeletedChars / backspaceDiv,
            ["incomplete_rate"] = IncompleteEnters / (double)Math.Max(EnterPresses, 1),
            ["avg_accuracy"] = SumAccuracy / accuracyDiv,
            ["avg_edit_distance"] = SumEditDistance / editDiv,
        };
    }

    public int GetComboTier()
    {
        int tier = 0;
        foreach (int threshold in ComboThresholds)
        {
            if (CurrentCombo >= threshold) tier++;
            else break;
        }
        return tier;
    }

    public bool DidReachThreshold(int prevCombo)
    {
        foreach (int threshold in ComboThresholds)
            if (CurrentCombo >= threshold && prevCombo < threshold) return true;
        return false;
    }
}
