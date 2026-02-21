using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;

namespace KeyboardDefense.Tests.Core;

public class InlineCombatPartialTests
{
    [Fact]
    public void UpdatePartialProgress_SetsTypedCharsForMatchingPrefix()
    {
        var state = CreateEncounterState();
        state.EncounterEnemies.Add(CreateEnemy(1, word: "castle"));
        state.EncounterEnemies.Add(CreateEnemy(2, word: "forest"));

        InlineCombat.UpdatePartialProgress(state, "cas");

        Assert.Equal(3, Convert.ToInt32(state.EncounterEnemies[0]["typed_chars"]));
        Assert.True(state.EncounterEnemies[0]["is_target"] is true);
        Assert.Equal(0, Convert.ToInt32(state.EncounterEnemies[1]["typed_chars"]));
        Assert.True(state.EncounterEnemies[1]["is_target"] is false);
    }

    [Fact]
    public void UpdatePartialProgress_ClearsOnNonMatchingInput()
    {
        var state = CreateEncounterState();
        state.EncounterEnemies.Add(CreateEnemy(1, word: "castle"));

        // First match
        InlineCombat.UpdatePartialProgress(state, "cas");
        Assert.Equal(3, Convert.ToInt32(state.EncounterEnemies[0]["typed_chars"]));

        // Now non-matching
        InlineCombat.UpdatePartialProgress(state, "xyz");
        Assert.Equal(0, Convert.ToInt32(state.EncounterEnemies[0]["typed_chars"]));
        Assert.True(state.EncounterEnemies[0]["is_target"] is false);
    }

    [Fact]
    public void UpdatePartialProgress_HandlesEmptyInput()
    {
        var state = CreateEncounterState();
        state.EncounterEnemies.Add(CreateEnemy(1, word: "castle"));

        InlineCombat.UpdatePartialProgress(state, "");

        Assert.Equal(0, Convert.ToInt32(state.EncounterEnemies[0]["typed_chars"]));
        Assert.True(state.EncounterEnemies[0]["is_target"] is false);
    }

    [Fact]
    public void UpdatePartialProgress_HandlesNullInput()
    {
        var state = CreateEncounterState();
        state.EncounterEnemies.Add(CreateEnemy(1, word: "castle"));

        InlineCombat.UpdatePartialProgress(state, null!);

        Assert.Equal(0, Convert.ToInt32(state.EncounterEnemies[0]["typed_chars"]));
    }

    [Fact]
    public void UpdatePartialProgress_CaseInsensitiveMatching()
    {
        var state = CreateEncounterState();
        state.EncounterEnemies.Add(CreateEnemy(1, word: "Castle"));

        InlineCombat.UpdatePartialProgress(state, "CAS");

        Assert.Equal(3, Convert.ToInt32(state.EncounterEnemies[0]["typed_chars"]));
        Assert.True(state.EncounterEnemies[0]["is_target"] is true);
    }

    [Fact]
    public void UpdatePartialProgress_FullWordMatchSetsAllChars()
    {
        var state = CreateEncounterState();
        state.EncounterEnemies.Add(CreateEnemy(1, word: "mist"));

        InlineCombat.UpdatePartialProgress(state, "mist");

        Assert.Equal(4, Convert.ToInt32(state.EncounterEnemies[0]["typed_chars"]));
        Assert.True(state.EncounterEnemies[0]["is_target"] is true);
    }

    [Fact]
    public void UpdatePartialProgress_MultipleEnemiesCanMatchDifferentPrefixes()
    {
        var state = CreateEncounterState();
        state.EncounterEnemies.Add(CreateEnemy(1, word: "castle"));
        state.EncounterEnemies.Add(CreateEnemy(2, word: "cave"));
        state.EncounterEnemies.Add(CreateEnemy(3, word: "forest"));

        InlineCombat.UpdatePartialProgress(state, "ca");

        // Both "castle" and "cave" start with "ca"
        Assert.Equal(2, Convert.ToInt32(state.EncounterEnemies[0]["typed_chars"]));
        Assert.True(state.EncounterEnemies[0]["is_target"] is true);
        Assert.Equal(2, Convert.ToInt32(state.EncounterEnemies[1]["typed_chars"]));
        Assert.True(state.EncounterEnemies[1]["is_target"] is true);
        Assert.Equal(0, Convert.ToInt32(state.EncounterEnemies[2]["typed_chars"]));
        Assert.True(state.EncounterEnemies[2]["is_target"] is false);
    }

    [Fact]
    public void UpdatePartialProgress_IgnoredOutsideEncounterMode()
    {
        var state = DefaultState.Create();
        state.ActivityMode = "exploration";
        state.EncounterEnemies.Add(CreateEnemy(1, word: "castle"));

        InlineCombat.UpdatePartialProgress(state, "cas");

        // Should not have set typed_chars
        Assert.False(state.EncounterEnemies[0].ContainsKey("typed_chars"));
    }

    [Fact]
    public void UpdatePartialProgress_WhitespaceInputTreatedAsEmpty()
    {
        var state = CreateEncounterState();
        state.EncounterEnemies.Add(CreateEnemy(1, word: "castle"));

        InlineCombat.UpdatePartialProgress(state, "   ");

        Assert.Equal(0, Convert.ToInt32(state.EncounterEnemies[0]["typed_chars"]));
        Assert.True(state.EncounterEnemies[0]["is_target"] is false);
    }

    private static GameState CreateEncounterState()
    {
        var state = DefaultState.Create();
        state.ActivityMode = "encounter";
        TypingMetrics.InitBattleMetrics(state);
        return state;
    }

    private static Dictionary<string, object> CreateEnemy(
        int id,
        string kind = "scout",
        string word = "mist",
        int hp = 5,
        int tier = 0)
    {
        return new Dictionary<string, object>
        {
            ["kind"] = kind,
            ["id"] = id,
            ["word"] = word,
            ["hp"] = hp,
            ["tier"] = tier,
            ["pos"] = new GridPoint(5, 5),
            ["approach_progress"] = 0f,
        };
    }
}
