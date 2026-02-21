using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.E2E;

/// <summary>
/// Helper for driving full game scenarios through the Core simulation
/// without rendering. Wraps IntentApplier with convenience methods.
/// </summary>
public class GameSimulator
{
    public GameState State { get; private set; }
    public List<string> AllEvents { get; } = new();
    public int TotalSteps { get; private set; }

    public GameSimulator(string seed = "e2e_test")
    {
        State = DefaultState.Create(seed, true);
    }

    // --- Core Operations ---

    /// <summary>Apply a raw intent and update state.</summary>
    public List<string> Apply(Dictionary<string, object> intent)
    {
        var result = IntentApplier.Apply(State, intent);
        State = (GameState)result["state"];
        var events = result.GetValueOrDefault("events") as List<string> ?? new();
        AllEvents.AddRange(events);
        TotalSteps++;
        return events;
    }

    /// <summary>Apply a named command string (parsed by CommandParser).</summary>
    public List<string> Command(string command)
    {
        var intent = CommandParser.Parse(command);
        return Apply(intent);
    }

    // --- Day Phase Shortcuts ---

    public List<string> Gather(string resource = "wood") =>
        Apply(SimIntents.Make("gather", new() { ["resource"] = resource }));

    public List<string> Build(string type, int x, int y) =>
        Apply(SimIntents.Make("build", new() { ["type"] = type, ["x"] = x, ["y"] = y }));

    public List<string> Explore() =>
        Apply(SimIntents.Make("explore"));

    public List<string> EndDay() =>
        Apply(SimIntents.Make("end"));

    // --- Night Phase Shortcuts ---

    public List<string> TypeWord(string text) =>
        Apply(SimIntents.Make("defend_input", new() { ["text"] = text }));

    public List<string> Wait() =>
        Apply(SimIntents.Make("wait"));

    /// <summary>Spawn enemies by waiting until at least one exists.</summary>
    public void SpawnEnemies(int maxWaits = 5)
    {
        for (int i = 0; i < maxWaits && State.Enemies.Count == 0; i++)
        {
            if (State.Phase != "night") break;
            Wait();
        }
    }

    /// <summary>Get the word from the first alive enemy.</summary>
    public string? FirstEnemyWord()
    {
        if (State.Enemies.Count == 0) return null;
        return State.Enemies[0].GetValueOrDefault("word")?.ToString();
    }

    /// <summary>Type the first enemy's word to defeat it.</summary>
    public List<string> DefeatFirstEnemy()
    {
        var word = FirstEnemyWord();
        if (string.IsNullOrEmpty(word)) return new();
        return TypeWord(word!);
    }

    // --- Scenario Runners ---

    /// <summary>Run through an entire night phase by typing all enemy words.</summary>
    public NightResult RunNightToCompletion(int maxSteps = 100)
    {
        var result = new NightResult();

        for (int step = 0; step < maxSteps; step++)
        {
            if (State.Phase != "night") break;

            if (State.Enemies.Count > 0)
            {
                var word = FirstEnemyWord();
                if (!string.IsNullOrEmpty(word))
                {
                    var events = TypeWord(word!);
                    result.WordsTyped++;
                    if (events.Any(e => e.Contains("defeated", StringComparison.OrdinalIgnoreCase)))
                        result.EnemiesKilled++;
                }
                else
                {
                    Wait();
                }
            }
            else
            {
                Wait();
            }

            result.Steps++;
        }

        result.EndPhase = State.Phase;
        result.EndHp = State.Hp;
        return result;
    }

    /// <summary>Run a full day (gather, build, explore) and transition to night.</summary>
    public void RunDayPhase(int gatherCount = 2)
    {
        if (State.Phase != "day") return;

        for (int i = 0; i < gatherCount && State.Ap > 0; i++)
            Gather();

        if (State.Ap > 0)
            Explore();

        EndDay();
    }

    /// <summary>Run multiple full day/night cycles and return aggregate results.</summary>
    public GameRunResult RunGameLoop(int days, int maxStepsPerNight = 100)
    {
        var result = new GameRunResult();

        for (int d = 0; d < days; d++)
        {
            if (State.Phase == "game_over" || State.Phase == "victory")
                break;

            RunDayPhase();
            result.DaysCompleted++;

            if (State.Phase == "night")
            {
                var nightResult = RunNightToCompletion(maxStepsPerNight);
                result.TotalEnemiesKilled += nightResult.EnemiesKilled;
                result.TotalWordsTyped += nightResult.WordsTyped;
            }
        }

        result.EndPhase = State.Phase;
        result.EndDay = State.Day;
        result.EndHp = State.Hp;
        result.EndGold = State.Gold;
        return result;
    }

    // --- Result Types ---

    public class NightResult
    {
        public int Steps;
        public int WordsTyped;
        public int EnemiesKilled;
        public string EndPhase = "";
        public int EndHp;
    }

    public class GameRunResult
    {
        public int DaysCompleted;
        public int TotalEnemiesKilled;
        public int TotalWordsTyped;
        public string EndPhase = "";
        public int EndDay;
        public int EndHp;
        public int EndGold;
    }
}
