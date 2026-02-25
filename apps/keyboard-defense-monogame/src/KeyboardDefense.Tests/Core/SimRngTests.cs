using KeyboardDefense.Core;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class SimRngTests
{
    [Fact]
    public void SeedToInt_IsDeterministic_AndMapsEmptySeedToZero()
    {
        long first = SimRng.SeedToInt("deterministic_seed");
        long second = SimRng.SeedToInt("deterministic_seed");

        Assert.Equal(first, second);
        Assert.True(first >= 0);
        Assert.Equal(0, SimRng.SeedToInt(string.Empty));
    }

    [Fact]
    public void SeedState_SetsSeedAndDerivedRngState()
    {
        var state = new GameState();

        SimRng.SeedState(state, "alpha_seed");

        Assert.Equal("alpha_seed", state.RngSeed);
        Assert.Equal(SimRng.SeedToInt("alpha_seed"), state.RngState);
    }

    [Fact]
    public void RollRange_SameSeed_ProducesIdenticalSequence()
    {
        const int sampleCount = 5_000;
        var stateA = CreateSeededState("same_seed_sequence");
        var stateB = CreateSeededState("same_seed_sequence");

        for (int i = 0; i < sampleCount; i++)
        {
            int left = SimRng.RollRange(stateA, -25, 75);
            int right = SimRng.RollRange(stateB, -25, 75);
            Assert.Equal(left, right);
        }

        Assert.Equal(stateA.RngState, stateB.RngState);
    }

    [Fact]
    public void RollRange_StaysWithinInclusiveBounds_AcrossLargeSample()
    {
        const int sampleCount = 100_000;
        var state = CreateSeededState("bounds_seed");

        for (int i = 0; i < sampleCount; i++)
        {
            int value = SimRng.RollRange(state, -137, 243);
            Assert.InRange(value, -137, 243);
        }
    }

    [Fact]
    public void RollRange_ReversedBounds_MatchesOrderedBoundsSequence()
    {
        const int sampleCount = 2_000;
        var orderedState = CreateSeededState("reversed_bounds_seed");
        var reversedState = CreateSeededState("reversed_bounds_seed");

        for (int i = 0; i < sampleCount; i++)
        {
            int ordered = SimRng.RollRange(orderedState, -9, 17);
            int reversed = SimRng.RollRange(reversedState, 17, -9);
            Assert.Equal(ordered, reversed);
        }
    }

    [Fact]
    public void RollRange_WhenBoundsAreEqual_AlwaysReturnsThatValue()
    {
        const int expected = 42;
        var state = CreateSeededState("single_value_seed");

        for (int i = 0; i < 2_000; i++)
            Assert.Equal(expected, SimRng.RollRange(state, expected, expected));
    }

    [Fact]
    public void RollDouble_StaysInUnitInterval_AndMeanIsNearHalf()
    {
        const int sampleCount = 100_000;
        var state = CreateSeededState("roll_double_seed");
        double sum = 0.0;

        for (int i = 0; i < sampleCount; i++)
        {
            double value = SimRng.RollDouble(state);
            Assert.InRange(value, 0.0, 1.0);
            sum += value;
        }

        double mean = sum / sampleCount;
        Assert.InRange(mean, 0.48, 0.52);
    }

    [Fact]
    public void RollRange_Distribution_IsReasonablyUniformAcrossBuckets()
    {
        const int bucketCount = 20;
        const int sampleCount = 200_000;
        const double maxDeviationFraction = 0.10;

        var state = CreateSeededState("distribution_seed");
        var histogram = new int[bucketCount];

        for (int i = 0; i < sampleCount; i++)
        {
            int value = SimRng.RollRange(state, 0, bucketCount - 1);
            histogram[value]++;
        }

        double expectedPerBucket = (double)sampleCount / bucketCount;
        for (int i = 0; i < histogram.Length; i++)
        {
            double deviationFraction = Math.Abs(histogram[i] - expectedPerBucket) / expectedPerBucket;
            Assert.True(
                deviationFraction <= maxDeviationFraction,
                $"Bucket {i} deviated too far: count={histogram[i]}, expected={expectedPerBucket:F0}, deviation={deviationFraction:P2}.");
        }
    }

    [Fact]
    public void RollRange_DifferentSeeds_ProduceDifferentSequences()
    {
        const int sampleCount = 4_096;
        var stateA = CreateSeededState("seed_a");
        var stateB = CreateSeededState("seed_b");
        int equalPositions = 0;

        for (int i = 0; i < sampleCount; i++)
        {
            int left = SimRng.RollRange(stateA, 0, 1_000_000);
            int right = SimRng.RollRange(stateB, 0, 1_000_000);
            if (left == right)
                equalPositions++;
        }

        Assert.True(equalPositions <= 2, $"Too many equal positions across sequences: {equalPositions}.");
        Assert.NotEqual(stateA.RngState, stateB.RngState);
    }

    [Fact]
    public void ChooseAndChooseValue_HandleEmptyAndNonEmptyLists()
    {
        var emptyReferenceState = CreateSeededState("choose_empty_seed");
        long emptyReferenceStart = emptyReferenceState.RngState;
        var emptyReferenceList = new List<string>();

        Assert.Null(SimRng.Choose(emptyReferenceState, emptyReferenceList));
        Assert.Equal(emptyReferenceStart, emptyReferenceState.RngState);

        var referenceState = CreateSeededState("choose_non_empty_seed");
        var referenceList = new List<string> { "a", "b", "c" };
        for (int i = 0; i < 200; i++)
        {
            string? picked = SimRng.Choose(referenceState, referenceList);
            Assert.NotNull(picked);
            Assert.Contains(picked, referenceList);
        }

        var emptyValueState = CreateSeededState("choose_value_empty_seed");
        long emptyValueStart = emptyValueState.RngState;
        var emptyValueList = new List<int>();

        Assert.Equal(-1, SimRng.ChooseValue(emptyValueState, emptyValueList, -1));
        Assert.Equal(emptyValueStart, emptyValueState.RngState);

        var valueState = CreateSeededState("choose_value_non_empty_seed");
        var valueList = new List<int> { 3, 7, 11 };
        for (int i = 0; i < 200; i++)
        {
            int picked = SimRng.ChooseValue(valueState, valueList, -1);
            Assert.Contains(picked, valueList);
        }
    }

    private static GameState CreateSeededState(string seed)
    {
        var state = new GameState();
        SimRng.SeedState(state, seed);
        return state;
    }
}
