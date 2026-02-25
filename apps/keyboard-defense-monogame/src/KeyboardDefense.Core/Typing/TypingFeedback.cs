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
    /// <summary>
    /// Normalizes raw player input by trimming whitespace and converting to lowercase.
    /// </summary>
    /// <param name="input">The raw input string to normalize.</param>
    /// <returns>A normalized lowercase string, or an empty string for null input.</returns>
    public static string NormalizeInput(string input)
        => input?.Trim().ToLowerInvariant() ?? "";

    /// <summary>
    /// Calculates the number of leading characters shared by two strings.
    /// </summary>
    /// <param name="typed">The typed input to compare.</param>
    /// <param name="word">The target word to compare against.</param>
    /// <returns>The matching prefix length.</returns>
    public static int PrefixLen(string typed, string word)
    {
        int len = Math.Min(typed.Length, word.Length);
        for (int i = 0; i < len; i++)
        {
            if (typed[i] != word[i]) return i;
        }
        return len;
    }

    /// <summary>
    /// Computes Levenshtein edit distance between two strings.
    /// </summary>
    /// <param name="a">The first string.</param>
    /// <param name="b">The second string.</param>
    /// <returns>The minimum number of single-character edits needed to transform one string into the other.</returns>
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

    /// <summary>
    /// Evaluates alive enemies against typed input and returns matching candidate metadata.
    /// </summary>
    /// <param name="typed">The typed input used to match enemy words.</param>
    /// <param name="enemies">Enemy dictionaries containing word, id, and alive state data.</param>
    /// <returns>A candidate analysis result containing exact, best-prefix, and expected-next-character data.</returns>
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

/// <summary>
/// Aggregated candidate-matching information for typed input against enemy words.
/// </summary>
public class TypingCandidateResult
{
    /// <summary>
    /// The original typed input string used for candidate evaluation.
    /// </summary>
    public string Typed { get; set; } = "";

    /// <summary>
    /// Enemy id with an exact word match, when one is found.
    /// </summary>
    public int? ExactId { get; set; }

    /// <summary>
    /// Enemy ids that share any positive prefix match with the typed input.
    /// </summary>
    public List<int> CandidateIds { get; set; } = new();

    /// <summary>
    /// The largest prefix length matched by any candidate.
    /// </summary>
    public int BestPrefixLen { get; set; }

    /// <summary>
    /// Enemy ids tied for the best prefix match length.
    /// </summary>
    public List<int> BestIds { get; set; } = new();

    /// <summary>
    /// Distinct expected next characters based on current prefix matches.
    /// </summary>
    public List<char> ExpectedNextChars { get; set; } = new();
}
