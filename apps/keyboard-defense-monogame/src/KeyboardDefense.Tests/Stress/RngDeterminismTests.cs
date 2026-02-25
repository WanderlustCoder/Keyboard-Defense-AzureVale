using System.Collections;
using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using KeyboardDefense.Core;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;
using KeyboardDefense.Tests.E2E;

namespace KeyboardDefense.Tests.Stress;

public class RngDeterminismTests
{
    private static readonly HashSet<string> UnorderedListPaths = new(StringComparer.Ordinal)
    {
        "discovered",
        "completed_quests",
        "bosses_defeated",
        "milestones",
        "unlocked_skills",
        "completed_daily_challenges",
    };

    [Fact]
    public void RollRange_SameSeed_ProducesIdenticalSequence_10000Samples()
    {
        const int sampleCount = 10_000;
        var stateA = new GameState();
        var stateB = new GameState();
        SimRng.SeedState(stateA, "rng_sequence_seed");
        SimRng.SeedState(stateB, "rng_sequence_seed");

        for (int i = 0; i < sampleCount; i++)
        {
            int left = SimRng.RollRange(stateA, -50, 50);
            int right = SimRng.RollRange(stateB, -50, 50);
            Assert.Equal(left, right);
        }

        Assert.Equal(stateA.RngState, stateB.RngState);
    }

    [Fact]
    public void RollRange_DifferentSeeds_ProduceStatisticallyDifferentDistributions()
    {
        const int sampleCount = 50_000;
        const int bucketCount = 32;

        int[] histogramA = SampleHistogram("dist_seed_a", sampleCount, 0, bucketCount - 1);
        int[] histogramB = SampleHistogram("dist_seed_b", sampleCount, 0, bucketCount - 1);

        int totalAbsoluteDelta = 0;
        for (int i = 0; i < bucketCount; i++)
            totalAbsoluteDelta += Math.Abs(histogramA[i] - histogramB[i]);

        double chiSquared = CalculateTwoSampleChiSquared(histogramA, histogramB);

        Assert.False(histogramA.SequenceEqual(histogramB));
        Assert.True(totalAbsoluteDelta > 600, $"Expected meaningful histogram divergence, delta={totalAbsoluteDelta}.");
        Assert.True(chiSquared > 5.0, $"Expected non-trivial chi-squared divergence, got {chiSquared:F3}.");
    }

    [Fact]
    public void RollRange_RangeBoundsAreNeverViolated_100000Samples()
    {
        const int sampleCount = 100_000;
        var state = new GameState();
        SimRng.SeedState(state, "rng_bounds_seed");

        for (int i = 0; i < sampleCount; i++)
        {
            int value = SimRng.RollRange(state, -137, 243);
            Assert.InRange(value, -137, 243);
        }
    }

    [Fact]
    public void RollRange_UniformDistribution_PassesChiSquaredBucketTest()
    {
        const int sampleCount = 200_000;
        const int bucketCount = 32;

        int[] histogram = SampleHistogram("uniformity_seed", sampleCount, 0, bucketCount - 1);
        double expectedCount = (double)sampleCount / bucketCount;
        double chiSquared = CalculateUniformChiSquared(histogram, expectedCount);

        Assert.True(chiSquared < 80.0, $"Chi-squared too high for near-uniform distribution: {chiSquared:F3}.");
    }

    [Fact]
    public void RollDouble_StaysWithinInclusiveUnitInterval_100000Samples()
    {
        const int sampleCount = 100_000;
        var state = new GameState();
        SimRng.SeedState(state, "roll_double_seed");

        for (int i = 0; i < sampleCount; i++)
        {
            double value = SimRng.RollDouble(state);
            Assert.InRange(value, 0.0, 1.0);
        }
    }

    [Fact]
    public void FullGameSimulation_WithSameSeed_ProducesSameOutcomes()
    {
        const string seed = "full_game_determinism_seed";

        var simA = new GameSimulator(seed);
        var simB = new GameSimulator(seed);

        var resultA = simA.RunGameLoop(days: 4, maxStepsPerNight: 120);
        var resultB = simB.RunGameLoop(days: 4, maxStepsPerNight: 120);

        Assert.Equal(resultA.DaysCompleted, resultB.DaysCompleted);
        Assert.Equal(resultA.TotalEnemiesKilled, resultB.TotalEnemiesKilled);
        Assert.Equal(resultA.TotalWordsTyped, resultB.TotalWordsTyped);
        Assert.Equal(resultA.EndPhase, resultB.EndPhase);
        Assert.Equal(resultA.EndDay, resultB.EndDay);
        Assert.Equal(resultA.EndHp, resultB.EndHp);
        Assert.Equal(resultA.EndGold, resultB.EndGold);
        Assert.Equal(simA.TotalSteps, simB.TotalSteps);
        Assert.Equal(simA.AllEvents, simB.AllEvents);
        Assert.Equal(BuildStateFingerprint(simA.State), BuildStateFingerprint(simB.State));
    }

