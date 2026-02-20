using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class VerticalSliceWaveSimTests
{
    [Fact]
    public void StartSingleWave_InitializesNightStateAndMetrics()
    {
        var state = DefaultState.Create("vs_init", placeStartingTowers: true);
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 4,
            SpawnIntervalSeconds = 0.5f,
            EnemyStepIntervalSeconds = 1.0f,
            EnemyStepDistance = 1,
            EnemyContactDamage = 1,
            TypedHitDamage = 2,
            TypedMissDamage = 1,
            TowerTickDamage = 1,
        };
        var events = new List<string>();

        VerticalSliceWaveSim.StartSingleWave(state, config, events);

        Assert.Equal("night", state.Phase);
        Assert.Equal(4, state.NightWaveTotal);
        Assert.Equal(4, state.NightSpawnRemaining);
        Assert.Equal("", MetricString(state, "vs_result"));
        Assert.True(events.Any(e => e.Contains("Night falls.", StringComparison.Ordinal)));
    }

    [Fact]
    public void Step_TypingPrefixProgress_CompletesWordAndEndsWave()
    {
        var state = DefaultState.Create("vs_prefix", placeStartingTowers: false);
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 1,
            SpawnIntervalSeconds = 1.0f,
            EnemyStepIntervalSeconds = 10.0f,
            EnemyStepDistance = 1,
            EnemyContactDamage = 1,
            TypedHitDamage = 2,
            TypedMissDamage = 1,
            TowerTickDamage = 0,
        };
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());

        state.Enemies.Clear();
        state.NightSpawnRemaining = 0;
        state.NightWaveTotal = 1;
        state.Enemies.Add(new Dictionary<string, object>
        {
            ["id"] = 1,
            ["kind"] = "scout",
            ["word"] = "cat",
            ["hp"] = 2,
            ["dist"] = 10,
            ["gold"] = 1,
            ["damage"] = 1,
        });

        var events = new List<string>();
        VerticalSliceWaveSim.Step(state, config, 0f, "c", events);
        Assert.Equal("at", state.NightPrompt);
        Assert.Contains(events, e => e.StartsWith("typing_hit:", StringComparison.Ordinal));

        events.Clear();
        VerticalSliceWaveSim.Step(state, config, 0f, "a", events);
        Assert.Equal("t", state.NightPrompt);
        Assert.Contains(events, e => e.StartsWith("typing_hit:", StringComparison.Ordinal));

        events.Clear();
        VerticalSliceWaveSim.Step(state, config, 0f, "t", events);
        Assert.Equal("day", state.Phase);
        Assert.Equal("victory", MetricString(state, "vs_result"));
        Assert.Equal(1, MetricInt(state, "battle_words_typed"));
        Assert.True(events.Any(e => e.StartsWith("typing_word_complete:", StringComparison.Ordinal)));
    }

    [Fact]
    public void Step_WaveClearedWithoutEnemies_FinalizesVictoryPayload()
    {
        var state = DefaultState.Create("vs_victory_payload", placeStartingTowers: false);
        var config = new VerticalSliceWaveConfig();
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());

        state.NightSpawnRemaining = 0;
        state.NightWaveTotal = 0;
        state.Enemies.Clear();

        var events = new List<string>();
        VerticalSliceWaveSim.Step(state, config, 0f, null, events);

        Assert.Equal("day", state.Phase);
        Assert.Equal("victory", MetricString(state, "vs_result"));
        Assert.True(state.TypingMetrics.ContainsKey("vs_summary_payload"));
        var payload = Assert.IsType<Dictionary<string, object>>(state.TypingMetrics["vs_summary_payload"]);
        Assert.Equal("victory", payload["result"]?.ToString());
    }

    [Fact]
    public void Step_MissAtLowHp_FinalizesDefeatPayload()
    {
        var state = DefaultState.Create("vs_defeat_payload", placeStartingTowers: false);
        state.Hp = 1;
        var config = new VerticalSliceWaveConfig
        {
            SpawnTotal = 1,
            SpawnIntervalSeconds = 1.0f,
            EnemyStepIntervalSeconds = 1.0f,
            EnemyStepDistance = 1,
            EnemyContactDamage = 1,
            TypedHitDamage = 2,
            TypedMissDamage = 1,
            TowerTickDamage = 0,
        };
        VerticalSliceWaveSim.StartSingleWave(state, config, new List<string>());
        state.NightSpawnRemaining = 0;
        state.Enemies.Clear();

        var events = new List<string>();
        VerticalSliceWaveSim.Step(state, config, 0f, "zzz", events);

        Assert.Equal("game_over", state.Phase);
        Assert.Equal("defeat", MetricString(state, "vs_result"));
        Assert.True(state.TypingMetrics.ContainsKey("vs_summary_payload"));
        var payload = Assert.IsType<Dictionary<string, object>>(state.TypingMetrics["vs_summary_payload"]);
        Assert.Equal("defeat", payload["result"]?.ToString());
        Assert.True(events.Any(e => e.StartsWith("typing_miss:", StringComparison.Ordinal)));
    }

    private static int MetricInt(GameState state, string key)
    {
        if (!state.TypingMetrics.TryGetValue(key, out object? value) || value == null)
            return 0;
        if (value is int i)
            return i;
        return int.TryParse(value.ToString(), out int parsed) ? parsed : 0;
    }

    private static string MetricString(GameState state, string key)
    {
        if (!state.TypingMetrics.TryGetValue(key, out object? value) || value == null)
            return "";
        return value.ToString() ?? "";
    }
}

