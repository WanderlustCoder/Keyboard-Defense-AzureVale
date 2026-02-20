using System;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core;

/// <summary>
/// Deterministic random number generation for reproducible games.
/// Ported from sim/rng.gd (SimRng class).
/// Uses a simple LCG (linear congruential generator) to match Godot's
/// RandomNumberGenerator behavior for deterministic sequences.
/// </summary>
public static class SimRng
{
    public static long SeedToInt(string seed)
    {
        long hashed = StringHash(seed);
        if (hashed == long.MinValue)
            return 0;
        return Math.Abs(hashed);
    }

    public static void SeedState(GameState state, string seedString)
    {
        state.RngSeed = seedString;
        state.RngState = SeedToInt(seedString);
    }

    public static int RollRange(GameState state, int minValue, int maxValue)
    {
        if (minValue > maxValue)
            (minValue, maxValue) = (maxValue, minValue);

        // Advance RNG state using LCG parameters
        state.RngState = unchecked(state.RngState * 6364136223846793005L + 1442695040888963407L);
        long range = (long)maxValue - minValue + 1;
        int value = (int)(((state.RngState >>> 33) % range + range) % range) + minValue;
        return value;
    }

    public static T? Choose<T>(GameState state, IList<T> arr) where T : class
    {
        if (arr.Count == 0)
            return null;
        int index = RollRange(state, 0, arr.Count - 1);
        return arr[index];
    }

    public static double RollDouble(GameState state)
    {
        state.RngState = unchecked(state.RngState * 6364136223846793005L + 1442695040888963407L);
        return ((double)((state.RngState >>> 33) & 0x7FFFFFFF)) / 0x7FFFFFFF;
    }

    public static T ChooseValue<T>(GameState state, IList<T> arr, T fallback) where T : struct
    {
        if (arr.Count == 0)
            return fallback;
        int index = RollRange(state, 0, arr.Count - 1);
        return arr[index];
    }

    /// <summary>
    /// Produces a hash compatible with GDScript's String.hash() for common cases.
    /// </summary>
    private static long StringHash(string s)
    {
        if (string.IsNullOrEmpty(s))
            return 0;

        // Use a standard hash that produces deterministic results
        unchecked
        {
            long hash = 5381;
            foreach (char c in s)
            {
                hash = ((hash << 5) + hash) + c;
            }
            return hash;
        }
    }
}
