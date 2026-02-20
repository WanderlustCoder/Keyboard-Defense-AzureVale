using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Typing;

/// <summary>
/// Word generation for enemies based on lessons and kind.
/// Ported from sim/words.gd.
/// </summary>
public static class WordPool
{
    public static readonly string[] ShortWords =
    {
        "mist", "fern", "glow", "bolt", "rift", "lark",
        "reed", "moth", "brim", "palm", "rust", "quill"
    };

    public static readonly string[] MediumWords =
    {
        "harvest", "harbor", "citron", "amber", "copper", "stone",
        "forest", "meadow", "candle", "shield", "vector", "echoes",
        "market", "bridge"
    };

    public static readonly string[] LongWords =
    {
        "sentinel", "fortress", "vanguard", "monolith", "stronghold",
        "cathedral", "archivist", "lighthouse", "riverstone", "everglade",
        "moonlight", "wildgrowth"
    };

    private static readonly HashSet<string> ReservedWords = new(StringComparer.OrdinalIgnoreCase)
    {
        "help", "version", "status", "balance", "gather", "build",
        "explore", "interact", "choice", "skip", "buy", "upgrades",
        "end", "seed", "defend", "wait", "save", "load", "new",
        "restart", "cursor", "inspect", "map", "overlay", "preview",
        "upgrade", "demolish", "enemies", "goal", "lesson", "lessons",
        "settings", "bind", "report", "history", "trend", "tutorial"
    };

    public static string WordForEnemy(string seed, int day, string kind, int enemyId,
        HashSet<string> alreadyUsed, string? lessonId = null)
    {
        // Try adaptive word generation first (uses weak keys from profile)
        string adaptive = TryAdaptiveWord(seed, day, kind, enemyId, alreadyUsed);
        if (adaptive != "") return adaptive;

        // Try lesson-based word generation
        if (!string.IsNullOrEmpty(lessonId))
        {
            string word = MakeWordFromCharset(seed, day, kind, enemyId, lessonId, alreadyUsed);
            if (word != "") return word;
        }

        return FallbackWord(seed, day, kind, enemyId, alreadyUsed);
    }

    /// <summary>
    /// Generate a word that emphasizes weak keys from the typing profile.
    /// ~30% of words will target weak keys for adaptive practice.
    /// </summary>
    private static string TryAdaptiveWord(string seed, int day, string kind, int enemyId,
        HashSet<string> alreadyUsed)
    {
        var profile = TypingProfile.Instance;
        var weakKeys = profile.GetWeakKeys();
        if (weakKeys.Count == 0) return "";

        // Only use adaptive generation for ~30% of enemies
        int hash = HashIndex($"{seed}|{day}|adaptive|{enemyId}", 100);
        if (hash >= 30) return "";

        // Build a charset biased toward weak keys (each weak key repeated 3x)
        var chars = new List<char>();
        foreach (char c in weakKeys)
        {
            chars.Add(c); chars.Add(c); chars.Add(c);
        }
        // Add adjacent keys for naturalness
        foreach (char c in weakKeys)
        {
            foreach (char adj in GetAdjacentKeys(c))
                chars.Add(adj);
        }
        if (chars.Count < 3) return "";

        string charset = new(chars.ToArray());
        int minLen = kind == "scout" ? 3 : kind == "armored" ? 6 : 4;
        int maxLen = kind == "scout" ? 5 : kind == "armored" ? 9 : 7;

        string baseKey = $"{seed}|{day}|{kind}|{enemyId}|adaptive";
        for (int attempt = 0; attempt < 10; attempt++)
        {
            string word = MakeWord(baseKey, charset, minLen, maxLen, attempt);
            if (word == "" || ReservedWords.Contains(word) || alreadyUsed.Contains(word)) continue;
            return word;
        }
        return "";
    }

