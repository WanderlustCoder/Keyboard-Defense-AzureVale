using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class ResourceChallengeTests
{
    private static GameState CreateHarvestState()
    {
        var state = DefaultState.Create("harvest_test");
        TypingMetrics.InitBattleMetrics(state);
        return state;
    }

    private static void PlaceNodeNearPlayer(GameState state)
    {
        var nodePos = state.PlayerPos;
        int nodeIdx = SimMap.Idx(nodePos.X, nodePos.Y, state.MapW);
        state.ResourceNodes[nodeIdx] = new Dictionary<string, object>
        {
            ["type"] = "wood_grove",
            ["pos"] = nodePos,
            ["zone"] = "safe",
            ["cooldown"] = 0f,
        };
    }

    [Fact]
    public void StartChallenge_NearResourceNode_ReturnsChallenge()
    {
        var state = CreateHarvestState();
        PlaceNodeNearPlayer(state);

        var result = ResourceChallenge.StartChallenge(state);

        Assert.NotNull(result);
        Assert.True(Convert.ToBoolean(result!["ok"]));
        Assert.False(string.IsNullOrEmpty(result["word"]?.ToString()));
        Assert.Equal("harvest_challenge", state.ActivityMode);
    }

    [Fact]
    public void StartChallenge_NoNodeNearby_ReturnsNull()
    {
        var state = CreateHarvestState();
        // Don't place any nodes near player

        var result = ResourceChallenge.StartChallenge(state);

        Assert.Null(result);
        Assert.Equal("exploration", state.ActivityMode);
    }

    [Fact]
    public void StartChallenge_NotInExploration_ReturnsNull()
    {
        var state = CreateHarvestState();
        state.ActivityMode = "encounter";
        PlaceNodeNearPlayer(state);

        var result = ResourceChallenge.StartChallenge(state);

        Assert.Null(result);
    }

    [Fact]
    public void StartChallenge_NodeOnCooldown_ReturnsNull()
    {
        var state = CreateHarvestState();
        var nodePos = state.PlayerPos;
        int nodeIdx = SimMap.Idx(nodePos.X, nodePos.Y, state.MapW);
        state.ResourceNodes[nodeIdx] = new Dictionary<string, object>
        {
            ["type"] = "wood_grove",
            ["pos"] = nodePos,
            ["cooldown"] = 5f, // on cooldown
        };

        var result = ResourceChallenge.StartChallenge(state);

        Assert.Null(result);
    }

    [Fact]
    public void ProcessChallengeInput_CorrectWord_HarvestsResource()
    {
        var state = CreateHarvestState();
        PlaceNodeNearPlayer(state);

        var challenge = ResourceChallenge.StartChallenge(state);
        Assert.NotNull(challenge);
        string word = challenge!["word"].ToString()!;

        int woodBefore = state.Resources.GetValueOrDefault("wood", 0);
        var events = ResourceChallenge.ProcessChallengeInput(state, word);

        Assert.NotEmpty(events);
        Assert.True(state.Resources.GetValueOrDefault("wood", 0) > woodBefore);
        Assert.Equal("exploration", state.ActivityMode);
    }

    [Fact]
    public void ProcessChallengeInput_WrongWord_StillHarvests()
    {
        // Wrong word gives partial credit via Levenshtein score
        var state = CreateHarvestState();
        PlaceNodeNearPlayer(state);

        var challenge = ResourceChallenge.StartChallenge(state);
        Assert.NotNull(challenge);

        var events = ResourceChallenge.ProcessChallengeInput(state, "xyzxyz");

        Assert.NotEmpty(events);
        Assert.Equal("exploration", state.ActivityMode);
    }

    [Fact]
    public void ProcessChallengeInput_SetsNodeCooldown()
    {
        var state = CreateHarvestState();
        PlaceNodeNearPlayer(state);
        int nodeIdx = SimMap.Idx(state.PlayerPos.X, state.PlayerPos.Y, state.MapW);

        var challenge = ResourceChallenge.StartChallenge(state);
        Assert.NotNull(challenge);
        string word = challenge!["word"].ToString()!;

        ResourceChallenge.ProcessChallengeInput(state, word);

        float cooldown = Convert.ToSingle(state.ResourceNodes[nodeIdx].GetValueOrDefault("cooldown", 0f));
        Assert.True(cooldown > 0, "Node should be on cooldown after harvest");
    }

    [Fact]
    public void CancelChallenge_ReturnsToExploration()
    {
        var state = CreateHarvestState();
        PlaceNodeNearPlayer(state);

        ResourceChallenge.StartChallenge(state);
        Assert.Equal("harvest_challenge", state.ActivityMode);

        ResourceChallenge.CancelChallenge(state);
        Assert.Equal("exploration", state.ActivityMode);
    }

    [Fact]
    public void TickCooldowns_DecrementsCooldown()
    {
        var state = CreateHarvestState();
        var nodePos = state.PlayerPos;
        int nodeIdx = SimMap.Idx(nodePos.X, nodePos.Y, state.MapW);
        state.ResourceNodes[nodeIdx] = new Dictionary<string, object>
        {
            ["type"] = "wood_grove",
            ["pos"] = nodePos,
            ["cooldown"] = 5f,
        };

        ResourceChallenge.TickCooldowns(state, 2f);

        float cooldown = Convert.ToSingle(state.ResourceNodes[nodeIdx]["cooldown"]);
        Assert.Equal(3f, cooldown, 0.01);
    }

    [Fact]
    public void TickCooldowns_DoesNotGoBelowZero()
    {
        var state = CreateHarvestState();
        var nodePos = state.PlayerPos;
        int nodeIdx = SimMap.Idx(nodePos.X, nodePos.Y, state.MapW);
        state.ResourceNodes[nodeIdx] = new Dictionary<string, object>
        {
            ["type"] = "wood_grove",
            ["pos"] = nodePos,
            ["cooldown"] = 1f,
        };

        ResourceChallenge.TickCooldowns(state, 10f);

        float cooldown = Convert.ToSingle(state.ResourceNodes[nodeIdx]["cooldown"]);
        Assert.Equal(0f, cooldown);
    }
}