    [Fact]
    public void WorldTick_100Ticks_WithSameSeed_ProducesIdenticalFinalStates()
    {
        const int tickCount = 100;
        const string seed = "world_tick_determinism_seed";

        var stateA = DefaultState.Create(seed, placeStartingTowers: true);
        var stateB = DefaultState.Create(seed, placeStartingTowers: true);

        var eventsA = new List<string>();
        var eventsB = new List<string>();

        for (int i = 0; i < tickCount; i++)
        {
            var tickResultA = WorldTick.Tick(stateA, WorldTick.WorldTickInterval);
            var tickResultB = WorldTick.Tick(stateB, WorldTick.WorldTickInterval);

            eventsA.AddRange(tickResultA["events"] as List<string> ?? []);
            eventsB.AddRange(tickResultB["events"] as List<string> ?? []);
            Assert.Equal(tickResultA["changed"], tickResultB["changed"]);
        }

        Assert.Equal(eventsA, eventsB);
        Assert.Equal(BuildStateFingerprint(stateA), BuildStateFingerprint(stateB));
    }

    private static int[] SampleHistogram(string seed, int sampleCount, int minInclusive, int maxInclusive)
    {
        var state = new GameState();
        SimRng.SeedState(state, seed);

        int bucketCount = maxInclusive - minInclusive + 1;
        var histogram = new int[bucketCount];

        for (int i = 0; i < sampleCount; i++)
        {
            int value = SimRng.RollRange(state, minInclusive, maxInclusive);
            histogram[value - minInclusive]++;
        }

        return histogram;
    }

    private static double CalculateUniformChiSquared(IReadOnlyList<int> histogram, double expectedCount)
    {
        double chiSquared = 0.0;
        for (int i = 0; i < histogram.Count; i++)
        {
            double diff = histogram[i] - expectedCount;
            chiSquared += (diff * diff) / expectedCount;
        }

        return chiSquared;
    }

    private static double CalculateTwoSampleChiSquared(IReadOnlyList<int> histogramA, IReadOnlyList<int> histogramB)
    {
        double chiSquared = 0.0;

        for (int i = 0; i < histogramA.Count; i++)
        {
            int combined = histogramA[i] + histogramB[i];
            if (combined == 0)
                continue;

            double diff = histogramA[i] - histogramB[i];
            chiSquared += (diff * diff) / combined;
        }

        return chiSquared;
    }

    private static string BuildStateFingerprint(GameState state)
    {
        string snapshot = BuildStateSnapshot(state);
        byte[] hash = SHA256.HashData(Encoding.UTF8.GetBytes(snapshot));
        return Convert.ToHexString(hash);
    }

    private static string BuildStateSnapshot(GameState state)
    {
        var builder = new StringBuilder(capacity: 4096);
        AppendCanonical(SaveManager.StateToDict(state), builder, path: "");
        return builder.ToString();
    }

    private static void AppendCanonical(object? value, StringBuilder builder, string path)
    {
        if (value is null)
        {
            builder.Append("null");
            return;
        }

        switch (value)
        {
            case string s:
                builder.Append('"');
                builder.Append(EscapeString(s));
                builder.Append('"');
                return;
            case bool b:
                builder.Append(b ? "true" : "false");
                return;
            case float f:
                builder.Append(f.ToString("R", CultureInfo.InvariantCulture));
                return;
            case double d:
                builder.Append(d.ToString("R", CultureInfo.InvariantCulture));
                return;
            case decimal m:
                builder.Append(m.ToString(CultureInfo.InvariantCulture));
                return;
            case sbyte or byte or short or ushort or int or uint or long or ulong:
                builder.Append(Convert.ToString(value, CultureInfo.InvariantCulture));
                return;
        }

        if (value is IDictionary dictionary)
        {
            var entries = new List<KeyValuePair<string, object?>>();
            foreach (DictionaryEntry entry in dictionary)
            {
                string key = Convert.ToString(entry.Key, CultureInfo.InvariantCulture) ?? string.Empty;
                entries.Add(new KeyValuePair<string, object?>(key, entry.Value));
            }

            entries.Sort((left, right) => StringComparer.Ordinal.Compare(left.Key, right.Key));
            builder.Append('{');
            for (int i = 0; i < entries.Count; i++)
            {
                if (i > 0)
                    builder.Append(',');

                string key = entries[i].Key;
                string childPath = string.IsNullOrEmpty(path) ? key : path + "." + key;
                builder.Append(key);
                builder.Append(':');
                AppendCanonical(entries[i].Value, builder, childPath);
            }

            builder.Append('}');
            return;
        }

        if (value is IEnumerable enumerable)
        {
            var items = new List<object?>();
            foreach (object? item in enumerable)
                items.Add(item);

            if (UnorderedListPaths.Contains(path))
            {
                items.Sort(static (left, right) =>
                    StringComparer.Ordinal.Compare(
                        Convert.ToString(left, CultureInfo.InvariantCulture),
                        Convert.ToString(right, CultureInfo.InvariantCulture)));
            }

            builder.Append('[');
            for (int i = 0; i < items.Count; i++)
            {
                if (i > 0)
                    builder.Append(',');
                AppendCanonical(items[i], builder, path + "[]");
            }

            builder.Append(']');
            return;
        }

        builder.Append(Convert.ToString(value, CultureInfo.InvariantCulture));
    }

    private static string EscapeString(string value)
    {
        return value
            .Replace("\\", "\\\\", StringComparison.Ordinal)
            .Replace("\"", "\\\"", StringComparison.Ordinal);
    }
}
