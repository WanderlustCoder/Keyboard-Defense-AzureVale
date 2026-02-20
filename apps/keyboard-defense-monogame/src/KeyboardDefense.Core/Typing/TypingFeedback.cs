using System;
using System.Collections.Generic;
using System.Linq;

namespace KeyboardDefense.Core.Typing;

/// <summary>
/// Analyzes typed input against enemy words, provides matching and routing.
/// Ported from sim/typing_feedback.gd.
/// </summary>
public static class TypingFeedback
{
    public static string NormalizeInput(string input)
        => input?.Trim().ToLowerInvariant() ?? "";

    public static int PrefixLen(string typed, string word)
    {
        int len = Math.Min(typed.Length, word.Length);
        for (int i = 0; i < len; i++)
        {
            if (typed[i] != word[i]) return i;
        }
        return len;
    }

    public static int EditDistance(string a, string b)
    {
        int m = a.Length, n = b.Length;
        var dp = new int[m + 1, n + 1];
        for (int i = 0; i <= m; i++) dp[i, 0] = i;
        for (int j = 0; j <= n; j++) dp[0, j] = j;
        for (int i = 1; i <= m; i++)
        {
            for (int j = 1; j <= n; j++)
            {
                int cost = a[i - 1] == b[j - 1] ? 0 : 1;
                dp[i, j] = Math.Min(
                    Math.Min(dp[i - 1, j] + 1, dp[i, j - 1] + 1),
                    dp[i - 1, j - 1] + cost);
            }
        }
        return dp[m, n];
    }

    public static TypingCandidateResult EnemyCandidates(string typed, List<Dictionary<string, object>> enemies)
    {
        var result = new TypingCandidateResult { Typed = typed };
        if (string.IsNullOrEmpty(typed) || enemies.Count == 0)
            return result;

        var normalized = NormalizeInput(typed);
        int bestPrefix = 0;
        int? exactId = null;

        foreach (var enemy in enemies)
        {
            if (enemy.GetValueOrDefault("alive") is not true) continue;
            string word = enemy.GetValueOrDefault("word")?.ToString()?.ToLowerInvariant() ?? "";
            if (string.IsNullOrEmpty(word)) continue;

            int prefix = PrefixLen(normalized, word);
            int id = Convert.ToInt32(enemy.GetValueOrDefault("id", -1));

            if (normalized == word)
            {
                exactId = id;
                result.ExactId = id;
            }

            if (prefix > bestPrefix)
            {
                bestPrefix = prefix;
                result.BestPrefixLen = prefix;
                result.BestIds.Clear();
                result.BestIds.Add(id);
            }
            else if (prefix == bestPrefix && prefix > 0)
            {
                result.BestIds.Add(id);
            }

            if (prefix > 0)
            {
                result.CandidateIds.Add(id);
                // Collect expected next characters
                if (prefix < word.Length)
                {
                    char next = word[prefix];
                    if (!result.ExpectedNextChars.Contains(next))
                        result.ExpectedNextChars.Add(next);
                }
            }
        }

        return result;
    }
}

public class TypingCandidateResult
{
    public string Typed { get; set; } = "";
    public int? ExactId { get; set; }
    public List<int> CandidateIds { get; set; } = new();
    public int BestPrefixLen { get; set; }
    public List<int> BestIds { get; set; } = new();
    public List<char> ExpectedNextChars { get; set; } = new();
}
