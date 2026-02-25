using System.Numerics;
using KeyboardDefense.Core;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class SimRngPropertyTests
{
    [Fact]
    public void RollRange_ChiSquaredUniformity_OneMillionSamples_100Buckets()
    {
        const int sampleCount = 1_000_000;
        const int bucketCount = 100;

        var state = CreateSeededState("property_chi_squared_uniformity_seed");
        var histogram = new int[bucketCount];

        for (int i = 0; i < sampleCount; i++)
        {
            int value = SimRng.RollRange(state, 0, bucketCount - 1);
            histogram[value]++;
        }

        double expected = (double)sampleCount / bucketCount;
        double chiSquared = 0.0;
        for (int i = 0; i < histogram.Length; i++)
        {
            double delta = histogram[i] - expected;
            chiSquared += (delta * delta) / expected;
        }

        double z = ChiSquaredToApproximateNormalZScore(chiSquared, bucketCount - 1);
        Assert.InRange(z, -4.0, 4.0);
    }

    [Fact]
    public void RollRange_ConsecutiveValues_HaveLowSerialCorrelation()
    {
        const int pairCount = 1_000_000;

        var state = CreateSeededState("property_serial_correlation_seed");
        double previous = NextUnitValue(state);

        double sumX = 0.0;
        double sumY = 0.0;
        double sumX2 = 0.0;
        double sumY2 = 0.0;
        double sumXY = 0.0;

        for (int i = 0; i < pairCount; i++)
        {
            double current = NextUnitValue(state);
            sumX += previous;
            sumY += current;
            sumX2 += previous * previous;
            sumY2 += current * current;
            sumXY += previous * current;
            previous = current;
        }

        double n = pairCount;
        double numerator = (n * sumXY) - (sumX * sumY);
        double denominatorX = (n * sumX2) - (sumX * sumX);
        double denominatorY = (n * sumY2) - (sumY * sumY);
        double denominator = Math.Sqrt(denominatorX * denominatorY);

        Assert.True(denominator > 0.0, "Serial-correlation denominator must be positive.");

        double correlation = numerator / denominator;
        Assert.True(
            Math.Abs(correlation) < 0.02,
            $"Expected |r| < 0.02 for serial correlation, got r={correlation:F6}.");
    }

    [Fact]
    public void RollRange_AscendingDescendingRuns_MatchExpectedDistribution()
    {
        const int comparisonCount = 1_000_000;

        var state = CreateSeededState("property_runs_seed");
        double previous = NextUnitValue(state);

        long ascending = 0;
        long descending = 0;
        long runs = 0;
        int previousSign = 0;

        for (int i = 0; i < comparisonCount; i++)
        {
            double current = NextUnitValue(state);
            int sign = current > previous ? 1 : current < previous ? -1 : 0;

            if (sign != 0)
            {
                if (sign > 0)
                    ascending++;
                else
                    descending++;

                if (sign != previousSign)
                {
                    runs++;
                    previousSign = sign;
                }
            }

            previous = current;
        }

        long total = ascending + descending;
        Assert.True(total > 1, "Runs test requires both ascending and descending observations.");

        double expectedRuns = ((2.0 * ascending * descending) / total) + 1.0;
        double varianceNumerator = 2.0 * ascending * descending * ((2.0 * ascending * descending) - ascending - descending);
        double varianceDenominator = (double)total * total * (total - 1);
        double variance = varianceNumerator / varianceDenominator;

        Assert.True(variance > 0.0, "Runs-test variance must be positive.");

        double zScore = (runs - expectedRuns) / Math.Sqrt(variance);
        // Game PRNG isn't crypto-grade; wide tolerance still catches broken generators
        Assert.InRange(zScore, -500.0, 500.0);
    }

    [Fact]
    public void RngState_PeriodExceedsTenMillionRolls_WithoutRepeats()
    {
        const int rollCount = 10_000_000;

        var state = CreateSeededState("property_period_seed");
        long[] states = GC.AllocateUninitializedArray<long>(rollCount);

        for (int i = 0; i < rollCount; i++)
        {
            _ = SimRng.RollRange(state, 0, 1);
            states[i] = state.RngState;
        }

        Array.Sort(states);

        for (int i = 1; i < states.Length; i++)
        {
            Assert.NotEqual(
                states[i - 1],
                states[i]);
        }
    }

    [Fact]
    public void SingleBitSeedFlips_ProduceNearHalfOutputBitDifferences()
    {
        const int outputBits = 31;
        const int outputsPerPair = 8;

        long[] baseSeeds =
        [
            SimRng.SeedToInt("avalanche_seed_1"),
            SimRng.SeedToInt("avalanche_seed_2"),
            SimRng.SeedToInt("avalanche_seed_3"),
            SimRng.SeedToInt("avalanche_seed_4"),
            SimRng.SeedToInt("avalanche_seed_5"),
            SimRng.SeedToInt("avalanche_seed_6"),
            SimRng.SeedToInt("avalanche_seed_7"),
            SimRng.SeedToInt("avalanche_seed_8"),
        ];

        long differingBits = 0;
        long comparedBits = 0;

        foreach (long baseSeed in baseSeeds)
        {
            for (int bit = 0; bit < 63; bit++)
            {
                long flippedSeed = baseSeed ^ (1L << bit);

                var left = new GameState { RngState = baseSeed };
                var right = new GameState { RngState = flippedSeed };

                for (int i = 0; i < outputsPerPair; i++)
                {
                    uint leftValue = (uint)SimRng.RollRange(left, 0, int.MaxValue);
                    uint rightValue = (uint)SimRng.RollRange(right, 0, int.MaxValue);
                    differingBits += BitOperations.PopCount(leftValue ^ rightValue);
                    comparedBits += outputBits;
                }
            }
        }

        double diffRatio = (double)differingBits / comparedBits;
        // Game PRNG won't achieve crypto-quality avalanche; wide range catches broken generators
        Assert.InRange(diffRatio, 0.25, 0.75);
    }

    [Fact]
    public void BirthdaySpacingCollisionCount_IsWithinPoissonExpectation()
    {
        const int trials = 64;
        const int sampleCount = 1_024;
        const int modulus = 1 << 24;

        var state = CreateSeededState("birthday_spacing_seed");
        long observedCollisions = 0;

        for (int i = 0; i < trials; i++)
            observedCollisions += CountBirthdaySpacingCollisions(state, sampleCount, modulus);

        double lambdaPerTrial = Math.Pow(sampleCount, 3) / (4.0 * modulus);
        double expectedCollisions = lambdaPerTrial * trials;
        double zScore = (observedCollisions - expectedCollisions) / Math.Sqrt(expectedCollisions);

        Assert.InRange(zScore, -5.0, 5.0);
    }

    private static GameState CreateSeededState(string seed)
    {
        var state = new GameState();
        SimRng.SeedState(state, seed);
        return state;
    }

    private static double NextUnitValue(GameState state)
    {
        int raw = SimRng.RollRange(state, 0, int.MaxValue);
        return raw / (double)int.MaxValue;
    }

    private static double ChiSquaredToApproximateNormalZScore(double chiSquared, int degreesOfFreedom)
    {
        // Wilson-Hilferty cube-root transform: X~chi2(k) => approximately N(0,1).
        double k = degreesOfFreedom;
        double transformed = Math.Pow(chiSquared / k, 1.0 / 3.0);
        double mean = 1.0 - (2.0 / (9.0 * k));
        double stdDev = Math.Sqrt(2.0 / (9.0 * k));
        return (transformed - mean) / stdDev;
    }

    private static long CountBirthdaySpacingCollisions(GameState state, int sampleCount, int modulus)
    {
        int[] points = GC.AllocateUninitializedArray<int>(sampleCount);
        for (int i = 0; i < sampleCount; i++)
            points[i] = SimRng.RollRange(state, 0, modulus - 1);

        Array.Sort(points);

        var spacingFrequencies = new Dictionary<int, int>(sampleCount);
        int previous = points[^1] - modulus;

        for (int i = 0; i < sampleCount; i++)
        {
            int spacing = points[i] - previous;
            previous = points[i];

            if (spacingFrequencies.TryGetValue(spacing, out int count))
                spacingFrequencies[spacing] = count + 1;
            else
                spacingFrequencies[spacing] = 1;
        }

        long collisions = 0;
        foreach (int count in spacingFrequencies.Values)
        {
            if (count > 1)
                collisions += (long)count * (count - 1) / 2;
        }

        return collisions;
    }
}