    /// <summary>Get adjacent keys on QWERTY layout for more natural word generation.</summary>
    private static char[] GetAdjacentKeys(char key)
    {
        return char.ToLower(key) switch
        {
            'q' => new[] { 'w', 'a' },
            'w' => new[] { 'q', 'e', 's' },
            'e' => new[] { 'w', 'r', 'd' },
            'r' => new[] { 'e', 't', 'f' },
            't' => new[] { 'r', 'y', 'g' },
            'y' => new[] { 't', 'u', 'h' },
            'u' => new[] { 'y', 'i', 'j' },
            'i' => new[] { 'u', 'o', 'k' },
            'o' => new[] { 'i', 'p', 'l' },
            'p' => new[] { 'o', 'l' },
            'a' => new[] { 'q', 'w', 's', 'z' },
            's' => new[] { 'a', 'w', 'e', 'd', 'x' },
            'd' => new[] { 's', 'e', 'r', 'f', 'c' },
            'f' => new[] { 'd', 'r', 't', 'g', 'v' },
            'g' => new[] { 'f', 't', 'y', 'h', 'b' },
            'h' => new[] { 'g', 'y', 'u', 'j', 'n' },
            'j' => new[] { 'h', 'u', 'i', 'k', 'm' },
            'k' => new[] { 'j', 'i', 'o', 'l' },
            'l' => new[] { 'k', 'o', 'p' },
            'z' => new[] { 'a', 's', 'x' },
            'x' => new[] { 'z', 's', 'd', 'c' },
            'c' => new[] { 'x', 'd', 'f', 'v' },
            'v' => new[] { 'c', 'f', 'g', 'b' },
            'b' => new[] { 'v', 'g', 'h', 'n' },
            'n' => new[] { 'b', 'h', 'j', 'm' },
            'm' => new[] { 'n', 'j', 'k' },
            _ => Array.Empty<char>(),
        };
    }

    public static string ScrambleWord(string word, string seed)
    {
        if (word.Length <= 1) return word;

        char[] chars = word.ToCharArray();
        int hashBase = (seed + word).GetHashCode();

        for (int i = chars.Length - 1; i > 0; i--)
        {
            int j = Math.Abs((hashBase + i).GetHashCode()) % (i + 1);
            (chars[i], chars[j]) = (chars[j], chars[i]);
        }

        string result = new(chars);
        if (result == word && word.Length > 1)
        {
            chars[0] = word[1];
            chars[1] = word[0];
            result = new string(chars);
        }
        return result;
    }

    private static string MakeWordFromCharset(string seed, int day, string kind, int enemyId,
        string lessonId, HashSet<string> alreadyUsed)
    {
        // Simplified charset-based generation
        string charset = "asdfghjkl"; // Default home row
        int minLen = kind == "scout" ? 3 : kind == "armored" ? 6 : 4;
        int maxLen = kind == "scout" ? 5 : kind == "armored" ? 9 : 7;

        string baseKey = $"{seed}|{day}|{kind}|{enemyId}|{lessonId}";
        int attempts = Math.Max(16, charset.Length * 2);

        for (int attempt = 0; attempt < attempts; attempt++)
        {
            string word = MakeWord(baseKey, charset, minLen, maxLen, attempt);
            if (word == "") continue;
            if (ReservedWords.Contains(word)) continue;
            if (alreadyUsed.Contains(word)) continue;
            return word;
        }
        return "";
    }

    private static string MakeWord(string baseKey, string charset, int minLen, int maxLen, int attempt)
    {
        if (charset.Length == 0) return "";
        int span = Math.Max(1, maxLen - minLen + 1);
        int length = minLen + HashIndex($"{baseKey}|len|{attempt}", span);
        var chars = new char[length];
        for (int i = 0; i < length; i++)
        {
            int idx = HashIndex($"{baseKey}|{attempt}|{i}", charset.Length);
            chars[i] = charset[idx];
        }
        return new string(chars);
    }

    private static string FallbackWord(string seed, int day, string kind, int enemyId, HashSet<string> alreadyUsed)
    {
        var list = ListForKind(kind);
        if (list.Length == 0) return $"foe{enemyId}";

        string key = $"{seed}|{day}|{kind}|{enemyId}";
        int index = HashIndex(key, list.Length);

        for (int i = 0; i < list.Length; i++)
        {
            string word = list[index].ToLowerInvariant();
            if (!ReservedWords.Contains(word) && !alreadyUsed.Contains(word))
                return word;
            index = (index + 1) % list.Length;
        }
        return $"foe{enemyId}";
    }

    private static string[] ListForKind(string kind) => kind switch
    {
        "scout" => ShortWords,
        "armored" => LongWords,
        _ => MediumWords,
    };

    private static int HashIndex(string key, int modulo)
    {
        if (modulo <= 0) return 0;
        int hash = key.GetHashCode();
        if (hash == int.MinValue) hash = 0;
        return Math.Abs(hash) % modulo;
    }
}
